# Roadmap: Oban Powertools

## Milestones

- ✅ **v1 MVP** — Phases 0-7 (shipped 2026-05-21) — [archive](milestones/v1-ROADMAP.md)
- ✅ **v1.1 Host Contract & Adoption Hardening** — Phases 8-15 (shipped 2026-05-23) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Workflow Semantics & Recovery** — Phases 16-26 (shipped 2026-05-25) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Unified Control Plane & Explainability** — Phases 27-31 (shipped 2026-05-26) — [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 Operator Forensics & SRE Runbooks** — Phases 32-42 (shipped 2026-05-27) — [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 Native Job Surface & Automation API** — Phases 43-46 (shipped 2026-05-28) — [archive](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 Release & Operability** — Phases 47-52.1 (shipped 2026-05-30) — [archive](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 Worker Lifecycle & Safety** — Phases 53-56 (shipped 2026-06-13) — [archive](milestones/v1.7-ROADMAP.md)
- 🚧 **v1.8 Integration Fixes** — Phases 57-58 (in progress)

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

<details>
<summary>✅ v1.6 Release & Operability (Phases 47-52.1) — SHIPPED 2026-05-30</summary>

Full phase details: [milestones/v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md)

- [x] Phase 47: Hex Release Foundation (3/3 plans) — completed 2026-05-29
- [x] Phase 48: Doctor Health-Check Task (2/2 plans) — completed 2026-05-30
- [x] Phase 49: Limiter Explain/Simulate CLI (3/3 plans) — completed 2026-05-30
- [x] Phase 50: Telemetry Metrics & SLO Guide (3/3 plans) — completed 2026-05-30
- [x] Phase 51: Published-Package Verification (3/3 plans) — completed 2026-05-30
- [x] Phase 52: Zero-Touch Release Automation (1/1 plan) — completed 2026-05-30
- [x] Phase 52.1: Close gap REL-04 — fix verify-published CI (INSERTED) (1/1 plan) — completed 2026-05-30

</details>

<details>
<summary>✅ v1.7 Worker Lifecycle & Safety (Phases 53-56) — SHIPPED 2026-06-13</summary>

Full phase details: [milestones/v1.7-ROADMAP.md](milestones/v1.7-ROADMAP.md)

- [x] Phase 53: Worker Lifecycle Hooks (2/2 plans) — completed 2026-06-12
- [x] Phase 54: deadline: / timeout: Pass-through (4/4 plans) — completed 2026-06-12
- [x] Phase 55: Output Recording (JobRecord) (4/4 plans) — completed 2026-06-13
- [x] Phase 56: redact: At-Rest (4/4 plans) — completed 2026-06-13

</details>

### 🚧 v1.8 Integration Fixes (In Progress)

**Milestone Goal:** Close the two non-blocking integration gaps deferred from the v1.7 audit — Doctor manifest coverage for the Phase 55 table and cron-path deadline injection — before expanding capability.

- [ ] **Phase 57: Doctor Manifest Fix** - Add `oban_powertools_job_records` to `@powertools_manifest` so Doctor warns when the output-recording table is absent
- [ ] **Phase 58: Cron Deadline Injection** - Inject `__deadline_at__` meta on the cron scheduling path for `deadline:`-configured Powertools workers

## Phase Details

### Phase 57: Doctor Manifest Fix
**Goal**: Doctor correctly detects a missing `oban_powertools_job_records` table and warns operators, closing the silent gap introduced when Phase 55 shipped the output-recording table without updating the manifest
**Depends on**: Phase 56 (v1.7 complete)
**Requirements**: INT-01
**Success Criteria** (what must be TRUE):
  1. Running `mix oban_powertools.doctor` on a DB missing `oban_powertools_job_records` produces an error finding that names the table and its migration set
  2. Running `mix oban_powertools.doctor` on a fully-migrated DB returns no error for `oban_powertools_job_records` — no regression on the happy path
  3. The Doctor test suite references "all 5 groups present" (not "4 groups") after the manifest update
**Plans**: 1 plan
  - [ ] 57-01-PLAN.md — Add output-recording group to @powertools_manifest and update Doctor test description to "5 groups present"

### Phase 58: Cron Deadline Injection
**Goal**: Cron-scheduled Powertools workers with `deadline:` configured produce `__deadline_at__` in stored job meta, matching the behavior of the non-cron enqueue path through `Idempotency.transaction/3`
**Depends on**: Phase 57
**Requirements**: INT-02
**Success Criteria** (what must be TRUE):
  1. A cron-enqueued job from a `deadline:`-configured Powertools worker has `meta["__deadline_at__"]` present in the database record
  2. A cron-enqueued job from a Powertools worker without `deadline:` has no `__deadline_at__` key in meta — no contamination of plain workers
  3. A cron-enqueued job from a worker with both `redact:` and `deadline:` has both `__redacted_fields__` and `__deadline_at__` present in meta — composition works correctly
  4. Plain (non-Powertools) Oban workers scheduled via cron are unaffected — no `__deadline_at__` injection on the non-Powertools path
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status      | Completed  |
|-------|-----------|----------------|-------------|------------|
| 0-7   | v1        | 28/28          | Complete    | 2026-05-21 |
| 8-15  | v1.1      | 27/27          | Complete    | 2026-05-23 |
| 16-26 | v1.2      | 31/31          | Complete    | 2026-05-25 |
| 27-31 | v1.3      | 15/15          | Complete    | 2026-05-26 |
| 32-42 | v1.4      | 27/27          | Complete    | 2026-05-27 |
| 43-46 | v1.5      | 9/9            | Complete    | 2026-05-28 |
| 47-52.1 | v1.6    | 16/16          | Complete    | 2026-05-30 |
| 53-56 | v1.7      | 14/14          | Complete    | 2026-06-13 |
| 57    | v1.8      | 0/1            | Not started | -          |
| 58    | v1.8      | 0/TBD          | Not started | -          |
