# Roadmap: Oban Powertools

## Milestones

- ✅ **v1 MVP** — Phases 0-7 (shipped 2026-05-21) — [archive](milestones/v1-ROADMAP.md)
- ✅ **v1.1 Host Contract & Adoption Hardening** — Phases 8-15 (shipped 2026-05-23) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Workflow Semantics & Recovery** — Phases 16-26 (shipped 2026-05-25) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Unified Control Plane & Explainability** — Phases 27-31 (shipped 2026-05-26) — [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 Operator Forensics & SRE Runbooks** — Phases 32-42 (shipped 2026-05-27) — [archive](milestones/v1.4-ROADMAP.md)
- 📋 **v1.5 Native Job Surface & Automation API** — Phases 43-46 (in progress)

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

### 📋 v1.5 Native Job Surface & Automation API (Phases 43-46)

- [x] **Phase 43: Read-Only Job Browse** — Native job list and detail views with filter/search and DisplayPolicy redaction (completed 2026-05-28)
- [ ] **Phase 44: Single-Job Actions** — Retry, cancel, discard on individual jobs through the full Lifeline preview/reason/audit pipeline
- [ ] **Phase 45: Bulk Operations** — Bulk retry/cancel/discard for a visible job selection with per-job result reporting
- [ ] **Phase 46: Operator Elixir API** — Typed programmatic surface for single and bulk job mutations with actor attribution

## Phase Details

### Phase 43: Read-Only Job Browse

**Goal**: Operators can browse and inspect jobs natively without touching the Oban Web bridge
**Depends on**: Phase 42 (v1.4 complete baseline)
**Requirements**: QRY-01, QRY-02
**Success Criteria** (what must be TRUE):

  1. Operator can open a native `/ops/jobs/jobs` (or equivalent route) page listing jobs filtered by state — state is the primary navigation dimension
  2. Operator can narrow the job list by queue, worker, and tags without triggering a sequential scan (state leads the WHERE clause; tags filter requires documented host-owned GIN index)
  3. Operator can click any job row and see its full detail — args, meta, errors, attempt history, and timing — with `DisplayPolicy` redaction applied to args and meta
  4. Filter state is URL-serialized so deep-links and browser back/forward preserve the current view
  5. Unauthorized actors see a read-only banner and cannot reach mutation surfaces from the browse or detail pages

**Plans**: 3 plans

  - [x] 43-01-PLAN.md — Data layer: ObanPowertools.Jobs context module + %JobFilter{} + DisplayPolicy render_job_field/3 + Selectors :jobs path + unit tests
  - [x] 43-02-PLAN.md — Wave 2: LiveAuth atoms + router routes + JobsLive :index action (list page, state tabs, filter, push_patch) + LiveView tests
  - [x] 43-03-PLAN.md — Wave 3: JobsLive :show action (detail render with DisplayPolicy redaction, errors/attempt panels, back link) + detail tests

**UI hint**: yes

### Phase 44: Single-Job Actions

**Goal**: Operators can retry, cancel, or discard an individual job through the full audited Lifeline pipeline
**Depends on**: Phase 43
**Requirements**: QRY-03
**Success Criteria** (what must be TRUE):

  1. Operator can initiate retry, cancel, or discard from the job detail page and sees a preview of the action before committing
  2. Operator must supply a reason string before executing any mutation — no mutation fires without a reason
  3. Each executed action produces a durable audit record via `Lifeline.execute_repair` — no direct `Oban` function calls occur in the LiveView event handler
  4. A concurrent-modification guard returns a visible error (not a silent success) when another operator has already changed the job's state before the action executes
  5. `"job_discard"` is registered in `Lifeline.@supported_actions`; nil-incident browse-initiated actions are explicitly permitted through the Lifeline guard

**Plans**: 2 plans

  - [ ] 44-01-PLAN.md — Implement Lifeline job_discard Action Support
  - [ ] 44-02-PLAN.md — Implement Single-Job UI Actions in JobsLive
**UI hint**: yes

### Phase 45: Bulk Operations

**Goal**: Operators can retry, cancel, or discard a visible selection of jobs with clear per-job outcome reporting
**Depends on**: Phase 44
**Requirements**: QRY-04
**Success Criteria** (what must be TRUE):

  1. Operator can select multiple jobs via checkbox on the job list page (MapSet-backed selection via `JS.push/3`) and see a count of selected jobs
  2. Operator can bulk retry, cancel, or discard the selection (capped at configurable max, default 100) and sees a count-preview before committing
  3. Each job in the selection runs its own `Lifeline.execute_repair` call — no single Ecto.Multi wraps all N jobs
  4. After execution, the operator sees a per-job breakdown of successes and failures — partially-failed bulk operations are reported honestly, not collapsed

**Plans**: TBD
**UI hint**: yes

### Phase 46: Operator Elixir API

**Goal**: Host app code can programmatically retry, cancel, or discard jobs with the same audit guarantee as the UI
**Depends on**: Phase 45
**Requirements**: API-01, API-02
**Success Criteria** (what must be TRUE):

  1. `ObanPowertools.Operator` exposes typed functions for single-job retry, cancel, and discard — each requires a non-nil actor and produces a durable audit record
  2. `ObanPowertools.Operator` exposes typed functions for bulk retry, cancel, and discard accepting a list of job IDs — returns per-job result reporting matching the UI behavior
  3. API functions call the same `Lifeline.execute_repair` pipeline the UI phases established — no parallel mutation path exists
  4. Telemetry emitted from API calls carries `source: "api"` metadata and remains within the frozen `@contract` (no new high-cardinality keys added)

**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status      | Completed  |
|-------|-----------|---------------|-------------|------------|
| 0-7   | v1        | 28/28         | Complete    | 2026-05-21 |
| 8-15  | v1.1      | 27/27         | Complete    | 2026-05-23 |
| 16-26 | v1.2      | 31/31         | Complete    | 2026-05-25 |
| 27-31 | v1.3      | 15/15         | Complete    | 2026-05-26 |
| 32    | v1.4      | 3/3           | Complete    | 2026-05-27 |
| 33    | v1.4      | 3/3           | Complete    | 2026-05-27 |
| 34    | v1.4      | 3/3           | Complete    | 2026-05-27 |
| 35    | v1.4      | 3/3           | Complete    | 2026-05-27 |
| 36    | v1.4      | 3/3           | Complete    | 2026-05-27 |
| 37    | v1.4      | 3/3           | Complete    | 2026-05-27 |
| 38    | v1.4      | 3/3           | Complete    | 2026-05-27 |
| 39    | v1.4      | 3/3           | Complete    | 2026-05-27 |
| 40    | v1.4      | 2/2           | Complete    | 2026-05-27 |
| 41    | v1.4      | 1/1           | Complete    | 2026-05-27 |
| 42    | v1.4      | 1/1           | Complete    | 2026-05-27 |
| 43    | v1.5      | 3/3 | Complete    | 2026-05-28 |
| 44    | v1.5      | 0/?           | Not started | —          |
| 45    | v1.5      | 0/?           | Not started | —          |
| 46    | v1.5      | 0/?           | Not started | —          |
