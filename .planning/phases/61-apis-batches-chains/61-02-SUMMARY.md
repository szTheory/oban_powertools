---
phase: 61-apis-batches-chains
plan: "02"
subsystem: api
tags: [elixir, ecto, oban, batches, tdd]

requires:
  - phase: 61-apis-batches-chains
    provides: durable batch insertion metadata and installer contract from plan 61-01
provides:
  - Fixed-size `ObanPowertools.Batch.insert_stream/2` API for bounded massive batch enqueueing
  - Compact `Batch.InsertResult` and `Batch.InsertError` structs
  - Durable `insert_failed` status updates for partial insertion failures and count mismatches
affects: [phase-61, phase-62, batches, batch-operator-ui]

tech-stack:
  added: []
  patterns:
    - Bounded chunk insertion through `Oban.insert_all/2`
    - Batch member metadata injection through Oban job changeset meta
    - Durable partial failure reporting through batch row counters and failure payloads

key-files:
  created:
    - test/oban_powertools/batch_insert_stream_test.exs
    - .planning/phases/61-apis-batches-chains/61-02-SUMMARY.md
  modified:
    - lib/oban_powertools/batch.ex

key-decisions:
  - "`Batch.insert_stream/2` requires caller-provided `total_count:` and never consumes the stream to infer size."
  - "`on_conflict: :skip` is rejected before persistence because skipped jobs corrupt fixed-size batch completion invariants."
  - "Caller-supplied `batch_id` values are creation-only; an existing batch id returns `:batch_id_exists` and never appends jobs."
  - "Partial insertion failure is persisted as `insert_failed` before returning an `InsertError`."

patterns-established:
  - "Batch streaming API: validate options, create an inserting batch row, insert Oban job changesets per chunk, then return compact counters."
  - "Batch failure payloads: store JSON-safe `reason`, `kind`, and `message` strings for Phase 62 operator visibility."

requirements-completed: [BAT-02]

duration: 3 min
completed: 2026-06-14
---

# Phase 61 Plan 02: Batch Insert Stream Summary

**Fixed-size batch stream insertion with bounded Oban chunks, compact counters, and durable partial-failure state**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-14T21:12:30Z
- **Completed:** 2026-06-14T21:15:27Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added BAT-02 tests for bounded chunk insertion, metadata injection, invalid options, deterministic batch ids, partial insert failure, and count mismatch handling.
- Implemented `Batch.insert_stream/2` with required `repo:` and `total_count:`, default `chunk_size: 1_000`, optional `name:`, optional `batch_id:`, optional `oban:`, and `timeout:` pass-through.
- Added compact `%Batch.InsertResult{}` and `%Batch.InsertError{}` structs instead of returning every inserted Oban job.
- Persisted honest `insert_failed` state before returning errors for chunk insertion failures and stream count mismatches.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing batch insert stream tests** - `55c06c0` (test)
2. **Task 2 GREEN: Implement `Batch.insert_stream/2`** - `4724966` (feat)

**Plan summary metadata:** pending docs commit
**Plan tracking metadata:** pending tracking commit

## Files Created/Modified

- `test/oban_powertools/batch_insert_stream_test.exs` - BAT-02 regression coverage created by the existing RED commit.
- `lib/oban_powertools/batch.ex` - Adds result/error structs, option validation, batch row creation, chunked `Oban.insert_all/2`, metadata injection, counter updates, and durable failure handling.
- `.planning/phases/61-apis-batches-chains/61-02-SUMMARY.md` - Execution summary and verification evidence.

## Decisions Made

- Followed locked Phase 61 decisions D-01 through D-07 and D-19.
- Kept `Batch.insert_stream/2` in `ObanPowertools.Batch` rather than introducing a new service module because the current batch API surface is still compact and schema-adjacent.
- Limited Oban insertion option forwarding to `timeout:` as specified by the plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed invalid changeset exception normalization**
- **Found during:** Task 2 (`Batch.insert_stream/2`)
- **Issue:** The first implementation attempted to read `error.message` from `%Ecto.InvalidChangesetError{}`, which raised a `KeyError` while handling a chunk failure.
- **Fix:** Used `Exception.message(error)` for invalid changeset exception formatting.
- **Files modified:** `lib/oban_powertools/batch.ex`
- **Verification:** `mix test test/oban_powertools/batch_insert_stream_test.exs` passed with 6 tests, 0 failures.
- **Committed in:** `4724966`

---

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** No scope change; the fix was required for the planned partial-failure behavior.

## Issues Encountered

- The focused test emits existing warnings from Oban worker macro expansion and the test worker `@impl` annotation, but the BAT-02 behavior passes. No warning was introduced as a blocker for this plan.

## Known Stubs

None introduced by this plan.

## User Setup Required

None - no external service configuration required.

## Threat Flags

None. The plan intentionally adds a public batch enqueue API and mitigates the documented trust-boundary risks with option validation, bounded chunking, batch-id reuse refusal, metadata minimization, and persisted partial-failure state.

## Verification

- RED Task 1: `mix test test/oban_powertools/batch_insert_stream_test.exs` failed as expected before production implementation because `Batch.insert_stream/2` and result structs were missing.
- GREEN Task 2: `mix test test/oban_powertools/batch_insert_stream_test.exs` passed with 6 tests, 0 failures.
- Acceptance source assertion passed: `lib/oban_powertools/batch.ex` contains `def insert_stream(stream, opts)` and `@default_chunk_size 1_000`.
- Acceptance source assertion passed: `lib/oban_powertools/batch.ex` contains `Oban.insert_all` and does not contain support for `on_conflict: :skip`.

## Next Phase Readiness

Ready for 61-03 to build `ObanPowertools.Chain` on top of fixed-size batch insertion and callback outbox primitives.

## Self-Check: PASSED

- Created file exists: `test/oban_powertools/batch_insert_stream_test.exs`.
- Created file exists: `.planning/phases/61-apis-batches-chains/61-02-SUMMARY.md`.
- Task commits exist: `55c06c0`, `4724966`.
- Plan-level verification passed: `mix test test/oban_powertools/batch_insert_stream_test.exs`.

---
*Phase: 61-apis-batches-chains*
*Completed: 2026-06-14*
