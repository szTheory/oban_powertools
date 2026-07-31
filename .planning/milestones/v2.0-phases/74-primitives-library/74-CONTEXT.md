# Phase 74: Primitives Library - Context

**Gathered:** 2026-07-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 74 builds the token-driven primitive component foundation for the v2.0 Powertools Identity milestone. It converts the Phase 71 token/proof-seam classes into documented, stateless `Phoenix.Component` primitives and registers those primitives as real showcase stories covered by the Phase 73 visual-regression and axe accessibility harness.

This phase is the first reusable component layer, not a page migration and not a new operator capability. It should make future form, shell, data-display, meta-component, and page phases compose from a stable base instead of copying inline Tailwind or ad hoc `.obpt-*` class fragments.

In scope:

- Stateless `Phoenix.Component` primitives for the roadmap list: Button, Icon button, Link, Badge/Tag/StatusPill, Card/Surface, Divider, Spinner/Skeleton, Tooltip, Kbd, and Stat.
- Documented attrs/slots, sensible defaults, `:global` passthrough for caller-owned `id`, `phx-*`, `aria-*`, and `data-*` attributes, and closed token-backed variants.
- Token-only CSS additions under `.obpt-root`, with raw hex/px prohibited in primitive source outside the token layer.
- Primitive showcase stories rendered inside the dev-only `/ops/jobs/_showcase` surface and included in the existing Playwright VRT/a11y matrix.
- Targeted browser assertions for accessibility behavior that axe alone cannot prove, especially icon-button labels, tooltip open/dismiss behavior, focus-visible state, and named loading states.

Out of scope:

- Publishing a general host-facing Phoenix UI kit or promising primitive attrs as a broad external customization API.
- Page migration across the 9 LiveViews; that belongs to Phases 79-81.
- Forms, app shell/navigation, data tables, operator meta-components, confirm dialogs, drawers, popovers, and page patterns; those belong to later phases.
- Full cross-domain Oban/Powertools state taxonomy mapping; Phase 74 renders status/tone primitives, while Phase 77 owns `DATA-02`.
- New runtime component/storybook/headless UI dependencies, host Tailwind changes, host theme hooks, or production showcase exposure.

</domain>

<decisions>
## Implementation Decisions

### Component Support Boundary
- **D-01:** Ship a narrow Powertools-owned primitive layer as stateless `Phoenix.Component` function components, likely under `ObanPowertools.Web.Components.Primitives`. These components are for native Powertools pages and the dev showcase first, documented for contributors, and intentionally not positioned as a standalone host-facing UI kit.
- **D-02:** Prefer Phoenix function components with `attr/3`, `slot/3`, and `attr :rest, :global` over LiveComponents or stateful/headless primitives. Parent LiveViews continue to own state, events, authorization, and mutation flows.
- **D-03:** Keep primitive variants closed and token-backed. Do not expose arbitrary visual class/style escape hatches that let callers bypass the brand book, raw-value lint, or `.obpt-root` isolation. Allow caller-owned `id`, `phx-*`, `aria-*`, `data-*`, and necessary native attributes such as `form` where the primitive semantics require them.
- **D-04:** Existing `.obpt-button`, `.obpt-badge`, `.obpt-tab`, `.obpt-modal`, `.obpt-form-label`, `.obpt-input`, and `.obpt-alert` proof-seam classes from Phase 71 are implementation material to formalize or replace behind components. Do not leave Phase 74 as CSS classes only; that would preserve duplicated HEEx and weak a11y semantics.
- **D-05:** Do not introduce a third-party Storybook, Radix, Web Component, or React-style runtime dependency. Use successful design systems as pattern evidence, but keep the implementation Phoenix-native, library-owned, and zero-new-runtime-dependency.

### Primitive API And Semantics
- **D-06:** `Button` should be semantic `<button>` by default with explicit variants such as neutral, primary, warning, danger, and ghost/link-like only where needed by existing Powertools flows. Primary is for safe forward action; danger is reserved for destructive/irreversible/error actions; warning is available for reversible caution actions such as pause-like operations.
- **D-07:** `IconButton` requires an accessible `label` at compile-time/API level. Tooltip text may mirror or supplement the label, but tooltip visibility is never the only accessible name.
- **D-08:** `Link` should wrap Phoenix link/navigation affordances without making non-navigation elements look like links. Links navigate; buttons act. Do not use a link-styled element for a mutation.
- **D-09:** `Badge`, `Tag`, and `StatusPill` are non-interactive metadata/status primitives. If a future filter chip needs selection or dismissal, that belongs to form/filter components, not the static status primitive.
- **D-10:** `Card`/`Surface` should be restrained structural containers, not decorative nested cards. Provide only the surface roles the 9 pages actually use, such as plain/elevated/inset/attention, with tokenized border/background/radius/elevation.
- **D-11:** `Divider`, `Kbd`, `Stat`, `Spinner`, and `Skeleton` should encode the brand rules rather than just styles: mono only for literal machine values, tabular sans numerics for metrics, skeleton for progressive content loading, and spinner only for bounded action/section work with named context.
- **D-12:** `Tooltip` in Phase 74 is text-only, non-interactive, and descriptive. It appears on hover/focus, dismisses on `Escape`, leaves focus on the trigger, and uses `aria-describedby`/equivalent semantics. Rich hovercards, menus, popovers, drawers, and dialogs are later group/meta-component work.

### StatusPill Scope
- **D-13:** Ship a token-only, non-interactive `StatusPill` primitive with `tone`, visible label, optional icon, size, and accessible text hooks.
- **D-14:** Add a tiny render-spec shape that future callers can hand to the primitive, such as `%{label: "Retryable", tone: :warning, icon: :alert, sr_prefix: "Job state"}`, but do not create a domain registry in Phase 74.
- **D-15:** Explicitly defer the full cross-domain state mapping to Phase 77 (`DATA-02`). Phase 74 may include representative examples like job `retryable -> warning`, `executing -> info`, `completed -> success`, and `discarded -> danger`, but it must not decide all batch, workflow, cron, limiter, Lifeline, audit, and forensics status semantics.
- **D-16:** Status/tone primitives must carry information through text and, where useful, icon/shape as well as color. This preserves the brand-book rule that color is never the sole signal and keeps grayscale/colorblind interpretation viable.

### Showcase And Baselines
- **D-17:** Add a small dev/test-only primitive story registry instead of appending primitive stories to `ObanPowertools.ShowcaseCatalog.scenarios/0`. The existing catalog remains the domain/persona/JTBD stress-fixture source of truth; primitive stories get their own metadata such as `kind`, `component`, `variant`, `state`, `snapshot`, and `a11y`.
- **D-18:** Generate a unified Playwright manifest from both stress scenarios and primitive stories. Do not hardcode primitive target lists in TypeScript.
- **D-19:** Use story-level primitive cells as VRT/a11y targets across the existing themes (`system`, `light`, `dark`, `high-contrast`) and viewports (`320`, `tablet`, `wide`).
- **D-20:** Prefer one matrix story per primitive for static variants, with separate targeted stories for open or interaction-sensitive states. Example story IDs: `primitive-button-matrix`, `primitive-icon-button-accessible-names`, `primitive-status-pill-tones`, `primitive-surface-card-density`, `primitive-tooltip-open`, `primitive-spinner-skeleton-loading`, and `primitive-kbd-stat-values`.
- **D-21:** Do not snapshot placeholders, broad section galleries, or future components before their owning phases provide real stories. Do not broad-mask meaningful pixels such as tone colors, focus rings, long labels, icons, redaction indicators, or dense metric values.
- **D-22:** Baseline updates stay explicit and reviewed through the existing Phase 73 workflow. Primitive stories should be grep-friendly and stable so contributors can update one component's baselines without normalizing unrelated churn.

### Strict Accessibility Contracts
- **D-23:** Encode accessibility in the primitive API, not only in docs. Examples: icon buttons require labels; spinner/skeleton require named loading context; tooltip requires trigger/description IDs; disabled-with-reason controls stay perceivable; and focus-visible styling uses tokenized focus treatment.
- **D-24:** Use semantic HTML first. Add ARIA only when native semantics are insufficient; no custom role should replace a native button/link/status element without a concrete reason.
- **D-25:** For disabled actions that need an explanatory reason, prefer `aria-disabled="true"` plus action suppression when the reason must remain focusable/reachable. Native `disabled` is acceptable when no explanation is needed and the control can leave the tab order.
- **D-26:** Loading primitives must avoid bare spinners. Use `role="status"` or equivalent live status where appropriate, pair visible or screen-reader text with the loading state, and use `aria-busy` on regions when content is being refreshed.
- **D-27:** Add targeted Playwright checks beyond axe for primitive behavior: icon-button accessible names, keyboard focus visibility, tooltip focus/hover/Escape behavior, no horizontal overflow at 320px, and reduced-motion-safe loading/transition behavior.
- **D-28:** Do not claim Phase 74 proves the full accessibility contract. Manual screen-reader announcement quality, complete keyboard traversal across pages, dialog focus trap/restore, 200% zoom/reflow, and final copy/motion audit remain Phase 82 work.

### Claude's Discretion
- Exact module/file names, CSS class names, attrs, variant atom names, story registry module name, and manifest schema details are left to research/planning, provided the decisions above hold.
- The planner may split the work into multiple plans, but the sequence should keep the API and test contract coherent: component module/API, token CSS refinements, primitive stories/manifest, VRT/a11y baselines, docs/static guards.
- If an existing proof-seam class already satisfies a primitive style, the implementation may reuse it behind the component rather than churn CSS names for no behavioral gain.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Requirements And Scope
- `.planning/ROADMAP.md` section "Phase 74: Primitives Library" — phase goal, dependencies, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` section "Primitives (COMP)" — COMP-01..04 define the primitive list, docs/attrs/slots, token-only source, keyboard/SR correctness, theme rendering, 320px behavior, and showcase stories.
- `.planning/REQUIREMENTS.md` section "Accessibility (A11Y)" — A11Y-02/A11Y-04 define keyboard, focus, color, dialog, reduced-motion, and manual-review boundaries.
- `.planning/REQUIREMENTS.md` section "Motion (MOTION)" — MOTION-02 requires purposeful, interruptible, reduced-motion-safe transitions.
- `.planning/REQUIREMENTS.md` section "Component Showcase (SHOW)" — SHOW-01 requires primitive stories in the dev-only showcase.
- `.planning/PROJECT.md` sections "Decision Posture" and "Current Milestone: v2.0 Powertools Identity" — research-first defaults, no new operator capability, library-owned isolated design system.

### Prior Locked Decisions
- `.planning/phases/70-brand-book-identity-foundation/70-CONTEXT.md` — brand decisions D-01..D-22, especially calm/precise identity, color-as-information, color-never-sole-signal, monospace-as-signal, no orphan styles, and explain-then-act copy/affordance rules.
- `guides/brand-book.md` — newest brand-book source of truth; supersedes older prompt references for visual/verbal identity.
- `.planning/phases/71-token-layer-isolated-theming-engine/71-02-SUMMARY.md` — token CSS, primitive/semantic `--obpt-*` roles, proof-seam classes, and no raw component values.
- `.planning/phases/71-token-layer-isolated-theming-engine/71-05-SUMMARY.md` — JobsLive proof seam using token-backed state tabs, badges, modal, form, alert, and button classes.
- `.planning/phases/71-token-layer-isolated-theming-engine/71-VERIFICATION.md` — verified Phase 71 token/proof-seam behavior and relevant source locations.
- `.planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md` — showcase route, stable sections/selectors, stress catalog boundary, theme/viewport controls, and open-state naming.
- `.planning/phases/73-visual-regression-a11y-harness/73-CONTEXT.md` — Playwright/axe harness, baseline update workflow, artifact policy, and limits of automated accessibility proof.
- `guides/visual-regression-and-a11y.md` — contributor-facing VRT/a11y commands, baseline update process, snapshot naming, and guardrail scope.

### Repo-Local Product Research And Prompts
- `prompts/oban_powertools_context.md` — project personas/JTBD, research-first decision posture, dashboard UX principles, domain vocabulary, and day-2 operator requirements.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — Ops Console route/domain language, native shell vs bridge strategy, dangerous-action vocabulary, and operator UX priorities.
- `prompts/oban-powertools-deep-research-original-prompt.md` — maintainer preference for subagent research, ecosystem lessons, DX/SRE/devops lenses, and one-shot coherent recommendations.
- `.planning/research/operator_ux.md` — operator/SRE dashboard strategy, explainability, dry-run repair, telemetry/evidence boundaries.
- `.planning/research/domain_competitors.md` — cross-ecosystem job UI and workflow footguns; use as background for why status/explainability must be explicit.
- `.planning/research/PITFALLS.md` — UX pitfalls around unclear batch/workflow state, silent callback failure, bulk action scope, and explicit operator recovery.

### Existing Implementation Seams
- `lib/oban_powertools/web/dev/showcase_live.ex` — dev-only showcase route, stable section anchors, current token controls, placeholder primitive section, catalog story rendering, and open-state metadata.
- `test/support/showcase_catalog.ex` — current stress-fixture catalog; do not pollute it with primitive-only stories.
- `test/oban_powertools/web/live/showcase_live_test.exs` — route/shell/selector contract for showcase sections and story metadata.
- `test/browser/support/manifest.ts` — current Playwright manifest schema and assumptions that will need extension for primitive stories.
- `test/browser/support/showcase.ts` — theme/viewport preparation and structure assertions for showcase targets.
- `test/browser/specs/showcase.vrt.spec.ts` — story-level screenshot pattern to extend to primitive stories.
- `test/browser/specs/showcase.a11y.spec.ts` — axe scan pattern to extend to primitive stories and open states.
- `assets/oban_powertools/tokens.css` — current `.obpt-root` token source and proof-seam classes for buttons, badges, tabs, modal, forms, alerts, and showcase.
- `priv/static/oban_powertools/oban_powertools.css` — compiled package asset that must remain in sync with token CSS.
- `lib/oban_powertools/web/theme_shell.ex` — `.obpt-root`, `data-obpt-theme`, `data-obpt-effective-theme`, and asset shell boundary.
- `lib/oban_powertools/web/router.ex` — dev-only `_showcase` route guard and native LiveView session.
- `test/oban_powertools/web/theme_tokens_test.exs` — static token/theme contract and no-host-leakage checks to extend for primitive no-raw-value policy if useful.
- `lib/oban_powertools/web/jobs_live.ex` — current proof seam using `.obpt-badge`, `.obpt-tab`, `.obpt-button`, and `.obpt-modal`; useful migration target/examples but not full page migration scope.
- `lib/oban_powertools/web/batches_live.ex`, `lib/oban_powertools/web/lifeline_live.ex`, `lib/oban_powertools/web/cron_live.ex`, and `lib/oban_powertools/web/control_plane_presenter.ex` — examples of scattered status/tone mappings that Phase 77 should unify after Phase 74 provides primitives.

### External Standards And Tool Docs
- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` — official Phoenix function component attrs, slots, global attributes, and compile-time validation model.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html` — use only when state/event encapsulation is actually needed; Phase 74 should prefer function components.
- `https://playwright.dev/docs/test-snapshots` — official Playwright screenshot comparison, snapshot naming, and update behavior.
- `https://playwright.dev/docs/accessibility-testing` — official Playwright accessibility testing guidance and axe integration limits.
- `https://storybook.js.org/docs` and `https://storybook.js.org/docs/writing-tests/visual-testing` — story-as-rendered-state model and visual baseline/review lessons; use as inspiration, not dependency.
- `https://www.w3.org/WAI/ARIA/apg/patterns/button/` — button accessible-name, disabled, toggle, and focus guidance.
- `https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/` — text-only tooltip focus/hover/Escape behavior and ARIA relationship.
- `https://www.w3.org/TR/WCAG22/` and `https://www.w3.org/WAI/WCAG22/quickref/` — WCAG 2.2 source/quick reference for contrast, focus, target size, color, motion, and reflow.
- `https://design-system.service.gov.uk/components/tag/` — status tags are non-interactive, descriptive, and useful only when status matters.
- `https://primer.style/product/components/label/` — labels as contextual metadata/status with constrained variants.
- `https://carbondesignsystem.com/components/tag/usage/` — tag types, read-only vs interactive distinctions, and visual differentiation guidance.
- `https://carbondesignsystem.com/components/loading/usage/` — loading vs skeleton usage and overuse warnings.
- `https://carbondesignsystem.com/components/tooltip/accessibility/` — tooltip keyboard/focus/Escape guidance and icon-button annotation expectations.
- `https://www.patternfly.org/components/label/design-guidelines/` and `https://www.patternfly.org/patterns/status-and-severity/` — enterprise-console lessons for labels, status, severity, and component documentation.
- `https://m3.material.io/components/badges` and `https://material-web.dev/components/chip/` — useful counterexample: badges/chips can imply notification/selection behavior, so Powertools static status primitives must not look interactive.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `assets/oban_powertools/tokens.css` already defines the token layer and proof-seam CSS for `.obpt-button`, `.obpt-badge`, `.obpt-tab`, `.obpt-modal`, `.obpt-form-label`, `.obpt-input`, and `.obpt-alert`. Phase 74 should formalize these behind components where they match the desired API.
- `ObanPowertools.Web.ThemeShell` already supplies the `.obpt-root` theme boundary, asset links, and motion/theme attributes for every native page and the showcase.
- `ObanPowertools.Web.Dev.ShowcaseLive` already has stable section anchors including `primitives`, theme/viewport controls, and reserved open-state metadata. It is the right human/browser inspection surface.
- The Phase 73 browser harness already runs story-level screenshots and axe scans against showcase targets across 4 themes x 3 viewports.
- `JobsLive` has the narrowest current design-system proof seam and can serve as an example of how primitives should preserve behavior while replacing direct class strings later.

### Established Patterns
- Dev-only Powertools routes are underscore routes under `/ops/jobs`, guarded by `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)`, and absent from prod/package output.
- The repo favors host-owned Phoenix integration with library-owned scoped CSS/JS served through the Powertools asset Plug; no host Tailwind dependency and no global `<html>` theme mutation.
- Existing CI uses a single `ci-gate` fan-in; the Phase 73 `visual_a11y` lane is already part of that blocking posture.
- Documentation and tests prefer explicit support-truth boundaries. Components may be documented for internal/contributor use without becoming a broad external support promise.

### Integration Points
- Add a component module under `lib/oban_powertools/web/` and import/alias it where the showcase needs to render primitive stories.
- Add a dev/test-only primitive story source next to the showcase/catalog support code, not inside the stress fixture catalog.
- Extend `scripts/showcase_manifest.exs` and `test/browser/support/manifest.ts` so the manifest can represent both stress scenarios and primitive stories without duplicating target IDs in TypeScript.
- Extend token/static tests or add primitive-specific static tests to reject raw hex values, raw pixel literals where token values exist, host selectors, and arbitrary class/style variant leakage in primitive source.
- Add browser tests for open/focus/loading states that axe and static tests cannot validate.

</code_context>

<specifics>
## Specific Ideas

- Treat Phase 74 as "boring primitives with unusually strong contracts." The win is not novelty; it is making every later UI phase faster, safer, and harder to make inconsistent.
- Story examples should reflect real operator console pressures rather than decorative samples: long labels, destructive actions, disabled-with-reason controls, status tones, dense metrics, code/key labels, and loading states that name what is loading.
- Prefer story IDs that are stable, grep-friendly, and reviewable: `primitive-button-matrix`, `primitive-icon-button-accessible-names`, `primitive-status-pill-tones`, `primitive-tooltip-open`, `primitive-spinner-skeleton-loading`, `primitive-surface-card-density`, and `primitive-kbd-stat-values`.
- Keep microcopy plain and consequence-aware even in primitive stories. Example labels should say what the operator does or sees, such as "Retry job", "Cancel job", "Blocked", "Loading job history", or "Requires operator role".
- The user explicitly asked for research-backed, one-shot recommendations. The four decision areas were researched by parallel subagents plus local source review; no remaining public-product fork requires user escalation.

</specifics>

<deferred>
## Deferred Ideas

- Full domain status taxonomy and one `StatusPill` mapping every Oban/Powertools state belongs to Phase 77 (`DATA-02`).
- Interactive filter chips, removable tags, combobox tags, and form-control variants belong to Phase 75/form and Phase 77/data-display work.
- ConfirmActionDialog, danger forms, drawers, rich popovers, "Why blocked?" explainer, and operator group patterns belong to Phase 78.
- Page migration of the 9 LiveViews belongs to Phases 79-81.
- Full manual screen-reader pass, dialog focus-trap/restore, copy audit, motion hardening, and 200% zoom/reflow pass belong to Phase 82.
- A broad host-facing Powertools UI kit can be reconsidered only after internal page migrations prove which primitive APIs are stable enough to support publicly.

</deferred>

---

*Phase: 74-primitives-library*
*Context gathered: 2026-07-10*
