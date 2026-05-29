# Phase 43: Read-Only Job Browse - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship a native job browse and detail surface — operators browse Oban jobs by state, narrow by queue/worker/tags, and inspect full job detail with DisplayPolicy redaction on args and meta — all without touching the Oban Web bridge.

QRY-01: native job list with filter/search  
QRY-02: native job detail view with DisplayPolicy redaction

Out of scope for Phase 43: any mutation (retry/cancel/discard), action previews, reason capture, audit writes, PubSub/live-count updates, args/meta full-text search.

</domain>

<decisions>
## Implementation Decisions

### Locked from Prior Phases (STATE.md)

- **D-01:** `%JobFilter{}` struct MUST be defined before any event handler is written — the struct anchors all filter event handling
- **D-02:** Permission atoms to declare in `LiveAuth.@permission_messages` before Phase 43: `:view_jobs`, `:view_job_detail`, `:retry_job`, `:cancel_job`, `:discard_job`
- **D-03:** Pagination: offset-based for Phase 43. The keyset upgrade path is explicitly a single function change in `ObanPowertools.Jobs.list/3` — document it, don't implement it
- **D-04:** Tags filtering requires a host-owned GIN index on `oban_jobs.tags` — document in the `ObanPowertools.Jobs` module doc and host guide; do NOT block Phase 43 on it
- **D-05:** State MUST lead every WHERE clause — it is the primary filter dimension, not an optional one

### Route & Navigation

- **D-06:** Two new routes added to the existing `live_session :oban_powertools_native` in `ObanPowertools.Web.Router`:
  ```elixir
  live("/jobs", ObanPowertools.Web.JobsLive, :index)
  live("/jobs/:id", ObanPowertools.Web.JobsLive, :show)
  ```
  Single module, two actions — follows the `WorkflowsLive` double-route pattern exactly.

- **D-07:** Filter state serialized as URL query params: `?state=executing&queue=default&worker=MyWorker&tags=tag1,tag2`. Filter changes use `push_patch` to update params — browser back/forward and deep-links work automatically.

- **D-08:** Job detail is a full-page navigation (`navigate("/jobs/#{id}")` from list row click), not a side-panel. Rationale: Phase 44 attaches preview/reason/execute mutation controls to this same detail page — a dedicated route is cleaner than a cramped side-panel.

- **D-09:** State navigation is a tab bar across the top with 7 tabs: `available`, `scheduled`, `executing`, `retryable`, `cancelled`, `discarded`, `completed`. Mirrors Oban Web's UX; single-click; no "all states" default tab (state is always required for efficient query planning).

### Data Layer

- **D-10:** New context module `ObanPowertools.Jobs` containing:
  - `%JobFilter{}` defstruct: `%{state: atom, queue: string | nil, worker: string | nil, tags: [string] | nil, page: integer, page_size: integer}`
  - `Jobs.list/3` query function signature: `list(repo, %JobFilter{}, opts \\ [])` — state leads the WHERE clause
  - `Jobs.get/2`: `get(repo, job_id)` — returns full `Oban.Job` with preloads needed for detail view
  - GIN index warning documented in `@moduledoc` for tags filtering

- **D-11:** Query order: `ORDER BY scheduled_at DESC, id DESC` as the default for the list view — most recently scheduled jobs first.

### Job List UI

- **D-12:** Job list row fields: state badge, worker (short module name — last segment only, e.g., `IngestWorker`), queue, job ID, `scheduled_at`, attempt count. Clicking a row navigates to `/jobs/:id`.

- **D-13:** State navigation tab shows job count per state (offset-based count query per visible tab set on mount/filter change).

### Job Detail UI

- **D-14:** Detail view displays all of: args (DisplayPolicy redacted), meta (DisplayPolicy redacted), errors (all attempt error records), attempt history (attempt number, timing), timing (inserted_at, scheduled_at, attempted_at, completed_at, cancelled_at, discarded_at where present).

- **D-15:** No mutation controls on the detail page in Phase 43 — read-only surface. Phase 44 adds action controls to this same page.

### DisplayPolicy Extension (Public API)

- **D-16:** `DisplayPolicy.display/3` gains two new atom kinds: `:job_args` and `:job_meta`. Return contract:
  - `nil` → show raw JSON (no redaction — default for all existing host implementations)
  - `String` → show this formatted string instead of raw JSON
  - `Map` → show as a field-level redacted copy (host strips sensitive keys and returns cleaned map)

  A new `render_job_field/3` helper is added to the `ObanPowertools.DisplayPolicy` module (parallel to the existing `workflow_result/2` path). Existing host implementations are not affected — their catch-all `display(_kind, _value, _context), do: nil` returns `nil`, which renders raw JSON.

### Auth & Permissions

- **D-17:** `JobsLive.mount/3` for `:index` action: `LiveAuth.authorize_page(socket, :view_jobs, %{type: :page, id: "jobs"})`
- **D-18:** `JobsLive.mount/3` for `:show` action: `LiveAuth.authorize_page(socket, :view_job_detail, %{type: :job, id: job_id})`
- **D-19:** `LiveAuth.@page_read_only_banners` extended with:
  - `:jobs` — "Permission: read-only. Job list stays visible, but mutation controls stay disabled until you receive broader permission."
  - `:job_detail` — "Permission: read-only. Job detail stays visible, but retry, cancel, and discard controls stay disabled until you receive broader permission."
- **D-20:** `LiveAuth.@permission_messages` extended with `:view_jobs` and `:view_job_detail` atoms (plus `:retry_job`, `:cancel_job`, `:discard_job` pre-declared for Phase 44).

### Claude's Discretion

- Exact copy for `:jobs` and `:job_detail` `@page_read_only_banners` — planner to draft following the established voice/pattern from existing entries.
- Exact worker short-name formatting (last segment of module name) — implementation detail for executor.
- Error display format in the detail view (which fields from the attempt error record to surface) — follow Lifeline's existing error display pattern.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Requirements
- `.planning/REQUIREMENTS.md` — QRY-01 and QRY-02 definitions (job list + detail requirements)
- `.planning/ROADMAP.md` §Phase 43 — success criteria (5 acceptance criteria, including URL serialization and read-only banner)

### Existing Implementation Surfaces (read before writing new code)
- `lib/oban_powertools/web/router.ex` — live_session route pattern; add new routes here
- `lib/oban_powertools/web/live_auth.ex` — `@permission_messages`, `@page_read_only_banners`, `authorize_page/3`, `authorize_action/4`; extend these maps, do NOT remove existing entries
- `lib/oban_powertools/runtime_config.ex` — `ObanPowertools.DisplayPolicy` module (lines ~78–end); add `:job_args`/`:job_meta` kinds here with `render_job_field/3` helper
- `lib/oban_powertools/web/workflows_live.ex` — canonical model for the double-route (`:index`/`:show`) single-module LiveView pattern
- `lib/oban_powertools/web/lifeline_live.ex` — canonical model for `mount/3` with `authorize_page`, `load_data`, `handle_params`, `push_patch` filter pattern

### Project Context
- `.planning/PROJECT.md` §Key Decisions — locked architectural decisions (Postgres-native, auth-before-preview, etc.)
- `.planning/STATE.md` §Accumulated Context — locked Phase 43 decisions (JobFilter struct, pagination, telemetry keys, permission atoms)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Web.LiveAuth` — `authorize_page/3`, `authorize_action/4`, `page_read_only_banner/1`, `permission_message/1`; extend rather than bypass
- `ObanPowertools.DisplayPolicy` — `assert_configured!/0`; must be called in mount; extend with `render_job_field/3`
- `ObanPowertools.Web.ControlPlanePresenter` — shared formatting helpers already used by other LiveViews
- `Selectors` alias pattern — used in `LifelineLive` for reusable query/selection logic

### Established Patterns
- **Double-route single-module LiveView**: `WorkflowsLive` with `/workflows` (`:index`) and `/workflows/:id` (`:show`) — the exact pattern for `JobsLive`
- **`push_patch` for in-page state changes**: `LifelineLive` uses `push_patch` + `handle_params` for view toggles and selection — use the same for filter changes
- **`DisplayPolicy.assert_configured!()` in mount**: called in `LifelineLive.mount/3` before any display — required in `JobsLive.mount/3`
- **`live_session :oban_powertools_native` scope**: all new routes must be added to this existing live_session, NOT as a new live_session

### Integration Points
- `ObanPowertools.Web.Router.oban_powertools_routes/1` macro — new routes added to the `live_session :oban_powertools_native` `do` block here
- `LiveAuth.@permission_messages` and `@page_read_only_banners` — module attributes; extend the map literals (additive only)
- `ObanPowertools.DisplayPolicy` module in `runtime_config.ex` — add `render_job_field/3` and call it from new `display/3` clauses for `:job_args`/`:job_meta`

</code_context>

<specifics>
## Specific Ideas

- State is always required as a filter (no "all states" query) — the leading WHERE on `state` enables index-only scans on Oban's existing `oban_jobs_state_queue_priority_scheduled_at_id_index` composite index.
- Tags filter must be documented as requiring a host-owned GIN index (`CREATE INDEX CONCURRENTLY oban_jobs_tags_gin ON oban_jobs USING gin(tags)`) — Phase 43 must not fail or silently table-scan when no GIN index exists; it must surface a documented caveat.
- `RepairPreview.incident_id` nullability must be confirmed before Phase 44 begins (noted for Phase 44's CONTEXT.md, not a Phase 43 blocker).
- Telemetry keys NOT allowed as job filter metadata: `worker`, `queue`, `job_id`, `reason` (per STATE.md locked decisions).

</specifics>

<deferred>
## Deferred Ideas

- Keyset pagination upgrade — single `list/3` function change, document the path, don't implement in Phase 43
- PubSub-backed live job count updates — requires `oban_met` integration; post-v1.5 (QRY-06)
- args/meta full-text search — JSONB search without index/cache risks OOM; post-v1.5 (QRY-05)
- Cross-page bulk select — post-v1.5 (QRY-08)
- Navigate from Lifeline job row to native job detail — post-v1.5 (QRY-07)

</deferred>

---

*Phase: 43-Read-Only-Job-Browse*
*Context gathered: 2026-05-27*
