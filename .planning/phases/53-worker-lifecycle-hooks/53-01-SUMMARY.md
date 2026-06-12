---
phase: 53-worker-lifecycle-hooks
plan: 01
subsystem: worker-runtime
tags: [worker, hooks, telemetry, oban]

requires:
  - phase: 50-telemetry-metrics-slo-guide
    provides: public low-cardinality telemetry contract and metrics helper pattern
provides:
  - Crash-safe worker-local lifecycle hooks for ObanPowertools.Worker
  - Internal hook dispatcher with success, failure, discard, and exception routing
  - worker_hook telemetry family, helper, and metric counter
affects: [worker-lifecycle, telemetry, deadline-timeout, output-recording, redaction]

tech-stack:
  added: []
  patterns: [generated worker wrapper dispatch, compile-time hook override tracking, bounded telemetry helper]

key-files:
  created:
    - lib/oban_powertools/worker/hooks.ex
  modified:
    - lib/oban_powertools/telemetry.ex
    - lib/oban_powertools/worker.ex
    - test/oban_powertools/telemetry_test.exs
    - test/oban_powertools/worker_test.exs

key-decisions:
  - "Hook dispatch is generated-wrapper-owned rather than Oban telemetry-handler-owned."
  - "Omitted no-op hook defaults do not emit worker_hook telemetry."
  - "Hook crashes are warning-logged, converted to outcome crash_caught, and never change the job outcome."

patterns-established:
  - "Worker hooks run after args validation and before or after process/1 according to result classification."
  - "Public worker_hook telemetry exposes only hook and outcome labels."
  - "Final-attempt failures route to on_discard/2 only."

requirements-completed: [HOOK-01, HOOK-02, HOOK-03, HOOK-04, HOOK-05]

duration: 14 min
completed: 2026-06-12
---

# Phase 53 Plan 01: Runtime Worker Lifecycle Hooks Summary

**Crash-safe optional worker hooks with wrapper-owned routing, final-attempt discard classification, and bounded worker_hook telemetry**

## Performance

- **Duration:** 14 min
- **Started:** 2026-06-12T14:18:30Z
- **Completed:** 2026-06-12T14:32:23Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `on_start/1`, `on_success/2`, `on_failure/2`, and `on_discard/2` defaults to generated workers with compile-time override tracking.
- Created `ObanPowertools.Worker.Hooks` to classify process results and caught process failures, build narrow event envelopes, swallow hook crashes, and emit telemetry for actual hook dispatch attempts.
- Extended `ObanPowertools.Telemetry` with the `worker_hook` family, `execute_worker_hook_event/3`, and `oban_powertools.worker_hook.invoked.count`.
- Added RED/GREEN test coverage for telemetry contract, direct dispatcher routing, generated wrapper routing, no-op defaults, hook crash safety, cancel/snooze non-dispatch, and final-attempt non-double-fire behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Worker hook telemetry tests** - `b091a10` (test)
2. **Task 1 GREEN: Telemetry contract/helper/metric** - `5ef3cb1` (feat)
3. **Task 2 RED: Dispatcher tests** - `ecfe043` (test)
4. **Task 2 GREEN: Crash-safe dispatcher** - `d666e7e` (feat)
5. **Task 3 RED: Generated worker routing tests** - `da7a7ab` (test)
6. **Task 3 GREEN: Generated worker hook integration** - `3eac467` (feat)

## Files Created/Modified

- `lib/oban_powertools/worker/hooks.ex` - Internal dispatcher for safe hook invocation, envelope construction, result/exception classification, and worker_hook telemetry emission.
- `lib/oban_powertools/worker.ex` - Generated callbacks, no-op defaults, `defoverridable`, override tracking, and perform wrapper hook dispatch.
- `lib/oban_powertools/telemetry.ex` - `worker_hook` contract family, metric counter, and `execute_worker_hook_event/3`.
- `test/oban_powertools/worker_test.exs` - Dispatcher and generated worker lifecycle routing coverage.
- `test/oban_powertools/telemetry_test.exs` - Telemetry contract, metric, and helper emission coverage.

## Decisions Made

- Used `@on_definition` plus `@before_compile` to distinguish user-overridden hooks from generated no-op defaults.
- Preserved original process exceptions, throws, and exits after dispatching the appropriate failure/discard hook.
- Kept telemetry metadata to exactly `hook` and `outcome`; rich reason/stacktrace data stays inside hook envelopes only.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/oban_powertools/telemetry_test.exs --trace` - 11 tests, 0 failures.
- `mix test test/oban_powertools/worker_test.exs test/oban_powertools/telemetry_test.exs --trace` - 31 tests, 0 failures.
- `mix test` - 443 tests, 0 failures.
- Source gates passed:
  - `worker_hook: [:hook, :outcome]` in `lib/oban_powertools/telemetry.ex`
  - `__powertools_hook_overridden?` in `lib/oban_powertools/worker.ex`
  - `defmodule ObanPowertools.Worker.Hooks` in `lib/oban_powertools/worker/hooks.ex`

## Self-Check: PASSED

- Key created file exists: `lib/oban_powertools/worker/hooks.ex`.
- Phase commit trace exists for `53-01`.
- Automated target and full-suite verification passed.
- No `## Self-Check: FAILED` conditions found.

## Next Phase Readiness

Plan 53-02 can document the runtime hook support truth and telemetry contract. Later v1.7 phases can reuse the generated perform wrapper seam for deadline/timeout, output recording, and redaction without changing hook dispatch ownership.

---
*Phase: 53-worker-lifecycle-hooks*
*Completed: 2026-06-12*
