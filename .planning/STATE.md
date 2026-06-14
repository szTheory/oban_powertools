---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: milestone
status: ready_to_plan
last_updated: "2026-06-14T19:27:11.797Z"
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 10
  completed_plans: 6
  percent: 50
---

# Project State

## Project Reference

**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

**Current Focus:** Phase 61 — apis-batches-chains

## Current Position

Phase: 61 (apis-batches-chains) — EXECUTING
Plan: 2 of 5
| Phase | Plan | Status | Progress |
|-------|------|--------|----------|
| 59. Schemas & Foundation | None | 🟡 Planning | `[          ] 0%` |

## Performance Metrics

| Metric | Target | Current | Notes |
|--------|--------|---------|-------|
| Test Coverage | >95% | - | - |
| Type Checking | 0 Dialyzer errors | - | - |
| Linting | 0 Credo warnings | - | - |
| Phase 61-apis-batches-chains P01 | 3 min | 2 tasks | 6 files |

## Accumulated Context

### Architectural Decisions

- Dedicated `batches` / `batch_jobs` / `callbacks` tables (not overloading `oban_jobs` meta).
- Generalized callback outbox for execution of `completed` and `exhausted` callbacks.
- Exactly-Once progress tracking wired transactionally into v1.7 worker lifecycle hooks.
- Chains as linear-DAG sugar built on top of the callback outbox.
- No `libgraph` or Redis dependencies allowed.

### Known Technical Debt / Todos

- TBD

### Blockers / Open Questions

- None currently

## Session Continuity

- **Last Action:** Completed 61-01 durable batch insertion metadata
- **Next Action:** Execute 61-02 Batch.insert_stream/2
- **Active Context:** Phase 61 plan 01 added durable batch insertion metadata fields and installer contract; 61-02 can build Batch.insert_stream/2 on these fields.

## Decisions

- Phase 61 batch insertion metadata is additive to the Phase 59 batch table because the batch table has not shipped publicly yet.
- The installer template and test migration use the same metadata columns and status/name indexes to keep host installs aligned with test storage.
