# Phase 73: Visual-Regression & A11y Harness - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 73 establishes the external Node Playwright visual-regression and axe-core accessibility harness for the v2.0 Powertools Identity milestone. The goal is to make the Phase 72 showcase and deterministic fixture catalog a real merge-blocking quality gate before primitives, forms, app shell, data display, meta-components, and page migrations begin.

This phase is guardrail infrastructure. It does not implement new UI components, migrate operator pages, redesign the showcase, add new operator capability, or tighten the full manual accessibility contract from Phase 82. It creates the harness, committed baselines, CI lane, artifact/reporting flow, and baseline-update workflow that later phases consume.

In scope:

- External Node Playwright harness with `@playwright/test` and `@axe-core/playwright`.
- Pinned Playwright Docker execution for reproducible screenshots in CI and local update scripts.
- Visual snapshots for Phase 72 catalog-backed showcase story targets across themes and viewports.
- Axe scans for the same stable showcase targets and currently implemented open-state variants.
- Merge-blocking CI integration through the existing `ci-gate` fan-in.
- Committed PNG baselines and an explicit, reviewable `--update-snapshots` workflow.

Out of scope:

- Pixel-locking future placeholder sections before real component stories exist.
- Failing every moderate/minor axe finding before Phase 82's broader accessibility pass.
- Replacing manual keyboard/focus/reduced-motion/screen-reader review with automation claims.
- Introducing SaaS visual-regression services, PhoenixStorybook, Wallaby, or Hex runtime dependencies.

</domain>

<decisions>
## Implementation Decisions

### CI Enforcement
- **D-01:** Add a required `visual_a11y` lane inside `.github/workflows/ci.yml` and include it in the existing `ci-gate` job. This matches the repo's current branch-protection and release model: one stable required status (`ci-gate`) fans in every blocking lane, and `release.yml` already waits for `ci-gate` before publishing.
- **D-02:** The `visual_a11y` lane is merge-blocking on pull requests and pushes, not a manual or local-only check. A manual/local script may exist for debugging and baseline updates, but it does not satisfy VRT-02 or A11Y-01.
- **D-03:** Run the browser harness in a pinned official Playwright Docker image that matches the locked `@playwright/test` version. Do not rely on developer OS/browser/font parity for baseline generation. The Node toolchain lives at the repo root as development/test infrastructure, with `package-lock.json` committed. No new Hex runtime dependency is introduced.
- **D-04:** Drive the harness against the dev/test-only `examples/phoenix_host` `/ops/jobs/_showcase` route, not a synthetic static page. This proves the real host-owned router path, `ThemeShell`, md5 Powertools CSS/JS assets, `.obpt-root`, and catalog-backed story cells together.

### Snapshot Scope
- **D-05:** Baseline only catalog-backed story cells from `ObanPowertools.ShowcaseCatalog.scenarios/0` in Phase 73. Do not snapshot future placeholder sections such as Primitives, Forms, Data Display, Operator Groups, or Pages before their owning phases populate real stories. This avoids locking obsolete skeleton pixels and keeps Phase 74-83 reviews focused on real visual changes.
- **D-06:** Still assert the showcase shell structurally: route loads, one `.obpt-root` exists, theme choices exist, viewport choices exist, section anchors exist, and all catalog story targets render. These can be Playwright assertions or existing ExUnit assertions; they should not become broad placeholder screenshot baselines.
- **D-07:** Preserve the Phase 72 single-source-of-truth contract. The Node harness should consume or generate its target manifest from `test/support/showcase_catalog.ex` rather than duplicating the current story ID list in JavaScript. The planner can choose the cleanest mechanism, such as a small Mix/script step that emits JSON for Playwright.
- **D-08:** Snapshot matrix is themes `system`, `light`, `dark`, `high-contrast` crossed with real browser viewports `320`, tablet, and wide. Make `system` deterministic through Playwright media emulation so the same run has stable effective theme behavior.

### Determinism And Pixel Discipline
- **D-09:** Use Playwright screenshot comparison with committed baselines, not ad hoc image diffs. Baseline paths must be stable, human-readable, and grouped by story, theme, viewport, and browser/project so reviewers can understand what changed.
- **D-10:** Disable or neutralize volatility in the harness: animations disabled, caret hidden, fonts ready before capture, timezone/locale fixed, media preferences controlled, theme state set deterministically on `.obpt-root`, and viewport size set by the browser rather than only by the in-showcase viewport control.
- **D-11:** Use masks or screenshot style overrides only for genuinely volatile pixels. Do not broad-mask story content, status colors, focus/hover affordances, long identifiers, RTL/non-ASCII text, redaction displays, or severity signals. The point is to catch identity regressions, not hide them.
- **D-12:** Do not introduce Chromatic, Percy, or another SaaS baseline store. Their lesson is useful - required visual checks, reviewed baselines, stable rendering, and diff artifacts - but this repo's support-truth and OSS posture fit committed PNG baselines plus GitHub Actions artifacts.

### Axe Accessibility Gate
- **D-13:** Axe runs over the same stable catalog-backed story targets and any implemented open-state variants that exist in the showcase. Reserved metadata such as `confirm_action_open`, `tooltip_open`, and `drawer_open` should become scan targets when the actual open stories are implemented; metadata alone is not enough.
- **D-14:** Configure axe with WCAG A/AA tags including WCAG 2.2 AA coverage where supported by the installed axe-core version. The merge-blocking threshold for Phase 73 is 0 `critical` or `serious` violations.
- **D-15:** Publish the full axe output, including moderate/minor violations and incomplete results, as CI artifacts. Do not hide lower-severity findings; just do not make them merge-blocking until the planned Phase 82 accessibility/motion/copy hardening pass.
- **D-16:** Do not claim automated axe scans prove the full accessibility contract. Keyboard traversal, dialog focus trap/restore, Esc behavior, focus-not-obscured, screen-reader announcement quality, reduced-motion behavior, and 200% zoom/reflow require later manual or targeted tests. Phase 73 creates the automated gate and reporting channel.

### Baseline Update Workflow
- **D-17:** CI never updates snapshots. Snapshot updates are explicit local commands run in the pinned Playwright Docker environment, producing committed PNG changes.
- **D-18:** Add CI artifacts for failed visual runs: Playwright HTML/report output, actual/expected/diff images, and axe JSON/report files. Use short retention so artifacts help review without becoming a long-term baseline store.
- **D-19:** Any PR or commit that changes baselines must explain why. Prefer a separate baseline-update commit or a clearly named commit section when practical. A baseline change bundled silently with code is a process smell.
- **D-20:** Baseline update commands should default to the narrowest practical update mode, such as changed snapshots only, and should be documented in the contributor/guardrail docs. Avoid a casual "update everything" workflow that normalizes accidental churn.

### Claude's Discretion
- Exact file names, npm script names, Playwright project names, baseline directory shape, and JSON manifest generation mechanics are left to research/planning as long as the decisions above hold.
- The planner may split the work across multiple plans if needed: Node harness bootstrap, target-manifest/showcase server integration, VRT snapshots, axe gate, CI/artifacts/docs.
- If the first implementation finds that the full theme x viewport x story matrix is too slow for the existing CI budget, the planner should optimize through Playwright project organization, caching, and narrow capture targets before reducing coverage.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Requirements And Scope
- `.planning/ROADMAP.md` section "Phase 73: Visual-Regression & A11y Harness" - phase goal, dependency on Phase 72, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` section "Visual Regression (VRT)" - VRT-01..03 define Playwright snapshots, pinned Docker, committed baselines, reviewed updates, and deterministic harness behavior.
- `.planning/REQUIREMENTS.md` section "Accessibility (A11Y)" - A11Y-01 defines the automated axe gate; A11Y-02..04 clarify later keyboard/focus/reduced-motion/manual work.
- `.planning/REQUIREMENTS.md` section "Component Showcase (SHOW)" - SHOW-01..03 define the showcase as the canonical scan surface.
- `.planning/REQUIREMENTS.md` section "Stress Fixtures (FIX)" - FIX-01..03 define the deterministic story data the harness consumes.
- `.planning/PROJECT.md` section "Decision Posture" and "Current Milestone: v2.0 Powertools Identity" - research-first defaults, no new operator capability, library-owned isolated design system.

### Prior Locked Decisions
- `.planning/phases/70-brand-book-identity-foundation/70-CONTEXT.md` - brand decisions D-01..D-22, especially color-as-information, color-never-sole-signal, motion-safe behavior, focus/contrast, and calm/precise operator identity.
- `guides/brand-book.md` - newest brand-book source of truth; supersedes older prompt references for visual/verbal identity.
- `.planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md` - Phase 72 decisions D-01..D-14, especially stable scenario IDs, `data-obpt-*` selectors, open-state naming, deterministic fixture data, and showcase route scope.
- `.planning/phases/72-stress-fixtures-showcase-skeleton/72-03-SUMMARY.md` - canonical deterministic scenario catalog and target helpers.
- `.planning/phases/72-stress-fixtures-showcase-skeleton/72-04-SUMMARY.md` - dev-only showcase route, ThemeShell-hosted selectors, compiled CSS, and package proof.
- `.planning/phases/71-token-layer-isolated-theming-engine/71-04-SUMMARY.md` - `ThemeShell` live-session integration and `.obpt-root` shell pattern.
- `.planning/phases/71-token-layer-isolated-theming-engine/71-05-SUMMARY.md` - JobsLive proof seam and example-host isolation closure.

### Repo-Local Product Research And Prompts
- `prompts/oban_powertools_context.md` - Phoenix-first, host-owned, operator-grade, research-first, DX/SRE posture; use newer brand book for identity details where the prompt is older.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` - Ops Console route/domain language, host-owned UI strategy, and operator experience principles; use newer brand book for visual decisions.
- `prompts/oban-powertools-deep-research-original-prompt.md` - maintainer preference for subagent research, ecosystem lessons, DX, great CI/CD, and one-shot coherent recommendations.
- `.planning/research/operator_ux.md` - operator/SRE JTBD and "explain, then act" context.
- `.planning/research/domain_competitors.md` and `.planning/research/PITFALLS.md` - lessons from job/workflow UI failure modes that the showcase fixtures and guardrails are meant to keep visible.

### Existing Implementation Seams
- `test/support/showcase_catalog.ex` - canonical target source for scenario IDs, snapshot names, and a11y selectors.
- `test/oban_powertools/showcase_catalog_test.exs` - contract tests for catalog determinism and target naming.
- `lib/oban_powertools/web/dev/showcase_live.ex` - dev-only showcase route content and stable `data-obpt-*` story/control attributes.
- `test/oban_powertools/web/live/showcase_live_test.exs` - route, shell, controls, anchors, story metadata, and open-state metadata assertions.
- `lib/oban_powertools/web/router.ex` - native route tree, `ThemeShell` live session, `_showcase` route guard, and `_assets` route.
- `lib/oban_powertools/web/theme_shell.ex` - scoped asset/root shell with `.obpt-root`, `data-obpt-theme`, and `data-obpt-motion`.
- `lib/oban_powertools/web/assets.ex` and `test/oban_powertools/web/assets_test.exs` - md5 asset route and immutable asset serving pattern.
- `examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs` - example-host isolation proof pattern to extend for browser harness setup.
- `.github/workflows/ci.yml` - existing required CI fan-in pattern and `ci-gate` job.

### External Standards And Tool Docs
- `https://playwright.dev/docs/test-snapshots` - official Playwright visual comparison and snapshot update behavior.
- `https://playwright.dev/docs/ci` - official Playwright CI guidance.
- `https://playwright.dev/docs/docker` - official Playwright Docker image guidance; pin image to Playwright version.
- `https://playwright.dev/docs/accessibility-testing` - official Playwright + axe accessibility testing guidance and automation limitations.
- `https://www.deque.com/axe/core-documentation/api-documentation/` - axe-core API/result model.
- `https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md` - axe rule impacts and WCAG tags.
- `https://www.w3.org/TR/WCAG22/` and `https://www.w3.org/WAI/WCAG22/quickref/` - WCAG 2.2 source and quick reference.
- `https://docs.github.com/actions/using-workflows/storing-workflow-data-as-artifacts` - GitHub Actions artifact upload/retention behavior.
- `https://docs.github.com/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks` - required-check behavior and skipped-check footguns.
- `https://storybook.js.org/docs/writing-tests/visual-testing` - ecosystem precedent for required visual tests, baselines, and reviewed UI changes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.ShowcaseCatalog` already exposes deterministic scenario IDs, `snapshot_name/1`, and `a11y_target/1`. It is the correct target source for Playwright and axe.
- `ObanPowertools.Web.Dev.ShowcaseLive` already renders `data-obpt-story`, `data-obpt-domain`, `data-obpt-persona`, `data-obpt-state`, `data-obpt-theme-choice`, `data-obpt-viewport`, `data-obpt-section`, and reserved open-state metadata.
- `ObanPowertools.Web.ThemeShell` already supplies one `.obpt-root`, md5 CSS/JS assets, `data-obpt-theme="system"`, and `data-obpt-motion="safe"`.
- Existing ExUnit tests already cover structural showcase contracts. Phase 73 can layer browser-level VRT/a11y on top instead of re-testing all HTML contracts in Node.

### Established Patterns
- The repo uses a single required `ci-gate` fan-in inside `.github/workflows/ci.yml`; new blocking lanes should join it rather than creating branch-protection drift.
- Dev-only Powertools routes use `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)` and underscore routes under `/ops/jobs`.
- Runtime Powertools assets are packaged under `priv/static/oban_powertools`, while dev/test support artifacts such as `test/support/showcase_catalog.ex` stay out of the Hex tarball.
- Example-host proofs are preferred when the contract crosses host-owned routing/layout boundaries.

### Integration Points
- Root Node metadata (`package.json`, `package-lock.json`) should become the harness entrypoint for `vrt`, `vrt:update`, and `a11y` scripts.
- Playwright config should know how to start or target the example-host showcase route in a deterministic environment.
- CI should add Node/Playwright dependency setup, pinned Docker execution, artifact upload, and `ci-gate` dependency wiring.
- Any target manifest generated for Playwright should be derived from `test/support/showcase_catalog.ex`.

</code_context>

<specifics>
## Specific Ideas

- Treat Phase 73 like "test infrastructure with product taste": the point is not screenshots for their own sake, but enforcing the calm, precise, token-scoped identity before later UI work creates churn.
- Catalog-backed stories are the correct first baselines because they exercise the real operator/JTBD stress fixtures: empty, many, long IDs/modules/URLs, non-ASCII/RTL/emoji, high counts, mixed severity, permission-denied, stale/disconnected, and boundary pagination.
- UI/UX lens: the harness should protect the brand book's high-leverage checks - color as information, color never as sole signal, visible focus, no decorative accent misuse, calm density, long-content handling, and no weird hover/focus behavior as components arrive.
- DX lens: scripts should be obvious and boring: run the gate, update baselines, inspect artifacts. Avoid a bespoke command vocabulary that future contributors have to decode.
- SRE/DevOps lens: flaky visual checks are worse than no checks. Invest in pinned environment, controlled media, stable targets, and diff artifacts now so later phases trust the gate.

</specifics>

<deferred>
## Deferred Ideas

- Full primitive/form/data/group/page story baselines belong to their owning phases as real stories are implemented.
- Tightening axe to selected moderate rules or all violations belongs to Phase 82/84 after the component library and open-state stories exist.
- Manual keyboard traversal, dialog focus trap/restore, screen-reader announcement quality, reduced-motion verification, 200% zoom/reflow, and copy quality belong to Phase 82's accessibility/motion/copy hardening.
- Separate browser-workflow sharding can be reconsidered if the Phase 73 lane becomes materially too slow after optimization.

</deferred>

---

*Phase: 73-visual-regression-a11y-harness*
*Context gathered: 2026-06-19*
