---
phase: 61-apis-batches-chains
plan: "04"
subsystem: api
tags: [elixir, oban, ecto, chains, callbacks, tdd]

requires:
  - phase: 61-apis-batches-chains
    provides: "61-03 chain DSL and durable chain_next_step descriptors"
provides:
  - Event-scoped callback vocabulary including `chain.step_succeeded`
  - Host workflow callback claim filtering for workflow and batch events only
  - Tracker bridge from successful chain step metadata to durable chain callback rows
  - `ObanPowertools.Chain.Progression.dispatch_callbacks/2` for retryable next-step enqueueing
affects: [phase-61, phase-62, chains, callbacks, batch-operator-ui]

tech-stack:
  added: []
  patterns:
    - Event-scoped callback claim queries with `FOR UPDATE SKIP LOCKED`
    - Chain progression through callback outbox rows rather than worker lifecycle callbacks
    - Durable tail rewriting from `%{"step" => next, "remaining" => tail}`

key-files:
  created:
    - lib/oban_powertools/chain/progression.ex
    - test/oban_powertools/chain_progression_test.exs
    - .planning/phases/61-apis-batches-chains/61-04-SUMMARY.md
  modified:
    - lib/oban_powertools/callback.ex
    - lib/oban_powertools/workflow/runtime.ex
    - lib/oban_powertools/batch/tracker.ex
    - test/oban_powertools/workflow_callbacks_test.exs

key-decisions:
  - "Host callback dispatch claims only workflow and batch events; chain events are reserved for Powertools-owned progression."
  - "Chain progression callbacks are emitted only for first-time successful chain step progress and are deduped by chain id, step index, and upstream job id."
  - "The chain dispatcher rewrites `chain_next_step` from the remaining tail instead of copying upstream payloads into callback rows."

patterns-established:
  - "Chain dispatcher result shape mirrors workflow callback dispatch: `%{delivered: count, failed: count}`."
  - "Failed chain progression remains inspectable through callback `status`, `attempts`, `available_at`, and `last_error`."

requirements-completed: [CHN-01]

duration: 6 min
completed: 2026-06-14
---

# Phase 61 Plan 04: Event-Scoped Chain Progression Summary

**Durable chain progression through event-scoped callback rows, with host workflow callbacks isolated from internal chain events**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-14T21:26:29Z
- **Completed:** 2026-06-14T21:32:14Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `chain.step_succeeded` to the callback event vocabulary.
- Scoped `Workflow.Runtime.dispatch_callbacks/2` to workflow and batch callback events so chain events remain pending for chain progression.
- Extended `Batch.Tracker.record_progress/3` to emit one durable chain callback after first-time successful progress when chain metadata includes `chain_next_step`.
- Added `ObanPowertools.Chain.Progression.dispatch_callbacks/2` to claim only chain events, insert the next Oban job, carry the remaining tail, and mark callbacks delivered or retryable failed.
- Covered the full D-20 fetch -> parse -> write -> notify progression across repeated tracker/progression cycles.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Callback event scope tests** - `ed65e28` (test)
2. **Task 1 GREEN: Host callback event filtering** - `ee4c544` (feat)
3. **Task 2 RED: Chain progression tests** - `f2ec2d5` (test)
4. **Task 2 GREEN: Chain progression dispatcher** - `f7a9b2b` (feat)
5. **Plan formatting cleanup** - `1029847` (style)

**Plan metadata:** pending docs commit

## Files Created/Modified

- `lib/oban_powertools/chain/progression.ex` - Event-scoped chain callback dispatcher that claims `chain.step_succeeded`, inserts next jobs, rewrites remaining tails, and records retry state on failure.
- `test/oban_powertools/chain_progression_test.exs` - CHN-01 coverage for event vocabulary, tracker-emitted chain callbacks, dispatcher success/failure behavior, nil next-step delivery, and four-step D-20 progression.
- `lib/oban_powertools/batch/tracker.ex` - Emits deduped chain callback rows from first-time successful chain step progress.
- `lib/oban_powertools/callback.ex` - Allows `chain.step_succeeded` in callback changesets.
- `lib/oban_powertools/workflow/runtime.ex` - Restricts host callback claiming to workflow and batch events.
- `test/oban_powertools/workflow_callbacks_test.exs` - Proves workflow dispatch leaves chain callbacks pending while workflow and batch callbacks still dispatch.

## Decisions Made

- Followed D-10 and D-12 by using the existing callback outbox and tracker bridge instead of introducing a chain table or a worker `on_success/2` authoring contract.
- Kept the host workflow dispatcher and chain progression dispatcher separate by exact event filtering.
- Used callback rows as the retry and operator-inspection surface for failed progression, matching the Phase 62 visibility needs.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- RED Task 1 failed as expected because `chain.step_succeeded` was not yet accepted by `Callback.changeset/2`.
- RED Task 2 failed as expected because `ObanPowertools.Chain.Progression` did not exist and the tracker did not yet emit chain callbacks.
- `mix test` continues to emit existing warnings from Oban worker macro expansion in dependency docs; the focused behavior passed.

## Known Stubs

None introduced by this plan.

## User Setup Required

None - no external service configuration required.

## Threat Flags

None. The plan intentionally adds a callback-row-to-Oban-job trust boundary and mitigates the registered risks with event-scoped claims, lease/limit handling, retry availability, `last_error`, and payloads limited to ids plus next-step descriptors.

## Verification

- RED Task 1: `mix test test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/chain_progression_test.exs` failed with 2 expected failures before implementation.
- GREEN Task 1: `mix test test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/chain_progression_test.exs` passed with 6 tests, 0 failures.
- RED Task 2: `mix test test/oban_powertools/chain_progression_test.exs` failed with expected missing progression module and tracker-emission failures.
- GREEN Task 2: `mix test test/oban_powertools/chain_progression_test.exs` passed with 7 tests, 0 failures.
- Final plan verification after formatting: `mix test test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/chain_progression_test.exs` passed with 12 tests, 0 failures.
- Acceptance source assertions passed for `chain.step_succeeded`, host callback events, `dispatch_callbacks/2`, `FOR UPDATE SKIP LOCKED`, `next_step`, `step`, `remaining`, and `chain_next_step`.

## Next Phase Readiness

Ready for 61-05 to add durable upstream output handoff and safe args builders on top of the existing chain metadata and event-scoped progression path.

## Self-Check: PASSED

- Created file exists: `lib/oban_powertools/chain/progression.ex`.
- Created file exists: `test/oban_powertools/chain_progression_test.exs`.
- Created file exists: `.planning/phases/61-apis-batches-chains/61-04-SUMMARY.md`.
- Task commits exist: `ed65e28`, `ee4c544`, `f2ec2d5`, `f7a9b2b`, `1029847`.
- Plan-level verification passed: `mix test test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/chain_progression_test.exs`.

---
*Phase: 61-apis-batches-chains*
*Completed: 2026-06-14*
