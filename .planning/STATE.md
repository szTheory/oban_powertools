---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: milestone
status: ready_to_plan
last_updated: "2026-06-16T20:49:34.649Z"
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 16
  completed_plans: 16
  percent: 100
---

# Project State

## Project Reference

**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

**Current Focus:** Phase 63 — Close gap: runtime callback and chain progression consumers

## Current Position

Phase: 63
Plan: Not started
| Phase | Plan | Status | Progress |
|-------|------|--------|----------|
| 63. Close gap | 63-01 | 🔵 Planned | `[          ] 0%` |

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
| Phase 61-apis-batches-chains P05 | 5 min | 2 tasks | 6 files |
| Phase 62 P01 | 10 min | 3 tasks | 6 files |
| Phase 62 P02 | 3 min | 2 tasks | 3 files |
| Phase 62 P03 | 8 min | 3 tasks | 1 files |
| Phase 62 P04 | 4 min | 2 tasks | 2 files |
| Phase 62 P05 | 8 min | 3 tasks | 1 files |

## Accumulated Context

### Roadmap Evolution

- Phase 63 added: Close gap: runtime callback and chain progression consumers

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

- **Last Action:** Completed Phase 63-01-PLAN.md
- **Next Action:** Plan Phase 64 or evaluate milestone.
- **Active Context:** Phase 63 was added as a closure phase after the v1.8 milestone audit found runtime callback and chain progression consumers missing.

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
- Chain output handoff reads upstream payloads through `JobRecord.fetch_record/2` so expiry can be enforced before returning payloads.
- Output-dependent chain args builders must opt in with `ObanPowertools.Chain.ArgsBuilder` and expose the persisted arity-2 function.
- Chain progression builds downstream args only from the builder return value; upstream payloads are never automatically merged into job args.
- Uses state.conf.repo for reliable polling execution in test environments without ETS initialization overhead.
- Implemented try/rescue boundary around dispatch rows to prevent poison pill callbacks from crashing the polling loop and inducing a denial of service.
