---
phase: 55-output-recording-jobrecord
plan: 01
subsystem: database
tags: [ecto, oban, job-records, jsonb, tdd]

requires:
  - phase: 53-worker-lifecycle-hooks
    provides: Worker wrapper and hook ordering used by later recording integration
provides:
  - Dedicated oban_powertools_job_records storage table and indexes
  - ObanPowertools.JobRecord schema with best-effort record/5 persistence
  - fetch_result/1 and fetch_result/2 lookup for latest recorded job output
affects: [worker-output-recording, jobs-live-recorded-output, lifeline-pruning]

tech-stack:
  added: []
  patterns:
    - Repo-explicit persistence plus configured-repo convenience lookup
    - JSON-compatible payload normalization before byte measurement
    - Best-effort recorder warnings instead of worker failure

key-files:
  created:
    - lib/oban_powertools/job_record.ex
    - test/oban_powertools/job_record_test.exs
    - test/support/migrations/6_phase_55_tables.exs
  modified:
    - lib/mix/tasks/oban_powertools.install.ex
    - test/mix/tasks/oban_powertools.install_test.exs
    - test/support/migrations/5_phase_6_tables.exs
    - test/test_helper.exs

key-decisions:
  - "JobRecord uses a dedicated table with oban_job_id as a soft reference and no FK to oban_jobs."
  - "Recording failures, oversized payloads, encoding failures, and uniqueness conflicts warn and return :ok."
  - "fetch_result/1 uses the configured :oban_powertools repo while fetch_result/2 remains available for explicit repo callers."

patterns-established:
  - "Output record payloads normalize map keys recursively and measure compact Jason-encoded byte size before insert."
  - "Retention policies persist as strings with fixed TTLs: ephemeral 6h, standard 7d, extended 30d."

requirements-completed: [REC-02, REC-03]

duration: 8min
completed: 2026-06-13
---

# Phase 55 Plan 01: JobRecord Storage Summary

**Dedicated JobRecord storage with JSON-safe payload normalization, byte limits, retention expiry, and latest-result lookup**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-13T01:10:00Z
- **Completed:** 2026-06-13T01:17:09Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `oban_powertools_job_records` to the Igniter installer and test migrations with uniqueness on `[:oban_job_id, :attempt]` plus worker/status/expires indexes.
- Added `ObanPowertools.JobRecord` with schema validation, best-effort `record/5`, payload normalization, byte cap enforcement, fixed retention TTLs, and warning-only rejection paths.
- Added `fetch_result/1` and `fetch_result/2` for latest recorded output lookup by job id or `%Oban.Job{}`.

## Task Commits

1. **Task 1 RED: Job record migration tests** - `e6b9c0a` (test)
2. **Task 1 GREEN: Job record migrations** - `b25760e` (feat)
3. **Task 2 RED: Job record API tests** - `48e5beb` (test)
4. **Task 2 GREEN: Job record API** - `453460c` (feat)
5. **Task 2 contract fix: configured lookup** - `423bf9d` (fix)

## Files Created/Modified

- `lib/oban_powertools/job_record.ex` - JobRecord schema, changeset, recorder, retention, normalization, and lookup API.
- `test/oban_powertools/job_record_test.exs` - TDD coverage for normalization, byte counts, rejection, uniqueness, retention, and lookup.
- `test/support/migrations/6_phase_55_tables.exs` - Test database migration for `oban_powertools_job_records`.
- `lib/mix/tasks/oban_powertools.install.ex` - Host installer migration generation for JobRecord storage.
- `test/mix/tasks/oban_powertools.install_test.exs` - Installer/test migration assertions for JobRecord storage.
- `test/support/migrations/5_phase_6_tables.exs` - Idempotency repair for duplicated test-support migration objects.
- `test/test_helper.exs` - Test DB bootstrap for the phase 55 table on already-migrated databases.

## Decisions Made

- Used the dedicated JobRecord table required by the phase, independent of `Workflow.Result`.
- Kept `oban_job_id` as a soft bigint reference without an `oban_jobs` FK.
- Preserved worker success by returning `:ok` for all recorder rejection and insert failure paths.
- Exposed both configured-repo `fetch_result/1` and explicit-repo `fetch_result/2` for current tests and future host call sites.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made duplicated test-support migration idempotent**
- **Found during:** Task 1 (Generate `oban_powertools_job_records` migrations)
- **Issue:** Clean `MIX_ENV=test mix ecto.migrate -r ObanPowertools.TestRepo` failed before the new migration because phase 3 already created callback-outbox lease fields and recovery session objects that phase 6 tried to add again.
- **Fix:** Changed `test/support/migrations/5_phase_6_tables.exs` to use idempotent column/table/index creation and removed the redundant recovery-session FK add that phase 3 already owns.
- **Files modified:** `test/support/migrations/5_phase_6_tables.exs`
- **Verification:** Clean drop/create/migrate reached and ran `Phase55Tables.up/0`.
- **Committed in:** `b25760e`

**2. [Rule 2 - Missing Critical] Added configured-repo `fetch_result/1`**
- **Found during:** Task 2 close-out
- **Issue:** The implementation initially exposed only repo-explicit `fetch_result/2`, while REC-03 and phase success criteria require `fetch_result/1`.
- **Fix:** Added `fetch_result/1` wrappers for integer job ids and `%Oban.Job{}` using `Application.fetch_env!(:oban_powertools, :repo)`.
- **Files modified:** `lib/oban_powertools/job_record.ex`, `test/oban_powertools/job_record_test.exs`
- **Verification:** `mix test test/oban_powertools/job_record_test.exs` passes with configured-repo lookup coverage.
- **Committed in:** `423bf9d`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 missing critical)  
**Impact on plan:** Both fixes were required to satisfy the plan's migration and public lookup contracts. No scope expansion beyond storage/API foundation.

## Issues Encountered

- The raw `mix ecto.migrate -r ObanPowertools.TestRepo` command is not valid outside `MIX_ENV=test` because `TestRepo` is configured only in test. Verification used `MIX_ENV=test mix ecto.migrate -r ObanPowertools.TestRepo`.

## Known Stubs

- `lib/mix/tasks/oban_powertools.install.ex` retains pre-existing generated host TODO comments for auth/display-policy modules. These are intentional installer scaffolding placeholders and do not affect JobRecord storage or APIs.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: database-storage | `lib/oban_powertools/job_record.ex` | New durable storage surface for worker output payloads crossing from worker execution into host Postgres storage. Mitigated by JSON normalization, byte caps, warning-only rejection, and no hard FK to `oban_jobs`. |

## Verification

- `mix test test/mix/tasks/oban_powertools.install_test.exs` - PASS (6 tests, 0 failures)
- `MIX_ENV=test mix ecto.drop -r ObanPowertools.TestRepo && MIX_ENV=test mix ecto.create -r ObanPowertools.TestRepo && MIX_ENV=test mix ecto.migrate -r ObanPowertools.TestRepo` - PASS; `Phase55Tables.up/0` created `oban_powertools_job_records`.
- `mix test test/oban_powertools/job_record_test.exs` - PASS (7 tests, 0 failures)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 55-02. The storage layer and lookup API exist for worker-wrapper recording injection.

## Self-Check: PASSED

- Summary file exists.
- Key created files exist.
- Task commits `e6b9c0a`, `b25760e`, `48e5beb`, `453460c`, and `423bf9d` exist in git history.

---
*Phase: 55-output-recording-jobrecord*
*Completed: 2026-06-13*
