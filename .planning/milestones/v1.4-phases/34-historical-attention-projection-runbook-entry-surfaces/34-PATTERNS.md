# Phase 34: Historical Attention Projection & Runbook Entry Surfaces - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 16 new/modified files
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/forensics/attention_projection.ex` | service/read-model | transform + CRUD reads | `lib/oban_powertools/forensics/cron_history.ex` | exact |
| `lib/oban_powertools/forensics/runbook_entry.ex` | service/read-model | transform | `lib/oban_powertools/forensics/evidence_bundle.ex` | exact |
| `lib/oban_powertools/web/overview_read_model.ex` | presenter/read-model | request-response + CRUD reads | `lib/oban_powertools/web/overview_read_model.ex` | exact |
| `lib/oban_powertools/forensics.ex` | service/facade | request-response + CRUD reads | `lib/oban_powertools/forensics.ex` | exact |
| `lib/oban_powertools/web/control_plane_presenter.ex` | presenter/utility | transform | `lib/oban_powertools/web/control_plane_presenter.ex` | exact |
| `lib/oban_powertools/web/engine_overview_live.ex` | component/LiveView | request-response | `lib/oban_powertools/web/engine_overview_live.ex` | exact |
| `lib/oban_powertools/web/forensics_live.ex` | component/LiveView | request-response | `lib/oban_powertools/web/forensics_live.ex` | exact |
| `lib/oban_powertools/web/cron_live.ex` | component/LiveView | request-response + event-driven | `lib/oban_powertools/web/cron_live.ex` | exact |
| `lib/oban_powertools/web/limiters_live.ex` | component/LiveView | request-response + CRUD reads | `lib/oban_powertools/web/limiters_live.ex` | exact |
| `lib/oban_powertools/web/workflows_live.ex` | component/LiveView | request-response | `lib/oban_powertools/web/workflows_live.ex` | exact |
| `lib/oban_powertools/web/lifeline_live.ex` | component/LiveView | request-response + event-driven | `lib/oban_powertools/web/lifeline_live.ex` | role-match |
| `test/oban_powertools/forensics_test.exs` | test | request-response + transform | `test/oban_powertools/forensics_test.exs` | exact |
| `test/oban_powertools/web/live/engine_overview_live_test.exs` | test | request-response | `test/oban_powertools/web/live/engine_overview_live_test.exs` | exact |
| `test/oban_powertools/web/live/forensics_live_test.exs` | test | request-response | `test/oban_powertools/web/live/forensics_live_test.exs` | exact |
| `test/oban_powertools/web/live/control_plane_copy_coherence_test.exs` | test | request-response + event-driven | `test/oban_powertools/web/live/control_plane_copy_coherence_test.exs` | exact |
| `test/oban_powertools/web/live/cron_live_test.exs` / `limiters_live_test.exs` | test | request-response | existing history-summary tests | exact |

## Pattern Assignments

### `lib/oban_powertools/forensics/attention_projection.ex` (service/read-model, transform + CRUD reads)

**Analog:** `lib/oban_powertools/forensics/cron_history.ex`

**Imports and module pattern** (lines 1-9):
```elixir
defmodule ObanPowertools.Forensics.CronHistory do
  @moduledoc false

  import Ecto.Query

  alias ObanPowertools.{Audit, ControlPlane}
  alias ObanPowertools.Cron.{Entry, Slot}
  alias ObanPowertools.Forensics.{CronCoverage, EvidenceBundle}
```

**Bounded query pattern** (lines 92-125):
```elixir
def slot_views(repo, %Entry{} = entry) do
  slots =
    repo.all(
      from(slot in Slot,
        where: slot.entry_id == ^entry.id,
        order_by: [desc: slot.slot_at],
        limit: @history_limit
      )
    )

  coverages =
    repo.all(
      from(coverage in CronCoverage,
        where: coverage.entry_id == ^entry.id,
        order_by: [desc: coverage.slot_at],
        limit: @history_limit
      )
    )
```

**Classification/ranking input pattern** (lines 127-206):
```elixir
defp classify_slot(entry, slot_at, slot, coverage) do
  cond do
    manual_slot?(slot) ->
      base_view(entry, slot_at, :manual_run, :complete, "...", slot, coverage)

    (is_nil(slot) and coverage) && coverage.status == "healthy" ->
      base_view(entry, slot_at, :missed_fire, :complete, "...", slot, coverage)

    is_nil(slot) and coverage ->
      base_view(entry, slot_at, :partial_evidence, :partial_evidence, "...", slot, coverage)
```

**Completeness guardrail pattern** (lines 290-320):
```elixir
defp completeness([]) do
  %{state: :history_unavailable, details: "history unavailable: no retained cron slot or scheduler coverage history is available yet."}
end

defp completeness(views) do
  cond do
    Enum.any?(views, &(&1.completeness == :unknown)) ->
      %{state: :partial_evidence, details: "partial evidence: some recent cron windows are unknown because scheduler coverage was not retained."}
```

Copy this shape for attention projection: query only durable current/history facts, classify candidates into explanation-backed reasons, sort deterministically, and return a bounded list. Do not create a feed.

---

### `lib/oban_powertools/forensics/runbook_entry.ex` (service/read-model, transform)

**Analog:** `lib/oban_powertools/forensics/evidence_bundle.ex`

**Normalization pattern** (lines 4-28):
```elixir
def build(attrs) when is_map(attrs) do
  chronology =
    attrs
    |> Map.get(:chronology, Map.get(attrs, "chronology", []))
    |> Enum.map(&Chronology.item/1)
    |> Chronology.sort()

  %{
    subject: Map.get(attrs, :subject) || Map.get(attrs, "subject") || %{},
    diagnosis_summary:
      Map.get(attrs, :diagnosis_summary) || Map.get(attrs, "diagnosis_summary") || %{},
    chronology: chronology,
    related_evidence:
      attrs
      |> Map.get(:related_evidence, Map.get(attrs, "related_evidence", []))
      |> Enum.map(&normalize_related_evidence/1),
    linked_resources:
      Map.get(attrs, :linked_resources) || Map.get(attrs, "linked_resources") || [],
    legal_next_paths:
      Map.get(attrs, :legal_next_paths) || Map.get(attrs, "legal_next_paths") || [],
    completeness:
      attrs
      |> Map.get(:completeness, Map.get(attrs, "completeness", %{}))
      |> normalize_completeness()
  }
end
```

**Completeness normalization pattern** (lines 40-52):
```elixir
defp normalize_completeness(%{state: state} = item) do
  %{item | state: Provenance.normalize_completeness(state)}
end

defp normalize_completeness(_item), do: %{state: :unknown, details: "No evidence completeness details available."}
```

`RunbookEntry.build/1` should mirror this internal map normalizer: accept atom or string keys, normalize completeness/ownership fields, and emit advisory fields only. Minimum fields from context: diagnosis state, why now, prerequisites, cautions, order, ownership/venue per next path, evidence link, unsupported boundaries.

---

### `lib/oban_powertools/web/overview_read_model.ex` (presenter/read-model, request-response + CRUD reads)

**Analog:** `lib/oban_powertools/web/overview_read_model.ex`

**Composition seam** (lines 13-31):
```elixir
def build(opts) do
  repo = Keyword.fetch!(opts, :repo)
  dashboard_path = Keyword.fetch!(opts, :dashboard_path)

  resources = repo.all(from(resource in Resource, order_by: [asc: resource.name]))
  states = repo.all(State)
  explains =
    repo.all(from(explain in Explain, order_by: [desc: explain.captured_at], limit: 12))
  entries = repo.all(from(entry in Entry, order_by: [asc: entry.name]))
  active_incidents = repo.all(from(incident in Incident, where: incident.status == "active"))
  audit_events = Audit.list_all(repo: repo)
  retention = Lifeline.retention_status(repo)
```

**Bucket map pattern** (lines 47-90):
```elixir
%{
  status: "Waiting",
  count: length(waiting_resources) + length(paused_entries),
  diagnosis: waiting_diagnosis(waiting_resources, paused_entries),
  ownership: ControlPlanePresenter.ownership_badge(:powertools_native),
  venue: ControlPlanePresenter.venue_label(:powertools_native),
  posture: ControlPlanePresenter.ownership_posture(:powertools_native),
  next_step_label: waiting_next_step_label(waiting_resources, paused_entries),
  next_step_path: waiting_next_step_path(waiting_resources, paused_entries),
  exemplars: waiting_exemplars(waiting_resources, paused_entries)
}
```

**Bounded exemplar pattern** (lines 216-235):
```elixir
defp limiter_exemplars(resources) do
  resources
  |> Enum.take(3)
  |> Enum.map(fn resource ->
    %{label: resource.name, fact: limiter_fact(resource), path: "/ops/jobs/limiters?resource=#{URI.encode_www_form(resource.name)}"}
  end)
end

defp waiting_exemplars(resources, entries) do
  (limiter_exemplars(resources) ++ cron_exemplars(entries))
  |> Enum.take(3)
end
```

Extend this file by calling `AttentionProjection` and `RunbookEntry` helpers. Keep the bucket keys stable and add fields such as `attention_reason`, `evidence_completeness`, `evidence_path`, and compact `runbook_entry` only when there is honest guidance.

---

### `lib/oban_powertools/forensics.ex` (service/facade, request-response + CRUD reads)

**Analog:** `lib/oban_powertools/forensics.ex`

**Selector dispatch pattern** (lines 13-32):
```elixir
def bundle(params, opts \\ []) when is_map(params) do
  repo = Keyword.get(opts, :repo, Application.fetch_env!(:oban_powertools, :repo))
  selectors = selectors(params)

  cond do
    selectors.workflow_id ->
      workflow_bundle(repo, selectors)
    selectors.incident_fingerprint ->
      lifeline_bundle(repo, selectors)
    selectors.resource_type == "cron_entry" and selectors.resource_id ->
      CronHistory.bundle(repo, selectors.resource_id, selectors) || unknown_bundle(selectors)
    selectors.resource_type == "limiter" and selectors.resource_id ->
      LimiterHistory.bundle(repo, selectors.resource_id, selectors) || unknown_bundle(selectors)
    true ->
      unknown_bundle(selectors)
  end
end
```

**Stable selector allowlist shape** (lines 35-44):
```elixir
def selectors(params) do
  %{
    resource_type: blank_to_nil(params[:resource_type] || params["resource_type"]),
    resource_id: blank_to_nil(params[:resource_id] || params["resource_id"]),
    workflow_id: blank_to_nil(params[:workflow_id] || params["workflow_id"]),
    step: blank_to_nil(params[:step] || params["step"]),
    incident_fingerprint: blank_to_nil(params[:incident_fingerprint] || params["incident_fingerprint"]),
    view: blank_to_nil(params[:view] || params["view"])
  }
end
```

**Bundle build pattern** (lines 95-142):
```elixir
EvidenceBundle.build(%{
  subject: %{type: "workflow", id: workflow.id, label: workflow.name, entry_surface: "Powertools-native workflows"},
  diagnosis_summary: %{title: "Workflow diagnosis", current: workflow_story.diagnosis, detail: "...", provenance: :durable},
  chronology: chronology,
  related_evidence: [...],
  linked_resources: [...],
  legal_next_paths: workflow_next_paths(workflow, selected_step, workflow_story, step_story),
  completeness: workflow_completeness(chronology, audit_events)
})
```

Add canonical deep runbook entry assembly here or in a helper consumed here. Do not add URL params for rendered reason/prose.

---

### `lib/oban_powertools/web/control_plane_presenter.ex` (presenter/utility, transform)

**Analog:** `lib/oban_powertools/web/control_plane_presenter.ex`

**Shared labels pattern** (lines 8-27):
```elixir
@status_labels %{
  needs_review: "Needs Review",
  blocked: "Blocked",
  waiting: "Waiting",
  runnable: "Runnable",
  resolved: "Resolved",
  bridge_only: "Bridge-only Follow-up"
}

def ownership_badge(ownership), do: ControlPlane.ownership_badge(ownership)
def ownership_posture(:powertools_native), do: "Audited action"
def ownership_posture(:oban_web_bridge), do: "Inspection only"
def ownership_posture(:host_owned), do: "Host-owned"
```

**Completeness labels** (lines 46-54):
```elixir
def forensic_completeness_label(:complete), do: "complete"
def forensic_completeness_label(:partial_evidence), do: "partial evidence"
def forensic_completeness_label(:history_unavailable), do: "history unavailable"
def forensic_completeness_label(:unknown), do: "unknown"

def venue_label(venue), do: ControlPlane.venue_label(venue)
```

**Refusal-adjacent operator shape** (lines 79-89):
```elixir
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

Put runbook wording helpers here when they are pure labels/copy. Keep the shape `outcome -> reason -> legal next move -> venue -> evidence`.

---

### LiveView Surface Files (components, request-response)

**Analogs:** `engine_overview_live.ex`, `forensics_live.ex`, `cron_live.ex`, `limiters_live.ex`, `workflows_live.ex`, `lifeline_live.ex`

**Auth and thin-render pattern** from `engine_overview_live.ex` (lines 9-20, 105-110):
```elixir
def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
  with {:ok, socket} <- LiveAuth.authorize_page(socket, :view_overview, %{type: :page, id: "overview"}) do
    {:ok, assign_metrics(socket, dashboard_path)}
  else
    {:error, socket} -> {:ok, socket}
  end
end

defp assign_metrics(socket, dashboard_path) do
  assign(socket, :overview_buckets, OverviewReadModel.build(repo: repo(), dashboard_path: dashboard_path))
end
```

**Overview exemplar render pattern** from `engine_overview_live.ex` (lines 56-69):
```elixir
<div class="mt-4 space-y-3">
  <div :for={exemplar <- bucket.exemplars} class="rounded border bg-slate-50 p-3 text-sm">
    <div class="font-medium"><%= exemplar.label %></div>
    <div class="mt-1 text-zinc-600"><%= exemplar.fact %></div>
    <.link navigate={exemplar.path} class="mt-2 inline-block text-indigo-700 underline">
      Review exemplar
    </.link>
  </div>
</div>
```

**Forensics stable selector pattern** from `forensics_live.ex` (lines 10, 26-35):
```elixir
@allowed_params ~w(resource_type resource_id workflow_id step incident_fingerprint view)

def handle_params(params, _uri, socket) do
  selectors =
    params
    |> Map.take(@allowed_params)
    |> Forensics.selectors()

  {:noreply, socket |> assign(:selectors, selectors) |> assign(:bundle, Forensics.bundle(selectors, repo: repo()))}
end
```

**Legal path and completeness render pattern** from `forensics_live.ex` (lines 120-135):
```elixir
<h2 class="text-base font-semibold">Legal Next Paths</h2>
<div :for={item <- @bundle.legal_next_paths}>
  <a href={item.path} class="text-indigo-700 underline"><%= item.label %></a>
  <span class="text-zinc-500"> — <%= item.venue %></span>
</div>

<%= ControlPlanePresenter.forensic_completeness_label(@bundle.completeness.state) %>
```

**Drilldown history summary pattern** from `cron_live.ex` (lines 209-230):
```elixir
<div :if={@history_summary} class="mt-4 rounded border bg-slate-50 p-4">
  <div class="flex items-center justify-between gap-3">
    <h3 class="text-sm font-semibold">History Summary</h3>
    <a :if={can_view_forensics?(@current_actor)} href={forensics_path(@selected_entry.name)} class="text-sm text-indigo-700 underline">
      Open forensic timeline
    </a>
  </div>
  <p class="mt-2 text-sm text-zinc-700"><%= @history_summary.detail %></p>
  <p class="mt-1 text-xs text-zinc-500">
    <%= ControlPlanePresenter.forensic_completeness_label(@history_summary.completeness.state) %>
  </p>
</div>
```

**Limiter analog for selected-resource summaries** from `limiters_live.ex` (lines 138-160):
```elixir
<div :if={@history_summary}>
  <div class="flex items-center justify-between gap-3 text-sm font-medium">
    <span class="rounded border px-2 py-1">History Summary</span>
    <a :if={can_view_forensics?(@current_actor)} href={forensics_path(@selected_resource)} class="text-sm text-indigo-700 underline">
      Open forensic timeline
    </a>
  </div>
  <p class="mt-2 text-sm text-zinc-600"><%= @history_summary.detail %></p>
  <p class="mt-1 text-xs text-zinc-500">
    <%= ControlPlanePresenter.forensic_completeness_label(@history_summary.completeness.state) %>
  </p>
</div>
```

**Workflow decision-point pattern** from `workflows_live.ex` (lines 145-151, 200-206):
```elixir
<% workflow_refusal = ControlPlanePresenter.workflow_refusal(@workflow_story.rejection_summary) %>
<div :if={workflow_refusal} class="mt-2 rounded border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
  <p><strong>Outcome:</strong> <%= workflow_refusal.outcome %></p>
  <p class="mt-1"><strong>Reason:</strong> <%= workflow_refusal.reason %></p>
  <p class="mt-1"><strong>Legal next move:</strong> <%= workflow_refusal.next_move %></p>
  <p class="mt-1"><strong>Venue:</strong> <%= workflow_refusal.venue %></p>
</div>
```

For Phase 34, LiveViews should render runbook entries from assigns built by shared helpers. Do not compute scoring, prerequisites, or ownership branching in HEEx.

---

### Test Files (tests, request-response + transform)

**Analogs:** `forensics_test.exs`, `engine_overview_live_test.exs`, `forensics_live_test.exs`, `control_plane_copy_coherence_test.exs`

**Bundle contract test pattern** from `forensics_test.exs` (lines 14-57):
```elixir
test "bundle contract preserves diagnosis-first shape, chronology ordering, and supporting evidence labels" do
  bundle =
    EvidenceBundle.build(%{
      subject: %{type: "workflow", id: "wf-1"},
      diagnosis_summary: %{current: "waiting_on_dependencies"},
      chronology: [...],
      related_evidence: [%{title: "Limiter fact", summary: "supporting", provenance: :supporting}],
      linked_resources: [],
      legal_next_paths: [],
      completeness: %{state: :partial_evidence, details: "partial evidence"}
    })

  assert Map.has_key?(bundle, :diagnosis_summary)
  assert Map.has_key?(bundle, :legal_next_paths)
  assert bundle.completeness.state == :partial_evidence
end
```

**History input tests** from `forensics_test.exs` (lines 165-186, 188-228):
```elixir
test "cron forensic bundle explains missed fire from retained coverage without inventing certainty" do
  {:ok, entry} = Cron.sync_entry(TestRepo, %{name: "nightly-history", ...})
  assert {:ok, _coverage} = Cron.record_coverage(TestRepo, entry, slot_at, status: "healthy")
  bundle = Forensics.bundle(%{"resource_type" => "cron_entry", "resource_id" => entry.name}, repo: TestRepo)
  assert bundle.completeness.state == :complete
  assert Enum.any?(bundle.chronology, &(&1.event_type == "cron.missed_fire"))
end
```

**Overview LiveView proof pattern** from `engine_overview_live_test.exs` (lines 8-33):
```elixir
test "renders diagnosis-first cards with native and bridge ownership labels", %{conn: conn} do
  seed_overview_fixture!()
  conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-1", permissions: [:view_overview]})
  {:ok, view, html} = live(conn, "/ops/jobs")

  assert html =~ "Diagnosis-first overview"
  assert html =~ "Bridge-only Follow-up"
  assert html =~ "Oban Web bridge"
  assert has_element?(view, "a[href*='/ops/jobs/cron?entry=nightly-sync']")
end
```

**Forensics stable URL proof pattern** from `forensics_live_test.exs` (lines 23-48):
```elixir
{:ok, _view, html} =
  live(conn, "/ops/jobs/forensics?workflow_id=#{workflow.id}&step=sync_billing&resource_type=workflow_step")

assert html =~ "Diagnosis Summary"
assert html =~ "partial evidence"
assert html =~ "workflow_id=#{workflow.id}"
refute html =~ "preview_token="
refute html =~ "reason="
refute html =~ "diagnosis="
refute html =~ "refusal="
```

**Copy coherence proof pattern** from `control_plane_copy_coherence_test.exs` (lines 153-170):
```elixir
{:ok, _forensics_view, forensics_html} =
  live(conn, "/ops/jobs/forensics?workflow_id=#{workflow.id}&step=fetch_customer")

assert_occurs_in_order(forensics_html, [
  "Diagnosis Summary",
  "Timeline",
  "Related Evidence",
  "Linked Resources",
  "Legal Next Paths",
  "Evidence Completeness"
])

assert forensics_html =~ "supporting evidence"
assert forensics_html =~ "Inspection only"
refute forensics_html =~ "preview_token="
refute forensics_html =~ "reason="
```

**Selected drilldown history tests** from `cron_live_test.exs` lines 361-385 and `limiters_live_test.exs` lines 150-160:
```elixir
{:ok, _view, html} = live(conn, "/ops/jobs/cron?entry=#{entry.name}")
assert html =~ "History Summary"
assert html =~ "Open forensic timeline"
assert html =~ "/ops/jobs/forensics?resource_type=cron_entry&amp;resource_id=forensic-entry"
```

Add Phase 34 tests for bounded attention count, partial/history-unavailable labels, advisory-only runbook copy, and native/bridge/host-owned venue labels at the decision point.

## Shared Patterns

### Authentication and Read-Only Boundaries
**Source:** `lib/oban_powertools/web/live_auth.ex` lines 54-70, 100-103  
**Apply to:** All LiveView entry surfaces
```elixir
def authorize_page(socket, action, resource) do
  case Auth.authorization_outcome(Map.get(socket.assigns, :current_actor), action, resource) do
    :ok -> {:ok, socket}
    {:error, _reason} -> {:error, redirect(socket, to: "/")}
  end
end

def audit_consequence_copy, do: @audit_consequence <> " " <> ControlPlanePresenter.native_banner()
def page_read_only_banner(surface), do: Map.fetch!(@page_read_only_banners, surface)
```

### Ownership Triad
**Source:** `lib/oban_powertools/control_plane.ex` lines 6-23 and `control_plane_presenter.ex` lines 22-27  
**Apply to:** Runbook entries, next paths, compact cards, tests
```elixir
@ownerships [:powertools_native, :oban_web_bridge, :host_owned]
@venues %{powertools_native: "Powertools-native", oban_web_bridge: "Oban Web bridge", host_owned: "Host-owned"}

def ownership_badge(ownership), do: ControlPlane.ownership_badge(ownership)
def ownership_posture(:host_owned), do: "Host-owned"
```

### Evidence Completeness
**Source:** `lib/oban_powertools/web/control_plane_presenter.ex` lines 46-52  
**Apply to:** Attention cards, runbook entries, forensic detail
```elixir
def forensic_completeness_label(:complete), do: "complete"
def forensic_completeness_label(:partial_evidence), do: "partial evidence"
def forensic_completeness_label(:history_unavailable), do: "history unavailable"
def forensic_completeness_label(:unknown), do: "unknown"
```

### Stable Forensic Handoff
**Source:** `lib/oban_powertools/web/forensics_live.ex` lines 10, 26-35; `cron_live.ex` lines 484-486; `limiters_live.ex` lines 250-251  
**Apply to:** Runbook evidence links and attention exemplars
```elixir
@allowed_params ~w(resource_type resource_id workflow_id step incident_fingerprint view)

defp forensics_path(entry_name),
  do: "/ops/jobs/forensics?resource_type=cron_entry&resource_id=#{URI.encode_www_form(entry_name)}"

defp forensics_path(name),
  do: "/ops/jobs/forensics?resource_type=limiter&resource_id=#{URI.encode_www_form(name)}"
```

### Advisory-Only Runbook Boundary
**Source:** `lib/oban_powertools/forensics.ex` lines 127-140 and `forensics_live.ex` lines 120-127  
**Apply to:** `RunbookEntry` and all renderers
```elixir
linked_resources: [
  %{label: "Workflow detail", path: workflow_path(workflow, selected_step), venue: "Powertools-native"},
  %{label: "Audit follow-up", path: audit_path(selected_step || workflow), venue: "Inspection only"}
],
legal_next_paths: workflow_next_paths(workflow, selected_step, workflow_story, step_story)
```

## No Analog Found

All planned Phase 34 files have usable analogs. There is no existing host-owned external escalation registry; planner should keep host-owned runbook paths as semantic/advisory entries only when derived from supported diagnosis boundaries, not as a new configuration API.

## Metadata

**Analog search scope:** `lib/oban_powertools`, `lib/oban_powertools/web`, `lib/oban_powertools/forensics`, `test/oban_powertools`, `test/oban_powertools/web/live`  
**Files scanned:** 62  
**Pattern extraction date:** 2026-05-27
