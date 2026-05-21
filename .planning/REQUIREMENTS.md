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

Evidence contract:
- `Implementation Owner` preserves the phase that originally delivered the behavior.
- `Evidence Closure Phase` identifies the phase responsible for closing the repo-local proof chain.
- `Proof Status` is one of `closed`, `deferred`, or `open_gap`.

| Requirement | Implementation Owner | Evidence Closure Phase | Proof Status | Summary Evidence | Verification Evidence | Notes |
|-------------|----------------------|------------------------|--------------|------------------|-----------------------|-------|
| FND-01 | Phase 0 | Phase 6 | closed | `0-01-SUMMARY.md`, `6-01-SUMMARY.md` | `0-VERIFICATION.md`, `6-VERIFICATION.md` | Phase 6 adds explicit installer/runtime wiring and host-like verification for the repo contract. |
| FND-02 | Phase 0 | Phase 6 | closed | `0-01-SUMMARY.md`, `6-01-SUMMARY.md`, `6-02-SUMMARY.md` | `0-VERIFICATION.md`, `6-VERIFICATION.md` | Phase 6 closes the runtime auth wiring and auth-before-preview web behavior gaps. |
| FND-03 | Phase 0 | Phase 5 | closed | `0-01-SUMMARY.md` | `0-VERIFICATION.md` | Native shell strategy is implemented and now evidence-backed. |
| WRK-01 | Phase 1 | Phase 5 | closed | `1-01-SUMMARY.md` | `1-VERIFICATION.md` | Compile-time worker arg validation is proven by current tests. |
| WRK-02 | Phase 1 | Phase 5 | closed | `1-01-SUMMARY.md` | `1-VERIFICATION.md` | Synchronous enqueue validation is proven by current tests. |
| WRK-03 | Phase 1 | Phase 5 | closed | `1-01-SUMMARY.md` | `1-VERIFICATION.md` | Durable idempotency receipts are proven by current tests. |
| ENG-01 | Phase 2 | Phase 5 | closed | `2-01-SUMMARY.md`, `2-02-SUMMARY.md` | `2-VERIFICATION.md` | Durable limiter persistence and reservation behavior are evidence-closed. |
| ENG-02 | Phase 2 | Phase 5 | closed | `2-03-SUMMARY.md`, `2-05-SUMMARY.md` | `2-VERIFICATION.md` | Explain contract and native operator visibility are evidence-closed. |
| ENG-03 | Phase 2 | Phase 6 | closed | `2-04-SUMMARY.md`, `6-02-SUMMARY.md` | `2-VERIFICATION.md`, `6-VERIFICATION.md` | Phase 6 proves cron mutations preserve durable behavior while blocking unauthorized preview entry. |
| WF-01 | Phase 3 | Phase 5 | closed | `3-01-SUMMARY.md`, `3-02-SUMMARY.md` | `3-VERIFICATION.md` | Durable workflow persistence and builder insertion are evidence-closed. |
| WF-02 | Phase 3 | Phase 5 | closed | `3-03-SUMMARY.md`, `3-04-SUMMARY.md` | `3-VERIFICATION.md` | Runtime reconciliation and coordinator signaling are evidence-closed. |
| WF-03 | Phase 3 | Phase 5 | closed | `3-05-SUMMARY.md` | `3-VERIFICATION.md` | Native workflow inspection UI is evidence-closed. |
| LIF-01 | Phase 4 | Phase 5 | closed | `4-02-SUMMARY.md` | `4-VERIFICATION.md` | Durable heartbeat and incident projection are evidence-closed. |
| LIF-02 | Phase 4 | Phase 7 | closed | `4-03-SUMMARY.md`, `4-05-SUMMARY.md`, `7-01-SUMMARY.md`, `7-02-SUMMARY.md`, `7-03-SUMMARY.md` | `4-VERIFICATION.md`, `7-VERIFICATION.md` | Phase 7 closes active incident retirement, stale reprojection prevention, and LiveView closure continuity without changing Phase 4 implementation ownership. |
| LIF-03 | Phase 4 | Phase 5 | closed | `4-03-SUMMARY.md`, `4-05-SUMMARY.md` | `4-VERIFICATION.md` | Manual repair audit evidence is current and verified. |
| LIF-04 | Phase 4 | Phase 5 | closed | `4-04-SUMMARY.md`, `4-05-SUMMARY.md` | `4-VERIFICATION.md` | Archive-before-delete retention is current and verified. |
