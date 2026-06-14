# Project State

## Project Reference

**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

**Current Focus:** v1.9 Batches & Composition. Providing durable, Ecto-native batch processing and workflow composition primitives (linear chains/DAG sugar) with Lifeline-routed recovery and native inspection UI.

## Current Position

| Phase | Plan | Status | Progress |
|-------|------|--------|----------|
| 59. Schemas & Foundation | None | 🟡 Planning | `[          ] 0%` |

## Performance Metrics

| Metric | Target | Current | Notes |
|--------|--------|---------|-------|
| Test Coverage | >95% | - | - |
| Type Checking | 0 Dialyzer errors | - | - |
| Linting | 0 Credo warnings | - | - |

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

- **Last Action:** Created v1.9 Roadmap
- **Next Action:** Plan Phase 59 (Schemas & Foundation)
- **Active Context:** Focus is on establishing the core data models for batches without overloading Oban's structures.