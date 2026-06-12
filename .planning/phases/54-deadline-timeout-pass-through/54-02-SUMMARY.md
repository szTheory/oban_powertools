---
phase: 54-deadline-timeout-pass-through
plan: "02"
subsystem: idempotency
tags: [oban, worker, deadline, idempotency, metadata]
requires:
  - phase: 54-deadline-timeout-pass-through
    provides: worker deadline configuration and deadline metadata helper
provides:
  - enqueue-time top-level deadline metadata for deadline-enabled workers
  - idempotency-safe Powertools metadata merge after fingerprint generation
  - reserved-key precedence over host-supplied __deadline_at__ meta
affects: [worker, idempotency, limits, doctor, docs]
tech-stack:
  added: []
  patterns: [post-fingerprint metadata merge, synthetic test option stripping, reserved meta precedence]
key-files:
  created: []
  modified:
    - lib/oban_powertools/idempotency.ex
    - lib/oban_powertools/worker/deadlines.ex
    - test/oban_powertools/idempotency_test.exs
key-decisions:
  - "Deadline metadata is computed after idempotency fingerprint generation so changing wall-clock enqueue time does not perturb duplicate detection."
  - "Powertools-owned __deadline_at__ overwrites host-supplied spoofed deadline meta while preserving unrelated caller meta."
  - "Synthetic :now opts are stripped before worker_mod.new/2 so Oban never receives test/control options."
patterns-established:
  - "Idempotency enqueue metadata is assembled through merge_powertools_meta/4 with caller meta merged first and Powertools meta second."
  - "Deadline timestamps with zero fractional seconds are normalized to the compact ISO8601 UTC form ending in Z."
requirements-completed: [SAFE-02]
duration: 3 min
completed: 2026-06-12
---

# Phase 54 Plan 02: Enqueue Deadline Metadata Summary

**Idempotency-safe enqueue metadata writes concrete deadline_at timestamps without changing duplicate detection**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-12T17:03:15Z
- **Completed:** 2026-06-12T17:07:32Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added RED idempotency tests for deadline enqueue metadata, caller-meta preservation, reserved-key precedence, duplicate conflict stability across different `now:` values, and coexistence with limiter/idempotency metadata.
- Replaced the limiter-only metadata merge with `merge_powertools_meta/4`, which computes deadline metadata after fingerprint generation and strips the synthetic `:now` option before building Oban jobs.
- Reused `ObanPowertools.Worker.Deadlines.build_meta/2` from the worker runtime path so enqueue and perform checks share the reserved key and timestamp construction.
- Normalized zero-fraction deadline timestamps to the exact compact ISO8601 UTC form used by docs and tests, such as `2026-06-13T12:00:00Z`.

## Task Commits

1. **Task 1: Add RED idempotency tests for deadline meta insertion** - `555973c` (test)
2. **Task 2: Merge deadline metadata after fingerprint generation** - `184ccf2` (feat)

## Files Created/Modified

- `test/oban_powertools/idempotency_test.exs` - Adds deadline-enabled workers and integration coverage for deadline meta, spoofed caller meta, duplicate detection, and limiter/idempotency coexistence.
- `lib/oban_powertools/idempotency.ex` - Adds `merge_powertools_meta/4`, computes deadline meta after fingerprint generation, preserves caller meta with Powertools precedence, and strips `:now` before job construction.
- `lib/oban_powertools/worker/deadlines.ex` - Normalizes zero-fraction deadline timestamps while preserving existing defensive deadline helper behavior.

## Decisions Made

- Deadline metadata remains top-level `meta["__deadline_at__"]` rather than nested under `"oban_powertools"` because runtime cancellation and Doctor diagnostics both consume the top-level reserved key.
- Duplicate detection remains based only on worker identity and validated args; deadline timestamps are persisted job metadata only.
- Host-supplied `meta["__deadline_at__"]` is treated as spoofable input and overwritten by the worker's compile-time deadline declaration.

## Deviations from Plan

### Auto-fixed Issues

**1. [Contract precision] Normalized zero-fraction ISO8601 deadline timestamps**
- **Found during:** Task 2 (Merge deadline metadata after fingerprint generation)
- **Issue:** The existing deadline helper could emit zero fractional seconds, while the SAFE-02 contract and docs tests expected compact UTC timestamps ending directly in `Z`.
- **Fix:** Added zero-fraction trimming inside `ObanPowertools.Worker.Deadlines.build_meta/2`.
- **Files modified:** `lib/oban_powertools/worker/deadlines.ex`
- **Verification:** `mix test test/oban_powertools/idempotency_test.exs --trace`
- **Committed in:** `184ccf2` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed contract-precision adjustment.
**Impact on plan:** No scope change; the adjustment keeps enqueue metadata aligned with the exact SAFE-02 timestamp contract.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All Phase 54 plans are implemented. Phase-level review and verification can now validate timeout pass-through, enqueue deadline metadata, pre-run deadline cancellation, Doctor expired-deadline warnings, and support-truth documentation as one slice.

---
*Phase: 54-deadline-timeout-pass-through*
*Completed: 2026-06-12*
