---
phase: 4
plan: 03
subsystem: api
tags: [repair, preview, audit, drift, ecto-multi]
requires:
  - phase: 4
    provides: incident evidence and heartbeat classification
provides:
  - durable repair preview generation
  - drift-aware repair execution
  - immutable audit writes for manual repairs
affects: [lifeline-ui, audit-ui]
tech-stack:
  added: []
  patterns: [preview-before-execute, single-use preview token, transactional audit writes]
key-files:
  created: []
  modified:
    - lib/oban_powertools/lifeline.ex
    - test/oban_powertools/lifeline_test.exs
key-decisions:
  - "Repair preview and execute authorization stay separate."
  - "Execute rechecks plan hash drift and consumes previews once."
patterns-established:
  - "Manual mutation, preview consumption, and audit insert happen in one transaction."
requirements-completed: [LIF-02, LIF-03]
duration: checkpoint
completed: 2026-05-19
---

# Phase 4 Plan 03 Summary

**Durable repair preview generation with drift-aware execution, reason validation, and immutable audit evidence for job and workflow-step actions**

## Accomplishments
- Added repair preview generation for narrow Phase 4 actions on jobs and workflow steps.
- Added execute paths that reject stale previews, require meaningful reasons, and consume previews once.
- Added immutable audit writes capturing preview token, fingerprint, plan hash, reason, and affected counts.

## Files Created/Modified
- `lib/oban_powertools/lifeline.ex` - repair preview and execute logic
- `test/oban_powertools/lifeline_test.exs` - drift, reason, single-use, and audit tests

## Decisions Made
- Supported only the narrow Phase 4 mutation set instead of broad workflow “heal everything” controls.

## Deviations from Plan
None.

## Next Phase Readiness
The native UI can now drive preview-first repairs against a stable backend contract.
