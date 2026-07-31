---
phase: 73-visual-regression-a11y-harness
plan: 04
subsystem: testing
tags: [playwright, visual-regression, screenshots, showcase]

requires:
  - phase: 73-03
    provides: Deterministic browser path and green axe matrix
provides:
  - Story-level visual-regression spec
  - 108 committed Docker-generated PNG baselines
  - Green normal VRT compare mode
affects: [phase-73, visual-regression, showcase, ci]

tech-stack:
  added: []
  patterns:
    - Locator-level screenshots capture only catalog-backed story cells
    - Snapshot names use manifest `scenario.snapshot` and theme filenames
    - Baselines are generated through `npm run vrt:update` in the pinned Playwright Docker path

key-files:
  created:
    - test/browser/specs/showcase.vrt.spec.ts
    - test/browser/__screenshots__/chromium-*/showcase/*/*.png
  modified: []

key-decisions:
  - "Used `toHaveScreenshot([scenario.snapshot, `${theme}.png`])` so Playwright resolves paths to `test/browser/__screenshots__/{projectName}/showcase/{scenario-id}/{theme}.png`."
  - "Committed only expected PNG baselines under `test/browser/__screenshots__/`; generated manifest, reports, test-results, actuals, and diffs remain ignored."
  - "Kept the VRT spec mask-free because no volatile story pixels were proven."

patterns-established:
  - "`showcase.vrt.spec.ts` enumerates 9 manifest scenarios x 4 themes x 3 viewport projects."
  - "`npm run vrt:update` is the explicit local baseline update workflow."
  - "Normal `npm run visual:a11y -- test/browser/specs/showcase.vrt.spec.ts` compare mode is green after baseline generation."

requirements-completed: [VRT-01, VRT-02, VRT-03]

duration: 22 min
completed: 2026-06-19
status: complete
---

# Phase 73 Plan 04: Visual Regression Baselines Summary

**The showcase now has story-level Playwright VRT coverage with 108 committed PNG baselines generated in the pinned Docker browser environment.**

## Performance

- **Duration:** 22 min
- **Completed:** 2026-06-19
- **Tasks:** 2
- **Files modified:** 109

## Accomplishments

- Added `test/browser/specs/showcase.vrt.spec.ts`, scanning all generated manifest stories across all themes and Playwright viewport projects.
- Used locator-level `toHaveScreenshot` on each story cell rather than full-page screenshots.
- Generated 108 expected PNG baselines under `test/browser/__screenshots__/chromium-*/showcase/*/*.png`.
- Verified the baseline tree has 36 PNGs per viewport project and 27 per theme filename.
- Verified normal compare mode passes without snapshot update flags.

## Task Commits

1. **Task 1: Add story-level visual regression spec** - `fcb00af` (test)
2. **Task 2: Generate and verify committed baselines in Docker** - `a822d1c` (test)

## Files Created/Modified

- `test/browser/specs/showcase.vrt.spec.ts` - Manifest-backed story VRT matrix.
- `test/browser/__screenshots__/chromium-320/showcase/*/*.png` - 36 mobile story baselines.
- `test/browser/__screenshots__/chromium-tablet/showcase/*/*.png` - 36 tablet story baselines.
- `test/browser/__screenshots__/chromium-wide/showcase/*/*.png` - 36 wide story baselines.

## Decisions Made

- Passed `[scenario.snapshot, `${theme}.png`]` to Playwright so `scenario.snapshot` remains the complete relative manifest path and the spec adds only the theme filename.
- Cleared a partial baseline tree created by an accidental compare-mode run before executing the intended `npm run vrt:update` workflow.
- Visually sampled a generated baseline and confirmed it was a real story-cell crop with visible content.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Non-blocking] Used direct Playwright list check after npm wrapper argument loss**
- **Found during:** Task 1 verification
- **Issue:** `npm run visual:a11y -- test/browser/specs/showcase.vrt.spec.ts --list` did not propagate `--list` through the nested `npm run visual:a11y:docker` call and started compare mode before baselines existed.
- **Fix:** Stopped the run, cleared partial generated output, and used `npx playwright test --list test/browser/specs/showcase.vrt.spec.ts` for the list check.
- **Files modified:** None.
- **Verification:** Direct list check reported 108 tests; `npm run vrt:update` and normal compare mode passed.
- **Committed in:** N/A

---

**Total deviations:** 1 auto-fixed (0 blocking)
**Impact on plan:** No implementation change was needed; final update and compare commands used the planned Docker path.

## Issues Encountered

- The accidental compare-mode run created 49 partial expected PNGs before it was interrupted. They were untracked and removed before the authoritative `npm run vrt:update` baseline generation.

## User Setup Required

Docker must be available for `vrt:update` and normal `visual:a11y` browser runs.

## Verification

- `npx playwright test --list test/browser/specs/showcase.vrt.spec.ts` - PASS, 108 tests listed.
- `npm run vrt:update` - PASS, 108 tests while writing expected baselines.
- `test "$(find test/browser/__screenshots__ -name '*.png' | wc -l | tr -d ' ')" = "108"` - PASS.
- `find test/browser/__screenshots__ -name '*.png' | rg 'showcase/.*/showcase/' || true` - PASS, no repeated `showcase/` path segment.
- `npm run visual:a11y -- test/browser/specs/showcase.vrt.spec.ts` - PASS, 108 tests in normal compare mode.

## Next Phase Readiness

Plan 73-05 can wire the browser harness into CI, document local workflows, and add documentation contract checks.

## Self-Check: PASSED

- Found `test/browser/specs/showcase.vrt.spec.ts`.
- Found exactly 108 committed PNG baselines under `test/browser/__screenshots__/`.
- Found task commits `fcb00af` and `a822d1c` in git history.
- Verified normal Docker-backed compare mode passes without update flags.

---
*Phase: 73-visual-regression-a11y-harness*
*Completed: 2026-06-19*
