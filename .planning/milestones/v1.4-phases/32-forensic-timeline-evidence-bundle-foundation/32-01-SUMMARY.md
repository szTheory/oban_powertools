---
phase: 32-forensic-timeline-evidence-bundle-foundation
plan: 01
subsystem: api
tags: [forensics, liveview, audit, workflows, lifeline]
requires: []
provides:
  - shared forensic bundle contract
  - provenance and completeness vocabulary
  - chronology ordering helpers
affects: [forensics-live, control-plane-copy, audit-follow-up]
tech-stack:
  added: []
  patterns: [shared forensic assembler, diagnosis-first bundle contract]
key-files:
  created:
    - lib/oban_powertools/forensics.ex
    - lib/oban_powertools/forensics/evidence_bundle.ex
    - lib/oban_powertools/forensics/chronology.ex
    - lib/oban_powertools/forensics/provenance.ex
    - test/oban_powertools/forensics_test.exs
  modified:
    - lib/oban_powertools/web/control_plane_presenter.ex
key-decisions:
  - "Workflow and Lifeline remain the durable anchors; limiter and cron stay supporting evidence in Phase 32."
  - "Completeness is explicit with complete, partial_evidence, history_unavailable, and unknown states."
patterns-established:
  - "Forensic bundles are assembled in domain code, not in LiveViews."
  - "Chronology sorting prefers newer durable events before weaker supporting evidence."
requirements-completed: [FRN-02, FRN-03]
duration: 1h
completed: 2026-05-26
---

# Phase 32: Forensic Timeline & Evidence Bundle Foundation Summary

**Shared forensic bundle and chronology modules now provide one diagnosis-first investigative contract for workflow and Lifeline drilldowns.**

## Performance

- **Duration:** 1h
- **Started:** 2026-05-26T09:58:00-04:00
- **Completed:** 2026-05-26T10:20:00-04:00
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added `ObanPowertools.Forensics` as the shared forensic read-model entrypoint.
- Introduced concrete provenance, completeness, chronology, and evidence-bundle helpers.
- Extended presenter helpers and unit coverage for support-truthful provenance and completeness labels.

## Task Commits

Inline execution in this runtime did not produce per-task git commits.

## Files Created/Modified
- `lib/oban_powertools/forensics.ex` - builds workflow and Lifeline forensic bundles from durable selectors
- `lib/oban_powertools/forensics/evidence_bundle.ex` - normalizes bundle shape and completeness metadata
- `lib/oban_powertools/forensics/chronology.ex` - orders chronology items by time and provenance strength
- `lib/oban_powertools/forensics/provenance.ex` - centralizes provenance and completeness vocabularies
- `lib/oban_powertools/web/control_plane_presenter.ex` - exposes shared forensic wording helpers
- `test/oban_powertools/forensics_test.exs` - locks bundle semantics and degraded-evidence behavior

## Decisions Made

- Kept the bundle contract diagnosis-first with chronology subordinate to the subject summary.
- Encoded venue honesty in the presenter so UI consumers share the same phrases for supporting evidence and Inspection only posture.

## Deviations from Plan

None. The plan was executed as designed, with the only difference being inline execution instead of subagent fan-out.

## Issues Encountered

Unit tests initially used the wrong test case and hit SQL sandbox ownership; switching to `ObanPowertools.DataCase` resolved it.

## User Setup Required

None.

## Next Phase Readiness

The shared forensic contract is stable and Phase 32 UI work can consume it without re-deciding evidence semantics.

