# Phase 79: Page Migration Wave 1 — Overview, Cron, Limiters, Audit - Pattern Map

**Mapped:** 2026-07-19  
**Binding inputs:** `79-CONTEXT.md` decisions D-01 through D-45 and `79-RESEARCH.md`  
**Scope:** Four production LiveViews, their bounded query/presentation seams, scoped page layout, deterministic page stories, browser evidence, and regression tests

## Scope and Instruction Check

- No root `CLAUDE.md`, `.claude/CLAUDE.md`, root `AGENTS.md`, project-local `.claude/skills/`, or project-local `.agents/skills/` exists. The only repository `AGENTS.md` is beneath `examples/phoenix_host_upgrade_source/`, outside Phase 79's scope.
- Existing unrelated worktree changes are user-owned and must be preserved. This artifact is the only file changed by pattern mapping.
- `ThemeShell` already supplies `AppShell`; none of the four pages should instantiate another shell.
- Parent LiveViews remain the orchestration boundary. Shared components stay stateless `Phoenix.Component` functions and must receive normalized maps, never raw schemas or metadata.
- Overview, Limiters, and Audit remain read-only. Cron alone retains pause, resume, and run-now.
- The only required query-shape change is bounded Audit retrieval with a stable tie-break. A batched Limiters read and bounded Overview/Cron support reads are contained optimizations, not new product capabilities.
- The context names `lib/oban_powertools/display_policy.ex`, but the repository's actual `ObanPowertools.DisplayPolicy` module is in `lib/oban_powertools/runtime_config.ex:84`. Phase 79 should use it, not move or globally rewrite it.
- No dependency, schema migration, route, authorization policy, provider adapter, `Cron` public command contract, or AppShell architecture change is expected.

## Architecture and Data Flow

```text
canonical URL params
  entry | resource | resource_type/resource_id/event_type/page/event
          |
          v
parent LiveView handle_params/3
  authorize page/resource/action on the server
  load bounded repository truth outside render/1
  own selection, forms, preview, recovery, receipts, and focus fallback
          |
          +--> domain/query seam
          |      OverviewReadModel | Cron | Limiters reads | Audit.page
          |
          +--> ControlPlanePresenter + DisplayPolicy
          |      schemas/domain structs -> finite redaction-safe presentation maps
          |
          +--> stateless shared components
                 DataTable | MetricCard | DetailSurface | ConfirmActionDialog
                 AttentionCard | WhyBlocked | AuditEntry | Forms | Primitives
                          |
                          v
                 one semantic token-owned HEEx tree

deterministic normalized page fixtures (dev/test only)
  -> production page composition path
  -> ShowcaseLive
  -> versioned generated manifest
  -> strict Node/TypeScript validation
  -> generic structure/axe/VRT matrix + connected behavior spec
```

Repository work must not occur in `render/1` or a shared component. Responsive behavior must reflow one DOM tree; no desktop/mobile duplicate is allowed.

## File Classification

### Production and packaged assets

| Expected File | Change | Role | Data Flow | Closest Existing Analog | Match |
|---|---|---|---|---|---|
| `lib/oban_powertools/web/engine_overview_live.ex` | modify | read-only page composition | normalized ordered buckets -> shared triage surfaces | same file for auth/load; `OperatorPatterns.attention_card/1`, `DataDisplay.metric_card/1` for rendering | composite exact |
| `lib/oban_powertools/web/overview_read_model.ex` | modify | page aggregation/ranking boundary | repository facts + one captured `now` -> six finite ordered bucket maps | same file and `AttentionProjection.project_bucket/2` | exact |
| `lib/oban_powertools/web/cron_live.ex` | modify | selected-detail mutation orchestrator | `entry` URL + auth + preview/form/result -> table/detail/dialog/receipt | same file's durable state machine plus `OperatorPatternsHarnessLive` lifecycle | composite exact |
| `lib/oban_powertools/web/limiters_live.ex` | modify | read-only master/detail orchestrator | `resource` URL + current/snapshot/history reads -> normalized table/detail | same file plus `why_blocked/1` and harness detail lifecycle | composite exact |
| `lib/oban_powertools/web/audit_live.ex` | modify | read-only paged evidence orchestrator | exact filters + `page` + `event` -> filter/table/detail/navigation | harness filter/detail URL ownership plus `AuditLive` exact filters | composite exact |
| `lib/oban_powertools/audit.ex` | modify | query/domain boundary | exact filter map + page options -> rows/count/page metadata | existing `filter_query/2` plus `Jobs.list/3` database pagination | composite exact |
| `lib/oban_powertools/web/control_plane_presenter.ex` | modify | pure finite presenter/redaction seam | domain inputs -> consumer copy and closed presentation maps | same file's blocker/audit/operator-result normalizers | exact |
| `lib/oban_powertools/web/components/operator_patterns.ex` | narrow conditional modify | stateless shared component contract | normalized attrs/maps/slots -> semantic HEEx | same file | exact |
| `lib/oban_powertools/web/selectors.ex` | modify/use | canonical ordered URL builder | ordered params -> encoded page/selection/filter URLs | same file | exact |
| `assets/oban_powertools/tokens.css` | modify | root-scoped page layout CSS | page classes/state attrs -> token-owned reflow | existing data-table/detail/operator blocks in same file | exact |
| `priv/static/oban_powertools/oban_powertools.css` | regenerate | checked-in package asset | normalized source CSS -> shipped bytes | same file through `mix oban_powertools.assets.build` | exact |

`lib/oban_powertools/web/components/operator_patterns.ex` should change only if the page cannot express D-28's optional affected scope or D-33's visible `Recorded at` label through the current closed contract. Existing callers must remain valid.

### Deterministic page-story and browser harness

| Expected File | Change | Role | Data Flow | Closest Existing Analog | Match |
|---|---|---|---|---|---|
| `test/support/page_story_catalog.ex` | likely new; exact name planner may lock | dev/test page fixture catalog | normalized safe fixtures -> stable page story metadata | `test/support/operator_pattern_story_catalog.ex` | exact role |
| `test/oban_powertools/page_story_catalog_test.exs` | likely new | deterministic catalog contract | page stories -> exact order/count/state/safety assertions | `operator_pattern_story_catalog_test.exs` | exact role |
| `lib/oban_powertools/web/dev/showcase_live.ex` | modify | connected story host | page catalog + events -> production page composition | current group-story integration in same file | exact extension |
| `scripts/showcase_manifest.exs` | modify | manifest generator | Elixir catalogs -> versioned JSON | current schema-6 `group_stories` append | exact |
| `test/browser/support/manifest.ts` | modify | strict generated-manifest types/validator | JSON -> typed `page` targets | current group target validation | exact |
| `test/browser/support/manifest-smoke.mjs` | modify | independent Node manifest gate | JSON -> schema/order/count diagnostics | current schema-6 group checks | exact |
| `test/browser/support/showcase.ts` | modify | generic browser target activation | page target metadata -> one selected detail/dialog at most | current group activation branch | exact extension |
| `test/browser/specs/showcase.structure.spec.ts` | modify | generic DOM structure matrix | all targets -> semantic/metadata assertions | same file | exact |
| `test/browser/specs/showcase.a11y.spec.ts` | modify as needed | generic axe matrix | activated page story × theme × viewport -> axe | same file | exact |
| `test/browser/specs/showcase.vrt.spec.ts` | modify as needed | generic visual matrix | activated page story × theme × viewport -> PNG | same file | exact |
| `test/browser/specs/page-migration-wave-1.spec.ts` | likely new; exact name may follow convention | connected production-page behavior | real LiveView URL/keyboard/focus/mutation events -> assertions | `operator-patterns.behavior.spec.ts` | exact style |
| `test/browser/support/verify-page-baselines.mjs` | likely new or equivalent verifier extension | exact baseline/scope gate | locked page story IDs × 4 themes × 3 viewports + git scope -> diagnostics | `verify-group-baselines.mjs` | exact role |
| `test/browser/__screenshots__/chromium-{320,tablet,wide}/showcase/page-*/{system,light,dark,high-contrast}.png` | generated new | page VRT evidence | locked story count × 12 -> PNGs | existing `group-*` baseline family | exact |

The page catalog name and story count must be locked in the plan before baseline generation. Existing scenario/component/group IDs remain stable; page stories append a new target kind rather than replacing old catalogs.

### Tests and validation evidence

| Expected File | Change | Role | Data Flow | Closest Existing Analog | Match |
|---|---|---|---|---|---|
| `test/oban_powertools/web/live/engine_overview_live_test.exs` | extend | Overview behavior/regression | fixtures/auth -> semantic order, bounds, links, confidentiality | same file | exact |
| `test/oban_powertools/web/live/cron_live_test.exs` | extend | Cron safety/state-machine regression | actor/events/repo -> double auth, preview recovery, mutation, Audit, receipt | same file | exact |
| `test/oban_powertools/web/live/limiters_live_test.exs` | extend | Limiter evidence-truth regression | resources/auth/selection -> current/snapshot/history and destinations | same file | exact |
| `test/oban_powertools/web/live/audit_live_test.exs` | extend | Audit URL/render/read-only regression | filter/page/event URLs -> bounded table/detail | same file | exact |
| `test/oban_powertools/audit_test.exs` | likely new focused query test | Audit paging/query contract | inserted rows + exact filters -> count/order/reachability | `jobs_test.exs`, `batches_test.exs` | role match |
| `test/oban_powertools/web/operator_pattern_presenter_test.exs` | extend | pure presenter/security contract | maps/schemas -> normalized values or fail-closed errors | same file | exact |
| `test/oban_powertools/web/selectors_test.exs` | extend | canonical URL contract | ordered filter/page/event params -> exact URLs | same file | exact |
| `test/oban_powertools/web/components/operator_patterns_test.exs` | conditional extend | shared component compatibility | optional affected scope/time label -> HTML | same file | exact |
| `test/oban_powertools/web/live/operator_patterns_harness_test.exs` | conditional extend | connected component lifecycle | parent events -> detail/dialog/focus transitions | same file | exact |
| `test/oban_powertools/web/live/showcase_live_test.exs` | extend | catalog/render/package boundary | page story route/events -> one production composition tree | same file | exact |
| `test/oban_powertools/web/theme_tokens_test.exs` | extend | CSS static contract | source CSS -> root/token/media assertions | same file | exact |
| `test/oban_powertools/web/assets_test.exs` | extend | packaged asset/idempotence contract | build/source/static -> selectors and byte equality | same file | exact |
| `test/oban_powertools/hex_release_test.exs` | conditional extend | package exclusion contract | built tarball -> dev/test catalog absent | existing support-catalog exclusions | exact |
| `.planning/phases/79-page-migration-wave-1-overview-cron-limiters-audit/79-VALIDATION.md` | update through execution | Nyquist evidence ledger | task commands/manual observations/baseline count -> closeout proof | Phase 78 validation artifact | exact |

No `assets/oban_powertools/theme.js` or packaged JavaScript change is expected: Phase 78 already owns adaptive detail and confirmation behavior. Change it only if a concrete shipped-controller defect prevents the locked page lifecycle, and retain the standalone/idempotent host contract.

## Pattern Assignments and Concrete Analogs

### 1. Parent LiveViews own state; shared components render it

The exact ownership contract is already documented in the shared components. `operator_patterns.ex:52-58`:

```elixir
@doc """
Renders consequence-first confirmation from parent-owned preview, form, and result truth.

The component never authorizes or executes an action. Parents create the preview,
revalidate submitted fields and frozen scope, normalize results, and remove the dialog
after an authoritative clean success.
"""
```

`operator_patterns.ex:334-339` makes the detail boundary equally explicit:

```elixir
@doc """
Renders one adaptive native-dialog tree from parent-owned selection and content truth.

Callers must close or leave modal detail before opening a confirmation dialog. The
component never fetches, authorizes, changes URL state, or renders nested dialogs.
"""
```

Apply this directly:

- `EngineOverviewLive` authorizes and loads a read model, then renders stable sections.
- `CronLive` owns `entry`, current-principal authorization, form errors, preview freshness, result classification, reload, receipt, and focus fallback.
- `LimitersLive` owns `resource`, evidence retrieval, Forensics authorization, and current/history separation.
- `AuditLive` owns exact filters, page, selection, close/reset URLs, and redaction-ready row/detail maps.

Do not add a LiveComponent. Do not let a component infer permission from `disabled`, fetch schemas, build URLs, or execute mutations.

### 2. Canonical selection/history lifecycle

The Phase 78 harness is the closest exact lifecycle analog. `operator_patterns_harness_test.exs:246-269`:

```elixir
def handle_event("open-detail", %{"id" => id}, socket) do
  first_open? = is_nil(socket.assigns.selected_detail)
  op = if first_open?, do: :push, else: :replace
  url = detail_url(socket.assigns.applied_filters, id)

  {:noreply,
   socket
   |> assign(:selected_detail, id)
   |> assign(:confirmation_open?, false)
   |> assign(:canonical_url, url)
   |> record_history(op, url)}
end

def handle_event("close-detail", _params, socket) do
  url = filter_url(socket.assigns.applied_filters)

  {:noreply,
   socket
   |> assign(:selected_detail, nil)
   |> assign(:canonical_url, url)
   |> record_history(:replace, url)}
end
```

Use the real LiveView operations (`push_patch`/`replace`) with `Selectors`, not the harness's history recorder:

- first `entry`, `resource`, or `event` selection pushes;
- switching selection replaces;
- explicit close replaces to the list URL while preserving the applicable filters/page;
- applying/removing/clearing Audit filters resets to page 1 and removes `event`;
- Previous/Next retains exact filters and removes or safely re-resolves selection;
- direct/reloaded selections run through `handle_params/3` and never trust forged events.

The existing parent-owned `handle_params/3` seam should be retained. `cron_live.ex:30-38`:

```elixir
def handle_params(params, _uri, socket) do
  entries = Cron.list_entries(repo())

  {:noreply,
   socket
   |> assign_entries(entries)
   |> assign_selected_entry(Enum.find(entries, &(&1.name == params["entry"])))}
end
```

Replace the page-local `entry_path/1` and `limiter_path/1` string interpolation with ordered `Selectors.cron_path/1` and `Selectors.limiter_path/1` calls.

### 3. Native semantic tables, explicit controls, one responsive tree

`DataDisplay.data_table/1` is the exact scan-surface API. `data_display.ex:43-65,76-84,110-132`:

```elixir
attr(:id, :string, required: true)
attr(:caption, :string, required: true)
attr(:rows, :list, required: true)
attr(:row_id, :any, required: true)
attr(:state, :atom, default: :ready, values: @data_states)
attr(:row_count, :integer, default: nil)
attr(:pagination_summary, :string, default: nil)
slot(:col) do
  attr(:label, :string, required: true)
  attr(:value_kind, :atom)
end
slot(:action)

<table class="obpt-data-table__table">
  <caption>
    <span>{@caption}</span>
    <span class="obpt-data-table__summary">{@row_count_text}</span>
    <span :if={@pagination_summary} class="obpt-data-table__summary">{@pagination_summary}</span>
  </caption>
  ...
  <tr :for={row <- @rows} :if={@state == :ready} id={row_dom_id(@id, row_key(row, @row_id))}>
    ...
    <td :if={@action != []} class="obpt-data-table__cell" data-obpt-mobile-label="Actions">
      <div class="obpt-data-table__cell-value">{render_slot(@action, row)}</div>
    </td>
  </tr>
</table>
```

Mapping by page:

- Cron: entry name is an explicit patch link; no Actions column and no row mutation controls. Actions appear only in selected detail.
- Limiters: one explicit `Review blockers` action with resource-specific accessible name; rows are not clickable.
- Audit: one explicit `View evidence` control; job target link remains a distinct link; no selection checkbox/action menu.
- Overview: not a table. Use stable sections, bounded direct list rows, and shared surfaces.

The existing 320px CSS already converts the same table tree into stacked rows (`tokens.css:1735-1743,1780-1796`). Page CSS should compose around that contract, not create another mobile table.

### 4. Overview keeps the read model and changes its finite presentation order

`OverviewReadModel` is already the only aggregation boundary. `overview_read_model.ex:18-31`:

```elixir
resources = repo.all(from(resource in Resource, order_by: [asc: resource.name]))
states = repo.all(State)
explains = repo.all(from(explain in Explain, order_by: [desc: explain.captured_at], limit: 12))
entries = repo.all(from(entry in Entry, order_by: [asc: entry.name]))
active_incidents = repo.all(from(incident in Incident, where: incident.status == "active"))
resolved_incidents = repo.all(from(incident in Incident, where: incident.status == "resolved"))
audit_events = Audit.list_all(repo: repo)
retention = Lifeline.retention_status(repo)
```

Keep this boundary, but capture one `now` near the start and inject it through options for deterministic tests. Replace the unbounded Audit support read with a bounded latest-matching query. Do not query from `EngineOverviewLive.render/1`.

The current array at `overview_read_model.ex:48-115` is already finite. Change its explicit order to:

```text
Needs Review
Blocked
Waiting
Bridge-only Follow-up
Runnable
Resolved continuity
```

Do not derive order from maps, count, time, viewport, or severity. Preserve `AttentionProjection.project_bucket/2` and the three-exemplar bound. The bridge's current upstream bound is explicit (`overview_read_model.ex:142-147`):

```elixir
explains
|> Enum.filter(& &1.job_id)
|> Enum.uniq_by(& &1.job_id)
|> Enum.take(3)
```

The page's current helper split is string-dependent (`active_buckets/1` rejects `"Resolved Recently"`). Replace it with explicit semantic grouping/presenter fields rather than another fragile label comparison.

For current attention only, `attention_card/1` is valid when all required facts are honest. Its contract requires summary, impact, observed time, status, severity, and completeness (`operator_patterns.ex:558-568`). Never borrow one exemplar timestamp as aggregate truth. If the aggregate cannot supply those facts, use a neutral shared surface. Runnable maps to `metric_card/1`; bridge and continuity stay neutral.

### 5. Cron preserves the durable state machine and changes the venue/presentation

The page already has both required authorization points. `cron_live.ex:46-55` authorizes before preview:

```elixir
with :ok <-
       LiveAuth.authorize_action(socket, auth_action(action), resource,
         message: unauthorized_preview_message(action)
       ),
     {:ok, preview} <- Cron.preview_entry_action(repo(), action, entry) do
  ...
end
```

`cron_live.ex:96-103` reauthorizes with the current principal immediately before execution:

```elixir
preview = socket.assigns.preview
entry_name = get_in(preview.metadata, ["resource", "id"])
resource = %{type: :cron_entry, id: entry_name}

with :ok <- LiveAuth.authorize_action(socket, auth_action(preview.action), resource),
     {:ok, principal} <- LiveAuth.principal_for_action(socket),
     {:ok, _result} <- perform_action(preview, principal, socket.assigns.reason) do
  ...
end
```

Keep those calls, `Cron.pause_cron_entry/4`, `resume_cron_entry/4`, `run_cron_entry/4`, preview expiry/drift/consumption, Ecto transaction, Audit record, and repository reload. Do not change `lib/oban_powertools/cron.ex` or its public `reason_required: false` preview contract.

Use a page-owned form, as in the harness (`showcase_live.ex:1573-1581`):

```elixir
defp group_confirmation_form(params, errors) do
  to_form(params,
    as: :group_confirmation,
    id: "group-confirmation-form",
    errors: group_form_errors(errors)
  )
end
```

Phase 79 differs from the generic harness's eight-character example: Cron requires only `String.trim(reason) != ""`, revalidated in the submit handler. The safe draft survives recoverable failure and clears on clean success or an intentional new action.

The shared dialog already closes the lifecycle over `preview submitting partial failed expired drifted consumed` and accepts exact labels, parent form, recovery, and Audit slots (`operator_patterns.ex:26-50`). Use warning intent for all three actions with D-20's exact labels. Never pass or render preview token, plan hash, action atom, internal risk, exception, or raw metadata.

When opening confirmation, keep `?entry=` selected but stop rendering the detail surface. The harness demonstrates mutually exclusive state (`operator_patterns_harness_test.exs:297-309`):

```elixir
socket
|> assign(
  selected_detail: nil,
  confirmation_open?: true,
  confirmation_state: :preview
)
```

For Cron, retain selected entry identity separately while `detail_open?` is false. Dismissal/recoverable result reopens detail; clean success closes confirmation, reloads repository truth, emits one receipt, and restores the updated detail or row fallback.

Do not preserve `find_entry!/1` for event input: `cron_live.ex:389-390` currently raises on a forged name. Resolve safely and return an unavailable state or canonical list patch.

### 6. Limiters must separate current truth, snapshot, and retained history

The existing page already exposes the three source seams, but currently renders raw maps:

- current explanation: `Explain.explain_snapshot(snapshot, repo: repo()).live_now`;
- block-start snapshot: `snapshot.details["live_now"]` and `snapshot.captured_at`;
- retained history: `LimiterHistory.summary(repo(), name)`.

Keep them distinct. The current load shape (`limiters_live.ex:266-288`) is:

```elixir
snapshot =
  repo().one(
    from(event in Explain,
      where: event.scope_id == ^name,
      order_by: [desc: event.captured_at],
      limit: 1
    )
  )

case snapshot do
  nil -> %{snapshot: nil, live_now: [], oban_job_path: nil}
  snapshot ->
    explanation = Explain.explain_snapshot(snapshot, repo: repo())
    %{snapshot: snapshot, live_now: explanation.live_now, oban_job_path: build_job_path(...)}
end
```

The migrated detail must not interpret `nil` as complete empty evidence. Build an explicit support/completeness state, and pass only current normalized blockers to `why_blocked/1`.

`ControlPlanePresenter.normalize_blockers/1` already enforces closed fields (`control_plane_presenter.ex:123-154`):

```elixir
%{
  id: normalize_presentation_id!(presentation_value(blocker, :id), "blocker id"),
  evidence_kind: normalize_closed_value!(..., @blocker_evidence_kinds, ...),
  label: required_presentation_text!(...),
  summary: required_presentation_text!(...),
  clearing_condition: required_presentation_text!(...),
  evidence_source: required_presentation_text!(...),
  technical_code: optional_presentation_text(...)
}
```

Add optional `affected_scope` backward-compatibly. The shared component may render it in the existing facts list. Do not make raw technical codes page headlines.

`why_blocked/1` already computes empty truth from evidence state, completeness, and blockers (`operator_patterns.ex:652-675`). Supply the correct state rather than duplicating copy. Complete + empty current evidence may say `Runnable`; partial, stale, unavailable, or permission-denied evidence may not say `No blockers`.

The list's current resource loop performs one State query per Resource (`limiters_live.ex:245-263`). Prefer one resources query plus one State query grouped/indexed by `resource_id`, matching `OverviewReadModel.resource_rows/3`. This is a contained read-shape improvement and must preserve status meaning.

### 7. Audit paging composes the existing exact filter query with database pagination

Keep the exact filter clauses. `audit.ex:218-243` already ignores blanks and supports only the three approved keys:

```elixir
Enum.reduce(filters, query, fn
  {_key, value}, query when value in [nil, ""] -> query
  {"resource_type", value}, query -> where(query, [event], event.resource_type == ^value)
  {"resource_id", value}, query -> where(query, [event], event.resource_id == ^value)
  {"event_type", value}, query -> where(query, [event], event.event_type == ^value)
  {:resource_type, value}, query -> where(query, [event], event.resource_type == ^value)
  {:resource_id, value}, query -> where(query, [event], event.resource_id == ^value)
  {:event_type, value}, query -> where(query, [event], event.event_type == ^value)
  _, query -> query
end)
```

Compose that query once for both exact count and row retrieval. `Jobs.list/3` is the closest database-pagination analog (`jobs.ex:89-97`):

```elixir
def list(repo, %__MODULE__{} = filter, _opts \\ []) do
  offset = (filter.page - 1) * filter.page_size

  base_query(filter)
  |> order_by([j], desc: j.scheduled_at, desc: j.id)
  |> limit(^filter.page_size)
  |> offset(^offset)
  |> repo.all()
end
```

Audit's bounded API should fix page size at 20, normalize invalid/missing page to 1, order by `inserted_at DESC, id DESC`, count the same filtered query, and return rows plus exact total/page/page-size/total-pages/previous?/next? metadata. Specify and test out-of-range behavior so all rows remain reachable.

Also add the ID tie-break to compatible existing `list/2` and `list_all` paths. Keep those public functions for compatibility, but none of the four Phase 79 render paths should load a global unbounded audit list.

The Audit page's current `filtered_events/1` is the exact replacement point (`audit_live.ex:169`):

```elixir
defp filtered_events(filters), do: Audit.list_all(filters, repo: repo())
```

Move filter/page/event parsing into one canonical URL-state function in `handle_params/3`; row selection must resolve within the active filter scope and fail closed if `event` identifies a mismatched row.

### 8. Structural redaction happens before Audit row/detail rendering

`ControlPlanePresenter.normalize_audit_entry/1` is already fail-closed and validates safe allowlisted presentation data (`control_plane_presenter.ex:165-208`):

```elixir
changes = presentation_value(entry, :changes)
evidence = presentation_value(entry, :evidence)
ensure_safe_presentation_data!(changes, "audit changes")
ensure_safe_presentation_data!(evidence, "audit evidence")
ensure_audit_presentation_data!(changes, "audit changes")
ensure_audit_presentation_data!(evidence, "audit evidence")

%{
  sentence: required_presentation_text!(...),
  outcome: optional_presentation_text(...) || "Outcome not recorded",
  actor: required_presentation_text!(...),
  action: required_presentation_text!(...),
  target: required_presentation_text!(...),
  reason: optional_presentation_text(...) || "No operator reason recorded",
  source: required_presentation_text!(...),
  correlation: required_presentation_text!(...),
  occurred_at: required_presentation_text!(...),
  occurred_datetime: normalize_datetime!(...),
  changes: changes,
  evidence: evidence
}
```

Extend this seam for Phase 79 row/detail maps and the exact absence strings:

- `No operator reason recorded`
- `Outcome not recorded`
- `Source not recorded`
- `Correlation not recorded`

Use `DisplayPolicy.actor_label/2` and `DisplayPolicy.reason/2` only on values selected from the Audit schema/allowlist. Never pass `event.metadata` wholesale to assigns or components. `command_key`, Audit row ID, and event suffixes are not correlation/outcome evidence.

The current `audit_entry/1` uses `occurred_at` without a visible label (`operator_patterns.ex:766-781`). Add a backward-compatible visible `Recorded at` association, either through a normalized label or a containing description item. Do not fork page-local Audit detail markup. Absolute UTC is primary.

The current component can render normalized technical evidence in a `<details>` section. Phase 79 must not populate that slot with raw metadata, secret originals, tokens, hashes, credentials, exception text, stacktraces, or provider blobs. Test HTML text, values, attributes, hidden nodes, and serialized story fixtures.

### 9. Selectors are the single URL builder

`Selectors.encode/2` already drops empty values and preserves ordered list iteration (`selectors.ex:53-65`):

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

Use ordered parameter lists for literal URL compatibility. Audit should establish one order and use it everywhere, for example:

```text
resource_type -> resource_id -> event_type -> page -> event
```

Omit default page 1 if that is the locked canonical choice; whichever choice the planner makes must be consistent across apply/remove/clear/previous/next/select/close/direct-link tests. Existing `Selectors.audit_path/1`, `cron_path/1`, and `limiter_path/1` already accept permissive `page`, `event`, `entry`, and `resource` keys.

### 10. Page CSS is composition-only and token-owned

The shared styles already own component chrome, detail modality, 320px action stacking, and reduced motion. For example, `tokens.css:3333-3366`:

```css
@media (max-width: 24rem) {
  .obpt-root .obpt-detail-surface {
    position: fixed;
    inset: 0;
    width: 100%;
    height: 100dvh;
    max-height: 100dvh;
    border-radius: 0;
  }

  .obpt-root .obpt-detail-surface__footer,
  .obpt-root .obpt-detail-surface__actions {
    align-items: stretch;
    flex-direction: column;
  }
}

@media (prefers-reduced-motion: reduce) {
  .obpt-root .obpt-detail-surface {
    transition-duration: var(--obpt-motion-duration-instant);
  }
}
```

New page selectors should only own page stack, fixed section order, wide two-column composition, direct exemplar row separators, action/pagination alignment, and long-value wrapping. Every declaration must be rooted beneath `.obpt-root` and use `--obpt-*` values. Do not add page-local button, status, form, table, dialog, or card styling.

After editing source CSS, run `mix oban_powertools.assets.build`; never edit static CSS independently. `assets_test.exs:195-197` is the exact packaged-byte contract:

```elixir
assert File.read!(@css_static) == normalized_source("assets/oban_powertools/tokens.css")
assert File.read!(@js_static) == normalized_source("assets/oban_powertools/theme.js")
```

### 11. Page stories extend the existing deterministic catalog pipeline

The page fixture catalog should copy the safety posture from `operator_pattern_story_catalog.ex:1-7`:

```elixir
@moduledoc """
Deterministic dev/test stories for the operator-pattern showcase.

Fixtures are normalized presentation data only. They deliberately exclude
backend structs, preview credentials, implementation errors, and original
secret values while retaining long, hostile-looking, Unicode, and RTL copy.
"""
```

Copy its stable target construction (`operator_pattern_story_catalog.ex:588-610`):

```elixir
@stories Enum.map(@story_specs, fn story ->
           id = story.id
           Map.put(story, :test_targets, %{
             story: "obpt-group-story-#{id}",
             snapshot: "showcase/#{id}",
             a11y: ~s([data-obpt-group-story="#{id}"])
           })
         end)

def stories, do: @stories
def snapshot_name(id), do: "showcase/#{story!(id).id}"
```

Use a `page-*` ID family and `kind: :page`. Fixtures must be normalized page assigns, not schemas, raw metadata, preview credentials, or a second HTML implementation.

The production page render path should be reusable by its LiveView and `ShowcaseLive`. A private/pure function component within the page module is acceptable if it does not fetch, authorize, or mutate. `ShowcaseLive` should select fixture assigns and invoke that production composition, not copy its markup.

The manifest currently appends catalogs (`showcase_manifest.exs:151-165`):

```elixir
targets =
  Enum.map(scenarios, &Map.put(&1, :kind, "scenario")) ++
    primitive_stories ++ form_stories ++ shell_stories ++ data_stories ++ group_stories

manifest = %{
  schema_version: 6,
  ...,
  group_stories: group_stories,
  targets: targets
}
```

Bump the schema intentionally, append `page_stories`, and update `manifest.ts` plus `manifest-smoke.mjs` in the same task. Existing target arrays and IDs must remain byte-order stable.

`showcase.ts:88-124` activates at most one group overlay and asserts the one-dialog bound. Extend the same generic functions for page targets, where activation may select one detail or one confirmation. A page target must never leave both adaptive detail and confirmation dialogs open.

The generic VRT loop already derives filenames from manifest targets (`showcase.vrt.spec.ts:6-33`). Once `page` is a validated target kind, reuse that loop. Do not add a separate screenshot runner.

### 12. Browser behavior uses connected LiveViews; VRT is matrix evidence

The new connected page behavior spec should copy the helper discipline from `operator-patterns.behavior.spec.ts`:

```typescript
async function expectNoHorizontalOverflow(story: Locator): Promise<void> {
  const overflow = await story.evaluate((element) => ({
    story: Math.ceil(element.scrollWidth - element.clientWidth),
    body: Math.ceil(document.body.scrollWidth - document.body.clientWidth),
    document: Math.ceil(
      document.documentElement.scrollWidth - document.documentElement.clientWidth
    )
  }));

  expect(overflow.story).toBeLessThanOrEqual(1);
  expect(overflow.body).toBeLessThanOrEqual(1);
  expect(overflow.document).toBeLessThanOrEqual(1);
}
```

Also copy its confidentiality-channel audit, which scans text, HTML, values, attributes, and live form control values rather than checking only visible text.

Connected behavior—not static screenshots—must prove:

- first-selection push, selection-switch replace, close, Back, and direct reload;
- Cron detail-to-confirm mutual exclusion, focus containment, dismissible Escape rules, recoverable restore, clean-success restore, loading disable, and one receipt;
- wide inline detail has no trap; narrow detail/dialog is modal; resizing preserves one tree and state;
- named controls, keyboard traversal, focus visibility/restoration, 320px and 200% reflow;
- no confidential values in text, attributes, hidden DOM, URLs, or fixture payloads.

The deterministic page targets supply the four-theme × three-viewport axe/VRT matrix. Lock the exact story list before generation and verify exactly `story_count × 12` page PNGs. Baseline generation is not verification; compare-only VRT must pass afterward.

### 13. Tests extend behavioral contracts instead of replacing them

The existing Cron test demonstrates the right repository-effect style (`cron_live_test.exs:99-113`):

```elixir
render_change(view, "reason", %{"reason" => "maintenance"})
html = render_click(view, "confirm", %{})

assert_receive {:telemetry_event, [:oban_powertools, :cron, :paused], %{count: 1}, _}
[event | _] = Audit.list(%{type: :cron_entry, id: "nightly"}, repo: TestRepo)
assert event.action == "cron.paused"
assert event.actor_id == "ops-1"
assert event.metadata["reason"] == "maintenance"
```

Keep this proof while replacing obsolete positive assertions that expose preview tokens or raw preview status with negative confidentiality assertions and dialog semantics.

The Audit tests already pin exact three-filter compatibility (`audit_live_test.exs:95-106`). Preserve the meaning while replacing raw query-shaped copy with human labels. Add page/event composition rather than renaming the existing keys.

`selectors_test.exs:31-47` demonstrates literal ordered URL assertions. Extend it for filter/page/event preservation and removal/reset paths.

Tests should select semantic IDs, roles, headings, accessible names, canonical URLs, database effects, and confidential-value absence. Avoid class-string snapshots except dedicated CSS static tests.

## File-Specific Guardrails

### `engine_overview_live.ex` / `overview_read_model.ex`

- Keep page authorization and all current domain inputs/count meanings.
- Rename only the unsupported presentation claim `Resolved Recently` -> `Resolved continuity`.
- Stable DOM and data order must match D-09; assert it with semantic section IDs/headings.
- Preserve deterministic three-exemplar projection and selector destinations.
- Static state has no `role="alert"` or live region.
- Bridge count says representative/shown, never global total.

### `cron_live.ex`

- Actions exist only in selected detail and remain discoverable with server-derived disabled reason when useful.
- Nonblank trimmed UI reason is page policy; backend API compatibility remains unchanged.
- Preview and confirm authorization both stay server-side.
- Partial/skipped/expired/drifted/consumed/failed remains open with recovery and safe draft.
- Run-now receipts describe slot claim/result, never job execution.
- One receipt and Audit destination on clean success; no duplicate generic flash.

### `limiters_live.ex`

- Read-only; no mutation events or pseudo-actions.
- Detail order is resource/support -> current blockers -> block-start snapshot -> retained history -> destinations.
- Complete empty current evidence alone yields `Runnable`.
- Forensics link is server-authorized; Oban Web is a secondary bridge destination.
- Batch list State reads if practical; no new N+1 in presenters/details.

### `audit.ex` / `audit_live.ex`

- Exactly 20 rows per page, stable `inserted_at DESC, id DESC`, exact matching count.
- Previous/Next makes every row reachable; no latest-N cap, stream substitute, or infinite scroll.
- Exact existing filter meaning remains unchanged.
- Detail record is immutable past-tense evidence and uses `Recorded at`.
- Read-only semantics: no mutation controls, bulk selection, action menu, urgency role, auto-refresh, or current-state color claim.
- Repair retention copy distinguishes archived repair evidence from live Audit rows.

### `control_plane_presenter.ex` / `operator_patterns.ex`

- Presentation maps are closed, pure, deterministic, and fail closed.
- Add only optional backward-compatible component fields.
- `affected_scope` does not make technical code a headline.
- Audit row/detail are built from allowlisted scalar facts after DisplayPolicy.
- Never serialize whole metadata or raw schemas into page/story assigns.

### `tokens.css` / static CSS

- Root scope and `--obpt-*` values only.
- One DOM reflows at 320px and 200% zoom.
- Reduced motion is instant; no gratuitous transitions.
- Static file is generated and byte-equal to source.

### Showcase/browser files

- Append page target kind; preserve existing IDs/order.
- Render production page composition from normalized fixtures.
- Only one selected detail or confirmation overlay may be active.
- Lock exact story IDs/count and `count × 12` baseline equation before generation.
- Report unrelated pre-existing baseline residuals separately.

## Anti-Patterns to Avoid

- Replacing a parent LiveView state machine with LiveComponents.
- Instantiating `AppShell` within a page already wrapped by `ThemeShell`.
- Passing Ecto schemas or `event.metadata` to components.
- Loading `Audit.list_all/2` for any Phase 79 global page/support surface.
- Whole-row click handlers, ARIA grids, duplicated mobile markup, hidden secret-bearing DOM.
- Row-level Cron actions, an Actions kebab, nested detail/confirmation dialogs.
- Treating disabled client controls as authorization or concurrency control.
- Calling run-now accepted work “ran.”
- Calling snapshot/history current evidence or chronology causal proof.
- Calling incomplete/unknown Limiter evidence `Runnable` or `No blockers`.
- Treating `command_key`, row ID, or event suffix as correlation/outcome.
- Raw filter query syntax in operator copy.
- Page-local component/CSS substitutes for shipped primitives and groups.
- Showcase-only duplicate HTML that can pass VRT while production pages regress.
- Editing checked-in static CSS independently or changing dependencies/migrations speculatively.

## Recommended Dependency Order for Planning

1. Add RED pure/query tests for Audit paging/tie-break/reachability, presenter allowlists/copy, selector composition, Overview stable order/time/bounds, and Limiter current-evidence truth.
2. Implement bounded Audit query, canonical URL helpers, and pure presentation maps; apply narrow backward-compatible shared-component refinements only if tests prove the gap.
3. Migrate Overview, Cron, Limiters, and Audit compositions while preserving their existing auth/query/mutation tests.
4. Add token-owned page layout CSS, rebuild static CSS, and prove source/static equality.
5. Lock page story IDs/count; add deterministic normalized fixtures through the production render path and extend the manifest/browser target pipeline.
6. Run connected page behavior and generic structure/axe gates; generate and review exact page baselines only after those pass, then run compare-only VRT.
7. Record targeted and integrated results plus manual screen-reader/focus/reflow observations in `79-VALIDATION.md`.

This order follows the repository's actual seams: query and normalized truth first, page composition second, deterministic matrix evidence last.
