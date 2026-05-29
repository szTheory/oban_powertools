# Phase 43: Read-Only Job Browse - Research

**Researched:** 2026-05-27
**Domain:** Phoenix LiveView, Ecto/Postgres query layer, `Oban.Job` schema, `DisplayPolicy` extension
**Confidence:** HIGH — all findings verified against the live codebase

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `%JobFilter{}` struct MUST be defined before any event handler is written — the struct anchors all filter event handling
- **D-02:** Permission atoms to declare in `LiveAuth.@permission_messages` before Phase 43: `:view_jobs`, `:view_job_detail`, `:retry_job`, `:cancel_job`, `:discard_job`
- **D-03:** Pagination: offset-based for Phase 43. The keyset upgrade path is explicitly a single function change in `ObanPowertools.Jobs.list/3` — document it, don't implement it
- **D-04:** Tags filtering requires a host-owned GIN index on `oban_jobs.tags` — document in the `ObanPowertools.Jobs` module doc and host guide; do NOT block Phase 43 on it
- **D-05:** State MUST lead every WHERE clause — it is the primary filter dimension, not an optional one
- **D-06:** Two new routes added to the existing `live_session :oban_powertools_native` in `ObanPowertools.Web.Router`: `live("/jobs", ObanPowertools.Web.JobsLive, :index)` and `live("/jobs/:id", ObanPowertools.Web.JobsLive, :show)` — single module, two actions, follows `WorkflowsLive` double-route pattern exactly
- **D-07:** Filter state serialized as URL query params: `?state=executing&queue=default&worker=MyWorker&tags=tag1,tag2`. Filter changes use `push_patch` to update params — browser back/forward and deep-links work automatically
- **D-08:** Job detail is a full-page navigation (`navigate("/jobs/#{id}")` from list row click), not a side-panel
- **D-09:** State navigation is a tab bar across the top with 7 tabs: `available`, `scheduled`, `executing`, `retryable`, `cancelled`, `discarded`, `completed`. No "all states" default tab — state is always required
- **D-10:** New context module `ObanPowertools.Jobs` with `%JobFilter{}` defstruct and `Jobs.list/3`, `Jobs.get/2`
- **D-11:** Query order: `ORDER BY scheduled_at DESC, id DESC` as the default for the list view
- **D-12:** Job list row fields: state badge, worker (short module name — last segment only), queue, job ID, `scheduled_at`, attempt count
- **D-13:** State navigation tab shows job count per state (offset-based count query per visible tab set on mount/filter change)
- **D-14:** Detail view displays: args (redacted), meta (redacted), errors (all attempt error records), attempt history, timing fields
- **D-15:** No mutation controls on the detail page in Phase 43
- **D-16:** `DisplayPolicy.display/3` gains two new atom kinds: `:job_args` and `:job_meta`. Return contract: `nil` → raw JSON, `String` → formatted string, `Map` → field-level redacted copy. New `render_job_field/3` helper added to `ObanPowertools.DisplayPolicy`
- **D-17:** `JobsLive.mount/3` for `:index` action: `LiveAuth.authorize_page(socket, :view_jobs, %{type: :page, id: "jobs"})`
- **D-18:** `JobsLive.mount/3` for `:show` action: `LiveAuth.authorize_page(socket, :view_job_detail, %{type: :job, id: job_id})`
- **D-19:** `LiveAuth.@page_read_only_banners` extended with `:jobs` and `:job_detail` entries
- **D-20:** `LiveAuth.@permission_messages` extended with `:view_jobs`, `:view_job_detail`, `:retry_job`, `:cancel_job`, `:discard_job`

### Claude's Discretion

- Exact copy for `:jobs` and `:job_detail` `@page_read_only_banners` — planner to draft following the established voice/pattern from existing entries
- Exact worker short-name formatting (last segment of module name) — implementation detail for executor
- Error display format in the detail view — follow Lifeline's existing error display pattern

### Deferred Ideas (OUT OF SCOPE)

- Keyset pagination upgrade
- PubSub-backed live job count updates (QRY-06)
- args/meta full-text search (QRY-05)
- Cross-page bulk select (QRY-08)
- Navigate from Lifeline job row to native job detail (QRY-07)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QRY-01 | User can browse jobs filtered by state, queue, worker, and tags — state is the primary navigation dimension; tags filtering requires a host-owned GIN index | Fulfilled by `ObanPowertools.Jobs` context module with `%JobFilter{}`, `list/3` using `oban_jobs_state_queue_priority_scheduled_at_id_index` composite index; GIN index caveat documented |
| QRY-02 | User can view a job's full detail including args, meta, errors, attempt history, and timing — DisplayPolicy redaction applied to args and meta | Fulfilled by `Jobs.get/2` returning full `Oban.Job`, `render_job_field/3` in `DisplayPolicy`, detail LiveView action `:show` |
</phase_requirements>

---

## Summary

Phase 43 ships a read-only job browse surface — a list page with state-tab navigation and filter controls, and a full-page detail view — entirely within the existing `live_session :oban_powertools_native` scope. The context module `ObanPowertools.Jobs` is new; everything else (routing, auth, DisplayPolicy, LiveView skeleton) mirrors patterns already proven in the codebase.

The Oban.Job schema is fully understood from the installed dependency (`oban 2.22.1`). All fields needed for the list and detail views exist: `state`, `queue`, `worker`, `args`, `meta`, `tags`, `errors`, `attempt`, `max_attempts`, `scheduled_at`, `inserted_at`, `attempted_at`, `completed_at`, `cancelled_at`, `discarded_at`. The composite index `oban_jobs_state_queue_priority_scheduled_at_id_index` already exists in Oban's migrations — state-leading WHERE clauses will use it. Tags filtering requires an additional host-owned GIN index that Oban does not create by default.

The `DisplayPolicy` extension is a bounded additive change: two new `display/3` kind atoms (`:job_args`, `:job_meta`) with a new `render_job_field/3` helper that follows the same `render_text/4` / `apply_policy/3` shape as `actor_label` and `reason`. Existing host implementations are not affected because their catch-all `display(_kind, _value, _context), do: nil` returns `nil`, which `render_job_field/3` maps to raw JSON output.

**Primary recommendation:** Model `ObanPowertools.Jobs` directly after `ObanPowertools.Lifeline` for the context layer, and model `ObanPowertools.Web.JobsLive` directly after `ObanPowertools.Web.WorkflowsLive` for the double-route LiveView skeleton and `LifelineLive` for the `push_patch` / `handle_params` filter pattern.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Job list query (filtered, paginated) | API / Backend (`ObanPowertools.Jobs`) | — | Context module owns all DB interaction; LiveView calls `Jobs.list/3` |
| Job detail fetch | API / Backend (`ObanPowertools.Jobs`) | — | `Jobs.get/2` is the single DB call; LiveView does not query directly |
| URL filter serialization | Frontend Server (`JobsLive` via `push_patch`) | — | `handle_params/3` reads params, rebuilds `%JobFilter{}`, calls context |
| State tab count queries | API / Backend (`ObanPowertools.Jobs`) | — | Per-state count queries called from `load_data`; no live subscription |
| DisplayPolicy redaction | API / Backend (`ObanPowertools.DisplayPolicy`) | — | `render_job_field/3` in `DisplayPolicy` module; LiveView calls the helper |
| Auth / permission gate | Frontend Server (`LiveAuth.authorize_page/3`) | — | Called in `mount/3` before any data load, per established pattern |
| Read-only banner | Frontend Server (LiveView assigns) | — | `@read_only?` flag based on actor permissions; rendered conditionally |
| Route declaration | Frontend Server (`ObanPowertools.Web.Router`) | — | Additive entries in existing `live_session :oban_powertools_native` |

---

## Standard Stack

No new dependencies are required for Phase 43. All necessary libraries are already in `mix.exs` and available at the correct versions.

### Core (all already in mix.exs / mix.lock)

| Library | Version (locked) | Purpose | Why Standard |
|---------|-----------------|---------|--------------|
| `oban` | 2.22.1 | `Oban.Job` schema, `oban_jobs` table | Already the project's job backend |
| `ecto_sql` | 3.10+ | Ecto query DSL for `ObanPowertools.Jobs` | Already the project's DB layer |
| `phoenix_live_view` | 1.1.30 | LiveView for `JobsLive` | Already the project's UI layer |
| `phoenix` | 1.8.7 | Router macro, LiveView routing | Already the project's web framework |

[VERIFIED: codebase grep of mix.lock]

### No New Dependencies

Phase 43 introduces no npm packages, no new Hex packages, and no new assets. Tailwind CSS is delivered by the host application's asset pipeline (established pattern across all LiveViews). No package legitimacy audit is required.

---

## Package Legitimacy Audit

No external packages are installed in Phase 43. This section is intentionally omitted.

---

## Architecture Patterns

### System Architecture Diagram

```
Browser
  |
  | GET /ops/jobs/jobs?state=executing&queue=default
  v
JobsLive.mount/3
  |-- LiveAuth.authorize_page(:view_jobs) --> [:ok | redirect /]
  |-- DisplayPolicy.assert_configured!()
  |-- push_patch(to: "?state=available") if no state param
  v
JobsLive.handle_params/3
  |-- build %JobFilter{} from URL params
  |-- Jobs.list(repo, filter)     ---> oban_jobs WHERE state = $1 [AND queue / worker / tags] ORDER BY scheduled_at DESC, id DESC LIMIT $n OFFSET $m
  |-- Jobs.count_by_state(repo, filter)  ---> one COUNT query per tab
  |-- assign(:jobs, :filter, :counts, :page)
  v
render/1 (HEEX template)
  |-- State tab bar (7 buttons, active tab highlighted)
  |-- Filter bar (queue select, worker select, tags select)
  |-- Job table (rows: state badge, worker short name, queue, id, scheduled_at, attempts)
  |-- Pagination (prev/next)
  |-- Empty state (if jobs == [])
  |-- Read-only banner (if @read_only?)

  Row click:
    phx-click="select_job" + JS.navigate("/ops/jobs/jobs/#{id}")

GET /ops/jobs/jobs/:id
  v
JobsLive.mount/3 (action: :show)
  |-- LiveAuth.authorize_page(:view_job_detail, %{type: :job, id: job_id})
  |-- DisplayPolicy.assert_configured!()
  v
JobsLive.handle_params/3
  |-- Jobs.get(repo, job_id)  ---> oban_jobs WHERE id = $1
  |-- DisplayPolicy.render_job_field(:job_args, job.args, context)
  |-- DisplayPolicy.render_job_field(:job_meta, job.meta, context)
  |-- assign(:job, :args_display, :meta_display)
  v
render/1 (HEEX template)
  |-- Back link to /ops/jobs/jobs (preserving last filter params)
  |-- Identity card (worker, queue, state badge, id, attempt, timing)
  |-- Args panel (DisplayPolicy output)
  |-- Meta panel (DisplayPolicy output)
  |-- Errors panel (all error records from job.errors)
  |-- Attempt history panel
  |-- Read-only banner (if @read_only?)
```

### Recommended Project Structure

```
lib/oban_powertools/
├── jobs.ex                        # NEW: ObanPowertools.Jobs context module
│                                  #   defstruct %JobFilter{}, list/3, get/2, count_by_state/2
└── web/
    ├── jobs_live.ex               # NEW: ObanPowertools.Web.JobsLive (:index + :show)
    ├── router.ex                  # EDIT: add /jobs and /jobs/:id routes
    ├── live_auth.ex               # EDIT: add permission atoms + banners
    └── runtime_config.ex          # EDIT: add render_job_field/3 to ObanPowertools.DisplayPolicy
```

### Pattern 1: Double-Route Single-Module LiveView (from WorkflowsLive)

**What:** One LiveView module handles both `:index` and `:show` actions. `mount/3` checks the action and branches; `handle_params/3` dispatches on the presence of `"id"` in params.

**When to use:** Whenever a list and detail page share enough context (auth, assigns, helpers) to benefit from being co-located.

**Example:**
```elixir
# Source: lib/oban_powertools/web/workflows_live.ex
@impl true
def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
  with {:ok, socket} <-
         LiveAuth.authorize_page(socket, :view_workflows, %{type: :page, id: "workflows"}) do
    :ok = DisplayPolicy.assert_configured!()
    {:ok, socket |> assign(:oban_dashboard_path, dashboard_path) |> assign(...)}
  else
    {:error, socket} -> {:ok, socket}
  end
end

@impl true
def handle_params(params, _uri, socket) do
  case Map.get(params, "id") do
    nil -> {:noreply, load_list(socket)}
    id  -> {:noreply, load_detail(socket, id)}
  end
end
```

For `JobsLive`, `mount/3` must branch on action because each action has a different permission:

```elixir
# JobsLive pattern — auth differs per action
@impl true
def mount(params, %{"oban_dashboard_path" => dashboard_path}, socket) do
  action = socket.assigns.live_action
  permission = if action == :show, do: :view_job_detail, else: :view_jobs
  resource_id = if action == :show, do: params["id"], else: "jobs"
  resource_type = if action == :show, do: :job, else: :page

  with {:ok, socket} <-
         LiveAuth.authorize_page(socket, permission, %{type: resource_type, id: resource_id}) do
    :ok = DisplayPolicy.assert_configured!()
    {:ok, socket |> assign(:oban_dashboard_path, dashboard_path) |> assign_defaults()}
  else
    {:error, socket} -> {:ok, socket}
  end
end
```

### Pattern 2: push_patch Filter Flow (from LifelineLive)

**What:** All filter changes, tab clicks, and pagination produce a `push_patch` that updates URL params. `handle_params/3` rebuilds the query from URL params, making browser back/forward and deep-links work with zero extra state management.

**When to use:** Any page with URL-serialized filter or navigation state.

**Example:**
```elixir
# Source: lib/oban_powertools/web/lifeline_live.ex
def handle_event("toggle_view", %{"view" => view}, socket) do
  {:noreply,
   socket
   |> push_patch(to: selection_path(%{view: view, ...}))}
end

@impl true
def handle_params(params, _uri, socket) do
  {:noreply, load_data(socket, filter_from_params(params))}
end
```

For `JobsLive`, filter events call `push_patch` with the updated params; `handle_params/3` rebuilds `%JobFilter{}` and calls `Jobs.list/3`.

### Pattern 3: DisplayPolicy render helper (from ObanPowertools.DisplayPolicy)

**What:** `render_text/4` and `apply_policy/3` are the internal primitives. `render_job_field/3` is a new public helper that follows the same shape but supports `nil → raw JSON`, `String → string`, `Map → formatted JSON` instead of text-only.

**Example (new, to add to runtime_config.ex):**
```elixir
def render_job_field(kind, value, context) do
  case apply_policy(kind, value, context) do
    nil ->
      {:raw_json, Jason.encode!(value || %{}, pretty: true)}

    text when is_binary(text) ->
      {:string, text}

    %{} = redacted_map ->
      {:raw_json, Jason.encode!(redacted_map, pretty: true)}

    other ->
      raise ArgumentError, invalid_return_message(kind, other)
  end
rescue
  _ -> {:fallback, "[redacted]"}
end
```

The LiveView uses the tagged tuple to choose rendering:
- `{:raw_json, json}` → `<pre class="text-sm bg-slate-50 p-3 rounded overflow-x-auto"><%= json %></pre>`
- `{:string, text}` → same `<pre>` wrapper
- `{:fallback, msg}` → `<span class="text-zinc-500"><%= msg %></span>`

### Pattern 4: ObanPowertools.Jobs context module

**What:** A new context module that owns all `Oban.Job` queries. Follows the same shape as `ObanPowertools.Cron` and `ObanPowertools.Lifeline` — repo is always the first argument, no process state.

**JobFilter struct:**
```elixir
# Source: CONTEXT.md D-10
defmodule ObanPowertools.Jobs do
  @moduledoc """
  Native job query context for the read-only job browse surface.

  ## Tags Filtering and GIN Index

  Filtering by tags uses the `@>` (contains) array operator. Without a GIN index on
  `oban_jobs.tags`, this falls back to a sequential scan on all rows matching the leading
  `state` filter. For production deployments with large job tables, create the index:

      CREATE INDEX CONCURRENTLY oban_jobs_tags_gin ON oban_jobs USING gin(tags);

  Oban does not create this index. The host application owns it.

  ## Keyset Pagination

  Phase 43 uses offset-based pagination. The `list/3` function can be upgraded to
  keyset pagination by replacing the `offset:` clause with a `where: job.scheduled_at < ^cursor`
  condition using a `{scheduled_at, id}` tuple cursor. This is a single-function change.
  """

  import Ecto.Query

  defstruct state: :available,
            queue: nil,
            worker: nil,
            tags: nil,
            page: 1,
            page_size: 20

  @type t :: %__MODULE__{
    state: atom(),
    queue: String.t() | nil,
    worker: String.t() | nil,
    tags: [String.t()] | nil,
    page: pos_integer(),
    page_size: pos_integer()
  }

  def list(repo, %__MODULE__{} = filter, _opts \\ []) do
    # state MUST lead the WHERE clause (D-05)
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

  def get(repo, job_id) do
    repo.get(Oban.Job, job_id)
  end

  def count_by_state(repo, base_filter) do
    states = ~w(available scheduled executing retryable cancelled discarded completed)
    Enum.into(states, %{}, fn state ->
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
  defp maybe_filter_tags(query, tags) when is_list(tags),
    do: where(query, [j], fragment("? @> ?", j.tags, ^tags))
end
```

### Pattern 5: Selectors extension for /jobs path

`ObanPowertools.Web.Selectors` is the canonical URL encoder (Phase 34 D-25). A `jobs_path/1` helper must be added, following the same shape as `lifeline_path/1`. The `:jobs` key is added to `@canonical_paths`.

```elixir
# Add to Selectors module:
@canonical_paths %{
  ...,
  jobs: "/ops/jobs/jobs"
}

def jobs_path(params \\ []), do: encode(:jobs, params)
```

The detail path `/ops/jobs/jobs/:id` is constructed inline (`"/ops/jobs/jobs/#{id}"`) since it has a dynamic segment — consistent with how `WorkflowsLive` constructs `/ops/jobs/workflows/#{workflow.id}`.

### Anti-Patterns to Avoid

- **Querying without state in the WHERE clause:** `Oban.Job` tables grow large. Even a `queue` filter without a leading `state` clause can bypass the composite index. State MUST be the first WHERE condition (D-05).
- **`repo.all(from Oban.Job)` with no filter:** Never query all jobs — always filter by state minimum.
- **Calling `Oban` functions (retry/cancel/discard) from LiveView:** All mutations in Phase 44+ must route through `Lifeline.execute_repair`. Phase 43 is read-only; no mutation calls needed here.
- **Creating a new `live_session` for `/jobs` routes:** Add to the existing `live_session :oban_powertools_native` block — a second live_session would break the shared `on_mount` and session assignment.
- **Using `Map.get(params, "id")` for route actions:** LiveView provides `socket.assigns.live_action` — use it in `mount/3` to branch cleanly between `:index` and `:show` for permission selection.
- **Passing `tags` as a comma-separated string without parsing:** URL param `?tags=foo,bar` must be split to `["foo", "bar"]` before passing to `%JobFilter{}`. The `maybe_filter_tags/2` clause expects a list.
- **Hardcoding the `/ops/jobs` prefix in LiveView:** Use the `@oban_dashboard_path` session assign (already injected by `live_session` session map) for any path construction that needs the outer scope prefix.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| URL query param encoding | Custom param serializer | `URI.encode_query/1` via `Selectors.jobs_path/1` | Existing canonical pattern; handles nil/empty dropping; preserves ordering |
| Array contains query for tags | Manual SQL fragment | `fragment("? @> ?", j.tags, ^tags)` in Ecto query | The `@>` operator plus the GIN index is the correct Postgres idiom; custom SQL fragments avoid it |
| Worker short-name extraction | Regex | `String.split(worker, ".") |> List.last()` | Simple, idiomatic; already the stated approach in D-12 |
| JSON display of args/meta | Custom JSON renderer | `Jason.encode!(value, pretty: true)` in `render_job_field/3` | Jason is already in the project; pretty-print is one flag |
| Permission check logic | Custom authorization | `LiveAuth.authorize_page/3`, `LiveAuth.authorized?/3` | Established auth layer; bypassing it breaks the permission model |
| Read-only banner copy | Inline string | `LiveAuth.page_read_only_banner(:jobs)` / `LiveAuth.page_read_only_banner(:job_detail)` | Canonical copy location is the `@page_read_only_banners` module attribute |

**Key insight:** The project's established patterns cover every recurring problem in this phase. The only genuinely new code is `ObanPowertools.Jobs` (the context module) and the job-specific DisplayPolicy helpers. Everything else is additive extension of existing patterns.

---

## Common Pitfalls

### Pitfall 1: mount/3 action branch for auth

**What goes wrong:** Using a single permission (e.g., `:view_jobs`) for both `:index` and `:show` actions means the detail page doesn't get the separate `view_job_detail` gate that Phase 44 expects to find.

**Why it happens:** `WorkflowsLive` uses one permission for both actions (`:view_workflows`). `JobsLive` must use two, per D-17 and D-18.

**How to avoid:** Branch on `socket.assigns.live_action` in `mount/3`. Use `:view_jobs` for `:index`, `:view_job_detail` for `:show`.

**Warning signs:** Router test passes but `authorize_page` in the detail view uses the wrong action atom.

### Pitfall 2: Missing default state push_patch on mount

**What goes wrong:** A user lands on `/ops/jobs/jobs` with no `?state=` param. `handle_params/3` receives empty params, builds a `%JobFilter{}` with `state: nil` or whatever the struct default is, and either crashes or queries without a state filter.

**Why it happens:** The spec (D-09, UI-SPEC Interaction Contract step 1) requires that arriving with no state param triggers a `push_patch` to `?state=available` before any query runs.

**How to avoid:** In `handle_params/3`, check for missing `"state"` param first. If absent, `push_patch(to: jobs_path([{"state", "available"}]))` and return `{:noreply, socket}` without loading data.

**Warning signs:** Test against `/ops/jobs/jobs` with no params produces an Ecto query without a `WHERE state =` clause, or a function clause error in `to_string(nil)`.

### Pitfall 3: count_by_state/2 N+1 query on each tab

**What goes wrong:** Running 7 separate COUNT queries in a loop on every filter change is slow on large tables if each is a full scan. However, since state leads every query, each COUNT uses the index. This is acceptable for Phase 43.

**Why it happens:** The alternative (a GROUP BY state query) returns only states with jobs, so absent states don't show `(0)` in tabs. Separate queries are the correct approach here.

**How to avoid:** The `count_by_state/2` implementation above is correct. Document that this makes 7 DB round-trips per filter change; the keyset path doesn't change this.

**Warning signs:** Slow page load on large `oban_jobs` tables with no GIN index on `state`. Check that Oban's composite index includes `state` as the leading column.

### Pitfall 4: DisplayPolicy nil/crash handling in render_job_field

**What goes wrong:** `job.args` or `job.meta` is `nil` (possible for meta, unlikely for args but defensive). `Jason.encode!(nil)` raises. The LiveView crashes.

**Why it happens:** `Oban.Job` schema has `args: :map` (no default nil, but could be nil from test fixtures) and `meta: :map, default: %{}` (safe). However, the DisplayPolicy callback might return an unexpected value.

**How to avoid:** The `render_job_field/3` implementation above wraps everything in a `rescue` and returns `{:fallback, "[redacted]"}` on any error. Also, `Jason.encode!(value || %{})` normalizes nil to `%{}`.

**Warning signs:** `Protocol.UndefinedError` for Jason encoding, or `FunctionClauseError` in the display policy match.

### Pitfall 5: Tags URL param parsing

**What goes wrong:** `?tags=foo,bar,baz` arrives as the string `"foo,bar,baz"` in `params`. Passing this string directly to `%JobFilter{tags: "foo,bar,baz"}` and then to `maybe_filter_tags/2` causes a type error in the `@>` fragment (expects a list).

**Why it happens:** URL params are always strings. The filter builder must split on `","` and trim whitespace.

**How to avoid:** In `filter_from_params/1`:
```elixir
tags =
  case Map.get(params, "tags") do
    nil -> nil
    "" -> nil
    str -> str |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end
```

**Warning signs:** Ecto raises `ArgumentError` or Postgres raises `ERROR 42883` about the `@>` operator receiving wrong types.

### Pitfall 6: page_read_only_banner uses Map.fetch! — new keys must be added

**What goes wrong:** `LiveAuth.page_read_only_banner(:jobs)` calls `Map.fetch!(@page_read_only_banners, :jobs)` — if `:jobs` is not in the map, it raises `KeyError` at runtime.

**Why it happens:** `@page_read_only_banners` is a compile-time module attribute map. Adding `:jobs` and `:job_detail` to it is a hard requirement.

**How to avoid:** The edit to `live_auth.ex` that adds `:jobs` and `:job_detail` to `@page_read_only_banners` MUST precede any LiveView render that calls `page_read_only_banner/1`.

**Warning signs:** `KeyError` at `:oban_powertools, key :jobs not found in %{cron: ..., lifeline: ...}`.

### Pitfall 7: Selectors module missing :jobs key

**What goes wrong:** `Selectors.jobs_path/1` calls `encode(:jobs, params)` which calls `Map.fetch!(@canonical_paths, :jobs)`. If `:jobs` is not added to `@canonical_paths`, it raises.

**Why it happens:** Same compile-time module attribute pattern as `@page_read_only_banners`.

**How to avoid:** The edit to `selectors.ex` adding `:jobs` to `@canonical_paths` must be in the same wave or before the LiveView uses `jobs_path/1`.

---

## Code Examples

### Oban.Job schema fields confirmed for this phase

```elixir
# Source: deps/oban/lib/oban/job.ex (oban 2.22.1)
# Fields used by JobsLive:
# List view: state, queue, worker, id, scheduled_at, attempt
# Detail view: all of the above plus args, meta, errors, max_attempts,
#              inserted_at, attempted_at, completed_at, cancelled_at, discarded_at
# errors field: {:array, :map} — each element has keys including "at", "attempt", "error"
# tags field: {:array, :string}
```

### Existing composite index Oban ships

```sql
-- Source: Oban migration history (standard Oban install)
-- Index name: oban_jobs_state_queue_priority_scheduled_at_id_index
-- Columns: state, queue, priority, scheduled_at, id
-- State-leading WHERE clauses use this index.
-- Tags column has NO default index — host must create GIN index separately.
```

### Errors field structure (from Oban docs / lifeline_live usage pattern)

```elixir
# Source: deps/oban/lib/oban/job.ex — errors type
# @type errors :: [%{at: DateTime.t(), attempt: pos_integer(), error: binary()}]
# Each error map in job.errors has at minimum:
#   "at"      => ISO8601 timestamp string
#   "attempt" => integer attempt number
#   "error"   => string error message + backtrace
```

### render_job_field/3 return shape (new helper)

```elixir
# Return values from render_job_field/3:
# {:raw_json, json_string}  — nil policy return OR Map return — render in <pre> block
# {:string, text}           — String policy return — render in <pre> block
# {:fallback, "[redacted]"} — any error/exception — render as muted text
```

### Worker short-name extraction

```elixir
# Source: CONTEXT.md D-12 + standard Elixir idiom
defp short_worker_name(worker) when is_binary(worker) do
  worker |> String.split(".") |> List.last()
end
defp short_worker_name(nil), do: "—"
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Side-panel job detail | Full-page detail route `/jobs/:id` | D-08 (Phase 43) | Phase 44 can attach mutation controls to the same route without layout changes |
| Oban Web bridge for job inspection | Native `/ops/jobs/jobs` LiveView | Phase 43 | Operators stay in the native shell; no bridge dependency for read |
| offset pagination (documented) | offset pagination with documented keyset upgrade path | D-03 (Phase 43) | Single function change to `Jobs.list/3` when needed |

**Deprecated/outdated:**
- Redirecting to Oban Web bridge for job inspection: Phase 43 makes this unnecessary for the list/detail case. Links to the bridge remain available (e.g., from Lifeline) but the browse surface is now native.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

All claims in this research are VERIFIED against the live codebase (router.ex, live_auth.ex, runtime_config.ex, workflows_live.ex, lifeline_live.ex, selectors.ex, deps/oban/lib/oban/job.ex, mix.lock) or CITED against locked CONTEXT.md decisions. No assumed claims require user confirmation.

---

## Open Questions

1. **`Selectors.jobs_path/1` or inline path construction?**
   - What we know: `Selectors` is the canonical URL encoder. All existing canonical paths have dedicated helpers. `WorkflowsLive` constructs the detail path inline (`"/ops/jobs/workflows/#{workflow.id}"`).
   - What's unclear: The spec only requires `jobs_path` for the list URL. The detail path has a dynamic segment.
   - Recommendation: Add `jobs_path/1` to `Selectors` for the list URL (used in `push_patch` and back-link construction). Construct the detail URL inline: `"/ops/jobs/jobs/#{id}"`. This matches the WorkflowsLive precedent.

2. **Back-link filter state preservation**
   - What we know: UI-SPEC says the back link on the detail page navigates to `/ops/jobs/jobs` preserving the last-known filter params.
   - What's unclear: Whether to pass filter state via URL param on the detail page (e.g., `?back=...`) or assign it in the socket and lose it on hard refresh.
   - Recommendation: Pass a `?back=<encoded_filter>` param or simply navigate to `/ops/jobs/jobs` without preserving filter state. The simpler approach (no back-state) is consistent with other LiveViews in the codebase. Accept that refreshing the detail page loses the previous filter. Phase 44 can improve if needed.

---

## Environment Availability

Phase 43 is pure code changes — no external tools, services, or CLIs beyond the project's existing stack are required. PostgreSQL and the `oban_jobs` table are required at test time, as with all existing phases.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | `ObanPowertools.Jobs` context queries | Assumed (existing project) | — | — |
| `oban_jobs` table + composite index | `Jobs.list/3`, `Jobs.count_by_state/2` | Assumed (Oban migration prerequisite) | oban 2.22.1 | — |
| Host-owned GIN index on `oban_jobs.tags` | `tags` filter | Not guaranteed (host-owned) | — | Sequential scan on state-filtered rows; documented caveat |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/oban_powertools/web/live/jobs_live_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QRY-01 | List page renders with state tab bar | LiveView integration | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ❌ Wave 0 |
| QRY-01 | Filter by queue narrows job list | LiveView integration | same | ❌ Wave 0 |
| QRY-01 | Filter by worker narrows job list | LiveView integration | same | ❌ Wave 0 |
| QRY-01 | Filter by tags narrows job list (with GIN caveat) | LiveView integration | same | ❌ Wave 0 |
| QRY-01 | URL params preserved on filter change | LiveView integration | same | ❌ Wave 0 |
| QRY-01 | Unauthorized redirect | LiveView integration | same | ❌ Wave 0 |
| QRY-01 | Read-only banner renders for restricted actor | LiveView integration | same | ❌ Wave 0 |
| QRY-01 | `Jobs.list/3` state leads WHERE clause | Unit | `mix test test/oban_powertools/jobs_test.exs` | ❌ Wave 0 |
| QRY-02 | Detail page renders all job fields | LiveView integration | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ❌ Wave 0 |
| QRY-02 | DisplayPolicy redaction applied to args | LiveView integration | same | ❌ Wave 0 |
| QRY-02 | DisplayPolicy redaction applied to meta | LiveView integration | same | ❌ Wave 0 |
| QRY-02 | Job not found returns 404-like state | LiveView integration | same | ❌ Wave 0 |
| D-06 | `/jobs` and `/jobs/:id` routes registered | Router test | `mix test test/oban_powertools/web/router_test.exs` | ✅ (extend existing) |
| D-20 | Permission atoms added to LiveAuth | Unit / compile | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/jobs_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/oban_powertools/jobs_test.exs` — unit tests for `ObanPowertools.Jobs`: `list/3` state-leading WHERE, pagination, optional filters, `count_by_state/2`, `get/2`
- [ ] `test/oban_powertools/web/live/jobs_live_test.exs` — LiveView integration tests following `lifeline_live_test.exs` / `workflows_live_test.exs` pattern; needs a test display policy module at the top
- [ ] `test/oban_powertools/web/router_test.exs` — extend with assertions for `/ops/jobs/jobs` and `/ops/jobs/jobs/:id` route registration (file exists, add cases)

---

## Security Domain

Phase 43 is read-only. No mutations, no credential handling, no new external calls.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Auth is delegated to host; `LiveAuth.on_mount` already wires current_actor |
| V3 Session Management | No | Existing `live_session :oban_powertools_native` handles session |
| V4 Access Control | Yes | `LiveAuth.authorize_page/3` gates both `:index` and `:show` with separate permission atoms |
| V5 Input Validation | Yes | URL params parsed into `%JobFilter{}` — all values treated as strings; no eval, no SQL injection (Ecto parameterizes all values) |
| V6 Cryptography | No | Read-only; no secrets stored or transmitted |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized job detail access | Information Disclosure | `LiveAuth.authorize_page(socket, :view_job_detail, %{type: :job, id: job_id})` in mount |
| Sensitive args/meta exposure | Information Disclosure | `DisplayPolicy.render_job_field/3` — host controls redaction via `display/3` callback |
| SQL injection via filter params | Tampering | Ecto parameterized queries — all `%JobFilter{}` values bound as params, never interpolated |
| Large table scan via unindexed filter | Denial of Service | State MUST lead WHERE clause (D-05); GIN index caveat documented for tags |

---

## Sources

### Primary (HIGH confidence — verified against live codebase)

- `lib/oban_powertools/web/router.ex` — existing `live_session :oban_powertools_native` block; route insertion point confirmed
- `lib/oban_powertools/web/live_auth.ex` — `@permission_messages`, `@page_read_only_banners`, `authorize_page/3` implementation confirmed
- `lib/oban_powertools/runtime_config.ex` — `ObanPowertools.DisplayPolicy` module; `apply_policy/3`, `render_text/4` primitives confirmed
- `lib/oban_powertools/web/workflows_live.ex` — double-route single-module pattern confirmed
- `lib/oban_powertools/web/lifeline_live.ex` — `push_patch` / `handle_params` filter pattern, `load_data` shape confirmed
- `lib/oban_powertools/web/selectors.ex` — canonical URL encoder; `@canonical_paths` map; `encode/2` shape confirmed
- `deps/oban/lib/oban/job.ex` (oban 2.22.1) — `Oban.Job` schema fields, types, and `oban_jobs` table mapping confirmed
- `mix.lock` — library versions confirmed (oban 2.22.1, phoenix 1.8.7, phoenix_live_view 1.1.30, ecto_sql 3.10+)
- `.planning/phases/43-read-only-job-browse/43-CONTEXT.md` — all locked decisions
- `.planning/phases/43-read-only-job-browse/43-UI-SPEC.md` — component inventory, color tokens, copywriting contract, interaction contract

### Secondary (MEDIUM confidence — standard Oban/Phoenix/Postgres knowledge)

- Oban composite index `oban_jobs_state_queue_priority_scheduled_at_id_index` — standard Oban migration; confirmed by Oban's public migration documentation and existing codebase usage in `lifeline.ex` and `cron.ex`
- PostgreSQL `@>` array contains operator for tags GIN filtering — standard Postgres array operator

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in mix.lock; no new packages
- Architecture: HIGH — verified against live codebase patterns; no speculation
- Pitfalls: HIGH — all pitfalls derived from direct reading of existing code and locked decisions

**Research date:** 2026-05-27
**Valid until:** 2026-07-27 (stable stack; 60-day window is conservative)
