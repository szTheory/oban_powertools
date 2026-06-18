---
phase: 71-token-layer-isolated-theming-engine
plan: 01
subsystem: testing
tags: [tokens, theming, assets, liveview, host-isolation]
requires:
  - phase: 70-brand-book-identity-foundation
    provides: Brand decisions D-07..D-15 and D-22
provides:
  - Wave 0 RED validation harness for token, theme, asset, proof-seam, and host-isolation contracts
affects: [token-layer, theme-shell, assets, jobs-live, example-host]
tech-stack:
  added: []
  patterns: [ExUnit static contract checks, LiveView proof-seam assertions]
key-files:
  created:
    - test/oban_powertools/web/theme_tokens_test.exs
    - test/oban_powertools/web/assets_test.exs
    - examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs
  modified:
    - test/oban_powertools/web/live/jobs_live_test.exs
key-decisions:
  - "Wave 0 tests intentionally fail RED on missing Phase 71 production assets and shell integration."
  - "Token and theme tests use file/static assertions so missing assets fail explicitly instead of through undefined modules."
patterns-established:
  - "Theme contract checks resolve CSS custom properties and assert representative WCAG contrast floors."
  - "Asset contract tests avoid compile-time references to the missing asset module through Code.ensure_loaded?/1 and apply/3."
requirements-completed: [TOKEN-01, TOKEN-02, TOKEN-03, TOKEN-04, TOKEN-05, MOTION-01, A11Y-03]
duration: 7 min
completed: 2026-06-18
status: complete
---

# Phase 71 Plan 01: Wave 0 Validation Harness Summary

**RED validation harness for scoped tokens, md5 immutable assets, JobsLive proof classes, and example-host isolation**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-18T19:10:00Z
- **Completed:** 2026-06-18T19:17:48Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added token/theme static tests for Phase 70 decisions D-07..D-15 and D-22, including primitive and semantic token categories, scoped selectors, contrast floors, media preferences, and namespaced theme-controller strings.
- Added md5 immutable asset-route, package `priv`, and byte-stability tests for the future `ObanPowertools.Web.Assets` boundary and build task.
- Added JobsLive proof-seam and example-host isolation tests requiring `.obpt-root`, md5 asset tags, token-backed tab/badge/modal classes, and host root isolation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Token/theme contract checks** - `3de08c6` (test)
2. **Task 2: Immutable asset route checks** - `9351e2e` (test)
3. **Task 3: Theming proof seam checks** - `3d40f6d` (test)

## Files Created/Modified

- `test/oban_powertools/web/theme_tokens_test.exs` - RED static contract checks for token categories, theme selectors, contrast floors, motion/media preferences, and theme-controller isolation.
- `test/oban_powertools/web/assets_test.exs` - RED asset module, route, cache header, package inclusion, and byte-stability tests.
- `test/oban_powertools/web/live/jobs_live_test.exs` - Proof-seam assertions for token-backed JobsLive shell, tabs, badges, and modals.
- `examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs` - Host root and Powertools route isolation proof.

## Decisions Made

- Kept the harness intentionally RED for missing Phase 71 production files and modules, matching the validation-first sequence.
- Used direct file/static assertions for token and theme assets so missing files produce explicit contract failures.
- Used string/route assertions for shell integration because the actual ThemeShell and asset Plug land in later dependent plans.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope expansion; the harness remains limited to the Phase 71 Wave 0 validation surface.

## Issues Encountered

- `~r{}` regex delimiters conflicted with `{32}` quantifiers in md5 path assertions. Switched those literals to `~r|...|` before verification.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/oban_powertools/web/theme_tokens_test.exs` - RED as expected: 6 tests compile and fail on missing `assets/oban_powertools/tokens.css` or `assets/oban_powertools/theme.js`.
- `mix test test/oban_powertools/web/assets_test.exs` - RED as expected: 5 tests compile and fail on missing `ObanPowertools.Web.Assets`, missing build task, and missing package `priv` inclusion.
- `mix test test/oban_powertools/web/live/jobs_live_test.exs` - RED as expected: existing suite compiles; failures are proof-seam expectations for missing `.obpt-*` classes/root/assets.
- `cd examples/phoenix_host && mix test test/phoenix_host_web/oban_powertools_theme_isolation_test.exs` - RED as expected: host `/` isolation passes; Powertools route fails on missing `.obpt-root` and md5 asset shell.

## Self-Check: PASSED

- Key files created or modified as planned.
- `git log --oneline --grep="71-01"` returns the three task commits above.
- RED failures are assertion failures for Phase 71 implementation contracts, not syntax errors.

## Next Phase Readiness

Ready for `71-02`: implement the source token layer, vanilla theme controller, deterministic asset build task, and compiled static outputs until the token/theme and byte-stability portions of the harness turn green.

---
*Phase: 71-token-layer-isolated-theming-engine*
*Completed: 2026-06-18*
