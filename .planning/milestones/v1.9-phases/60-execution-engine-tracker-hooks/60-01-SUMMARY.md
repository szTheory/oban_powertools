---
phase: 60-execution-engine-tracker-hooks
plan: 01
subsystem: database
tags: [ecto, batches, migrations]
requires:
  - phase: 59-schemas-foundation
    provides: Dedicated batch and batch job tables
provides:
  - Batch completed_at schema field
  - Installer and test support migration completed_at column
affects: [batches, tracker, callbacks]
tech-stack:
  added: []
  patterns: [Ecto schema field with nullable completion timestamp]
key-files:
  created: []
  modified:
    - lib/oban_powertools/batch.ex
    - lib/mix/tasks/oban_powertools.install.ex
    - test/support/migrations/7_phase_59_tables.exs
key-decisions:
  - "Keep completed_at nullable and out of validate_required so executing batches can be incomplete."
patterns-established:
  - "Batch completion timestamp is the DB guard used by tracker callback enqueueing."
requirements-completed: [BAT-03, BAT-04]
duration: 15 min
completed: 2026-06-14
---

# Phase 60 Plan 01: Batch Completion Timestamp Summary

**Nullable batch completion timestamp added to the schema and generated migrations for exactly-once completion guarding**

## Performance

- **Duration:** 15 min
- **Started:** 2026-06-14T15:44:00Z
- **Completed:** 2026-06-14T15:58:53Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `completed_at` to `ObanPowertools.Batch` as a nullable `:utc_datetime_usec` field.
- Added `:completed_at` to the batch changeset cast list without making it required.
- Added the `completed_at` column to both the Igniter installer migration template and the test support migration.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add completed_at field to Batch schema** - `871bf3a` (feat)
2. **Task 2: Update migrations for completed_at** - `3ca99b8` (feat)

## Files Created/Modified

- `lib/oban_powertools/batch.ex` - Adds the nullable completion timestamp to the Batch schema and changeset cast list.
- `lib/mix/tasks/oban_powertools.install.ex` - Adds the column to generated host migrations.
- `test/support/migrations/7_phase_59_tables.exs` - Adds the column to the test support schema.

## Decisions Made

- Kept `completed_at` nullable and excluded from `validate_required`, matching the plan and allowing executing batches to remain incomplete until the tracker closes them.

## Deviations from Plan

### Auto-fixed Issues

None.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No implementation scope changes.

## Issues Encountered

- `mix ecto.setup` is not available in this project (`The task "ecto.setup" could not be found`). Verified available Ecto tasks with `mix help --search ecto`, ran `mix ecto.migrate` instead, and used targeted schema/installer tests. `mix ecto.migrate` exited 0 with the existing no-repo warning from non-test config.
- A full `mix test` run was started but did not complete after several minutes and idle DB connections; it was stopped with SIGTERM. Targeted checks completed successfully.

## Verification

- `rg -n "field\\(:completed_at, :utc_datetime_usec\\)|:completed_at|add :completed_at, :utc_datetime_usec" lib/oban_powertools/batch.ex lib/mix/tasks/oban_powertools.install.ex test/support/migrations/7_phase_59_tables.exs` - PASS
- `mix test test/oban_powertools/batch_test.exs test/mix/tasks/oban_powertools.install_test.exs` - PASS (8 tests, 0 failures)
- `mix ecto.migrate` - PASS (exit 0; no repos configured in non-test config warning)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`completed_at` is available for the tracker to use as the race-condition guard in `60-02`.

---
*Phase: 60-execution-engine-tracker-hooks*
*Completed: 2026-06-14*
