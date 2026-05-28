---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Native Job Surface & Automation API
status: planning
stopped_at: Phase 44 execution completed
last_updated: "2026-05-28T20:30:58.535Z"
last_activity: 2026-05-28
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 9
  completed_plans: 8
  percent: 75
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-27)

**Core value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.
**Current focus:** Phase 44 — single-job-actions (completed)

## Current Position

Phase: 46
Plan: 01
Status: Executing Phase 46
Progress: [█████████░] 89%

Last activity: 2026-05-28

## Performance Metrics

- Phases: 2/4 complete
- Plans: 5/5 complete
| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 46    | 01   | 2m       | 2     | 4     |

## Accumulated Context

### Decisions

See PROJECT.md Key Decisions section for the full locked decision list.

**v1.5 decisions:**

- Operator API explicitly requires an actor map for all actions, maintaining strict authorization boundaries.
- Programmatic actions always route through the Lifeline preview and execute flows rather than directly mutating the job database, ensuring full auditability and host callbacks.
- Telemetry metadata is threaded down through opts and merged into the final telemetry event, allowing the Operator module to identify itself via source: api.

- Phase order is non-negotiable: QRY-01 leads (zero Lifeline risk); QRY-03 must come after QRY-02 (actions anchor to detail context); QRY-04 iterates the single-job pipeline proven in Phase 44; API wraps last so signatures derive from the proven UI pipeline.
- All mutations must route through `Lifeline.execute_repair` — no direct `Oban` function calls from LiveViews or the API module.
- `%JobFilter{}` struct must be defined before any event handler is written in Phase 43.
- Tags filtering requires a host-owned GIN index on `oban_jobs.tags` — document in module docs and host guide, do not block Phase 43 on it.
- `RepairPreview.incident_id` nullability must be confirmed before Phase 44 begins.
- `LiveAuth.@permission_messages` atoms to declare before Phase 43: `:view_jobs`, `:view_job_detail`, `:retry_job`, `:cancel_job`, `:discard_job`.
- Pagination: offset-based for Phase 43; keyset upgrade path made explicit as a single function change in `ObanPowertools.Jobs.list/3`.
- Telemetry: `source: "api"` in API call metadata; `worker`, `queue`, `job_id`, `reason` must never appear as telemetry metadata keys.
- No `Ecto.Multi` wrapping all N bulk jobs — each runs its own `Lifeline.execute_repair` with result accumulation.

### Todos

- Run `/gsd-plan-phase 45` to begin Phase 45 planning.

### Blockers

None.

## Session Continuity

- **Last session:** 2026-05-28T20:30:58.532Z
- **Stopped at:** Phase 44 execution completed
- **Next action:** `/gsd-plan-phase 45` — Bulk Operations (QRY-04)
