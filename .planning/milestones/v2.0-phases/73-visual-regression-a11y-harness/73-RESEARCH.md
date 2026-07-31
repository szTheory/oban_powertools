# Phase 73: Visual-Regression & A11y Harness - Research

**Researched:** 2026-06-19
**Domain:** Node Playwright visual regression, axe-core accessibility scanning, Phoenix showcase harness, GitHub Actions gating
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### CI Enforcement
- **D-01:** Add a required `visual_a11y` lane inside `.github/workflows/ci.yml` and include it in the existing `ci-gate` job. This matches the repo's current branch-protection and release model: one stable required status (`ci-gate`) fans in every blocking lane, and `release.yml` already waits for `ci-gate` before publishing.
- **D-02:** The `visual_a11y` lane is merge-blocking on pull requests and pushes, not a manual or local-only check. A manual/local script may exist for debugging and baseline updates, but it does not satisfy VRT-02 or A11Y-01.
- **D-03:** Run the browser harness in a pinned official Playwright Docker image that matches the locked `@playwright/test` version. Do not rely on developer OS/browser/font parity for baseline generation. The Node toolchain lives at the repo root as development/test infrastructure, with `package-lock.json` committed. No new Hex runtime dependency is introduced.
- **D-04:** Drive the harness against the dev/test-only `examples/phoenix_host` `/ops/jobs/_showcase` route, not a synthetic static page. This proves the real host-owned router path, `ThemeShell`, md5 Powertools CSS/JS assets, `.obpt-root`, and catalog-backed story cells together.

#### Snapshot Scope
- **D-05:** Baseline only catalog-backed story cells from `ObanPowertools.ShowcaseCatalog.scenarios/0` in Phase 73. Do not snapshot future placeholder sections such as Primitives, Forms, Data Display, Operator Groups, or Pages before their owning phases populate real stories. This avoids locking obsolete skeleton pixels and keeps Phase 74-83 reviews focused on real visual changes.
- **D-06:** Still assert the showcase shell structurally: route loads, one `.obpt-root` exists, theme choices exist, viewport choices exist, section anchors exist, and all catalog story targets render. These can be Playwright assertions or existing ExUnit assertions; they should not become broad placeholder screenshot baselines.
- **D-07:** Preserve the Phase 72 single-source-of-truth contract. The Node harness should consume or generate its target manifest from `test/support/showcase_catalog.ex` rather than duplicating the current story ID list in JavaScript. The planner can choose the cleanest mechanism, such as a small Mix/script step that emits JSON for Playwright.
- **D-08:** Snapshot matrix is themes `system`, `light`, `dark`, `high-contrast` crossed with real browser viewports `320`, tablet, and wide. Make `system` deterministic through Playwright media emulation so the same run has stable effective theme behavior.

#### Determinism And Pixel Discipline
- **D-09:** Use Playwright screenshot comparison with committed baselines, not ad hoc image diffs. Baseline paths must be stable, human-readable, and grouped by story, theme, viewport, and browser/project so reviewers can understand what changed.
- **D-10:** Disable or neutralize volatility in the harness: animations disabled, caret hidden, fonts ready before capture, timezone/locale fixed, media preferences controlled, theme state set deterministically on `.obpt-root`, and viewport size set by the browser rather than only by the in-showcase viewport control.
- **D-11:** Use masks or screenshot style overrides only for genuinely volatile pixels. Do not broad-mask story content, status colors, focus/hover affordances, long identifiers, RTL/non-ASCII text, redaction displays, or severity signals. The point is to catch identity regressions, not hide them.
- **D-12:** Do not introduce Chromatic, Percy, or another SaaS baseline store. Their lesson is useful - required visual checks, reviewed baselines, stable rendering, and diff artifacts - but this repo's support-truth and OSS posture fit committed PNG baselines plus GitHub Actions artifacts.

#### Axe Accessibility Gate
- **D-13:** Axe runs over the same stable catalog-backed story targets and any implemented open-state variants that exist in the showcase. Reserved metadata such as `confirm_action_open`, `tooltip_open`, and `drawer_open` should become scan targets when the actual open stories are implemented; metadata alone is not enough.
- **D-14:** Configure axe with WCAG A/AA tags including WCAG 2.2 AA coverage where supported by the installed axe-core version. The merge-blocking threshold for Phase 73 is 0 `critical` or `serious` violations.
- **D-15:** Publish the full axe output, including moderate/minor violations and incomplete results, as CI artifacts. Do not hide lower-severity findings; just do not make them merge-blocking until the planned Phase 82 accessibility/motion/copy hardening pass.
- **D-16:** Do not claim automated axe scans prove the full accessibility contract. Keyboard traversal, dialog focus trap/restore, Esc behavior, focus-not-obscured, screen-reader announcement quality, reduced-motion behavior, and 200% zoom/reflow require later manual or targeted tests. Phase 73 creates the automated gate and reporting channel.

#### Baseline Update Workflow
- **D-17:** CI never updates snapshots. Snapshot updates are explicit local commands run in the pinned Playwright Docker environment, producing committed PNG changes.
- **D-18:** Add CI artifacts for failed visual runs: Playwright HTML/report output, actual/expected/diff images, and axe JSON/report files. Use short retention so artifacts help review without becoming a long-term baseline store.
- **D-19:** Any PR or commit that changes baselines must explain why. Prefer a separate baseline-update commit or a clearly named commit section when practical. A baseline change bundled silently with code is a process smell.
- **D-20:** Baseline update commands should default to the narrowest practical update mode, such as changed snapshots only, and should be documented in the contributor/guardrail docs. Avoid a casual "update everything" workflow that normalizes accidental churn.

### the agent's Discretion

- Exact file names, npm script names, Playwright project names, baseline directory shape, and JSON manifest generation mechanics are left to research/planning as long as the decisions above hold.
- The planner may split the work across multiple plans if needed: Node harness bootstrap, target-manifest/showcase server integration, VRT snapshots, axe gate, CI/artifacts/docs.
- If the first implementation finds that the full theme x viewport x story matrix is too slow for the existing CI budget, the planner should optimize through Playwright project organization, caching, and narrow capture targets before reducing coverage.

### Deferred Ideas (OUT OF SCOPE)

- Full primitive/form/data/group/page story baselines belong to their owning phases as real stories are implemented.
- Tightening axe to selected moderate rules or all violations belongs to Phase 82/84 after the component library and open-state stories exist.
- Manual keyboard traversal, dialog focus trap/restore, screen-reader announcement quality, reduced-motion verification, 200% zoom/reflow, and copy quality belong to Phase 82's accessibility/motion/copy hardening.
- Separate browser-workflow sharding can be reconsidered if the Phase 73 lane becomes materially too slow after optimization.
</user_constraints>

## Project Constraints

No root `AGENTS.md`, `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/skills/*/SKILL.md`, or `.agents/skills/*/SKILL.md` was found for this project root. [VERIFIED: `find` in `/Users/jon/projects/oban_powertools`] The repo does contain `examples/phoenix_host_upgrade_source/AGENTS.md`, but it is outside the active root guidance requested for this phase and should not override the Phase 73 harness plan. [VERIFIED: `find .. -name AGENTS.md`]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VRT-01 | External Node Playwright harness captures deterministic showcase snapshots across themes x {320, tablet, wide} in pinned Docker. | Use `@playwright/test` 1.61.0, `mcr.microsoft.com/playwright:v1.61.0-noble`, Chromium-only viewport projects, generated catalog manifest, and locator-level screenshots. [CITED: https://playwright.dev/docs/test-snapshots] [CITED: https://playwright.dev/docs/docker] [VERIFIED: `test/support/showcase_catalog.ex`] |
| VRT-02 | Committed baselines, CI fails on unintended diff, updates only through reviewed `--update-snapshots`. | Use `toHaveScreenshot`, `snapshotPathTemplate`, committed `test/browser/__screenshots__`, Docker-only update scripts, and `visual_a11y` in `ci-gate`. [CITED: https://playwright.dev/docs/test-snapshots] [CITED: https://playwright.dev/docs/api/class-testconfig] [VERIFIED: `.github/workflows/ci.yml`] |
| VRT-03 | Harness is hermetic against stress fixtures: animations disabled, timestamps/IDs masked, fonts ready, fixed viewports. | Playwright `toHaveScreenshot` defaults animations disabled and caret hidden; add screenshot CSS only for true volatility, fixed locale/timezone/media, `document.fonts.ready`, and stable scenario data from the catalog. [CITED: https://playwright.dev/docs/api/class-testconfig] [VERIFIED: `test/support/showcase_catalog.ex`] |
| A11Y-01 | Axe-core WCAG 2.2 AA scans run in CI against showcase/pages/open states; 0 critical/serious is merge-blocking. | Use `@axe-core/playwright` with axe `runOnly` tags for WCAG A/AA plus `wcag22aa`, explicitly enable installed `target-size`, fail only `critical`/`serious`, and attach full JSON results. [CITED: https://playwright.dev/docs/accessibility-testing] [CITED: https://www.deque.com/axe/core-documentation/api-documentation/] [VERIFIED: temporary npm install of `@axe-core/playwright@4.11.3`] |
</phase_requirements>

## Summary

Phase 73 should be planned as test infrastructure, not UI implementation: add a root Node Playwright workspace, generate a target manifest from `ObanPowertools.ShowcaseCatalog`, run Chromium screenshots and axe scans against the real `examples/phoenix_host` `_showcase` route, and wire the result into the existing `ci-gate` fan-in. [VERIFIED: `73-CONTEXT.md`; `.github/workflows/ci.yml`; `lib/oban_powertools/web/router.ex`] The harness should snapshot only the nine current catalog-backed story cells, yielding 108 PNG baselines in Phase 73: 9 stories x 4 themes x 3 browser viewports. [VERIFIED: `test/support/showcase_catalog.ex`] [VERIFIED: `73-CONTEXT.md`]

Use Playwright's native snapshot machinery rather than an image-diff wrapper. Playwright generates reference screenshots, compares future runs, supports `--update-snapshots`, and documents that rendering varies by OS/browser/font environment, so the same Docker image must generate and verify baselines. [CITED: https://playwright.dev/docs/test-snapshots] [CITED: https://playwright.dev/docs/docker] The correct Docker pin as of this research is `mcr.microsoft.com/playwright:v1.61.0-noble`, matching `@playwright/test@1.61.0`. [VERIFIED: `npm view @playwright/test@1.61.0`] [CITED: https://playwright.dev/docs/docker]

For accessibility, use axe as a CI gate but keep claims narrow. Axe returns `violations`, `passes`, `incomplete`, and `inapplicable`, and each rule result carries an `impact` value such as `minor`, `moderate`, `serious`, or `critical`. [CITED: https://github.com/dequelabs/axe-core/blob/develop/doc/API.md] Phase 73 should fail only serious/critical violations while attaching full JSON output, including moderate/minor and incomplete results, for Phase 82 hardening. [VERIFIED: `73-CONTEXT.md`] [CITED: https://playwright.dev/docs/accessibility-testing]

**Primary recommendation:** Build a root Playwright + axe harness with generated JSON manifest, `chromium-320/tablet/wide` projects, committed `test/browser/__screenshots__` baselines, Docker-only run/update scripts, and a `visual_a11y` CI lane added to `ci-gate`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Catalog target authority | Elixir test/support | Browser harness | `ObanPowertools.ShowcaseCatalog` already owns scenario IDs, snapshot names, and a11y selectors; Node must consume generated JSON, not duplicate the list. [VERIFIED: `test/support/showcase_catalog.ex`] |
| Showcase rendering | Phoenix example host | ThemeShell/assets | The harness must exercise the real host route, live session, md5 CSS/JS asset paths, `.obpt-root`, and `data-obpt-*` selectors. [VERIFIED: `lib/oban_powertools/web/router.ex`; `lib/oban_powertools/web/theme_shell.ex`; `lib/oban_powertools/web/dev/showcase_live.ex`] |
| Visual comparison | Browser test harness | CI artifact store | Playwright owns screenshot capture, baseline comparison, update mode, and diff outputs. [CITED: https://playwright.dev/docs/test-snapshots] |
| Accessibility scanning | Browser test harness | axe-core rule engine | Axe scans the DOM in current/open state and returns structured rule results; Playwright attaches artifacts and enforces thresholds. [CITED: https://playwright.dev/docs/accessibility-testing] [CITED: https://www.deque.com/axe/core-documentation/api-documentation/] |
| Merge blocking | GitHub Actions CI | `ci-gate` fan-in | This repo already centralizes required status checks through `ci-gate`; adding `visual_a11y` to `needs` preserves branch-protection stability. [VERIFIED: `.github/workflows/ci.yml`] |
| Baseline review | Git repository | GitHub Actions artifacts | Expected PNGs are committed; actual/diff/report files are short-lived artifacts for review. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@playwright/test` | 1.61.0, published 2026-06-15, registry modified 2026-06-19 | Test runner, browser automation, visual snapshot assertions, HTML/JUnit reporters. | Official Playwright Test API supports `toHaveScreenshot`, `snapshotPathTemplate`, CI workers, Docker guidance, and `--update-snapshots`. [CITED: https://playwright.dev/docs/intro] [CITED: https://playwright.dev/docs/test-snapshots] [VERIFIED: `npm view @playwright/test@1.61.0`] |
| `@axe-core/playwright` | 4.11.3, published 2026-04-30, registry modified 2026-06-15 | Chainable `AxeBuilder` integration for Playwright pages and frames. | Official Deque package exposes `include`, `exclude`, `withTags`, `options`, and `analyze` for Playwright. [CITED: https://github.com/dequelabs/axe-core-npm/blob/develop/packages/playwright/README.md] [VERIFIED: `npm view @axe-core/playwright@4.11.3`] |
| `axe-core` | 4.11.4, published 2026-04-29, registry modified 2026-06-18 | Explicit direct dependency for the rule/result model used by `@axe-core/playwright@4.11.3`. | The adapter depends on `axe-core: ~4.11.4`; pinning it directly keeps the lockfile explicit and adapter-compatible. [VERIFIED: `npm view @axe-core/playwright@4.11.3 dependencies`] [VERIFIED: `npm view axe-core@4.11.4`] |
| `mcr.microsoft.com/playwright:v1.61.0-noble` | Playwright Docker image tag matching 1.61.0 | Reproducible Linux browser/font/system-dependency environment for screenshots. | Official Docker docs state the image includes browsers and browser system dependencies, while the Playwright package is installed separately. [CITED: https://playwright.dev/docs/docker] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| GitHub Actions `actions/upload-artifact` | Existing repo uses v4 pinned by SHA in `host-contract-proof.yml`; docs show v4 `retention-days`. | Upload Playwright report, actual/expected/diff images, and axe JSON. | Use in `visual_a11y` with `if: ${{ !cancelled() }}` and short retention. [VERIFIED: `.github/workflows/host-contract-proof.yml`] [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] |
| GitHub Actions `actions/setup-node` | Current Playwright docs show v6; pin by SHA to match repo style. | Provide Node/npm for `npm ci` before Docker test run. | Needed in CI because the Playwright Docker image does not include project npm dependencies. [CITED: https://playwright.dev/docs/ci] [VERIFIED: `.github/workflows/ci.yml` action pinning style] |
| `Jason` | Existing Mix dependency `~> 1.4` | Encode the generated showcase manifest from Elixir. | Use in `MIX_ENV=test mix run --no-start scripts/showcase_manifest.exs`. [VERIFIED: `mix.exs`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Playwright snapshots | Custom `pixelmatch` script | Playwright already uses Pixelmatch and manages baseline/update/reporting semantics; custom diffing would duplicate edge cases. [CITED: https://playwright.dev/docs/test-snapshots] |
| Pinned official Docker | Host-installed browsers | Official docs warn rendering varies by host OS, version, settings, hardware, headless mode, and other factors. [CITED: https://playwright.dev/docs/test-snapshots] |
| Generated manifest | Hardcoded JS story list | Hardcoding violates Phase 72's single-source catalog contract. [VERIFIED: `test/support/showcase_catalog.ex`] [VERIFIED: `73-CONTEXT.md`] |
| `@axe-core/playwright` | Raw `axe-core` injection | The wrapper already injects and runs axe through Playwright pages and frames. [CITED: https://github.com/dequelabs/axe-core-npm/blob/develop/packages/playwright/README.md] |
| Committed PNG baselines | Percy/Chromatic SaaS | Phase 73 explicitly rejects SaaS baseline stores. [VERIFIED: `73-CONTEXT.md`] |

**Installation:**

```bash
npm install --save-dev @playwright/test@1.61.0 @axe-core/playwright@4.11.3 axe-core@4.11.4
```

**Version verification:**

```bash
npm view @playwright/test@1.61.0 version time dist-tags.latest repository.url
npm view @axe-core/playwright@4.11.3 version time dependencies repository.url
npm view axe-core@4.11.4 version time repository.url
npm view @playwright/test scripts.postinstall
npm view @axe-core/playwright scripts.postinstall
npm view axe-core scripts.postinstall
```

The three recommended npm packages returned no `scripts.postinstall` value during this research. [VERIFIED: `npm view ... scripts.postinstall`] `@playwright/test` and `@axe-core/playwright` package names are cited from official docs, but the GSD package-legitimacy seam was unavailable, so they are not tagged `[VERIFIED: npm registry]`. [CITED: https://playwright.dev/docs/intro] [CITED: https://github.com/dequelabs/axe-core-npm/blob/develop/packages/playwright/README.md] [VERIFIED: failed `gsd-tools query package-legitimacy check`]

## Package Legitimacy Audit

> Required gate status: attempted, but the installed GSD CLI returned `Unknown command: package-legitimacy`. Manual registry and source checks were completed; planner should rerun the seam if it becomes available before installing. [VERIFIED: `gsd-tools query package-legitimacy check --ecosystem npm ...`]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | Created 2020-09-24; 1.61.0 published 2026-06-15 | 42,613,659 last-week downloads for 2026-06-12..2026-06-18 | `github.com/microsoft/playwright` | Manual OK; seam unavailable | Approved for planning; rerun legitimacy seam before execution if possible. [VERIFIED: `npm view`; npm downloads API] |
| `@axe-core/playwright` | npm | Created 2021-06-02; 4.11.3 published 2026-04-30 | 5,172,514 last-week downloads for 2026-06-12..2026-06-18 | `github.com/dequelabs/axe-core-npm` | Manual OK; seam unavailable | Approved for planning; rerun legitimacy seam before execution if possible. [VERIFIED: `npm view`; npm downloads API] |
| `axe-core` | npm | Created 2015-06-08; 4.11.4 published 2026-04-29 | 53,065,133 last-week downloads for 2026-06-12..2026-06-18 | `github.com/dequelabs/axe-core` | Manual OK; seam unavailable | Approved for planning; pin 4.11.4 to match adapter dependency. [VERIFIED: `npm view`; npm downloads API] |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none by manual audit; formal seam verdict unavailable.

*Packages are official-doc-cited and registry-checked, but not formally `[VERIFIED: npm registry]` because the package-legitimacy command was unavailable in this GSD installation.* [VERIFIED: failed `gsd-tools query package-legitimacy check`]

## Architecture Patterns

### System Architecture Diagram

```text
ObanPowertools.ShowcaseCatalog (Elixir, test/support)
  -> MIX_ENV=test manifest script (no timestamp, JSON schema v1)
  -> test/browser/.generated/showcase-manifest.json
  -> Playwright config/projects
       -> start/use Phoenix example host /ops/jobs/_showcase
       -> apply deterministic media/theme/viewport state
       -> story locator [data-obpt-story="..."]
          -> VRT: expect(locator).toHaveScreenshot()
          -> A11y: AxeBuilder.include(selector).analyze()
       -> committed PNG baselines + test-results attachments
  -> GitHub Actions visual_a11y lane
       -> upload Playwright report, diffs, axe JSON
       -> ci-gate checks visual_a11y result
```

### Recommended Project Structure

```text
package.json
package-lock.json
playwright.config.ts
scripts/
  showcase_manifest.exs                 # Emits catalog-derived JSON, no timestamp
  playwright-docker.sh                   # Runs Playwright in mcr.microsoft.com/playwright:v1.61.0-noble
  with-showcase-server.sh                # Starts examples/phoenix_host, runs command, cleans up
test/
  browser/
    .generated/                          # Ignored manifest output
      showcase-manifest.json
    __screenshots__/                     # Committed expected PNGs
      chromium-320/showcase/<story>/<theme>.png
      chromium-tablet/showcase/<story>/<theme>.png
      chromium-wide/showcase/<story>/<theme>.png
    specs/
      showcase.vrt.spec.ts
      showcase.a11y.spec.ts
      showcase.structure.spec.ts
    support/
      axe.ts
      deterministic.ts
      manifest.ts
      showcase.ts
    styles/
      screenshot.css
```

Root `package.json` and `package-lock.json` exist in this checkout but are currently untracked; Phase 73 should intentionally add them as part of the Node harness rather than assuming they are already committed. [VERIFIED: `git status --short`; `git ls-files package.json package-lock.json`]

### Pattern 1: Manifest Generated From Catalog

**What:** Generate a deterministic JSON manifest from `ShowcaseCatalog.scenarios/0` and helpers before Playwright runs. [VERIFIED: `test/support/showcase_catalog.ex`]

**When to use:** Always in CI and local Docker scripts; never hand-edit story IDs in JavaScript. [VERIFIED: `73-CONTEXT.md`]

**Recommended JSON shape:**

```json
{
  "schema_version": 1,
  "themes": ["system", "light", "dark", "high-contrast"],
  "viewports": [
    {"name": "320", "width": 320, "height": 900},
    {"name": "tablet", "width": 768, "height": 1000},
    {"name": "wide", "width": 1440, "height": 1000}
  ],
  "scenarios": [
    {
      "id": "jobs-long-identifiers-many",
      "domain": "jobs",
      "snapshot": "showcase/jobs-long-identifiers-many",
      "a11y": "[data-obpt-story=\"jobs-long-identifiers-many\"]",
      "story": "obpt-story-jobs-long-identifiers-many"
    }
  ]
}
```

Do not include `generated_at`, absolute paths, randomized order, or host-specific values in this manifest. [VERIFIED: `test/support/showcase_catalog.ex` deterministic constants]

**Command:**

```bash
MIX_ENV=test mix run --no-start scripts/showcase_manifest.exs > test/browser/.generated/showcase-manifest.json
```

### Pattern 2: Playwright Projects Encode Real Browser Viewports

**What:** Use three Chromium projects named `chromium-320`, `chromium-tablet`, and `chromium-wide`; each project sets real `viewport`, `deviceScaleFactor: 1`, `colorScheme: 'light'`, `reducedMotion: 'reduce'`, `timezoneId: 'UTC'`, and `locale: 'en-US'`. [CITED: https://playwright.dev/docs/api/class-testoptions] [VERIFIED: `73-CONTEXT.md`]

**When to use:** For both VRT and a11y specs so the target matrix is shared and hidden responsive issues are not missed. [VERIFIED: `73-CONTEXT.md`]

**Config skeleton:**

```typescript
// Source: Playwright config, snapshots, and CI docs
// https://playwright.dev/docs/api/class-testconfig
// https://playwright.dev/docs/test-snapshots
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './test/browser/specs',
  fullyParallel: false,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['junit', { outputFile: 'test-results/playwright-junit.xml' }]
  ],
  expect: {
    toHaveScreenshot: {
      animations: 'disabled',
      caret: 'hide',
      scale: 'css',
      stylePath: './test/browser/styles/screenshot.css',
      pathTemplate: './test/browser/__screenshots__{/projectName}/{arg}{ext}'
    }
  },
  use: {
    baseURL: process.env.PLAYWRIGHT_TEST_BASE_URL || 'http://127.0.0.1:4000',
    browserName: 'chromium',
    timezoneId: 'UTC',
    locale: 'en-US',
    colorScheme: 'light',
    reducedMotion: 'reduce',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure'
  },
  projects: [
    { name: 'chromium-320', use: { viewport: { width: 320, height: 900 } } },
    { name: 'chromium-tablet', use: { viewport: { width: 768, height: 1000 } } },
    { name: 'chromium-wide', use: { viewport: { width: 1440, height: 1000 } } }
  ]
});
```

### Pattern 3: Story-Level Screenshot Assertions

**What:** Navigate to `/ops/jobs/_showcase`, set the theme through `window.ObanPowertoolsTheme.setTheme(theme)` or the stable `data-obpt-theme-choice` controls, set the showcase viewport control, wait for fonts, then screenshot the story locator. [VERIFIED: `assets/oban_powertools/theme.js`; `lib/oban_powertools/web/dev/showcase_live.ex`] [CITED: https://playwright.dev/docs/test-snapshots]

**Example:**

```typescript
// Source: Playwright visual comparisons docs
// https://playwright.dev/docs/test-snapshots
import { expect, test } from '@playwright/test';
import { manifest } from '../support/manifest';
import { prepareShowcase } from '../support/showcase';

for (const theme of manifest.themes) {
  for (const scenario of manifest.scenarios) {
    test(`vrt ${scenario.id} ${theme}`, async ({ page }, testInfo) => {
      await prepareShowcase(page, {
        theme,
        viewportName: testInfo.project.name.replace('chromium-', '')
      });

      const story = page.locator(scenario.a11y);
      await expect(story).toBeVisible();
      await page.evaluate(() => document.fonts.ready);

      await expect(story).toHaveScreenshot([scenario.snapshot, `${theme}.png`]);
    });
  }
}
```

### Pattern 4: Axe Gate With Full JSON Attachments

**What:** Run axe against each story selector with explicit WCAG A/AA tags and installed WCAG 2.2 AA support; fail only serious/critical violations, but attach the complete result object. [CITED: https://playwright.dev/docs/accessibility-testing] [CITED: https://github.com/dequelabs/axe-core/blob/develop/doc/API.md]

**Important nuance:** `@axe-core/playwright@4.11.3` depends on `axe-core@~4.11.4`, and that installed version exposes one `wcag22aa` rule, `target-size`. [VERIFIED: temporary npm install and `axe.getRules(['wcag22aa'])`] The axe rule descriptions state WCAG 2.2 A/AA rules are disabled by default until WCAG 2.2 is more widely adopted, so Phase 73 should enable `target-size` explicitly when asking for `wcag22aa` coverage. [CITED: https://raw.githubusercontent.com/dequelabs/axe-core/develop/doc/rule-descriptions.md]

**Example:**

```typescript
// Source: Playwright accessibility and axe-core API docs
// https://playwright.dev/docs/accessibility-testing
// https://github.com/dequelabs/axe-core/blob/develop/doc/API.md
import { AxeBuilder } from '@axe-core/playwright';
import { expect, test } from '@playwright/test';
import { manifest } from '../support/manifest';
import { prepareShowcase } from '../support/showcase';

const wcagTags = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];
const blockingImpacts = new Set(['critical', 'serious']);

for (const theme of manifest.themes) {
  for (const scenario of manifest.scenarios) {
    test(`a11y ${scenario.id} ${theme}`, async ({ page }, testInfo) => {
      await prepareShowcase(page, {
        theme,
        viewportName: testInfo.project.name.replace('chromium-', '')
      });

      const results = await new AxeBuilder({ page })
        .include(scenario.a11y)
        .options({
          runOnly: { type: 'tag', values: wcagTags },
          rules: { 'target-size': { enabled: true } },
          resultTypes: ['violations', 'incomplete', 'inapplicable', 'passes']
        })
        .analyze();

      await testInfo.attach('axe-result', {
        body: JSON.stringify(results, null, 2),
        contentType: 'application/json'
      });

      const blocking = results.violations.filter((violation) =>
        blockingImpacts.has(violation.impact || '')
      );

      expect(blocking, JSON.stringify(blocking, null, 2)).toEqual([]);
    });
  }
}
```

### Anti-Patterns to Avoid

- **Hardcoded story IDs in JS:** It creates a second source of truth and will drift from `ShowcaseCatalog`. [VERIFIED: `73-CONTEXT.md`]
- **Full-page showcase screenshots in Phase 73:** They would lock placeholder sections that later phases are supposed to replace. [VERIFIED: `73-CONTEXT.md`]
- **Running baselines on host browsers:** Playwright warns host rendering changes affect screenshots; use the pinned Docker image for both update and CI. [CITED: https://playwright.dev/docs/test-snapshots] [CITED: https://playwright.dev/docs/docker]
- **Broad screenshot masks:** They hide the long IDs, status colors, focus states, RTL/non-ASCII text, and severity cues the stress fixtures exist to protect. [VERIFIED: `73-CONTEXT.md`; `test/support/showcase_catalog.ex`]
- **Using `withTags()` and then `.options()` unknowingly:** `@axe-core/playwright` documents that `options()` overrides configured `withTags()`/`withRules()`, so use `options({ runOnly, rules })` when enabling `target-size`. [CITED: https://github.com/dequelabs/axe-core-npm/blob/develop/packages/playwright/README.md]
- **Separate required workflow with path filters:** GitHub documents that path-filtered required workflows can stay pending when skipped; keep the lane in the existing workflow and fan into `ci-gate`. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks] [VERIFIED: `.github/workflows/ci.yml`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pixel comparison | Custom PNG diffing or shell scripts around `pixelmatch` | Playwright `expect(locator).toHaveScreenshot()` | Playwright owns baseline generation, retries until stable, update mode, project/platform pathing, and report integration. [CITED: https://playwright.dev/docs/test-snapshots] |
| Browser dependency management | Installing Chrome manually in CI | Official Playwright Docker image pinned to package version | The image bundles browsers and browser system dependencies for the matching Playwright release. [CITED: https://playwright.dev/docs/docker] |
| WCAG rule engine | Custom DOM accessibility checks | `@axe-core/playwright` plus `axe-core` | Axe provides rule tags, result arrays, impacts, help URLs, and incomplete/manual-review reporting. [CITED: https://www.deque.com/axe/core-documentation/api-documentation/] |
| Artifact upload | Custom curl/GitHub API artifact uploader | `actions/upload-artifact` | GitHub's supported action handles named artifacts, directories, wildcards, and retention days. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] |
| Target manifest parsing in JS from `.ex` source | Regex parsing Elixir | Mix script requiring `ShowcaseCatalog` and using `Jason` | The module already exposes helpers; parsing source text would be brittle. [VERIFIED: `test/support/showcase_catalog.ex`; `mix.exs`] |

**Key insight:** The hard part is not taking screenshots; it is keeping the rendering inputs stable and keeping ownership single-sourced. The plan should spend effort on Docker pinning, manifest generation, media/theme control, and artifact review instead of reinventing diff or a11y engines. [CITED: https://playwright.dev/docs/test-snapshots] [VERIFIED: `73-CONTEXT.md`]

## Common Pitfalls

### Pitfall 1: Baselines Generated Outside Docker

**What goes wrong:** CI fails on pixels that looked fine locally. [CITED: https://playwright.dev/docs/test-snapshots]
**Why it happens:** Browser rendering varies by OS, browser version, fonts, hardware, headless mode, and other factors. [CITED: https://playwright.dev/docs/test-snapshots]
**How to avoid:** Make `npm run vrt:update` and CI both call the same `mcr.microsoft.com/playwright:v1.61.0-noble` runner. [CITED: https://playwright.dev/docs/docker]
**Warning signs:** PNG diffs with antialiasing/font changes across most text rather than a localized UI change. [ASSUMED]

### Pitfall 2: Catalog Drift

**What goes wrong:** New Phase 74+ stories are added to `ShowcaseCatalog`, but the Node harness silently skips them. [VERIFIED: `test/support/showcase_catalog.ex`]
**Why it happens:** The story list was copied into TypeScript. [VERIFIED: `73-CONTEXT.md`]
**How to avoid:** Generate the JSON manifest from `ShowcaseCatalog.scenarios/0`; add a smoke test asserting manifest scenario IDs equal rendered `[data-obpt-story]` attributes. [VERIFIED: `lib/oban_powertools/web/dev/showcase_live.ex`]
**Warning signs:** ExUnit story count and Playwright story count differ. [VERIFIED: `test/oban_powertools/showcase_catalog_test.exs`]

### Pitfall 3: `system` Theme Is Not Actually Deterministic

**What goes wrong:** `system` screenshots flip between light, dark, or high-contrast. [VERIFIED: `assets/oban_powertools/theme.js`]
**Why it happens:** The theme script derives effective system theme from `prefers-color-scheme` and `prefers-contrast`. [VERIFIED: `assets/oban_powertools/theme.js`]
**How to avoid:** Set Playwright media to `colorScheme: 'light'`, no forced high contrast, `reducedMotion: 'reduce'`, then assert `.obpt-root[data-obpt-theme="system"][data-obpt-effective-theme="light"]`. [CITED: https://playwright.dev/docs/api/class-testoptions] [VERIFIED: `assets/oban_powertools/theme.js`]
**Warning signs:** Only `system` baselines differ and explicit `light`/`dark`/`high-contrast` remain stable. [ASSUMED]

### Pitfall 4: WCAG 2.2 Tag Does Not Mean All WCAG 2.2 Is Automated

**What goes wrong:** The project claims full WCAG 2.2 AA coverage from axe. [VERIFIED: `73-CONTEXT.md`]
**Why it happens:** Axe can only test automatically detectable rules, and Playwright docs explicitly note automated testing cannot detect all WCAG violations. [CITED: https://playwright.dev/docs/accessibility-testing]
**How to avoid:** Document the exact installed `wcag22aa` support (`target-size` in axe 4.11.4), enable it explicitly, and defer manual focus/SR/reflow assertions to Phase 82. [VERIFIED: temporary npm install of `axe-core@4.11.4`] [VERIFIED: `73-CONTEXT.md`]
**Warning signs:** Research or docs say "axe proves WCAG 2.2 AA" instead of "axe gates automatically detectable serious/critical violations." [CITED: https://playwright.dev/docs/accessibility-testing]

### Pitfall 5: Artifacts Missing On Failure

**What goes wrong:** A visual/a11y failure blocks merge but reviewers cannot inspect the actual/diff/axe output. [VERIFIED: `73-CONTEXT.md`]
**Why it happens:** Upload steps are conditional on job success or do not include `test-results/`. [ASSUMED]
**How to avoid:** Upload `playwright-report/`, `test-results/`, and axe JSON with `if: ${{ !cancelled() }}` and short retention. [CITED: https://playwright.dev/docs/ci] [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data]
**Warning signs:** CI log has snapshot failure paths but no downloadable artifact. [ASSUMED]

### Pitfall 6: `ci-gate` Does Not Actually See The Browser Lane

**What goes wrong:** `visual_a11y` fails but `ci-gate` still passes, or the lane is skipped and branch protection waits forever. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks]
**Why it happens:** The new job is not in `needs`, or the required check is a separate workflow affected by path filters. [VERIFIED: `.github/workflows/ci.yml`]
**How to avoid:** Add `visual_a11y` to `needs`, add `VISUAL_A11Y` to the verification loop, and leave the single branch-protected check as `ci-gate`. [VERIFIED: `.github/workflows/ci.yml`]
**Warning signs:** PR checks show `visual_a11y` separately but `ci-gate` does not list it in its environment loop. [VERIFIED: `.github/workflows/ci.yml`]

## Code Examples

Verified patterns from official sources and repo-local seams:

### Manifest Script Skeleton

```elixir
# Source: test/support/showcase_catalog.ex and mix.exs
# Run with: MIX_ENV=test mix run --no-start scripts/showcase_manifest.exs
alias ObanPowertools.ShowcaseCatalog

themes = ~w[system light dark high-contrast]
viewports = [
  %{name: "320", width: 320, height: 900},
  %{name: "tablet", width: 768, height: 1000},
  %{name: "wide", width: 1440, height: 1000}
]

scenarios =
  ShowcaseCatalog.scenarios()
  |> Enum.map(fn scenario ->
    id = Map.fetch!(scenario, :id)

    %{
      id: id,
      domain: scenario.domain |> Atom.to_string(),
      story: Map.fetch!(scenario.test_targets, :story),
      snapshot: ShowcaseCatalog.snapshot_name(id),
      a11y: ShowcaseCatalog.a11y_target(id)
    }
  end)

IO.write(Jason.encode!(%{schema_version: 1, themes: themes, viewports: viewports, scenarios: scenarios}))
```

### Deterministic Showcase Prep

```typescript
// Source: assets/oban_powertools/theme.js and ShowcaseLive selectors
import { expect, Page } from '@playwright/test';

export async function prepareShowcase(page: Page, opts: { theme: string; viewportName: string }) {
  await page.emulateMedia({ colorScheme: 'light', reducedMotion: 'reduce' });
  await page.goto('/ops/jobs/_showcase');

  await expect(page.locator('.obpt-root')).toHaveCount(1);
  await page.evaluate((theme) => window.ObanPowertoolsTheme?.setTheme(theme), opts.theme);
  await page.locator(`[data-obpt-viewport="${opts.viewportName}"]`).click();
  await page.waitForLoadState('networkidle');
  await page.evaluate(() => document.fonts.ready);

  const root = page.locator('.obpt-root');
  await expect(root).toHaveAttribute('data-obpt-theme', opts.theme);

  if (opts.theme === 'system') {
    await expect(root).toHaveAttribute('data-obpt-effective-theme', 'light');
  }
}
```

### Docker Runner Command

```bash
# Source: Playwright Docker docs
docker run --rm --init --ipc=host --network host \
  -e CI=1 \
  -e PLAYWRIGHT_TEST_BASE_URL="${PLAYWRIGHT_TEST_BASE_URL:-http://127.0.0.1:4000}" \
  -v "$PWD:/work" \
  -w /work \
  mcr.microsoft.com/playwright:v1.61.0-noble \
  npm run visual:a11y:host
```

For macOS local baseline updates, the wrapper may need `host.docker.internal` instead of `--network host`; verify this during implementation because Docker Desktop networking differs from Linux CI. [ASSUMED]

### CI Fan-In Shape

```yaml
# Source: .github/workflows/ci.yml and GitHub Actions artifact docs
visual_a11y:
  name: Visual & A11y
  runs-on: ubuntu-latest
  timeout-minutes: 20
  env:
    CI: "true"
    MIX_ENV: dev
    PGUSER: postgres
    PGPASSWORD: postgres
  services:
    postgres:
      image: postgres:16
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
      ports: ["5432:5432"]
      options: >-
        --health-cmd "pg_isready -U postgres"
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5
  steps:
    - uses: actions/checkout@<pin>
    - uses: erlef/setup-beam@<existing-pin>
      with:
        elixir-version: "1.19.5"
        otp-version: "27.3"
    - uses: actions/setup-node@<pin>
      with:
        node-version: "22"
        cache: npm
    - run: mix deps.get
    - run: npm ci
    - run: npm run showcase:manifest
    - run: scripts/with-showcase-server.sh npm run visual:a11y:docker
    - uses: actions/upload-artifact@<pin>
      if: ${{ !cancelled() }}
      with:
        name: visual-a11y-report
        path: |
          playwright-report/
          test-results/
          test/browser/.generated/showcase-manifest.json
        retention-days: 7

ci-gate:
  needs: [format, compile, test, docs_package, actionlint, visual_a11y]
```

## Screenshot And A11y Matrix

| Axis | Values | Count | Notes |
|------|--------|-------|-------|
| Stories | 9 catalog scenarios | 9 | Initial scenario IDs are stable and tested. [VERIFIED: `test/oban_powertools/showcase_catalog_test.exs`] |
| Themes | `system`, `light`, `dark`, `high-contrast` | 4 | Explicit themes use `ObanPowertoolsTheme.setTheme`; `system` uses deterministic light media. [VERIFIED: `assets/oban_powertools/theme.js`] |
| Browser viewports | `320`, `tablet` 768px, `wide` 1440px | 3 | Set by Playwright viewport, then mirror the showcase viewport control. [VERIFIED: `lib/oban_powertools/web/dev/showcase_live.ex`] |
| Browser engine | Chromium in Playwright Docker | 1 | Cross-browser pixel baselines are not required by VRT-01 and would multiply review noise. [VERIFIED: `73-CONTEXT.md`] |

**VRT count:** 9 x 4 x 3 x 1 = 108 committed PNG baselines. [VERIFIED: `test/support/showcase_catalog.ex`; `73-CONTEXT.md`]

**A11y count:** run the same 108 story/theme/viewport targets in Chromium, plus implemented open-state variants when real stories exist. [VERIFIED: `73-CONTEXT.md`] Reserved metadata alone (`confirm_action_open`, `tooltip_open`, `drawer_open`) should not create scans until corresponding open DOM is implemented. [VERIFIED: `lib/oban_powertools/web/dev/showcase_live.ex`; `73-CONTEXT.md`]

## CI And Artifact Design

Add `visual_a11y` inside `.github/workflows/ci.yml` and add it to `ci-gate.needs`. [VERIFIED: `.github/workflows/ci.yml`] Keep the existing `paths-ignore` behavior; code and baseline changes under `test/browser/**`, `package*.json`, scripts, and CI files will trigger the workflow, while `.planning/**` only changes remain ignored. [VERIFIED: `.github/workflows/ci.yml`]

The CI lane should run on Ubuntu with Postgres service, setup Beam 1.19.5/OTP 27.3 like existing jobs, setup Node 22, run `npm ci`, generate the manifest, start `examples/phoenix_host` in dev mode, and run Playwright inside `mcr.microsoft.com/playwright:v1.61.0-noble`. [VERIFIED: `.github/workflows/ci.yml`; `examples/phoenix_host/config/dev.exs`] [CITED: https://playwright.dev/docs/ci] The host app dev route is enabled in `examples/phoenix_host/config/dev.exs`, and `_showcase` is mounted under `/ops/jobs` by the host router. [VERIFIED: `examples/phoenix_host/config/dev.exs`; `examples/phoenix_host/lib/phoenix_host_web/router.ex`]

Artifacts should be uploaded with `if: ${{ !cancelled() }}` and `retention-days: 7`. [CITED: https://playwright.dev/docs/ci] [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] Upload paths should include `playwright-report/`, `test-results/`, and the generated manifest; Playwright will place snapshot actual/expected/diff outputs and attachments under test output/report paths on failure. [CITED: https://playwright.dev/docs/test-snapshots] [CITED: https://playwright.dev/docs/accessibility-testing]

## Baseline Update Workflow

Recommended npm scripts:

```json
{
  "scripts": {
    "showcase:manifest": "mkdir -p test/browser/.generated && MIX_ENV=test mix run --no-start scripts/showcase_manifest.exs > test/browser/.generated/showcase-manifest.json",
    "visual:a11y": "npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:docker",
    "visual:a11y:host": "npx playwright test",
    "visual:a11y:docker": "scripts/playwright-docker.sh npx playwright test",
    "vrt:update": "npm run showcase:manifest && scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/showcase.vrt.spec.ts --update-snapshots=changed"
  }
}
```

Default update mode should be `--update-snapshots=changed`, because Playwright CLI supports `all`, `changed`, `missing`, and `none`, with `changed` as the flag preset. [VERIFIED: `npx playwright test --help` for 1.61.0] Add examples for narrow updates:

```bash
npm run vrt:update -- --grep "jobs-long-identifiers-many"
npm run vrt:update -- --project=chromium-320 --grep "dark"
```

PRs that change `test/browser/__screenshots__/**/*.png` should explain why, and CI should never run an update script. [VERIFIED: `73-CONTEXT.md`]

## Determinism Risks And Controls

| Risk | Control | Source |
|------|---------|--------|
| OS/browser/font rendering drift | Same Playwright Docker image for CI and updates. | [CITED: https://playwright.dev/docs/test-snapshots] [CITED: https://playwright.dev/docs/docker] |
| Animation/caret flicker | Use `toHaveScreenshot` defaults or explicit `animations: 'disabled'`, `caret: 'hide'`. | [CITED: https://playwright.dev/docs/api/class-testconfig] |
| Font load race | Wait for `document.fonts.ready` before capture. | [ASSUMED] |
| Timezone/locale variance | Set `timezoneId: 'UTC'` and `locale: 'en-US'`. | [CITED: https://playwright.dev/docs/api/class-testoptions] |
| Media preference variance | Set `colorScheme: 'light'`, `reducedMotion: 'reduce'`, and assert system effective theme. | [CITED: https://playwright.dev/docs/api/class-testoptions] [VERIFIED: `assets/oban_powertools/theme.js`] |
| Generated manifest churn | No timestamps or absolute paths; stable scenario order from module attributes. | [VERIFIED: `test/support/showcase_catalog.ex`] |
| Network/server readiness | Use a wrapper or Playwright `webServer`-equivalent readiness check before tests. | [CITED: https://playwright.dev/docs/test-webserver] |
| Overmasking | Only screenshot style genuinely volatile pixels; do not mask story data. | [VERIFIED: `73-CONTEXT.md`] |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Host-installed browser screenshots | Version-matched Playwright Docker image | Current official docs for 1.61.0 show `mcr.microsoft.com/playwright:v1.61.0-noble`. [CITED: https://playwright.dev/docs/docker] | Baselines are tied to a reproducible Linux browser environment. |
| Global or file-adjacent snapshot directories only | `snapshotPathTemplate` and assertion-specific `pathTemplate` | Playwright `snapshotPathTemplate` added in v1.28; current docs support project/name tokens. [CITED: https://playwright.dev/docs/api/class-testconfig] | Planner can use a human-readable baseline tree under `test/browser/__screenshots__`. |
| WCAG 2.0/2.1 tags only | Add `wcag22aa` where installed axe supports it, with explicit `target-size` enablement | Installed axe 4.11.4 exposes `target-size` tagged `wcag22aa`; rule descriptions mark WCAG 2.2 rules disabled by default. [VERIFIED: temporary npm install] [CITED: https://raw.githubusercontent.com/dequelabs/axe-core/develop/doc/rule-descriptions.md] | Phase 73 can honestly include supported WCAG 2.2 AA automation without claiming full manual coverage. |
| Standalone required workflow | Existing workflow lane with `ci-gate` fan-in | Repo already uses `ci-gate` as single required status. [VERIFIED: `.github/workflows/ci.yml`] | Avoids branch protection drift and skipped-required-check footguns. |

**Deprecated/outdated:**

- `actions/upload-artifact@v3` or older should not be introduced; repo already uses v4 pinned by SHA, and GitHub artifact docs show v4 usage. [VERIFIED: `.github/workflows/host-contract-proof.yml`] [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data]
- Wallaby/playwright-elixir are out of scope for visual diffing in this milestone; requirements explicitly choose external Node Playwright. [VERIFIED: `.planning/REQUIREMENTS.md`]
- SaaS baseline stores are out of scope for Phase 73. [VERIFIED: `73-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | macOS local Docker update can reach a host Phoenix server through `host.docker.internal` or script branching. | Code Examples / Baseline Update Workflow | Local baseline updates may need a small endpoint bind override or documentation adjustment. |
| A2 | 108 VRT screenshots plus 108 axe scans will fit the current CI budget after workers are set to 1 and the server is reused. | Screenshot And A11y Matrix | Planner may need to split VRT/a11y specs or optimize before reducing coverage. |
| A3 | `document.fonts.ready` is sufficient for current system-font stack. | Determinism Risks And Controls | If future custom fonts are introduced, a stronger preload/font readiness gate may be needed. |
| A4 | Manual package audit is sufficient for planning while the GSD legitimacy seam is unavailable. | Package Legitimacy Audit | Execution should rerun the formal seam or add a human verification checkpoint before install. |

## Open Questions (RESOLVED)

1. **Will the first axe run find current serious/critical violations in the Phase 72 skeleton?**
   - RESOLVED: Plan 73-03 owns the first axe run and any narrow serious/critical showcase shell fixes needed to make the merge-blocking gate green.
   - What we know: the skeleton has semantic sections, controls, and catalog cells, but axe has not been run yet. [VERIFIED: `lib/oban_powertools/web/dev/showcase_live.ex`]
   - What's unclear: whether `target-size`, contrast, or structural rules fail in current CSS. [ASSUMED]
   - Recommendation: Execute the Plan 73-03 axe task as the first serious/critical red/green run; if failures are in the showcase shell itself, fix the shell CSS/markup narrowly in Phase 73 so the gate can be merge-blocking. [VERIFIED: `73-CONTEXT.md`]

2. **Should a direct `axe-core@4.12.1` install be deferred?**
   - RESOLVED: Retain the adapter-compatible direct `axe-core@4.11.4` pin with `@axe-core/playwright@4.11.3`; upgrade both together when Deque publishes a compatible adapter line.
   - What we know: latest standalone `axe-core` is 4.12.1, but latest `@axe-core/playwright` is 4.11.3 and depends on `~4.11.4`. [VERIFIED: `npm view`]
   - What's unclear: when Deque will publish `@axe-core/playwright` 4.12.x. [ASSUMED]
   - Recommendation: Pin adapter-compatible `axe-core@4.11.4` now; upgrade both together when the wrapper publishes a 4.12 line. [VERIFIED: `npm view @axe-core/playwright@4.11.3 dependencies`]

3. **Will local Docker networking need repo config changes?**
   - RESOLVED: Plan 73-02 handles this through `scripts/playwright-docker.sh` and `scripts/with-showcase-server.sh` wrapper branching for Linux CI host networking and macOS Docker Desktop host naming.
   - What we know: Linux CI can use `--network host`; macOS Docker Desktop usually uses `host.docker.internal`. [ASSUMED]
   - What's unclear: whether the example host's current 127.0.0.1 dev bind works for every local Docker update path. [VERIFIED: `examples/phoenix_host/config/dev.exs`]
   - Recommendation: Implement script branching first; add an env-driven bind override only if local verification fails. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | npm install and Playwright tooling | yes | v22.14.0 local; Playwright docs support latest 22.x/24.x/26.x | Use GitHub `actions/setup-node` 22 in CI. [VERIFIED: `node --version`] [CITED: https://playwright.dev/docs/intro] |
| npm | Root Node lockfile and scripts | yes | 11.1.0 | None needed. [VERIFIED: `npm --version`] |
| Docker | Pinned Playwright browser execution | yes | 29.5.2 local | CI can use Docker on `ubuntu-latest`; no non-Docker baseline generation fallback should be accepted. [VERIFIED: `docker --version`; `docker info`] |
| Elixir/Mix | Manifest generation and Phoenix host | yes | Elixir 1.19.5 / Mix 1.19.5 local; CI pins Elixir 1.19.5 and OTP 27.3 | Use existing `erlef/setup-beam` pin in CI. [VERIFIED: `elixir --version`; `.github/workflows/ci.yml`] |
| PostgreSQL | Example Phoenix host startup | yes | Server accepting on 5432; `psql` client 14.17 | CI service already uses postgres:16 pattern. [VERIFIED: `pg_isready`; `.github/workflows/ci.yml`] |
| actionlint | Workflow lint | yes | 1.7.12 local; CI uses raven-actions/actionlint v2.1.2 pinned by SHA | Existing CI lane covers workflow syntax. [VERIFIED: `actionlint -version`; `.github/workflows/ci.yml`] |

**Missing dependencies with no fallback:** none found. [VERIFIED: environment probes]

**Missing dependencies with fallback:** formal GSD package-legitimacy seam unavailable; manual package audit completed and execution should rerun seam if available. [VERIFIED: failed `gsd-tools query package-legitimacy check`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit for Elixir contracts; Playwright Test 1.61.0 for browser VRT/a11y. [VERIFIED: existing `test/**/*_test.exs`; `npm view @playwright/test@1.61.0`] |
| Config file | Existing ExUnit via `mix.exs` and `test/test_helper.exs`; new `playwright.config.ts` required in Wave 0. [VERIFIED: `mix.exs`; `test/test_helper.exs`] |
| Quick run command | `mix test test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs && npm run visual:a11y -- --grep "overview-operational-empty"` |
| Full suite command | `mix test --exclude host_contract && npm run visual:a11y` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| VRT-01 | Playwright captures catalog story cells across themes and browser viewports in Docker. | browser VRT | `npm run visual:a11y -- test/browser/specs/showcase.vrt.spec.ts` | No - Wave 0 |
| VRT-02 | PNG baselines are committed; diff fails CI; update command uses `--update-snapshots=changed`. | browser VRT + CI | `npm run vrt:update -- --grep overview-operational-empty && git diff -- test/browser/__screenshots__` | No - Wave 0 |
| VRT-03 | Deterministic media/theme/viewport/font/screenshot controls are applied. | browser smoke + VRT | `npm run visual:a11y -- test/browser/specs/showcase.structure.spec.ts` | No - Wave 0 |
| A11Y-01 | Axe scans catalog targets with WCAG A/AA + supported WCAG 2.2 AA tags and fails serious/critical only. | browser a11y | `npm run visual:a11y -- test/browser/specs/showcase.a11y.spec.ts` | No - Wave 0 |
| SHOW support | Structural route/control/story contracts remain green. | ExUnit | `mix test test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/showcase_catalog_test.exs` | Yes |
| CI support | `visual_a11y` is included in `ci-gate` fan-in. | workflow lint | `actionlint .github/workflows/ci.yml` | Existing workflow yes; lane no - Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs` plus the narrow relevant Playwright spec. [VERIFIED: existing ExUnit files]
- **Per wave merge:** `mix test --exclude host_contract && npm run visual:a11y`. [VERIFIED: `.github/workflows/ci.yml` existing non-host suite]
- **Phase gate:** Full suite green, committed baselines present, `npm run visual:a11y` green without update mode, and `ci-gate` includes `visual_a11y`. [VERIFIED: `73-CONTEXT.md`; `.github/workflows/ci.yml`]

### Wave 0 Gaps

- [ ] `package.json` and `package-lock.json` committed with exact dev dependencies and scripts. [VERIFIED: currently untracked]
- [ ] `playwright.config.ts` with Docker-compatible Chromium projects and snapshot path template. [CITED: https://playwright.dev/docs/api/class-testconfig]
- [ ] `scripts/showcase_manifest.exs` and `.gitignore` entry for `/test/browser/.generated/`. [VERIFIED: `.gitignore` currently lacks this entry]
- [ ] `scripts/playwright-docker.sh` and `scripts/with-showcase-server.sh` wrappers. [ASSUMED]
- [ ] `test/browser/specs/showcase.structure.spec.ts`, `showcase.vrt.spec.ts`, `showcase.a11y.spec.ts`. [ASSUMED]
- [ ] `test/browser/support/*` helpers and `test/browser/styles/screenshot.css`. [ASSUMED]
- [ ] `.github/workflows/ci.yml` `visual_a11y` lane and `ci-gate` fan-in update. [VERIFIED: `.github/workflows/ci.yml`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no for the harness | The example host auth seam returns a demo ops actor by default; Phase 73 does not change auth semantics. [VERIFIED: `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex`] |
| V3 Session Management | no for the harness | No new session storage beyond existing Phoenix/LiveView session. [VERIFIED: `lib/oban_powertools/web/router.ex`] |
| V4 Access Control | yes, as route-scope proof | Keep route dev/test-only and run against example host route; do not expose `_showcase` in prod. [VERIFIED: `lib/oban_powertools/web/router.ex`; `72-04-SUMMARY.md`] |
| V5 Input Validation | yes | Validate generated manifest schema in Node before tests and reject unknown theme/viewport/story selector values. [VERIFIED: `test/support/showcase_catalog.ex`] |
| V6 Cryptography | no | Do not add custom crypto; asset md5 paths already exist and are outside this phase. [VERIFIED: `lib/oban_powertools/web/assets.ex`] |
| V14 Configuration | yes | Pin npm package versions, Docker image tag, GitHub Actions by SHA, and CI service versions. [VERIFIED: `.github/workflows/ci.yml`; `npm view`] |

### Known Threat Patterns for Visual/A11y Harness

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Supply-chain package confusion | Tampering | Use official-doc package names, exact versions, lockfile, no postinstall scripts, rerun GSD package-legitimacy seam when available. [CITED: https://playwright.dev/docs/intro] [CITED: https://github.com/dequelabs/axe-core-npm/blob/develop/packages/playwright/README.md] [VERIFIED: `npm view scripts.postinstall`] |
| Artifact leakage | Information Disclosure | Upload only local showcase reports/diffs/axe JSON; do not include env files or broad workspace zips. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] |
| Untrusted browsing in Playwright Docker | Elevation of Privilege | Use the Docker image only against trusted local showcase routes; official docs warn it is for testing/development and not recommended for untrusted websites. [CITED: https://playwright.dev/docs/docker] |
| Required check bypass | Tampering | Put `visual_a11y` in `ci-gate.needs` with `if: always()` fan-in verification. [VERIFIED: `.github/workflows/ci.yml`] [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks] |

## Sources

### Primary (HIGH confidence)

- `test/support/showcase_catalog.ex` - scenario IDs, snapshot names, a11y selectors, deterministic fixture values. [VERIFIED: codebase read]
- `test/oban_powertools/showcase_catalog_test.exs` - stable domain/scenario/test target contracts. [VERIFIED: codebase read]
- `lib/oban_powertools/web/dev/showcase_live.ex` - `_showcase` selectors, theme/viewport controls, story cells, open-state metadata. [VERIFIED: codebase read]
- `lib/oban_powertools/web/router.ex` - `_showcase` route guard and ThemeShell live session. [VERIFIED: codebase read]
- `lib/oban_powertools/web/theme_shell.ex` - `.obpt-root`, theme/effective-theme/motion attributes, md5 asset inclusion. [VERIFIED: codebase read]
- `assets/oban_powertools/theme.js` - theme storage, effective theme media behavior, `window.ObanPowertoolsTheme`. [VERIFIED: codebase read]
- `.github/workflows/ci.yml` - existing required `ci-gate` fan-in pattern. [VERIFIED: codebase read]
- Playwright visual comparisons - `toHaveScreenshot`, baseline generation, `--update-snapshots`, rendering variance warning. [CITED: https://playwright.dev/docs/test-snapshots]
- Playwright Docker - `v1.61.0-noble` image, browsers/system dependencies, package installed separately. [CITED: https://playwright.dev/docs/docker]
- Playwright CI - workers=1 guidance, setup, Docker container examples, report upload. [CITED: https://playwright.dev/docs/ci]
- Playwright TestConfig/TestOptions - `snapshotPathTemplate`, screenshot options, update snapshots modes, media options, webServer. [CITED: https://playwright.dev/docs/api/class-testconfig] [CITED: https://playwright.dev/docs/api/class-testoptions] [CITED: https://playwright.dev/docs/test-webserver]
- Playwright accessibility testing - AxeBuilder usage, open-state scans, WCAG tags, full result attachments, automation limitation. [CITED: https://playwright.dev/docs/accessibility-testing]
- Deque axe API docs - tags, result arrays, impacts, `runOnly`, `rules`, `resultTypes`. [CITED: https://www.deque.com/axe/core-documentation/api-documentation/] [CITED: https://github.com/dequelabs/axe-core/blob/develop/doc/API.md]
- Deque `@axe-core/playwright` README - wrapper API and `options()` override behavior. [CITED: https://github.com/dequelabs/axe-core-npm/blob/develop/packages/playwright/README.md]
- GitHub Actions artifacts and required-check troubleshooting. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks]

### Secondary (MEDIUM confidence)

- npm registry metadata for package versions, publish/modified dates, repositories, licenses, no postinstall scripts, and last-week download counts. [VERIFIED: `npm view`; npm downloads API]
- Temporary npm install in `/tmp` of `@axe-core/playwright@4.11.3` and `axe.getRules(['wcag22aa'])` proving installed axe version 4.11.4 exposes `target-size` as the supported `wcag22aa` rule. [VERIFIED: local npm install]

### Tertiary (LOW confidence)

- Local Docker networking assumptions for macOS vs Linux wrapper behavior. [ASSUMED]
- Estimated runtime of the 108 VRT + 108 a11y scan matrix before implementation. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - official docs and npm versions are verified, but the GSD package-legitimacy seam was unavailable. [VERIFIED: failed seam; npm view]
- Architecture: HIGH - all critical repo seams were read and match Phase 73 locked decisions. [VERIFIED: codebase read; `73-CONTEXT.md`]
- Pitfalls: HIGH - main pitfalls come from official Playwright/GitHub/Deque docs and current repo structure. [CITED: official docs] [VERIFIED: codebase read]

**Research date:** 2026-06-19
**Valid until:** 2026-06-26 for package/Docker versions; repo-local architecture remains valid until Phase 72 showcase/catalog changes.
