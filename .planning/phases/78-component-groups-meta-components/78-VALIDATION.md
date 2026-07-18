---
phase: 78
slug: component-groups-meta-components
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-18
---

# Phase 78 — Validation Strategy

> Per-phase validation contract for the component-group meta-patterns. This remains a draft until execution records meaningful RED/green evidence and maps the final plan task IDs.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix LiveViewTest; Playwright 1.61.0 with axe-core 4.11.3; Docker-backed canonical VRT |
| **Config file** | `test/test_helper.exs`, `playwright.config.ts`, `test/browser/support/manifest.ts` |
| **Quick run command** | `mix test test/oban_powertools/web/components/operator_patterns_test.exs --seed 0` |
| **Focused full command** | `mix format --check-formatted && mix compile --warnings-as-errors && mix test test/oban_powertools/web/components/operator_patterns_test.exs test/oban_powertools/web/operator_pattern_presenter_test.exs test/oban_powertools/web/live/operator_patterns_harness_test.exs test/oban_powertools/operator_pattern_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs test/oban_powertools/hex_release_test.exs --seed 0 && npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs && node test/browser/support/verify-group-baselines.mjs` |
| **Canonical browser runner** | Docker-backed Playwright via `scripts/playwright-docker.sh` / the repository visual-a11y scripts |
| **Estimated feedback latency** | Component/presenter loop under 30 seconds; focused ExUnit/manifest loop under 120 seconds; browser/VRT matrix is a wave/final gate |

---

## Sampling Rate

- **After every implementation task:** run the narrowest affected ExUnit file; do not allow three consecutive tasks without automated feedback.
- **After component/presenter changes:** run `mix test test/oban_powertools/web/components/operator_patterns_test.exs test/oban_powertools/web/operator_pattern_presenter_test.exs --seed 0`.
- **After connected-state changes:** run `mix test test/oban_powertools/web/live/operator_patterns_harness_test.exs --seed 0`.
- **After catalog/showcase/manifest changes:** run the catalog and ShowcaseLive tests, regenerate the manifest, and run manifest smoke.
- **After CSS/JS changes:** run theme-token and asset equality tests after `mix oban_powertools.assets.build`.
- **After each plan wave:** run all Phase 78 focused ExUnit files plus manifest smoke and Playwright test discovery.
- **Before `/gsd:verify-work`:** run connected behavior on `chromium-320`, adaptive coverage on tablet, wide behavior on `chromium-wide`, focused group axe, canonical Docker compare-only VRT, exact 276-baseline verification, and the focused full command.

---

## Per-Task Verification Map

Final task IDs are assigned by PLAN.md. The planner must map every task to one of these required contracts.

| Contract | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|----------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| W0 component API/render | GROUP-01, GROUP-02, FORM-04, COPY-02, A11Y-02 | T-78-ATTR, T-78-XSS, T-78-LEAK | Closed attrs/maps, escaped hostile values, exact copy order, semantic roots, and no raw error/secret output | ExUnit render/source | `mix test test/oban_powertools/web/components/operator_patterns_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| W0 presenter normalization | GROUP-01, GROUP-02, COPY-02 | T-78-ATOM, T-78-LEAK | Atom/string parity without dynamic atom creation; unknown evidence stays unknown; audit/blocker/result copy is normalized | ExUnit unit | `mix test test/oban_powertools/web/operator_pattern_presenter_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| W0 connected parent authority | GROUP-01, GROUP-02, FORM-04, A11Y-02 | T-78-AUTH, T-78-REPLAY | Reason/count/freshness/authorization/single-use are revalidated server-side; draft/applied and URL/detail state remain authoritative | LiveView integration | `mix test test/oban_powertools/web/live/operator_patterns_harness_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| W0 deterministic story catalog | GROUP-01, GROUP-02, COPY-02, A11Y-02 | T-78-FIXTURE, T-78-LEAK | Exactly 23 ordered, secret-free stories expose stable activation metadata and schema-6 group targets | ExUnit catalog | `mix test test/oban_powertools/operator_pattern_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| W0 browser behavior | GROUP-01, GROUP-02, FORM-04, COPY-02, A11Y-02 | T-78-FOCUS, T-78-REPLAY, T-78-LEAK | Focus trap/restore, Escape, inertness, resize modality, history, announcements, duplicate-submit suppression, and secret absence are exercised live | Playwright behavior | `npx playwright test --list test/browser/specs/operator-patterns.behavior.spec.ts` | ❌ W0 | ⬜ pending |
| Asset/package boundary | GROUP-01, GROUP-02, A11Y-02 | T-78-HOST, T-78-SUPPLY | Scoped selectors/assets need no host hook registration; source/static assets match; optional catalog failure reaches the existing placeholder | ExUnit source/package | `mix test test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs test/oban_powertools/hex_release_test.exs --seed 0` | ✅ infrastructure | ⬜ pending |
| Group axe and VRT | GROUP-01, GROUP-02, COPY-02, A11Y-02 | T-78-VISUAL | One overlay story is activated at a time; 276 group axe/VRT cases are discoverable; exact group baseline scope excludes unrelated residuals | Playwright axe/VRT | `node test/browser/support/verify-group-baselines.mjs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/web/components/operator_patterns_test.exs` — six public functions, semantic/copy order, composition, closed attrs/maps, safe escaping, and forbidden-generic-copy contracts.
- [ ] `test/oban_powertools/web/operator_pattern_presenter_test.exs` — presenter normalization, missing/unknown evidence, blocker/audit/result ordering, and no dynamic atom creation.
- [ ] `test/oban_powertools/web/live/operator_patterns_harness_test.exs` — server-authoritative confirmation, preview freshness/single-use, partial results, filter draft/applied state, URL/history, and drawer-to-confirmation transition.
- [ ] `test/oban_powertools/operator_pattern_story_catalog_test.exs` — exact 23-story order, deterministic fixtures, activation metadata, schema-6 inputs, and secret sentinels.
- [ ] `test/browser/specs/operator-patterns.behavior.spec.ts` — focus, Escape, inertness, adaptive mode, resize, restore, announcements, URL history, duplicate submit, and generated-target guard.
- [ ] `test/browser/support/verify-group-baselines.mjs` — exact manifest-derived 276 group PNGs and group-only changed-scope proof.
- [ ] Extend manifest/showcase support to schema 6 and `kind: "group"` before browser discovery is considered green.

Every missing Wave 0 contract must first fail at its intended seam before production implementation turns it green.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Broad assistive-technology quality sweep | A11Y-02 | Automated role/text/cardinality checks prove the component contract, but cannot fully judge announcement quality across screen readers | After automated status-message assertions pass, inspect representative confirmation, filter, adaptive detail, blocker, and audit stories with VoiceOver or NVDA; record any cross-page residual for the Phase 82 gate |
| Representative visual inspection | GROUP-01, GROUP-02, COPY-02, A11Y-02 | Pixel equality proves stability, not semantic or aesthetic correctness | Inspect representative 320/high-contrast, tablet/dark, and wide/light group baselines after the canonical Docker update; verify copy hierarchy, danger scope/consequence, non-color severity, focus treatment, and no stacked overlays |

---

## Final Phase Gate

- [ ] Formatting and warnings-as-errors compilation pass.
- [ ] All focused Phase 78 ExUnit contracts pass with `--seed 0`.
- [ ] Manifest smoke reports schema 6, 23 group stories, and 64 total targets.
- [ ] Browser behavior runs live on 320 and wide, with tablet adaptive-transition coverage.
- [ ] Focused group axe passes for all manifest-derived group targets/themes/viewports.
- [ ] Canonical Docker group VRT update is followed by a compare-only pass.
- [ ] `verify-group-baselines.mjs` reports exactly 276 group PNGs and no changed screenshot outside group paths.
- [ ] Packaged source/static CSS and JS are byte-identical after a repeatable asset build.
- [ ] Fresh package/child-VM evidence proves absent or malformed optional group catalogs render the existing Operator Groups placeholder.
- [ ] The unrelated Phase 76/77 scenario-only VRT residual is preserved and is not reported as Phase 78 success.

Do not mark Phase 78 complete from discovery, static markup, axe, or baseline existence alone. Record connected behavior, exact announcement text/cardinality, focus/history/resize behavior, compare-only VRT, exact baseline equality, asset equality, and package fallback evidence in this file during execution.

---

## Validation Sign-Off

- [ ] Every final PLAN.md task maps to an automated command or an explicit Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 contracts reach meaningful RED before implementation and then green.
- [ ] No watch-mode flags appear in verification commands.
- [ ] Fast feedback remains under 30 seconds for the component/presenter loop and under 120 seconds for the focused ExUnit/manifest loop.
- [ ] `wave_0_complete: true` and `nyquist_compliant: true` are set only after evidence is recorded.

**Approval:** pending
