---
phase: 54-deadline-timeout-pass-through
plan: "03"
subsystem: doctor
tags: [doctor, oban, deadline, diagnostics, postgres]
requires:
  - phase: 54-deadline-timeout-pass-through
    provides: deadline metadata key and support truth
provides:
  - prefix-safe Doctor check for expired retryable deadline jobs
  - warning severity integration in Doctor.run/2
  - formatter coverage for expired_deadline_jobs under schema_version 1
affects: [doctor, cli, docs, operations]
tech-stack:
  added: []
  patterns: [prefix-safe SQL, defensive ISO8601 parsing, warning-only diagnostic]
key-files:
  created: []
  modified:
    - lib/oban_powertools/doctor.ex
    - lib/oban_powertools/doctor/checks.ex
    - test/oban_powertools/doctor/checks_test.exs
    - test/oban_powertools/doctor/formatter_test.exs
    - test/oban_powertools/doctor_test.exs
key-decisions:
  - "Expired retryable deadline jobs are Doctor warnings, including under strict mode."
  - "Malformed deadline metadata is ignored by the expired deadline check rather than crashing Doctor."
patterns-established:
  - "Doctor checks validate schema prefixes before identifier interpolation and bind all data values as query parameters."
  - "Doctor warning findings reuse the existing formatter shape without changing JSON schema_version."
requirements-completed: [SAFE-04]
duration: 2 min
completed: 2026-06-12
---

# Phase 54 Plan 03: Doctor Expired Deadline Diagnostics Summary

**Prefix-safe Doctor warning for retryable jobs whose Powertools deadline has already expired**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-12T16:57:55Z
- **Completed:** 2026-06-12T16:59:12Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added RED tests for expired, future, malformed, non-retryable, and invalid-prefix deadline diagnostic behavior.
- Implemented `Checks.expired_deadline_jobs/2` with prefix validation, read-only SQL, parameterized deadline key/state values, and defensive `DateTime.from_iso8601/1` parsing.
- Composed the check into `Doctor.run/2` without passing `strict:`, keeping expired deadline findings at warning severity.
- Locked human and JSON formatter behavior for `expired_deadline_jobs` while preserving `schema_version: 1`.

## Task Commits

1. **Task 1: Add RED Doctor tests for expired deadline findings** - `892e3b9` (test)
2. **Task 2: Implement prefix-safe expired deadline Doctor check** - `0ea139e` (feat)

## Files Created/Modified

- `lib/oban_powertools/doctor/checks.ex` - Adds `expired_deadline_jobs/2`, invalid-prefix error findings, read-only retryable job query, and defensive deadline parsing.
- `lib/oban_powertools/doctor.ex` - Composes expired deadline findings into the Doctor run pipeline.
- `test/oban_powertools/doctor/checks_test.exs` - Covers expired/future/non-retryable/malformed deadline metadata and prefix safety.
- `test/oban_powertools/doctor/formatter_test.exs` - Covers human and JSON rendering for the new warning shape.
- `test/oban_powertools/doctor_test.exs` - Covers `Doctor.run/2` strict-mode composition without severity promotion.

## Decisions Made

- `expired_deadline_jobs` queries only retryable jobs because available/scheduled jobs have not yet failed and should not be surfaced as retryable stale work.
- Invalid prefixes become bounded error findings before SQL interpolation.
- Malformed deadline metadata is ignored to avoid making Doctor noisy or crash-prone when hosts insert or edit meta outside Powertools.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 54-04 can document the new `expired_deadline_jobs` warning and lock the `--strict` support truth without changing runtime behavior.

---
*Phase: 54-deadline-timeout-pass-through*
*Completed: 2026-06-12*
