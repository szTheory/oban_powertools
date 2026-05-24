---
phase: 21-workflow-diagnosis-projection-native-workflow-surface
plan: 03
subsystem: operator-surfaces
tags: [phoenix, liveview, workflow, lifeline, explainability]
requires:
  - phase: 21-workflow-diagnosis-projection-native-workflow-surface
    provides: shared workflow diagnosis projector and native detail routing
provides:
  - diagnosis-first native workflow rendering with durable evidence and guidance posture
  - Lifeline workflow-stuck evidence aligned to the shared projector vocabulary
  - full targeted proof bundle for workflow and Lifeline explanation parity
affects: [Phase-22-recovery-actions, Phase-23-proof-closure, DIA-01, DIA-02, VER-01, VER-02]
tech-stack:
  added: []
  patterns:
    - workflow and Lifeline surfaces share one diagnosis vocabulary and evidence posture
    - read-only workflow guidance precedes future bounded action controls
key-files:
  created:
    - .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-03-SUMMARY.md
  modified:
    - lib/oban_powertools/explain.ex
    - lib/oban_powertools/lifeline.ex
    - lib/oban_powertools/web/workflows_live.ex
    - test/oban_powertools/explain_test.exs
    - test/oban_powertools/lifeline_test.exs
    - test/oban_powertools/web/live/lifeline_live_test.exs
    - test/oban_powertools/web/live/workflows_live_test.exs
key-decisions:
  - "Align Lifeline workflow-stuck evidence to `Explain.step_story/2` instead of carrying bespoke diagnosis wording."
  - "Close the phase from a green targeted proof bundle rather than fabricating clean-worktree execution metadata."
patterns-established:
  - "Diagnosis-first workflow rendering is layered: summary first, evidence second, raw facts lower."
  - "Neighboring operator surfaces should reuse projector-owned vocabulary for the same durable workflow facts."
requirements-completed: [DIA-01, DIA-02, VER-01, VER-02]
duration: verification and closure pass
completed: 2026-05-24
---

# Phase 21 Plan 03 Summary

**Workflow and Lifeline now speak the same diagnosis language, and the native workflow surface presents durable cause and evidence before raw internals.**

## Performance

- **Duration:** verification and closure pass
- **Started:** 2026-05-24T18:07:00Z
- **Completed:** 2026-05-24T18:10:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Verified the diagnosis-first workflow surface renders shared story data, refusal context, callback posture, and recovery-session evidence.
- Aligned Lifeline workflow-stuck incidents and repair previews to the shared diagnosis projector instead of bespoke step-only wording.
- Closed the full targeted Phase 21 proof bundle across explain, runtime, Lifeline, and both LiveView surfaces.

## Task Commits

This plan was closed from an already-dirty working tree, so atomic task commits were not created during this execution pass.

## Files Created/Modified
- `lib/oban_powertools/explain.ex` - shared wording and evidence fields reused by workflow and Lifeline surfaces
- `lib/oban_powertools/lifeline.ex` - workflow-stuck incident and preview evidence aligned to shared step stories
- `lib/oban_powertools/web/workflows_live.ex` - diagnosis-first workflow rendering over shared story assignments
- `test/oban_powertools/explain_test.exs` - shared projector parity coverage
- `test/oban_powertools/lifeline_test.exs` - workflow-stuck evidence and repair metadata coverage
- `test/oban_powertools/web/live/lifeline_live_test.exs` - neighboring-surface parity proof
- `test/oban_powertools/web/live/workflows_live_test.exs` - diagnosis-first workflow rendering proof

## Decisions Made
- Used the green targeted proof bundle as the source of truth for closure because the target files were already modified before this run.
- Kept workflow guidance informational-only so Phase 21 does not pull Phase 22 mutation semantics forward.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- None beyond dirty-worktree continuation handling; all targeted suites passed without requiring follow-up edits in this closure pass.

## User Setup Required

None - the phase remains read-only and fully covered by the existing targeted test harnesses.

## Next Phase Readiness

- Phase 22 can attach bounded, audited workflow actions to an already-aligned diagnosis vocabulary across workflow and Lifeline surfaces.
- Phase 23 can treat Phase 21’s explanation posture as the stable proof and docs seam for the milestone closeout.

---
*Phase: 21-workflow-diagnosis-projection-native-workflow-surface*
*Completed: 2026-05-24*

## Self-Check: PASSED

- Workflow and Lifeline surfaces share one durable diagnosis vocabulary
- The native workflow surface answers cause and evidence before raw internals
- The full targeted Phase 21 proof bundle passed in this execution run
