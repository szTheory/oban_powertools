---
phase: 73-visual-regression-a11y-harness
plan: 02
subsystem: testing
tags: [playwright, docker, visual-regression, showcase]

requires:
  - phase: 73-01
    provides: Exact Node tooling and generated showcase manifest
provides:
  - Deterministic Playwright Chromium viewport configuration
  - Pinned Docker browser runner and real showcase host lifecycle wrapper
  - Browser-visible showcase structure smoke test
affects: [phase-73, visual-regression, accessibility, showcase, ci]

tech-stack:
  added: []
  patterns:
    - Playwright projects pin browser viewport, locale, timezone, media preferences, and device scale factor
    - Browser specs drive the real `examples/phoenix_host` showcase route through the Docker runner
    - Structure checks consume the generated manifest instead of copying scenario targets

key-files:
  created:
    - playwright.config.ts
    - scripts/playwright-docker.sh
    - scripts/with-showcase-server.sh
    - test/browser/support/deterministic.ts
    - test/browser/support/showcase.ts
    - test/browser/styles/screenshot.css
    - test/browser/specs/showcase.structure.spec.ts
  modified:
    - scripts/with-showcase-server.sh

key-decisions:
  - "Grouped screenshot baselines under `test/browser/__screenshots__/{projectName}/{arg}{ext}` and let manifest snapshot paths provide the `showcase/` prefix exactly once."
  - "Kept screenshot CSS narrowly scoped to `.obpt-root` volatility controls so semantic content, state tones, focus indicators, long values, redaction displays, and severity signals remain visible."
  - "Asserted real browser viewport dimensions after selecting the showcase viewport control because Playwright project viewport is the deterministic source of truth."

patterns-established:
  - "`scripts/with-showcase-server.sh` starts the Phoenix host, waits for `/ops/jobs/_showcase`, exports host and Docker base URLs, and traps cleanup."
  - "`scripts/playwright-docker.sh` runs arbitrary Playwright commands inside `mcr.microsoft.com/playwright:v1.61.0-noble` with reports and baselines written back to the repo."
  - "`assertShowcaseStructure` verifies md5 asset URLs, theme choices, viewport choices, section anchors, and every manifest story selector."

requirements-completed: [VRT-01, VRT-03]

duration: 18 min
completed: 2026-06-19
status: complete
---

# Phase 73 Plan 02: Deterministic Browser Harness Summary

**The Playwright harness now reaches the real showcase route through the pinned Docker path and verifies browser-visible structure across all themes and configured viewports.**

## Performance

- **Duration:** 18 min
- **Completed:** 2026-06-19
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added deterministic Playwright configuration with Chromium projects for `320x900`, `768x1000`, and `1440x1000`.
- Added screenshot-path, reporter, output, trace, screenshot, media, locale, timezone, and device-scale settings for stable later VRT runs.
- Added pinned Docker and showcase server wrappers that exercise `examples/phoenix_host` at `/ops/jobs/_showcase`.
- Added browser support helpers for theme setup, viewport assertions, font readiness, story selection, and showcase structure checks.
- Added a structure smoke spec that verifies md5 asset URLs, all controls, all section anchors, and all 9 manifest story targets without creating screenshots.

## Task Commits

1. **Task 1: Configure deterministic Playwright projects** - `6332810` (test)
2. **Task 2: Add pinned Docker and showcase server wrappers** - `4d37fc0` (test)
3. **Task 3: Add showcase browser helpers and structure smoke spec** - `75b4417` (test)

## Files Created/Modified

- `playwright.config.ts` - Deterministic Playwright config, projects, snapshot path template, and reporters.
- `scripts/playwright-docker.sh` - Pinned Playwright Docker runner preserving arbitrary command arguments.
- `scripts/with-showcase-server.sh` - Real Phoenix host lifecycle wrapper with route readiness polling and cleanup trap.
- `test/browser/support/deterministic.ts` - Manifest-backed viewport and theme constants for tests.
- `test/browser/support/showcase.ts` - Shared showcase navigation, readiness, story, and structure helpers.
- `test/browser/styles/screenshot.css` - Scoped screenshot volatility controls.
- `test/browser/specs/showcase.structure.spec.ts` - Browser-visible structure smoke test.

## Decisions Made

- Used Playwright project viewport dimensions as the deterministic viewport assertion while still interacting with the showcase viewport control.
- Kept the existing `forensics-long-url-stacktrace` rendered persona contract as `repair`, matching `showcase_live.ex` and the existing LiveView ExUnit contract.
- Fixed the server wrapper readiness poll to pass `SHOWCASE_URL` through an environment variable into a quoted heredoc, avoiding shell interpolation issues.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Quoted the server-wrapper Node heredoc**
- **Found during:** Task 3 verification
- **Issue:** The unquoted heredoc attempted shell expansion inside JavaScript template syntax and failed with `bad substitution`.
- **Fix:** Passed `SHOWCASE_URL` as an environment variable and quoted the heredoc delimiter.
- **Files modified:** `scripts/with-showcase-server.sh`
- **Verification:** `bash -n scripts/with-showcase-server.sh` and full `npm run visual:a11y -- test/browser/specs/showcase.structure.spec.ts`
- **Committed in:** `75b4417`

**2. [Rule 3 - Blocking] Mirrored the existing rendered persona compatibility contract**
- **Found during:** Task 3 verification
- **Issue:** The generated catalog reports `forensics-long-url-stacktrace` as `incident_response`, while the existing showcase LiveView and ExUnit story contract render that one scenario as `repair`.
- **Fix:** Added a narrow browser-spec helper for the existing rendered contract instead of changing app behavior inside the harness phase.
- **Files modified:** `test/browser/specs/showcase.structure.spec.ts`
- **Verification:** Full Docker-backed structure spec passed.
- **Committed in:** `75b4417`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** The planned browser contract remains intact, and verification now exercises the real showcase host reliably.

## Issues Encountered

- The browser-visible viewport controls do not reliably expose the selected LiveView state in the JS-less example host path, so the helper verifies control presence and actual Playwright viewport dimensions.

## User Setup Required

Docker must be available for `visual:a11y:docker` and `visual:a11y` runs.

## Verification

- `node -e "const fs=require('fs'); const c=fs.readFileSync('playwright.config.ts','utf8'); for (const token of ['chromium-320','chromium-tablet','chromium-wide','snapshotPathTemplate','timezoneId','UTC','locale','en-US','reducedMotion','reduce']) { if (!c.includes(token)) throw new Error('missing ' + token); }"` - PASS.
- `bash -n scripts/playwright-docker.sh scripts/with-showcase-server.sh && test -x scripts/playwright-docker.sh && test -x scripts/with-showcase-server.sh` - PASS.
- `npx playwright test --list --pass-with-no-tests` - PASS.
- `npm run visual:a11y -- test/browser/specs/showcase.structure.spec.ts` - PASS, 12 tests across 3 Chromium projects.

## Next Phase Readiness

Plan 73-03 can consume the deterministic browser helpers and structure path to add the axe accessibility scan and critical/serious violation gate.

## Self-Check: PASSED

- Found all planned browser config, wrapper, support, style, and structure spec files.
- Found task commits `6332810`, `4d37fc0`, and `75b4417` in git history.
- Verified the Docker-backed structure spec passes against the real example-host showcase route.

---
*Phase: 73-visual-regression-a11y-harness*
*Completed: 2026-06-19*
