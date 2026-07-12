---
phase: 76-navigation-app-shell
plan: 04
subsystem: ui-testing
tags: [phoenix-liveview, app-shell, showcase, manifest, playwright]

requires:
  - phase: 76-navigation-app-shell
    provides: 76-01 RED shell story/browser contracts, 76-02 AppShell, and 76-03 scoped shell CSS/JS
provides:
  - Deterministic ShellStoryCatalog with six AppShell showcase stories
  - Rendered AppShell showcase section with shell story metadata and real AppShell markup
  - Schema 4 generated showcase manifest with shell_stories and shell targets
  - Browser support validation for shell targets, nav_state, and app-shell structure
affects: [76-05, visual-regression, accessibility, showcase-manifest, navigation-app-shell]

tech-stack:
  added: []
  patterns:
    - Dev/test support-module catalog loaded by ShowcaseLive through the existing fallback path
    - Elixir-owned shell targets exported through the generated browser manifest
    - Scoped repeated AppShell ids for multi-story showcase rendering while preserving production defaults

key-files:
  created:
    - test/support/shell_story_catalog.ex
    - .planning/phases/76-navigation-app-shell/76-04-SUMMARY.md
  modified:
    - lib/oban_powertools/web/components/app_shell.ex
    - lib/oban_powertools/web/dev/showcase_live.ex
    - test/oban_powertools/web/components/app_shell_test.exs
    - test/oban_powertools/shell_story_catalog_test.exs
    - test/oban_powertools/web/live/showcase_live_test.exs
    - scripts/showcase_manifest.exs
    - test/browser/support/manifest.ts
    - test/browser/support/manifest-smoke.mjs
    - test/browser/support/showcase.ts

key-decisions:
  - "Shell stories live in ObanPowertools.ShellStoryCatalog, separate from stress fixtures, primitive stories, and form stories."
  - "Showcase renders real AppShell instances with story-scoped nav/main ids so repeated evidence cells remain valid DOM while production AppShell defaults stay obpt-primary-nav and obpt-main."
  - "Schema 4 treats shell stories as generated first-class targets after form stories; TypeScript validates shell metadata but does not own a shell id inventory."

patterns-established:
  - "Shell stories derive story ids, snapshots, and a11y selectors from the catalog id."
  - "Browser structure support validates shell target metadata from the manifest, including nav_state and app-shell section presence."

requirements-completed:
  - NAV-01
  - NAV-02
  - NAV-03
  - A11Y-02
  - "COPY-* (nav labels)"

duration: 10 min
completed: 2026-07-12
status: complete
---

# Phase 76 Plan 04: Shell Story Catalog And Manifest Summary

**First-class AppShell showcase stories with schema 4 generated browser targets and strict shell metadata validation.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-12T14:51:01Z
- **Completed:** 2026-07-12T15:00:42Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added `ObanPowertools.ShellStoryCatalog` with six deterministic shell stories for nine-surface nav, mobile collapsed/open states, active breadcrumb, actor/theme context, and long-context wrapping.
- Rendered a first `app-shell` showcase section with real `AppShell.app_shell/1` markup and stable story, component, variant, state, nav_state, snapshot, and a11y metadata.
- Bumped the generated showcase manifest to schema 4 with top-level `shell_stories`, appended shell targets after form targets, and exported `shellStories` from TypeScript support.
- Updated browser structure support to validate generated shell metadata and locate the `app-shell` section without hardcoded shell story ids.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add shell showcase story contract** - `018af59` (test)
2. **Task 1 GREEN: Render app shell stories in showcase** - `72698fe` (feat)
3. **Task 2: Add shell targets to showcase manifest** - `3307108` (feat)

## Files Created/Modified

- `test/support/shell_story_catalog.ex` - Deterministic shell story source with helper-derived targets, snapshots, and a11y selectors.
- `lib/oban_powertools/web/dev/showcase_live.ex` - Loads shell stories and renders the `app-shell` section with real AppShell markup.
- `lib/oban_powertools/web/components/app_shell.ex` - Adds optional scoped ids for repeated showcase AppShell instances while preserving default production ids.
- `test/oban_powertools/web/components/app_shell_test.exs` - Guards default and scoped AppShell id behavior.
- `test/oban_powertools/shell_story_catalog_test.exs` - Verifies shell story metadata, order, helpers, nav states, copy, and hooks.
- `test/oban_powertools/web/live/showcase_live_test.exs` - Verifies shell showcase rendering, escaped long context, nav_state, canonical copy, and bridge absence.
- `scripts/showcase_manifest.exs` - Generates schema 4 `shell_stories` and shell targets.
- `test/browser/support/manifest.ts` - Validates schema 4, shell target metadata, and exports `shellStories`.
- `test/browser/support/manifest-smoke.mjs` - Standalone schema 4/count/order/nav_state smoke checks.
- `test/browser/support/showcase.ts` - Includes the app-shell section and validates rendered shell target metadata.

## Decisions Made

- Kept shell story data separate from all existing catalogs to preserve the Phase 72/74/75 story ownership boundaries.
- Used story-scoped AppShell `id_scope` values only for repeated showcase cells; native routes still render `obpt-primary-nav` and `obpt-main`.
- Kept shell ids Elixir-owned. TypeScript validates generated shell targets and the `shell-*` prefix but does not define a copied story-id array.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Scoped repeated AppShell ids inside showcase stories**
- **Found during:** Task 1 (Implement ShellStoryCatalog and render shell stories in showcase)
- **Issue:** Rendering six real AppShell instances in one LiveView duplicated `obpt-primary-nav` and `obpt-main`, which LiveView testing rejects and which would make story-local browser behavior ambiguous.
- **Fix:** Added optional `id_scope` to AppShell. Production defaults stay `obpt-primary-nav` and `obpt-main`; showcase stories pass the story id to derive unique nav/main ids.
- **Files modified:** `lib/oban_powertools/web/components/app_shell.ex`, `lib/oban_powertools/web/dev/showcase_live.ex`, `test/oban_powertools/web/components/app_shell_test.exs`
- **Verification:** `mix test test/oban_powertools/web/components/app_shell_test.exs test/oban_powertools/shell_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs --seed 0`
- **Committed in:** `72698fe`

**2. [Rule 1 - Bug] Scoped showcase theme-control assertions**
- **Found during:** Task 1 RED
- **Issue:** Once the page itself is wrapped in AppShell, global `data-obpt-theme-choice` assertions also see shell theme controls.
- **Fix:** Scoped the showcase-control test and browser structure helper to `[data-obpt-showcase] [data-obpt-theme-controls]`.
- **Files modified:** `test/oban_powertools/web/live/showcase_live_test.exs`, `test/browser/support/showcase.ts`
- **Verification:** ExUnit showcase tests and chromium-320 structure suite passed.
- **Committed in:** `018af59`, `3307108`

---

**Total deviations:** 2 auto-fixed Rule 1 bugs.
**Impact on plan:** Both fixes were required for valid repeated shell evidence and did not add new product behavior or new dependencies.

## Issues Encountered

- The browser structure verification printed existing Hex authentication expiry and dependency advisory output while resolving unchanged deps; the command still passed. This plan installed no packages and did not change dependencies.
- A direct ad hoc Node import of `manifest.ts` is unsupported because Node does not load TypeScript files directly in this repo. The Playwright loader path was used instead and listed the shell behavior spec successfully.

## Verification

| Command | Result |
| --- | --- |
| `mix format --check-formatted test/support/shell_story_catalog.ex test/oban_powertools/shell_story_catalog_test.exs lib/oban_powertools/web/dev/showcase_live.ex test/oban_powertools/web/live/showcase_live_test.exs` | Passed |
| `mix test test/oban_powertools/shell_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs --seed 0` | Passed, 13 tests |
| `mix test test/oban_powertools/web/components/app_shell_test.exs test/oban_powertools/shell_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs --seed 0` | Passed, 25 tests |
| `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` | Passed: 9 scenarios, 7 primitive stories, 9 form stories, 6 shell stories, 31 targets |
| `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/showcase.structure.spec.ts --project chromium-320` | Passed, 4 tests |
| `npx playwright test --list test/browser/specs/shell.behavior.spec.ts` | Passed, 33 tests listed |
| `rg 'shell-nine-surface-nav\|shell-mobile-collapsed' test/browser --glob '*.ts' --glob '*.mjs' --glob '!**/shell.behavior.spec.ts'` | Passed, no copied shell id inventory outside behavior-spec lookups |
| Key-link `rg` checks for `ShellStoryCatalog/shell_stories`, `nav_state`, and `kind: 'shell'/targets` | Passed |

## Known Stubs

None. Stub scan found only intentional showcase empty-state/fallback placeholders and existing reserved section placeholder copy. The shell catalog loads in normal dev/test and the shell empty state is not active in the verified route.

## Threat Flags

None. The new trust-boundary surfaces are the planned catalog-to-HEEx, catalog-to-JSON, and manifest-to-TypeScript paths from the plan threat model; they are covered by HEEx escaping tests, schema 4 validation, deterministic target derivation, and rendered metadata checks.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 76-05. Shell stories are visible through generated manifest targets; Wave 5 can own shell behavior execution, VRT evidence, and any baseline work without hardcoded browser target inventories.

## Self-Check: PASSED

- Found `test/support/shell_story_catalog.ex`.
- Found `lib/oban_powertools/web/dev/showcase_live.ex`.
- Found `scripts/showcase_manifest.exs`.
- Found `test/browser/support/manifest.ts`.
- Found `test/browser/support/manifest-smoke.mjs`.
- Found `test/browser/support/showcase.ts`.
- Found `.planning/phases/76-navigation-app-shell/76-04-SUMMARY.md`.
- Found task commit `018af59`.
- Found task commit `72698fe`.
- Found task commit `3307108`.

---
*Phase: 76-navigation-app-shell*
*Completed: 2026-07-12*
