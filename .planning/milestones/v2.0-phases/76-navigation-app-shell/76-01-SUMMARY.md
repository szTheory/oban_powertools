---
phase: 76-navigation-app-shell
plan: 01
subsystem: testing
tags: [phoenix-liveview, exunit, playwright, app-shell, navigation, accessibility]

requires:
  - phase: 76-navigation-app-shell-planning
    provides: UI-SPEC, RESEARCH, PATTERNS, and VALIDATION contracts for Phase 76
provides:
  - RED AppShell render and source contracts for the future shell component
  - RED native-route layout contracts for ThemeShell and current-path plumbing
  - RED shell story catalog and Playwright behavior contracts
affects: [76-02, 76-03, 76-04, 76-05, navigation-app-shell]

tech-stack:
  added: []
  patterns:
    - Phoenix.LiveViewTest component and route contracts that fail on missing Phase 76 modules
    - Playwright manifest contract that fails until shellStories is exported

key-files:
  created:
    - test/oban_powertools/web/components/app_shell_test.exs
    - test/oban_powertools/web/live/app_shell_layout_test.exs
    - test/oban_powertools/shell_story_catalog_test.exs
    - test/browser/specs/shell.behavior.spec.ts
    - .planning/phases/76-navigation-app-shell/76-01-SUMMARY.md
  modified: []

key-decisions:
  - "Plan 76-01 remains RED-only: failures are valid only when they point at missing Phase 76 shell, layout, catalog, or manifest implementation artifacts."
  - "The Playwright shell behavior file includes a module-load guard so the RED phase proves the generated manifest must export shellStories before browser evidence can run."

patterns-established:
  - "Shared shell data attributes are pinned across component, layout, catalog, and browser tests before implementation."
  - "Native routes are mounted through existing LiveCase/session helpers so layout failures isolate shell integration rather than auth or fixture setup."

requirements-completed:
  - NAV-01
  - NAV-02
  - NAV-03
  - NAV-04
  - A11Y-02
  - "COPY-* (nav labels)"

duration: 12min
completed: 2026-07-12
status: complete
---

# Phase 76 Plan 01: RED Navigation App Shell Contracts Summary

**RED Phoenix and Playwright contracts for the Phase 76 app shell, route-aware navigation, shell stories, and browser behavior.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-12T13:59:31Z
- **Completed:** 2026-07-12T14:10:23Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added AppShell component render/source contracts covering the header, nine native nav surfaces, theme choices, actor copy, breadcrumbs, skip link, nav state, and caller attribute filtering.
- Added native LiveView layout contracts proving the future shell wraps `/ops/jobs` routes and derives current nav/breadcrumb state from server-side path context.
- Added shell story catalog and Playwright browser contracts covering deterministic shell stories, mobile disclosure, skip-link focus, theme state, visible focus, and 320px overflow.

## Task Commits

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Write AppShell render and source contracts | `5828df1` | `test/oban_powertools/web/components/app_shell_test.exs` |
| 2 | Write ThemeShell and current-path integration contracts | `8db3f88` | `test/oban_powertools/web/live/app_shell_layout_test.exs` |
| 3 | Write shell story catalog and browser behavior contracts | `4b415d5` | `test/oban_powertools/shell_story_catalog_test.exs`, `test/browser/specs/shell.behavior.spec.ts` |

## Files Created/Modified

- `test/oban_powertools/web/components/app_shell_test.exs` - RED AppShell render/source contract for NAV-01, NAV-02, NAV-03, NAV-04, A11Y-02, and COPY-*.
- `test/oban_powertools/web/live/app_shell_layout_test.exs` - RED ThemeShell/LiveAuth native-route layout contract.
- `test/oban_powertools/shell_story_catalog_test.exs` - RED deterministic shell story catalog contract.
- `test/browser/specs/shell.behavior.spec.ts` - RED Playwright shell behavior and manifest export contract.
- `.planning/phases/76-navigation-app-shell/76-01-SUMMARY.md` - Execution summary and verification record.

## Decisions Made

- Kept Plan 76-01 strictly test-only. No production shell, CSS, JS, catalog, or manifest implementation was added.
- Added an explicit Playwright module-load guard for `shellStories` so `npx playwright test --list` is RED until the generated support manifest exposes the required shell story export.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed AppShell contract syntax before committing**
- **Found during:** Task 1 (Write AppShell render and source contracts)
- **Issue:** Initial draft had invalid test syntax around a quoted script assertion and module attribute setup.
- **Fix:** Rewrote the assertions as valid Elixir and formatted the file.
- **Files modified:** `test/oban_powertools/web/components/app_shell_test.exs`
- **Verification:** `mix format --check-formatted test/oban_powertools/web/components/app_shell_test.exs`; `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0`
- **Committed in:** `5828df1`

**2. [Rule 1 - Bug] Fixed layout contract setup so failures isolate shell markup**
- **Found during:** Task 2 (Write ThemeShell and current-path integration contracts)
- **Issue:** The initial route assertion expected stale overview copy and would have failed before reaching the shell integration contract.
- **Fix:** Updated the assertion to the current route copy and kept workflow fixture setup inside existing LiveCase patterns.
- **Files modified:** `test/oban_powertools/web/live/app_shell_layout_test.exs`
- **Verification:** `mix format --check-formatted test/oban_powertools/web/live/app_shell_layout_test.exs`; `mix test test/oban_powertools/web/live/app_shell_layout_test.exs --seed 0`
- **Committed in:** `8db3f88`

**3. [Rule 1 - Bug] Made Playwright RED behavior observable at list time**
- **Found during:** Task 3 (Write shell story catalog and browser behavior contracts)
- **Issue:** `npx playwright test --list` passed unexpectedly because the missing manifest export was not touched while listing tests.
- **Fix:** Added a top-level guard requiring `shellStories` to be an array.
- **Files modified:** `test/browser/specs/shell.behavior.spec.ts`
- **Verification:** `npx playwright test --list test/browser/specs/shell.behavior.spec.ts`
- **Committed in:** `4b415d5`

---

**Total deviations:** 3 auto-fixed Rule 1 bugs.
**Impact on plan:** All fixes kept the plan test-only and made the RED contracts fail on the intended missing Phase 76 artifacts.

## Issues Encountered

- Expected RED: `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` exits with 11 failures requiring `ObanPowertools.Web.Components.AppShell`, `lib/oban_powertools/web/components/app_shell.ex`, and future helper functions.
- Expected RED: `mix test test/oban_powertools/web/live/app_shell_layout_test.exs --seed 0` exits with 3 failures for missing app-shell wrapper/current nav/breadcrumb behavior and `main#obpt-main` integration.
- Expected RED: `mix test test/oban_powertools/shell_story_catalog_test.exs --seed 0` exits with 4 failures requiring `ObanPowertools.ShellStoryCatalog` and future helper functions.
- Expected RED: `npx playwright test --list test/browser/specs/shell.behavior.spec.ts` exits with `Missing shellStories export in generated showcase manifest support`.

## Command Results

| Command | Result |
| ------- | ------ |
| `mix format --check-formatted test/oban_powertools/web/components/app_shell_test.exs test/oban_powertools/web/live/app_shell_layout_test.exs test/oban_powertools/shell_story_catalog_test.exs` | PASS |
| `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` | RED as expected: 11 failures limited to missing AppShell/source/helpers |
| `mix test test/oban_powertools/web/live/app_shell_layout_test.exs --seed 0` | RED as expected: 3 failures limited to missing shell/current-path markup |
| `mix test test/oban_powertools/shell_story_catalog_test.exs --seed 0` | RED as expected: 4 failures limited to missing ShellStoryCatalog/helpers |
| `npx playwright test --list test/browser/specs/shell.behavior.spec.ts` | RED as expected: missing `shellStories` manifest export |

## Known Stubs

None - stub scan found no TODO, FIXME, placeholder, coming soon, not available, or empty UI data markers in the files created by this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 76-02 can implement `ObanPowertools.Web.Components.AppShell`, ThemeShell integration, current-path assigns, and helper functions against the RED contracts created here. Plans 76-04 and 76-05 can use the shell story and browser contracts to wire manifest support and collect behavior/VRT evidence.

## Self-Check: PASSED

- Found `test/oban_powertools/web/components/app_shell_test.exs`
- Found `test/oban_powertools/web/live/app_shell_layout_test.exs`
- Found `test/oban_powertools/shell_story_catalog_test.exs`
- Found `test/browser/specs/shell.behavior.spec.ts`
- Found `.planning/phases/76-navigation-app-shell/76-01-SUMMARY.md`
- Found task commit `5828df1`
- Found task commit `8db3f88`
- Found task commit `4b415d5`

---
*Phase: 76-navigation-app-shell*
*Completed: 2026-07-12*
