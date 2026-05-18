# Project Roadmap

## Phases
- [ ] **Phase 0: Foundation & Bridge** - Establish base schemas, Igniter installers, ecosystem integration, and the hybrid Web UI shell.
- [ ] **Phase 1: Worker Ergonomics & Idempotency** - Introduce typed args validation and durable idempotency receipts.
- [ ] **Phase 2: Smart Engine Limits & Cron** - Implement atomic global limiters, explainable blocks, and dynamic scheduling.
- [ ] **Phase 3: Workflows (DAGs) & Signaling** - Deliver explicit persisted DAGs with PubSub-driven rapid step progression.
- [ ] **Phase 4: Lifeline & Repair Center** - Deliver heartbeat monitoring and an auditable dry-run repair UI for Day-2 Ops.

## Phase Details

### Phase 0: Foundation & Bridge
**Goal**: The base integration framework and user interface are functional and secure.
**Depends on**: None
**Requirements**: FND-01, FND-02, FND-03
**Success Criteria**:
  1. Developers can run an Igniter installer to generate the necessary base tables and modules in their host application.
  2. Powertools Native Shell routes render successfully and encapsulate the standard Oban Web viewer.
  3. The Shell is secured via Sigra and emits baseline low-cardinality metrics via Parapet.
**Plans**: 1 plan
- [ ] 0-PLAN.md — Initialize project, core contracts, and Igniter installer
**UI hint**: yes

### Phase 1: Worker Ergonomics & Idempotency
**Goal**: Developers can define strongly typed jobs that guarantee reliable, exactly-once application logic execution.
**Depends on**: Phase 0
**Requirements**: WRK-01, WRK-02, WRK-03
**Success Criteria**:
  1. Compiling a worker with invalid schema definitions raises explicit compile-time errors.
  2. Attempting to enqueue a job with invalid parameters synchronously yields an Ecto changeset error.
  3. A duplicate enqueue operation returns `{:conflict, existing_job}` and respects durable Idempotency Receipts across worker crashes.
**Plans**: TBD

### Phase 2: Smart Engine Limits & Cron
**Goal**: Operations are safely throttled and scheduled without deadlocking or spamming external APIs.
**Depends on**: Phase 1
**Requirements**: ENG-01, ENG-02, ENG-03
**Success Criteria**:
  1. A partitioned rate limiter enforces strict token bucket constraints (e.g., max 100 jobs/min per user_id).
  2. The UI explicitly visualizes the reason a job is blocked using the `explain/1` output.
  3. A dynamic cron job honors explicit overlap policies instead of spamming duplicates during slow executions.
**Plans**: TBD
**UI hint**: yes

### Phase 3: Workflows (DAGs) & Signaling
**Goal**: Developers can safely construct and execute complex multi-step processes with clear progression tracking.
**Depends on**: Phase 2
**Requirements**: WF-01, WF-02, WF-03
**Success Criteria**:
  1. A workflow definition correctly inserts normalized nodes and edges into `oban_powertools_workflows`.
  2. Completing a parent step unblocks child steps almost instantaneously via Phoenix PubSub signaling.
  3. Operators can visually identify the exact blocked step in a nested workflow via the Web UI.
**Plans**: TBD
**UI hint**: yes

### Phase 4: Lifeline & Repair Center
**Goal**: SREs and Operators can safely diagnose, test, and resolve stuck jobs or dead nodes with full auditability.
**Depends on**: Phase 3
**Requirements**: LIF-01, LIF-02, LIF-03, LIF-04
**Success Criteria**:
  1. Nodes emit consistent heartbeats, enabling the UI to surface "orphaned" jobs from dead executors.
  2. SREs can execute a "Dry-Run" on a stuck workflow to preview state changes before committing.
  3. Any manual intervention via the UI immediately writes an immutable record to the Threadline audit events table.
  4. The database is kept lean via an automated pruner that archives data before deletion.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Foundation & Bridge | 1/1 | Completed | 2026-05-18 |
| 1. Worker Ergonomics & Idempotency | 0/0 | Not started | - |
| 2. Smart Engine Limits & Cron | 0/0 | Not started | - |
| 3. Workflows (DAGs) & Signaling | 0/0 | Not started | - |
| 4. Lifeline & Repair Center | 0/0 | Not started | - |
