# Phase 60: Execution Engine & Tracker Hooks - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Exactly-once progress tracking transactionally wired into v1.7 worker lifecycle hooks, and execution of completion callbacks via the generalized callback outbox when batch targets are met.
</domain>

<decisions>
## Implementation Decisions

### Exactly-Once Progress Tracking
- **D-01:** Prevent double-increments on BEAM crashes using a lightweight `batch_progress` idempotency table (`batch_id`, `job_id`, `state`).
- **D-02:** Execute `INSERT INTO oban_powertools_batch_progress ... ON CONFLICT DO NOTHING` inside the worker hook.
- **D-03:** If the insert succeeds, execute `Repo.update_all(inc: [success_count: 1])` to increment the batch total safely without locking the `batches` table row.

### Completion Callback Triggering
- **D-04:** Handle callback enqueueing directly in the worker hook via a `RETURNING *` clause on the `update_all`.
- **D-05:** If `success_count + discard_count == total_count` and `completed_at` is null, update `completed_at` (acting as a race condition guard) and transactionally insert the callback into `oban_powertools_callbacks`.

### Callback Failure Recovery
- **D-06:** Callbacks are standard Oban Jobs enqueued via the outbox. If a callback exhausts its retries, transition the Batch state to `callback_failed`.
- **D-07:** Surface failed callbacks in the native `/ops/jobs/batches` UI.
- **D-08:** Require the Operator to repair failed callbacks explicitly using the established Lifeline preview/reason/execute pipeline.

### Claude's Discretion
None. All areas resolved via one-shot recommendation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope & Decisions
- `.planning/ROADMAP.md` — Active milestone and phase breakdown.
- `.planning/REQUIREMENTS.md` — Core validated requirements (BAT-03, BAT-04).
- `.planning/phases/59-schemas-foundation/59-CONTEXT.md` — Phase 59 data model decisions (schema fields, counters, unified `oban_powertools_callbacks` outbox).

### Prompts & Strategy
- `prompts/oban_powertools_context.md` — Oban Powertools domain context, architectural bounds, operator boundaries, and batch strategy.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — Powertools Web UI design boundaries and principles.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Worker.Hooks.after_result/3` / `after_exception/5`: The established hooks where the progress tracking and `RETURNING` updates will be wired.
- `ObanPowertools.Lifeline`: The explicit repair and audit pipeline to be reused for "Retry Callback" actions.

### Established Patterns
- `Repo.update_all` inside hooks: Pattern established in `ObanPowertools.Cron.maybe_insert_job` for atomic updates without locking.
- Explicit Support-Truth Boundaries: Surface failing states (like `callback_failed`) clearly in the UI rather than hiding or infinitely retrying them.

### Integration Points
- `/ops/jobs/batches`: The LiveView UI where `callback_failed` states will eventually surface (built in Phase 62, but state enums defined now).
- `ObanPowertools.Batch`: The core schema updated in Phase 59, which will receive the `completed_at` timestamp.

</code_context>

<specifics>
## Specific Ideas

- Adhere to the established Postgres idiom `INSERT ON CONFLICT DO NOTHING` for idempotency inside the worker hook.
- Emphasize native operator visibility via Lifeline repairs over implicit, magical retries.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed strictly within the execution engine tracking scope.

</deferred>

---

*Phase: 60-Execution Engine & Tracker Hooks*
*Context gathered: 2026-06-14*
