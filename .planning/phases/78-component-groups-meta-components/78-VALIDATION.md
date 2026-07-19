---
phase: 78
slug: component-groups-meta-components
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-18
---

# Phase 78 — Validation Strategy

> Per-phase validation contract and completed automated evidence record for the component-group meta-patterns. Manual-only boundaries remain explicit and are not implied by automated sign-off.

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
| W0 component API/render | GROUP-01, GROUP-02, FORM-04, COPY-02, A11Y-02 | T-78-ATTR, T-78-XSS, T-78-LEAK | Closed attrs/maps, escaped hostile values, exact copy order, semantic roots, and no raw error/secret output | ExUnit render/source | `mix test test/oban_powertools/web/components/operator_patterns_test.exs --seed 0` | ✅ | ✅ green |
| W0 presenter normalization | GROUP-01, GROUP-02, COPY-02 | T-78-ATOM, T-78-LEAK | Atom/string parity without dynamic atom creation; unknown evidence stays unknown; audit/blocker/result copy is normalized | ExUnit unit | `mix test test/oban_powertools/web/operator_pattern_presenter_test.exs --seed 0` | ✅ | ✅ green |
| W0 connected parent authority | GROUP-01, GROUP-02, FORM-04, A11Y-02 | T-78-AUTH, T-78-REPLAY | Reason/count/freshness/authorization/single-use are revalidated server-side; draft/applied and URL/detail state remain authoritative | LiveView integration | `mix test test/oban_powertools/web/live/operator_patterns_harness_test.exs --seed 0` | ✅ | ✅ green |
| W0 deterministic story catalog | GROUP-01, GROUP-02, COPY-02, A11Y-02 | T-78-FIXTURE, T-78-LEAK | Exactly 23 ordered, secret-free stories expose stable activation metadata and schema-6 group targets | ExUnit catalog | `mix test test/oban_powertools/operator_pattern_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs --seed 0` | ✅ | ✅ green |
| W0 browser behavior | GROUP-01, GROUP-02, FORM-04, COPY-02, A11Y-02 | T-78-FOCUS, T-78-REPLAY, T-78-LEAK | Focus trap/restore, Escape, inertness, resize modality, history, announcements, duplicate-submit suppression, and secret absence are exercised live | Playwright behavior | `npx playwright test --list test/browser/specs/operator-patterns.behavior.spec.ts` | ✅ | ✅ green |
| Incremental ExUnit slices | GROUP-01, GROUP-02, FORM-04, COPY-02, A11Y-02 | T-78-AUTH, T-78-FOCUS | Explanation/filter/confirmation/detail contracts are independently tagged; only Plan 78-05 must make the complete component/presenter/harness files green | ExUnit tag/full gate | `mix test test/oban_powertools/web/components/operator_patterns_test.exs --only phase78_slice:explanation --seed 0` (analogous filter/confirmation/detail commands; unfiltered after 78-05) | ✅ | ✅ green |
| Connected schema-6 structure | GROUP-01, GROUP-02, A11Y-02 | T-78-ACTIVATE | Group metadata, unique IDs, activation state, one responsive tree, and overlay cardinality execute against a connected Docker-backed showcase | Playwright structure | `scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/showcase.structure.spec.ts` | ✅ | ✅ green |
| Representative 200% zoom reflow | GROUP-01, GROUP-02, FORM-04, COPY-02, A11Y-02 | T-78-ZOOM, T-78-FOCUS | Five connected confirmation/filter/detail/explanation/audit stories, project-gated to chromium-wide, assert effective half-CSS-width/device-scale-2 zoom, wrapping/stacking, usable visible focus, one tree, and no ordinary horizontal overflow; exact grep requires five passes/zero skips | Playwright behavior | `scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/operator-patterns.behavior.spec.ts --grep "200% zoom" --project chromium-wide` | ✅ | ✅ green |
| Asset/package boundary | GROUP-01, GROUP-02, A11Y-02 | T-78-HOST, T-78-SUPPLY | Scoped selectors/assets need no host hook registration; source/static assets match; optional catalog failure reaches the existing placeholder | ExUnit source/package | `mix test test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs test/oban_powertools/hex_release_test.exs --seed 0` | ✅ | ✅ green |
| Group axe and VRT | GROUP-01, GROUP-02, COPY-02, A11Y-02 | T-78-VISUAL | One overlay story is activated at a time; 276 group axe/VRT cases are discoverable; exact group baseline scope excludes unrelated residuals | Playwright axe/VRT | `node test/browser/support/verify-group-baselines.mjs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `test/oban_powertools/web/components/operator_patterns_test.exs` — six public functions, semantic/copy order, composition, closed attrs/maps, safe escaping, forbidden-generic-copy contracts, and exact explanation/filter/confirmation/detail slice tags.
- [x] `test/oban_powertools/web/operator_pattern_presenter_test.exs` — presenter normalization, missing/unknown evidence, blocker/audit/result ordering, and no dynamic atom creation.
- [x] `test/oban_powertools/web/live/operator_patterns_harness_test.exs` — independently tagged server-authoritative confirmation, filter draft/applied state, and detail URL/history contracts plus the phase-wide drawer-to-confirmation transition.
- [x] `test/oban_powertools/operator_pattern_story_catalog_test.exs` — exact 23-story order, deterministic fixtures, activation metadata, schema-6 inputs, and secret sentinels.
- [x] `test/browser/specs/operator-patterns.behavior.spec.ts` — focus, Escape, inertness, adaptive mode, resize, restore, announcements, URL history, duplicate submit, generated-target guard, and five representative `200% zoom` reflow cases.
- [x] `test/browser/support/verify-group-baselines.mjs` — exact manifest-derived 276 group PNGs and group-only changed-scope proof.
- [x] Extend manifest/showcase support to schema 6 and `kind: "group"` before browser discovery is considered green.

Every missing Wave 0 contract must first fail at its intended seam before production implementation turns it green. Waves 2–4 run only their owning `phase78_slice`; the complete unfiltered component/presenter/harness RED gate is required to become green after Plan 78-05.

### Task evidence index

- **78-01-01 through 78-01-04:** established meaningful RED at the absent component/presenter symbols, connected parent-authority seams, missing 23-story catalog/schema-6 target fields, and exact-276 baseline contract. The RED suite contained no production implementation.
- **78-02-01 through 78-02-03:** turned finite presenter/taxonomy contracts green, then the explanation slice green (**3 passes**, 9 future cases excluded), and proved deterministic source/static CSS equality.
- **78-03-01 through 78-03-03:** turned the FilterBar component slice green (**3 passes**, 10 future cases excluded), synchronized the single responsive tree, and turned the connected filter slice green (**5 passes**, 10 future cases excluded).
- **78-04-01 through 78-04-03:** turned the confirmation component slice green (**3 passes**, 11 future cases excluded), its connected authority slice green (**5 passes**, 10 future cases excluded), and retained repeat-build asset equality; verification hardening also suppressed sensitive test-harness event logs.
- **78-05-01 through 78-05-03:** turned the detail component and connected slices green (**2/2** and **4/4**), then made the first complete unfiltered component/presenter/harness gate green (**38/38**) with one native detail tree and parent-owned history/modality.
- **78-06-01 through 78-06-04:** made the exact 23-story support catalog, fail-closed showcase, schema-6/64-target manifest, and shared connected activation path green; structure passed **12/12**.
- **78-07-01 through 78-07-03:** made connected confirmation, filter/detail, explanation/audit, confidentiality, responsive, focus/history, and exact five-story zoom behavior green; the complete behavior suite passed **37** with **20 intentional project gates**.
- **78-08-01 through 78-08-03:** made connected behavior/structure/zoom and axe green, generated and compared the exact group-only 276-baseline set, then passed the focused final gate and both protected-boundary audits recorded below. Post-plan review tightened confidentiality, submission, outcome, and attention-matrix semantics; the corrected Docker launcher then re-proved the complete browser matrix.

## Execution Evidence

### 78-08-01 — Connected behavior, structure, zoom, and axe

- `npm run showcase:manifest` regenerated schema 6 with 64 total targets and the exact 23 ordered group stories.
- The connected group behavior suite passed **37 tests** across `chromium-320`, `chromium-tablet`, and `chromium-wide`; **20 viewport-intentional skips** kept narrow, tablet, wide, and zoom-only contracts project-gated.
- The exact `200% zoom` grep on `chromium-wide` passed **5 tests with 0 skips**.
- Connected structure passed **12 tests**: 4 themes × 3 viewports, including group activation, one responsive tree, and overlay cardinality.
- Focused group axe passed **276 tests**: 23 group stories × 4 themes × 3 viewports, with **0 critical or serious violations**.
- The first fresh axe run exposed `scrollable-region-focusable` on the narrow DetailSurface body. The body now has a server-rendered keyboard-access baseline, while client synchronization removes the extra tab stop in inline mode; focused ExUnit/asset coverage passed **21 tests**, and the affected axe slice passed **8 tests** before the complete matrix rerun.
- No manual screen-reader or representative visual-review claim is made here. Those remain explicit manual boundaries below and the broader cross-page sweep remains assigned to Phase 82.

### 78-08-02 — Exact group VRT baseline scope

- The plan-time update produced the exact **276 group PNGs**: 23 group stories × 4 themes × 3 viewports. The first parallel update encountered **39 new-crop stability timeouts** at Playwright's 5-second screenshot limit; serial group-only recovery isolated tablet and wide generation, and an explicit 15-second assertion timeout made the remaining long-content crop deterministic without changing visual comparison semantics.
- `node test/browser/support/verify-group-baselines.mjs` reported `group baselines ok: 276`.
- Code review later exposed that Apple Bash 3.2 rejected the launcher's empty `NETWORK_ARGS` expansion under `set -u`; the earlier updater had therefore captured host Chromium despite being invoked through the Docker wrapper. The launcher now uses a non-empty portable Docker argument array, and the showcase wrapper `exec`s the BEAM server so cleanup owns the actual listener.
- A fresh update in the confirmed container passed **276/276** and corrected **80** tracked PNGs. `node test/browser/support/verify-group-baselines.mjs --changed-scope` reported `80 paths, all within 276`; no non-group screenshot path was modified or added.
- The required fresh canonical Docker **compare-only** run then passed **276/276** in 3.7 minutes with no update flag. That established runtime determinism, but fresh goal-backward verification later found that overlay screenshots were still framed to their containing story articles; the overlay-specific correction below supersedes those pixels.
- The unrelated scenario baseline set remains exactly **108 PNGs** and is not counted as Phase 78 success. No manual representative-visual-review claim is made by this automated evidence.

### 78-08-03 — Final focused and protected-boundary gates

- `mix format --check-formatted` and `mix compile --warnings-as-errors` passed. The focused Phase 78 ExUnit command passed **157 tests with 0 failures**, including repeat-build asset SHA equality, source/static CSS and JavaScript equality, package exclusion, and absent/malformed optional-catalog fallback contracts.
- Manifest regeneration and independent smoke validation reported schema **6**, **23 group stories**, **64 ordered targets**, 4 themes, and 3 viewports; the exact baseline verifier again reported **276**.
- Fresh connected structure passed **12/12**, and the exact wide `200% zoom` grep passed **5/5 with 0 skips**.
- The immutable start commit `f2e1c98944197c90265d7599ae2493ede153c97f` resolved. Its cumulative `base..HEAD` audit found only the five allowed production seams under `lib/oban_powertools`; no config, migration, dependency manifest, or lockfile boundary changed.
- The final working-tree and untracked protected-path audit was empty. Unrelated pre-existing planning-directory changes remain outside Phase 78 and were neither staged nor claimed.
- Browser behavior (**37 passed**, 20 intentional project gates), group axe (**276 passed**, zero critical/serious), and compare-only group VRT (**276 passed**) are retained from Tasks 78-08-01 and 78-08-02; no discovery-only or aggregate scenario claim substitutes for those connected runs.

### Post-plan code review and canonical revalidation

- Three review/fix iterations resolved all four in-scope findings: audit evidence is now projected through an explicit presentation allowlist (`abd3370`), submitting confirmations cannot be dismissed (`89f687b`), finite audit outcomes retain their semantics (`473df91`), and the attention story renders the complete four-card status/severity matrix (`c960fc9`). The canonical-launcher correction and focused baseline repair are in `1f1e4b5`; the detailed record is `78-REVIEW-FIX.md`.
- After the launcher correction, the complete connected Docker behavior suite passed **37** with **20 intentional project gates**, including the exact five wide `200% zoom` cases, and connected structure passed **12/12**. The complete group axe matrix passed **276/276** with zero critical or serious violations. The full group VRT update and independent compare-only matrix each passed **276/276**, with exactly **80** corrected group PNGs and zero non-group screenshot changes.
- The repository-wide ExUnit command executed **797 tests**: **794 passed** and **3 failed** in pre-existing host/package lanes. Two child-host compilation failures require Phoenix UI dependencies already referenced by Phase-78-start modules, and the example-host reset failure timed out in an unrelated concurrent-index migration. These are recorded as out-of-phase residuals; they do not replace or weaken the green **157-test** focused Phase 78 gate.
- The Docker dependency preflight continues to report the repository's existing vulnerable-dependency advisories and expired local Hex authentication warning. Phase 78 changed no dependency manifest or lockfile; dependency remediation remains outside this phase's allowed boundary.

### Fresh verification gap closure — complete overlay VRT

- Initial goal-backward verification resolved **66/67** must-haves and reported `gaps_found`: `showcase.vrt.spec.ts` always captured the story article returned by `activateTarget()`, so fixed/top-layer confirmation and detail overlays were stable but clipped. Representative committed images omitted dialog headings and required controls even though exact-set and compare-only checks were green.
- The focused pre-update regression produced the expected **4 failures** for `group-confirm-bulk-count` on `chromium-320`: the old **224×305** story fragment was compared with the corrected **320×900** overlay root.
- `visualTargetLocator()` now returns the exact active confirmation root or open native detail dialog for `activation: overlay`, while all non-overlay targets retain story framing. Every overlay VRT case asserts a visible heading plus a confirmation action or detail close control before screenshot comparison.
- A confirmed Docker update passed **276/276** and changed exactly **120** PNGs: 10 overlay stories × 4 themes × 3 viewports. Exact-set verification remained **276**, changed-scope verification reported `120 paths, all within 276`, and no non-group screenshot changed.
- Representative inspection confirmed complete 320/high-contrast bulk confirmation, tablet/dark modal detail, and wide/light long-detail surfaces with their headings and required close/actions. The mandatory fresh no-update Docker comparison then passed **276/276** in 3.8 minutes.
- Fresh independent re-verification passed **67/67** must-haves with no gaps or regressions. It independently reran the complete no-update Docker VRT matrix (**276/276**), all **120** overlay semantic guards, format/warnings compilation, and **46** core Phase 78 tests; `78-VERIFICATION.md` records the full goal-backward evidence.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Broad assistive-technology quality sweep | A11Y-02 | Automated role/text/cardinality checks prove the component contract, but cannot fully judge announcement quality across screen readers | After automated status-message assertions pass, inspect representative confirmation, filter, adaptive detail, blocker, and audit stories with VoiceOver or NVDA; record any cross-page residual for the Phase 82 gate |
| Representative visual inspection | GROUP-01, GROUP-02, COPY-02, A11Y-02 | Pixel equality proves stability, not semantic or aesthetic correctness | Inspect representative 320/high-contrast, tablet/dark, and wide/light group baselines after the canonical Docker update; verify copy hierarchy, danger scope/consequence, non-color severity, focus treatment, and no stacked overlays. The broader manual cross-page 200% zoom sweep remains Phase 82; it does not replace Phase 78's five automated connected zoom cases. |

---

## Final Phase Gate

- [x] Formatting and warnings-as-errors compilation pass.
- [x] All focused Phase 78 ExUnit contracts pass with `--seed 0`.
- [x] Manifest smoke reports schema 6, 23 group stories, and 64 total targets.
- [x] Browser behavior runs live on 320 and wide, with tablet adaptive-transition coverage.
- [x] Connected `showcase.structure.spec.ts` executes schema-6 group metadata/activation/one-tree assertions; `--list` is not completion evidence.
- [x] Exactly five connected representative `200% zoom` stories pass asserted effective zoom, wrapping/stacking, focus usability, one-tree, and ordinary-overflow checks.
- [x] Focused group axe passes for all manifest-derived group targets/themes/viewports.
- [x] Canonical Docker group VRT update is followed by a compare-only pass.
- [x] `verify-group-baselines.mjs` reports exactly 276 group PNGs and no changed screenshot outside group paths.
- [x] Packaged source/static CSS and JS are byte-identical after a repeatable asset build.
- [x] Fresh package/child-VM evidence proves absent or malformed optional group catalogs render the existing Operator Groups placeholder.
- [x] `78-START-SHA` resolves, and both its cumulative `base..HEAD` protected-path diff and the final working-tree/untracked audit exclude all forbidden production/dependency boundaries.
- [x] The unrelated Phase 76/77 scenario-only VRT residual is preserved and is not reported as Phase 78 success.

Do not mark Phase 78 complete from discovery, static markup, axe, or baseline existence alone. Record connected structure, connected behavior, exact announcement text/cardinality, focus/history/resize behavior, five-story 200% zoom reflow, compare-only VRT, exact baseline equality, asset equality, package fallback, and cumulative/worktree protected-boundary evidence in this file during execution.

---

## Validation Sign-Off

- [x] Every final PLAN.md task maps to an automated command or an explicit Wave 0 dependency.
- [x] Sampling continuity: no three consecutive tasks without automated verification.
- [x] Wave 0 contracts reach meaningful RED before implementation and then green.
- [x] No watch-mode flags appear in verification commands.
- [x] Fast feedback remains under 30 seconds for the component/presenter loop and under 120 seconds for the focused ExUnit/manifest loop.
- [x] `wave_0_complete: true` and `nyquist_compliant: true` are set only after evidence is recorded.

## Validation Audit 2026-07-19

| Metric | Count |
|--------|-------|
| Requirements audited | 5 |
| Automated coverage gaps found | 0 |
| Resolved during audit | 0 |
| Escalated to manual-only | 0 new |

All PLAN tasks map to executable ExUnit, connected Playwright, manifest, asset/package, or protected-boundary contracts. The two existing manual-only items concern qualitative cross-assistive-technology and broader representative visual review; they remain explicitly assigned to Phase 82 and do not replace any Phase 78 automated requirement gate.

**Approval:** automated Phase 78 gate and fresh 67/67 goal-backward re-verification passed. Broader manual-only screen-reader and cross-page representative visual boundaries remain intentionally unclaimed for Phase 82.
