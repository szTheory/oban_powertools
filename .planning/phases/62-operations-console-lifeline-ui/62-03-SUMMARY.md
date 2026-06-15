---
phase: 62-operations-console-lifeline-ui
plan: 03
subsystem: read-model
tags: [ecto, batches, callbacks, chains, display-policy]
requires:
  - phase: 62-operations-console-lifeline-ui
    provides: 62-01 RED tests for the Batches read model
  - phase: 61-apis-batches-chains
    provides: persisted batch, callback, chain, and audit evidence
provides:
  - Read-only `ObanPowertools.Batches` query context
  - Batch list rows, status counts, progress, failed-member summaries, callback summaries, and chain badges
  - Batch detail rows with failed members, callback outbox evidence, blocked-state copy, chain context, and audit evidence
affects: [batches-ui, callbacks, chains]
tech-stack:
  added: []
  patterns: [read-only Ecto query context, display-policy rendering, server-derived retry eligibility]
key-files:
  created:
    - lib/oban_powertools/batches.ex
  modified: []
key-decisions:
  - "Batch UI SQL lives in `ObanPowertools.Batches`, keeping the future LiveView out of ad hoc cross-table queries."
  - "Callback retry eligibility is derived from durable callback state and lease expiry."
  - "Chain context is inferred from existing job metadata and callback payload evidence; no chain route or chain table was introduced."
patterns-established:
  - "Batch detail rows expose display-policy-rendered job args/meta/errors and callback payload/errors for safe operator rendering."
  - "Output-unavailable blocked-state copy is locked in the read model for consistent support-truth messaging."
requirements-completed: [BUI-01, BUI-02, BUI-03, BUI-04]
duration: 8 min
completed: 2026-06-15
---

# Phase 62 Plan 03: Batches Read Model Summary

**Read-only batch operations query context for list, detail, blocked-state, and retry eligibility data**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-15T02:56:55Z
- **Completed:** 2026-06-15T03:04:41Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Added `ObanPowertools.Batches` with `%Batches{}` filters, `list/3`, `get/3`, `count_by_status/2`, and `blocked_state/2`.
- Implemented status/query/chain/queue/worker filtering, status counts, offset pagination, progress calculations, failed-member counts, callback summaries, and retry eligibility.
- Added detail shaping for failed Oban members, callback outbox rows, chain context, display-policy-rendered payload/error fields, Oban Web bridge paths, and directly findable audit evidence.
- Added blocked-state support copy for insertion failures, callback failures, output unavailable/expired, executing, exhausted, and completed states.

## Task Commits

The implementation was committed as one cohesive read-model file:

1. **Tasks 1-3: Add Batches list/detail/blocked-state read model** - `95e9e21` (feat)

## Files Created/Modified

- `lib/oban_powertools/batches.ex` - Read-only batch UI query context and blocked-state derivation.

## Decisions Made

The read model uses batch queries as the primary entry point and performs member/callback shaping inside the context rather than in the LiveView. Queue and worker filters inspect all batch members so operators can find batches by their successful or pending members as well as failed members.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed. **Impact:** No scope change.

## Issues Encountered

The first queue/worker filter pass only considered failed members. It was corrected to derive filter values from all batch members while keeping failed-member rows scoped to actionable failures.

The first chain context merge preferred earlier job argument evidence over later callback payload evidence. It was corrected so callback evidence can refine upstream output details when both sources are present.

## Verification

- `mix test test/oban_powertools/batches_test.exs` passed: `5 tests, 0 failures`.
- `rg -n "Oban\\.(retry_job|cancel_job|drain_queue)" lib/oban_powertools/batches.ex` emitted no matches.

## Self-Check: PASSED

- `ObanPowertools.Batches` owns Phase 62 batch list/detail read data.
- Read-side retry eligibility is server-derived and test-covered.
- The module has no Oban runtime mutation API references.
- No chain route, chain table, or generic DAG surface was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 62-04 Lifeline callback retry implementation.

---
*Phase: 62-operations-console-lifeline-ui*
*Completed: 2026-06-15*
