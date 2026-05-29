# Roadmap: Oban Powertools

## Milestones

- ✅ **v1 MVP** — Phases 0-7 (shipped 2026-05-21) — [archive](milestones/v1-ROADMAP.md)
- ✅ **v1.1 Host Contract & Adoption Hardening** — Phases 8-15 (shipped 2026-05-23) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Workflow Semantics & Recovery** — Phases 16-26 (shipped 2026-05-25) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Unified Control Plane & Explainability** — Phases 27-31 (shipped 2026-05-26) — [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 Operator Forensics & SRE Runbooks** — Phases 32-42 (shipped 2026-05-27) — [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 Native Job Surface & Automation API** — Phases 43-46 (shipped 2026-05-28) — [archive](milestones/v1.5-ROADMAP.md)
- 🚧 **v1.6 Release & Operability** — Phases 47-51 (in progress)

## Phases

<details>
<summary>✅ v1.4 Operator Forensics & SRE Runbooks (Phases 32-42) — SHIPPED 2026-05-27</summary>

- [x] Phase 32: Forensic Timeline & Evidence Bundle Foundation (3/3 plans) — completed 2026-05-27
- [x] Phase 33: Limiter History & Cron Missed-Fire Diagnostics (3/3 plans) — completed 2026-05-27
- [x] Phase 34: Historical Attention Projection & Runbook Entry Surfaces (3/3 plans) — completed 2026-05-27
- [x] Phase 35: Runbook-Guided Remediation & Alert Hook Boundaries (3/3 plans) — completed 2026-05-27
- [x] Phase 36: Docs/Example-Host/Verification/Support-Truth Closure (3/3 plans) — completed 2026-05-27
- [x] Phase 37: Verification Backfill for Forensic & Ops Baseline (3/3 plans) — completed 2026-05-27
- [x] Phase 38: Docs & Example-Host Forensics Journey Closure (3/3 plans) — completed 2026-05-27
- [x] Phase 39: CI Continuity Proof Lane Closure (3/3 plans) — completed 2026-05-27
- [x] Phase 40: Phase 34 Manual Acceptance Closure (2/2 plans) — completed 2026-05-27
- [x] Phase 41: Runbook Link Fidelity & Atom Safety Hardening (1/1 plan) — completed 2026-05-27
- [x] Phase 42: Nyquist Validation Compliance Sweep (1/1 plan) — completed 2026-05-27

</details>

<details>
<summary>✅ v1.5 Native Job Surface & Automation API (Phases 43-46) — SHIPPED 2026-05-28</summary>

Full phase details: [milestones/v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)

- [x] Phase 43: Read-Only Job Browse (3/3 plans) — completed 2026-05-28
- [x] Phase 44: Single-Job Actions (2/2 plans) — completed 2026-05-28
- [x] Phase 45: Bulk Operations (2/2 plans) — completed 2026-05-28
- [x] Phase 46: Operator Elixir API (2/2 plans) — completed 2026-05-28

</details>

<details open>
<summary>🚧 v1.6 Release & Operability (Phases 47-51) — IN PROGRESS</summary>

**Milestone goal:** Make Oban Powertools real for adopters — publish it to hex and ship the two named operability footguns — before adding any more capability. Zero new runtime dependencies. The release IS the milestone.

**Verification convention (graduated from v1.5):** phase verification and the milestone audit must assert a clean working tree (or per-phase commit existence), not validate working-tree-only state.

### Phase 47: Hex Release Foundation

**Goal:** Package and publish Oban Powertools to hex.pm at a deliberate 0.5.0 with correctly rendering documentation, so adopters can install it as a real dependency.

**Requirements:** REL-01, REL-02, REL-03
**Plans:** 3 plans
**Wave 1**

- [x] 47-01-PLAN.md — CHANGELOG.md (0.5.0 + path-to-1.0) and Apache-2.0 LICENSE

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 47-02-PLAN.md — mix.exs package/0 + docs/0 + igniter scope, tarball/docs verification, README ~> 0.5

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 47-03-PLAN.md — release-please pipeline (config + manifest + workflow) and operator publish handoff

**Success Criteria:**

1. `mix hex.build --unpack` shows the package ships `priv/` migration generators and excludes `.planning/`, `test/`, and dev cruft.
2. The library publishes to hex.pm at version 0.5.0 and the package page renders.
3. ExDoc documentation builds with `source_ref` pinned to the release tag and renders on hexdocs with guides as extras.
4. `CHANGELOG.md` documents the 0.5.0 release and the explicit path to 1.0.

### Phase 48: Doctor Health-Check Task

**Goal:** Ship `mix oban_powertools.doctor` so operators can diagnose index, migration, and config health read-only before and after deploys.

**Requirements:** OPS-03, OPS-04, OPS-05
**Plans:** 1/2 plans executed

**Wave 1**

- [x] 48-01-PLAN.md — Doctor core: Finding struct, run/2 orchestrator + exit_code_for/1, and the five read-only catalog checks (index validity, missing indexes, Oban migration version, Powertools tables, uniqueness-timeout risk)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 48-02-PLAN.md — Formatter (human + JSON schema_version) and the plain Mix.Task entry (flags, repo/prefix resolution, repo-only with_repo boot, honest System.halt exit codes) + operator smoke-verify

**Success Criteria:**

1. `mix oban_powertools.doctor` reports Oban index presence and flags `INVALID` indexes, fully read-only over `pg_catalog`.
2. The task detects migration drift and validates config, honoring a custom Oban prefix/schema.
3. The task flags uniqueness-timeout risk.
4. The task returns exit codes 0 (ok) / 1 (warnings) / 2 (errors) suitable for CI.
5. Output includes actionable remediation hints.

### Phase 49: Limiter Explain/Simulate CLI

**Goal:** Ship `mix oban_powertools.limiter.explain` and `.simulate` so operators can diagnose and preview limiter behavior from the command line, reusing existing seams.

**Requirements:** OPS-06, OPS-07, OPS-08

**Success Criteria:**

1. `mix oban_powertools.limiter.explain` explains a limiter's current blocking state via the existing `Explain` API.
2. `mix oban_powertools.limiter.simulate` previews limiter behavior for a config without mutating real state.
3. The CLI ships the rate-limit glossary in its help/documentation output.
4. Both commands reuse `Explain`/`Limits` without duplicating limiter logic.

### Phase 50: Telemetry Metrics & SLO Guide

**Goal:** Give hosts an opt-in, reporter-agnostic metrics surface and an SLO guide over the frozen telemetry contract, with no new runtime dependency.

**Requirements:** TEL-01, TEL-02, TEL-03

**Success Criteria:**

1. `ObanPowertools.Telemetry.metrics/0` returns `Telemetry.Metrics` definitions over the frozen low-cardinality contract.
2. `telemetry_metrics`/`telemetry_poller` are optional deps gated like `oban_web` — no runtime cost or failure when absent.
3. A Parapet/SLO telemetry guide documents golden-signals/SLO setup with no `oban_met` dependency.
4. Metric tags stay within the frozen low-cardinality contract (no `job_id`/`args`).

### Phase 51: Published-Package Verification

**Goal:** Prove the published package actually works for a fresh adopter — getting-started from hex, not from the repo.

**Requirements:** REL-04

**Success Criteria:**

1. A fresh host app adds the dependency from hex and installs cleanly.
2. The getting-started quickstart reaches a first successful operator session from the published package.
3. The verification asserts a clean working tree (or per-phase commit existence) per the v1.5-graduated convention.
4. Any drift found between in-repo and published behavior is documented or fixed.

</details>

## Progress

| Phase | Milestone | Plans Complete | Status   | Completed  |
|-------|-----------|----------------|----------|------------|
| 0-7   | v1        | 28/28          | Complete | 2026-05-21 |
| 8-15  | v1.1      | 27/27          | Complete | 2026-05-23 |
| 16-26 | v1.2      | 31/31          | Complete | 2026-05-25 |
| 27-31 | v1.3      | 15/15          | Complete | 2026-05-26 |
| 32-42 | v1.4      | 27/27          | Complete | 2026-05-27 |
| 43-46 | v1.5      | 9/9            | Complete | 2026-05-28 |
| 47-51 | v1.6      | 0/—            | Planning | —          |
