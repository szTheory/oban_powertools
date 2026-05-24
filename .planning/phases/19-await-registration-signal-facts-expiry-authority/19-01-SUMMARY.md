---
phase: 19-await-registration-signal-facts-expiry-authority
plan: 01
subsystem: workflow
tags: [ecto, postgres, workflow, signals, awaits]
requires:
  - phase: 17-db-first-transition-engine-command-pipeline
    provides: DB-first workflow mutation and reconcile authority
provides:
  - explicit active-await step mirrors anchored by `active_await_id`
  - canonical await and signal row vocabulary aligned across runtime and supported hosts
  - fresh proof that pre-await and active-await semantics stay durable
affects: [19-02-signal-ingress, 19-03-expiry-authority, SIG-01, VER-02]
tech-stack:
  added: []
  patterns:
    - one waiting await row owns wait truth while workflow steps expose only a thin diagnosis mirror
    - runtime, installer, repo-test, and supported-host migrations must carry the same workflow wait contract
key-files:
  created: []
  modified:
    - lib/oban_powertools/workflow/await.ex
    - lib/oban_powertools/workflow/signal_record.ex
    - lib/oban_powertools/workflow/step.ex
    - lib/oban_powertools/workflow/runtime.ex
    - lib/mix/tasks/oban_powertools.install.ex
    - test/support/migrations/2_phase_3_tables.exs
    - examples/phoenix_host/priv/repo/migrations/20260522000020_oban_powertools_workflows.exs
    - examples/phoenix_host/priv/repo/migrations/20260522000021_oban_powertools_workflow_steps.exs
    - examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs
    - examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000020_oban_powertools_workflows.exs
    - examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000021_oban_powertools_workflow_steps.exs
    - examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs
    - test/oban_powertools/workflow_runtime_test.exs
key-decisions:
  - "Keep exactly one active wait per step and expose it on the step row only as a thin mirror plus `active_await_id`."
  - "Treat canonical signal rows as durable facts with bounded statuses instead of relying on correlation-only wakeups."
patterns-established:
  - "Await rows own resolution linkage and deadline truth; step rows only mirror diagnosis-facing fields."
  - "Supported-host example migrations must stay schema-parity aligned with repo test migrations and installer output."
requirements-completed: [SIG-01, VER-02]
duration: in-progress working tree plus closure pass
completed: 2026-05-24
---

# Phase 19 Plan 01 Summary

**One active await per step now lives as explicit durable truth, with workflow steps reduced to a thin diagnosis mirror and supported-host schema parity restored.**

## Performance

- **Duration:** in-progress working tree plus closure pass
- **Started:** 2026-05-24T15:32:00Z
- **Completed:** 2026-05-24T15:49:00Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments
- Added `active_await_id` to the workflow step mirror and aligned wait-field ownership around the await row.
- Narrowed signal-row vocabulary to explicit durable statuses that later runtime reconciliation can interpret safely.
- Synced runtime, installer, repo-test, and supported-host migrations so the await/signal contract is the same everywhere it is supported.

## Task Commits

This plan was finished from an already-dirty working tree, so atomic task commits were not created during this execution pass.

## Files Created/Modified
- `lib/oban_powertools/workflow/await.ex` - bounded await statuses and row-level truth contract
- `lib/oban_powertools/workflow/signal_record.ex` - canonical durable signal statuses
- `lib/oban_powertools/workflow/step.ex` - thin step mirror with `active_await_id`
- `lib/oban_powertools/workflow/runtime.ex` - await registration and mirror updates
- `lib/mix/tasks/oban_powertools.install.ex` - generated host migration contract for wait/signal fields
- `test/support/migrations/2_phase_3_tables.exs` - fresh repo-test schema parity
- `examples/phoenix_host/priv/repo/migrations/20260522000020_oban_powertools_workflows.exs` - supported host workflow column parity
- `examples/phoenix_host/priv/repo/migrations/20260522000021_oban_powertools_workflow_steps.exs` - supported host step mirror parity
- `examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs` - supported host await/signal parity
- `examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000020_oban_powertools_workflows.exs` - archived host workflow parity
- `examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000021_oban_powertools_workflow_steps.exs` - archived host step mirror parity
- `examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs` - archived host await/signal parity
- `test/oban_powertools/workflow_runtime_test.exs` - proof for active-await mirrors and pre-await durability

## Decisions Made
- Kept the public await API narrow and moved extra semantics into durable row meaning rather than new public DSL surface.
- Used step-row mirroring only for operator diagnosis, not as a second source of correctness.

## Deviations from Plan

### Auto-fixed Issues

**1. Supported-host workflow schema drift**
- **Found during:** Task 2
- **Issue:** The example-host workflow and step migrations lagged behind the runtime/test-support contract, which blocked upgrade-lane workflow proof.
- **Fix:** Brought both supported-host fixture migration sets up to the same workflow, step, await, and signal schema shape the runtime now expects.
- **Files modified:** `examples/phoenix_host/priv/repo/migrations/20260522000020_oban_powertools_workflows.exs`, `examples/phoenix_host/priv/repo/migrations/20260522000021_oban_powertools_workflow_steps.exs`, `examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000020_oban_powertools_workflows.exs`, `examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000021_oban_powertools_workflow_steps.exs`
- **Verification:** `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof`

## Issues Encountered

- The working tree already contained substantial workflow-semantic changes, so execution finished that in-place implementation instead of attempting a clean-room rewrite.

## User Setup Required

None - supported host installs inherit the updated wait/signal schema contract through the existing installer and example-host flows.

## Next Phase Readiness

- `19-02` can assume one authoritative wait row per step and a workflow-scoped signal row vocabulary.
- `19-03` can collapse expiry semantics onto the shared reconcile path without re-opening schema meaning.

---
*Phase: 19-await-registration-signal-facts-expiry-authority*
*Completed: 2026-05-24*

## Self-Check: PASSED

- One active await per step is explicit and durable
- Step rows mirror wait state through `active_await_id` plus diagnosis-facing fields only
- Runtime, repo-test, installer, and supported-host migrations expose the same wait/signal contract
