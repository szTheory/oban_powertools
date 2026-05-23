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
- ✓ Host-owned install/config/router contract with deterministic migrations (`PKG-01`) — v1.1 Phase 8
- ✓ Public low-cardinality telemetry contract (`POL-03`) — v1.1 Phase 8 / Phase 14 closure repair
- ✓ Host/library ownership boundary for routes and supervision (`HST-01`) — v1.1 Phase 8
- ✓ Stable auth and actor-attribution hooks across native operator flows (`POL-01`) — v1.1 Phase 9 / Phase 14 closure repair
- ✓ Shared redaction and display-policy seams across native pages and the bridge (`POL-02`) — v1.1 Phase 9 / Phase 14 closure repair
- ✓ Consistent preview/read-only/reason/audit behavior across operator surfaces (`HST-02`) — v1.1 Phase 10 / Phase 14 closure repair
- ✓ Supported day-0 install and first successful operator session (`DOC-01`) — v1.1 Phase 12
- ✓ Native-only and optional-bridge host contract proof (`PKG-03`, `DOC-03`) — v1.1 Phase 13
- ✓ Supported archived-host upgrade lane (`PKG-02`) — v1.1 Phase 15
- ✓ Explicit support-truth boundaries and host-owned hardening/troubleshooting guidance (`HST-03`, `DOC-02`) — v1.1 Phase 15

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

Version `v1.1` shipped on 2026-05-23. All 12 host-contract milestone requirements are evidence-closed: fresh-host install, canonical first-session proof, native-only optional dependency support, bounded bridge support, repaired cross-phase traceability, and a real archived-host upgrade lane now align with the public docs and CI proof stack.

## Next Milestone Goals

- Start `v1.2 Workflow Semantics & Recovery` as the next planned milestone.
- Strengthen workflow callback/recovery semantics, stuck-graph diagnosis, signal/await behavior, and cancellation/expiry contracts on top of the now-stable host contract.
- Keep `.planning/MILESTONE-ARC.md` as the source of truth for milestone ordering and pivots.

## Recently Shipped

<details>
<summary>v1.1 Host Contract & Adoption Hardening</summary>

Goal: make Oban Powertools predictable to install, configure, secure, and operate as a host-owned Phoenix dependency before expanding the public runtime surface again.

Delivered:
- Stable install, upgrade, auth, redaction, display-policy, and optional dependency seams for host apps.
- Native-first operator UX with the `/ops/jobs/oban` bridge kept explicitly narrower and read-only.
- Repaired docs, example-host, first-session, native-only, bridge, and upgrade proof lanes that make public support truth enforceable.

</details>

## Evolution

This document evolves at milestone boundaries and whenever the active milestone meaningfully changes.

- Keep validated requirements and major constraints accurate as shipped behavior changes.
- Prefer left-shifting prerequisite and support-truth work before broadening public capability claims.
- Update the milestone arc when a candidate becomes active or when a deliberate pivot changes ordering.

---
*Last updated: 2026-05-23 after v1.1 shipment*
