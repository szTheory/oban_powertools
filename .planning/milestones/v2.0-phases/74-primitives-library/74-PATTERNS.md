# Phase 74: Primitives Library - Pattern Map

**Mapped:** 2026-07-10
**Files analyzed:** 20 source/artifact targets
**Analogs found:** 19 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/web/components/primitives.ex` | component | transform | `lib/oban_powertools/web/theme_shell.ex` + `test/support/test_layouts.ex` | role-match |
| `assets/oban_powertools/tokens.css` | config/style | transform | `assets/oban_powertools/tokens.css` | exact |
| `priv/static/oban_powertools/oban_powertools.css` | generated asset | file-I/O | `lib/mix/tasks/oban_powertools.assets.build.ex` | exact |
| `assets/oban_powertools/theme.js` | utility | event-driven | `assets/oban_powertools/theme.js` | exact |
| `priv/static/oban_powertools/oban_powertools.js` | generated asset | file-I/O | `lib/mix/tasks/oban_powertools.assets.build.ex` | exact |
| `test/support/primitive_story_catalog.ex` | service/test-support catalog | transform | `test/support/showcase_catalog.ex` | exact |
| `test/oban_powertools/primitive_story_catalog_test.exs` | test | transform | `test/oban_powertools/showcase_catalog_test.exs` | exact |
| `lib/oban_powertools/web/dev/showcase_live.ex` | route/live component | request-response | `lib/oban_powertools/web/dev/showcase_live.ex` | exact |
| `test/oban_powertools/web/live/showcase_live_test.exs` | test | request-response | `test/oban_powertools/web/live/showcase_live_test.exs` | exact |
| `scripts/showcase_manifest.exs` | script | batch/transform | `scripts/showcase_manifest.exs` | exact |
| `test/browser/support/manifest.ts` | utility | validation/transform | `test/browser/support/manifest.ts` | exact |
| `test/browser/support/manifest-smoke.mjs` | utility/test | validation/transform | `test/browser/support/manifest-smoke.mjs` | exact |
| `test/browser/support/showcase.ts` | browser utility | request-response | `test/browser/support/showcase.ts` | exact |
| `test/browser/specs/showcase.vrt.spec.ts` | browser test | file-I/O | `test/browser/specs/showcase.vrt.spec.ts` | exact |
| `test/browser/specs/showcase.a11y.spec.ts` | browser test | request-response | `test/browser/specs/showcase.a11y.spec.ts` | exact |
| `test/browser/specs/primitives.behavior.spec.ts` | browser test | event-driven | `test/browser/specs/showcase.structure.spec.ts` + `test/browser/support/showcase.ts` | role-match |
| `test/oban_powertools/web/components/primitives_test.exs` | test | transform/file-I/O | `test/oban_powertools/web/theme_tokens_test.exs` + `test/oban_powertools/web/live/showcase_live_test.exs` | role-match |
| `test/oban_powertools/web/theme_tokens_test.exs` | test | file-I/O/validation | `test/oban_powertools/web/theme_tokens_test.exs` | exact |
| `test/oban_powertools/web/assets_test.exs` | test | file-I/O | `test/oban_powertools/web/assets_test.exs` | exact |
| `test/browser/__screenshots__/**/showcase/primitive-*/**/*.png` | test artifact | file-I/O | existing `test/browser/__screenshots__/**/showcase/*.png` | artifact-match |

## Pattern Assignments

### `lib/oban_powertools/web/components/primitives.ex` (component, transform)

**Analog:** `lib/oban_powertools/web/theme_shell.ex`

**Component import and attr pattern** (lines 1-11):
```elixir
defmodule ObanPowertools.Web.ThemeShell do
  @moduledoc false

  use Phoenix.Component

  alias ObanPowertools.Web.Assets

  attr(:inner_content, :any, required: true)

  def live(assigns) do
    ~H"""
```

**Scoped render pattern** (lines 12-24):
```elixir
<link phx-track-static rel="stylesheet" href={Assets.path(:css)} />
<div
  id="oban-powertools"
  class="obpt-root"
  data-obpt-theme="system"
  data-obpt-effective-theme="light"
  data-obpt-motion="safe"
>
  <script type="text/javascript" src={Assets.path(:js)}></script>
  <main class="obpt-shell" data-obpt-shell>
    <%= @inner_content %>
  </main>
</div>
```

**Test component analog** (`test/support/test_layouts.ex` lines 1-12):
```elixir
defmodule ObanPowertools.TestLayouts do
  use Phoenix.Component

  attr(:inner_content, :any, required: true)

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <body><%= @inner_content %></body>
    </html>
    """
```

**Proof-seam class/tone pattern** (`lib/oban_powertools/web/jobs_live.ex` lines 453-455, 808-810, 1097-1107):
```elixir
<span class="obpt-badge" data-obpt-tone={state_badge_tone(@job.state)}>
  <%= @job.state %>
</span>

<span class="obpt-badge" data-obpt-tone={state_badge_tone(job.state)}>
  <%= job.state %>
</span>

defp state_tab_class(true), do: "obpt-tab obpt-tab--active"
defp state_tab_class(false), do: "obpt-tab"

defp state_badge_tone("executing"), do: "info"
defp state_badge_tone("retryable"), do: "warning"
defp state_badge_tone("discarded"), do: "danger"
defp state_badge_tone("completed"), do: "success"
defp state_badge_tone(_), do: "neutral"

defp preview_confirm_button_class("job_retry"), do: "obpt-button obpt-button--primary"
defp preview_confirm_button_class(_), do: "obpt-button obpt-button--danger"
```

**Planner notes:** There is no local component module with `slot/3`, closed `:values`, or filtered `:global` rest attrs. Use the local `use Phoenix.Component` and `~H` shape above, then apply the Phoenix.Component contract and rest-filtering pattern from `74-RESEARCH.md`.

---

### `assets/oban_powertools/tokens.css` (config/style, transform)

**Analog:** `assets/oban_powertools/tokens.css`

**Token-only foundation pattern** (lines 67-99):
```css
--obpt-font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
--obpt-font-mono: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", "DejaVu Sans Mono", monospace;
--obpt-font-size-xs: 0.75rem;
--obpt-font-size-sm: 0.8125rem;
--obpt-font-size-md: 0.875rem;
--obpt-font-size-lg: 1rem;
--obpt-font-size-xl: 1.125rem;
--obpt-line-height-tight: 1.25;
--obpt-line-height-base: 1.4286;
--obpt-line-height-relaxed: 1.6;
--obpt-font-weight-regular: 400;
--obpt-font-weight-medium: 500;
--obpt-font-weight-semibold: 600;
--obpt-numeric-tabular: tabular-nums;
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
--obpt-shadow-overlay: 0 20px 40px rgb(15 23 42 / 18%);
--obpt-shadow-focus: 0 0 0 3px var(--obpt-color-focus);
--obpt-motion-duration-instant: 1ms;
--obpt-motion-duration-fast: 120ms;
--obpt-motion-duration-base: 180ms;
--obpt-motion-duration-slow: 240ms;
--obpt-motion-ease-standard: cubic-bezier(0.2, 0, 0, 1);
--obpt-motion-ease-enter: cubic-bezier(0, 0, 0.2, 1);
--obpt-motion-ease-exit: cubic-bezier(0.4, 0, 1, 1);
```

**Semantic color role pattern** (lines 101-136):
```css
--obpt-color-surface: var(--obpt-palette-white);
--obpt-color-elevated: var(--obpt-palette-slate-50);
--obpt-color-overlay: var(--obpt-palette-white);
--obpt-color-border: var(--obpt-palette-slate-300);
--obpt-color-border-strong: var(--obpt-palette-slate-600);
--obpt-color-text: var(--obpt-palette-slate-900);
--obpt-color-muted: var(--obpt-palette-slate-600);
--obpt-color-subtle: var(--obpt-palette-slate-700);
--obpt-color-focus: var(--obpt-palette-indigo-600);
--obpt-color-accent-fg: var(--obpt-palette-indigo-800);
--obpt-color-accent-bg: var(--obpt-palette-indigo-50);
--obpt-color-accent-border: var(--obpt-palette-indigo-300);
--obpt-color-accent-solid: var(--obpt-palette-indigo-600);
--obpt-color-info-fg: var(--obpt-palette-cyan-800);
--obpt-color-info-bg: var(--obpt-palette-cyan-50);
--obpt-color-info-border: var(--obpt-palette-cyan-300);
--obpt-color-success-fg: var(--obpt-palette-emerald-800);
--obpt-color-success-bg: var(--obpt-palette-emerald-50);
--obpt-color-warning-fg: var(--obpt-palette-amber-900);
--obpt-color-danger-fg: var(--obpt-palette-red-800);
```

**Reduced-motion token pattern** (lines 353-360):
```css
@media (prefers-reduced-motion: reduce) {
  .obpt-root,
  .obpt-root[data-obpt-motion="reduce"] {
    --obpt-motion-duration-fast: var(--obpt-motion-duration-instant);
    --obpt-motion-duration-base: var(--obpt-motion-duration-instant);
    --obpt-motion-duration-slow: var(--obpt-motion-duration-instant);
  }
}
```

**Badge/status tone pattern** (lines 388-429):
```css
.obpt-root .obpt-badge {
  display: inline-flex;
  align-items: center;
  gap: var(--obpt-space-1);
  border: 1px solid var(--obpt-badge-border, var(--obpt-color-border));
  border-radius: var(--obpt-radius-sm);
  background: var(--obpt-badge-bg, var(--obpt-color-elevated));
  color: var(--obpt-badge-fg, var(--obpt-color-muted));
  padding: var(--obpt-space-1) var(--obpt-space-2);
  font-size: var(--obpt-font-size-xs);
  font-weight: var(--obpt-font-weight-semibold);
}

.obpt-root .obpt-badge[data-obpt-tone="warning"] {
  --obpt-badge-bg: var(--obpt-color-warning-bg);
  --obpt-badge-fg: var(--obpt-color-warning-fg);
  --obpt-badge-border: var(--obpt-color-warning-border);
}
```

**Focus and button pattern** (lines 479-529):
```css
.obpt-root .obpt-input:focus-visible,
.obpt-root .obpt-button:focus-visible,
.obpt-root .obpt-tab:focus-visible {
  outline: 2px solid var(--obpt-color-focus);
  outline-offset: 2px;
}

.obpt-root .obpt-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--obpt-space-1);
  border: 1px solid transparent;
  border-radius: var(--obpt-radius-md);
  padding: var(--obpt-space-2) var(--obpt-space-4);
  font-size: var(--obpt-font-size-sm);
  font-weight: var(--obpt-font-weight-semibold);
  transition: background-color var(--obpt-motion-duration-fast) var(--obpt-motion-ease-standard), border-color var(--obpt-motion-duration-fast) var(--obpt-motion-ease-standard);
}

.obpt-root .obpt-button--primary {
  border-color: var(--obpt-color-accent-solid);
  background: var(--obpt-color-accent-solid);
  color: var(--obpt-color-accent-solid-fg);
}
```

**Responsive showcase cell pattern** (lines 673-688, 821-833):
```css
.obpt-root .obpt-showcase-token-grid,
.obpt-root .obpt-showcase-open-targets,
.obpt-root .obpt-showcase-story-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(14rem, 1fr));
  gap: var(--obpt-space-3);
}

.obpt-root .obpt-showcase-token,
.obpt-root .obpt-showcase-open-target,
.obpt-root .obpt-showcase-story {
  border: 1px solid var(--obpt-color-border);
  border-radius: var(--obpt-radius-md);
  background: var(--obpt-color-elevated);
  padding: var(--obpt-space-4);
}

@media (max-width: 48rem) {
  .obpt-root .obpt-showcase {
    padding: var(--obpt-space-4);
  }

  .obpt-root .obpt-showcase-fixture-index-row {
    grid-template-columns: 1fr;
  }
}
```

---

### `priv/static/oban_powertools/oban_powertools.css` and `priv/static/oban_powertools/oban_powertools.js` (generated assets, file-I/O)

**Analog:** `lib/mix/tasks/oban_powertools.assets.build.ex`

**Source-to-static copy pattern** (lines 10-35):
```elixir
@source_dir "assets/oban_powertools"
@static_dir "priv/static/oban_powertools"

@impl Mix.Task
def run(_args) do
  File.mkdir_p!(@static_dir)

  copy_normalized(
    Path.join(@source_dir, "tokens.css"),
    Path.join(@static_dir, "oban_powertools.css")
  )

  copy_normalized(
    Path.join(@source_dir, "theme.js"),
    Path.join(@static_dir, "oban_powertools.js")
  )

  Mix.shell().info("Built Oban Powertools assets in #{@static_dir}")
end

defp copy_normalized(source, destination) do
  source
  |> File.read!()
  |> normalize()
  |> then(&File.write!(destination, &1))
end
```

**Asset stability test pattern** (`test/oban_powertools/web/assets_test.exs` lines 50-80):
```elixir
test "compiled assets are byte stable across repeated build task runs" do
  assert Code.ensure_loaded?(Mix.Tasks.ObanPowertools.Assets.Build),
         "expected mix oban_powertools.assets.build task to be loadable"

  Mix.Task.rerun("oban_powertools.assets.build", [])
  first = static_sha256s()

  Mix.Task.rerun("oban_powertools.assets.build", [])
  second = static_sha256s()

  assert first == second
end

defp static_sha256s do
  for path <- [@css_static, @js_static], into: %{} do
    assert File.exists?(path), "expected #{path} to exist after asset build"
    {path, :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)}
  end
end
```

---

### `assets/oban_powertools/theme.js` (utility, event-driven)

**Analog:** `assets/oban_powertools/theme.js`

**Scoped IIFE constants pattern** (lines 1-12):
```javascript
(() => {
  const STORAGE_KEY = "oban_powertools:theme";
  const THEMES = new Set(["system", "light", "dark", "high-contrast"]);
  const ATTR_THEME = "data-obpt-theme";
  const ATTR_EFFECTIVE_THEME = "data-obpt-effective-theme";
  const ATTR_MOTION = "data-obpt-motion";
  const ROOT_SELECTOR = ".obpt-root";

  const colorPreference = window.matchMedia("(prefers-color-scheme: dark)");
  const contrastPreference = window.matchMedia("(prefers-contrast: more)");
  const motionPreference = window.matchMedia("(prefers-reduced-motion: reduce)");
```

**Root-scoped apply pattern** (lines 39-48):
```javascript
function apply(root, theme = storedTheme()) {
  if (!root || !root.matches || !root.matches(ROOT_SELECTOR)) {
    return;
  }

  const requestedTheme = normalizeTheme(theme);
  root.setAttribute(ATTR_THEME, requestedTheme);
  root.setAttribute(ATTR_EFFECTIVE_THEME, effectiveTheme(requestedTheme));
  root.setAttribute(ATTR_MOTION, motionPreference.matches ? "reduce" : "safe");
}
```

**Delegated event pattern** (lines 94-100):
```javascript
document.addEventListener("click", (event) => {
  const control = event.target.closest("[data-obpt-theme-choice]");

  if (control) {
    setTheme(control.getAttribute("data-obpt-theme-choice"));
  }
});
```

**Public namespace pattern** (lines 102-107):
```javascript
window.ObanPowertoolsTheme = {
  apply,
  setTheme,
  storedTheme,
  effectiveTheme
};
```

**Planner notes:** Add tooltip Escape/focus behavior in the same dependency-free IIFE style. Keep selectors scoped with `data-obpt-*` and avoid `document.documentElement` or global class toggles.

---

### `test/support/primitive_story_catalog.ex` (test-support catalog, transform)

**Analog:** `test/support/showcase_catalog.ex`

**Module contract pattern** (lines 1-7):
```elixir
defmodule ObanPowertools.ShowcaseCatalog do
  @moduledoc """
  Deterministic dev/test scenario catalog for the Powertools showcase.

  The scenario IDs and targets are public contracts for ExUnit, future VRT
  snapshots, and accessibility scans. Keep values constant and synthetic.
  """
```

**Story map shape pattern** (lines 46-83):
```elixir
@scenarios [
  %{
    id: "overview-operational-empty",
    domain: :overview,
    name: "Operational overview with no active pressure",
    persona: :triage,
    jtbd: "Confirm the control plane is empty before starting an incident triage pass.",
    states: [:empty],
    fixtures: %{
      headline: "No active work requires attention",
      summary: %{
        queues: 0,
        running_jobs: 0,
        retryable_jobs: 0
      }
    },
    test_targets: %{
      story: "obpt-story-overview-operational-empty",
      snapshot: "showcase/overview-operational-empty",
      a11y: ~s([data-obpt-story="overview-operational-empty"])
    }
  }
]
```

**Lookup/helper pattern** (lines 405-437):
```elixir
@scenarios_by_id Map.new(@scenarios, &{Map.fetch!(&1, :id), &1})

def scenarios, do: @scenarios

def scenario!(id) when is_binary(id) do
  Map.fetch!(@scenarios_by_id, id)
rescue
  KeyError ->
    raise ArgumentError, "unknown showcase scenario: #{inspect(id)}"
end

def snapshot_name(id) when is_binary(id) do
  "showcase/#{scenario!(id).id}"
end

def a11y_target(id) when is_binary(id) do
  ~s([data-obpt-story="#{scenario!(id).id}"])
end
```

**Planner notes:** Keep primitive stories separate from `ShowcaseCatalog.scenarios/0`. Use fields like `kind`, `component`, `variant`, `state`, `snapshot`, and `a11y`, but copy the deterministic ID/helper style above.

---

### `test/oban_powertools/primitive_story_catalog_test.exs` (test, transform)

**Analog:** `test/oban_powertools/showcase_catalog_test.exs`

**Determinism and slug contract pattern** (lines 78-95):
```elixir
describe "D-02 stable scenario identifiers and test targets" do
  test "scenarios/0 is deterministic and exposes unique slug IDs" do
    scenarios = ShowcaseCatalog.scenarios()
    repeated_scenarios = ShowcaseCatalog.scenarios()
    ids = Enum.map(scenarios, &scenario_field!(&1, :id))

    assert scenarios == repeated_scenarios,
           "D-04/D-13 require scenarios/0 to be deterministic across repeated calls"

    assert ids == Enum.uniq(ids),
           "D-02 requires every scenario ID to be unique"

    assert Enum.all?(ids, &(&1 =~ ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/)),
           "D-02 requires slug-like scenario IDs for stable selectors and snapshots"
```

**Target derivation pattern** (lines 111-133):
```elixir
test "snapshot_name/1 and a11y_target/1 derive from scenario ID instead of display copy" do
  Enum.each(ShowcaseCatalog.scenarios(), fn scenario ->
    id = scenario_field!(scenario, :id)
    name = scenario_field!(scenario, :name)
    expected_snapshot_name = "showcase/#{id}"
    expected_a11y_target = ~s([data-obpt-story="#{id}"])
    test_targets = scenario_field!(scenario, :test_targets)

    assert ShowcaseCatalog.scenario!(id) |> scenario_field!(:id) == id,
           "D-02 requires scenario!/1 to fetch scenarios by stable ID"

    assert ShowcaseCatalog.snapshot_name(id) == expected_snapshot_name,
           "D-02 requires snapshot names to derive from #{id}, not display copy #{inspect(name)}"

    assert ShowcaseCatalog.a11y_target(id) == expected_a11y_target,
           "D-02 requires a11y targets to derive from #{id}, not display copy #{inspect(name)}"
```

**Generic map/struct field helpers** (lines 176-215):
```elixir
defp scenario_field!(scenario, key) do
  scenario
  |> scenario_map()
  |> Map.fetch!(key)
rescue
  KeyError ->
    flunk("D-01 requires every scenario to contain #{inspect(key)}")
end

defp scenario_map(%_{} = struct), do: Map.from_struct(struct)
defp scenario_map(%{} = map), do: map

defp normalize_value(value) when is_atom(value), do: Atom.to_string(value)
defp normalize_value(value) when is_binary(value), do: value
defp normalize_value(value), do: inspect(value)
```

---

### `lib/oban_powertools/web/dev/showcase_live.ex` (route/live component, request-response)

**Analog:** `lib/oban_powertools/web/dev/showcase_live.ex`

**Dev-only module and runtime support catalog pattern** (lines 1-19):
```elixir
# Dev-only module guard: defined only when dev_routes is enabled at the host's
# compile time (dev/test). In production builds this file defines no fallback
# module, so the route and LiveView stay absent together.
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) or
     System.get_env("MIX_ENV", "dev") == "dev" do
  defmodule ObanPowertools.Web.Dev.ShowcaseLive do
    @moduledoc """
    Dev-only LiveView for the deterministic Powertools showcase skeleton.
    """

    use Phoenix.LiveView

    @catalog_module ObanPowertools.ShowcaseCatalog
    @catalog_path Path.expand("../../../../test/support/showcase_catalog.ex", __DIR__)
```

**Mount assigns pattern** (lines 50-64):
```elixir
@impl Phoenix.LiveView
def mount(_params, _session, socket) do
  catalog = load_catalog()

  {:ok,
   socket
   |> assign(:page_title, "Powertools Showcase")
   |> assign(:theme_choices, @theme_choices)
   |> assign(:viewport_choices, @viewport_choices)
   |> assign(:selected_viewport, "wide")
   |> assign(:sections, @section_list)
   |> assign(:open_state_targets, @open_state_targets)
   |> assign(:catalog_available?, catalog.available?)
   |> assign(:catalog_scenarios, catalog.scenarios)
   |> assign(:catalog_domains, catalog.domains)}
end
```

**Stable control attributes pattern** (lines 92-127):
```elixir
<section class="obpt-showcase-controls" aria-label="Showcase controls">
  <div class="obpt-showcase-control-group" data-obpt-theme-controls>
    <h2>Theme</h2>
    <div class="obpt-showcase-segmented">
      <button
        :for={theme <- @theme_choices}
        type="button"
        class="obpt-button obpt-button--neutral"
        data-obpt-theme-choice={theme.value}
      >
        {theme.label}
      </button>
    </div>
  </div>

  <div class="obpt-showcase-control-group">
    <h2>Viewport</h2>
    <div class="obpt-showcase-segmented">
      <button
        :for={viewport <- @viewport_choices}
        type="button"
        class={[
          "obpt-button",
          if(@selected_viewport == viewport.value,
            do: "obpt-button--primary",
            else: "obpt-button--neutral"
          )
        ]}
        phx-click="select_viewport"
        phx-value-viewport={viewport.value}
        aria-pressed={@selected_viewport == viewport.value}
        data-obpt-viewport={viewport.value}
      >
```

**Section and story cell pattern** (lines 137-172, 243-272):
```elixir
<div class={"obpt-showcase-canvas obpt-showcase-canvas--#{@selected_viewport}"}>
  <section
    :for={section <- @sections}
    id={section.id}
    class="obpt-showcase-section"
    data-obpt-section={section.id}
  >
    <header>
      <p class="obpt-showcase-eyebrow">Section</p>
      <h2>{section.title}</h2>
    </header>

    <%= if section.id == "tokens" do %>
      <div class="obpt-showcase-token-grid">
        <div class="obpt-showcase-token" data-obpt-tone="accent">
          <span>Accent</span>
          <strong>Safe action</strong>
        </div>
      </div>
    <% else %>
      <p class="obpt-showcase-placeholder">
        Reserved for Phase-owned stories. The anchor and selector are stable now.
      </p>
    <% end %>
  </section>

  <div class="obpt-showcase-story-grid">
    <article
      :for={scenario <- @catalog_scenarios}
      id={"obpt-story-#{scenario.id}"}
      class="obpt-showcase-story"
      data-obpt-story={scenario.id}
      data-obpt-domain={stringify(scenario.domain)}
      data-obpt-persona={story_persona(scenario)}
      data-obpt-state={state_value(scenario.states)}
    >
```

**Runtime catalog load pattern** (lines 280-311):
```elixir
defp load_catalog do
  with {:ok, module} <- ensure_catalog_module(),
       true <- function_exported?(module, :scenarios, 0),
       true <- function_exported?(module, :domains, 0) do
    %{
      available?: true,
      scenarios: apply(module, :scenarios, []),
      domains: apply(module, :domains, [])
    }
  else
    _ -> %{available?: false, scenarios: [], domains: []}
  end
end

defp ensure_catalog_module do
  cond do
    Code.ensure_loaded?(@catalog_module) ->
      {:ok, @catalog_module}

    Mix.env() != :test and File.exists?(@catalog_path) ->
      Code.require_file(@catalog_path)
```

---

### `test/oban_powertools/web/live/showcase_live_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/web/live/showcase_live_test.exs`

**Dev-route gated LiveCase pattern** (lines 1-7):
```elixir
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  defmodule ObanPowertools.Web.Dev.ShowcaseLiveTest do
    use ObanPowertools.LiveCase, async: true
```

**Stable selector assertions pattern** (lines 40-84):
```elixir
test "renders the showcase through the Powertools theme shell", %{conn: conn} do
  {:ok, _view, html} = mount_showcase!(conn)

  assert count(html, "obpt-root") == 1
  assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.css|
  assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.js|
  assert html =~ "data-obpt-showcase"
end

test "future showcase sections reserve stable anchors", %{conn: conn} do
  {:ok, _view, html} = mount_showcase!(conn)

  assert_attribute_values(html, "data-obpt-section", @section_ids)
end

test "story cells expose stable scenario metadata", %{conn: conn} do
  {:ok, view, html} = mount_showcase!(conn)

  assert_attribute_values(html, "data-obpt-story", Enum.map(@story_contracts, & &1.id))

  for %{id: id, domain: domain, persona: persona} <- @story_contracts do
    assert has_element?(
             view,
             "[data-obpt-story='#{id}'][data-obpt-domain='#{domain}'][data-obpt-persona='#{persona}'][data-obpt-state]"
           )
  end
end
```

**Route verification helper pattern** (lines 90-103):
```elixir
defp mount_showcase!(conn) do
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

  live(conn, "/ops/jobs/_showcase")
end
```

---

### `scripts/showcase_manifest.exs` (script, batch/transform)

**Analog:** `scripts/showcase_manifest.exs`

**Manifest generation pattern** (lines 1-35):
```elixir
alias ObanPowertools.ShowcaseCatalog

themes = ["system", "light", "dark", "high-contrast"]

viewports = [
  %{name: "320", width: 320, height: 900},
  %{name: "tablet", width: 768, height: 1000},
  %{name: "wide", width: 1440, height: 1000}
]

scenarios =
  ShowcaseCatalog.scenarios()
  |> Enum.map(fn scenario ->
    id = Map.fetch!(scenario, :id)
    test_targets = Map.fetch!(scenario, :test_targets)

    %{
      id: id,
      domain: scenario.domain |> Atom.to_string(),
      persona: scenario.persona |> Atom.to_string(),
      states: Enum.map(scenario.states, &Atom.to_string/1),
      story: Map.fetch!(test_targets, :story),
      snapshot: ShowcaseCatalog.snapshot_name(id),
      a11y: ShowcaseCatalog.a11y_target(id)
    }
  end)

manifest = %{
  schema_version: 1,
  themes: themes,
  viewports: viewports,
  scenarios: scenarios
}

IO.write(Jason.encode!(manifest))
```

**Planner notes:** Extend this, do not duplicate target IDs in TypeScript. Preferred shape: keep `scenarios`, add `primitive_stories`, bump schema if needed, and emit a unified `targets` list or enough metadata for TypeScript to derive one.

---

### `test/browser/support/manifest.ts` and `test/browser/support/manifest-smoke.mjs` (utility/test, validation/transform)

**Analog:** `test/browser/support/manifest.ts`

**Type and path pattern** (lines 1-36):
```typescript
import fs from 'node:fs';
import path from 'node:path';

const manifestPath = path.join(process.cwd(), 'test/browser/.generated/showcase-manifest.json');
const allowedThemes = ['system', 'light', 'dark', 'high-contrast'] as const;
const expectedViewports = [
  { name: '320', width: 320, height: 900 },
  { name: 'tablet', width: 768, height: 1000 },
  { name: 'wide', width: 1440, height: 1000 }
] as const;

export type ShowcaseTheme = (typeof allowedThemes)[number];
export type ViewportName = (typeof expectedViewports)[number]['name'];

export type ShowcaseScenario = {
  id: string;
  domain: string;
  persona: string;
  states: string[];
  story: string;
  snapshot: string;
  a11y: string;
};
```

**Runtime validator pattern** (lines 49-103):
```typescript
function validateManifest(value: unknown, filePath: string): ShowcaseManifest {
  const manifest = assertRecord(value, filePath);

  assertEqual(manifest.schema_version, 1, 'schema_version');

  const themes = assertStringArray(manifest.themes, 'themes') as ShowcaseTheme[];
  assertExactList(themes, [...allowedThemes], 'themes');

  const viewports = assertArray(manifest.viewports, 'viewports').map((viewport, index) => {
    const expected = expectedViewports[index];
    const actual = assertRecord(viewport, `viewports[${index}]`);

    assertEqual(actual.name, expected.name, `viewports[${index}].name`);
    assertEqual(actual.width, expected.width, `viewports[${index}].width`);
    assertEqual(actual.height, expected.height, `viewports[${index}].height`);

    return actual as ShowcaseViewport;
  });

  const scenarios = assertArray(manifest.scenarios, 'scenarios').map((scenario, index) => {
    const actual = assertRecord(scenario, `scenarios[${index}]`);
    const id = assertString(actual.id, `scenarios[${index}].id`);

    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
      throw new Error(`scenarios[${index}].id must be a slug-like identifier`);
    }

    const story = assertString(actual.story, `scenarios[${index}].story`);
    const snapshot = assertString(actual.snapshot, `scenarios[${index}].snapshot`);
    const a11y = assertString(actual.a11y, `scenarios[${index}].a11y`);

    assertEqual(story, `obpt-story-${id}`, `scenarios[${index}].story`);
    assertEqual(snapshot, `showcase/${id}`, `scenarios[${index}].snapshot`);
    assertEqual(a11y, `[data-obpt-story="${id}"]`, `scenarios[${index}].a11y`);
```

**Export pattern** (lines 154-157):
```typescript
export const manifest = loadManifest();
export const themes = manifest.themes;
export const viewports = manifest.viewports;
export const scenarios = manifest.scenarios;
```

**Smoke validator analog** (`test/browser/support/manifest-smoke.mjs` lines 62-100):
```javascript
const manifest = loadManifest();

equal(manifest.schema_version, 1, 'schema_version');
exactList(array(manifest.themes, 'themes'), expectedThemes, 'themes');

const scenarios = array(manifest.scenarios, 'scenarios');
equal(scenarios.length, 9, 'scenarios.length');

for (const [index, scenario] of scenarios.entries()) {
  const actual = record(scenario, `scenarios[${index}]`);
  const id = string(actual.id, `scenarios[${index}].id`);
  const states = array(actual.states, `scenarios[${index}].states`);

  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
    fail(`scenarios[${index}].id must be a slug-like identifier`);
  }

  string(actual.domain, `scenarios[${index}].domain`);
  string(actual.persona, `scenarios[${index}].persona`);
  equal(states.length > 0, true, `scenarios[${index}].states non-empty`);
  equal(actual.story, `obpt-story-${id}`, `scenarios[${index}].story`);
  equal(actual.snapshot, `showcase/${id}`, `scenarios[${index}].snapshot`);
  equal(actual.a11y, `[data-obpt-story="${id}"]`, `scenarios[${index}].a11y`);
}
```

---

### `test/browser/support/showcase.ts` (browser utility, request-response)

**Analog:** `test/browser/support/showcase.ts`

**Showcase preparation pattern** (lines 29-70):
```typescript
export async function prepareShowcase(
  page: Page,
  opts: { theme: ShowcaseTheme; viewportName: ViewportName }
): Promise<void> {
  await page.emulateMedia({ colorScheme: 'light', reducedMotion: 'reduce' });
  await page.goto('/ops/jobs/_showcase');

  const root = page.locator('.obpt-root');
  await expect(root).toHaveCount(1);

  const themeApplied = await page.evaluate((theme) => {
    if (window.ObanPowertoolsTheme?.setTheme) {
      window.ObanPowertoolsTheme.setTheme(theme);
      return true;
    }

    return false;
  }, opts.theme);

  if (!themeApplied) {
    await page.locator(`[data-obpt-theme-choice="${opts.theme}"]`).click();
  }

  await expect(root).toHaveAttribute('data-obpt-theme', opts.theme);
  await expect(root).toHaveAttribute(
    'data-obpt-effective-theme',
    opts.theme === 'system' ? 'light' : opts.theme
  );

  const viewportControl = page.locator(`[data-obpt-viewport="${opts.viewportName}"]`);
  await expect(viewportControl).toHaveCount(1);
  await viewportControl.click();

  await page.waitForLoadState('networkidle');
  await page.evaluate(() => document.fonts.ready);
}
```

**Locator/structure pattern** (lines 72-105):
```typescript
export function storyLocator(page: Page, scenario: ShowcaseScenario): Locator {
  return page.locator(scenario.a11y);
}

export async function assertShowcaseStructure(page: Page): Promise<void> {
  await expect(page.locator('.obpt-root')).toHaveCount(1);
  await expect(page.locator('[data-obpt-showcase]')).toHaveCount(1);

  for (const theme of themes) {
    await expect(page.locator(`[data-obpt-theme-choice="${theme}"]`)).toHaveCount(1);
  }

  for (const viewport of viewports) {
    await expect(page.locator(`[data-obpt-viewport="${viewport.name}"]`)).toHaveCount(1);
  }

  for (const sectionId of sectionIds) {
    await expect(page.locator(`[data-obpt-section="${sectionId}"]`)).toHaveCount(1);
    await expect(page.locator(`a[href="#${sectionId}"]`)).toHaveCount(1);
  }

  for (const scenario of scenarios) {
    await expect(storyLocator(page, scenario)).toHaveCount(1);
  }
}
```

---

### `test/browser/specs/showcase.vrt.spec.ts` (browser test, file-I/O)

**Analog:** `test/browser/specs/showcase.vrt.spec.ts`

**Screenshot matrix pattern** (lines 1-19):
```typescript
import { expect, test } from '@playwright/test';
import { scenarios, themes } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { prepareShowcase, storyLocator } from '../support/showcase';

for (const theme of themes) {
  test.describe(`showcase vrt ${theme}`, () => {
    for (const scenario of scenarios) {
      test(`${scenario.id}`, async ({ page }, testInfo) => {
        const viewportName = viewportNameFromProject(testInfo.project.name);
        const story = storyLocator(page, scenario);

        await prepareShowcase(page, { theme, viewportName });
        await expect(story).toBeVisible();
        await expect(story).toHaveScreenshot([scenario.snapshot, `${theme}.png`]);
      });
    }
  });
}
```

**Planner notes:** Rename loop variable to `target` or export unified `targets` so primitive stories and catalog scenarios use the same screenshot path contract.

---

### `test/browser/specs/showcase.a11y.spec.ts` (browser test, request-response)

**Analog:** `test/browser/specs/showcase.a11y.spec.ts`

**Axe target matrix pattern** (lines 1-23):
```typescript
import { expect, test } from '@playwright/test';
import { scenarios, themes } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { assertNoCriticalOrSerious, runAxeForTarget, writeAxeResult } from '../support/axe';
import { prepareShowcase, storyLocator } from '../support/showcase';

for (const theme of themes) {
  test.describe(`showcase axe ${theme}`, () => {
    for (const scenario of scenarios) {
      test(`${scenario.id}`, async ({ page }, testInfo) => {
        const viewportName = viewportNameFromProject(testInfo.project.name);
        const resultName = `${theme}-${scenario.id}`;

        await prepareShowcase(page, { theme, viewportName });
        await expect(storyLocator(page, scenario)).toBeVisible();

        const results = await runAxeForTarget(page, scenario.a11y);
        await writeAxeResult(testInfo, resultName, results);
        assertNoCriticalOrSerious(results, resultName);
      });
    }
  });
}
```

**Axe helper pattern** (`test/browser/support/axe.ts` lines 11-24, 43-54):
```typescript
export async function runAxeForTarget(page: Page, selector: string): Promise<AxeResults> {
  return new AxeBuilder({ page })
    .include(selector)
    .options({
      runOnly: {
        type: 'tag',
        values: [...axeTags]
      },
      rules: {
        'target-size': { enabled: true }
      },
      resultTypes: [...resultTypes]
    })
    .analyze();
}

export function assertNoCriticalOrSerious(results: AxeResults, name: string): void {
  const blockingViolations = results.violations.filter((violation) =>
    blockingImpacts.has(violation.impact ?? '')
  );

  if (blockingViolations.length === 0) {
    return;
  }

  const summary = blockingViolations.map(formatViolation).join('\n\n');
  throw new Error(`${name} has critical/serious axe violations:\n\n${summary}`);
}
```

---

### `test/browser/specs/primitives.behavior.spec.ts` (browser test, event-driven)

**Analog:** `test/browser/specs/showcase.structure.spec.ts` plus `test/browser/support/showcase.ts`

**Structure spec import and preparation pattern** (`showcase.structure.spec.ts` lines 1-15):
```typescript
import { expect, test } from '@playwright/test';
import { scenarios, themes } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { assertShowcaseStructure, prepareShowcase, storyLocator } from '../support/showcase';

for (const theme of themes) {
  test(`showcase structure is stable for ${theme}`, async ({ page }, testInfo) => {
    const viewportName = viewportNameFromProject(testInfo.project.name);

    await prepareShowcase(page, { theme, viewportName });
    await assertShowcaseStructure(page);
```

**Targeted attribute assertion pattern** (`showcase.structure.spec.ts` lines 17-25):
```typescript
for (const scenario of scenarios) {
  const story = storyLocator(page, scenario);

  await expect(story).toBeVisible();
  await expect(story).toHaveAttribute('id', scenario.story);
  await expect(story).toHaveAttribute('data-obpt-domain', scenario.domain);
  await expect(story).toHaveAttribute('data-obpt-persona', renderedPersona(scenario));
  await expect(story).toHaveAttribute('data-obpt-state', /.+/);
}
```

**Planner notes:** No exact local Playwright interaction spec exists for tooltip Escape, accessible names, or overflow checks. Use this role-match structure and the `prepareShowcase` helper, then add direct assertions with Playwright locators: `toHaveAccessibleName`, `toBeFocused`, `keyboard.press('Escape')`, viewport overflow checks, and `page.emulateMedia({ reducedMotion: 'reduce' })`.

---

### `test/oban_powertools/web/components/primitives_test.exs` (test, transform/file-I/O)

**Analog:** `test/oban_powertools/web/theme_tokens_test.exs` plus `test/oban_powertools/web/live/showcase_live_test.exs`

**Static token contract style** (`theme_tokens_test.exs` lines 55-82):
```elixir
test "token source exists and declares the Phase 70 primitive and semantic contract" do
  css = read_contract_file!(@tokens_path)
  vars = variables_for(css, ".obpt-root")

  for prefix <- @primitive_prefixes do
    assert has_variable_prefix?(vars, prefix), "missing primitive token category #{prefix}"
  end

  for role <- @semantic_roles do
    assert Map.has_key?(vars, role), "missing semantic token #{role}"
  end

  for prefix <- @foundation_prefixes do
    assert has_variable_prefix?(vars, prefix), "missing foundation token category #{prefix}"
  end

  assert Map.has_key?(vars, "--obpt-font-sans")
  assert Map.has_key?(vars, "--obpt-font-mono")
  assert Map.has_key?(vars, "--obpt-numeric-tabular")
end
```

**No host leakage style** (`theme_tokens_test.exs` lines 84-103):
```elixir
test "token source is scoped to Powertools and rejects host-root leakage" do
  css = read_contract_file!(@tokens_path)

  assert css =~ ".obpt-root"
  assert css =~ ".obpt-shell"
  assert css =~ ".obpt-tab"
  assert css =~ ".obpt-tab--active"
  assert css =~ ".obpt-badge"
  assert css =~ ".obpt-modal-backdrop"
  assert css =~ ".obpt-modal"

  refute css =~ ~r/(^|})\s*:root\s*[{,]/m
  refute css =~ ~r/(^|})\s*html(\s|\.|#|\[|:|,|\{)/m
  refute css =~ ~r/(^|})\s*body(\s|\.|#|\[|:|,|\{)/m
  refute css =~ ~r/(^|})\s*\.dark(\s|\.|#|\[|:|,|\{)/m
  refute css =~ "document.documentElement"
end
```

**File parsing helpers** (`theme_tokens_test.exs` lines 195-232):
```elixir
defp read_contract_file!(path) do
  assert File.exists?(path),
         "expected #{path} to exist so Phase 71 token/theme contract can be validated"

  File.read!(path)
end

defp variables_for(css, selector_fragment) do
  css
  |> blocks_for(selector_fragment)
  |> Enum.flat_map(fn {_selector, body} -> declarations(body) end)
  |> Enum.filter(fn {property, _value} -> String.starts_with?(property, "--obpt-") end)
  |> Map.new()
end

defp blocks_for(css, selector_fragment) do
  Regex.scan(~r/([^{}]+)\{([^{}]+)\}/m, css, capture: :all_but_first)
  |> Enum.map(fn [selector, body] -> {String.trim(selector), body} end)
  |> Enum.filter(fn {selector, _body} -> String.contains?(selector, selector_fragment) end)
end

defp declarations(body) do
  Regex.scan(~r/([A-Za-z0-9_-]+|--obpt-[A-Za-z0-9_-]+)\s*:\s*([^;]+);/, body)
  |> Enum.map(fn [_match, property, value] -> {String.trim(property), String.trim(value)} end)
end
```

**LiveView selector assertion style** (`showcase_live_test.exs` lines 86-118):
```elixir
defp assert_attribute_values(html, attribute, expected_values) do
  assert Enum.sort(attribute_values(html, attribute)) == Enum.sort(expected_values)
end

defp attribute_values(html, attribute) do
  Regex.scan(Regex.compile!("#{Regex.escape(attribute)}=\"([^\"]+)\""), html,
    capture: :all_but_first
  )
  |> List.flatten()
end

defp count(html, needle) do
  html
  |> String.split(needle)
  |> length()
  |> Kernel.-(1)
end
```

**Planner notes:** There is no local direct component render helper. Introduce one in this test or use Phoenix.LiveViewTest component rendering. Keep assertions concrete: required labels, `aria-*`, `role="status"`, `class`/`style` rest filtering, no raw hex/px in primitive source, and token-backed class/data attributes only.

---

### `test/oban_powertools/web/theme_tokens_test.exs` (test, file-I/O/validation)

**Analog:** `test/oban_powertools/web/theme_tokens_test.exs`

**Motion and JS scope contract** (lines 159-193):
```elixir
test "motion and media preference hooks are centralized in the token layer" do
  css = read_contract_file!(@tokens_path)

  assert css =~ "@media (prefers-color-scheme: dark)"
  assert css =~ "@media (prefers-contrast: more)"
  assert css =~ "@media (prefers-reduced-motion: reduce)"
  assert css =~ ~s([data-obpt-motion="reduce"])
  assert css =~ "--obpt-motion-duration-fast"
  assert css =~ "--obpt-motion-duration-base"
  assert css =~ "--obpt-motion-ease-standard"
end

test "theme controller is root scoped, system-first, and namespaced" do
  js = read_contract_file!(@theme_path)

  assert js =~ "window.ObanPowertoolsTheme"
  assert js =~ "oban_powertools:theme"
  assert js =~ "data-obpt-theme"
  assert js =~ "data-obpt-effective-theme"
  assert js =~ "data-obpt-motion"
  assert js =~ "prefers-color-scheme"
  assert js =~ "prefers-contrast"
  assert js =~ "prefers-reduced-motion"

  refute js =~ "document.documentElement"
  refute js =~ ".classList"
  refute js =~ "oban:theme"
end
```

**Planner notes:** Extend this or create `primitives_test.exs` checks to reject raw visual values outside the token layer and caller-supplied `class`/`style` passthrough in primitive render output.

---

### `test/browser/__screenshots__/**/showcase/primitive-*/**/*.png` (test artifact, file-I/O)

**Analog:** Existing `test/browser/__screenshots__/chromium-{320,tablet,wide}/showcase/<scenario>/<theme>.png`

**Artifact pattern:** No code excerpt. Existing screenshot baselines use the Playwright `toHaveScreenshot([scenario.snapshot, `${theme}.png`])` path pattern from `test/browser/specs/showcase.vrt.spec.ts` lines 13-16:
```typescript
await prepareShowcase(page, { theme, viewportName });
await expect(story).toBeVisible();
await expect(story).toHaveScreenshot([scenario.snapshot, `${theme}.png`]);
```

**Planner notes:** Primitive baseline paths should be generated from primitive story `snapshot` metadata, not from a hand-written TypeScript array.

## Shared Patterns

### Authentication And Authorization

**Source:** `lib/oban_powertools/web/jobs_live.ex` lines 23-34, 210-232, 261-296
**Apply to:** Parent LiveViews only. Primitive components must not authorize, mutate, or own state.

```elixir
with {:ok, socket} <-
       LiveAuth.authorize_page(socket, permission, %{type: resource_type, id: resource_id}) do
  :ok = DisplayPolicy.assert_configured!()
  {:ok, socket |> assign(:oban_dashboard_path, dashboard_path) |> assign_defaults()}
else
  {:error, socket} -> {:ok, socket}
end
```

### Dev-Only Showcase Boundary

**Source:** `lib/oban_powertools/web/router.ex` lines 73-85
**Apply to:** Any primitive showcase integration.

```elixir
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) or
     System.get_env("MIX_ENV", "dev") == "dev" do
  if match?({:module, _}, Code.ensure_compiled(ObanPowertools.Web.Dev.BrandBookLive)) do
    live("/_brand_book", ObanPowertools.Web.Dev.BrandBookLive, :index)
  end

  if match?({:module, _}, Code.ensure_compiled(ObanPowertools.Web.Dev.ShowcaseLive)) do
    live("/_showcase", ObanPowertools.Web.Dev.ShowcaseLive, :index)
  end
end
```

### Theme Shell And Asset Boundary

**Source:** `lib/oban_powertools/web/theme_shell.ex` lines 12-24 and `lib/oban_powertools/web/assets.ex` lines 49-56
**Apply to:** All primitive rendering and browser tests.

```elixir
<link phx-track-static rel="stylesheet" href={Assets.path(:css)} />
<div id="oban-powertools" class="obpt-root" data-obpt-theme="system">
  <script type="text/javascript" src={Assets.path(:js)}></script>
  <main class="obpt-shell" data-obpt-shell>
    <%= @inner_content %>
  </main>
</div>

def path(:css), do: "/ops/jobs/_assets/oban_powertools-#{@css_hash}.css"
def path(:js), do: "/ops/jobs/_assets/oban_powertools-#{@js_hash}.js"
defp content_type(:css), do: "text/css; charset=utf-8"
defp content_type(:js), do: "text/javascript; charset=utf-8"
```

### Token-Only Styling

**Source:** `assets/oban_powertools/tokens.css` lines 479-529
**Apply to:** Primitive CSS and any source scan tests.

Use `.obpt-root .obpt-*` selectors, `var(--obpt-*)` values, `data-obpt-*` state/tone attributes, and existing focus/motion tokens. Raw palette values belong only in the token definition layer.

### Story Metadata

**Source:** `test/support/showcase_catalog.ex` lines 79-83 and 431-437
**Apply to:** Primitive story catalog, manifest, VRT, axe.

```elixir
test_targets: %{
  story: "obpt-story-overview-operational-empty",
  snapshot: "showcase/overview-operational-empty",
  a11y: ~s([data-obpt-story="overview-operational-empty"])
}

def snapshot_name(id) when is_binary(id) do
  "showcase/#{scenario!(id).id}"
end

def a11y_target(id) when is_binary(id) do
  ~s([data-obpt-story="#{scenario!(id).id}"])
end
```

### Browser Matrix

**Source:** `test/browser/support/showcase.ts` lines 29-70 and `test/browser/specs/showcase.vrt.spec.ts` lines 6-16
**Apply to:** VRT, axe, primitive behavior specs.

```typescript
for (const theme of themes) {
  test.describe(`showcase vrt ${theme}`, () => {
    for (const scenario of scenarios) {
      test(`${scenario.id}`, async ({ page }, testInfo) => {
        const viewportName = viewportNameFromProject(testInfo.project.name);
        await prepareShowcase(page, { theme, viewportName });
        await expect(story).toHaveScreenshot([scenario.snapshot, `${theme}.png`]);
      });
    }
  });
}
```

### Static Contract Tests

**Source:** `test/oban_powertools/web/theme_tokens_test.exs` lines 195-232
**Apply to:** Primitive no-raw-value, no-host-leakage, no-visual-rest-escape tests.

Use `File.read!`, regex-based selector/declaration extraction, and direct `assert`/`refute` messages with concrete phase contract text.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/oban_powertools/web/components/primitives.ex` | component | transform | Local repo has `use Phoenix.Component` and `attr/3` examples but no existing reusable component module with `slot/3`, closed variant values, `:global` rest filtering, or direct component-render tests. Use `74-RESEARCH.md` Phoenix.Component examples for this gap. |
| `test/browser/specs/primitives.behavior.spec.ts` | browser test | event-driven | Existing Playwright specs cover structure, VRT, and axe scans, but no current test drives tooltip Escape, icon-button accessible-name checks, focus-visible behavior, or horizontal overflow. |
| `test/browser/__screenshots__/**/showcase/primitive-*/**/*.png` | test artifact | file-I/O | Binary baselines have no source-code excerpt. Use existing screenshot directory layout and Playwright snapshot path generation. |

## Metadata

**Analog search scope:** `lib/`, `test/`, `assets/`, `scripts/`, `priv/static/`
**Primary files read:** `74-CONTEXT.md`, `74-RESEARCH.md`, `theme_shell.ex`, `test_layouts.ex`, `showcase_live.ex`, `showcase_catalog.ex`, `showcase_catalog_test.exs`, `showcase_live_test.exs`, `showcase_manifest.exs`, `manifest.ts`, `manifest-smoke.mjs`, `showcase.ts`, `axe.ts`, `showcase.vrt.spec.ts`, `showcase.a11y.spec.ts`, `showcase.structure.spec.ts`, `tokens.css`, `theme.js`, `theme_tokens_test.exs`, `assets.build.ex`, `assets_test.exs`, `assets.ex`, `router.ex`, `jobs_live.ex`
**Files scanned:** targeted `rg`/`find` searches across source, test, asset, and script directories
**Pattern extraction date:** 2026-07-10

