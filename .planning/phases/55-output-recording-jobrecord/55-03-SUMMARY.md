---
phase: 55-output-recording-jobrecord
plan: 03
subsystem: ui
tags: [phoenix-liveview, display-policy, job-records, tdd]

requires:
  - phase: 55-output-recording-jobrecord
    provides: JobRecord storage, fetch_result payload lookup, and worker recording integration from plans 55-01 and 55-02
provides:
  - Dedicated :job_recorded DisplayPolicy normalization with bounded fallback behavior
  - Recorded Output card on the native JobsLive detail view
  - Full-record JobRecord lookup for UI metadata while preserving fetch_result payload semantics
affects: [jobs-live-recorded-output, lifeline-pruning, redact-at-rest]

tech-stack:
  added: []
  patterns:
    - Preserve public payload lookup while adding metadata-specific record lookup
    - DisplayPolicy structured output normalization before LiveView rendering

key-files:
  created: []
  modified:
    - lib/oban_powertools/runtime_config.ex
    - lib/oban_powertools/job_record.ex
    - lib/oban_powertools/web/jobs_live.ex
    - test/oban_powertools_test.exs
    - test/oban_powertools/web/live/jobs_live_test.exs

key-decisions:
  - "Kept JobRecord.fetch_result/1 and /2 returning payloads for compatibility; added fetch_record/1 and /2 for UI metadata."
  - "Rendered the Recorded Output card between Args/Meta and Errors with neutral missing-output copy."
  - "Treat redacted output display as stored metadata only, not proof of Phase 56 args redaction."

patterns-established:
  - "DisplayPolicy.render_job_field(:job_recorded, ...) returns a normalized display map rather than the generic args/meta tuple."
  - "JobsLive loads recorded output through DisplayPolicy before rendering payloads or metadata."

requirements-completed: [REC-04]

duration: 6min
completed: 2026-06-13
---

# Phase 55 Plan 03: JobsLive Recorded Output Summary

**JobsLive recorded-output visibility with dedicated :job_recorded display policy normalization and safe fallback rendering**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-13T01:35:00Z
- **Completed:** 2026-06-13T01:40:53Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `DisplayPolicy.render_job_field(:job_recorded, ...)` support with default metadata, string/map policy handling, neutral missing-output state, and bounded fallback copy.
- Added a Recorded Output card to JobsLive detail after Args/Meta and before Errors, showing availability, summary, status, attempt, payload bytes, recorded timestamp, retention, expiry, redaction metadata, and payload.
- Added `JobRecord.fetch_record/1` and `fetch_record/2` so the UI can render metadata while the existing `fetch_result/1` payload contract remains unchanged.
- Added LiveView tests for available output, missing output, and policy nil/string/map/raising behavior.

## Task Commits

1. **Task 1 RED: Job recorded DisplayPolicy tests** - `38f0ed9` (test)
2. **Task 1 GREEN: Job recorded DisplayPolicy support** - `063b4db` (feat)
3. **Task 2 RED: Recorded Output card tests** - `7d7a0ea` (test)
4. **Task 2 GREEN: JobsLive recorded output card** - `20ff2f3` (feat)

## Files Created/Modified

- `lib/oban_powertools/runtime_config.ex` - Added `:job_recorded` structured display normalization and policy fallback handling.
- `lib/oban_powertools/job_record.ex` - Added full-record lookup helpers while preserving existing payload-returning `fetch_result` behavior.
- `lib/oban_powertools/web/jobs_live.ex` - Loads recorded output for job detail and renders the Recorded Output card.
- `test/oban_powertools_test.exs` - Covers default and fallback `:job_recorded` DisplayPolicy behavior.
- `test/oban_powertools/web/live/jobs_live_test.exs` - Covers available/missing recorded output and policy variants in the detail view.

## Decisions Made

- Preserved the prior public `JobRecord.fetch_result/1` contract because plans 55-01 and 55-02 established payload-returning lookup behavior.
- Added `fetch_record/1` and `fetch_record/2` as a narrow metadata lookup for JobsLive instead of changing existing callers to receive schema structs.
- Used explicit "Redacted Metadata" copy to describe stored metadata without implying Phase 56 args redaction is already implemented.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added full-record lookup for UI metadata**
- **Found during:** Task 2 (Inject "Recorded Output" card in `JobsLive`)
- **Issue:** The plan says to use `JobRecord.fetch_result/1` in `load_job_detail/2`, but prior completed plans intentionally made `fetch_result/1` return only the stored payload. The Recorded Output card also needs status, attempt, byte count, retention, recorded timestamp, and expiry.
- **Fix:** Kept `fetch_result/1` and `fetch_result/2` payload-compatible, added `fetch_record/1` and `fetch_record/2`, and used both in JobsLive: `fetch_result` proves availability while `fetch_record` supplies metadata.
- **Files modified:** `lib/oban_powertools/job_record.ex`, `lib/oban_powertools/web/jobs_live.ex`
- **Verification:** `mix test test/oban_powertools/job_record_test.exs` and `mix test test/oban_powertools/web/live/jobs_live_test.exs` pass.
- **Committed in:** `20ff2f3`

---

**Total deviations:** 1 auto-fixed (1 missing critical)  
**Impact on plan:** The deviation preserves the earlier public API while satisfying the plan's UI metadata requirements. No scope expansion beyond recorded-output display.

## Issues Encountered

- The initial JobsLive policy-variant tests attempted to record output for freshly inserted jobs with attempt `0`, which the JobRecord changeset correctly rejects. The fixtures now record attempt `1` or `2`.

## Known Stubs

None.

## TDD Gate Compliance

- RED commit present: `38f0ed9`
- GREEN commit present after RED: `063b4db`
- RED commit present: `7d7a0ea`
- GREEN commit present after RED: `20ff2f3`
- Refactor commit not needed.

## Verification

- `mix test test/oban_powertools_test.exs` - PASS (3 tests, 0 failures)
- `mix test test/oban_powertools/web/live/jobs_live_test.exs` - PASS (30 tests, 0 failures)
- `mix test test/oban_powertools/job_record_test.exs` - PASS (7 tests, 0 failures)
- `rg -n "JobRecord\\.fetch_result|Recorded Output|No recorded output found for this job|job_recorded|fetch_record" lib/oban_powertools/runtime_config.ex lib/oban_powertools/job_record.ex lib/oban_powertools/web/jobs_live.ex test/oban_powertools_test.exs test/oban_powertools/web/live/jobs_live_test.exs` - PASS

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 55-04. The job detail UI can now display persisted output records, and the remaining phase work can focus on Lifeline retention pruning and support-truth docs.

## Self-Check: PASSED

- Summary file exists.
- Key modified files exist.
- Task commits `38f0ed9`, `063b4db`, `7d7a0ea`, and `20ff2f3` exist in git history.
- Plan-level verification passed with JobsLive recorded-output coverage.

---
*Phase: 55-output-recording-jobrecord*
*Completed: 2026-06-13*
