---
phase: 77-data-display-operator-patterns
reviewed: 2026-07-13T01:25:03Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - assets/oban_powertools/tokens.css
  - examples/phoenix_host/priv/static/assets/js/app.js
  - lib/oban_powertools/web/components/data_display.ex
  - lib/oban_powertools/web/dev/showcase_live.ex
  - lib/oban_powertools/web/status_taxonomy.ex
  - priv/static/oban_powertools/oban_powertools.css
  - scripts/showcase_manifest.exs
  - test/browser/specs/data-display.behavior.spec.ts
  - test/browser/specs/showcase.structure.spec.ts
  - test/browser/support/manifest-smoke.mjs
  - test/browser/support/manifest.ts
  - test/browser/support/showcase.ts
  - test/browser/support/verify-data-baselines.mjs
  - test/oban_powertools/data_display_story_catalog_test.exs
  - test/oban_powertools/web/assets_test.exs
  - test/oban_powertools/web/components/data_display_test.exs
  - test/oban_powertools/web/live/showcase_live_test.exs
  - test/oban_powertools/web/status_taxonomy_test.exs
  - test/oban_powertools/web/theme_tokens_test.exs
  - test/support/data_display_story_catalog.ex
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 77: Code Review Report

**Reviewed:** 2026-07-13T01:25:03Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Plan 77-08 correctly closes the previously reported shared-component defects. Real string-keyed Phoenix flash maps now preserve tone, urgency, unique key-derived identity, and exact per-item `lv:clear-flash` payloads; atom aliases do not create atoms and binary entries take deterministic precedence. Omitted and explicit `nil` progress now fail closed to `Progress unavailable` without a native progress element, count, value, or percentage.

One adjacent showcase regression remains. The new mount-time flash seeding assumes the data story catalog is always available, even though the loader, render branch, module documentation, and package boundary intentionally support an unavailable catalog. This makes the packaged dev showcase crash instead of rendering its existing placeholder.

The focused 65-test ExUnit suite, warnings-as-errors compile, schema-5 manifest smoke, exact 120-baseline gate, source/package CSS equality, and `git diff --check` all passed.

## Findings

### Warnings

#### WR-01: Showcase mount crashes when the optional data story catalog is unavailable

**File:** `lib/oban_powertools/web/dev/showcase_live.ex:67-76,493-499,746-754`

**Issue:** `load_data_catalog/0` explicitly returns `%{available?: false, stories: []}` when the dev/test catalog module or support file cannot be loaded, and the render path has a `data-obpt-data-index="empty"` placeholder for that state. Plan 77-08 now calls `seed_data_flash(data_catalog.stories)` unconditionally during mount. With `stories == []`, `Enum.find/2` returns `nil`, `get_in(nil, [:fixtures, :flash])` returns `nil`, and `Enum.reduce(nil, socket, ...)` raises `Protocol.UndefinedError` before the placeholder can render.

This path is reachable in the published package: `mix.exs` packages `lib` but excludes `test/support`, while `ShowcaseLive` documents that the catalogs intentionally stay out of Hex packages and should be optional. The current LiveView tests compile `test/support`, so they never exercise the unavailable-catalog branch.

**Fix:** Make `seed_data_flash/2` default to an empty map when the story or `fixtures.flash` is absent or invalid, then reduce only a verified map. Add a dev-route/package-style regression that mounts the showcase without `ObanPowertools.DataDisplayStoryCatalog` and asserts the existing data-display placeholder renders instead of crashing.

### Critical Issues

None.

### Info

None.

## Verification Evidence

- `mix test` for the six Phase 77 ExUnit files: 65 tests, 0 failures.
- `mix compile --warnings-as-errors`: passed.
- `npm run showcase:manifest` plus manifest smoke: schema 5, 10 data stories, 41 targets.
- `node test/browser/support/verify-data-baselines.mjs`: exactly 120 data baselines.
- `cmp` between source and packaged CSS: byte-identical.
- `git diff --check` across the requested 20-file scope: passed.
- Direct fallback probe: `get_in(nil, [:fixtures, :flash])` returns `nil`; reducing that value raises `Protocol.UndefinedError`.

---

_Reviewed: 2026-07-13T01:25:03Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
