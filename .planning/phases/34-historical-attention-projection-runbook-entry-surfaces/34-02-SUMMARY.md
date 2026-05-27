---
phase: 34-historical-attention-projection-runbook-entry-surfaces
plan: 02
subsystem: forensics
tags: [forensics, runbook, liveview, tdd, ownership-boundaries]

requires:
  - phase: 34-01
    provides: Stable forensic selector links and historical attention projection
  - phase: 32-forensic-timeline-evidence-bundle-foundation
    provides: Shared forensic bundle contract and completeness vocabulary
  - phase: 33-limiter-history-cron-missed-fire-diagnostics
    provides: Cron and limiter retained-history bundle inputs
provides:
  - Canonical advisory RunbookEntry read-model helper
  - Forensic bundles enriched with canonical runbook_entry data
  - Deep runbook entry rendering on /ops/jobs/forensics
affects: [forensics-live, runbook-guidance, phase-35-remediation-continuity]

tech-stack:
  added: []
  patterns:
    - TDD red/green per runbook entry slice
    - Shared read-model enrichment before LiveView rendering
    - Selector-only evidence links for runbook guidance

key-files:
  created:
    - lib/oban_powertools/forensics/runbook_entry.ex
  modified:
    - lib/oban_powertools/forensics.ex
    - lib/oban_powertools/forensics/cron_history.ex
    - lib/oban_powertools/forensics/limiter_history.ex
    - lib/oban_powertools/web/forensics_live.ex
    - test/oban_powertools/forensics_test.exs
    - test/oban_powertools/web/live/forensics_live_test.exs

key-decisions:
  - "Runbook entries remain advisory read-model data, not persisted action state."
  - "Evidence links use only existing durable selectors: workflow_id, step, incident_fingerprint, view, resource_type, and resource_id."
  - "Bridge-only and host-owned follow-up paths render as bordered guidance rather than filled native action controls."

patterns-established:
  - "RunbookEntry.from_bundle/1 derives prerequisites, cautions, ordered paths, boundaries, and evidence links from bundle-shaped data."
  - "Forensic bundle builders attach runbook_entry immediately after EvidenceBundle.build/1."
  - "ForensicsLive renders the canonical deep runbook entry between diagnosis summary and timeline."

requirements-completed: [RNB-01, RNB-02]

duration: 8m 44s
completed: 2026-05-27
---

# Phase 34 Plan 02: Runbook Entry Surfaces Summary

**Advisory forensic runbook entries now pair diagnosis states with prerequisites, cautions, selector-safe evidence links, and venue-honest next paths.**

## Performance

- **Duration:** 8m 44s
- **Started:** 2026-05-27T06:44:05Z
- **Completed:** 2026-05-27T06:52:49Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added `ObanPowertools.Forensics.RunbookEntry` with `build/1` and `from_bundle/1`.
- Enriched workflow, Lifeline, cron, limiter, and unknown forensic bundles with canonical `:runbook_entry` data.
- Rendered the canonical deep runbook panel on `/ops/jobs/forensics` immediately after diagnosis summary and before timeline.
- Preserved the ownership triad: `Powertools-native`, `Oban Web bridge`, and `host-owned follow-up`.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED:** `383695c` test(34-02): add failing tests for runbook entry builder
2. **Task 1 GREEN:** `c444165` feat(34-02): implement advisory runbook entry builder
3. **Task 2 RED:** `8129243` test(34-02): add failing tests for runbook bundle enrichment
4. **Task 2 GREEN:** `0fac674` feat(34-02): enrich forensic bundles with runbook entries
5. **Task 3 RED:** `0356744` test(34-02): add failing tests for forensic runbook rendering
6. **Task 3 GREEN:** `4d84642` feat(34-02): render forensic runbook entries

## Files Created/Modified

- `lib/oban_powertools/forensics/runbook_entry.ex` - Builds advisory runbook entry maps from bundle-shaped evidence.
- `lib/oban_powertools/forensics.ex` - Attaches runbook entries to workflow, Lifeline, and unknown bundles.
- `lib/oban_powertools/forensics/cron_history.ex` - Adds cron runbook enrichment and native/bridge/host-owned follow-up paths.
- `lib/oban_powertools/forensics/limiter_history.ex` - Adds limiter runbook enrichment and native/bridge/host-owned follow-up paths.
- `lib/oban_powertools/web/forensics_live.ex` - Renders the deep runbook entry panel in the required page order.
- `test/oban_powertools/forensics_test.exs` - Covers builder behavior, bundle enrichment, ownership labels, and selector safety.
- `test/oban_powertools/web/live/forensics_live_test.exs` - Covers runbook rendering order, required sections, evidence states, and non-native path treatment.

## Decisions Made

- Runbook entries are additive maps inside the existing forensic read-model family, keeping Phase 34 free of persisted action state.
- Cron and limiter runbook entries include native return paths, bridge-only audit inspection, and host-owned coordination guidance so ownership is visible before navigation.
- The forensic LiveView renders non-native next paths as bordered/plain guidance, while native paths may use the existing indigo action treatment.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. Stub scan found only legitimate empty-list checks, nil handling, and blank-string filtering in read-model code.

## Threat Flags

None. New trust-boundary behavior matches the plan threat model: bundle-to-runbook transformation, operator advisory rendering, and stable selector reconstruction. No new endpoints, auth paths, file access patterns, schema changes, mutation events, or unsafe selector parameters were introduced.

## Verification

- `mix test test/oban_powertools/forensics_test.exs` -> 16 tests, 0 failures
- `mix test test/oban_powertools/web/live/forensics_live_test.exs` -> 7 tests, 0 failures
- `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs` -> 23 tests, 0 failures
- `rg -n "preview_token|runbook_copy|attention_reason|reason=" lib/oban_powertools/forensics.ex lib/oban_powertools/forensics/cron_history.ex lib/oban_powertools/forensics/limiter_history.ex lib/oban_powertools/web/forensics_live.ex` -> no matches

## TDD Gate Compliance

PASSED. Each task has a RED test commit followed by a GREEN implementation commit.

## Next Phase Readiness

Plan 34-03 can align compact runbook copy and handoffs with the canonical forensic runbook entry without reworking bundle enrichment or ownership labeling.

## Self-Check

PASSED. Verified all created/modified files exist and all task commits are present in git history.

---
*Phase: 34-historical-attention-projection-runbook-entry-surfaces*
*Completed: 2026-05-27*
