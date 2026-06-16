---
phase: 62-operations-console-lifeline-ui
plan: 02
subsystem: web
tags: [phoenix, liveview, router, selectors, auth]
requires:
  - phase: 62-operations-console-lifeline-ui
    provides: 62-01 RED tests for batch routes, selectors, and LiveAuth copy
provides:
  - Native `/ops/jobs/batches` and `/ops/jobs/batches/:id` routes
  - Canonical batch selector helpers
  - Batch page/detail and recovery permission copy
affects: [batches-ui, live-auth]
tech-stack:
  added: []
  patterns: [host-owned route shell, canonical selector encoding, read-only permission copy]
key-files:
  created: []
  modified:
    - lib/oban_powertools/web/router.ex
    - lib/oban_powertools/web/selectors.ex
    - lib/oban_powertools/web/live_auth.ex
key-decisions:
  - "Batch index/detail routes live inside the existing `:oban_powertools_native` live session."
  - "Batch links must go through `Selectors.batches_path/1` and `Selectors.batch_detail_path/1`."
patterns-established:
  - "Batch UI view permissions are separate from UI retry affordance permissions and Lifeline preview/execute permissions."
requirements-completed: [BUI-01, BUI-03, BUI-04]
duration: 3 min
completed: 2026-06-15
---

# Phase 62 Plan 02: Routes, Selectors, and Auth Summary

**Native batch route, canonical selector, and read-only permission vocabulary for the batch operations surface**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-15T02:54:49Z
- **Completed:** 2026-06-15T02:56:55Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `/ops/jobs/batches` and `/ops/jobs/batches/:id` LiveView routes.
- Added `Selectors.batches_path/1` and `Selectors.batch_detail_path/1`.
- Added `:view_batches`, `:view_batch_detail`, `:retry_batch_jobs`, and `:retry_callback` permission copy plus `:batches` and `:batch_detail` read-only banners.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add canonical batch routes and selectors** - `4c571cd` (feat)
2. **Task 2: Add batch permission and read-only copy** - `a3e5d91` (feat)

## Files Created/Modified

- `lib/oban_powertools/web/router.ex` - Registers native batch index/detail routes.
- `lib/oban_powertools/web/selectors.ex` - Adds canonical batch path helpers.
- `lib/oban_powertools/web/live_auth.ex` - Adds batch view/retry permission and read-only copy.

## Decisions Made

Batch retry affordance permissions remain distinct from Lifeline service permissions. The UI may use `:retry_batch_jobs` and `:retry_callback` to enable controls, but preview/execute still uses `:preview_repair` and `:execute_repair`.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed. **Impact:** No scope change.

## Issues Encountered

None.

## Verification

- `mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/selectors_test.exs` passed.
- `rg -n "view_batches|view_batch_detail|retry_batch_jobs|retry_callback|batches:|batch_detail:" lib/oban_powertools/web/live_auth.ex` found all expected keys.
- Direct `mix run` banner/message lookup for `:batches`, `:batch_detail`, `:retry_batch_jobs`, and `:retry_callback` passed.
- `mix test test/oban_powertools/web/live/batches_live_test.exs --only phase62_batches_render` remains RED because `ObanPowertools.Web.BatchesLive` is implemented in Plan 62-05.

## Self-Check: PASSED

- Routes and selector helpers pass focused tests.
- LiveAuth copy exists for batch index/detail and both recovery controls.
- No direct mutation behavior was added in this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 62-03 `ObanPowertools.Batches` read model.

---
*Phase: 62-operations-console-lifeline-ui*
*Completed: 2026-06-15*
