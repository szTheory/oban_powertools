---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 02
subsystem: ui
tags: [phoenix-liveview, jobs, filtering, pagination, accessibility, redaction]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 01
    provides: Bounded Jobs queries, canonical URL parsing, and closed selector encoders
provides:
  - Closed redaction-safe Jobs row and quick-review presenters
  - Submit-mode canonical Jobs filtering with retained invalid drafts
  - Exact count-driven pagination and persistent explicit selection
  - Authorized URL-owned adaptive quick review through shared components
affects: [80-03, 80-04, jobs, forensics]

tech-stack:
  added: []
  patterns:
    - Raw Oban jobs remain local to orchestration while assigns receive closed presentation maps
    - Disconnected index rendering defers queries until the actual connected URL can be canonicalized
    - First quick review pushes history while switches and close replace the current review entry

key-files:
  created: []
  modified:
    - lib/oban_powertools/web/control_plane_presenter.ex
    - lib/oban_powertools/web/jobs_live.ex
    - test/oban_powertools/web/operator_pattern_presenter_test.exs
    - test/oban_powertools/web/live/jobs_live_test.exs

key-decisions:
  - "Jobs index assigns contain finite presenter rows and quick-review maps; raw args, meta, errors, output payloads, and provider values never enter shared composition."
  - "Filter change retains and validates draft strings only; one valid submit patches canonical applied URL truth before the three bounded list/count/grouped-count reads."
  - "The disconnected Jobs index performs no query because the host router does not expose URL query params until the connected phase."
  - "Quick-review authorization uses the same unavailable outcome for missing and unauthorized jobs, and stale review identity is removed with a replace patch."

patterns-established:
  - "Exact scan truth: active count drives state copy, visible range, and Previous/Next boundaries independently of row length."
  - "Selection continuity: explicit IDs persist across ordinary pagination, page controls expose checked/mixed/unchecked state, and forged off-page IDs are ignored."
  - "Pure page composition: JobsLive.page_content/1 renders shared FilterBar, Forms, DataTable, StatusPill, EmptyState, and DetailSurface components."

requirements-completed: ["PAGE-02", "FORM-03", "DATA-*", "PAGE-10", "A11Y-*"]

duration: 17min
completed: 2026-07-27
status: complete
---

# Phase 80 Plan 02: Jobs Browse and Quick Review Summary

**Exact bounded Jobs scanning with submit-mode canonical filters, persistent selection, and authorized redaction-safe adaptive quick review**

## Performance

- **Duration:** 17 min
- **Started:** 2026-07-28T02:57:23Z
- **Completed:** 2026-07-28T03:14:40Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added finite row and quick-review presenters that exclude raw args, meta, errors, payloads, histories, provider values, credentials, tokens, and mutation state before assignment or rendering.
- Rebuilt the Jobs index with the shipped submit-mode FilterBar, Forms, semantic DataTable, status taxonomy, explicit EmptyState, and stateless adaptive DetailSurface.
- Separated retained draft validation from canonical applied URL state, including exact help/error copy, human applied-filter removal destinations, and pre-query connected canonicalization.
- Added fixed 20-row descending pages with exact state totals/ranges, full-final-page Next disabling, cross-page explicit selection, tri-state page selection, and URL-reloadable authorized quick review.

## Task Commits

Each task used an atomic red-green pair:

1. **Task 80-02-01: Implement closed Jobs row and quick-review presenters**
   - `4bfd6c0` — failing presenter contracts
   - `d8f5bf6` — closed presenter implementation
2. **Task 80-02-02: Compose the bounded Jobs scan and adaptive quick review**
   - `e7966c5` — failing Jobs scan contracts
   - `ade3e88` — Jobs index and quick-review implementation

## Files Created/Modified

- `lib/oban_powertools/web/control_plane_presenter.ex` - Closed eight-fact row projection and bounded quick-review projection.
- `lib/oban_powertools/web/jobs_live.ex` - Canonical filter orchestration, exact bounded scan, selection, quick review, and public pure index composition.
- `test/oban_powertools/web/operator_pattern_presenter_test.exs` - Finite-key, grammatical-value, and nested sensitive-sentinel exclusion coverage.
- `test/oban_powertools/web/live/jobs_live_test.exs` - Submit-only draft behavior, exact query/range truth, semantic shared-component HTML, selection, history, deep-link, and unavailable-review coverage.

## Decisions Made

- Deferred every disconnected index query because the host router supplies `%{}` rather than the actual URL query during static rendering; the connected phase canonicalizes the real URL first and then performs exactly three bounded browse reads.
- Kept the required state outside removable optional-filter presentation and reset review, explicit selection, preview, confirmation, frozen scope, and stale results on state/filter identity changes.
- Used row-local `Review job` controls rather than clickable rows, preserving full worker and job identities in the semantic table DOM.
- Kept existing full-detail and bulk mutation behavior compatible without adding presenter contracts or new behavior owned by Plans 80-03 and 80-04.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The disconnected LiveView phase cannot see Jobs query params in this host route. Querying there would load a safe default before validating an invalid direct URL, so the index now renders finite defaults without a read and defers canonicalization/loading to the connected phase.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/oban_powertools/web/operator_pattern_presenter_test.exs --seed 0` - 22 tests, 0 failures.
- `mix test test/oban_powertools/web/live/jobs_live_test.exs --seed 0` - 36 tests, 0 failures.
- `mix test test/oban_powertools/web/operator_pattern_presenter_test.exs test/oban_powertools/web/live/jobs_live_test.exs --seed 0` - 58 tests, 0 failures.
- `mix test test/oban_powertools/web/components/operator_patterns_test.exs test/oban_powertools/web/components/data_display_test.exs --seed 0` - 47 tests, 0 failures.
- Both plan formatting checks and `mix compile --warnings-as-errors` passed.
- The implementation diff from the Plan 80-01 checkpoint contains exactly the four declared production/test paths.

## Next Phase Readiness

- Plan 80-03 can replace the compatible full-detail branch while reusing closed list return context and the current authorization boundary.
- Plan 80-04 can build bounded all-matching selection, confirmation, progress, and result behavior on the exact filter identity and explicit-selection state established here.

## Self-Check: PASSED

- All four declared implementation/test files exist and are committed.
- Red/green task commits `4bfd6c0`, `d8f5bf6`, `e7966c5`, and `ade3e88` exist.
- Every plan verification command passes.
- No schema, migration, dependency, Forensics behavior, fixture, story, asset, CSS, or evidence work was added.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-27*
