---
phase: 19-await-registration-signal-facts-expiry-authority
plan: 03
subsystem: workflow
tags: [ecto, postgres, workflow, expiry, upgrade-proof]
requires:
  - phase: 19-await-registration-signal-facts-expiry-authority
    provides: workflow-authoritative await and signal facts
provides:
  - one reconcile-owned expiry finalization path
  - late-signal durable evidence that cannot reopen expired waits
  - updated project traceability and archived-host proof for in-flight waiting workflows
affects: [SIG-03, VER-01, VER-02, planning-traceability]
tech-stack:
  added: []
  patterns:
    - expiry legality belongs to DB-first reconcile, never to ingress-side shortcuts
    - planning truth is updated only after tests and supported-host proof align
key-files:
  created:
    - .planning/phases/19-await-registration-signal-facts-expiry-authority/19-01-SUMMARY.md
    - .planning/phases/19-await-registration-signal-facts-expiry-authority/19-02-SUMMARY.md
    - .planning/phases/19-await-registration-signal-facts-expiry-authority/19-03-SUMMARY.md
  modified:
    - lib/oban_powertools/workflow/runtime.ex
    - test/support/example_host_contract.ex
    - test/oban_powertools/example_host_contract_test.exs
    - test/oban_powertools/workflow_runtime_test.exs
    - test/oban_powertools/workflow_coordinator_test.exs
    - .planning/PROJECT.md
    - .planning/REQUIREMENTS.md
key-decisions:
  - "Keep late signals as durable evidence after expiry and never let them reopen expired waits."
  - "Move archived-host proof beyond compile/reset by exercising a real waiting workflow on the upgrade lane."
patterns-established:
  - "Upgrade-lane fixture prep must refresh the supported workflow migration set before running current semantic proof."
  - "Requirements and milestone posture advance only after repo tests and supported-host proof are both green."
requirements-completed: [SIG-03, VER-01, VER-02]
duration: in-progress working tree plus closure pass
completed: 2026-05-24
---

# Phase 19 Plan 03 Summary

**Wait expiry now finalizes through one DB-first reconcile path, late signals remain durable evidence only, and the archived host upgrade lane proves the shipped contract on a real waiting workflow.**

## Performance

- **Duration:** in-progress working tree plus closure pass
- **Started:** 2026-05-24T15:44:00Z
- **Completed:** 2026-05-24T15:50:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Kept expiry authority inside the shared reconcile path and prevented late signals from reopening expired waits.
- Extended the archived upgrade lane so it now exercises an in-flight waiting workflow under the supported Phase 19 host contract.
- Updated `PROJECT.md` and `REQUIREMENTS.md` so traceability and milestone posture match what the repo and host proof now verify.

## Task Commits

This plan was finished from an already-dirty working tree, so atomic task commits were not created during this execution pass.

## Files Created/Modified
- `lib/oban_powertools/workflow/runtime.ex` - reconcile-owned expiry handling and late-signal evidence
- `test/support/example_host_contract.ex` - archived upgrade-lane workflow proof and current migration refresh
- `test/oban_powertools/example_host_contract_test.exs` - upgrade-proof assertions for Phase 19 wait/signal semantics
- `test/oban_powertools/workflow_runtime_test.exs` - expiry and late-arrival proof
- `test/oban_powertools/workflow_coordinator_test.exs` - advisory-gap proof stays aligned with DB-first semantics
- `.planning/PROJECT.md` - milestone posture reflects Phase 19 closure
- `.planning/REQUIREMENTS.md` - `SIG-01` through `SIG-03`, `VER-01`, and `VER-02` traceability now point to Phase 19

## Decisions Made
- Preserved the support truth as explicitly Postgres-first and workflow-scoped, with no exactly-once or generic event-bus claims.
- Reused the archived host lane instead of inventing a separate migration harness, but refreshed it to current supported workflow migrations before proof.

## Deviations from Plan

### Auto-fixed Issues

**1. Archived host workflow migrations lagged behind current runtime semantics**
- **Found during:** Task 2
- **Issue:** The archived upgrade fixture could not execute the Phase 19 waiting-workflow proof because its workflow and step tables lacked current runtime columns.
- **Fix:** Synced the copied upgrade lane to the current supported workflow migration set before reset, then added a real waiting-workflow proof run on that lane.
- **Files modified:** `test/support/example_host_contract.ex`, `examples/phoenix_host/priv/repo/migrations/20260522000020_oban_powertools_workflows.exs`, `examples/phoenix_host/priv/repo/migrations/20260522000021_oban_powertools_workflow_steps.exs`, `examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000020_oban_powertools_workflows.exs`, `examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000021_oban_powertools_workflow_steps.exs`
- **Verification:** `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof`

## Issues Encountered

- The archived host lane originally only proved compile/reset plus the cron first-session flow, so it needed an additional Phase 19 semantic proof to satisfy the new upgrade requirement.

## User Setup Required

None - the archived upgrade lane remains automated and continues to use the existing `ExampleHostContract` harness.

## Next Phase Readiness

- Phase 20 can build broader cancel, late-arrival, and completion precedence rules on top of a now-explicit wait/signal/expiry contract.

---
*Phase: 19-await-registration-signal-facts-expiry-authority*
*Completed: 2026-05-24*

## Self-Check: PASSED

- Expiry finalizes through the shared DB-first reconcile path
- Late signals remain evidence and do not reopen expired waits
- Repo proof and archived-host upgrade proof both exercise the Phase 19 contract
- Planning traceability now matches the semantics the repo actually ships
