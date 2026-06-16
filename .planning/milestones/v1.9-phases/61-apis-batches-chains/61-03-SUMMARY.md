---
phase: 61-apis-batches-chains
plan: "03"
subsystem: api
tags: [elixir, oban, ecto, chains, tdd]

requires:
  - phase: 61-apis-batches-chains
    provides: durable batch rows and bounded batch insertion metadata from plans 61-01 and 61-02
provides:
  - Public `ObanPowertools.Chain` struct and pipeable linear chain DSL
  - `Chain.from_list/2` constructor with duplicate-name, non-linear, and anonymous-builder validation
  - First-step chain insertion anchored in `ObanPowertools.Batch` rows and Oban job metadata
  - Durable `"chain_next_step"` metadata preserving immediate next step plus full remaining tail
affects: [phase-61, phase-62, chains, callbacks, batch-operator-ui]

tech-stack:
  added: []
  patterns:
    - Pipeable chain specs over Oban job changesets
    - JSON-safe durable step descriptors stored in Oban job meta
    - Chain grouping through existing batch rows rather than a new chain table

key-files:
  created:
    - lib/oban_powertools/chain.ex
    - test/oban_powertools/chain_test.exs
    - .planning/phases/61-apis-batches-chains/61-03-SUMMARY.md
  modified:
    - lib/oban_powertools.ex

key-decisions:
  - "`ObanPowertools.Chain` is a public spec/DSL layer over batches and Oban job metadata, not a new persistence table."
  - "Dynamic next-step arguments are persisted only as MFA builder references; anonymous functions are rejected."
  - "First-job metadata stores the immediate next step separately from the ordered remaining tail so 3+ step chains survive restarts."

patterns-established:
  - "Chain step descriptors include name, index, worker, args, queue, meta, optional args_builder, and requires_output."
  - "Chain insertion returns compact `%Chain.InsertResult{}` with chain_id equal to the backing batch id."

requirements-completed: [CHN-01]

duration: 5 min
completed: 2026-06-14
---

# Phase 61 Plan 03: Chain DSL and First-Step Insert Summary

**Public linear chain DSL with first-step Oban insertion and durable tail metadata over existing batch rows**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-14T21:17:00Z
- **Completed:** 2026-06-14T21:22:59Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added RED coverage for CHN-01 chain construction, `from_list/2`, duplicate-name validation, non-linear input rejection, anonymous builder rejection, first-job insertion, and 3+ step tail preservation.
- Implemented `ObanPowertools.Chain` with `%Chain{}`, `%Chain.Step{}`, `%Chain.InsertResult{}`, `chain/3`, `chain/4`, `from_list/2`, `insert/2`, and `insert/3`.
- Inserted chains by creating one existing `Batch` row and one first Oban job, with no `chains` table or migration.
- Stored `"chain_next_step"` as `%{"step" => immediate_descriptor, "remaining" => tail_descriptors}` so later progression can keep carrying the full linear tail.
- Updated top-level docs to list `ObanPowertools.Batch` and `ObanPowertools.Chain` as public builder-facing primitives.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing chain DSL tests** - `60c0618` (test)
2. **Task 2 GREEN: Implement linear chain DSL** - `8735568` (feat)

**Plan metadata:** pending docs commit

## Files Created/Modified

- `lib/oban_powertools/chain.ex` - Public chain structs, DSL/list constructors, validation, batch-backed first-step insertion, and durable tail descriptors.
- `test/oban_powertools/chain_test.exs` - CHN-01 tests for pipeable/list construction, validation, and first-job metadata.
- `lib/oban_powertools.ex` - Adds Batch and Chain to the public builder-facing primitive documentation.
- `.planning/phases/61-apis-batches-chains/61-03-SUMMARY.md` - Execution summary and verification evidence.

## Decisions Made

- Followed Phase 61 decisions D-08 through D-13 and D-20: chains remain strictly linear and compile to existing batch/job metadata primitives.
- Used the backing batch id as `chain_id`, matching the plan requirement to avoid a new chain persistence model.
- Stored dynamic args as JSON-safe MFA descriptors while keeping actual upstream-output execution for the later progression/output plans.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- RED Task 1 failed as expected because `ObanPowertools.Chain` did not exist yet.
- Focused tests emit existing warnings from Oban worker macro expansion in dependency docs, but the plan behavior passes and no new chain module warnings remain.

## Known Stubs

None introduced by this plan. Chain progression and upstream output execution are intentionally assigned to plans 61-04 and 61-05; this plan stores the durable metadata they consume.

## User Setup Required

None - no external service configuration required.

## Threat Flags

None. The plan intentionally adds a developer DSL-to-job-metadata trust boundary and mitigates the registered risks by rejecting branch-like inputs, rejecting anonymous builders, and storing only ids, names, step descriptors, and builder references.

## Verification

- RED Task 1: `mix test test/oban_powertools/chain_test.exs` failed as expected before implementation with `module ObanPowertools.Chain is not loaded and could not be found`.
- Task 1 structural acceptance passed for `from_list`, `duplicate_step_name`, `non_linear_chain`, `anonymous_builder_not_allowed`, `"chain_next_step"`, and `"remaining"`.
- GREEN Task 2: `mix test test/oban_powertools/chain_test.exs` passed with 6 tests, 0 failures.
- Plan verification: `mix test test/oban_powertools/chain_test.exs` passed with 6 tests, 0 failures.
- Acceptance source assertions passed for `defmodule ObanPowertools.Chain`, `defstruct name: nil, steps: []`, `def chain(`, `def from_list(`, `def insert(`, `:non_linear_chain`, `:anonymous_builder_not_allowed`, `"chain_next_step"`, `"step"`, `"remaining"`, and top-level docs mentioning `ObanPowertools.Chain`.

## Next Phase Readiness

Ready for 61-04 to consume the stored `"chain_next_step"` descriptors and wire event-scoped chain callback progression without routing chain events through workflow callbacks.

## Self-Check: PASSED

- Created file exists: `lib/oban_powertools/chain.ex`.
- Created file exists: `test/oban_powertools/chain_test.exs`.
- Created file exists: `.planning/phases/61-apis-batches-chains/61-03-SUMMARY.md`.
- Task commits exist: `60c0618`, `8735568`.
- Plan-level verification passed: `mix test test/oban_powertools/chain_test.exs`.

---
*Phase: 61-apis-batches-chains*
*Completed: 2026-06-14*
