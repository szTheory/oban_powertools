---
phase: 61-apis-batches-chains
plan: "01"
subsystem: database
tags: [ecto, oban, batches, installer, tdd]

requires:
  - phase: 60-execution-engine-tracker-hooks
    provides: batch progress tracking and callback enqueueing over the batch table
provides:
  - Durable batch insertion metadata fields for future Batch.insert_stream/2 partial failure reporting
  - Test migration and boot fallback for Phase 61 batch metadata columns
  - Host installer migration contract for new batch metadata columns and indexes
affects: [phase-61, phase-62, batches, installer]

tech-stack:
  added: []
  patterns:
    - Ecto schema fields mirror test and installer migration definitions
    - TDD RED/GREEN task commits for batch storage contracts

key-files:
  created:
    - test/support/migrations/8_phase_61_batch_failure_fields.exs
  modified:
    - lib/oban_powertools/batch.ex
    - lib/mix/tasks/oban_powertools.install.ex
    - test/test_helper.exs
    - test/oban_powertools/batch_test.exs
    - test/mix/tasks/oban_powertools.install_test.exs

key-decisions:
  - "Phase 61 batch insertion metadata is additive to the Phase 59 batch table because the batch table has not shipped publicly yet."
  - "The installer template and test migration use the same metadata columns and status/name indexes to keep host installs aligned with test storage."

patterns-established:
  - "Batch insertion failure metadata: name, inserted_count, insert_chunk_count, insert_failed_chunk, insert_failure, and insert_failed_at are persisted on oban_powertools_batches."
  - "Existing test databases are upgraded through an idempotent information_schema fallback before Phase 61 tests run."

requirements-completed: [BAT-02]

duration: 3 min
completed: 2026-06-14
---

# Phase 61 Plan 01: Durable Batch Insertion Metadata Summary

**Durable batch insertion metadata and installer migration contract for future `Batch.insert_stream/2` failure reporting**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-14T19:23:16Z
- **Completed:** 2026-06-14T19:26:14Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `name`, insertion counters, failure payload, and failed-at timestamp fields to `ObanPowertools.Batch`.
- Added Phase 61 test migration plus test boot fallback so existing local test databases receive the new batch columns.
- Updated the host installer batch migration template with the same columns and `status`/`name` indexes.
- Added TDD coverage for schema casting, numeric validation, database columns, and installer source contract.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing test for batch insertion metadata** - `4ee6205` (test)
2. **Task 1 GREEN: Add durable batch insertion metadata** - `e676440` (feat)
3. **Task 2 RED: Add failing test for installer batch metadata** - `6349453` (test)
4. **Task 2 GREEN: Update installer batch metadata contract** - `d173cf0` (feat)

**Plan summary metadata:** `17584fa` (docs)

## Files Created/Modified

- `lib/oban_powertools/batch.ex` - Adds durable batch insertion metadata fields, casting, required fields, and counter validation.
- `test/support/migrations/8_phase_61_batch_failure_fields.exs` - Adds Phase 61 batch metadata columns and status/name indexes for tests.
- `test/test_helper.exs` - Requires the Phase 61 migration and applies an idempotent fallback when existing test DBs lack `inserted_count`.
- `test/oban_powertools/batch_test.exs` - Covers metadata casting, validation, and test database columns.
- `lib/mix/tasks/oban_powertools.install.ex` - Adds the new metadata columns and indexes to generated host migrations.
- `test/mix/tasks/oban_powertools.install_test.exs` - Asserts the installer emits the durable metadata contract.

## Decisions Made

- Kept this plan additive: no separate public upgrade migration was added because Phase 59 batch tables have not shipped in a public release.
- Used `information_schema.columns` for the test boot fallback to avoid relying only on migration history in already-booted local test databases.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## Known Stubs

None introduced by this plan. Existing installer-template TODO comments remain intentional host-owned setup guidance and were not added or expanded here.

## User Setup Required

None - no external service configuration required.

## Verification

- RED Task 1: `mix test test/oban_powertools/batch_test.exs` failed with 3 expected failures before schema/migration changes.
- GREEN Task 1: `mix test test/oban_powertools/batch_test.exs` passed with 5 tests, 0 failures.
- RED Task 2: `mix test test/mix/tasks/oban_powertools.install_test.exs` failed with 1 expected failure before installer changes.
- GREEN Task 2: `mix test test/mix/tasks/oban_powertools.install_test.exs` passed with 7 tests, 0 failures.
- Plan verification: `mix test test/oban_powertools/batch_test.exs test/mix/tasks/oban_powertools.install_test.exs` passed with 12 tests, 0 failures.

## Next Phase Readiness

Ready for 61-02 to implement `Batch.insert_stream/2` on top of the durable insertion metadata fields.

## Self-Check: PASSED

- Created file exists: `test/support/migrations/8_phase_61_batch_failure_fields.exs`.
- Task commits exist: `4ee6205`, `e676440`, `6349453`, `d173cf0`.
- Acceptance source assertions passed for batch schema fields, Phase 61 migration module/table alteration, installer insert metadata, and installer test assertions.
- Plan-level verification passed.

---
*Phase: 61-apis-batches-chains*
*Completed: 2026-06-14*
