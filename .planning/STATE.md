---
gsd_state_version: 1.0
milestone: v1.6
milestone_name: Release & Operability
status: planning
last_updated: "2026-05-29T00:50:47.887Z"
last_activity: 2026-05-29
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-28)

**Core value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.
**Current focus:** Planning next milestone (v1.5 shipped)

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-05-29 — Milestone v1.6 started

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
