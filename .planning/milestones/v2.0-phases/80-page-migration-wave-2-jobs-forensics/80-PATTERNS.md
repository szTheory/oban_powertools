# Phase 80: Page Migration Wave 2 — Jobs, Forensics - Pattern Map

**Mapped:** 2026-07-27
**Binding inputs:** `80-CONTEXT.md` decisions D-01 through D-88 and `80-RESEARCH.md`
**Scope:** Jobs browse/review/detail, frozen bulk execution, Forensics typed/bounded evidence, deterministic page stories, connected browser fixtures, and page-quality evidence

## Scope and Instruction Check

- No root `AGENTS.md` exists. The only repository `AGENTS.md` is under `examples/phoenix_host_upgrade_source/`, outside this phase's implementation and fixture-host paths.
- The worktree already contains unrelated user-owned changes, including active Phase 79 page-quality work. Pattern mapping changes only this file and assumes those changes remain authoritative rather than reverting or recreating them.
- The current Wave 1 page-story harness is present in the worktree with 19 stories, schema version 8, 83 showcase targets, 228 page PNGs, and 57 page ARIA snapshots. Phase 80 must extend that exact harness after locking a final story list; it must not reason from an older pre-Phase-79 baseline.
- The research refers to `lib/oban_powertools/cron_history.ex` and `lib/oban_powertools/limiter_history.ex`; the actual files are `lib/oban_powertools/forensics/cron_history.ex` and `lib/oban_powertools/forensics/limiter_history.ex`.
- The research suggests `test/oban_powertools/web/control_plane_presenter_test.exs`; the existing presenter contract suite is `test/oban_powertools/web/operator_pattern_presenter_test.exs`. Extend that file unless a deliberate test rename is separately justified.
- `test/oban_powertools/web/jobs_params_test.exs`, `test/oban_powertools/jobs/batch_coordinator_test.exs`, and `test/browser/specs/page-migration-wave-2.spec.ts` do not exist and are expected new files.
- `lib/oban_powertools/web/components/operator_patterns.ex`, `data_display.ex`, `forms.ex`, and `primitives.ex` already expose the required generic contracts. Treat component-internal edits as conditional, not default page work.
- No dependency, host schema migration, production route-shape change, Oban schema change, durable bulk-run ledger, or second story/screenshot system belongs in Phase 80.

## Architecture and Data Flow

```text
untrusted Jobs URL / Forensics URL / LiveView event
        |
        v
parent LiveView
  parse + canonicalize with replace when input is invalid
  authorize page/resource/action
  keep applied URL truth separate from invalid/dirty draft truth
        |
        +--> Jobs / Forensics / Audit contexts
        |      reusable Ecto query composition
        |      stable ordering + exact count or bounded has-more metadata
        |
        +--> Lifeline per-target preview and execute
        |      opaque tokens stay server-side
        |      frozen IDs -> supervised nonlinked coordinator
        |
        +--> ControlPlanePresenter
        |      schemas/domain facts -> finite closed redaction-safe maps
        |
        v
public pure page_content/1
        |
        +--> FilterBar + Forms
        +--> DataTable / DescriptionList / Timeline
        +--> DetailSurface / ConfirmActionDialog
        +--> Primitives

deterministic normalized fixtures
  -> PageStoryCatalog
  -> ShowcaseLive calls the same production page_content/1
  -> schema-8 manifest
  -> page acceptance + ARIA + axe + VRT

isolated opt-in Phoenix host fixtures
  -> real URL/history/auth/query/Lifeline/task behavior
  -> page-migration-wave-2.spec.ts
```

Repository work, authorization, current-time reads, and task spawning stay outside `render/1`, `page_content/1`, and shared components. Presentation maps must already be safe before they enter LiveView assigns.

## File Classification

### Production query, lifecycle, and configuration

| Expected File | Change | Role | Data Flow | Closest Existing Analog | Match |
|---|---|---|---|---|---|
| `lib/oban_powertools/jobs.ex` | modify | sole `oban_jobs` query owner | applied `%Jobs{}` -> stable rows, exact active count, one grouped seven-state count, bounded ordered IDs | same file's filter semantics/order plus `Audit.page/2` count/page metadata | composite exact |
| `lib/oban_powertools/audit.ex` | modify | bounded forensic Audit query owner | typed workflow/incident scope + limit -> stable event window and coverage metadata | same file's `filter_query/2`, `page/2`, and `fetch_in_scope/3` | exact extension |
| `lib/oban_powertools/forensics.ex` | modify | typed scope and evidence assembly boundary | six allowlisted params -> empty/valid/invalid scope -> authoritative bounded source result | same file's source-specific bundle builders; replace its current precedence and `list_all |> Enum.filter` | corrective |
| `lib/oban_powertools/forensics/chronology.ex` | conditional modify | chronology normalization and stable order | safe source-specific event maps -> newest-first finite chronology items | same file | exact, but current shape is too broad |
| `lib/oban_powertools/forensics/evidence_bundle.ex` | conditional modify | internal evidence normalization | normalized source result -> internal bundle | same file | exact, but unknown-key preservation is not a DOM-safety boundary |
| `lib/oban_powertools/forensics/cron_history.ex` | use / narrow modify | bounded Cron evidence source | canonical Cron entry ID -> newest eight source facts | same file's `@history_limit 8` queries | exact |
| `lib/oban_powertools/forensics/limiter_history.ex` | use / narrow modify | bounded Limiter evidence source | canonical Limiter ID -> newest eight facts and current state | same file's `@history_limit 8` query | exact |
| `lib/oban_powertools/forensics/provenance.ex` | use / conditional modify | finite support vocabulary | source/completeness values -> closed support meanings | same file and presenter label functions | exact |
| `lib/oban_powertools/forensics/runbook_entry.ex` | use / conditional modify | source guidance model | evidence bundle -> ordered legal guidance | same file | partial; presenter must deduplicate and authorize destinations |
| `lib/oban_powertools/jobs/batch_coordinator.ex` | new, name discretionary | frozen batch state machine and supervised execution | frozen IDs + actor + action + opaque previews -> aggregate progress + stable safe results | `Operator.do_repair/6` for one-target Lifeline composition, `Application` for supervision, `ConfirmActionDialog` for result states | no single exact analog |
| `lib/oban_powertools/application.ex` | modify | library supervision tree | application startup -> named `Task.Supervisor` child | same file's named/conditional child construction | exact role |
| `lib/oban_powertools/runtime_config.ex` | modify | validated host configuration | `:oban_powertools` env -> positive limit, default 100, hard max 1000 or actionable failure | same file's centralized `configured/2` and setup-error style | exact role |
| `lib/oban_powertools/lifeline.ex` | use, normally no change | sole mutation authority | actor + target/action -> preview token -> independently committed execution/audit | same file's `preview_repair/4` and `execute_repair/5` | exact |
| `lib/oban_powertools/operator.ex` | preserve, normally no change | public sequential bulk API compatibility | public bulk calls -> per-target Lifeline result | same file's `do_repair/6` | reference only, not the page coordinator |

The new coordinator should not query `oban_jobs`, call direct `Oban` mutation APIs, own presentation markup, or become a durable run ledger. `Jobs` freezes membership; Lifeline owns each mutation; Audit owns recovery evidence.

### Production web and packaged assets

| Expected File | Change | Role | Data Flow | Closest Existing Analog | Match |
|---|---|---|---|---|---|
| `lib/oban_powertools/web/jobs_live.ex` | major modify | Jobs URL/auth/selection/preview/progress orchestrator plus pure page composition | canonical filters + `job` + page -> bounded rows/review/detail/confirmation/result assigns -> shared components | `AuditLive` filter/detail URL ownership, `CronLive` confirmation state, `LimitersLive` explicit review controls | composite exact |
| `lib/oban_powertools/web/forensics_live.ex` | major modify | typed chooser, canonical scope, auth, and diagnosis-first composition | six-key params + draft form -> empty/unavailable/ready presentation -> FilterBar/Timeline | `AuditLive` submit FilterBar and pure `page_content/1`; same file for auth route | composite exact |
| `lib/oban_powertools/web/control_plane_presenter.ex` | modify | closed redaction and grammatical presentation seam | Job/Forensics/Audit domain facts -> finite row/detail/event/guidance/result maps | same file's Overview/Audit presenters and operator-result normalizer | exact |
| `lib/oban_powertools/web/selectors.ex` | modify | canonical URL and destination allowlisting | ordered safe params -> Jobs list/detail, Forensics, and Audit paths | same file's ordered `encode/2` plus Phase 79 Audit selector tests | exact |
| `lib/oban_powertools/web/live_auth.ex` | conditional narrow modify | finite authorization/result copy | known auth/mutation outcomes -> safe operator copy | same file's closed permission maps | partial; never use its current `inspect(reason)` fallback for Phase 80 results |
| `lib/oban_powertools/web/components/operator_patterns.ex` | use / conditional generic extension | stateless filter/detail/confirmation/results | closed assigns -> semantic adaptive UI | same file | exact |
| `lib/oban_powertools/web/components/data_display.ex` | use / conditional generic extension | semantic table/timeline/detail payload UI | closed rows/events/displays -> one responsive DOM tree | same file | exact |
| `lib/oban_powertools/web/components/forms.ex` | use | typed accessible fields | parent-owned form/errors -> labels, hints, `aria-invalid`, descriptions | same file | exact |
| `lib/oban_powertools/web/components/primitives.ex` | use | semantic buttons/links/disclosure/surfaces | safe labels/destinations -> foundational controls | same file | exact |
| `assets/oban_powertools/tokens.css` | modify | root-scoped Jobs/Forensics page composition | page classes/state attrs -> token-owned wide/mobile/theme/motion behavior | same file's Phase 79 page and shared component blocks | exact |
| `priv/static/oban_powertools/oban_powertools.css` | regenerate | shipped package asset | source CSS -> checked-in built CSS | `mix oban_powertools.assets.build` | exact |

`JobsLive` and `ForensicsLive` must both expose public pure `page_content/1` functions. Production `render/1` and ShowcaseLive must call those exact functions. `ThemeShell`/`AppShell` already wrap the routes; neither page should instantiate another shell.

### Focused unit, context, coordinator, and LiveView tests

| Expected File | Change | Role | Data Flow | Closest Existing Analog | Match |
|---|---|---|---|---|---|
| `test/oban_powertools/jobs_test.exs` | extend | query semantics/bounds/count proof | inserted Oban jobs -> stable filters/counts/ID windows and query count | same file plus `audit_test.exs` telemetry query capture | exact |
| `test/oban_powertools/audit_test.exs` | extend | scoped forensic window proof | inserted Audit events -> stable bounded workflow/incident window | same file's page/filter/query-count tests | exact |
| `test/oban_powertools/forensics_test.exs` | extend/rework | typed scope, source, coverage, and chronology contract | adversarial six-key params + source fixtures -> empty/invalid/valid evidence | same file | exact |
| `test/oban_powertools/forensics/evidence_bundle_test.exs` | extend if internal contract changes | bundle closure/order regression | source maps -> normalized finite internal bundle | same file | exact |
| `test/oban_powertools/jobs/batch_coordinator_test.exs` | new | concurrency/lifecycle/frozen-result proof | gated fake targets -> max-four, timeout, crash, stable order, disconnect | `operator_test.exs` per-target results plus message-gated process tests elsewhere | closest role |
| `test/oban_powertools/application_test.exs` | extend | supervisor/config startup contract | application config -> Task Supervisor child or clear invalid-config failure | same file's child-ID assertions | exact |
| `test/oban_powertools/auth_test.exs` or a new focused RuntimeConfig suite | extend/new | bulk-limit validation | absent/valid/invalid application env -> 100/override/error | `auth_test.exs` RuntimeConfig setup tests | exact style |
| `test/oban_powertools/web/jobs_params_test.exs` | new, or private-parser tests in LiveView suite | pure Jobs URL/draft contract | malformed params/JSON/pages -> safe applied state + canonical params + explanation | `selectors_test.exs` table-driven URL assertions | exact role |
| `test/oban_powertools/web/operator_pattern_presenter_test.exs` | extend | closed-map/redaction/result taxonomy proof | jobs/errors/audit/runbook maps -> safe finite maps or fail-closed error | same file's secret-key and operator-result tests | exact |
| `test/oban_powertools/web/selectors_test.exs` | extend | deterministic allowlisted URL proof | Jobs list/detail and Forensics params -> exact encoded URLs | same file's Audit/Cron/Limiter order tests | exact |
| `test/oban_powertools/web/live/jobs_live_test.exs` | major extend/rework | connected LiveView state-machine regression | auth + URL/events + repo + task messages -> scan/review/detail/bulk receipts | same file and Phase 79 Audit/Cron LiveView tests | composite exact |
| `test/oban_powertools/web/live/forensics_live_test.exs` | major extend/rework | chooser/canonicalization/page-order/security regression | auth + direct/submitted scope -> empty/unavailable/ready page | same file and `audit_live_test.exs` | composite exact |
| `test/oban_powertools/web/components/operator_patterns_test.exs` | conditional extend | generic component compatibility | any new generic frozen-scope/result field -> semantic HTML | same file | exact |
| `test/oban_powertools/web/components/data_display_test.exs` | conditional extend | table/timeline adversarial semantics | Phase 80 row/event maps -> semantic one-tree HTML | same file | exact |

Delete no existing regression coverage merely because event names or markup change. Rewrite assertions around the locked state machine and shared component contracts.

### Deterministic page-story and browser-quality harness

| Expected File | Change | Role | Data Flow | Closest Existing Analog | Match |
|---|---|---|---|---|---|
| `test/support/page_story_catalog.ex` | extend | deterministic production-composition fixtures | closed Jobs/Forensics fixture maps -> exact story metadata and acceptance | existing 19 Phase 79 stories in same file | exact |
| `test/oban_powertools/page_story_catalog_test.exs` | extend | exact story/order/state/safety gate | story catalog -> exact IDs/count/coverage/no secrets | same file | exact |
| `lib/oban_powertools/web/dev/showcase_live.ex` | modify | story host using production page seams | page story -> materialized forms/activation -> Jobs/Forensics `page_content/1` | existing Overview/Cron/Limiters/Audit switch | exact |
| `test/oban_powertools/web/live/showcase_live_test.exs` | extend | no-fork composition contract | activated Jobs/Forensics story -> one production page tree | same file's four-page seam assertions | exact |
| `test/oban_powertools/showcase_catalog_test.exs` | conditional extend | aggregate showcase contract | catalog metadata -> required adversarial state coverage | same file | exact |
| `scripts/showcase_manifest.exs` | modify | schema-8 generated manifest | expanded page catalog -> exact page/target counts | same file's `page_stories` append | exact |
| `test/browser/support/manifest.ts` | modify only if its closed page union/count requires it | strict TS manifest contract | generated JSON -> typed Jobs/Forensics page targets | same file's page target validator | exact |
| `test/browser/support/manifest-smoke.mjs` | modify | independent generated-manifest cardinality gate | manifest -> exact expanded counts and page family validation | same file's Phase 79 checks | exact |
| `test/browser/support/showcase.ts` | conditional modify | generic target activation | page activation metadata -> visible page/detail/confirmation tree | same file's page branch | likely already generic |
| `test/browser/specs/page.acceptance.spec.ts` | modify naming/count only as needed | generic copy/role/order/ARIA contract | every page story × three viewport projects -> acceptance + snapshot | same file | exact |
| `test/browser/specs/showcase.a11y.spec.ts` | normally use | generic axe matrix | page targets × four themes × three viewports -> axe results | same file's `PAGE_QUALITY_ONLY` branch | exact |
| `test/browser/specs/showcase.vrt.spec.ts` | normally use | generic screenshot matrix | page targets × four themes × three viewports -> PNG | same file's page target branch | exact |
| `test/browser/support/verify-page-baselines.mjs` | modify | exact PNG cardinality and changed-scope gate | locked page IDs × 4 × 3 -> exact paths | same file | exact |
| `test/browser/support/verify-page-aria-snapshots.mjs` | use / strengthen count assertion if needed | exact ARIA file gate | locked page IDs × three projects -> exact YAML paths | same file | exact |
| `test/browser/__aria_snapshots__/{chromium-320,chromium-tablet,chromium-wide}/page-{jobs,forensics}-*-aria.yml` | generated new | ARIA evidence | locked Phase 80 story list × three viewports -> YAML | existing Phase 79 files | exact |
| `test/browser/__screenshots__/chromium-{320,tablet,wide}/showcase/page-{jobs,forensics}-*/{system,light,dark,high-contrast}.png` | generated new | VRT evidence | locked Phase 80 story list × 12 -> PNG | existing Phase 79 page family | exact |
| `package.json` | modify | aggregate browser gate | `verify:pages` -> Wave 1 + Wave 2 + acceptance + axe + VRT | current scripts | exact extension |

Lock one exact Jobs/Forensics story ID list and final count before changing manifest cardinalities or generating baselines. Keep schema version 8 unless the story object schema itself changes.

### Connected isolated-host fixtures

| Expected File | Change | Role | Data Flow | Closest Existing Analog | Match |
|---|---|---|---|---|---|
| `test/browser/specs/page-migration-wave-2.spec.ts` | new | connected Jobs/Forensics browser behavior | opt-in seeded host -> URL/auth/query/mutation/disconnect assertions | `page-migration-wave-1.spec.ts` | exact role |
| `test/browser/support/phase79-fixtures.ts` | generalize with compatibility or preserve and add sibling helper | strict fixture client | secret + closed commands -> validated public state | same file | exact |
| new version-neutral or Phase 80 fixture TS helper | conditional new | Jobs/Forensics fixture client | reset/actor/perturb/barrier commands -> closed typed state | `phase79-fixtures.ts` | exact role |
| `test/browser/specs/phase79-fixtures.spec.ts` | preserve; extend only if generalized | fixture-toggle/contract proof | route on/off + secret + schemas -> isolation evidence | same file | exact |
| `examples/phoenix_host/test/support/phase79_browser_fixtures.ex` | generalize compatibly or preserve and add sibling | deterministic test-only seed/control implementation | closed reset/actor/recovery/barrier command -> database/session state | same file | exact |
| new version-neutral or Phase 80 host fixture module/controller | conditional new | Wave 2 seed/control implementation | Jobs/Forensics cases -> bounded public fixture identity | Phase 79 module/controller | exact role |
| `examples/phoenix_host/lib/phoenix_host_web/router.ex` | modify | test-only fixture routes | opt-in env -> POST-only fixture endpoints | existing Phase 79 guarded scope | exact |
| `examples/phoenix_host/config/test.exs` | modify | fixture feature toggle/config | environment -> `dev_routes` and test fixture availability | existing Phase 79 toggle | exact |
| fixture host tests under `examples/phoenix_host/test/` | extend/new | closed endpoint and isolation proof | correct/wrong secrets + schemas + repeated reset -> 404 or deterministic state | `phase79_browser_fixtures_test.exs` | exact |
| `scripts/with-showcase-server.sh`, `scripts/playwright-docker.sh`, `playwright.config.ts` | conditional modify | isolated host lifecycle and test project wiring | fixture env/secret/build path -> connected server and three projects | current Phase 79 browser infrastructure | exact |

Prefer a version-neutral fixture name only if compatibility aliases keep all Wave 1 tests green. A Phase 80 sibling is lower risk than breaking the accepted Phase 79 contract. Do not add fixture routes to production or expose GET/resource-style fixture APIs.

## Pattern Assignments and Concrete Analogs

### 1. Parent LiveViews own URL, authorization, repository work, and page state

`AuditLive` is the closest shipped page-level seam (`lib/oban_powertools/web/audit_live.ex:46-71`):

```elixir
def handle_params(params, _uri, socket) do
  {:noreply, assign(socket, load_audit_state(params))}
end

def handle_event("select_event", %{"event" => event_id}, socket) do
  replace? = not is_nil(socket.assigns.selected_event_id)

  {:noreply,
   push_patch(socket,
     to: audit_path(socket.assigns.filters, socket.assigns.audit_page.page, event_id),
     replace: replace?
   )}
end

def handle_event("close_detail", _params, socket) do
  {:noreply,
   push_patch(socket,
     to: audit_path(socket.assigns.filters, socket.assigns.audit_page.page, nil),
     replace: true
   )}
end
```

Apply the same lifecycle to Jobs quick review:

- first valid `job=<id>` open pushes;
- switching selected jobs replaces;
- close replaces to the same state/filter/page URL without `job`;
- stale, malformed, missing, and unauthorized selection share one unavailable/non-enumerating result and safely remove `job`;
- state/filter changes clear review, selection, frozen scope, preview, progress, and stale results;
- ordinary pagination keeps explicit selected IDs and removes contextual quick review.

Forensics uses the same parent boundary but has no detail surface. `handle_params/3` parses one scope family, authorizes it, loads a bounded result, and assigns a presenter-built page map.

Both pages then follow the Wave 1 pure composition seam (`audit_live.ex:76-88,111-117`):

```elixir
def render(assigns) do
  ~H"""
  <.page_content
    audit_page={@audit_page}
    event_rows={@event_rows}
    ...
  />
  """
end

@doc """
The component consumes normalized presentation assigns only. It performs no
authorization, repository work, URL parsing, time lookup, or mutation.
"""
def page_content(assigns) do
  ...
end
```

Do not place repo access, authorization, `DateTime.utc_now/0`, or coordinator startup inside the new `page_content/1` functions.

### 2. Applied URL state and invalid draft state are separate

`OperatorPatterns.filter_bar/1` already encodes the ownership contract (`operator_patterns.ex:457-520`):

```elixir
@doc """
Renders one stateless filter form while the parent retains valid or invalid draft,
applied, and URL truth.
"""
def filter_bar(assigns) do
  ...
  <.form
    for={@form}
    phx-change={@change_event}
    phx-submit={if(@mode == :submit, do: @submit_event)}
  >
    ...
    <p :if={@dirty} class="obpt-filter-bar__dirty">Changes not applied.</p>
    <Primitives.button type="submit" variant={:primary}>Apply filters</Primitives.button>
  </.form>
end
```

Jobs must not retain the current one-event pattern in `jobs_live.ex:80-143`, where `"filter"` validates and immediately patches. Use two parent events:

```text
change -> validate draft only, retain invalid text, reveal conditional/advanced UI
submit -> validate complete draft, canonicalize, patch URL, then query
```

Forensics uses the same submit model: change reveals Workflow/Lifeline/Cron/Limiter fields; submit patches only one valid family.

`Forms.input/1` already wires accessible error relationships (`forms.ex:29-50`):

```elixir
<input
  ...
  aria-invalid={@aria_invalid}
  aria-describedby={@describedby}
/>
<.hint :if={@hint} id={@hint_id} text={@hint} />
<.error :for={{message, error_id} <- @error_items} id={error_id} error={message} />
```

Use the locked Jobs copy verbatim. Invalid direct URL JSON is different from an invalid draft: normalize it to a safe applied filter, replace the URL, and retain a concise explanation; never query with the malformed value.

### 3. `Selectors` owns canonical ordering and detail-return allowlisting

The shared encoder preserves ordered lists and drops empty values (`selectors.ex:53-65`):

```elixir
def encode(destination, params) when is_atom(destination) do
  base = Map.fetch!(@canonical_paths, destination)

  query =
    params
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> URI.encode_query()

  if query == "", do: base, else: "#{base}?#{query}"
end
```

Extend it with a single canonical Jobs order:

```text
state, queue, worker, tags, args, meta, page, job
```

`job_detail_path/2` should accept only:

```text
state, queue, worker, tags, args, meta, page
```

It must drop `job`, `return_to`, and all unknown values. Do not keep `JobsLive.back_path_from_session/1`; the full detail route reconstructs its back link from explicit allowlisted request state.

Forensics preserves exactly:

```text
resource_type, resource_id, workflow_id, step, incident_fingerprint, view
```

The existing selector tests show the required literal-order style (`selectors_test.exs:103-125`):

```elixir
path =
  Selectors.audit_path([
    {"resource_type", "job"},
    {"resource_id", resource_id},
    {"event_type", "lifeline.repair_executed"},
    {"page", 3},
    {"event", event_id}
  ])

assert URI.decode_query(URI.parse(path).query) == %{
  "resource_type" => "job",
  "resource_id" => resource_id,
  "event_type" => "lifeline.repair_executed",
  "page" => "3",
  "event" => event_id
}
```

Add negative assertions for opaque `return_to`, quick-review `job` on detail links, a seventh Forensics key, and delimiter-heavy values.

### 4. Reuse one Jobs query base across rows, counts, and frozen IDs

The current `Jobs` context already has the locked filter semantics and stable list order (`jobs.ex:89-117,162-176`):

```elixir
def list(repo, %__MODULE__{} = filter, _opts \\ []) do
  offset = (filter.page - 1) * filter.page_size

  base_query(filter)
  |> order_by([j], desc: j.scheduled_at, desc: j.id)
  |> limit(^filter.page_size)
  |> offset(^offset)
  |> repo.all()
end

defp maybe_filter_tags(query, tags),
  do: where(query, [j], fragment("? @> ?", j.tags, ^tags))

defp maybe_filter_args(query, args),
  do: where(query, [j], fragment("? @> ?", j.args, type(^args, :map)))

defp maybe_filter_meta(query, meta),
  do: where(query, [j], fragment("? @> ?", j.meta, type(^meta, :map)))
```

Refactor without changing those semantics:

```text
non-state predicates: queue AND worker AND all tags AND args containment AND meta containment
active list/count: non-state predicates + required state
grouped counts: non-state predicates only, GROUP BY state, merge into fixed zero map
frozen IDs: active predicates + scheduled_at DESC, id DESC + limit + 1
```

The current seven-round-trip implementation (`jobs.ex:139-154`) is the anti-pattern to replace:

```elixir
Map.new(@states, fn state ->
  count =
    Oban.Job
    |> where([j], j.state == ^state)
    ...
    |> repo.one()

  {state, count}
end)
```

Use one grouped query and merge its result into a fixed seven-state zero map. Add an exact active-filter count for range copy and Next availability. Do not infer Next from `length(rows) == 20`.

`Audit.page/2` is the closest result-shape analog (`audit.ex:107-130`):

```elixir
query = filter_query(__MODULE__, filters)
total_count = repo.aggregate(query, :count, :id)
...
events =
  query
  |> order_by([event], desc: event.inserted_at, desc: event.id)
  |> limit(^@page_size)
  |> offset(^offset)
  |> repo.all()

%{
  events: events,
  total_count: total_count,
  page: page,
  page_size: @page_size,
  previous?: page > 1,
  next?: page < total_pages
}
```

`ordered_ids_window` must return overflow explicitly; never silently take the first N. The extra `limit + 1` row detects oversize and is not frozen.

### 5. Forensics scope is a sum type, not precedence

The current `Forensics.bundle/2` uses hidden precedence (`forensics.ex:15-34`):

```elixir
cond do
  selectors.workflow_id ->
    workflow_bundle(repo, selectors)

  selectors.incident_fingerprint ->
    lifeline_bundle(repo, selectors)

  selectors.resource_type == "cron_entry" and selectors.resource_id ->
    CronHistory.bundle(repo, selectors.resource_id, selectors)

  selectors.resource_type == "limiter" and selectors.resource_id ->
    LimiterHistory.bundle(repo, selectors.resource_id, selectors)

  true ->
    unknown_bundle(selectors)
end
```

Replace it with an explicit parser result before any query:

```elixir
{:empty, canonical_params, explanation}
{:ok, %Forensics.Scope{kind: :workflow | :incident | :cron | :limiter, ...}, canonical_params}
{:invalid, [], explanation}
```

Rules:

- no keys is the real empty chooser;
- exactly one valid family may load;
- orphan `step`/`view`, unknown resource types, incomplete pairs, and mixed families are invalid;
- invalid direct scopes replace to bare `/forensics` with an explanation;
- a valid but absent/unauthorized target becomes the same `Evidence unavailable` state;
- arbitrary job IDs are not a fifth evidence family.

Derive accepted `resource_type` literals from current producers. Existing code establishes at least `workflow`, `workflow_step`, `cron_entry`, and `limiter`; do not accept arbitrary paired strings merely because both fields are present.

### 6. Forensics reads must be bounded in Ecto, not after loading

The current workflow and incident reads are explicit anti-patterns (`forensics.ex:289-310`):

```elixir
defp workflow_audit_events(repo, workflow, selected_step) do
  Audit.list_all(repo: repo)
  |> Enum.filter(fn event ->
    ...
  end)
end

defp incident_audit_events(repo, incident) do
  Audit.list_all(repo: repo)
  |> Enum.filter(fn event ->
    event.metadata["incident_fingerprint"] == incident.incident_fingerprint
  end)
end
```

The closest implementation analog is the composable stable Audit query (`audit.ex:296-321`) plus its bounded page:

```elixir
defp filter_query(query, filters) do
  Enum.reduce(filters, query, fn
    {"resource_type", value}, query ->
      where(query, [event], event.resource_type == ^value)

    {"resource_id", value}, query ->
      where(query, [event], event.resource_id == ^value)

    {"event_type", value}, query ->
      where(query, [event], event.event_type == ^value)

    _, query ->
      query
  end)
end
```

Add a forensic window API with:

- source-specific exact predicates;
- `inserted_at DESC, id DESC`;
- finite limit;
- exact total or `limit + 1` `has_more?`;
- explicit coverage/provenance metadata;
- no `list_all/1`.

Workflow evidence should prefer relational `resource_type/resource_id` predicates. Incident fingerprint may require a JSONB metadata predicate; keep it bounded, measure/document `EXPLAIN`, and do not add a migration. Cron and Limiter already enforce `@history_limit 8`; preserve that bound and disclose it.

### 7. Presentation maps are closed before assignment

`ControlPlanePresenter` already supplies the right fail-closed shape. The Audit row presenter selects every output key (`control_plane_presenter.ex:280-300`):

```elixir
%{
  id: normalize_audit_id!(event.id),
  event_label: event_label,
  target_label: target_label,
  target_href: audit_target_href(identity),
  actor: actor,
  reason_summary: reason,
  recorded_at: recorded_at,
  recorded_datetime: recorded_datetime,
  evidence_href: audit_evidence_href(identity, event),
  evidence_label: "View evidence for #{event_label} on #{target_label}"
}
```

Its validators reject structs, sensitive source fields, and unknown evidence keys (`control_plane_presenter.ex:1128-1174`):

```elixir
defp ensure_presentation_map!(value, name) when is_map(value) do
  if is_struct(value) do
    raise ArgumentError, "#{name} must be a plain presentation map"
  end

  ensure_safe_presentation_data!(value, name)
end

if not is_nil(nested) and sensitive_presentation_source_key?(normalized_key) do
  raise ArgumentError, "#{name} contains a prohibited source field"
end
```

Add distinct Jobs presenters for:

```text
row               -> only the eight table-column/control facts
quick review      -> bounded read-only identity/current/error/output-availability disclosure
full detail       -> ordered action/identity/error/payload/redaction/destination sections
batch result      -> success | skipped | failed with finite safe copy
```

Add a Forensics presenter for:

```text
support, scope, summary, next_steps, latest_remediation, events, coverage, audit_href
```

Do not pass Oban jobs, Audit schemas, exceptions, runbook maps, arbitrary metadata, preview tokens, plan hashes, raw errors, stacktraces, or payload-like maps into page assigns. `EvidenceBundle` currently preserves unknown binary keys; therefore it is an internal normalizer, not proof of render safety.

`normalize_operator_results/1` already preserves the required result split (`control_plane_presenter.ex:375-417`):

```elixir
%{
  id: ...,
  object_label: ...,
  outcome: normalize_closed_value!(..., @operator_result_states, ...),
  message: ...,
  recovery: ...,
  audit_href: ...
}
```

Never use `inspect(error)` in Jobs result copy. Note that `LiveAuth.mutation_error/1` currently falls back to `inspect(reason)`; Phase 80 coordinator/presenter paths must instead use a finite taxonomy.

### 8. Shared components already encode the required semantics

Use the existing components directly:

| Phase 80 surface | Component |
|---|---|
| Jobs filters and Forensics chooser | `OperatorPatterns.filter_bar/1` in `:submit` mode + `Forms` |
| Jobs scan | `DataDisplay.data_table/1` |
| Jobs quick review | `OperatorPatterns.detail_surface/1` |
| single and bulk confirmation/results | `OperatorPatterns.confirm_action_dialog/1` |
| full detail facts | `DataDisplay.description_list/1` |
| args/meta/output | `DataDisplay.args_viewer/1`, `code_block/1` |
| Forensics event log | `DataDisplay.timeline/1` |

The table already renders one native table and mobile labels (`data_display.ex:79-135`):

```elixir
<table class="obpt-data-table__table">
  ...
  <tr :for={row <- @rows} :if={@state == :ready} class="obpt-data-table__row">
    <td :if={@selection != []} data-obpt-mobile-label="Selection">...</td>
    <td :for={col <- @col} data-obpt-mobile-label={col.label}>...</td>
    <td :if={@action != []} data-obpt-mobile-label="Actions">...</td>
  </tr>
</table>
```

Jobs supplies columns in the locked order: Selection, Worker, State, Queue, Scheduled, Attempts, Job ID, Review job. Rows are not click targets. The Review control and checkbox each get a durable accessible name; the reviewed row gets structural/programmatic current state.

The detail surface explicitly leaves URL/auth/loading to the parent (`operator_patterns.ex:334-339`):

```elixir
Callers must close or leave modal detail before opening a confirmation dialog. The
component never fetches, authorizes, changes URL state, or renders nested dialogs.
```

Its public footer currently says “Open full details.” Phase 80 locks “Open full job details”; prefer a generic label attr only if the shared component cannot express that exact noun without forking Jobs markup.

The timeline already keeps semantic ordered-list structure (`data_display.ex:286-299`):

```elixir
<ol :if={@state == :ready} class="obpt-timeline__list">
  <li :for={{event, index} <- Enum.with_index(@event)} ...>
    <time ...>{event.timestamp}</time>
    <p ...>{event.title}</p>
    <span :if={Map.get(event, :source)}>{event.source}</span>
    <.status_pill :if={Map.get(event, :domain) && Map.get(event, :state)} ... />
    <div>{render_slot(event)}</div>
  </li>
</ol>
```

Feed it absolute timestamps, grammatical event sentences, finite human source/status, redacted notes, and authorized links. Status, provenance, severity, and completeness remain separate.

### 9. Freeze scope before preview; execute outside the socket

The current page defers “all matching” and runs sequential mutation work inside `handle_event` (`jobs_live.ex:301-348`):

```elixir
job_ids =
  if socket.assigns.global_select do
    Jobs.list_ids(repo(), filter)
  else
    socket.assigns.selected_jobs
  end

Enum.reduce(job_ids, {0, 0}, fn job_id, {succ, fail} ->
  case Lifeline.preview_repair(repo(), actor, %{...}) do
    {:ok, preview} ->
      case Lifeline.execute_repair(repo(), actor, preview.preview_token, reason) do
        {:ok, _} -> {succ + 1, fail}
        _ -> {succ, fail + 1}
      end
    _ -> {succ, fail + 1}
  end
end)
```

Replace `global_select` with explicit state:

```elixir
%{mode: :explicit, ids: MapSet.t()}

%{
  mode: :all_matching,
  ids: [integer],
  filter_identity: binary,
  selected_count: non_neg_integer,
  observed_at: DateTime.t()
}
```

All-matching freezes ordered IDs immediately after the bounded `limit + 1` query. Preview authorizes the page, action, and each target, then calls the real Lifeline API. Keep execution and display layers separate:

```elixir
%{
  ready: [%{job_id: id, token: opaque, ...}],
  excluded: [%{job_id: id, reason: finite_atom, ...}],
  display: %{selected_count: ..., ready_count: ..., excluded_count: ...}
}
```

Lifeline remains the exact per-target authority (`lifeline.ex:157-213`):

```elixir
with :ok <- authorize(actor, :preview_repair, attrs),
     {:ok, preview_attrs} <- build_preview(repo, attrs, now) do
  ...
end

with %RepairPreview{} = preview <- repo.get_by(RepairPreview, preview_token: preview_token),
     :ok <- authorize(actor, :execute_repair, %{preview_token: preview.preview_token}),
     :ok <- ensure_preview_available(repo, preview, now),
     :ok <- validate_reason(reason, preview.reason_required),
     {:ok, current_hash} <- recompute_plan_hash(repo, preview),
     :ok <- ensure_not_drifted(repo, preview, current_hash, now),
     {:ok, result} <- apply_repair(...) do
  {:ok, result}
end
```

Add a named Task Supervisor through the existing application child pattern (`application.ex:11-21`):

```elixir
children =
  []
  |> maybe_add_pubsub()
  |> maybe_add_workflow_coordinator()
  |> maybe_add_heartbeat_writer()

Supervisor.start_link(children, strategy: :one_for_one, name: ObanPowertools.Supervisor)
```

There is no existing supervised batch-task analog in this repository. The new coordinator must use library-owned nonlinked work, maximum concurrency four, finite per-target timeout, stable result reconstruction by frozen order, and low-cardinality messages. The socket may observe progress but does not own task lifetime.

Messages should carry run reference and aggregate progress, not preview tokens, payloads, raw errors, or telemetry identifiers:

```text
run_ref, processed, total, success_count, skipped_count, failed_count
```

On partial completion, clear successful IDs and retain unresolved/skipped/failed IDs. A later attempt starts with fresh authorization and preview.

### 10. Confirmation and progress are parent-owned truth

`confirm_action_dialog/1` is already consequence-first and parent-owned (`operator_patterns.ex:52-110`):

```elixir
The component never authorizes or executes an action. Parents create the preview,
revalidate submitted fields and frozen scope, normalize results, and remove the dialog
after an authoritative clean success.

assigns
|> assign(:progress_measurement, confirmation_progress(assigns.progress))
|> assign(:results, ControlPlanePresenter.normalize_operator_results(assigns.results))
```

Use it for both single-target full detail and bulk operations. Bulk confirmation supplies:

- selected/ready/excluded/off-page counts;
- human applied-filter identity and captured time;
- consequence, reversibility, and support boundary;
- non-atomic and restart truth;
- reason of at least eight trimmed characters;
- exact typed ready count.

Zero-ready cannot submit. Drift/expiry requires fresh preview. Only an all-success exact receipt may dismiss immediately; partial/skipped/failed/interrupted states stay visible with bounded/paged rows.

Use one restrained status/live region for start/final outcome. Visible progress is actual processed/total, not animation, and per-target completion must not flood assistive technology.

### 11. Forensics composition is one diagnosis-first page

Do not preserve the current card-wall order or raw bundle access in `ForensicsLive`. Compose one page:

```text
Forensics title + read-only support truth
typed FilterBar
Investigation summary
What to do next
Latest remediation evidence (only when genuine; neutral/history-labeled)
Event log using Timeline
Evidence limits and sources
```

The page must not use `DetailSurface`, tabs, a two-pane explorer, or duplicated completeness cards. Deduplicate guidance by canonical URL and meaning. Only authorized, supported noun actions render:

```text
Open workflow
Review incident in Lifeline
Open cron entry
Review limiter blockers
View matching audit evidence
```

Current truth, historical evidence, provenance, status, and completeness remain independent. Chronological adjacency must not imply cause.

The existing `EvidenceBundle.build/1` shows why a separate presenter remains necessary (`evidence_bundle.ex:34-50`):

```elixir
%{
  subject: ...,
  diagnosis_summary: ...,
  chronology: chronology,
  related_evidence: ...,
  linked_resources: ...,
  legal_next_paths: ...,
  completeness: ...
}
```

It is useful as an internal assembly shape, but its documented preservation of unknown keys and the current chronology's `reason`, `action`, `selected_path`, and `runbook_context` fields are too broad for page assigns.

### 12. Reuse current token-owned responsive behavior

The shared table already becomes stacked rows at 24rem without duplicate DOM (`tokens.css:1727-1805`):

```css
@media (max-width: 24rem) {
  .obpt-root .obpt-data-table__table,
  .obpt-root .obpt-data-table__table caption,
  .obpt-root .obpt-data-table__table thead,
  .obpt-root .obpt-data-table__table tbody,
  .obpt-root .obpt-data-table__header,
  .obpt-root .obpt-data-table__cell {
    display: block;
    width: 100%;
    max-width: 100%;
  }

  .obpt-root .obpt-data-table__row {
    display: grid;
    min-width: 0;
    max-width: 100%;
  }
}
```

The detail surface already becomes full-screen at the same breakpoint and enforces 44px-class targets (`tokens.css:3272-3278,3340-3367`). Extend only page composition selectors so Jobs and Forensics join the Phase 79 root-scoped page system (`tokens.css:3689-3709`):

```css
.obpt-root .obpt-page,
.obpt-root #overview-page,
.obpt-root .obpt-cron-page,
.obpt-root .obpt-limiters-page,
.obpt-root .obpt-audit-page {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--obpt-space-6);
  min-width: 0;
  max-width: 100%;
}
```

Add narrowly scoped `.obpt-jobs-page` and `.obpt-forensics-page` composition. Preserve semantic tokens, light/dark/system/high-contrast behavior, focus, reduced motion, and no page-level horizontal scrolling. Regenerate packaged CSS; do not hand-edit the static file.

### 13. Extend the exact production-composition story harness

The story catalog states the governing seam (`page_story_catalog.ex:1-7`):

```elixir
Every fixture is finite normalized presentation data. The showcase feeds it
through the production page composition functions, while this support module
remains outside the runtime package.
```

ShowcaseLive directly calls every production page function (`showcase_live.ex:910-959`):

```elixir
case @story.page do
  :overview -> <EngineOverviewLive.page_content ... />
  :cron -> <CronLive.page_content ... />
  :limiters -> <LimitersLive.page_content ... />
  :audit -> <AuditLive.page_content ... />
end
```

Add `:jobs` and `:forensics`, their activation/materialization rules, and direct calls to the new page seams. Do not copy page HEEx into the showcase.

The current hard gates are deliberate:

```elixir
# showcase_live.ex
@page_story_count 19
@page_story_pages [:overview, :cron, :limiters, :audit]
```

```elixir
# scripts/showcase_manifest.exs
unless length(page_stories) == 19, do: raise(...)
unless length(targets) == 83, do: raise(...)
schema_version: 8
```

```javascript
// verify-page-baselines.mjs
const expectedStoryCount = 19;
const expectedCount =
  expectedStoryCount * expectedThemes.length * viewportProjects.size;

/^page-(overview|cron|limiters|audit)-[a-z0-9-]+$/
```

Update every exact count and the page-name regex together after the final ID list is locked. Preserve:

```text
final page story count × 4 themes × 3 viewports = exact PNG count
final page story count × 3 viewport projects = exact ARIA snapshot count
```

“Thousands of jobs” stories must render a 20-row page with a count in the thousands, not thousands of DOM rows.

### 14. Connected fixtures prove what static stories cannot

The Phase 79 host fixture is the exact security/isolation analog (`phase79_browser_fixtures.ex:11-49,459-518`):

```elixir
if Mix.env() == :test and System.get_env("PHASE79_BROWSER_FIXTURES") == "1" do
  ...
  def reset(%{"project" => project, "run" => run}) do
    with :ok <- validate_project(project),
         :ok <- validate_run(run) do
      Repo.transaction(fn ->
        ...
        public_state(...)
      end)
    end
  end
end
```

```elixir
defp authenticate(conn) do
  expected = System.get_env("PHASE79_BROWSER_FIXTURE_SECRET") || ""
  provided = conn |> get_req_header("x-phase79-fixture-secret") |> List.first() || ""

  if expected != "" and provided != "" and constant_time_equal?(expected, provided),
    do: :ok,
    else: {:error, :not_found}
end

defp not_found(conn), do: send_resp(conn, 404, "")
```

The TS client also validates a closed public response and rejects sensitive keys (`phase79-fixtures.ts:183-240`). Preserve those properties for Jobs/Forensics:

- test-only and explicit opt-in;
- POST-only closed commands;
- secret header with uniform empty 404 failure;
- deterministic reset keyed by project/run;
- exact actor set and capability differences;
- exact response keys with no token/hash/raw error/metadata leakage;
- fixture barriers/polling, not arbitrary sleeps.

Static stories cover composition states. Connected fixtures must cover URL history, direct invalid URL replacement, real filter semantics, exact query bounds, auth equality, frozen membership, Lifeline drift/execute, task continuation after disconnect, and scoped Forensics Ecto reads.

For the disconnect test, start a deliberately gated supervised batch, disconnect/navigate away, release it through a test-only control, and poll for individual Lifeline Audit evidence with a finite timeout. Do not imply reconstruction of aggregate progress after reconnect.

## Test Pattern Assignments

### Query counts and stable bounds

`audit_test.exs:198-228` already provides a telemetry-based query counter:

```elixir
:telemetry.attach(
  handler_id,
  event,
  fn _event, _measurements, metadata, pid ->
    if metadata[:source] == "oban_powertools_audit_events" do
      send(pid, :audit_query)
    end
  end,
  test_pid
)
```

Adapt that style to prove:

- Jobs grouped state counts use one query and still return seven keys;
- list/count/ID windows apply identical optional predicates;
- Forensics workflow/incident paths never call an unbounded full-table loader;
- `fetch_in_scope`/unavailable paths do not enumerate across authorization or filter scope.

Avoid brittle complete SQL equality. Query-plan assertions may inspect generated SQL/index use only for the specific incident JSONB measurement.

### Coordinator determinism

Use message barriers or a test adapter to control each target. Assert:

- frozen order survives out-of-order completion;
- active target count never exceeds four;
- one timeout/crash does not crash the run or socket;
- authorization/resource disappearance is rechecked;
- zero-ready and typed-count/reason gates prevent execution;
- drifted/expired/consumed/skipped/failed remain distinct;
- only safe aggregate messages cross to the LiveView;
- task continues when the observing LiveView exits;
- individual Audit rows are the post-disconnect recovery authority.

No test should depend on an arbitrary sleep for lifecycle correctness.

### Redaction absence, not merely redaction copy

The existing presenter suite already table-tests prohibited keys. Extend it with sentinel values in:

```text
args, meta, recorded output, latest error, stacktrace,
operator reason, audit metadata, runbook continuity, URL/query/header/token fields
```

Assert sentinel absence from:

- presenter output;
- rendered HTML;
- LiveView-visible DOM/diffs;
- coordinator messages;
- captured logs;
- telemetry metadata;
- fixture public responses.

Do not consider the presence of “[redacted]” sufficient if the original sentinel also survives.

### Browser matrix

The generic acceptance spec already asserts required/forbidden/ordered copy, roles, and ARIA snapshots for every page story. Keep it generic and extend the catalog.

The final aggregate scripts should run:

```text
page.acceptance.spec.ts
page-migration-wave-1.spec.ts
page-migration-wave-2.spec.ts
showcase.a11y.spec.ts with PAGE_QUALITY_ONLY=1
showcase.vrt.spec.ts with PAGE_QUALITY_ONLY=1
```

The connected Wave 2 spec owns history/auth/query/mutation/disconnect assertions; VRT and static page stories do not substitute for them.

## Integration Order

The pattern dependencies support the research's nine-plan decomposition:

```text
canonical parser/query/presenter contracts
  |
  +--> Jobs browse/filter/count/quick review
  |      |
  |      +--> Jobs full detail + single confirmation
  |      |
  |      +--> frozen batch coordinator + supervisor
  |
  +--> Forensics typed bounded evidence
         |
         +--> diagnosis-first page

all production page seams
  -> exact story matrix + CSS + manifest/ARIA contracts
  -> isolated connected fixtures + Wave 2 browser spec
  -> full page-quality and repository closure
```

`JobsLive` is a high-overlap file across browse, detail, and bulk work, so those plans should be sequential even though Forensics context work can proceed independently. Baselines come after story IDs and production composition stabilize.

## Anti-Patterns to Remove

- Jobs `phx-change` querying/patching on every valid edit.
- Seven state-count round trips.
- Unbounded `Jobs.list_ids/2`.
- `global_select` as deferred filter execution authority.
- Sequential Lifeline work in `handle_event`.
- `inspect(reason)`/`inspect(error)` in operator-visible results.
- Entire-row click behavior or shortened worker module identity.
- Arguments/meta/output/stacktrace/mutations inside quick review.
- Opaque `return_to`.
- Forensics selector precedence.
- `Audit.list_all |> Enum.filter`.
- Raw audit reason/runbook context/source/action atoms in assigns.
- Card-wall Forensics rendering and duplicated completeness.
- A bounded component backed by an unbounded query.
- A story-only fork of production page markup.
- Relaxed manifest/baseline cardinality to accommodate additions.
- Thousands of DOM rows for a “thousands” fixture.
- Test fixture routes available without test-only opt-in and a secret.

## Planning Anchors

The planner still needs to lock these bounded choices:

1. Exact Phase 80 Jobs and Forensics story IDs and final story count.
2. New coordinator module name and per-target timeout.
3. Runtime config key name for the 100-default/1000-max bulk target limit.
4. Whether page fixture naming is generalized with Phase 79 aliases or implemented as a lower-risk sibling.
5. Exact accepted Forensics `resource_type` literals and supported incident `view` values derived from current producers.
6. Exact Forensics event-window/result-page bounds.
7. Conservative error attempt/text limits in the presenter.
8. Whether any genuinely generic component attr is required for the exact “Open full job details” label or added frozen-scope copy.

These choices may not alter the locked URL keys, filter semantics, fixed Jobs ordering/page size, bulk bounds/concurrency, safety semantics, support truth, page order, or verification matrix.
