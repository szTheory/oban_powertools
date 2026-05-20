# Requirements

## v1 Requirements

### Foundation
* **FND-01**: Provide Igniter installers and Ecto migrations for foundational database schemas.
* **FND-02**: Integrate with Parapet for low-cardinality telemetry and Sigra for authentication.
* **FND-03**: Establish the hybrid UI strategy (Powertools Native Shell wrapping Oban Web).

### Worker Ergonomics
* **WRK-01**: Provide `use ObanPowertools.Worker` macro supporting compile-time Ecto schema `args`.
* **WRK-02**: Enqueue operations must synchronously validate args and return `{:error, changeset}` on failure.
* **WRK-03**: Implement Postgres-backed Idempotency Receipts to guarantee exactly-once business logic execution.

### Smart Engine
* **ENG-01**: Implement Ecto-native global and partitioned rate limiters (token buckets).
* **ENG-02**: Provide `explain/1` capability to explicitly surface why any job is blocked.
* **ENG-03**: Support dynamic cron with explicit overlap and catch-up policies.

### Workflows
* **WF-01**: Model explicit DAG workflows using `oban_powertools_workflows` and `edges` tables.
* **WF-02**: Build GenServer coordinators and Phoenix PubSub signaling for rapid step progression.
* **WF-03**: Create a visual UI representation for DAG states, highlighting blocked steps.

### Lifeline & Repair
* **LIF-01**: Implement executor heartbeats tracking into `oban_powertools_heartbeats`.
* **LIF-02**: Build an SRE-grade Dry-Run Repair Center for orphaned jobs and stuck workflows.
* **LIF-03**: Audit all manual UI operations (retries, cancels) to `oban_powertools_audit_events`.
* **LIF-04**: Implement a dynamic pruner with an archive-before-delete compliance feature.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FND-01      | Phase 6 | Pending |
| FND-02      | Phase 6 | Pending |
| FND-03      | Phase 5 | Pending |
| WRK-01      | Phase 5 | Pending |
| WRK-02      | Phase 5 | Pending |
| WRK-03      | Phase 5 | Pending |
| ENG-01      | Phase 5 | Pending |
| ENG-02      | Phase 5 | Pending |
| ENG-03      | Phase 6 | Pending |
| WF-01       | Phase 5 | Pending |
| WF-02       | Phase 5 | Pending |
| WF-03       | Phase 5 | Pending |
| LIF-01      | Phase 5 | Pending |
| LIF-02      | Phase 7 | Pending |
| LIF-03      | Phase 5 | Pending |
| LIF-04      | Phase 5 | Pending |
