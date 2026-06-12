---
phase: 54-deadline-timeout-pass-through
plan: "01"
subsystem: worker
tags: [oban, worker, timeout, deadline, hooks]
requires:
  - phase: 53-worker-lifecycle-hooks
    provides: worker lifecycle hook dispatch and cancellation semantics
provides:
  - compile-time timeout option validation and generated Oban timeout/1 callback
  - soft pre-run deadline cancellation from meta["__deadline_at__"]
  - defensive deadline parsing helper for enqueue and perform paths
affects: [worker, idempotency, doctor, docs]
tech-stack:
  added: []
  patterns: [macro option stripping, overridable generated callback, defensive meta parsing]
key-files:
  created:
    - lib/oban_powertools/worker/deadlines.ex
  modified:
    - lib/oban_powertools/worker.ex
    - test/oban_powertools/worker_test.exs
key-decisions:
  - "timeout: is a compile-time positive integer millisecond default that generates an overridable Oban timeout/1 callback."
  - "deadline: is a soft pre-run expiry that returns {:cancel, :deadline_expired} before lifecycle hooks or process/1."
patterns-established:
  - "Powertools-only worker options are stripped before use Oban.Worker so Oban does not receive unsupported options."
  - "Deadline metadata is parsed defensively; missing or malformed values allow normal execution."
requirements-completed: [SAFE-01, SAFE-03]
duration: 3 min
completed: 2026-06-12
---

# Phase 54 Plan 01: Worker Timeout and Deadline Runtime Summary

**Oban timeout pass-through and soft deadline pre-run cancellation for Powertools workers**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-12T16:52:56Z
- **Completed:** 2026-06-12T16:55:33Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added RED worker tests for generated timeout callbacks, host timeout overrides, invalid safety options, expired deadline cancellation, and malformed deadline tolerance.
- Added `ObanPowertools.Worker.Deadlines` with the reserved meta key, duration normalization, enqueue timestamp construction, and defensive expiry parsing.
- Updated `ObanPowertools.Worker` to strip `:timeout` and `:deadline`, validate them at compile time, expose `__powertools_deadline_ms__/0`, generate overridable `timeout/1`, and cancel expired jobs before hooks or host work.

## Task Commits

1. **Task 1: Add RED worker tests for timeout and deadline wrapper behavior** - `6cd0a74` (test)
2. **Task 2: Implement worker timeout and deadline runtime support** - `5d77334` (feat)

## Files Created/Modified

- `lib/oban_powertools/worker/deadlines.ex` - Internal helper for deadline meta key, positive duration normalization, ISO8601 meta construction, and defensive expiry checks.
- `lib/oban_powertools/worker.ex` - Worker macro strips Powertools safety options, validates timeout/deadline values, generates overridable `timeout/1`, exposes deadline config, and checks deadline expiry before hook dispatch.
- `test/oban_powertools/worker_test.exs` - Regression coverage for timeout generation/override, invalid declarations, expired deadline cancellation ordering, and malformed/future deadline behavior.

## Decisions Made

- Timeout generation remains host-overridable through `defoverridable timeout: 1`.
- Expired deadlines return `{:cancel, :deadline_expired}` without invoking `on_start/1`, `process/1`, `on_success/2`, `on_failure/2`, or `on_discard/2`.
- Missing or malformed deadline metadata is treated as not expired to avoid crashing jobs inserted or edited outside Powertools.

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

Plan 54-02 can now consume `__powertools_deadline_ms__/0` and `ObanPowertools.Worker.Deadlines.build_meta/2` to add enqueue-time deadline metadata without changing idempotency fingerprints.

---
*Phase: 54-deadline-timeout-pass-through*
*Completed: 2026-06-12*
