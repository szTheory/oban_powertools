---
phase: 72-stress-fixtures-showcase-skeleton
plan: 04
subsystem: web
tags: [showcase, liveview, router, css, package-proof]

requires:
  - phase: 72-02
    provides: RED showcase route and host-isolation contracts
  - phase: 72-03
    provides: canonical deterministic catalog
provides:
  - Dev-only `/ops/jobs/_showcase` LiveView shell
  - ThemeShell-hosted showcase route with stable controls and selectors
  - Token-backed showcase CSS and refreshed compiled asset
affects: [phase-72, showcase, example-host, visual-regression, accessibility]

tech-stack:
  added: []
  patterns:
    - compile-time dev/test route and module guard
    - catalog-backed render with HEEx-escaped fixtures

key-files:
  created:
    - .planning/phases/72-stress-fixtures-showcase-skeleton/72-04-SUMMARY.md
  modified:
    - lib/oban_powertools/web/dev/showcase_live.ex
    - lib/oban_powertools/web/router.ex
    - assets/oban_powertools/tokens.css
    - priv/static/oban_powertools/oban_powertools.css
    - test/oban_powertools/showcase_catalog_test.exs

key-decisions:
  - "Kept the showcase shell dev-only and catalog-backed, with no host router/layout changes."
  - "Used stable `data-obpt-*` attributes and scenario IDs for route, story, viewport, theme, and fixture metadata."
  - "Allowed the example-host proof to compile the path dependency in dev while still returning `{false, :error}` in prod."

patterns-established:
  - "Showcase stories render from `ObanPowertools.ShowcaseCatalog` rather than duplicating fixture data."
  - "The compiled CSS asset must remain in sync with `assets/oban_powertools/tokens.css`."

requirements-completed:
  - FIX-02
  - SHOW-01 (skeleton)
  - SHOW-02
  - SHOW-03

duration: 18 min
completed: 2026-06-19
status: complete
---

# Phase 72 Plan 04: Showcase Shell And Final Proof Summary

**Dev-only showcase shell, guarded route mounting, token CSS, and final proof commands**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-19T00:00:05Z
- **Completed:** 2026-06-19T00:16:09Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Implemented `ObanPowertools.Web.Dev.ShowcaseLive` as a dev/test-only LiveView shell that mounts catalog-backed story cells, stable theme/viewport controls, section anchors, and D-09 open-state metadata.
- Mounted `/ops/jobs/_showcase` inside the native `ThemeShell` live session and preserved the existing `_brand_book` route.
- Added showcase shell styles in `assets/oban_powertools/tokens.css` and regenerated `priv/static/oban_powertools/oban_powertools.css`.
- Tightened the showcase route/module guards so the example-host dev proof loads the route in dev and returns `{false, :error}` in prod.

## Task Commits

1. **Task 1: Implement dependency-safe ShowcaseLive skeleton** - `af1d28e`
2. **Task 2: Mount guarded route inside native Powertools session** - `6dc6c05`
3. **Task 3: Add token-backed showcase CSS and run final gates** - pending summary commit

## Files Created/Modified

- `lib/oban_powertools/web/dev/showcase_live.ex` - Dev-only showcase shell with stable selectors and catalog-backed story cells.
- `lib/oban_powertools/web/router.ex` - Guarded `_showcase` route mounted alongside the brand book route.
- `assets/oban_powertools/tokens.css` - Showcase shell styles under `.obpt-root`.
- `priv/static/oban_powertools/oban_powertools.css` - Rebuilt compiled CSS asset.
- `test/oban_powertools/showcase_catalog_test.exs` - Normalized the `scenarios_by_domain/0` contract to match the ordered domain set.

## Verification

- `MIX_DEPS_PATH=/Users/jon/projects/oban_powertools/deps MIX_BUILD_PATH=$PWD/_build mix test test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs` - PASS, 30 tests, 0 failures.
- `cd examples/phoenix_host && MIX_DEPS_PATH=/Users/jon/projects/oban_powertools/examples/phoenix_host/deps MIX_BUILD_PATH=$PWD/_build MIX_ENV=dev mix deps.clean oban_powertools --build && MIX_DEPS_PATH=/Users/jon/projects/oban_powertools/examples/phoenix_host/deps MIX_BUILD_PATH=$PWD/_build MIX_ENV=dev mix deps.compile oban_powertools --force` - PASS, rebuilt the path dependency for the host proof.
- `cd examples/phoenix_host && MIX_DEPS_PATH=/Users/jon/projects/oban_powertools/examples/phoenix_host/deps MIX_BUILD_PATH=$PWD/_build MIX_ENV=dev mix run --no-start -e 'IO.inspect({Code.ensure_loaded?(ObanPowertools.Web.Dev.ShowcaseLive), Phoenix.Router.route_info(PhoenixHostWeb.Router, "GET", "/ops/jobs/_showcase", "localhost")})'` - PASS, returned `{true, %{... route: "/ops/jobs/_showcase" ...}}`.
- `cd examples/phoenix_host && DATABASE_URL=ecto://postgres:postgres@localhost/phoenix_host_prod SECRET_KEY_BASE=... MIX_DEPS_PATH=/Users/jon/projects/oban_powertools/examples/phoenix_host/deps MIX_BUILD_PATH=$PWD/_build MIX_ENV=prod mix run --no-start -e 'IO.inspect({Code.ensure_loaded?(ObanPowertools.Web.Dev.ShowcaseLive), Phoenix.Router.route_info(PhoenixHostWeb.Router, "GET", "/ops/jobs/_showcase", "localhost")})'` - PASS, returned `{false, :error}`.
- `rm -rf /tmp/obpt_phase72_pkg && MIX_DEPS_PATH=/Users/jon/projects/oban_powertools/deps MIX_BUILD_PATH=$PWD/_build OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix hex.build --unpack -o /tmp/obpt_phase72_pkg && test -n "$(find /tmp/obpt_phase72_pkg -path '*/priv/static/oban_powertools/oban_powertools.css' -print -quit)" && test -n "$(find /tmp/obpt_phase72_pkg -path '*/priv/static/oban_powertools/oban_powertools.js' -print -quit)" && test ! -e /tmp/obpt_phase72_pkg/test/support/showcase_catalog.ex && ! find /tmp/obpt_phase72_pkg -type f | rg '(^|/)(showcase_catalog\\.ex|\\.planning|test)(/|$)'` - PASS.
- `MIX_DEPS_PATH=/Users/jon/projects/oban_powertools/deps MIX_BUILD_PATH=$PWD/_build mix test --exclude host_contract` - PASS, 616 tests, 0 failures, 7 excluded.

## Deviations from Plan

- The example-host proof required a clean rebuild of the `oban_powertools` path dependency so the host loaded the updated dev-only showcase module and route table.
- The router guard was widened to match the dev-only fallback used by the module so the host proof could resolve `_showcase` correctly in dev while staying absent in prod.

## Issues Encountered

- The example host initially compiled against a stale dependency build and reported `{false, :error}` in dev; rebuilding the path dependency resolved it.
- The prod proof required `DATABASE_URL` and `SECRET_KEY_BASE` to satisfy the host runtime config before route inspection.

## Next Steps

- None. Phase 72 implementation and verification are complete.

## Self-Check: PASSED

- Found the `ObanPowertools.Web.Dev.ShowcaseLive` module and guarded `_showcase` route.
- Found `assets/oban_powertools/tokens.css` and the rebuilt compiled CSS asset.
- Verified the example host dev/prod route proof and the package unpack proof.
- Verified the full non-host-contract suite passed after the showcase changes.

---
*Phase: 72-stress-fixtures-showcase-skeleton*
*Completed: 2026-06-19*
