defmodule ObanPowertools.Batch.Tracker do
  @moduledoc """
  Exactly-once batch progress tracking.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias ObanPowertools.Batch
  alias ObanPowertools.BatchJob
  alias ObanPowertools.Callback

  @valid_states [:success, :discard]

  def record_progress(repo, %Oban.Job{} = job, state) when state in @valid_states do
    case batch_id_from_meta(job.meta) do
      nil ->
        {:ok, :ignored}

      batch_id ->
        now = timestamp()

        case insert_batch_job(repo, batch_id, job, state, now) do
          :inserted ->
            with {:ok, batch} <- increment_batch(repo, batch_id, state, now),
                 {:ok, _callback} <- maybe_insert_chain_callback(repo, batch_id, job, state, now) do
              maybe_complete_batch(repo, batch)
            end

          :duplicate ->
            {:ok, :duplicate}
        end
    end
  end

  def record_progress(_repo, %Oban.Job{}, _state), do: {:error, :invalid_state}

  def record_callback_exhaustion(repo, %Oban.Job{} = job) do
    case callback_batch_id(repo, job) do
      nil ->
        {:ok, :ignored}

      batch_id ->
        {count, _rows} =
          repo.update_all(
            from(batch in Batch, where: batch.id == ^batch_id),
            set: [status: "callback_failed", updated_at: timestamp()]
          )

        if count == 1, do: {:ok, :callback_failed}, else: {:ok, :ignored}
    end
  end

  defp callback_batch_id(repo, %Oban.Job{meta: meta}) when is_map(meta) do
    cond do
      callback_id = callback_id_from_meta(meta) ->
        case repo.get(Callback, callback_id) do
          %Callback{batch_id: batch_id} when not is_nil(batch_id) -> batch_id
          _other -> nil
        end

      batch_id = batch_id_from_meta(meta) ->
        batch_id

      true ->
        nil
    end
  end

  defp callback_batch_id(_repo, _job), do: nil

  defp batch_id_from_meta(meta) when is_map(meta) do
    Map.get(meta, "batch_id") || Map.get(meta, :batch_id)
  end

  defp batch_id_from_meta(_meta), do: nil

  defp callback_id_from_meta(meta) when is_map(meta) do
    Map.get(meta, "callback_id") ||
      Map.get(meta, :callback_id) ||
      Map.get(meta, "oban_powertools_callback_id") ||
      Map.get(meta, :oban_powertools_callback_id)
  end

  defp callback_id_from_meta(_meta), do: nil

  defp insert_batch_job(repo, batch_id, %Oban.Job{id: job_id}, state, now) do
    {count, _rows} =
      repo.insert_all(
        BatchJob,
        [
          %{
            id: Ecto.UUID.generate(),
            batch_id: batch_id,
            job_id: job_id,
            state: Atom.to_string(state),
            inserted_at: now,
            updated_at: now
          }
        ],
        on_conflict: :nothing,
        conflict_target: [:batch_id, :job_id]
      )

    if count == 1, do: :inserted, else: :duplicate
  end

  defp increment_batch(repo, batch_id, :success, now) do
    batch_id
    |> batch_count_query()
    |> repo.update_all(inc: [success_count: 1], set: [updated_at: now])
    |> updated_batch_result()
  end

  defp increment_batch(repo, batch_id, :discard, now) do
    batch_id
    |> batch_count_query()
    |> repo.update_all(inc: [discard_count: 1], set: [updated_at: now])
    |> updated_batch_result()
  end

  defp batch_count_query(batch_id) do
    from(batch in Batch,
      where: batch.id == ^batch_id,
      select: %{
        id: batch.id,
        total_count: batch.total_count,
        success_count: batch.success_count,
        discard_count: batch.discard_count
      }
    )
  end

  defp updated_batch_result({1, [batch]}), do: {:ok, batch}
  defp updated_batch_result({0, []}), do: {:error, :batch_not_found}

  defp maybe_complete_batch(repo, batch) do
    if batch.success_count + batch.discard_count == batch.total_count do
      complete_batch(repo, batch)
    else
      {:ok, :tracked}
    end
  end

  defp complete_batch(repo, batch) do
    {status, event} =
      if batch.discard_count == 0 do
        {"completed", "batch.completed"}
      else
        {"exhausted", "batch.exhausted"}
      end

    completed_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Multi.new()
    |> Multi.update_all(
      :batch,
      from(candidate in Batch,
        where: candidate.id == ^batch.id and is_nil(candidate.completed_at)
      ),
      set: [completed_at: completed_at, status: status]
    )
    |> Multi.run(:callback, fn repo, %{batch: {updated_count, _rows}} ->
      if updated_count == 1 do
        insert_callback(repo, batch.id, event)
      else
        {:ok, :already_completed}
      end
    end)
    |> repo.transaction()
    |> case do
      {:ok, %{batch: {1, _rows}}} -> {:ok, :completed}
      {:ok, %{batch: {0, _rows}}} -> {:ok, :tracked}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp insert_callback(repo, batch_id, event) do
    %Callback{}
    |> Callback.changeset(%{
      batch_id: batch_id,
      event: event,
      dedupe_key: "#{event}-#{batch_id}",
      status: "pending",
      payload: %{"batch_id" => batch_id, "event" => event},
      attempts: 0
    })
    |> repo.insert()
  end

  defp maybe_insert_chain_callback(
         repo,
         batch_id,
         %Oban.Job{meta: meta, id: job_id},
         :success,
         now
       )
       when is_map(meta) do
    with %{
           "chain_id" => chain_id,
           "chain_step_name" => step_name,
           "chain_step_index" => step_index,
           "chain_step_count" => step_count,
           "chain_next_step" => next_step
         } <- normalize_meta(meta) do
      %Callback{}
      |> Callback.changeset(%{
        batch_id: batch_id,
        event: "chain.step_succeeded",
        dedupe_key: "chain.step_succeeded:#{chain_id}:#{step_index}:#{job_id}",
        status: "pending",
        payload: %{
          "event" => "chain.step_succeeded",
          "chain_id" => chain_id,
          "batch_id" => batch_id,
          "step_name" => step_name,
          "step_index" => step_index,
          "step_count" => step_count,
          "upstream_job_id" => job_id,
          "next_step" => next_step
        },
        attempts: 0,
        available_at: now
      })
      |> repo.insert(on_conflict: :nothing, conflict_target: :dedupe_key)
    else
      _missing_chain_meta -> {:ok, :ignored}
    end
  end

  defp maybe_insert_chain_callback(_repo, _batch_id, %Oban.Job{}, _state, _now),
    do: {:ok, :ignored}

  defp normalize_meta(meta) do
    Map.new(meta, fn {key, value} -> {to_string(key), value} end)
  end

  defp timestamp do
    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end
end
