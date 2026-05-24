---
phase: 21-workflow-diagnosis-projection-native-workflow-surface
plan: 02
subsystem: ui
tags: [phoenix, liveview, workflow, explainability, routing]
requires:
  - phase: 21-workflow-diagnosis-projection-native-workflow-surface
    provides: shared workflow and step diagnosis projection with durable evidence
provides:
  - server-owned primary workflow diagnosis step selection
  - patch-preserving workflow detail routing backed by shared projector semantics
  - explicit unsupported and refusal rendering in the native workflow detail path
affects: [Phase-21-native-workflow-surface, Phase-22-recovery-actions, DIA-01, DIA-02, VER-01]
tech-stack:
  added: []
  patterns:
    - LiveView renders projector-owned diagnosis data instead of raw branch-specific copy
    - workflow detail routing remains shareable while the server names the canonical diagnosis anchor
key-files:
  created:
    - .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-02-SUMMARY.md
  modified:
    - lib/oban_powertools/explain.ex
    - lib/oban_powertools/web/workflows_live.ex
    - test/oban_powertools/explain_test.exs
    - test/oban_powertools/web/live/workflows_live_test.exs
key-decisions:
  - "Keep `WorkflowsLive` thin by assigning workflow and step stories directly from `Explain`."
  - "Render durable refusal and semantics posture in the native workflow screen instead of falling back to generic labels."
patterns-established:
  - "Primary diagnosis selection belongs to the shared projector and server routing layer, not display order."
  - "Unsupported workflow states stay explicit and read-only in the native detail path."
requirements-completed: [DIA-01, DIA-02, VER-01]
duration: verification and closure pass
completed: 2026-05-24
---

# Phase 21 Plan 02 Summary

**The native workflow detail path now defaults to shared diagnosis semantics, preserves patch-driven inspection, and surfaces refusal and unsupported-state evidence explicitly.**

## Performance

- **Duration:** verification and closure pass
- **Started:** 2026-05-24T18:07:00Z
- **Completed:** 2026-05-24T18:10:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Reworked `WorkflowsLive` to assign and render shared workflow and step stories instead of calling runtime helpers ad hoc in templates.
- Preserved patch-based step inspection while letting the server choose the canonical diagnosis step and explanation context.
- Verified refusal, semantics, callback, and recovery details render through the native workflow LiveView.

## Task Commits

This plan was closed from an already-dirty working tree, so atomic task commits were not created during this execution pass.

## Files Created/Modified
- `lib/oban_powertools/explain.ex` - projector fields consumed by the native workflow detail path
- `lib/oban_powertools/web/workflows_live.ex` - diagnosis-first workflow assignments and explicit refusal/detail rendering
- `test/oban_powertools/explain_test.exs` - projector proof for shared diagnosis data
- `test/oban_powertools/web/live/workflows_live_test.exs` - LiveView proof for refusal, semantics, callback posture, and shareable step inspection

## Decisions Made
- Used the already-implemented projector output as the single explanation seam for the native workflow page.
- Kept the phase read-only by rendering legal-next-step context as information rather than executable controls.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The phase files already contained substantial in-progress changes, so the closure pass focused on proof and artifact completion rather than incremental code edits.

## User Setup Required

None - the workflow detail changes remain internal to the native operator surface and its tests.

## Next Phase Readiness

- Plan 03 can reshape the full workflow screen and Lifeline parity on top of a verified shared detail seam.
- Phase 22 can map future bounded actions onto refusal and legal-next-step evidence already visible in the operator UI.

---
*Phase: 21-workflow-diagnosis-projection-native-workflow-surface*
*Completed: 2026-05-24*

## Self-Check: PASSED

- `WorkflowsLive` consumes shared projector semantics instead of recomputing diagnosis copy
- Patch-driven workflow step inspection remains intact
- Unsupported and refusal-oriented workflow states remain explicit and support-truthful
