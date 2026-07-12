---
phase: 76
slug: navigation-app-shell
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-11
completed: 2026-07-12
---

# Phase 76 - Validation Strategy

Final validation record for the navigation app shell phase.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix LiveViewTest render/component tests; Playwright 1.61.0 with axe |
| **Config file** | `test/test_helper.exs`, `playwright.config.ts`, `test/browser/support/manifest.ts` |
| **Quick run command** | `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` |
| **Full suite command** | `mix test && npm run visual:a11y` |
| **VRT baseline command** | `npm run vrt:update -- --grep shell` |
| **Canonical VRT runner** | Docker-backed Playwright via `scripts/playwright-docker.sh` |

---

## Sampling Rate

- **Per task:** each Phase 76 plan committed after focused automated verification.
- **Browser behavior:** shell behavior was verified on `chromium-320` and `chromium-wide`.
- **Visual/a11y:** shell structure, axe, and VRT were verified through generated shell targets.
- **Final phase close:** component/layout/catalog/showcase/theme/assets ExUnit suites and `mix compile --warnings-as-errors` were run after shell VRT baselines were generated.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 76-01 | 76-01 | 1 | NAV-01, NAV-03, COPY-* | T-76-XSS-01 | Fixed server-side nav labels render through HEEx escaping; no caller-supplied raw HTML labels | unit/render | `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` | Yes | green |
| 76-02 | 76-02 | 2 | NAV-01, NAV-03 | T-76-ROUTE-01 | Live layout integration renders shell landmarks, active route state, and breadcrumb state from route context | LiveView render | `mix test test/oban_powertools/web/live/app_shell_layout_test.exs --seed 0` | Yes | green |
| 76-03 | 76-03 | 3 | NAV-01, NAV-02, NAV-04, A11Y-02 | T-76-UX-01 | Deterministic shell story catalog exposes mobile/desktop, route, theme, actor, and long-context states | source + unit | `mix test test/oban_powertools/shell_story_catalog_test.exs --seed 0` | Yes | green |
| 76-04 | 76-04 | 4 | NAV-01, NAV-03, COPY-* | T-76-ROUTE-01 | Showcase manifest/schema exposes generated `kind: "shell"` targets for browser proof and VRT | source + browser structure | `npm run showcase:manifest` | Yes | green |
| 76-05a | 76-05 | 5 | NAV-01, NAV-02, NAV-03, NAV-04, A11Y-02, COPY-* | T-76-02, T-76-04, T-76-05 | Browser behavior proves canonical nav, optional bridge absence, active route/breadcrumb, skip link transfer, disclosure keyboard/click/Escape, collapsed tab order, theme state, focus visibility, and 320px overflow | Playwright behavior | `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/shell.behavior.spec.ts --project chromium-320` | Yes | green |
| 76-05b | 76-05 | 5 | NAV-01, NAV-02, NAV-03, NAV-04, A11Y-02, COPY-* | T-76-09 | Shell structure, axe, and VRT evidence is generated from manifest-backed `kind: "shell"` targets | Playwright structure/axe/VRT | See final evidence table | Yes | green with documented host-runner VRT residual |

Status values: pending, green, red, flaky.

---

## Wave 0 Requirements

- [x] `lib/oban_powertools/web/components/app_shell.ex` - shell component API and central nav model.
- [x] `test/oban_powertools/web/components/app_shell_test.exs` - render/static/copy/active-route contract tests.
- [x] `test/support/shell_story_catalog.ex` - deterministic shell showcase stories.
- [x] `test/oban_powertools/shell_story_catalog_test.exs` - catalog/target contract tests.
- [x] `test/browser/specs/shell.behavior.spec.ts` - skip link, focus order, disclosure collapse, active route, and 320px overflow checks.
- [x] `scripts/showcase_manifest.exs`, `test/browser/support/manifest.ts`, and `ShowcaseLive` support shell targets.

---

## Final Evidence

| Scope | Command | Result | Notes |
|-------|---------|--------|-------|
| Shell behavior 320 | `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/shell.behavior.spec.ts --project chromium-320` | Passed: 12 tests | Proves mobile disclosure, collapsed tab order, Escape close, skip-link transfer, theme state, focus visibility, and overflow at 320px. |
| Shell behavior wide | `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/shell.behavior.spec.ts --project chromium-wide` | Passed: 8 tests, 4 mobile-only checks skipped | Proves visible wide nav, canonical labels, active route/breadcrumb, theme state, and focus visibility. |
| Shell VRT baseline update | `npm run vrt:update -- --grep shell` | Passed: 72 tests | Generated 72 shell-only baselines: 6 stories x 3 Chromium projects x 4 themes. |
| Shell baseline cardinality | `node -e 'const fs=require("fs"); const projects=["chromium-320","chromium-tablet","chromium-wide"]; const stories=["shell-nine-surface-nav","shell-mobile-collapsed","shell-mobile-expanded","shell-active-breadcrumb","shell-theme-actor-context","shell-long-context-wrapping"]; const themes=["system","light","dark","high-contrast"]; const baselinePaths=projects.flatMap(project=>stories.flatMap(story=>themes.map(theme=>"test/browser/__screenshots__/"+project+"/showcase/"+story+"/"+theme+".png"))); const missing=baselinePaths.filter(path=>!fs.existsSync(path)); if (baselinePaths.length !== 72 || missing.length) { console.error(missing.join("\n")); process.exit(1); } console.log("FOUND "+baselinePaths.length+" shell baselines");'` | Passed: `FOUND 72 shell baselines` | Confirms expected shell baseline count. |
| Shell structure 320 | `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/showcase.structure.spec.ts --project chromium-320 --grep shell` | Passed: 4 tests | Required a title-only harness fix so `--grep shell` selects the existing structure coverage. |
| Shell axe 320 | `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/showcase.a11y.spec.ts --project chromium-320 --grep shell` | Passed: 24 tests | Axe checks passed for six shell stories across four themes. |
| Shell VRT 320, canonical runner | `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:docker -- test/browser/specs/showcase.vrt.spec.ts --project chromium-320 --grep shell` | Passed: 24 tests | Uses the same Docker-backed Playwright runner that writes the baselines. |
| Shell VRT 320, planned host command | `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/showcase.vrt.spec.ts --project chromium-320 --grep shell` | Failed: 24/24 host screenshot diffs | Host runner on macOS rendered different element heights than Docker baselines. The project baseline writer is Docker-backed; canonical Docker compare passed. |
| Shell/component/layout/catalog/showcase/theme/assets ExUnit | `mix test test/oban_powertools/web/components/app_shell_test.exs test/oban_powertools/web/live/app_shell_layout_test.exs test/oban_powertools/shell_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs --seed 0` | Passed: 42 tests, 0 failures | Covers shell component contracts, layout integration, catalog, showcase, theme tokens, and assets. |
| Compile | `mix compile --warnings-as-errors` | Passed | Compiled with warnings treated as errors. |

---

## Manual-Only Verifications

| Behavior | Requirement | Outcome |
|----------|-------------|---------|
| Optional Oban Web bridge presence in shell | NAV-01 | Resolved by browser evidence: the targeted shell behavior proof asserts `/ops/jobs/oban` is absent from primary nav while the nine canonical shell links remain present. |
| Actor/context label specificity | NAV-01, COPY-* | Resolved by shell story evidence: actor/context stories render `Actor:` context copy and participate in shell axe/VRT targets. Further copy polish, if desired, is outside Phase 76. |

---

## Known Residuals

- The planned host VRT compare command fails for shell snapshots because baselines are generated with the Docker-backed Playwright runner while the host macOS runner produces different element heights. The canonical Docker compare passed for all 24 shell `chromium-320` VRT targets.
- The broad aggregate visual gate still includes known older scenario-only baseline failures from pre-Phase-76 drift, previously documented in Phase 75/76 state. Phase 76 did not update scenario, primitive, or form baselines.
- Mix commands print an expired Hex authentication warning and dependency security advisory list before continuing. No package install or private dependency fetch was attempted by this plan.

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or completed Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing test files and browser shell evidence.
- [x] No watch-mode flags in verification commands.
- [x] Feedback latency target documented for unit/render checks.
- [x] `nyquist_compliant: true` set in frontmatter and plans map concrete task IDs.

**Approval:** complete with documented host VRT runner residual
