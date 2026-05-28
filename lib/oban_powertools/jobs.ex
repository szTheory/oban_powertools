defmodule ObanPowertools.Jobs do
  @moduledoc """
  Native job query context for the read-only job browse surface.

  This module is the single owner of all `oban_jobs` queries for the Phase 43 job browse
  surface. LiveView never queries the `oban_jobs` table directly — all reads go through this
  module (D-10).

  ## Tags Filtering and GIN Index (D-04)

  Filtering by tags uses the Postgres array containment operator via:

      fragment("? @> ?", j.tags, ^tags)

  Oban does **not** create a GIN index on the `tags` column by default. Without this index,
  tags-filtered queries perform a sequential scan on the state-filtered result set. To enable
  efficient tags filtering, the host application must create the index:

      CREATE INDEX CONCURRENTLY oban_jobs_tags_gin ON oban_jobs USING gin(tags);

  Oban does not create this index. The host application owns it.

  The state-leading composite index `oban_jobs_state_queue_priority_scheduled_at_id_index`
  (created by Oban's standard migration) still applies to every query in this module. The
  sequential scan is bounded to state-filtered rows — never an unfiltered full-table scan.

  ## Keyset Pagination Upgrade Path (D-03)

  `list/3` currently uses offset-based pagination via `limit/offset`. To upgrade to keyset
  pagination, replace the `offset(^offset)` clause with a cursor-based `where` clause:

      where: j.scheduled_at < ^cursor_scheduled_at or
             (j.scheduled_at == ^cursor_scheduled_at and j.id < ^cursor_id)

  This is a single-function change in `Jobs.list/3`. The `%JobFilter{}` struct would gain
  `cursor_scheduled_at` and `cursor_id` fields in place of `page`.

  ## Query Ownership Boundary

  - This module is read-only — it contains no calls to `Oban` runtime functions such as
    `Oban.cancel_job/1`, `Oban.retry_job/1`, or `Oban.drain_queue/2`.
  - Callers pass the repo explicitly (first argument) following the convention established in
    `ObanPowertools.Cron` and `ObanPowertools.Lifeline`.
  - No `defp repo/0` helper is defined in this module.
  """

  import Ecto.Query

  @states ~w(available scheduled executing retryable cancelled discarded completed)

  @typedoc """
  Filter struct for the job browse query layer.

  - `state` — required; the atom state to browse (e.g. `:available`). Converted to a string
    at the WHERE boundary via `to_string/1`.
  - `queue`, `worker`, `tags` — optional narrowing filters; `nil` means "all".
  - `page`, `page_size` — offset pagination controls (D-03).
  """
  @type t :: %__MODULE__{
          state: atom(),
          queue: String.t() | nil,
          worker: String.t() | nil,
          tags: [String.t()] | nil,
          page: pos_integer(),
          page_size: pos_integer()
        }

  defstruct state: :available,
            queue: nil,
            worker: nil,
            tags: nil,
            page: 1,
            page_size: 20

  @doc """
  Lists jobs matching the given filter, ordered by `scheduled_at DESC, id DESC` (D-11).

  State is always the first WHERE predicate (D-05), ensuring the composite index
  `oban_jobs_state_queue_priority_scheduled_at_id_index` applies to every query.

  Optional filters `queue`, `worker`, and `tags` narrow the result set when non-nil.
  Results are paginated using offset-based pagination (D-03); see the module doc for the
  keyset upgrade path.
  """
  def list(repo, %__MODULE__{} = filter, _opts \\ []) do
    offset = (filter.page - 1) * filter.page_size

    Oban.Job
    |> where([j], j.state == ^to_string(filter.state))
    |> maybe_filter_queue(filter.queue)
    |> maybe_filter_worker(filter.worker)
    |> maybe_filter_tags(filter.tags)
    |> order_by([j], [desc: j.scheduled_at, desc: j.id])
    |> limit(^filter.page_size)
    |> offset(^offset)
    |> repo.all()
  end

  @doc """
  Returns the `%Oban.Job{}` with the given `job_id`, or `nil` if not found.
  """
  def get(repo, job_id) do
    repo.get(Oban.Job, job_id)
  end

  @doc """
  Returns a map of job counts keyed by all 7 Oban state strings (D-13).

  The `state` field of `base_filter` is ignored — this function iterates all 7 states and
  returns a count for each. Non-state filters (`queue`, `worker`, `tags`) from `base_filter`
  narrow each per-state count.

  This issues 7 round-trips per filter change, which is acceptable for Phase 43 because each
  query uses the state-leading composite index `oban_jobs_state_queue_priority_scheduled_at_id_index`.

  A single `GROUP BY state` query would miss states with zero counts (D-13) — the map must
  always include all 7 keys, even for states with no matching jobs.
  """
  def count_by_state(repo, %__MODULE__{} = base_filter) do
    Map.new(@states, fn state ->
      count =
        Oban.Job
        |> where([j], j.state == ^state)
        |> maybe_filter_queue(base_filter.queue)
        |> maybe_filter_worker(base_filter.worker)
        |> maybe_filter_tags(base_filter.tags)
        |> select([j], count(j.id))
        |> repo.one()

      {state, count}
    end)
  end

  defp maybe_filter_queue(query, nil), do: query
  defp maybe_filter_queue(query, queue), do: where(query, [j], j.queue == ^queue)

  defp maybe_filter_worker(query, nil), do: query
  defp maybe_filter_worker(query, worker), do: where(query, [j], j.worker == ^worker)

  defp maybe_filter_tags(query, nil), do: query
  defp maybe_filter_tags(query, []), do: query
  defp maybe_filter_tags(query, tags), do: where(query, [j], fragment("? @> ?", j.tags, ^tags))
end
