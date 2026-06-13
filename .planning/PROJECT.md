# Project

## What This Is

Oban Powertools is a host-owned operations layer for Oban-backed Phoenix applications in the szTheory ecosystem. It extends Oban with typed worker contracts, durable idempotency, explicit limiter and cron controls, durable workflow semantics, and native operator surfaces for diagnosis, repair, and audited manual operations.

## Core Value

Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

<details>
<summary>✅ v1.7 Worker Lifecycle & Safety — SHIPPED 2026-06-13</summary>

**Goal:** Equip every worker with observable, durable lifecycle hooks, a generalised output recording contract, and at-rest redaction before adding Batches.

**Shipped:** Worker lifecycle hooks (`on_start/1`, `on_success/2`, `on_failure/2`, `on_discard/2` — observe-only, crash-caught, wrapper-owned dispatch), soft `deadline:` + `timeout:` pass-through to Oban with Doctor expired-deadline warnings, opt-in `record_output: true` via new `oban_powertools_job_records` table with Recorded Output card in `/ops/jobs` detail, and `redact: [:field]` at-rest PII removal after fingerprint with UI disclosure and cron-path fix.

**Test suite at close:** 507 tests, 0 failures. Zero new runtime dependencies.

</details>

<details>
<summary>✅ v1.6 Release & Operability — SHIPPED 2026-05-30</summary>

**Goal:** Make Oban Powertools real for adopters — publish it to hex and ship the two named operability footguns — before adding any more capability.

**Shipped:** First public hex release at `0.5.0` with full release-please CI/CD, `mix oban_powertools.doctor` (index/migration/uniqueness health with honest exit codes), `mix oban_powertools.limiter.explain` / `.simulate` (CLI over existing `Explain` + `Limits`, rate-limit glossary), opt-in `Telemetry.metrics/0` over the frozen low-cardinality contract (no `oban_met` dep), Parapet/SLO guide, and first-session adoption verified from the published tarball.

**Test suite at close:** 428 tests, 0 failures. Zero new runtime dependencies.

</details>

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
- ✓ First hex.pm publication at `0.5.0` with full release-please CI/CD pipeline — release-please → gate-ci-green → publish-hex → verify-published, zero-touch automerge via `release-pr-automerge.yml` (`REL-01`, `REL-02`, `REL-03`) — v1.6 Phase 47
- ✓ `mix oban_powertools.doctor` — read-only `pg_catalog` health checks (index validity, INVALID detection, migration drift, Powertools tables, uniqueness-timeout risk), human + `schema_version: 1` JSON output, 0/1/2 CI exit codes (`OPS-03`, `OPS-04`, `OPS-05`) — v1.6 Phase 48
- ✓ `mix oban_powertools.limiter.explain` and `.simulate` — CLI over existing `Explain` API + pure `compute_reservation/4`, rate-limit glossary locked by docs-contract test (`OPS-06`, `OPS-07`, `OPS-08`) — v1.6 Phase 49
- ✓ Opt-in `ObanPowertools.Telemetry.metrics/0` — 17 counters over frozen low-cardinality contract, `telemetry_metrics`/`telemetry_poller` optional deps, no new runtime dependency (`TEL-01`, `TEL-02`) — v1.6 Phase 50
- ✓ `guides/telemetry-and-slos.md` — reporter-agnostic Parapet/SLO Operations guide, no `oban_met` dependency (`TEL-03`) — v1.6 Phase 50

- ✓ Worker lifecycle hooks (`on_start/1`, `on_success/2`, `on_failure/2`, `on_discard/2`) — observe-only, crash-caught, wrapper-owned, `worker_hook` telemetry family (`HOOK-01..05`) — v1.7 Phase 53
- ✓ Soft `deadline:` — `__deadline_at__` meta at enqueue, pre-run cancellation, Doctor warning (`SAFE-01..04`) — v1.7 Phase 54
- ✓ `timeout:` pass-through — compile-time overridable Oban `timeout/1` callback (`SAFE-01`) — v1.7 Phase 54
- ✓ Output recording (`record_output: true`) — `ObanPowertools.JobRecord`, `oban_powertools_job_records` table, `fetch_result/1`, Recorded Output card in `/ops/jobs`, Lifeline ephemeral prune (`REC-01..05`) — v1.7 Phase 55
- ✓ At-rest redaction (`redact: [:field]`) — `Map.drop` after fingerprint, `__redacted_fields__` meta, cron-path fix, UI disclosure + per-field overlay, docs-contract locked (`REDACT-01..04`) — v1.7 Phase 56

### Active

- [ ] INT-01 fix: Add `oban_powertools_job_records` to `@powertools_manifest` in Doctor/checks.ex — deferred from v1.7 audit
- [ ] INT-02 fix: Inject `__deadline_at__` meta on cron path in `cron.ex maybe_insert_job` — deferred from v1.7 audit

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
- ✓ Hex publication at `0.5.0` before `1.0` — shipped v1.6. Public API meets real adopters before freeze. — v1.6
- ✓ Worker Lifecycle precedes Batches — batch callbacks reuse the worker hook contract; building Batches first forces a refactor. — 2026-05-28 assessment (carried to v1.7 planning)
- ✓ `include-component-in-tag: false` — future release tags are `v*` only (no `oban_powertools-v*` duplication). — v1.6 Phase 47
- ✓ RELEASE_PLEASE_TOKEN = PAT (not GitHub App token) — required for workflow triggers; provenance attestation skipped (not available for third-party registries). — v1.6 Phase 47
- ✓ Worker hooks are wrapper-owned (not Oban telemetry-handler-owned); omitted no-op hooks do not emit telemetry; crashes are warning-logged and never change job outcome. — v1.7 Phase 53
- ✓ Separate `oban_powertools_job_records` table (not modifying `Workflow.Result`) — FK/unique semantics differ; no FK to `oban_jobs` so Oban can prune its own table freely. — v1.7 Phase 55
- ✓ Redact after fingerprint — fingerprint computed from full unredacted args; `Map.drop` applied before `Oban.Job.new/2` in `new/2` override. — v1.7 Phase 56
- ✓ Cron-path redaction via `function_exported?(:__powertools_limits__, 0)` sentinel — applies to all Powertools workers; `rescue ArgumentError` degrades to bare `Oban.Job.new` for unloaded modules. — v1.7 Phase 56
- ✓ `encrypt:` deferred indefinitely — collides with args-hashing fingerprint, blinds v1.5 job filter (encrypted args not searchable), leaks via meta/errors/stacktraces. Ship `redact:` (at-persist drop) instead. — v1.7 research

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

**v1.6 Release & Operability — SHIPPED 2026-05-30.** All 7 phases complete (47-52.1), 16/16 plans, 428 tests, 0 failures, 121 files changed (+16,574/−222 LOC). Published to hex.pm at `0.5.0` with zero-touch release-please CI/CD. Shipped `mix oban_powertools.doctor` (five read-only `pg_catalog` checks, 0/1/2 exit codes, human + JSON output), `mix oban_powertools.limiter.explain` + `.simulate` (CLI over existing `Explain` API + pure `compute_reservation/4`, rate-limit glossary), opt-in `ObanPowertools.Telemetry.metrics/0` (17 counters over frozen contract, optional deps), `guides/telemetry-and-slos.md`, `examples/hex_consumer/` Phoenix adoption proof, and `verify-published` CI job. Phase 52.1 (inserted) fixed the Igniter committed-modules conflict in `verify-published`. Deferred: live CI E2E gate for REL-04 (resolves on next release cycle).

**v1.7 Worker Lifecycle & Safety — SHIPPED 2026-06-13.** All 4 phases complete (53-56), 14/14 plans, 507 tests, 0 failures. Zero new runtime dependencies. Shipped: crash-safe worker lifecycle hooks with wrapper-owned dispatch and `worker_hook` telemetry; soft `deadline:` storing `__deadline_at__` meta at enqueue with pre-run cancellation and Doctor warning; opt-in `record_output: true` via new `ObanPowertools.JobRecord` schema (dedicated `oban_powertools_job_records` table, `fetch_result/1`, Recorded Output card in `/ops/jobs` detail, Lifeline ephemeral prune); `redact: [:field]` at-rest PII removal after fingerprint via `new/2` override with UI disclosure and cron-path fix. Milestone audit `tech_debt` — 18/18 requirements satisfied; INT-01 (Doctor manifest) and INT-02 (cron+deadline path) deferred as non-blocking to v1.8.

(Earlier: `v1.4` delivered operator forensics and SRE runbooks; `v1.3` unified the native control plane and explainability story.)

## Current Milestone: v1.8 Integration Fixes

**Goal:** Close the two non-blocking integration gaps deferred from the v1.7 audit before expanding capability.

**Target features:**
- INT-01: Add `oban_powertools_job_records` to `@powertools_manifest` in Doctor/checks.ex so Doctor reports on the Phase 55 migration table
- INT-02: Inject `__deadline_at__` meta on cron path in `cron.ex maybe_insert_job` for `deadline:`-configured workers

## Next Milestone

**v1.9 Batches & Composition** is the recommended next milestone (from the 2026-05-28 post-v1.5 assessment, confirmed by v1.7 shipping the prerequisite hook + recording infra):

1. **v1.9 Batches & Composition** *(the pick)* — dedicated `batches` / `batch_jobs` tables (not a DAG), `completed` + `exhausted` callbacks via the generalized callback outbox, chains as linear-DAG sugar, native Batches page with Lifeline-routed bulk-retry. Defer chunks / nested / growable batches.
2. **v1.10 Observability / live counts (QRY-06)** — `oban_met` as an optional read source, never a hard dep.
3. **Native job-surface polish** — QRY-05 (args/meta filter), QRY-07 (Lifeline→job deep-link), QRY-08 (cross-page select), API-03 (`Operator.list/2`). Opportunistic.

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
*Last updated: 2026-06-13 — v1.8 Integration Fixes milestone started*
