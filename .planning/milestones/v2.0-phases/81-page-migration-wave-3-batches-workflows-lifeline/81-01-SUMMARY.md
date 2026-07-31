---
phase: 81-page-migration-wave-3-batches-workflows-lifeline
plan: 01
subsystem: testing
tags: [elixir, phoenix-liveview, playwright, security, accessibility]
requires:
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 07
    provides: isolated secret-gated Wave 3 connected fixtures
provides:
  - RED finite presenter, selector, and page-composition contracts
  - exact ordered 50-story Wave 3 inventory contract
  - connected production-route Batches, Workflows, and Lifeline acceptance contract
affects: [81-02, 81-03, 81-04, 81-05, 81-06, 81-08]
tech-stack:
  added: []
  patterns:
    - RED source-boundary tests name pure seams and finite LIMIT-plus-one windows
    - connected browser tests use the isolated Phase 81 fixture and production routes
key-files:
  created:
    - test/browser/specs/page-migration-wave-3.spec.ts
  modified:
    - test/oban_powertools/web/operator_pattern_presenter_test.exs
    - test/oban_powertools/web/selectors_test.exs
    - test/oban_powertools/web/live/batches_live_test.exs
    - test/oban_powertools/web/live/workflows_live_test.exs
    - test/oban_powertools/web/live/lifeline_live_test.exs
    - test/oban_powertools/page_story_catalog_test.exs
    - test/oban_powertools/showcase_catalog_test.exs
    - test/oban_powertools/web/live/showcase_live_test.exs
key-decisions:
  - "Wave 3 uses literal presenter seam names and exact finite source constants so later migrations cannot pass through generic raw fallbacks."
  - "The locked catalog appends 18 Batches, 12 Workflows, and 20 Lifeline stories after the unchanged 49-story prefix."
  - "Connected acceptance remains serial and fails closed when the Phase 81 fixture credential is absent."
requirements-completed: []
duration: 12min
completed: 2026-07-29
status: complete
---

# Phase 81 Plan 01: Wave 3 RED Contracts Summary

**The Batches, Workflows, and Lifeline migration now has executable RED contracts for finite presentation, exact inventory, production composition, authority, confidentiality, accessibility, motion, and connected behavior.**

## Performance

- **Duration:** 12 min
- **Completed:** 2026-07-29
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Locked fifteen finite presenter seams, closed Batches/Workflows/Lifeline selectors, twelve exact render bounds, public pure page composition, and removal of raw serialization fallbacks.
- Froze the exact ordered 18/12/20 Wave 3 story IDs, 99-page-story and 163-target totals, normalized fixture closure, and delegation to all nine production page seams.
- Added ten serial Playwright cases against credential-protected fixtures and real production routes for navigation, selection, bounds, preview/reason/reauthorization/execute/Audit behavior, distinct recovery outcomes, focus, reflow, reduced motion, and confidentiality.

## Task Commits

1. **Task 81-01-01: Lock closed presenter, selector, and pure page contracts** — `f2779cb`
2. **Task 81-01-02: Lock the exact 50-story inventory and production composition requirement** — `f7f3893`
3. **Task 81-01-03: Scaffold connected production-route acceptance** — `7b3d1f3`

## RED Verification Evidence

- Focused presenter/selector/LiveView command: **83 tests compiled; 6 expected failures**. Failures name missing selectors, presenter seams/constants, page composition seams, bounds, and unsafe legacy fallbacks. Existing pre-migration tests continued past the new contracts.
- Catalog/showcase command: **50 tests compiled; 3 expected failures**. Failures name the missing 50 stories, 163-target total, and three production ShowcaseLive delegations.
- Playwright discovery: **10 tests in one file** for `chromium-wide`.
- `npm run showcase:manifest`: passed against the current schema-8 graph.
- Secret-gated Docker execution reached the isolated fixture and connected production Batches route, then failed at the first missing migrated root (`#batches-page, #batch-detail-page`). The remaining nine serial cases correctly did not run after the first RED failure.

## Failure Contract

The expected RED failures are:

- `Selectors.batch_detail_path/2`, `workflows_path/1`, and `workflow_detail_path/2` are absent.
- Fifteen Wave 3 presenter functions and twelve finite constants are absent.
- Batches, Workflows, and Lifeline do not yet expose their required pure page seams or bounded source windows.
- Legacy Batches and Lifeline raw serialization/token rendering remains present.
- The catalog still has 49 page stories / 113 total targets and ShowcaseLive delegates only six production families.
- Connected Batches lacks the migrated production root and shared bounded composition.

## Deviations from Plan

None - the plan was intentionally RED-only and no production implementation was added.

## Issues Encountered

- Dependency resolution printed pre-existing advisory notices for locked packages. No dependency or lockfile change was made.
- The connected suite is serial, so the first intentional RED production failure prevented the remaining nine cases from executing. Discovery proves all ten compile; later implementation waves will advance the runtime suite incrementally.

## Security and Threat Review

- No endpoint, schema, dependency, authorization path, or production mutation surface was added.
- The browser contract requires the generated Phase 81 credential and scans page text, HTML, URL state, and named confidential fields.
- Tests explicitly block forged URL action/preview authority, preview-token and plan-hash disclosure, raw snapshots/metadata/provider errors, stale authorization, duplicate execution, and unbounded retained evidence.

## Known Stubs

None. This plan adds contracts only; the intentionally missing production behavior is owned by Plans 81-02 through 81-06.

## TDD Gate Compliance

This plan is a RED-only Wave 0 contract plan. All three task commits contain tests only; GREEN implementation is intentionally deferred to subsequent Phase 81 plans.

## Next Phase Readiness

- Plan 81-02 can implement Batches against the exact presenter, selector, pure seam, and 50/25 bounds.
- Plan 81-03 can implement Workflows against the exact deep-link, read-only, and 50/100/50/25 contracts.
- Plans 81-04 and 81-05 can close Lifeline presentation before migrating its preview/reason/execute/Audit composition.
- Plan 81-06 has a frozen 50-ID inventory and exact nine-family production-delegation target.

## Self-Check: PASSED

- All nine plan-scoped test files exist.
- Commits `f2779cb`, `f7f3893`, and `7b3d1f3` exist.
- Every focused command produced the intended structurally valid RED evidence.
- No production file, dependency, route, schema, or unrelated dirty artifact was committed.

---
*Phase: 81-page-migration-wave-3-batches-workflows-lifeline*
*Completed: 2026-07-29*
