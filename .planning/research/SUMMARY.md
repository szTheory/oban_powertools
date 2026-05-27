# Research Summary: Oban Powertools v1.5 — Native Job Surface & Operator API

**Researched:** 2026-05-27
**Confidence:** HIGH

## Executive Summary

Oban Powertools v1.5 closes the UI asymmetry between the existing Oban Web bridge (read/write via a third-party UI) and the native operator surface (previously read-only outside of incident-scoped Lifeline actions). The addition is a native job browse surface (list, filter, detail) paired with audited job mutations (retry, cancel, discard) and a typed Elixir API for automation. **No new dependencies are required:** Oban 2.22.1 ships `Oban.Job.query/1` and the bulk `retry_all_jobs`/`cancel_all_jobs` APIs; Phoenix LiveView 1.1.30 ships `stream/4` for large list rendering; all mutation primitives are already proven in the Lifeline module via direct Ecto updates on `Oban.Job`.

The recommended approach is an additive, four-phase build that starts with read-only query infrastructure (zero Lifeline risk), then wires single-job actions through the existing Lifeline preview/reason/audit pipeline (additive Lifeline changes only), then adds bulk operations, and finally wraps everything in a clean public Elixir API module.

The native surface's primary differentiator over the Oban Web bridge is **mandatory preview, reason capture, and durable audit evidence for every mutation** — this must be preserved without exception. Bypassing the Lifeline pipeline for "convenience" is the highest-risk implementation mistake and creates irrecoverable audit gaps.

## Key Findings

### Recommended Stack

No new dependencies needed. The locked stack provides every primitive required.

**Core primitives:**
- `Oban.Job.query/1` — composable Ecto query builder covering state, queue, worker, tags, args, meta, timestamps (2.22.1 verified)
- `Oban.retry_all_jobs/2` / `cancel_all_jobs/2` — public bulk mutation API; no `discard_all_jobs` exists (bulk discard uses `repo.update_all`)
- `Phoenix.LiveView.stream/4` — first use in this codebase; correct pattern for job list cardinality (1.1.30 verified)
- `JS.push/3` with `:value` — handles bulk checkbox selection without client-side hooks
- Direct Ecto `repo.update!` on `Oban.Job` — single-job mutations already proven in `Lifeline.mutate_target/5`
- Tags JSONB filtering — requires manual `fragment` for containment; `Oban.Job.query(tags:)` does full-array equality only

**What NOT to add:** Scrivener/Paginator, PubSub live-job subscriptions, ETS/GenServer query cache, `oban_met` integration.

### Expected Features

**Table stakes (must have):**
- Job list scoped by state with scalar filters (queue, worker, tags) — `state` is the primary navigation dimension
- Job detail: args, meta, errors, attempt history, timing — `Oban.Job` schema has all fields; no migration needed
- Retry, cancel, discard with preview/reason/audit — must route through `Lifeline.execute_repair`, not Oban functions directly
- Bulk retry/cancel/discard on visible selection — capped at configurable max (default 100)
- Operator actions Elixir API (`ObanPowertools.Operator`) — IEx sessions and automation with same audit guarantee

**Differentiators (vs. Oban Web bridge):**
- Mandatory preview/reason/audit for every mutation — the native surface's value proposition
- `DisplayPolicy` redaction for args/meta — non-negotiable for sensitive data
- Deep-link from Overview attention buckets to pre-filtered job list via `Selectors`
- Read-only page banner for unauthorized actors

**Anti-features (explicit exclusions):**
- args/meta free-text search — JSONB search without caching risks OOM/timeouts at scale
- Immediate mutations without preview — the bridge exists for that use case
- Delete job — removes audit trail; contradicts core product value
- Cross-page bulk select-all — deferred to post-v1.5

### Architecture Approach

Two new LiveViews (`JobsLive`, `JobDetailLive`) and two new service modules (`ObanPowertools.Jobs` for query building, `ObanPowertools.Operator` for the typed API) slot into the existing `live_session :oban_powertools_native` block. Five existing files receive surgical additive changes:

- `Lifeline` — add `"job_discard"` to `@supported_actions`; relax incident guard for browse-initiated nil-incident actions
- `Router` — 2 new routes under the existing macro scope
- `LiveAuth` — 2 permission keys + banner for new page types
- `Selectors` — `:jobs` and `:job_detail` canonical paths
- `Telemetry` — doc update only (no contract changes)

**No new migrations required.** `Oban.Job` schema already has all needed fields.

### Critical Pitfalls

1. **Sequential scan on `oban_jobs` filters** — Always lead with `state` (most selective Oban index). Tag filtering requires a GIN index. Enforce `LIMIT` at the query layer. Verify with `EXPLAIN ANALYZE` before shipping QRY-01.

2. **Actions bypassing the Lifeline pipeline** — All retry/cancel/discard must go through `Lifeline.preview_repair` + `execute_repair`. Calling `Oban.retry_job/1` directly from a LiveView event loses audit evidence permanently.

3. **Filter state as raw assigns** — Define `%JobFilter{}` struct before writing any event handler. URL-serialized via `push_patch`; `handle_params/3` is the single point of truth.

4. **Bulk partial failure with no per-job reporting** — Never wrap all N jobs in one `Ecto.Multi`. Each job runs its own `Lifeline.execute_repair`; results accumulate; UI reports per-job breakdown.

5. **Telemetry cardinality explosion** — `worker`, `queue`, `job_id`, and `reason` must never appear as telemetry metadata keys. The frozen `@contract` in `ObanPowertools.Telemetry` is the constraint boundary.

6. **Concurrent operator sessions** — Add optimistic `WHERE state = expected_state` guard at the `mutate_target` level; return `{:error, :state_changed}` for drift rather than silently succeeding.

7. **`LiveAuth.@permission_messages` must declare atoms before use** — Undeclared atoms cause `Map.fetch!` crash at runtime. Declare `:view_jobs`, `:view_job_detail`, `:retry_job`, `:cancel_job`, `:discard_job` in `LiveAuth` and the example-host auth module in Phase 1.

8. **`RepairPreview.incident_id` nullability** — Confirm the `RepairPreview` schema's `incident_id` column is nullable before Phase 2 begins. The nil-incident path for `job_retry`/`job_cancel` is confirmed in Lifeline source, but the schema constraint must be verified.

## Roadmap Implications

### Phase A: Read-Only Job Browse (QRY-01 + QRY-02)

Zero Lifeline dependency. Validates `Oban.Job` query access, index behavior, and `%JobFilter{}` URL contract before touching mutation code. Establishes `stream/4` pattern (first use in codebase) safely.

**Delivers:** Browsable job list (state/queue/worker/tags filters, keyset-ready pagination), job detail with DisplayPolicy-redacted args/meta and error history. Router routes, Selectors `:jobs`/`:job_detail`, LiveAuth permission keys.

**Key gate:** Run `EXPLAIN ANALYZE` on filter queries; verify no seq scan with `state` as leading WHERE clause.

### Phase B: Single-Job Actions (QRY-03)

Highest-risk phase — modifies `Lifeline`. Changes are purely additive (new match clauses, no existing clause reordering). Must come after Phase A so the job list/detail are stable action surfaces.

**Delivers:** Retry, cancel, discard on individual jobs with full preview/reason/audit pipeline. `"job_discard"` added to `Lifeline.@supported_actions` and `mutate_target/5`. Concurrent-modification guard.

### Phase C: Bulk Operations (QRY-04)

Depends on Phase B's single-job pipeline. Bulk is per-job iteration over `Lifeline.execute_repair` with result accumulation. No new Lifeline changes needed after Phase B.

**Delivers:** Bulk selection via `JS.push/3` checkbox MapSet, bulk retry/cancel/discard with count-preview, per-job success/failure reporting.

### Phase D: Operator Elixir API (API-01)

Entirely additive — all Lifeline changes are in place from Phases B-C. `ObanPowertools.Operator` is a thin wrapper designed last so its public function signatures derive from the same `%JobFilter{}` struct and Lifeline pipeline the UI phases establish.

**Delivers:** `ObanPowertools.Operator` with typed single-job and bulk functions. All require non-nil `actor`. `source: "api"` in telemetry metadata.

### Phase Ordering Rationale

- A before B: read-only query access validated before mutation code introduced
- B before C: bulk iterates over the single-job pipeline; pipeline must be proven first
- C before D: API must call the same functions the UI calls; those must be proven before public exposure
- No phase skips are safe — QRY-03 requires QRY-02; API-01 requires QRY-03

## Gaps Requiring Pre-Phase Decision

1. **Tags GIN index ownership** — Tag filtering without a GIN index degrades at scale. The library cannot own this migration. Either document as a host-owned prerequisite, or exclude tag filtering from Phase A and add it conditionally. Decide before Phase A begins.

2. **`RepairPreview.incident_id` nullability** — Confirm before Phase B begins.

3. **Keyset vs. offset pagination** — Offset acceptable for < 50k rows. Phase A should start with offset and make the keyset upgrade path explicit as a single function change in `ObanPowertools.Jobs.list/3`.

4. **Route path** — `/ops/jobs/jobs` (natural sub-path) vs. `/ops/jobs` with job list as a tab. Decide before Phase A to avoid URL contract churn.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified against locked deps in `mix.lock` and `deps/` |
| Features | HIGH | Derived from Oban Web source, Oban docs, and existing Lifeline surface |
| Architecture | HIGH | Direct source inspection of all integration points |
| Pitfalls | HIGH | Derived from Lifeline, telemetry `@contract`, and known Oban/Postgres/LiveView patterns |

---
*Research completed: 2026-05-27*
*Ready for roadmap: yes*
