---
phase: 78-component-groups-meta-components
reviewed: 2026-07-19T02:25:31Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - assets/oban_powertools/theme.js
  - assets/oban_powertools/tokens.css
  - lib/oban_powertools/web/components/data_display.ex
  - lib/oban_powertools/web/components/operator_patterns.ex
  - lib/oban_powertools/web/control_plane_presenter.ex
  - lib/oban_powertools/web/dev/showcase_live.ex
  - lib/oban_powertools/web/status_taxonomy.ex
  - priv/static/oban_powertools/oban_powertools.css
  - priv/static/oban_powertools/oban_powertools.js
  - scripts/showcase_manifest.exs
  - test/browser/specs/operator-patterns.behavior.spec.ts
  - test/browser/specs/showcase.a11y.spec.ts
  - test/browser/specs/showcase.structure.spec.ts
  - test/browser/specs/showcase.vrt.spec.ts
  - test/browser/support/manifest-smoke.mjs
  - test/browser/support/manifest.ts
  - test/browser/support/showcase.ts
  - test/browser/support/verify-group-baselines.mjs
  - test/oban_powertools/hex_release_test.exs
  - test/oban_powertools/operator_pattern_story_catalog_test.exs
  - test/oban_powertools/web/assets_test.exs
  - test/oban_powertools/web/components/operator_patterns_test.exs
  - test/oban_powertools/web/live/operator_patterns_harness_test.exs
  - test/oban_powertools/web/live/showcase_live_test.exs
  - test/oban_powertools/web/operator_pattern_presenter_test.exs
  - test/oban_powertools/web/theme_tokens_test.exs
  - test/support/operator_pattern_story_catalog.ex
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 78: Code Review Report

**Reviewed:** 2026-07-19T02:25:31Z
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

The Phase 78 component, presenter, client behavior, showcase, manifest, and test changes were re-reviewed at standard depth after final fix commits `abd3370` and `59d51e4`. CR-01 is resolved: audit changes/evidence now accept only the finite `field`, `before`, `after`, `label`, `value`, and `items` presentation schema, retain the required already-redacted evidence shapes, reject the previously demonstrated credential aliases, and reject arbitrary metadata keys. WR-01, WR-02, and WR-03 remain resolved. WR-04 is not resolved because all 12 refreshed attention-matrix screenshots fail the canonical compare-only test.

Verification evidence: the focused Elixir suite passes (54 tests), three focused connected-browser behavior tests pass, the baseline inventory verifier reports the exact 276 files, generated CSS and JavaScript copies remain byte-identical to their source assets, and `git diff --check 8158739..HEAD` passes.

## Narrative Findings (AI reviewer)

## Critical Issues

None.

## Warnings

### WR-04: Refreshed attention-matrix screenshots still fail canonical visual comparison

**File:** `test/browser/specs/showcase.vrt.spec.ts:9-18`
**Related:** `lib/oban_powertools/web/dev/showcase_live.ex:1393-1429,1830-1840`; `test/browser/__screenshots__/*/showcase/group-attention-status-severity-matrix/*.png`

**Issue:** Commit `59d51e4` replaces all 12 expected images and the structural baseline verifier accepts the complete 276-file inventory, but a canonical compare-only Playwright run of `group-attention-status-severity-matrix` fails all four themes at all three viewports. The refreshed screenshots do contain the intended four cards, yet they were not produced with pixel output matching the checked-in test runtime. Representative failures include the 320px baseline expecting `224x3106` while the test receives `224x3029`, and the wide baseline expecting `271x2740` while the test receives `271x2743`; the wide light image alone reports 34,636 differing pixels. The full Phase 78 VRT gate therefore remains red.

**Fix:** Regenerate these 12 screenshots through the same canonical Docker/browser command used by compare-only CI, with no concurrent or alternate host-browser capture path. Inspect the resulting four-card diffs, then immediately rerun the exact 12-target compare-only command and require all 12 to pass before committing them.

## Resolved Prior Findings

- **CR-01 resolved:** the presenter combines sensitive-key rejection with an allowlisted audit presentation schema. Required redacted `field/before/after` and `label/value` structures normalize successfully; `APIKey`, `apikey`, `secretKey`, `credentials`, and arbitrary `unclassifiedMetadata` are rejected.
- **WR-01 resolved:** `:submitting` confirmations are non-dismissible at the component boundary.
- **WR-02 resolved:** audit outcome taxonomy state remains separate from human-readable outcome copy.
- **WR-03 resolved:** all four attention-matrix rows render with unique IDs and valid status/severity combinations.

---

_Reviewed: 2026-07-19T02:25:31Z_
_Reviewer: Codex (gsd-code-reviewer)_
_Depth: standard_
