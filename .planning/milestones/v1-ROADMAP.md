# Milestone v1: Oban Powertools v1

**Status:** ✅ SHIPPED 2026-05-21
**Phases:** 0-7
**Total Plans:** 28

## Overview

Oban Powertools v1 establishes the full batteries-included job operations foundation for Phoenix applications in the szTheory ecosystem. The milestone ships installer/runtime setup, typed worker contracts, durable idempotency, global throttling, dynamic cron, explicit workflow DAGs, and a native Lifeline repair surface with closed audit-grade proof for every v1 requirement.

## Phases

### Phase 0: Foundation & Bridge

**Goal**: The base integration framework and user interface are functional and secure.
**Depends on**: None
**Plans**: 1 plan

Plans:

- [x] 0-PLAN.md — Initialize project, core contracts, and Igniter installer

**Details:**
Established the installer, base contracts, auth behavior, telemetry wrapper, and hybrid Powertools shell around Oban Web.

### Phase 1: Worker Ergonomics & Idempotency

**Goal**: Developers can define strongly typed jobs that guarantee reliable, exactly-once application logic execution.
**Depends on**: Phase 0
**Plans**: 1 plan

Plans:

- [x] 1-PLAN.md — Worker Ergonomics & Idempotency implementation

**Details:**
Added compile-time worker arg validation, synchronous enqueue validation, and deterministic durable idempotency receipts.

### Phase 2: Smart Engine Limits & Cron

**Goal**: Operations are safely throttled and scheduled without deadlocking or spamming external APIs.
**Depends on**: Phase 1
**Plans**: 5 plans

Plans:

- [x] 2-01-PLAN.md — Smart-engine persistence contracts
- [x] 2-02-PLAN.md — Worker limits DSL and limiter reservation engine
- [x] 2-03-PLAN.md — Explain contract, telemetry, and audit normalization
- [x] 2-04-PLAN.md — Dynamic cron engine and slot-ledger policies
- [x] 2-05-PLAN.md — Native operator UI, auth gating, and preview-first actions

**Details:**
Delivered durable limiter state, explainable blocking, dynamic cron overlap policies, and native `/ops/jobs` operator pages.

### Phase 3: Workflows (DAGs) & Signaling

**Goal**: Developers can safely construct and execute complex multi-step processes with clear progression tracking.
**Depends on**: Phase 2
**Plans**: 5 plans

Plans:

- [x] 3-01-PLAN.md — Workflow persistence contracts
- [x] 3-02-PLAN.md — Builder API and normalized insert path
- [x] 3-03-PLAN.md — Runtime completion, results, and blocker explanations
- [x] 3-04-PLAN.md — Coordinator signaling, telemetry, and audit hooks
- [x] 3-05-PLAN.md — Native workflow routes and read-only LiveView

**Details:**
Delivered explicit persisted DAG workflows, DB-first runtime reconciliation, PubSub progression hints, and native workflow inspection UI.

### Phase 4: Lifeline & Repair Center

**Goal**: SREs and Operators can safely diagnose, test, and resolve stuck jobs or dead nodes with full auditability.
**Depends on**: Phase 3
**Plans**: 5 plans

Plans:

- [x] 4-01-PLAN.md — Phase 4 persistence contracts
- [x] 4-02-PLAN.md — Heartbeat writer and incident projection backend
- [x] 4-03-PLAN.md — Repair preview, execute, and audit backend
- [x] 4-04-PLAN.md — Archive/prune retention backend
- [x] 4-05-PLAN.md — Native Lifeline route and LiveView UI

**Details:**
Delivered heartbeat monitoring, incident projection, dry-run repair previews, repair execution audit trails, archive-before-delete retention, and the native Lifeline operator page.

### Phase 5: Milestone Evidence & Traceability Closure

**Goal**: Restore audit-grade verification artifacts, missing summaries, and traceability so completed milestone work can be formally proven complete.
**Depends on**: Phase 4
**Plans**: 5 plans

Plans:

- [x] 5-01-PLAN.md — Traceability contract and Phase 0 evidence repair
- [x] 5-02-PLAN.md — Phase 1 worker evidence restoration
- [x] 5-03-PLAN.md — Phase 2 summary and smart-engine evidence restoration
- [x] 5-04-PLAN.md — Phase 3 workflow evidence normalization
- [x] 5-05-PLAN.md — Phase 4 evidence repair and milestone audit rerun

**Details:**
Rebuilt the repo-local proof chain so summaries, verification artifacts, and the requirements ledger align with shipped behavior.

### Phase 6: Runtime Config & Authorization Hardening

**Goal**: Close the shared foundational safety gaps in installer/runtime wiring and cron authorization ordering.
**Depends on**: Phase 4
**Plans**: 3 plans

Plans:

- [x] 6-01-PLAN.md — Centralize runtime config and installer wiring
- [x] 6-02-PLAN.md — Enforce auth-before-preview cron behavior
- [x] 6-03-PLAN.md — Close requirement evidence and refresh audit state

**Details:**
Closed the runtime wiring and cron authorization gaps, then refreshed verification evidence for `FND-01`, `FND-02`, and `ENG-03`.

### Phase 7: Lifeline Incident Closure Integrity

**Goal**: Ensure repairs retire active incidents and the full incident closure flow stays consistent.
**Depends on**: Phase 4
**Plans**: 3 plans

Plans:

- [x] 7-01-PLAN.md — Backend incident reconciliation and atomic retirement
- [x] 7-02-PLAN.md — Lifeline LiveView active/resolved continuity and remount proof
- [x] 7-03-PLAN.md — Phase 7 verification artifact and LIF-02 traceability closure

**Details:**
Closed `LIF-02` by resolving acted-on incidents during repair, reconciling stale active rows during projection, and preserving closure evidence in the resolved Lifeline view.

---

## Milestone Summary

**Key Accomplishments:**

- Bootstrapped the installer, auth, telemetry, and native Powertools shell foundation for host Phoenix apps.
- Added typed worker contracts, synchronous enqueue validation, and durable idempotency receipts.
- Delivered durable limiters, dynamic cron, and preview-first native operator actions.
- Added explicit workflow DAG persistence, runtime signaling, and native workflow inspection.
- Shipped the Lifeline repair center with preview-before-execute safety, auditability, and archive retention.
- Closed all remaining milestone audit gaps with runtime/auth hardening and durable incident retirement integrity.

**Key Decisions:**

- Use a hybrid Powertools shell around Oban Web to keep native operator surfaces consistent with the host app.
- Keep operational coordination Postgres/Ecto-native rather than introducing Redis or other external control planes.
- Require preview-first operator flows with auth enforcement before any mutation-side behavior is exposed.

**Issues Resolved:**

- Missing verification and summary artifacts were restored in Phase 5.
- Installer/runtime wiring and cron authorization ordering gaps were closed in Phase 6.
- Active Lifeline incidents now retire durably after successful repair in Phase 7.

**Issues Deferred:**

- None at milestone close.

**Technical Debt Incurred:**

- Next milestone still needs fresh requirements and roadmap definition before additional feature work starts.

---

_For current project status, see `.planning/ROADMAP.md`._
