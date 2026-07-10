# Phase 74: Primitives Library - Research

**Researched:** 2026-07-10
**Domain:** Phoenix.LiveView function components, scoped token CSS, custom showcase stories, Playwright VRT, axe accessibility
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

All content in this section is copied from `.planning/phases/74-primitives-library/74-CONTEXT.md`. [VERIFIED: codebase]

### Locked Decisions

#### Component Support Boundary
- **D-01:** Ship a narrow Powertools-owned primitive layer as stateless `Phoenix.Component` function components, likely under `ObanPowertools.Web.Components.Primitives`. These components are for native Powertools pages and the dev showcase first, documented for contributors, and intentionally not positioned as a standalone host-facing UI kit.
- **D-02:** Prefer Phoenix function components with `attr/3`, `slot/3`, and `attr :rest, :global` over LiveComponents or stateful/headless primitives. Parent LiveViews continue to own state, events, authorization, and mutation flows.
- **D-03:** Keep primitive variants closed and token-backed. Do not expose arbitrary visual class/style escape hatches that let callers bypass the brand book, raw-value lint, or `.obpt-root` isolation. Allow caller-owned `id`, `phx-*`, `aria-*`, `data-*`, and necessary native attributes such as `form` where the primitive semantics require them.
- **D-04:** Existing `.obpt-button`, `.obpt-badge`, `.obpt-tab`, `.obpt-modal`, `.obpt-form-label`, `.obpt-input`, and `.obpt-alert` proof-seam classes from Phase 71 are implementation material to formalize or replace behind components. Do not leave Phase 74 as CSS classes only; that would preserve duplicated HEEx and weak a11y semantics.
- **D-05:** Do not introduce a third-party Storybook, Radix, Web Component, or React-style runtime dependency. Use successful design systems as pattern evidence, but keep the implementation Phoenix-native, library-owned, and zero-new-runtime-dependency.

#### Primitive API And Semantics
- **D-06:** `Button` should be semantic `<button>` by default with explicit variants such as neutral, primary, warning, danger, and ghost/link-like only where needed by existing Powertools flows. Primary is for safe forward action; danger is reserved for destructive/irreversible/error actions; warning is available for reversible caution actions such as pause-like operations.
- **D-07:** `IconButton` requires an accessible `label` at compile-time/API level. Tooltip text may mirror or supplement the label, but tooltip visibility is never the only accessible name.
- **D-08:** `Link` should wrap Phoenix link/navigation affordances without making non-navigation elements look like links. Links navigate; buttons act. Do not use a link-styled element for a mutation.
- **D-09:** `Badge`, `Tag`, and `StatusPill` are non-interactive metadata/status primitives. If a future filter chip needs selection or dismissal, that belongs to form/filter components, not the static status primitive.
- **D-10:** `Card`/`Surface` should be restrained structural containers, not decorative nested cards. Provide only the surface roles the 9 pages actually use, such as plain/elevated/inset/attention, with tokenized border/background/radius/elevation.
- **D-11:** `Divider`, `Kbd`, `Stat`, `Spinner`, and `Skeleton` should encode the brand rules rather than just styles: mono only for literal machine values, tabular sans numerics for metrics, skeleton for progressive content loading, and spinner only for bounded action/section work with named context.
- **D-12:** `Tooltip` in Phase 74 is text-only, non-interactive, and descriptive. It appears on hover/focus, dismisses on `Escape`, leaves focus on the trigger, and uses `aria-describedby`/equivalent semantics. Rich hovercards, menus, popovers, drawers, and dialogs are later group/meta-component work.

#### StatusPill Scope
- **D-13:** Ship a token-only, non-interactive `StatusPill` primitive with `tone`, visible label, optional icon, size, and accessible text hooks.
- **D-14:** Add a tiny render-spec shape that future callers can hand to the primitive, such as `%{label: "Retryable", tone: :warning, icon: :alert, sr_prefix: "Job state"}`, but do not create a domain registry in Phase 74.
- **D-15:** Explicitly defer the full cross-domain state mapping to Phase 77 (`DATA-02`). Phase 74 may include representative examples like job `retryable -> warning`, `executing -> info`, `completed -> success`, and `discarded -> danger`, but it must not decide all batch, workflow, cron, limiter, Lifeline, audit, and forensics status semantics.
- **D-16:** Status/tone primitives must carry information through text and, where useful, icon/shape as well as color. This preserves the brand-book rule that color is never the sole signal and keeps grayscale/colorblind interpretation viable.

#### Showcase And Baselines
- **D-17:** Add a small dev/test-only primitive story registry instead of appending primitive stories to `ObanPowertools.ShowcaseCatalog.scenarios/0`. The existing catalog remains the domain/persona/JTBD stress-fixture source of truth; primitive stories get their own metadata such as `kind`, `component`, `variant`, `state`, `snapshot`, and `a11y`.
- **D-18:** Generate a unified Playwright manifest from both stress scenarios and primitive stories. Do not hardcode primitive target lists in TypeScript.
- **D-19:** Use story-level primitive cells as VRT/a11y targets across the existing themes (`system`, `light`, `dark`, `high-contrast`) and viewports (`320`, `tablet`, `wide`).
- **D-20:** Prefer one matrix story per primitive for static variants, with separate targeted stories for open or interaction-sensitive states. Example story IDs: `primitive-button-matrix`, `primitive-icon-button-accessible-names`, `primitive-status-pill-tones`, `primitive-surface-card-density`, `primitive-tooltip-open`, `primitive-spinner-skeleton-loading`, and `primitive-kbd-stat-values`.
- **D-21:** Do not snapshot placeholders, broad section galleries, or future components before their owning phases provide real stories. Do not broad-mask meaningful pixels such as tone colors, focus rings, long labels, icons, redaction indicators, or dense metric values.
- **D-22:** Baseline updates stay explicit and reviewed through the existing Phase 73 workflow. Primitive stories should be grep-friendly and stable so contributors can update one component's baselines without normalizing unrelated churn.

#### Strict Accessibility Contracts
- **D-23:** Encode accessibility in the primitive API, not only in docs. Examples: icon buttons require labels; spinner/skeleton require named loading context; tooltip requires trigger/description IDs; disabled-with-reason controls stay perceivable; and focus-visible styling uses tokenized focus treatment.
- **D-24:** Use semantic HTML first. Add ARIA only when native semantics are insufficient; no custom role should replace a native button/link/status element without a concrete reason.
- **D-25:** For disabled actions that need an explanatory reason, prefer `aria-disabled="true"` plus action suppression when the reason must remain focusable/reachable. Native `disabled` is acceptable when no explanation is needed and the control can leave the tab order.
- **D-26:** Loading primitives must avoid bare spinners. Use `role="status"` or equivalent live status where appropriate, pair visible or screen-reader text with the loading state, and use `aria-busy` on regions when content is being refreshed.
- **D-27:** Add targeted Playwright checks beyond axe for primitive behavior: icon-button accessible names, keyboard focus visibility, tooltip focus/hover/Escape behavior, no horizontal overflow at 320px, and reduced-motion-safe loading/transition behavior.
- **D-28:** Do not claim Phase 74 proves the full accessibility contract. Manual screen-reader announcement quality, complete keyboard traversal across pages, dialog focus trap/restore, 200% zoom/reflow, and final copy/motion audit remain Phase 82 work.

### the agent's Discretion

- Exact module/file names, CSS class names, attrs, variant atom names, story registry module name, and manifest schema details are left to research/planning, provided the decisions above hold.
- The planner may split the work into multiple plans, but the sequence should keep the API and test contract coherent: component module/API, token CSS refinements, primitive stories/manifest, VRT/a11y baselines, docs/static guards.
- If an existing proof-seam class already satisfies a primitive style, the implementation may reuse it behind the component rather than churn CSS names for no behavioral gain.

### Deferred Ideas (OUT OF SCOPE)

- Full domain status taxonomy and one `StatusPill` mapping every Oban/Powertools state belongs to Phase 77 (`DATA-02`).
- Interactive filter chips, removable tags, combobox tags, and form-control variants belong to Phase 75/form and Phase 77/data-display work.
- ConfirmActionDialog, danger forms, drawers, rich popovers, "Why blocked?" explainer, and operator group patterns belong to Phase 78.
- Page migration of the 9 LiveViews belongs to Phases 79-81.
- Full manual screen-reader pass, dialog focus-trap/restore, copy audit, motion hardening, and 200% zoom/reflow pass belong to Phase 82.
- A broad host-facing Powertools UI kit can be reconsidered only after internal page migrations prove which primitive APIs are stable enough to support publicly.
</user_constraints>

## Summary

Phase 74 should be planned as a foundation/API phase, not a page migration phase: build stateless Phoenix function components, put all visual values behind `.obpt-root` token CSS, register separate primitive stories, and extend the existing Playwright/axe manifest so primitive story cells join the same theme x viewport gate as Phase 73 catalog stories. [VERIFIED: `.planning/phases/74-primitives-library/74-CONTEXT.md`][VERIFIED: `assets/oban_powertools/tokens.css`][VERIFIED: `test/browser/support/manifest.ts`]

The main implementation risk is not component rendering; it is accidentally opening escape hatches that undermine the token system. Phoenix `:global` attributes accept standard globals and default `phx-`, `aria-`, and `data-` prefixes, so the plan must explicitly filter or reject caller-supplied `class` and `style` while still passing `id`, `phx-*`, `aria-*`, `data-*`, and narrowly needed native attributes such as `form`. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html][VERIFIED: `deps/phoenix_live_view/lib/phoenix_component.ex`]

The a11y plan should pair semantic HTML and compile-time component attrs with browser checks that axe cannot prove: accessible names for icon buttons, `aria-disabled` suppression, tooltip hover/focus/Escape behavior, visible focus, no horizontal overflow at 320px, and reduced-motion-safe loading/transition behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/button/][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/][CITED: https://playwright.dev/docs/accessibility-testing]

**Primary recommendation:** Implement `ObanPowertools.Web.Components.Primitives` plus a dev/test-only `ObanPowertools.PrimitiveStoryCatalog`, extend the manifest to unified VRT/a11y targets, add static no-raw/no-escape guards, and keep all new code dependency-free. [VERIFIED: `.planning/phases/74-primitives-library/74-CONTEXT.md`][VERIFIED: `package.json`]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMP-01 | Primitive library exists as documented `Phoenix.Component` function components. | Use `attr/3`, `slot/3`, and function components; LiveComponents are inappropriate for generic DOM primitives. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html][CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html] |
| COMP-02 | Primitives have documented attrs/slots, defaults, and token-only rendering. | Phoenix docs support required/default attrs and required slots; Phase 71 token layer is the only visual source. [VERIFIED: `deps/phoenix_live_view/lib/phoenix_component.ex`][VERIFIED: `assets/oban_powertools/tokens.css`] |
| COMP-03 | Primitives are keyboard-operable and screen-reader-correct. | APG button and tooltip patterns define keyboard and accessible-name behavior; Playwright must test behavior beyond axe. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/button/][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/] |
| COMP-04 | Primitives render across themes and 320px with showcase stories per state. | Existing manifest has themes `system`, `light`, `dark`, `high-contrast` and viewports `320`, `tablet`, `wide`; Phase 74 should add primitive targets to that matrix. [VERIFIED: `test/browser/support/manifest.ts`][VERIFIED: `playwright.config.ts`] |
| MOTION-02 | Transitions are purposeful, interruptible, and reduced-motion-safe. | Motion tokens already centralize duration/easing and `prefers-reduced-motion`; primitives should use those tokens only. [VERIFIED: `assets/oban_powertools/tokens.css`][CITED: https://www.w3.org/WAI/WCAG22/quickref/] |
| A11Y-02 | Interactive elements are keyboard-reachable/operable with visible focus; color is not sole signal. | Brand book and WCAG require visible focus and non-color status channels; targeted Playwright checks are needed. [VERIFIED: `guides/brand-book.md`][CITED: https://www.w3.org/WAI/WCAG22/quickref/] |
| SHOW-01 | Dev-only showcase renders primitive stories. | Showcase route already reserves `primitives`; separate primitive registry should populate it without polluting `ShowcaseCatalog.scenarios/0`. [VERIFIED: `lib/oban_powertools/web/dev/showcase_live.ex`][VERIFIED: `test/support/showcase_catalog.ex`] |
</phase_requirements>

## Project Constraints (from AGENTS.md/CLAUDE.md)

No `AGENTS.md`, `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/skills`, `.agents/skills`, or `.codex/skills` exists in this project root, so there are no additional project-local agent directives to copy into the plan. [VERIFIED: codebase search]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Primitive component APIs | Frontend Server (LiveView render tier) | Browser / Client | `Phoenix.Component` renders HEEx on the server; browser behavior is limited to native semantics and minimal tooltip Escape handling. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/] |
| Token styling and themes | CDN / Static asset tier | Frontend Server | CSS lives in `assets/oban_powertools/tokens.css`, compiles to `priv/static`, and is served by the asset plug under `.obpt-root`. [VERIFIED: `assets/oban_powertools/tokens.css`][VERIFIED: `.planning/phases/71-token-layer-isolated-theming-engine/71-VERIFICATION.md`] |
| Primitive story data | Frontend Server (dev/test support) | Browser / Client | Story metadata should be generated from Elixir support modules, then consumed by Playwright TypeScript. [VERIFIED: `scripts/showcase_manifest.exs`][VERIFIED: `test/browser/support/manifest.ts`] |
| VRT and axe execution | Browser / Client test tier | CI / Docker | Playwright runs Chromium projects against the example-host showcase route and writes screenshots/axe artifacts. [VERIFIED: `playwright.config.ts`][VERIFIED: `guides/visual-regression-and-a11y.md`] |
| Accessibility contracts | Frontend Server API | Browser / Client tests | Required attrs encode labels/descriptions; browser tests prove focus, keyboard, tooltip, and 320px behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/button/][CITED: https://playwright.dev/docs/accessibility-testing] |

## Standard Stack

### Core

| Library / System | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Build and test runtime. | Project `mix.exs` requires Elixir `~> 1.19`; local toolchain matches. [VERIFIED: `mix.exs`][VERIFIED: local command `elixir --version`] |
| Phoenix | 1.8.7 locked | Host routing and LiveView shell dependencies. | Locked in `mix.lock`; no Phase 74 upgrade needed. [VERIFIED: `mix.lock`][VERIFIED: `mix hex.info phoenix`] |
| Phoenix LiveView / `Phoenix.Component` | 1.1.31 locked | Function component attrs, slots, HEEx rendering, `<.link>`. | Local locked docs support the required stateless component API. [VERIFIED: `mix.lock`][VERIFIED: `deps/phoenix_live_view/lib/phoenix_component.ex`] |
| Scoped `.obpt-root` CSS tokens | Phase 71 source | Primitive styling, themes, focus, motion. | Existing token contract is verified and must remain the sole primitive visual source. [VERIFIED: `assets/oban_powertools/tokens.css`][VERIFIED: `.planning/phases/71-token-layer-isolated-theming-engine/71-VERIFICATION.md`] |
| Playwright Test | 1.61.0 locked | Browser structure, VRT, targeted interaction tests. | Existing Phase 73 harness is already wired to Docker and committed baselines. [VERIFIED: `package.json`][CITED: https://playwright.dev/docs/test-snapshots] |
| `@axe-core/playwright` / `axe-core` | 4.11.3 / 4.11.4 locked | Automated accessibility scans. | Existing Phase 73 gate already imports `AxeBuilder` and blocks critical/serious violations. [VERIFIED: `package.json`][VERIFIED: `test/browser/support/axe.ts`][CITED: https://playwright.dev/docs/accessibility-testing] |

### Supporting

| Library / System | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `lazy_html` | 0.1.11 locked | HTML assertions in ExUnit. | Use for primitive render contract tests if regex is too brittle. [VERIFIED: `mix.lock`] |
| `Jason` | 1.4.5 locked | Manifest JSON encoding. | Continue using it in `scripts/showcase_manifest.exs`. [VERIFIED: `mix.lock`][VERIFIED: `scripts/showcase_manifest.exs`] |
| PostgreSQL | 14.17 local | Example-host database for browser showcase server. | Required by `scripts/with-showcase-server.sh` because it runs example-host `ecto.create` and `ecto.migrate`. [VERIFIED: `examples/phoenix_host/config/dev.exs`][VERIFIED: local command `pg_isready`] |
| Docker | 29.5.2 local | Pinned Playwright image execution. | Required for `npm run visual:a11y` and `npm run vrt:update`. [VERIFIED: local command `docker info`][VERIFIED: `guides/visual-regression-and-a11y.md`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Phoenix function components | LiveComponents | LiveComponents are for state plus event encapsulation and should not be used for generic DOM primitives. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html] |
| Custom dev showcase | Storybook / PhoenixStorybook | Context explicitly rejects third-party storybook/runtime dependencies; existing route already exists. [VERIFIED: `.planning/phases/74-primitives-library/74-CONTEXT.md`][VERIFIED: `lib/oban_powertools/web/dev/showcase_live.ex`] |
| Existing Playwright/axe harness | New visual or a11y service | Phase 73 already established committed baselines, Docker execution, and axe artifacts; adding another service would duplicate the gate. [VERIFIED: `.planning/phases/73-visual-regression-a11y-harness/73-CONTEXT.md`][VERIFIED: `guides/visual-regression-and-a11y.md`] |

**Installation:**

```bash
# No new packages should be installed in Phase 74. [VERIFIED: 74-CONTEXT.md]
mix deps.get
npm ci
```

**Version verification:**

- `mix.lock` currently locks `phoenix_live_view` 1.1.31, `phoenix` 1.8.7, `jason` 1.4.5, and `lazy_html` 0.1.11. [VERIFIED: `mix.lock`]
- `package.json` currently pins `@playwright/test` 1.61.0, `@axe-core/playwright` 4.11.3, and `axe-core` 4.11.4. [VERIFIED: `package.json`]
- npm registry latest versions on 2026-07-10 are newer for all three browser packages; do not upgrade them inside this phase because Phase 73 baselines and Docker image are pinned to 1.61.0. [VERIFIED: npm registry][VERIFIED: `guides/visual-regression-and-a11y.md`]

## Package Legitimacy Audit

Phase 74 should install no new external packages. [VERIFIED: `.planning/phases/74-primitives-library/74-CONTEXT.md`]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@playwright/test` 1.61.0 | npm | Published 2026-06-15 | Existing devDependency | `github.com/microsoft/playwright` | SUS for latest package check due "too-new"; existing lock is already in repo | Keep existing lock; do not install/upgrade in Phase 74. [VERIFIED: npm registry][VERIFIED: `package.json`] |
| `@axe-core/playwright` 4.11.3 | npm | Published 2026-04-30 | Existing devDependency | `github.com/dequelabs/axe-core-npm` | SUS for latest package check due "too-new"; existing lock is already in repo | Keep existing lock; do not install/upgrade in Phase 74. [VERIFIED: npm registry][VERIFIED: `package.json`] |
| `axe-core` 4.11.4 | npm | Published 2026-04-29 | Existing devDependency | `github.com/dequelabs/axe-core` | OK | Keep existing lock; do not install/upgrade in Phase 74. [VERIFIED: npm registry][VERIFIED: `package.json`] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy seam]
**Packages flagged as suspicious [SUS]:** `@playwright/test`, `@axe-core/playwright` latest package checks; no install task should be planned, and any upgrade must be a separate human-verified dependency-upgrade task. [VERIFIED: package-legitimacy seam]

## Architecture Patterns

### System Architecture Diagram

```text
Contributor writes primitive attrs/slots
  -> Phoenix.Component render contract
    -> closed variant helpers choose .obpt-* classes and data attrs
      -> token CSS under .obpt-root supplies visual values
        -> ShowcaseLive renders primitive story cells
          -> showcase_manifest.exs emits scenarios + primitive stories
            -> Playwright manifest validates unified targets
              -> VRT screenshots + axe scans + targeted interaction specs
                -> CI visual_a11y lane / local gate
```

### Recommended Project Structure

```text
lib/oban_powertools/web/components/
  primitives.ex                 # Public contributor-facing primitive components. [VERIFIED: 74-CONTEXT.md]
test/support/
  primitive_story_catalog.ex    # Dev/test-only primitive story source. [VERIFIED: 74-CONTEXT.md]
test/oban_powertools/web/components/
  primitives_test.exs           # Render/API/static source contract tests. [VERIFIED: existing test layout]
test/browser/specs/
  primitives.behavior.spec.ts   # Focus/name/tooltip/overflow/reduced-motion checks. [VERIFIED: Phase 73 harness]
assets/oban_powertools/
  tokens.css                    # Add primitive CSS only through tokens. [VERIFIED: Phase 71 source]
  theme.js or primitives.js     # Minimal delegated tooltip Escape handling, no dependency. [VERIFIED: no new deps decision]
scripts/
  showcase_manifest.exs         # Emit schema with catalog and primitive targets. [VERIFIED: existing script]
```

### Pattern 1: Closed Function Component Variants

**What:** Use `attr/3` with `:values` for closed atoms/strings, `slot/3` for content, and a filtered rest map for caller-owned non-visual attributes. [VERIFIED: `deps/phoenix_live_view/lib/phoenix_component.ex`]

**When to use:** Every primitive that has visual variants or required a11y labels. [VERIFIED: 74-CONTEXT.md]

**Example:**

```elixir
# Source: deps/phoenix_live_view/lib/phoenix_component.ex and Phoenix.Component docs.
defmodule ObanPowertools.Web.Components.Primitives do
  use Phoenix.Component

  @button_variants ~w(neutral primary warning danger ghost)a

  attr :variant, :atom, default: :neutral, values: @button_variants
  attr :type, :string, default: "button", values: ~w(button submit reset)
  attr :disabled, :boolean, default: false
  attr :disabled_reason, :string, default: nil
  attr :rest, :global, include: ~w(form name value)
  slot :inner_block, required: true

  def button(assigns) do
    assigns =
      assigns
      |> assign(:class, ["obpt-button", "obpt-button--#{assigns.variant}"])
      |> assign(:rest, visual_safe_rest(assigns.rest))

    ~H"""
    <button
      type={@type}
      class={@class}
      disabled={@disabled && is_nil(@disabled_reason)}
      aria-disabled={if @disabled_reason, do: "true"}
      aria-describedby={@disabled_reason && "#{@rest[:id]}-reason"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    <span :if={@disabled_reason} id={"#{@rest[:id]}-reason"} class="obpt-sr-only">
      {@disabled_reason}
    </span>
    """
  end

  defp visual_safe_rest(rest) do
    Map.drop(rest, [:class, "class", :style, "style"])
  end
end
```

### Pattern 2: Primitive Story Catalog Separate From Stress Fixtures

**What:** Add a primitive registry with explicit metadata and target helpers instead of adding primitive stories to `ObanPowertools.ShowcaseCatalog.scenarios/0`. [VERIFIED: 74-CONTEXT.md]

**When to use:** All primitive showcase cells and open/interaction states. [VERIFIED: 74-CONTEXT.md]

**Example:**

```elixir
# Source: test/support/showcase_catalog.ex pattern, adapted for primitive metadata.
defmodule ObanPowertools.PrimitiveStoryCatalog do
  @stories [
    %{
      id: "primitive-button-matrix",
      kind: :primitive,
      component: :button,
      variant: :matrix,
      state: :default,
      snapshot: "showcase/primitives/button-matrix",
      a11y: ~s([data-obpt-primitive-story="primitive-button-matrix"])
    }
  ]

  def stories, do: @stories
  def snapshot_name(id), do: story!(id).snapshot
  def a11y_target(id), do: story!(id).a11y
  def story!(id), do: Enum.find(@stories, &(&1.id == id)) || raise KeyError, key: id
end
```

### Pattern 3: Unified Manifest With Typed Targets

**What:** Preserve `scenarios` for compatibility, add `primitive_stories`, and expose a `targets` list for VRT/a11y loops. [VERIFIED: `test/browser/support/manifest.ts`][VERIFIED: 74-CONTEXT.md]

**When to use:** The first plan that adds primitive stories should update manifest generation and TypeScript validation before screenshot baselines. [VERIFIED: `scripts/showcase_manifest.exs`]

**Example:**

```typescript
// Source: test/browser/support/manifest.ts, extended schema recommendation.
export type ShowcaseTarget = {
  kind: 'scenario' | 'primitive';
  id: string;
  story: string;
  snapshot: string;
  a11y: string;
};

export const targets: ShowcaseTarget[] = [
  ...manifest.scenarios.map((scenario) => ({ kind: 'scenario' as const, ...scenario })),
  ...manifest.primitive_stories.map((story) => ({ kind: 'primitive' as const, ...story }))
];
```

### Pattern 4: Tooltip Requires a Tiny Browser Behavior Seam

**What:** CSS can show hover/focus, but Escape dismissal requires client-side behavior or a browser-native mechanism; use a dependency-free delegated listener in the existing Powertools asset boundary. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/][VERIFIED: `assets/oban_powertools/theme.js`]

**When to use:** `Tooltip` open story and targeted browser test. [VERIFIED: 74-CONTEXT.md]

**Example:**

```javascript
// Source: WAI APG tooltip requirements; implement in scoped Powertools asset.
document.addEventListener('keydown', (event) => {
  if (event.key !== 'Escape') return;

  const trigger = document.activeElement?.closest?.('[data-obpt-tooltip-trigger]');
  if (!trigger) return;

  trigger.setAttribute('data-obpt-tooltip-dismissed', 'true');
});

document.addEventListener('focusin', (event) => {
  event.target?.closest?.('[data-obpt-tooltip-trigger]')
    ?.removeAttribute('data-obpt-tooltip-dismissed');
});
```

### Anti-Patterns to Avoid

- **Passing caller `class` or `style` through primitives:** This bypasses token-only styling and invalidates raw-value guards. [VERIFIED: 74-CONTEXT.md][CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]
- **Using LiveComponents for primitives:** Phoenix docs say LiveComponents are for event/state encapsulation, not generic DOM components. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html]
- **Appending primitives to `ShowcaseCatalog.scenarios/0`:** The phase context reserves that catalog for domain/persona/JTBD stress fixtures. [VERIFIED: 74-CONTEXT.md]
- **Relying on axe alone:** Playwright docs say automated accessibility tests catch common issues but not all issues. [CITED: https://playwright.dev/docs/accessibility-testing]
- **Making status tags interactive:** GOV.UK and Carbon explicitly distinguish status/read-only tags from interactive chip variants. [CITED: https://design-system.service.gov.uk/components/tag/][CITED: https://carbondesignsystem.com/components/tag/usage/]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Phoenix navigation behavior | Custom link routing or JS navigation | Delegate to Phoenix `<.link>` for `href`, `patch`, and `navigate`. | LiveView already validates and emits the right link attributes. [VERIFIED: `deps/phoenix_live_view/lib/phoenix_component.ex`] |
| Stateful primitive layer | Custom component lifecycle | Stateless `Phoenix.Component` functions. | LiveComponents are for state and event encapsulation, not DOM primitives. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html] |
| Visual diffing | Custom screenshot comparator | Existing Playwright `toHaveScreenshot` harness. | Playwright already provides screenshot comparison and snapshot update flow. [CITED: https://playwright.dev/docs/test-snapshots][VERIFIED: `test/browser/specs/showcase.vrt.spec.ts`] |
| Accessibility scanning | Custom axe runner | Existing `@axe-core/playwright` helper. | Current helper already sets WCAG tags and blocks serious/critical violations. [VERIFIED: `test/browser/support/axe.ts`] |
| Status taxonomy | Full Oban/Powertools state registry | Tiny render spec only; defer taxonomy to Phase 77. | Phase context explicitly defers full mapping to `DATA-02`. [VERIFIED: 74-CONTEXT.md] |
| Dialog/focus trap patterns | Homemade focus trap in primitives | Defer to Phase 78/82; later use Phoenix `focus_wrap` where applicable. | Dialogs are out of scope for Phase 74. [VERIFIED: 74-CONTEXT.md][CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] |

**Key insight:** The hard parts are API boundaries and regression gates, not drawing the components. The plan should spend early tasks on attrs/rest filtering, static raw-value guards, story target generation, and browser behavior checks. [VERIFIED: codebase review][CITED: https://playwright.dev/docs/accessibility-testing]

## Common Pitfalls

### Pitfall 1: `:global` Rest Becomes a Style Escape Hatch

**What goes wrong:** `class` or `style` from callers leaks through primitives. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]
**Why it happens:** Phoenix `:global` accepts standard HTML globals in addition to `phx-`, `aria-`, and `data-`. [VERIFIED: `deps/phoenix_live_view/lib/phoenix_component.ex`]
**How to avoid:** Filter `class` and `style` before rendering and add an ExUnit render test that caller `class`/`style` do not appear. [VERIFIED: 74-CONTEXT.md]
**Warning signs:** Primitive tests only grep source and do not render with hostile `class`/`style` attrs. [VERIFIED: codebase testing pattern]

### Pitfall 2: Icon Buttons Depend on Tooltip Text for Names

**What goes wrong:** Screen readers see an unlabeled button when tooltip text is hidden or not associated. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/button/]
**Why it happens:** Tooltip visibility is not an accessible-name contract. [VERIFIED: 74-CONTEXT.md]
**How to avoid:** Require `label` on `icon_button/1`, render `aria-label`, and test `toHaveAccessibleName`. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/button/][VERIFIED: 74-CONTEXT.md]
**Warning signs:** `IconButton` has only an icon slot and optional tooltip. [VERIFIED: 74-CONTEXT.md]

### Pitfall 3: Tooltip Is Only CSS

**What goes wrong:** Hover/focus works, but Escape dismissal cannot be tested or satisfied. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/]
**Why it happens:** CSS cannot persist an Escape-dismissed state on the trigger. [ASSUMED]
**How to avoid:** Add a tiny root-scoped delegated JS behavior in the existing asset boundary and verify focus remains on the trigger. [VERIFIED: `assets/oban_powertools/theme.js`][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/]
**Warning signs:** Tooltip open story has no keyboard test. [VERIFIED: 74-CONTEXT.md]

### Pitfall 4: Manifest Update Hardcodes Primitive IDs in TypeScript

**What goes wrong:** Elixir showcase and Playwright target lists drift. [VERIFIED: `scripts/showcase_manifest.exs`][VERIFIED: `test/browser/support/manifest.ts`]
**Why it happens:** Current schema validates exactly nine scenarios and has no primitive target shape. [VERIFIED: `test/browser/support/manifest.ts`]
**How to avoid:** Generate primitive story metadata from Elixir and validate a unified typed target list. [VERIFIED: 74-CONTEXT.md]
**Warning signs:** New primitive tests import a hand-written array in `test/browser/specs/*.ts`. [VERIFIED: Phase 73 pattern]

### Pitfall 5: Raw Value Guards Only Check CSS

**What goes wrong:** Raw hex/px values enter HEEx source, helper modules, or compiled primitive classes. [VERIFIED: `.planning/REQUIREMENTS.md`]
**Why it happens:** Existing `theme_tokens_test.exs` focuses on token/theme source, not primitive modules. [VERIFIED: `test/oban_powertools/web/theme_tokens_test.exs`]
**How to avoid:** Add primitive-specific source scans for `lib/oban_powertools/web/components/primitives.ex` and any primitive CSS block, with allowlists for token-layer-only raw values. [VERIFIED: `.planning/REQUIREMENTS.md`]
**Warning signs:** Passing `mix test test/oban_powertools/web/theme_tokens_test.exs` is treated as enough. [VERIFIED: current test scope]

### Pitfall 6: Loading Primitives Render Bare Motion

**What goes wrong:** Spinners communicate "something is happening" without naming what is loading. [VERIFIED: 74-CONTEXT.md]
**Why it happens:** Loading indicators are visually easy to add and often overused. [CITED: https://carbondesignsystem.com/components/loading/usage/]
**How to avoid:** Require `label`/`context`, use `role="status"` or SR text where appropriate, and prefer skeleton for progressive content. [VERIFIED: 74-CONTEXT.md][CITED: https://carbondesignsystem.com/components/loading/usage/]
**Warning signs:** Story text says only "Loading..." or renders multiple spinners in one cell. [CITED: https://carbondesignsystem.com/components/loading/usage/]

## Code Examples

Verified patterns from official and local sources:

### Icon Button Contract

```elixir
# Source: WAI APG button pattern + Phoenix.Component attr docs.
attr :label, :string, required: true
attr :variant, :atom, default: :neutral, values: ~w(neutral primary warning danger ghost)a
attr :rest, :global
slot :inner_block, required: true

def icon_button(assigns) do
  assigns =
    assigns
    |> assign(:class, ["obpt-icon-button", "obpt-icon-button--#{assigns.variant}"])
    |> assign(:rest, visual_safe_rest(assigns.rest))

  ~H"""
  <button type="button" class={@class} aria-label={@label} {@rest}>
    <span aria-hidden="true">{render_slot(@inner_block)}</span>
  </button>
  """
end
```

### Status Pill Render Spec

```elixir
# Source: Phase 74 D-14 decision.
def status_pill(%{spec: spec} = assigns) when is_map(spec) do
  assigns =
    assigns
    |> assign(:label, Map.fetch!(spec, :label))
    |> assign(:tone, Map.get(spec, :tone, :neutral))
    |> assign(:icon, Map.get(spec, :icon))
    |> assign(:sr_prefix, Map.get(spec, :sr_prefix))

  status_pill(assigns)
end
```

### Playwright Behavior Checks

```typescript
// Source: existing Playwright harness plus Phase 74 D-27.
test('primitive tooltip opens on focus and dismisses on Escape', async ({ page }, testInfo) => {
  const viewportName = viewportNameFromProject(testInfo.project.name);
  await prepareShowcase(page, { theme: 'light', viewportName });

  const trigger = page.getByRole('button', { name: 'Retry job' });
  await trigger.focus();
  await expect(page.getByRole('tooltip')).toBeVisible();

  await page.keyboard.press('Escape');
  await expect(page.getByRole('tooltip')).toBeHidden();
  await expect(trigger).toBeFocused();
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CSS classes only in LiveView markup | Documented Phoenix function components with attrs/slots | Phase 74 target | Prevents duplicate HEEx and makes a11y contracts compile/test-visible. [VERIFIED: 74-CONTEXT.md][CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] |
| LiveComponents for reuse | Function components unless state and events are encapsulated | Phoenix LiveView docs | Keeps primitive APIs simple and avoids generic DOM LiveComponents. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html] |
| Placeholder showcase sections | Real story cells only when phase owns them | Phase 73/74 decisions | Avoids snapshotting meaningless placeholders. [VERIFIED: `.planning/phases/73-visual-regression-a11y-harness/73-CONTEXT.md`][VERIFIED: 74-CONTEXT.md] |
| Page-wide or hardcoded VRT lists | Generated manifest from Elixir story sources | Phase 73 established | Keeps browser targets in sync with source story metadata. [VERIFIED: `scripts/showcase_manifest.exs`][VERIFIED: `test/browser/support/manifest.ts`] |

**Deprecated/outdated:**

- Storybook/PhoenixStorybook as a dependency is out of scope for this repo's current design-system milestone. [VERIFIED: `.planning/REQUIREMENTS.md`][VERIFIED: 74-CONTEXT.md]
- Arbitrary Tailwind/hex/px component source is forbidden outside the token layer. [VERIFIED: `.planning/REQUIREMENTS.md`][VERIFIED: `guides/brand-book.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CSS alone cannot persist an Escape-dismissed tooltip state; a tiny browser behavior seam is recommended. [ASSUMED] | Common Pitfalls / Pattern 4 | If wrong, a CSS/native-only implementation could avoid JS, but must still pass the Escape behavior test. |

## Open Questions

1. **Exact icon source**
   - What we know: No new icon package is allowed, and `StatusPill` may accept an optional icon. [VERIFIED: 74-CONTEXT.md]
   - What's unclear: Whether the first primitive pass should ship a tiny internal icon set, use text/shape glyphs, or accept icon slot content only. [VERIFIED: codebase review]
   - Recommendation: Use slots or a tiny closed internal atom-to-markup helper with decorative `aria-hidden` icons; do not install an icon dependency. [VERIFIED: 74-CONTEXT.md]

2. **Manifest compatibility shape**
   - What we know: Current TypeScript validator requires schema v1 and exactly nine `scenarios`. [VERIFIED: `test/browser/support/manifest.ts`]
   - What's unclear: Whether to bump to schema v2 immediately or retain schema v1 plus optional `primitive_stories`. [VERIFIED: codebase review]
   - Recommendation: Bump to schema v2, keep `scenarios` intact for compatibility, add `primitive_stories`, and make tests loop over a generated `targets` export. [VERIFIED: 74-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Component implementation and ExUnit | yes | 1.19.5 | None needed. [VERIFIED: local command] |
| Mix | Build/test commands | yes | 1.19.5 | None needed. [VERIFIED: local command] |
| Node.js | Playwright harness | yes | 22.14.0 | None needed. [VERIFIED: local command] |
| npm | Browser dependency install/scripts | yes | 11.1.0 | None needed. [VERIFIED: local command] |
| Docker | Pinned Playwright Docker run | yes | 29.5.2 | Local host Playwright exists, but baselines should use Docker. [VERIFIED: local command][VERIFIED: `guides/visual-regression-and-a11y.md`] |
| PostgreSQL | Example host database | yes | 14.17 client; server accepting connections | No fallback in current script. [VERIFIED: local command][VERIFIED: `examples/phoenix_host/config/dev.exs`] |
| Playwright CLI | Browser specs | yes | 1.61.0 | `npm ci` restores if missing. [VERIFIED: local command][VERIFIED: `package.json`] |

**Missing dependencies with no fallback:** none found. [VERIFIED: local command checks]

**Missing dependencies with fallback:** none found. [VERIFIED: local command checks]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5; Playwright Test 1.61.0; axe-core 4.11.4. [VERIFIED: local command][VERIFIED: `package.json`] |
| Config file | `mix.exs`, `playwright.config.ts`, `test/browser/support/axe.ts`. [VERIFIED: codebase] |
| Quick run command | `mix test test/oban_powertools/web/components/primitives_test.exs test/oban_powertools/web/live/showcase_live_test.exs` [VERIFIED: existing test layout] |
| Full suite command | `npm run visual:a11y && mix test --exclude host_contract` [VERIFIED: `package.json`][VERIFIED: Phase 71 verification command pattern] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| COMP-01 | Components exist with documented attrs/slots. | unit/static | `mix test test/oban_powertools/web/components/primitives_test.exs -x` | No - Wave 0. [VERIFIED: codebase] |
| COMP-02 | No raw hex/px or class/style escape hatches in primitive source/render output. | unit/static | `mix test test/oban_powertools/web/components/primitives_test.exs -x` | No - Wave 0. [VERIFIED: codebase] |
| COMP-03 | Keyboard and SR behavior for buttons, icon buttons, links, tooltips, loading. | browser | `npm run visual:a11y:host -- test/browser/specs/primitives.behavior.spec.ts` | No - Wave 0. [VERIFIED: codebase] |
| COMP-04 | Theme/viewport rendering for primitive stories. | browser VRT/axe | `npm run visual:a11y` | Existing harness yes; primitive targets no - Wave 0. [VERIFIED: `test/browser/specs/showcase.vrt.spec.ts`] |
| MOTION-02 | Reduced-motion-safe primitive transitions/loading. | browser/static | `npm run visual:a11y:host -- test/browser/specs/primitives.behavior.spec.ts` | No - Wave 0. [VERIFIED: codebase] |
| A11Y-02 | Focus-visible, accessible names, non-color channels. | browser/axe | `npm run visual:a11y` | Existing axe harness yes; primitive behavior file no - Wave 0. [VERIFIED: `test/browser/support/axe.ts`] |
| SHOW-01 | Primitive stories render at `/ops/jobs/_showcase`. | ExUnit/browser | `mix test test/oban_powertools/web/live/showcase_live_test.exs -x` | Existing file yes; primitive assertions no - Wave 0. [VERIFIED: `test/oban_powertools/web/live/showcase_live_test.exs`] |

### Sampling Rate

- **Per task commit:** `mix test test/oban_powertools/web/components/primitives_test.exs test/oban_powertools/web/live/showcase_live_test.exs` [VERIFIED: existing ExUnit workflow]
- **Per wave merge:** `npm run visual:a11y` [VERIFIED: `package.json`]
- **Phase gate:** `npm run visual:a11y && mix test --exclude host_contract && mix compile --warnings-as-errors` [VERIFIED: Phase 71/73 verification pattern]

### Wave 0 Gaps

- [ ] `test/oban_powertools/web/components/primitives_test.exs` - render/API/no-raw/no-escape contracts for COMP-01..03. [VERIFIED: codebase]
- [ ] `test/support/primitive_story_catalog.ex` - primitive story metadata and helper contracts for SHOW-01/COMP-04. [VERIFIED: codebase]
- [ ] `test/oban_powertools/primitive_story_catalog_test.exs` - deterministic IDs/snapshots/a11y selectors. [VERIFIED: codebase]
- [ ] `test/browser/specs/primitives.behavior.spec.ts` - focus/name/tooltip/overflow/reduced-motion checks. [VERIFIED: codebase]
- [ ] Manifest schema tests in `test/browser/support/manifest.ts` - unified target validation. [VERIFIED: existing schema v1]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Parent LiveViews keep auth; primitives do not authenticate. [VERIFIED: 74-CONTEXT.md] |
| V3 Session Management | no | No session behavior is added in this phase. [VERIFIED: 74-CONTEXT.md] |
| V4 Access Control | yes, indirectly | Disabled/reason affordances may expose unavailable actions, but authorization and mutation suppression remain parent-owned. [VERIFIED: 74-CONTEXT.md] |
| V5 Input Validation | yes | Closed `attr :values`, required labels, filtered rest attrs, no caller `class`/`style`. [VERIFIED: `deps/phoenix_live_view/lib/phoenix_component/declarative.ex`][VERIFIED: 74-CONTEXT.md] |
| V6 Cryptography | no | No cryptography is introduced. [VERIFIED: phase scope] |

### Known Threat Patterns for Phoenix Component Primitives

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Visual policy bypass through `class`/`style` rest attrs | Tampering | Drop visual globals and test hostile render cases. [VERIFIED: 74-CONTEXT.md][CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] |
| Mutation disguised as navigation | Spoofing / Tampering | `Link` wraps navigation only; actions use buttons and parent-owned events. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/button/][VERIFIED: 74-CONTEXT.md] |
| Unlabeled icon control | Information disclosure / usability failure | Require `label`; test accessible name. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/button/][VERIFIED: 74-CONTEXT.md] |
| XSS through arbitrary HTML attrs or story content | Tampering | Prefer text attrs/slots rendered through HEEx escaping; avoid raw `html` attrs in primitive APIs. [VERIFIED: `deps/phoenix_live_view/lib/phoenix_component.ex`][CITED: https://design-system.service.gov.uk/components/tag/] |
| Disabled controls still firing events | Tampering | Native `disabled` when no explanation is needed; `aria-disabled` with explicit event suppression when reason must stay focusable. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/button/][VERIFIED: 74-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/74-primitives-library/74-CONTEXT.md` - locked phase decisions, scope, and deferred boundaries. [VERIFIED: codebase]
- `.planning/REQUIREMENTS.md` - COMP, MOTION, A11Y, SHOW requirements. [VERIFIED: codebase]
- `deps/phoenix_live_view/lib/phoenix_component.ex` and `deps/phoenix_live_view/lib/phoenix_live_component.ex` - local locked Phoenix LiveView 1.1.31 docs/source. [VERIFIED: codebase]
- `assets/oban_powertools/tokens.css`, `lib/oban_powertools/web/dev/showcase_live.ex`, `scripts/showcase_manifest.exs`, `test/browser/support/manifest.ts`, `test/browser/support/axe.ts` - current implementation seams. [VERIFIED: codebase]
- `guides/brand-book.md` and `guides/visual-regression-and-a11y.md` - project design and guardrail contracts. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html - current Phoenix.Component docs cross-check. [CITED: phoenix-live-view.hexdocs.pm]
- https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html - current LiveComponent docs cross-check. [CITED: phoenix-live-view.hexdocs.pm]
- https://playwright.dev/docs/test-snapshots - official Playwright visual comparison docs. [CITED: playwright.dev]
- https://playwright.dev/docs/accessibility-testing - official Playwright + axe accessibility guidance. [CITED: playwright.dev]
- https://www.w3.org/WAI/ARIA/apg/patterns/button/ - WAI APG button pattern. [CITED: w3.org]
- https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/ - WAI APG tooltip pattern. [CITED: w3.org]
- https://www.w3.org/WAI/WCAG22/quickref/ - WCAG 2.2 quick reference. [CITED: w3.org]
- https://design-system.service.gov.uk/components/tag/ - GOV.UK tag guidance. [CITED: design-system.service.gov.uk]
- https://carbondesignsystem.com/components/tag/usage/ and https://carbondesignsystem.com/components/loading/usage/ - Carbon tag/loading guidance. [CITED: carbondesignsystem.com]
- https://primer.style/product/components/label/ - Primer label guidance. [CITED: primer.style]
- https://www.patternfly.org/patterns/status-and-severity/ - PatternFly status/severity guidance. [CITED: patternfly.org]

### Tertiary (LOW confidence)

- A1 in Assumptions Log: CSS-only tooltip Escape persistence limitation. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions were read from lockfiles/local commands and current registry checks; no new packages recommended. [VERIFIED: `mix.lock`][VERIFIED: `package.json`][VERIFIED: npm registry]
- Architecture: HIGH - based on locked phase decisions and current repo seams. [VERIFIED: 74-CONTEXT.md][VERIFIED: codebase]
- Pitfalls: MEDIUM - most pitfalls are directly grounded in docs/code; one tooltip implementation detail is flagged assumed. [CITED: official docs][ASSUMED]

**Research date:** 2026-07-10
**Valid until:** 2026-08-09 for Phoenix/component architecture; 2026-07-17 for npm/Playwright package currency. [VERIFIED: current date]
