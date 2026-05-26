# Project

## What This Is

Oban Powertools is a host-owned operations layer for Oban-backed Phoenix applications in the szTheory ecosystem. It extends Oban with typed worker contracts, durable idempotency, explicit limiter and cron controls, durable workflow semantics, and native operator surfaces for diagnosis, repair, and audited manual operations.

## Core Value

Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

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
- Presenting the workflow layer as a general orchestration platform.
- Rebuilding the full generic Oban Web dashboard surface before the native Powertools control plane clearly demands it.

## Context

Shipped v1 on 2026-05-21 after 8 phases and 28 plans. The codebase now includes installer/runtime wiring, typed worker contracts, limiter and cron control planes, workflow persistence and signaling, a native Lifeline operator flow with durable repair auditability and resolved-incident continuity, and a unified native control plane story across the existing operator surfaces.

## Key Decisions

- ✓ Use a hybrid web UI strategy with a Powertools shell wrapping Oban Web.
- ✓ Keep operational state Postgres/Ecto-native with no Redis dependency.
- ✓ Make limiter, workflow, and repair behavior explicit and inspectable rather than implicit.
- ✓ Require auth before previewing or mutating operator actions.
- ✓ Preserve implementation ownership while using later phases to close evidence gaps.

## Decision Posture

- Prefer research-backed, one-shot recommendations over interactive re-litigation.
- Shift the decision burden left within GSD for this repo: downstream agents should read repo-local context and prompts, analyze tradeoffs, and recommend a coherent default before asking the user anything.
- When `discuss-phase` runs for this repo, agents should do real repo-local research first: read current planning artifacts, relevant prompts, nearby phase context, and implementation surfaces before forming questions.
- Default `discuss-phase` behavior is to narrow to one coherent recommendation set, not to present broad option menus.
- Do not ask the user to choose between implementation options that can be resolved by existing repo decisions, Phoenix/LiveView/Ecto/Postgres norms, ecosystem best practice, or direct inspection of the current implementation.
- Escalate questions only when a choice would materially change the public product promise, support truth, operator trust, architectural boundaries, or long-term maintainer burden.
- When escalation is necessary, present the recommended path first and ask the narrowest possible question rather than running a broad design interview.
- Favor idiomatic Phoenix/LiveView/Ecto/Postgres patterns, least-surprise UX, strong DX, and ecosystem lessons from comparable operator/admin systems.
- Treat prior locked CONTEXT decisions as defaults unless a later phase must reopen them for one of the material reasons above.

## Constraints

- Remain compatible with Phoenix host applications in the szTheory ecosystem.
- Preserve low-cardinality telemetry semantics.
- Keep operational behavior durable and auditable under host-app runtime conditions.

## Current State

Version `v1.3` shipped on 2026-05-26. The native `/ops/jobs` shell now reads as one coherent operator control plane: shared vocabulary and ownership boundaries span overview, cron, limiters, workflows, Lifeline, audit, and bounded Oban Web handoffs; the overview is diagnosis-first; drilldowns preserve durable context; and the public docs plus example-host proof tell the same native-shell versus bridge-only story. The next highest-leverage gap is deeper operator forensics and runbook-guided remediation, not broader queue-dashboard scope or machine-facing automation.

## Next Milestone Goals

The default next candidate is `v1.4 Operator Forensics & SRE Runbooks`.

**Target features:**
- richer historical timelines, limiter history, missed-fire views, and cross-surface evidence bundles
- runbook-guided remediation flows that build on the now-stable control-plane vocabulary
- operator-grade investigative UX that deepens day-2 trust without widening into a generic dashboard rewrite

**Why next:** the control-plane contract is now stable enough that deeper forensics and remediation guidance should produce more operator leverage than another public capability family.

## Recently Shipped

<details>
<summary>v1.3 Unified Control Plane & Explainability</summary>

Goal: make the native `/ops/jobs` shell feel like one coherent operator control plane rather than a set of adjacent feature pages.

Delivered:
- One shared operator vocabulary, status taxonomy, and ownership model across overview, cron, limiters, workflows, Lifeline, audit, and Oban Web handoffs.
- A diagnosis-first overview and continuity-safe drill-down model that preserves durable context across native and bridge destinations.
- One consistent preview, reason, refusal, and audit posture across bounded native mutation surfaces.
- Support-truthful docs, example-host proof, and merge-blocking verification for the native-shell versus bridge-only contract.

</details>

<details>
<summary>v1.2 Workflow Semantics & Recovery</summary>

Goal: make workflow recovery, diagnosis, signal handling, cancellation, expiry, and support-truth semantics explicit, durable, and explainable under real host-app runtime conditions.

Delivered:
- Explicit workflow semantics version `2`, durable terminal-cause vocabulary, and an additive compatibility path for historical rows.
- One DB-first workflow command pipeline with durable command-attempt, callback, recovery, await, signal, cancel, and late-arrival evidence.
- Shared workflow/Lifeline diagnosis vocabulary with bounded workflow actions routed through Lifeline instead of a second mutation surface.
- Focused proof, upgrade, telemetry, docs, verification-backfill, traceability-repair, and historical closeout coverage sufficient for milestone archival.

</details>

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
*Last updated: 2026-05-26 after shipping milestone v1.3*
