---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: milestone
status: ready_to_plan
last_updated: "2026-06-15T02:44:33.652Z"
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 15
  completed_plans: 10
  percent: 67
---

# Project State

## Project Reference

**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

**Current Focus:** Phase 62 — operations console & lifeline ui

## Current Position

Phase: 62
Plan: Not started
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
| Phase 61-apis-batches-chains P05 | 5 min | 2 tasks | 6 files |

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

- **Last Action:** Phase 62 planned and plan-checker verification passed
- **Next Action:** Execute Phase 62 using $gsd-execute-phase 62
- **Active Context:** Phase 62 has 5 verified plans across 3 waves: Wave 0 validation scaffold, Wave 1 routes/auth plus read model plus Lifeline callback retry, and Wave 2 BatchesLive UI/recovery flows. Plan checker passed after revision; BUI-01 through BUI-04 and CONTEXT decisions D-01 through D-19 are covered.

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
