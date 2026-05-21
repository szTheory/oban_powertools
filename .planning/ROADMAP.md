# Project Roadmap

## Phases
- [x] **Phase 0: Foundation & Bridge** - Establish base schemas, Igniter installers, ecosystem integration, and the hybrid Web UI shell.
- [x] **Phase 1: Worker Ergonomics & Idempotency** - Introduce typed args validation and durable idempotency receipts.
- [x] **Phase 2: Smart Engine Limits & Cron** - Implement atomic global limiters, explainable blocks, and dynamic scheduling.
- [x] **Phase 3: Workflows (DAGs) & Signaling** - Deliver explicit persisted DAGs with PubSub-driven rapid step progression.
- [x] **Phase 4: Lifeline & Repair Center** - Deliver heartbeat monitoring and an auditable dry-run repair UI for Day-2 Ops.
- [ ] **Phase 5: Milestone Evidence & Traceability Closure** - Restore verification artifacts, missing summaries, and requirement traceability needed to close the audit.
- [x] **Phase 6: Runtime Config & Authorization Hardening** - Fix installer/runtime wiring gaps and enforce authorization before cron preview behavior.
- [x] **Phase 7: Lifeline Incident Closure Integrity** - Ensure repairs retire active incidents and the full incident closure flow stays consistent.

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
- [x] 4-05-PLAN.md — Native Lifeline route and LiveView UI
**UI hint**: yes

### Phase 5: Milestone Evidence & Traceability Closure
**Goal**: Restore audit-grade verification artifacts, missing summaries, and traceability so completed milestone work can be formally proven complete.
**Depends on**: Phase 4
**Requirements**: FND-03, WRK-01, WRK-02, WRK-03, ENG-01, ENG-02, WF-01, WF-02, WF-03, LIF-01, LIF-03, LIF-04
**Gap Closure**: Closes orphaned requirement evidence, missing Phase 2/3 summary artifacts, and stale traceability from the v1 milestone audit.
**Success Criteria**:
  1. Each completed phase has the required verification and validation artifacts, and missing Phase 2/3 summary outputs/frontmatter are restored.
  2. `REQUIREMENTS.md` matches the restored summary and verification evidence for every requirement assigned to this phase.
  3. Re-running the milestone audit no longer reports orphaned requirements for these requirements.
**Plans**:
- [x] 5-01-PLAN.md — Traceability contract and Phase 0 evidence repair
- [x] 5-02-PLAN.md — Phase 1 worker evidence restoration
- [x] 5-03-PLAN.md — Phase 2 summary and smart-engine evidence restoration
- [x] 5-04-PLAN.md — Phase 3 workflow evidence normalization
- [x] 5-05-PLAN.md — Phase 4 evidence repair and milestone audit rerun

### Phase 6: Runtime Config & Authorization Hardening
**Goal**: Close the shared foundational safety gaps in installer/runtime wiring and cron authorization ordering.
**Depends on**: Phase 4
**Requirements**: FND-01, FND-02, ENG-03
**Gap Closure**: Closes the installer runtime config gap and the cron preview authorization gap from the v1 milestone audit.
**Success Criteria**:
  1. Installer output wires the required repo and auth runtime dependencies without relying on test-only configuration.
  2. Cron preview and related mutation surfaces enforce authorization before preview-state behavior is exposed.
  3. Verification proves the runtime wiring and authorization flow in host-app-like conditions.
**Plans**: None yet

### Phase 7: Lifeline Incident Closure Integrity
**Goal**: Ensure repair execution fully resolves the active incident lifecycle and preserves a clean end-to-end repair flow.
**Depends on**: Phase 4
**Requirements**: LIF-02
**Gap Closure**: Closes the broken post-repair incident retirement flow identified by the v1 milestone audit.
**Success Criteria**:
  1. Successful repair execution retires or resolves the acted-on incident record.
  2. Refreshing the Lifeline UI after repair does not re-project the repaired incident as active.
  3. Verification covers the full heartbeat -> projection -> repair -> closure flow.
**Plans**: 3 plans
- [x] 7-01-PLAN.md — Backend incident reconciliation and atomic retirement
- [x] 7-02-PLAN.md — Lifeline LiveView active/resolved continuity and remount proof
- [x] 7-03-PLAN.md — Phase 7 verification artifact and LIF-02 traceability closure

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Foundation & Bridge | 1/1 | Completed | 2026-05-18 |
| 1. Worker Ergonomics & Idempotency | 1/1 | Completed | 2026-05-19 |
| 2. Smart Engine Limits & Cron | 5/5 | Completed | 2026-05-19 |
| 3. Workflows (DAGs) & Signaling | 5/5 | Completed | 2026-05-19 |
| 4. Lifeline & Repair Center | 5/5 | Completed | 2026-05-19 |
| 5. Milestone Evidence & Traceability Closure | 5/5 | Completed | 2026-05-20 |
| 6. Runtime Config & Authorization Hardening | 3/3 | Completed | 2026-05-20 |
| 7. Lifeline Incident Closure Integrity | 3/3 | Completed | 2026-05-21 |
