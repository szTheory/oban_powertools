# Phase 78: Component Groups (Meta-Components) - Pattern Map

**Mapped:** 2026-07-18  
**Files analyzed:** 28 logical source/support/test/planning targets plus 276 generated VRT baselines  
**Analogs found:** 27 / 28 logical targets; adaptive native-dialog behavior is a composite analog rather than an existing local feature

## Scope and Instruction Check

- Binding inputs read in full: `78-CONTEXT.md` decisions D-01 through D-61 and `78-RESEARCH.md`.
- No root `AGENTS.md`, `.claude/skills/`, or `.agents/skills/` applies. The only project-tree `AGENTS.md` is below `examples/phoenix_host_upgrade_source/`, outside this phase's scope.
- This map covers the production component/presenter seams, scoped assets, dev/test harness, manifest/browser pipeline, tests, generated group baselines, and validation evidence named by the upstream artifacts.
- Phase 78 must not modify production page LiveViews, authorization, Ecto query behavior, audit schemas, mutation engines, route grammars, dependency manifests, or package lockfiles.
- `ControlPlanePresenter` versus a narrowly named pure presenter is a planner choice, and `StatusTaxonomy` changes are conditional. The classification table records these as alternatives rather than requiring both.
- Existing unrelated worktree changes must be preserved. Generated CSS/JS are rebuilt from source; they are never edited independently.

## Architecture and Data Flow

```text
parent LiveView / presenter
  owns auth, data, URL/history, open/draft/loading state, validation,
  preview, execution, audit writes, redaction, and result normalization
       |
       +--> pure finite-key presenter/normalizer
       |      backend/domain input -> narrow presentation maps + complete copy
       |
       +--> OperatorPatterns function components
       |      attrs + named slots -> one escaped semantic HEEx tree
       |      compose Primitives + Forms + DataDisplay
       |
       +--> scoped source CSS + standalone data-attribute JS controller
              -> rebuilt checked-in package assets

OperatorPatternStoryCatalog (dev/test only)
  -> ShowcaseLive connected parent/harness
  -> showcase_manifest.exs schema 6 + activation metadata
  -> strict TypeScript/Node validation
  -> focused connected behavior tests
  -> generic one-at-a-time axe/VRT loops
  -> exactly 276 group PNGs
```

The authorization pattern for every production component file is deliberately **none**. These are stateless renderers. Authorization is a parent/server concern and must not be inferred from disabled buttons, preview copy, or client state.

## File Classification

| Expected File | Change | Role | Data Flow | Closest Existing Analog | Match Quality |
|---|---|---|---|---|---|
| `lib/oban_powertools/web/components/operator_patterns.ex` | new | stateless component library | presentation maps/attrs/slots -> escaped HEEx | `components/data_display.ex`, `forms.ex`, `primitives.ex` | composite role + flow match |
| `lib/oban_powertools/web/control_plane_presenter.ex` | modify, preferred seam | pure presenter/normalizer | domain input -> grammatical presentation maps | same file; `status_taxonomy.ex` | exact role |
| `lib/oban_powertools/web/operator_pattern_presenter.ex` | optional alternative new file | pure presenter/normalizer | domain input -> grammatical presentation maps | `control_plane_presenter.ex` | role match |
| `lib/oban_powertools/web/status_taxonomy.ex` | conditional modify | pure closed registry | domain/state -> status spec | same file | exact |
| `test/oban_powertools/web/components/operator_patterns_test.exs` | new | component/render/security contract | attrs/slots -> HTML and source assertions | `components/data_display_test.exs` | exact style |
| `test/oban_powertools/web/operator_pattern_presenter_test.exs` | new, or equivalent presenter tests | pure unit contract | maps/copy inputs -> normalized outputs/errors | `status_taxonomy_test.exs`, catalog deterministic-map tests | role match |
| `test/oban_powertools/web/live/operator_patterns_harness_test.exs` | new, or focused ShowcaseLive tests | connected LiveView contract | events/params -> parent state, URL, rendered transitions | `web/live/showcase_live_test.exs`; `workflows_live.ex` | role + flow match |
| `test/support/operator_pattern_story_catalog.ex` | new | dev/test story catalog | fixed normalized fixtures -> targets/stories | `data_display_story_catalog.ex` | exact |
| `test/oban_powertools/operator_pattern_story_catalog_test.exs` | new | catalog contract | catalog -> exact order/coverage/safety | `data_display_story_catalog_test.exs` | exact |
| `assets/oban_powertools/tokens.css` | modify | root-scoped token CSS | semantic classes/data attrs -> responsive themed layout | existing data/form/shell blocks in same file | exact |
| `assets/oban_powertools/theme.js` | modify | standalone scoped client controller | delegated DOM/resize/patch events -> presentational DOM state | existing nav/tooltip controller in same file | role + event-flow match |
| `priv/static/oban_powertools/oban_powertools.css` | regenerate | packaged asset | source CSS -> shipped bytes | same file via asset build task | exact |
| `priv/static/oban_powertools/oban_powertools.js` | regenerate | packaged asset | source JS -> shipped bytes | same file via asset build task | exact |
| `lib/oban_powertools/web/dev/showcase_live.ex` | modify | dev/test LiveView and behavior harness | catalogs/events/params -> connected story DOM | existing data-story integration in same file | exact |
| `scripts/showcase_manifest.exs` | modify | manifest generator | Elixir catalogs -> schema-6 JSON | current schema-5 data-story pipeline | exact |
| `test/browser/support/manifest.ts` | modify | strict runtime validator/types | generated JSON -> typed target registry | current `ShowcaseDataStory` path | exact |
| `test/browser/support/manifest-smoke.mjs` | modify | independent Node schema gate | JSON -> schema/order/count diagnostics | existing schema-5 checks in same file | exact |
| `test/browser/support/showcase.ts` | modify | browser target/activation support | target metadata -> prepared locator/overlay | current target-kind branches and `prepareShowcase` | exact, activation is an extension |
| `test/browser/specs/showcase.structure.spec.ts` | modify | generic structure test | all targets -> DOM metadata assertions | same file plus `assertShowcaseStructure` | exact |
| `test/browser/specs/showcase.a11y.spec.ts` | modify as needed | generic axe matrix | activated target x theme x viewport -> axe result | current generic target loop | exact, activation is an extension |
| `test/browser/specs/showcase.vrt.spec.ts` | modify as needed | generic VRT matrix | activated target x theme x viewport -> PNG comparison | current generic target loop | exact, activation is an extension |
| `test/browser/specs/operator-patterns.behavior.spec.ts` | new | focused connected browser behavior | keyboard/resize/history/live events -> assertions | `data-display.behavior.spec.ts`, `shell.behavior.spec.ts` | exact style |
| `test/browser/support/verify-group-baselines.mjs` | new | independent baseline verifier CLI | manifest + screenshot tree/git status -> exact set/scope | `verify-data-baselines.mjs` | exact |
| `test/oban_powertools/web/live/showcase_live_test.exs` | modify | LiveView/catalog/package contract | route/events -> story DOM/fallback | current data catalog tests in same file | exact |
| `test/oban_powertools/web/theme_tokens_test.exs` | modify | CSS static contract | CSS source -> root/token/media assertions | current `@data_classes`/`data_blocks` family | exact |
| `test/oban_powertools/web/assets_test.exs` | modify | packaged asset/idempotence contract | build/files -> hashes/selectors | same file | exact |
| `test/oban_powertools/web/status_taxonomy_test.exs` | conditional modify | pure registry contract | operator-result states -> exact specs | same file | exact |
| `.planning/phases/78-component-groups-meta-components/78-VALIDATION.md` | modify at closeout | validation evidence | commands/results -> Nyquist sign-off | Phase 77 validation artifact | exact |
| `test/browser/__screenshots__/chromium-{320,tablet,wide}/showcase/group-*/{system,light,dark,high-contrast}.png` | new, 276 files | VRT baselines | 23 stories x 4 themes x 3 viewports -> PNG | existing `data-*` baseline tree | exact |

The ignored `test/browser/.generated/showcase-manifest.json` is regenerated by `npm run showcase:manifest`; it is not a tracked implementation target. No `mix.exs`, `mix.lock`, `package.json`, or `package-lock.json` change is expected.

## Pattern Assignments

### 1. `lib/oban_powertools/web/components/operator_patterns.ex`

**Primary composite analogs:** `DataDisplay`, `Forms`, and `Primitives` establish the exact module boundary: stateless `Phoenix.Component`, closed attrs, named slots, safe caller attributes, and leaf-component composition.

`lib/oban_powertools/web/components/data_display.ex:1-40`:

```elixir
defmodule ObanPowertools.Web.Components.DataDisplay do
  @moduledoc """
  Stateless data-display function components for Powertools operator surfaces.
  """

  use Phoenix.Component

  alias ObanPowertools.Web.Components.Primitives
  alias ObanPowertools.Web.StatusTaxonomy

  @data_states ~w[ready loading empty error unavailable permission_denied]a

  attr(:id, :string, default: nil)
  attr(:domain, :atom, required: true, values: @status_domains)
  attr(:state, :any, required: true)
  attr(:rest, :global, default: %{})

  def status_pill(assigns) do
    assigns =
      assigns
      |> assign(:spec, StatusTaxonomy.spec(assigns.domain, assigns.state))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <Primitives.status_pill id={@id} spec={@spec} {@rest} />
    """
  end
end
```

Copy the **structure**, not the permissive `:rest` surface. Phase 78 decisions prohibit a caller `class`, `style`, arbitrary globals, raw color, or size escape hatch, so `OperatorPatterns` should generally expose explicit semantic attrs and constrained slots instead of a public global rest attr.

Use repeated named slots as established by `DataDisplay.description_list/1` (`data_display.ex:169-205`):

```elixir
slot(:item) do
  attr(:label, :string, required: true)
  attr(:value_kind, :atom)
end

def description_list(assigns) do
  ~H"""
  <section id={@id} class="obpt-description-list">
    <dl :if={@state == :ready} class="obpt-description-list__list">
      <div :for={item <- @item} class="obpt-description-list__item">
        <dt class="obpt-description-list__term">{item.label}</dt>
        <dd class="obpt-description-list__value">{render_slot(item)}</dd>
      </div>
    </dl>
  </section>
  """
end
```

Apply the pattern to caller-owned action/evidence/field/body slots. Repeated filters, blockers, and result rows remain normalized maps rather than arbitrary inner HEEx.

Compose semantic leaves instead of recreating them. `Primitives.button/1` already supports permission-disabled discoverability and suppresses actions when a reason exists (`primitives.ex:26-80`):

```elixir
attr(:variant, :atom, default: :neutral, values: @button_variants)
attr(:disabled, :boolean, default: false)
attr(:disabled_reason, :string, default: nil)
slot(:inner_block, required: true)

def button(assigns) do
  disabled_reason = present_text(assigns.disabled_reason)
  described? = not is_nil(disabled_reason)

  rest = visual_safe_rest(assigns.rest, suppress_actions?: described?)

  ~H"""
  <button aria-disabled={@aria_disabled} aria-describedby={@describedby} {@rest}>
    {render_slot(@inner_block)}
  </button>
  <span :if={@disabled_reason} id={@reason_id} class="obpt-sr-only">
    {@disabled_reason}
  </span>
  """
end
```

`Forms.textarea/1` already owns required/error/hint wiring (`forms.ex:54-76`):

```elixir
attr(:field, Phoenix.HTML.FormField, required: true)
attr(:label, :string, required: true)
attr(:hint, :string, default: nil)
attr(:required, :boolean, default: false)

def textarea(assigns) do
  assigns = prepare_field(assigns, "obpt-textarea")

  ~H"""
  <div class="obpt-field" data-obpt-state={@state}>
    <.label for={@id} label={@label} required={@required} />
    <textarea id={@id} name={@name} required={@required}
      aria-invalid={@aria_invalid} aria-describedby={@describedby} {@rest}>{@value}</textarea>
    <.hint :if={@hint} id={@hint_id} text={@hint} />
    <.error :for={{message, error_id} <- @error_items} id={error_id} error={message} />
  </div>
  """
end
```

Use this for confirmation reason and exact bulk count fields. The parent supplies a `Phoenix.HTML.Form` and owns changeset errors and server validation.

#### Per-component analog assignment

| New component | Copy these local patterns | Do not copy |
|---|---|---|
| `confirm_action_dialog/1` | `Forms.textarea/input`, `Primitives.button`, `DataDisplay.data_table/status_pill/toast`, pinned `focus_wrap` and LiveView focus JS | page-local raw modals, browser-only authorization, generic confirm/cancel copy |
| `filter_bar/1` | Phase 75 form ownership; real button disclosure; current same-DOM shell disclosure controller; parent event pattern in `ShowcaseLive` | StatusPill as chip, component-owned URL/query grammar, duplicate mobile field tree |
| `detail_surface/1` | one semantic tree, native `<dialog>`, scoped idempotent controller, parent URL selection precedent in `WorkflowsLive` | unconditional `focus_wrap`, custom host-registered `phx-hook`, duplicate drawer/panel trees |
| `attention_card/1` | `Primitives.card/surface`, status taxonomy, explicit observed/completeness copy | dismissible toast behavior, default alert role, severity as domain status |
| `why_blocked/1` | `DataDisplay.description_list/code_block`, normalized blocker list, `Explain.live_now` vs snapshot split | inference from audit events or snapshots, “root cause” without proof |
| `audit_entry/1` | `<article>` inside `DataDisplay.timeline`, `<time datetime>`, `description_list`, normalized Audit helpers | treating history as current status, relative-only time, hidden missing fields |

### 2. Confirmation focus, lifecycle, and server-truth patterns

There is no local reusable modal component. Use the pinned Phoenix implementations as the exact focus primitives.

`deps/phoenix_live_view/lib/phoenix_component.ex:3148-3184`:

```elixir
attr.(:id, :string, required: true)
attr.(:rest, :global)
slot.(:inner_block, required: true)

def focus_wrap(assigns) do
  ~H"""
  <div id={@id} phx-hook="Phoenix.FocusWrap" {@rest}>
    <div id={"#{@id}-start"} tabindex="0" aria-hidden="true"></div>
    {render_slot(@inner_block)}
    <div id={"#{@id}-end"} tabindex="0" aria-hidden="true"></div>
  </div>
  """
end
```

`deps/phoenix_live_view/lib/phoenix_live_view/js.ex:1019-1063` supplies the pinned operations:

```elixir
JS.focus_first(to: "#modal")
JS.push_focus()
JS.push_focus(to: "#my-button")
JS.pop_focus()
```

Use `focus_wrap` only for `confirm_action_dialog/1`; focus a static title/consequence node with `tabindex="-1"`, then restore the pushed invoker or caller-required logical fallback. The adaptive inline detail surface must not trap focus.

Server truth already exists in `Lifeline.execute_repair/5` (`lifeline.ex:199-213`):

```elixir
with %RepairPreview{} = preview <- repo.get_by(RepairPreview, preview_token: preview_token),
     :ok <- authorize(actor, :execute_repair, %{preview_token: preview.preview_token}),
     :ok <- ensure_preview_available(repo, preview, now),
     :ok <- validate_reason(reason, preview.reason_required),
     {:ok, current_hash} <- recompute_plan_hash(repo, preview),
     :ok <- ensure_not_drifted(repo, preview, current_hash, now),
     {:ok, result} <- apply_repair(repo, preview, actor, reason, now, opts) do
  {:ok, result}
end
```

The eight-character rule and stale status errors are already finite (`lifeline.ex:1011-1042`):

```elixir
trimmed = String.trim(reason)

cond do
  trimmed == "" -> {:error, :reason_required}
  String.length(trimmed) < 8 -> {:error, :reason_too_short}
  true -> :ok
end

case RepairPreview.execute_status(preview, now) do
  :ok -> :ok
  {:error, :preview_expired} ->
    # persist expired continuity state
    {:error, :preview_expired}
  other -> other
end
```

Component/harness plans must render these states truthfully and test against the existing engine; they must not reproduce or weaken the authorization/freshness/single-use path inside HEEx or JavaScript.

### 3. Presenter/normalizer seam

**Preferred analog:** extend `ControlPlanePresenter` with narrow public normalization functions unless cohesion clearly favors one new pure `OperatorPatternPresenter` module.

`control_plane_presenter.ex:191-200` shows the current normalized presentation-map shape:

```elixir
def workflow_refusal(nil), do: nil

def workflow_refusal(rejection) do
  %{
    outcome: "Needs Review",
    reason: rejection.message || refusal_reason_label(rejection.code),
    next_move: legal_next_move_label(rejection.legal_next_steps),
    venue: refusal_venue_label(rejection.legal_next_steps),
    code: rejection.code
  }
end
```

For repeated presentation maps, prefer string-key normalization without atom creation. `StatusTaxonomy.spec/2` (`status_taxonomy.ex:53-79,279-289`) is the safer modern analog:

```elixir
def spec(domain, state) do
  domain_key = domain!(domain)
  state_key = state |> normalize_state() |> resolve_alias(domain_key)

  get_in(registry(), [domain_key, state_key]) ||
    unknown_spec(domain_key, state_key)
end

defp normalize_state(state) when is_atom(state), do: Atom.to_string(state)
defp normalize_state(state) when is_binary(state), do: state
defp normalize_state(state), do: to_string(state)
```

Apply this finite-key approach to active filters, results, blockers, and audit entries. Required copy is trimmed and validated; unknown keys never become DOM attrs; unknown completeness becomes `:unknown`; never call `String.to_atom/1`; never render `inspect(error)`.

Use existing domain readers as **input inventory**, not component contracts:

- `Audit.event_principal/1`, `event_reason/1`, `event_label/1`, and `event_resource_identity/1` (`audit.ex:99-163`) already distinguish missing principal/reason/resource fields. The presenter converts them to explicit copy such as “No operator reason recorded” and “Outcome not recorded.”
- `Explain.explain/3` returns both `live_now` and `snapshot_at_block_start` (`explain.ex:59-71`). Preserve those labels and never promote the snapshot to current truth.
- `RepairPreview` has the closed `ready | drifted | expired | consumed` statuses (`repair_preview.ex:79-101`). Do not expose preview tokens, plan hashes, or raw schema structs through component attrs.

If result pills need shared semantics, extend `StatusTaxonomy` with one closed operator-result domain (`success | failed | skipped`) and tests. Never borrow an unrelated domain or create local color maps.

### 4. `detail_surface/1` and `assets/oban_powertools/theme.js`

There is no exact local adaptive native-dialog implementation. The analog is composite:

1. native `<dialog>` and pinned `JS.ignore_attributes("open")`;
2. the current standalone, host-independent, `.obpt-root`-scoped controller;
3. current same-DOM disclosure behavior;
4. parent-owned URL selection in `WorkflowsLive`.

Pinned LiveView explicitly documents dialog patch preservation (`deps/phoenix_live_view/lib/phoenix_live_view/js.ex:928-968`):

```heex
<dialog phx-mounted={JS.ignore_attributes("open")}>
  ...
</dialog>
```

The shipped JS scopes selectors through the nearest root (`theme.js:82-113`):

```javascript
function closestElement(event, selector) {
  const target = event.target;
  return target && target.closest ? target.closest(selector) : null;
}

function rootForElement(element) {
  return element && element.closest ? element.closest(ROOT_SELECTOR) : null;
}

function shellForElement(element) {
  const root = rootForElement(element);
  const shell = element.closest(APP_SHELL_SELECTOR);
  return !root || !shell || !root.contains(shell) ? null : shell;
}
```

And synchronizes state idempotently (`theme.js:127-151`):

```javascript
function setNavState(shell, state) {
  const nextState = normalizeNavState(state);
  const expanded = nextState === "open";
  shell.setAttribute(ATTR_NAV_STATE, nextState);
  if (toggle) toggle.setAttribute("aria-expanded", expanded ? "true" : "false");
}

function syncNavDisclosures(root) {
  Array.from(root.querySelectorAll(APP_SHELL_SELECTOR)).forEach((shell) => {
    setNavState(shell, shell.getAttribute(ATTR_NAV_STATE));
  });
}
```

Add fixed `data-obpt-*` selectors, root-scoped lookup, an idempotent `syncDetailSurface`, resize synchronization, and narrowly filtered patch observation. When effective mode changes, close before calling `show()` or `showModal()`. Do not require host `LiveSocket` hook registration; do not store or log resource ids, reason text, filters, tokens, or results.

For URL-selected inline detail, copy only the parent ownership from `workflows_live.ex:42-60,163-168`:

```elixir
def handle_params(params, _uri, socket) do
  case Map.get(params, "id") do
    nil -> {:noreply, assign(socket, selected_step: nil)}
    workflow_id -> {:noreply, load_workflow_detail(socket, workflow_id, Map.get(params, "step"))}
  end
end

<.link patch={selected_step_path(@workflow.id, step.step_name)}>Detail</.link>
```

The Phase 78 harness extends this with push-on-first-open, replace-on-selection-switch, replace-on-close, direct-link fallback, and Back behavior. The component itself does not construct paths.

### 5. `assets/oban_powertools/tokens.css` and packaged assets

Continue the exact root-scoped, token-backed CSS convention. `tokens.css:1528-1548`:

```css
.obpt-root .obpt-data-table {
  box-sizing: border-box;
  min-width: 0;
  max-width: 100%;
  border: 1px solid var(--obpt-color-border);
  border-radius: var(--obpt-radius-lg);
  background: var(--obpt-color-surface);
  color: var(--obpt-color-text);
}

.obpt-root .obpt-data-table__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: var(--obpt-space-2);
  padding: var(--obpt-space-3) var(--obpt-space-4);
}
```

Responsive and reduced-motion behavior must have both media-query and root-attribute paths, as in `tokens.css:1712-1720`:

```css
@media (prefers-reduced-motion: reduce) {
  .obpt-root .obpt-data-table__header button {
    transition-duration: var(--obpt-motion-duration-instant);
  }
}

.obpt-root[data-obpt-motion="reduce"] .obpt-data-table__header button {
  transition-duration: var(--obpt-motion-duration-instant);
}
```

Use token-backed `min-width: 0`, `max-width: 100%`, and `overflow-wrap: anywhere` throughout. One bounded machine-data/body region may scroll; the page and ordinary surfaces may not. Use the locked `64rem`-around content breakpoint for adaptive detail and `24rem`/320px reflow where the existing token layer does so. Do not use raw colors, inline styles, or unscoped selectors.

`priv/static/...css` and `...js` are generated only with:

```text
mix oban_powertools.assets.build
```

`assets_test.exs:50-64` pins repeat-build byte equality:

```elixir
checked_in = static_sha256s()
Mix.Task.rerun("oban_powertools.assets.build", [])
first_build = static_sha256s()
Mix.Task.rerun("oban_powertools.assets.build", [])
second_build = static_sha256s()
assert first_build == checked_in
assert second_build == first_build
```

### 6. `test/support/operator_pattern_story_catalog.ex`

Copy `DataDisplayStoryCatalog`'s deterministic, support-only registry shape (`data_display_story_catalog.ex:208-233`):

```elixir
@stories Enum.map(@story_specs, fn story ->
  id = story.id

  %{story |
    test_targets: %{
      story: "obpt-data-story-#{id}",
      snapshot: "showcase/#{id}",
      a11y: ~s([data-obpt-data-story="#{id}"])
    }
  }
end)

@stories_by_id Map.new(@stories, &{&1.id, &1})
def stories, do: @stories
def story!(id), do: Map.fetch!(@stories_by_id, id)
```

Use the group contract instead:

```text
kind: :group
story: obpt-group-story-{id}
snapshot: showcase/{id}
a11y: [data-obpt-group-story="{id}"]
activation: :none | :overlay
```

Keep exactly the 23 IDs and order from D-58 through D-60. Fixtures contain only normalized presentation maps, deterministic absolute timestamps, stable long/Unicode values, and redaction-safe data. Do not include raw secrets, backend structs, Faker, database access, or random time.

`operator_pattern_story_catalog_test.exs` should copy the table-driven exactness from `data_display_story_catalog_test.exs:25-60`:

```elixir
stories = OperatorPatternStoryCatalog.stories()
ids = Enum.map(stories, & &1.id)

assert stories == OperatorPatternStoryCatalog.stories()
assert ids == @ids
assert ids == Enum.uniq(ids)

for id <- @ids do
  story = OperatorPatternStoryCatalog.story!(id)
  assert story.test_targets.snapshot == "showcase/#{id}"
end
```

Add exact `activation` validation and sentinel checks across inspected fixture metadata.

### 7. `lib/oban_powertools/web/dev/showcase_live.ex` and connected harness

Preserve the dev-only and package-fallback boundary. Current integration (`showcase_live.ex:1-34,67-95`) uses module/path pairs and assigns parent-owned state:

```elixir
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  defmodule ObanPowertools.Web.Dev.ShowcaseLive do
    use Phoenix.LiveView

    @data_catalog_module ObanPowertools.DataDisplayStoryCatalog
    @data_catalog_path Path.expand("../../../../test/support/data_display_story_catalog.ex", __DIR__)

    def mount(_params, _session, socket) do
      data_catalog = load_data_catalog()

      {:ok,
       socket
       |> assign(:data_catalog_available?, data_catalog.available?)
       |> assign(:data_stories, data_catalog.stories)
       |> assign(:data_sort_key, "worker")
       |> assign(:data_sort_direction, :asc)}
    end
  end
end
```

The fail-closed loader (`showcase_live.ex:493-540`) is the exact pattern:

```elixir
defp load_data_catalog do
  with {:ok, module} <- ensure_data_catalog_module(),
       true <- function_exported?(module, :stories, 0),
       stories when is_list(stories) <- apply(module, :stories, []) do
    %{available?: true, stories: stories}
  else
    _ -> %{available?: false, stories: []}
  end
end
```

Add the group catalog through the same optional module/path seam. `ShowcaseLive` owns deterministic open state, form validation, draft/applied filters, URL selection/history, overlay activation, confirmation lifecycle/result patches, and flash receipts for stories. Production components remain stateless.

Render group story articles like the current data article (`showcase_live.ex:310-336`), using `data-obpt-group-story`, complete metadata, and a placeholder when the catalog is absent/malformed.

Overlay stories need a single-active-story protocol: initial mount opens no modal overlays; an activation event/query opens only the target under test; each browser case starts on a fresh page. This is an intentional extension to the existing catalog pattern.

### 8. Manifest and browser target pipeline

`scripts/showcase_manifest.exs` currently appends data targets and owns schema/order (`showcase_manifest.exs:107-144`):

```elixir
data_stories = DataDisplayStoryCatalog.stories() |> Enum.map(&serialize_story/1)

targets =
  Enum.map(scenarios, &Map.put(&1, :kind, "scenario")) ++
    primitive_stories ++ form_stories ++ shell_stories ++ data_stories

manifest = %{
  schema_version: 5,
  data_stories: data_stories,
  targets: targets
}
```

Add `group_stories` after `data_stories`, serialize `activation`, append group targets last, and bump exactly once to schema 6. Target count becomes exactly 64: `9 + 7 + 9 + 6 + 10 + 23`.

`manifest.ts` follows a strict discriminated-union and append-order pattern (`manifest.ts:45-74,214-244`):

```typescript
export type ShowcaseDataStory = Omit<ShowcasePrimitiveStory, 'kind'> & {
  kind: 'data';
};

export type ShowcaseTarget =
  | (ShowcaseScenario & { kind: 'scenario' })
  | ShowcasePrimitiveStory
  | ShowcaseFormStory
  | ShowcaseShellStory
  | ShowcaseDataStory;

const expectedTargets = [
  ...scenarios.map((scenario) => ({ kind: 'scenario' as const, ...scenario })),
  ...primitiveStories,
  ...formStories,
  ...shellStories,
  ...dataStories
];
```

Add `ShowcaseGroupStory` with `kind: 'group'` and `activation: 'none' | 'overlay'`; include it in schema 6, validation, expected target order, returned manifest, and exported `groupStories`. Keep story IDs Elixir-owned—TypeScript validates rather than duplicates them.

`manifest-smoke.mjs` remains an independent implementation; do not import `manifest.ts`. Pin schema 6, 23 group entries, activation values, group prefix/selector/snapshot, append order, and 64 total targets.

`showcase.ts` currently prepares a connected deterministic page and uses generic target locators (`showcase.ts:31-85`):

```typescript
await page.goto('/ops/jobs/_showcase');
await expect(page.locator('[data-phx-main].phx-connected')).toHaveCount(1);
// apply viewport and theme

export function targetLocator(page: Page, target: ShowcaseTarget): Locator {
  return page.locator(target.a11y);
}
```

Extend preparation with `activateTarget(page, target)` or equivalent. For `activation === 'overlay'`, activate the one target, assert a single open modal/confirmation, and return its story stage. `showcase.structure`, axe, and VRT must all call the same activation path so overlays are never stacked.

The generic loops remain data-driven. `showcase.vrt.spec.ts:6-16`:

```typescript
for (const theme of themes) {
  for (const target of targets) {
    test(`${target.kind} ${target.id}`, async ({ page }, testInfo) => {
      await prepareShowcase(page, { theme, viewportName });
      await expect(story).toBeVisible();
      await expect(story).toHaveScreenshot([target.snapshot, `${theme}.png`]);
    });
  }
}
```

Insert target activation between preparation and visibility/axe/screenshot. Do not add hardcoded group IDs to the generic VRT/axe specs.

### 9. Component and presenter tests

Copy the existing component render helper and slot-map convention from `data_display_test.exs:880-902`:

```elixir
Phoenix.LiveViewTest.__render_component__(
  ObanPowertools.TestEndpoint,
  Function.capture(@module, component, 1),
  Map.new(assigns),
  []
)

defp slot(name, attrs, fun) do
  %{__slot__: name, inner_block: fn _changed, argument -> call_slot_fun(fun, argument) end}
  |> Map.merge(attrs)
end
```

Use export/source contracts, semantic DOM selectors, information-order assertions, exact copy, hostile HTML, and full-DOM sentinel absence. The existing source guard pattern (`data_display_test.exs:853-877`) is directly reusable:

```elixir
source = File.read!(@source_path)

for forbidden <- [
      "Phoenix.HTML.raw",
      "String.to_atom",
      ~s(style=),
      "document.",
      "raw_value",
      "original_value"
    ] do
  refute source =~ forbidden
end
```

Adjust prohibitions for the component's legitimate pinned `focus_wrap`/JS use. Assert no caller visual escape hatch, raw error inspection, backend schema pattern matching, nested dialogs, duplicate responsive trees, secret-bearing attrs, or inferred truth.

Presenter tests should be table-driven and pure. Pin atom/string parity without atom creation, required key failures, stable ids/order, explicit unknown/unavailable copy, absolute audit timestamps, missing reason/outcome copy, and current-vs-snapshot labels.

### 10. Connected LiveView tests

Use `ObanPowertools.LiveCase` and real LiveView selectors/events like `showcase_live_test.exs:388-418`:

```elixir
{:ok, view, _html} = mount_showcase!(conn)

assert has_element?(view, "#{story} th[aria-sort='ascending']")

view
|> element("#{story} button[phx-click='sort-data-table']")
|> render_click()

assert has_element?(view, "#{story} th[aria-sort='descending']")
```

Required connected proof belongs here or in a dedicated `operator_patterns_harness_test.exs`:

- short/blank reason and wrong bulk count retain the preview with errors;
- valid inputs submit once and server-side validation is invoked;
- expired/drifted/consumed execution rejects through real Lifeline APIs;
- partial rows retain deterministic success/failed/skipped distinctions and recovery links;
- filter draft does not alter applied URL/results until Apply; invalid direct URLs canonicalize with replace;
- initial detail open pushes, switch/close replace, Back closes, direct URL loads with fallback;
- drawer-to-confirmation transition never nests dialogs.

Keep package-fallback tests for absent and non-list catalogs. The existing tests guard the LiveView with the same `Application.compile_env` condition and exercise isolated child VMs; extend that pattern for the group catalog.

### 11. Focused Playwright behavior

Copy the setup and connected-socket guard from `data-display.behavior.spec.ts:22-37`:

```typescript
await prepareShowcase(page, {
  theme,
  viewportName: viewportNameFromProject(projectName)
});
await expect(page.locator('[data-phx-main].phx-connected')).toHaveCount(1);

const locator = targetLocator(page, story);
await expect(locator).toBeVisible();
```

Copy computed-style evidence rather than merely asserting `:focus` (`data-display.behavior.spec.ts:51-82`), and reuse the no-horizontal-overflow helper (`:39-49`).

The new spec must prove the transitions static render tests cannot:

- Confirm dialog: static initial focus, Tab/Shift-Tab wrap, Escape/visible close, invoker/fallback restore, busy/duplicate suppression, result-heading focus, one exact receipt.
- FilterBar: disclosure keyboard/ARIA, collapsed tab order, draft/applied divergence, Apply/remove/Clear URL changes, exact restrained status message, 320px no overflow.
- DetailSurface: `dialog.matches(':modal')` below the breakpoint and not wide, native inertness only when modal, modal containment, wide no-trap, resize mode changes, URL/history, restore/fallback.
- Explanation/audit: no default alert, visible non-color severity, all blockers/clearing conditions, honest unknown evidence, absolute time, missing-field copy, secret sentinel absent from text and all attributes/details/destinations.

At minimum run `chromium-320` and `chromium-wide`; use tablet for adaptive transition evidence.

### 12. CSS/assets tests

Extend `theme_tokens_test.exs` with an `@group_classes` plus `group_blocks/1`, parallel to the existing data family (`theme_tokens_test.exs:361-402,625-651`):

```elixir
group_blocks = group_blocks(css)

for {selector, body} <- group_blocks do
  for part <- selector_parts(selector) do
    assert String.starts_with?(part, ".obpt-root")
  end

  refute body =~ ~r/#[0-9a-fA-F]{3,8}/

  for {property, value} <- declarations(body), group_visual_property?(property) do
    assert String.contains?(value, "var(--obpt-")
  end
end
```

Pin the adaptive breakpoint, 320px reflow, focus-visible, high-contrast/non-color markers, one body scroll region, and both reduced-motion paths. Do not broaden literal allowlists when a token can express the value.

Extend `assets_test.exs` with representative group CSS selectors and JS selectors/functions, while preserving repeat-build hashes. Also reject host selectors, custom hook registration requirements, localStorage for component state, `eval`, `new Function`, and sensitive logging/storage.

### 13. `test/browser/support/verify-group-baselines.mjs` and PNGs

`verify-data-baselines.mjs` is an exact analog. Its manifest-derived matrix (`verify-data-baselines.mjs:73-115`) and set comparison (`:138-155`) prevent stale/missing/extra images; `--changed-scope` parses porcelain status including renames (`:158-216`).

Copy it with these substitutions:

```text
data_stories -> group_stories
kind "data" -> kind "group"
snapshot prefix showcase/data- -> showcase/group-
expectedCount 120 -> 276
schema_version 5 -> 6
```

The exact expected matrix is `23 x 4 x 3 = 276`. Run default exact-set validation and `--changed-scope`; reject any changed screenshot outside group paths. The baseline update uses canonical Docker rendering once, followed by a compare-only pass. Do not refresh the unrelated 108 scenario residual documented by prior phases.

### 14. `.planning/.../78-VALIDATION.md`

At closeout, reconcile actual plan/task IDs and set Nyquist compliance only after execution evidence exists. Record:

- focused ExUnit component/presenter/harness/catalog/CSS/assets/package tests;
- schema-6 manifest and independent smoke checks;
- connected 320/tablet/wide behavior results;
- focused group axe with zero critical/serious issues;
- Docker VRT update and compare-only result;
- exact 276 baseline equality and changed-scope output;
- source/static CSS and JS byte equality and repeated-build stability.

Test discovery, static markup, or baseline existence alone are not completion evidence.

## Shared Patterns

### Stateless ownership boundary

**Apply to:** all six production components, presenter APIs, client controller.

- Components render caller-supplied truth and emit constrained actions.
- Parent LiveViews own authorization, data, URL/history, state, validation, redaction, mutations, results, and receipts.
- Client JS owns only modality/disclosure/focus presentation; it never becomes a business-state source of truth.

### Finite input normalization

**Source:** `StatusTaxonomy` and existing safe-rest helpers.

- Closed enums use explicit finite lists.
- Presentation maps fetch only documented atom/string aliases.
- Unknown evidence remains unknown; missing completeness defaults to unknown.
- No dynamic atom creation, raw structs, raw error inspection, or arbitrary keys reaching DOM attrs.

### Structural redaction

**Source:** `DataDisplay` sentinel tests and normalized-only `ArgsViewer` boundary.

- Normalize/redact before rendering.
- Assert the original sentinel is absent from the complete HTML/DOM, attributes, titles, data attrs, details, destinations, and copy channels.
- Visually hidden or collapsed content is still rendered content and is not a redaction mechanism.

### One responsive DOM tree

**Source:** Phase 76/77 shell/data patterns and root-scoped CSS.

- Filter fields and adaptive details render once.
- CSS/client behavior changes presentation, not tree identity.
- Prevent duplicate ids, duplicate event controls, divergent keyboard behavior, and hidden sensitive duplicates.

### Deterministic dev/test evidence

**Source:** data story catalog, schema pipeline, generic target loops, independent baseline verifier.

- Elixir catalog owns exact ids/order/fixtures/targets.
- Manifest validation is independent in TypeScript and Node.
- Overlay activation is one-at-a-time.
- Browser cases start fresh and assert connected LiveView behavior.

## No Exact Local Analog

| File/Concern | Why no exact analog | Required composite source |
|---|---|---|
| `detail_surface/1` adaptive native-dialog controller | Project has no current native `<dialog>` switching between `show()` and `showModal()` across resize/patch | pinned `JS.ignore_attributes`, current scoped `theme.js`, native dialog contract from research, connected Playwright proof |

`operator_patterns.ex` itself has no prior meta-component module, but its role and data flow are fully covered by the exact lower-layer component conventions. The planner should treat the six public APIs as new composition, not invent a new architecture.

## Planner-Oriented Touch Order

1. RED contracts: component/presenter/catalog/browser behavior files.
2. Pure normalizers plus AttentionCard, WhyBlocked, and AuditEntry.
3. FilterBar and scoped disclosure/harness behavior.
4. ConfirmActionDialog and real server validation/stale-result evidence.
5. DetailSurface and native-dialog controller/URL/focus evidence.
6. Catalog, ShowcaseLive activation, schema-6 manifest/browser pipeline, and package fallback.
7. Connected behavior, axe, exact 276 Docker baselines, compare-only pass, asset equality, validation closeout.

Plans touching `operator_patterns.ex`, `tokens.css`, or `theme.js` should remain sequential. ConfirmActionDialog and DetailSurface should not share an implementation plan because their state/focus risks are independent.

## Metadata

**Analog search scope:** `lib/oban_powertools`, `assets/oban_powertools`, `test/oban_powertools`, `test/support`, `test/browser`, `scripts`, and pinned `deps/phoenix_live_view` API source  
**Primary analog families read:** component/presenter, Lifeline/Audit/Explain truth seams, scoped CSS/JS, story/showcase/manifest, ExUnit/browser/VRT validation  
**Pattern extraction date:** 2026-07-18

---

*Pattern mapping complete for Phase 78 planning. This artifact maps implementation conventions only; it does not create PLAN.md files or production implementation.*
