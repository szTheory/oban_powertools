---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 17
subsystem: security
tags: [jobs, liveview, authorization, postgresql, signed-int64]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 15
    provides: Signed-int64-safe Jobs quick-review parsing and connected query telemetry
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 16
    provides: Phase verification evidence isolating the remaining full-detail WR-01 gap
provides:
  - One signed-int64-safe canonical parser shared by Jobs quick review and full detail
  - Canonical decimal-string or nil-sentinel mount authorization resources
  - Zero-query connected overflow and malformed full-detail behavior
affects: [jobs, authorization, deep-links, PAGE-02, WR-01]

tech-stack:
  added: []
  patterns:
    - Normalize untrusted resource identity before host authorization
    - Reject database-bound integers outside the exact downstream signed range
    - Use one finite nil sentinel for malformed page-level detail authorization

key-files:
  created: []
  modified:
    - lib/oban_powertools/web/jobs_params.ex
    - lib/oban_powertools/web/jobs_live.ex
    - test/oban_powertools/web/jobs_params_test.exs
    - test/oban_powertools/web/live/jobs_live_test.exs

key-decisions:
  - "Jobs quick review and full detail share one public parser accepting only positive IDs through PostgreSQL signed bigint maximum."
  - "Mount authorization receives canonical decimal strings for valid job IDs and exactly nil for every malformed or overflow ID."
  - "Parser failure remains subject to the host's page-level view_job_detail decision but stops before resource reauthorization and Repo access."

patterns-established:
  - "Authorization-boundary normalization: attacker-controlled path identity is converted to a canonical bounded resource or a finite sentinel before host policy."
  - "Uniform unavailable truth: missing, malformed, and overflow detail targets share the same authorized-viewer presentation without database error detail."

requirements-completed:
  - PAGE-02

duration: 4m
completed: 2026-07-29
status: complete
---

# Phase 80 Plan 17: Canonical Jobs Detail ID Boundary Summary

**One signed-int64 Jobs ID parser now protects both mount authorization and full-detail repository loading while preserving the uniform unavailable state**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-29T04:51:00Z
- **Completed:** 2026-07-29T04:55:47Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Promoted Jobs ID parsing into one documented `JobsParams.parse_job_id/1` contract that accepts only positive integers or full decimal strings through `9_223_372_036_854_775_807`.
- Normalized full-detail mount authorization to `%{type: :job, id: canonical_decimal_string}` or exactly `%{type: :job, id: nil}` before the host policy runs.
- Removed the separate unbounded detail parser and prevented malformed or overflow IDs from reaching resource reauthorization or `Jobs.get/2`.
- Added connected recording-policy and query-telemetry regressions proving maximum-ID behavior, zero-query overflow/malformed behavior, uniform unavailable HTML, and preserved mount denial.

## Task Commits

The task was committed through a TDD red/green cycle:

1. **RED:** `93a6f14` — failing shared-parser, authorization-resource, and query-boundary regressions.
2. **GREEN:** `8a8fd81` — shared parser plus bounded mount and detail-loading implementation.

## Files Created/Modified

- `lib/oban_powertools/web/jobs_params.ex` - Public canonical signed-int64 Jobs ID parser and unchanged optional quick-review semantics.
- `lib/oban_powertools/web/jobs_live.ex` - Canonical mount authorization resources and parser-gated detail loading.
- `test/oban_powertools/web/jobs_params_test.exs` - Direct maximum, overflow, malformed, integer, and binary parser regressions.
- `test/oban_powertools/web/live/jobs_live_test.exs` - Recording auth policy, connected query telemetry, uniform unavailable, and denial regressions.

## Decisions Made

- Kept absent `job` query state valid and separate from malformed explicit quick-review values by adapting `parse_url/1` around the shared parser.
- Used the nil sentinel only for mount-time page permission; malformed IDs never receive a resource-level reauthorization or database lookup.
- Measured connected query counts after the static render so the maximum path proves exactly one connected bounded lookup while overflow paths prove zero.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Direct `live/2` query telemetry includes both static and connected render lookups. The regression was refined to connect from the static response and measure the connected phase explicitly, matching the plan's connected-query contract.
- The recording policy also observes existing page-level action-control checks during unavailable rendering. Assertions retain the complete recording policy while filtering specifically for the `:view_job_detail` resource contract under test.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/oban_powertools/web/jobs_params_test.exs test/oban_powertools/web/live/jobs_live_test.exs --seed 0` — 62 tests, 0 failures.
- `mix test test/oban_powertools/jobs_test.exs test/oban_powertools/auth_test.exs test/oban_powertools/web/router_test.exs --seed 0` — 28 tests, 0 failures.
- Plan-scoped `mix format --check-formatted` — passed.
- Plan-scoped `git diff --check` — passed.
- Schema and migration scope guard — passed with zero changed files.

## Next Phase Readiness

- WR-01 is closed at both authorization and repository boundaries with exact signed-int64 and zero-query evidence.
- PAGE-02 is ready for Phase 80 re-verification and terminal phase bookkeeping.
- No blockers remain from this plan.

## Self-Check: PASSED

All four key files exist, both TDD commits are present, every task acceptance criterion and plan-level verification passed, and no unrelated dirty-tree changes were staged.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-29*
