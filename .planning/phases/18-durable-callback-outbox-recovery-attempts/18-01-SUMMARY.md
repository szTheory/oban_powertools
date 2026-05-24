---
phase: 18-durable-callback-outbox-recovery-attempts
plan: 01
subsystem: workflow
tags: [ecto, postgres, workflow, callbacks, retries]
requires:
  - phase: 17-db-first-transition-engine-command-pipeline
    provides: DB-first workflow semantics version 2 and durable command evidence
provides:
  - thin versioned callback envelopes for terminal and recovery events
  - lease-safe callback claiming on the durable outbox
  - schema parity for callback delivery fields across repo and supported hosts
affects: [18-02-recovery-sessions, 18-03-proof-and-support-truth, REC-01, VER-02]
tech-stack:
  added: []
  patterns:
    - post-commit callbacks are delivered through a claimed outbox row, never inline with workflow truth
    - callback payloads stay thin and fetch-by-ID friendly
key-files:
  created: []
  modified:
    - lib/oban_powertools/workflow/runtime.ex
    - lib/oban_powertools/workflow/callback_outbox.ex
    - lib/mix/tasks/oban_powertools.install.ex
    - test/support/migrations/2_phase_3_tables.exs
    - examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs
    - examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs
    - test/oban_powertools/workflow_runtime_test.exs
key-decisions:
  - "Keep exactly two workflow-scoped callback events and encode them as thin versioned envelopes."
  - "Use durable lease fields on callback rows instead of optimistic scan-and-send delivery."
patterns-established:
  - "Claim callback rows with lease expiry before invoking the host handler."
  - "Preserve workflow truth even when callback delivery fails or is retried."
requirements-completed: [REC-01, VER-02]
duration: in-progress working tree
completed: 2026-05-24
---

# Phase 18 Plan 01 Summary

**Lease-safe workflow callback outbox delivery with thin versioned envelopes and schema-aligned retry evidence across runtime and supported host installs.**

## Performance

- **Duration:** in-progress working tree plus closure pass
- **Started:** 2026-05-24T11:03:27Z
- **Completed:** 2026-05-24T12:04:27Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Added callback claim fields and a `FOR UPDATE SKIP LOCKED` lease-safe dispatcher path so callback delivery is durable and multi-node safe in design.
- Tightened callback payloads to a thin versioned envelope with `callback_id`, `event`, `workflow_id`, `semantics_version`, and `occurred_at`.
- Brought runtime, installer, test-support, and example-host schema definitions into parity for callback delivery fields.

## Task Commits

This plan was finished from an already-dirty working tree, so atomic task commits were not created during this execution pass.

## Files Created/Modified
- `lib/oban_powertools/workflow/runtime.ex` - callback claim path, envelope shaping, and lease expiry handling
- `lib/oban_powertools/workflow/callback_outbox.ex` - claimed-row schema fields and event validation
- `lib/mix/tasks/oban_powertools.install.ex` - generated migration contract for callback lease fields
- `test/support/migrations/2_phase_3_tables.exs` - fresh test schema contract for callback delivery
- `examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs` - supported host callback schema parity
- `examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs` - archived upgrade-source schema parity
- `test/oban_powertools/workflow_runtime_test.exs` - proof for retry, lease ownership, and envelope shape

## Decisions Made
- Used durable row claims with lease expiry instead of trying to infer dispatcher ownership from in-memory iteration.
- Preserved at-least-once semantics and kept failure evidence on the outbox row instead of widening the callback surface.

## Deviations from Plan

### Auto-fixed Issues

**1. Pre-existing implementation overlap**
- **Found during:** Plan execution bootstrap
- **Issue:** The working tree already contained substantial uncommitted Phase 18 work across runtime, tests, and migrations.
- **Fix:** Finished the missing lease-safe claim behavior in place and verified it with focused ExUnit instead of discarding or rewriting the in-progress implementation.
- **Files modified:** `lib/oban_powertools/workflow/runtime.ex`, `lib/oban_powertools/workflow/callback_outbox.ex`, `test/oban_powertools/workflow_runtime_test.exs`
- **Verification:** `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/explain_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/workflows_live_test.exs`

## Issues Encountered

- The callback delivery loop was still a plain fetch-and-iterate path despite earlier Phase 18 scaffolding, so this execution pass closed the missing claim semantics before verification.

## User Setup Required

None - hosts continue to provide one `workflow_callback_handler` implementation, now with explicit idempotency guidance.

## Next Phase Readiness

- `18-02` can build grouped recovery-session headers on top of the hardened callback obligation model.
- `18-03` can now treat callback support truth as proven code instead of a planned future seam.

---
*Phase: 18-durable-callback-outbox-recovery-attempts*
*Completed: 2026-05-24*

## Self-Check: PASSED

- Thin callback envelopes are limited to `workflow.terminal` and `workflow.recovery_completed`
- Claimed rows are lease-protected and retry safely after expiry
- Runtime, repo migrations, and supported-host example migrations expose the same callback delivery fields
