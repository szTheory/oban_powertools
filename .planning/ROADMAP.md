# Project Roadmap

## Milestones

- ✅ **v1** — Phases 0-7 shipped 2026-05-21. Full archive: `.planning/milestones/v1-ROADMAP.md`
- ✅ **v1.1** — Host Contract & Adoption Hardening. Phases 8-15 shipped 2026-05-23. Full archive: `.planning/milestones/v1.1-ROADMAP.md`
- 🚧 **v1.2** — Workflow Semantics & Recovery. Phases 16-26 active after audit gap discovery on 2026-05-25. Working roadmap: `.planning/milestones/v1.2-ROADMAP.md`

## Active Phases

### Phase 16: Semantics Contract, Cause Vocabulary & Compatibility Baseline

**Goal**: Freeze one explicit workflow and step lifecycle contract before adding broader mutation and recovery behavior.
**Depends on**: v1.1 foundation
**Plans**: 3 plans

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
**Plans**: 3 plans

**Details:**
Route Lifeline workflow repairs back through the workflow command pipeline and keep all workflow recovery actions audited and bounded.

Plans:
- [x] 22-01-PLAN.md — Project runtime-owned workflow actions and preserve cooperative cancel routing through `Workflow.request_cancel/3`.
- [x] 22-02-PLAN.md — Extend Lifeline to review, preview, and execute incident-backed and workflow-directed bounded actions through the shared preview envelope.
- [x] 22-03-PLAN.md — Add the diagnosis-first workflow-to-Lifeline handoff and prove cross-surface parity after execute and remount.

### Phase 23: Verification, Upgrade Proof, Telemetry & Support-Truth Closure

**Goal**: Close the milestone with proof and docs that match the actual semantics.
**Depends on**: Phase 22
**Plans**: 3 plans

**Details:**
Add duplicate/late/dropped/race-path fixtures, in-flight upgrade proof, low-cardinality telemetry markers, and support-truth documentation aligned to durable workflow behavior.

Plans:
- [x] 23-01-PLAN.md — Close the focused workflow-proof gaps and keep broader historical continuity in the repo-local compatibility lane.
- [x] 23-02-PLAN.md — Keep the supported upgrade harness singular while separating repo-local compatibility proof and support-truth wording.
- [x] 23-03-PLAN.md — Lock bounded workflow telemetry plus canonical docs-contract semantics to the verified proof topology.

### Phase 24: Verification Artifact Backfill

**Goal**: Restore milestone-auditable proof coverage for the shipped workflow semantics work.
**Depends on**: Phase 23
**Plans**: 0 plans

**Details:**
Backfill the missing phase-level `VERIFICATION.md` artifacts for Phases 17, 19, 20, 21, 22, and 23 so the existing proof commands, summaries, and requirement claims close `WFS-02`, `REC-03`, `SIG-01`, `SIG-02`, `SIG-03`, `DIA-01`, `DIA-02`, and `VER-01` explicitly.

Plans:
- [x] 24-01-PLAN.md — Restore canonical verification artifacts for the command-core, signal, expiry, and cancellation ownership chain.
- [x] 24-02-PLAN.md — Backfill workflow diagnosis and bounded Lifeline action verification without blurring surface ownership.
- [x] 24-03-PLAN.md — Close the public-proof layer and normalize the six-file verification set for traceability repair.

### Phase 25: Traceability & Audit Consistency Repair

**Goal**: Align requirements traceability and milestone evidence bookkeeping with the actual verification chain.
**Depends on**: Phase 24
**Plans**: 3 plans

**Details:**
Repair the v1.2 traceability table so original owner phases, canonical closure proof, and additive milestone-audit chronology all tell the same present-tense story.

Plans:
- [ ] 25-01-PLAN.md — Repair the v1.2 owner-phase traceability ledger and sync the active roadmap plan inventory.
- [ ] 25-02-PLAN.md — Preserve the failed audit snapshot while adding the canonical passed v1.2 rerun audit.
- [ ] 25-03-PLAN.md — Narrow `PROJECT.md` and `STATE.md` back to stable posture and session continuity after the repair lands.

### Phase 26: Historical Closeout Hygiene

**Goal**: Remove the remaining non-milestone artifact noise that still blocks closeout.
**Depends on**: Phase 25
**Plans**: 0 plans

**Details:**
Resolve the lingering Phase 12 UAT closeout signal and any related closeout metadata so milestone archiving no longer fails on stale historical artifacts.

## Progress

| Milestone | Phases | Plans | Status | Shipped |
|-----------|--------|-------|--------|---------|
| v1 | 0-7 | 28/28 | Shipped | 2026-05-21 |
| v1.1 | 8-15 | 27/27 | Shipped | 2026-05-23 |
| v1.2 | 16-26 | 25/28 | Gap Closure Active | - |
