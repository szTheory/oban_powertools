---
phase: 83-showcase-completion-documentation
status: ready
created: 2026-07-30
---

# Phase 83 Context

## Goal

Close the already-built showcase as the canonical design-system audit surface and
publish contributor and forward-only quality documentation.

## Locked Decisions

- The existing schema-8 manifest is authoritative: 163 targets, including 99 page
  stories, across scenario, primitive, form, shell, data, group, and page kinds.
- The showcase remains dev/test-only and runs through `examples/phoenix_host`;
  production packages contain runtime assets and guides, never test catalogs or
  showcase support code.
- Phase 83 adds no component variants or operator capability. Missing inventory is
  a blocker; otherwise this is documentation and proof closure.
- The explicit quality contract is compare-only by default. Snapshot updates are
  reviewed exceptions and never count as passing verification.
- The contributor guide must document token ownership, scoped theming, component
  extension workflow, the existing source-level no-raw-values checks, and the
  exact verification commands.

## Evidence Already Present

- `test/oban_powertools/showcase_catalog_test.exs` locks 163 targets and 99 pages.
- `test/oban_powertools/web/live/showcase_live_test.exs` locks the dev route,
  switchers, stable selectors, and production page seams.
- `test/oban_powertools/hex_release_test.exs` excludes test/planning catalogs from
  the Hex package.
- `test/oban_powertools/web/assets_test.exs` proves repeated asset builds are
  byte-stable.
- `npm run visual:a11y` and `npm run verify:pages` are the canonical unfiltered
  browser gates.
