# Phase 75: Form Components - Codebase Patterns

**Mapped:** 2026-07-11
**Inputs:** `75-CONTEXT.md`, `75-RESEARCH.md`
**Purpose:** Give the planner concrete, repository-local implementation analogs for every expected Phase 75 file.

## Planned File Inventory

| File | Change | Role | Data flow | Closest analog |
|---|---|---|---|---|
| `lib/oban_powertools/web/components/forms.ex` | create | Stateless SSR component API | parent `to_form` -> `Phoenix.HTML.FormField` -> derived id/name/value/errors -> semantic native HTML | `lib/oban_powertools/web/components/primitives.ex` |
| `test/oban_powertools/web/components/forms_test.exs` | create | Unit, render, source, and boundary contracts | component assigns -> rendered HTML/source -> semantic and static assertions | `test/oban_powertools/web/components/primitives_test.exs` |
| `assets/oban_powertools/tokens.css` | modify | Token-scoped form visuals and states | `.obpt-*` markup/data states -> role tokens -> themed browser rendering | existing `.obpt-form-label`, `.obpt-input`, and primitive rules in the same file |
| `priv/static/oban_powertools/oban_powertools.css` | regenerate | Published compiled CSS artifact | source token CSS -> existing asset build -> package-served fingerprinted CSS | current compiled counterpart of `assets/oban_powertools/tokens.css` |
| `test/support/form_story_catalog.ex` | create | Deterministic dev/test-only form story metadata | story records -> showcase rendering and manifest generation | `test/support/primitive_story_catalog.ex` |
| `test/oban_powertools/form_story_catalog_test.exs` | create | Catalog schema, target, id, and coverage guard | catalog list -> metadata invariants | `test/oban_powertools/primitive_story_catalog_test.exs` |
| `lib/oban_powertools/web/dev/showcase_live.ex` | modify | Dev-only story renderer | catalog stories + map-backed `to_form` assigns -> form story articles -> browser targets | existing primitive catalog loader and `primitive_story_body/1` |
| `scripts/showcase_manifest.exs` | modify | Elixir-to-JSON target generator | scenario + primitive + form catalogs -> normalized manifest targets | existing `primitive_stories` pipeline |
| `test/browser/support/manifest.ts` | modify | Runtime manifest type/shape validation | generated JSON -> validated typed form stories/targets -> specs | `ShowcasePrimitiveStory` validation and union branch |
| `test/browser/support/showcase.ts` | modify | Shared structural assertions | typed targets -> locators and required data attributes | existing primitive branch in `assertShowcaseStructure` |
| `test/browser/specs/forms.behavior.spec.ts` | create | Targeted semantics/interaction checks beyond axe | form story locator -> keyboard/click/computed-style/attribute assertions | `test/browser/specs/primitives.behavior.spec.ts` |
| `test/browser/specs/showcase.vrt.spec.ts` | likely no code change | Manifest-driven visual coverage | `targets` (now including forms) -> theme/viewport screenshots | existing generic target loop |
| `test/browser/specs/showcase.a11y.spec.ts` | likely no code change | Manifest-driven axe coverage | `targets` (now including forms) -> scoped axe scans | existing generic target loop |
| `test/browser/specs/showcase.structure.spec.ts` | likely no code change | Manifest/render synchronization | `targets` -> visibility and shared structural checks | existing generic target loop |

The research explicitly identifies the first eleven files. The three generic showcase specs are listed because their existing data flow should automatically absorb form targets; planning should avoid needless edits unless a failing contract proves one is required.

## 1. Form Component Module

### Target

`lib/oban_powertools/web/components/forms.ex`

### Role and flow

This is a sibling of `Primitives`, not an extension of it. It should expose narrow stateless function components (`input`, `textarea`, `select`, `checkbox`, `radio_group`, `switch`, `field_group`, `label`, `hint`, and `error`) while parent LiveViews retain params, events, changesets, authorization, and persistence.

The normal flow is:

```text
to_form data -> form[:field] -> Phoenix.HTML.FormField
             -> Forms component derives id/name/value/errors
             -> hint/error ids + caller aria-describedby are merged
             -> native control with token-owned classes
```

### Analog: closed stateless components and safe rest attrs

From `lib/oban_powertools/web/components/primitives.ex`:

```elixir
use Phoenix.Component

attr(:variant, :atom, default: :neutral, values: @button_variants)
attr(:rest, :global, default: %{})
slot(:inner_block, required: true)

def button(assigns) do
  variant = normalize_closed!(assigns.variant, @button_variants, "unsupported button variant")

  assigns =
    assigns
    |> assign(:variant, variant)
    |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: false))

  ~H"""
  <button class={"obpt-button obpt-button--#{@variant}"} {@rest}>
    {render_slot(@inner_block)}
  </button>
  """
end
```

Mirror the component declaration style and closed variants, but use `attr(:field, Phoenix.HTML.FormField, ...)` as the primary field API. Do not copy button-specific action suppression into editable controls: form controls must preserve relevant `phx-*`, native form, `aria-*`, and `data-*` attributes.

### Analog: visual-boundary filtering

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

Forms need the same `class`/`style` rejection and string-key normalization. They should use component-specific global `include:` lists where Phoenix would otherwise reject useful attributes such as `autocomplete`, `placeholder`, `required`, `readonly`, `form`, `phx-debounce`, and `phx-throttle`.

### Analog: required visible text and description merging

```elixir
defp require_text!(value, name) do
  case present_text(value) do
    nil -> raise ArgumentError, "#{name} is required"
    text -> text
  end
end

defp merge_describedby(rest, description_id) do
  existing = rest |> Map.get("aria-describedby") |> present_text()

  describedby =
    [existing, description_id]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")

  {describedby, Map.delete(rest, "aria-describedby")}
end
```

Generalize `merge_describedby/2` to merge multiple stable ids (caller ids, `#{id}-hint`, `#{id}-error`) without duplication. Remove the original attribute from `rest` so HEEx cannot render two competing values. Use the `require_text!` pattern for high-level visible labels and legends.

### Form-specific deviations from the analog

- Derive `id`, `name`, `value`, and field errors from `%Phoenix.HTML.FormField{}`; explicit overrides are secondary.
- Gate normal changeset errors with `Phoenix.Component.used_input?/1`; allow explicit error input for submit/action-level stories.
- Set `aria-invalid="true"` only if an error element is actually rendered.
- Use stable `-hint` and `-error` ids for both single controls and groups.
- Render checkbox/radio/switch as native inputs. Named boolean form checkboxes get a hidden unchecked value; event-driven row-selection checkboxes do not.
- Render radios in `fieldset`/`legend`; do not use `role="combobox"` or combobox ARIA for filter-ready text/search fields.
- Keep disabled and read-only as distinct native/visual states.

## 2. Form Component Tests

### Target

`test/oban_powertools/web/components/forms_test.exs`

### Analog

`test/oban_powertools/web/components/primitives_test.exs` establishes three useful layers:

```elixir
@primitive_module ObanPowertools.Web.Components.Primitives
@primitive_source "lib/oban_powertools/web/components/primitives.ex"

test "all primitives are implemented as function components" do
  assert Code.ensure_loaded?(@primitive_module)

  for component <- @components do
    assert function_exported?(@primitive_module, component, 1)
  end
end
```

```elixir
html =
  render_primitive(:button,
    rest: %{
      "id" => "retry-job",
      "phx-click" => "retry",
      "aria-controls" => "retry-panel",
      "class" => "host-visual-class",
      "style" => "border: 999px solid red"
    },
    inner_block: slot("Retry job")
  )

assert html =~ ~s(id="retry-job")
assert html =~ ~s(phx-click="retry")
refute html =~ "host-visual-class"
refute html =~ "999px"
```

Use the existing render-component helper style, constructing real forms via `Phoenix.Component.to_form/2` and passing `form[:field]`. Tests should cover exports, derived field identity, valid/invalid timing, label association, merged descriptions, error prefix/text, select/textarea values, named versus event-driven checkbox hidden inputs, radio fieldsets, switch native semantics, filter inputs without combobox roles, disabled/read-only differences, rest filtering, and source guards for raw hex/pixels/host selectors.

The strongest assertion style here is contract-oriented string/attribute testing, not snapshots. Use `lazy_html` only if nested fieldset/label assertions become materially clearer than the established helpers.

## 3. Token CSS and Published Asset

### Targets

- `assets/oban_powertools/tokens.css`
- `priv/static/oban_powertools/oban_powertools.css`

### Analog

The source already contains the proof seam:

```css
.obpt-root .obpt-form-label {
  display: block;
  color: var(--obpt-color-subtle);
  font-size: var(--obpt-font-size-sm);
  font-weight: var(--obpt-font-weight-semibold);
}

.obpt-root .obpt-input {
  width: 100%;
  border: 1px solid var(--obpt-color-border);
  border-radius: var(--obpt-radius-md);
  background: var(--obpt-color-surface);
  color: var(--obpt-color-text);
  padding: var(--obpt-space-2) var(--obpt-space-3);
  font-size: var(--obpt-font-size-sm);
}

.obpt-root .obpt-input:focus-visible {
  outline: calc(var(--obpt-space-1) / 2) solid var(--obpt-color-focus);
  outline-offset: calc(var(--obpt-space-1) / 2);
}
```

Extend this family for field layout, hint/error text, textarea/select, checkbox/radio/switch, invalid, required, disabled, read-only, pending/filter variants, comfortable hit targets, and narrow wrapping. Preserve `.obpt-root` scoping and semantic tokens; validation must have a text/icon/border signal, not only color.

`priv/static/oban_powertools/oban_powertools.css` is generated output, not a second hand-maintained source. Regenerate it through the repository's existing asset build path after source CSS changes, then verify the served fingerprinted stylesheet through the existing browser harness.

## 4. Form Story Catalog and Catalog Tests

### Targets

- `test/support/form_story_catalog.ex`
- `test/oban_powertools/form_story_catalog_test.exs`

### Analog

From `test/support/primitive_story_catalog.ex`:

```elixir
@stories [
  %{
    id: "primitive-button-matrix",
    kind: :primitive,
    component: :button,
    components: [:button],
    name: "Button matrix",
    description: "Safe, caution, destructive, ghost, and disabled-with-reason actions.",
    variant: [:neutral, :primary, :warning, :danger, :ghost],
    state: [:default, :disabled, :disabled_reason],
    test_targets: %{
      story: "obpt-primitive-story-primitive-button-matrix",
      snapshot: "showcase/primitive-button-matrix",
      a11y: ~s([data-obpt-primitive-story="primitive-button-matrix"])
    }
  }
]
```

Create a separate `ObanPowertools.FormStoryCatalog` with `kind: :form`, `form-*` ids, deterministic examples, and parallel `story`/`snapshot`/`a11y` targets. Cover the complete component list and representative states: valid, invalid, required, optional, disabled, read-only, pending, filter-ready, long labels/values, and 320px wrapping. Include both named booleans and event-driven selection, plus grouped radios and a switch.

Mirror `primitive_story_catalog_test.exs` invariants: non-empty unique slug ids, exact target derivation, non-empty component/variant/state metadata, exact Phase 75 component coverage, and no future `FilterBar`, combobox, destructive dialog, or page-migration placeholders.

## 5. Dev Showcase Integration

### Target

`lib/oban_powertools/web/dev/showcase_live.ex`

### Analog: dev/test-only catalog loading

```elixir
@primitive_catalog_module ObanPowertools.PrimitiveStoryCatalog
@primitive_catalog_path Path.expand(
                          "../../../../test/support/primitive_story_catalog.ex",
                          __DIR__
                        )

def mount(_params, _session, socket) do
  primitive_catalog = load_primitive_catalog()

  {:ok,
   socket
   |> assign(:primitive_catalog_available?, primitive_catalog.available?)
   |> assign(:primitive_stories, primitive_catalog.stories)}
end
```

Add an equivalent form catalog loader and aliases for `Forms`. Keep the compile-time `dev_routes` guard so neither catalog nor showcase becomes production surface.

### Analog: stable story article

```elixir
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
  <.primitive_story_body story={story} />
</article>
```

Replace the reserved Forms placeholder with parallel `data-obpt-form-story` articles and a `form_story_body/1`. Story forms should be created with `to_form(%{...}, as: "...")`, then controls receive `field={form[:name]}`. Keep story ids/inputs stable because targeted Playwright tests will depend on them.

Do not turn the showcase into a production route or migrate Jobs/Batches fields here. The showcase is evidence for the component substrate only.

## 6. Generated Manifest

### Target

`scripts/showcase_manifest.exs`

### Analog

```elixir
primitive_stories =
  PrimitiveStoryCatalog.stories()
  |> Enum.map(fn story ->
    id = Map.fetch!(story, :id)
    test_targets = Map.fetch!(story, :test_targets)

    %{
      id: id,
      kind: story.kind |> Atom.to_string(),
      component: story.component |> Atom.to_string(),
      components: Enum.map(story.components, &Atom.to_string/1),
      variant: stringify_list.(Map.fetch!(story, :variant)),
      state: stringify_list.(Map.fetch!(story, :state)),
      story: Map.fetch!(test_targets, :story),
      snapshot: PrimitiveStoryCatalog.snapshot_name(id),
      a11y: PrimitiveStoryCatalog.a11y_target(id)
    }
  end)

targets =
  Enum.map(scenarios, &Map.put(&1, :kind, "scenario")) ++
    Enum.map(primitive_stories, & &1)
```

Alias `FormStoryCatalog`, generate `form_stories` with the same normalized metadata shape and `kind: "form"`, include it as a top-level manifest collection, and append it to `targets`. Bump `schema_version` if the validator treats the new top-level collection/union member as a schema change; update generator and TypeScript validation atomically.

## 7. TypeScript Manifest and Showcase Support

### Targets

- `test/browser/support/manifest.ts`
- `test/browser/support/showcase.ts`

### Manifest analog

```ts
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

export type ShowcaseTarget =
  | (ShowcaseScenario & { kind: 'scenario' })
  | (ShowcasePrimitiveStory & { kind: 'primitive' });
```

Add `ShowcaseFormStory`, `form_stories`, a `kind: 'form'` union branch, `form-*` slug and derived-target checks, collection length/shape validation, target ordering checks, and an exported `formStories`. Prefer factoring the duplicate primitive/form story validator only if it stays easy to audit.

### Structure analog

```ts
for (const target of targets) {
  const story = targetLocator(page, target);
  await expect(story).toHaveCount(1);
  await expect(story).toHaveAttribute('id', target.story);

  if (target.kind === 'scenario') {
    // scenario metadata
  } else {
    await expect(story).toHaveAttribute('data-obpt-component', target.components.join(' '));
    await expect(story).toHaveAttribute('data-obpt-state', target.state.join(' '));
  }
}
```

Make the non-scenario branch explicitly understand both `primitive` and `form` selectors, including `data-obpt-form-story` through each target's `a11y` locator. `targetLocator` itself remains generic and likely needs no change.

## 8. Browser Behavior Spec

### Target

`test/browser/specs/forms.behavior.spec.ts`

### Analog

Reuse the helper style from `primitives.behavior.spec.ts`:

```ts
async function tabUntilFocused(page: Page, locator: Locator, label: string): Promise<void> {
  await expect(locator).toBeVisible();

  for (let index = 0; index < 80; index += 1) {
    if (await locator.evaluate((element) => element === document.activeElement)) return;
    await page.keyboard.press('Tab');
  }

  throw new Error(`Could not reach ${label} with keyboard Tab navigation`);
}
```

```ts
const outline = await locator.evaluate((element) => {
  const style = window.getComputedStyle(element);
  return {
    color: style.outlineColor,
    style: style.outlineStyle,
    width: Number.parseFloat(style.outlineWidth)
  };
});

expect(outline.style).not.toBe('none');
expect(outline.width).toBeGreaterThan(0);
```

Add a `formStory(id)` lookup over generated `formStories` and a `prepareFormStory` wrapper over `prepareShowcase`/`targetLocator`. Assert what axe cannot prove:

- label/`for` and control id association, including label click;
- caller description plus generated hint/error ids in `aria-describedby`;
- `aria-invalid` present only alongside a visible error;
- checkbox space toggling and radio arrow-key behavior through native inputs;
- switch checkbox semantics and visible on/off signal;
- hidden unchecked value only for named boolean fields;
- disabled versus read-only behavior and perceivability;
- visible focus in system/light/dark/high-contrast themes;
- no horizontal overflow at the 320 viewport;
- reduced-motion-safe transitions/pending presentation;
- plain filter inputs have no false combobox ARIA.

## 9. Existing Generic VRT/Axe/Structure Loops

The current specs already iterate all generated targets:

```ts
for (const theme of themes) {
  test.describe(`showcase vrt ${theme}`, () => {
    for (const target of targets) {
      test(`${target.kind} ${target.id}`, async ({ page }, testInfo) => {
        await prepareShowcase(page, { theme, viewportName });
        await expect(targetLocator(page, target)).toHaveScreenshot([
          target.snapshot,
          `${theme}.png`
        ]);
      });
    }
  });
}
```

The axe spec has the same shape and scans `target.a11y`. Therefore the correct integration is to add form stories to generated `targets`; do not hardcode form ids in `showcase.vrt.spec.ts` or `showcase.a11y.spec.ts`.

## Cross-File Dependency Order

```text
forms.ex + tokens.css
  -> forms_test.exs
  -> form_story_catalog.ex + catalog tests
  -> showcase_live.ex story rendering
  -> showcase_manifest.exs
  -> manifest.ts + showcase.ts
  -> generic VRT/axe/structure + forms.behavior.spec.ts
  -> regenerate published CSS and visual baselines
```

The manifest slice must remain atomic across Elixir generation, JSON schema/type validation, showcase selectors, and target iteration. A partially updated schema will either prevent Playwright startup or silently omit form coverage.

## Boundaries the Plan Must Preserve

- No production page migration in Phase 75.
- No `FilterBar`, chips, saved-filter grammar, or combobox/typeahead behavior.
- No destructive-action dialog or reason/confirm meta-component.
- No form schema/macro DSL and no new runtime dependency.
- No caller `class`/`style`, raw visual values, host selectors, or host theme mutation.
- No hidden unchecked input for event-driven row-selection checkboxes.
- No placeholder-only labels, color-only errors, or conflation of disabled and read-only.

