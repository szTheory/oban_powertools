---
phase: 72-stress-fixtures-showcase-skeleton
plan: 02
subsystem: testing
tags: [phoenix-liveview, router, example-host, showcase, red-tests]

requires:
  - phase: 71-token-layer-isolated-theming-engine
    provides: ThemeShell, scoped md5 assets, and example-host isolation proof
provides:
  - RED LiveView contracts for the dev-only showcase shell, controls, selectors, and D-09 open-state targets
  - RED router route-info contract for `/ops/jobs/_showcase`
  - Example-host host-root non-leakage assertions for future showcase markers
affects: [phase-72, phase-72-04, showcase, example-host, visual-regression]

tech-stack:
  added: []
  patterns:
    - validation-first RED Phoenix LiveView contracts
    - stable `data-obpt-*` selector contracts for future VRT/a11y targets

key-files:
  created:
    - test/oban_powertools/web/live/showcase_live_test.exs
  modified:
    - test/oban_powertools/web/router_test.exs
    - examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs

key-decisions:
  - "RED tests assert `_showcase` route-info before render so failures point directly at missing Phase 72-04 route/module work."
  - "Example-host test-env coverage stays host-root isolation only; dev-mode `_showcase` module/route proof remains Plan 72-04 work."

patterns-established:
  - "Showcase tests target route paths and `data-obpt-*` attributes, never display copy."
  - "Reserved open-state targets are metadata contracts: `confirm_action_open`, `tooltip_open`, and `drawer_open`."

requirements-completed:
  - "SHOW-01 (skeleton)"
  - SHOW-02
  - SHOW-03

duration: 9 min
completed: 2026-06-18
status: complete
---

# Phase 72 Plan 02: Showcase RED Contracts Summary

**Validation-first showcase contracts for route-info, ThemeShell rendering, stable selectors, and example-host isolation**

## Performance

- **Duration:** 9 min
- **Started:** 2026-06-18T23:33:04Z
- **Completed:** 2026-06-18T23:41:48Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added RED LiveView tests for `/ops/jobs/_showcase` covering ThemeShell asset/root expectations, theme choices, viewport choices, future section anchors, story metadata, and D-09 open-state targets.
- Extended router tests with the `_showcase` route-info contract for `ObanPowertools.Web.Dev.ShowcaseLive` action `:index`.
- Extended example-host isolation tests so the host home page remains free of future showcase markers while the existing `/ops/jobs/jobs` scoped-shell proof stays green.

## Task Commits

1. **Task 1: Add RED showcase LiveView render and selector tests** - `95a052a` (test)
2. **Task 2: Extend router tests for showcase route-info contract** - `1db8592` (test)
3. **Task 3: Extend example-host isolation expectations without host router edits** - `56584fd` (test)

**Plan metadata:** committed after this summary is written.

## Files Created/Modified

- `test/oban_powertools/web/live/showcase_live_test.exs` - New RED LiveView contract for the future `_showcase` route, controls, section anchors, story metadata, and reserved open-state targets.
- `test/oban_powertools/web/router_test.exs` - Adds the `_showcase` route-info assertion without changing existing native or bridge route checks.
- `examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs` - Adds host-root non-leakage assertions for future showcase markers; no router/layout changes.

## Decisions Made

- RED failures are intentionally anchored on `Phoenix.Router.route_info/4` returning `:error`; this keeps failures clean until Plan 72-04 implements the route/module.
- Example-host `_showcase` route/module proof remains a dev-mode compile/route command for Plan 72-04 because the example host test environment does not enable dev routes.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The isolated worktree did not have local `deps/`, so the initial unqualified `mix test` command failed before ExUnit. Verification was rerun with `MIX_DEPS_PATH` pointing at the existing fetched dependency cache and `MIX_BUILD_PATH` pointing at the worktree-local `_build`; no packages were installed.

## Verification

- `MIX_DEPS_PATH=/Users/jon/projects/oban_powertools/deps MIX_BUILD_PATH=$PWD/_build mix test test/oban_powertools/web/live/showcase_live_test.exs` - RED as expected: 6 failures, all because `Phoenix.Router.route_info(..., "/ops/jobs/_showcase", ...)` returned `:error`.
- `MIX_DEPS_PATH=/Users/jon/projects/oban_powertools/deps MIX_BUILD_PATH=$PWD/_build mix test test/oban_powertools/web/router_test.exs` - RED as expected: 1 failure on the new `_showcase` route-info assertion returning `:error`; existing route/bridge checks ran.
- `cd examples/phoenix_host && MIX_DEPS_PATH=/Users/jon/projects/oban_powertools/examples/phoenix_host/deps MIX_BUILD_PATH=$PWD/_build mix test test/phoenix_host_web/oban_powertools_theme_isolation_test.exs test/phoenix_host_web/controllers/page_controller_test.exs` - PASSED, 3 tests.

## Known Stubs

None. The missing `_showcase` route/module is the intentional RED target for Plan 72-04, not a stub in this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 72-04 to implement `ObanPowertools.Web.Dev.ShowcaseLive`, mount `/ops/jobs/_showcase` inside the native ThemeShell live session, expose the asserted controls/selectors, and run the dev-mode example-host route/module proof.

## Self-Check: PASSED

- Found `test/oban_powertools/web/live/showcase_live_test.exs`.
- Found `test/oban_powertools/web/router_test.exs`.
- Found `examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs`.
- Found task commits `95a052a`, `1db8592`, and `56584fd`.
- Stub scan over changed files found no `TODO`, `FIXME`, placeholder copy, or hardcoded empty values that flow to UI.
- No new endpoint, auth path, file access pattern, or schema change was introduced; this plan is test-only.

---
*Phase: 72-stress-fixtures-showcase-skeleton*
*Completed: 2026-06-18*
