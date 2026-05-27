# Feature Research

**Domain:** Native job query surface and operator actions API for a Phoenix/LiveView/Oban operator control plane
**Researched:** 2026-05-27
**Confidence:** HIGH

---

## Context: What Already Exists

The existing surfaces that directly constrain v1.5 design choices:

- **Lifeline** — operator repair flow for dead-executor and stuck-workflow incidents. Establishes the preview/reason/audit UX contract: preview first, require 8+ char reason, show before/after snapshot, write durable audit event, support drift detection.
- **`ObanPowertools.Lifeline`** — the Elixir-level mutation surface for jobs within incident contexts (`job_rescue`, `job_retry`, `job_cancel`). Uses `Oban.Job` Ecto queries directly and `Oban.cancel_all_jobs`/`Oban.retry_all_jobs` under the hood.
- **`/ops/jobs/oban` bridge** — read-only handoff to Oban Web. This is the UI asymmetry v1.5 closes. Oban Web supports full filter/search/bulk-action/detail on all job states; the native surface currently has none of that outside of incident-scoped Lifeline actions.
- **`ObanPowertools.Audit`** — durable audit event writer. All native mutations write here.
- **`ObanPowertools.Web.LiveAuth`** — actor resolution and authorization checks for all native pages. Must be used for all mutation surfaces.

---

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Job list scoped by state | Every job monitor tool organizes by state (available, executing, retryable, scheduled, completed, cancelled, discarded). Operators expect this as the primary navigation dimension. | LOW | Use `Oban.Job.states()` which returns all 8 states. The existing Oban Web bridge shows this; native must match. |
| Filter by queue | Operators with multi-queue deployments need to isolate one queue immediately. Missing this is felt on first use. | LOW | `Oban.Job.query/1` accepts `queue:` as a keyword, maps directly to `j.queue in ^queues`. |
| Filter by worker | The most common operational question is "show me all failing MyApp.FooWorker jobs". | LOW | `Oban.Job.query/1` accepts `worker:`. Oban Web uses `workers:` qualifier. Map module name as string. |
| Filter by tags | Tags are the host-defined labeling system on jobs. Operators who set tags expect to filter by them. | LOW | JSONB array overlap query: `fragment("? && ?", j.tags, ^tags)`. Already in Oban Web's job_query.ex. |
| Paginated/limited result list | Unbounded job queries against large deployments will OOM or time out. Operators expect a reasonable default result window. | LOW | Default 30 results per Oban Web's pattern. Offset pagination is simplest; keyset pagination is more correct but higher complexity. |
| Job detail: args and meta display | Operators need to see what arguments a job was invoked with and what's in meta. | LOW | `Oban.Job` fields `args` and `meta` are maps. Display as formatted JSON. Apply `DisplayPolicy` redaction consistent with existing audit surfaces. |
| Job detail: error history | When a job has retried, operators need to see previous error messages and stacktraces. | LOW | `Oban.Job.errors` field is a list of error objects with `at`, `attempt`, and `error` keys. The most recent error is diagnostic; all errors tell the retry story. |
| Job detail: attempt and timing fields | Attempt count, max attempts, inserted_at, scheduled_at, attempted_at, and state-specific terminal timestamps (completed_at, cancelled_at, discarded_at, attempted_by node) | LOW | All available directly on `Oban.Job` schema. |
| Retry action with reason and audit | Operators expect to retry a failed or discarded job. Must match Lifeline's preview/reason/audit posture since that is now the established native UX contract for any mutation. | MEDIUM | `Oban.retry_job/2` or `Oban.retry_all_jobs/2` for bulk. Requires reason capture (8+ chars), audit write, auth check via `LiveAuth`. |
| Cancel action with reason and audit | Operators expect to cancel available, scheduled, retryable, or executing jobs. Same reason/audit requirement. | MEDIUM | `Oban.cancel_job/2` or `Oban.cancel_all_jobs/2`. Executing jobs are killed. |
| Discard action with reason and audit | Discarding moves a job to discarded state permanently (stops retrying). Operators expect this as a way to drop a repeatedly failing job permanently. | MEDIUM | Oban does not expose `Oban.discard_job/2` directly. Discard is accomplished by setting state to `"discarded"` and clearing attempts. Implemented in Lifeline today with `Ecto.Changeset.change(job, state: "discarded", discarded_at: now)`. Must extend that pattern here. |
| Read-only page banner when not authorized | Established pattern across all native pages. If the actor cannot mutate, the page still renders as read-only inspection with a clear banner. | LOW | Reuse `LiveAuth.page_read_only_banner/1` — add `:jobs` key to the `@page_read_only_banners` map. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Consistent preview/reason/audit UX for QRY-03 actions | Oban Web performs retry/cancel immediately without a preview or reason capture step. The native surface forces a preview token, reason, and audit event — making operator mutations inspectable and reversible within the existing forensic/audit surfaces. | MEDIUM | Reuse `RepairPreview` schema and `Lifeline.build_preview` pattern. The preview stores before/after snapshot, a plan_hash for drift detection, and expires in 7 days. The key extension is adding `"job_retry"`, `"job_cancel"`, `"job_discard"` as standalone actions outside of incident context (Lifeline already supports them inside incident context). |
| Operator actions Elixir API (API-01) mirroring UI mutations | Automation pipelines and IEx-based operator sessions can call the same audited mutation surface the UI uses, without going through the LiveView layer. The API returns typed results and writes the same audit evidence. | MEDIUM | Module `ObanPowertools.OperatorActions` (or extend `ObanPowertools.Lifeline` with non-incident-scoped entry points). Must accept `actor`, `job_or_id`, `reason`, and optionally `opts`. Returns `{:ok, job}` or `{:error, reason}`. Writes to `ObanPowertools.Audit`. |
| Bulk operations with count-limited preview | Bulk retry/cancel/discard with a preview showing the count of affected jobs and requiring a reason. Prevents silent mass mutations. | HIGH | `Oban.retry_all_jobs/2` and `Oban.cancel_all_jobs/2` accept Ecto queryables. Bulk preview shows affected count, selected job IDs (or a capped summary), and estimated outcome. Does not require per-job drift detection — the preview captures the query snapshot count at preview time and re-counts at execute time. |
| Filter search integrated with existing attention buckets | The native job list does not replace the diagnosis-first overview — it is the drilldown surface. Deep-linking from the overview's attention buckets (retryable count, discarded count) pre-populates the state filter in the job list. | LOW | URL param encoding via `Selectors` module. Add `/jobs` to canonical paths. |
| Discard as a first-class native action (not just Oban Web) | Oban Web supports discard; the native surface currently does not outside of Lifeline's repair flow. Making discard explicit and audited closes the UX gap. | LOW | Low incremental complexity once the preview/reason/audit pipeline for QRY-03 is in place. |
| Job history tab on detail view (recent same-worker jobs) | Shows the last N runs of the same worker. Operators debugging a recurring failure want to see the pattern. | MEDIUM | Oban Web's `job_history/3` in `JobQuery` queries the last 60 jobs of the same worker sorted by id desc. Can replicate this pattern with a straight Ecto query: `from j in Oban.Job, where: j.worker == ^worker, order_by: [desc: :id], limit: 60`. |
| Args/meta redaction via DisplayPolicy | The existing `DisplayPolicy` module is already the redaction seam for audit evidence. Job args/meta display through the same hook prevents sensitive data leaking through the new surface. | LOW | Call `DisplayPolicy.redact/2` on args/meta before rendering. This is the existing pattern on the Lifeline audit detail view. |

### Anti-Features (Commonly Requested, Often Problematic)

| Anti-Feature | Why Requested | Why Problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| Immediate mutation without preview | Operators want one-click retry/cancel for speed. | Bypasses the established preview/reason/audit contract. Creates a second-class mutation path that generates no audit evidence and no drift detection. Undermines the native shell's primary value over Oban Web's bridge. | Keep the bridge for raw speed; the native surface always previews. Make preview fast enough (one click to generate, one click to execute) that the friction is acceptable. |
| Free-text global search across args/meta for all job states | Oban Web supports args./meta. qualifier search. Looks like a differentiator. | Cross-state JSONB search on large job tables is expensive. Oban Web limits to the last 100k jobs (configurable) and caches suggestions for 5 minutes. Replicating this without the same caching and limit infrastructure creates OOM or timeout incidents. | Start with scalar filter fields (state, queue, worker, tags). Add args/meta filtering only after establishing query limits and caching consistent with the host-app's risk tolerance. Flag as a future phase. |
| Real-time auto-refresh / live subscriptions | Operators want live job counts and state updates without refreshing. | Oban Web uses `oban_met` for real-time metrics via PubSub. That dependency is already in the lockfile but not yet used natively. Adding live subscriptions in this milestone balloons scope and requires testing the subscription lifecycle across reconnects and node topology changes. | Provide a manual refresh button (or page reload). Add PubSub-backed live updates as a separate milestone once the static query surface is stable. |
| Delete job action | Operators occasionally ask for delete (not cancel, not discard — permanent removal). | Deletion removes the audit trail. Oban Web supports it via `Oban.delete_all_jobs/2`, but the native surface's value proposition is durable evidence. Permanently deleting evidence contradicts that value. | The existing archive-and-prune flow in Lifeline is the answer for bulk evidence retention management. For individual jobs, discard is the correct terminal state. |
| Retry from a specific attempt number | "I want to retry from attempt 2, not attempt 1." | Oban has no such API. Retry always starts from the beginning. Pretending otherwise requires rewriting the job schema in ways Oban does not support. | Document that retry resets attempt count (consistent with `Oban.retry_job/2` behavior). The audit evidence captures what attempt it was before the retry. |
| Per-job rate limit override from the UI | Operators want to bump a job's priority or change its queue at execution time. | `Oban.update_job/2` does support priority and tag changes, but making this a general UI feature turns the job browser into a configuration surface with unpredictable operator impact. | The existing explicit limiter control plane (`/ops/jobs/limiters`) is the right surface for changing throughput policy. |
| Bulk select across paginated pages | "Select all 10,000 retryable jobs even though I can only see 30 at a time." | LiveView streams do not track which records span pages. Collecting IDs across pages requires either client-side accumulation or a server-side select-all query that runs independently of the visible page. Cross-page select-all is high complexity and high risk of surprising operators with unintended bulk mutations. | Support bulk actions only within the current visible selection (up to the configured bulk limit). Add a "select all matching query" shortcut only after the basic bulk pattern is proven. |
| Full-text error message search | Searching inside error stacktraces for a substring. | Error messages are stored in a JSONB errors array. Full-text search on JSONB error strings requires either a GIN index on that expression or a sequential scan. Neither is appropriate as an ad-hoc operator feature without explicit index planning. | Show error messages in the job detail view. Operators can use Ctrl+F in the browser for substring search within a rendered detail view. |

---

## Feature Dependencies

```text
QRY-01: Native job listing with filter/search
    requires: Oban.Job schema access (already available)
    requires: Selectors module extension (add :jobs canonical path)
    requires: LiveAuth page authorization (:view_jobs action)
    enhances: Overview attention buckets (deep-link from retryable/discarded counts)

QRY-02: Native job detail view
    requires: QRY-01 (a job must be selectable from the list)
    requires: DisplayPolicy for args/meta redaction
    enhances: Forensics surface (could deep-link to forensic bundle for a given job_id)
    enhances: Lifeline (existing job links in Lifeline could navigate here instead of Oban Web bridge)

QRY-03: Native job actions (retry/cancel/discard)
    requires: QRY-02 (actions live in the detail view context)
    requires: Lifeline preview/reason/audit pipeline (extend, not replace)
    requires: LiveAuth :preview_job_action and :execute_job_action permissions
    requires: ObanPowertools.Audit.record/4 (already available)
    enhances: Lifeline (Lifeline's job_retry/job_cancel actions become wrappers over the same pipeline)

QRY-04: Bulk operations
    requires: QRY-01 (selection is built from the list)
    requires: QRY-03 action pipeline (bulk uses same preview/reason/audit flow at batch level)
    requires: Oban.cancel_all_jobs/2 and Oban.retry_all_jobs/2 (available in Oban 2.22)

API-01: Operator actions Elixir API
    requires: QRY-03 action pipeline (API is a non-LiveView entry point into the same mutations)
    requires: ObanPowertools.Auth.actor_id/1 (already available)
    requires: ObanPowertools.Audit.record/4 (already available)

Lifeline compatibility:
    QRY-03 must not break Lifeline's existing job_rescue/job_retry/job_cancel paths
    Lifeline's incident-scoped actions remain valid; QRY-03 adds non-incident-scoped equivalents
    The RepairPreview schema may be reused as-is or extended with a nullable incident_id
```

### Dependency Notes

- **QRY-03 requires the Lifeline preview/reason/audit pipeline** because the established UX contract on this product requires preview → reason → execute → audit for any mutation. Any new action that skips this becomes the exception and erodes operator trust.
- **API-01 requires QRY-03** because the API must call the same underlying mutation functions (not a shortcut), or audit evidence diverges between UI and API callers.
- **Lifeline's `job_retry` and `job_cancel` actions are already incident-scoped** — QRY-03 adds the same actions without requiring an incident. The implementation should share the same `mutate_target/5` internal function or the same new `OperatorActions` module to avoid duplicating the Oban.Job mutation logic.
- **Discard is not in Oban's public API as a first-class function** — it requires a direct Ecto update to `state: "discarded", discarded_at: now`. Lifeline does this in `mutate_target/5` for the `"job_cancel"` action today (which actually uses state "cancelled"). Discard needs a new variant.

---

## MVP for v1.5

### Ship in v1.5

- [x] QRY-01: Native job list with state selector tabs and scalar filters (queue, worker, tags) — essential to close the UI asymmetry
- [x] QRY-02: Native job detail view (args, meta, errors, attempt history, timing fields) — required before actions are meaningful
- [x] QRY-03: Retry, cancel, discard actions with preview/reason/audit — the core differentiator that justifies native over bridge
- [x] QRY-04: Bulk retry/cancel/discard on the visible selection — high-value for operators managing retryable/discarded backlogs
- [x] API-01: Operator actions Elixir API (retry, cancel, discard) with actor, reason, and audit — enables automation and IEx operator sessions

### Defer Post-v1.5

- [ ] args/meta qualifier search — add after query limit and caching infrastructure is proven
- [ ] PubSub-backed real-time counts — add as a separate milestone targeting the `oban_met` dependency
- [ ] Job history tab (same-worker recent runs) — valuable but not blocking; add in a v1.5.x patch
- [ ] Deep-link from Lifeline job rows to native job detail (replacing Oban Web bridge link) — add after QRY-02 ships

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Job list with state + scalar filters (QRY-01) | HIGH | LOW | P1 |
| Job detail: args, meta, errors, timing (QRY-02) | HIGH | LOW | P1 |
| Retry/cancel/discard with preview/reason/audit (QRY-03) | HIGH | MEDIUM | P1 |
| Operator actions Elixir API (API-01) | HIGH | MEDIUM | P1 |
| Bulk retry/cancel/discard (QRY-04) | HIGH | MEDIUM | P1 |
| Job history tab (same-worker runs) | MEDIUM | MEDIUM | P2 |
| args/meta search qualifiers | MEDIUM | HIGH | P3 |
| PubSub live counts | LOW | HIGH | P3 |

---

## Existing Surface Analysis (Oban Web Bridge — What We're Closing)

| Feature | Oban Web bridge today | Native v1.5 approach |
|---------|-----------------------|----------------------|
| Job list by state | Yes — full state tabs | Yes — native state tabs |
| Filter by queue | Yes — `queues:` qualifier | Yes — dropdown or query param |
| Filter by worker | Yes — `workers:` qualifier | Yes — text or dropdown |
| Filter by tags | Yes — `tags:` qualifier | Yes — text or dropdown |
| args/meta search | Yes — `args.`, `meta.` qualifiers | Defer to post-v1.5 |
| Job detail: args, meta, errors | Yes | Yes — with DisplayPolicy redaction |
| Job detail: retry history | Yes — `job_history` shows last 60 | Yes — same pattern, native query |
| Retry action | Yes — immediate, no reason, no audit | Yes — preview/reason/audit required |
| Cancel action | Yes — immediate, no reason, no audit | Yes — preview/reason/audit required |
| Discard action | Yes — immediate, no reason, no audit | Yes — preview/reason/audit required |
| Bulk retry/cancel/discard | Yes — select all matching | Yes — scoped to visible selection |
| Elixir API | No | Yes — API-01 |

---

## Sources

- `Oban.Job` schema and `Oban.Job.states/0`: https://hexdocs.pm/oban/Oban.Job.html — HIGH confidence (official docs, verified against Oban 2.22.1 lockfile)
- `Oban.cancel_job/2`, `Oban.retry_job/2`, `Oban.cancel_all_jobs/2`, `Oban.retry_all_jobs/2`: https://hexdocs.pm/oban/Oban.html — HIGH confidence
- Oban Web filtering/qualifier system: https://oban.pro/docs/web/2.10.6/filtering.html — HIGH confidence (verified against Oban Web 2.12.4 lockfile)
- Oban Web `JobQuery` module: `/Users/jon/projects/oban_powertools/deps/oban_web/lib/oban/web/queries/job_query.ex` — HIGH confidence (source code in lockfile)
- Phoenix LiveView bulk selection pattern: https://fullstackphoenix.com/tutorials/add-bulk-actions-in-phoenix-liveview — MEDIUM confidence
- Existing Lifeline/Audit/LiveAuth surface: `/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex`, `web/lifeline_live.ex`, `web/live_auth.ex` — HIGH confidence (direct source read)

---

*Feature research for: Oban Powertools v1.5 Native Job Surface & Automation API*
*Researched: 2026-05-27*
