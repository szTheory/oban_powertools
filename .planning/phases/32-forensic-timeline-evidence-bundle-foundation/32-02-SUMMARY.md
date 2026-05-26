---
phase: 32-forensic-timeline-evidence-bundle-foundation
plan: 02
subsystem: ui
tags: [forensics, liveview, router, workflows, lifeline]
requires:
  - phase: 32-01
    provides: shared forensic contract
provides:
  - /ops/jobs/forensics LiveView
  - workflow forensic entry links
  - lifeline forensic entry links
affects: [audit-follow-up, copy-coherence, phase-33-forensics]
tech-stack:
  added: []
  patterns: [selector-only forensic continuity, bounded forensic destination]
key-files:
  created:
    - lib/oban_powertools/web/forensics_live.ex
    - test/oban_powertools/web/live/forensics_live_test.exs
  modified:
    - lib/oban_powertools/web/router.ex
    - lib/oban_powertools/web/live_auth.ex
    - lib/oban_powertools/web/workflows_live.ex
    - lib/oban_powertools/web/lifeline_live.ex
    - test/oban_powertools/web/live/workflows_live_test.exs
    - test/oban_powertools/web/live/lifeline_live_test.exs
    - test/oban_powertools/web/router_test.exs
key-decisions:
  - "The forensic destination reads only stable selectors from params."
  - "Workflow and Lifeline pages advertise forensic entry while keeping audit follow-up read-only."
patterns-established:
  - "Native pages deep-link into one forensic destination under /ops/jobs/forensics."
  - "Selector builders preserve deterministic query ordering for remount-safe tests."
requirements-completed: [FRN-01, FRN-02, FRN-03]
duration: 1h
completed: 2026-05-26
---

# Phase 32: Forensic Timeline & Evidence Bundle Foundation Summary

**A bounded `/ops/jobs/forensics` LiveView now restores workflow and Lifeline forensic bundles from durable selectors only.**

## Performance

- **Duration:** 1h
- **Started:** 2026-05-26T10:05:00-04:00
- **Completed:** 2026-05-26T10:21:00-04:00
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Mounted the native forensic destination and rendered diagnosis, timeline, related evidence, links, and completeness sections.
- Added workflow and Lifeline CTAs into the forensic destination with stable selector-only URLs.
- Extended route and LiveView tests for workflow, incident, and remount continuity.

## Task Commits

Inline execution in this runtime did not produce per-task git commits.

## Files Created/Modified
- `lib/oban_powertools/web/forensics_live.ex` - renders the shared forensic story
- `lib/oban_powertools/web/router.ex` - mounts `/ops/jobs/forensics`
- `lib/oban_powertools/web/live_auth.ex` - adds read-only banner wording for forensic bundles
- `lib/oban_powertools/web/workflows_live.ex` - exposes workflow forensic CTA and selector builder
- `lib/oban_powertools/web/lifeline_live.ex` - exposes incident forensic CTA and deterministic continuity params
- `test/oban_powertools/web/live/forensics_live_test.exs` - covers workflow and Lifeline bundle remounts

## Decisions Made

- Kept forensic continuity URL-safe by rejecting preview tokens, mutable reason text, diagnosis prose, and refusal copy from params.
- Used one shared read-only forensic destination instead of page-local investigative drilldowns.

## Deviations from Plan

None.

## Issues Encountered

The Lifeline continuity helper needed deterministic query param ordering to preserve existing assert-patch expectations.

## User Setup Required

None.

## Next Phase Readiness

Workflow and Lifeline now hand operators into the same forensic destination, which is ready for cross-surface proof hardening.

