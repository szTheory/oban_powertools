---
phase: 76-navigation-app-shell
plan: 02
subsystem: web-ui
tags:
  - phoenix-component
  - liveview
  - app-shell
  - navigation
  - accessibility
dependency_graph:
  requires:
    - 76-01 RED shell and layout contracts
    - 71 token layer ThemeShell boundary
    - 74 primitives and component conventions
  provides:
    - ObanPowertools.Web.Components.AppShell
    - closed native navigation model
    - route-aware shell layout integration
    - LiveAuth current URI/current path assigns
  affects:
    - 76-03 shell styling and disclosure behavior
    - 76-04 shell story catalog
    - native /ops/jobs LiveView layout
tech_stack:
  added: []
  patterns:
    - stateless Phoenix.Component shell
    - server-owned closed nav model
    - LiveView handle_params route context hook
    - scoped obpt root and data-hook contracts
key_files:
  created:
    - lib/oban_powertools/web/components/app_shell.ex
    - .planning/phases/76-navigation-app-shell/76-02-SUMMARY.md
  modified:
    - lib/oban_powertools/web/theme_shell.ex
    - lib/oban_powertools/web/live_auth.ex
    - test/oban_powertools/web/live/app_shell_layout_test.exs
decisions:
  - Primary nav remains a closed nine-surface native model and excludes the optional Oban Web bridge.
  - Current route context is assigned centrally through the LiveAuth handle_params hook and consumed by ThemeShell.
  - ThemeShell keeps the isolated .obpt-root asset boundary while AppShell owns the inner shell, nav, breadcrumb, and main target.
requirements_completed:
  - NAV-01
  - NAV-03
  - NAV-04
  - A11Y-02
  - "COPY-* (nav labels)"
metrics:
  started: 2026-07-12T14:23:04Z
  completed: 2026-07-12T14:31:15Z
  duration: 8m11s
  tasks_completed: 2
  files_changed: 5
status: complete
---

# Phase 76 Plan 02: Server-Rendered App Shell Summary

Phoenix LiveView AppShell with closed native navigation, route-aware breadcrumbs, actor context, and ThemeShell integration.

## Accomplishments

- Implemented `ObanPowertools.Web.Components.AppShell` with semantic header/nav/main markup, skip link, disclosure data hooks, theme-choice buttons, actor display, and breadcrumb helpers.
- Wired `ThemeShell.live/1` to wrap native page content with AppShell while preserving `.obpt-root`, md5 static asset links, and isolated theme attributes.
- Added a `LiveAuth` `:handle_params` hook that assigns `:current_uri` and normalized `:current_path` for all native LiveViews.
- Kept navigation server-owned and closed to the nine UI-SPEC native surfaces; `/ops/jobs/oban` is intentionally excluded from primary nav.

## Task Commits

| Task | Name | Commit | Files |
| --- | --- | --- | --- |
| 1 | Implement AppShell component API and closed nav model | `bf50611` | `lib/oban_powertools/web/components/app_shell.ex` |
| 2 | Wire AppShell through ThemeShell and LiveAuth current-path assigns | `fbda302` | `lib/oban_powertools/web/theme_shell.ex`, `lib/oban_powertools/web/live_auth.ex`, `test/oban_powertools/web/live/app_shell_layout_test.exs` |

## Verification

| Command | Result |
| --- | --- |
| `mix format --check-formatted lib/oban_powertools/web/components/app_shell.ex test/oban_powertools/web/components/app_shell_test.exs` | Passed |
| `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` | Passed, 11 tests |
| `mix format --check-formatted lib/oban_powertools/web/theme_shell.ex lib/oban_powertools/web/live_auth.ex test/oban_powertools/web/live/app_shell_layout_test.exs` | Passed |
| `mix test test/oban_powertools/web/components/app_shell_test.exs test/oban_powertools/web/live/app_shell_layout_test.exs test/oban_powertools/web/router_test.exs --seed 0` | Passed, 20 tests |
| `mix compile --warnings-as-errors` | Passed |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed active-route longest-prefix selection**
- **Found during:** Task 1
- **Issue:** The overview route prefix matched every `/ops/jobs/...` path before more specific nav items could become current.
- **Fix:** Select the active nav item by longest matching path prefix.
- **Files modified:** `lib/oban_powertools/web/components/app_shell.ex`
- **Commit:** `bf50611`

**2. [Rule 1 - Bug] Honored explicit `current_path` and tightened breadcrumb output**
- **Found during:** Task 1
- **Issue:** Component tests passed both `current_uri` and `current_path`; the shell initially preferred the URI and ignored the explicit current path override. Breadcrumb regex checks also expected the visible crumb text immediately after the opening tag.
- **Fix:** Prefer `current_path` when present and render breadcrumb text without intervening whitespace.
- **Files modified:** `lib/oban_powertools/web/components/app_shell.ex`
- **Commit:** `bf50611`

**3. [Rule 3 - Blocking] Added display-policy fixture for layout route coverage**
- **Found during:** Task 2
- **Issue:** The layout contract mounted `JobsLive`, which requires a configured display policy. Existing focused JobsLive tests set that fixture, but the new shell layout contract did not.
- **Fix:** Added a local test display policy and setup/restore logic to the layout test so native route mounting exercises the shell instead of stopping during page setup.
- **Files modified:** `test/oban_powertools/web/live/app_shell_layout_test.exs`
- **Commit:** `fbda302`

## Known Stubs

None. Stub-pattern scan over the created and modified shell files found no TODO/FIXME/placeholder markers or hardcoded empty UI data sources.

## Threat Surface Scan

No unplanned security surface was introduced. The only security-relevant additions are the planned server-rendered shell component and LiveAuth route-context hook; no new routes, network endpoints, schemas, file access paths, auth bypasses, static assets, or global html/body theme mutation were added.

## Remaining Work

- Wave 3 owns CSS/JS disclosure behavior and responsive shell styling.
- Wave 4 owns shell story catalog and browser/VRT coverage.

## Self-Check: PASSED

- Found `.planning/phases/76-navigation-app-shell/76-02-SUMMARY.md`.
- Found task commit `bf50611`.
- Found task commit `fbda302`.
