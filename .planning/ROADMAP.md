# Project Roadmap

## Phases
- [x] **Phase 0: Foundation & Bridge** - Establish base schemas, Igniter installers, ecosystem integration, and the hybrid Web UI shell.
- [x] **Phase 1: Worker Ergonomics & Idempotency** - Introduce typed args validation and durable idempotency receipts.
- [x] **Phase 2: Smart Engine Limits & Cron** - Implement atomic global limiters, explainable blocks, and dynamic scheduling.
- [x] **Phase 3: Workflows (DAGs) & Signaling** - Deliver explicit persisted DAGs with PubSub-driven rapid step progression.
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
- [x] 0-PLAN.md — Initialize project, core contracts, and Igniter installer
**UI hint**: yes

### Phase 1: Worker Ergonomics & Idempotency
**Goal**: Developers can define strongly typed jobs that guarantee reliable, exactly-once application logic execution.
**Depends on**: Phase 0
**Requirements**: WRK-01, WRK-02, WRK-03
**Success Criteria**:
  1. Compiling a worker with invalid schema definitions raises explicit compile-time errors.
  2. Attempting to enqueue a job with invalid parameters synchronously yields an Ecto changeset error.
  3. A duplicate enqueue operation returns `{:conflict, existing_job}` and respects durable Idempotency Receipts across worker crashes.
**Plans**:
- [x] 1-PLAN.md — Worker Ergonomics & Idempotency implementation

### Phase 2: Smart Engine Limits & Cron
**Goal**: Operations are safely throttled and scheduled without deadlocking or spamming external APIs.
**Depends on**: Phase 1
**Requirements**: ENG-01, ENG-02, ENG-03
**Success Criteria**:
  1. A partitioned rate limiter enforces strict token bucket constraints (e.g., max 100 jobs/min per user_id).
  2. The UI explicitly visualizes the reason a job is blocked using the `explain/1` output.
  3. A dynamic cron job honors explicit overlap policies instead of spamming duplicates during slow executions.
**Plans**:
- [x] 2-01-PLAN.md — Smart-engine persistence contracts
- [x] 2-02-PLAN.md — Worker limits DSL and limiter reservation engine
- [x] 2-03-PLAN.md — Explain contract, telemetry, and audit normalization
- [x] 2-04-PLAN.md — Dynamic cron engine and slot-ledger policies
- [x] 2-05-PLAN.md — Native operator UI, auth gating, and preview-first actions
**UI hint**: yes

### Phase 3: Workflows (DAGs) & Signaling
**Goal**: Developers can safely construct and execute complex multi-step processes with clear progression tracking.
**Depends on**: Phase 2
**Requirements**: WF-01, WF-02, WF-03
**Success Criteria**:
  1. A workflow definition correctly inserts normalized nodes and edges into `oban_powertools_workflows`.
  2. Completing a parent step unblocks child steps almost instantaneously via Phoenix PubSub signaling.
  3. Operators can visually identify the exact blocked step in a nested workflow via the Web UI.
**Plans**:
- [x] 3-01-PLAN.md — Workflow persistence contracts
- [x] 3-02-PLAN.md — Builder API and normalized insert path
- [x] 3-03-PLAN.md — Runtime completion, results, and blocker explanations
- [x] 3-04-PLAN.md — Coordinator signaling, telemetry, and audit hooks
- [x] 3-05-PLAN.md — Native workflow routes and read-only LiveView
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
**Plans**:
- [x] 4-01-PLAN.md — Phase 4 persistence contracts
- [x] 4-02-PLAN.md — Heartbeat writer and incident projection backend
- [x] 4-03-PLAN.md — Repair preview, execute, and audit backend
- [x] 4-04-PLAN.md — Archive/prune retention backend
- [ ] 4-05-PLAN.md — Native Lifeline route and LiveView UI
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Foundation & Bridge | 1/1 | Completed | 2026-05-18 |
| 1. Worker Ergonomics & Idempotency | 1/1 | Completed | 2026-05-19 |
| 2. Smart Engine Limits & Cron | 5/5 | Completed | 2026-05-19 |
| 3. Workflows (DAGs) & Signaling | 5/5 | Completed | 2026-05-19 |
| 4. Lifeline & Repair Center | 4/5 | In progress | - |
