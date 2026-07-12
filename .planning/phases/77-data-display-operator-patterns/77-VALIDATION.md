---
phase: 77
slug: data-display-operator-patterns
status: planned
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-12
reconciled: 2026-07-12
---

# Phase 77 — Validation Strategy

> Reconciled planning-time validation contract. All execution statuses remain pending until `/gsd:execute-phase 77` produces command evidence.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveViewTest; Playwright 1.61.0 + axe-core 4.11.3 |
| **Config file** | `mix.exs`, `playwright.config.ts` |
| **Quick run command** | `mix test test/oban_powertools/web/status_taxonomy_test.exs test/oban_powertools/web/components/data_display_test.exs --seed 0` |
| **Focused full command** | `mix format --check-formatted && mix compile --warnings-as-errors && mix test test/oban_powertools/web/status_taxonomy_test.exs test/oban_powertools/web/components/data_display_test.exs test/oban_powertools/data_display_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs --seed 0 && npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` plus the live commands below |
| **Estimated runtime** | Source/component loops under 30 seconds; live browser and Docker VRT are wave-level exceptions |

## Sampling Rate

- **After every task:** run the narrowest automated command in the map.
- **After every plan:** run all Phase 77 tests affected by that plan and `mix compile --warnings-as-errors` when production source changed.
- **After Plan 06:** generate schema 5, run independent manifest smoke, and verify focused Playwright discovery.
- **Before completion:** execute focused behavior at 320/wide, the complete live structure spec across all three projects/four themes, focused data axe, Docker baseline update and Docker compare, the manifest-derived exact 120-file matrix gate, the independent changed-screenshot scope gate, and the focused full command.
- **Claim boundary:** the known 108 unrelated scenario-only VRT residual from Phase 76 remains non-blocking for focused Phase 77 evidence and must never be reported as aggregate green.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure behavior | Test type | Automated command | File exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 77-01-01 | 01 | 1 | DATA-02, A11Y-02 | T-77-01-ATOM | Taxonomy rejects unsafe atom creation and unknown domains | RED unit | `mix test test/oban_powertools/web/status_taxonomy_test.exs --seed 0` | ❌ planned | ⬜ pending |
| 77-01-02 | 01 | 1 | DATA-01, DATA-03, DATA-04, A11Y-02 | T-77-01-LEAK, T-77-01-ATTR, T-77-01-XSS | Native semantics, attr filtering, hostile escaping, and cross-channel sentinel absence are pinned | RED component | `mix test test/oban_powertools/web/components/data_display_test.exs --seed 0` | ❌ planned | ⬜ pending |
| 77-01-03 | 01 | 1 | DATA-01, DATA-02, DATA-03, DATA-04 | T-77-01-DOS | Ten stories are deterministic; huge rows use a bounded truthful window | RED catalog | `mix test test/oban_powertools/data_display_story_catalog_test.exs --seed 0` | ❌ planned | ⬜ pending |
| 77-01-04 | 01 | 1 | DATA-01, DATA-03, DATA-04, A11Y-02 | T-77-01-LEAK, T-77-01-DOS | Browser contract covers sorting, reflow, focus, overflow, redaction, toast, progress, and row bounds | RED browser discovery | `npx playwright test --list test/browser/specs/data-display.behavior.spec.ts` | ❌ planned | ⬜ pending |
| 77-02-01 | 02 | 2 | DATA-02, A11Y-02 | T-77-02-ATOM | Pure domain-aware mapping is exhaustive, atom/binary safe, and wrapper attrs cannot override semantics | unit + component | `mix test test/oban_powertools/web/status_taxonomy_test.exs test/oban_powertools/web/components/data_display_test.exs --seed 0` | ❌ planned | ⬜ pending |
| 77-03-01 | 03 | 3 | DATA-01, DATA-03, A11Y-02 | T-77-03-ATTR, T-77-03-XSS | One table DOM, parent sort event, explicit states, and escaped cells | component | `mix test test/oban_powertools/web/components/data_display_test.exs --seed 0` | ❌ planned | ⬜ pending |
| 77-03-02 | 03 | 3 | DATA-01, DATA-03, A11Y-02 | T-77-03-LEAK, T-77-03-DOS | Token CSS reflows the same DOM at 24rem without page overflow or duplicate controls | CSS + asset | `mix oban_powertools.assets.build && mix test test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs test/oban_powertools/web/components/data_display_test.exs --seed 0` | ✅ existing tests/assets | ⬜ pending |
| 77-04-01 | 04 | 4 | DATA-01, DATA-03, A11Y-02 | T-77-04-ATTR, T-77-04-XSS | Native dl/ol/progress/live semantics, explicit states, and safe long-value expansion | component | `mix test test/oban_powertools/web/components/data_display_test.exs --seed 0` | ❌ planned | ⬜ pending |
| 77-04-02 | 04 | 4 | DATA-01, DATA-03, A11Y-02 | T-77-04-DOS | Secondary displays wrap/stack with token-scoped focus and no unbounded ordinary scroll | CSS + asset | `mix oban_powertools.assets.build && mix test test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs --seed 0` | ✅ existing tests/assets | ⬜ pending |
| 77-05-01 | 05 | 5 | DATA-01, DATA-04, A11Y-02 | T-77-05-LEAK, T-77-05-XSS | Normalized-only ArgsViewer keeps secret sentinel out of text/title/data/copy/details/JSON | component + policy regression | `mix test test/oban_powertools/web/components/data_display_test.exs test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs --seed 0` | ❌ component test planned | ⬜ pending |
| 77-05-02 | 05 | 5 | DATA-01, DATA-04, A11Y-02 | T-77-05-DOS | Code is focusable/bounded and the sole internally scrolling data region; redaction stays visible | CSS + asset | `mix oban_powertools.assets.build && mix test test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs test/oban_powertools/web/components/data_display_test.exs --seed 0` | ✅ existing tests/assets | ⬜ pending |
| 77-06-01 | 06 | 6 | DATA-01, DATA-02, DATA-03, DATA-04, A11Y-02 | T-77-06-LEAK, T-77-06-DOS | Real deterministic stories contain no raw secret and large rows remain bounded | catalog + LiveView | `mix test test/oban_powertools/data_display_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/components/data_display_test.exs test/oban_powertools/web/status_taxonomy_test.exs --seed 0` | ❌ catalog/test planned | ⬜ pending |
| 77-06-02 | 06 | 6 | DATA-01, DATA-02, DATA-03, DATA-04, A11Y-02 | T-77-06-ATTR, T-77-06-XSS | Schema 5 validates generated data targets without hardcoded TS ids or selector injection | manifest contract | `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` | ✅ existing pipeline | ⬜ pending |
| 77-07-01 | 07 | 7 | DATA-01, DATA-02, DATA-03, DATA-04, A11Y-02 | T-77-07-LEAK, T-77-07-ATTR, T-77-07-DOS | Live 320/wide behavior proves semantics, focus, reflow, secret absence, and bounded rows | Playwright behavior | `npm run showcase:manifest && scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/data-display.behavior.spec.ts --project chromium-320` plus `--project chromium-wide` | ❌ spec planned | ⬜ pending |
| 77-07-02 | 07 | 7 | DATA-01, DATA-02, DATA-03, DATA-04, A11Y-02 | T-77-07-LEAK, T-77-07-DOS | Live structure/axe/Docker VRT compare, an exact manifest-derived 120-path matrix, and a no-non-data-screenshot-change gate provide final evidence | browser + VRT + closeout | Commands in the Browser Evidence section | ❌ baselines/script planned | ⬜ pending |

Status: ⬜ pending · ✅ green · ❌ red/missing · ⚠️ flaky

## Wave 0 Requirements

- [ ] `test/oban_powertools/web/status_taxonomy_test.exs` — exact domain/value taxonomy, aliases, unknown behavior, and atom-safety.
- [ ] `test/oban_powertools/web/components/data_display_test.exs` — native semantics, explicit states, one-DOM table, safe attrs, hostile escaping, long values, and secret-sentinel matrix.
- [ ] `test/oban_powertools/data_display_story_catalog_test.exs` — exact ten-story order, deterministic fixtures, full taxonomy/state coverage, and bounded truthful large-row window.
- [ ] `test/browser/specs/data-display.behavior.spec.ts` — generated-target sorting/focus/reflow/overflow/redaction/toast/progress/row-bound contract.
- [x] Existing ExUnit, manifest, example-host, Playwright, axe, and Docker VRT infrastructure is sufficient; no framework or package installation is planned.

## Browser and VRT Evidence Commands

Validate focused selection first:

```text
npm run showcase:manifest
npx playwright test --list test/browser/specs/showcase.structure.spec.ts test/browser/specs/showcase.vrt.spec.ts test/browser/specs/showcase.a11y.spec.ts --grep "data data-"
npx playwright test --list test/browser/specs/data-display.behavior.spec.ts
```

Execute live behavior and generic data gates:

```text
npm run showcase:manifest && scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/data-display.behavior.spec.ts --project chromium-320
npm run showcase:manifest && scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/data-display.behavior.spec.ts --project chromium-wide
npm run showcase:manifest && scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/showcase.structure.spec.ts
npm run showcase:manifest && scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/showcase.a11y.spec.ts --grep "data data-"
```

Use the canonical Docker renderer for update and compare:

```text
npm run showcase:manifest && scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/showcase.vrt.spec.ts --grep "data data-" --update-snapshots=changed
npm run showcase:manifest && scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/showcase.vrt.spec.ts --grep "data data-"
npm run showcase:manifest && node test/browser/support/verify-data-baselines.mjs
npm run showcase:manifest && node test/browser/support/verify-data-baselines.mjs --changed-scope
```

`verify-data-baselines.mjs` must derive the expected screenshot set from schema-5 `data_stories[].snapshot`, manifest themes, and manifest viewports. Its default mode must independently fail for any missing path, extra data path, duplicate-derived path, unexpected manifest dimension, or cardinality other than exactly 120. Its `--changed-scope` mode must parse porcelain `git status` and independently fail for tracked, untracked, and renamed screenshot changes outside the expected data matrix. The executor must keep `.generated`, `playwright-report`, `test-results`, actuals, and diffs uncommitted.

## Manual-Only Verifications

All Phase 77 success criteria have automated evidence. Human review may inspect representative screenshots and baseline diffs, but cannot replace focused live behavior, axe, or canonical Docker VRT compare.

## Known Residual Boundary

- Phase 76 records 108 unrelated scenario-only VRT baseline failures in the broad aggregate gate.
- Phase 77 must not update those scenario baselines and must not claim `npm run visual:a11y` is globally green while the residual exists.
- Focused data behavior, complete live structure across the full project/theme matrix, focused data axe, Docker VRT compare, exact manifest-derived baseline equality, and changed-screenshot scope are the completion evidence for this phase.

## Validation Sign-Off Readiness

- [x] Every final plan task ID (`77-01-01` through `77-07-02`) maps to requirements, threats, a test type, and an automated command.
- [x] Sampling continuity has no three consecutive implementation tasks without automated feedback.
- [x] Wave 0 covers every new missing contract file before implementation.
- [x] No watch-mode flags or dependency/schema-push work is planned.
- [x] Fast feedback remains under 30 seconds outside explicit browser/Docker gates.
- [ ] Wave 0 contract files exist and reached meaningful RED.
- [ ] Focused live behavior, complete live structure, axe, Docker VRT compare, exact 120-path equality, and no-non-data-screenshot-change evidence executed green.
- [ ] Focused full ExUnit/format/compile/manifest gate executed green.
- [ ] Execution evidence recorded without an unrelated aggregate-green claim.

**Approval:** planning-complete; execution evidence pending
