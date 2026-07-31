---
phase: 76-navigation-app-shell
plan: 03
subsystem: web-ui
tags:
  - css
  - javascript
  - app-shell
  - accessibility
  - static-assets
dependency_graph:
  requires:
    - 76-01 RED shell, asset, and browser behavior contracts
    - 76-02 server-rendered AppShell markup and data-hook contracts
    - 74-02 token-only primitive CSS and scoped tooltip behavior patterns
  provides:
    - Scoped token-backed AppShell CSS under .obpt-root
    - Root-scoped mobile navigation disclosure behavior
    - Rebuilt byte-stable Powertools static CSS and JS assets
    - Static guards for shell selector scope, token usage, host isolation, and asset stability
  affects:
    - 76-04 shell story catalog and showcase rendering
    - 76-05 shell browser behavior, VRT, and a11y evidence
    - native /ops/jobs shell styling
tech_stack:
  added: []
  patterns:
    - .obpt-root-scoped shell selectors with token-backed visual declarations
    - data-obpt-nav-state as the CSS/JS disclosure state contract
    - deterministic source-to-static asset copying through mix oban_powertools.assets.build
key_files:
  created:
    - .planning/phases/76-navigation-app-shell/76-03-SUMMARY.md
  modified:
    - assets/oban_powertools/tokens.css
    - assets/oban_powertools/theme.js
    - priv/static/oban_powertools/oban_powertools.css
    - priv/static/oban_powertools/oban_powertools.js
    - test/oban_powertools/web/theme_tokens_test.exs
    - test/oban_powertools/web/assets_test.exs
key_decisions:
  - "AppShell CSS remains fully scoped under .obpt-root and uses the existing semantic token system for visual values."
  - "Mobile nav disclosure state is represented by data-obpt-nav-state on the owning shell and synchronized with the toggle aria-expanded value."
  - "Theme-choice aria-pressed state is synchronized from the existing root-scoped theme controller so selected theme styling stays programmatic and visual."
patterns_established:
  - "Shell CSS guard tests scan AppShell selectors separately from primitive selectors to enforce root scoping and token-backed declarations."
  - "Disclosure JS resolves from event target to nearest .obpt-root and owning data-obpt-app-shell before mutating shell state."
requirements_completed:
  - NAV-02
  - NAV-04
  - A11Y-02
metrics:
  started: 2026-07-12T14:37:02Z
  completed: 2026-07-12T14:44:53Z
  duration: 7m51s
  tasks_completed: 2
  files_changed: 6
status: complete
---

# Phase 76 Plan 03: AppShell CSS And Disclosure Assets Summary

Token-backed responsive AppShell CSS and scoped mobile disclosure JavaScript with rebuilt byte-stable Powertools static assets.

## Accomplishments

- Added `.obpt-root` scoped AppShell CSS for the shell frame, skip link, header, mobile nav disclosure, primary nav, breadcrumbs, actor context, theme choices, and main content wrapper.
- Added non-color visual state for current nav links, current breadcrumbs, selected theme choices, focus-visible controls, and open navigation state.
- Added root-scoped disclosure JavaScript that toggles `data-obpt-nav-state`, keeps `aria-expanded` synchronized, closes with Escape only inside the owning shell disclosure region, and restores focus to the toggle.
- Rebuilt `priv/static/oban_powertools/oban_powertools.css` and `priv/static/oban_powertools/oban_powertools.js` with the existing deterministic asset task.
- Extended static tests to guard shell selector scope, token-backed visual declarations, compiled shell CSS, fixed disclosure selectors, host-root safety, and repeated-build byte stability.

## Task Commits

| Task | Name | Commit | Files |
| --- | --- | --- | --- |
| 1 | Add token-backed AppShell CSS and static guards | `4db12a5` | `assets/oban_powertools/tokens.css`, `priv/static/oban_powertools/oban_powertools.css`, `test/oban_powertools/web/theme_tokens_test.exs` |
| 2 | Add scoped disclosure behavior and asset byte-stability checks | `9cbcd1c` | `assets/oban_powertools/theme.js`, `priv/static/oban_powertools/oban_powertools.js`, `test/oban_powertools/web/assets_test.exs`, `test/oban_powertools/web/theme_tokens_test.exs` |

## Verification

| Command | Result |
| --- | --- |
| `mix format --check-formatted test/oban_powertools/web/theme_tokens_test.exs` | Passed |
| `mix oban_powertools.assets.build` | Passed |
| `mix test test/oban_powertools/web/theme_tokens_test.exs --seed 0` | Passed, 8 tests |
| `mix format --check-formatted test/oban_powertools/web/assets_test.exs` | Passed |
| `mix test test/oban_powertools/web/assets_test.exs test/oban_powertools/web/theme_tokens_test.exs --seed 0` | Passed, 14 tests |
| `mix oban_powertools.assets.build && git diff --exit-code -- priv/static/oban_powertools/oban_powertools.css priv/static/oban_powertools/oban_powertools.js` | Passed |
| `mix test test/oban_powertools/web/components/app_shell_test.exs test/oban_powertools/web/live/app_shell_layout_test.exs --seed 0` | Passed, 14 tests |

## Files Created/Modified

- `assets/oban_powertools/tokens.css` - Scoped AppShell CSS selectors, responsive layout, disclosure state styling, active/current state styling, and focus-visible treatment.
- `assets/oban_powertools/theme.js` - Root-scoped disclosure helpers and delegated click/Escape behavior inside the existing theme IIFE.
- `priv/static/oban_powertools/oban_powertools.css` - Rebuilt compiled CSS asset copied from token source.
- `priv/static/oban_powertools/oban_powertools.js` - Rebuilt compiled JS asset copied from theme source.
- `test/oban_powertools/web/theme_tokens_test.exs` - Static guards for shell CSS scope, token-backed declarations, and disclosure selector presence.
- `test/oban_powertools/web/assets_test.exs` - Compiled asset guards for shell CSS, disclosure JS selectors, host mutation rejection, dynamic-eval rejection, and byte stability.
- `.planning/phases/76-navigation-app-shell/76-03-SUMMARY.md` - Execution summary and verification record.

## Decisions Made

- Kept shell styling in `assets/oban_powertools/tokens.css` rather than a new stylesheet so source and generated package assets remain on the established token/build path.
- Used CSS `display: none` for the small-screen closed nav state so collapsed links leave the tab sequence at 320px; the wide breakpoint forces the nav visible regardless of the stored shell state.
- Synchronized theme-choice `aria-pressed` in the existing theme controller so selected theme has both programmatic and visual state without host `<html>` mutation.

## Deviations from Plan

None - plan executed within the planned CSS, JS, static asset, and static guard scope.

## Issues Encountered

None. The only dirty files outside the plan were pre-existing unrelated planning deletions and untracked review/setup artifacts; they were not staged or committed.

## Known Stubs

None. Stub-pattern scan found no new TODO/FIXME/placeholder/coming-soon UI data stubs in the files modified by this plan. The existing `.obpt-showcase-placeholder` class name predates this plan and is not a new AppShell stub.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 76-04 can add shell story catalog/showcase integration against the committed CSS and disclosure data-hook contract. Plan 76-05 can use the compiled assets to prove browser behavior, 320px overflow, VRT, and axe evidence.

## Self-Check: PASSED

- Found `assets/oban_powertools/tokens.css`.
- Found `assets/oban_powertools/theme.js`.
- Found `priv/static/oban_powertools/oban_powertools.css`.
- Found `priv/static/oban_powertools/oban_powertools.js`.
- Found `test/oban_powertools/web/theme_tokens_test.exs`.
- Found `test/oban_powertools/web/assets_test.exs`.
- Found `.planning/phases/76-navigation-app-shell/76-03-SUMMARY.md`.
- Found task commit `4db12a5`.
- Found task commit `9cbcd1c`.

---
*Phase: 76-navigation-app-shell*
*Completed: 2026-07-12*
