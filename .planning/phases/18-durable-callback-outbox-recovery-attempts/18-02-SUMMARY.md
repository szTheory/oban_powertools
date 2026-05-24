---
phase: 18-durable-callback-outbox-recovery-attempts
plan: 02
subsystem: workflow
tags: [ecto, workflow, recovery, liveview, diagnosis]
requires:
  - phase: 18-durable-callback-outbox-recovery-attempts
    provides: hardened callback outbox and narrow workflow callback contract
provides:
  - workflow-scoped recovery session headers
  - append-only recovery attempts linked to grouped recovery intent
  - diagnosis seams for callback posture and latest recovery session identity
affects: [18-03-proof-and-support-truth, REC-02, DIA-02]
tech-stack:
  added: []
  patterns:
    - recovery stays step-oriented at the public API while grouping is modeled in durable storage
    - operator diagnosis reads callback posture and recovery sessions without conflating them with workflow truth
key-files:
  created:
    - lib/oban_powertools/workflow/recovery_session.ex
    - test/support/migrations/5_phase_6_tables.exs
  modified:
    - lib/oban_powertools/workflow/recovery_attempt.ex
    - lib/oban_powertools/workflow/workflow.ex
    - lib/oban_powertools/workflow.ex
    - lib/oban_powertools/workflow/runtime.ex
    - lib/oban_powertools/explain.ex
    - lib/oban_powertools/web/workflows_live.ex
    - test/test_helper.exs
    - test/oban_powertools/explain_test.exs
    - test/oban_powertools/web/live/workflows_live_test.exs
key-decisions:
  - "Create one durable recovery session per grouped recovery intent while keeping `Workflow.recover_step/5` as the paved-road API."
  - "Expose callback posture and latest recovery session through explain/read-model seams instead of building a new Phase 18 operator surface."
patterns-established:
  - "Attach append-only recovery attempts to a workflow-scoped session header."
  - "Render callback delivery posture separately from workflow terminal truth."
requirements-completed: [REC-02]
duration: in-progress working tree
completed: 2026-05-24
---

# Phase 18 Plan 02 Summary

**Workflow-scoped recovery-session headers linked to append-only step recovery attempts, with diagnosis seams that expose callback posture separately from workflow terminal truth.**

## Performance

- **Duration:** in-progress working tree plus closure pass
- **Started:** 2026-05-24T11:03:27Z
- **Completed:** 2026-05-24T12:04:27Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Added durable `RecoverySession` rows and linked `RecoveryAttempt` records to a workflow-scoped header without widening the public recovery API.
- Extended explain/read-model output with callback posture and latest recovery session identity.
- Surfaced the new diagnosis seam on the native workflow screen without building a broader callback or recovery UI.

## Task Commits

This plan was finished from an already-dirty working tree, so atomic task commits were not created during this execution pass.

## Files Created/Modified
- `lib/oban_powertools/workflow/recovery_session.ex` - workflow-scoped recovery session schema
- `lib/oban_powertools/workflow/recovery_attempt.ex` - link from step recovery attempt to session header
- `lib/oban_powertools/workflow/runtime.ex` - session creation during `recover_step/5`
- `lib/oban_powertools/explain.ex` - callback posture and latest recovery session read model
- `lib/oban_powertools/web/workflows_live.ex` - workflow diagnosis rendering for callback posture and latest session ID
- `test/support/migrations/5_phase_6_tables.exs` - additive local migration for already-migrated test databases
- `test/test_helper.exs` - local migration bootstrap for Phase 18 additive schema
- `test/oban_powertools/explain_test.exs` - explain proof for callback posture and recovery sessions
- `test/oban_powertools/web/live/workflows_live_test.exs` - workflow screen proof for the new diagnosis seam

## Decisions Made
- Chose durable recovery-session headers over metadata-only grouping so future diagnosis and operator flows can reference a stable recovery identity.
- Kept grouping additive: step recovery truth still lives in `RecoveryAttempt`, and successful work is still rejected durably when the public API tries to replay it.

## Deviations from Plan

None beyond executing against a partially implemented working tree and recording the grouped recovery model directly into that state.

## Issues Encountered

- The existing Phase 18 code had recovery attempts but no workflow-level session header, so diagnosis would have had to infer grouping from timing. This pass removed that ambiguity.

## User Setup Required

None - the host callback seam is unchanged and recovery grouping is internal to Powertools.

## Next Phase Readiness

- `18-03` can now close proof and support-truth language around a real durable recovery-session model.
- Later workflow/Lifeline phases have a stable recovery identity to reference without adding a generic redrive API.

---
*Phase: 18-durable-callback-outbox-recovery-attempts*
*Completed: 2026-05-24*

## Self-Check: PASSED

- Recovery attempts are linked to workflow-scoped recovery sessions
- `Workflow.recover_step/5` remains the public step-oriented API
- Workflow diagnosis exposes callback posture and latest recovery session separately from workflow terminal truth
