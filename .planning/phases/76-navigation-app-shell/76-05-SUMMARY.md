---
phase: 76
plan: 05
subsystem: navigation-app-shell
status: complete
completed: 2026-07-12T15:33:37Z
duration: 25m23s
executor: codex
tags:
  - browser-proof
  - visual-regression
  - accessibility
  - validation
dependency_graph:
  requires:
    - 76-01
    - 76-02
    - 76-03
    - 76-04
  provides:
    - shell-browser-behavior-proof
    - shell-vrt-baselines
    - phase-76-validation-evidence
  affects:
    - test/browser/specs/shell.behavior.spec.ts
    - test/browser/specs/showcase.structure.spec.ts
    - test/browser/__screenshots__/chromium-*/showcase/shell-*/*.png
    - .planning/phases/76-navigation-app-shell/76-VALIDATION.md
tech_stack:
  added:
    - Playwright shell VRT baselines
  patterns:
    - generated shellStories metadata drives browser proof
    - Docker-backed Playwright remains canonical for VRT baselines
key_files:
  created:
    - test/browser/__screenshots__/chromium-320/showcase/shell-*/*.png
    - test/browser/__screenshots__/chromium-tablet/showcase/shell-*/*.png
    - test/browser/__screenshots__/chromium-wide/showcase/shell-*/*.png
    - .planning/phases/76-navigation-app-shell/76-05-SUMMARY.md
  modified:
    - test/browser/specs/shell.behavior.spec.ts
    - test/browser/specs/showcase.structure.spec.ts
    - assets/oban_powertools/tokens.css
    - priv/static/oban_powertools/oban_powertools.css
    - test/oban_powertools/web/assets_test.exs
    - test/oban_powertools/web/theme_tokens_test.exs
    - .planning/phases/76-navigation-app-shell/76-VALIDATION.md
decisions:
  - Treat Docker-backed Playwright as canonical for shell VRT baselines because `npm run vrt:update` writes baselines through `scripts/playwright-docker.sh`.
  - Keep 320-only disclosure and overflow assertions mobile-scoped while wide browser proof still verifies visible nav, route, theme, and focus behavior.
  - Make the structure spec title include target kinds so `--grep shell` selects existing shell-inclusive structure coverage.
metrics:
  tasks_completed: 2
  files_changed: 79
  shell_png_baselines: 72
  verification_commands: 11
---

# Phase 76 Plan 05: Navigation App Shell Validation Summary

Closed Phase 76 with targeted shell browser behavior proof, 72 shell-only VRT baselines, focused shell accessibility evidence, and final validation metadata.

## Work Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Finalize targeted shell browser behavior proof | `bfee582` | `test/browser/specs/shell.behavior.spec.ts`, shell CSS/static guards |
| 2 | Generate shell VRT baselines and record final validation evidence | `f517b9c` | 72 shell PNG baselines, `76-VALIDATION.md`, `showcase.structure.spec.ts` |

## Verification

| Command | Result |
|---------|--------|
| `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/shell.behavior.spec.ts --project chromium-320` | Passed: 12 tests |
| `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/shell.behavior.spec.ts --project chromium-wide` | Passed: 8 tests, 4 mobile-only checks skipped |
| `npm run vrt:update -- --grep shell` | Passed: 72 shell VRT targets generated/updated |
| Shell baseline cardinality Node check | Passed: `FOUND 72 shell baselines` |
| `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/showcase.structure.spec.ts --project chromium-320 --grep shell` | Passed: 4 tests |
| `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/showcase.a11y.spec.ts --project chromium-320 --grep shell` | Passed: 24 tests |
| `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:docker -- test/browser/specs/showcase.vrt.spec.ts --project chromium-320 --grep shell` | Passed: 24 tests |
| `mix test test/oban_powertools/web/components/app_shell_test.exs test/oban_powertools/web/live/app_shell_layout_test.exs test/oban_powertools/shell_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs --seed 0` | Passed: 42 tests |
| `mix compile --warnings-as-errors` | Passed |

The exact planned host VRT compare command for `showcase.vrt.spec.ts` failed with 24 host screenshot diffs because the repository writes VRT baselines with Docker-backed Playwright while the macOS host browser renders different element heights. The canonical Docker compare, using the same runner as baseline generation, passed and is recorded in `76-VALIDATION.md`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Scoped closed-shell nav CSS to the production shell**
- **Found during:** Task 1 browser behavior proof.
- **Issue:** The closed-nav selector hid nested showcase shell navs because it used a descendant selector from `.obpt-app-shell`.
- **Fix:** Changed the selector to target the production shell header direct child nav only.
- **Files modified:** `assets/oban_powertools/tokens.css`, `priv/static/oban_powertools/oban_powertools.css`, `test/oban_powertools/web/assets_test.exs`, `test/oban_powertools/web/theme_tokens_test.exs`.
- **Commit:** `bfee582`

**2. [Rule 1 - Bug] Kept shell showcase stories inspectable at wide viewport**
- **Found during:** Task 1 browser behavior proof.
- **Issue:** App-shell stories inside the generic showcase grid could collapse to a zero-width nav at wide viewport.
- **Fix:** Added a shell-section grid rule forcing app-shell showcase stories into a single minmax column.
- **Files modified:** `assets/oban_powertools/tokens.css`, `priv/static/oban_powertools/oban_powertools.css`, `test/oban_powertools/web/assets_test.exs`, `test/oban_powertools/web/theme_tokens_test.exs`.
- **Commit:** `bfee582`

**3. [Rule 3 - Blocking verification harness] Made structure spec selectable by `--grep shell`**
- **Found during:** Task 2 focused structure verification.
- **Issue:** The planned command `--grep shell` selected zero tests because structure spec titles did not include target kinds.
- **Fix:** Updated the title to include `scenario primitive form shell targets`; assertions were unchanged.
- **Files modified:** `test/browser/specs/showcase.structure.spec.ts`.
- **Commit:** `f517b9c`

### Residuals Documented

- The planned host VRT compare remains red for shell screenshots because host and Docker Playwright render different screenshot heights. The canonical Docker compare passed for the shell VRT proof.
- Broad aggregate `visual:a11y` still includes older scenario-only VRT drift documented before this plan. This plan updated only shell baselines.
- Mix commands printed expired Hex authentication and dependency advisory warnings but continued successfully; no package install or private dependency access occurred.

## Auth Gates

None. The Hex warning was non-blocking and did not prevent compilation or tests.

## Known Stubs

None. Stub-pattern scanning found only the existing `.obpt-showcase-placeholder` CSS class name, which is styling rather than hardcoded empty/mock shell data.

## Threat Flags

None. This plan added browser tests, screenshot baselines, CSS fixes, and validation metadata; it did not introduce new network endpoints, auth paths, file access patterns, or schema trust boundaries.

## Self-Check: PASSED

- Found `.planning/phases/76-navigation-app-shell/76-05-SUMMARY.md`.
- Found `.planning/phases/76-navigation-app-shell/76-VALIDATION.md`.
- Found task commits `bfee582` and `f517b9c`.
- Confirmed 72 shell VRT baseline PNGs exist.
