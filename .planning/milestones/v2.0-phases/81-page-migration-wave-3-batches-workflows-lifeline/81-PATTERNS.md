# Phase 81: Page Migration Wave 3 — Batches, Workflows, Lifeline - Pattern Map

**Mapped:** 2026-07-29
**Binding inputs:** `81-CONTEXT.md`, `81-RESEARCH.md`
**Scope:** migrate Batches, Workflows, and Lifeline to the Phase 79/80 presentation contract, then extend the single page-quality graph

## Scope and Repository Notes

- No root `CLAUDE.md`, `.claude/skills/`, or `.agents/skills/` exists in this repository.
- The worktree is already dirty with audit, CI, page-quality, fixture, package, and planning changes. Preserve them. In particular, re-read the current catalog, scripts, CSS, package commands, and fixture launchers immediately before editing because other closure work may advance them after this map was written.
- This phase changes presentation and evidence, not routes, schemas, dependencies, authorization, or mutation authority.
- `BatchesLive`, `WorkflowsLive`, and `LifelineLive` already own the behavior to preserve. `JobsLive` and `ForensicsLive` are the nearest completed Phase 80 production analogs.
- Research names `test/oban_powertools/web/control_plane_presenter_test.exs`, but the existing presenter contract suite is `test/oban_powertools/web/operator_pattern_presenter_test.exs`. Extend the latter unless a deliberate rename is planned.
- The 50-story recommendation makes the current 49-page-story graph become 99 stories, 163 total showcase targets, 297 ARIA YAML files, and 1,188 PNGs. Freeze IDs and activation states before generating either artifact type.

## Architecture and Data Flow

```text
URL / PubSub / connected event
  -> LiveView parse + canonicalize + authorize
  -> bounded domain/context read or Lifeline preview/execute
  -> ControlPlanePresenter finite closed maps
  -> public pure page_content/1 (Batches also detail_page_content/1)
  -> existing shared components

deterministic closed fixture maps
  -> PageStoryCatalog
  -> ShowcaseLive calls those same production seams
  -> schema-8 manifest
  -> acceptance + exact ARIA + axe + compare-only VRT

isolated test-only host fixture
  -> connected page-migration-wave-3.spec.ts
  -> URL/history/auth-race/focus/confidentiality/query-bound proof
```

Repository calls, authorization, clocks, tasks, preview structs/tokens, raw domain structs, and raw errors stay outside `page_content/1`. Components receive only finite presentation maps and never execute operator actions.

## File Classification

### Production pages, presentation, selectors, and contexts

| Expected file | Change | Role | Data flow | Closest Phase 79/80 analog | Match |
|---|---|---|---|---|---|
| `lib/oban_powertools/web/batches_live.ex` | major modify | LiveView coordinator + components | URL/event -> auth/domain preview/execute -> closed index/detail assigns | `jobs_live.ex` browse/detail/selection/confirmation | exact composite |
| `lib/oban_powertools/web/workflows_live.ex` | major modify | read-only LiveView coordinator + components | URL/PubSub -> bounded workflow evidence -> semantic sequence/detail | `forensics_live.ex` safe unavailable evidence + pure composition; `jobs_live.ex` detail URL | composite |
| `lib/oban_powertools/web/lifeline_live.ex` | major modify | recovery LiveView coordinator + components | URL/event -> preview/reason/reauthorize/execute/audit -> closed danger UI | `jobs_live.ex` confirmation/results plus `cron_live.ex` single action | exact composite |
| `lib/oban_powertools/web/control_plane_presenter.ex` | modify | presenter/redaction boundary | authorized domain facts -> exact finite maps | its `present_job_*`, `present_forensics/2`, normalizers | exact |
| `lib/oban_powertools/web/selectors.ex` | modify | canonical route helper | allowlisted ordered params -> encoded URLs | `jobs_path/1`, `job_detail_path/2`, `forensic_path/1` | exact |
| `lib/oban_powertools/web/status_taxonomy.ex` | use; conditional modify | closed status registry | domain/state -> label/tone/icon | existing batch/workflow/Lifeline specs in same file | exact |
| `lib/oban_powertools/batches.ex` | conditional modify | bounded Batch query context | filters/detail windows -> stable finite rows/counts | `jobs.ex` shared query base and `audit.ex` page metadata | role match |
| `lib/oban_powertools/lifeline.ex` | conditional query-only modify | incident/evidence query + mutation authority | finite options -> incidents/history; preview/execute unchanged | existing `list_incidents/2`, `preview_repair/4`, `execute_repair/5` | exact |
| `lib/oban_powertools/web/components/{primitives,forms,data_display,operator_patterns}.ex` | use; modify only for generic defect | shared components | closed assigns -> semantic HTML | same modules used by Jobs/Forensics | exact |
| `assets/oban_powertools/tokens.css` | modify | token-backed responsive styles | page/state classes -> one-tree geometry/theme/motion | current `.obpt-jobs-*` / `.obpt-forensics-*` blocks | exact |
| `priv/static/oban_powertools/oban_powertools.css` | regenerate | packaged asset | source CSS -> byte-identical shipped CSS | `mix oban_powertools.assets.build` contract | exact |

### Unit, context, and LiveView tests

| Expected file | Role / data flow | Closest analog |
|---|---|---|
| `test/oban_powertools/web/live/batches_live_test.exs` | URL, selection, callback/retry, auth-race, composition, confidentiality | `jobs_live_test.exs` selection/bulk/detail/source-boundary cases |
| `test/oban_powertools/web/live/workflows_live_test.exs` | deep-link, reload/PubSub parity, safe unavailable, DAG reading order, destinations | `forensics_live_test.exs` unavailable and `jobs_live_test.exs` detail URL |
| `test/oban_powertools/web/live/lifeline_live_test.exs` | preview/reason/execute state machine, duplicate suppression, durable audit, confidentiality | `jobs_live_test.exs` confirmation/result states and existing Lifeline behavior |
| `test/oban_powertools/web/operator_pattern_presenter_test.exs` | exact-key presenter maps, redaction, fail-closed unknowns | existing Jobs/Forensics presenter assertions in same file |
| `test/oban_powertools/web/selectors_test.exs` | exact ordered URLs and rejected keys | existing Jobs detail/Forensics table-driven cases |
| `test/oban_powertools/web/status_taxonomy_test.exs` | exact specs for every emitted state | existing `@all_expected_specs` registry loop |
| `test/oban_powertools/batches_test.exs` | conditional grouped counts/window/query bounds | `jobs_test.exs` finite counts/IDs |
| `test/oban_powertools/lifeline_test.exs` and relevant Audit tests | conditional finite incident/history API and durable receipt evidence | existing tests in those files |
| component test files | conditional generic defect regression only | corresponding existing component suite |

### Catalog, Showcase, manifest, browser, and artifacts

| Expected file | Change / role | Closest analog |
|---|---|---|
| `test/support/page_story_catalog.ex` | append 18 Batches + 12 Workflows + 20 Lifeline closed fixtures | current Phase 80 `phase80_story/10`, `jobs_fixture/1`, `forensics_fixture/1` |
| `test/oban_powertools/page_story_catalog_test.exs` | exact 99 IDs/order/family/activation/safety | current exact 49-ID contract |
| `test/oban_powertools/showcase_catalog_test.exs` | expanded aggregate/adversarial coverage | same file |
| `lib/oban_powertools/web/dev/showcase_live.ex` | add aliases, three families, count 99, production seam delegation | Jobs/Forensics branches at lines 966-969 |
| `test/oban_powertools/web/live/showcase_live_test.exs` | nine-family no-fork composition and roots | existing six-family activation loop |
| `scripts/showcase_manifest.exs` | retain schema 8; exact 99 pages / 163 targets | lines 152-200 |
| `test/browser/support/manifest.ts` | extend closed page union and validator | `allowedPages`, `ShowcasePageStory` |
| `test/browser/support/manifest-smoke.mjs` | exact nine families / 99 pages / 163 targets | current independent 49/113 checks |
| `test/browser/support/verify-page-baselines.mjs` | exact 1,188 PNG matrix | current 49 × 4 × 3 contract |
| `test/browser/support/verify-page-aria-snapshots.mjs` | exact 297 YAML matrix | current manifest-derived 49 × 3 contract |
| `test/browser/specs/page-migration-wave-3.spec.ts` | **new** connected behavior/a11y/security suite | `page-migration-wave-2.spec.ts` |
| Wave 3 fixture client, likely `test/browser/support/phase81-fixtures.ts` | **new** closed typed test API | `phase80-fixtures.ts` |
| Wave 3 fixture contract spec, likely `test/browser/specs/phase81-fixtures.spec.ts` | **new** isolation/credential/schema proof | `phase80-fixtures.spec.ts` |
| `examples/phoenix_host/test/support/phase81_browser_fixtures.ex` | **new** opt-in seed/control authority | Phase 80 fixture module |
| `examples/phoenix_host/test/phase81_browser_fixtures_test.exs` | **new** POST-only/secret/reset contract | Phase 80 fixture tests |
| `examples/phoenix_host/lib/phoenix_host_web/router.ex` | add test-only guarded POST scope | existing Phase 80 guarded scope |
| `examples/phoenix_host/config/test.exs` | add explicit Wave 3 toggle | current Phase 79/80 OR gate |
| `scripts/with-showcase-server.sh`, `scripts/playwright-docker.sh` | pass generated Wave 3 credential/toggle | current Phase 80 wiring |
| `playwright.config.ts` | conditional env/project wiring | current Phase 80 webServer env |
| `package.json` | append Wave 3 spec in preserved order; no dependencies | existing `verify:pages:{host,docker}` |
| `test/browser/voiceover/page.voiceover.spec.ts` | append 3 representative IDs | existing seven-page target map |
| `test/browser/__aria_snapshots__/chromium-*/page-{batches,workflows,lifeline}-*-aria.yml` | **new generated/reviewed** | existing Jobs/Forensics YAML |
| `test/browser/__screenshots__/chromium-*/showcase/page-{batches,workflows,lifeline}-*/{system,light,dark,high-contrast}.png` | **new generated/reviewed** | existing Jobs/Forensics PNG |

Generic `page.acceptance.spec.ts`, `showcase.a11y.spec.ts`, and `showcase.vrt.spec.ts` should normally require no family-specific code; their manifest-derived loops are the analog to reuse. Change them only if the new states expose a genuine generic harness gap.

## Pattern Assignments

### 1. `BatchesLive`: copy Jobs ownership and split index/detail composition

**Analog:** `lib/oban_powertools/web/jobs_live.ex:26-75, 477+`

```elixir
def mount(params, %{"oban_dashboard_path" => dashboard_path}, socket) do
  action = socket.assigns.live_action

  {permission, resource_type, resource_id} =
    case action do
      :show -> {:view_job_detail, :job, detail_resource_id(params["id"])}
      _ -> {:view_jobs, :page, "jobs"}
    end

  with {:ok, socket} <-
         LiveAuth.authorize_page(socket, permission, %{type: resource_type, id: resource_id}) do
    :ok = DisplayPolicy.assert_configured!()
    {:ok, socket |> assign(:oban_dashboard_path, dashboard_path) |> assign_defaults()}
  else
    {:error, socket} -> {:ok, socket}
  end
end

def page_content(assigns) do
  if Map.get(assigns, :page_mode) == :detail do
    detail_page_content(assigns)
  else
    # one pure semantic index tree
  end
end
```

Keep existing Batch mount/params/event/loader functions. Add public `page_content/1` and `detail_page_content/1`; production `render/1` delegates to them with presentation assigns only. Map rows/details/previews before render.

Use the Jobs table/selection pattern (`jobs_live.ex:477+`):

```elixir
<DataDisplay.data_table
  id="jobs-results"
  caption="Jobs"
  rows={@rows}
  row_id={& &1.id}
  state={:ready}
  resource="jobs"
  row_count={@pagination.total_count}
  pagination_summary={@pagination.summary}
>
  <:selection :let={row}>
    <input
      id={"job-select-#{row.id}"}
      type="checkbox"
      checked={row.selection.checked?}
      phx-click="toggle_job"
      phx-value-id={row.id}
      aria-label={row.selection.label}
    />
  </:selection>
</DataDisplay.data_table>
```

Assignments/symbols to add in the presenter: `present_batch_row/2`,
`present_batch_detail/2`, `present_batch_retry_preview/2`, callback preview/result
equivalents, and closed aggregate result maps. The exact names are discretionary;
the maps are not.

Use:

- `DataDisplay.progress_bar/1` for every progress value, never inline width;
- `DataDisplay.data_table/1` for Batch/callback/member rows;
- `OperatorPatterns.detail_surface/1` for bounded review;
- `OperatorPatterns.confirm_action_dialog/1` for bulk and callback confirmation;
- `OperatorPatterns.why_blocked/1` where retry/callback recovery is unavailable;
- `OperatorPatterns.audit_entry/1` or `DataDisplay.timeline/1` for durable history.

Pitfalls:

- preserve page-local selected IDs and independently revalidate each Lifeline target;
- never widen the scope to all matching batches;
- keep callback and Lifeline-routed recovery calls in the parent;
- remove `payload_copy/1`/`inspect/1`, raw callback/member errors, local badge helpers, literal tables, and local dialog markup;
- detail/back URLs must retain only the accepted list context;
- show partial, skipped, failed, drifted, and disconnected outcomes separately.

### 2. `WorkflowsLive`: copy Forensics safe evidence and Jobs canonical detail URLs

**Analogs:** `lib/oban_powertools/web/forensics_live.ex:42-61, 105-142`;
`lib/oban_powertools/web/selectors.ex:99-117`

```elixir
def handle_params(params, _uri, socket) do
  case Scope.parse(params) do
    {:empty, [], _notice} ->
      {:noreply, assign_empty(socket)}

    {:invalid, [], _notice} ->
      socket = socket |> assign_empty() |> assign(:scope_notice, safe_notice())
      if connected?(socket),
        do: {:noreply, push_patch(socket, to: @bare_path, replace: true)},
        else: {:noreply, socket}

    {:ok, %Scope{} = scope, _canonical_params} ->
      {:noreply, load_scope(socket, scope)}
  end
end
```

Implement `Selectors.workflows_path/1` and `workflow_detail_path/2` with a new
`:workflows` canonical path and only the current `step` query key:

```elixir
def jobs_path(params \\ []) do
  encode(:jobs, ordered_params(params, @jobs_keys))
end

def job_detail_path(id, params) do
  base = "#{@canonical_paths.jobs}/#{id}"
  encode_path(base, ordered_params(params, @job_detail_return_keys))
end
```

Add a public pure `page_content/1`. Suggested presenter symbols are
`present_workflow_row/2`, `present_workflow_detail/2`,
`present_workflow_step/2`, and `present_workflow_step_detail/3`.

Render one semantic ordered list for the DAG; visible dependency labels and
blocked explanations come from the presenter. Use `why_blocked/1`,
`description_list/1`, `detail_surface/1`, `timeline/1`, `machine_value/1`, and
taxonomy-backed status pills.

Pitfalls:

- replace `Repo.get!/2` with one non-enumerating unavailable branch after resource authorization;
- bound `Repo.all` workflow rows and step/result/evidence windows, carrying `has_more?`/completeness copy;
- preserve `?step=` on direct load, patch, reload, and PubSub refresh;
- do not make visual or chronological adjacency causal evidence;
- Lifeline links diagnose/hand off only; Workflows remains read-only;
- replace local literal route construction, `highlight_class/2`, status labels, and local cards.

### 3. `LifelineLive`: copy Jobs/Chron confirmation while preserving Lifeline authority

**Analogs:** `lib/oban_powertools/web/jobs_live.ex` confirmation path;
`lib/oban_powertools/web/control_plane_presenter.ex:503-538`

```elixir
def present_job_action_result(result) when is_map(result) and not is_struct(result) do
  state = normalize_job_result_state(presentation_value(result, :state))

  %{
    state: state,
    message: job_result_message(action, state),
    recovery: job_result_recovery(state),
    receipt: job_result_receipt(action, state, job_id),
    audit_href: job_result_audit_href!(result, state),
    requires_fresh_preview?: state != :success
  }
end

def present_job_action_result(_result) do
  %{state: :failed, message: "The job action was not recorded.",
    recovery: "Create a new preview before trying again.", receipt: nil,
    audit_href: nil, requires_fresh_preview?: true}
end
```

Add pure `page_content/1`. Suggested presenter symbols:
`present_lifeline_summary/1`, `present_incident_row/2`,
`present_incident_detail/2`, `present_repair_confirmation/3`,
`present_repair_result/2`, `present_lifeline_audit_entry/2`,
`present_executor_row/1`, and `present_archive_summary/1`.

Use the existing confirmation component contract
(`operator_patterns.ex:26-59`):

```elixir
attr(:intent, :atom, required: true, values: @confirmation_intents)
attr(:state, :atom, required: true, values: @confirmation_states)
attr(:consequence, :string, required: true)
attr(:reversibility, :string, required: true)
attr(:support_boundary, :string, required: true)
attr(:form, Phoenix.HTML.Form, required: true)
attr(:progress, :map, default: nil)
attr(:results, :list, default: [])
def confirm_action_dialog(assigns)
```

Use danger intent and cover `:preview`, `:submitting`, `:partial`, `:failed`,
`:expired`, `:drifted`, and `:consumed`. Keep the `RepairPreview` and token only
in private server assigns. Validate trimmed reason length in the LiveView,
reauthorize immediately before the existing `Lifeline.execute_repair/5`, and
render only a closed result/receipt/audit projection.

Pitfalls:

- remove visible Preview Token, `repair_preview_value/1`, raw snapshots, raw target identity, `state_copy/1` fallback, and `error_message(reason) -> inspect(reason)`;
- close adaptive incident detail before opening confirmation: at most one modal;
- preserve duplicate-submit suppression, expiry/drift/consumption, authorization refusal, successful execution, and durable Audit evidence without inventing aggregate or connection-lifecycle results;
- never claim atomicity or exactly-once execution;
- bound incident expansion, healthy executors, audit events, and retention records and expose incomplete evidence honestly.

### 4. `ControlPlanePresenter`: exact keys, typed sources, fail closed

**Analog:** `lib/oban_powertools/web/control_plane_presenter.ex:405-429`

```elixir
def present_job_row(%Oban.Job{} = job, context) do
  context = ensure_job_context!(context)
  id = normalize_job_id!(job.id)
  state = normalize_job_state!(job.state)

  %{
    id: id,
    worker: required_presentation_text!(job.worker, "job worker"),
    state: state,
    queue: required_presentation_text!(job.queue, "job queue"),
    scheduled: job_row_time!(job.scheduled_at),
    attempts: job_attempts!(job.attempt, job.max_attempts),
    selection: %{label: "Select job #{id}", checked?: job_context_boolean!(context, :selected?, false)},
    review: %{label: "Review job #{id}", current?: job_context_boolean!(context, :reviewing?, false)}
  }
end

def present_job_row(_job, _context),
  do: raise(ArgumentError, "job row source must be an Oban job")
```

**Analog:** `control_plane_presenter.ex:614-653` for finite result normalization:

```elixir
def normalize_operator_results(results) when is_list(results) do
  results
  |> Enum.map(fn result ->
    ensure_presentation_map!(result, "operator result")
    %{
      id: normalize_presentation_id!(presentation_value(result, :id), "operator result id"),
      object_label: required_presentation_text!(presentation_value(result, :object_label), "operator result object label"),
      outcome: normalize_closed_value!(presentation_value(result, :outcome), @operator_result_states, "operator result outcome"),
      message: required_presentation_text!(presentation_value(result, :message), "operator result message"),
      recovery: optional_presentation_text(presentation_value(result, :recovery), "operator result recovery"),
      audit_href: optional_presentation_text(presentation_value(result, :audit_href), "operator result audit destination")
    }
  end)
  |> ensure_unique_presentation_ids!("operator results")
end
```

Each Wave 3 function should:

- accept the expected domain struct or an explicitly documented plain-map contract;
- normalize all statuses through `StatusTaxonomy`;
- return a literal map with an exact tested key set;
- accept timestamps and authorized destinations through context rather than reading time/auth itself;
- cap every list before returning;
- structurally redact before assign/render;
- raise or return a finite unavailable map for unknown source shapes without traversing them.

Do not carry structs, preview tokens, plan hashes, before/after snapshots,
metadata, raw provider errors, or raw reasons through a seemingly safe outer map.

### 5. Shared components: use their shipped contracts; do not fork them

**Data table:** `data_display.ex:43-67`

```elixir
attr(:id, :string, required: true)
attr(:caption, :string, required: true)
attr(:rows, :list, required: true)
attr(:row_id, :any, required: true)
attr(:state, :atom, default: :ready, values: @data_states)
slot(:toolbar)
slot(:selection)
slot(:col)
slot(:action)
slot(:state_detail)
def data_table(assigns)
```

**Detail:** `operator_patterns.ex:318-340`

```elixir
attr(:title, :string, required: true)
attr(:open, :boolean, required: true)
attr(:variant, :atom, default: :adaptive, values: @detail_variants)
attr(:state, :atom, required: true, values: @detail_states)
attr(:logical_fallback_id, :string, required: true)
attr(:close_event, :string, required: true)
slot(:body, required: true)
slot(:actions)
slot(:evidence)
def detail_surface(assigns)
```

Also reuse `progress_bar/1` (`data_display.ex:304-311`), `metric_card/1`
(`342-351`), `timeline/1` (`253-266`), and `why_blocked/1`
(`operator_patterns.ex:639-654`). Page CSS may compose these components but
must not duplicate their semantics, focus code, or status vocabulary.

### 6. Page catalog and Showcase: append deterministic maps and call production

**Analog:** `test/support/page_story_catalog.ex:1485-1530`

```elixir
%{
  id: id,
  kind: :page,
  page: page,
  name: name,
  description: description,
  components: components,
  variant: variant,
  state: state,
  fixtures: fixtures,
  activation: activation,
  acceptance: %{
    required_text: required_text,
    forbidden_text: @phase80_forbidden_copy,
    ordered_text: required_text,
    roles: [%{role: "heading", name: page_heading(page), level: 1, states: %{}}]
  },
  test_targets: %{
    story: "obpt-page-story-#{id}",
    snapshot: "showcase/#{id}",
    a11y: ~s([data-obpt-page-story="#{id}"])
  }
}
```

Keep the exact recommended order: 18 Batches, then 12 Workflows, then 20
Lifeline. Fixtures must contain normalized presentation data and deterministic
timestamps only. They may materialize `Phoenix.HTML.Form` in ShowcaseLive, but
must never construct a domain struct or pretend to authorize/execute.

**Analog:** `showcase_live.ex:917-970`

```elixir
defp page_story_body(assigns) do
  assigns = assign(assigns, :page_assigns, materialize_page_assigns(assigns.story))

  ~H"""
  <%= case @story.page do %>
    <% :jobs -> %>
      <JobsLive.page_content {@page_assigns} />
    <% :forensics -> %>
      <ForensicsLive.page_content {@page_assigns} />
  <% end %>
  """
end
```

Add Batches, Workflows, and Lifeline aliases/cases and activation-to-open/form
materialization. Update `@page_story_count` from 49 to 99 and
`@page_story_pages` to the nine exact families. Never copy their HEEx into the
showcase.

### 7. Manifest and validators: keep one Elixir-owned inventory

**Analog:** `scripts/showcase_manifest.exs:152-200`

```elixir
page_stories =
  PageStoryCatalog.stories()
  |> Enum.map(fn story ->
    %{id: story.id, kind: "page", page: Atom.to_string(story.page), ...}
  end)

unless length(page_stories) == 49, do: raise(...)
unless length(targets) == 113, do: raise(...)

manifest = %{schema_version: 8, ..., page_stories: page_stories, targets: targets}
```

Only cardinalities and allowed families change if the serialized shape stays
the same: 99 pages and 163 targets. Mirror that closed family set in
`manifest.ts`, `manifest-smoke.mjs`, baseline/ARIA validators, catalog tests,
Showcase tests, and Wave 1/2 compatibility assertions that intentionally lock
the full graph.

Pitfalls:

- do not create a TypeScript page list independent of the manifest;
- do not bump schema 8 for count/family additions;
- do not generate artifacts until IDs, activation, and exact counts pass;
- baseline update is scoped to new Wave 3 files unless reviewed shared CSS
  intentionally changes prior families.

### 8. Connected fixture and browser suite: copy the isolated Phase 80 contract

**Analog:** `test/browser/specs/page-migration-wave-2.spec.ts:18-64`

```typescript
test.describe.configure({ mode: "serial" });
test.setTimeout(90_000);

test.beforeEach(async ({ page, request }, testInfo) => {
  fixtureSecret = process.env.PHASE80_BROWSER_FIXTURE_SECRET?.trim() ?? "";
  if (fixtureSecret.length === 0) throw new Error("fixture credential is unavailable");

  captureBrowserChannels(page);
  fixtureState = await resetPhase80BrowserFixture(request, {
    secret: fixtureSecret,
    project: testInfo.project.name,
  });
  await authenticatePhase80Actor(page, { actor: "ops", secret: fixtureSecret });
});
```

**Channel scan analog:** `page-migration-wave-2.spec.ts:67-101`

```typescript
page.on("console", ...);
page.on("pageerror", ...);
page.on("request", ...);
page.on("response", ...);
page.on("websocket", socket => {
  socket.on("framesent", ...);
  socket.on("framereceived", ...);
});
```

Build a Wave 3 sibling rather than destabilizing accepted Wave 1/2 fixture
schemas. It must be:

- compiled and routed only in `Mix.env() == :test`;
- enabled only by explicit `PHASE81_BROWSER_FIXTURES=1`;
- POST-only under a distinct endpoint;
- protected by a generated nonblank credential;
- closed-schema and deterministic per Playwright project;
- incapable of echoing secrets/tokens/raw snapshots.

The connected spec should reuse Wave 2 helpers for connected-state proof,
horizontal overflow, 200% zoom, 44px targets, visible focus, reduced motion,
and complete browser-channel scans. Add family-specific URL/history,
selection/PubSub, preview/auth-race/duplicate-submit, focus
containment/Escape/restore, and durable evidence assertions.

Append `page-migration-wave-3.spec.ts` after Wave 2 and before generic
a11y/VRT in both `verify:pages:host` and `verify:pages:docker`.

### 9. CSS and packaged asset: copy page blocks, preserve token/motion rules

Use the current Jobs/Forensics CSS organization in
`assets/oban_powertools/tokens.css`: root-scoped page classes, component state
attributes, a single responsive tree, and existing breakpoints. Use only
`--obpt-*` color/spacing/type/radius/shadow/motion tokens.

Required Wave 3 selectors should describe composition, not rebuild components:
`.obpt-batches-page*`, `.obpt-workflows-page*`, `.obpt-lifeline-page*`, semantic
workflow step/dependency layout, selection/result groups, and bounded labelled
machine-content regions.

Pitfalls:

- no inline progress width;
- no duplicate mobile table/cards;
- no geometry-moving hover;
- no raw duration/easing literals;
- no animated progress or DAG reordering;
- reduced-motion retains immediate focus and actionable controls;
- regenerate `priv/static/...css` with the repository asset task and verify
  byte equality rather than editing it by hand.

## Shared Safety and Verification Patterns

### Authorization and mutation

- Page/resource/action authorization remains in `LiveAuth`/parent LiveViews.
- Preview readiness is never authorization; reauthorize at execute.
- `Lifeline.preview_repair/4` and `execute_repair/5` remain sole repair
  authority.
- Missing and unauthorized resources share the same unavailable surface.

### Error handling

- Known outcomes map to finite operator copy and recovery guidance.
- Unknown domain/provider errors fail closed; never render `inspect/1`.
- Ready, drifted, expired, consumed, authorization-refused, and successful are
  separate states and assertions.

### Boundedness

- Limit-plus-one or exact count metadata distinguishes complete from truncated.
- Cap workflow lists/steps/results, batch members/callbacks/results, incidents,
  executor expansion, audit history, and story DOM.
- Tests assert both query count and rendered row count for saturated fixtures.

### Accessibility

- One H1 per page, one caption per table, one semantic responsive tree.
- Native controls have durable names and 44px target evidence.
- Status/progress meaning includes text, not color alone.
- At most one dialog; focus contains, Escape closes, and focus restores.
- Live regions announce sparse state changes, not every row/progress tick.
- Four themes × three viewports, 320px, 200% zoom, high contrast, and reduced
  motion are manifest/browser obligations.

## Planner Checklist

1. Contract tests and closed presenter/selectors first.
2. Migrate Batches and pass focused behavior gate.
3. Migrate Workflows and pass focused behavior gate.
4. Build Lifeline projections before changing its HEEx; then pass the full
   preview/reason/execute/audit gate.
5. Freeze the 50 IDs and activation states.
6. Extend catalog/Showcase/manifest/validators and token CSS.
7. Add the isolated Wave 3 fixture and connected spec.
8. Generate and review exactly 150 new ARIA files and 600 new PNGs.
9. Run focused ExUnit after each page, then catalog/manifest contracts,
   connected Wave 3, full `npm run verify:pages`, format, warnings-as-errors,
   and full ExUnit.
