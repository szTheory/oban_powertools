---
phase: 60-execution-engine-tracker-hooks
plan: 02
subsystem: database
tags: [ecto, batches, callbacks, tdd]
requires:
  - phase: 60-execution-engine-tracker-hooks
    provides: Batch completed_at completion guard
provides:
  - Exactly-once batch job progress tracking
  - Completed and exhausted callback enqueueing
  - Fresh test bootstrap for Phase 59 batch tables
affects: [batches, worker-hooks, callbacks]
tech-stack:
  added: []
  patterns: [insert_all idempotency, update_all counter increments, guarded callback transaction]
key-files:
  created:
    - lib/oban_powertools/batch/tracker.ex
    - test/oban_powertools/batch/tracker_test.exs
  modified:
    - lib/oban_powertools/batch_job.ex
    - lib/mix/tasks/oban_powertools.install.ex
    - test/support/migrations/7_phase_59_tables.exs
    - test/oban_powertools/batch_job_test.exs
    - test/test_helper.exs
key-decisions:
  - "Use BatchJob insert_all with on_conflict: :nothing as the idempotency guard before incrementing counters."
  - "Use completed_at IS NULL inside an Ecto.Multi transaction as the single callback enqueue guard."
patterns-established:
  - "Batch tracker returns :ignored for non-batch jobs, :duplicate for already-recorded jobs, :tracked for incomplete batches, and :completed when callback enqueue wins."
requirements-completed: [BAT-03, BAT-04]
duration: 8 min
completed: 2026-06-14
---

# Phase 60 Plan 02: Exactly-Once Batch Tracker Summary

**Batch tracker records each job once, atomically increments progress counters, and enqueues completed/exhausted callbacks behind a completion timestamp guard**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-14T16:00:00Z
- **Completed:** 2026-06-14T16:07:49Z
- **Tasks:** 1
- **Files modified:** 7

## Accomplishments

- Added `ObanPowertools.Batch.Tracker.record_progress/3`.
- Added RED/GREEN tests covering ignored jobs, duplicate job records, success/discard increments, and completed/exhausted callback outbox rows.
- Repaired `BatchJob` timestamp declarations and test DB bootstrap so fresh test schemas include Phase 59 batch tables.

## Task Commits

TDD task commits:

1. **RED: Tracker behavior tests** - `337f762` (test)
2. **GREEN: Tracker implementation** - `88dfe3a` (feat)

## Files Created/Modified

- `lib/oban_powertools/batch/tracker.ex` - Implements idempotent progress tracking, counter increments, and callback enqueueing.
- `test/oban_powertools/batch/tracker_test.exs` - Covers tracker behavior and callback outcomes.
- `lib/oban_powertools/batch_job.ex` - Uses standard `inserted_at` / `updated_at` timestamps.
- `lib/mix/tasks/oban_powertools.install.ex` - Corrects generated batch job timestamps.
- `test/support/migrations/7_phase_59_tables.exs` - Corrects test support batch job timestamps.
- `test/oban_powertools/batch_job_test.exs` - Locks the timestamp field regression.
- `test/test_helper.exs` - Requires and conditionally applies Phase 59 support migration for fresh test databases.

## Decisions Made

- Kept callback payload minimal: `batch_id` and `event`, with the canonical `dedupe_key` of `"#{event}-#{batch_id}"`.
- Returned `{:ok, :tracked}` when a batch was incremented but not completed, and `{:ok, :completed}` when the guarded completion transaction enqueued the callback.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected BatchJob timestamp field declaration**
- **Found during:** GREEN verification for Task 1.
- **Issue:** `timestamps(updated_at: true)` created an Ecto field and database column named `true`, so `insert_all` rejected `updated_at` and fresh schemas had the wrong timestamp column.
- **Fix:** Changed `BatchJob`, installer migration template, and test support migration to use `timestamps()`. Added a regression test asserting `:updated_at` exists and `true` does not.
- **Files modified:** `lib/oban_powertools/batch_job.ex`, `lib/mix/tasks/oban_powertools.install.ex`, `test/support/migrations/7_phase_59_tables.exs`, `test/oban_powertools/batch_job_test.exs`.
- **Verification:** `mix test test/oban_powertools/batch/tracker_test.exs test/oban_powertools/batch_job_test.exs` passed.
- **Committed in:** `88dfe3a`

**2. [Rule 3 - Blocking] Added Phase 59 migration bootstrap to test_helper**
- **Found during:** Fresh test DB verification.
- **Issue:** `test/test_helper.exs` required migrations only through Phase 55, so a clean test database did not create `oban_powertools_batches` or `oban_powertools_batch_jobs`.
- **Fix:** Required `7_phase_59_tables.exs` and applied it when the batch table is absent.
- **Files modified:** `test/test_helper.exs`.
- **Verification:** Focused tracker tests passed after recreating the test database.
- **Committed in:** `88dfe3a`

---

**Total deviations:** 2 auto-fixed (2 blocking).
**Impact on plan:** Both fixes were necessary for the planned tracker to run against the intended Phase 59 schema. No new runtime dependency or public API scope was added.

## Issues Encountered

- Recreated the test database with `MIX_ENV=test mix ecto.drop --quiet` and `MIX_ENV=test mix ecto.create --quiet` to verify fresh support migration behavior.

## Verification

- RED: `mix test test/oban_powertools/batch/tracker_test.exs` - FAILED as expected before implementation because `Tracker.record_progress/3` was undefined.
- GREEN: `mix test test/oban_powertools/batch/tracker_test.exs test/oban_powertools/batch_job_test.exs` - PASS (8 tests, 0 failures).
- Plan command: `mix test test/oban_powertools/batch/tracker_test.exs` - PASS (5 tests, 0 failures).
- `rg -n "def record_progress|insert_all|on_conflict: :nothing|completed_at|batch\\.completed|batch\\.exhausted" lib/oban_powertools/batch/tracker.ex` - PASS.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`Tracker.record_progress/3` is ready for Worker Hook integration in `60-03`.

---
*Phase: 60-execution-engine-tracker-hooks*
*Completed: 2026-06-14*
