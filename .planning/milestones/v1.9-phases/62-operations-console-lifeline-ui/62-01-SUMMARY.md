---
phase: 62-operations-console-lifeline-ui
plan: 01
subsystem: testing
tags: [exunit, liveview, batches, lifeline, red-tests]
requires:
  - phase: 61-apis-batches-chains
    provides: batch, callback, and chain data contracts for operator UI validation
provides:
  - Wave 0 RED tests for batch routes, selectors, LiveView rendering, read model, and callback retry
  - Tagged test commands for Phase 62 implementation slices
affects: [batches-ui, lifeline, web]
tech-stack:
  added: []
  patterns: [tagged ExUnit validation scaffold, LiveView route RED tests]
key-files:
  created:
    - test/oban_powertools/batches_test.exs
    - test/oban_powertools/lifeline_callback_test.exs
    - test/oban_powertools/web/live/batches_live_test.exs
  modified:
    - test/oban_powertools/web/router_test.exs
    - test/oban_powertools/web/selectors_test.exs
    - test/oban_powertools/lifeline/target_type_test.exs
key-decisions:
  - "Phase 62 implementation will be driven by tagged RED tests for route/rendering, read-model, blocked-state, and callback retry behavior."
  - "Batches read tests construct the planned filter struct at runtime so the scaffold compiles before ObanPowertools.Batches exists."
patterns-established:
  - "Phase 62 test tags split implementation feedback into phase62_batches_render, phase62_batch_bulk_retry, phase62_batch_callback_retry, phase62_read_list, phase62_read_detail, phase62_blocked, phase62_callback_preview, and phase62_callback_execute."
requirements-completed: [BUI-01, BUI-02, BUI-03, BUI-04]
duration: 10 min
completed: 2026-06-15
---

# Phase 62 Plan 01: Validation Scaffold Summary

**Tagged RED validation scaffold for native batch routes, read model, LiveView, and Lifeline callback retry**

## Performance

- **Duration:** 10 min
- **Started:** 2026-06-15T02:44:33Z
- **Completed:** 2026-06-15T02:54:49Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added RED route, selector, and LiveView tests for `/ops/jobs/batches` and `/ops/jobs/batches/:id`.
- Added RED `ObanPowertools.Batches` read-model tests for list filters, counts, details, retry eligibility, chain context, and blocked-state copy.
- Added RED Lifeline callback retry tests covering target enum, preview, execute, reason, drift, expiry, consumption, authorization, and audit evidence.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add router, selector, and LiveView route behavior tests** - `0a547d9` (test)
2. **Task 2: Add Batches read-model tests** - `b489941` (test)
3. **Task 3: Add Lifeline callback retry tests** - `2381fe6` (test)

## Files Created/Modified

- `test/oban_powertools/web/live/batches_live_test.exs` - LiveView RED coverage for index/detail rendering, read-only controls, bulk retry, and callback retry.
- `test/oban_powertools/batches_test.exs` - Read-model RED coverage for list/detail/count/blocked-state contracts.
- `test/oban_powertools/lifeline_callback_test.exs` - Lifeline callback retry RED coverage.
- `test/oban_powertools/web/router_test.exs` - Canonical batch route assertions.
- `test/oban_powertools/web/selectors_test.exs` - Canonical batch selector assertions.
- `test/oban_powertools/lifeline/target_type_test.exs` - Closed target enum assertion for `"callback"`.

## Decisions Made

The scaffold intentionally remains RED until Plans 62-02 through 62-05 provide the missing route, selector, read-model, Lifeline, and LiveView behavior.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed. **Impact:** No scope change.

## Issues Encountered

The first RED run exposed compile-time struct expansion from `%Batches{}` before the planned module exists. The tests now build the planned struct at runtime through `struct(Batches, attrs)`, preserving a compile-clean RED scaffold.

## Verification

`mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/selectors_test.exs test/oban_powertools/web/live/batches_live_test.exs test/oban_powertools/batches_test.exs test/oban_powertools/lifeline_callback_test.exs test/oban_powertools/lifeline/target_type_test.exs`

Result: expected RED. Failures point to missing Phase 62 implementation surfaces: `Batches`, `BatchesLive`, batch routes/selectors, callback target enum, and `callback_retry`.

## Self-Check: PASSED

- Key test files exist.
- Tagged tests for each Phase 62 implementation area exist.
- Expected RED failures are caused by missing planned implementation behavior, not syntax errors.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 62-02 route, selector, and LiveAuth implementation.

---
*Phase: 62-operations-console-lifeline-ui*
*Completed: 2026-06-15*
