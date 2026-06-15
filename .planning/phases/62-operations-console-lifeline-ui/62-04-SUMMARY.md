---
phase: 62-operations-console-lifeline-ui
plan: 04
subsystem: lifeline
tags: [lifeline, callback, audit, drift-detection, recovery]
requires:
  - phase: 62-operations-console-lifeline-ui
    provides: 62-01 RED tests for callback target preview and execute
provides:
  - First-class `callback_retry` Lifeline action
  - Closed `"callback"` target type support for audit resources and host follow-up
  - Callback retry preview, execute, drift, preview lifecycle, and audit behavior
affects: [lifeline, callbacks, audit]
tech-stack:
  added: []
  patterns: [Lifeline preview/execute transaction, closed target enum, callback drift hash]
key-files:
  created: []
  modified:
    - lib/oban_powertools/lifeline.ex
    - lib/oban_powertools/lifeline/target_type.ex
key-decisions:
  - "Callback retry is a Lifeline action, not a LiveView-owned callback mutation."
  - "Only failed callbacks and expired claimed callbacks are retryable."
  - "Callback execution resets retryable callbacks to pending, clears claim/delivery/failure fields, and preserves attempts."
patterns-established:
  - "Callback previews hash durable callback evidence so execution detects state drift before mutation."
  - "Consumed previews and repair audit metadata include before/after callback snapshots."
requirements-completed: [BUI-04]
duration: 4 min
completed: 2026-06-15
---

# Phase 62 Plan 04: Lifeline Callback Retry Summary

**Callback retry preview and execute support inside the existing Lifeline repair boundary**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-15T03:05:24Z
- **Completed:** 2026-06-15T03:08:06Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `"callback"` to `ObanPowertools.Lifeline.TargetType`.
- Added `callback_retry` to Lifeline supported actions and preview dispatch.
- Implemented callback preview for failed callbacks and claimed callbacks with expired leases.
- Added callback plan-hash recomputation so event, dedupe key, status, attempts, lease/delivery fields, and last error drift blocks execution.
- Added callback execution inside the existing `apply_repair/6` `Ecto.Multi`, resetting callbacks to `pending`, clearing claim/delivery/failure fields, preserving attempts, consuming the preview, and writing callback audit evidence.

## Task Commits

The implementation was committed as one cohesive Lifeline extension:

1. **Tasks 1-2: Add callback target preview and execute support** - `c63ed44` (feat)

## Files Created/Modified

- `lib/oban_powertools/lifeline.ex` - Adds callback preview, drift hash, mutation, before/after metadata, and callback repair summary.
- `lib/oban_powertools/lifeline/target_type.ex` - Adds closed `"callback"` target conversion.

## Decisions Made

Callback retry uses the same Lifeline preview token, reason, drift, transaction, audit, host-follow-up, and telemetry flow as job and workflow repairs. The UI will call Lifeline from Plan 62-05 rather than updating callback rows directly.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed. **Impact:** No scope change.

## Issues Encountered

None.

## Verification

- `mix test test/oban_powertools/lifeline/target_type_test.exs` passed: `2 tests, 0 failures`.
- `mix test test/oban_powertools/lifeline_callback_test.exs --only phase62_callback_preview` passed: `3 tests, 0 failures`.
- `mix test test/oban_powertools/lifeline_callback_test.exs --only phase62_callback_execute` passed.
- `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/lifeline/target_type_test.exs` passed: `26 tests, 0 failures`.

## Self-Check: PASSED

- `callback_retry` is a first-class Lifeline action.
- `"callback"` is a closed target type and unknown target strings still raise.
- Callback retry cannot bypass Lifeline preview, authorization, reason validation, drift checks, preview consumption, or audit recording.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 62-05 native `BatchesLive` implementation.

---
*Phase: 62-operations-console-lifeline-ui*
*Completed: 2026-06-15*
