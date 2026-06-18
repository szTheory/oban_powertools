---
phase: 71-token-layer-isolated-theming-engine
plan: 03
subsystem: web
tags: [assets, plug, router, hex-package]
requires:
  - phase: 71-token-layer-isolated-theming-engine
    provides: 71-02 compiled CSS and JS assets
provides:
  - ObanPowertools.Web.Assets Plug
  - /ops/jobs/_assets/oban_powertools-<md5>.css|js routes
  - Hex package inclusion for priv/static/oban_powertools
affects: [theme-shell, example-host, package-release]
tech-stack:
  added: []
  patterns: [router-mounted Plug assets, content-md5 cache fingerprinting, package contract tests]
key-files:
  created:
    - lib/oban_powertools/web/assets.ex
  modified:
    - lib/oban_powertools/web/router.ex
    - mix.exs
    - test/oban_powertools/web/assets_test.exs
    - test/oban_powertools/hex_release_test.exs
key-decisions:
  - "Phoenix route parsing uses a single /_assets/:filename route while preserving public md5 .css/.js URLs."
  - "Mismatched asset filenames return normal halted 404 responses rather than raising router errors."
patterns-established:
  - "Asset paths are exposed through ObanPowertools.Web.Assets.path/1 and served only when the filename hash matches the compiled content."
  - "Hex package tests require priv/static/oban_powertools assets while continuing to reject test and .planning artifacts."
requirements-completed: [TOKEN-03, TOKEN-05]
duration: 5 min
completed: 2026-06-18
status: complete
---

# Phase 71 Plan 03: Asset Boundary Summary

**Library-owned md5 immutable CSS/JS routes and package inclusion for the Powertools theme assets**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-18T19:24:00Z
- **Completed:** 2026-06-18T19:28:15Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `ObanPowertools.Web.Assets` with compile-time static reads, content md5 helpers, public path helpers, immutable cache headers, content types, CSRF skip private, and halted 404 mismatch handling.
- Mounted Powertools asset serving inside the existing host-owned `/ops/jobs` scope through the router macro without changing host endpoint/static config.
- Added `priv` to the Hex package file list and updated release tests to require the Phase 71 compiled assets while still excluding development/planning artifacts.

## Task Commits

Each task was committed atomically:

1. **Task 1: MD5 asset Plug** - `85898d8` (feat)
2. **Task 2: Asset routes and package contract** - `2834001` (feat)

## Files Created/Modified

- `lib/oban_powertools/web/assets.ex` - Plug serving compiled CSS/JS only when the requested filename hash matches current content.
- `lib/oban_powertools/web/router.ex` - Adds `/_assets/:filename` inside `oban_powertools_routes/1`.
- `mix.exs` - Includes `priv` in package files.
- `test/oban_powertools/web/assets_test.exs` - Asserts normal 404 responses for mismatched hashes.
- `test/oban_powertools/hex_release_test.exs` - Requires packaged Phase 71 static assets.

## Decisions Made

- Used one filename route because Phoenix does not allow a dynamic segment followed by `.css` in the route pattern. The public URL remains `/ops/jobs/_assets/oban_powertools-<md5>.css|js`; parsing happens in the Plug.
- Kept md5 scoped to cache fingerprinting only, not security integrity.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Route dynamic-extension pattern was invalid**
- **Found during:** Task 2 compile verification
- **Issue:** Phoenix/Plug rejected `/_assets/oban_powertools-:hash.css` as an invalid dynamic path.
- **Fix:** Mounted `/_assets/:filename` and parsed `oban_powertools-<hash>.css|js` inside `ObanPowertools.Web.Assets`.
- **Files modified:** `lib/oban_powertools/web/router.ex`, `lib/oban_powertools/web/assets.ex`
- **Verification:** `mix test test/oban_powertools/web/assets_test.exs` and `mix compile --warnings-as-errors` pass.
- **Committed in:** `85898d8`, `2834001`

**2. [Rule 1 - Test Harness Bug] 404 assertion expected an exception**
- **Found during:** Task 1 verification
- **Issue:** The test used `assert_error_sent/2`, but the planned behavior is a normal halted 404 response.
- **Fix:** Asserted `response(conn, 404) == "not found"` for mismatched CSS and JS asset filenames.
- **Files modified:** `test/oban_powertools/web/assets_test.exs`
- **Verification:** `mix test test/oban_powertools/web/assets_test.exs` passes.
- **Committed in:** `85898d8`

---

**Total deviations:** 2 auto-fixed (1 blocking route shape, 1 test harness bug).
**Impact on plan:** Public asset URLs and cache semantics are unchanged; implementation follows Phoenix route constraints.

## Issues Encountered

None beyond the auto-fixed route/test issues above.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/oban_powertools/web/assets_test.exs` - PASSED, 5 tests.
- `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` - PASSED, 35 tests.
- `mix compile --warnings-as-errors` - PASSED.
- `mix hex.build --unpack` - PASSED; inspected unpacked `oban_powertools-1.0.0/priv/static/oban_powertools/oban_powertools.css` and `.js`.

## Self-Check: PASSED

- Key files created or modified as planned.
- `git log --oneline --grep="71-03"` returns the two task commits above.
- Asset route, cache, package, and compile checks are green.

## Next Phase Readiness

Ready for `71-04`: render the asset links and scoped `.obpt-root` shell around Powertools LiveViews.

---
*Phase: 71-token-layer-isolated-theming-engine*
*Completed: 2026-06-18*
