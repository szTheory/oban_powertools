---
phase: 61-apis-batches-chains
plan: "05"
subsystem: api
tags: [elixir, oban, ecto, chains, job-records, tdd]

requires:
  - phase: 61-apis-batches-chains
    provides: "61-03 chain DSL and 61-04 event-scoped chain progression callbacks"
provides:
  - Public `ObanPowertools.Chain.fetch_upstream_result/1` and repo-explicit output fetch variants
  - `ObanPowertools.Chain.ArgsBuilder` marker behavior for persisted dynamic chain args
  - Insert-time validation for output-dependent steps requiring upstream `record_output: true`
  - Output-aware chain progression that fetches `JobRecord` payloads and fails callbacks explicitly when unavailable
affects: [phase-61, phase-62, chains, callbacks, batch-operator-ui]

tech-stack:
  added: []
  patterns:
    - Durable upstream output handoff through `JobRecord` rather than callback/job-arg payload copies
    - Persisted dynamic args execution gated by a behavior marker and arity-2 function references
    - Recoverable chain progression failure with explicit `last_error` atoms on callback rows

key-files:
  created:
    - lib/oban_powertools/chain/args_builder.ex
    - test/oban_powertools/chain_output_test.exs
    - .planning/phases/61-apis-batches-chains/61-05-SUMMARY.md
  modified:
    - lib/oban_powertools/chain.ex
    - lib/oban_powertools/chain/progression.ex
    - test/oban_powertools/chain_test.exs
    - test/oban_powertools/chain_progression_test.exs

key-decisions:
  - "Chain output handoff reads upstream payloads through `JobRecord.fetch_record/2` so expiry can be enforced before returning payloads."
  - "Output-dependent chain args builders must opt in with `ObanPowertools.Chain.ArgsBuilder` and expose the persisted arity-2 function."
  - "Chain progression builds downstream args only from the builder return value; upstream payloads are never automatically merged into job args."

patterns-established:
  - "Output-dependent steps are represented by safe MFA descriptors plus `requires_output`, not anonymous functions or copied payloads."
  - "Unavailable or expired upstream output returns explicit errors and leaves the chain callback row failed and retryable."

requirements-completed: [CHN-02]

duration: 5 min
completed: 2026-06-14
---

# Phase 61 Plan 05: Durable Chain Output Handoff Summary

**Chain state propagation through durable `JobRecord` output references with behavior-gated args builders and explicit callback failure states**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-14T21:35:15Z
- **Completed:** 2026-06-14T21:40:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added CHN-02 RED coverage for upstream result fetching, missing/unrecorded/expired output errors, output-recording validation, unsafe builder rejection, output-aware progression, and failed callback persistence.
- Added `ObanPowertools.Chain.ArgsBuilder` as the explicit marker behavior for persisted dynamic args builders.
- Added `Chain.fetch_upstream_result/1` and `/2`, including repo-explicit lookup, missing upstream id handling, unavailable output handling, and expiry checks.
- Extended chain insertion validation so output-dependent steps require a safe builder and an immediately preceding worker with `record_output: true`.
- Updated chain progression to fetch upstream output from `JobRecord`, invoke builder MFA references, insert downstream jobs with only builder-returned args, and mark unavailable-output callbacks failed with explicit errors.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: CHN-02 output handoff tests** - `04d472a` (test)
2. **Task 2 GREEN: Durable output handoff and safe args builders** - `c66df3f` (feat)

**Plan metadata:** pending docs commit

## Files Created/Modified

- `lib/oban_powertools/chain/args_builder.ex` - Marker behavior and `__using__/1` macro for safe persisted builder execution.
- `lib/oban_powertools/chain.ex` - Adds upstream output fetch APIs and output-dependent builder/recording validation.
- `lib/oban_powertools/chain/progression.ex` - Resolves output-dependent args by fetching `JobRecord` payloads and applying safe builder references.
- `test/oban_powertools/chain_output_test.exs` - CHN-02 coverage for durable handoff, explicit errors, safe builders, and callback failure states.
- `test/oban_powertools/chain_test.exs` - Updates existing dynamic-builder fixture to opt into the new safe builder behavior.
- `test/oban_powertools/chain_progression_test.exs` - Updates existing D-20 chain fixture to record upstream output before output-dependent progression.

## Decisions Made

- Followed D-14 through D-18: chain metadata carries upstream job ids, not payloads; output is fetched through `JobRecord`; output-dependent upstream workers must record output; failures are explicit and recoverable.
- Kept builder execution narrow: persisted descriptors must resolve to a loaded module that opted into `ObanPowertools.Chain.ArgsBuilder`, and the named function must have arity 2.
- Preserved 61-04 tail rewriting behavior while changing only the args source for output-dependent steps.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated existing dynamic-chain fixtures for the new safe builder contract**
- **Found during:** Task 2 (Implement output handoff and safe args builders)
- **Issue:** Existing `chain_test` and `chain_progression_test` fixtures used persisted builder references without the new marker behavior and without recorded upstream output, which would fail under the CHN-02 security contract.
- **Fix:** Added `use ObanPowertools.Chain.ArgsBuilder` to the existing fixture builders, enabled `record_output: true` on the relevant fetch workers, and recorded output before output-dependent progression in the D-20 test.
- **Files modified:** `test/oban_powertools/chain_test.exs`, `test/oban_powertools/chain_progression_test.exs`
- **Verification:** `mix test test/oban_powertools/chain_test.exs test/oban_powertools/chain_progression_test.exs` passed with 13 tests, 0 failures.
- **Committed in:** `c66df3f`

---

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** No scope creep; the fixes keep existing chain tests aligned with the new CHN-02 correctness and security requirements.

## Issues Encountered

- RED Task 1 failed as expected because `ObanPowertools.Chain.ArgsBuilder` did not exist yet.
- Test-inserted Oban rows default to attempt `0`; tests that directly call `JobRecord.record/5` now set attempt `1` to model a performed job while preserving the persisted upstream job id.
- Focused test runs continue to emit existing Oban worker macro warnings from dependency docs and pre-existing batch test fixtures; the planned behavior passes.

## Known Stubs

None introduced by this plan.

## User Setup Required

None - no external service configuration required.

## Threat Flags

None. The plan's registered trust boundaries were implemented directly: builder execution is marker-gated, upstream payloads stay behind `JobRecord`, and output lookup failures persist explicit callback `last_error` state.

## Verification

- RED Task 1: `mix test test/oban_powertools/chain_output_test.exs` failed as expected before implementation because `ObanPowertools.Chain.ArgsBuilder` was missing.
- Task 1 structural acceptance passed for `fetch_upstream_result`, `record_output_required`, `unsafe_args_builder`, `output_expired`, and `output_unavailable`.
- GREEN Task 2: `mix test test/oban_powertools/chain_output_test.exs` passed with 7 tests, 0 failures.
- Regression verification: `mix test test/oban_powertools/chain_test.exs test/oban_powertools/chain_progression_test.exs` passed with 13 tests, 0 failures.
- Plan verification: `mix test test/oban_powertools/chain_output_test.exs` passed with 7 tests, 0 failures.
- Phase 61 focused verification: `mix test test/oban_powertools/batch_insert_stream_test.exs test/oban_powertools/chain_test.exs test/oban_powertools/chain_progression_test.exs test/oban_powertools/chain_output_test.exs` passed with 26 tests, 0 failures.
- Acceptance source assertions passed for `__powertools_chain_args_builder__/0`, `fetch_upstream_result`, `:missing_upstream_job_id`, `:output_unavailable`, `:output_expired`, `:record_output_required`, `:unsafe_args_builder`, `Chain.fetch_upstream_result`, and no default merge of full upstream payload into downstream args.

## Next Phase Readiness

Phase 61 now satisfies BAT-02, CHN-01, and CHN-02. Phase 62 can build operator visibility for batches, chain progression callbacks, and output-unavailable failure states without guessing from implicit job behavior.

## Self-Check: PASSED

- Created file exists: `lib/oban_powertools/chain/args_builder.ex`.
- Created file exists: `test/oban_powertools/chain_output_test.exs`.
- Created file exists: `.planning/phases/61-apis-batches-chains/61-05-SUMMARY.md`.
- Task commits exist: `04d472a`, `c66df3f`.
- Plan-level verification passed: `mix test test/oban_powertools/chain_output_test.exs`.
- Phase focused verification passed: `mix test test/oban_powertools/batch_insert_stream_test.exs test/oban_powertools/chain_test.exs test/oban_powertools/chain_progression_test.exs test/oban_powertools/chain_output_test.exs`.

---
*Phase: 61-apis-batches-chains*
*Completed: 2026-06-14*
