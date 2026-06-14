# Requirements — v1.9 Batches & Composition

## Milestone Goal

Provide durable, Ecto-native batch processing and workflow composition primitives (linear chains/DAG sugar) with Lifeline-routed recovery and native inspection UI, guided by deep ecosystem research.

## v1.9 Requirements

### Batches (BAT)
- [x] **BAT-01**: Dedicated Ecto schemas and migrations for `batches`, `batch_jobs`, and a `callbacks` outbox.
- [x] **BAT-02**: `Batch.insert_stream/2` API for safely enqueuing massive batches via chunked inserts to prevent DB lock starvation.
- [x] **BAT-03**: Exactly-once progress tracking wired transactionally into v1.7 worker lifecycle hooks (`on_success`, `on_discard`).
- [x] **BAT-04**: Execution of `completed` and `exhausted` callbacks via the callback outbox when batch targets are met.

### Chains (CHN)
- [ ] **CHN-01**: Ergonomic DSL for linear Chains (e.g. `JobA |> chain(JobB)`), mapping sequentially to the Callback Outbox under the hood.
- [ ] **CHN-02**: State propagation support, allowing a sequential job to access the durable output of its upstream predecessor.

### Batch Operations UI (BUI)
- [ ] **BUI-01**: Native `/ops/jobs/batches` LiveView page showing batch progress, statuses, and failed member inspection.
- [ ] **BUI-02**: Operator visibility into explainable blocked states (e.g., waiting on batch completion or upstream chain).
- [ ] **BUI-03**: Lifeline-routed bulk recovery action to safely "Retry failed in batch".
- [ ] **BUI-04**: Operator visibility and recovery actions for "stuck/dead callbacks" to prevent silent hanging batches.

## Future Requirements (deferred)

- QRY-05 args/meta filter, QRY-06 real-time counts, QRY-07 Lifeline→job deep-link, QRY-08 cross-page select-all, API-03 programmatic job query.
- Observability / live counts (`oban_met` integration).

## Out of Scope

- **Dynamic / Growable Batches**: Adding jobs to a batch after it starts executing introduces massive race condition complexity. Require fixed-size batches on insert.
- **Chunking (size/timeout based batches)**: Distinct from logical grouping; optimizing throughput via chunking is a different JTBD than logical composition.
- **Implicit Workflow Callbacks**: Overloading a worker's `on_success` hook to mean "the whole workflow is done."
- **Complex fan-in/fan-out DAGs**: Stick to linear chains for this milestone.
- **External Dependencies**: No `libgraph` or Redis.

## Traceability

| REQ-ID | Phase | Plan |
|--------|-------|------|
| BAT-01 | Phase 59 | TBD  |
| BAT-02 | Phase 61 | 61-02 |
| BAT-03 | Phase 60 | TBD  |
| BAT-04 | Phase 60 | TBD  |
| CHN-01 | Phase 61 | TBD  |
| CHN-02 | Phase 61 | TBD  |
| BUI-01 | Phase 62 | TBD  |
| BUI-02 | Phase 62 | TBD  |
| BUI-03 | Phase 62 | TBD  |
| BUI-04 | Phase 62 | TBD  |
