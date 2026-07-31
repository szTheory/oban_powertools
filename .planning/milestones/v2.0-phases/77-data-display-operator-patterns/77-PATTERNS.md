# Phase 77: Data-Display & Operator Patterns - Pattern Map

**Mapped:** 2026-07-12  
**Files analyzed:** 33 production, support, test, browser, and planning files  
**Expected implementation files:** 8 new source/test/support files, 11 modified source/test files, 1 validation artifact, and 120 generated VRT baselines

## Scope And Instruction Check

- The binding inputs are `77-CONTEXT.md` decisions D-01 through D-25, the approved `77-UI-SPEC.md`, `77-RESEARCH.md`, and `77-VALIDATION.md`.
- No root `CLAUDE.md`, `.claude/CLAUDE.md`, root `AGENTS.md`, or project-local skill applies. `examples/phoenix_host_upgrade_source/AGENTS.md` is below a fixture subtree and is outside this phase's files.
- The worktree already contains unrelated deleted planning files and untracked worktree/review artifacts. Phase 77 plans must preserve them and must not use broad cleanup.
- Existing production page tables, badge helpers, progress bars, and code panels are migration inventory, not files to rewrite in Phase 77. D-15 defers the nine page-body migrations to Phases 79-81.

## Architecture And Data Flow

```text
parent LiveView / presenter
  owns fetch, auth, sort, pagination, selection, URL and events
             |
             +--> StatusTaxonomy.spec(domain, state)
             |       -> %{label, tone, icon, sr_prefix}
             |       -> DataDisplay.status_pill -> Primitives.status_pill
             |
             +--> DisplayPolicy.render_job_field/3 or workflow_result/2
             |       -> normalized tuple/map only (never raw + display together)
             |       -> ArgsViewer -> CodeBlock or RedactedValue
             |
             +--> DataDisplay function components
                     -> one semantic DOM tree
                     -> token-backed .obpt-root CSS

DataDisplayStoryCatalog (test/support only)
  -> ShowcaseLive runtime loading and real story rendering
  -> showcase_manifest.exs schema 5
  -> manifest.ts / showcase.ts
  -> generic VRT + axe target loops
  -> focused data-display behavior spec
```

The key ownership convention is already stated in `Primitives`: stateless components own semantic markup, accessible names, closed visual variants, and safe caller attributes; parent LiveViews own data, authorization, events, and mutations. `DataDisplay` must preserve that boundary even when `ShowcaseLive` adds a dev/test-only sort event to prove parent-owned state changes.

## File Classification

| Expected File | Change | Role | Data Flow | Closest Existing Analog | Match |
|---|---|---|---|---|---|
| `lib/oban_powertools/web/status_taxonomy.ex` | new | pure presenter/registry | domain + state -> presentation map | `lib/oban_powertools/web/control_plane_presenter.ex` | role-match |
| `lib/oban_powertools/web/components/data_display.ex` | new | stateless component library | assigns/slots -> escaped HEEx | `lib/oban_powertools/web/components/primitives.ex`, `forms.ex`; Phoenix generated table template | composite |
| `test/oban_powertools/web/status_taxonomy_test.exs` | new | pure unit contract | registry inputs -> exact specs | presenter tests plus `primitive_story_catalog_test.exs` deterministic-map style | role-match |
| `test/oban_powertools/web/components/data_display_test.exs` | new | component/render/security contract | assigns/slots -> HTML/source assertions | `primitives_test.exs`, `forms_test.exs` | exact style |
| `test/support/data_display_story_catalog.ex` | new | dev/test story catalog | fixed specs -> targets + fixtures | `shell_story_catalog.ex`, `form_story_catalog.ex` | exact |
| `test/oban_powertools/data_display_story_catalog_test.exs` | new | catalog contract | catalog -> order/coverage/bounds | `shell_story_catalog_test.exs`, `form_story_catalog_test.exs` | exact |
| `test/browser/specs/data-display.behavior.spec.ts` | new | focused browser behavior | live showcase -> keyboard/layout/security assertions | `forms.behavior.spec.ts`, `shell.behavior.spec.ts` | exact style |
| `test/browser/support/verify-data-baselines.mjs` | new | independent baseline verifier CLI | manifest + screenshot tree/git status -> exact-set and changed-scope diagnostics | `manifest-smoke.mjs` independent Node gate | role-match |
| `assets/oban_powertools/tokens.css` | modify | token-scoped component CSS | data attributes/classes -> layout/theme/motion | existing primitive/form/shell blocks in same file | exact |
| `priv/static/oban_powertools/oban_powertools.css` | regenerate | packaged asset | normalized token CSS -> shipped bytes | same file via `mix oban_powertools.assets.build` | exact |
| `lib/oban_powertools/web/dev/showcase_live.ex` | modify | dev/test LiveView | catalogs + parent sort assign -> story DOM | primitive/form/shell catalog loading and story bodies | exact |
| `scripts/showcase_manifest.exs` | modify | manifest generator | Elixir catalogs -> JSON | schema 4 primitive/form/shell pipeline | exact |
| `test/browser/support/manifest.ts` | modify | runtime validator/types | JSON -> typed target registry | existing component-story validation | exact |
| `test/browser/support/manifest-smoke.mjs` | modify | generated-manifest smoke test | JSON -> schema/order checks | existing schema 4 checks | exact |
| `test/browser/support/showcase.ts` | modify | browser target support | typed targets -> locators/structure | existing target-kind branches | exact |
| `test/browser/specs/showcase.structure.spec.ts` | modify | generic structure test | all targets -> one structure gate | current title/target loop | exact |
| `test/oban_powertools/web/live/showcase_live_test.exs` | modify | LiveView render contract | route/live DOM -> story assertions | existing primitive/form/shell sections | exact |
| `test/oban_powertools/web/theme_tokens_test.exs` | modify | CSS static contract | CSS text -> scoped/token rules | `primitive_blocks/1`, `shell_blocks/1` | exact |
| `test/oban_powertools/web/assets_test.exs` | modify | packaged asset contract | compiled bytes -> selector/build assertions | current primitive/shell selector list | exact |
| `.planning/phases/77-data-display-operator-patterns/77-VALIDATION.md` | modify at closeout | execution evidence | commands/results -> Nyquist sign-off | Phase 76 validation closeout | exact |
| `test/browser/__screenshots__/chromium-{320,tablet,wide}/showcase/data-*/{system,light,dark,high-contrast}.png` | new, 120 files | VRT baselines | story x theme x viewport -> PNG | existing primitive/form/shell baseline tree | exact |

The ignored `test/browser/.generated/showcase-manifest.json` is regenerated by `npm run showcase:manifest`; it is not a tracked implementation change. No `mix.exs`, `mix.lock`, `package.json`, `package-lock.json`, `assets/oban_powertools/theme.js`, or production page LiveView change is expected.

## Pattern Assignments

### `lib/oban_powertools/web/status_taxonomy.ex`

**Closest analog:** `ObanPowertools.Web.ControlPlanePresenter` is the nearest pure, shared presentation module. It keeps labels in module attributes, accepts atoms and strings, and humanizes unknown values:

```elixir
@status_labels %{
  needs_review: "Needs Review",
  blocked: "Blocked",
  waiting: "Waiting",
  runnable: "Runnable",
  resolved: "Resolved",
  bridge_only: "Bridge-only Follow-up"
}

def status_label(status) when is_binary(status) do
  String.to_existing_atom(status) |> status_label()
rescue
  ArgumentError -> humanize(status)
end

def status_label(status), do: Map.get(@status_labels, status, humanize(status))

def humanize(atom) when is_atom(atom), do: humanize(Atom.to_string(atom))
def humanize(bin) when is_binary(bin) do
  bin |> String.replace("_", " ") |> String.capitalize()
end
```

**Apply with an intentional safety improvement:** use a closed atom domain registry but string-key status maps. Normalize a state with `to_string/1`; do not call `String.to_atom/1` or `String.to_existing_atom/1`. Unknown state values inside a known domain return deterministic neutral specs. Unknown domains raise because no truthful `sr_prefix` exists.

The required public data shape already matches `Primitives.status_pill/1`:

```elixir
%{label: "Retryable", tone: :warning, icon: :alert, sr_prefix: "Job state"}
```

Recommended finite API from research:

- `spec(domain, state)` returns exactly the four-key primitive spec.
- `all_specs/0` returns a deterministic ordered audit list containing domain/state metadata as well as the presentation spec.
- Domain is mandatory. Do not add `spec(state)` because `pending`, `active`, `blocked`, and `expired` collide across domains.
- Keep aliases explicit (`lifeline_preview`: `pending -> ready`, `executed -> consumed`; lease expiry is a derived state, not a mutation of stored callback status).

**Inventory sources, not tone authorities:**

- `jobs_live.ex:1100-1104` has a five-case `state_badge_tone/1`.
- `batches_live.ex:1075-1089` has raw class maps for status and severity.
- `lifeline_live.ex:938-982` has preview and incident badge maps.
- `control_plane_presenter.ex:13-25`, `140-168` has labels for control-plane, completeness, and host follow-up values.
- `forensics/provenance.ex:3` defines `[:complete, :partial_evidence, :history_unavailable, :unknown]`.
- `forensics/cron_history.ex` contains `missed_fire`, `overlap_relevant`, and partial-evidence states.
- `host_escalation.ex:8-10` owns the three host-follow-up status strings.

The UI-SPEC tone table is canonical where legacy raw classes differ. In particular, the old Lifeline `expired` class is slate/neutral, but the approved taxonomy makes terminal preview expiry danger.

### `lib/oban_powertools/web/components/data_display.ex`

**Primary analog:** `Primitives` establishes the module/API/safety convention:

```elixir
use Phoenix.Component

attr(:spec, :any, default: nil)
attr(:label, :string, default: nil)
attr(:tone, :atom, default: :neutral, values: @tones)
attr(:icon, :atom, default: nil)
attr(:sr_prefix, :string, default: nil)
attr(:rest, :global, default: %{})

def status_pill(assigns) do
  assigns = apply_status_spec(assigns)
  # normalize closed values, then render HEEx
end
```

Its safe-rest implementation is the direct convention to reuse:

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

`Primitives.status_pill/1`, `skeleton/1`, and `stat/1` are composition points, not code to duplicate:

```elixir
<span class="obpt-status-pill" data-obpt-tone={@tone} data-obpt-size={@size} {@rest}>
  <span :if={@sr_prefix} class="obpt-sr-only">{@sr_prefix}: </span>
  ...
</span>

<div class="obpt-skeleton" role="status" aria-busy="true" aria-label={@label} {@rest}>
  ...
</div>

<dl class="obpt-stat" data-obpt-tone={@tone} {@rest}>...</dl>
```

**Component-specific boundaries:**

- `status_pill/1` should call `StatusTaxonomy.spec/2` and delegate to `Primitives.status_pill/1`.
- `metric_card/1` may wrap `Primitives.card/1` and `Primitives.stat/1`; do not create nested cards or implicit click behavior.
- Loading tables should compose named `Primitives.skeleton/1` output and keep `aria-busy` on the owning data region.
- Row selection stories should use `Forms.checkbox/1`. Its event-selection behavior omits the hidden unchecked input/name when `phx-click` is present, preventing duplicate form values:

```elixir
<label class="obpt-choice" for={@id}>
  <input type="checkbox" id={@id} name={@name} ... {@rest} />
  <span>{@label}</span>
</label>
```

#### DataTable slot pattern

The installed Phoenix generator is the closest table-composition analog (`deps/phoenix/installer/templates/phx_web/components/core_components.ex.eex:350-388`):

```elixir
attr :id, :string, required: true
attr :rows, :list, required: true
attr :row_id, :any, default: nil

slot :col, required: true do
  attr :label, :string
end

slot :action

<tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
  <td :for={col <- @col}>{render_slot(col, @row_item.(row))}</td>
</tr>
```

Extend that established `rows`/`row_id`/repeated `:col`/`render_slot(col, row)` shape with the locked DataTable contract: required caption, explicit state, counts/pagination, optional toolbar/selection/action, sortable column metadata, and visible mobile cell labels.

Render one table tree. At the 24rem breakpoint, CSS reflows the same `<tbody>/<tr>/<td>` into stacked cards and reveals a real label within each cell. Do not render separate desktop and mobile trees: duplicated ids, checkbox names, actions, and hidden sensitive values are unacceptable.

Sortable headers are buttons inside `<th scope="col">`. Set `aria-sort` only on the active header, and let `sort_event`/`phx-value-*` notify the parent. Do not use `role="grid"`, client-side sorting, or a table JS package.

#### Secondary semantic patterns

| Component | Required markup/convention | Existing composition point |
|---|---|---|
| DescriptionList/KeyValue | `<dl>` with repeated `<dt>/<dd>`, `min-width: 0` | `Primitives.stat/1` demonstrates valid dl markup |
| Timeline | `<ol>` with timestamp/title/source and optional detail slot | current `cron_live.ex:238` proves ordered-event intent, but not styling |
| ProgressBar | native `<progress value max>` for determinate values; omit fake value when unavailable | intentionally replaces `batches_live.ex` inline width style |
| MetricCard | one card/surface plus `Primitives.stat/1` | `Primitives.card/1`, `stat/1` |
| CodeBlock | `<figure><figcaption><pre tabindex="0"><code>`; escaped text and bounded internal overflow | jobs/batches `<pre>` panels are content inventory only |
| Machine value | middle truncation plus native `<details>/<summary>` or other explicit expansion | no exact component analog; no JS clipboard is required |
| EmptyState | heading + body + optional semantic Button/Link action | primitive Button/Link composition |
| Toast/Flash | closed tone and urgency; polite status by default, alert only for immediate failure | no exact reusable component analog |

`ProgressBar` should intentionally deviate from the current page-local implementation:

```elixir
# batches_live.ex:390 and :798 -- migration inventory, do not copy
<div class="h-2 bg-indigo-600" style={"width: #{progress_width(percent)}"}></div>
```

Native `<progress>` avoids the forbidden inline `style` escape hatch while supplying range semantics.

#### ArgsViewer and RedactedValue

`DisplayPolicy` already defines the boundary (`runtime_config.ex:202-250`):

```elixir
nil                -> {:raw_json, Jason.encode!(value || %{}, pretty: true)}
text when binary   -> {:string, text}
map when is_map    -> {:raw_json, Jason.encode!(map, pretty: true)}
policy failure     -> {:fallback, "[redacted]"}
```

It also preserves the host-policy contract: enqueue overlay markers are added only on the default path; host-returned strings/maps are not overlaid again. `workflow_result/2` and `job_recorded/2` return explicit maps containing `available?`, `redacted?`, summary, payload, and status.

Apply these rules:

- `ArgsViewer` receives normalized tuple/map output only. It must not invoke host callbacks or accept a raw secret beside a display value.
- `{:raw_json, json}` and `{:string, text}` render labelled CodeBlock/text output; `{:fallback, msg}` renders only through RedactedValue.
- `RedactedValue` uses a narrow closed reason API (`:enqueue`, `:policy`, `:fallback`) and should not expose a general inner slot, tooltip, copy control, `title`, or global `data-*` passthrough.
- Exact visible copy is `Redacted at enqueue`, `Hidden by display policy`, and `[redacted]` only inside the component.
- Preserve visible non-redacted siblings. Assert a unique secret sentinel is absent from the entire rendered HTML, not merely the text node.

### `test/oban_powertools/web/status_taxonomy_test.exs`

Use `ExUnit.Case, async: true` and table-driven assertions. The deterministic catalog tests show the local style:

```elixir
stories = ShellStoryCatalog.stories()
ids = Enum.map(stories, & &1.id)

assert stories == ShellStoryCatalog.stories()
assert ids == @ids
assert ids == Enum.uniq(ids)
```

Pin:

- every mandatory UI-SPEC domain/value tuple and each selected supplemental source-audit state;
- exact `%{label, tone, icon, sr_prefix}` output;
- atom/binary state parity without atom creation;
- preview aliases and domain collisions;
- neutral/dot/humanized unknown-state fallback within each domain;
- unknown-domain failure;
- stable, unique, ordered `all_specs/0` output.

The source guard should explicitly reject `String.to_atom` and `String.to_existing_atom` in the new taxonomy module. Do not globally ban those calls in legacy production modules during this phase.

### `test/oban_powertools/web/components/data_display_test.exs`

Reuse the exact render helper from `primitives_test.exs` / `forms_test.exs`:

```elixir
Phoenix.LiveViewTest.__render_component__(
  ObanPowertools.TestEndpoint,
  Function.capture(@data_display_module, component, 1),
  Map.new(assigns),
  []
)
```

Their slot helper shape is also reusable:

```elixir
[%{
  __slot__: :inner_block,
  inner_block: fn _changed, _argument -> Phoenix.HTML.raw(text) end
}]
```

For DataTable, add repeated slot maps with slot attrs (`label`, optional `sort_key`) and an `inner_block` accepting the row argument. Avoid relying only on string matching when `LazyHTML`/LiveView selectors can prove element relationships.

Required groups:

1. Export/source contracts for all components and `use Phoenix.Component`.
2. Native table/caption/header/body semantics, stable row ids, counts, pagination, toolbar, selection/action seams.
3. One active `aria-sort`, native header buttons, and no ARIA grid roles.
4. All six states: ready, loading, empty, error, unavailable, permission denied; loading has named busy semantics.
5. Mobile label text exists in the same table DOM.
6. `<dl>/<dt>/<dd>`, `<ol>`, `<progress>`, `<pre><code>`, metric, toast roles, and dismiss accessible names.
7. Hostile content is escaped.
8. `class`, `style`, role overrides, inline handlers, and inappropriate action attrs are removed.
9. Full redaction matrix with a unique secret sentinel absent from HTML/attributes/details/copy channels.
10. Source guards: no raw hex/pixel component literals, host selectors, raw HTML APIs, inline width styles, dynamic atom conversion, table JS hooks, or production page imports.

Existing policy fixture modules in `test/oban_powertools/web/live/jobs_live_test.exs:1-53` already cover nil, string, map, raising, and host-custom-map arms and provide proven expectations. Prefer extracting or recreating narrow local fixtures in the component test rather than coupling the new async component test to the large non-async LiveView test module.

### `test/support/data_display_story_catalog.ex`

Copy the separate registry shape from `ShellStoryCatalog` and `FormStoryCatalog`, not the domain `ShowcaseCatalog`:

```elixir
@stories Enum.map(@story_specs, fn story ->
  id = story.id
  %{story | test_targets: %{
      story: "obpt-shell-story-#{id}",
      snapshot: "showcase/#{id}",
      a11y: ~s([data-obpt-shell-story="#{id}"])
  }}
end)

@stories_by_id Map.new(@stories, &{&1.id, &1})
def stories, do: @stories
def story!(id), do: Map.fetch!(@stories_by_id, id)
```

Use the data prefix instead:

```text
kind: :data
story: obpt-data-story-{id}
snapshot: showcase/{id}
a11y: [data-obpt-data-story="{id}"]
```

Keep exactly this locked order:

1. `data-table-sort-states`
2. `data-table-320-stacked`
3. `data-table-explicit-states`
4. `data-status-taxonomy-all`
5. `data-description-list-long-values`
6. `data-timeline-event-log`
7. `data-progress-metric-cards`
8. `data-code-args-redaction`
9. `data-empty-toast-flash`
10. `data-table-thousands-row-stress`

Reuse fixture values, not catalog ownership, from `ShowcaseCatalog`: long jobs at lines 83-146, boundary pagination at 269-309, non-ASCII/emoji/RTL audit events at 340-370, and long URL/stacktrace/timeline data at 374-401. The new catalog may own deterministic derived maps/comprehensions. Avoid Faker, database inserts, random timestamps, and cross-support-module compile-order coupling.

The thousands-row story must represent a large truthful total while rendering a small deterministic window (for example, 20 rows with pinned first/last keys). Literal thousands of DOM rows would slow every VRT/axe target because the full showcase mounts for each target.

### `test/oban_powertools/data_display_story_catalog_test.exs`

Follow `shell_story_catalog_test.exs`:

- exact ordered ids and uniqueness;
- `kind == :data`, non-empty `component/components/variant/state/name/description`;
- derived lookup/snapshot/a11y targets;
- exact component and state coverage;
- all taxonomy audit specs represented;
- bounded thousands-row window with truthful row count and stable endpoints;
- deterministic repeated return values;
- no raw secret sentinel in inspected story metadata.

### `lib/oban_powertools/web/dev/showcase_live.ex`

The existing dev-only compile guard and runtime support loading must remain unchanged in principle:

```elixir
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  defmodule ObanPowertools.Web.Dev.ShowcaseLive do
    use Phoenix.LiveView
    ...
  end
end
```

Current catalogs are configured as module/path pairs and loaded through `ensure_support_module/2`:

```elixir
@shell_catalog_module ObanPowertools.ShellStoryCatalog
@shell_catalog_path Path.expand("../../../../test/support/shell_story_catalog.ex", __DIR__)

defp ensure_support_module(module, path) do
  cond do
    Code.ensure_loaded?(module) -> {:ok, module}
    Mix.env() != :test and File.exists?(path) ->
      Code.require_file(path)
      if Code.ensure_loaded?(module), do: {:ok, module}, else: :error
    true -> :error
  end
end
```

Add the data catalog through the same path, mount assigns, availability fallback, stable story article metadata, and a `data_story_body/1` renderer. Replace only the `data-display` placeholder; keep all other future-section placeholders.

For the sort story, `ShowcaseLive` should own a narrow `data_sort_key` / `data_sort_direction` assign and event handler. The event changes the parent assign, causing DataTable to re-render truthful `aria-sort`. This is an evidence fixture, not state embedded in the production component.

The article convention to duplicate is:

```heex
<article
  id={target_value(story.test_targets, :story)}
  data-obpt-data-story={story.id}
  data-obpt-component={component_value(story)}
  data-obpt-variant={state_value(story.variant)}
  data-obpt-state={state_value(story.state)}
  data-obpt-a11y-target={target_value(story.test_targets, :a11y)}
>
```

### Manifest pipeline files

#### `scripts/showcase_manifest.exs`

The schema 4 flow is explicit:

```elixir
targets =
  Enum.map(scenarios, &Map.put(&1, :kind, "scenario")) ++
    primitive_stories ++ form_stories ++ shell_stories

manifest = %{
  schema_version: 4,
  ...,
  shell_stories: shell_stories,
  targets: targets
}
```

Add `DataDisplayStoryCatalog`, serialize the common story fields, append `data_stories` after `shell_stories`, append data targets last, and bump to schema 5. Do not duplicate the data ids anywhere in TypeScript.

#### `test/browser/support/manifest.ts`

Follow the existing `ShowcaseFormStory` alias and `validateComponentStory` path:

```ts
export type ShowcaseFormStory = Omit<ShowcasePrimitiveStory, 'kind'> & {
  kind: 'form';
};
```

Add `ShowcaseDataStory` with `kind: 'data'`, include it in `ShowcaseTarget`, schema literal 5, `data_stories`, validation/count 10, expected target append order, `validateTarget`, `validateComponentStory` collection/kind unions, error copy, returned manifest, and `dataStories` export.

#### `test/browser/support/manifest-smoke.mjs`

Mirror the form loop with data prefix/selector validation, exact count 10, schema 5, append order, target field comparisons, and updated success output. This script is deliberately independent of the TypeScript validator and must not be reduced to importing it.

#### `test/browser/support/showcase.ts`

Add a `target.kind === 'data'` structure branch asserting:

- `data-obpt-data-story` equals target id;
- component, variant, state, and a11y metadata match the manifest.

The target locator stays generic (`page.locator(target.a11y)`).

#### `test/browser/specs/showcase.structure.spec.ts`

The body already loops all generated targets and needs no hardcoded ids. Update the test title from `scenario primitive form shell targets` to include `data`; this also makes focused discovery/grep output truthful.

### Browser behavior and generic evidence

#### `test/browser/specs/data-display.behavior.spec.ts`

Use the helper style from `forms.behavior.spec.ts` and `shell.behavior.spec.ts`:

```ts
function dataStory(id: string): ShowcaseDataStory {
  const story = dataStories.find((candidate) => candidate.id === id);
  if (!story) throw new Error(`Missing data story in generated manifest: ${id}`);
  return story;
}

await prepareShowcase(page, {
  theme,
  viewportName: viewportNameFromProject(testInfo.project.name)
});
const story = targetLocator(page, dataStory('...'));
```

Reuse the computed-style focus helpers from the form/shell specs rather than checking only `:focus`. Required proof includes:

- click and Enter/Space change parent-owned sort and `aria-sort`; exactly one active sorted header;
- visible focus across all four themes;
- 320px computed display/layout shows stacked rows and visible column labels;
- document/body/story overflow delta is at most 1px;
- row-selection accessible names and effective 44px hit area;
- long identifiers preserve useful ends or expose explicit native expansion;
- CodeBlock is focusable, internally scrollable, bounded, and does not cause page overflow;
- redaction copy is visible and a secret sentinel is absent from text, titles, `data-*`, details, and copy-related markup;
- toast live roles/urgency and dismiss behavior do not steal focus;
- determinate progress clamps values and unavailable progress has no fake value;
- thousands-row story reports the large total while DOM rows remain bounded and stable.

Run behavior at minimum on `chromium-320` and `chromium-wide`; do not infer responsive proof from one project.

#### Existing generic VRT and axe specs

`showcase.vrt.spec.ts` and `showcase.a11y.spec.ts` already iterate all `targets` for all `themes`. Do not add data-specific ids or modify their logic. Once schema 5 appends data targets, they automatically produce 10 x 4 x 3 = 120 data cases in each gate.

Baseline path/cardinality analogs are exact:

- 6 shell stories currently produce 72 tracked PNGs.
- 9 form stories currently produce 108 tracked PNGs.
- 7 primitive stories currently produce 84 tracked PNGs.
- Therefore 10 data stories must produce exactly 120 tracked PNGs under the three project directories and four theme filenames.

Create `test/browser/support/verify-data-baselines.mjs` as an independent CLI gate. Its default mode derives and validates the exact manifest-backed data screenshot set and cardinality 120. Its `--changed-scope` mode parses screenshot changes and rejects tracked, untracked, and renamed paths outside the expected `data-*` matrix.

### CSS and packaged assets

#### `assets/oban_powertools/tokens.css`

Continue the exact root-scoped/token-backed pattern:

```css
.obpt-root .obpt-stat {
  display: grid;
  gap: var(--obpt-space-1);
  margin: 0;
  min-width: 0;
  color: var(--obpt-color-text);
}

.obpt-root .obpt-input:focus-visible {
  outline: 2px solid var(--obpt-color-focus);
  outline-offset: 2px;
}

@media (max-width: 24rem) {
  .obpt-root .obpt-primitive-matrix { grid-template-columns: 1fr; }
}
```

Data classes must all remain below `.obpt-root`, use `var(--obpt-*)` for visual values, provide 24rem table reflow/mobile-label rules, visible sort/action/code focus, token-derived selection hit area, bounded code overflow, tone/state styling, and both reduced-motion mechanisms:

```css
@media (prefers-reduced-motion: reduce) { ... }
.obpt-root[data-obpt-motion="reduce"] ... { ... }
```

Avoid ambient animation and inline styles. Ordinary surfaces must not horizontally scroll; bounded machine/code regions may.

#### `priv/static/oban_powertools/oban_powertools.css`

Never edit independently. The build task normalizes and copies source CSS:

```text
mix oban_powertools.assets.build
```

`AssetsTest` already runs two builds and compares SHA-256 maps, so source and checked-in compiled CSS must be synchronized before the test.

#### `test/oban_powertools/web/theme_tokens_test.exs`

Add a `@data_classes` list and a `data_blocks/1` helper parallel to `@primitive_classes`/`primitive_blocks/1` and `@shell_classes`/`shell_blocks/1`. Reuse `selector_parts/1`, `declarations/1`, and the token-backed property/allowlist model. Pin representative 24rem, focus, bounded overflow, state/tone, and reduced-motion selectors.

Do not broaden the global literal allowlist just to make a data declaration pass; first express it with an existing token or token calculation.

#### `test/oban_powertools/web/assets_test.exs`

Extend `checked-in compiled assets include ...` with representative data selectors and leave the byte-stability assertion intact. `theme.js` should not gain data-table behavior, and no new JS selector assertion is expected.

### `test/oban_powertools/web/live/showcase_live_test.exs`

Follow the existing form/shell section tests:

```elixir
assert_attribute_values(html, "data-obpt-form-story", @form_story_ids)
refute has_element?(view, "[data-obpt-section='forms'] .obpt-showcase-placeholder")

for id <- @form_story_ids do
  assert has_element?(view,
    "#obpt-form-story-#{id}[data-obpt-form-story='#{id}']" <>
    "[data-obpt-component][data-obpt-variant][data-obpt-state][data-obpt-a11y-target]")
end
```

Add an exact data-story list, assert the placeholder is gone, each story renders once with metadata, required semantic elements/copy exist, hostile HTML is escaped, the secret sentinel is absent, the thousands-row DOM window is bounded, and `render_click` on the sort button updates the header's `aria-sort`.

Keep the surrounding `Application.compile_env(:oban_powertools, :dev_routes, ...)` guard so production compilation remains free of showcase code.

### `.planning/.../77-VALIDATION.md`

At execution closeout, reconcile actual plan/task ids and set `nyquist_compliant: true` only after the mapped commands have run. Record focused server-backed behavior, axe, and canonical Docker VRT compare results plus exact 120-baseline cardinality. Discovery (`--list`) and file existence alone are not completion evidence.

## Reusable Test Helpers And Commands

| Purpose | Existing helper/pattern | Command |
|---|---|---|
| Render function component | `Phoenix.LiveViewTest.__render_component__/4` in primitive/form tests | `mix test test/oban_powertools/web/components/data_display_test.exs --seed 0` |
| DOM/LiveView selector proof | `has_element?/2`, `render_click` via `ObanPowertools.LiveCase` | `mix test test/oban_powertools/web/live/showcase_live_test.exs --seed 0` |
| Deterministic catalog | `stories/0`, `story!/1`, `snapshot_name/1`, `a11y_target/1` | `mix test test/oban_powertools/data_display_story_catalog_test.exs --seed 0` |
| CSS static inspection | `blocks_for/2`, `selector_parts/1`, `declarations/1` | `mix test test/oban_powertools/web/theme_tokens_test.exs --seed 0` |
| Asset synchronization | byte-stable build test | `mix oban_powertools.assets.build && mix test test/oban_powertools/web/assets_test.exs --seed 0` |
| Manifest generation | Elixir catalogs -> ignored JSON | `npm run showcase:manifest` |
| Independent schema smoke | `manifest-smoke.mjs` | `node test/browser/support/manifest-smoke.mjs` |
| Browser discovery | generated `dataStories` | `npx playwright test --list test/browser/specs/data-display.behavior.spec.ts` |
| Live behavior | `prepareShowcase`, `targetLocator`, computed styles | server wrapper + focused 320/wide projects |
| VRT | generic target loop; Docker canonical renderer | `scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/showcase.vrt.spec.ts --grep "data data-"` |
| Axe | generic target loop | `scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/showcase.a11y.spec.ts --grep "data data-"` |

Quick Wave 0/implementation feedback should remain:

```text
mix test test/oban_powertools/web/status_taxonomy_test.exs test/oban_powertools/web/components/data_display_test.exs --seed 0
```

The canonical VRT update must use Docker and `--update-snapshots=changed`, followed by a compare run. Validate the grep with `--list` first. Do not refresh the 108 unrelated scenario-only residual baselines documented by Phase 76.

## Intentional Deviations And Pitfalls

1. **One responsive DOM tree.** The Phoenix generator is the slot analog, but its default table is not 320px-safe. Extend it with visible cell labels and CSS reflow; do not create a second card tree.
2. **Domain required for status.** `ControlPlanePresenter.status_label/1` is a label analog only. Phase 77 needs `spec(domain, state)` because identical state strings have different meaning/tone.
3. **No dynamic state atoms.** Legacy code uses `String.to_atom/1` in bounded contexts. The new taxonomy accepts external strings and must remain string-keyed.
4. **UI-SPEC tones outrank old classes.** Existing raw Tailwind colors show inventory and copy, not canonical Phase 77 semantics.
5. **Render normalized policy output only.** Do not call `DisplayPolicy` in a component or pass raw and redacted forms together.
6. **RedactedValue has stricter attrs than ordinary components.** General `data-*`, `title`, tooltip, slot, expansion, and copy APIs are leak channels.
7. **Native progress replaces inline width.** Do not copy `batches_live.ex`'s `style={"width: ..."}` pattern.
8. **No clipboard controller is required.** Copy is optional. Native details/expansion satisfies long-value access without creating a secret-buffer surface.
9. **Bound the thousands-row story.** Truthful count plus a stable window tests the component boundary without mounting thousands of rows.
10. **Keep page migrations deferred.** Do not edit the nine LiveViews or globally reject their known local status helpers.
11. **Do not put data ids in TypeScript.** Elixir catalog order is the source of truth; browser files validate and consume generated entries.
12. **Generic VRT/axe specs remain generic.** Data targets join through `targets`; only focused behavior gets a new spec.
13. **Do not modify `theme.js`.** Sorting is server/parent-owned; responsive table behavior is CSS; no table package or client hook is needed.
14. **Do not claim full accessibility closure.** Phase 77 proves targeted semantics/keyboard/reflow/axe; full manual screen-reader and 200% cross-page closure remain Phase 82.
15. **Preserve dirty worktree state.** Only the files classified above belong to this phase.

## Planner-Oriented Touch Order

The actual shared-file conflict shape favors this order:

1. Wave 0: create taxonomy, component, catalog, and browser RED contracts.
2. Implement pure taxonomy and wrapper first.
3. Implement DataTable plus explicit states and responsive CSS.
4. Add secondary display components in the same component/CSS files.
5. Add CodeBlock/ArgsViewer/RedactedValue and run the full sentinel matrix.
6. Add the data catalog, ShowcaseLive parent state/rendering, and schema 5 pipeline atomically.
7. Run focused behavior/axe/VRT, add exactly 120 baselines, and close validation evidence.

Plans that touch `data_display.ex` and `tokens.css` should normally be sequential to avoid shared-file conflicts. Taxonomy is independently testable but should land before stories that consume it.

---

*Pattern mapping complete for Phase 77 planning. This artifact maps implementation conventions only; it does not create PLAN.md files or production implementation.*
