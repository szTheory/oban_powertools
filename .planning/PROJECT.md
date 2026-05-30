# Project

## What This Is

Oban Powertools is a host-owned operations layer for Oban-backed Phoenix applications in the szTheory ecosystem. It extends Oban with typed worker contracts, durable idempotency, explicit limiter and cron controls, durable workflow semantics, and native operator surfaces for diagnosis, repair, and audited manual operations.

## Core Value

Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

## Current Milestone: v1.6 Release & Operability

**Goal:** Make Oban Powertools real for adopters — publish it to hex and ship the two named operability footguns — before adding any more capability.

**Target features:**
- First public hex release at a deliberate `0.x` (recommend `0.5.0`; document a path to `1.0` after real adopter feedback), with getting-started verified from the published package.
- `mix oban_powertools.doctor` — index / invalid-index / uniqueness-timeout / config / migration-drift health checks over read-only `pg_catalog`, with honest exit codes.
- `mix oban_powertools.limiter.explain` / `.simulate` — CLI over the existing `Explain` + `Limits`, shipping the rate-limit glossary.
- Parapet/SLO telemetry guide and opt-in `Telemetry.metrics/0` over the frozen low-cardinality contract — no `oban_met` dependency.

**Key context:** Post-v1.5 assessment (`threads/2026-05-28-post-v1.5-next-milestone.md`) put the project at ~87% done with mild overbuilding risk; the foundational gap is that the lib is `0.1.0` and unpublished after 5 milestones, not a missing feature. Zero new deps, near-zero runtime risk. Phase numbering continues from v1.5 — v1.6 starts at Phase 47. Worker Lifecycle (v1.7) and Batches (v1.8) are explicitly deferred until adoption signals demand.

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
- ✓ Runbook-guided remediation continuity with explicit host-owned escalation boundaries (`RNB-01`, `RNB-02`, `RNB-03`, `HST-05`) — v1.4 Phase 35
- ✓ Forensic timeline and evidence-bundle closure with canonical phase-level verification backfills (`FRN-01`, `FRN-02`, `FRN-03`) — v1.4 Phase 37
- ✓ Limiter/cron diagnostics closure with canonical phase-level verification backfills (`OPS-01`, `OPS-02`) — v1.4 Phase 37
- ✓ Support-truthful docs and fixture closure for forensics/runbook surfaces (`DOC-05`) — v1.4 Phase 38
- ✓ Merge-blocking CI continuity proof coverage for forensics and runbook surfaces (`VER-04`) — v1.4 Phase 39
- ✓ Native job listing with filter/search (`QRY-01`) — v1.5 Phase 43
- ✓ Native job detail view (`QRY-02`) — v1.5 Phase 43
- ✓ Native single-job actions (retry/cancel/discard) via preview/reason/audit through Lifeline (`QRY-03`) — v1.5 Phase 44
- ✓ Bulk job operations with honest per-job result reporting (`QRY-04`) — v1.5 Phase 45
- ✓ Single-job Operator Elixir API with actor attribution (`API-01`) — v1.5 Phase 46
- ✓ Bulk Operator Elixir API with per-job reporting (`API-02`) — v1.5 Phase 46
- ✓ Read-only Oban health-check CLI (`mix oban_powertools.doctor`) — index/INVALID, migration-drift, Powertools-table, and uniqueness-timeout diagnostics over `pg_catalog` with honest 0/1/2 CI exit codes, human + JSON (`schema_version: 1`) output, and a CI-enforced host-contract e2e lane (`OPS-03`, `OPS-04`, `OPS-05`) — v1.6 Phase 48
- ✓ Published-package end-to-end verification — `examples/hex_consumer/` Phoenix app installs `{:oban_powertools, "~> 0.5"}` from Hex, first-session operator test (cron pause + audit evidence) proved green via path-dep swap, `verify-published` CI job gates release pipeline on real published tarball (`REL-04`) — v1.6 Phase 51

### Active

v1.6 Release & Operability — see `## Current Milestone` above and `REQUIREMENTS.md` for the scoped, REQ-ID'd list (hex release, `mix oban_powertools.doctor`, limiter explain/simulate CLI, Parapet/SLO telemetry guide).

Carried backlog (not in v1.6): QRY-05 args/meta filter, QRY-06 real-time counts (→ v1.9), QRY-07 Lifeline→job deep-link, QRY-08 cross-page select-all, API-03 programmatic job query.

### Out of Scope

- Per-worker ad hoc rate limiting outside the explicit global/partitioned limiter model.
- Non-Postgres coordination layers such as Redis-backed control planes.
- Presenting the workflow layer as a general orchestration platform.
- Rebuilding the full generic Oban Web dashboard surface before the native Powertools control plane clearly demands it.

**Defer-until-signal (2026-05-28 assessment — don't build until evidence/demand):**
- Field-level arg **encryption** (`encrypt:`) — defer until an adopter asks; collides with the args-hashing idempotency fingerprint, blinds the v1.5 job filter (encrypted args aren't searchable), and leaks via meta/errors/stacktraces. Ship `redact:` (at-persist drop) instead.
- Prioritizer / autoscaler — don't build until adoption proves demand.
- Nested / chunked / growable batches — out of first batch milestone (Sidekiq's worst reliability area).
- `oban_met` as a hard dependency or a native generic-metrics dashboard — that's rebuilding Oban Web; use it only as an optional read source for live counts.
- Mobile/companion operator surfaces; generic event bus / webhook platform.

## Context

Shipped v1 on 2026-05-21 after 8 phases and 28 plans. The codebase now includes installer/runtime wiring, typed worker contracts, limiter and cron control planes, workflow persistence and signaling, a native Lifeline operator flow with durable repair auditability and resolved-incident continuity, and a unified native control plane story across the existing operator surfaces.

## Key Decisions

- ✓ Use a hybrid web UI strategy with a Powertools shell wrapping Oban Web.
- ✓ Keep operational state Postgres/Ecto-native with no Redis dependency.
- ✓ Make limiter, workflow, and repair behavior explicit and inspectable rather than implicit.
- ✓ Require auth before previewing or mutating operator actions.
- ✓ Preserve implementation ownership while using later phases to close evidence gaps.
- ✓ All native job mutations (UI and API) route through `Lifeline.execute_repair` — no direct `Oban` calls and no parallel mutation path. — v1.5
- ✓ Bulk operations run an independent repair per job (no single `Ecto.Multi` over N jobs) and report per-job success/failure honestly. — v1.5
- ✓ `ObanPowertools.Operator` requires a non-nil actor for every action and emits `source: "api"` telemetry within the frozen low-cardinality `@contract`. — v1.5
- — Hex publication is a near-term goal; first public release at `0.x` (recommend `0.5.0`) before committing to `1.0` SemVer, so the public API meets real adopters before it's frozen. — 2026-05-28 assessment
- — Worker Lifecycle precedes Batches: batch callbacks reuse the worker hook contract and output recording reuses a generalized `Workflow.Result` table; building Batches first forces a refactor. — 2026-05-28 assessment

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
- At milestone boundaries, run an adopter-first "done" assessment (repo-grounded, not phase-counting) and research candidate milestones with parallel subagents before committing — surface overbuilding risk explicitly.
- Apply an idiomatic-Elixir/Phoenix/Ecto + DX/UX-first lens; prefer reusing existing seams (Lifeline pipeline, callback outbox, `Workflow.Result`, `Redactor`/`DisplayPolicy` behaviours) over inventing new abstraction families.

## Constraints

- Remain compatible with Phoenix host applications in the szTheory ecosystem.
- Preserve low-cardinality telemetry semantics.
- Keep operational behavior durable and auditable under host-app runtime conditions.

## Current State

Version `v1.5` shipped on 2026-05-28. The native `/ops/jobs` shell now owns the full job lifecycle without leaning on the Oban Web bridge: operators browse jobs at `/ops/jobs/jobs` filtered by state/queue/worker/tags with URL-serialized filter state and `DisplayPolicy` redaction on args/meta; inspect full job detail; and retry/cancel/discard single jobs or bulk selections through the same Lifeline preview → reason → execute → audit pipeline, with a concurrent-modification guard and honest per-job bulk reporting. The new `ObanPowertools.Operator` module gives host code a typed, actor-attributed programmatic surface for the same single and bulk mutations, routed through the identical Lifeline pipeline and emitting `source: "api"` telemetry within the frozen low-cardinality contract. Milestone audit passed 6/6 requirements; full suite at 270 tests, 0 failures.

**v1.6 Release & Operability — in progress.** Phase 47 (hex release foundation), Phase 48 (`mix oban_powertools.doctor` health check), Phase 49 (limiter CLI), and Phase 50 (telemetry/SLO guide) are complete. Phase 49 shipped `mix oban_powertools.limiter.explain` (read-only blocking-state diagnostics, OPS-06) and `mix oban_powertools.limiter.simulate` (pure reservation preview via the new side-effect-free `Limits.compute_reservation/4`, OPS-07), plus a single-source rate-limit glossary surfaced across both task docs and the guide (OPS-08). Phase 50 added an opt-in, reporter-agnostic `ObanPowertools.Telemetry.metrics/0` (17 `Telemetry.Metrics` counters over the frozen control-plane contract, TEL-01) behind optional `telemetry_metrics`/`telemetry_poller` deps with no new runtime dependency (TEL-02), plus `guides/telemetry-and-slos.md`, a reporter-agnostic Operations/SLO guide with explicit no-`oban_met` framing (TEL-03). Suite at 428 tests, 0 failures. Remaining: Phase 51 (published-package verification).

(Earlier: `v1.4` delivered operator forensics and SRE runbooks; `v1.3` unified the native control plane and explainability story.)

## Next Milestone

Recommended ordering from the 2026-05-28 post-v1.5 assessment (see `threads/2026-05-28-post-v1.5-next-milestone.md`). Done-% ~87%; the foundational gap is that the lib is unpublished, not a missing feature.

1. **v1.6 Release & Operability** *(the pick)* — first public hex release at `0.x` (recommend `0.5.0`; document a path to `1.0` after real adopter feedback) + `mix oban_powertools.doctor` (index / uniqueness-timeout / config / migration-drift health) + `mix oban_powertools.limiter.explain` / `.simulate` CLI + Parapet/SLO telemetry guide & opt-in `Telemetry.metrics/0` over the frozen contract (no `oban_met` dep) + getting-started verified from hex.
2. **v1.7 Worker Lifecycle & Safety** — hooks (on_start/success/failure/discard, observe-only, crash-caught), soft `deadline:` + `timeout:` pass-through to Oban, output recording (generalize `Workflow.Result`), `redact:` at-rest. Defer `encrypt:`. (Must precede Batches — shared hook + recordings infra.)
3. **v1.8 Batches & Composition** — dedicated `batches` / `batch_jobs` tables (not a DAG), `completed` + `exhausted` callbacks via the generalized callback outbox, chains as linear-DAG sugar, native Batches page with Lifeline-routed bulk-retry. Defer chunks / nested / growable batches.
4. **v1.9 Observability / live counts (QRY-06)** — `oban_met` as an optional read source, never a hard dep.
5. **Native job-surface polish** — QRY-05 (args/meta filter), QRY-07 (Lifeline→job deep-link), QRY-08 (cross-page select), API-03 (`Operator.list/2`). Opportunistic.

## Recently Shipped

<details>
<summary>v1.5 Native Job Surface & Automation API (shipped 2026-05-28)</summary>

Goal: close the UI asymmetry with Oban Web by shipping a native operator job surface and a typed Elixir API for the same audited mutations.

Delivered:
- Native job browse/detail (`/ops/jobs/jobs`) with state/queue/worker/tags filtering, URL-serialized filter state, and DisplayPolicy redaction.
- Single-job retry/cancel/discard through the full Lifeline preview/reason/execute/audit pipeline with a concurrent-modification guard.
- Bulk operations with independent per-job repairs and honest per-job success/failure reporting.
- `ObanPowertools.Operator` typed single + bulk API requiring actor attribution, routed through the same Lifeline pipeline with `source: "api"` telemetry.

</details>

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
*Last updated: 2026-05-30 — Phase 50 (telemetry metrics/0 + SLO guide, TEL-01/02/03) complete and verified (9/9 must-haves, 428 tests 0 failures); v1.6 now has only Phase 51 (published-package verification) remaining.*
