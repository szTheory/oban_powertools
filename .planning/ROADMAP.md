# Roadmap

## Phases

- [x] **Phase 59: Schemas & Foundation** - Establish the core Ecto data model for batch tracking and the callback outbox (completed 2026-06-14)
- [x] **Phase 60: Execution Engine & Tracker Hooks** - Track batch progress transactionally via worker hooks and safely dispatch callbacks (completed 2026-06-14)
- [ ] **Phase 61: APIs (Batches & Chains)** - Expose developer ergonomics for massive batch enqueuing and linear chain composition
- [ ] **Phase 62: Operations Console & Lifeline UI** - Provide operators native visibility and Lifeline-routed recovery for batches and chains

## Phase Details

### Phase 59: Schemas & Foundation
**Goal**: Establish the core Ecto data model for dedicated batch tracking and the generalized callback outbox.
**Depends on**: Phase 58 (v1.8)
**Requirements**: BAT-01
**Success Criteria** (what must be TRUE):
  1. Developer can run Ecto migrations to create `oban_powertools_batches`, `oban_powertools_batch_jobs`, and `oban_powertools_callbacks` tables.
  2. Ecto schemas exist for the new tables and compile successfully without relying on heavy Oban metadata.
**Plans**: TBD

### Phase 60: Execution Engine & Tracker Hooks
**Goal**: Track batch progress transactionally via worker hooks and safely dispatch callbacks when targets are met.
**Depends on**: Phase 59
**Requirements**: BAT-03, BAT-04
**Success Criteria** (what must be TRUE):
  1. Worker `on_success` and `on_discard` hooks correctly update batch progress exactly-once.
  2. `completed` callbacks are inserted into the outbox automatically when all batch jobs succeed.
  3. `exhausted` callbacks are inserted into the outbox automatically when batch jobs complete but some are discarded.
**Plans**: 3 plans
- [x] 60-01-PLAN.md — Add completed_at field to Batch schema
- [x] 60-02-PLAN.md — Implement Tracker exactly-once progress and callback enqueueing
- [x] 60-03-PLAN.md — Wire Tracker into Worker Hooks

### Phase 61: APIs (Batches & Chains)
**Goal**: Expose developer ergonomics for massive batch enqueuing and linear chain composition without lock contention or DAG abuse.
**Depends on**: Phase 60
**Requirements**: BAT-02, CHN-01, CHN-02
**Success Criteria** (what must be TRUE):
  1. Developer can enqueue massive batches using `Batch.insert_stream/2` without crashing the database via lock starvation.
  2. Developer can compose sequential jobs using an ergonomic `chain` DSL that maps to the callback outbox.
  3. Downstream jobs in a chain can access the durable output of their upstream predecessor.
**Plans**: 5 plans
- [x] 61-01-PLAN.md — Add durable batch insertion metadata and installer contract
- [x] 61-02-PLAN.md — Implement `Batch.insert_stream/2`
- [ ] 61-03-PLAN.md — Create `ObanPowertools.Chain` DSL and first-step insert
- [ ] 61-04-PLAN.md — Wire event-scoped chain callback progression
- [ ] 61-05-PLAN.md — Add durable upstream output handoff and safe args builders

### Phase 62: Operations Console & Lifeline UI
**Goal**: Provide operators native visibility into batches and chains, with Lifeline-routed recovery tools.
**Depends on**: Phase 61
**Requirements**: BUI-01, BUI-02, BUI-03, BUI-04
**Success Criteria** (what must be TRUE):
  1. Operator can view batch progress, statuses, and explainable blocked states in the `/ops/jobs/batches` UI.
  2. Operator can safely retry failed jobs within a batch using a bulk Lifeline action.
  3. Operator can view and retry stuck or dead callbacks to unblock seemingly hanging batches.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 59. Schemas & Foundation | 2/2 | Complete    | 2026-06-14 |
| 60. Execution Engine & Tracker Hooks | 3/3 | Complete    | 2026-06-14 |
| 61. APIs (Batches & Chains) | 2/5 | In Progress|  |
| 62. Operations Console & Lifeline UI | 0/0 | Not started | - |
