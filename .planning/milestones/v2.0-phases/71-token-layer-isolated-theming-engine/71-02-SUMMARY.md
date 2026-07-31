---
phase: 71-token-layer-isolated-theming-engine
plan: 02
subsystem: ui
tags: [tokens, css, javascript, assets, theming]
requires:
  - phase: 71-token-layer-isolated-theming-engine
    provides: 71-01 Wave 0 validation harness
provides:
  - Scoped token source CSS
  - Root-scoped vanilla theme controller
  - Deterministic asset build task and compiled static outputs
affects: [theme-shell, asset-plug, jobs-live-proof-seam]
tech-stack:
  added: []
  patterns: [scoped CSS custom properties, dependency-free browser controller, deterministic Mix asset task]
key-files:
  created:
    - assets/oban_powertools/tokens.css
    - assets/oban_powertools/theme.js
    - lib/mix/tasks/oban_powertools.assets.build.ex
    - priv/static/oban_powertools/oban_powertools.css
    - priv/static/oban_powertools/oban_powertools.js
  modified:
    - test/oban_powertools/web/theme_tokens_test.exs
key-decisions:
  - "Theme selectors remap only semantic color variables and color-scheme; layout tokens stay outside theme overrides."
  - "The asset build is deterministic source copying with normalized line endings and no manifest/timestamp generation."
patterns-established:
  - "Source assets live in assets/oban_powertools and compiled package assets live in priv/static/oban_powertools."
  - "The browser controller owns only .obpt-root attributes and localStorage[\"oban_powertools:theme\"]."
requirements-completed: [TOKEN-01, TOKEN-02, TOKEN-04, TOKEN-05, MOTION-01, A11Y-03]
duration: 6 min
completed: 2026-06-18
status: complete
---

# Phase 71 Plan 02: Token Assets Summary

**Scoped token CSS, root-only theme JavaScript, and byte-stable compiled assets for the Powertools theme layer**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-18T19:18:00Z
- **Completed:** 2026-06-18T19:23:51Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `assets/oban_powertools/tokens.css` with Phase 70 primitive palettes, semantic roles, typography, spacing, radii, elevation, motion tokens, theme remaps, and `.obpt-*` proof-seam classes.
- Added `assets/oban_powertools/theme.js` with `window.ObanPowertoolsTheme`, system/light/dark/high-contrast handling, media preference listeners, and namespaced storage.
- Added `mix oban_powertools.assets.build` and committed deterministic compiled CSS/JS outputs in `priv/static/oban_powertools`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Scoped token layer** - `6637a43` (feat)
2. **Task 2: Scoped theme controller** - `386924c` (feat)
3. **Task 3: Deterministic asset build** - `2ef6a1d` (feat)

## Files Created/Modified

- `assets/oban_powertools/tokens.css` - Two-tier scoped `--obpt-*` token layer and proof-seam classes.
- `assets/oban_powertools/theme.js` - Dependency-free theme controller scoped to `.obpt-root`.
- `lib/mix/tasks/oban_powertools.assets.build.ex` - Deterministic build task.
- `priv/static/oban_powertools/oban_powertools.css` - Compiled CSS asset.
- `priv/static/oban_powertools/oban_powertools.js` - Compiled JS asset.
- `test/oban_powertools/web/theme_tokens_test.exs` - Fixed the block parser to read selector/body captures in the correct order.

## Decisions Made

- Used deterministic source copying instead of Phoenix digest/minification to keep Phase 71 byte-stability direct and inspectable.
- Kept exact theme remaps limited to semantic color variables so theme switching cannot introduce layout shift.
- Preserved CSS/JS as dependency-free browser platform code; no npm or Tailwind build coupling.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test Harness Bug] Corrected CSS block parser capture order**
- **Found during:** Task 1 verification
- **Issue:** The Wave 0 helper used named capture output as if it were ordered selector/body; Elixir returned the captures in a different order, causing false failures against valid CSS.
- **Fix:** Switched the helper to positional `:all_but_first` captures.
- **Files modified:** `test/oban_powertools/web/theme_tokens_test.exs`
- **Verification:** `mix test test/oban_powertools/web/theme_tokens_test.exs` passes.
- **Committed in:** `6637a43`

---

**Total deviations:** 1 auto-fixed (test harness bug).
**Impact on plan:** The fix preserves the intended Wave 0 contract and does not weaken token/theme assertions.

## Issues Encountered

- `mix test test/oban_powertools/web/assets_test.exs` still fails on `ObanPowertools.Web.Assets`, router serving, and package `priv` inclusion. Those are expected `71-03` responsibilities.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/oban_powertools/web/theme_tokens_test.exs` - PASSED, 6 tests.
- `mix oban_powertools.assets.build` - PASSED.
- `mix oban_powertools.assets.build` again plus `git diff --exit-code -- priv/static/oban_powertools` - PASSED; no byte drift.
- `mix test test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs` - Expected partial RED: token/theme tests pass, asset tests fail only for the `71-03` asset Plug/router/package work.

## Self-Check: PASSED

- Key files created on disk and committed.
- `git log --oneline --grep="71-02"` returns the three task commits above.
- Token/theme static contract is green and compiled assets are byte-stable.

## Next Phase Readiness

Ready for `71-03`: add the library-owned asset Plug, router routes, `priv` package inclusion, and Hex package contract updates.

---
*Phase: 71-token-layer-isolated-theming-engine*
*Completed: 2026-06-18*
