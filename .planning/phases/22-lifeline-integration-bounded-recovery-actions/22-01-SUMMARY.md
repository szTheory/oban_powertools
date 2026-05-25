---
phase: 22-lifeline-integration-bounded-recovery-actions
plan: 01
subsystem: workflow-runtime
tags: [workflow, lifeline, runtime, explainability, recovery]
requires:
  - phase: 21-workflow-diagnosis-projection-native-workflow-surface
    provides: shared workflow and step diagnosis projection with durable evidence
provides:
  - runtime-owned executable workflow action projection for bounded recovery
  - shared workflow and step stories that expose normalized executable actions
  - workflow-facing Lifeline routing that preserves cooperative cancel semantics
affects: [Phase-22-lifeline-handoff, DIA-02, WFS-02, REC-03]
tech-stack:
  added: []
  patterns:
    - legality stays in runtime truth and is only rendered by downstream surfaces
    - cooperative workflow cancel remains request evidence, not an immediate-stop promise
key-files:
  created:
    - .planning/phases/22-lifeline-integration-bounded-recovery-actions/22-01-SUMMARY.md
  modified:
    - lib/oban_powertools/workflow/runtime.ex
    - lib/oban_powertools/explain.ex
    - lib/oban_powertools/lifeline.ex
    - test/oban_powertools/explain_test.exs
    - test/oban_powertools/lifeline_test.exs
key-decisions:
  - "Project executable actions from `Workflow.Runtime` and `Explain` instead of inferring legality from Lifeline incident rows."
  - "Route workflow-level cancel through the existing workflow facade while keeping request-versus-outcome evidence explicit."
patterns-established:
  - "Workflow and step stories expose one bounded executable vocabulary: retry step, cancel step, request workflow cancel."
  - "Lifeline can call workflow actions without becoming the legality source."
requirements-completed: [DIA-02, WFS-02, REC-03]
duration: implementation, verification, and closure pass
completed: 2026-05-25
---

# Phase 22 Plan 01 Summary

**Phase 22 now has a runtime-owned executable action contract for workflow recovery, with cooperative cancel routing preserved through the workflow command facade.**

## Performance

- **Duration:** implementation, verification, and closure pass
- **Started:** 2026-05-25T04:00:00Z
- **Completed:** 2026-05-25T04:23:45Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added normalized executable action projection in `Workflow.Runtime` so workflow and step stories expose `workflow_step_retry`, `workflow_step_cancel`, and `workflow_request_cancel` from durable truth.
- Extended `Explain` so downstream surfaces can consume executable actions directly without recomputing legality.
- Updated Lifeline’s backend adapter to support workflow-level cancel through the workflow facade while keeping request evidence distinct from eventual workflow outcome.

## Task Commits

This plan was executed from an already-dirty working tree, so atomic task commits were not created during this run.

## Files Created/Modified

- `lib/oban_powertools/workflow/runtime.ex` - runtime-owned executable action projection and legality helpers
- `lib/oban_powertools/explain.ex` - workflow and step stories now include executable actions
- `lib/oban_powertools/lifeline.ex` - workflow action routing and cooperative cancel preview/execute support
- `test/oban_powertools/explain_test.exs` - workflow and step story action projection proof
- `test/oban_powertools/lifeline_test.exs` - workflow-directed cancel preview and execute coverage

## Decisions Made

- Kept the executable-action vocabulary frozen to the three bounded Phase 22 actions instead of exposing deferred or UI-invented controls.
- Reused the existing workflow facade rather than introducing a Lifeline-side mutation path for workflow cancel.

## Deviations from Plan

- `lib/oban_powertools/workflow.ex` did not require new edits during this run because the existing facade already provided the needed `request_cancel/3` entry point.

## Issues Encountered

- The repo already contained unrelated and in-progress changes, including files in this phase, so completion was handled as a continuation and verified against the resulting behavior.

## User Setup Required

None.

## Next Phase Readiness

- Plan 02 can build a workflow-directed Lifeline preview flow on top of the shared executable-action contract.
- Plan 03 can add a diagnosis-first workflow-to-Lifeline handoff without inventing any new legality logic in the UI.

---
*Phase: 22-lifeline-integration-bounded-recovery-actions*
*Completed: 2026-05-25*

## Self-Check: PASSED

- Runtime owns bounded workflow action legality
- Shared workflow and step stories expose the executable vocabulary directly
- Cooperative cancel remains request-evidence-first through the workflow command path
