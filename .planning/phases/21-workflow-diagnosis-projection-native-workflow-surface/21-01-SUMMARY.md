---
phase: 21-workflow-diagnosis-projection-native-workflow-surface
plan: 01
subsystem: workflow-runtime
tags: [ecto, postgres, workflow, explainability, runtime]
requires:
  - phase: 20-cancellation-late-completion-expiry-semantics
    provides: terminal-truth-first cancellation, expiry, and late-arrival semantics
provides:
  - shared workflow and step diagnosis projection rooted in durable runtime truth
  - terminal-truth-first diagnosis precedence for workflow and step read models
  - explicit durable refusal and recovery evidence for downstream operator surfaces
affects: [Phase-21-native-workflow-surface, Phase-22-recovery-actions, DIA-01, VER-01]
tech-stack:
  added: []
  patterns:
    - runtime owns diagnosis precedence and unsupported-state posture
    - projector-owned explanation data is shared across operator surfaces
key-files:
  created:
    - .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-01-SUMMARY.md
  modified:
    - lib/oban_powertools/workflow/runtime.ex
    - lib/oban_powertools/explain.ex
    - test/oban_powertools/workflow_runtime_test.exs
    - test/oban_powertools/explain_test.exs
key-decisions:
  - "Keep diagnosis ordering in `Runtime` so UI layers consume durable truth instead of inventing precedence."
  - "Expand `Explain` into the shared read-model seam for diagnosis, rejection, callback, and recovery evidence."
patterns-established:
  - "Terminal truth outranks stale request evidence once durable reconciliation settles."
  - "Allowed next action guidance comes from durable refusal evidence, not optimistic UI copy."
requirements-completed: [DIA-01, VER-01]
duration: verification and closure pass
completed: 2026-05-24
---

# Phase 21 Plan 01 Summary

**Phase 21 now has a shared diagnosis projector backed by runtime-owned precedence, durable refusal evidence, callback posture, and recovery-session context.**

## Performance

- **Duration:** verification and closure pass
- **Started:** 2026-05-24T18:07:00Z
- **Completed:** 2026-05-24T18:10:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Expanded `ObanPowertools.Explain` so workflow and step stories carry diagnosis plus bounded durable evidence instead of thin metadata.
- Corrected runtime diagnosis precedence so terminal outcomes such as `completed_after_cancel_request` and `expired_wait` outrank stale request hints.
- Verified explicit refusal and unsupported-state posture through focused runtime and explain tests.

## Task Commits

This plan was closed from an already-dirty working tree, so atomic task commits were not created during this execution pass.

## Files Created/Modified
- `lib/oban_powertools/workflow/runtime.ex` - durable diagnosis ordering, refusal handling, and explicit unsupported behavior
- `lib/oban_powertools/explain.ex` - shared workflow and step diagnosis projector with rejection, callback, and recovery summaries
- `test/oban_powertools/workflow_runtime_test.exs` - terminal-truth, refusal-evidence, signal, and recovery proof coverage
- `test/oban_powertools/explain_test.exs` - projector coverage for diagnosis-first workflow and step explanation

## Decisions Made
- Closed the plan from verification evidence already present in the worktree instead of inventing missing commit metadata.
- Kept projector semantics bounded to durable facts so later UI work can render them without branching copy logic.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The repo was already dirty in the target files, so execution was treated as a continuation and verified against the existing implementation before artifact closure.

## User Setup Required

None - this plan only changes runtime and projector behavior plus automated proof coverage.

## Next Phase Readiness

- Phase 21 plan 02 can rely on one projector-owned diagnosis vocabulary instead of recomputing meaning in LiveView.
- Phase 22 now has durable refusal and legal-next-step evidence available for bounded action guidance.

---
*Phase: 21-workflow-diagnosis-projection-native-workflow-surface*
*Completed: 2026-05-24*

## Self-Check: PASSED

- Runtime and projector tests prove terminal-truth-first diagnosis ordering
- Shared explanation output includes bounded rejection, callback, and recovery evidence
- Unsupported and rejected paths remain explicit instead of being smoothed over
