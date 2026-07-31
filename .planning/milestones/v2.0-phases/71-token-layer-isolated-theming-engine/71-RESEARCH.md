# Phase 71: Token Layer & Isolated Theming Engine - Research

**Researched:** 2026-06-18
**Domain:** Phoenix/LiveView library-owned CSS custom properties, theme controller JS, md5-hashed Plug-served assets
**Confidence:** HIGH

## User Constraints

No `71-CONTEXT.md` exists; Phase 71 is constrained by the phase prompt, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, Phase 70 artifacts, and live code. [VERIFIED: codebase]

- Do not implement production code during research; only create this artifact. [VERIFIED: phase prompt]
- Use Phase 70 brand-book decisions D-07..D-15 and D-22 as source of truth for token values and traceability. [VERIFIED: guides/brand-book.md]
- Ship a library-owned, namespaced, self-contained token/theme layer under `.obpt-root`; never mutate `<html>` or host theme storage. [VERIFIED: .planning/ROADMAP.md]
- CSS/JS must be precompiled and served by Powertools, md5-hashed, immutable, and independent of the host Tailwind build. [VERIFIED: .planning/REQUIREMENTS.md]
- Prove isolation against `examples/phoenix_host`, including host pages outside `/ops/jobs`, unchanged `<html>`, and no host storage mutation. [VERIFIED: phase prompt]
- Migrate only the `jobs_live.ex` badge/tab/modal seam as end-to-end proof; broader page migration belongs to later phases. [VERIFIED: .planning/STATE.md]

## Project Constraints (from AGENTS.md)

No root `./AGENTS.md` was present in `/Users/jon/projects/oban_powertools`; no project-specific AGENTS directives apply. [VERIFIED: `rg --files --hidden -g AGENTS.md`]

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TOKEN-01 | Two-tier `--obpt-*` token layer is the sole color/space/type/radii/elevation/motion source; no raw values in components. | Token taxonomy, CSS examples, grep validation, and proof seam migration below. [VERIFIED: .planning/REQUIREMENTS.md] |
| TOKEN-02 | Theme is scoped to `.obpt-root`; no host bleed/leak. | Root-scoped selectors, no `:root`/`html`/`body` mutation, and host isolation tests below. [VERIFIED: guides/brand-book.md] |
| TOKEN-03 | Library ships compiled CSS/JS, md5-hashed and immutable, independent of host Tailwind. | Oban Web-style `ObanPowertools.Web.Assets` Plug asset pattern and `priv/static` package notes below. [VERIFIED: deps/oban_web/lib/oban/web/assets.ex] |
| TOKEN-04 | Light/dark/system themes via `data-obpt-theme` on `.obpt-root`; system default; namespaced localStorage; media preferences honored. | Vanilla theme controller behavior and CSS media-query fallback below. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-color-scheme] |
| TOKEN-05 | Build is byte-stable; no FOUC/layout shift; token names are public contract. | Deterministic asset build, md5 route hashes, no Phoenix manifest timestamp reliance, and layout-shift checks below. [VERIFIED: deps/phoenix/lib/phoenix/digester.ex] |
| MOTION-01 | Motion duration/easing tokens live in the token layer; components avoid inline timing. | Motion token set and `prefers-reduced-motion` override below. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-reduced-motion] |
| A11Y-03 | Contrast meets AA in light/dark and enhanced ratios in high-contrast; target/focus checks. | Contrast token thresholds, local contrast-script requirement, WCAG mapping below. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html] |

</phase_requirements>

## Summary

Phase 71 should introduce a small design-system foundation, not a component library rewrite: a scoped `.obpt-root` token layer, a vanilla JS theme controller, an Oban Web-style asset Plug, and one migrated proof seam in `lib/oban_powertools/web/jobs_live.ex`. [VERIFIED: .planning/STATE.md] The existing library has no `assets/` or `priv/` static tree, and the current 9 LiveViews still use inline Tailwind utility classes; this phase must add the owned asset boundary before later component/page migration phases consume it. [VERIFIED: codebase]

Use `ObanPowertools.Web.Assets` modeled after `Oban.Web.Assets`: read compiled CSS/JS from `priv/static/oban_powertools`, compute md5 hashes at compile time, serve routes such as `/_assets/oban_powertools-<md5>.css` and `/_assets/oban_powertools-<md5>.js` through the Powertools router macro, and return `cache-control: public, max-age=31536000, immutable`. [VERIFIED: deps/oban_web/lib/oban/web/assets.ex] This avoids modifying the host endpoint or depending on host `Plug.Static`/Tailwind while still using Plug-served static content. [VERIFIED: examples/phoenix_host/lib/phoenix_host_web/endpoint.ex]

**Primary recommendation:** implement a deterministic, no-new-dependency token/asset layer with `assets/oban_powertools/{tokens.css,theme.js}` as source, `priv/static/oban_powertools/{oban_powertools.css,oban_powertools.js}` as compiled output, `ObanPowertools.Web.Assets` as the md5/immutable asset Plug, and `jobs_live.ex` badges/tabs/modals as the only migrated proof seam. [VERIFIED: codebase]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Token definitions | Browser / Client | API / Backend | CSS custom properties resolve in the browser; Elixir only ships assets and markup. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascading_variables/Using_custom_properties] |
| Theme persistence | Browser / Client | — | `localStorage` is origin browser state saved across sessions; keep it namespaced and only read/write from Powertools JS. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage] |
| Theme asset serving | API / Backend | Browser / Client | Router-mounted Plug serves immutable CSS/JS; browser consumes via link/script tags. [VERIFIED: deps/oban_web/lib/oban/web/router.ex] |
| Host isolation | Frontend Server / Router | Browser / Client | The router creates the `/ops/jobs` boundary; CSS selectors and JS enforce `.obpt-root` scope inside that boundary. [VERIFIED: lib/oban_powertools/web/router.ex] |
| Proof seam migration | Browser / Client | API / Backend | HEEx emits token class names; CSS variables control visual behavior without changing Lifeline/job mutation logic. [VERIFIED: lib/oban_powertools/web/jobs_live.ex] |
| Contrast/motion validation | Browser / Client | Test Harness | Ratios and media-query behavior are observable in rendered CSS/DOM; ExUnit can validate tokens and markup, browser checks validate computed styles. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html] |

## Current Codebase Facts

| Fact | Source |
|------|--------|
| `ObanPowertools.Web.Router.oban_powertools_routes/1` owns the inner native route tree mounted inside the host `/ops/jobs` scope. | [VERIFIED: lib/oban_powertools/web/router.ex] |
| The router currently imports `live/3`, `live/4`, and `live_session/3`, and mounts 12 native routes plus the dev-only brand book route. | [VERIFIED: lib/oban_powertools/web/router.ex] |
| `examples/phoenix_host` mounts Powertools inside `scope "/ops/jobs"` and leaves `/` as a normal host page. | [VERIFIED: examples/phoenix_host/lib/phoenix_host_web/router.ex] |
| The example host root layout links only host assets: `/assets/css/app.css`, `/assets/default.css`, and `/assets/js/app.js`; Powertools assets are not currently linked there. | [VERIFIED: examples/phoenix_host/lib/phoenix_host_web/components/layouts/root.html.heex] |
| The library has no `assets/` or root `priv/` directory today. | [VERIFIED: `find assets priv`] |
| `mix.exs` package `files:` includes `lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE`; it does not include `priv` yet, so compiled assets in `priv/static` will not ship unless `priv` is added. | [VERIFIED: mix.exs] |
| `jobs_live.ex` has the proof seam: `state_tab_class/1`, `state_badge_class/1`, single-job preview modal, and bulk preview modal. | [VERIFIED: lib/oban_powertools/web/jobs_live.ex] |
| Existing jobs tests cover tabs, badge class fragments, preview modals, and bulk preview behavior; they can be extended instead of creating an unrelated harness. | [VERIFIED: test/oban_powertools/web/live/jobs_live_test.exs] |
| Root test layout is minimal `<html><body>`, which is useful for asserting Powertools does not mutate `<html>`. | [VERIFIED: test/support/test_layouts.ex] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Phoenix | locked 1.8.7; latest visible 1.8.8 | Router, Plug endpoints, static digest primitives. | Already in repo; official docs/source cover static asset digest and endpoint behavior. [VERIFIED: mix.lock; `mix hex.info phoenix`] |
| Phoenix LiveView | locked 1.1.31; latest visible 1.2.3 | Current `/ops/jobs` UI and LiveView tests. | Existing route/session/render model; do not upgrade in Phase 71. [VERIFIED: mix.lock; `mix hex.info phoenix_live_view`] |
| Plug | locked 1.19.2 | Asset Plug response and immutable cache headers. | Official `Plug.Static` docs/source establish versioned immutable cache behavior; Oban Web uses a Plug asset module. [VERIFIED: mix.lock; deps/plug/lib/plug/static.ex] |
| Vanilla CSS custom properties | browser platform | Token implementation. | Custom properties can be scoped to `.obpt-root` and referenced by semantic classes. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascading_variables/Using_custom_properties] |
| Vanilla JavaScript | browser platform | Theme controller. | Avoids host bundler, LiveView hook registration, and npm dependencies. [VERIFIED: examples/phoenix_host has no asset watcher/package deps] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| ExUnit + Phoenix.LiveViewTest | existing | DOM/route assertions for root, proof seam, and no forbidden markup. | Primary automated validation. [VERIFIED: test/oban_powertools/web/live/jobs_live_test.exs] |
| lazy_html | 0.1.11 | HTML parsing assertions in tests. | Use for robust selector assertions instead of brittle string-only tests. [VERIFIED: mix.lock] |
| Node/npm | Node 22.14.0, npm 11.1.0 available | Optional browser-style script checks if planner adds a tiny JS test. | Do not install new packages for core phase. [VERIFIED: environment probe] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Oban Web-style asset Plug | Host endpoint `Plug.Static` | `Plug.Static` is official and supports immutable versioned requests, but using the host endpoint would require host code changes; Phase 71 should keep host opt-in limited to the existing router macro. [VERIFIED: deps/plug/lib/plug/static.ex; examples/phoenix_host endpoint] |
| Deterministic custom asset build | `mix phx.digest` manifest | Phoenix digester creates md5 filenames, but its manifest metadata includes generated `mtime`; clean regeneration can break byte-stability unless controlled. [VERIFIED: deps/phoenix/lib/phoenix/digester.ex] |
| LiveView colocated JS | Host bundler import | LiveView colocated JS requires bundler configuration/imports for dependencies; this phase must not require host asset pipeline changes. [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/colocated_js.ex] |

**Installation:**

```bash
# No new Hex or npm packages.
```

## Package Legitimacy Audit

No external packages should be installed for Phase 71. [VERIFIED: research recommendation]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | — | — | — | — | OK | No package legitimacy gate required. |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Host router scope "/ops/jobs"
  |
  | calls ObanPowertools.Web.Router.oban_powertools_routes("/oban")
  v
Powertools router macro
  |-- GET "/_assets/oban_powertools-<md5>.css" --> ObanPowertools.Web.Assets(:css)
  |-- GET "/_assets/oban_powertools-<md5>.js"  --> ObanPowertools.Web.Assets(:js)
  |
  v
JobsLive disconnected render
  |
  | renders asset tags + .obpt-root[data-obpt-theme="system"]
  | first child script initializes .obpt-root from oban_powertools:theme
  v
Browser
  |-- CSS custom properties resolve semantic tokens
  |-- matchMedia("(prefers-color-scheme: dark)") updates system theme
  |-- matchMedia("(prefers-reduced-motion: reduce)") zeroes motion tokens
  |-- localStorage writes only "oban_powertools:theme"
  v
Proof seam: badges, tabs, single/bulk modals use .obpt-* classes
```

### Recommended Project Structure

```text
assets/
└── oban_powertools/
    ├── tokens.css              # source token layer and scoped component proof classes
    └── theme.js                # source vanilla theme controller
priv/
└── static/
    └── oban_powertools/
        ├── oban_powertools.css # deterministic compiled output
        └── oban_powertools.js  # deterministic compiled output
lib/
└── oban_powertools/
    └── web/
        ├── assets.ex           # Plug serving compiled assets with md5 hashes
        ├── theme_shell.ex      # asset tags + .obpt-root wrapper helper
        ├── router.ex           # adds asset routes inside host-owned scope
        └── jobs_live.ex        # proof seam only
test/
└── oban_powertools/
    └── web/
        ├── assets_test.exs
        ├── theme_tokens_test.exs
        └── live/jobs_live_test.exs
```

### Pattern 1: Oban Web-Style Asset Plug

**What:** Read compiled static files at compile time, compute md5 hashes from content, serve via router `get` routes, and set immutable cache headers. [VERIFIED: deps/oban_web/lib/oban/web/assets.ex]

**When to use:** Use for library-owned assets when the library cannot modify the host endpoint or host Tailwind build. [VERIFIED: examples/phoenix_host endpoint/root layout]

**Example:**

```elixir
# Source: deps/oban_web/lib/oban/web/assets.ex, adapted for Powertools.
defmodule ObanPowertools.Web.Assets do
  @behaviour Plug
  import Plug.Conn

  @static_path Application.app_dir(:oban_powertools, ["priv", "static", "oban_powertools"])
  @external_resource css_path = Path.join(@static_path, "oban_powertools.css")
  @external_resource js_path = Path.join(@static_path, "oban_powertools.js")

  @css File.read!(css_path)
  @js File.read!(js_path)

  def init(asset), do: asset
  def call(conn, :css), do: serve(conn, @css, "text/css")
  def call(conn, :js), do: serve(conn, @js, "text/javascript")

  def current_hash(:css), do: md5(@css)
  def current_hash(:js), do: md5(@js)

  defp serve(conn, body, type) do
    conn
    |> put_resp_header("content-type", type)
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> put_private(:plug_skip_csrf_protection, true)
    |> send_resp(200, body)
    |> halt()
  end

  defp md5(body), do: Base.encode16(:crypto.hash(:md5, body), case: :lower)
end
```

### Pattern 2: Scoped Tokens Only Under `.obpt-root`

**What:** Declare primitive values and semantic roles only under `.obpt-root`; component/proof classes reference semantic roles only. [VERIFIED: guides/brand-book.md D-10]

**When to use:** All Powertools UI styling in this phase and later phases. [VERIFIED: .planning/REQUIREMENTS.md TOKEN-01/TOKEN-02]

**Example:**

```css
/* Source: guides/brand-book.md D-07..D-15; exact palette is Phase 71 recommendation. */
.obpt-root {
  --obpt-palette-slate-950: #0e1116;
  --obpt-palette-slate-900: #0f172a;
  --obpt-palette-slate-700: #334155;
  --obpt-palette-slate-600: #475569;
  --obpt-palette-slate-500: #64748b;
  --obpt-palette-slate-100: #f1f5f9;
  --obpt-palette-slate-50: #f8fafc;
  --obpt-palette-white: #ffffff;

  --obpt-font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
  --obpt-font-mono: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", "DejaVu Sans Mono", monospace;

  --obpt-color-surface: var(--obpt-palette-white);
  --obpt-color-elevated: var(--obpt-palette-white);
  --obpt-color-text: var(--obpt-palette-slate-900);
  --obpt-color-muted: var(--obpt-palette-slate-600);
  --obpt-color-border: var(--obpt-palette-slate-500);

  --obpt-space-1: 0.25rem;
  --obpt-space-2: 0.5rem;
  --obpt-space-3: 0.75rem;
  --obpt-space-4: 1rem;
  --obpt-space-5: 1.5rem;
  --obpt-space-6: 2rem;
  --obpt-space-7: 3rem;

  --obpt-radius-sm: 0.25rem;
  --obpt-radius-md: 0.375rem;
  --obpt-radius-lg: 0.5rem;
}
```

### Pattern 3: Theme Controller With System Default

**What:** A tiny vanilla JS controller applies `data-obpt-theme` and `data-obpt-effective-theme` to `.obpt-root`, persists explicit choices under `oban_powertools:theme`, listens to media-query changes for `system`, and never touches `<html>`. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Window/matchMedia]

**When to use:** Loaded by Powertools asset tags on Powertools pages only. [VERIFIED: phase prompt]

**Example:**

```javascript
// Source: MDN matchMedia/localStorage APIs; scoped to .obpt-root.
(() => {
  const KEY = "oban_powertools:theme";
  const THEMES = new Set(["system", "light", "dark", "high-contrast"]);
  const color = window.matchMedia("(prefers-color-scheme: dark)");
  const contrast = window.matchMedia("(prefers-contrast: more)");
  const motion = window.matchMedia("(prefers-reduced-motion: reduce)");

  function storedTheme() {
    try {
      const value = window.localStorage.getItem(KEY);
      return THEMES.has(value) ? value : "system";
    } catch (_) {
      return "system";
    }
  }

  function effective(theme) {
    if (theme !== "system") return theme;
    if (contrast.matches) return "high-contrast";
    return color.matches ? "dark" : "light";
  }

  function apply(root, theme = storedTheme()) {
    root.dataset.obptTheme = THEMES.has(theme) ? theme : "system";
    root.dataset.obptEffectiveTheme = effective(root.dataset.obptTheme);
    root.dataset.obptMotion = motion.matches ? "reduce" : "safe";
  }

  function setTheme(theme) {
    const next = THEMES.has(theme) ? theme : "system";
    try { window.localStorage.setItem(KEY, next); } catch (_) {}
    document.querySelectorAll(".obpt-root").forEach(root => apply(root, next));
  }

  const current = document.currentScript && document.currentScript.closest(".obpt-root");
  if (current) apply(current);
  document.querySelectorAll(".obpt-root").forEach(root => apply(root));

  [color, contrast, motion].forEach(mq => mq.addEventListener("change", () => {
    document.querySelectorAll('.obpt-root[data-obpt-theme="system"]').forEach(root => apply(root, "system"));
  }));

  document.addEventListener("click", event => {
    const control = event.target.closest("[data-obpt-theme-choice]");
    if (control) setTheme(control.dataset.obptThemeChoice);
  });

  window.ObanPowertoolsTheme = { apply, setTheme, storedTheme };
})();
```

### Anti-Patterns to Avoid

- **Global `:root`, `html`, `body`, or `.dark` selectors:** These leak into host ownership and contradict TOKEN-02/TOKEN-04. [VERIFIED: .planning/REQUIREMENTS.md]
- **Using Oban Web's `<html>.dark` model:** Oban Web mutates `document.documentElement.classList`; Powertools must not copy that part. [VERIFIED: deps/oban_web/lib/oban/web/components/layouts/root.html.heex]
- **Relying on host Tailwind classes for token proof:** The proof seam must use `.obpt-*` classes backed by Powertools CSS, not new Tailwind utilities. [VERIFIED: guides/brand-book.md D-10]
- **LiveView hooks for theme behavior:** Host `LiveSocket` would need Powertools hook registration; vanilla delegated JS avoids host bundler coupling. [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/colocated_js.ex]
- **Clean `Phoenix.Digester` manifest as the byte-stability proof:** The manifest can include generated `mtime`; prefer custom deterministic output and md5 functions for this phase. [VERIFIED: deps/phoenix/lib/phoenix/digester.ex]

## Recommended Token Structure

### Primitive Tokens

Use these categories in `tokens.css`; exact hex choices are Phase 71-owned and must pass the contrast script before merge. [VERIFIED: guides/brand-book.md D-10/D-12]

| Category | Required Names | Source Decision |
|----------|----------------|-----------------|
| Cool slate ramp | `--obpt-palette-slate-0/50/100/200/300/400/500/600/700/800/900/950` | D-08, D-10 [VERIFIED: guides/brand-book.md] |
| Accent ramp | `--obpt-palette-indigo-*` | D-07, D-10 [VERIFIED: guides/brand-book.md] |
| Info ramp | `--obpt-palette-cyan-*` | D-09, D-12 [VERIFIED: guides/brand-book.md] |
| Success ramp | `--obpt-palette-emerald-*` | D-09, D-12 [VERIFIED: guides/brand-book.md] |
| Warning ramp | `--obpt-palette-amber-*` | D-09, D-11 [VERIFIED: guides/brand-book.md] |
| Danger ramp | `--obpt-palette-red-*` | D-09, D-12 [VERIFIED: guides/brand-book.md] |
| Type | `--obpt-font-sans`, `--obpt-font-mono`, `--obpt-font-size-*`, `--obpt-line-height-*`, `--obpt-font-weight-*`, `--obpt-numeric-tabular` | D-13..D-15 [VERIFIED: guides/brand-book.md] |
| Space/radius/elevation | `--obpt-space-1..7`, `--obpt-radius-sm/md/lg`, `--obpt-shadow-overlay`, `--obpt-shadow-focus` | D-11, D-15, D-22 [VERIFIED: guides/brand-book.md] |
| Motion | `--obpt-duration-instant/fast/base/slow`, `--obpt-ease-standard/exit/enter` | D-05, MOTION-01 [VERIFIED: guides/brand-book.md] |

### Semantic Color Tokens

| Role | Required Names | Notes |
|------|----------------|-------|
| Surfaces | `--obpt-color-surface`, `--obpt-color-elevated`, `--obpt-color-overlay`, `--obpt-color-backdrop` | Dark elevation must step lighter than dark surface. [VERIFIED: guides/brand-book.md D-11] |
| Text | `--obpt-color-text`, `--obpt-color-muted`, `--obpt-color-subtle`, `--obpt-color-inverse` | `muted` must be at least 4.5:1. [VERIFIED: guides/brand-book.md D-11] |
| Borders/focus | `--obpt-color-border`, `--obpt-color-border-strong`, `--obpt-color-focus` | UI boundaries and focus need at least 3:1 where they convey affordance/state. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html] |
| Accent | `--obpt-color-accent-fg/bg/border/solid/solid-fg` | Accent is indigo-blue and never used for status pills. [VERIFIED: guides/brand-book.md D-07/D-09] |
| Status | `--obpt-color-info-*`, `--obpt-color-success-*`, `--obpt-color-warning-*`, `--obpt-color-danger-*` with `fg/bg/border/solid/solid-fg` subroles | Info is cyan-shifted; danger has highest chroma and is reserved. [VERIFIED: guides/brand-book.md D-09] |

### Theme Sets

| Selector | Behavior |
|----------|----------|
| `.obpt-root[data-obpt-theme="light"]`, `.obpt-root[data-obpt-effective-theme="light"]` | Explicit light tokens. [VERIFIED: phase prompt] |
| `.obpt-root[data-obpt-theme="dark"]`, `.obpt-root[data-obpt-effective-theme="dark"]` | Explicit dark tokens; near-black slate, not pure black. [VERIFIED: guides/brand-book.md D-11] |
| `.obpt-root[data-obpt-theme="high-contrast"]`, `.obpt-root[data-obpt-effective-theme="high-contrast"]` | Manual high-contrast tokens with enhanced ratios and thicker focus. [VERIFIED: guides/brand-book.md D-11/D-12] |
| `.obpt-root[data-obpt-theme="system"]` with `@media (prefers-color-scheme: dark)` | No-JS system dark fallback. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-color-scheme] |
| `.obpt-root[data-obpt-theme="system"]` with `@media (prefers-contrast: more)` | No-JS high-contrast fallback when the OS asks for more contrast. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-contrast] |
| `.obpt-root` with `@media (prefers-reduced-motion: reduce)` | Set non-essential motion durations to `0ms` or near-zero and remove transform-only flourish. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-reduced-motion] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Library asset serving | Host endpoint instructions or host Tailwind pipeline | Router-mounted `ObanPowertools.Web.Assets` Plug | Preserves host boundary and mirrors Oban Web's proven library route pattern. [VERIFIED: deps/oban_web/lib/oban/web/router.ex] |
| Theme state | Host `<html>.dark`, host `localStorage.theme`, or cookies | `.obpt-root[data-obpt-theme]` plus `localStorage["oban_powertools:theme"]` | Prevents host theme/storage collision. [VERIFIED: .planning/REQUIREMENTS.md] |
| Color roles in components | Raw hex/Tailwind utilities in HEEx | `.obpt-*` classes that reference semantic variables | Keeps token names semver-protected and grep-checkable. [VERIFIED: guides/brand-book.md D-10] |
| System theme detection | Custom polling | `window.matchMedia(...).addEventListener("change", ...)` | Browser API emits change events for media query changes. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Window/matchMedia] |
| Reduced motion | Per-component ad hoc conditionals | CSS motion tokens overridden by `prefers-reduced-motion` | Centralizes MOTION-01 and prevents missed inline timings. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-reduced-motion] |

**Key insight:** the hard part is the ownership boundary, not CSS syntax; copying host-dashboard patterns that mutate `<html>` or require host asset compilation would satisfy aesthetics while failing the product contract. [VERIFIED: .planning/PROJECT.md]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — Phase 71 is visual/theme-layer work and no database table stores theme/token state. [VERIFIED: repo grep for theme/localStorage plus schema inventory] | No data migration. |
| Live service config | None found in repo; example host route/static config is source-controlled. [VERIFIED: examples/phoenix_host/config/*.exs] | No external service patch. |
| OS-registered state | None — no launchd/systemd/pm2 state is involved. [ASSUMED] | No OS registration. |
| Secrets/env vars | None — theme key is public browser preference, not a secret; no env var controls it. [VERIFIED: config/*.exs] | No secret change. |
| Build artifacts / installed packages | New `priv/static/oban_powertools/*` compiled assets will become tracked/package artifacts; `mix.exs` must add `priv` to package `files:`. [VERIFIED: mix.exs] | Add deterministic build and package check. |
| Browser storage | New `localStorage["oban_powertools:theme"]` only; host keys such as `theme`, `oban:theme`, or app-specific keys must not be written. [VERIFIED: phase prompt; deps/oban_web uses `oban:theme`] | Add JS tests/browser checks for allowed key only. |

## Common Pitfalls

### Pitfall 1: Shipping Assets That Are Not In The Hex Package
**What goes wrong:** CSS/JS works locally but is missing for adopters. [VERIFIED: mix.exs]
**Why it happens:** `mix.exs` package `files:` does not include `priv` today. [VERIFIED: mix.exs]
**How to avoid:** Add `priv` once compiled assets live in `priv/static/oban_powertools`; verify with `mix hex.build --unpack` or existing package contract tests. [VERIFIED: mix.exs]
**Warning signs:** `Application.app_dir(:oban_powertools, ["priv", "static", ...])` fails in a package-like build. [VERIFIED: deps/oban_web/lib/oban/web/assets.ex]

### Pitfall 2: Theme FOUC From Late JS
**What goes wrong:** Page paints system theme, then flips to persisted explicit theme. [ASSUMED]
**Why it happens:** Server cannot read localStorage, and deferred scripts run after paint. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage]
**How to avoid:** Render CSS link before `.obpt-root`; render a small non-deferred theme script as the first child of `.obpt-root` so it sets root attributes before the rest of the Powertools content parses. [ASSUMED]
**Warning signs:** Browser test sees `data-obpt-effective-theme` change after first paint or layout shift after theme load. [ASSUMED]

### Pitfall 3: Copying Oban Web's Global Theme Model
**What goes wrong:** Powertools mutates `<html>.dark` or `localStorage["oban:theme"]`, changing host/Oban Web behavior. [VERIFIED: deps/oban_web/lib/oban/web/components/layouts/root.html.heex]
**Why it happens:** Oban Web is a full dashboard owning its root layout; Powertools is a nested host-owned surface. [VERIFIED: .planning/PROJECT.md]
**How to avoid:** Copy Oban Web's asset Plug pattern, not its `<html>` theme mutation. [VERIFIED: deps/oban_web/lib/oban/web/assets.ex]
**Warning signs:** Tests find `.dark` on `<html>`, `document.documentElement.style`, or `oban:theme` writes. [VERIFIED: phase prompt]

### Pitfall 4: Phoenix Digester Manifest Byte Drift
**What goes wrong:** Re-running a clean digest build changes `cache_manifest.json`. [VERIFIED: deps/phoenix/lib/phoenix/digester.ex]
**Why it happens:** Phoenix digester stores generated `mtime` in digest metadata, though unchanged existing digests may be reused. [VERIFIED: deps/phoenix/lib/phoenix/digester.ex]
**How to avoid:** For Phase 71, use deterministic source-to-`priv/static` copying plus compile-time md5 route hashes; if `Phoenix.Digester` is used, prove the exact clean/non-clean command sequence is byte-stable. [VERIFIED: deps/phoenix/lib/phoenix/digester.ex]
**Warning signs:** `git diff -- priv/static/oban_powertools` changes after re-running the build with unchanged sources. [ASSUMED]

### Pitfall 5: Broad Page Migration Hidden In Foundation
**What goes wrong:** Phase 71 becomes a page redesign and destabilizes operator behavior. [VERIFIED: .planning/ROADMAP.md]
**Why it happens:** Token work touches markup, and existing pages are inline utility-heavy. [VERIFIED: codebase]
**How to avoid:** Limit visible proof to `jobs_live.ex` badge/tab/modal classes; do not convert tables, filters, forms, or all cards yet. [VERIFIED: .planning/STATE.md]
**Warning signs:** Many `*_live.ex` files have broad Tailwind replacements. [VERIFIED: .planning/ROADMAP.md]

## Code Examples

### Proof Seam Classes

```css
/* Source: guides/brand-book.md D-09/D-10; used by jobs_live.ex only in Phase 71. */
.obpt-badge {
  display: inline-flex;
  align-items: center;
  gap: var(--obpt-space-1);
  border: 1px solid var(--obpt-badge-border);
  border-radius: var(--obpt-radius-sm);
  background: var(--obpt-badge-bg);
  color: var(--obpt-badge-fg);
  padding: var(--obpt-space-1) var(--obpt-space-2);
  font-size: var(--obpt-font-size-xs);
  font-weight: var(--obpt-font-weight-semibold);
}

.obpt-badge[data-obpt-tone="neutral"] {
  --obpt-badge-bg: var(--obpt-color-neutral-bg);
  --obpt-badge-fg: var(--obpt-color-neutral-fg);
  --obpt-badge-border: var(--obpt-color-neutral-border);
}

.obpt-badge[data-obpt-tone="info"] {
  --obpt-badge-bg: var(--obpt-color-info-bg);
  --obpt-badge-fg: var(--obpt-color-info-fg);
  --obpt-badge-border: var(--obpt-color-info-border);
}
```

### JobsLive Helper Shape

```elixir
# Source: lib/oban_powertools/web/jobs_live.ex proof seam.
defp state_badge_tone("executing"), do: "info"
defp state_badge_tone("retryable"), do: "warning"
defp state_badge_tone("discarded"), do: "danger"
defp state_badge_tone("completed"), do: "success"
defp state_badge_tone(_state), do: "neutral"

defp state_badge_class(_state), do: "obpt-badge"

# HEEx:
<span class={state_badge_class(job.state)} data-obpt-tone={state_badge_tone(job.state)}>
  <%= job.state %>
</span>
```

### Contrast Check Script

```javascript
// Source: WCAG relative luminance formula; run in tests against selected tokens.
function luminance(hex) {
  const [r, g, b] = hex.replace("#", "").match(/../g).map(v => parseInt(v, 16) / 255);
  const channel = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
}

function contrast(a, b) {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Host Tailwind utilities inside every LiveView | Library-owned scoped token classes under `.obpt-root` | Phase 71 begins this migration | Enables theme/contrast without host Tailwind dependency. [VERIFIED: .planning/ROADMAP.md] |
| Phoenix app endpoint owns `Plug.Static` | Library router owns an asset Plug, Oban Web style | Existing Oban Web 2.12.5 precedent | Keeps dependency assets self-contained in a host-owned router scope. [VERIFIED: deps/oban_web/lib/oban/web/router.ex] |
| Dashboard theme mutates `<html>.dark` | Powertools theme mutates only `.obpt-root[data-obpt-theme]` | Phase 70/TOKEN-04 locked | Preserves host ownership. [VERIFIED: .planning/REQUIREMENTS.md] |
| Ad hoc durations/classes | Motion tokens + reduced-motion media override | Phase 71 foundation | Centralizes MOTION-01. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-reduced-motion] |

**Deprecated/outdated:**
- Treating `dark:` Tailwind classes or global `.dark` as acceptable theming is out of scope for Powertools v2.0. [VERIFIED: .planning/REQUIREMENTS.md]
- Adding PhoenixStorybook or npm visual tooling in this foundation phase is out of scope; Phase 73 owns external Playwright/axe harnesses. [VERIFIED: .planning/REQUIREMENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Rendering a parser-blocking script as the first child of `.obpt-root` is sufficient to avoid visible theme FOUC for persisted explicit choices. | Common Pitfalls / Theme Controller | If browsers paint earlier than expected, planner may need a host head helper or accept a documented limitation. |
| A2 | The starter palette values suggested in examples are acceptable brand values if contrast checks pass. | Recommended Token Structure | If visual review rejects them, implementation must adjust hexes while preserving token names and ratios. |
| A3 | CSP nonce support is outside Phase 71 implementation scope, while `ThemeShell`/asset tags should remain compatible with nonce attrs. | Resolved Questions / Security | A nonce-requiring adopter would need a later compatible option mirroring Oban Web's `:csp_nonce_assign_key` route setting. |

## Open Questions (RESOLVED)

1. **CSP nonce support**
   - What we know: Oban Web supports a `:csp_nonce_assign_key` option for style/script assets. [VERIFIED: deps/oban_web/lib/oban/web/router.ex]
   - Disposition: CSP nonce support is not implemented in Phase 71. Current Powertools host examples do not configure CSP nonces, and Phase 71 owns the isolated theme asset boundary rather than CSP configuration. [VERIFIED: examples/phoenix_host/config/*.exs]
   - Plan constraint: `ThemeShell` and asset tags must be shaped so nonce attrs can be added through assigns/router options in a future compatible change, without changing the `.obpt-root` ownership model or asset route contract. [ASSUMED]

2. **Exact hex palette acceptance**
   - What we know: Phase 70 locked hue families, role semantics, and contrast floors but deferred exact hexes to Phase 71. [VERIFIED: guides/brand-book.md]
   - Disposition: Exact hex palette values are locked by the Plan 71-02 implementation of `assets/oban_powertools/tokens.css`; acceptance is through automated contrast/static checks plus the narrow JobsLive proof seam and manual visual check described in `71-VALIDATION.md`. [ASSUMED]
   - Plan constraint: The executor may adjust hex values only while preserving the D-07..D-12 hue families, semantic token names, contrast floors, and passing Wave 0 checks; the proof seam remains limited to JobsLive badges, tabs, and preview modals. [VERIFIED: .planning/REQUIREMENTS.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | Compile/tests/build task | yes | Mix 1.19.5 / OTP 28 | — |
| Phoenix | Router/asset docs | yes | 1.8.7 locked | Do not upgrade. |
| Plug | Asset Plug | yes | 1.19.2 locked | — |
| PostgreSQL client | Existing LiveView tests with repo setup | yes | psql 14.17 | Existing test aliases handle DB setup. |
| Node/npm | Optional JS smoke checks | yes | Node 22.14.0 / npm 11.1.0 | ExUnit string/DOM assertions for core phase. |
| Playwright CLI | Optional browser FOUC/storage checks | no | — | Defer full browser/VRT to Phase 73; use manual browser check or lightweight Node only if already available. |
| gsd-tools research seam | Research-plan/cache/classifier | no | local tool fails missing `package.json` | Used local code and official docs; no package installs recommended. |

**Missing dependencies with no fallback:** none for implementation. [VERIFIED: environment probe]

**Missing dependencies with fallback:**
- Playwright CLI is missing; Phase 71 can still validate core behavior with ExUnit/LiveView/lazy_html and leave full browser matrix to Phase 73. [VERIFIED: environment probe]
- `gsd-tools.cjs` failed with `Cannot find module '../../../package.json'`; this research used codebase, dependency source, Hex registry, and official docs instead. [VERIFIED: command output]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest + lazy_html. [VERIFIED: test tree / mix.lock] |
| Config file | `config/test.exs`. [VERIFIED: config/test.exs] |
| Quick run command | `mix test test/oban_powertools/web/assets_test.exs test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/web/router_test.exs` |
| Full suite command | `mix test --exclude host_contract` plus targeted `cd examples/phoenix_host && mix test test/phoenix_host_web/oban_powertools_control_plane_smoke_test.exs test/phoenix_host_web/controllers/page_controller_test.exs` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| TOKEN-01 | Token CSS contains two-tier primitive/semantic `--obpt-*`; proof seam classes contain no raw hex/px except token file. | unit/static | `mix test test/oban_powertools/web/theme_tokens_test.exs` | no - Wave 0 |
| TOKEN-02 | Rendered jobs page has one `.obpt-root`; no selectors/classes target `html`, `body`, `:root`, `.dark`, or unprefixed global component classes in Powertools CSS. | unit/static | `mix test test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/live/jobs_live_test.exs` | partial - jobs test exists |
| TOKEN-03 | Asset routes serve CSS/JS with md5 path and immutable cache header; package includes `priv/static/oban_powertools/*`. | unit/package | `mix test test/oban_powertools/web/assets_test.exs test/oban_powertools/hex_release_test.exs` | partial - hex release test exists |
| TOKEN-04 | Theme controller uses `data-obpt-theme` on `.obpt-root`, `oban_powertools:theme`, valid theme whitelist, and no `<html>` mutation strings. | unit/static | `mix test test/oban_powertools/web/theme_tokens_test.exs` | no - Wave 0 |
| TOKEN-05 | Re-running asset build changes no bytes; md5 hash stays stable; theme classes do not change layout-affecting dimensions. | unit/static + optional browser | `mix oban_powertools.assets.build && shasum priv/static/oban_powertools/*` repeated in test helper | no - Wave 0 |
| MOTION-01 | CSS declares motion tokens and `prefers-reduced-motion: reduce` override; proof seam uses token durations only. | unit/static | `mix test test/oban_powertools/web/theme_tokens_test.exs` | no - Wave 0 |
| A11Y-03 | Token pairs meet text/muted/status/focus contrast thresholds. | unit/static | `mix test test/oban_powertools/web/theme_tokens_test.exs` | no - Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs`
- **Per proof-seam commit:** `mix test test/oban_powertools/web/live/jobs_live_test.exs`
- **Per wave merge:** `mix test --exclude host_contract`
- **Phase gate:** full suite plus example host smoke/page tests, byte-stability re-run, and grep checks for forbidden selectors/storage keys.

### Wave 0 Gaps

- [ ] `test/oban_powertools/web/theme_tokens_test.exs` — parses `assets/oban_powertools/tokens.css` and checks token categories, forbidden selectors, raw values outside token declarations, media queries, and contrast pairs.
- [ ] `test/oban_powertools/web/assets_test.exs` — asserts md5 route paths, immutable headers, content types, and invalid/mismatched md5 behavior if implemented.
- [ ] `test/oban_powertools/web/live/jobs_live_test.exs` additions — assert `obpt-badge`, `obpt-tab`, and `obpt-modal` proof seam classes plus preserved behavior.
- [ ] `examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs` — host `/` page unchanged, `/ops/jobs/jobs` includes assets/root, no `<html>` class/data mutation in rendered static HTML.
- [ ] Asset build byte-stability test helper — run build twice and compare SHA256 of `priv/static/oban_powertools/*`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase only changes presentation; existing `LiveAuth` remains unchanged. [VERIFIED: lib/oban_powertools/web/router.ex] |
| V3 Session Management | no | Theme state uses localStorage only and does not affect auth/session. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage] |
| V4 Access Control | no | No mutation/auth flow changes; jobs actions still route through existing Lifeline behavior. [VERIFIED: lib/oban_powertools/web/jobs_live.ex] |
| V5 Input Validation | yes | Whitelist theme values to `system/light/dark/high-contrast`; ignore invalid localStorage values. [ASSUMED] |
| V6 Cryptography | yes, limited | MD5 is acceptable only for cache-busting route names, not security integrity; do not present it as tamper protection. [VERIFIED: deps/oban_web/lib/oban/web/assets.ex] |
| V14 Configuration | yes | Add `priv` to package files and avoid host endpoint/static config changes. [VERIFIED: mix.exs] |

### Known Threat Patterns for Scoped Theme Assets

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Host style leakage into Powertools proof seam | Tampering | Use `.obpt-root .obpt-*` selectors and avoid generic selectors. [VERIFIED: .planning/REQUIREMENTS.md] |
| Powertools style leakage into host pages | Tampering | Never emit global selectors; host `/` smoke test must not include `.obpt-root` or asset tags. [VERIFIED: examples/phoenix_host router] |
| localStorage poisoning | Tampering | Treat stored theme as untrusted; whitelist exact values and fallback to `system`. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage] |
| CSP breakage from inline/bootstrap script | Denial of Service | Prefer external JS asset; if inline bootstrap remains, design for optional nonce support mirroring Oban Web. [VERIFIED: deps/oban_web/lib/oban/web/router.ex] |
| Cache poisoning/stale asset confusion | Spoofing/Tampering | Include content md5 in URL and immutable cache headers; optionally 404 mismatched md5 params. [VERIFIED: deps/oban_web/lib/oban/web/assets.ex] |

## Exact Files Likely To Change

| File | Expected Change | Risk |
|------|-----------------|------|
| `mix.exs` | Add `priv` to package files; optionally add `mix oban_powertools.assets.build` alias/preferred env. | Medium: package omission breaks adopters. [VERIFIED: mix.exs] |
| `assets/oban_powertools/tokens.css` | New source token and proof-seam CSS. | Medium: public token contract starts here. [VERIFIED: .planning/REQUIREMENTS.md] |
| `assets/oban_powertools/theme.js` | New source theme controller. | Medium: host isolation and FOUC risk. [ASSUMED] |
| `priv/static/oban_powertools/oban_powertools.css` | New compiled CSS output. | Medium: must be byte-stable. [ASSUMED] |
| `priv/static/oban_powertools/oban_powertools.js` | New compiled JS output. | Medium: must be byte-stable. [ASSUMED] |
| `lib/oban_powertools/web/assets.ex` | New asset Plug. | Low/medium: follows Oban Web precedent. [VERIFIED: deps/oban_web/lib/oban/web/assets.ex] |
| `lib/oban_powertools/web/theme_shell.ex` | New root wrapper/asset tag helper. | Medium: placement controls FOUC/isolation. [ASSUMED] |
| `lib/oban_powertools/web/router.ex` | Add asset routes under host-owned scope. | Medium: route scope must not expose assets at host root. [VERIFIED: lib/oban_powertools/web/router.ex] |
| `lib/oban_powertools/web/jobs_live.ex` | Migrate state badges, tabs, and single/bulk modal classes to `.obpt-*` proof seam; do not alter action behavior. | Medium: behavior regression risk. [VERIFIED: lib/oban_powertools/web/jobs_live.ex] |
| `test/oban_powertools/web/live/jobs_live_test.exs` | Extend proof seam assertions. | Low. [VERIFIED: existing test] |
| `test/oban_powertools/web/assets_test.exs` | New immutable/md5 route tests. | Low. |
| `test/oban_powertools/web/theme_tokens_test.exs` | New token/static checks. | Low. |
| `examples/phoenix_host/test/...` | Add host isolation smoke test. | Low/medium: may require example host DB setup. [VERIFIED: examples/phoenix_host tests] |

## Sources

### Primary (HIGH confidence)

- `.planning/REQUIREMENTS.md` - TOKEN-01..05, MOTION-01, A11Y-03, out-of-scope boundaries. [VERIFIED: codebase]
- `.planning/ROADMAP.md` - Phase 71 success criteria and sequencing. [VERIFIED: codebase]
- `.planning/STATE.md` - current phase and proof seam debt note. [VERIFIED: codebase]
- `guides/brand-book.md` - D-07..D-15 and D-22 source of truth. [VERIFIED: codebase]
- `lib/oban_powertools/web/router.ex` - native route macro and dev route pattern. [VERIFIED: codebase]
- `lib/oban_powertools/web/jobs_live.ex` - proof seam functions/markup. [VERIFIED: codebase]
- `examples/phoenix_host/lib/phoenix_host_web/{router.ex,endpoint.ex,components/layouts/root.html.heex}` - host mount/static/layout boundary. [VERIFIED: codebase]
- `deps/oban_web/lib/oban/web/{assets.ex,router.ex,components/layouts/root.html.heex}` - asset Plug precedent and global theme anti-pattern to avoid. [VERIFIED: dependency source]
- `deps/plug/lib/plug/static.ex` - official Plug static caching behavior. [VERIFIED: dependency source]
- `deps/phoenix/lib/mix/tasks/phx.digest.ex`, `deps/phoenix/lib/phoenix/digester.ex`, `deps/phoenix/lib/phoenix/endpoint.ex` - official Phoenix digest/static behavior. [VERIFIED: dependency source]

### Secondary (MEDIUM confidence)

- Phoenix `mix phx.digest` docs - https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Digest.html [CITED: official docs]
- MDN CSS custom properties - https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascading_variables/Using_custom_properties [CITED: MDN]
- MDN `prefers-color-scheme` - https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-color-scheme [CITED: MDN]
- MDN `prefers-reduced-motion` - https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-reduced-motion [CITED: MDN]
- MDN `prefers-contrast` - https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-contrast [CITED: MDN]
- MDN `matchMedia` - https://developer.mozilla.org/en-US/docs/Web/API/Window/matchMedia [CITED: MDN]
- MDN `localStorage` - https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage [CITED: MDN]
- W3C WCAG 2.2 contrast docs - https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html, https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html, https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html [CITED: W3C]

### Tertiary (LOW confidence)

- Exact starter palette and FOUC mitigation details are recommendations that must be validated by implementation tests and visual review. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing locked deps, Hex registry checks, and local dependency source verified. [VERIFIED: mix.lock; mix hex.info]
- Architecture: HIGH - Oban Web asset precedent and current router/host boundaries are directly inspected. [VERIFIED: codebase]
- Token taxonomy: HIGH for names/categories from Phase 70; MEDIUM for starter hex values pending implementation contrast/visual review. [VERIFIED: guides/brand-book.md; ASSUMED]
- Pitfalls: HIGH for package/static/digest risks; MEDIUM for FOUC mitigation pending browser proof. [VERIFIED: codebase; ASSUMED]

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 for repository-local architecture; re-check Phoenix/LiveView/Plug docs if dependency versions change.
