---
phase: 20-cancellation-late-completion-expiry-semantics
plan: 01
subsystem: workflow
tags: [ecto, postgres, workflow, cancellation, semantics]
requires:
  - phase: 19-await-registration-signal-facts-expiry-authority
    provides: durable await, signal, and expiry facts for later cancellation races
provides:
  - canonical request/evidence/outcome reduction for workflow truth
  - bounded post-cancel and late-arrival evidence vocabulary
  - schema parity across runtime, installer, repo tests, and supported hosts
affects: [20-02-cooperative-cancellation, 20-03-proof-closure, REC-03, SIG-03, VER-02]
tech-stack:
  added: []
  patterns:
    - cancellation request evidence is durable but never authoritative by itself
    - workflow, test, installer, and host schemas must ship the same bounded evidence contract
key-files:
  created: []
  modified:
    - lib/oban_powertools/workflow/runtime.ex
    - lib/oban_powertools/workflow/workflow.ex
    - lib/oban_powertools/workflow/step.ex
    - lib/oban_powertools/workflow/signal_record.ex
    - lib/oban_powertools/workflow/command_attempt.ex
    - lib/mix/tasks/oban_powertools.install.ex
    - test/support/migrations/2_phase_3_tables.exs
    - examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs
    - examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs
    - test/oban_powertools/workflow_runtime_test.exs
key-decisions:
  - "Reduce final workflow and step truth from durable facts in one runtime-owned path instead of letting `cancel_requested_at` masquerade as terminal meaning."
  - "Reuse `SignalRecord` and `CommandAttempt` as the bounded late-evidence seam instead of adding a generalized event-history surface."
patterns-established:
  - "Request evidence, late evidence, and terminal outcome are separate concerns with one canonical reducer."
  - "Supported-host migration parity is part of the semantics contract, not post-hoc documentation."
requirements-completed: [REC-03, SIG-03, VER-02]
duration: in-progress working tree plus closure pass
completed: 2026-05-24
---

# Phase 20 Plan 01 Summary

**Workflow cancellation and late-arrival truth now reduce through one canonical request/evidence/outcome path, with bounded durable evidence aligned across runtime and host schemas.**

## Performance

- **Duration:** in-progress working tree plus closure pass
- **Started:** 2026-05-24T16:00:00Z
- **Completed:** 2026-05-24T17:00:00Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Centralized final workflow and step outcome reduction around durable facts instead of transient cancel-request state.
- Added bounded schema vocabulary for late signals and post-cancel evidence without widening the public control surface.
- Kept installer output, repo-test schema, and supported-host migrations aligned with the runtime contract.

## Task Commits

This plan was closed from an already-dirty working tree, so atomic task commits were not created during this execution pass.

## Files Created/Modified
- `lib/oban_powertools/workflow/runtime.ex` - canonical reducer and bounded precedence logic
- `lib/oban_powertools/workflow/workflow.ex` - durable workflow fields aligned to request-versus-outcome semantics
- `lib/oban_powertools/workflow/step.ex` - step-level cancellation and terminal-truth contract updates
- `lib/oban_powertools/workflow/signal_record.ex` - bounded late-signal vocabulary
- `lib/oban_powertools/workflow/command_attempt.ex` - append-only evidence for rejected, duplicate, and late paths
- `lib/mix/tasks/oban_powertools.install.ex` - generated schema contract for supported hosts
- `test/support/migrations/2_phase_3_tables.exs` - repo-test schema parity
- `examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs` - current supported-host semantics migration
- `examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs` - archived upgrade-source semantics migration
- `test/oban_powertools/workflow_runtime_test.exs` - proof that request evidence and final truth no longer drift

## Decisions Made
- Preserved `completed_after_cancel_request` as explicit durable truth rather than collapsing it to generic cancellation.
- Kept late and duplicate arrivals as append-only evidence that cannot rewrite canonical workflow rows.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The implementation was already partially landed in the working tree, so execution validated and closed that in-place work rather than replaying it from clean commits.

## User Setup Required

None - the supported-host migration set and installer output now carry the same semantics contract automatically.

## Next Phase Readiness

- `20-02` can build cooperative cancellation and diagnosis ordering directly on top of the new reducer.
- The runtime now exposes one durable truth path for callback and explain surfaces to consume.

---
*Phase: 20-cancellation-late-completion-expiry-semantics*
*Completed: 2026-05-24*

## Self-Check: PASSED

- Final workflow and step truth reduce from durable facts in one canonical runtime path
- Request evidence remains durable without outranking terminal meaning
- Repo, installer, and supported-host schemas expose the same bounded evidence contract
