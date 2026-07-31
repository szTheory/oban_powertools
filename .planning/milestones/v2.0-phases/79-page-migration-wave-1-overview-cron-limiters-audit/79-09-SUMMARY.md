---
phase: 79-page-migration-wave-1-overview-cron-limiters-audit
plan: 09
subsystem: testing
tags: [page-stories, playwright, visual-regression, red-contracts, accessibility, confidentiality]
requires:
  - phase: 78-component-groups-meta-components
    provides: generated target conventions, connected operator-pattern browser helpers, and exact baseline verification
  - phase: 79-page-migration-wave-1-overview-cron-limiters-audit
    provides: shared and connected RED page migration contracts from Plan 79-01
provides:
  - Exact ordered 19-story normalized page catalog RED contract
  - Connected real-route browser contract requiring isolated authenticated Phase 79 fixtures
  - Independent schema-7 verifier for exactly 228 page-only PNG baselines
affects: [79-10, 79-11, 79-12, showcase-manifest, browser-evidence]
tech-stack:
  added: []
  patterns: [Elixir-owned story registry, fail-closed browser fixture prerequisite, manifest-derived baseline scope]
key-files:
  created:
    - test/oban_powertools/page_story_catalog_test.exs
    - test/browser/specs/page-migration-wave-1.spec.ts
    - test/browser/support/verify-page-baselines.mjs
  modified: []
key-decisions:
  - "Keep the exact 19 page-story IDs literal only in the Elixir catalog contract; TypeScript derives all page targets from future schema-7 pageStories."
  - "Require Plan 79-10 Task 79-10-03's authenticated reset, actor, and recovery helper plus PHASE79_BROWSER_FIXTURE_SECRET before any connected page test can run."
  - "Verify page visual evidence independently as exactly 19 stories times four themes times three Chromium projects, including tracked, untracked, renamed, and copied changed paths."
patterns-established:
  - "RED browser discovery fails at one module-load schema-7/pageStories guard only after the complete TypeScript module parses."
  - "Connected browser evidence uses production routes and fixture-returned identities; showcase story assigns never substitute for database behavior."
  - "Confidentiality proof scans complete text, markup, URLs, live values, hidden nodes, forms, titles, and every attribute."
requirements-completed: [PAGE-01, PAGE-05, PAGE-06, PAGE-08, PAGE-10, COPY-01, A11Y-*, MOTION-*]
duration: 7 min
completed: 2026-07-19
status: complete
---

# Phase 79 Plan 09: Page Story and Connected Browser RED Contracts Summary

**Exact 19-story/228-image contracts plus fail-closed connected browser evidence for Overview, Cron, Limiters, and Audit.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-19T19:29:30Z
- **Completed:** 2026-07-19T19:36:17Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Locked the exact 19 page-story IDs, four page-family counts, closed metadata fields, activation states, deterministic normalized fixtures, explicit UI states, internationalized stress content, and authority-value exclusions in one Elixir-owned registry contract.
- Added a parsed connected Playwright contract for canonical URL/history, Audit filter-page-selection composition, Cron confirmation/recovery/duplicate suppression, named actions, server-derived authorization, adaptive focus behavior, 320px and 200% reflow, reduced motion, and full-channel confidentiality.
- Made connected execution fail closed on Plan 79-10 Task 79-10-03's authenticated reset/actor/recovery helper and `PHASE79_BROWSER_FIXTURE_SECRET`, with no skip or ambient one-entry seed fallback.
- Added an independent schema-7 verifier deriving exactly `19 * 4 * 3 = 228` page PNGs and rejecting missing, extra, tracked, untracked, renamed, copied, or non-page screenshot scope.

## Task Commits

Each task was committed atomically:

1. **Task 79-09-01: Lock the exact page-story and connected-browser evidence contracts** - `0742b96` (test)

**Plan metadata:** committed separately after the atomic task commit.

## Files Created/Modified

- `test/oban_powertools/page_story_catalog_test.exs` - Exact ordered story metadata, activation, normalized fixture, state coverage, adversarial content, determinism, and confidentiality RED contract.
- `test/browser/specs/page-migration-wave-1.spec.ts` - Future schema-7 manifest guard and isolated authenticated connected production-page behavior contract.
- `test/browser/support/verify-page-baselines.mjs` - Exact-set and changed-scope verifier for the 228 page-only browser baselines.

## Decisions Made

- Kept every literal page-story ID in the Elixir test only. The browser suite checks future generated `pageStories` and family counts without duplicating the registry.
- Deferred the fixture module import until test setup so current discovery reaches the intended schema-7/pageStories RED guard first; once schema 7 lands, the missing Plan 79-10 helper becomes the next explicit prerequisite.
- Required all connected tests to reset isolated database state and establish an explicit operator or read-only actor. Static page-story data and the example host's ambient seed are not valid connected evidence.
- Treated page baselines as an independent exact set rather than relying on aggregate showcase VRT, preserving the unrelated 108 scenario residual as separate evidence.

## RED Contract Compliance

- `mix test test/oban_powertools/page_story_catalog_test.exs --seed 0` parses, compiles, and reports 5 intentional failures, all at the missing future `ObanPowertools.PageStoryCatalog` gate.
- `npx playwright test --list test/browser/specs/page-migration-wave-1.spec.ts` parses the complete TypeScript module and reaches the intentional missing schema-7/generated-`pageStories` guard.
- No production catalog, fixture helper, manifest support, example-host route/seed, generated PNG, dependency, schema, policy, or packaged asset was added.
- This independent plan is intentionally RED-only; no GREEN or production implementation commit belongs in Plan 79-09.

## Verification

- `mix format --check-formatted test/oban_powertools/page_story_catalog_test.exs` - PASS.
- `node --check test/browser/support/verify-page-baselines.mjs` - PASS.
- Static acceptance gate - PASS: exactly 19 page IDs occur once in Elixir and zero occur in TypeScript; required browser title/prerequisite/scope markers are present; no Playwright skip/fixme/fail declaration exists.
- `git diff --check` across all three contract files - PASS.
- RED-only commands fail solely at named future Phase 79 catalog/manifest artifacts as intended.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope expansion and no production, package, route, policy, dependency, or database change.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. Plan 79-10 owns the future test-only browser fixture secret and helper delivery.

## Next Phase Readiness

- Plan 79-10 can implement the deterministic catalog, schema-7 manifest, isolated authenticated fixture/reset/recovery helper, and production-rendered page targets against these exact contracts.
- Plans 79-11 and 79-12 can generate and review exactly 228 page baselines, run page-only changed-scope verification, and keep the known 108 scenario residual separate.
- No blocker or unresolved high-severity threat was introduced.

## Self-Check: PASSED

- All three declared key files exist and are committed in `0742b96`.
- The task commit contains exactly the three planned RED contract files and no deletions.
- Every task and plan verification/acceptance criterion was rerun after final formatting.
- The summary records the intentional RED outcomes without claiming the future implementation or PNG evidence exists.

---
*Phase: 79-page-migration-wave-1-overview-cron-limiters-audit*
*Completed: 2026-07-19*
