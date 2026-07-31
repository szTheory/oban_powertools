---
phase: 71-token-layer-isolated-theming-engine
plan: 04
subsystem: web
tags: [theme-shell, live-session, assets]
requires:
  - phase: 71-token-layer-isolated-theming-engine
    provides: 71-03 md5 asset paths and routes
provides:
  - ObanPowertools.Web.ThemeShell.live/1
  - Native Powertools live_session layout wiring
  - Single .obpt-root shell with system default theme state
affects: [router, jobs-live-rendering, example-host]
tech-stack:
  added: []
  patterns: [Phoenix LiveView layout component, library-owned scoped shell]
key-files:
  created:
    - lib/oban_powertools/web/theme_shell.ex
  modified:
    - lib/oban_powertools/web/router.ex
key-decisions:
  - "ThemeShell owns the Powertools asset tags and `.obpt-root`; host root layouts remain untouched."
  - "The optional Oban Web bridge stays outside the native Powertools live_session layout."
patterns-established:
  - "Native Powertools LiveViews receive asset tags and scoped theme defaults through one router-level layout."
  - "The first child inside `.obpt-root` is the external theme script, followed by `main.obpt-shell` content."
requirements-completed: [TOKEN-02, TOKEN-04, TOKEN-05]
duration: 4 min
completed: 2026-06-18
status: complete
---

# Phase 71 Plan 04: Theme Shell Summary

**Library-owned LiveView shell integration for scoped Powertools theming**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-18T19:29:00Z
- **Completed:** 2026-06-18T19:32:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `ObanPowertools.Web.ThemeShell.live/1` as the native LiveView layout component.
- Rendered the md5 stylesheet link through `ObanPowertools.Web.Assets.path(:css)`.
- Added the single `.obpt-root` wrapper with system default theme attributes, safe motion defaults, the external md5 theme script, and `main.obpt-shell`.
- Wired the existing `:oban_powertools_native` live session to the shell while preserving LiveAuth, session data, route list, dev brand-book route, and bridge placement.

## Task Commits

Each task was committed atomically:

1. **Task 1: Theme shell layout** - `365f2e3` (feat)
2. **Task 2: Native live_session wiring** - `af1ae33` (feat)

## Files Created/Modified

- `lib/oban_powertools/web/theme_shell.ex` - Library-owned layout wrapper with CSS/JS asset tags and `.obpt-root`.
- `lib/oban_powertools/web/router.ex` - Applies the shell layout to native Powertools LiveViews.

## Decisions Made

- Kept the shell as a normal Phoenix component layout instead of altering any host root layout.
- Left proof-seam JobsLive class migration for `71-05`; this plan only establishes the shared shell boundary.

## Deviations from Plan

None.

## Issues Encountered

The full JobsLive verification command remains red until `71-05` migrates the planned proof seam classes:

- missing `obpt-tab` / `obpt-tab--active`
- missing `obpt-badge` / `data-obpt-tone`
- missing `obpt-modal-backdrop`, `obpt-modal`, and `obpt-modal-summary`

Those failures match the `71-05` scope and are not shell regressions.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/oban_powertools/web/live/jobs_live_test.exs:143 test/oban_powertools/web/assets_test.exs` - PASSED, 6 tests.
- `mix compile --warnings-as-errors` - PASSED.
- `mix test test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/web/assets_test.exs` - RED as expected on 5 JobsLive proof-seam assertions owned by `71-05`; asset tests and shell rendering pass.

## Self-Check: PASSED

- `ThemeShell.live/1` compiles and emits md5 asset paths through `Assets.path/1`.
- Native routes render inside exactly one `.obpt-root`.
- Host root layouts and example host router files were not modified.

## Next Phase Readiness

Ready for `71-05`: migrate the JobsLive tab, badge, and modal proof seams to token-backed `.obpt-*` classes and complete the example-host isolation proof.

---
*Phase: 71-token-layer-isolated-theming-engine*
*Completed: 2026-06-18*
