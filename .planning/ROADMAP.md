# Roadmap: Oban Powertools

## Milestones

- ✅ **v1 MVP** — Phases 0-7 (shipped 2026-05-21) — [archive](milestones/v1-ROADMAP.md)
- ✅ **v1.1 Host Contract & Adoption Hardening** — Phases 8-15 (shipped 2026-05-23) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Workflow Semantics & Recovery** — Phases 16-26 (shipped 2026-05-25) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Unified Control Plane & Explainability** — Phases 27-31 (shipped 2026-05-26) — [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 Operator Forensics & SRE Runbooks** — Phases 32-42 (shipped 2026-05-27) — [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 Native Job Surface & Automation API** — Phases 43-46 (shipped 2026-05-28) — [archive](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 Release & Operability** — Phases 47-52.1 (shipped 2026-05-30) — [archive](milestones/v1.6-ROADMAP.md)
- ⏳ **v1.7 Worker Lifecycle & Safety** — Phases 53-56 (started 2026-05-30)

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

### v1.7 Worker Lifecycle & Safety

- [ ] **Phase 53: Worker Lifecycle Hooks** — per-job observe-only callbacks with crash-caught dispatch and telemetry contract extension
- [ ] **Phase 54: deadline: / timeout: Pass-through** — compile-time soft deadline and timeout opts with Doctor integration
- [ ] **Phase 55: Output Recording (JobRecord)** — new schema for fault-tolerant job output persistence with detail-view visibility
- [ ] **Phase 56: redact: At-Rest** — compile-time field redaction from args at enqueue with UI annotation and recording integration

## Phase Details

### Phase 53: Worker Lifecycle Hooks

**Goal**: Every ObanPowertools.Worker can observe its own execution lifecycle with crash-safe callbacks that never affect job outcome
**Depends on**: Phase 52.1 (v1.6 complete)
**Requirements**: HOOK-01, HOOK-02, HOOK-03, HOOK-04, HOOK-05
**Success Criteria** (what must be TRUE):

  1. A worker declaring `on_start/1` has that callback invoked before `process/1` runs; a crash in the callback does not retry the job
  2. A worker declaring `on_success/2` receives the `:ok`/`{:ok, _}` result after `process/1` succeeds; `on_failure/2` receives the error when `process/1` returns `{:error, _}` or raises
  3. A worker's `on_discard/2` fires exactly once when a job is discarded after retry exhaustion, not on each failed attempt
  4. Workers that omit any hook callback compile and run without error via no-op `defoverridable` defaults
  5. Hook invocations produce telemetry events under the `:worker_hook` family in the frozen low-cardinality contract (`hook` and `outcome` keys present)

**Plans**: 2 plans
Plans:
**Wave 1**

- [x] 53-01-PLAN.md - Core worker lifecycle hook runtime, crash safety, routing, and telemetry contract

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 53-02-PLAN.md - Worker hook support-truth docs, telemetry guide, and docs-contract tests

### Phase 54: deadline: / timeout: Pass-through

**Goal**: Workers can declare per-job execution time limits and wall-clock expiry constraints as compile-time opts that Oban and the perform wrapper enforce automatically
**Depends on**: Phase 53
**Requirements**: SAFE-01, SAFE-02, SAFE-03, SAFE-04
**Success Criteria** (what must be TRUE):

  1. A worker declaring `timeout: 5_000` has Oban use that value as the per-attempt kill timeout without any additional host configuration
  2. A worker declaring `deadline: :timer.hours(24)` causes enqueued jobs to store `__deadline_at__` as an ISO8601 timestamp in meta
  3. When `perform/1` runs and wall-clock time has passed `__deadline_at__`, the job returns `{:cancel, :deadline_expired}` without calling `process/1`
  4. `mix oban_powertools.doctor` reports `retryable` jobs with an expired `__deadline_at__` as a warning

**Plans**: TBD

### Phase 55: Output Recording (JobRecord)

**Goal**: Workers can opt in to persisting their successful output in a dedicated schema that operators can query and inspect in the job detail view
**Depends on**: Phase 53
**Requirements**: REC-01, REC-02, REC-03, REC-04, REC-05
**Success Criteria** (what must be TRUE):

  1. A worker declaring `record_output: true` has its `{:ok, payload}` return value persisted to `oban_powertools_job_records` after `process/1` succeeds; a recording failure logs a warning but does not fail or retry the job
  2. `ObanPowertools.JobRecord.fetch_result/1` returns `{:ok, result}` for a job that recorded output and `{:error, :not_found}` for one that did not
  3. The `/ops/jobs` job detail view shows the recorded output for jobs where output was persisted
  4. A worker declaring `output_limit: 65_536` has payloads exceeding that byte count rejected at record time with a warning rather than stored or truncated silently
  5. A worker declaring `output_retention: :ephemeral` has its job records pruned on the shorter retention schedule via the existing Lifeline prune cycle

**Plans**: TBD
**UI hint**: yes

### Phase 56: redact: At-Rest

**Goal**: Workers can declare which arg fields must be dropped from persistence at enqueue time, with transparent operator visibility into what was redacted and why
**Depends on**: Phase 55
**Requirements**: REDACT-01, REDACT-02, REDACT-03, REDACT-04
**Success Criteria** (what must be TRUE):

  1. A worker declaring `redact: [:ssn, :token]` causes those keys to be absent from `oban_jobs.args` in the database after enqueue, while the idempotency fingerprint is computed from the original unredacted args
  2. Enqueued jobs store `__redacted_fields__` in meta listing which fields were dropped, so the record is self-describing
  3. The `/ops/jobs` job detail view renders "Fields redacted at enqueue: [:ssn, :token]" when `__redacted_fields__` is present in meta
  4. `DisplayPolicy.render_job_field/3` shows "Redacted at enqueue" for any arg field listed in `__redacted_fields__` rather than displaying a missing value

**Plans**: TBD
**UI hint**: yes

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
| 53    | v1.7      | 1/2            | In Progress | -          |
| 54    | v1.7      | 0/TBD          | Not started | -          |
| 55    | v1.7      | 0/TBD          | Not started | -          |
| 56    | v1.7      | 0/TBD          | Not started | -          |
