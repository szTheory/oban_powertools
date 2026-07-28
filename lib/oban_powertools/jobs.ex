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

  Active-state list, count, and ID-window queries retain Oban's state predicate and stable
  order. Grouped state counts intentionally omit one active state so all seven states can be
  counted in a single query while retaining every optional predicate.

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

  @page_size 20
  @zero_state_counts %{
    "available" => 0,
    "scheduled" => 0,
    "executing" => 0,
    "retryable" => 0,
    "cancelled" => 0,
    "discarded" => 0,
    "completed" => 0
  }

  @typedoc """
  Filter struct for the job browse query layer.

  - `state` — required; the atom state to browse (e.g. `:available`). Converted to a string
    at the WHERE boundary via `to_string/1`.
  - `queue`, `worker`, `tags`, `args`, `meta` — optional narrowing filters; `nil` means "all".
  - `page` — offset page number.
  - `page_size` — retained struct metadata; list queries always use the fixed 20-row contract.
  """
  @type t :: %__MODULE__{
          state: atom(),
          queue: String.t() | nil,
          worker: String.t() | nil,
          tags: [String.t()] | nil,
          args: map() | nil,
          meta: map() | nil,
          page: pos_integer(),
          page_size: pos_integer()
        }

  defstruct state: :available,
            queue: nil,
            worker: nil,
            tags: nil,
            args: nil,
            meta: nil,
            page: 1,
            page_size: 20

  @doc """
  Lists jobs matching the given filter, ordered by `scheduled_at DESC, id DESC` (D-11).

  State and optional `queue`, `worker`, `tags`, `args`, and `meta` predicates are ANDed.
  Results use the fixed 20-row offset-page contract.
  """
  def list(repo, %__MODULE__{} = filter, opts \\ []) do
    offset = (filter.page - 1) * @page_size

    active_query(filter)
    |> order_by([j], desc: j.scheduled_at, desc: j.id)
    |> limit(^@page_size)
    |> offset(^offset)
    |> repo.all(opts)
  end

  @doc """
  Returns just the IDs of all jobs matching the given filter, without pagination limit.
  Useful for cross-page bulk operations.
  """
  def list_ids(repo, %__MODULE__{} = filter) do
    active_query(filter)
    |> select([j], j.id)
    |> repo.all()
  end

  @doc """
  Returns the exact count for the active state and all optional filters.
  """
  def count(repo, %__MODULE__{} = filter, opts \\ []) do
    active_query(filter)
    |> select([j], count(j.id))
    |> repo.one(opts)
  end

  @doc """
  Returns a stable bounded ID window for the active filter.

  The query reads at most `limit + 1` IDs in fixed `scheduled_at DESC, id DESC`
  order. The extra ID is used only to report overflow and is never returned in
  the executable scope.
  """
  def ordered_ids_window(repo, filter, limit, opts \\ [])

  def ordered_ids_window(repo, %__MODULE__{} = filter, limit, opts)
      when is_integer(limit) and limit > 0 do
    ids =
      active_query(filter)
      |> order_by([j], desc: j.scheduled_at, desc: j.id)
      |> select([j], j.id)
      |> limit(^(limit + 1))
      |> repo.all(opts)

    %{
      ids: Enum.take(ids, limit),
      overflow?: length(ids) > limit
    }
  end

  def ordered_ids_window(_repo, %__MODULE__{}, _limit, _opts) do
    raise ArgumentError, "limit must be a positive integer"
  end

  defp active_query(%__MODULE__{} = filter) do
    filter
    |> non_state_query()
    |> where([j], j.state == ^to_string(filter.state))
  end

  defp non_state_query(%__MODULE__{} = filter) do
    Oban.Job
    |> maybe_filter_queue(filter.queue)
    |> maybe_filter_worker(filter.worker)
    |> maybe_filter_tags(filter.tags)
    |> maybe_filter_args(filter.args)
    |> maybe_filter_meta(filter.meta)
  end

  @doc """
  Returns the `%Oban.Job{}` with the given `job_id`, or `nil` if not found.
  """
  def get(repo, job_id) do
    repo.get(Oban.Job, job_id)
  end

  @doc """
  Returns a map of job counts keyed by all seven Oban state strings.

  The filter's `state` is ignored. One grouped query applies the shared non-state
  predicates, and its result is merged into a literal seven-state zero map.
  """
  def count_by_state(repo, %__MODULE__{} = base_filter) do
    count_by_state(repo, base_filter, [])
  end

  def count_by_state(repo, %__MODULE__{} = base_filter, opts) when is_list(opts) do
    grouped_counts =
      base_filter
      |> non_state_query()
      |> group_by([j], j.state)
      |> select([j], {j.state, count(j.id)})
      |> repo.all(opts)
      |> Map.new()

    Map.merge(@zero_state_counts, grouped_counts)
  end

  defp maybe_filter_queue(query, nil), do: query
  defp maybe_filter_queue(query, queue), do: where(query, [j], j.queue == ^queue)

  defp maybe_filter_worker(query, nil), do: query
  defp maybe_filter_worker(query, worker), do: where(query, [j], j.worker == ^worker)

  defp maybe_filter_tags(query, nil), do: query
  defp maybe_filter_tags(query, []), do: query
  defp maybe_filter_tags(query, tags), do: where(query, [j], fragment("? @> ?", j.tags, ^tags))

  defp maybe_filter_args(query, nil), do: query
  defp maybe_filter_args(query, args) when args == %{}, do: query

  defp maybe_filter_args(query, args),
    do: where(query, [j], fragment("? @> ?", j.args, type(^args, :map)))

  defp maybe_filter_meta(query, nil), do: query
  defp maybe_filter_meta(query, meta) when meta == %{}, do: query

  defp maybe_filter_meta(query, meta),
    do: where(query, [j], fragment("? @> ?", j.meta, type(^meta, :map)))
end
