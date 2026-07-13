---
phase: 77-data-display-operator-patterns
reviewed: 2026-07-13T00:34:35Z
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
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 77: Code Review Report

**Reviewed:** 2026-07-13T00:34:35Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

The data-display components, taxonomy, scoped assets, showcase catalog, manifest plumbing, and browser evidence are generally coherent. The focused 60-test ExUnit suite, manifest smoke gate, exact 120-baseline gate, asset byte comparison, and `git diff --check` all passed. Two runtime edge cases remain in the shared component API: normal Phoenix flash maps are rendered with incorrect semantics, and an omitted progress value is presented as a real zero measurement.

## Narrative Findings (AI reviewer)

### Warnings

#### WR-01: `flash_group/1` does not support the string-keyed shape of Phoenix `@flash`

**File:** `lib/oban_powertools/web/components/data_display.ex:529-535,754-768`

**Issue:** Phoenix LiveView normalizes flash keys to strings, but `flash_tone/1` recognizes only atom keys. Passing a real `%{"info" => "...", "error" => "..."}` `@flash` therefore renders both messages as neutral polite statuses with the same DOM id (`<group>-neutral`) instead of info/danger notifications. In addition, the original key is discarded and the default `lv:clear-flash` buttons omit `phx-value-key`, so dismissing one notification clears the entire flash map rather than that item. The current component/story tests use atom-keyed fixture maps and do not exercise this framework contract.

**Fix:** Normalize atom and binary keys to the canonical string form, retain the source key in each rendered item, derive tone/urgency from that normalized key, generate ids from the key (or a collision-safe index), and pass `phx-value-key={key}` when the dismiss event is `lv:clear-flash`. Add coverage using `%{"info" => ..., "error" => ...}` and verify per-item dismissal through a connected LiveView.

#### WR-02: The default `nil` progress value is rendered as a measured 0%

**File:** `lib/oban_powertools/web/components/data_display.ex:304-320,323-337,652-656`

**Issue:** `progress_bar/1` declares `value` optional with a `nil` default, but `clamp_progress(nil, max)` converts that unknown value to `0`. A caller that omits the value receives a determinate native progress bar announcing `0/100` and `0%`, even though no measurement exists. This violates the Phase 77 contract that unavailable/unknown progress must use `Progress unavailable` and must not expose a fake numeric value.

**Fix:** Either make `value` required for `state: :ready`, or treat `nil` as unavailable and render the non-numeric unavailable branch automatically. Add a regression test for the default/`nil` value that asserts there is no `<progress>`, `value`, percentage, or count.

### Critical Issues

None.

### Info

None.

---

_Reviewed: 2026-07-13T00:34:35Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
