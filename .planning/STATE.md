---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: milestone
status: ready_to_plan
last_updated: "2026-06-14T21:33:19.633Z"
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 10
  completed_plans: 9
  percent: 90
---

# Project State

## Project Reference

**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

**Current Focus:** Phase 61 — apis-batches-chains

## Current Position

Phase: 61 (apis-batches-chains) — EXECUTING
Plan: 5 of 5
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
| Phase 61-apis-batches-chains P02 | 3 min | 2 tasks | 2 files |
| Phase 61-apis-batches-chains P03 | 5 min | 2 tasks | 3 files |
| Phase 61-apis-batches-chains P04 | 6 min | 2 tasks | 6 files |

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

- **Last Action:** Completed 61-04 event-scoped chain callback progression
- **Next Action:** Execute 61-05 durable upstream output handoff and safe args builders
- **Active Context:** Phase 61 plan 04 added `chain.step_succeeded` callback rows, host callback event filtering, tracker-emitted chain progression callbacks, and `ObanPowertools.Chain.Progression.dispatch_callbacks/2` for retryable next-step enqueueing through the callback outbox.

## Decisions

- Phase 61 batch insertion metadata is additive to the Phase 59 batch table because the batch table has not shipped publicly yet.
- The installer template and test migration use the same metadata columns and status/name indexes to keep host installs aligned with test storage.
- Batch.insert_stream/2 uses caller-provided total_count with bounded Oban.insert_all chunks and compact result/error structs.
- Batch.insert_stream/2 rejects on_conflict: :skip and existing caller-supplied batch_id values to preserve fixed-size batch invariants.
- ObanPowertools.Chain is a public spec/DSL layer over batches and Oban job metadata, not a new persistence table.
- Dynamic next-step arguments are persisted only as MFA builder references; anonymous functions are rejected.
- First-job metadata stores the immediate next step separately from the ordered remaining tail so 3+ step chains survive restarts.
- Host callback dispatch claims only workflow and batch events; chain events are reserved for Powertools-owned progression.
- Chain progression callbacks are emitted only for first-time successful chain step progress and are deduped by chain id, step index, and upstream job id.
- The chain dispatcher rewrites `chain_next_step` from the remaining tail instead of copying upstream payloads into callback rows.
