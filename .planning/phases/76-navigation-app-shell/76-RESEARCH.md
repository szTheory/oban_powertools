# Phase 76: Navigation & App Shell - Research

**Researched:** 2026-07-11 [VERIFIED: system date]  
**Domain:** Phoenix LiveView app-shell components, scoped Powertools token CSS/JS, responsive navigation, accessibility, showcase/VRT/a11y evidence [VERIFIED: .planning/ROADMAP.md][VERIFIED: lib/oban_powertools/web/theme_shell.ex][VERIFIED: test/browser/specs/showcase.vrt.spec.ts]  
**Confidence:** MEDIUM [VERIFIED: codebase review][CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/breadcrumb/]

## User Constraints

No `.planning/phases/76-navigation-app-shell/76-CONTEXT.md` exists, so there are no phase-specific locked user decisions to copy verbatim. [VERIFIED: .planning/phases/76-navigation-app-shell directory listing]

### Locked Decisions

- Phase 76 goal: build the responsive Powertools app-shell with header, nav across 9 surfaces, theme toggle, and actor/context display. [VERIFIED: .planning/ROADMAP.md]
- Phase 76 depends on Phase 74 and inherits the primitive component layer and Phase 73 browser gate. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/phases/74-primitives-library/74-RESEARCH.md]
- The v2.0 milestone is a design-system/coherence milestone, not new operator capability. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/PROJECT.md]
- Library-owned CSS/JS must stay scoped under `.obpt-root`; theme state belongs on `.obpt-root` and not `<html>`. [VERIFIED: .planning/STATE.md][VERIFIED: assets/oban_powertools/tokens.css][VERIFIED: lib/oban_powertools/web/theme_shell.ex]
- Page migration across the 9 LiveViews is deferred to Phases 79-81; Phase 76 should create the shared shell surface and evidence without rewriting page bodies. [VERIFIED: .planning/ROADMAP.md]

### the agent's Discretion

- Exact module names, CSS class names, nav model shape, shell story catalog name, manifest schema extension, and plan split are left to planning because no Phase 76 CONTEXT.md exists. [VERIFIED: missing CONTEXT.md]
- Recommended default: add a separate `ObanPowertools.Web.Components.AppShell` plus dev/test-only shell story catalog, then integrate it into `ObanPowertools.Web.ThemeShell.live/1` after render/source/browser contracts exist. [VERIFIED: existing primitive/form component pattern][ASSUMED]

### Deferred Ideas (OUT OF SCOPE)

- Data-display components and unified status taxonomy belong to Phase 77. [VERIFIED: .planning/ROADMAP.md]
- `ConfirmActionDialog`, drawers, filter groups, and "Why blocked?" meta-components belong to Phase 78. [VERIFIED: .planning/ROADMAP.md]
- Rebuilding individual production pages onto the shell/components belongs to Phases 79-81. [VERIFIED: .planning/ROADMAP.md]
- Final copy, reduced-motion, 200% zoom/reflow, and manual screen-reader quality sweep remain Phase 82/83 work. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/REQUIREMENTS.md]

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NAV-01 | App-shell owns header, primary nav across 9 surfaces, theme toggle, actor/context display. [VERIFIED: .planning/REQUIREMENTS.md] | Implement a Phoenix function component/wrapper rendered by `ThemeShell.live/1`; current `ThemeShell` already wraps all native LiveViews and gets LiveView assigns before layout rendering. [VERIFIED: lib/oban_powertools/web/theme_shell.ex][VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/renderer.ex] |
| NAV-02 | Mobile-first responsive shell, collapsible at small widths, no horizontal scroll or unusable nested scrolling. [VERIFIED: .planning/REQUIREMENTS.md] | Use token CSS under `.obpt-root`, a button-driven disclosure state for small nav, and Playwright overflow checks at `chromium-320`. [VERIFIED: assets/oban_powertools/tokens.css][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/][VERIFIED: test/browser/specs/primitives.behavior.spec.ts] |
| NAV-03 | Active-route, breadcrumb, and deep-link affordances follow least surprise; nav labels match domain language. [VERIFIED: .planning/REQUIREMENTS.md] | Centralize a route/nav model for the 9 native surfaces and use `aria-current="page"` in primary nav/breadcrumb. [VERIFIED: lib/oban_powertools/web/router.ex][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/breadcrumb/] |
| NAV-04 | Shell is keyboard-navigable with skip-to-content link and logical focus order. [VERIFIED: .planning/REQUIREMENTS.md] | First focusable control should be "Skip to main content"; shell order should be skip link -> header/nav controls -> main content, verified by Playwright role/focus assertions. [CITED: https://www.w3.org/WAI/WCAG22/Techniques/general/G1][CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html][CITED: https://playwright.dev/docs/locators] |
| A11Y-02 | Interactive elements keyboard-reachable/operable with visible focus; color not sole signal. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse Phase 74 focus tokens and add shell-specific browser checks for focus visibility, disclosure toggle, `aria-expanded`, `aria-current`, and non-color active indicators. [VERIFIED: assets/oban_powertools/tokens.css][CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html] |
| COPY-* (nav labels) | Nav labels must use project/domain language consistently. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/REQUIREMENTS.md] | Recommended primary labels are Overview, Jobs, Batches, Workflows, Cron, Limiters, Lifeline, Audit, Forensics; they match current route/page vocabulary. [VERIFIED: lib/oban_powertools/web/router.ex][VERIFIED: current LiveView headings][ASSUMED] |

</phase_requirements>

## Project Constraints (from AGENTS.md/CLAUDE.md/Project Skills)

- No root `AGENTS.md`, root `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/skills`, or `.agents/skills` files were found in this workspace. [VERIFIED: file scan]
- An `AGENTS.md` exists only under `examples/phoenix_host_upgrade_source/`, so it does not apply as the working-directory project instruction file for Phase 76. [VERIFIED: file scan]
- The worktree already contains unrelated deleted planning files and untracked review/setup artifacts; planners/executors must not revert unrelated changes. [VERIFIED: git status --short]

## Summary

Phase 76 should be planned as a shell component/evidence phase, not a page migration. [VERIFIED: .planning/ROADMAP.md] The right implementation seam is the existing LiveView layout `ObanPowertools.Web.ThemeShell.live/1`, which already wraps every native route in `.obpt-root` and loads the compiled Powertools CSS/JS asset. [VERIFIED: lib/oban_powertools/web/theme_shell.ex][VERIFIED: lib/oban_powertools/web/router.ex] The shell can render header, primary nav, breadcrumb, skip link, actor display, and theme controls around `@inner_content` while keeping page body migrations deferred. [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/renderer.ex][ASSUMED]

The core design pattern should mirror Phases 74 and 75: stateless Phoenix function components, closed token-backed variants, safe rest attributes, a separate dev/test shell story catalog, generated manifest targets, VRT/axe coverage, and targeted Playwright behavior checks. [VERIFIED: lib/oban_powertools/web/components/primitives.ex][VERIFIED: lib/oban_powertools/web/components/forms.ex][VERIFIED: scripts/showcase_manifest.exs][VERIFIED: test/browser/specs/showcase.a11y.spec.ts]

The main planning risk is active-route/current-path plumbing. [VERIFIED: current ThemeShell has no current path assign] Layouts receive LiveView assigns, and LiveView supports `attach_hook/4` at `:handle_params`, so the least-invasive path is to extend `LiveAuth.on_mount/4` or a sibling on-mount hook to assign `:current_uri`/`:current_path` during `handle_params`; the layout can then compute active nav and breadcrumbs centrally. [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/renderer.ex][VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view.ex][ASSUMED]

**Primary recommendation:** add `ObanPowertools.Web.Components.AppShell`, a central 9-surface nav model, a `ShellStoryCatalog`, manifest/browser coverage, token CSS/JS for a disclosure-style mobile nav, then integrate the shell into `ThemeShell.live/1` with route-aware assigns from an on-mount `handle_params` hook. [VERIFIED: current code patterns][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/][ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Shell component rendering | Frontend Server (SSR / LiveView layout) | Browser / Client | `ThemeShell.live/1` is the LiveView layout for native routes; LiveView renders layouts with socket assigns and `@inner_content`. [VERIFIED: lib/oban_powertools/web/router.ex][VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/renderer.ex] |
| Route/nav model and breadcrumbs | Frontend Server (SSR) | Browser / Client | Route definitions live in `ObanPowertools.Web.Router`; nav labels/paths should be centralized rather than inferred in JS. [VERIFIED: lib/oban_powertools/web/router.ex][ASSUMED] |
| Mobile collapse state | Browser / Client | Frontend Server (SSR) | Disclosure open/closed state is immediate UI state; APG uses `button[aria-expanded]`/`aria-controls`, and the existing asset JS already handles delegated UI behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/][VERIFIED: assets/oban_powertools/theme.js] |
| Theme toggle | Browser / Client | CDN / Static | Existing `theme.js` owns `data-obpt-theme`, effective theme, reduced-motion, and `localStorage` under `.obpt-root`. [VERIFIED: assets/oban_powertools/theme.js][VERIFIED: lib/oban_powertools/web/theme_shell.ex] |
| Actor/context display | Frontend Server (SSR) | API / Backend | `LiveAuth.on_mount/4` assigns `:current_actor`; `Auth.audit_principal/1` and display policy normalize actor labels. [VERIFIED: lib/oban_powertools/web/live_auth.ex][VERIFIED: lib/oban_powertools/auth.ex][VERIFIED: lib/oban_powertools/runtime_config.ex] |
| Showcase/VRT/a11y evidence | Browser / Client test tier | Frontend Server (dev/test support) | Existing manifest-driven Playwright tests consume Elixir-generated story targets for screenshots and axe scans. [VERIFIED: scripts/showcase_manifest.exs][VERIFIED: test/browser/support/manifest.ts][VERIFIED: test/browser/specs/showcase.vrt.spec.ts] |

## Standard Stack

### Core

| Library / System | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 local; project requires `~> 1.19`. [VERIFIED: elixir --version][VERIFIED: mix.exs] | Builds Phoenix components and runs ExUnit tests. [VERIFIED: mix.exs] | Existing project runtime; no upgrade needed for Phase 76. [VERIFIED: mix.exs] |
| Phoenix | locked 1.8.7; latest seen 1.8.9 on Hex. [VERIFIED: mix deps][VERIFIED: mix hex.info phoenix] | Router/live_session host for native `/ops/jobs` routes. [VERIFIED: lib/oban_powertools/web/router.ex] | Existing native route tree uses Phoenix LiveView router integration. [VERIFIED: lib/oban_powertools/web/router.ex] |
| `phoenix_live_view` / `Phoenix.Component` | locked 1.1.31; latest seen 1.2.6 on Hex. [VERIFIED: mix deps][VERIFIED: mix hex.info phoenix_live_view] | Function components, LiveView layout rendering, `on_mount`, `attach_hook`, `handle_params`. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex][VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view.ex] | Existing primitive/form components already use this stack; shell should follow it. [VERIFIED: lib/oban_powertools/web/components/primitives.ex][VERIFIED: lib/oban_powertools/web/components/forms.ex] |
| Powertools token CSS + theme JS | existing source in `assets/oban_powertools/`. [VERIFIED: assets/oban_powertools/tokens.css][VERIFIED: assets/oban_powertools/theme.js] | Scoped styling, theme switching, reduced-motion and tooltip behavior. [VERIFIED: assets/oban_powertools/theme.js] | v2.0 requires library-owned isolated CSS/JS with no host Tailwind dependency. [VERIFIED: .planning/STATE.md][VERIFIED: .planning/REQUIREMENTS.md] |
| Playwright Test | `@playwright/test` locked 1.61.0. [VERIFIED: package.json][VERIFIED: npm ls] | VRT, structure, and targeted browser behavior checks. [VERIFIED: test/browser/specs/showcase.vrt.spec.ts][VERIFIED: test/browser/specs/primitives.behavior.spec.ts] | Existing Phase 73 harness is the merge-blocking browser gate. [VERIFIED: guides/visual-regression-and-a11y.md] |
| `@axe-core/playwright` / `axe-core` | 4.11.3 / 4.11.4 locked. [VERIFIED: package.json][VERIFIED: npm ls] | Automated a11y scans over generated showcase targets. [VERIFIED: test/browser/specs/showcase.a11y.spec.ts][VERIFIED: test/browser/support/axe.ts] | Existing axe gate blocks critical/serious violations. [VERIFIED: guides/visual-regression-and-a11y.md][CITED: https://playwright.dev/docs/accessibility-testing] |

### Supporting

| Library / System | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `jason` | 1.4.5 locked. [VERIFIED: mix deps] | Encodes generated showcase manifest JSON. [VERIFIED: scripts/showcase_manifest.exs] | Extend `scripts/showcase_manifest.exs` for shell stories. [VERIFIED: current manifest generator] |
| `lazy_html` | available test-only dependency. [VERIFIED: mix.exs] | HTML parsing for render contract tests. [VERIFIED: mix.exs] | Use if shell render tests become too brittle for string assertions. [ASSUMED] |
| PostgreSQL | accepting connections on `/tmp:5432`. [VERIFIED: pg_isready] | Example-host/dev browser gate database. [VERIFIED: scripts/with-showcase-server.sh][VERIFIED: guides/visual-regression-and-a11y.md] | Required for `npm run visual:a11y`. [VERIFIED: guides/visual-regression-and-a11y.md] |
| Docker | 29.5.2 local. [VERIFIED: docker info] | Runs pinned Playwright Docker image. [VERIFIED: guides/visual-regression-and-a11y.md] | Required for normal VRT/a11y gate and baseline updates. [VERIFIED: guides/visual-regression-and-a11y.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Phoenix function component shell | Stateful LiveComponent shell | Shell state is mostly presentational route/theme/collapse state; function components match Phases 74/75 and avoid adding component process/state complexity. [VERIFIED: previous component decisions][ASSUMED] |
| `nav` + links + disclosure button | ARIA `menu`/`menubar` roles | App/site navigation should keep normal link semantics; disclosure pattern preserves native link behavior and only adds `aria-expanded`/`aria-controls` for collapse. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/][ASSUMED] |
| Generated shell story targets | Hardcoded TypeScript shell selectors | Existing VRT/a11y harness is generated from Elixir catalogs; hardcoding would diverge from Phase 74/75 pattern. [VERIFIED: scripts/showcase_manifest.exs][VERIFIED: test/browser/support/manifest.ts] |
| Existing `theme.js` delegation | New client dependency | Existing scoped JS already owns theme and delegated tooltip behavior; adding a dependency would contradict zero-new-runtime-dep posture. [VERIFIED: assets/oban_powertools/theme.js][VERIFIED: .planning/STATE.md] |

**Installation:**

```bash
# No new package installs should be planned for Phase 76. Use existing locks. [VERIFIED: package.json][VERIFIED: mix.exs]
mix deps.get
npm ci
```

**Version verification performed:**

```bash
mix deps | rg 'phoenix|html|jason|lazy_html|oban|postgrex|ecto_sql'
mix hex.info phoenix_live_view
mix hex.info phoenix_html
mix hex.info phoenix
npm ls --depth=0 --json
npm view @playwright/test@1.61.0 version time.modified repository.url scripts.postinstall --json
npm view @axe-core/playwright@4.11.3 version time.modified repository.url scripts.postinstall --json
npm view axe-core@4.11.4 version time.modified repository.url scripts.postinstall --json
```

These commands verified locked local versions and npm package metadata; the phase should not upgrade dependencies because browser baselines are tied to the pinned Playwright image. [VERIFIED: command output][VERIFIED: guides/visual-regression-and-a11y.md]

## Package Legitimacy Audit

Phase 76 should install no new external packages. [VERIFIED: .planning/ROADMAP.md][VERIFIED: package.json][VERIFIED: mix.exs]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | none | n/a | n/a | n/a | OK | No new installs; planner should use existing locked deps. [VERIFIED: no new install requirement] |

Existing npm dev dependencies were checked because they remain in the validation stack. [VERIFIED: package-legitimacy seam]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | latest package flagged too-new by seam. [VERIFIED: package-legitimacy seam] | 44,736,392 weekly. [VERIFIED: package-legitimacy seam] | `github.com/microsoft/playwright`. [VERIFIED: npm view] | SUS for latest package check. [VERIFIED: package-legitimacy seam] | Keep existing lock `1.61.0`; do not upgrade/install in Phase 76. [VERIFIED: package.json][ASSUMED] |
| `@axe-core/playwright` | npm | latest package flagged too-new by seam. [VERIFIED: package-legitimacy seam] | 4,546,117 weekly. [VERIFIED: package-legitimacy seam] | `github.com/dequelabs/axe-core-npm`. [VERIFIED: npm view] | SUS for latest package check. [VERIFIED: package-legitimacy seam] | Keep existing lock `4.11.3`; do not upgrade/install in Phase 76. [VERIFIED: package.json][ASSUMED] |
| `axe-core` | npm | publishedAt 2026-06-10 in seam output. [VERIFIED: package-legitimacy seam] | 53,132,727 weekly. [VERIFIED: package-legitimacy seam] | `github.com/dequelabs/axe-core`. [VERIFIED: npm view] | OK. [VERIFIED: package-legitimacy seam] | Keep existing lock `4.11.4`; no install task needed. [VERIFIED: package.json] |

Existing locked npm packages returned no `scripts.postinstall` value at their checked versions. [VERIFIED: npm view]

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy seam]  
**Packages flagged as suspicious [SUS]:** no new installs; existing latest-package checks flagged `@playwright/test` and `@axe-core/playwright`, so any upgrade must be a separate human-verified dependency-upgrade task. [VERIFIED: package-legitimacy seam][ASSUMED]

## Architecture Patterns

### System Architecture Diagram

```text
Host router mounts /ops/jobs
  -> ObanPowertools.Web.Router live_session
    -> LiveAuth.on_mount assigns current_actor
    -> route-aware handle_params hook assigns current_path/current_uri [ASSUMED]
      -> ThemeShell.live layout renders .obpt-root
        -> AppShell component
          -> skip link
          -> header + actor/context display
          -> theme controls using existing theme.js
          -> primary nav across 9 native surfaces
          -> breadcrumb with aria-current=page
          -> mobile disclosure nav state in scoped JS/CSS
          -> main#obpt-main receives @inner_content
            -> existing page LiveView content unchanged in Phase 76
              -> ShellStoryCatalog + generated manifest
                -> Playwright structure + VRT + axe + shell behavior checks
```

### Recommended Project Structure

```text
lib/oban_powertools/web/components/
├── app_shell.ex                 # Shell, nav, breadcrumb, theme controls, actor/context display. [ASSUMED]
├── primitives.ex                # Existing lower-level components. [VERIFIED: lib/oban_powertools/web/components/primitives.ex]
└── forms.ex                     # Existing field components. [VERIFIED: lib/oban_powertools/web/components/forms.ex]

lib/oban_powertools/web/
├── theme_shell.ex               # Integrate AppShell around @inner_content. [VERIFIED: lib/oban_powertools/web/theme_shell.ex]
└── live_auth.ex                 # Add route/current-path on-mount hook or sibling hook. [ASSUMED]

test/support/
└── shell_story_catalog.ex       # Dev/test-only shell story source. [ASSUMED]

test/oban_powertools/web/components/
└── app_shell_test.exs           # Render/source/active-route/a11y contract tests. [ASSUMED]

test/browser/specs/
└── shell.behavior.spec.ts       # Skip link, collapse, focus order, aria-current, overflow. [ASSUMED]
```

### Pattern 1: Central App-Shell Component

**What:** Add a stateless function component that receives nav items, current path, actor, optional context, and inner content; it emits semantic shell markup and token-owned classes. [VERIFIED: Phoenix.Component pattern in existing code][ASSUMED]

**When to use:** Use for all native `/ops/jobs` LiveViews through `ThemeShell.live/1`; use showcase stories to render isolated shell states. [VERIFIED: lib/oban_powertools/web/theme_shell.ex][ASSUMED]

**Example:**

```elixir
# Source: Phoenix.Component docs and existing Primitives/Forms component style.
defmodule ObanPowertools.Web.Components.AppShell do
  use Phoenix.Component

  attr :current_path, :string, required: true
  attr :actor_label, :string, default: nil
  attr :context_label, :string, default: nil
  attr :nav_items, :list, required: true
  attr :rest, :global, default: %{}
  slot :inner_block, required: true

  def app_shell(assigns) do
    assigns = assign(assigns, :main_id, "obpt-main")

    ~H"""
    <div class="obpt-app-shell" data-obpt-app-shell {@rest}>
      <a class="obpt-skip-link" href={"##{@main_id}"}>Skip to main content</a>
      <header class="obpt-app-header">
        <.shell_nav items={@nav_items} current_path={@current_path} />
      </header>
      <main id={@main_id} tabindex="-1" class="obpt-app-main">
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end
end
```

### Pattern 2: Route-Aware Assigns via `attach_hook/4`

**What:** Add one on-mount hook that assigns route path/URI for every root LiveView during `handle_params`, then let the layout read those assigns. [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view.ex][VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/renderer.ex][ASSUMED]

**When to use:** Use when central shell active state/breadcrumbs need current URI without duplicating assignments in every LiveView. [ASSUMED]

**Example:**

```elixir
# Source: Phoenix.LiveView.attach_hook/4 local docs and current LiveAuth.on_mount/4 seam.
def on_mount(:default, _params, session, socket) do
  actor = Auth.current_actor(session)

  socket =
    socket
    |> assign(:current_actor, actor)
    |> Phoenix.LiveView.attach_hook(:obpt_current_path, :handle_params, fn _params, uri, socket ->
      path = URI.parse(uri).path || "/ops/jobs"
      {:cont, assign(socket, :obpt_current_path, path)}
    end)

  {:cont, socket}
end
```

### Pattern 3: Disclosure Navigation for Mobile

**What:** Use a native button with `aria-expanded` and `aria-controls` to collapse/expand nav links below the shell breakpoint; keep nav links as anchors/LiveView links and mark the active item with `aria-current="page"`. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/]

**When to use:** Use for the 320px mobile shell; wide view can render the same list expanded without changing link order. [VERIFIED: Phase 76 NAV-02][ASSUMED]

**Example:**

```heex
<button
  type="button"
  class="obpt-shell-nav-toggle"
  aria-expanded="false"
  aria-controls="obpt-primary-nav"
  data-obpt-nav-toggle
>
  Navigation
</button>
<nav id="obpt-primary-nav" class="obpt-primary-nav" aria-label="Powertools surfaces">
  <a
    :for={item <- @items}
    href={item.path}
    aria-current={if item.active?, do: "page"}
    data-obpt-active={item.active?}
  >
    {item.label}
  </a>
</nav>
```

### Anti-Patterns to Avoid

- **Page-owned nav/header duplication:** It keeps route labels, active state, and focus order scattered across pages; centralize in shell. [VERIFIED: current pages have their own headers][ASSUMED]
- **ARIA menu/menubar for app navigation:** It changes keyboard expectations for ordinary navigation links; use `nav` and disclosure semantics. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/][ASSUMED]
- **CSS-only collapse with stale ARIA:** Hidden checkbox/CSS-only patterns can leave `aria-expanded` unsynchronized; use a real button and scoped JS/data state. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/][ASSUMED]
- **Full-page VRT for shell first:** Existing harness captures stable story cells; shell stories should become explicit targets rather than broad screenshots that normalize unrelated page churn. [VERIFIED: test/browser/specs/showcase.vrt.spec.ts][ASSUMED]
- **Using host theme/global selectors:** v2.0 requires `.obpt-root` isolation and no host Tailwind/theme ownership. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: test/oban_powertools/web/theme_tokens_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Shell rendering | Stateful dashboard framework or custom component runtime | Phoenix function components in `AppShell`. [VERIFIED: existing component modules] | Existing stack already provides attrs/slots/layout rendering. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] |
| Theme switching | Second theme store or host `<html>` class toggles | Existing `assets/oban_powertools/theme.js`. [VERIFIED: assets/oban_powertools/theme.js] | v2.0 requires scoped `data-obpt-theme` and namespaced localStorage. [VERIFIED: .planning/STATE.md] |
| Active route/breadcrumb inference in JS | Client-side pathname parser with duplicated labels | Server-side nav model from router paths and current path assign. [VERIFIED: lib/oban_powertools/web/router.ex][ASSUMED] | Labels and breadcrumbs are product/copy contract, not client-only behavior. [VERIFIED: NAV-03][ASSUMED] |
| Mobile nav widget | ARIA menu implementation | Disclosure button + normal links. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/] | Keeps link semantics and simpler keyboard behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/] |
| A11y proof | Axe-only pass | Existing axe gate plus targeted Playwright focus/order/overflow tests. [VERIFIED: test/browser/specs/showcase.a11y.spec.ts][VERIFIED: test/browser/specs/primitives.behavior.spec.ts] | Axe does not prove focus order, skip link behavior, or collapse keyboard behavior. [VERIFIED: guides/visual-regression-and-a11y.md][CITED: https://playwright.dev/docs/accessibility-testing] |

**Key insight:** The shell is infrastructure for consistency. [ASSUMED] The planner should create a central nav/copy/accessibility contract and prove it in showcase/browser tests before touching individual page bodies. [VERIFIED: Phase ordering in .planning/ROADMAP.md][ASSUMED]

## Common Pitfalls

### Pitfall 1: Layout Lacks Current Route

**What goes wrong:** Active nav and breadcrumb cannot be computed centrally because `ThemeShell.live/1` currently only renders static shell wrapper markup. [VERIFIED: lib/oban_powertools/web/theme_shell.ex]  
**Why it happens:** Current pages already implement `handle_params/3`, but the layout does not yet receive a normalized current path assign. [VERIFIED: current LiveViews][VERIFIED: lib/oban_powertools/web/theme_shell.ex]  
**How to avoid:** Add a shared on-mount `:handle_params` hook or sibling hook that assigns `:obpt_current_path`/`:obpt_current_uri` before layout render. [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view.ex][ASSUMED]  
**Warning signs:** Shell tests need per-page manual assigns, or active state is duplicated in LiveViews. [ASSUMED]

### Pitfall 2: Mobile Nav Has Visual State Without Programmatic State

**What goes wrong:** The nav looks collapsed/expanded but screen readers do not get accurate `aria-expanded` state. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/]  
**Why it happens:** CSS-only state can be easier to draw than to synchronize. [ASSUMED]  
**How to avoid:** Use a button with `aria-controls` and `aria-expanded`, and update both data/CSS and ARIA from one scoped handler. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/][ASSUMED]  
**Warning signs:** Browser tests cannot assert `aria-expanded` changes after Space/Enter/click. [ASSUMED]

### Pitfall 3: Skip Link Does Not Actually Move Focus

**What goes wrong:** A skip link scrolls visually but leaves keyboard focus in the header/nav. [CITED: https://www.w3.org/WAI/WCAG22/Techniques/general/G1]  
**Why it happens:** The main target lacks an id and focusable target such as `tabindex="-1"`. [CITED: https://www.w3.org/WAI/WCAG22/Techniques/general/G1][ASSUMED]  
**How to avoid:** Make the skip link first, point it at `main#obpt-main`, and verify activation moves focus to main content. [CITED: https://www.w3.org/WAI/WCAG22/Techniques/general/G1]  
**Warning signs:** First Tab lands on theme/nav controls instead of "Skip to main content", or Enter on skip link leaves `document.activeElement` unchanged. [ASSUMED]

### Pitfall 4: Optional Oban Web Bridge Becomes Primary Navigation

**What goes wrong:** The shell implies the read-only bridge is a peer native operator surface. [VERIFIED: guides/optional-oban-web-bridge.md][VERIFIED: lib/oban_powertools/web/router.ex]  
**Why it happens:** `oban_dashboard_path` is available in session, but the roadmap names 9 native surfaces for primary nav. [VERIFIED: lib/oban_powertools/web/router.ex][VERIFIED: .planning/ROADMAP.md]  
**How to avoid:** Keep primary nav to the 9 native Powertools surfaces; if bridge is surfaced, make it secondary/contextual and label it "Oban Web bridge" / "Inspection only". [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex][ASSUMED]  
**Warning signs:** Primary nav count becomes 10 or bridge links use native/action language. [ASSUMED]

### Pitfall 5: Shell Story Pollutes Domain Stress Fixtures

**What goes wrong:** Shell component evidence becomes mixed into `ShowcaseCatalog.scenarios/0`, weakening the fixture boundary. [VERIFIED: test/support/showcase_catalog.ex][VERIFIED: previous phase decisions]  
**Why it happens:** The existing showcase renders several source catalogs and could accept shell examples in the wrong place. [VERIFIED: lib/oban_powertools/web/dev/showcase_live.ex]  
**How to avoid:** Add `ShellStoryCatalog` beside primitive/form catalogs and extend the manifest schema. [VERIFIED: test/support/primitive_story_catalog.ex][VERIFIED: test/support/form_story_catalog.ex][ASSUMED]

## Code Examples

Verified patterns from local and official sources:

### Layout Receives Assigns And Inner Content

```elixir
# Source: deps/phoenix_live_view/lib/phoenix_live_view/renderer.ex
assigns = put_in(assigns[:inner_content], inner_content)
assigns = put_in(assigns.__changed__[:inner_content], true)
Phoenix.Template.render(layout_mod, to_string(layout_template), "html", assigns)
```

This means route/current_actor assigns can be made available to `ThemeShell.live/1` if they are assigned on the socket before layout render. [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/renderer.ex][ASSUMED]

### Manifest Target Extension

```elixir
# Source: scripts/showcase_manifest.exs pattern, adapted for shell stories.
shell_stories =
  ShellStoryCatalog.stories()
  |> Enum.map(fn story ->
    id = Map.fetch!(story, :id)
    targets = Map.fetch!(story, :test_targets)

    %{
      id: id,
      kind: "shell",
      component: "app_shell",
      name: Map.fetch!(story, :name),
      story: Map.fetch!(targets, :story),
      snapshot: ShellStoryCatalog.snapshot_name(id),
      a11y: ShellStoryCatalog.a11y_target(id)
    }
  end)
```

Use the existing generated-manifest pattern rather than hardcoding shell tests in TypeScript. [VERIFIED: scripts/showcase_manifest.exs][ASSUMED]

### Browser Behavior Checks

```typescript
// Source: Playwright locator docs and current primitives/forms behavior specs.
const shell = page.locator('[data-obpt-shell-story="shell-nine-surface-nav"]');
await expect(shell.getByRole('navigation', { name: 'Powertools surfaces' })).toBeVisible();
await expect(shell.getByRole('link', { name: 'Jobs' })).toHaveAttribute('aria-current', 'page');
await shell.getByRole('button', { name: 'Navigation' }).press('Enter');
await expect(shell.getByRole('button', { name: 'Navigation' })).toHaveAttribute('aria-expanded', 'true');
```

Use role/name locators for shell behavior because Playwright recommends user-facing locators, especially `getByRole`. [CITED: https://playwright.dev/docs/locators]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Page-local headers and inline utility classes. [VERIFIED: current LiveViews] | Central app-shell function component plus token CSS. [ASSUMED] | v2.0 Phase 76 plan. [VERIFIED: .planning/ROADMAP.md] | Gives later page migrations a stable wrapper and reduces duplicated nav/copy/focus behavior. [ASSUMED] |
| ARIA menu roles for site navigation. [ASSUMED] | Native `nav`, links, and disclosure button for collapsible sections. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/] | Current WAI APG disclosure example updated 2026-01-20. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/] | Preserves normal link behavior and simpler keyboard expectations. [ASSUMED] |
| Manual VRT selector lists. [VERIFIED: older risk avoided by Phase 74/75] | Generated manifest with scenario/primitive/form targets. [VERIFIED: scripts/showcase_manifest.exs] | Phases 74-75. [VERIFIED: .planning/STATE.md] | Phase 76 should add shell as another generated target family. [ASSUMED] |
| Theme controlled by host/global `<html>`. [VERIFIED: .planning/REQUIREMENTS.md out of scope] | Scoped `.obpt-root` `data-obpt-theme` and namespaced localStorage. [VERIFIED: assets/oban_powertools/theme.js] | Phase 71. [VERIFIED: .planning/STATE.md] | Shell theme controls should call the existing mechanism. [ASSUMED] |

**Deprecated/outdated:**

- Treating the optional Oban Web bridge as a co-equal operator mutation surface is out of bounds; it is read-only inspection. [VERIFIED: lib/oban_powertools/web/router.ex][VERIFIED: guides/optional-oban-web-bridge.md]
- Adding PhoenixStorybook/third-party story runtime is out of scope for this milestone. [VERIFIED: .planning/REQUIREMENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Primary nav should include the 9 native surfaces only: Overview, Jobs, Batches, Workflows, Cron, Limiters, Lifeline, Audit, Forensics. [ASSUMED] | Phase Requirements, Common Pitfalls | If the bridge should appear in primary nav, shell copy/route model and VRT stories need one extra target/state. |
| A2 | Shell integration should happen through `ThemeShell.live/1` rather than wrapping each LiveView manually. [ASSUMED] | Summary, Architecture Patterns | If layout assigns are insufficient in practice, each LiveView may need explicit shell wrapper calls or a different on-mount hook shape. |
| A3 | Current path can be assigned centrally with an `attach_hook/4` `:handle_params` hook. [ASSUMED] | Summary, Pattern 2 | If hook ordering conflicts with page `handle_params/3`, the planner needs a narrower proof plan before broad integration. |
| A4 | Mobile collapse state can be owned by scoped browser JS in the existing asset. [ASSUMED] | Responsibility Map, Pattern 3 | If server-owned collapse is required, plans need LiveView events and possibly page diff considerations. |
| A5 | Phase 76 should add shell showcase stories and browser checks before production page integration. [ASSUMED] | Summary, Don't Hand-Roll | If the phase must visibly wrap production pages immediately, plan risk and VRT scope increase. |

## Open Questions

1. **Should the optional `/ops/jobs/oban` bridge appear in the shell?**
   - What we know: The router can mount `/ops/jobs/oban` as an optional read-only bridge, and project docs call it "Inspection only." [VERIFIED: lib/oban_powertools/web/router.ex][VERIFIED: guides/optional-oban-web-bridge.md]
   - What's unclear: No Phase 76 CONTEXT.md says whether to show it in the shell. [VERIFIED: missing CONTEXT.md]
   - Recommendation: Keep it out of primary 9-surface nav; if displayed, use secondary/context copy and `ControlPlanePresenter.bridge_banner/0`. [ASSUMED][VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex]

2. **How much actor context belongs in the header?**
   - What we know: `LiveAuth` assigns `current_actor`, and auth principal/display policy can produce operator labels. [VERIFIED: lib/oban_powertools/web/live_auth.ex][VERIFIED: lib/oban_powertools/auth.ex][VERIFIED: lib/oban_powertools/runtime_config.ex]
   - What's unclear: No user decision specifies tenant/environment context fields. [VERIFIED: missing CONTEXT.md]
   - Recommendation: Show a minimal actor label plus support-truth/context text available from existing seams; avoid inventing tenant/project labels without a host-provided value. [ASSUMED]

3. **Should shell wrap production pages in Phase 76 or only prove showcase stories?**
   - What we know: NAV-01 says the shell component owns header/nav/theme/actor display, while page migrations are later phases. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/ROADMAP.md]
   - What's unclear: No CONTEXT.md defines whether "owns" requires immediate production layout integration. [VERIFIED: missing CONTEXT.md]
   - Recommendation: Build and integrate the wrapper at layout level, but avoid rewriting page body content; use tests to ensure no page behavior regression. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Component/test runtime | yes | 1.19.5 / OTP 28. [VERIFIED: elixir --version] | none needed |
| Mix | Build/test commands | yes | 1.19.5. [VERIFIED: mix --version] | none needed |
| Node.js | Playwright/manifest tooling | yes | v22.14.0. [VERIFIED: node --version] | none needed |
| npm | Browser tooling install/scripts | yes | 11.1.0. [VERIFIED: npm --version] | none needed |
| PostgreSQL | Example-host browser gate | yes | `/tmp:5432` accepting connections. [VERIFIED: pg_isready] | none needed |
| Docker | Pinned Playwright image | yes | 29.5.2. [VERIFIED: docker info] | Host Playwright script exists but normal gate uses Docker. [VERIFIED: package.json] |

**Missing dependencies with no fallback:** none found. [VERIFIED: environment audit]  
**Missing dependencies with fallback:** none found. [VERIFIED: environment audit]

## Validation Architecture

`.planning/config.json` does not set `workflow.nyquist_validation` to `false`, so validation architecture is enabled for this phase. [VERIFIED: .planning/config.json]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit plus Phoenix LiveViewTest render/component tests; Playwright 1.61.0 plus axe. [VERIFIED: mix.exs][VERIFIED: package.json] |
| Config file | `test/test_helper.exs`, `playwright.config.ts`, `test/browser/support/manifest.ts`. [VERIFIED: rg --files] |
| Quick run command | `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` [ASSUMED] |
| Full suite command | `mix test && npm run visual:a11y` [VERIFIED: package.json][ASSUMED] |

Existing validation smoke:

- `mix test test/oban_powertools/web/components/primitives_test.exs test/oban_powertools/web/components/forms_test.exs --seed 0` passed with 32 tests, 0 failures. [VERIFIED: command output]
- `npm run showcase:manifest` completed successfully. [VERIFIED: command output]

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| NAV-01 | Shell renders header/nav/theme controls/actor context around content. [VERIFIED: .planning/REQUIREMENTS.md] | unit/render | `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` | No - Wave 0 |
| NAV-02 | 320px collapse has no horizontal overflow and no nested scrolling trap. [VERIFIED: .planning/REQUIREMENTS.md] | browser | `npx playwright test test/browser/specs/shell.behavior.spec.ts --project chromium-320` | No - Wave 0 |
| NAV-03 | Active route and breadcrumb use `aria-current=page`, stable labels, and deep-link paths. [VERIFIED: .planning/REQUIREMENTS.md] | unit + browser | `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` and shell Playwright spec | No - Wave 0 |
| NAV-04 | Skip link and focus order work by keyboard. [VERIFIED: .planning/REQUIREMENTS.md] | browser | `npx playwright test test/browser/specs/shell.behavior.spec.ts --project chromium-320` | No - Wave 0 |
| A11Y-02 | Interactive shell elements are keyboard-operable with visible focus. [VERIFIED: .planning/REQUIREMENTS.md] | axe + browser | `npm run visual:a11y -- --grep shell` [ASSUMED] | No - Wave 0 |
| COPY-* | Nav labels match domain language. [VERIFIED: .planning/ROADMAP.md] | unit/source | `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` | No - Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` plus the narrow browser spec when shell behavior changes. [ASSUMED]
- **Per wave merge:** `npm run showcase:manifest && npm run visual:a11y` for shell target coverage. [VERIFIED: package.json][ASSUMED]
- **Phase gate:** `mix test && npm run visual:a11y`; update VRT baselines only with `npm run vrt:update` when shell pixel changes are intentional. [VERIFIED: package.json][VERIFIED: guides/visual-regression-and-a11y.md]

### Wave 0 Gaps

- [ ] `lib/oban_powertools/web/components/app_shell.ex` - shell component API and nav model. [ASSUMED]
- [ ] `test/oban_powertools/web/components/app_shell_test.exs` - render/static/copy contract. [ASSUMED]
- [ ] `test/support/shell_story_catalog.ex` - deterministic shell stories. [ASSUMED]
- [ ] `test/oban_powertools/shell_story_catalog_test.exs` - catalog/target contract. [ASSUMED]
- [ ] `test/browser/specs/shell.behavior.spec.ts` - skip link, focus, collapse, active route, overflow. [ASSUMED]
- [ ] Extend `scripts/showcase_manifest.exs`, `test/browser/support/manifest.ts`, and `ShowcaseLive` for `kind: "shell"`. [VERIFIED: existing files][ASSUMED]

## Security Domain

`.planning/config.json` does not set `security_enforcement` to `false`, so security research applies. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Use existing host-owned `ObanPowertools.Auth.current_actor/1` via `LiveAuth.on_mount/4`; shell must not create authentication decisions. [VERIFIED: lib/oban_powertools/web/live_auth.ex][VERIFIED: lib/oban_powertools/auth.ex][CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| V3 Session Management | yes | Preserve existing LiveView session flow and do not add new client session tokens; theme/collapse state remains non-sensitive UI state. [VERIFIED: lib/oban_powertools/web/router.ex][VERIFIED: assets/oban_powertools/theme.js][CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| V4 Access Control | yes | Keep page/action authorization in `LiveAuth.authorize_page/3` and `authorize_action/4`; shell nav must not expose unauthorized mutation controls. [VERIFIED: lib/oban_powertools/web/live_auth.ex][CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| V5 Input Validation / V1 Encoding (ASVS 5.x) | yes | Treat route/path values and labels as server-controlled data; HEEx escaping and closed nav model should prevent injected nav HTML. [VERIFIED: Phoenix component stack][CITED: https://cheatsheetseries.owasp.org/IndexASVS.html][ASSUMED] |
| V6 Cryptography | no | Phase 76 adds no crypto, secrets, or protected data storage. [VERIFIED: phase scope][ASSUMED] |
| Client-side security | yes | JS must stay scoped to `.obpt-root`, use fixed selectors/data attributes, and avoid evaluating caller-provided strings. [VERIFIED: assets/oban_powertools/theme.js][ASSUMED] |

### Known Threat Patterns for Phoenix LiveView Shell

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized affordance confusion | Elevation of privilege | Nav may link to pages, but authorization remains enforced by `LiveAuth.authorize_page/3`; do not show mutation controls in shell. [VERIFIED: lib/oban_powertools/web/live_auth.ex][ASSUMED] |
| XSS through nav labels/context labels | Tampering | Use fixed server-side nav labels and HEEx escaping; reject caller `class`/`style` escape hatches like prior components. [VERIFIED: existing component patterns][ASSUMED] |
| Theme/collapse localStorage abuse | Spoofing / Tampering | Existing theme storage only accepts known theme enum and stores under `oban_powertools:theme`; nav collapse should use attributes, not persistent sensitive data. [VERIFIED: assets/oban_powertools/theme.js][ASSUMED] |
| Click target hidden behind sticky header | Denial of service / usability | Verify skip link, focus not obscured, and no nested scroll traps at 320px. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html][ASSUMED] |

## Sources

### Primary (HIGH confidence)

- `.planning/REQUIREMENTS.md` - NAV-01..04, A11Y-02, COPY requirements and milestone constraints. [VERIFIED: codebase]
- `.planning/ROADMAP.md` - Phase 76 scope, dependencies, and later phase boundaries. [VERIFIED: codebase]
- `.planning/STATE.md` and `.planning/PROJECT.md` - current phase state and v2.0 design-system decisions. [VERIFIED: codebase]
- `lib/oban_powertools/web/theme_shell.ex`, `router.ex`, `live_auth.ex`, `components/primitives.ex`, `components/forms.ex` - current shell/layout/auth/component seams. [VERIFIED: codebase]
- `scripts/showcase_manifest.exs`, `test/browser/support/manifest.ts`, Playwright specs - current evidence harness. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- Phoenix Component docs - function components, attrs, slots, globals. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]
- Phoenix LiveView JS interop/bindings docs - hooks and mounted JS. [CITED: https://phoenix-live-view.hexdocs.pm/js-interop.html][CITED: https://phoenix-live-view.hexdocs.pm/bindings.html]
- WAI APG breadcrumb/disclosure navigation docs. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/breadcrumb/][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/]
- W3C WCAG/WAI docs for bypass blocks, skip link technique, focus order, focus visible, and quick reference. [CITED: https://www.w3.org/WAI/WCAG22/Techniques/general/G1][CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html][CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html][CITED: https://www.w3.org/WAI/WCAG22/quickref/]
- Playwright docs for locators, screenshots, and accessibility testing. [CITED: https://playwright.dev/docs/locators][CITED: https://playwright.dev/docs/test-snapshots][CITED: https://playwright.dev/docs/accessibility-testing]
- OWASP ASVS project and ASVS cheat sheet index. [CITED: https://owasp.org/www-project-application-security-verification-standard/][CITED: https://cheatsheetseries.owasp.org/IndexASVS.html]

### Tertiary (LOW confidence)

- Planning assumptions caused by missing Phase 76 CONTEXT.md are logged in `## Assumptions Log`. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - locked project deps, local command output, and existing source files verified. [VERIFIED: command output][VERIFIED: codebase]
- Architecture: MEDIUM - current layout/auth/showcase seams are verified, but current-path hook and shell integration order are planning assumptions because no Phase 76 CONTEXT.md exists. [VERIFIED: codebase][ASSUMED]
- Pitfalls: MEDIUM - most risks are grounded in current source and W3C/Playwright guidance; optional bridge/nav treatment remains an assumption. [VERIFIED: codebase][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/][ASSUMED]

**Research date:** 2026-07-11 [VERIFIED: system date]  
**Valid until:** 2026-08-10 for codebase-centered planning; re-check package/tool versions before dependency upgrades. [ASSUMED]
