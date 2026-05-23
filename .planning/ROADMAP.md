# Project Roadmap

## Milestones

- ✅ **v1** — Phases 0-7 shipped 2026-05-21. Full archive: `.planning/milestones/v1-ROADMAP.md`
- ✅ **v1.1** — Host Contract & Adoption Hardening. Phases 8-15 shipped 2026-05-23. Full archive: `.planning/milestones/v1.1-ROADMAP.md`
- 🚧 **v1.2** — Workflow Semantics & Recovery. Phases 16-23 active. Working roadmap: `.planning/milestones/v1.2-ROADMAP.md`

## Active Phases

### Phase 16: Semantics Contract, Cause Vocabulary & Compatibility Baseline

**Goal**: Freeze one explicit workflow and step lifecycle contract before adding broader mutation and recovery behavior.
**Depends on**: v1.1 foundation
**Plans**: 0 plans

**Details:**
Persist workflow semantics versioning, define durable terminal-cause vocabulary, and document the compatibility path for pre-v1.2 in-flight workflows.

### Phase 17: DB-First Transition Engine & Command Pipeline

**Goal**: Route runtime and operator workflow mutations through one legal transition path backed by Postgres truth.
**Depends on**: Phase 16
**Plans**: 0 plans

**Details:**
Centralize workflow cancel, expire, recover, reconcile, and completion transitions so unsupported mutations are rejected durably instead of inferred from transient hints.

### Phase 18: Durable Callback Outbox & Recovery Attempts

**Goal**: Make workflow callbacks and recovery attempts survive crashes, retries, and operator re-entry.
**Depends on**: Phase 17
**Plans**: 0 plans

**Details:**
Add a post-commit callback outbox, durable recovery attempt evidence, and narrow supported callback semantics for terminal and recovery events.

### Phase 19: Await Registration, Signal Facts & Expiry Authority

**Goal**: Persist wait/signal truth before layering broader operator behavior on top.
**Depends on**: Phase 18
**Plans**: 0 plans

**Details:**
Store await registrations and signal facts durably, reconcile them idempotently, and establish one authoritative expiry path.

### Phase 20: Cancellation, Late Completion & Expiry Semantics

**Goal**: Make cancel, completion, expiry, and late-arrival races explainable and support-truthful.
**Depends on**: Phase 19
**Plans**: 0 plans

**Details:**
Preserve cancel-request evidence, late completion evidence, and explicit precedence rules for cancel, completion, expiry, dependency failure, and late signals.

### Phase 21: Workflow Diagnosis Projection & Native Workflow Surface

**Goal**: Explain workflow state without DB spelunking.
**Depends on**: Phase 20
**Plans**: 0 plans

**Details:**
Project durable diagnosis classes from workflow evidence and render cause, evidence, and allowed next action in the native workflow UI.

### Phase 22: Lifeline Integration & Bounded Recovery Actions

**Goal**: Unify diagnosis vocabulary and bounded workflow actions across workflow and Lifeline surfaces.
**Depends on**: Phase 21
**Plans**: 0 plans

**Details:**
Route Lifeline workflow repairs back through the workflow command pipeline and keep all workflow recovery actions audited and bounded.

### Phase 23: Verification, Upgrade Proof, Telemetry & Support-Truth Closure

**Goal**: Close the milestone with proof and docs that match the actual semantics.
**Depends on**: Phase 22
**Plans**: 0 plans

**Details:**
Add duplicate/late/dropped/race-path fixtures, in-flight upgrade proof, low-cardinality telemetry markers, and support-truth documentation aligned to durable workflow behavior.

## Progress

| Milestone | Phases | Plans | Status | Shipped |
|-----------|--------|-------|--------|---------|
| v1 | 0-7 | 28/28 | Shipped | 2026-05-21 |
| v1.1 | 8-15 | 27/27 | Shipped | 2026-05-23 |
| v1.2 | 16-23 | 0/0 | Active | - |
