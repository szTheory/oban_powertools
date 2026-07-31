# Phase 76: Navigation & App Shell - Pattern Map

**Mapped:** 2026-07-11  
**Files analyzed:** 16  
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/web/components/app_shell.ex` | component | request-response | `lib/oban_powertools/web/components/primitives.ex` | role-match |
| `lib/oban_powertools/web/theme_shell.ex` | component/layout | request-response | `lib/oban_powertools/web/theme_shell.ex` | exact |
| `lib/oban_powertools/web/live_auth.ex` | middleware/hook | request-response | `lib/oban_powertools/web/live_auth.ex` | role-match |
| `assets/oban_powertools/tokens.css` | config/style | transform | `assets/oban_powertools/tokens.css` | exact |
| `assets/oban_powertools/theme.js` | utility/client behavior | event-driven | `assets/oban_powertools/theme.js` | exact |
| `test/support/shell_story_catalog.ex` | test fixture/catalog | transform | `test/support/form_story_catalog.ex` | exact |
| `lib/oban_powertools/web/dev/showcase_live.ex` | component/dev LiveView | request-response + event-driven | `lib/oban_powertools/web/dev/showcase_live.ex` | exact |
| `scripts/showcase_manifest.exs` | utility/script | batch + transform | `scripts/showcase_manifest.exs` | exact |
| `test/browser/support/manifest.ts` | utility/types | file-I/O + transform | `test/browser/support/manifest.ts` | exact |
| `test/browser/support/manifest-smoke.mjs` | utility/test support | file-I/O + transform | `test/browser/support/manifest-smoke.mjs` | exact |
| `test/browser/support/showcase.ts` | utility/browser support | request-response | `test/browser/support/showcase.ts` | exact |
| `test/browser/specs/shell.behavior.spec.ts` | test | event-driven | `test/browser/specs/primitives.behavior.spec.ts` | role-match |
| `test/oban_powertools/web/components/app_shell_test.exs` | test | request-response | `test/oban_powertools/web/components/primitives_test.exs` | role-match |
| `test/oban_powertools/shell_story_catalog_test.exs` | test | transform | `test/oban_powertools/form_story_catalog_test.exs` | exact |
| `test/oban_powertools/web/live/showcase_live_test.exs` | test | request-response | `test/oban_powertools/web/live/showcase_live_test.exs` | exact |
| `test/oban_powertools/web/router_test.exs` | test | request-response | `test/oban_powertools/web/router_test.exs` | role-match |

## Pattern Assignments

### `lib/oban_powertools/web/components/app_shell.ex` (component, request-response)

**Analog:** `lib/oban_powertools/web/components/primitives.ex` and `lib/oban_powertools/web/components/forms.ex`

**Imports/API pattern** (`primitives.ex` lines 1-18):
```elixir
defmodule ObanPowertools.Web.Components.Primitives do
  @moduledoc """
  Token-owned primitive function components for Powertools operator surfaces.

  These components are intentionally stateless. Parent LiveViews own data,
  authorization, events, and mutations; primitives own semantic markup,
  accessible names, closed visual variants, and safe caller attributes.
  """

  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]

  @button_variants ~w[neutral primary warning danger ghost]a
```

**Component contract pattern** (`primitives.ex` lines 26-32):
```elixir
attr(:variant, :atom, default: :neutral, values: @button_variants)
attr(:size, :atom, default: :md, values: @sizes)
attr(:type, :string, default: "button")
attr(:disabled, :boolean, default: false)
attr(:disabled_reason, :string, default: nil)
attr(:rest, :global, default: %{})
slot(:inner_block, required: true)
```

**Semantic link pattern for nav links** (`primitives.ex` lines 153-188):
```elixir
@doc """
Renders a navigation link.

Exactly one navigation target is required: `href`, `patch`, or `navigate`.
Mutation events are suppressed so link styling cannot become an action affordance.
"""
attr(:href, :string, default: nil)
attr(:patch, :string, default: nil)
attr(:navigate, :string, default: nil)
attr(:rest, :global, default: %{})
slot(:inner_block, required: true)

def link(assigns) do
  target_count = Enum.count([assigns.href, assigns.patch, assigns.navigate], &present?/1)

  if target_count != 1 do
    raise ArgumentError, "link requires href, patch, or navigate"
  end
```

**Caller attribute safety pattern** (`primitives.ex` lines 499-508):
```elixir
defp visual_safe_rest(rest, opts) do
  rest
  |> normalize_rest()
  |> Enum.reject(fn {key, _value} -> key in ["class", "style"] end)
  |> Enum.reject(fn {key, _value} ->
    Keyword.get(opts, :suppress_actions?, false) and action_attr?(key)
  end)
  |> Enum.reject(fn {_key, value} -> is_nil(value) or value == false end)
  |> Map.new()
end
```

**Form convention to copy for deterministic IDs/ARIA** (`forms.ex` lines 268-295):
```elixir
defp prepare_field(assigns, _class) do
  label = require_text!(assigns.label, "visible field label")
  rest = visual_safe_rest(assigns.rest)
  {rest_id, rest} = pop_key(rest, "id")
  {caller_description, rest} = pop_key(rest, "aria-describedby")
  id = present_text(rest_id) || present_text(assigns.id) || assigns.field.id
  name = present_text(assigns.name) || assigns.field.name
  value = if is_nil(assigns.value), do: assigns.field.value, else: assigns.value
  hint = present_text(assigns.hint)
  errors = visible_errors(assigns.field, assigns.errors)
  hint_id = if hint, do: "#{id}-hint"
  error_ids = error_ids(id, errors)
```

**Apply to AppShell:** use `use Phoenix.Component`; explicit `attr/3` for `current_path`, `current_uri`, `current_actor`, `actor_label`, `context_label`, `nav_items`, and `rest`; `slot(:inner_block, required: true)`; filter `class`/`style`; keep nav labels server-controlled; render semantic `header`, native `nav`, links, buttons, breadcrumb list, and `main#obpt-main`.

---

### `lib/oban_powertools/web/theme_shell.ex` (component/layout, request-response)

**Analog:** `lib/oban_powertools/web/theme_shell.ex`

**Current layout wrapper pattern** (lines 8-24):
```elixir
attr(:inner_content, :any, required: true)

def live(assigns) do
  ~H"""
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
  """
end
```

**Apply to ThemeShell:** keep the asset link/script and `.obpt-root` attributes exactly scoped here. Replace the simple `<main class="obpt-shell">` wrapper with `<AppShell.app_shell ...>` around `@inner_content`; do not move theme state to `<html>`.

---

### `lib/oban_powertools/web/live_auth.ex` (middleware/hook, request-response)

**Analog:** `lib/oban_powertools/web/live_auth.ex`

**Imports and current actor assignment** (lines 5-10, 75-78):
```elixir
import Phoenix.Component, only: [assign: 3]
import Phoenix.LiveView

alias ObanPowertools.Auth
alias ObanPowertools.Web.ControlPlanePresenter

def on_mount(:default, _params, session, socket) do
  actor = Auth.current_actor(session)
  {:cont, assign(socket, :current_actor, actor)}
end
```

**Authorization stays page/action-owned** (lines 80-97):
```elixir
def authorize_page(socket, action, resource) do
  case Auth.authorization_outcome(Map.get(socket.assigns, :current_actor), action, resource) do
    :ok ->
      {:ok, socket}

    {:error, _reason} ->
      {:error, redirect(socket, to: "/")}
  end
end

def authorize_action(socket, action, resource, opts \\ []) do
  case Auth.authorization_outcome(Map.get(socket.assigns, :current_actor), action, resource) do
    :ok ->
      :ok
```

**Page-local `handle_params/3` pattern to avoid breaking** (`jobs_live.ex` lines 37-61):
```elixir
@impl true
def handle_params(%{"id" => id}, _uri, socket) do
  {:noreply, load_job_detail(socket, id)}
end

def handle_params(params, _uri, socket) do
  case {connected?(socket), Map.get(params, "state")} do
    {true, nil} ->
      {:noreply, push_patch(socket, to: Selectors.jobs_path([{"state", "available"}]))}

    _ ->
      filter = filter_from_params(params)
```

**Apply to LiveAuth/current path:** extend `on_mount/4` or a sibling on-mount module with `attach_hook/4` for `:handle_params` to assign `:current_uri` and `:current_path` before layout render. Keep it additive: page LiveViews already own `handle_params/3` URL behavior.

**Gap:** no exact in-repo `attach_hook(:handle_params, ...)` analog exists. Use the existing `LiveAuth` import pattern and Phoenix LiveView hook docs from research.

---

### `assets/oban_powertools/tokens.css` (config/style, transform)

**Analog:** `assets/oban_powertools/tokens.css`

**Token and namespace pattern** (lines 1, 67-99, 103-147):
```css
.obpt-root {
  --obpt-font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
  --obpt-font-mono: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", "DejaVu Sans Mono", monospace;
  --obpt-font-size-xs: 0.75rem;
  --obpt-font-size-sm: 0.8125rem;
  --obpt-font-size-md: 0.875rem;
  --obpt-font-size-lg: 1rem;
  --obpt-font-size-xl: 1.125rem;
  --obpt-line-height-tight: 1.25;
  --obpt-line-height-base: 1.4286;
  --obpt-font-weight-regular: 400;
  --obpt-font-weight-semibold: 600;
  --obpt-space-1: 0.25rem;
```

**Button/link token pattern** (lines 734-755, 854-864):
```css
.obpt-root .obpt-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--obpt-space-1);
  border: 1px solid var(--obpt-color-transparent);
  border-radius: var(--obpt-radius-md);
  padding: var(--obpt-space-2) var(--obpt-space-4);
  font-size: var(--obpt-font-size-sm);
  font-weight: var(--obpt-font-weight-semibold);
  transition: background-color var(--obpt-motion-duration-fast) var(--obpt-motion-ease-standard), border-color var(--obpt-motion-duration-fast) var(--obpt-motion-ease-standard);
}
```

**Responsive/wrapping showcase pattern** (lines 1258-1304, 1493-1505):
```css
.obpt-root .obpt-showcase-controls {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(16rem, 1fr));
  gap: var(--obpt-space-4);
  border: 1px solid var(--obpt-color-border);
  border-radius: var(--obpt-radius-lg);
  background: var(--obpt-color-elevated);
  padding: var(--obpt-space-4);
}

.obpt-root .obpt-showcase-segmented {
  display: flex;
  flex-wrap: wrap;
  gap: var(--obpt-space-2);
}

.obpt-root .obpt-showcase-section-nav a:focus-visible {
  outline: 2px solid var(--obpt-color-focus);
  outline-offset: 2px;
}
```

**Apply to shell CSS:** add `.obpt-root .obpt-app-shell*` selectors only. Use `var(--obpt-*)` tokens, wrap-enabled flex/grid, `min-width: 0`, visible `:focus-visible`, and media queries under the existing scoped stylesheet. No raw component hex/px outside token definitions.

---

### `assets/oban_powertools/theme.js` (utility/client behavior, event-driven)

**Analog:** `assets/oban_powertools/theme.js`

**Scoped constants and theme API** (lines 1-12, 43-52, 201-207):
```javascript
(() => {
  const STORAGE_KEY = "oban_powertools:theme";
  const THEMES = new Set(["system", "light", "dark", "high-contrast"]);
  const ATTR_THEME = "data-obpt-theme";
  const ATTR_EFFECTIVE_THEME = "data-obpt-effective-theme";
  const ATTR_MOTION = "data-obpt-motion";
  const ATTR_TOOLTIP_OPEN = "data-obpt-tooltip-open";
  const ATTR_TOOLTIP_DISMISSED = "data-obpt-tooltip-dismissed";
  const ROOT_SELECTOR = ".obpt-root";

  function apply(root, theme = storedTheme()) {
    if (!root || !root.matches || !root.matches(ROOT_SELECTOR)) {
      return;
    }
```

**Delegated theme control pattern** (lines 149-155):
```javascript
document.addEventListener("click", (event) => {
  const control = event.target.closest("[data-obpt-theme-choice]");

  if (control) {
    setTheme(control.getAttribute("data-obpt-theme-choice"));
  }
});
```

**Scoped Escape handling pattern** (lines 181-199):
```javascript
document.addEventListener("keydown", (event) => {
  if (event.key !== "Escape") {
    return;
  }

  const tooltip = scopedTooltipFor(event);

  if (!tooltip) {
    return;
  }

  closeTooltip(tooltip, true);
```

**Apply to shell JS:** add delegated handlers for fixed data attributes such as `[data-obpt-nav-toggle]` and `[data-obpt-primary-nav]`. Scope through `.obpt-root`; update `aria-expanded`, hidden/inert/tabbability state, and open data attributes together; close on Escape only when focus is inside the disclosure region; do not evaluate strings or persist sensitive state.

---

### `test/support/shell_story_catalog.ex` (test fixture/catalog, transform)

**Analog:** `test/support/form_story_catalog.ex`

**Catalog boundary pattern** (lines 1-8):
```elixir
defmodule ObanPowertools.FormStoryCatalog do
  @moduledoc """
  Deterministic dev/test form stories for the Powertools showcase.

  This registry is deliberately separate from domain stress fixtures and from
  production packaging. It describes component evidence, never behavior owned
  by an operator LiveView.
  """
```

**Target derivation pattern** (`form_story_catalog.ex` lines 146-171):
```elixir
@stories Enum.map(@story_specs, fn story ->
           id = story.id

           %{
             story
             | test_targets: %{
                 story: "obpt-form-story-#{id}",
                 snapshot: "showcase/#{id}",
                 a11y: ~s([data-obpt-form-story="#{id}"])
               }
           }
         end)

@stories_by_id Map.new(@stories, &{&1.id, &1})

def stories, do: @stories
def story!(id), do: raise(ArgumentError, "unknown form story: #{inspect(id)}")
def snapshot_name(id), do: "showcase/#{story!(id).id}"
def a11y_target(id), do: ~s([data-obpt-form-story="#{story!(id).id}"])
```

**Apply to shell catalog:** create deterministic shell story specs for the UI-SPEC targets. Use `kind: :shell`, `component: :app_shell`, stable IDs like `shell-nine-surface-nav`, `test_targets.story: "obpt-shell-story-#{id}"`, `snapshot: "showcase/#{id}"`, and `a11y: ~s([data-obpt-shell-story="#{id}"])`.

---

### `lib/oban_powertools/web/dev/showcase_live.ex` (component/dev LiveView, request-response + event-driven)

**Analog:** `lib/oban_powertools/web/dev/showcase_live.ex`

**Dev-only guard and catalog loading pattern** (lines 1-28, 58-78):
```elixir
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  defmodule ObanPowertools.Web.Dev.ShowcaseLive do
    @moduledoc """
    Dev-only LiveView for the deterministic Powertools showcase skeleton.
    """

    use Phoenix.LiveView

    alias ObanPowertools.Web.Components.{Forms, Primitives}

    @catalog_module ObanPowertools.ShowcaseCatalog
    @primitive_catalog_module ObanPowertools.PrimitiveStoryCatalog
    @form_catalog_module ObanPowertools.FormStoryCatalog
```

**Story cell rendering pattern** (lines 184-245):
```elixir
<%= if @primitive_catalog_available? and @primitive_stories != [] do %>
  <div class="obpt-showcase-story-grid">
    <article
      :for={story <- @primitive_stories}
      id={target_value(story.test_targets, :story)}
      class="obpt-showcase-story"
      data-obpt-primitive-story={story.id}
      data-obpt-component={component_value(story)}
      data-obpt-variant={state_value(story.variant)}
      data-obpt-state={state_value(story.state)}
      data-obpt-a11y-target={target_value(story.test_targets, :a11y)}
    >
```

**Support module fallback pattern** (lines 405-422):
```elixir
defp ensure_support_module(module, path) do
  cond do
    Code.ensure_loaded?(module) ->
      {:ok, module}

    Mix.env() != :test and File.exists?(path) ->
      Code.require_file(path)

      if Code.ensure_loaded?(module) do
        {:ok, module}
      else
        :error
      end

    true ->
      :error
  end
end
```

**Apply to ShowcaseLive:** add `ShellStoryCatalog` alias/path, load/assign `:shell_catalog_available?` and `:shell_stories`, add shell section/story cells with `data-obpt-shell-story`, and render `<AppShell.app_shell>` inside story bodies. Do not mix shell stories into `ShowcaseCatalog`, primitive, or form catalogs.

---

### `scripts/showcase_manifest.exs` (utility/script, batch + transform)

**Analog:** `scripts/showcase_manifest.exs`

**Existing catalog mapping pattern** (lines 1-3, 37-77):
```elixir
alias ObanPowertools.ShowcaseCatalog
alias ObanPowertools.PrimitiveStoryCatalog
alias ObanPowertools.FormStoryCatalog

primitive_stories =
  PrimitiveStoryCatalog.stories()
  |> Enum.map(fn story ->
    id = Map.fetch!(story, :id)
    test_targets = Map.fetch!(story, :test_targets)

    %{
      id: id,
      kind: story.kind |> Atom.to_string(),
      component: story.component |> Atom.to_string(),
```

**Target aggregation pattern** (lines 79-93):
```elixir
targets =
  Enum.map(scenarios, &Map.put(&1, :kind, "scenario")) ++
    primitive_stories ++ form_stories

manifest = %{
  schema_version: 3,
  themes: themes,
  viewports: viewports,
  scenarios: scenarios,
  primitive_stories: primitive_stories,
  form_stories: form_stories,
  targets: targets
}

IO.write(Jason.encode!(manifest))
```

**Apply to manifest script:** alias `ShellStoryCatalog`, map `shell_stories`, bump schema version, add `shell_stories` to the manifest, and append it to `targets` after forms unless planner explicitly chooses another stable ordering.

---

### `test/browser/support/manifest.ts` (utility/types, file-I/O + transform)

**Analog:** `test/browser/support/manifest.ts`

**Type union pattern** (lines 31-62):
```typescript
export type ShowcasePrimitiveStory = {
  id: string;
  kind: 'primitive';
  component: string;
  components: string[];
  name: string;
  description: string;
  variant: string[];
  state: string[];
  story: string;
  snapshot: string;
  a11y: string;
};

export type ShowcaseFormStory = Omit<ShowcasePrimitiveStory, 'kind'> & {
  kind: 'form';
};
```

**Validation and expected target ordering pattern** (lines 191-204, 244-252):
```typescript
const formStories = assertArray(manifest.form_stories, 'form_stories').map((story, index) =>
  validateComponentStory(story, index, 'form_stories', 'form') as ShowcaseFormStory
);

const targets = assertArray(manifest.targets, 'targets').map((target, index) =>
  validateTarget(target, index)
);
const expectedTargets: ShowcaseTarget[] = [
  ...scenarios.map((scenario) => ({ kind: 'scenario' as const, ...scenario })),
  ...primitiveStories,
  ...formStories
];
```

**Reusable component-story validator** (lines 297-331):
```typescript
function validateComponentStory(
  value: unknown,
  index: number,
  collection: 'primitive_stories' | 'form_stories',
  kind: 'primitive' | 'form'
): ShowcasePrimitiveStory | ShowcaseFormStory {
  const actual = assertRecord(value, `${collection}[${index}]`);
  const id = assertString(actual.id, `${collection}[${index}].id`);
  const prefix = kind === 'primitive' ? 'primitive' : 'form';

  assertEqual(actual.kind, kind, `${collection}[${index}].kind`);
  if (!new RegExp(`^${prefix}-[a-z0-9]+(?:-[a-z0-9]+)*$`).test(id)) {
```

**Apply to manifest.ts:** add `ShowcaseShellStory` with `kind: 'shell'`, include `shell_stories`, extend `ShowcaseTarget`, update `validateComponentStory` collection/kind/prefix unions, accept `shell` in `validateTarget`, and export `shellStories`.

---

### `test/browser/support/manifest-smoke.mjs` (utility/test support, file-I/O + transform)

**Analog:** `test/browser/support/manifest-smoke.mjs`

**Smoke validator pattern** (lines 136-164, 163-175):
```javascript
const formStories = array(manifest.form_stories, 'form_stories');
equal(formStories.length, 9, 'form_stories.length');

for (const [index, story] of formStories.entries()) {
  const actual = record(story, `form_stories[${index}]`);
  const id = string(actual.id, `form_stories[${index}].id`);
  const components = array(actual.components, `form_stories[${index}].components`);
  const variant = array(actual.variant, `form_stories[${index}].variant`);
  const state = array(actual.state, `form_stories[${index}].state`);

  equal(actual.kind, 'form', `form_stories[${index}].kind`);
  if (!/^form-[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
    fail(`form_stories[${index}].id must be a slug-like form-* identifier`);
  }
```

**Apply to manifest smoke:** add shell-story validation with a `shell-*` slug check, expected count from shell catalog, target-order assertions, and final log count.

---

### `test/browser/support/showcase.ts` (utility/browser support, request-response)

**Analog:** `test/browser/support/showcase.ts`

**Prepare showcase and theme pattern** (lines 30-71):
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
```

**Target locator/structure pattern** (lines 77-132):
```typescript
export function targetLocator(page: Page, target: ShowcaseTarget): Locator {
  return page.locator(target.a11y);
}

export async function assertShowcaseStructure(page: Page): Promise<void> {
  await expect(page.locator('.obpt-root')).toHaveCount(1);
  await expect(page.locator('[data-obpt-showcase]')).toHaveCount(1);
  ...
  for (const target of targets) {
    const story = targetLocator(page, target);

    await expect(story).toHaveCount(1);
    await expect(story).toHaveAttribute('id', target.story);
```

**Apply to showcase support:** add `shell` branch to `assertShowcaseStructure` checking `data-obpt-shell-story`, `data-obpt-component`, `data-obpt-variant`, `data-obpt-state`, and `data-obpt-a11y-target`.

---

### `test/browser/specs/shell.behavior.spec.ts` (test, event-driven)

**Analog:** `test/browser/specs/primitives.behavior.spec.ts` and `test/browser/specs/forms.behavior.spec.ts`

**Story preparation pattern** (`primitives.behavior.spec.ts` lines 16-30):
```typescript
async function preparePrimitiveStory(
  page: Page,
  projectName: string,
  story: ShowcasePrimitiveStory,
  theme = 'light'
): Promise<Locator> {
  const viewportName = viewportNameFromProject(projectName);

  await prepareShowcase(page, { theme, viewportName });

  const locator = targetLocator(page, story);
  await expect(locator).toBeVisible();

  return locator;
}
```

**Keyboard focus helper pattern** (`primitives.behavior.spec.ts` lines 32-64):
```typescript
async function tabUntilFocused(page: Page, locator: Locator, label: string): Promise<void> {
  await expect(locator).toBeVisible();

  for (let index = 0; index < 80; index += 1) {
    if (await locator.evaluate((element) => element === document.activeElement)) {
      return;
    }

    await page.keyboard.press('Tab');
  }

  throw new Error(`Could not reach ${label} with keyboard Tab navigation`);
}
```

**Overflow pattern** (`forms.behavior.spec.ts` lines 309-322):
```typescript
test('form stories and page do not overflow horizontally at 320px', async ({ page }, testInfo) => {
  await prepareFormStory(page, testInfo.project.name, formStory('form-long-content'));
  const overflow = await page.evaluate(() => ({
    body: document.body.scrollWidth - document.body.clientWidth,
    document: document.documentElement.scrollWidth - document.documentElement.clientWidth,
    stories: Array.from(document.querySelectorAll('[data-obpt-form-story]')).map(
      (element) => element.scrollWidth - element.clientWidth
    )
  }));

  expect(overflow.document).toBeLessThanOrEqual(1);
```

**Apply to shell behavior spec:** create `shellStory(id)` and `prepareShellStory(...)`; verify primary nav role/name, 9 links, `aria-current="page"`, breadcrumb current item, skip-link focus transfer, disclosure `aria-expanded` and collapsed tab order at 320, Escape close, theme `aria-pressed`/root state, visible focus across themes, and no body/document/shell horizontal overflow.

---

### `test/oban_powertools/web/components/app_shell_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/web/components/primitives_test.exs` and `test/oban_powertools/web/components/forms_test.exs`

**Component export and render helper pattern** (`primitives_test.exs` lines 35-44, 348-361):
```elixir
describe "COMP-01 primitive exports" do
  test "all primitives are implemented as function components" do
    assert Code.ensure_loaded?(@primitive_module),
           "D-01/COMP-01 require #{@primitive_module} to exist"

    for component <- @components do
      assert function_exported?(@primitive_module, component, 1),
             "COMP-01 requires #{inspect(@primitive_module)}.#{component}/1"
    end
  end
end
```

```elixir
defp render_primitive(component, assigns) when is_atom(component) do
  assert Code.ensure_loaded?(@primitive_module)

  Phoenix.LiveViewTest.__render_component__(
    ObanPowertools.TestEndpoint,
    Function.capture(@primitive_module, component, 1),
    Map.new(assigns),
    []
  )
end
```

**Source guard pattern** (`forms_test.exs` lines 423-449):
```elixir
test "source forbids visual literals, host theme mutation, raw HTML, and invented widget behavior" do
  source = read_source!()

  assert source =~ "use Phoenix.Component"
  assert source =~ "used_input?"
  assert source =~ "visual_safe_rest"

  refute source =~ ~r/#[0-9a-fA-F]{3,8}/
  refute source =~ ~r/\b\d+(?:\.\d+)?px\b/

  for forbidden <- [
        ":root",
        "document.documentElement",
        "<html",
        "<body",
        ".dark",
```

**Apply to app shell tests:** assert `AppShell.app_shell/1` exists; renders exactly 9 primary nav links in canonical order; omits `/oban`; includes skip link, `main#obpt-main tabindex="-1"`, theme buttons, actor copy, breadcrumb, current link/crumb `aria-current`; filters caller `class`/`style`; rejects unsafe nav model input; source has no raw colors/px or host theme selectors.

---

### `test/oban_powertools/shell_story_catalog_test.exs` (test, transform)

**Analog:** `test/oban_powertools/form_story_catalog_test.exs`

**Catalog contract pattern** (lines 15-38):
```elixir
test "D-22 keeps exactly nine deterministic form stories in a separate catalog" do
  stories = FormStoryCatalog.stories()
  ids = Enum.map(stories, & &1.id)

  assert stories == FormStoryCatalog.stories()
  assert ids == @ids
  assert ids == Enum.uniq(ids)
  assert Enum.all?(ids, &Regex.match?(~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/, &1))
  assert Enum.all?(stories, &(&1.kind == :form))
end

test "targets and lookup helpers derive only from stable ids" do
  for story <- FormStoryCatalog.stories() do
    id = story.id
    assert FormStoryCatalog.story!(id) == story
    assert FormStoryCatalog.snapshot_name(id) == "showcase/#{id}"
```

**Apply to shell catalog tests:** assert exact shell story IDs from UI-SPEC, deterministic order, unique slug IDs, `kind == :shell`, all required metadata present, stable target derivation, no bridge primary nav story, and story copy includes canonical nav/theme/actor labels.

---

### `test/oban_powertools/web/live/showcase_live_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/web/live/showcase_live_test.exs`

**ThemeShell/asset render pattern** (lines 89-102):
```elixir
test "renders the showcase through the Powertools theme shell", %{conn: conn} do
  {:ok, _view, html} = mount_showcase!(conn)

  assert count(html, "obpt-root") == 1
  assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.css|
  assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.js|
  assert html =~ "data-obpt-showcase"
end
```

**Story-cell render pattern** (lines 172-193):
```elixir
test "forms section renders nine real catalog-backed form stories", %{conn: conn} do
  {:ok, view, html} = mount_showcase!(conn)

  assert_attribute_values(html, "data-obpt-form-story", @form_story_ids)
  refute has_element?(view, "[data-obpt-section='forms'] .obpt-showcase-placeholder")

  for id <- @form_story_ids do
    assert has_element?(
             view,
             "#obpt-form-story-#{id}[data-obpt-form-story='#{id}'][data-obpt-component][data-obpt-variant][data-obpt-state][data-obpt-a11y-target]"
           )
  end
```

**Apply to showcase tests:** add `@shell_story_ids`, assert shell section/story cells render with `data-obpt-shell-story`, ensure empty placeholder is absent, verify copy/structure for nav/theme/actor/breadcrumb, and assert escaped long context content.

---

### `test/oban_powertools/web/router_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/web/router_test.exs`

**Nine native surfaces and dev route pattern** (lines 12-78):
```elixir
test "native powertools routes mount inside the ops/jobs shell" do
  assert %{
           plug: Phoenix.LiveView.Plug,
           phoenix_live_view: {ObanPowertools.Web.EngineOverviewLive, :index, _, _}
         } =
           Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs", "localhost")

  assert %{
           plug: Phoenix.LiveView.Plug,
           phoenix_live_view: {ObanPowertools.Web.LifelineLive, :index, _, _}
         } =
           Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/lifeline", "localhost")
```

**Bridge boundary pattern** (lines 84-110):
```elixir
test "the optional oban_web bridge mounts under /ops/jobs/oban with the bounded powertools bridge contract" do
  if Code.ensure_loaded?(Oban.Web.Router) do
    assert %{
             plug: Phoenix.LiveView.Plug,
             route: "/ops/jobs/oban",
             phoenix_live_view: {Oban.Web.DashboardLive, :home, _, metadata}
           } =
             Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/oban", "localhost")

    assert %{
             extra: %{
               session:
                 {Oban.Web.Router, :__session__, ["/ops/jobs/oban", nil, resolver, _, _, _, _]},
               on_mount: on_mount_hooks
             }
           } = metadata
```

**Apply to router tests:** preserve these route assertions. Add shell-related assertions only if route metadata changes; keep optional bridge read-only and out of primary nav.

## Shared Patterns

### Phoenix Function Components

**Source:** `lib/oban_powertools/web/components/primitives.ex` lines 10-18, 26-32, 499-508  
**Apply to:** `app_shell.ex`, `app_shell_test.exs`, `showcase_live.ex`

Use stateless function components, closed values, explicit slots, semantic HEEx, and `visual_safe_rest` filtering. Shell must not become a LiveComponent or own page behavior.

### ThemeShell And Scoped Assets

**Source:** `lib/oban_powertools/web/theme_shell.ex` lines 8-24  
**Apply to:** `theme_shell.ex`, `app_shell.ex`, browser tests

Keep the asset link/script and all theme attributes on `.obpt-root`. Shell integration belongs inside this layout around `@inner_content`.

### Auth And Current Path

**Source:** `lib/oban_powertools/web/live_auth.ex` lines 75-97; `lib/oban_powertools/web/jobs_live.ex` lines 37-61  
**Apply to:** `live_auth.ex`, `theme_shell.ex`, `app_shell.ex`

`LiveAuth` assigns actor context and enforces authorization helpers. Add current URI/path assignment as an additive hook; do not interfere with existing page-local `handle_params/3`.

### Route/Nav Model

**Source:** `lib/oban_powertools/web/router.ex` lines 56-72; `test/oban_powertools/web/router_test.exs` lines 12-78  
**Apply to:** `app_shell.ex`, `app_shell_test.exs`, `shell_story_catalog.ex`

Primary nav has exactly the nine native routes: Overview, Jobs, Batches, Workflows, Cron, Limiters, Lifeline, Audit, Forensics. Optional `/ops/jobs/oban` bridge is secondary/read-only only.

### Showcase Evidence

**Source:** `test/support/form_story_catalog.ex` lines 146-171; `scripts/showcase_manifest.exs` lines 79-93; `test/browser/support/manifest.ts` lines 191-204  
**Apply to:** shell catalog, manifest script, manifest validators, showcase LiveView, VRT/axe

Stories are deterministic support modules; manifest generation is the source of truth; browser specs iterate over `targets`. Add shell as a first-class kind.

### Browser Behavior Checks

**Source:** `test/browser/specs/primitives.behavior.spec.ts` lines 32-64 and `test/browser/specs/forms.behavior.spec.ts` lines 309-322  
**Apply to:** `shell.behavior.spec.ts`

Use role/name locators, helper functions for target lookup/focus, and explicit assertions for visible focus and horizontal overflow.

### CSS/JS Scoping

**Source:** `assets/oban_powertools/tokens.css` lines 1-147, 1258-1304; `assets/oban_powertools/theme.js` lines 1-12, 149-155  
**Apply to:** shell CSS and disclosure JS

Every selector and DOM mutation stays under `.obpt-root` with fixed `data-obpt-*` attributes. No host selectors, no `<html>` theme mutation, no new UI runtime.

## No Analog Found

| File/Concern | Role | Data Flow | Reason |
|--------------|------|-----------|--------|
| Current-path `attach_hook(:handle_params, ...)` implementation | middleware/hook | request-response | No in-repo `attach_hook` pattern exists. Closest analog is `LiveAuth.on_mount/4` plus page-local `handle_params/3`; implement from Phoenix LiveView docs cited in research. |

## Metadata

**Analog search scope:** `lib/`, `assets/`, `scripts/`, `test/`  
**Files scanned:** Phoenix web modules, component modules/tests, story catalogs, manifest generator/validators, Playwright specs/support, token CSS, theme JS  
**Pattern extraction date:** 2026-07-11
