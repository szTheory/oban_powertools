# Phase 59 Context: Schemas & Foundation

**Goal:** Establish the core Ecto data model for batch tracking and the callback outbox

<spec_lock>
Requirements are locked by SPEC.md / ROADMAP.md — discussing implementation decisions only.
</spec_lock>

## Canonical Refs
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`

## Decisions

### Callback Outbox Evolution
- **Decision:** Rename and generalize the existing `oban_powertools_workflow_callback_outbox` to `oban_powertools_callbacks`.
- **Rationale:** We already have a durable transactional outbox used by v1.2 Workflows. Having two outboxes (one for workflows, one for batches/chains) creates operator confusion and polling overhead. A single generalized outbox (`callbacks`) is idiomatic Ecto, adheres to the principle of least surprise, and ensures uniform Lifeline recovery for stuck callbacks regardless of whether they originated from a workflow, a batch, or a chain.

### Progress Tracking Structure
- **Decision:** Explicit integer counters on the `batches` row (`total_count`, `success_count`, `discard_count`, `cancelled_count`, `snooze_count`), updated atomically via `Repo.update_all(inc: [...])`.
- **Rationale:** Computing progress via `SELECT count(*)` on a `batch_jobs` join table is too slow for the UI and creates race conditions for callback execution. Explicit counters provide O(1) reads for the LiveView dashboard (crucial for UX). To prevent Postgres lock starvation during massive concurrent completions (BAT-03), updates will be performed atomically using Ecto's `inc` in `update_all` without pre-fetching the row, wired into the v1.7 worker lifecycle hooks.

### Chain Representation
- **Decision:** No separate `chains` table. Model Chains as syntactic sugar over the `callbacks` outbox and `batches` schema.
- **Rationale:** A chain is fundamentally a linear sequence where Job A's success callback enqueues Job B. Introducing a `chains` table creates schema bloat and overlapping responsibility with `workflows`. By treating a chain as a Batch (for grouping/UI visibility) where progression is handled via the Callback Outbox, we reuse the exact same recovery, telemetry, and execution primitives. This keeps the data model lean and adheres to the architectural vision of strong primitives composing into higher-order features.

## Code Context
- Reusing patterns from `ObanPowertools.JobRecord` for schema definitions.
- Migrating `ObanPowertools.Workflow.CallbackOutbox` to `ObanPowertools.Callback`.
