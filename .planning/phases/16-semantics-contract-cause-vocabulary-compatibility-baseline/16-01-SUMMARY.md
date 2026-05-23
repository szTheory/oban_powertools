---
phase: 16-semantics-contract-cause-vocabulary-compatibility-baseline
plan: 01
subsystem: workflow
tags: [workflow, semantics, compatibility, diagnosis, lifeline]
requires:
  - phase: 11-docs-example-app-compatibility-contract-proof
    provides: native workflow inspection surface and public support-truth discipline
provides:
  - explicit v2 workflow lifecycle and terminal-cause contract
  - additive compatibility posture for pre-v1.2 workflow rows
  - shared diagnosis vocabulary across runtime, workflows UI, and Lifeline
affects: [workflow-recovery, signal-await, cancellation, operator-diagnosis]
tech-stack:
  added: []
  patterns: [repo-local lifecycle contract API, additive semantics compatibility, shared diagnosis vocabulary]
key-files:
  created: [.planning/phases/16-semantics-contract-cause-vocabulary-compatibility-baseline/16-01-SUMMARY.md]
  modified: [lib/oban_powertools/workflow/runtime.ex, lib/oban_powertools/workflow.ex, lib/oban_powertools/workflow/workflow.ex, lib/oban_powertools/workflow/step.ex, lib/oban_powertools/lifeline.ex, lib/oban_powertools/web/workflows_live.ex, .planning/PROJECT.md, .planning/REQUIREMENTS.md, test/oban_powertools/workflow_runtime_test.exs]
key-decisions:
  - "Treat semantics version 2 as the only current lifecycle contract and expose it through a repo-local runtime API."
  - "Keep pre-v1.2 rows on an explicit compatibility path until a v2 transition rewrites durable meaning."
  - "Reuse runtime diagnosis helpers in both workflow and Lifeline surfaces instead of maintaining parallel wording."
patterns-established:
  - "Workflow semantics are described by runtime-owned contract helpers rather than inferred ad hoc from row state."
  - "Historical workflow rows keep stored meaning until a newer semantics transition persists replacement facts."
requirements-completed: [WFS-01, WFS-03]
duration: 3min
completed: 2026-05-23
---

# Phase 16 Plan 01: Semantics Contract, Cause Vocabulary & Compatibility Baseline Summary

**A repo-local v2 lifecycle contract now defines workflow and step terminal-cause meaning, preserves explicit compatibility handling for historical rows, and drives the same diagnosis vocabulary in native workflow and Lifeline surfaces**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-23T20:45:52Z
- **Completed:** 2026-05-23T20:47:35Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added an explicit runtime lifecycle contract API covering workflow states, step states, terminal causes, semantics version `2`, and the legacy compatibility posture.
- Locked the pre-v1.2 support posture in repo docs so historical rows are handled additively instead of being silently reinterpreted under v1.2 semantics.
- Kept workflow diagnosis wording consistent across runtime, the native workflows LiveView, and Lifeline incident projection.

## Task Commits

Each task was committed atomically where the underlying diff could be isolated safely:

1. **Task 1: Freeze the lifecycle and terminal-cause vocabulary in one repo-local contract** - `ec625df` (feat)
2. **Task 2: Define the pre-v1.2 compatibility posture and legal interpretation boundaries** - `29b29f0` (docs)
3. **Task 3: Align diagnosis-facing surfaces to the frozen Phase 16 vocabulary** - `ec625df` (feat)

## Files Created/Modified

- `lib/oban_powertools/workflow/runtime.ex` - explicit lifecycle contract, compatibility policy, semantics profile helpers, and durable diagnosis interpretation
- `lib/oban_powertools/workflow.ex` - public workflow API entrypoints for the expanded runtime contract
- `lib/oban_powertools/workflow/workflow.ex` - workflow row fields for semantics version and terminal-cause truth
- `lib/oban_powertools/workflow/step.ex` - step row fields for terminal cause, wait identity, and cancel/transition timing
- `lib/oban_powertools/lifeline.ex` - workflow-stuck incident summaries now reuse runtime diagnosis vocabulary
- `lib/oban_powertools/web/workflows_live.ex` - native workflow inspection shows runtime-owned diagnosis wording
- `.planning/PROJECT.md` - active milestone framing now states the v2 lifecycle and compatibility baseline explicitly
- `.planning/REQUIREMENTS.md` - v1.2 baseline section and traceability rows for the semantics baseline
- `test/oban_powertools/workflow_runtime_test.exs` - lifecycle contract and compatibility posture coverage

## Decisions Made

- Exposed the lifecycle contract through `ObanPowertools.Workflow.Runtime` so future recovery/signal work can consume one stable source of truth.
- Documented legacy handling as a compatibility path rather than an upgrade-in-place reinterpretation policy.
- Reused the same runtime diagnosis helpers for workflow UI and Lifeline evidence instead of duplicating cause vocabulary in multiple surfaces.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Correctness] Kept Task 1 and Task 3 in one commit**
- **Found during:** Task 3 (diagnosis-facing surface alignment)
- **Issue:** The UI/Lifeline diagnosis changes were already coupled to the runtime semantics refactor in the same in-progress diff, so splitting them into a second code commit would have created an artificial partial state.
- **Fix:** Kept the runtime contract and diagnosis-surface alignment together in `ec625df`, then isolated the compatibility docs in a separate commit.
- **Files modified:** `lib/oban_powertools/workflow/runtime.ex`, `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/web/workflows_live.ex`
- **Verification:** `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/lifeline_test.exs`
- **Committed in:** `ec625df`

---

**Total deviations:** 1 auto-fixed (correctness/workflow hygiene)
**Impact on plan:** No scope increase. The commit boundary changed, but the phase still landed the same contract with green verification.

## Issues Encountered

- Parallel git commit attempts raced on `.git/index.lock`; the stale lock was removed after confirming no other git process was active, and the remaining docs commit was retried sequentially.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later v1.2 phases can build callback, recovery, await, and cancellation behavior against one explicit semantics vocabulary.
- Historical-row handling now has a written baseline, but upgrade-proof fixtures and unsupported mutation boundaries still belong to later verification-focused phases.

## Self-Check

PASSED - `mix compile`, targeted workflow/Lifeline/UI tests, and the contract grep checks all pass; commit hashes `ec625df` and `29b29f0` are present in git history.

---
*Phase: 16-semantics-contract-cause-vocabulary-compatibility-baseline*
*Completed: 2026-05-23*
