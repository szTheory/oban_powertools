# Pitfalls Research

**Domain:** Native job query surface and typed operator API added to an existing Phoenix/LiveView/Oban operator control plane
**Researched:** 2026-05-27
**Confidence:** HIGH — derived from direct inspection of the existing Lifeline pipeline, audit module, telemetry contract, ObanWebBridge, LiveAuth, and router; augmented with known Postgres/Oban/LiveView failure patterns.

---

## Critical Pitfalls

### Pitfall 1: Querying oban_jobs Without Index-Aware Filters — Seq Scans at Scale

**What goes wrong:**
A query filter combining `state`, `queue`, `worker`, and `tags` without matching the existing `oban_jobs` index layout degrades to a sequential scan. At 100k+ historical jobs (including completed and discarded), this blocks the repo connection pool during operator page load, which is the worst time — operators are usually looking at the UI because something is wrong.

**Why it happens:**
Developers reach for intuitive multi-column `WHERE` clauses (`state = 'available' AND queue = 'default' AND worker = 'MyWorker'`) without verifying which indexes Oban creates. Oban's default indexes favor `(state, queue)` and `(state, scheduled_at)` — a filter on `worker` alone or `tags` (JSONB) without a GIN index will not benefit from those. Tags filtering via `@>` against a non-GIN-indexed column is especially dangerous.

**How to avoid:**
- Inspect Oban's migration-generated indexes before designing the filter API. Run `\d oban_jobs` in psql to confirm which composite indexes exist.
- Make `state` the leading WHERE clause column in every query — it matches the most selective Oban index.
- Never offer a "filter by tags" option unless a GIN index on `tags` is in place. Either add the index in a Powertools migration or make tag filtering an explicit advanced feature with a query-cost warning.
- Use Ecto's `explain/2` on the query in test to detect seq scans before shipping.
- Enforce a page size limit (e.g., 50 rows) at the query layer, not only the rendering layer, so a user who removes all filters cannot accidentally issue `SELECT *`.

**Warning signs:**
- Filter queries taking > 200ms against a test dataset of 10k jobs.
- `EXPLAIN ANALYZE` showing `Seq Scan on oban_jobs` rather than `Index Scan`.
- Operator page load time increasing proportionally to total job count rather than result set count.

**Phase to address:** QRY-01 (native job listing) — must be the first design decision before any LiveView filter state work begins.

---

### Pitfall 2: Pagination State Living Only in LiveView Assigns — Lost on Filter Change

**What goes wrong:**
Cursor or offset pagination state stored in socket assigns resets silently when the operator changes a filter. The operator changes the queue filter, the page resets to 1, but the `before`/`after` cursor from the previous result set is still being applied in the background — returning an empty or wrong page. Alternatively, the URL encodes page number but not the filter parameters, so a refresh or a copied link lands on page 3 of a different filter set.

**Why it happens:**
LiveView makes it tempting to keep pagination state in assigns and filter state in separate assigns, treating them as independent. They are not. The cursor is only meaningful relative to the filter set that produced it.

**How to avoid:**
- Represent both filter state and pagination state together in the URL via `push_patch`. When any filter parameter changes, reset the page/cursor to initial.
- Use `handle_params/3` as the single point of truth for applying filter + pagination together. Never have two separate event handlers that each partially rebuild the query.
- Prefer keyset/cursor pagination over offset for `oban_jobs` — offset pagination degrades with large offsets and `oban_jobs` can have millions of rows. Use `id > :cursor` or `(scheduled_at, id)` as a stable cursor pair.
- Encode cursor in the URL only when there is an explicit "next page" navigation, not on every filter change.

**Warning signs:**
- A browser refresh on page 2 shows different rows than clicking "next" shows.
- Changing queue filter while on page 3 stays on "page 3" but shows fewer results than expected.
- The `handle_event("filter", ...)` and `handle_event("next_page", ...)` handlers both call the job query with slightly different parameter construction.

**Phase to address:** QRY-01 (listing) — define the filter+pagination URL contract before implementing any filter event handler.

---

### Pitfall 3: Action Buttons on the Job Listing That Bypass the Lifeline Preview Pipeline

**What goes wrong:**
A "Retry" or "Cancel" button directly on the job list row calls `Oban.retry_job/1` or sets `state = "cancelled"` inline, bypassing `Lifeline.preview_repair` and `Lifeline.execute_repair`. The repair audit event is not written. The plan_hash drift check is not applied. The action is not covered by reason capture. The operator later has no audit evidence for what they did or why.

**Why it happens:**
The native job browse surface looks like a CRUD interface. It is tempting to wire actions directly to Oban functions because Oban exposes them at `Oban.retry_job/1`, `Oban.cancel_job/1`, etc. The Lifeline pipeline feels like it is "for incidents" rather than for all audited operator actions.

**How to avoid:**
- The existing `Lifeline.execute_repair/4` multi-step pipeline (preview → drift check → mutate → audit → host follow-up) must be the only mutation path for retry, cancel, and discard operations — regardless of whether the job has an associated Incident record.
- The `build_job_preview` private function in `Lifeline` already handles the case where `incident` is `nil` (see `incident_fingerprint_for_job/2` and `infer_incident_class/1`). Extend that path rather than creating a parallel one.
- The new job actions phase (QRY-03) should add `action` atoms matching the existing `@supported_actions` list in `Lifeline`, not bypass it. If "discard" is a new action, add it to `@supported_actions` and implement its `mutate_target` clause there.
- Reason capture, preview token, and audit record are non-optional for all mutations. The LiveView for the job detail should replicate the exact preview → reason → execute → audit UX flow from `LifelineLive`.

**Warning signs:**
- Any code path that calls `Oban.retry_job/1`, `Oban.cancel_job/1`, or issues `UPDATE oban_jobs SET state = ...` directly from a LiveView `handle_event`.
- An audit event missing the `plan_hash`, `preview_token`, or `reason` metadata fields.
- A job action that does not write a `lifeline.repair_executed` audit event.

**Phase to address:** QRY-03 (native job actions) — this is the highest-risk phase and must design against the Lifeline pipeline from the start, not as a retrofit.

---

### Pitfall 4: Bulk Operations With No Partial Failure Handling — Silent Subset Failures

**What goes wrong:**
A bulk retry of 50 selected jobs sends all 50 through a single `Ecto.Multi` or a `Repo.update_all`. If even one job has drifted state (e.g., already completed since the operator selected it), the whole transaction rolls back and the operator sees a generic error with no indication of which jobs succeeded and which failed. Alternatively, each job is processed in an `Enum.map` with no transaction — partial success happens and there is no audit trail for which subset was actually mutated.

**Why it happens:**
Developers reach for `Repo.update_all` for efficiency (correct) but forget that audit records, plan_hash checks, and drift detection cannot be skipped in bulk mode. Or they iterate with individual `execute_repair` calls, which is slow and leaves partial success if the process crashes midway.

**How to avoid:**
- Bulk operations require a two-phase design: (1) preview phase that validates each job individually and collects preview tokens, (2) execute phase that runs each action and accumulates per-job results.
- Do not wrap all N jobs in one Ecto.Multi transaction. The correct model for bulk is: for each job, attempt the action in its own transaction, collect `{:ok, _}` or `{:error, reason}`. After all jobs are processed, write a single bulk audit summary event that records how many succeeded, failed, and why.
- Emit a per-job audit event for each successfully mutated job (reusing `Lifeline.execute_repair`), plus a single bulk-action summary audit event keyed to the operator's bulk action token.
- Surface per-job results back to the operator in the UI: "42 of 50 jobs retried. 8 jobs could not be retried (state changed). See audit for details."
- Reason is required at the bulk level — the operator provides one reason that applies to all jobs in the selection.

**Warning signs:**
- Bulk action UI shows only "success" or "failure" with no per-job breakdown.
- `Audit.list_all` for a bulk action shows either zero events (bypassed audit) or exactly N events with no summary event.
- A crash during bulk processing leaves the database in a state where some jobs are retried and no audit evidence exists.

**Phase to address:** QRY-04 (bulk operations) — design the per-job vs. bulk audit event schema before writing any bulk LiveView code.

---

### Pitfall 5: Double-Action via Rapid UI Click or Concurrent Operator Sessions

**What goes wrong:**
An operator clicks "Execute Retry" twice in quick succession, or two operators act on the same job concurrently from different browser sessions. The Lifeline pipeline's plan_hash drift check prevents the second `execute_repair` from running if state has changed — but the preview token is scoped per session, so two concurrent sessions each have their own "ready" preview and both may execute before either mutation completes.

**Why it happens:**
The current Lifeline pipeline uses the `preview_token` uniqueness as the idempotency key for a single session. When the same `target_id` + `action` combination is executed from two different actor sessions within the same clock tick, both can have valid "ready" previews simultaneously.

**How to avoid:**
- Add a database-level optimistic concurrency check at the job level. At `mutate_target` time for job actions, verify that `oban_jobs.state` has not changed from `preview.before_snapshot["state"]` using a `WHERE state = :expected_state` in the UPDATE. If the update affects 0 rows, the mutation failed due to concurrent modification.
- For the QRY-03 and API-01 phases, the `mutate_target` function should return `{:error, :concurrent_modification}` if the UPDATE affects 0 rows, not just assume success.
- The existing `ensure_not_drifted` drift check in Lifeline is the right pattern — extend it to also catch the concurrent same-state race at the UPDATE level, not only at the preview generation level.
- In the UI, use `phx-disable-with` on Execute buttons to prevent double-click within a single session. This does not prevent two operators, but it is the correct first layer.

**Warning signs:**
- Two audit events for the same `(target_id, action)` combination within the same second.
- A job that ends up in an unexpected state (e.g., double-cancelled with `cancelled_at` written twice).
- Tests that pass in isolation but fail under concurrent load.

**Phase to address:** QRY-03 for single-job actions; QRY-04 for bulk. The database-level UPDATE guard should be part of the initial `mutate_target` implementation, not a follow-up hardening phase.

---

### Pitfall 6: LiveView Filter State Growing Into an Unstructured Assign Bag

**What goes wrong:**
Each filter dimension (queue, state, worker, tags, inserted_after, scheduled_before) gets its own assign: `@queue_filter`, `@state_filter`, `@worker_filter`, etc. Each filter change event partially updates its own assign. The query builder reads from all of them. Over time, adding a new filter requires changing the event handler, the assign initialization, the query builder, the URL encoding, and the reset logic — in five different places with no type safety.

**Why it happens:**
LiveView encourages individual assigns for individual UI elements. The natural path is to add one assign per filter.

**How to avoid:**
- Define a single `%JobFilter{}` struct that holds all filter dimensions with typed fields. Initialize it from URL params in `handle_params`, not from `phx-value-*` events.
- A single `"apply_filters"` event replaces the entire filter struct from the submitted form params. There is no partial filter assignment.
- URL encoding and decoding go through a `JobFilter.from_params/1` and `JobFilter.to_params/1` pair. All filter-to-query translation happens in one `build_query(filter)` function.
- This struct should live in its own module (e.g., `ObanPowertools.Web.JobFilter`) because the API layer (API-01) will need to construct the same filter to run queries programmatically.

**Warning signs:**
- More than 4 individual filter-related assigns in the socket.
- A `handle_event("change_queue", ...)` handler that directly calls `assign(socket, :queue_filter, ...)`.
- A filter change that does not also reset pagination state.

**Phase to address:** QRY-01 (listing) — the filter struct must be designed before any LiveView event handlers are written.

---

### Pitfall 7: The Native Job Surface Duplicating Oban Web's Patterns Instead of Closing the UI Asymmetry

**What goes wrong:**
The native job listing recreates the Oban Web dashboard look and feel — including its raw job args/meta display, its state tabs, and its inspection-only posture. The result is two parallel job inspection surfaces with no clear ownership boundary, and operators use Oban Web for inspection and then navigate back to native pages for actions — defeating the purpose of the native surface.

**Why it happens:**
Oban Web is the mental model for "job listing." It is easy to replicate its UI patterns without questioning whether they serve the Powertools operator model.

**How to avoid:**
- The native job listing is a diagnosis-and-action surface, not a raw inspection dump. Its primary job is to get operators to the right job quickly and then perform audited actions — not to show raw args/meta.
- Apply `DisplayPolicy` to all args/meta rendering (the `ObanWebBridge` already demonstrates this pattern via `format_job_args` and `format_job_meta`). The native job detail must go through the same `DisplayPolicy.display(:job_args, ...)` seam.
- The Oban Web bridge (`/ops/jobs/oban`) should remain the destination for deep raw inspection. The native job detail page links to the bridge for "Open Generic Job Inspection in Oban Web bridge" — maintain this boundary and do not replicate raw inspection capability in the native detail page.
- The native surface should expose actions the bridge cannot: audited retry/cancel/discard with reason capture, preview, and audit trail. That is the differentiator.

**Warning signs:**
- The native job detail page renders raw `inspect(job.args)` or `Jason.encode!(job.args)` without going through `DisplayPolicy`.
- The native job listing has tabs mirroring Oban Web's `available | executing | scheduled | retryable | cancelled | discarded | completed` state tab strip.
- The native surface has no action buttons — it has become read-only inspection like the bridge.

**Phase to address:** QRY-02 (job detail) and QRY-03 (job actions) — the detail page design must start from the operator action workflow, not from raw data display.

---

### Pitfall 8: The Operator API (API-01) Allowing Unbounded Queries — Automation Misuse

**What goes wrong:**
The public Elixir API provides a `list_jobs/1` function that accepts arbitrary filter maps. Automation scripts pass no filters and iterate over all jobs. Or automation retries entire queues by calling `retry_job` in a loop. The API has no built-in limits, so it becomes an unbounded mutation surface under automation.

**Why it happens:**
Library APIs feel like they should be maximally flexible. Rate limiting and quotas feel like application concerns, not library concerns.

**How to avoid:**
- `list_jobs/1` must have a mandatory `:limit` option with a hard ceiling (e.g., max 500). The default limit should be 50. Omitting limit does not mean "all jobs" — it means the default limit applies.
- Bulk mutation functions (`retry_jobs/2`, `cancel_jobs/2`) must accept a list of job IDs, not a filter. The caller is responsible for retrieving the IDs and selecting the scope. This prevents "retry all failed jobs" from being a single function call.
- All mutation functions in the API must go through the same Lifeline pipeline as the UI — preview, drift check, reason, audit. The API does not expose a "fast path" that skips preview.
- Design the typed API around `actor` as a required first argument. Every mutation function signature is `action(repo, actor, ...)`. This mirrors the existing `Lifeline.execute_repair(repo, actor, ...)` pattern and makes audit attribution non-optional.
- Document what the API does not do: it does not replace a cron system, it does not enable queue draining automation, and it does not expose raw DB writes.

**Warning signs:**
- `list_jobs(repo, %{})` returns all jobs (no limit applied).
- Any API function that does not require an `actor` argument.
- Any API function that directly calls `Oban.retry_job/1` or `Repo.update_all` without going through the audit pipeline.

**Phase to address:** API-01 — define the typed function signatures and required options before implementing any API function body.

---

### Pitfall 9: Telemetry Cardinality Explosion From Job-Level Metadata

**What goes wrong:**
New telemetry events for job actions include job-specific metadata — `worker`, `queue`, `job_id`, or `reason` — as metadata keys. These become high-cardinality dimensions in metrics systems (Prometheus, Datadog). A monitor that previously had 5 time series now has 5 × N_workers × N_queues × N_reasons time series. The metric store runs out of label cardinality budget and starts dropping events.

**Why it happens:**
The natural way to enrich a telemetry event with context is to add all available context. `worker`, `queue`, and `job_id` all feel like "low-cardinality" until the system has 50 workers and 20 queues.

**How to avoid:**
- The existing `Telemetry` module's public contract (defined in `@contract`) is the constraint boundary. Adding new events for job actions must follow the same low-cardinality rule: allowed metadata keys are `:action`, `:source`, `:target_type`, `:outcome`. Not `:worker`, `:queue`, `:job_id`, `:reason`.
- The new operator_action family is the right home for job action telemetry: `[:oban_powertools, :operator_action, :job_action_executed]` with `%{count: 1}` measurement and `%{action: "retry", source: "ui"|"api", outcome: "ok"|"error"}` metadata. Queue and worker identity belong in audit events, not telemetry events.
- If `queue` or `worker` is truly needed for observability, add them to the `@contract` as explicit low-cardinality additions and document the cardinality expectation.
- The `Telemetry.execute_operator_action/3` function already exists — use it, do not add a new `execute_job_action/3` variant that bypasses the contract.

**Warning signs:**
- A new telemetry event call that passes `worker: job.worker` or `queue: job.queue` or `job_id: job.id` as metadata.
- A new event family added outside the five frozen families in `@contract`.
- An event that passes `reason: reason` from free-form user input as a metadata key.

**Phase to address:** QRY-03 (actions) and API-01 (api mutations) — check telemetry metadata against the contract before writing any `Telemetry.execute_*` call.

---

### Pitfall 10: The Selectors Module Not Extended for Job Surface Paths — Inconsistent Deep-Link URLs

**What goes wrong:**
New pages (`/ops/jobs/jobs`, `/ops/jobs/jobs/:id`) generate their URLs with hardcoded path strings or `Routes.live_path(...)` calls rather than going through the `Selectors` module. Other pages that deep-link into a job detail (e.g., Lifeline's "Open Generic Job Inspection in Oban Web bridge" link) use `build_job_path(@oban_dashboard_path, job_id)` — a private helper. The result is two different helpers for job paths, with no canonical contract.

**Why it happens:**
`Selectors` currently only has entries for the 5 existing destinations (`:lifeline`, `:forensics`, `:audit`, `:limiters`, `:cron`). Adding new paths to `Selectors` requires updating `@canonical_paths`, which might feel like extra work for the first phase.

**How to avoid:**
- Add `:jobs` and `:job_detail` to `@canonical_paths` in `Selectors` when adding the new routes to the router. `job_path/1` and `job_detail_path/1` should be public helpers on `Selectors`, not private helpers on individual LiveView modules.
- The existing `build_job_path(@oban_dashboard_path, job_id)` helper in `LifelineLive` is a bridge path (Oban Web), not a native path. Keep it. Add a separate `Selectors.job_detail_path/1` for the native job detail.
- When `LifelineLive` or `ForensicsLive` links to the native job detail in QRY-02, they should use `Selectors.job_detail_path([{"id", job_id}])`, not a hardcoded `"/ops/jobs/jobs/#{job_id}"`.

**Warning signs:**
- A hardcoded `"/ops/jobs/jobs"` string anywhere outside of `Selectors` or the router.
- A `link` or `navigate` in any LiveView that constructs a job path with string interpolation rather than calling `Selectors`.
- The router adds new routes for job pages but `Selectors.@canonical_paths` is not updated.

**Phase to address:** QRY-01 — add the canonical paths to `Selectors` when adding the routes, not after.

---

### Pitfall 11: Auth Actions Not Declared for Job Operations — Silent Read-Only Default

**What goes wrong:**
The native job listing and detail pages load and render without any auth check because `LiveAuth.authorize_page` is only called for actions that are already enumerated (`:view_lifeline`, `:view_oban_web`). The job surface is accessible to any authenticated user with no per-action check. When job actions are added, the action atoms (e.g., `:retry_job`, `:cancel_job`) are not in the host's auth module because the host was never told they were expected — so all job mutations silently fail auth and appear disabled with no explanation.

**Why it happens:**
Each new page and action type requires a corresponding auth action atom. The host application must enumerate these in its auth module. If the new atoms are not documented clearly, the host keeps the old module and operators wonder why the buttons are always greyed out.

**How to avoid:**
- Define and document the new auth action atoms in `LiveAuth`'s `@permission_messages` map before the pages ship: `:view_jobs`, `:retry_job`, `:cancel_job`, `:discard_job`.
- Add corresponding `@page_read_only_banners` entries for the jobs surface.
- The `LiveAuth.authorize_page` call must be present in `mount/3` of `JobsLive` and `JobDetailLive`, not skipped.
- The example-host test app must add the new atoms to its fake auth module — this is the integration proof that the auth contract is complete.
- Write a docs-contract test that verifies the new action atoms are documented in the operator guide.

**Warning signs:**
- A new `JobsLive` that calls `mount/3` without a `LiveAuth.authorize_page` call.
- Action buttons in `JobDetailLive` that are always disabled because `LiveAuth.authorized?(actor, :retry_job, ...)` always returns false (the action is not in the host's auth module).
- No new atoms added to `@permission_messages` in `LiveAuth`.

**Phase to address:** QRY-01 (listing) — declare the auth atoms when creating the page, not when adding actions.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Using `Audit.list_all/0` to find job-related audit events | Simple, no query optimization needed | Full table scan on audit_events; breaks as audit log grows | Never for production; acceptable only in test harness |
| Skipping `DisplayPolicy` for job args/meta on the native detail page | Faster initial implementation | Leaks redacted fields; breaks the bridge/native display-policy parity contract | Never — apply `DisplayPolicy` from the first render |
| Putting `filter` state in raw assigns instead of a `%JobFilter{}` struct | Fewer files to create initially | Each new filter dimension requires touching 5 places; no type safety | Never — define `%JobFilter{}` before writing any filter handler |
| Using `Repo.update_all` for bulk job state changes without per-row audit | Single query, very fast | No audit trail; no per-job drift detection; silent partial failures on constraint violations | Never — audit trail is a hard constraint |
| Hardcoding the Lifeline `@supported_actions` list: not extending it for new job action atoms | Avoids touching the existing `Lifeline` module | New actions bypass the centralized action guard; support-truth breaks | Never — add new atoms to `@supported_actions` in `Lifeline` |
| Offset-based pagination for the job listing | Simpler to implement initially | Degrades with large offsets on high-volume oban_jobs tables | Acceptable for MVP only if total job count is known to be < 50k |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Oban Web bridge (`/ops/jobs/oban`) | Adding a native "job listing" that looks identical to Oban Web, causing operators to be unsure which surface owns mutations | Native listing is action-first (retry/cancel/discard with audit); bridge stays inspection-only. Link from native detail to bridge for raw args/meta inspection. |
| Lifeline `preview_repair` / `execute_repair` | Calling Oban functions directly for retry/cancel, bypassing the pipeline | All job mutations must go through `Lifeline.execute_repair` with a valid preview token, even for jobs with no associated Incident |
| `Telemetry.execute_operator_action` | Adding `worker:` or `queue:` metadata keys to telemetry events | Only low-cardinality atoms from the frozen `@contract` are allowed as metadata keys |
| `Audit.list_all/0` | Using it to find audit events for a specific job on the job detail page | Use `Audit.list/1` with `%{type: :job, id: job_id}` or `Audit.list_all/2` with filters; never load the full audit table into memory |
| `DisplayPolicy` | Rendering `job.args` or `job.meta` directly in HEEx without going through `DisplayPolicy.display/3` | Call `DisplayPolicy.display(:job_args, job.args, %{surface: :jobs, ...})` for every args/meta render; fall back to redacted placeholder if display policy returns nil |
| `Selectors` module | Creating private path helpers in LiveView modules for job URLs | Add `:jobs` and `:job_detail` to `Selectors.@canonical_paths` and use `Selectors.job_path/1`, `Selectors.job_detail_path/1` |
| `LiveAuth` permission messages | Using a new job action atom in `authorize_action` that is not in `@permission_messages` | Causes a `Map.fetch!` error at runtime — add the atom to `@permission_messages` before using it |
| `LifelineLive`'s `build_job_path` helper | Repurposing it for native job detail links | Keep `build_job_path` for the bridge (Oban Web URL); add a separate `Selectors.job_detail_path/1` for native destination links |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Filter query without `state` as leading WHERE clause | Slow listing page; DB CPU spike on operator actions | Always lead with `state` in the WHERE clause; it matches the most selective Oban index | Beyond ~50k total oban_jobs rows |
| JSONB tag filter without GIN index | Filter by tags takes seconds | Either add a migration for a GIN index on `tags`, or exclude tag filtering from the initial feature set | Beyond ~10k rows |
| Loading all audit events for a job with `Audit.list_all/0` + Enum.filter | Audit tab on job detail slows as audit log grows | Use `Audit.list/1` with a resource identifier; add DB-level filter | Beyond ~5k audit events |
| Bulk operation iterating N individual `execute_repair` calls synchronously | Bulk retry of 100 jobs takes 30+ seconds; UI times out | Batch preview generation, then parallel-safe per-job execute with aggregated results | Beyond ~20 jobs selected |
| No `LIMIT` in the API `list_jobs` query | Full table scan from automation scripts | Enforce a hard limit in the query builder; reject requests with no explicit limit above ceiling | Any automation script |
| Offset pagination on oban_jobs | Page 50+ is slower than page 1 due to scan-then-skip | Use keyset/cursor pagination with `(state, id)` as cursor | Beyond page 10 with large result sets |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Exposing full `job.args` / `job.meta` without `DisplayPolicy` | Leaks sensitive data (PII, credentials, internal IDs) in the operator UI | Apply `DisplayPolicy.display(:job_args, ...)` on every render; never pass raw args to the template |
| API-01 functions that accept `actor: nil` or skip `actor` | Any system process can perform audited mutations without attribution | All API mutation functions require a non-nil `actor`; `Auth.actor_id(nil)` returning nil must be a hard error, not a soft skip |
| Bulk cancel/discard on an unbounded job set from the API | An automation script cancels the entire production queue | `cancel_jobs` and `discard_jobs` require an explicit list of job IDs, never a filter-and-all pattern |
| Job detail page accessible without `authorize_page` auth check | Any authenticated user can inspect operator job details including worker module name and routing metadata | Every `mount/3` in `JobsLive` and `JobDetailLive` must call `LiveAuth.authorize_page(socket, :view_jobs, ...)` |
| `reason` field from user input included as a telemetry metadata key | Free-form user text creates high-cardinality and potential injection in metrics labels | `reason` is stored in audit events only; it must never appear as a telemetry metadata key |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Job listing defaults to showing all states | Operators see thousands of completed jobs and cannot find actionable jobs | Default filter to `state in [available, executing, scheduled, retryable]`; require explicit opt-in to show completed/discarded |
| Retry/cancel buttons visible but always disabled (auth misconfiguration) | Operators assume the feature is broken; support load increases | Show the read-only banner from `LiveAuth.page_read_only_banner/1` and link to the doc on configuring the new auth atoms |
| Bulk select does not show a count of selected jobs | Operator selects 200 jobs by accident | Show selected count prominently; require a confirmation step for bulk actions over a threshold (e.g., > 10 jobs) |
| Job detail page does not link back to the job listing with preserved filters | Operator drills into a job, acts on it, then loses their filter context | Use `push_patch` or a "Back to list" link that preserves the filter URL params |
| After a job action succeeds, the page does not update the job's state | Operator thinks the action failed and clicks again | Reload the job record after a successful `execute_repair` and update the assigns; show the new state prominently |
| Oban Web bridge link appears even when Oban Web is not installed | Broken link confuses operator | Conditionally render the bridge link only when `Code.ensure_loaded?(Oban.Web.Router)` is true — same pattern the router already uses |

---

## "Looks Done But Isn't" Checklist

- [ ] **Job listing filters:** Filter state is in a `%JobFilter{}` struct encoded in URL params — not in raw assigns — verify with a `push_patch` test that filter changes preserve the URL.
- [ ] **Job detail DisplayPolicy:** Every `job.args` and `job.meta` render goes through `DisplayPolicy.display/3` — verify by checking no HEEx template calls `Jason.encode!(job.args)` or `inspect(job.args)`.
- [ ] **Job actions audit trail:** Every retry/cancel/discard action writes a `lifeline.repair_executed` audit event with `plan_hash`, `preview_token`, and `reason` — verify with an audit log assertion in the action test.
- [ ] **Bulk partial failure reporting:** A bulk action test that has 2 of 5 jobs already in terminal state reports exactly 3 successes and 2 failures back to the operator — verify with a mixed-state fixture test.
- [ ] **API-01 actor requirement:** Every API mutation function raises or returns `{:error, :actor_required}` when called with `actor: nil` — verify with a nil-actor unit test for each public function.
- [ ] **Telemetry cardinality:** No new telemetry event includes `worker`, `queue`, `job_id`, or `reason` as metadata keys — verify with a `Telemetry.contract/0` assertion test against the new events.
- [ ] **Auth atoms documented:** The new auth action atoms (`:view_jobs`, `:retry_job`, `:cancel_job`, `:discard_job`) are listed in `LiveAuth.@permission_messages` and in the operator guide — verify with the docs-contract test pattern from Phase 38.
- [ ] **Selectors extended:** `Selectors.job_path/1` and `Selectors.job_detail_path/1` exist and are used by all cross-surface links — verify by grepping for hardcoded `"/ops/jobs/jobs"` strings outside of `Selectors` and the router.
- [ ] **Oban Web bridge boundary preserved:** The native job detail page links to the bridge for raw inspection but does not replicate it — verify that there is no second `format_job_args`/`format_job_meta` call path outside of `ObanWebBridge`.
- [ ] **Concurrent action guard:** The `mutate_target` implementation for job actions includes a `WHERE state = :expected_state` guard that returns `{:error, :concurrent_modification}` on 0-row updates — verify with a concurrent-update integration test.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Job listing seq scan discovered in production | MEDIUM | Add missing index via migration (Oban's JSONB `tags` GIN index or `(state, worker)` composite); can be done concurrently without downtime using `CONCURRENTLY` |
| Actions found to bypass Lifeline pipeline | HIGH | Retroactive audit events are impossible for already-lost records; implement the Lifeline pipeline correctly going forward; publish a support-truth notice to adopters |
| Telemetry high-cardinality events already shipped | HIGH | Requires removing or replacing metric label dimensions; existing dashboards break; requires coordinated rollout with host apps |
| Bulk operation partial failures with no audit trail | HIGH | Audit log gap is unrecoverable — affected jobs must be manually investigated and re-audited; implement proper per-job audit events going forward |
| Filter state in raw assigns causing stale pagination | LOW | Refactor to `%JobFilter{}` struct + URL-encoded state; no data loss, only UI regression |
| API-01 shipped without actor requirement | MEDIUM | Add actor validation and bump API version; document breaking change; automation scripts need update |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Seq scan on oban_jobs filters | QRY-01 (listing) — index analysis before query design | `EXPLAIN ANALYZE` on filter query in test; assert no Seq Scan |
| Pagination state reset on filter change | QRY-01 (listing) — define `%JobFilter{}` + URL contract | Test: change queue filter, assert cursor resets; page URL changes |
| Actions bypassing Lifeline pipeline | QRY-03 (actions) — design constraint, not retrofit | Test: every action writes `lifeline.repair_executed` audit event with required metadata fields |
| Bulk partial failure handling | QRY-04 (bulk) — per-job result accumulation design | Test: mixed-state bulk fixture reports per-job success/failure |
| Double-action race condition | QRY-03 and QRY-04 — `WHERE state = expected` guard in `mutate_target` | Concurrent-update test: two simultaneous executes, only one succeeds |
| Filter state as raw assigns | QRY-01 (listing) — `%JobFilter{}` struct defined first | No single filter-dimension assign in socket; all filter in one struct |
| Native surface duplicating Oban Web | QRY-02 (detail) — design review before first template render | Check: no `inspect(job.args)` or `Jason.encode!(job.args)` in any native template |
| API-01 unbounded queries | API-01 — mandatory `:limit` in API spec | Test: calling `list_jobs(repo, actor, %{})` with no limit applies default limit; limit ceiling is enforced |
| Telemetry cardinality explosion | QRY-03 and API-01 — `@contract` check before any `Telemetry.execute_*` call | Test: telemetry events for job actions assert no high-cardinality metadata keys |
| Selectors not extended for job paths | QRY-01 — add to `Selectors.@canonical_paths` with route addition | Test: no hardcoded job path strings outside Selectors; `job_path/1` and `job_detail_path/1` exist |
| Auth atoms not declared | QRY-01 — add to `LiveAuth.@permission_messages` before `authorize_page` call | Test: new atoms in `@permission_messages`; example-host auth module includes new atoms |

---

## Sources

- Direct inspection of `ObanPowertools.Lifeline` (preview pipeline, `@supported_actions`, `mutate_target`, `ensure_not_drifted`, `plan_hash` drift check)
- Direct inspection of `ObanPowertools.Web.LifelineLive` (Lifeline UX, audit event filtering, filter/selection state patterns, `build_job_path` bridge helper)
- Direct inspection of `ObanPowertools.Audit` (`list_all/0` full-scan pattern, `list/1` resource-scoped pattern, `list_all/2` filter variant)
- Direct inspection of `ObanPowertools.Telemetry` (`@contract` frozen families, low-cardinality constraint, `execute_operator_action/3`)
- Direct inspection of `ObanPowertools.Web.ObanWebBridge` (DisplayPolicy application pattern for `format_job_args` and `format_job_meta`)
- Direct inspection of `ObanPowertools.Web.LiveAuth` (`@permission_messages`, `@page_read_only_banners`, `authorize_page/3`, `authorize_action/4`)
- Direct inspection of `ObanPowertools.Web.Selectors` (canonical path contract, `@canonical_paths`, current 5-destination scope)
- Direct inspection of `ObanPowertools.Web.Router` (route structure, `Code.ensure_loaded?(oban_web_router)` conditional pattern)
- Known Postgres `oban_jobs` index layout (state/queue/scheduled_at composite, no default GIN on tags)
- v1.4 requirements archive (API-02 and QRY-01 deferred context, telemetry low-cardinality contract from POL-03)

---
*Pitfalls research for: native job query surface and typed operator API (v1.5 — QRY-01..04, API-01)*
*Researched: 2026-05-27*
