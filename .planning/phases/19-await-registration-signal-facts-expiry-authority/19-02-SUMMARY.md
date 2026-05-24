---
phase: 19-await-registration-signal-facts-expiry-authority
plan: 02
subsystem: workflow
tags: [ecto, postgres, workflow, signals, reconciliation]
requires:
  - phase: 19-await-registration-signal-facts-expiry-authority
    provides: explicit active await truth and bounded signal status vocabulary
provides:
  - facts-first signal ingress with workflow-scoped authority
  - durable duplicate and already-consumed attempt evidence
  - row-only reconcile proof for lost advisory wakeups
affects: [19-03-expiry-authority, SIG-02, VER-01]
tech-stack:
  added: []
  patterns:
    - canonical signal rows are inserted before any workflow wait is consumed
    - ambiguous and unmatched facts remain durable until workflow authority can be resolved safely
key-files:
  created: []
  modified:
    - lib/oban_powertools/workflow/runtime.ex
    - lib/oban_powertools/workflow.ex
    - lib/oban_powertools/workflow/signal_record.ex
    - lib/oban_powertools/workflow/command_attempt.ex
    - test/oban_powertools/workflow_runtime_test.exs
    - test/oban_powertools/workflow_coordinator_test.exs
key-decisions:
  - "Resolve signal authority from durable workflow IDs before consumption instead of waking by correlation alone."
  - "Keep duplicate and already-consumed attempts as durable command evidence rather than mutating canonical signal truth."
patterns-established:
  - "Claim unmatched or ambiguous signal rows only when one workflow-authoritative match exists."
  - "Lost or duplicated advisory wakeups are harmless because reconcile consumes from rows alone."
requirements-completed: [SIG-02, VER-01]
duration: in-progress working tree plus closure pass
completed: 2026-05-24
---

# Phase 19 Plan 02 Summary

**Signal ingress now records canonical durable facts first, claims authority at the workflow scope, and reconciles waits safely even when advisory wakeups are missing.**

## Performance

- **Duration:** in-progress working tree plus closure pass
- **Started:** 2026-05-24T15:37:00Z
- **Completed:** 2026-05-24T15:49:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Changed signal ingress to insert a canonical signal row before any wait reconciliation happens.
- Added durable ambiguity, unmatched, duplicate, and already-consumed evidence behavior without widening the public API.
- Proved that a signal row inserted without coordinator wakeup still resolves through `reconcile_workflow/3`.

## Task Commits

This plan was finished from an already-dirty working tree, so atomic task commits were not created during this execution pass.

## Files Created/Modified
- `lib/oban_powertools/workflow/runtime.ex` - workflow-scoped signal claiming, facts-first ingress, and row-only reconcile logic
- `lib/oban_powertools/workflow.ex` - unchanged public paved road over the tightened runtime semantics
- `lib/oban_powertools/workflow/signal_record.ex` - canonical signal status vocabulary
- `lib/oban_powertools/workflow/command_attempt.ex` - durable attempt evidence reused for duplicates and already-consumed paths
- `test/oban_powertools/workflow_runtime_test.exs` - proof for unmatched, ambiguous, duplicate, replay, and row-only reconcile behavior
- `test/oban_powertools/workflow_coordinator_test.exs` - proof that advisory coordinator gaps do not change DB-first signal truth

## Decisions Made
- Kept `Workflow.deliver_signal/2` as the only public ingress seam while changing its underlying semantics to be facts-first and workflow-authoritative.
- Reused command-attempt rows for replay evidence instead of introducing a second dedicated evidence table.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The pre-await signal path initially stayed unmatched after await registration because the claim helper compared the workflow ID tuple incorrectly. Fixing that restored deterministic row-only reconciliation without changing public behavior.

## User Setup Required

None - host signal ingress still uses the same narrow API.

## Next Phase Readiness

- `19-03` can now treat signal rows as authoritative evidence and focus only on expiry finalization and late-arrival proof.

---
*Phase: 19-await-registration-signal-facts-expiry-authority*
*Completed: 2026-05-24*

## Self-Check: PASSED

- Every signal is stored durably before wait reconciliation
- Ambiguous correlation-only signals stay durable and do not wake waits
- Duplicate and already-consumed attempts remain durable evidence
- Row-only reconcile succeeds without advisory wakeups
