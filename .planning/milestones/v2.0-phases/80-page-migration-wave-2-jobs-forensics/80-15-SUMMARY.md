---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 15
subsystem: security
tags: [jobs, postgresql, liveview, otp, batch-coordinator]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 13
    provides: Phase closure verification identifying oversized URL and frozen-result gaps
provides:
  - Signed-64-bit-safe Jobs page and quick-review URL parsing
  - Frozen target identity across every batch terminal path
  - Fail-closed LiveView reconciliation for malformed execution positions
affects: [jobs, batch-recovery, url-safety, PAGE-02, FORM-03]

tech-stack:
  added: []
  patterns:
    - Bound URL integers to the exact downstream database binding before canonical state
    - Associate ordered async terminals with their originating frozen targets
    - Validate exact unique position sets before joining post-effect results

key-files:
  created: []
  modified:
    - lib/oban_powertools/web/jobs_params.ex
    - lib/oban_powertools/jobs/batch_coordinator.ex
    - lib/oban_powertools/web/jobs_live.ex
    - test/oban_powertools/web/jobs_params_test.exs
    - test/oban_powertools/jobs/batch_coordinator_test.exs
    - test/oban_powertools/web/live/jobs_live_test.exs

key-decisions:
  - "Jobs pages are bounded by the largest page whose 20-row offset fits signed 64-bit Postgrex encoding; quick-review IDs are bounded directly by signed 64-bit maximum."
  - "Execution authorization and Lifeline execution share one per-target timeout, while ordered stream terminals remain paired with their originating frozen targets."
  - "LiveView accepts execution results only when their count and exact unique integer position set equal the ready preview positions."

patterns-established:
  - "Database-bound URL safety: reject rather than clamp, truncate, or partially parse oversized integers."
  - "Post-effect recovery: malformed terminal identity preserves selection and reports interruption/Audit recovery instead of joining partial data."

requirements-completed: []

coverage:
  - deliverable: Signed-64-bit-safe Jobs URL parsing
    verification:
      - kind: test
        ref: "test/oban_powertools/web/jobs_params_test.exs#page and job URL integers are bounded by their Postgrex bindings"
        status: pass
      - kind: test
        ref: "test/oban_powertools/web/live/jobs_live_test.exs#canonicalizes oversized page and job URL values before Repo bindings"
        status: pass
    human_judgment: false
  - deliverable: Exact frozen batch terminal positions
    verification:
      - kind: test
        ref: "test/oban_powertools/jobs/batch_coordinator_test.exs#stalled authorization retains its frozen position after later targets finish"
        status: pass
      - kind: command
        ref: "three consecutive complete batch_coordinator_test.exs runs with --seed 0"
        status: pass
    human_judgment: false
  - deliverable: Fail-closed LiveView result reconciliation
    verification:
      - kind: test
        ref: "test/oban_powertools/web/live/jobs_live_test.exs#duplicate and missing execution positions fail closed with interruption recovery"
        status: pass
    human_judgment: false

duration: 9m
completed: 2026-07-29
status: complete
---

# Phase 80 Plan 15: Jobs Integer and Frozen-Result Boundary Summary

**Signed-64-bit-safe Jobs URLs and target-associated batch terminals with exact fail-closed LiveView reconciliation**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-29T01:42:17Z
- **Completed:** 2026-07-29T01:51:17Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Rejected oversized page offsets and quick-review IDs before either value can reach a Postgrex binding, while retaining the existing canonical URL and finite invalid-notice behavior.
- Preserved every ready target's original frozen position across success, timeout, crash, authorization stall, and out-of-order completion paths.
- Prevented duplicate, missing, extra, or non-integer execution position sets from reaching the LiveView map join; malformed completion now retains selection and reports interruption/Audit recovery.
- Stabilized the real Lifeline integration assertion with an explicit 1,000 ms preview timeout and proved the complete coordinator suite green three consecutive times.

## Task Commits

Each task was committed atomically through TDD red/green cycles:

1. **Task 80-15-01: Bound Jobs page offsets and job IDs before Repo**
   - `955126f` — failing boundary and connected URL regressions
   - `4e3d33b` — bounded page/job parser implementation
2. **Task 80-15-02: Preserve frozen target positions and fail closed during bulk reconciliation**
   - `5b5b98f` — failing stalled-authorization position regression
   - `522d302` — failing duplicate/missing LiveView reconciliation regressions
   - `7e4f7d0` — target-associated terminals and exact result-set validation

## Files Created/Modified

- `lib/oban_powertools/web/jobs_params.ex` - Distinct bounded page and job parsers using signed 64-bit-safe limits.
- `lib/oban_powertools/jobs/batch_coordinator.ex` - Target-associated async terminal handling and exact ready-position reconciliation.
- `lib/oban_powertools/web/jobs_live.ex` - Exact execution-position validation before the result map join.
- `test/oban_powertools/web/jobs_params_test.exs` - Integer/binary boundary and 50-digit parser coverage.
- `test/oban_powertools/jobs/batch_coordinator_test.exs` - Authorization-stall identity regression and explicit integration timeout.
- `test/oban_powertools/web/live/jobs_live_test.exs` - Connected oversized URL and malformed terminal-set recovery coverage.

## Decisions Made

- The maximum accepted page is `div(9_223_372_036_854_775_807, 20) + 1`, keeping `(page - 1) * 20` encodable without changing the fixed page size.
- Authorization and Lifeline execution run inside the same target timeout so authorization stalls become finite target outcomes.
- Ordered stream association is used for target identity, while completion order remains irrelevant to frozen position truth.
- LiveView validates count, integer shape, uniqueness, and exact set equality before any `Map.fetch!/2`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The red LiveView regression initially asserted a patch consumed during connected mount; it was corrected to exercise a direct connected `render_patch/2`.
- The malformed-result harness initially accumulated jobs between its two cases; the fixture was shared across both isolated LiveViews so each case retained the exact three-target scope.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/oban_powertools/web/jobs_params_test.exs test/oban_powertools/web/live/jobs_live_test.exs --seed 0` — 59 tests, 0 failures.
- `mix test test/oban_powertools/jobs_test.exs test/oban_powertools/web/selectors_test.exs --seed 0` — 30 tests, 0 failures.
- `mix test test/oban_powertools/jobs/batch_coordinator_test.exs --seed 0` — 9 tests, 0 failures, including three consecutive complete runs.
- `mix test test/oban_powertools/auth_test.exs test/oban_powertools/application_test.exs test/oban_powertools/lifeline_test.exs --seed 0` — 35 tests, 0 failures.
- Plan-scoped `mix format --check-formatted` and `git diff --check` — passed.

## Next Phase Readiness

- WR-01, WR-02, and V-TEST-01 are closed with adversarial red/green evidence.
- Jobs URL safety, batch authority, Audit recovery, and confidentiality contracts are ready for Phase 80 re-verification.
- No blockers remain from this plan.

## Self-Check: PASSED

All six modified files exist, all five task commits are present, every acceptance gate and plan-level verification passed, and no unrelated working-tree changes were staged.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-29*
