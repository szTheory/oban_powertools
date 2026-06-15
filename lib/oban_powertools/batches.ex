defmodule ObanPowertools.Batches do
  @moduledoc """
  Native batch query context for the batch operations surface.

  This module owns all Phase 62 batch UI reads. LiveViews call this module for
  list rows, counts, detail data, retry eligibility, callback evidence, and
  blocked-state copy instead of building ad hoc cross-table queries.

  The module is read-only. It must not call job retry, job cancellation, queue
  drain, or other Oban runtime mutation APIs.
  """

  import Ecto.Query

  alias ObanPowertools.{Audit, Batch, BatchJob, Callback, DisplayPolicy}

  @statuses ~w(all inserting executing exhausted insert_failed callback_failed completed)
  @failed_member_states ~w(failed discarded)
  @retryable_job_states ~w(retryable discarded cancelled completed)
  @output_unavailable_copy "A chain step needs upstream output that is missing, expired, or was not recorded. Review the failed callback and retry only after the upstream output contract is corrected."

  defstruct status: :all,
            query: nil,
            chain_only: false,
            queue: nil,
            worker: nil,
            page: 1,
            page_size: 20

  @type t :: %__MODULE__{
          status: atom(),
          query: String.t() | nil,
          chain_only: boolean(),
          queue: String.t() | nil,
          worker: String.t() | nil,
          page: pos_integer(),
          page_size: pos_integer()
        }

  @doc """
  Lists batch rows matching `filter`.

  Pagination is intentionally offset-based for Phase 62. A future keyset upgrade
  can replace the final `Enum.slice/3` with cursor predicates inside this
  function without adding a generic pagination abstraction.
  """
  def list(repo, %__MODULE__{} = filter, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    offset = (normalize_page(filter.page) - 1) * normalize_page_size(filter.page_size)

    filter
    |> base_batch_query()
    |> repo.all()
    |> Enum.map(&list_row(repo, &1, now))
    |> Enum.filter(&matches_member_filters?(&1, filter))
    |> Enum.filter(&matches_chain_filter?(&1, filter))
    |> Enum.slice(offset, normalize_page_size(filter.page_size))
  end

  @doc """
  Returns a detail map for `batch_id`, or `nil`.
  """
  def get(repo, batch_id, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    case repo.get(Batch, batch_id) do
      nil ->
        nil

      %Batch{} = batch ->
        members = failed_members(repo, batch, now)
        callbacks = callback_rows(repo, batch, now)
        callback_summary = summarize_callbacks(callbacks)
        chain_context = chain_context(batch, members, callbacks)

        %{
          id: batch.id,
          batch: batch,
          name: batch.name,
          short_id: short_id(batch.id),
          status: batch.status,
          progress: progress(batch),
          failed_members: members,
          callbacks: callbacks,
          callback_summary: callback_summary,
          chain_context: chain_context,
          blocked_state:
            blocked_state(
              %{
                batch
                | status: output_status(batch.status, callbacks)
              },
              now
            ),
          audit_events: audit_events(repo, batch, callbacks),
          inserted_at: batch.inserted_at,
          updated_at: batch.updated_at,
          completed_at: batch.completed_at
        }
    end
  end

  @doc """
  Counts batches by all UI status keys, including zero-count statuses.
  """
  def count_by_status(repo, %__MODULE__{} = base_filter) do
    counts =
      Map.new(@statuses -- ["all"], fn status ->
        filter = %{
          base_filter
          | status: String.to_existing_atom(status),
            page: 1,
            page_size: 100_000
        }

        {status, list(repo, filter) |> length()}
      end)

    all_filter = %{base_filter | status: :all, page: 1, page_size: 100_000}
    Map.put(counts, "all", list(repo, all_filter) |> length())
  end

  @doc """
  Returns support-truth copy for a batch state or detail-shaped map.
  """
  def blocked_state(batch_or_detail, now \\ DateTime.utc_now())

  def blocked_state(%{status: "insert_failed"} = batch, _now) do
    failure = read_key(batch, :insert_failure) || %{}

    %{
      name: :insert_failed,
      severity: :warning,
      title: "Insertion failed",
      copy:
        "Batch insertion stopped at chunk #{read_key(batch, :insert_failed_chunk) || "unknown"} after #{read_key(batch, :inserted_count) || 0} of #{read_key(batch, :total_count) || 0} jobs were inserted.",
      evidence: %{
        failed_chunk: read_key(batch, :insert_failed_chunk),
        inserted_count: read_key(batch, :inserted_count),
        total_count: read_key(batch, :total_count),
        failure_kind: read_key(failure, :kind),
        failure_message: read_key(failure, :message) || read_key(failure, :reason),
        failed_at: read_key(batch, :insert_failed_at)
      }
    }
  end

  def blocked_state(%{status: "callback_failed"} = batch, now) do
    callbacks = callbacks_from(batch)
    failed = Enum.find(callbacks, &(&1.status == "failed")) || List.first(callbacks)

    %{
      name: :callback_failed,
      severity: :warning,
      title: "Callback failed",
      copy: callback_failed_copy(failed, now),
      evidence: failed || %{}
    }
  end

  def blocked_state(%{status: "output_unavailable"} = state, _now) do
    %{
      name: :output_unavailable,
      severity: :warning,
      title: "Upstream output unavailable",
      copy: @output_unavailable_copy,
      evidence:
        Map.take(state, [:upstream_job_id, :chain_step_name, :chain_step_index, :chain_step_count])
    }
  end

  def blocked_state(%{status: "output_expired"} = state, _now) do
    %{
      name: :output_expired,
      severity: :warning,
      title: "Upstream output expired",
      copy: @output_unavailable_copy,
      evidence:
        Map.take(state, [:upstream_job_id, :chain_step_name, :chain_step_index, :chain_step_count])
    }
  end

  def blocked_state(%{status: "executing"} = batch, _now) do
    remaining = max((read_key(batch, :total_count) || 0) - completed_count(batch), 0)

    %{
      name: :executing,
      severity: :neutral,
      title: "Executing",
      copy: "#{remaining} jobs remain before this batch can complete.",
      evidence: %{remaining_count: remaining}
    }
  end

  def blocked_state(%{status: "exhausted"} = batch, _now) do
    %{
      name: :exhausted,
      severity: :warning,
      title: "Exhausted",
      copy:
        "Batch execution exhausted with #{read_key(batch, :discard_count) || 0} discarded or failed members.",
      evidence: %{discard_count: read_key(batch, :discard_count) || 0}
    }
  end

  def blocked_state(%{status: "completed"} = batch, _now) do
    %{
      name: :completed,
      severity: :success,
      title: "Completed",
      copy: "Batch completed successfully.",
      evidence: %{completed_at: read_key(batch, :completed_at)}
    }
  end

  def blocked_state(%{status: "inserting"} = batch, _now) do
    %{
      name: :inserting,
      severity: :neutral,
      title: "Inserting",
      copy: "Batch insertion is still in progress.",
      evidence: %{inserted_count: read_key(batch, :inserted_count) || 0}
    }
  end

  def blocked_state(%{status: status}, _now) do
    %{
      name: status_name(status),
      severity: :neutral,
      title: humanize(status),
      copy: "Batch state is #{status}.",
      evidence: %{}
    }
  end

  defp base_batch_query(filter) do
    Batch
    |> maybe_filter_status(filter.status)
    |> maybe_filter_query(filter.query)
    |> order_by([batch], desc: batch.updated_at, desc: batch.inserted_at, desc: batch.id)
  end

  defp maybe_filter_status(query, :all), do: query
  defp maybe_filter_status(query, "all"), do: query
  defp maybe_filter_status(query, nil), do: query

  defp maybe_filter_status(query, status) when is_atom(status),
    do: where(query, [batch], batch.status == ^Atom.to_string(status))

  defp maybe_filter_status(query, status) when is_binary(status),
    do: where(query, [batch], batch.status == ^status)

  defp maybe_filter_query(query, nil), do: query
  defp maybe_filter_query(query, ""), do: query

  defp maybe_filter_query(query, query_text) do
    pattern = "%#{query_text}%"

    where(
      query,
      [batch],
      ilike(batch.name, ^pattern) or fragment("?::text ILIKE ?", batch.id, ^pattern)
    )
  end

  defp list_row(repo, %Batch{} = batch, now) do
    members = failed_members(repo, batch, now)
    callbacks = callback_rows(repo, batch, now)
    callback_summary = summarize_callbacks(callbacks)
    chain_context = chain_context(batch, members, callbacks)
    member_filters = member_filter_values(repo, batch)
    status = output_status(batch.status, callbacks)

    blocked =
      blocked_state(
        Map.put(batch_map(batch), :status, status) |> Map.put(:callbacks, callbacks),
        now
      )

    %{
      id: batch.id,
      name: batch.name,
      short_id: short_id(batch.id),
      status: batch.status,
      progress: progress(batch),
      total_count: batch.total_count,
      success_count: batch.success_count,
      discard_count: batch.discard_count,
      failed_count: length(members),
      retryable_failed_count: Enum.count(members, & &1.retry_eligible?),
      callback_summary: callback_summary,
      updated_at: batch.updated_at,
      inserted_at: batch.inserted_at,
      completed_at: batch.completed_at,
      chain?: chain_context.chain? || false,
      chain_context: chain_context,
      blocked_state: blocked,
      queues: member_filters.queues,
      workers: member_filters.workers
    }
  end

  defp failed_members(repo, %Batch{} = batch, _now) do
    rows =
      repo.all(
        from(member in BatchJob,
          left_join: job in Oban.Job,
          on: job.id == member.job_id,
          where: member.batch_id == ^batch.id,
          order_by: [asc: member.inserted_at, asc: member.job_id],
          select: {member, job}
        )
      )

    rows
    |> Enum.filter(fn {member, job} -> failed_member?(member, job) end)
    |> Enum.map(fn {member, job} -> member_row(member, job) end)
  end

  defp member_row(%BatchJob{} = member, %Oban.Job{} = job) do
    context = %{surface: :batches, job: job}

    %{
      batch_job_id: member.id,
      batch_member_state: member.state,
      job_id: job.id,
      worker: job.worker,
      queue: job.queue,
      oban_state: job.state,
      attempt: job.attempt,
      max_attempts: job.max_attempts,
      last_error: last_job_error(job),
      last_error_display:
        DisplayPolicy.render_job_field(:job_error, last_job_error(job), context),
      args_display: DisplayPolicy.render_job_field(:job_args, job.args, context),
      meta_display: DisplayPolicy.render_job_field(:job_meta, job.meta, context),
      bridge_path: "/ops/jobs/oban/jobs/#{job.id}",
      retry_eligible?: retryable_member?(member, job),
      chain_context: chain_context_from_job(job)
    }
  end

  defp member_row(%BatchJob{} = member, nil) do
    %{
      batch_job_id: member.id,
      batch_member_state: member.state,
      job_id: member.job_id,
      worker: nil,
      queue: nil,
      oban_state: nil,
      attempt: nil,
      max_attempts: nil,
      last_error: nil,
      last_error_display: DisplayPolicy.render_job_field(:job_error, nil, %{}),
      args_display: DisplayPolicy.render_job_field(:job_args, %{}, %{}),
      meta_display: DisplayPolicy.render_job_field(:job_meta, %{}, %{}),
      bridge_path: "/ops/jobs/oban/jobs/#{member.job_id}",
      retry_eligible?: false,
      chain_context: %{}
    }
  end

  defp member_filter_values(repo, %Batch{} = batch) do
    repo.all(
      from(member in BatchJob,
        left_join: job in Oban.Job,
        on: job.id == member.job_id,
        where: member.batch_id == ^batch.id,
        select: job
      )
    )
    |> Enum.reduce(%{queues: [], workers: []}, fn
      %Oban.Job{} = job, acc ->
        %{
          acc
          | queues: maybe_cons(job.queue, acc.queues),
            workers: maybe_cons(job.worker, acc.workers)
        }

      nil, acc ->
        acc
    end)
    |> Map.update!(:queues, &Enum.uniq/1)
    |> Map.update!(:workers, &Enum.uniq/1)
  end

  defp failed_member?(%BatchJob{state: state}, %Oban.Job{state: job_state}) do
    state in @failed_member_states or job_state in @failed_member_states
  end

  defp failed_member?(%BatchJob{state: state}, nil), do: state in @failed_member_states

  defp retryable_member?(%BatchJob{state: member_state}, %Oban.Job{state: job_state}) do
    member_state in @failed_member_states and job_state in @retryable_job_states
  end

  defp callback_rows(repo, %Batch{} = batch, now) do
    repo.all(
      from(callback in Callback,
        where: callback.batch_id == ^batch.id,
        order_by: [asc: callback.available_at, asc: callback.inserted_at, asc: callback.id]
      )
    )
    |> Enum.map(&callback_row(&1, now))
  end

  defp callback_row(%Callback{} = callback, now) do
    context = %{surface: :batches, callback: callback}

    %{
      id: callback.id,
      event: callback.event,
      dedupe_key: callback.dedupe_key,
      status: callback.status,
      attempts: callback.attempts,
      available_at: callback.available_at,
      claimed_at: callback.claimed_at,
      claimed_by: callback.claimed_by,
      lease_expires_at: callback.lease_expires_at,
      delivered_at: callback.delivered_at,
      last_error: callback.last_error,
      last_error_display:
        DisplayPolicy.render_job_field(:callback_error, callback.last_error, context),
      payload_display:
        DisplayPolicy.render_job_field(:callback_payload, callback.payload, context),
      retry_eligible?: callback_retry_eligible?(callback, now),
      chain_context: chain_context_from_map(callback.payload || %{}),
      batch_id: callback.batch_id
    }
  end

  defp summarize_callbacks(callbacks) do
    base = %{total: length(callbacks), pending: 0, failed: 0, claimed: 0, delivered: 0, stuck: 0}

    Enum.reduce(callbacks, base, fn callback, acc ->
      acc
      |> Map.update(callback.status |> String.to_atom(), 1, &(&1 + 1))
      |> Map.update!(:stuck, fn count ->
        if callback.retry_eligible?, do: count + 1, else: count
      end)
    end)
  end

  defp callback_retry_eligible?(%Callback{} = callback, now) do
    callback.status == "failed" or
      (callback.status == "claimed" and not is_nil(callback.lease_expires_at) and
         DateTime.compare(callback.lease_expires_at, now) != :gt)
  end

  defp chain_context(batch, members, callbacks) do
    contexts =
      [chain_context_from_map(batch_map(batch))]
      |> Kernel.++(Enum.map(members, & &1.chain_context))
      |> Kernel.++(Enum.map(callbacks, & &1.chain_context))
      |> Enum.filter(&(map_size(&1) > 0))

    merged = Enum.reduce(contexts, %{}, &Map.merge(&2, &1, fn _key, old, new -> new || old end))

    Map.put(merged, :chain?, Map.has_key?(merged, :chain_id) and not is_nil(merged.chain_id))
  end

  defp chain_context_from_job(%Oban.Job{} = job) do
    job.meta
    |> Kernel.||(%{})
    |> Map.merge(job.args || %{}, fn _key, meta_value, args_value -> meta_value || args_value end)
    |> chain_context_from_map()
  end

  defp chain_context_from_map(map) when is_map(map) do
    %{
      chain_id: read_key(map, :chain_id),
      chain_step_name: read_key(map, :chain_step_name),
      chain_step_index: read_key(map, :chain_step_index),
      chain_step_count: read_key(map, :chain_step_count),
      upstream_job_id: read_key(map, :upstream_job_id),
      next_step: read_key(map, :next_step)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp matches_member_filters?(_row, %__MODULE__{queue: nil, worker: nil}), do: true

  defp matches_member_filters?(row, %__MODULE__{} = filter) do
    queue_match? = is_nil(filter.queue) or filter.queue in row.queues
    worker_match? = is_nil(filter.worker) or filter.worker in row.workers
    queue_match? and worker_match?
  end

  defp matches_chain_filter?(row, %__MODULE__{chain_only: true}), do: row.chain?
  defp matches_chain_filter?(_row, _filter), do: true

  defp audit_events(repo, %Batch{} = batch, callbacks) do
    batch_events = Audit.list(%{type: :batch, id: batch.id}, repo: repo)

    callback_events =
      callbacks
      |> Enum.flat_map(fn callback ->
        Audit.list(%{type: :callback, id: callback.id}, repo: repo)
      end)

    Enum.uniq_by(batch_events ++ callback_events, & &1.id)
  end

  defp progress(%Batch{} = batch) do
    completed = completed_count(batch)
    total = max(batch.total_count || 0, 0)
    percent = if total == 0, do: 0, else: Float.round(completed / total * 100, 1)

    %{
      total_count: total,
      success_count: batch.success_count || 0,
      discard_count: batch.discard_count || 0,
      cancelled_count: batch.cancelled_count || 0,
      snooze_count: batch.snooze_count || 0,
      inserted_count: batch.inserted_count || 0,
      completed_count: completed,
      percent: percent
    }
  end

  defp completed_count(batch) do
    (read_key(batch, :success_count) || 0) + (read_key(batch, :discard_count) || 0)
  end

  defp callback_failed_copy(nil, _now), do: "A failed callback is blocking this batch."

  defp callback_failed_copy(callback, _now) do
    "A failed callback is blocking this batch: #{read_key(callback, :event) || "unknown event"} #{read_key(callback, :dedupe_key) || ""} after #{read_key(callback, :attempts) || 0} attempts."
  end

  defp output_status(status, callbacks) do
    cond do
      Enum.any?(callbacks, &String.contains?(to_string(&1.last_error), "output_expired")) ->
        "output_expired"

      Enum.any?(callbacks, &String.contains?(to_string(&1.last_error), "output_unavailable")) ->
        "output_unavailable"

      true ->
        status
    end
  end

  defp callbacks_from(%{callbacks: callbacks}) when is_list(callbacks), do: callbacks
  defp callbacks_from(_), do: []

  defp batch_map(%Batch{} = batch) do
    %{
      id: batch.id,
      name: batch.name,
      status: batch.status,
      total_count: batch.total_count,
      success_count: batch.success_count,
      discard_count: batch.discard_count,
      cancelled_count: batch.cancelled_count,
      snooze_count: batch.snooze_count,
      inserted_count: batch.inserted_count,
      insert_chunk_count: batch.insert_chunk_count,
      insert_failed_chunk: batch.insert_failed_chunk,
      insert_failure: batch.insert_failure,
      insert_failed_at: batch.insert_failed_at,
      completed_at: batch.completed_at,
      inserted_at: batch.inserted_at,
      updated_at: batch.updated_at
    }
  end

  defp last_job_error(%Oban.Job{errors: errors}) when is_list(errors) do
    errors
    |> List.last()
    |> case do
      nil -> nil
      %{"error" => error} -> error
      %{error: error} -> error
      other -> inspect(other)
    end
  end

  defp short_id(id) when is_binary(id), do: String.slice(id, 0, 8)
  defp short_id(id), do: to_string(id)

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_page), do: 1

  defp normalize_page_size(page_size) when is_integer(page_size) and page_size > 0,
    do: min(page_size, 100_000)

  defp normalize_page_size(_page_size), do: 20

  defp status_name(status) when is_atom(status), do: status
  defp status_name(status) when is_binary(status), do: String.to_atom(status)
  defp status_name(_status), do: :unknown

  defp humanize(status) do
    status
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp read_key(map, key) when is_map(map) do
    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, Atom.to_string(key)) -> Map.get(map, Atom.to_string(key))
      true -> nil
    end
  end

  defp read_key(_value, _key), do: nil

  defp maybe_cons(nil, values), do: values
  defp maybe_cons(value, values), do: [value | values]
end
