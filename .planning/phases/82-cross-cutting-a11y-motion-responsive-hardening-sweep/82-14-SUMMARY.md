---
phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
plan: "14"
subsystem: ui
tags: [copy-policy, phoenix-liveview, jobs, forensics, redaction, accessibility]

requires:
  - phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
    provides: "Finite Copy.contract policy, shared dialog semantics, responsive data behavior, and first-page recovery patterns"
provides:
  - "Request- and record-scoped Jobs batch announcements without downstream outcome overclaims"
  - "Canonical Forensics Event log terminology and actionable uniform-unavailable guidance"
  - "Finite shared job preview recovery copy with existing authority, redaction, URL, and bounded-read contracts preserved"
affects: [82-08, 82-09, 82-10, 82-15, 82-16, page-quality]

tech-stack:
  added: []
  patterns:
    - "Page-owned copy states only Powertools-requested, recorded, changed, audited, and bounded-evidence truth"
    - "Uniform unavailable branches add recovery without distinguishing missing, retained, or unauthorized resources"

key-files:
  created: []
  modified:
    - lib/oban_powertools/web/control_plane_presenter.ex
    - lib/oban_powertools/web/jobs_live.ex
    - lib/oban_powertools/web/forensics_live.ex
    - test/oban_powertools/web/copy_contract_test.exs

key-decisions:
  - "Keep completed Powertools action receipts and server-owned operational flow unchanged while removing only downstream-sounding batch announcements."
  - "Add recovery to the existing uniform Forensics unavailable branch without exposing whether evidence is missing, unretained, or unauthorized."
  - "Use the finite canonical Event log term while leaving page-specific consequence and support prose with Jobs and Forensics."

patterns-established:
  - "Jobs async announcements distinguish request recording from host-owned job completion."
  - "Forensics unavailable copy combines non-enumerating truth with one legal next action."

requirements-completed:
  - COPY-01
  - COPY-02
  - DATA-03
  - A11Y-02

duration: 6min
completed: 2026-07-29
status: complete
---

# Phase 82 Plan 14: Jobs and Forensics Copy Semantics Summary

**Jobs batch feedback now reports only recorded requests and changes, while Forensics uses canonical Event log language and uniform actionable recovery without weakening server authority or confidentiality**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-29T21:12:00Z
- **Completed:** 2026-07-29T21:18:00Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Added a fail-closed source contract for Jobs, Forensics, and their shared presenter seam.
- Reworded Jobs bulk progress and result announcements around requests, recorded results, and recorded changes rather than implied downstream success.
- Added a legal next action to the indistinguishable Forensics unavailable branch and aligned the empty timeline with the canonical `Event log` term.
- Preserved signed-int64 handling, redaction, URL state, bounded reads, uniform denial, Lifeline handoff, and parent/server mutation authority.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Lock Jobs and Forensics copy truth** - `5fabc10` (test)
2. **Task 1 GREEN: Harden Jobs and Forensics copy truth** - `1194681` (fix)

## Files Created/Modified

- `lib/oban_powertools/web/control_plane_presenter.ex` - Corrects finite drift-recovery grammar without changing result or authority projection.
- `lib/oban_powertools/web/jobs_live.ex` - Reports bulk progress and bounded outcomes as requests, recorded actions, and recorded changes.
- `lib/oban_powertools/web/forensics_live.ex` - Adds uniform unavailable recovery and canonical Event log terminology.
- `test/oban_powertools/web/copy_contract_test.exs` - Locks the page-owner and presenter copy-policy seam against overclaims and raw reason branches.

## Decisions Made

- Kept successful job cancellation/discard receipts intact because they describe Powertools-owned state changes already proven by the established connected tests.
- Limited cross-page presenter repair to finite recovery wording; unique batch and evidence-support prose remains page-owned.
- Kept unavailable evidence non-enumerating while adding the same next action for missing, unretained, and unauthorized cases.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- An initial GREEN wording pass changed established connected-test receipts and recovery sentences too broadly. The implementation was narrowed to page-owned overclaims that preserve every existing authority and operational-flow assertion; the required combined suite then passed with 74 tests and zero failures.

## User Setup Required

None - no external service configuration required.

## Verification Evidence

- `mix test test/oban_powertools/web/copy_contract_test.exs test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0` — 74 tests, 0 failures.
- `node test/browser/support/verify-phase82-quality.mjs` — schema 8; 163 targets; 99 pages; 9 routes; 3 roots; 31 files; 18 declarations; 0 exceptions.
- `MIX_ENV=test mix compile --warnings-as-errors` — exit 0.
- Scoped `mix format --check-formatted` and `git diff --check` — pass.

## Next Phase Readiness

- Jobs and Forensics are ready for the connected browser, exact ARIA, and aggregate page-quality waves.
- No routes, schemas, domain behavior, dependencies, stories, target inventories, packaged assets, or raw provider channels changed.
- No blockers.

## Self-Check: PASSED

- All four plan-owned implementation/test files exist.
- Task commits `5fabc10` and `1194681` exist.
- Focused suites, the Phase 82 validator, warnings-as-errors compilation, formatting, and diff checks pass.

---
*Phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep*
*Completed: 2026-07-29*
