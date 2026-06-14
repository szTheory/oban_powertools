---
phase: 60-execution-engine-tracker-hooks
plan: 03
subsystem: worker-hooks
tags: [worker-hooks, batches, callbacks, tdd]
requires:
  - phase: 60-execution-engine-tracker-hooks
    provides: Exactly-once batch job progress tracking
provides:
  - Worker hook batch progress integration
  - Callback exhaustion transition to callback_failed
  - Example host batch/callback migration fixture
affects: [worker-hooks, batches, callbacks, example-host]
tech-stack:
  added: []
  patterns: [hook pre-dispatch tracking, callback metadata detection]
key-files:
  created:
    - examples/phoenix_host/priv/repo/migrations/20260522000026_oban_powertools_batches_and_callbacks.exs
  modified:
    - lib/oban_powertools/worker/hooks.ex
    - lib/oban_powertools/batch/tracker.ex
    - test/oban_powertools/worker_test.exs
    - test/support/example_host_contract.ex
key-decisions:
  - "Record batch progress before invoking host success/discard hooks so observers see updated counters."
  - "Detect callback exhaustion through durable callback metadata rather than fuzzy worker-name matching."
patterns-established:
  - "Worker hooks treat tracker failures as non-fatal side effects and preserve existing hook dispatch semantics."
requirements-completed: [BAT-03, BAT-04]
duration: 20 min
completed: 2026-06-14
---

# Phase 60 Plan 03: Worker Hook Tracker Integration Summary

**Worker hooks now update batch progress before host hooks run, and exhausted callback jobs move their batch to `callback_failed`**

## Performance

- **Duration:** 20 min
- **Started:** 2026-06-14T16:08:00Z
- **Completed:** 2026-06-14T16:26:56Z
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments

- Wired `ObanPowertools.Worker.Hooks` to call `Tracker.record_progress/3` before `on_success` and terminal `on_discard` hook dispatch.
- Left retryable failures, cancel outcomes, and snooze outcomes out of batch progress tracking.
- Added `Tracker.record_callback_exhaustion/2` and hook integration for callback jobs carrying callback metadata.
- Added hook-level tests proving counters are visible before host hooks execute and callback exhaustion marks the batch `callback_failed`.
- Added a regression test so normal batch workers with `Callback` in the module name are not misclassified as callback jobs.
- Added the missing Phase 59 batch/callback migration fixture to `examples/phoenix_host` and restored it in the upgrade-lane host contract.

## Task Commits

1. **Task 1: Wire Tracker into Worker Hooks and handle callback exhaustion** - `80ec8a7` (feat)
2. **Review fix: Prefer callback identity for callback exhaustion** - `90db28d` (fix)

## Files Created/Modified

- `lib/oban_powertools/worker/hooks.ex` - Calls the tracker before success/discard host hooks and handles callback exhaustion.
- `lib/oban_powertools/batch/tracker.ex` - Adds `record_callback_exhaustion/2` and callback metadata lookup helpers.
- `test/oban_powertools/worker_test.exs` - Covers hook ordering, terminal discard tracking, exception tracking, cancel/snooze no-ops, callback exhaustion, and callback-name regression.
- `examples/phoenix_host/priv/repo/migrations/20260522000026_oban_powertools_batches_and_callbacks.exs` - Brings the canonical example host fixture up to the current batch/callback schema.
- `test/support/example_host_contract.ex` - Restores the new migration when preparing the upgrade host lane.

## Decisions Made

- Callback exhaustion detection uses explicit metadata keys (`callback_id` / `oban_powertools_callback_id`) rather than broad worker-name matching. This avoids skipping normal batch progress for host workers whose module names happen to include `Callback`.
- Hook tracker calls intentionally ignore tracker return values. The hook dispatcher remains non-fatal and preserves existing worker result semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated canonical example host fixture with the batch/callback migration**
- **Found during:** Full `mix test` after the initial hook implementation.
- **Issue:** `mix oban_powertools.doctor` failed in the example host doctor contract because the fixture lacked `oban_powertools_batches`, `oban_powertools_batch_jobs`, and the renamed `oban_powertools_callbacks` table.
- **Fix:** Added `20260522000026_oban_powertools_batches_and_callbacks.exs` to `examples/phoenix_host` and included it in the upgrade-lane migration restore list.
- **Files modified:** `examples/phoenix_host/priv/repo/migrations/20260522000026_oban_powertools_batches_and_callbacks.exs`, `test/support/example_host_contract.ex`.
- **Verification:** `mix test test/oban_powertools/example_host_contract_test.exs --only doctor` passed.
- **Committed in:** `80ec8a7`

**2. [Review - Warning] Made callback_id authoritative for callback exhaustion**
- **Found during:** Phase code review.
- **Issue:** `record_callback_exhaustion/2` preferred raw `batch_id` metadata over `callback_id`, so conflicting metadata could mark the wrong batch as `callback_failed`.
- **Fix:** Resolve the batch through the durable `Callback` row when callback identity metadata is present, then fall back to raw `batch_id` only when no callback id exists.
- **Files modified:** `lib/oban_powertools/batch/tracker.ex`, `test/oban_powertools/batch/tracker_test.exs`.
- **Verification:** `mix test test/oban_powertools/batch/tracker_test.exs test/oban_powertools/worker_test.exs` passed.
- **Committed in:** `90db28d`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 review warning).
**Impact on plan:** The hook integration scope stayed the same; the fixture migration was required for the existing doctor contract to remain consistent with the current installer and doctor manifest.

## Issues Encountered

- The first full `mix test` run completed in 504.0 seconds with one failure: the doctor host contract found missing batch/callback tables in `examples/phoenix_host`.
- Re-running the exact doctor lane after adding the fixture migration passed.

## Verification

- RED: `mix test test/oban_powertools/worker_test.exs test/oban_powertools/batch/tracker_test.exs` - FAILED as expected before implementation because batch counters were not updated and callback exhaustion did not mark `callback_failed`.
- GREEN: `mix test test/oban_powertools/worker_test.exs test/oban_powertools/batch/tracker_test.exs` - PASS (40 tests, 0 failures).
- Doctor fix: `mix test test/oban_powertools/example_host_contract_test.exs --only doctor` - PASS (1 test, 0 failures, 5 excluded).
- Focused final: `mix test test/oban_powertools/worker_test.exs test/oban_powertools/batch/tracker_test.exs test/oban_powertools/batch_job_test.exs` - PASS (44 tests, 0 failures).
- Review fix: `mix test test/oban_powertools/batch/tracker_test.exs test/oban_powertools/worker_test.exs` - PASS (42 tests, 0 failures).
- Phase final: `mix test` - PASS (531 tests, 0 failures, 280.2 seconds).
- `git diff --check -- lib/oban_powertools/worker/hooks.ex lib/oban_powertools/batch/tracker.ex test/oban_powertools/worker_test.exs test/support/example_host_contract.ex` - PASS.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All phase 60 plans are implemented and phase-level verification is recorded in `60-VERIFICATION.md`.

---
*Phase: 60-execution-engine-tracker-hooks*
*Completed: 2026-06-14*
