---
phase: 78-component-groups-meta-components
plan: 03
subsystem: web-ui
tags: [operator-patterns, filter-bar, liveview, accessibility, css, javascript, assets]
requires:
  - phase: 78-component-groups-meta-components
    plan: 02
    provides: finite active-filter normalization and shared operator presentation foundations
provides:
  - stateless submit/instant FilterBar composition with caller-owned forms and canonical destinations
  - responsive token-backed FilterBar styling with one accessible field tree
  - nearest-root idempotent disclosure synchronization across narrow layouts and LiveView patches
  - connected proof of parent-owned draft, applied, validation, pagination, result, and navigation truth
affects: [78-04, 78-05, 78-06, 78-07, 78-08]
tech-stack:
  added: []
  patterns: [stateless filter composition, draft-applied separation, caller-owned canonical URLs, root-scoped disclosure, deterministic asset packaging]
key-files:
  created: []
  modified:
    - lib/oban_powertools/web/components/operator_patterns.ex
    - assets/oban_powertools/tokens.css
    - assets/oban_powertools/theme.js
    - priv/static/oban_powertools/oban_powertools.css
    - priv/static/oban_powertools/oban_powertools.js
    - test/oban_powertools/web/components/operator_patterns_test.exs
    - test/oban_powertools/web/live/operator_patterns_harness_test.exs
    - test/oban_powertools/web/theme_tokens_test.exs
    - test/oban_powertools/web/assets_test.exs
key-decisions:
  - "Keep FilterBar presentation-only: parents provide the Phoenix form, normalized applied filters, exact result copy, and every canonical remove or clear destination."
  - "Use one fixed field tree and synchronize only presentation state within the nearest .obpt-root; narrow collapsed fields become hidden and inert without persisting filter data."
  - "Model invalid connected-harness values with test-owned text inputs so server validation can retain tampered draft values and errors visibly."
patterns-established:
  - "Submit mode separates draft validation from explicit application; instant mode omits apply and dirty affordances without changing behavior at breakpoints."
  - "Applied noun/value pairs, named removal controls, Clear filters, and the exact result status remain outside the collapsible field region."
  - "Filter disclosure JavaScript stores no query values or result data and remains idempotent after repeated synchronization and inserted roots."
requirements-completed: [GROUP-01, GROUP-02, COPY-02, A11Y-02]
duration: 27 min
completed: 2026-07-18
status: complete
---

# Phase 78 Plan 03: FilterBar and Parent-Owned Filter Truth Summary

**A stateless submit/instant FilterBar now renders one responsive field tree while parent LiveViews retain exclusive authority over drafts, validation, applied results, pagination, canonical URLs, and history.**

## Performance

- **Duration:** 27 min
- **Started:** 2026-07-18T22:17:28Z
- **Completed:** 2026-07-18T22:44:12Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added `OperatorPatterns.filter_bar/1` with the exact constrained form, mode, result, applied-filter, disclosure, dirty-state, event, and canonical-destination contract.
- Added root-scoped token CSS for 44px targets, wrapping applied filters, visible focus, reduced motion, narrow single-column layout, and 320px overflow safety while retaining one field tree.
- Extended the standalone controller with nearest-root `setFilterState` and `syncFilterDisclosures` behavior that keeps state, `aria-expanded`, `hidden`, and inert tab reachability synchronized across clicks, media changes, and LiveView patches.
- Proved connected parent ownership of draft/applied values, validation errors, exact result status, pagination reset, canonical push/remove/clear destinations, safe replacement, and AND/OR query meaning without modifying production pages.

## Task Commits

Each task was committed atomically:

1. **Task 78-03-01: Implement the stateless FilterBar contract and responsive CSS** - `4b76cfc` (feat)
2. **Task 78-03-02: Add scoped idempotent filter disclosure behavior and rebuild assets** - `0a4f4d0` (chore)
3. **Task 78-03-03: Prove parent-owned draft, applied, validation, and navigation truth** - `9d1a9cf` (test)

**Plan summary:** committed separately before sequential state and roadmap tracking.

## Files Created/Modified

- `lib/oban_powertools/web/components/operator_patterns.ex` - Stateless FilterBar submit/instant API and semantic rendering.
- `assets/oban_powertools/tokens.css` - Root-scoped responsive FilterBar layout, targets, focus, wrapping, and disclosure presentation.
- `assets/oban_powertools/theme.js` - Nearest-root idempotent disclosure synchronization and patch handling.
- `priv/static/oban_powertools/oban_powertools.css` - Deterministically regenerated packaged CSS.
- `priv/static/oban_powertools/oban_powertools.js` - Deterministically regenerated packaged JavaScript.
- `test/oban_powertools/web/components/operator_patterns_test.exs` - FilterBar form, mode, applied-filter, safe-source, and URL-authority contracts.
- `test/oban_powertools/web/live/operator_patterns_harness_test.exs` - Connected draft/applied, validation, canonical navigation, and query-semantics proof.
- `test/oban_powertools/web/theme_tokens_test.exs` - FilterBar token, root-scope, responsive, focus, and overflow contracts.
- `test/oban_powertools/web/assets_test.exs` - Fixed selector/function, forbidden behavior, syntax, byte-equality, and repeat-build guards.

## Decisions Made

- Kept all URL serialization, query semantics, result loading, pagination, and validation in parents; the FilterBar only renders supplied truth and destinations.
- Used one presentation-only disclosure controller scoped to the nearest Powertools root, with no hook-map requirement, storage, logging, dynamic evaluation, or filter-value access.
- Kept applied state and the exact result status outside the controlled fields so collapsing filters never hides current query truth or removal affordances.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope expansion, production-page migration, authority change, dependency change, or protected-boundary modification.

## Issues Encountered

- Phoenix LiveView's select test helper rejects values not present in the option list before the server event runs. The test-owned harness uses text inputs for its stable domain values so tampered invalid drafts reach validation and remain visible with errors, as required.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 78-04 can build the confirmation composition on the same constrained, parent-owned authority boundary while the confirmation slice remains isolated.
- Plan 78-05 can add detail surfaces without changing FilterBar state or production page navigation.
- Catalog, manifest, browser, and baseline work in Plans 78-06 through 78-08 can consume the packaged FilterBar selectors and deterministic assets.

## Self-Check: PASSED

- All nine declared implementation/test artifacts are present in the cumulative Plan 78-03 diff; no production LiveView, route, authorization, query, mutation, schema, dependency, or lockfile file changed.
- All three atomic task commits are present in order, and unrelated pre-existing deletions/untracked files remain untouched.
- Filter component tests pass 3/3 with ten future cases excluded; theme tests pass 13/13; asset/theme tests pass 20/20; connected filter harness tests pass 5/5 with ten future cases excluded.
- Formatting, both JavaScript syntax checks, and warnings-as-errors compilation pass; packaged CSS and JavaScript are byte-equal to source after deterministic repeat builds.

---
*Phase: 78-component-groups-meta-components*
*Completed: 2026-07-18*
