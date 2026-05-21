# Phase 7: Lifeline Incident Closure Integrity - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 6 likely files + 1 conditional migration file
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/lifeline.ex` | service | CRUD | `lib/oban_powertools/lifeline.ex` | exact |
| `lib/oban_powertools/lifeline/incident.ex` | model | CRUD | `lib/oban_powertools/lifeline/incident.ex` | exact |
| `lib/oban_powertools/web/lifeline_live.ex` | component | request-response | `lib/oban_powertools/web/lifeline_live.ex` | exact |
| `test/oban_powertools/lifeline_test.exs` | test | CRUD | `test/oban_powertools/lifeline_test.exs` | exact |
| `test/oban_powertools/web/live/lifeline_live_test.exs` | test | request-response | `test/oban_powertools/web/live/lifeline_live_test.exs` | exact |
| `test/support/migrations/3_phase_4_tables.exs` | migration | CRUD | `test/support/migrations/3_phase_4_tables.exs` | exact |
| `lib/mix/tasks/oban_powertools.install.ex` | config | CRUD | `lib/mix/tasks/oban_powertools.install.ex` | role-match |

## Pattern Assignments

### `lib/oban_powertools/lifeline.ex` (service, CRUD)

**Analog:** `lib/oban_powertools/lifeline.ex`

**Imports + service boundary** ([lib/oban_powertools/lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:6)):
```elixir
import Ecto.Query

alias Ecto.Multi
alias ObanPowertools.{Audit, Auth}
alias ObanPowertools.Lifeline.{ArchiveRun, Heartbeat, Incident}
alias ObanPowertools.Telemetry
alias ObanPowertools.Workflow.Step
```

**Projection entrypoint to extend** ([lib/oban_powertools/lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:97)):
```elixir
def project_incidents(repo, opts \\ []) do
  now = Keyword.get(opts, :now, DateTime.utc_now())
  health_rows = list_executor_health(repo, now: now)

  dead_executor_incidents =
    Enum.flat_map(health_rows, fn row ->
      if row.health_state == "missing" do
        [upsert_dead_executor_incident(repo, row.heartbeat, now)]
      else
        []
      end
    end)

  workflow_stuck_incidents =
    repo.all(from(step in Step, order_by: [asc: step.inserted_at]))
    |> Enum.filter(&workflow_stuck?/1)
    |> Enum.map(&upsert_workflow_stuck_incident(repo, &1, now))
```

**Current dead-executor evidence query to narrow** ([lib/oban_powertools/lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:353)):
```elixir
jobs =
  repo.all(
    from(job in Oban.Job,
      where:
        job.state in ["executing", "available", "retryable"] and
          fragment("?->>'executor_id' = ?", job.meta, ^heartbeat.executor_id)
    )
  )

workflow_steps =
  repo.all(
    from(step in Step,
      where:
        step.state in ["available", "pending", "executing", "retryable"] and
          fragment("?->>'executor_id' = ?", step.context, ^heartbeat.executor_id)
    )
  )
```

**Stable-identity upsert pattern to preserve** ([lib/oban_powertools/lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:428)):
```elixir
case repo.get_by(Incident, incident_fingerprint: attrs.incident_fingerprint) do
  nil ->
    {:ok, incident} =
      %Incident{}
      |> Incident.changeset(attrs)
      |> repo.insert()

    incident

  incident ->
    {:ok, updated} =
      incident
      |> Incident.changeset(Map.put(attrs, :first_detected_at, incident.first_detected_at))
      |> repo.update()
```

**Execute path auth + validation guard order** ([lib/oban_powertools/lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:176)):
```elixir
with %ObanPowertools.Lifeline.RepairPreview{} = preview <-
       repo.get_by(ObanPowertools.Lifeline.RepairPreview, preview_token: preview_token),
     :ok <- authorize(actor, :execute_repair, %{preview_token: preview.preview_token}),
     :ok <- validate_reason(reason),
     :ok <- ensure_preview_available(preview),
     {:ok, current_hash} <- recompute_plan_hash(repo, preview),
     :ok <- ensure_not_drifted(repo, preview, current_hash, now),
     {:ok, result} <- apply_repair(repo, preview, actor, reason, now) do
```

**`Ecto.Multi` transaction shape to preserve and extend with incident resolution** ([lib/oban_powertools/lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:697)):
```elixir
Multi.new()
|> Multi.run(:target, fn repo, _changes -> mutate_target(repo, preview, now) end)
|> Multi.update(
  :preview,
  ObanPowertools.Lifeline.RepairPreview.changeset(preview, %{
    status: "executed",
    executed_at: now,
    consumed_at: now,
    metadata: Map.put(preview.metadata || %{}, "reason", String.trim(reason))
  })
)
|> Multi.run(:audit, fn repo, %{preview: preview_record} ->
  metadata = %{
    "preview_token" => preview_record.preview_token,
    "incident_class" => preview_record.incident_class,
    "incident_fingerprint" => preview_record.incident_fingerprint,
    "plan_hash" => preview_record.plan_hash,
    "reason" => String.trim(reason),
    "affected_counts" => preview_record.affected_counts,
    "result" => "ok"
  }

  Audit.record(
    "lifeline.repair_executed",
    %{type: String.to_atom(preview.target_type), id: preview.target_id},
    metadata,
    repo: repo,
    actor_id: Auth.actor_id(actor)
  )
end)
|> repo.transaction()
```

**Transaction result/error pattern** ([lib/oban_powertools/lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:729)):
```elixir
|> case do
  {:ok, %{target: target, preview: preview_record}} ->
    Telemetry.execute_lifeline_event(:repair_executed, %{count: 1}, %{
      action: preview.action,
      incident_class: preview.incident_class,
      target_type: preview.target_type
    })

    {:ok, %{target: target, preview: preview_record}}

  {:error, _step, reason, _changes} ->
    {:error, reason}
end
```

**Target mutation helpers to keep adjacent to lifecycle changes** ([lib/oban_powertools/lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:744)):
```elixir
defp mutate_target(repo, preview, now) do
  case {preview.target_type, preview.action} do
    {"job", action} when action in ["job_rescue", "job_retry"] ->
      job = repo.get!(Oban.Job, preview.target_id)
      {:ok, repo.update!(Ecto.Changeset.change(job, state: "available", scheduled_at: now))}

    {"workflow_step", "workflow_step_retry"} ->
      step = repo.get!(Step, preview.target_id)

      {:ok,
       repo.update!(
         Step.changeset(step, %{
           state: "available",
           blocker_codes: [],
           blocker_details: %{},
           dependency_snapshot: step.dependency_snapshot
         })
       )}
```

**Planner note:** Phase 7 should copy this file’s existing `with` guard order and `Multi` step naming. The new incident-resolution step belongs in this transaction, between target mutation and preview/audit finalization.

---

### `lib/oban_powertools/lifeline/incident.ex` (model, CRUD)

**Analog:** `lib/oban_powertools/lifeline/incident.ex`

**Schema lifecycle fields already in place** ([lib/oban_powertools/lifeline/incident.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline/incident.ex:11)):
```elixir
schema "oban_powertools_lifeline_incidents" do
  field(:incident_class, :string)
  field(:status, :string, default: "active")
  field(:executor_id, :string)
  field(:workflow_id, Ecto.UUID)
  field(:workflow_step_id, Ecto.UUID)
  field(:incident_fingerprint, :string)
  field(:health_state, :string)
  field(:summary, :string)
  field(:affected_counts, :map, default: %{})
  field(:evidence, :map, default: %{})
  field(:first_detected_at, :utc_datetime_usec)
  field(:last_detected_at, :utc_datetime_usec)
  field(:resolved_at, :utc_datetime_usec)
  field(:metadata, :map, default: %{})
```

**Changeset shape to preserve if lifecycle attrs expand** ([lib/oban_powertools/lifeline/incident.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline/incident.ex:30)):
```elixir
struct
|> cast(params, [
  :incident_class,
  :status,
  :executor_id,
  :workflow_id,
  :workflow_step_id,
  :incident_fingerprint,
  :health_state,
  :summary,
  :affected_counts,
  :evidence,
  :first_detected_at,
  :last_detected_at,
  :resolved_at,
  :metadata
])
|> validate_required([
  :incident_class,
  :status,
  :incident_fingerprint,
  :affected_counts,
  :evidence,
  :first_detected_at,
  :last_detected_at,
  :metadata
])
|> unique_constraint(:incident_fingerprint)
```

**Planner note:** Prefer extending this explicit row-level lifecycle model instead of introducing separate suppression/archive state for the hot path.

---

### `lib/oban_powertools/web/lifeline_live.ex` (component, request-response)

**Analog:** `lib/oban_powertools/web/lifeline_live.ex`

**Mount auth + initial load pattern** ([lib/oban_powertools/web/lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:15)):
```elixir
def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
  with {:ok, socket} <-
         LiveAuth.authorize_page(socket, :view_lifeline, %{type: :page, id: "lifeline"}) do
    {:ok,
     socket
     |> assign(:oban_dashboard_path, dashboard_path)
     |> assign(:reason, "")
     |> assign(:error_message, nil)
     |> assign(:success_message, nil)
     |> assign(:preview, nil)
     |> assign(:preview_state, :idle)
     |> load_data(nil)}
```

**Preview action auth + selected-row refresh pattern** ([lib/oban_powertools/web/lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:40)):
```elixir
row = find_row!(socket.assigns.incident_rows, row_id)

with :ok <- ensure_previewable(row),
     :ok <- LiveAuth.authorize_action(socket, :preview_repair, row.resource),
     {:ok, preview} <-
       Lifeline.preview_repair(
         repo(),
         socket.assigns.current_actor,
         %{
           incident_id: row.incident.id,
           action: row.action,
           target_type: row.target_type,
           target_id: row.target_id
         }
       ) do
```

**Current execute success path that loses active-row continuity** ([lib/oban_powertools/web/lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:92)):
```elixir
with :ok <- LiveAuth.authorize_action(socket, :execute_repair, row.resource),
     {:ok, _result} <-
       Lifeline.execute_repair(
         repo(),
         socket.assigns.current_actor,
         preview.preview_token,
         socket.assigns.reason
       ) do
  {:noreply,
   socket
   |> assign(:reason, "")
   |> assign(:error_message, nil)
   |> assign(:success_message, "Repair executed and audit evidence was written.")
   |> assign(:preview, nil)
   |> assign(:preview_state, :idle)
   |> load_data(row.id)}
```

**Current load path only loading active incidents** ([lib/oban_powertools/web/lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:401)):
```elixir
defp load_data(socket, selected_row_id) do
  repo = repo()
  Lifeline.project_incidents(repo)

  incidents = Lifeline.list_incidents(repo, status: "active")
  incident_rows = expand_rows(repo, incidents)
  selected_row = pick_selected_row(incident_rows, selected_row_id)
  preview = selected_row && find_pending_preview(repo, selected_row)
```

**Current row selection fallback to preserve or replace carefully** ([lib/oban_powertools/web/lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:486)):
```elixir
defp pick_selected_row([], _selected_row_id), do: nil

defp pick_selected_row(rows, selected_row_id) do
  Enum.find(rows, &(&1.id == selected_row_id)) || List.first(rows)
end
```

**Audit history continuity pattern to reuse for resolved destination** ([lib/oban_powertools/web/lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:514)):
```elixir
defp audit_events_for_row(row) do
  Audit.list_all(repo: repo())
  |> Enum.filter(fn event ->
    event.resource == resource_copy(row) or
      event.metadata["incident_fingerprint"] == row.incident.incident_fingerprint
  end)
  |> Enum.take(5)
end
```

**Planner note:** Any active/resolved split should be built by extending `load_data/2`, `pick_selected_row/2`, and the execute-success reload path, not by introducing transient client-only state.

---

### `test/oban_powertools/lifeline_test.exs` (test, CRUD)

**Analog:** `test/oban_powertools/lifeline_test.exs`

**Projection baseline to extend with stale-row resolution** ([test/oban_powertools/lifeline_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/lifeline_test.exs:48)):
```elixir
test "late executors do not project dead_executor incidents but missing executors do" do
  now = DateTime.utc_now()
  insert_heartbeat!("executor-late", DateTime.add(now, -60, :second))
  insert_heartbeat!("executor-missing", DateTime.add(now, -180, :second))

  insert_executing_job!("executor-missing")

  incidents = Lifeline.project_incidents(repo(), now: now)

  refute Enum.any?(incidents, &(&1.executor_id == "executor-late"))
```

**Execute transaction baseline to extend with incident retirement assertions** ([test/oban_powertools/lifeline_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/lifeline_test.exs:145)):
```elixir
test "execute_repair requires a reason, enforces single-use, and writes immutable audit evidence for jobs" do
  incident = insert_dead_executor_incident!("executor-missing")
  job = insert_executing_job!("executor-missing")
  actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

  {:ok, preview} =
    Lifeline.preview_repair(repo(), actor, %{
      incident_fingerprint: incident.incident_fingerprint,
      action: "job_rescue",
      target_type: "job",
      target_id: job.id
    })

  assert {:ok, %{target: repaired_job, preview: executed_preview}} =
           Lifeline.execute_repair(
             repo(),
             actor,
             preview.preview_token,
             "Rescuing the orphaned job after node loss"
           )
```

**Failed/drifted path baseline to extend with 'incident stays active' assertions** ([test/oban_powertools/lifeline_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/lifeline_test.exs:185)):
```elixir
test "execute_repair rejects drifted previews and supports workflow-step repair" do
  {:ok, workflow} = WorkflowFixtures.workflow_fixture(name: "repair-flow") |> Workflow.insert(repo())
  step = repo().get_by!(Step, workflow_id: workflow.id, step_name: "notify")
  actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}
  ...
  assert {:error, :preview_drifted} =
           Lifeline.execute_repair(
             repo(),
             actor,
             preview.preview_token,
             "State drifted before I could retry the step"
           )
```

**Fixture helpers already used for incident/job setup** ([test/oban_powertools/lifeline_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/lifeline_test.exs:275)):
```elixir
defp insert_heartbeat!(executor_id, last_heartbeat_at) do
  %Heartbeat{}
  |> Heartbeat.changeset(%{
    executor_id: executor_id,
    oban_name: "Oban",
    node: "node-a",
    queue: "default",
    producer_scope: "producer-1",
    health_state: "healthy",
    last_heartbeat_at: last_heartbeat_at,
```

**Planner note:** Add assertions into this file instead of creating a separate backend suite. This is already the repo’s DB-backed integration home for Lifeline semantics.

---

### `test/oban_powertools/web/live/lifeline_live_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/web/live/lifeline_live_test.exs`

**Session/route mount pattern** ([test/oban_powertools/web/live/lifeline_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/lifeline_live_test.exs:16)):
```elixir
conn =
  Plug.Test.init_test_session(conn,
    current_actor: %{id: "ops-1", permissions: [:view_lifeline, :preview_repair]}
  )

{:ok, view, html} = live(conn, "/ops/jobs/lifeline")
```

**Preview-first interaction pattern to reuse** ([test/oban_powertools/web/live/lifeline_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/lifeline_live_test.exs:36)):
```elixir
html =
  view
  |> element("button[phx-value-row-id='#{incident.id}:job:#{job.id}'][phx-click='preview']")
  |> render_click()

assert html =~ "Preview Ready"
assert html =~ "Audit Record to be Written"
assert has_element?(view, "button[phx-click='execute'][disabled]")

render_change(view, "reason", %{"reason" => "reviewed"})
refute has_element?(view, "button[phx-click='execute'][disabled]")
```

**Current execute success assertion baseline** ([test/oban_powertools/web/live/lifeline_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/lifeline_live_test.exs:96)):
```elixir
view
|> element("button[phx-value-row-id='#{incident.id}:job:#{job.id}'][phx-click='preview']")
|> render_click()

render_change(view, "reason", %{"reason" => "Rescuing orphaned job after node loss"})
html = render_click(view, "execute", %{})

assert html =~ "Repair executed and audit evidence was written."
assert html =~ "Manual Intervention History"
assert html =~ "Rescuing orphaned job after node loss"
```

**Fixture helpers to reuse for active/resolved continuity tests** ([test/oban_powertools/web/live/lifeline_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/lifeline_live_test.exs:123)):
```elixir
defp insert_dead_executor_incident!(executor_id, health_state \\ "missing") do
  %Incident{}
  |> Incident.changeset(%{
    incident_class: "dead_executor",
    status: "active",
    executor_id: executor_id,
    incident_fingerprint: "dead_executor:#{executor_id}",
```

**Planner note:** Extend this file with both immediate post-execute refresh assertions and a fresh `live(conn, "/ops/jobs/lifeline")` remount assertion. Keep using `render_click/2`, `render_change/3`, and route mounts instead of browser E2E.

---

### `test/support/migrations/3_phase_4_tables.exs` (migration, CRUD) — conditional

**Analog:** `test/support/migrations/3_phase_4_tables.exs`

**Existing incident-table lifecycle shape** ([test/support/migrations/3_phase_4_tables.exs](/Users/jon/projects/oban_powertools/test/support/migrations/3_phase_4_tables.exs:25)):
```elixir
create table(:oban_powertools_lifeline_incidents, primary_key: false) do
  add(:id, :uuid, primary_key: true)
  add(:incident_class, :string, null: false)
  add(:status, :string, null: false, default: "active")
  add(:executor_id, :string)
  add(:workflow_id, :uuid)
  add(:workflow_step_id, :uuid)
  add(:incident_fingerprint, :string, null: false)
  add(:health_state, :string)
  add(:summary, :string)
  add(:affected_counts, :map, null: false, default: %{})
  add(:evidence, :map, null: false, default: %{})
  add(:first_detected_at, :utc_datetime_usec, null: false)
  add(:last_detected_at, :utc_datetime_usec, null: false)
  add(:resolved_at, :utc_datetime_usec)
  add(:metadata, :map, null: false, default: %{})
```

**Index pattern to preserve if lifecycle fields/query shape change** ([test/support/migrations/3_phase_4_tables.exs](/Users/jon/projects/oban_powertools/test/support/migrations/3_phase_4_tables.exs:45)):
```elixir
create(unique_index(:oban_powertools_lifeline_incidents, [:incident_fingerprint]))
create(index(:oban_powertools_lifeline_incidents, [:incident_class]))
create(index(:oban_powertools_lifeline_incidents, [:status]))
create(index(:oban_powertools_lifeline_incidents, [:health_state]))
```

**Planner note:** Only touch this file if the plan adds durable lifecycle columns beyond `status` and `resolved_at`. The primary recommendation from research is to avoid schema churn if existing fields suffice.

---

### `lib/mix/tasks/oban_powertools.install.ex` (config, CRUD) — conditional

**Analog:** `lib/mix/tasks/oban_powertools.install.ex`

**Why this matters:** if the migration shape changes for shipped install scaffolding, the install task’s embedded migration template must stay aligned with `test/support/migrations/3_phase_4_tables.exs`.

**Analog anchor:** the grep hits for the embedded Lifeline incident migration are around [lib/mix/tasks/oban_powertools.install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex:426).

**Planner note:** Only modify this file if Phase 7 changes the persisted incident schema.

## Shared Patterns

### Authentication
**Source:** [lib/oban_powertools/web/live_auth.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/live_auth.ex:10)
**Apply to:** `LifelineLive` mount and repair actions
```elixir
def on_mount(:default, _params, session, socket) do
  actor = Auth.current_actor(session)
  {:cont, assign(socket, :current_actor, actor)}
end

def authorize_page(socket, action, resource) do
  if Auth.authorize(Map.get(socket.assigns, :current_actor), action, resource) do
    {:ok, socket}
  else
    {:error, redirect(socket, to: "/")}
  end
end

def authorize_action(socket, action, resource, opts \\ []) do
  if Auth.authorize(Map.get(socket.assigns, :current_actor), action, resource) do
    :ok
  else
    {:error, Keyword.get(opts, :message, "You are not authorized to perform this action.")}
  end
end
```

### Audit Writing
**Source:** [lib/oban_powertools/audit.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/audit.ex:27)
**Apply to:** repair execute path and resolved-view evidence lookups
```elixir
def record(action, resource, metadata \\ %{}, opts \\ []) do
  repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
  actor_id = Keyword.get(opts, :actor_id)

  %__MODULE__{}
  |> changeset(%{
    actor_id: actor_id,
    action: action,
    resource: normalize_resource(resource),
    metadata: metadata
  })
  |> repo.insert()
end
```

### Multi-Step Transaction Error Handling
**Source:** [lib/oban_powertools/workflow/runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:42), [lib/oban_powertools/cron.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/cron.ex:42)
**Apply to:** new incident-resolution `Multi.run/3` step in `Lifeline.apply_repair/5`
```elixir
Multi.new()
|> Multi.insert(:result, Result.changeset(%Result{}, result_attrs))
|> Multi.update(:step, Step.changeset(step, %{state: status, attempt: step.attempt + 1, finished_at: now}))
|> Multi.run(:reconcile, fn repo, _changes -> reconcile_workflow(repo, workflow_id, now) end)
|> Multi.run(:workflow, fn repo, _changes -> refresh_workflow(repo, workflow_id, now) end)
|> repo.transaction()
|> case do
  {:ok, %{step: updated_step, workflow: workflow}} -> {:ok, updated_step}
  {:error, _step, reason, _changes} -> {:error, reason}
end
```

### LiveView Test Harness
**Source:** [test/support/live_case.ex](/Users/jon/projects/oban_powertools/test/support/live_case.ex:1)
**Apply to:** all new Lifeline LiveView regression tests
```elixir
use ExUnit.CaseTemplate

using do
  quote do
    import Plug.Conn
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias ObanPowertools.TestRepo
```

## No Analog Found

None. Phase 7 is an extension of existing Lifeline service, schema, LiveView, and test patterns rather than a new subsystem.

## Metadata

**Analog search scope:** `lib/`, `test/`, `.planning/`
**Files scanned:** 13
**Pattern extraction date:** 2026-05-20
