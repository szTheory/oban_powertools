---
phase: 22-lifeline-integration-bounded-recovery-actions
plan: 02
subsystem: lifeline
tags: [lifeline, liveview, workflow, preview, audit]
requires:
  - phase: 22-lifeline-integration-bounded-recovery-actions
    provides: runtime-owned executable workflow action projection and routing
provides:
  - workflow-directed Lifeline preview and execute flow without incident ownership
  - canonical preview lifecycle reuse for workflow-native actions
  - param-driven Lifeline selection for workflow, step, and action context
affects: [Phase-22-lifeline-handoff, DIA-02, VER-01, POL-04]
tech-stack:
  added: []
  patterns:
    - one preview envelope serves incident-backed and workflow-directed actions
    - canonical preview status remains ready, drifted, expired, consumed everywhere
key-files:
  created:
    - .planning/phases/22-lifeline-integration-bounded-recovery-actions/22-02-SUMMARY.md
  modified:
    - lib/oban_powertools/lifeline.ex
    - lib/oban_powertools/web/lifeline_live.ex
    - test/oban_powertools/lifeline_test.exs
    - test/oban_powertools/web/live/lifeline_live_test.exs
key-decisions:
  - "Represent workflow-directed handoff rows as synthetic Lifeline rows backed by workflow truth instead of requiring an active incident row."
  - "Remove remaining LiveView assumptions that executable previews use a legacy `pending` status."
patterns-established:
  - "Workflow-directed actions enter Lifeline through shareable URL params and server-owned selection state."
  - "Workflow-native copy can stay diagnosis-first while reusing the same durable preview token lifecycle."
requirements-completed: [DIA-02, VER-01, POL-04]
duration: implementation, verification, and closure pass
completed: 2026-05-25
---

# Phase 22 Plan 02 Summary

**Lifeline can now review, preview, and execute workflow-directed bounded actions even when no active incident row exists, while keeping the existing preview lifecycle intact.**

## Performance

- **Duration:** implementation, verification, and closure pass
- **Started:** 2026-05-25T04:00:00Z
- **Completed:** 2026-05-25T04:23:45Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Extended `Lifeline` to build workflow-native previews and executions, including cooperative workflow cancel, through the shared durable preview model.
- Added param-driven workflow handoff support in `LifelineLive`, including synthetic workflow-directed rows that are reviewable without incident ownership.
- Normalized preview lookup, status copy, remount behavior, and execute gating to the canonical `ready` / `drifted` / `expired` / `consumed` contract.

## Task Commits

This plan was executed from an already-dirty working tree, so atomic task commits were not created during this run.

## Files Created/Modified

- `lib/oban_powertools/lifeline.ex` - workflow-directed preview and execute support with workflow-native copy
- `lib/oban_powertools/web/lifeline_live.ex` - shareable workflow selection params, synthetic handoff rows, and canonical preview-state handling
- `test/oban_powertools/lifeline_test.exs` - workflow-level request-cancel preview and execution proof
- `test/oban_powertools/web/live/lifeline_live_test.exs` - workflow-directed Lifeline entry, preview, and status-contract proof

## Decisions Made

- Kept the workflow-directed path inside the existing Lifeline preview table and token lifecycle rather than introducing a second preview system.
- Made workflow-specific wording explicit in preview and handoff copy so request cancel does not read like an immediate repair action.

## Deviations from Plan

- `lib/oban_powertools/lifeline/repair_preview.ex` did not need direct edits because the canonical lifecycle contract already existed; the work was in callers that still assumed legacy status wording.

## Issues Encountered

- Initial LiveView tests clicked the first preview button on the page and produced false failures once multiple workflow rows existed; the tests were tightened to target the exact workflow-directed row id.

## User Setup Required

None.

## Next Phase Readiness

- Plan 03 can link the workflow page directly into Lifeline using a stable, refresh-safe param contract.
- Cross-surface parity can now be verified against one shared preview lifecycle instead of separate workflow and Lifeline semantics.

---
*Phase: 22-lifeline-integration-bounded-recovery-actions*
*Completed: 2026-05-25*

## Self-Check: PASSED

- Workflow-directed actions are reviewable in Lifeline without incident ownership
- Canonical preview status handling is consistent across selection, remount, and execute paths
- Workflow-native copy remains diagnosis-first and support-truthful
