# Phase 72: Stress Fixtures & Showcase Skeleton - Research

**Researched:** 2026-06-18
**Domain:** Elixir/Phoenix LiveView dev-only showcase route, deterministic test/dev fixtures, Hex package exclusion
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

### Locked Decisions

The following locked decisions are copied verbatim from `.planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md`. [VERIFIED: .planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md]

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

### the agent's Discretion

The following discretion areas are copied verbatim from `.planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md`. [VERIFIED: .planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md]

- Exact module names, internal function names, HEEx layout, and copy are left to research/planning as long as the decisions above hold.
- The planner may choose the cleanest dev/test compilation mechanism for the shared catalog, but it must not duplicate fixture data or leak dev/test artifacts into production or the hex package.
- The initial visual layout of the showcase is flexible within the brand-book constraints: calm, precise, token-only, and built for scanning.

### Deferred Ideas (OUT OF SCOPE)

The following deferred ideas are copied verbatim from `.planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md`. [VERIFIED: .planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md]

- Full primitive/form/data/group/page story implementation belongs to Phases 74-83.
- Playwright VRT project setup, baseline PNG commits, Docker pinning, snapshot update flow, and axe CI belong to Phase 73.
- Page migration, behavior preservation, and final cross-page consistency checks belong to Phases 79-82.
- Any comfortable/compact density preference remains deferred outside this foundation work.

## Project Constraints (from AGENTS.md)

No root `AGENTS.md` exists in `/Users/jon/projects/oban_powertools`; no AGENTS-specific directives apply. [VERIFIED: `if [ -f AGENTS.md ]; then ...` returned no file]

No `.codex/skills/` or `.agents/skills/` project skill directory exists in the repo; no project-local skill rules apply. [VERIFIED: project skills discovery command returned no files]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIX-01 | Deterministic named-scenario catalog covers normal and adversarial states. | Use `test/support/showcase_catalog.ex` as canonical data, domain-first, constant-only, with coverage tests for required states. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md] |
| FIX-02 | Fixtures are plain structs by default, use constants, and are shared by showcase, ExUnit, VRT names, and a11y targets. | Provide a pure catalog API returning maps/structs plus stable `scenario.id` and `test_targets`; avoid DB insertion except explicit helpers. [VERIFIED: .planning/REQUIREMENTS.md; codebase fixture search] |
| FIX-03 | Fixtures exercise per-persona JTBD scenarios and are excluded from the Hex tarball. | Add persona/JTBD metadata for triage, incident, repair, audit review; extend Hex release tests and `mix hex.build --unpack` proof to reject `test/support/showcase_catalog.ex`. [VERIFIED: .planning/REQUIREMENTS.md; test/oban_powertools/hex_release_test.exs; Hex docs] |
| SHOW-01 (skeleton) | Dev-only `/ops/jobs/_showcase` route renders a full future skeleton and is absent in prod. | Mount a dev-only LiveView route inside `:oban_powertools_native`; add route-info and prod absence checks. [VERIFIED: lib/oban_powertools/web/router.ex; .planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md] |
| SHOW-02 | Showcase has theme switcher and 320/tablet/wide viewport toggle with stable targets. | Reuse Phase 71 `data-obpt-theme-choice` delegated JS contract and expose `data-obpt-viewport` plus stable story attributes. [VERIFIED: assets/oban_powertools/theme.js; .planning/phases/71-token-layer-isolated-theming-engine/71-02-SUMMARY.md] |
| SHOW-03 | Showcase runs from `examples/phoenix_host` with no host changes and never leaks into prod/package. | Keep host router/layout untouched, prove `/` remains clean, prove `_showcase` renders in the example host dev boundary, and prove tarball excludes fixture support files. [VERIFIED: examples/phoenix_host/lib/phoenix_host_web/router.ex; examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs] |

## Summary

Phase 72 should add a validation-first foundation: a deterministic scenario catalog under `test/support/showcase_catalog.ex`, a dev-only `ObanPowertools.Web.Dev.ShowcaseLive` route mounted as `/ops/jobs/_showcase`, and tests proving stable IDs/data attributes, package exclusion, route gating, theme/viewport controls, and example-host isolation. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md]

The showcase must reuse Phase 71 exactly: the route belongs inside the existing `:oban_powertools_native` live session, so `ThemeShell.live/1` provides the md5 CSS/JS asset tags, `.obpt-root`, `data-obpt-theme="system"`, and `main.obpt-shell` without host root-layout or host Tailwind changes. [VERIFIED: lib/oban_powertools/web/router.ex; lib/oban_powertools/web/theme_shell.ex; lib/oban_powertools/web/assets.ex]

The main risk is the dev-route/module boundary in `examples/phoenix_host`: the existing `_brand_book` route is visible in example-host dev route info, but `Code.ensure_loaded?(ObanPowertools.Web.Dev.BrandBookLive)` returns false and the host emits an undefined LiveView warning because dependency-local dev/test config and deps are not enough when compiled as a path dependency. [VERIFIED: `cd examples/phoenix_host && MIX_ENV=dev mix run ...` probe] Phase 72 must not repeat that failure; the planner should make `ShowcaseLive` compile and load safely in the example host under `MIX_ENV=dev` without direct compile-time dependency on the excluded catalog, while preserving D-06 by guarding the `ShowcaseLive` module body and route with `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)` and proving the module is not loaded plus route info is `:error` in prod. [VERIFIED: code probe; .planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md]

**Primary recommendation:** implement Wave 0 tests first, then add `test/support/showcase_catalog.ex`, a guarded `ShowcaseLive` module body, a guarded `_showcase` route next to `_brand_book`, and dependency-safe catalog loading that makes the dev-mode path dependency compile/load in the example host while remaining absent in prod. [VERIFIED: codebase route/test patterns; official LiveViewTest docs]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Named scenario catalog | Test/dev support code | Frontend Server (LiveView) | Catalog data is deterministic source material for tests/showcase; LiveView only renders it. [VERIFIED: .planning/REQUIREMENTS.md FIX-01..03] |
| Showcase route gating | Frontend Server (Router/compile env) | API / Backend | Phoenix router macro decides whether `/ops/jobs/_showcase` exists; official `Application.compile_env/3` reads config at compilation time. [CITED: https://hexdocs.pm/elixir/Application.html] |
| Theme switching | Browser / Client | Frontend Server | Phase 71 theme JS listens for `[data-obpt-theme-choice]` clicks and mutates only `.obpt-root` attributes. [VERIFIED: assets/oban_powertools/theme.js] |
| Viewport toggle | Browser / Client | Frontend Server | The shell should expose deterministic story canvas state such as `data-obpt-viewport`; Playwright later still uses real browser viewports. [VERIFIED: .planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md] |
| Production absence | Build/router boundary | Package boundary | Prod absence is a compile/route property; fixture exclusion is a Hex package contents property. [VERIFIED: lib/oban_powertools/web/router.ex; mix.exs; Hex docs] |
| Example-host proof | Example host integration | Browser / Client | The example host already mounts `oban_powertools_routes("/oban")` under `/ops/jobs`; proof should exercise that existing mount without editing host router/layout. [VERIFIED: examples/phoenix_host/lib/phoenix_host_web/router.ex] |

## Current Codebase Map

| Area | Current State | Phase 72 Implication |
|------|---------------|----------------------|
| Router | `oban_powertools_routes/1` mounts assets and native LiveViews under a `live_session :oban_powertools_native`; `_brand_book` is compile_env-gated next to native routes. [VERIFIED: lib/oban_powertools/web/router.ex] | Add `_showcase` beside `_brand_book`, inside the same live session, not outside the shell. [VERIFIED: .planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md] |
| Theme shell | `ThemeShell.live/1` renders md5 CSS link, `.obpt-root`, external theme script, and `main.obpt-shell`. [VERIFIED: lib/oban_powertools/web/theme_shell.ex] | Showcase should not render a second root or duplicate asset tags. [VERIFIED: Phase 71 verification] |
| Theme JS | `theme.js` exposes `window.ObanPowertoolsTheme`, allows `system/light/dark/high-contrast`, uses `localStorage["oban_powertools:theme"]`, and delegated clicks on `[data-obpt-theme-choice]`. [VERIFIED: assets/oban_powertools/theme.js] | Theme controls can be plain buttons with `data-obpt-theme-choice`; no LiveView hook or host JS needed. [VERIFIED: assets/oban_powertools/theme.js] |
| Token CSS | `tokens.css` defines token categories and proof-seam classes such as `.obpt-shell`, `.obpt-tab`, `.obpt-badge`, `.obpt-modal`, `.obpt-button`. [VERIFIED: assets/oban_powertools/tokens.css; test/oban_powertools/web/theme_tokens_test.exs] | Initial showcase can render token swatches and proof-seam class examples without adding primitives. [VERIFIED: Phase 71 summaries] |
| Brand-book dev route | Module body and route are guarded by `Application.compile_env`; it parses trusted Markdown at compile time with `EarmarkParser`. [VERIFIED: lib/oban_powertools/web/dev/brand_book_live.ex] | Copy the route placement and test guard, but avoid new compile-time dev dependencies for showcase. [VERIFIED: codebase; example-host probe] |
| Test support | `mix.exs` compiles `test/support` only in `:test`; current fixtures are limited to `WorkflowFixtures`. [VERIFIED: mix.exs; test/support/workflow_fixtures.ex] | Canonical catalog can live in `test/support`, but dev-route access needs a no-duplication, no-Hex-leak strategy. [VERIFIED: mix.exs; 72-CONTEXT.md] |
| Hex package | `package.files` includes `lib priv guides ...` and excludes `test` and `.planning`; current unpack includes `priv/static/oban_powertools` and `lib/oban_powertools/web/dev/brand_book_live.ex`, not `test`. [VERIFIED: mix.exs; `mix hex.build --unpack -o /tmp/oban_powertools_phase72_pkg`] | Add explicit rejection for `test/support/showcase_catalog.ex` and any showcase support adapter outside `lib`; runtime `priv/static` must stay included. [VERIFIED: test/oban_powertools/hex_release_test.exs; Hex docs] |
| Example host | `examples/phoenix_host` uses `{:oban_powertools, path: "../.."}` and mounts the router macro under `/ops/jobs`; host root test asserts home copy. [VERIFIED: examples/phoenix_host/mix.exs; examples/phoenix_host/lib/phoenix_host_web/router.ex; page_controller_test.exs] | Example proof should extend existing isolation tests, not change the host router/root layout. [VERIFIED: examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5, OTP 28 | Compile guards, tests, Hex build. | Existing project runtime; `Application.compile_env/3` is official compile-time config API. [VERIFIED: `elixir --version`; `mix --version`; CITED: https://hexdocs.pm/elixir/Application.html] |
| Phoenix | 1.8.7 | Router macro, route info, host app boundary. | Existing stack and route macro already use Phoenix Router. [VERIFIED: `mix deps`; lib/oban_powertools/web/router.ex] |
| Phoenix LiveView | 1.1.31 | Dev-only showcase LiveView and LiveView tests. | Existing 9 operator pages and `ThemeShell` are LiveViews; `live(conn, path)` is the official test helper pattern. [VERIFIED: `mix deps`; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| ExUnit + Phoenix.LiveViewTest | built into stack | Catalog, route, render, and stable-selector tests. | Current web tests use `ObanPowertools.LiveCase` and `live/2`. [VERIFIED: test/support/live_case.ex; test/oban_powertools/web/live/jobs_live_test.exs] |
| Hex build task | Hex 2.4.2 local archive | Tarball inclusion/exclusion proof. | `mix help hex.build` documents `--unpack` for inspecting package contents before publishing. [VERIFIED: `mix help hex.build`; CITED: https://github.com/hexpm/hex/blob/main/lib/mix/tasks/hex.build.ex] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| lazy_html | 0.1.11+ in lock/deps | Robust HTML selector assertions. | Use if string assertions become brittle for `data-obpt-*` story cells. [VERIFIED: mix.lock; mix.exs] |
| Node/npm | Node 22.14.0, npm 11.1.0 | Future Phase 73 Playwright harness availability check only. | Do not install Playwright in Phase 72; just create stable targets. [VERIFIED: `node --version`; .planning/REQUIREMENTS.md VRT] |
| PostgreSQL | psql 14.17, server accepting connections on `/tmp:5432` | Existing DB-backed LiveView tests. | Needed for current test suite and any explicit DB helper tests. [VERIFIED: `pg_isready`; `psql --version`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom dev-only showcase route | PhoenixStorybook | PhoenixStorybook is explicitly out of scope as a published-library runtime dependency; custom route fits host-boundary constraints. [VERIFIED: .planning/REQUIREMENTS.md Out of Scope] |
| Plain constant catalog | Faker/randomized fixtures | Randomness breaks VRT determinism and violates FIX-02. [VERIFIED: .planning/REQUIREMENTS.md FIX-02; 72-CONTEXT.md D-04] |
| `test/support` canonical catalog | DB-only seed setup | DB rows are allowed only for explicit helper tests; screenshot-facing data should be plain structs/maps by default. [VERIFIED: 72-CONTEXT.md D-04] |
| `data-testid` display-copy selectors | `data-obpt-story`, `data-obpt-domain`, `data-obpt-persona`, `data-obpt-state` | Phase 72 decisions make story IDs public test contracts and reject display copy as selectors. [VERIFIED: 72-CONTEXT.md D-02] |

**Installation:**

```bash
# No new Hex or npm packages for Phase 72.
```

## Package Legitimacy Audit

No external packages should be installed for Phase 72. [VERIFIED: research recommendation; .planning/REQUIREMENTS.md Phase 72 scope]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | - | - | - | - | OK | No package legitimacy gate required. |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Host app router scope "/ops/jobs"
  |
  | existing call: ObanPowertools.Web.Router.oban_powertools_routes("/oban")
  v
Powertools router macro
  |-- GET "/_assets/:filename" -> ObanPowertools.Web.Assets
  |
  |-- live_session :oban_powertools_native
        | layout: {ObanPowertools.Web.ThemeShell, :live}
        | on_mount: [ObanPowertools.Web.LiveAuth]
        |
        |-- existing operator LiveViews
        |-- if dev_routes: live "/_brand_book"
        |-- if dev_routes: live "/_showcase"
                                |
                                v
                         ShowcaseLive mount/render
                                |
                                | optional runtime lookup
                                v
                ObanPowertools.ShowcaseCatalog scenarios
                (canonical test/support source, local dev/test only)
                                |
                                v
Browser
  | .obpt-root from ThemeShell
  | data-obpt-theme-choice buttons -> Phase 71 theme.js
  | data-obpt-viewport/story/domain/persona/state -> stable VRT/a11y targets
```

### Recommended Project Structure

```text
test/
├── support/
│   └── showcase_catalog.ex                 # canonical deterministic catalog
└── oban_powertools/
    ├── showcase_catalog_test.exs           # coverage + determinism contract
    ├── hex_release_test.exs                # tarball exclusion extension
    └── web/
        ├── router_test.exs                 # route-info contract extension
        └── live/
            └── showcase_live_test.exs      # render, controls, stable selectors
lib/
└── oban_powertools/
    └── web/
        ├── router.ex                       # add guarded /_showcase route
        └── dev/
            └── showcase_live.ex            # dev-only showcase shell
examples/
└── phoenix_host/
    └── test/phoenix_host_web/
        └── oban_powertools_theme_isolation_test.exs  # extend if test-env route is made available without host config
```

This structure preserves the requirement-named catalog path and keeps fixture data outside `package.files`, while letting the route render through existing library web code. [VERIFIED: .planning/REQUIREMENTS.md FIX-01; mix.exs package files]

### Pattern 1: Dev Route Beside `_brand_book`

**What:** Add `_showcase` inside the existing native live session and dev-route guard. [VERIFIED: lib/oban_powertools/web/router.ex]

**When to use:** Use for Phase 72 showcase only; do not add public operator route entries or host router changes. [VERIFIED: 72-CONTEXT.md D-06/D-07]

**Example:**

```elixir
# Source: lib/oban_powertools/web/router.ex, adapted for Phase 72.
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  live("/_brand_book", ObanPowertools.Web.Dev.BrandBookLive, :index)
  live("/_showcase", ObanPowertools.Web.Dev.ShowcaseLive, :index)
end
```

### Pattern 2: Optional Catalog Lookup Without Compile-Time Coupling

**What:** Avoid direct compile-time calls from `lib/` to an excluded `test/support` module; use module-name lookup and `apply/3` after `Code.ensure_loaded?/1`. [VERIFIED: mix.exs elixirc paths; Hex package exclusion proof]

**When to use:** Use inside `ShowcaseLive` so a Hex/package build can compile route code without shipping fixture data, while local dev/test can render the catalog. [VERIFIED: example-host dev route probe; .planning/REQUIREMENTS.md FIX-03]

**Example:**

```elixir
# Source: recommended pattern based on mix.exs elixirc_paths and Hex package constraints.
defp showcase_scenarios do
  catalog = Module.concat([ObanPowertools, ShowcaseCatalog])

  if Code.ensure_loaded?(catalog) and function_exported?(catalog, :scenarios, 0) do
    apply(catalog, :scenarios, [])
  else
    []
  end
end
```

### Pattern 3: Scenario Shape

**What:** Return plain maps or structs with stable metadata and fixture payloads. [VERIFIED: 72-CONTEXT.md D-01..D-05]

**When to use:** Every scenario in `test/support/showcase_catalog.ex`. [VERIFIED: .planning/REQUIREMENTS.md FIX-01/FIX-02]

**Example:**

```elixir
# Source: Phase 72 context D-01..D-04.
%{
  id: "jobs-long-worker-retryable",
  domain: :jobs,
  name: "Retryable job with long worker and redacted args",
  persona: :triage,
  jtbd: "Find the failing worker and decide the next safe inspection step.",
  states: [:retryable, :long_text, :redacted_args],
  test_targets: %{
    story: "jobs-long-worker-retryable",
    snapshot: "jobs-long-worker-retryable",
    a11y: "jobs-long-worker-retryable"
  },
  fixtures: %{
    jobs: [
      %{
        id: 420_000_001,
        state: "retryable",
        queue: "critical-mailer",
        worker: "Acme.Operations.Workers.Deeply.Nested.SendLifecycleNotificationToRegionalEscalationQueue",
        args: %{"account_id" => "acct_00000000000000000000000042", "locale" => "ar"},
        meta: %{"__redacted_fields__" => ["token"], "trace_id" => "trc_fixed_0001"}
      }
    ]
  }
}
```

### Pattern 4: Stable Showcase Cell Attributes

**What:** Render every story and future placeholder with stable `id` and `data-obpt-*` attributes. [VERIFIED: 72-CONTEXT.md D-02/D-08/D-09]

**When to use:** Token story cells, fixture index rows, and future placeholder sections. [VERIFIED: .planning/REQUIREMENTS.md SHOW-01/SHOW-02]

**Example:**

```heex
<!-- Source: Phase 72 context stable selector contract. -->
<section id={"obpt-story-#{scenario.id}"}
         data-obpt-story={scenario.id}
         data-obpt-domain={scenario.domain}
         data-obpt-persona={scenario.persona}
         data-obpt-state={Enum.join(scenario.states, " ")}>
  <h3><%= scenario.name %></h3>
</section>
```

### Anti-Patterns to Avoid

- **Direct `ObanPowertools.ShowcaseCatalog.scenarios()` calls from `lib/`:** this can create compile warnings or failures when the catalog is intentionally excluded from Hex. [VERIFIED: mix.exs; Hex unpack proof]
- **Adding `examples/phoenix_host` router/layout changes:** success criterion says the showcase runs from the example host with no host changes. [VERIFIED: phase prompt; examples/phoenix_host router]
- **Using `DateTime.utc_now/0`, `Ecto.UUID.generate/0`, `Enum.random/1`, `:rand`, or Faker for screenshot-visible data:** visible fixture values must be constants. [VERIFIED: 72-CONTEXT.md D-04]
- **Mounting the showcase outside `:oban_powertools_native`:** it would bypass `ThemeShell`, assets, `.obpt-root`, and LiveAuth. [VERIFIED: lib/oban_powertools/web/router.ex; ThemeShell]
- **Implementing Playwright/axe in Phase 72:** Phase 73 owns the external harness; Phase 72 only provides stable targets. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md VRT/A11Y]
- **Theme controls that mutate `<html>`, `.dark`, or `localStorage.theme`:** Phase 71 forbids host theme mutation. [VERIFIED: assets/oban_powertools/theme.js; test/oban_powertools/web/theme_tokens_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Theme persistence and system/high-contrast logic | A second theme controller or LiveView hook | Existing `assets/oban_powertools/theme.js` contract | It already handles allowed themes, media queries, namespaced storage, and delegated controls. [VERIFIED: assets/oban_powertools/theme.js] |
| Asset serving | New static endpoint or host `Plug.Static` config | Existing `ObanPowertools.Web.Assets.path/1` and `ThemeShell` | Phase 71 already proved md5 immutable assets without host changes. [VERIFIED: lib/oban_powertools/web/assets.ex; 71-VERIFICATION.md] |
| Full storybook framework | PhoenixStorybook or custom component DSL | One small dev-only LiveView with stable sections | PhoenixStorybook is out of scope and a prod-leak/dependency risk for this milestone. [VERIFIED: .planning/REQUIREMENTS.md Out of Scope] |
| Fixture randomness | Faker/random IDs/current timestamps | Constant maps/structs with optional seed ordering | VRT and a11y targets need repeatable DOM and pixels. [VERIFIED: 72-CONTEXT.md D-04/D-13; Playwright docs] |
| DB seed engine for screenshots | Broad insert helpers for every story | Plain structs/maps; explicit DB helper only where a test needs persistence | Requirement FIX-02 makes plain structs default and DB inserts exceptional. [VERIFIED: .planning/REQUIREMENTS.md FIX-02] |
| Selector generation from copy | Slugifying visible labels | Explicit scenario IDs and `data-obpt-*` attributes | Display copy will evolve; scenario IDs are public test contracts. [VERIFIED: 72-CONTEXT.md D-02] |

**Key insight:** Phase 72 is a contract phase, not a visual-richness phase; stable IDs, deterministic data, route/package proof, and host-boundary correctness are more important than component completeness. [VERIFIED: .planning/ROADMAP.md; 72-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Dependency Dev Route Exists but Module Is Missing

**What goes wrong:** The host router can mount a dev route while the dependency did not compile the dev-only LiveView module, causing undefined LiveView warnings or runtime failure. [VERIFIED: example-host `_brand_book` probe]

**Why it happens:** `examples/phoenix_host` compiles `oban_powertools` as a path dependency; dependency-local dev/test config and dev-only deps do not behave like root-project compilation, so the existing `_brand_book` module is not loaded in example-host dev even though route info shows the route. [VERIFIED: `Code.ensure_loaded?` probe; examples/phoenix_host deps tree]

**How to avoid:** Guard the `ShowcaseLive` module body and router entry with the same `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)` condition, make the guarded dev body compile without excluded catalog data or dev-only dependencies, and load catalog data optionally by module name or the local canonical support path when running from the repo/path dependency. [VERIFIED: mix.exs; Hex package proof]

**Warning signs:** `PhoenixHostWeb.Router.__checks__/0` warning about `ObanPowertools.Web.Dev.ShowcaseLive.__live__/0` or `Code.ensure_loaded?(ObanPowertools.Web.Dev.ShowcaseLive) == false` in `examples/phoenix_host`. [VERIFIED: example-host `_brand_book` warning]

### Pitfall 2: Catalog Data Leaks Into the Hex Tarball

**What goes wrong:** Test/dev fixture files ship to adopters, contradicting FIX-03 and increasing package surface. [VERIFIED: .planning/REQUIREMENTS.md FIX-03]

**Why it happens:** `mix.exs` package `files:` includes whole directories; adding catalog data under `lib` or `priv` ships it unless explicitly avoided. [VERIFIED: mix.exs; Hex docs]

**How to avoid:** Keep canonical fixture data under `test/support/showcase_catalog.ex` or another excluded support path; add tarball tests that reject `test/support/showcase_catalog.ex`, `.planning`, and any showcase support data file. [VERIFIED: test/oban_powertools/hex_release_test.exs]

**Warning signs:** `find /tmp/oban_powertools_pkg -type f | rg 'showcase_catalog|test/support|\\.planning'` returns any file. [VERIFIED: Hex `--unpack` docs]

### Pitfall 3: Determinism Lost Through Time, UUIDs, or Environment Values

**What goes wrong:** Later snapshots differ between runs because story text, IDs, timestamps, or ordering change. [CITED: https://playwright.dev/docs/test-snapshots]

**Why it happens:** Existing app tests often use `DateTime.utc_now/0` and `Ecto.UUID.generate/0` for DB behavior, but screenshot-facing fixture data has a stricter contract. [VERIFIED: codebase fixture/time search; 72-CONTEXT.md D-04]

**How to avoid:** Define fixed timestamps, IDs, worker names, counts, and strings; if a seed argument exists, use it only to choose deterministic ordering from a fixed list. [VERIFIED: .planning/REQUIREMENTS.md FIX-02]

**Warning signs:** `rg 'DateTime\\.utc_now|Ecto\\.UUID\\.generate|Enum\\.random|:rand|Faker' test/support/showcase_catalog.ex lib/oban_powertools/web/dev/showcase_live.ex` returns screenshot-visible data generation. [VERIFIED: local grep pattern]

### Pitfall 4: Route Tests Assume Example-Host Test Config Enables Dev Routes

**What goes wrong:** A new example-host LiveView test for `/ops/jobs/_showcase` fails with route not found in `MIX_ENV=test`. [VERIFIED: `cd examples/phoenix_host && MIX_ENV=test ... dev_routes` returned false]

**Why it happens:** The root project has `config :oban_powertools, dev_routes: true` in `config/test.exs`, but the example host does not configure that app key in test. [VERIFIED: config/test.exs; examples/phoenix_host/config/test.exs]

**How to avoid:** Either prove example-host behavior in `MIX_ENV=dev` with route/module inspection and a browser/server smoke, or adjust the library dev-route availability strategy without changing host config. [VERIFIED: phase prompt no-host-change criterion]

**Warning signs:** `Phoenix.Router.route_info(PhoenixHostWeb.Router, "GET", "/ops/jobs/_showcase", "localhost") == :error` under example-host test. [VERIFIED: example-host `_brand_book` test-env probe]

### Pitfall 5: Showcase Skeleton Becomes a Component Library Early

**What goes wrong:** Phase 72 drifts into primitives/forms/data/groups/page stories that belong to Phases 74-83. [VERIFIED: .planning/ROADMAP.md]

**Why it happens:** A showcase route naturally invites story completeness, but the milestone sequence requires guardrails before component/page migration. [VERIFIED: .planning/ROADMAP.md sequencing rationale]

**How to avoid:** Populate tokens/theming and fixture index/examples now; render future sections as explicit stable placeholders. [VERIFIED: 72-CONTEXT.md D-08]

**Warning signs:** New `Phoenix.Component` primitives, Playwright config, axe config, or page migration diffs appear in Phase 72. [VERIFIED: .planning/REQUIREMENTS.md phase mapping]

## Code Examples

### Route Guard Test Pattern

```elixir
# Source: test/oban_powertools/web/router_test.exs, adapted.
test "showcase route mounts only when dev routes are compiled" do
  assert %{
           plug: Phoenix.LiveView.Plug,
           phoenix_live_view: {ObanPowertools.Web.Dev.ShowcaseLive, :index, _, _}
         } =
           Phoenix.Router.route_info(
             ObanPowertools.TestRouter,
             "GET",
             "/ops/jobs/_showcase",
             "localhost"
           )
end
```

### Theme Control Markup

```heex
<!-- Source: assets/oban_powertools/theme.js delegated click contract. -->
<div data-obpt-theme-controls>
  <button type="button" data-obpt-theme-choice="system">System</button>
  <button type="button" data-obpt-theme-choice="light">Light</button>
  <button type="button" data-obpt-theme-choice="dark">Dark</button>
  <button type="button" data-obpt-theme-choice="high-contrast">High contrast</button>
</div>
```

### Viewport Control State

```heex
<!-- Source: 72-CONTEXT.md D-12 recommended data contract. -->
<div id="obpt-showcase-canvas"
     data-obpt-viewport={@viewport}
     class={"obpt-showcase-canvas obpt-showcase-canvas--#{@viewport}"}>
  <%= render_slot(@inner_block) %>
</div>
```

### Catalog Determinism Test

```elixir
# Source: Phase 72 FIX-02 contract.
test "scenario ids are stable and complete" do
  scenarios = ObanPowertools.ShowcaseCatalog.scenarios()
  ids = Enum.map(scenarios, & &1.id)

  assert ids == Enum.uniq(ids)
  assert Enum.all?(ids, &(&1 =~ ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/))
  assert ObanPowertools.ShowcaseCatalog.scenarios() == scenarios
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Host-owned CSS/Tailwind assumptions for operator UI | Library-owned md5 CSS/JS in `priv/static/oban_powertools` plus `ThemeShell` | Phase 71, 2026-06-18 | Showcase must consume `ThemeShell`/assets, not host Tailwind. [VERIFIED: 71-VERIFICATION.md] |
| Ad hoc page tests as the main visual confidence | Deterministic fixture + showcase target before VRT/a11y | Phase 72 roadmap | Later Playwright/axe scans need stable route/story IDs before component/page changes. [VERIFIED: .planning/ROADMAP.md] |
| Random or DB-first fixtures in tests | Plain constant catalog for screenshot-facing data | Phase 72 requirements | VRT determinism and a11y target stability become enforceable. [VERIFIED: .planning/REQUIREMENTS.md FIX-02] |
| Storybook dependency as design-system surface | Custom dev-only Phoenix LiveView route | v2.0 requirements | Avoids published runtime dependency and host-bundle drift. [VERIFIED: .planning/REQUIREMENTS.md Out of Scope] |

**Deprecated/outdated:**
- PhoenixStorybook for this package's shipped foundation is out of scope; use the custom dev-only route. [VERIFIED: .planning/REQUIREMENTS.md Out of Scope]
- Host `<html>.dark`/`localStorage.theme` theme control is prohibited; use `.obpt-root` and `oban_powertools:theme`. [VERIFIED: assets/oban_powertools/theme.js; test/oban_powertools/web/theme_tokens_test.exs]
- Wall-clock/random fixture values are prohibited for screenshot-visible catalog data. [VERIFIED: 72-CONTEXT.md D-04]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A dependency-safe, compile-env-guarded `ShowcaseLive` with optional catalog lookup is the resolved no-host-change strategy for the example-host dev-route/module mismatch. [RESOLVED] | Summary, Architecture Patterns, Open Questions | Must satisfy both dev-mode path dependency loading and prod module/route absence. |

## Open Questions (RESOLVED)

1. **How strict is "modules are guarded" versus "route absent in prod" for `_showcase`?**
   - What we know: Context D-06 says route and modules mirror the `_brand_book` compile_env guard, but the example host currently shows the `_brand_book` route can be mounted while its module is unavailable in dev dependency compilation. [VERIFIED: 72-CONTEXT.md; example-host probe]
   - RESOLVED: D-06 is strict. `ObanPowertools.Web.Dev.ShowcaseLive` must wrap its module body in `if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do ... end`, matching the router guard. Prod verification must prove both `Code.ensure_loaded?(ObanPowertools.Web.Dev.ShowcaseLive) == false` and `Phoenix.Router.route_info(..., "/ops/jobs/_showcase", ...) == :error`.
   - RESOLVED: The guarded dev body must stay dependency-safe: no compile-time dependency on `test/support/showcase_catalog.ex`, no ExDoc/EarmarkParser dependency, and optional catalog loading from the loaded module or canonical local support file only when available.

2. **Should example-host `_showcase` proof be automated in `MIX_ENV=test` or verified in `MIX_ENV=dev`?**
   - What we know: `examples/phoenix_host/config/test.exs` does not set `config :oban_powertools, dev_routes: true`; `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)` evaluates false in example-host test. [VERIFIED: examples/phoenix_host/config/test.exs; code probe]
   - RESOLVED: Example-host `_showcase` proof is dev-mode automation, not test-env host configuration. Do not edit example-host router, layout, Tailwind, or config files. Use `cd examples/phoenix_host && MIX_ENV=dev ...` compile/route/module commands to prove the existing path dependency loads `ShowcaseLive`; use prod commands to prove the same module and route are absent.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile/tests | yes | 1.19.5 on OTP 28 | none |
| Mix | Compile/tests/Hex build | yes | 1.19.5 | none |
| Hex build task | Tarball proof | yes | 2.4.2 local archive | inspect `Mix.Project.config()[:package][:files]`, but unpack proof is stronger |
| PostgreSQL | Existing LiveView/DB tests | yes | server accepting connections; psql 14.17 | Use static catalog tests for pure fixture checks; DB-backed existing tests still need Postgres |
| Node/npm | Future Phase 73 only | yes | Node 22.14.0 / npm 11.1.0 | Not needed in Phase 72 |

**Missing dependencies with no fallback:** none for Phase 72 research/planning. [VERIFIED: environment probes]

**Missing dependencies with fallback:** none identified. [VERIFIED: environment probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest + optional lazy_html [VERIFIED: test/support/live_case.ex; mix.exs] |
| Config file | `config/test.exs`; example host has its own `examples/phoenix_host/config/test.exs` [VERIFIED: config/test.exs; examples/phoenix_host/config/test.exs] |
| Quick run command | `mix test test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/router_test.exs` |
| Full suite command | `mix test --exclude host_contract` plus `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` plus targeted example-host proof |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FIX-01 | Domain-first catalog covers overview, jobs, batches, workflows, cron, limiters, lifeline, audit, forensics plus required adversarial state tags. | unit/static | `mix test test/oban_powertools/showcase_catalog_test.exs` | No - Wave 0 |
| FIX-02 | Catalog returns stable, constant-only plain maps/structs and stable scenario IDs/test targets. | unit/static | `mix test test/oban_powertools/showcase_catalog_test.exs` | No - Wave 0 |
| FIX-03 | Persona/JTBD coverage exists and catalog is excluded from Hex tarball. | unit/package | `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` and `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix hex.build --unpack -o /tmp/obpt_pkg` | Partial - extend existing |
| SHOW-01 | `/ops/jobs/_showcase` renders in dev/test root router and is route-info absent in prod proof. | live/integration | `mix test test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/router_test.exs`; prod command below | No - Wave 0 |
| SHOW-02 | Theme controls and viewport controls render with stable `data-obpt-*` attributes. | live/static | `mix test test/oban_powertools/web/live/showcase_live_test.exs` | No - Wave 0 |
| SHOW-03 | Example host root remains clean; showcase runs from existing `/ops/jobs` mount without host router/layout changes; fixture data excluded from package. | integration/package | Targeted example-host command below plus Hex package command | Partial - extend existing |

### Concrete Verification Commands and Evidence

**Deterministic fixtures:**

```bash
mix test test/oban_powertools/showcase_catalog_test.exs
rg 'DateTime\.utc_now|NaiveDateTime\.utc_now|System\.system_time|Ecto\.UUID\.generate|Enum\.random|:rand|Faker' test/support/showcase_catalog.ex
```

Expected evidence: tests assert unique slug IDs, all required domains, all FIX-01 adversarial state tags, all required personas/JTBDs, stable repeated output, and no forbidden randomness/time grep hits. [VERIFIED: .planning/REQUIREMENTS.md FIX-01..03]

**Showcase render and controls:**

```bash
mix test test/oban_powertools/web/live/showcase_live_test.exs
```

Expected evidence: `live(conn, "/ops/jobs/_showcase")` returns HTML with exactly one `obpt-root`, md5 asset paths, `data-obpt-theme-choice` values for `system`, `light`, `dark`, `high-contrast`, `data-obpt-viewport` values for `320`, `tablet`, `wide`, stable section anchors, and fixture story cells with `data-obpt-story/domain/persona/state`. [VERIFIED: official LiveViewTest docs; assets/oban_powertools/theme.js; 72-CONTEXT.md]

**Production route absence:**

```bash
MIX_ENV=prod mix compile --warnings-as-errors
cd examples/phoenix_host && MIX_ENV=prod mix run --no-start -e 'IO.inspect({Code.ensure_loaded?(ObanPowertools.Web.Dev.ShowcaseLive), Phoenix.Router.route_info(PhoenixHostWeb.Router, "GET", "/ops/jobs/_showcase", "localhost")})'
```

Expected evidence: prod compile succeeds and the tuple prints `{false, :error}`; no `_showcase` route or `ShowcaseLive` module is present in prod. [VERIFIED: Application.compile_env docs; lib/oban_powertools/web/router.ex pattern]

**Hex tarball exclusion:**

```bash
rm -rf /tmp/obpt_phase72_pkg
OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix hex.build --unpack -o /tmp/obpt_phase72_pkg
test -f /tmp/obpt_phase72_pkg/priv/static/oban_powertools/oban_powertools.css
test -f /tmp/obpt_phase72_pkg/priv/static/oban_powertools/oban_powertools.js
test ! -e /tmp/obpt_phase72_pkg/test/support/showcase_catalog.ex
! find /tmp/obpt_phase72_pkg -type f | rg '(^|/)(showcase_catalog\.ex|\.planning|test)(/|$)'
```

Expected evidence: runtime Phase 71 assets remain packaged; `test`, `.planning`, and showcase catalog/support files are absent. [VERIFIED: Hex docs; current `mix hex.build --unpack` proof]

**Example host behavior:**

```bash
cd examples/phoenix_host
MIX_ENV=dev mix compile --warnings-as-errors
MIX_ENV=dev mix run --no-start -e 'IO.inspect({Code.ensure_loaded?(ObanPowertools.Web.Dev.ShowcaseLive), Phoenix.Router.route_info(PhoenixHostWeb.Router, "GET", "/ops/jobs/_showcase", "localhost")})'
mix test test/phoenix_host_web/oban_powertools_theme_isolation_test.exs test/phoenix_host_web/controllers/page_controller_test.exs
```

Expected evidence: dev compile has no undefined LiveView warning, `Code.ensure_loaded?` is true, route info returns a LiveView route, and host `/` remains free of `obpt-root`, `/ops/jobs/_assets/`, and `oban_powertools:theme`; no example-host router/layout/config edits are required. [VERIFIED: example-host route probe; examples/phoenix_host tests]

### Sampling Rate

- **Per task commit:** Run the quick run command for touched area: catalog tests for catalog changes, LiveView route tests for showcase changes, package test for packaging changes. [VERIFIED: Phase 71 validation pattern]
- **Per wave merge:** Run `mix test --exclude host_contract` and targeted example-host checks. [VERIFIED: Phase 71 verification pattern]
- **Phase gate:** Full suite, Hex package unpack proof, prod route absence proof, and example-host no-host-change proof must be green before verification. [VERIFIED: .planning/REQUIREMENTS.md SHOW/FIX]

### Wave 0 Gaps

- [ ] `test/oban_powertools/showcase_catalog_test.exs` - covers FIX-01, FIX-02, FIX-03.
- [ ] `test/oban_powertools/web/live/showcase_live_test.exs` - covers SHOW-01 skeleton render and SHOW-02 controls/selectors.
- [ ] `test/oban_powertools/web/router_test.exs` additions - route-info contract for `_showcase`.
- [ ] `test/oban_powertools/hex_release_test.exs` additions - reject `test/support/showcase_catalog.ex` and showcase support artifacts.
- [ ] Example-host proof update - only after the route/module availability strategy is chosen.

## Security Domain

### Applicable ASVS Categories

OWASP ASVS 5.0 is the current stable version dated May 2025 and defines a web application security verification standard. [CITED: https://github.com/OWASP/ASVS]

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no new auth | Route is dev-only and read-only; keep inside existing `LiveAuth` live session but do not add authentication behavior. [VERIFIED: lib/oban_powertools/web/router.ex; lib/oban_powertools/web/live_auth.ex] |
| V3 Session Management | no new session model | Do not add cookies/session state; theme persistence remains browser-local and namespaced through Phase 71 JS. [VERIFIED: assets/oban_powertools/theme.js] |
| V4 Access Control | yes | Production route absence, dev-route guard, no mutations, no host config changes, and optional catalog lookup must fail closed. [VERIFIED: 72-CONTEXT.md D-06/D-14] |
| V5 Validation, Sanitization and Encoding | yes | Allowlist theme choices, viewport choices, scenario IDs, and render fixture strings through HEEx escaping; only trusted constant fixture data is rendered. [VERIFIED: Phoenix HEEx usage in existing LiveViews; 72-CONTEXT.md D-02/D-04] |
| V6 Stored Cryptography | no | No secrets, encryption, signing, or credential storage are introduced. [VERIFIED: Phase 72 scope] |
| V7 Error Handling and Logging | yes, limited | Missing optional catalog should render a bounded dev-only empty state, not crash or log sensitive host data. [VERIFIED: package exclusion constraint; ASSUMED recommendation] |
| V10 Malicious Code | yes, limited | Do not add npm packages, external scripts, dynamic eval, or user-provided HTML. [VERIFIED: no package recommendation; Phase 72 scope] |

### Known Threat Patterns for Phoenix/LiveView Dev Showcase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dev route leaks to production | Information Disclosure | `Application.compile_env` route guard, prod route-info proof, and package exclusion checks. [CITED: https://hexdocs.pm/elixir/Application.html; VERIFIED: 72-CONTEXT.md] |
| Fixture HTML injection | Tampering / XSS | Render strings through HEEx interpolation; do not use `Phoenix.HTML.raw/1` for fixture values. [VERIFIED: existing BrandBookLive raw use is trusted Markdown-specific; Phase 72 fixtures are data] |
| Host theme/state tampering | Tampering | Use only `.obpt-root`, `data-obpt-theme-choice`, and `localStorage["oban_powertools:theme"]`; reject `<html>`/`.dark`/`localStorage.theme`. [VERIFIED: assets/oban_powertools/theme.js; theme_tokens_test.exs] |
| Catalog/package leak | Information Disclosure | Keep catalog under excluded support path and assert unpacked Hex tarball absence. [VERIFIED: mix.exs; Hex docs] |
| Selector instability breaks a11y/VRT gates | Repudiation / Integrity | Treat scenario IDs and `data-obpt-*` selectors as public contracts with tests. [VERIFIED: 72-CONTEXT.md D-02] |
| Accidental operator behavior change | Tampering | Do not modify existing 9 LiveViews except tests if needed; showcase uses fixture data and placeholders only. [VERIFIED: .planning/ROADMAP.md Phase 72 scope] |

## Risks and Plan Boundaries

| Risk | Severity | Recommendation |
|------|----------|----------------|
| Existing `_brand_book` route/module mismatch in example host may repeat for `_showcase`. [VERIFIED: example-host probe] | High | Add the route/module availability proof before implementation completion; keep the module body compile-env guarded and avoid direct compile-time dependencies from `ShowcaseLive` to excluded support files. [RESOLVED] |
| `test/support/showcase_catalog.ex` is not compiled in dev by current root `mix.exs`. [VERIFIED: mix.exs] | Medium | Make the guarded dev module optionally load `ObanPowertools.ShowcaseCatalog` from the loaded module or canonical local support path without duplicating fixture data, while tests exercise catalog in `MIX_ENV=test`. [RESOLVED] |
| Scope creep into primitives/VRT/a11y harness. [VERIFIED: roadmap] | Medium | Restrict Phase 72 to skeleton, tokens/theming, fixture index/examples, controls, stable placeholders, and validation contracts. [VERIFIED: 72-CONTEXT.md] |
| Hex package proof could accidentally remove required Phase 71 assets. [VERIFIED: current package includes `priv/static`] | Medium | Extend tests to reject fixture data while still requiring `priv/static/oban_powertools/*.css|*.js`. [VERIFIED: test/oban_powertools/hex_release_test.exs] |
| High-contrast and viewport controls may be visual-only without state exposure. [VERIFIED: SHOW-02] | Low | Assert explicit DOM attributes for selected control state, even if Phase 73 later drives real browser viewport sizes. [VERIFIED: 72-CONTEXT.md D-12] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md` - locked decisions D-01..D-14, discretion, deferred scope. [VERIFIED: codebase]
- `.planning/ROADMAP.md` - Phase 72 goal, success criteria, sequencing rationale. [VERIFIED: codebase]
- `.planning/REQUIREMENTS.md` - FIX-01..03, SHOW-01..03, VRT/A11Y boundaries. [VERIFIED: codebase]
- `.planning/phases/71-token-layer-isolated-theming-engine/71-RESEARCH.md`, `71-02-SUMMARY.md`, `71-03-SUMMARY.md`, `71-04-SUMMARY.md`, `71-05-SUMMARY.md`, `71-VERIFICATION.md` - token/theme/assets/shell proof. [VERIFIED: codebase]
- `guides/brand-book.md` - brand constraints: calm, precise, color as information, no decorative flourish. [VERIFIED: codebase]
- `lib/oban_powertools/web/router.ex`, `theme_shell.ex`, `assets.ex`, `web/dev/brand_book_live.ex` - route/shell/asset/dev-route implementation. [VERIFIED: codebase]
- `assets/oban_powertools/theme.js`, `tokens.css`, `test/oban_powertools/web/theme_tokens_test.exs` - Phase 71 theme and token contracts. [VERIFIED: codebase]
- `mix.exs`, `test/oban_powertools/hex_release_test.exs`, `examples/phoenix_host/*` - package and example-host constraints. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- Elixir Application docs - `Application.compile_env/3` compile-time behavior. [CITED: https://hexdocs.pm/elixir/Application.html]
- Phoenix LiveViewTest docs - `live(conn, path)` testing behavior. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
- Hex publish/build docs - package `:files` and `mix hex.build --unpack`. [CITED: https://hex.pm/docs/publish; https://github.com/hexpm/hex/blob/main/lib/mix/tasks/hex.build.ex]
- Playwright visual comparisons docs - screenshot determinism and snapshot update behavior. [CITED: https://playwright.dev/docs/test-snapshots]
- Playwright accessibility docs - `@axe-core/playwright` guidance and automated-a11y limitations. [CITED: https://playwright.dev/docs/accessibility-testing]
- OWASP ASVS repo - current stable ASVS 5.0.0 and verification-standard framing. [CITED: https://github.com/OWASP/ASVS]

### Tertiary (LOW confidence)

- A1 dependency-safe `ShowcaseLive` optional catalog lookup is now resolved by strict D-06 module/route guarding, dev-mode example-host automation, and prod module/route absence proof. [RESOLVED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and files verified locally; official docs checked for compile/test/package behavior. [VERIFIED: environment probes; cited docs]
- Architecture: HIGH - route/session/theme/package boundaries are established by Phase 71 code and verification. [VERIFIED: codebase; 71-VERIFICATION.md]
- Fixture catalog shape: HIGH - locked by Phase 72 context and requirements. [VERIFIED: 72-CONTEXT.md; REQUIREMENTS.md]
- Example-host route strategy: MEDIUM - no-host-change requirement is clear, but existing `_brand_book` mismatch creates a planning decision. [VERIFIED: code probe; ASSUMED recommendation]
- Pitfalls: HIGH - based on local code probes and official docs. [VERIFIED: codebase; cited docs]

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 for codebase-local findings; re-check official Playwright/LiveView docs before Phase 73 because those tools are moving. [ASSUMED]
