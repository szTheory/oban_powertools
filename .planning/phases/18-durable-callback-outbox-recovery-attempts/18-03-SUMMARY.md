---
phase: 18-durable-callback-outbox-recovery-attempts
plan: 03
subsystem: testing
tags: [requirements, docs, tests, workflow, support-truth]
requires:
  - phase: 18-durable-callback-outbox-recovery-attempts
    provides: hardened callback outbox and grouped recovery session model
provides:
  - focused proof for callback retry and recovery-session identity
  - aligned support-truth language for the host callback seam
  - updated phase requirements posture for REC-01 and POL-04
affects: [phase-18-verification, REC-01, POL-04, VER-02]
tech-stack:
  added: []
  patterns:
    - support-truth claims move only when the repo proves them
    - phase summaries and verification must call out dirty-worktree execution deviations explicitly
key-files:
  created: []
  modified:
    - test/oban_powertools/workflow_runtime_test.exs
    - test/oban_powertools/explain_test.exs
    - test/oban_powertools/web/live/workflows_live_test.exs
    - lib/oban_powertools/runtime_config.ex
    - lib/oban_powertools/workflow/callback_handler.ex
    - .planning/PROJECT.md
    - .planning/REQUIREMENTS.md
key-decisions:
  - "Update planning truth only for semantics now covered by code and tests."
  - "Document the host seam as a narrow, idempotent, at-least-once callback contract rather than a generic event platform."
patterns-established:
  - "Workflow proof and support language close together when a durable contract lands."
requirements-completed: [REC-01, POL-04, VER-02]
duration: in-progress working tree
completed: 2026-05-24
---

# Phase 18 Plan 03 Summary

**Focused callback and recovery proof plus planning-truth alignment for the narrow two-event, post-commit, at-least-once workflow callback contract.**

## Performance

- **Duration:** in-progress working tree plus closure pass
- **Started:** 2026-05-24T11:03:27Z
- **Completed:** 2026-05-24T12:04:27Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Expanded the focused ExUnit proof bundle to cover callback envelope identity, claim behavior, lease protection, and grouped recovery-session linkage.
- Tightened host-facing callback guidance in `RuntimeConfig` and `Workflow.CallbackHandler` so it matches the actual runtime guarantees.
- Updated planning truth to mark `REC-01` and `POL-04` complete while leaving the await/signal requirements active.

## Task Commits

This plan was finished from an already-dirty working tree, so atomic task commits were not created during this execution pass.

## Files Created/Modified
- `test/oban_powertools/workflow_runtime_test.exs` - callback lease and recovery-session proof
- `test/oban_powertools/explain_test.exs` - read-model proof for callback posture and latest session identity
- `test/oban_powertools/web/live/workflows_live_test.exs` - UI proof for diagnosis rendering
- `lib/oban_powertools/runtime_config.ex` - explicit idempotent at-least-once handler contract
- `lib/oban_powertools/workflow/callback_handler.ex` - narrow two-event host callback behavior docs
- `.planning/PROJECT.md` - milestone posture updated for Phase 18 callback and recovery contract
- `.planning/REQUIREMENTS.md` - `REC-01` and `POL-04` marked complete and mapped to Phase 18

## Decisions Made
- Closed only the requirement claims now backed by the repo; `SIG-01`, `SIG-02`, and `SIG-03` remain open.
- Kept the public callback seam narrow and idempotent instead of implying exactly-once or generic event-bus semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. Planning truth lagged behind implementation**
- **Found during:** closure and verification pass
- **Issue:** `.planning/PROJECT.md` and `.planning/REQUIREMENTS.md` still described callback guarantees as unfinished even after the runtime and tests covered them.
- **Fix:** Updated the planning artifacts to match the proven contract while leaving unrelated await/signal requirements open.
- **Files modified:** `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`
- **Verification:** focused proof bundle plus contract grep checks

## Issues Encountered

- None beyond closing the planning-truth lag left by the pre-existing in-progress worktree.

## User Setup Required

None - hosts keep one callback handler seam, now with explicit idempotency guidance.

## Next Phase Readiness

- Phase 18 now has a coherent callback/recovery support story for verification.
- The remaining v1.2 workflow work can focus on await, signal, and expiry semantics without callback ambiguity.

---
*Phase: 18-durable-callback-outbox-recovery-attempts*
*Completed: 2026-05-24*

## Self-Check: PASSED

- Focused proof covers callback retry, lease protection, recovery-session linkage, explain output, and workflow-screen rendering
- Host-facing callback guidance matches the runtime’s narrow, post-commit, at-least-once behavior
- Planning truth now reflects the proven Phase 18 callback and recovery contract
