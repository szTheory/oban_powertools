---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Native Job Surface & Automation API
status: complete
stopped_at: Milestone v1.5 completed and archived
last_updated: "2026-05-28T21:18:09.001Z"
last_activity: 2026-05-28 — Milestone v1.5 completed and archived
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 9
  completed_plans: 9
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-28)

**Core value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.
**Current focus:** Planning next milestone (v1.5 shipped)

## Current Position

Phase: Milestone v1.5 complete (Phases 43-46)
Plan: —
Status: Awaiting next milestone
Last activity: 2026-05-28 — Milestone v1.5 completed and archived

## Accumulated Context

### Decisions

See PROJECT.md Key Decisions section for the full locked decision list. v1.5 locked decisions:

- All native job mutations (UI and API) route through `Lifeline.execute_repair` — no direct `Oban` calls and no parallel mutation path.
- The Operator API requires a non-nil actor for every action and emits `source: "api"` telemetry within the frozen low-cardinality `@contract`.
- Bulk operations run an independent repair per job (no single `Ecto.Multi` over N jobs); missing jobs register as `:not_found` failures rather than aborting the batch.
- Pagination is offset-based with a documented single-function keyset upgrade path; tags filtering depends on a host-owned GIN index on `oban_jobs.tags`.

**Post-v1.5 assessment decisions (2026-05-28, see `threads/2026-05-28-post-v1.5-next-milestone.md`):**

- Hex publication is a near-term goal; first public release at `0.x` (recommend `0.5.0`) before committing to `1.0`.
- Recommended next milestone = **v1.6 Release & Operability** (publish + `mix oban_powertools.doctor` + limiter explain/simulate CLI + Parapet telemetry guide; no `oban_met` dep).
- Ordering after: v1.7 Worker Lifecycle & Safety → v1.8 Batches & Composition → v1.9 live counts → polish.
- Worker-Lifecycle must precede Batches (dependency: batch callbacks reuse the hook contract; output recording reuses a generalized `Workflow.Result` table).
- Done-% ~87% (band 80–89); mild overbuilding risk — ship the release before adding more capability.

### Todos

- Recommended: `/gsd:new-milestone` scoping **v1.6 Release & Operability** (see `threads/2026-05-28-post-v1.5-next-milestone.md`). Fresh REQUIREMENTS.md will be created.

### Blockers

None.

## Operator Next Steps

- `/clear`, then `/gsd:new-milestone` to scope v1.6.
