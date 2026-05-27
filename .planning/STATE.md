---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Native Job Surface & Automation API
status: executing
stopped_at: Phase 43 UI-SPEC approved
last_updated: "2026-05-27T23:04:55.298Z"
last_activity: 2026-05-27 -- Phase 43 planning complete
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 3
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-27)

**Core value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.
**Current focus:** Phase 43 — Read-Only Job Browse (QRY-01, QRY-02)

## Current Position

Phase: 43 — Read-Only Job Browse
Plan: —
Status: Ready to execute
Progress: [ ] [ ] [ ] [ ] — 0/4 phases complete

Last activity: 2026-05-27 -- Phase 43 planning complete

## Performance Metrics

- Phases: 0/4 complete
- Plans: 0/? complete

## Accumulated Context

### Decisions

See PROJECT.md Key Decisions section for the full locked decision list.

**v1.5 decisions:**

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

- Run `/gsd:plan-phase 43` to begin Phase 43 planning.

### Blockers

None.

## Session Continuity

- **Last session:** 2026-05-27T22:34:22.798Z
- **Stopped at:** Phase 43 UI-SPEC approved
- **Next action:** `/gsd:plan-phase 43` — Read-Only Job Browse (QRY-01 + QRY-02)
