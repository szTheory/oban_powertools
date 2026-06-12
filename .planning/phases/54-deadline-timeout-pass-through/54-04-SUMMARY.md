---
phase: 54-deadline-timeout-pass-through
plan: "04"
subsystem: docs
tags: [docs, worker, timeout, deadline, doctor]
requires:
  - phase: 53-worker-lifecycle-hooks
    provides: worker hook support truth and timeout-hook boundary
  - phase: 54-deadline-timeout-pass-through
    provides: timeout/deadline runtime behavior and Doctor warning check
provides:
  - worker guide timeout/deadline support-truth documentation
  - Doctor CLI expired_deadline_jobs warning documentation
  - docs-contract assertions preventing hard-deadline, hook, telemetry, and strict-mode overclaims
affects: [worker-guide, doctor-cli, docs-contract]
tech-stack:
  added: []
  patterns: [support-truth docs, source-contract tests]
key-files:
  created: []
  modified:
    - guides/workers-and-idempotency.md
    - lib/mix/tasks/oban_powertools.doctor.ex
    - test/oban_powertools/docs_contract_test.exs
    - test/mix/tasks/oban_powertools.doctor_test.exs
key-decisions:
  - "timeout: is documented as Oban's per-attempt timeout/1 kill timer, not a Powertools hook-driven behavior."
  - "deadline: is documented as soft pre-run cancellation that does not interrupt already-running work."
  - "expired_deadline_jobs remains warning severity under both default Doctor mode and --strict."
patterns-established:
  - "Builder-facing safety docs include explicit negative support truth to prevent overclaims."
  - "Doctor CLI moduledoc is treated as source-contract text and tested directly."
requirements-completed: [SAFE-01, SAFE-02, SAFE-03, SAFE-04]
duration: 2 min
completed: 2026-06-12
---

# Phase 54 Plan 04: Timeout, Deadline, and Doctor Docs Summary

**Support-truth documentation for worker timeout/deadline semantics and Doctor expired-deadline warnings**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-12T17:01:32Z
- **Completed:** 2026-06-12T17:02:42Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added worker guide documentation for `timeout:` and `deadline:` declarations, including positive integer millisecond units, Oban timeout ownership, soft pre-run deadline semantics, lifecycle hook boundaries, and no Powertools-specific deadline telemetry in this phase.
- Added docs-contract assertions that lock the timeout/deadline support truth and reject overclaims about hard deadlines, interrupting running work, or deadline telemetry.
- Updated the Doctor CLI moduledoc to list expired deadline jobs as warning findings under both default mode and `--strict`.
- Added source-contract assertions that keep `--strict` scoped to `uniqueness_timeout_risk check only`.

## Task Commits

1. **Task 1: Lock worker timeout and deadline support truth in docs** - `9af43b5` (docs)
2. **Task 2: Lock Doctor expired-deadline severity and strict scope** - `ad7c779` (docs)

## Files Created/Modified

- `guides/workers-and-idempotency.md` - Adds timeout/deadline worker example and support-truth bullets.
- `lib/mix/tasks/oban_powertools.doctor.ex` - Adds expired deadline jobs to exit-code and severity documentation.
- `test/oban_powertools/docs_contract_test.exs` - Locks worker timeout/deadline support-truth strings and overclaim refutations.
- `test/mix/tasks/oban_powertools.doctor_test.exs` - Locks expired_deadline_jobs warning severity and strict-mode scope in the CLI source.

## Decisions Made

- Documented deadlines as stale-work prevention only, not running-work interruption.
- Kept timeout observability delegated to Oban job exception telemetry rather than Powertools hooks.
- Kept `--strict` semantics unchanged for expired deadline jobs.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## User Setup Required

None - documentation and source-contract tests require no external configuration.

## Next Phase Readiness

Wave 1 is complete. Plan 54-02 can now add enqueue-time deadline metadata with the public support truth already documented and locked.

---
*Phase: 54-deadline-timeout-pass-through*
*Completed: 2026-06-12*
