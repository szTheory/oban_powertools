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
- **After Waves 2–4:** run only the owning `phase78_slice` ExUnit tag (`explanation`, `filter`, or `confirmation`); after Wave 5 run the final `detail` slice and then the unfiltered component/presenter/harness gate.
- **After each plan wave:** run its narrowest green contract plus manifest smoke/Playwright discovery where applicable; never require a future implementation slice to pass early.
- **Before `/gsd:verify-work`:** run connected structure, connected behavior on `chromium-320`, adaptive coverage on tablet, wide behavior on `chromium-wide`, the exact five-story `200% zoom` grep, focused group axe, canonical Docker compare-only VRT, exact 276-baseline verification, and the focused full command.

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
| Incremental ExUnit slices | GROUP-01, GROUP-02, FORM-04, COPY-02, A11Y-02 | T-78-AUTH, T-78-FOCUS | Explanation/filter/confirmation/detail contracts are independently tagged; only Plan 78-05 must make the complete component/presenter/harness files green | ExUnit tag/full gate | `mix test test/oban_powertools/web/components/operator_patterns_test.exs --only phase78_slice:explanation --seed 0` (analogous filter/confirmation/detail commands; unfiltered after 78-05) | ❌ W0 | ⬜ pending |
| Connected schema-6 structure | GROUP-01, GROUP-02, A11Y-02 | T-78-ACTIVATE | Group metadata, unique IDs, activation state, one responsive tree, and overlay cardinality execute against a connected Docker-backed showcase | Playwright structure | `scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/showcase.structure.spec.ts` | ✅ infrastructure | ⬜ pending |
| Representative 200% zoom reflow | GROUP-01, GROUP-02, FORM-04, COPY-02, A11Y-02 | T-78-ZOOM, T-78-FOCUS | Five connected confirmation/filter/detail/explanation/audit stories, project-gated to chromium-wide, assert effective half-CSS-width/device-scale-2 zoom, wrapping/stacking, usable visible focus, one tree, and no ordinary horizontal overflow; exact grep requires five passes/zero skips | Playwright behavior | `scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/operator-patterns.behavior.spec.ts --grep "200% zoom" --project chromium-wide` | ❌ W0 | ⬜ pending |
| Asset/package boundary | GROUP-01, GROUP-02, A11Y-02 | T-78-HOST, T-78-SUPPLY | Scoped selectors/assets need no host hook registration; source/static assets match; optional catalog failure reaches the existing placeholder | ExUnit source/package | `mix test test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs test/oban_powertools/hex_release_test.exs --seed 0` | ✅ infrastructure | ⬜ pending |
| Group axe and VRT | GROUP-01, GROUP-02, COPY-02, A11Y-02 | T-78-VISUAL | One overlay story is activated at a time; 276 group axe/VRT cases are discoverable; exact group baseline scope excludes unrelated residuals | Playwright axe/VRT | `node test/browser/support/verify-group-baselines.mjs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/web/components/operator_patterns_test.exs` — six public functions, semantic/copy order, composition, closed attrs/maps, safe escaping, forbidden-generic-copy contracts, and exact explanation/filter/confirmation/detail slice tags.
- [ ] `test/oban_powertools/web/operator_pattern_presenter_test.exs` — presenter normalization, missing/unknown evidence, blocker/audit/result ordering, and no dynamic atom creation.
- [ ] `test/oban_powertools/web/live/operator_patterns_harness_test.exs` — independently tagged server-authoritative confirmation, filter draft/applied state, and detail URL/history contracts plus the phase-wide drawer-to-confirmation transition.
- [ ] `test/oban_powertools/operator_pattern_story_catalog_test.exs` — exact 23-story order, deterministic fixtures, activation metadata, schema-6 inputs, and secret sentinels.
- [ ] `test/browser/specs/operator-patterns.behavior.spec.ts` — focus, Escape, inertness, adaptive mode, resize, restore, announcements, URL history, duplicate submit, generated-target guard, and five representative `200% zoom` reflow cases.
- [ ] `test/browser/support/verify-group-baselines.mjs` — exact manifest-derived 276 group PNGs and group-only changed-scope proof.
- [ ] Extend manifest/showcase support to schema 6 and `kind: "group"` before browser discovery is considered green.

Every missing Wave 0 contract must first fail at its intended seam before production implementation turns it green. Waves 2–4 run only their owning `phase78_slice`; the complete unfiltered component/presenter/harness RED gate is required to become green after Plan 78-05.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Broad assistive-technology quality sweep | A11Y-02 | Automated role/text/cardinality checks prove the component contract, but cannot fully judge announcement quality across screen readers | After automated status-message assertions pass, inspect representative confirmation, filter, adaptive detail, blocker, and audit stories with VoiceOver or NVDA; record any cross-page residual for the Phase 82 gate |
| Representative visual inspection | GROUP-01, GROUP-02, COPY-02, A11Y-02 | Pixel equality proves stability, not semantic or aesthetic correctness | Inspect representative 320/high-contrast, tablet/dark, and wide/light group baselines after the canonical Docker update; verify copy hierarchy, danger scope/consequence, non-color severity, focus treatment, and no stacked overlays. The broader manual cross-page 200% zoom sweep remains Phase 82; it does not replace Phase 78's five automated connected zoom cases. |

---

## Final Phase Gate

- [ ] Formatting and warnings-as-errors compilation pass.
- [ ] All focused Phase 78 ExUnit contracts pass with `--seed 0`.
- [ ] Manifest smoke reports schema 6, 23 group stories, and 64 total targets.
- [ ] Browser behavior runs live on 320 and wide, with tablet adaptive-transition coverage.
- [ ] Connected `showcase.structure.spec.ts` executes schema-6 group metadata/activation/one-tree assertions; `--list` is not completion evidence.
- [ ] Exactly five connected representative `200% zoom` stories pass asserted effective zoom, wrapping/stacking, focus usability, one-tree, and ordinary-overflow checks.
- [ ] Focused group axe passes for all manifest-derived group targets/themes/viewports.
- [ ] Canonical Docker group VRT update is followed by a compare-only pass.
- [ ] `verify-group-baselines.mjs` reports exactly 276 group PNGs and no changed screenshot outside group paths.
- [ ] Packaged source/static CSS and JS are byte-identical after a repeatable asset build.
- [ ] Fresh package/child-VM evidence proves absent or malformed optional group catalogs render the existing Operator Groups placeholder.
- [ ] `78-START-SHA` resolves, and both its cumulative `base..HEAD` protected-path diff and the final working-tree/untracked audit exclude all forbidden production/dependency boundaries.
- [ ] The unrelated Phase 76/77 scenario-only VRT residual is preserved and is not reported as Phase 78 success.

Do not mark Phase 78 complete from discovery, static markup, axe, or baseline existence alone. Record connected structure, connected behavior, exact announcement text/cardinality, focus/history/resize behavior, five-story 200% zoom reflow, compare-only VRT, exact baseline equality, asset equality, package fallback, and cumulative/worktree protected-boundary evidence in this file during execution.

---

## Validation Sign-Off

- [ ] Every final PLAN.md task maps to an automated command or an explicit Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 contracts reach meaningful RED before implementation and then green.
- [ ] No watch-mode flags appear in verification commands.
- [ ] Fast feedback remains under 30 seconds for the component/presenter loop and under 120 seconds for the focused ExUnit/manifest loop.
- [ ] `wave_0_complete: true` and `nyquist_compliant: true` are set only after evidence is recorded.

**Approval:** pending
