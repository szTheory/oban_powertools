---
phase: 72-stress-fixtures-showcase-skeleton
plan: 01
subsystem: testing
tags: [exunit, fixtures, showcase, hex-package, red-contracts]

requires:
  - phase: 71-token-layer-isolated-theming-engine
    provides: library-owned priv/static/oban_powertools CSS/JS assets and package inclusion contract
provides:
  - RED contract tests for ObanPowertools.ShowcaseCatalog public fixture API
  - RED Hex package assertions for local-only Phase 72 fixture catalog exclusion
  - Package unpack proof that Phase 71 runtime assets still ship while test/planning/catalog artifacts stay out
affects: [phase-72, fixture-catalog, showcase, package-release, phase-73-vrt-a11y]

tech-stack:
  added: []
  patterns: [validation-first ExUnit contracts, deterministic fixture API contract, Hex package boundary assertions]

key-files:
  created:
    - test/oban_powertools/showcase_catalog_test.exs
  modified:
    - test/oban_powertools/hex_release_test.exs

key-decisions:
  - "Catalog tests pin the initial nine scenario IDs as the public selector/snapshot contract."
  - "snapshot_name/1 is contracted as showcase/{scenario_id}; a11y_target/1 is contracted as [data-obpt-story=\"{scenario_id}\"]."
  - "Hex release tests require the canonical catalog source at test/support/showcase_catalog.ex for local dev/test while rejecting it from package files."

patterns-established:
  - "Phase 72 RED tests intentionally fail only on the absent ShowcaseCatalog module or absent canonical catalog source."
  - "Package tests keep Phase 71 priv/static assets required while extending exclusions for Phase 72 support artifacts."

requirements-completed: [FIX-01, FIX-02, FIX-03, SHOW-03]

duration: 6 min
completed: 2026-06-18
status: complete
---

# Phase 72 Plan 01: RED Fixture Catalog And Package Boundary Summary

**Validation-first RED contracts for deterministic showcase fixtures and Hex package exclusion**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-18T23:33:04Z
- **Completed:** 2026-06-18T23:39:10Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `ObanPowertools.ShowcaseCatalogTest` covering D-01 through D-05 with exact domain ordering, required state tags, persona/JTBD coverage, deterministic scenario IDs, scenario metadata, `scenario!/1`, `snapshot_name/1`, and `a11y_target/1`.
- Extended `ObanPowertools.HexReleaseTest` so Phase 72 requires the canonical local catalog path `test/support/showcase_catalog.ex` while preserving Phase 71 `priv/static/oban_powertools` package requirements.
- Verified the package unpack boundary still includes `priv/static/oban_powertools/oban_powertools.css` and `.js` and excludes `test`, `.planning`, and `showcase_catalog.ex`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add RED catalog contract tests** - `59fe053` (test)
2. **Task 2: Extend package boundary tests for fixture exclusion** - `21aff32` (test)

## Files Created/Modified

- `test/oban_powertools/showcase_catalog_test.exs` - New RED catalog API contract for the future `ObanPowertools.ShowcaseCatalog`.
- `test/oban_powertools/hex_release_test.exs` - Added Phase 72 local-only catalog and package exclusion assertions.

## Decisions Made

- Contracted snapshot names as `showcase/#{scenario_id}` to keep VRT names independent of display copy.
- Contracted a11y targets as `[data-obpt-story="#{scenario_id}"]` to align with D-02 stable selector guidance.
- Kept Task 2 focused on `Mix.Project.config()[:package][:files]` and asset existence; no `mix.exs` package changes were made in this RED plan.

## Verification

- `mix test test/oban_powertools/showcase_catalog_test.exs` - EXPECTED RED. Result: 7 tests, 7 failures, all caused by `UndefinedFunctionError` for missing `ObanPowertools.ShowcaseCatalog` functions/module. App and test boot succeeded.
- `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` - EXPECTED RED. Result: 36 tests, 1 failure, caused only by missing `test/support/showcase_catalog.ex`; the existing 35 package/release checks passed.
- Phase package unpack proof - PASSED:
  - `rm -rf /tmp/obpt_phase72_pkg`
  - `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix hex.build --unpack -o /tmp/obpt_phase72_pkg`
  - `test -n "$(find /tmp/obpt_phase72_pkg -path '*/priv/static/oban_powertools/oban_powertools.css' -print -quit)"`
  - `test -n "$(find /tmp/obpt_phase72_pkg -path '*/priv/static/oban_powertools/oban_powertools.js' -print -quit)"`
  - `test ! -e /tmp/obpt_phase72_pkg/test/support/showcase_catalog.ex`
  - `! find /tmp/obpt_phase72_pkg -type f | rg '(^|/)(showcase_catalog\.ex|\.planning|test)(/|$)'`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Bootstrapped existing locked Mix dependencies in fresh worktree**
- **Found during:** Task 1 verification
- **Issue:** The isolated worktree had no fetched Mix dependencies, so the first targeted test command stopped before compiling or running tests.
- **Fix:** Ran `mix deps.get` for the existing `mix.lock` dependencies only. No package names were changed, no alternatives were installed, and no tracked dependency files changed.
- **Files modified:** None
- **Verification:** Re-running both targeted commands reached ExUnit and produced only the intended RED failures.
- **Committed in:** Not applicable - environment bootstrap only

---

**Total deviations:** 1 auto-fixed blocking environment issue.
**Impact on plan:** No scope change and no tracked dependency changes. The RED test outcomes are valid.

## Issues Encountered

- The catalog test command is intentionally RED until Plan 72-03 implements `ObanPowertools.ShowcaseCatalog`.
- The package test command is intentionally RED until Plan 72-03 adds `test/support/showcase_catalog.ex`.

## Known Stubs

None - this plan added RED tests only. No UI stubs or mock data sources were introduced.

## User Setup Required

None - no external service configuration required.

## Parallel Worktree Notes

No `.planning/STATE.md`, `.planning/ROADMAP.md`, or `.planning/REQUIREMENTS.md` updates were made. The execute-phase orchestrator owns shared tracking after merging worktrees.

## Self-Check: PASSED

- `test/oban_powertools/showcase_catalog_test.exs` exists and defines `ObanPowertools.ShowcaseCatalogTest`.
- `test/oban_powertools/hex_release_test.exs` contains Phase 71 asset assertions plus Phase 72 `test/support/showcase_catalog.ex` package exclusion assertions.
- `git log --oneline --grep="72-01"` shows task commits `59fe053` and `21aff32`.
- `git status --short` was clean before summary creation.

## Next Phase Readiness

Ready for Plan 72-03 to implement the canonical deterministic catalog and turn these RED contracts green.

---
*Phase: 72-stress-fixtures-showcase-skeleton*
*Completed: 2026-06-18*
