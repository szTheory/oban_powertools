# Architecture Research

**Domain:** Phoenix/LiveView operator control plane — native job browse surface and Elixir API
**Researched:** 2026-05-27
**Confidence:** HIGH (based on direct codebase inspection)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Host Router Scope                           │
│              "/ops/jobs"  pipe_through(:browser)                │
├─────────────────────────────────────────────────────────────────┤
│              oban_powertools_routes("/oban")                     │
│                                                                 │
│  live_session :oban_powertools_native                           │
│  on_mount: [ObanPowertools.Web.LiveAuth]                        │
│                                                                 │
│  Existing                         NEW (v1.5)                    │
│  ┌──────────────┐  ┌────────────────────────────────────────┐  │
│  │ EngineOverview│  │ JobsLive          JobDetailLive        │  │
│  │ LifelineLive  │  │ /jobs             /jobs/:id            │  │
│  │ LimitersLive  │  └────────────────────────────────────────┘  │
│  │ CronLive      │                                              │
│  │ WorkflowsLive │                                              │
│  │ AuditLive     │                                              │
│  │ ForensicsLive │                                              │
│  └──────────────┘                                              │
├─────────────────────────────────────────────────────────────────┤
│                    Service Layer                                 │
│  Existing                         NEW (v1.5)                    │
│  ┌──────────────┐  ┌────────────────────────────────────────┐  │
│  │ Lifeline      │  │ Jobs (query module)                    │  │
│  │ Cron          │  │ ObanPowertools.Operator (API module)   │  │
│  │ Limits        │  └────────────────────────────────────────┘  │
│  │ Workflow      │                                              │
│  │ Forensics     │                                              │
│  └──────────────┘                                              │
├─────────────────────────────────────────────────────────────────┤
│           Shared Infrastructure (unchanged)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  Auth    │  │  Audit   │  │Telemetry │  │ControlPlane  │   │
│  │(Sigra)   │  │          │  │          │  │ Presenter    │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│                   Postgres / Ecto                               │
│  ┌──────────────────┐  ┌────────────────────────────────────┐  │
│  │ oban_jobs        │  │ oban_powertools_audit_events       │  │
│  │ (Oban.Job schema)│  │ oban_powertools_repair_previews    │  │
│  │                  │  │ oban_powertools_repair_archives    │  │
│  │ Existing schema, │  └────────────────────────────────────┘  │
│  │ no migration     │                                          │
│  │ required         │                                          │
│  └──────────────────┘                                          │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | New or Modified |
|-----------|----------------|-----------------|
| `ObanPowertools.Web.JobsLive` | Job list with filter by queue/state/worker/tags, pagination, bulk selection | NEW |
| `ObanPowertools.Web.JobDetailLive` | Job detail: args, meta, errors, attempt history, action buttons | NEW |
| `ObanPowertools.Jobs` | Ecto query builder over `Oban.Job` schema; filter, paginate, count | NEW |
| `ObanPowertools.Operator` | Typed Elixir API — retry, cancel, discard, bulk variants | NEW |
| `ObanPowertools.Lifeline` | Command execution pipeline for audited mutations | MODIFIED — add `job_discard` to `@supported_actions`; add clauses to 3 private functions; relax incident guard for browse-initiated actions |
| `ObanPowertools.Web.Router` | Route declarations | MODIFIED — add `/jobs` and `/jobs/:id` live routes inside existing `live_session` block |
| `ObanPowertools.Web.LiveAuth` | Auth hooks, permission messages, page banners | MODIFIED — add `:view_jobs`, `:view_job_detail` permission keys and `:jobs` banner |
| `ObanPowertools.Web.Selectors` | Canonical URL builder | MODIFIED — add `:jobs` and `:job_detail` canonical paths; add `jobs_path/1` and `job_detail_path/2` helpers |
| `ObanPowertools.Telemetry` | Low-cardinality event contract | MODIFIED — document `source: "api"` for Operator API events under existing `:operator_action` family; no breaking change |

## Recommended Project Structure

```
lib/oban_powertools/
├── jobs.ex                        # NEW: Ecto query builder over Oban.Job
├── operator.ex                    # NEW: typed public Elixir API
├── web/
│   ├── jobs_live.ex               # NEW: job list LiveView (QRY-01, QRY-03, QRY-04)
│   ├── job_detail_live.ex         # NEW: job detail LiveView (QRY-02, QRY-03)
│   ├── router.ex                  # MODIFIED: add /jobs and /jobs/:id routes
│   ├── live_auth.ex               # MODIFIED: add job-surface permission keys
│   └── selectors.ex               # MODIFIED: add jobs canonical paths
└── lifeline.ex                    # MODIFIED: add job_discard + browse-initiated action path
```

## Integration Points

### 1. Oban.Job Schema Access

`Oban.Job` is already used by `Lifeline` for direct `repo.get!(Oban.Job, id)` lookups and fragment queries against `meta`. The new `Jobs` query module extends this to full filter + paginate queries. The `tags` field is `{:array, :string}` in Oban's schema; Ecto array containment queries use `fragment/1`.

Key `Oban.Job` fields for the browse surface:

| Field | Type | Use |
|-------|------|-----|
| `id` | integer | identity, detail links |
| `state` | string | filter, display — 8 states: `available`, `scheduled`, `executing`, `retryable`, `completed`, `cancelled`, `discarded`, `suspended` |
| `queue` | string | filter |
| `worker` | string | filter, display |
| `args` | map | detail display (subject to DisplayPolicy redaction) |
| `meta` | map | detail display; `executor_id` key cross-links to Lifeline |
| `errors` | list of maps | detail display — each entry has `at`, `attempt`, `error`, `stderr` |
| `tags` | `[:string]` | filter |
| `attempt` / `max_attempts` | integer | display |
| `inserted_at` / `scheduled_at` / `attempted_at` / `completed_at` / `cancelled_at` / `discarded_at` | NaiveDateTime | sort, display |

No migration is required — `oban_jobs` is entirely Oban's schema. Oban's own indexes on `(state)`, `(queue)`, and `(worker)` already exist. A composite index on `(state, queue, inserted_at DESC)` may be needed for large tables but is a host-owned operational concern, not a library migration.

The query module follows the established pattern in `Lifeline` and `OverviewReadModel`:

```elixir
defmodule ObanPowertools.Jobs do
  import Ecto.Query

  def list(repo, filters \\ [], opts \\ []) do
    page_size = Keyword.get(opts, :page_size, 50)
    offset = Keyword.get(opts, :offset, 0)

    Oban.Job
    |> apply_filters(filters)
    |> order_by([j], desc: j.inserted_at)
    |> limit(^page_size)
    |> offset(^offset)
    |> repo.all()
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:state, v}, q -> where(q, [j], j.state == ^v)
      {:queue, v}, q -> where(q, [j], j.queue == ^v)
      {:worker, v}, q -> where(q, [j], j.worker == ^v)
      {:tag, v}, q -> where(q, [j], fragment("? @> ARRAY[?]::text[]", j.tags, ^v))
      _, q -> q
    end)
  end
end
```

### 2. Lifeline Command Pipeline Reuse

Lifeline is the canonical mutation surface. All job actions from the browse surface (retry, cancel, discard) must route through `Lifeline.preview_repair/4` → `Lifeline.execute_repair/5`. This preserves the preview token, plan hash drift check, `Ecto.Multi`-wrapped audit write, host escalation dispatch, and telemetry emit.

**What changes in Lifeline:**

a. `@supported_actions` — add `"job_discard"`. `job_retry` and `job_cancel` already exist; they work without incident context because `incident_fingerprint_for_job/2` handles `nil` incident by generating `"job:manual:#{job_id}"`.

b. `build_job_preview/5` — the existing guard blocks `job_rescue` when `health_state != "missing"` but does not block `job_retry` or `job_cancel`. Adding `job_discard` requires an analogous `after_state` and `plan_hash` clause. The browse-initiated path passes `incident: nil`; this already works for `job_retry` and `job_cancel` and will work for `job_discard` with the same treatment.

c. `mutate_target/5` — add the `"job_discard"` clause:
```elixir
{"job", "job_discard"} ->
  job = repo.get!(Oban.Job, preview.target_id)
  {:ok, repo.update!(Ecto.Changeset.change(job, state: "discarded", discarded_at: now))}
```

d. `next_job_state/1` — add `defp next_job_state("job_discard"), do: "discarded"`.

e. `repair_summary/3` — add a summary clause for `"job_discard"`.

**What does NOT change:** The preview token, plan hash, drift detection, `Ecto.Multi` transaction, `Audit.record/4` call, host escalation dispatch, and `Telemetry.execute_lifeline_event(:repair_executed, ...)` are all reused unmodified for browse-initiated actions.

### 3. Auth Hooks

`LiveAuth` wraps `Auth` (Sigra) and provides page-level and action-level guards. The new surfaces need:

- New `authorize_page` action atoms: `:view_jobs` (list page), `:view_job_detail` (detail page). Pattern matches every existing LiveView's `mount/3`.
- For Lifeline calls from the browse surface: reuse `:preview_repair` / `:execute_repair` rather than introducing new atoms. This means host auth modules need no changes, and the audit `command_key` stays `"execute_repair"`.
- New entries in `LiveAuth`'s `@permission_messages` for `:view_jobs` and `:view_job_detail`.
- New entry in `@page_read_only_banners` for `:jobs`.

The `Auth.authorize/3` call shape `(actor, action_atom, resource_map)` is unchanged.

### 4. Telemetry Hooks

The contract is frozen at five families: `operator_action`, `limiter`, `cron`, `workflow`, `lifeline`. Low-cardinality is a hard constraint.

- Browse queries: emit under `:operator_action` with `action: "job_browse"` and `source: "ui"` — both keys are already in the `:operator_action` allowed metadata set. No contract change.
- Executed mutations (retry, cancel, discard): `Lifeline` already emits `Telemetry.execute_lifeline_event(:repair_executed, ...)` with `action`, `incident_class`, `target_type`. Browse-initiated actions produce the same emit. No change needed.
- Operator API calls: emit under `:operator_action` with `action: "operator_api"` and `source: "api"`. Both metadata keys already allowed.

No new telemetry family is needed.

### 5. Selectors Extension

`Selectors` uses a `@canonical_paths` map with one helper per destination. Extension follows the same pattern as the existing five paths:

```elixir
# Add to @canonical_paths:
jobs: "/ops/jobs/jobs",

# Add helpers:
def jobs_path(params), do: encode(:jobs, params)

# For job detail, build a non-encode helper since the ID is path-embedded:
def job_detail_path(id, params \\ []) do
  base = "/ops/jobs/jobs/#{id}"
  query = params |> Enum.reject(fn {_, v} -> is_nil(v) or v == "" end) |> URI.encode_query()
  if query == "", do: base, else: "#{base}?#{query}"
end
```

### 6. Router Extension

The new routes go inside the existing `live_session :oban_powertools_native` block, inheriting `LiveAuth` on_mount and the `oban_dashboard_path` session key:

```elixir
live("/jobs", ObanPowertools.Web.JobsLive, :index)
live("/jobs/:id", ObanPowertools.Web.JobDetailLive, :show)
```

No new `live_session` is needed. No new session key is needed.

### 7. Operator API Module

`ObanPowertools.Operator` wraps Lifeline calls for programmatic use. The function signature follows the established `(repo, actor, ...)` convention used by `Lifeline`, `Cron`, and `Workflow`:

```elixir
defmodule ObanPowertools.Operator do
  @doc "Retry a single job. Actor must satisfy Auth.audit_principal/1."
  def retry_job(repo, actor, job_id, reason, opts \\ [])
  # -> {:ok, %{target: job, preview: preview}} | {:error, reason}

  def cancel_job(repo, actor, job_id, reason, opts \\ [])
  def discard_job(repo, actor, job_id, reason, opts \\ [])

  @doc "Retry multiple jobs. Returns {:ok, count} or {:error, [{id, reason}]}."
  def bulk_retry(repo, actor, job_ids, reason, opts \\ [])
  def bulk_cancel(repo, actor, job_ids, reason, opts \\ [])
  def bulk_discard(repo, actor, job_ids, reason, opts \\ [])
end
```

Each single-job function calls `Lifeline.preview_repair/4` then `Lifeline.execute_repair/5`. Bulk functions call the single-job path N times and aggregate results. Bulk operations should cap at a configurable `:max_bulk` option (default 100) to bound latency and audit volume.

## Data Flow

### Job Browse and Action Flow

```
Operator navigates to /ops/jobs
    |
    v
JobsLive.mount/3
  -> LiveAuth.authorize_page(socket, :view_jobs, %{type: :page, id: "jobs"})
  -> Jobs.list(repo, filters, page_size: 50)     [queries oban_jobs directly]
  -> assign(:jobs, jobs)
    |
Operator applies filter (queue, state, worker, tag)
    |
    v
JobsLive.handle_event("filter", params, socket)
  -> push_patch with new query params
  -> handle_params -> Jobs.list(repo, new_filters)
    |
Operator clicks "Preview Retry" on a job row
    |
    v
JobsLive.handle_event("preview_action", %{"job-id" => id, "action" => "job_retry"}, socket)
  -> LiveAuth.authorize_action(socket, :preview_repair, %{type: :job, id: id})
  -> Lifeline.preview_repair(repo, actor,
       %{action: "job_retry", target_type: "job", target_id: id, incident_id: nil})
  -> {:ok, preview}  [incident_fingerprint: "job:manual:#{id}"]
  -> assign(:preview, preview)
    |
Operator enters reason + clicks "Execute"
    |
    v
JobsLive.handle_event("execute_action", ...)
  -> LiveAuth.authorize_action(socket, :execute_repair, resource)
  -> Lifeline.execute_repair(repo, actor, preview_token, reason)
     -> plan_hash recompute (drift check)
     -> Ecto.Multi: mutate_target + update preview + Audit.record("lifeline.repair_executed", ...)
     -> Telemetry.execute_lifeline_event(:repair_executed, %{count: 1}, %{action: "job_retry", ...})
  -> {:ok, result}
  -> reload job list
```

### Operator API Flow

```
ObanPowertools.Operator.retry_job(repo, actor, job_id, reason)
    |
    v
  Lifeline.preview_repair(repo, actor,
    %{action: "job_retry", target_type: "job", target_id: job_id, incident_id: nil})
    |
  {:ok, preview}
    |
  Lifeline.execute_repair(repo, actor, preview.preview_token, reason)
    -> same Ecto.Multi path as UI: audit written, telemetry emitted
    |
  {:ok, %{target: updated_job, preview: consumed_preview}}
```

## New vs Modified: Explicit Component Table

### New (net-new files — zero risk to existing surfaces)

| Component | File | Risk |
|-----------|------|------|
| `ObanPowertools.Jobs` | `lib/oban_powertools/jobs.ex` | None — pure Ecto, no deps on Lifeline |
| `ObanPowertools.Operator` | `lib/oban_powertools/operator.ex` | None — thin wrapper; depends on Lifeline Phase 3 changes |
| `ObanPowertools.Web.JobsLive` | `lib/oban_powertools/web/jobs_live.ex` | None until Phase 3 (mutation wiring) |
| `ObanPowertools.Web.JobDetailLive` | `lib/oban_powertools/web/job_detail_live.ex` | None until Phase 3 |

### Modified (surgical additions to existing files)

| Component | File | Change Scope | Risk |
|-----------|------|-------------|------|
| `ObanPowertools.Lifeline` | `lib/oban_powertools/lifeline.ex` | Add `"job_discard"` to `@supported_actions`; add clauses to `build_job_preview/5`, `mutate_target/5`, `next_job_state/1`, `repair_summary/3` | Low — additive clauses, no existing match ordering affected |
| `ObanPowertools.Web.Router` | `lib/oban_powertools/web/router.ex` | Add 2 `live/3` calls inside existing `live_session` | Minimal — pattern is identical to existing 7 routes |
| `ObanPowertools.Web.LiveAuth` | `lib/oban_powertools/web/live_auth.ex` | Add 2 keys to `@permission_messages`; add 1 key to `@page_read_only_banners` | Minimal — module attribute additions only |
| `ObanPowertools.Web.Selectors` | `lib/oban_powertools/web/selectors.ex` | Add `:jobs` to `@canonical_paths`; add `jobs_path/1` and `job_detail_path/2` | Minimal — additive only |
| `ObanPowertools.Telemetry` | `lib/oban_powertools/telemetry.ex` | Doc update only if `source: "api"` needs callout; no runtime change | None |

## Build Order to Minimize Coupling Risk

**Phase A: Read-only job browse (QRY-01, QRY-02)**

Build `ObanPowertools.Jobs` and `JobsLive` as read-only first. Add router routes. Extend `Selectors` and `LiveAuth`. Zero Lifeline dependency. Validates `Oban.Job` query access before touching mutation code.

Add `JobDetailLive` (also read-only). No new integration points beyond Jobs query module.

**Phase B: Single-job actions (QRY-03)**

Modify `Lifeline` to add `job_discard` support and validate browse-initiated (no-incident) action path. Wire preview/execute events into `JobsLive` and `JobDetailLive`. This is the highest-risk phase because it modifies `Lifeline`, but the changes are purely additive — new match clauses, no existing clause reordering.

**Phase C: Bulk operations (QRY-04)**

Add bulk selection state to `JobsLive`. Implement `Operator.bulk_*` functions using the Phase B single-job pipeline. No new Lifeline changes needed.

**Phase D: Operator API module (API-01)**

Add `ObanPowertools.Operator` as a thin wrapper. All Lifeline changes are already in place. Entirely additive.

## Anti-Patterns

### Anti-Pattern 1: Raw Mass-Update Bypass

**What people do:** Use `Oban.cancel_all_jobs/1` or `repo.update_all/2` from the UI or API.

**Why it's wrong:** Bypasses preview token, plan hash, audit record, and telemetry — the entire Lifeline contract. Creates unauditable mutations.

**Do this instead:** Route all mutations through `Lifeline.preview_repair/4` + `Lifeline.execute_repair/5`.

### Anti-Pattern 2: Parallel Mutation Pipeline

**What people do:** Build a `JobActions` module with direct `repo.update!` calls for retry/cancel/discard.

**Why it's wrong:** Duplicates preview, drift, audit, and telemetry logic immediately and diverges from the audit trail format.

**Do this instead:** Extend Lifeline with one new action (`job_discard`) and reuse the existing pipeline for `job_retry` and `job_cancel`.

### Anti-Pattern 3: New Auth Actions Requiring Host Module Changes

**What people do:** Introduce `:preview_job_action` and `:execute_job_action` as new auth atoms, requiring host apps to update their auth modules.

**Why it's wrong:** Host apps have already implemented auth around `:preview_repair` / `:execute_repair`. New atoms are a breaking change to the host contract.

**Do this instead:** Reuse `:preview_repair` and `:execute_repair` for browse-initiated job actions. The resource map `%{type: :job, id: job_id}` already carries enough context for host auth logic.

### Anti-Pattern 4: Job Query Caching

**What people do:** Introduce a GenServer or ETS cache for job counts or filtered lists.

**Why it's wrong:** Conflicts with the Ecto-native, no-Redis design constraint. Adds stateful complexity that none of the existing operator surfaces require.

**Do this instead:** Query Postgres directly with appropriate `LIMIT` and pagination. Add `OFFSET`-based pagination for the list; switch to keyset (cursor) pagination only if table sizes warrant it.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| < 100K jobs | Default Oban indexes sufficient; `LIMIT/OFFSET` pagination fine |
| 100K–1M jobs | Host-owned composite index on `(state, queue, inserted_at DESC)` if needed; enforce `LIMIT` ceiling; keyset pagination for deep pages |
| > 1M jobs | Keyset pagination required; Oban Pruner discipline critical; out of scope for v1.5 |

Bulk action cap: enforce a max selection size (default 100) in `JobsLive` to bound latency and audit volume. Expose as a configurable `RuntimeConfig` option or hard-coded constant in `Operator`.

## Sources

- `lib/oban_powertools/lifeline.ex` — canonical mutation pipeline, `@supported_actions`, `mutate_target/5`, `build_job_preview/5`, `incident_fingerprint_for_job/2`, `next_job_state/1`
- `lib/oban_powertools/web/live_auth.ex` — auth hook extension pattern; `@permission_messages` and `@page_read_only_banners` maps
- `lib/oban_powertools/web/router.ex` — `live_session` block structure; route addition pattern
- `lib/oban_powertools/web/selectors.ex` — `@canonical_paths` map; path helper pattern
- `lib/oban_powertools/telemetry.ex` — frozen contract; allowed metadata keys per family
- `lib/oban_powertools/audit.ex` — `Audit.record/4` signature; resource identity format
- `lib/oban_powertools/auth.ex` — `authorize/3`, `actor_id/1`, `audit_principal/1` call shapes
- `lib/oban_powertools/runtime_config.ex` — `repo!/1` and `Application.fetch_env!` patterns
- Oban v2.18 docs (Context7 `/oban-bg/oban`) — `Oban.Job` fields and 8-state machine; `Oban.Job.query/1`; `cancel_all_jobs/1`; `retry_all_jobs/1`

---
*Architecture research for: Oban Powertools v1.5 Native Job Surface & Automation API*
*Researched: 2026-05-27*
