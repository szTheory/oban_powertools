# Project

## What This Is

Oban Powertools is a batteries-included background job operations layer for Phoenix applications in the szTheory ecosystem. It extends Oban with typed worker contracts, durable idempotency, global throttling, explicit workflow DAGs, and a native operator surface for cron, workflows, and Lifeline repair flows.

## Core Value

Ecto-native operational safety with explicit, inspectable behavior for developers and operators.

## Requirements

### Validated

- ✓ Igniter installers and foundational schemas (`FND-01`) — v1
- ✓ Parapet telemetry and Sigra auth integration (`FND-02`) — v1
- ✓ Hybrid native shell around Oban Web (`FND-03`) — v1
- ✓ Typed worker args and compile-time validation (`WRK-01`) — v1
- ✓ Synchronous enqueue validation (`WRK-02`) — v1
- ✓ Durable idempotency receipts (`WRK-03`) — v1
- ✓ Global and partitioned rate limiters (`ENG-01`) — v1
- ✓ Explainable blocking state (`ENG-02`) — v1
- ✓ Dynamic cron with overlap policies (`ENG-03`) — v1
- ✓ Explicit persisted workflow DAGs (`WF-01`) — v1
- ✓ Coordinator signaling for rapid progression (`WF-02`) — v1
- ✓ Native workflow state inspection UI (`WF-03`) — v1
- ✓ Heartbeat-backed executor health tracking (`LIF-01`) — v1
- ✓ Dry-run repair center with durable closure behavior (`LIF-02`) — v1
- ✓ Audit logging for manual UI operations (`LIF-03`) — v1
- ✓ Archive-before-delete retention flows (`LIF-04`) — v1

### Active

- [ ] Define the next milestone scope after the v1 ship review.

### Out of Scope

- Per-worker ad hoc rate limiting outside the explicit global/partitioned limiter model.
- Non-Postgres coordination layers such as Redis-backed control planes.

## Context

Shipped v1 on 2026-05-21 after 8 phases and 28 plans. The codebase now includes installer/runtime wiring, typed worker contracts, limiter and cron control planes, workflow persistence and signaling, and a native Lifeline operator flow with durable repair auditability and resolved-incident continuity.

## Key Decisions

- ✓ Use a hybrid web UI strategy with a Powertools shell wrapping Oban Web.
- ✓ Keep operational state Postgres/Ecto-native with no Redis dependency.
- ✓ Make limiter, workflow, and repair behavior explicit and inspectable rather than implicit.
- ✓ Require auth before previewing or mutating operator actions.
- ✓ Preserve implementation ownership while using later phases to close evidence gaps.

## Constraints

- Remain compatible with Phoenix host applications in the szTheory ecosystem.
- Preserve low-cardinality telemetry semantics.
- Keep operational behavior durable and auditable under host-app runtime conditions.

## Current State

Version `v1` is complete and ready for archival. All 16 v1 requirements are evidence-closed, and the final open audit gap (`LIF-02`) was closed by Phase 7 on 2026-05-21.

## Next Milestone Goals

- Define the post-v1 roadmap and fresh requirements.
- Decide whether the next milestone is hardening, expansion, or release packaging.

---
*Last updated: 2026-05-21 after v1 milestone audit refresh*
