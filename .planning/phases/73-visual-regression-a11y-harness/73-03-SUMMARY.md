---
phase: 73-visual-regression-a11y-harness
plan: 03
subsystem: testing
tags: [playwright, axe, accessibility, showcase]

requires:
  - phase: 73-02
    provides: Deterministic Playwright runtime and real showcase host path
provides:
  - Reusable axe helper with full JSON artifact output
  - Catalog-backed showcase axe matrix across themes and viewport projects
  - Critical/serious automated accessibility merge gate
affects: [phase-73, accessibility, showcase, ci]

tech-stack:
  added: []
  patterns:
    - Axe uses one `options({ runOnly, rules, resultTypes })` call so WCAG tag selection is not overwritten
    - Full axe result JSON is written under `test-results/axe/` and attached to Playwright test info
    - The blocking gate fails only `critical` and `serious` violation impacts

key-files:
  created:
    - test/browser/support/axe.ts
    - test/browser/specs/showcase.a11y.spec.ts
  modified:
    - lib/oban_powertools/web/dev/showcase_live.ex

key-decisions:
  - "Scanned only the manifest `scenario.a11y` story targets; reserved open-state metadata is not treated as implemented open-state DOM."
  - "Enabled WCAG A/AA and supported WCAG 2.2 AA coverage, including `target-size`, without suppressing moderate, minor, incomplete, passes, or inapplicable result data."
  - "Fixed the actual serious finding by making story fixture `<pre>` blocks keyboard-focusable and named, rather than disabling the rule or hiding the content."

patterns-established:
  - "`runAxeForTarget` scopes axe to a single manifest selector and applies the approved WCAG tag/rule configuration."
  - "`writeAxeResult` emits one reviewable JSON artifact per project/theme/scenario result."
  - "`showcase.a11y.spec.ts` produces the full 9 scenarios x 4 themes x 3 viewport-project matrix."

requirements-completed: [A11Y-01]

duration: 24 min
completed: 2026-06-19
status: complete
---

# Phase 73 Plan 03: Axe Accessibility Gate Summary

**The showcase now has a Docker-backed axe matrix with zero critical or serious findings across all current catalog targets, themes, and viewport projects.**

## Performance

- **Duration:** 24 min
- **Completed:** 2026-06-19
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `test/browser/support/axe.ts` with explicit WCAG tag configuration, `target-size` enablement, full-result JSON writing, and a critical/serious threshold helper.
- Added `test/browser/specs/showcase.a11y.spec.ts`, scanning all 9 generated manifest story targets across 4 themes and 3 Chromium projects.
- Made each story fixture `<pre>` keyboard-focusable with a useful `aria-label`, resolving the serious `scrollable-region-focusable` finding without changing story selectors.
- Verified 108 axe JSON artifacts are emitted and contain `violations`, `passes`, `incomplete`, and `inapplicable` arrays.

## Task Commits

1. **Task 1: Add axe helper with narrow threshold and full result output** - `3548ded` (test)
2. **Task 2: Add showcase axe matrix and close current serious or critical findings** - `a73d90b` (test)

## Files Created/Modified

- `test/browser/support/axe.ts` - AxeBuilder wrapper, JSON artifact writer, and critical/serious assertion.
- `test/browser/specs/showcase.a11y.spec.ts` - Manifest-backed axe scan matrix.
- `lib/oban_powertools/web/dev/showcase_live.ex` - Focusable, named fixture data `<pre>` blocks.

## Decisions Made

- Used `options()` only, rather than combining `withTags()` and `options()`, to preserve runOnly tag configuration.
- Persisted every result shape, including non-blocking moderate/minor and incomplete findings, as review artifacts.
- Left `assets/oban_powertools/tokens.css` and `priv/static/oban_powertools/oban_powertools.css` unchanged because the only serious finding was markup-level keyboard access.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made scrollable fixture code blocks keyboard-accessible**
- **Found during:** Task 2 axe verification
- **Issue:** All story targets failed `scrollable-region-focusable` because fixture `<pre>` blocks can scroll horizontally but were not focusable.
- **Fix:** Added `tabindex="0"` and a scenario-specific `aria-label` to the fixture `<pre>` in `ShowcaseLive`.
- **Files modified:** `lib/oban_powertools/web/dev/showcase_live.ex`
- **Verification:** `mix test test/oban_powertools/web/live/showcase_live_test.exs`; full Docker-backed axe matrix passed.
- **Committed in:** `a73d90b`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix preserves all existing selector contracts and improves the actual showcase DOM scanned by axe.

## Issues Encountered

- Initial axe verification failed all 108 cases because the same serious scrollable-region finding appeared in every story target. Resolved by the markup fix above.

## User Setup Required

Docker must be available for `visual:a11y` runs.

## Verification

- `node -e "const fs=require('fs'); const s=fs.readFileSync('test/browser/support/axe.ts','utf8'); for (const token of ['AxeBuilder','runAxeForTarget','writeAxeResult','assertNoCriticalOrSerious','wcag22aa','target-size','critical','serious','incomplete']) { if (!s.includes(token)) throw new Error('missing ' + token); }"` - PASS.
- `npx playwright test --list test/browser/specs/showcase.a11y.spec.ts` - PASS, 108 tests listed.
- `mix test test/oban_powertools/web/live/showcase_live_test.exs` - PASS, 6 tests.
- `npm run visual:a11y -- test/browser/specs/showcase.a11y.spec.ts` - PASS, 108 tests.
- `node` artifact check over `test-results/axe` - PASS, 108 JSON files with full result arrays.

## Next Phase Readiness

Plan 73-04 can consume the manifest, deterministic runtime, and verified accessibility path to add visual-regression screenshot capture and committed baselines.

## Self-Check: PASSED

- Found `test/browser/support/axe.ts` and `test/browser/specs/showcase.a11y.spec.ts`.
- Found task commits `3548ded` and `a73d90b` in git history.
- Verified the full Docker-backed axe matrix passes with full JSON artifacts emitted.

---
*Phase: 73-visual-regression-a11y-harness*
*Completed: 2026-06-19*
