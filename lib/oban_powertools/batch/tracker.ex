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
    case batch_id(job) do
      nil ->
        {:ok, :ignored}

      batch_id ->
        now = timestamp()

        case insert_batch_job(repo, batch_id, job, state, now) do
          :inserted ->
            with {:ok, batch} <- increment_batch(repo, batch_id, state, now) do
              maybe_complete_batch(repo, batch)
            end

          :duplicate ->
            {:ok, :duplicate}
        end
    end
  end

  def record_progress(_repo, %Oban.Job{}, _state), do: {:error, :invalid_state}

  defp batch_id(%Oban.Job{meta: meta}) when is_map(meta) do
    Map.get(meta, "batch_id") || Map.get(meta, :batch_id)
  end

  defp batch_id(_job), do: nil

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

  defp timestamp do
    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end
end
