---
milestone: v1
audited: 2026-05-20T22:09:08+02:00
status: gaps_found
scores:
  requirements: 12/16
  phases: 5/5
  integration: 0/1
  flows: 3/4
gaps:
  requirements:
    - id: "FND-01"
      status: "deferred"
      phase: "Phase 0"
      claimed_by_plans: ["0-PLAN.md"]
      completed_by_plans: ["0-01-SUMMARY.md"]
      verification_status: "deferred"
      evidence: "Phase 0 summary and verification now exist, but installer/runtime wiring still needs Phase 6 hardening."
    - id: "FND-02"
      status: "deferred"
      phase: "Phase 0"
      claimed_by_plans: ["0-PLAN.md"]
      completed_by_plans: ["0-01-SUMMARY.md"]
      verification_status: "deferred"
      evidence: "Core auth and telemetry tests pass, but runtime wiring still needs Phase 6 hardening."
    - id: "ENG-03"
      status: "deferred"
      phase: "Phase 2"
      claimed_by_plans: ["2-01-PLAN.md", "2-04-PLAN.md", "2-05-PLAN.md"]
      completed_by_plans: ["2-04-SUMMARY.md"]
      verification_status: "deferred"
      evidence: "Durable cron behavior is implemented and tested, but preview authorization ordering remains a Phase 6 defect."
    - id: "LIF-02"
      status: "open_gap"
      phase: "Phase 4"
      claimed_by_plans: ["4-01-PLAN.md", "4-03-PLAN.md", "4-05-PLAN.md"]
      completed_by_plans: []
      verification_status: "open_gap"
      evidence: "Repair preview and execute flow is green, but acted-on incidents are not retired from active projection after success."
  integration:
    - severity: "high"
      phase: "Phase 4"
      requirements: ["LIF-02"]
      evidence: "Successful repairs do not resolve or retire active incidents; repaired jobs can be re-projected as active incidents on refresh."
    - severity: "high"
      phase: "Phase 0"
      requirements: ["FND-01", "FND-02"]
      evidence: "Installer does not inject required runtime config for repo/auth dependencies; later phases rely on test-only config to pass."
    - severity: "medium"
      phase: "Phase 2"
      requirements: ["FND-02", "ENG-03"]
      evidence: "Cron preview UI exposes preview-side behavior before authorize_action is enforced."
  flows:
    - flow: "Heartbeat -> incident projection -> repair -> incident closure"
      severity: "high"
      requirements: ["LIF-02"]
      evidence: "Execution and audit complete, but post-repair incident closure is not enforced."
nyquist:
  compliant_phases: ["Phase 1", "Phase 2", "Phase 3", "Phase 4"]
  partial_phases: ["Phase 0"]
  missing_phases: []
  overall: "mostly_compliant"
---

# Milestone v1 Audit

## Verdict

**Status:** `gaps_found`

The evidence chain is now substantially repaired:

- Every completed phase now has the required summary and verification artifacts.
- The orphaned requirement set for `FND-03`, `WRK-01..03`, `ENG-01..02`, `WF-01..03`, and `LIF-01`, `LIF-03`, `LIF-04` is closed.
- `REQUIREMENTS.md` now preserves implementation ownership and separates evidence closure from deferred implementation gaps.

The milestone still cannot be archived as fully complete because four real defects remain deferred or open:
- `FND-01`
- `FND-02`
- `ENG-03`
- `LIF-02`

## Local Verification Signals

Commands run during this audit:

- `mix compile --warnings-as-errors` -> passed
- targeted evidence suite -> passed (`76 tests, 0 failures`)
- prior full suite baseline -> passed (`77 tests, 0 failures`)

## Requirement Coverage

| Requirement | Owner | Evidence Status | Result |
|-------------|-------|-----------------|--------|
| FND-03 | Phase 0 | summary + verification present | closed |
| WRK-01 | Phase 1 | summary + verification present | closed |
| WRK-02 | Phase 1 | summary + verification present | closed |
| WRK-03 | Phase 1 | summary + verification present | closed |
| ENG-01 | Phase 2 | summaries + verification present | closed |
| ENG-02 | Phase 2 | summaries + verification present | closed |
| WF-01 | Phase 3 | summaries + verification present | closed |
| WF-02 | Phase 3 | summaries + verification present | closed |
| WF-03 | Phase 3 | summary + verification present | closed |
| LIF-01 | Phase 4 | summary + verification present | closed |
| LIF-03 | Phase 4 | summaries + verification present | closed |
| LIF-04 | Phase 4 | summaries + verification present | closed |
| FND-01 | Phase 0 | verification present | deferred to Phase 6 |
| FND-02 | Phase 0 | verification present | deferred to Phase 6 |
| ENG-03 | Phase 2 | verification present | deferred to Phase 6 |
| LIF-02 | Phase 4 | verification present | open gap for Phase 7 |

## Cross-Phase Integration

The core wiring exists and remains healthy:

- [lib/oban_powertools/application.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/application.ex:1) supervises PubSub, the workflow coordinator, and the lifeline heartbeat writer together.
- [lib/oban_powertools/web/router.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/router.ex:1) mounts the native `/ops/jobs` surfaces for overview, limiters, cron, audit, workflows, and lifeline behind one LiveView shell.
- Targeted workflow, cron, limiter, router, and lifeline tests are green in the current evidence run.

Outstanding integration findings:

1. **High**: Lifeline repair execution does not retire the active incident it acted on. Affected requirement: `LIF-02`.
2. **High**: Installer output still does not inject runtime config for repo/auth dependencies that later phases assume exist. Affected requirements: `FND-01`, `FND-02`.
3. **Medium**: Cron preview actions still expose preview-state behavior before mutation authorization runs. Affected requirements: `FND-02`, `ENG-03`.

## E2E Flow Check

| Flow | Evidence | Result |
|------|----------|--------|
| Installer -> base schemas/auth/router | install, auth, telemetry, router tests | Pass with deferred runtime wiring gap |
| Worker enqueue -> idempotency -> limiter/cron state | worker, idempotency, limits, cron tests | Pass |
| Workflow insert -> runtime completion -> PubSub/UI inspection | workflow, runtime, coordinator, LiveView tests | Pass |
| Incident detection -> repair preview/execute -> audit/archive UI | lifeline + audit + lifeline LiveView tests | Gap: repair does not retire the acted-on incident |

Then:

1. Generate or restore `*-VERIFICATION.md` for Phases 0 through 4.
2. Backfill missing Phase 2 summaries and normalize Phase 3 summary frontmatter.
3. Reconcile `REQUIREMENTS.md` status for `LIF-01` through `LIF-04`.
4. Fix the three integration findings above.
5. Run `mix format` and re-check formatting.
