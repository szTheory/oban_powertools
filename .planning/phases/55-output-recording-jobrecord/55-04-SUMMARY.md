---
phase: 55-output-recording-jobrecord
plan: 04
subsystem: retention
tags: [ecto, lifeline, job-records, pruning, docs, tdd]

requires:
  - phase: 55-output-recording-jobrecord
    provides: JobRecord schema, worker recording, and JobsLive visibility from plans 55-01 through 55-03
provides:
  - Lifeline archive-prune deletion for expired JobRecord rows
  - ArchiveRun and archive_prune_completed pruned_count accounting for deleted JobRecords
  - Worker and Lifeline guide support-truth for output recording boundaries
affects: [output-recording, lifeline-pruning, phase-56-redact]

tech-stack:
  added: []
  patterns:
    - Bounded Ecto delete through ordered ID subquery inside existing prune transaction
    - JobRecord documentation as operational evidence, not durable business storage

key-files:
  created: []
  modified:
    - lib/oban_powertools/lifeline.ex
    - test/oban_powertools/lifeline_test.exs
    - guides/workers-and-idempotency.md
    - guides/lifeline-and-repairs.md

key-decisions:
  - "Expired JobRecords are pruned directly by expires_at inside Lifeline without joining oban_jobs."
  - "Deleted JobRecords contribute to pruned_count, not archived_count."
  - "Output recording docs frame JobRecord as best-effort operational context, not business storage or transaction truth."

patterns-established:
  - "Lifeline retention pruning can add operational tables by deleting bounded ID subqueries in the existing archive transaction."
  - "Large output should be stored in host-owned storage with JobRecord carrying only a small JSON reference."

requirements-completed: [REC-05]

duration: 4min
completed: 2026-06-13
---

# Phase 55 Plan 04: Lifeline JobRecord Pruning Summary

**Lifeline retention pruning now sweeps expired JobRecords with bounded accounting and support-truth documentation for recorded output**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-13T01:44:06Z
- **Completed:** 2026-06-13T01:48:16Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added Lifeline pruning for expired `ObanPowertools.JobRecord` rows using `expires_at <= now`, ordered by `expires_at, id`, and limited by the existing `batch_size`.
- Added deleted JobRecords to `ArchiveRun.pruned_count` and `:archive_prune_completed` telemetry `pruned_count`, while leaving `archived_count` unchanged.
- Documented `record_output`, `output_limit`, `output_retention`, the large-output reference pattern, and the operational-evidence boundary.

## Task Commits

1. **Task 1 RED: JobRecord prune coverage** - `4009cc1` (test)
2. **Task 1 GREEN: Lifeline JobRecord pruning** - `eb6bcbf` (feat)
3. **Task 2: Output recording support-truth docs** - `8f94590` (docs)

## Files Created/Modified

- `lib/oban_powertools/lifeline.ex` - Deletes expired JobRecords in the existing archive-prune transaction and adds the deleted count to prune accounting.
- `test/oban_powertools/lifeline_test.exs` - Covers expired JobRecord deletion, batch-size limiting, preserved non-expired records, ArchiveRun accounting, and telemetry counts.
- `guides/workers-and-idempotency.md` - Documents `record_output`, `output_limit`, `output_retention`, best-effort recording behavior, and large-output references.
- `guides/lifeline-and-repairs.md` - Documents JobRecord pruning scope, accounting, and the operational-context boundary.

## Decisions Made

- Used a bounded ID subquery for JobRecord deletion so pruning respects `batch_size` while keeping one `delete_all` operation.
- Kept JobRecord pruning independent of `oban_jobs`, matching the no-FK/no-join retention decision from the phase context.
- Counted deleted JobRecords as pruned operational rows, not archived evidence.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None - no new trust boundary was introduced. The existing pruning surface was extended to the already-indexed `oban_powertools_job_records.expires_at` field.

## TDD Gate Compliance

- RED commit present: `4009cc1`
- GREEN commit present after RED: `eb6bcbf`
- Refactor commit not needed.

## Verification

- `mix test test/oban_powertools/lifeline_test.exs` - PASS (24 tests, 0 failures)
- `mix test test/oban_powertools/docs_contract_test.exs` - PASS (17 tests, 0 failures)
- `grep -q "record_output" guides/workers-and-idempotency.md` - PASS
- `rg -n "from\\(record in ObanPowertools\\.JobRecord" lib/oban_powertools/lifeline.ex` - PASS
- Stub scan over modified source/docs found no goal-blocking stubs. Matches in `lifeline.ex` were ordinary comparisons such as `jobs == []` and `trimmed == ""`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 55 is complete. Phase 56 can build at-rest redaction on top of the worker recording and JobRecord display pipeline with retention cleanup already in place.

## Self-Check: PASSED

- Summary file exists.
- Key modified files exist.
- Task commits `4009cc1`, `eb6bcbf`, and `8f94590` exist in git history.
- Plan-level verification passed with Lifeline and docs-contract tests.

---
*Phase: 55-output-recording-jobrecord*
*Completed: 2026-06-13*
