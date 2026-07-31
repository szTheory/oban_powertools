# Phase 72: Stress Fixtures & Showcase Skeleton - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 72 stands up the deterministic guardrail surface for the v2.0 design-system milestone: a dev/test-only named scenario catalog plus the dev-only `/ops/jobs/_showcase` shell that future visual-regression, accessibility, and audit phases will target.

This phase is infrastructure for repeatable UI quality. It does **not** build the primitive/form/data/group component library, migrate operator pages, add Playwright visual baselines, add axe CI, or change operator behavior. It creates the stable fixture/story/control substrate those later phases consume.

In scope:

- A seedable deterministic scenario catalog for normal and adversarial operator states across the existing `/ops/jobs` domains.
- A dev-only `/ops/jobs/_showcase` route, mounted inside the existing native Powertools LiveView session and `ThemeShell`.
- Initial showcase content for tokens/theming plus the stable skeleton, anchors, story IDs, and data attributes future phases fill in.
- Theme and viewport controls that are stable enough for humans, ExUnit, Playwright VRT, and axe scans to target.
- Example-host proof that the showcase works from `examples/phoenix_host` with no host changes and is absent from prod/package output.

Out of scope:

- Full component stories for primitives/forms/data/groups/pages; those belong to Phases 74-83.
- The external Node Playwright VRT and axe harness; that belongs to Phase 73.
- New operator capabilities or behavior changes to the 9 existing LiveViews.

</domain>

<decisions>
## Implementation Decisions

### Fixture Catalog Shape
- **D-01:** Use a **domain-first catalog** with persona/JTBD metadata, not a persona-first tree or flat story list. Top-level domains should mirror the operator surfaces: overview, jobs, batches, workflows, cron, limiters, lifeline, audit, and forensics. Each scenario carries stable metadata such as `id`, `domain`, `name`, `persona`, `jtbd`, `states`, `fixtures`, and test targets.
- **D-02:** Scenario IDs are public test contract strings for later phases. They must be stable, slug-like, and shared by showcase cells, ExUnit assertions, VRT snapshot names, and a11y scan targets. Do not use display copy as selectors; use explicit attributes such as `data-obpt-story`, `data-obpt-domain`, `data-obpt-persona`, `data-obpt-state`, and stable element IDs.
- **D-03:** Coverage must include both normal and adversarial states from FIX-01: empty/one/many, long IDs/module names/URLs, non-ASCII/emoji/RTL, high counts, mixed severity, permission-denied, stale/disconnected, and boundary pagination. Also include per-persona JTBD scenarios for triage, incident response, repair, and audit review.
- **D-04:** Fixtures are plain structs/maps by default, never DB inserts for screenshot-facing data. DB-backed setup can exist only as an explicit helper for tests that truly need persistence. Anything visible in screenshots must be constant: no Faker, wall-clock timestamps, random IDs, or environment-derived strings.
- **D-05:** The catalog is the single source of truth. The requirement names `test/support/showcase_catalog.ex`; downstream planning should preserve that as the canonical catalog path or provide a thin dev-route adapter that reads the same data without duplication. The catalog and any adapter must remain dev/test-only and excluded from the hex tarball.

### Showcase Skeleton
- **D-06:** Mirror the Phase 70 brand-book dev-route pattern: route and modules are guarded by `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)`, compiled in dev/test, and absent from prod.
- **D-07:** Mount `/ops/jobs/_showcase` inside the existing `:oban_powertools_native` live session so it receives `ObanPowertools.Web.ThemeShell`, md5 CSS/JS assets, `.obpt-root`, and `LiveAuth` consistently with native pages. Do not touch host root layouts or host Tailwind config.
- **D-08:** Build the showcase as a **full future skeleton now**, but populate only Phase 72-appropriate stories. Sections should reserve stable anchors for Tokens, Primitives, Forms, Data Display, Operator Groups, Pages, and Stress Fixtures. Tokens/theming and fixture index/examples are populated now; future sections may render explicit placeholder/empty states until their owning phases fill them.
- **D-09:** Open-state naming conventions should be reserved now even if most open overlay stories arrive later. Use stable names like `confirm_action_open`, `tooltip_open`, or `drawer_open` when those stories land so Phase 73/82 a11y scans can target open variants without renaming.
- **D-10:** The showcase is an operator-quality inspection surface, not a marketing page. It should feel like the product shell: calm, dense, neutral, and token-driven. No decorative gradients, hero treatment, or standalone brand flourish.

### Controls And Guardrails
- **D-11:** Theme controls must manipulate the existing Powertools theme boundary on `.obpt-root[data-obpt-theme]` and use the Phase 71 theme controller/storage contract. They must never set host `<html>.dark`, `localStorage.theme`, or any host-owned theme state.
- **D-12:** The viewport toggle should provide stable story-canvas widths for 320, tablet, and wide inspection, exposed through explicit state such as `data-obpt-viewport`. Phase 73 Playwright should still capture real browser viewport sizes; the in-showcase viewport control exists for human inspection and stable story targeting.
- **D-13:** The showcase must be deterministic by construction: fixed fixture data, no ambient animation dependency, stable IDs, no timestamps that drift, no layout shift on theme switch, and no host CSS dependency. This sets up Playwright screenshot comparison and axe scans without implementing those harnesses yet.
- **D-14:** Production/package exclusion is a first-class acceptance criterion. Keep the example-host proof pattern from Phase 71: host `/` stays free of `.obpt-root` and Powertools assets, while `/ops/jobs/_showcase` renders only in dev/test. Hex package tests must continue to include required runtime `priv/static/oban_powertools` assets while excluding test/support/showcase artifacts and planning files.

### Claude's Discretion
- Exact module names, internal function names, HEEx layout, and copy are left to research/planning as long as the decisions above hold.
- The planner may choose the cleanest dev/test compilation mechanism for the shared catalog, but it must not duplicate fixture data or leak dev/test artifacts into production or the hex package.
- The initial visual layout of the showcase is flexible within the brand-book constraints: calm, precise, token-only, and built for scanning.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Requirements And Scope
- `.planning/ROADMAP.md` §"Phase 72: Stress Fixtures & Showcase Skeleton" — phase goal, dependency on Phase 71, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` §"Stress Fixtures (FIX)" — FIX-01..03 define catalog coverage, deterministic data, shared source-of-truth use, persona JTBD coverage, and tarball exclusion.
- `.planning/REQUIREMENTS.md` §"Component Showcase (SHOW)" — SHOW-01..03 define the dev-only route, theme/viewport switchers, stable scan surface, host independence, and prod exclusion.
- `.planning/REQUIREMENTS.md` §"Visual Regression (VRT)" and §"Accessibility (A11Y)" — Phase 72 must prepare stable targets for Phase 73 VRT/a11y without implementing the harness early.
- `.planning/PROJECT.md` §"Decision Posture" and §"Current Milestone: v2.0 Powertools Identity" — one-shot, repo-grounded defaults; no new operator capability; library-owned isolated design system.

### Prior Locked Decisions
- `.planning/phases/70-brand-book-identity-foundation/70-CONTEXT.md` — brand decisions D-01..D-22, especially calm/precise identity, color-as-information, no decorative accent fills, system-font/no-orphan-style posture, and traceability requirement.
- `guides/brand-book.md` — authored brand book that downstream showcase and fixture work must reflect.
- `.planning/phases/71-token-layer-isolated-theming-engine/71-02-SUMMARY.md` — token CSS, root-scoped vanilla theme controller, deterministic build task, and namespaced theme storage.
- `.planning/phases/71-token-layer-isolated-theming-engine/71-03-SUMMARY.md` — md5 immutable asset Plug/routes and package inclusion pattern.
- `.planning/phases/71-token-layer-isolated-theming-engine/71-04-SUMMARY.md` — `ThemeShell` live-session integration and `.obpt-root` shell pattern.
- `.planning/phases/71-token-layer-isolated-theming-engine/71-05-SUMMARY.md` — JobsLive proof seam and example-host isolation closure.

### Existing Implementation Seams
- `lib/oban_powertools/web/router.ex` — existing native route tree, asset route, `live_session`, and dev-only brand-book route guard that the showcase should mirror.
- `lib/oban_powertools/web/theme_shell.ex` — shared native LiveView layout with md5 asset links, `.obpt-root`, `data-obpt-theme`, and `data-obpt-effective-theme`.
- `lib/oban_powertools/web/assets.ex` — md5 CSS/JS path helpers and immutable asset serving.
- `lib/oban_powertools/web/dev/brand_book_live.ex` — dev-only module guard and compile-time doc rendering pattern.
- `test/oban_powertools/web/live/brand_book_live_test.exs` — dev/test route guard test pattern.
- `test/oban_powertools/web/theme_tokens_test.exs` — token/theme static contract pattern.
- `test/oban_powertools/web/assets_test.exs` — asset path/cache/package contract pattern.
- `examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs` — example-host isolation proof to extend for `/ops/jobs/_showcase`.
- `.planning/codebase/STRUCTURE.md` and `.planning/codebase/ARCHITECTURE.md` — route/UI/core-domain map for where new dev-only web code connects.

### External Standards And Tool Docs
- `https://playwright.dev/docs/test-snapshots` — official Playwright screenshot comparison behavior that Phase 73 will build on; Phase 72 should provide deterministic story targets.
- `https://playwright.dev/docs/accessibility-testing` — official Playwright + axe accessibility testing guidance; Phase 72 should prepare scan targets and open-state naming.
- `https://www.w3.org/TR/WCAG22/` and `https://www.w3.org/WAI/WCAG22/quickref/` — WCAG 2.2 source and quick reference for future a11y gates.
- `https://hexdocs.pm/elixir/Application.html` — `Application.compile_env/3` official docs; relevant to dev/prod route compilation boundaries.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Web.ThemeShell` already owns the Powertools CSS/JS asset tags and exactly one `.obpt-root`. The showcase should run inside this shell rather than inventing a parallel wrapper.
- `ObanPowertools.Web.Assets.path/1` already exposes md5 CSS/JS URLs served under `/ops/jobs/_assets/...`; the showcase should rely on those assets, not host static configuration.
- `ObanPowertools.Web.Router.oban_powertools_routes/1` already contains the native LiveView list and the dev-only brand-book route guard. Add `_showcase` beside `_brand_book`.
- `ObanPowertools.Web.Dev.BrandBookLive` demonstrates the correct production-exclusion posture: module body and route are both guarded by `Application.compile_env`.
- The Phase 71 example-host isolation test proves how to check both "host root unaffected" and "Powertools route owns scoped assets/classes."

### Established Patterns
- Dev-only Powertools routes are internal underscore routes under `/ops/jobs`, compiled only when `:dev_routes` is true.
- Theme state is scoped to `.obpt-root` and `data-obpt-*` attributes; host theme state is never touched.
- Package tests should prove runtime assets are included while development/test/planning artifacts stay out of the hex tarball.
- Design-system proof seams should be narrow and forward-compatible: stable classes/data attributes now, broader component migration later.

### Integration Points
- Add a dev-only LiveView under `lib/oban_powertools/web/dev/` for the showcase shell.
- Add a guarded `live("/_showcase", ...)` route next to `_brand_book` in `lib/oban_powertools/web/router.ex`.
- Add or expose the canonical scenario catalog at `test/support/showcase_catalog.ex` without duplicating data for the dev route.
- Extend example-host tests to prove `/ops/jobs/_showcase` renders in dev/test and remains absent from prod/package surfaces.

</code_context>

<specifics>
## Specific Ideas

- Treat this as the "idempotency guardrail substrate" phase: stable fixture names, story IDs, and scan targets matter more than visual richness right now.
- Use explicit empty/placeholder states in future showcase sections instead of leaving them absent; absence makes downstream phases invent anchors later.
- The showcase should make fixture coverage inspectable by humans, not only hidden in tests. A fixture index/table with domain, persona, JTBD, and adversarial tags is useful and within scope.
- Keep all visible fixture data calm and realistic for an operations console: long IDs/module names, stack traces, redaction overlays, stale/disconnected states, and permission-denied affordances are more valuable than synthetic decorative samples.

</specifics>

<deferred>
## Deferred Ideas

- Full primitive/form/data/group/page story implementation belongs to Phases 74-83.
- Playwright VRT project setup, baseline PNG commits, Docker pinning, snapshot update flow, and axe CI belong to Phase 73.
- Page migration, behavior preservation, and final cross-page consistency checks belong to Phases 79-82.
- Any comfortable/compact density preference remains deferred outside this foundation work.

</deferred>

---

*Phase: 72-stress-fixtures-showcase-skeleton*
*Context gathered: 2026-06-18*
