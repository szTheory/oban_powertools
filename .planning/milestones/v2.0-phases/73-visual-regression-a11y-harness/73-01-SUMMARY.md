---
phase: 73-visual-regression-a11y-harness
plan: 01
subsystem: testing
tags: [playwright, axe, visual-regression, accessibility, showcase]

requires:
  - phase: 72-03
    provides: Canonical deterministic scenario catalog and target helpers
provides:
  - Exact root npm development tooling for Playwright and axe
  - Deterministic showcase manifest generated from ObanPowertools.ShowcaseCatalog
  - TypeScript and Node validators for manifest shape and selector contracts
affects: [phase-73, visual-regression, accessibility, showcase, ci]

tech-stack:
  added:
    - "@playwright/test@1.61.0"
    - "@axe-core/playwright@4.11.3"
    - "axe-core@4.11.4"
  patterns:
    - Root npm tooling is private, lockfile-backed, and development/test-only
    - Browser target manifests are generated from Elixir catalog helpers

key-files:
  created:
    - package.json
    - package-lock.json
    - scripts/showcase_manifest.exs
    - test/browser/support/manifest.ts
    - test/browser/support/manifest-smoke.mjs
  modified:
    - .gitignore
    - package.json

key-decisions:
  - "Generated browser target data from ObanPowertools.ShowcaseCatalog rather than copying scenario IDs into TypeScript."
  - "Kept generated manifest output ignored while leaving future screenshot baselines commit-eligible."
  - "Made npm manifest generation compile quietly before redirecting JSON so cold Mix builds cannot corrupt the manifest file."

patterns-established:
  - "showcase:manifest writes test/browser/.generated/showcase-manifest.json with no timestamps, absolute paths, or randomized values."
  - "Manifest validation fails fast on missing files, malformed schema, unknown themes/viewports, or drifted story/snapshot/a11y selectors."

requirements-completed: [VRT-01, VRT-03, A11Y-01]

duration: 4 min
completed: 2026-06-19
status: complete
---

# Phase 73 Plan 01: Root Node Tooling and Showcase Manifest Summary

**Lockfile-backed Playwright/axe tooling now consumes a deterministic JSON manifest generated from the Elixir showcase catalog.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-19T15:56:38Z
- **Completed:** 2026-06-19T16:00:58Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added private root npm tooling with exact Playwright and axe dev dependency pins.
- Added scripts for manifest generation, local host runs, Docker harness runs, and changed-only snapshot updates.
- Added generated-output ignores for Playwright reports, test results, and the generated manifest while keeping future PNG baselines committable.
- Added `scripts/showcase_manifest.exs`, deriving all browser targets from `ObanPowertools.ShowcaseCatalog`.
- Added TypeScript and Node manifest validators that enforce schema, theme, viewport, story, snapshot, and a11y selector contracts.

## Task Commits

1. **Task 1: Add exact Node tooling and generated-output ignores** - `9d8ccba` (chore)
2. **Task 2: Generate and validate the showcase manifest** - `40b693e` (feat)

## Files Created/Modified

- `package.json` - Private root npm package with exact dev dependency pins and visual/a11y scripts.
- `package-lock.json` - Lockfile for the approved Playwright and axe dependency tree.
- `.gitignore` - Ignores Node dependencies and generated browser harness outputs.
- `scripts/showcase_manifest.exs` - Emits catalog-derived deterministic JSON.
- `test/browser/support/manifest.ts` - Loads and validates generated manifest data for Playwright specs.
- `test/browser/support/manifest-smoke.mjs` - Validates generated manifest shape without Playwright.

## Decisions Made

- Generated manifest data from `ObanPowertools.ShowcaseCatalog.scenarios/0`, `snapshot_name/1`, and `a11y_target/1`; TypeScript does not own a copied scenario list.
- Treated `test/browser/.generated/` as reproducible output and kept `test/browser/__screenshots__/` available for committed baselines.
- Compiled Mix quietly before manifest redirection so first-run compiler output cannot become invalid JSON.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Prevented Mix compile output from corrupting generated JSON**
- **Found during:** Task 2 (Generate and validate the showcase manifest)
- **Issue:** On a cold build, `mix run` printed `Compiling ...` before the JSON payload, and the npm redirection wrote invalid JSON into `test/browser/.generated/showcase-manifest.json`.
- **Fix:** Updated `showcase:manifest` to run `MIX_ENV=test mix compile --quiet` first, then run the generator with `--no-compile` for JSON-only stdout.
- **Files modified:** `package.json`
- **Verification:** `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs`
- **Committed in:** `40b693e`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix preserves the planned interface and makes manifest generation reliable on clean checkouts.

## Issues Encountered

- Initial manifest smoke validation failed because Mix compiler output preceded the JSON payload. Resolved by the deviation above.

## User Setup Required

None - no external service configuration required.

## Verification

- `node -e "const fs=require('fs'); const p=JSON.parse(fs.readFileSync('package.json','utf8')); const deps=p.devDependencies||{}; for (const [name, version] of Object.entries({'@playwright/test':'1.61.0','@axe-core/playwright':'4.11.3','axe-core':'4.11.4'})) { if (deps[name] !== version) throw new Error(name + ' must be pinned to ' + version); } for (const script of ['showcase:manifest','visual:a11y','visual:a11y:host','visual:a11y:docker','vrt:update']) { if (!p.scripts || !p.scripts[script]) throw new Error('missing script ' + script); } if (p.private !== true) throw new Error('private must be true'); console.log('package metadata ok')"` - PASS.
- `node -e "const fs=require('fs'); const lock=JSON.parse(fs.readFileSync('package-lock.json','utf8')); for (const name of ['node_modules/@playwright/test','node_modules/@axe-core/playwright','node_modules/axe-core']) { if (!lock.packages || !lock.packages[name]) throw new Error('missing lock entry ' + name); } console.log('lockfile entries ok')"` - PASS.
- `node -e "const fs=require('fs'); const gi=fs.readFileSync('.gitignore','utf8'); for (const item of ['/playwright-report/','/test-results/','/test/browser/.generated/']) { if (!gi.includes(item)) throw new Error('missing ignore ' + item); } if (gi.includes('test/browser/__screenshots__/')) throw new Error('screenshots must remain commit-eligible'); console.log('gitignore ok')"` - PASS.
- `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` - PASS, 9 scenarios, 4 themes, 3 viewports.
- `rg -n "overview-operational-empty|jobs-long-identifiers-many|batches-high-count-mixed-severity|workflows-stale-disconnected-dag|cron-permission-denied|limiters-boundary-pagination|lifeline-repair-preview|audit-non-ascii-rtl|forensics-long-url-stacktrace" test/browser/support/manifest.ts test/browser/support/manifest-smoke.mjs scripts/showcase_manifest.exs` - PASS, no copied scenario IDs in Node/TypeScript support.

## Next Phase Readiness

Plan 73-02 can consume the npm scripts and generated manifest to add the Playwright runtime, host/Docker wrappers, deterministic browser setup, and structure smoke tests.

## Self-Check: PASSED

- Found `package.json`, `package-lock.json`, `scripts/showcase_manifest.exs`, `test/browser/support/manifest.ts`, and `test/browser/support/manifest-smoke.mjs`.
- Found task commits `9d8ccba` and `40b693e` in git history.
- Verified generated manifest count and selector contracts.

---
*Phase: 73-visual-regression-a11y-harness*
*Completed: 2026-06-19*
