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
- ✓ Public low-cardinality telemetry contract (`POL-03`) — v1.1 Phase 8
- ✓ Host/library ownership boundary for routes and supervision (`HST-01`) — v1.1 Phase 8

### Active

- [ ] Stabilize the remaining public host contract for upgrade, auth, redaction, and optional `oban_web` adoption (`v1.1`).
- [ ] Unify operator permission/read-only/preview/audit expectations across the Powertools shell and the Oban Web bridge (`v1.1`).
- [ ] Produce docs, example-app proof, and support-truth guidance that make host adoption predictable (`v1.1`).

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

Version `v1` shipped on 2026-05-21. All 16 v1 requirements are evidence-closed, and Phase 8 of `v1.1` now closes the first public host-contract slice across install, route ownership, supervision posture, telemetry, README guidance, and validation proof.

## Current Milestone: v1.1 Host Contract & Adoption Hardening

**Goal:** Make Oban Powertools predictable to install, configure, secure, and operate as a host-owned Phoenix dependency before expanding the public runtime surface again.

**Target features:**
- Stable upgrade and optional dependency contract for host apps, building on the shipped install/config/router baseline from Phase 8.
- Frozen auth, redaction, and audit seams across the Powertools shell and Oban Web bridge, with telemetry now documented as public API.
- Consistent operator UX for permissions, read-only states, preview/reason/audit flows, and docs/example-app onboarding.

**Why now:** The cheapest post-v1 unlock is reducing host-adoption and contract churn so later workflow and control-plane expansion can land on stable public seams.

## Next Milestone Goals

- Ship the v1.1 host-contract hardening slice and keep workflow semantics as the next major capability milestone.
- Use `.planning/MILESTONE-ARC.md` as the source of truth for future milestone pulls and pivots.

## Evolution

This document evolves at milestone boundaries and whenever the active milestone meaningfully changes.

- Keep validated requirements and major constraints accurate as shipped behavior changes.
- Prefer left-shifting prerequisite and support-truth work before broadening public capability claims.
- Update the milestone arc when a candidate becomes active or when a deliberate pivot changes ordering.

---
*Last updated: 2026-05-21 after Phase 8 completion*
