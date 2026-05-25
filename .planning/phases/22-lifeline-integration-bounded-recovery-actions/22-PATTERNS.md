# Phase 22: Lifeline Integration & Bounded Recovery Actions - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/lifeline.ex` | service | request-response | `lib/oban_powertools/lifeline.ex` | exact |
| `lib/oban_powertools/lifeline/repair_preview.ex` | model | request-response | `lib/oban_powertools/lifeline/repair_preview.ex` | exact |
| `lib/oban_powertools/web/lifeline_live.ex` | liveview | request-response | `lib/oban_powertools/web/lifeline_live.ex` | exact |
| `lib/oban_powertools/web/workflows_live.ex` | liveview | request-response | `lib/oban_powertools/web/workflows_live.ex` | exact |
| `lib/oban_powertools/web/live_auth.ex` | middleware | request-response | `lib/oban_powertools/web/live_auth.ex` | exact |
| `lib/oban_powertools/explain.ex` | utility | request-response | `lib/oban_powertools/explain.ex` | exact |
| `lib/oban_powertools/workflow/runtime.ex` | service | request-response | `lib/oban_powertools/workflow/runtime.ex` | exact |
| `lib/oban_powertools/workflow.ex` | service | request-response | `lib/oban_powertools/workflow.ex` | exact |
| `lib/oban_powertools/cron.ex` | service | request-response | `lib/oban_powertools/cron.ex` | exact |
| `test/oban_powertools/lifeline_test.exs` | test | request-response | `test/oban_powertools/lifeline_test.exs` | exact |
| `test/oban_powertools/web/live/lifeline_live_test.exs` | test | request-response | `test/oban_powertools/web/live/lifeline_live_test.exs` | exact |
| `test/oban_powertools/web/live/workflows_live_test.exs` | test | request-response | `test/oban_powertools/web/live/workflows_live_test.exs` | exact |
| `test/oban_powertools/explain_test.exs` | test | request-response | `test/oban_powertools/explain_test.exs` | exact |
| `test/oban_powertools/workflow_runtime_test.exs` | test | request-response | `test/oban_powertools/workflow_runtime_test.exs` | exact |
| `test/oban_powertools/cron_test.exs` | test | request-response | `test/oban_powertools/cron_test.exs` | exact |

## Pattern Assignments

### `lib/oban_powertools/lifeline.ex` (service, request-response)

**Analog:** `lib/oban_powertools/lifeline.ex`

**Imports and supported-action vocabulary** ([lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:8))
```elixir
alias Ecto.Multi
alias ObanPowertools.{Audit, Auth, Explain}
alias ObanPowertools.Lifeline.{ArchiveRun, Heartbeat, Incident, RepairPreview}
alias ObanPowertools.Telemetry
alias ObanPowertools.Workflow.{Runtime, Step}

@supported_actions ~w(job_rescue job_retry job_cancel workflow_step_retry workflow_step_cancel)
```

**Preview creation contract: auth -> build attrs -> idempotent durable row -> telemetry** ([lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:146))
```elixir
def preview_repair(repo, actor, attrs, opts \\ []) do
  now = Keyword.get(opts, :now, DateTime.utc_now())
  attrs = Enum.into(attrs, %{})

  with :ok <- authorize(actor, :preview_repair, attrs),
       {:ok, preview_attrs} <- build_preview(repo, attrs, now) do
    existing =
      repo.one(
        from(preview in RepairPreview,
          where:
            preview.incident_fingerprint == ^preview_attrs.incident_fingerprint and
              preview.plan_hash == ^preview_attrs.plan_hash and preview.action == ^preview_attrs.action and
              preview.target_type == ^preview_attrs.target_type and
              preview.target_id == ^preview_attrs.target_id and preview.status == "ready",
          limit: 1
        )
      )

    preview =
      existing ||
        repo.insert!(RepairPreview.changeset(%RepairPreview{}, preview_attrs))

    Telemetry.execute_lifeline_event(:repair_previewed, %{count: 1}, %{
      action: preview.action,
      incident_class: preview.incident_class,
      target_type: preview.target_type
    })

    {:ok, preview}
  end
end
```

**Workflow-step preview payloads are built from shared explanation data, not LiveView-local logic** ([lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:635))
```elixir
defp build_workflow_step_preview(repo, incident, target_id, action, now) do
  step = repo.get!(Step, target_id)
  story = Explain.step_story(step, repo: repo)

  before_state = %{
    "step_id" => step.id,
    "state" => step.state,
    "blocker_codes" => step.blocker_codes,
    "diagnosis" => story.diagnosis,
    "latest_rejection" => story.rejection_summary
  }

  after_state = %{"step_id" => step.id, "state" => next_step_state(action)}
  incident_fingerprint = (incident && incident.incident_fingerprint) || "workflow_step:#{step.id}"
```

**Preview lifecycle enforcement: expire on execute check, drift via plan hash, then consume + audit in one transaction** ([lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:733))
```elixir
defp ensure_preview_available(repo, %RepairPreview{} = preview, now) do
  case RepairPreview.execute_status(preview, now) do
    :ok ->
      :ok

    {:error, :preview_expired} ->
      preview
      |> RepairPreview.changeset(%{status: "expired"})
      |> repo.update!()

      {:error, :preview_expired}

    other ->
      other
  end
end

defp ensure_not_drifted(repo, preview, current_hash, now) do
  if current_hash == preview.plan_hash do
    :ok
  else
    preview
    |> RepairPreview.changeset(%{
      status: "drifted",
      metadata:
        preview.metadata
        |> Kernel.||(%{})
        |> Map.put("drift_reason", "Target state changed after preview generation.")
        |> Map.put("drifted_at", DateTime.to_iso8601(now))
    })
    |> repo.update!()

    {:error, :preview_drifted}
  end
end
```

**Execution must route workflow actions back through `Runtime`, not a second mutation engine** ([lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:792))
```elixir
defp apply_repair(repo, preview, actor, reason, now) do
  Multi.new()
  |> Multi.run(:target, fn repo, _changes -> mutate_target(repo, preview, actor, reason, now) end)
  |> Multi.run(:incident, fn repo, _changes -> resolve_incident_after_repair(repo, preview, now) end)
  |> Multi.update(
    :preview,
    RepairPreview.changeset(preview, %{
      status: "consumed",
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
end
```

**Mutation routing for workflow actions** ([lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:878))
```elixir
defp mutate_target(repo, preview, actor, reason, now) do
  case {preview.target_type, preview.action} do
    {"workflow_step", "workflow_step_retry"} ->
      Runtime.recover_step_by_id(repo, preview.target_id, :retry,
        actor_id: Auth.actor_id(actor),
        reason: String.trim(reason),
        source: "lifeline"
      )

    {"workflow_step", "workflow_step_cancel"} ->
      Runtime.recover_step_by_id(repo, preview.target_id, :cancel,
        actor_id: Auth.actor_id(actor),
        reason: String.trim(reason),
        source: "lifeline"
      )
  end
end
```

### `lib/oban_powertools/lifeline/repair_preview.ex` (model, request-response)

**Analog:** `lib/oban_powertools/lifeline/repair_preview.ex`

**Durable preview schema and status contract** ([repair_preview.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline/repair_preview.ex:12))
```elixir
schema "oban_powertools_repair_previews" do
  field(:incident_id, Ecto.UUID)
  field(:incident_class, :string)
  field(:incident_fingerprint, :string)
  field(:plan_hash, :string)
  field(:preview_token, Ecto.UUID)
  field(:action, :string)
  field(:target_type, :string)
  field(:target_id, :string)
  field(:health_state, :string)
  field(:status, :string, default: "ready")
  field(:affected_counts, :map, default: %{})
  field(:before_snapshot, :map, default: %{})
  field(:after_snapshot, :map, default: %{})
  field(:evidence, :map, default: %{})
  field(:reason_required, :boolean, default: true)
  field(:executed_at, :utc_datetime_usec)
  field(:consumed_at, :utc_datetime_usec)
  field(:expires_at, :utc_datetime_usec)
  field(:metadata, :map, default: %{})
```

**Validation and canonical-status compatibility** ([repair_preview.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline/repair_preview.ex:36))
```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [
    :incident_id,
    :incident_class,
    :incident_fingerprint,
    :plan_hash,
    :preview_token,
    :action,
    :target_type,
    :target_id,
    :health_state,
    :status,
    :affected_counts,
    :before_snapshot,
    :after_snapshot,
    :evidence,
    :reason_required,
    :executed_at,
    :consumed_at,
    :expires_at,
    :metadata
  ])
  |> validate_required([
    :incident_class,
    :incident_fingerprint,
    :plan_hash,
    :preview_token,
    :action,
    :target_type,
    :target_id,
    :status,
    :affected_counts,
    :before_snapshot,
    :after_snapshot,
    :evidence,
    :reason_required,
    :metadata
  ])
  |> validate_inclusion(:status, @statuses)
  |> unique_constraint(:preview_token)
end

def canonical_status("pending"), do: "ready"
def canonical_status("executed"), do: "consumed"
```

**Shared execute-state reducer** ([repair_preview.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline/repair_preview.ex:86))
```elixir
def execute_status(%__MODULE__{consumed_at: consumed_at}, _now) when not is_nil(consumed_at),
  do: {:error, :preview_consumed}

def execute_status(%__MODULE__{status: status}, _now) when status in ["consumed", "executed"],
  do: {:error, :preview_consumed}

def execute_status(%__MODULE__{status: "drifted"}, _now), do: {:error, :preview_drifted}
def execute_status(%__MODULE__{status: "expired"}, _now), do: {:error, :preview_expired}
```

### `lib/oban_powertools/web/lifeline_live.ex` (liveview, request-response)

**Analog:** `lib/oban_powertools/web/lifeline_live.ex`

**Mount and page auth pattern** ([lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:15))
```elixir
def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
  with {:ok, socket} <-
         LiveAuth.authorize_page(socket, :view_lifeline, %{type: :page, id: "lifeline"}) do
    :ok = DisplayPolicy.assert_configured!()

    {:ok,
     socket
     |> assign(:oban_dashboard_path, dashboard_path)
     |> assign(:reason, "")
     |> assign(:error_message, nil)
     |> assign(:success_message, nil)
     |> assign(:current_view, "active")
     |> assign(:preview, nil)
     |> assign(:preview_state, :idle)
     |> load_data(nil)}
```

**Preview event pattern: check previewability, auth, principal, then call service with row-derived context** ([lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:53))
```elixir
def handle_event("preview", %{"row-id" => row_id}, socket) do
  row = find_row!(socket.assigns.visible_incident_rows, row_id)

  with :ok <- ensure_previewable(row),
       :ok <-
         LiveAuth.authorize_action(socket, :preview_repair, row.resource,
           message: LiveAuth.permission_message(:preview_repair)
         ),
       {:ok, _principal} <- LiveAuth.principal_for_action(socket),
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

**Execute event pattern: same checks, execute through service, reload into resolved view, drift handled by reloading preview row** ([lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:110))
```elixir
def handle_event("execute", _params, socket) do
  preview = socket.assigns.preview
  row = socket.assigns.selected_row

  with :ok <-
         LiveAuth.authorize_action(socket, :execute_repair, row.resource,
           message: LiveAuth.permission_message(:execute_repair)
         ),
       {:ok, _principal} <- LiveAuth.principal_for_action(socket),
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
     |> load_data(%{
       view: "resolved",
       incident_fingerprint: preview.incident_fingerprint
     })}
  else
    {:error, :preview_drifted} ->
      drifted_preview = repo().get_by!(RepairPreview, preview_token: preview.preview_token)
```

**Incident-row shaping is the existing seam for cross-surface action cards** ([lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:573))
```elixir
defp incident_rows(repo, %Incident{incident_class: "workflow_stuck", workflow_step_id: step_id} = incident) do
  step = repo.get(Step, step_id)
  step_name = step && step.step_name || Map.get(incident.evidence || %{}, "step_name", "workflow step")

  [
    %{
      id: "#{incident.id}:workflow_step:#{step_id}",
      incident: incident,
      action: "workflow_step_retry",
      target_type: "workflow_step",
      target_id: to_string(step_id),
      target_summary: "#{step_name} in workflow #{incident.workflow_id}",
      previewable?: true,
      resource: %{type: :workflow_step, id: to_string(step_id)}
    }
  ]
end
```

**Pending-preview lookup and UI gating helpers** ([lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:649))
```elixir
defp find_pending_preview(repo, row) do
  repo.one(
    from(preview in RepairPreview,
      where:
        preview.incident_id == ^row.incident.id and preview.action == ^row.action and
          preview.target_type == ^row.target_type and preview.target_id == ^row.target_id and
          preview.status in ["pending", "drifted"],
      order_by: [desc: preview.inserted_at],
      limit: 1
    )
  )
end

defp preview_action(row, actor) do
  cond do
    not row.previewable? ->
      %{enabled?: false, disabled_reason: LiveAuth.mutation_error(:preview_not_available)}

    LiveAuth.authorized?(actor, :preview_repair, row.resource) ->
      %{enabled?: true, disabled_reason: nil}
```

**Error mapping stays centralized in the LiveView, but wording comes from `LiveAuth`** ([lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:891))
```elixir
defp error_message(:preview_not_found), do: LiveAuth.mutation_error(:preview_not_available)
defp error_message(:preview_not_available), do: LiveAuth.mutation_error(:preview_not_available)
defp error_message(:preview_drifted), do: LiveAuth.mutation_error(:preview_drifted)
defp error_message(:preview_expired), do: LiveAuth.mutation_error(:preview_expired)
defp error_message(:preview_consumed), do: LiveAuth.mutation_error(:preview_consumed)
defp error_message(:reason_required), do: LiveAuth.mutation_error(:reason_required)
```

### `lib/oban_powertools/web/workflows_live.ex` (liveview, request-response)

**Analog:** `lib/oban_powertools/web/workflows_live.ex`

**Diagnosis-first read-only page posture** ([workflows_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/workflows_live.ex:14))
```elixir
def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
  with {:ok, socket} <-
         LiveAuth.authorize_page(socket, :view_workflows, %{type: :page, id: "workflows"}) do
    :ok = DisplayPolicy.assert_configured!()
```

**Current top-of-page copy and workflow summary rendering are the analog for the Phase 22 handoff CTA placement** ([workflows_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/workflows_live.ex:80))
```heex
<div>
  <h1 class="text-2xl font-semibold">Workflows</h1>
  <p class="text-sm text-zinc-600">
    Diagnose workflow causality here. Powertools-native pages own preview, reason, and audited mutations.
  </p>
</div>

<p class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
  <%= LiveAuth.page_read_only_banner(:workflows) %>
</p>
```

**Step navigation and rejection display pattern** ([workflows_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/workflows_live.ex:149))
```heex
<div :for={step <- @steps} class={["rounded border p-3", highlight_class(step, @selected_step)]}>
  <% story = Map.fetch!(@step_stories, step.id) %>
  <div class="flex items-center justify-between gap-3">
    <div>
      <p class="font-medium"><%= step.step_name %></p>
      <p class="text-xs text-zinc-500"><%= step.state %></p>
      <p class="text-xs text-zinc-500">diagnosis: <%= story.diagnosis || "none" %></p>
    </div>
    <.link
      patch={selected_step_path(@workflow.id, step.step_name)}
      class="text-sm text-indigo-700 underline"
    >
      Detail
    </.link>
  </div>
```

**Allowed-next-step rendering is already wired to shared refusal vocabulary** ([workflows_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/workflows_live.ex:184))
```heex
<p :if={@selected_step_story.rejection_summary} class="mt-1 text-sm text-amber-700">
  Latest refusal: <%= @selected_step_story.rejection_summary.code %> - <%= @selected_step_story.rejection_summary.message %>
</p>
<p
  :if={@selected_step_story.rejection_summary && @selected_step_story.rejection_summary.legal_next_steps != []}
  class="mt-1 text-sm text-zinc-600"
>
  Legal next steps: <%= Enum.join(@selected_step_story.rejection_summary.legal_next_steps, ", ") %>
</p>
```

**Detail-loading pattern: load records once, compute `workflow_story` and `step_stories`, choose a selected step deterministically** ([workflows_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/workflows_live.ex:251))
```elixir
defp load_workflow_detail(socket, workflow_id, selected_step_name) do
  workflow = repo().get!(Workflow, workflow_id)

  steps =
    repo().all(
      from(step in Step,
        where: step.workflow_id == ^workflow_id,
        order_by: [asc: step.position]
      )
    )

  selected_step =
    Enum.find(steps, &(&1.step_name == selected_step_name)) ||
      List.first(Enum.filter(steps, &(&1.blocker_codes != []))) ||
      List.first(steps)

  workflow_story = Explain.workflow_story(workflow, steps, repo: repo())
  step_stories = Map.new(steps, &{&1.id, Explain.step_story(&1, repo: repo())})
```

**Patch-based step routing** ([workflows_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/workflows_live.ex:328))
```elixir
defp selected_step_path(workflow_id, step_name),
  do: "/ops/jobs/workflows/#{workflow_id}?step=#{step_name}"
```

### `lib/oban_powertools/web/live_auth.ex` (middleware, request-response)

**Analog:** `lib/oban_powertools/web/live_auth.ex`

**Shared permission/error vocabulary** ([live_auth.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/live_auth.ex:10))
```elixir
@missing_principal_message "Oban Powertools could not derive a durable audit principal for this action."
@audit_consequence "One immutable operator event will be written."
@mutation_errors %{
  preview_not_found: "preview_not_available",
  preview_not_available: "preview_not_available",
  preview_drifted: "preview_drifted",
  preview_expired: "preview_expired",
  preview_consumed: "preview_consumed",
  reason_required: "reason_required",
  reason_too_short: "reason_too_short",
  mutation_conflict: "mutation_conflict",
  unauthorized: "unauthorized"
}
```

**Permission copy pattern for mutation surfaces** ([live_auth.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/live_auth.ex:23))
```elixir
@permission_messages %{
  preview_repair:
    "Permission: read-only. You can inspect this incident, but you do not have permission to preview this repair.",
  execute_repair:
    "Permission: read-only. You can inspect this preview, but you do not have permission to execute this repair."
}
```

**Page auth, action auth, and principal derivation** ([live_auth.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/live_auth.ex:51))
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

    {:error, _reason} ->
      {:error, Keyword.get(opts, :message, permission_message(action))}
  end
end

def principal_for_action(socket, opts \\ []) do
  case Auth.audit_principal(Map.get(socket.assigns, :current_actor)) do
    {:ok, principal} -> {:ok, principal}
    {:error, _reason} -> {:error, Keyword.get(opts, :message, @missing_principal_message)}
  end
end
```

### `lib/oban_powertools/explain.ex` (utility, request-response)

**Analog:** `lib/oban_powertools/explain.ex`

**Workflow and step read-model seam** ([explain.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex:137))
```elixir
def workflow_story(%Workflow{} = workflow, steps, opts \\ []) when is_list(steps) do
  repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
  latest_rejection = latest_rejection(repo, workflow.id)

  %{
    diagnosis: Runtime.workflow_diagnosis(workflow, steps),
    semantics: Runtime.semantics_profile(workflow),
    latest_rejection: latest_rejection,
    rejection_summary: rejection_summary(latest_rejection),
    callback_posture: callback_posture(repo, workflow.id),
    latest_recovery_session: latest_recovery_session(repo, workflow.id)
  }
end

def step_story(%Step{} = step, opts \\ []) do
  repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
  latest_rejection = latest_rejection(repo, step.workflow_id, step.id)

  %{
    diagnosis: Runtime.step_diagnosis(step),
    blocker_codes: step.blocker_codes,
    blocker_summaries: Enum.map(step.blocker_codes, &blocker_summary/1),
    latest_rejection: latest_rejection,
    rejection_summary: rejection_summary(latest_rejection)
  }
end
```

**Rejection summary keeps `legal_next_steps` close to the story payload** ([explain.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex:164))
```elixir
%{
  action: attempt.action,
  reason_code: attempt.reason_code,
  message: attempt.reason_message,
  legal_next_steps: Map.get(attempt.metadata || %{}, "legal_next_steps", []),
  requested_at: attempt.requested_at,
  actor_id: attempt.actor_id,
  source: attempt.source
}
```

**UI-facing rejection reducer** ([explain.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex:285))
```elixir
defp rejection_summary(rejection) do
  %{
    code: rejection.reason_code,
    message: rejection.message,
    legal_next_steps: rejection.legal_next_steps
  }
end
```

### `lib/oban_powertools/workflow/runtime.ex` (service, request-response)

**Analog:** `lib/oban_powertools/workflow/runtime.ex`

**Command validation and durable rejection evidence** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:177))
```elixir
defp validate_command(%{action: action, workflow: nil} = command)
     when action in ["complete_step", "await_step", "request_cancel", "recover_step"] do
  {:error,
   rejection(command, "workflow_not_found",
     message: "workflow mutation target was not found",
     legal_next_steps: ["verify_workflow_id"]
   )}
end

defp validate_command(%{scope: "step", step: nil} = command) do
  {:error,
   rejection(command, "step_not_found",
     message: "workflow step mutation target was not found",
     legal_next_steps: ["verify_step_name"]
   )}
end
```

**Rejected commands persist `legal_next_steps` into `CommandAttempt` metadata** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:230))
```elixir
defp reject_command(repo, command, rejection) do
  _ =
    %CommandAttempt{}
    |> CommandAttempt.changeset(
      command_attempt_attrs(command, "rejected",
        reason_code: rejection.reason_code,
        reason_message: rejection.message,
        after_snapshot: %{},
        metadata: %{"legal_next_steps" => rejection.legal_next_steps}
      )
    )
    |> repo.insert()
```

**Workflow-level cancel command already exists and is the analog for `workflow_request_cancel`** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:504))
```elixir
def request_cancel(repo, workflow_id, attrs \\ %{}) do
  execute_command(repo, %{
    action: "request_cancel",
    scope: "workflow",
    workflow_id: workflow_id,
    attrs: attrs,
    source: command_source(attrs, "operator")
  })
end

defp run_request_cancel(repo, %{attrs: attrs, workflow: workflow} = command) do
  now = command.requested_at
  actor_id = read_value(attrs, :actor_id)
  reason = blank_to_nil(read_value(attrs, :reason))
```

**Recover-step command is already the bounded step-action mutation path** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:604))
```elixir
def recover_step(repo, workflow_id, step_name, action, attrs \\ %{}) do
  execute_command(repo, %{
    action: "recover_step",
    recovery_action: normalize_status(action),
    scope: "step",
    workflow_id: workflow_id,
    step_name: to_string(step_name),
    attrs: attrs,
    source: command_source(attrs, "operator")
  })
end
```

**ID-based wrapper used by Lifeline** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:723))
```elixir
def recover_step_by_id(repo, step_id, action, attrs \\ %{}) do
  step = repo.get!(Step, step_id)
  recover_step(repo, step.workflow_id, step.step_name, action, attrs)
end
```

**Diagnosis vocabulary stays runtime-owned** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:777))
```elixir
def workflow_diagnosis(%Workflow{} = workflow, steps) do
  cond do
    workflow.state == "cancel_requested" or not is_nil(workflow.cancel_requested_at) ->
      "cancel_requested"
```

### `lib/oban_powertools/workflow.ex` (service, request-response)

**Analog:** `lib/oban_powertools/workflow.ex`

**Public API surface stays thin and explicit** ([workflow.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow.ex:92))
```elixir
def complete_step(repo, workflow_id, step_name, attrs \\ []),
  do:
    ObanPowertools.Workflow.Runtime.complete_step(
      repo,
      workflow_id,
      step_name,
      Enum.into(attrs, %{})
    )

def request_cancel(repo, workflow_id, attrs \\ []),
  do: ObanPowertools.Workflow.Runtime.request_cancel(repo, workflow_id, Enum.into(attrs, %{}))

def recover_step(repo, workflow_id, step_name, action, attrs \\ []),
  do:
    ObanPowertools.Workflow.Runtime.recover_step(
      repo,
      workflow_id,
      step_name,
      action,
      Enum.into(attrs, %{})
    )
```

### `lib/oban_powertools/cron.ex` (service, request-response)

**Analog:** `lib/oban_powertools/cron.ex`

**This is the existing second consumer of the shared preview seam** ([cron.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/cron.ex:107))
```elixir
def preview_entry_action(repo, action, %Entry{} = entry, opts \\ []) do
  now = Keyword.get(opts, :now, DateTime.utc_now())

  with :ok <- validate_preview_action(action, entry),
       preview_attrs <- build_preview(entry, action, now) do
    existing =
      repo.one(
        from(preview in RepairPreview,
          where:
            preview.incident_fingerprint == ^preview_attrs.incident_fingerprint and
              preview.plan_hash == ^preview_attrs.plan_hash and preview.action == ^preview_attrs.action and
              preview.target_type == ^preview_attrs.target_type and
              preview.target_id == ^preview_attrs.target_id and preview.status == "ready",
          limit: 1
        )
      )
```

**Preview payload shape for another Powertools-native surface** ([cron.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/cron.ex:421))
```elixir
%{
  incident_class: "cron_entry",
  incident_fingerprint: "cron_entry:#{entry.name}",
  plan_hash: cron_plan_hash(action, entry, before_snapshot),
  preview_token: Ecto.UUID.generate(),
  action: action,
  target_type: "cron_entry",
  target_id: entry.id,
  status: "ready",
  affected_counts: affected_counts(action),
  before_snapshot: before_snapshot,
  after_snapshot: cron_after_snapshot(action, entry),
  evidence: %{"previewed_at" => now},
  reason_required: false,
  expires_at: DateTime.add(now, @preview_ttl_seconds, :second),
  metadata: %{
    "summary" => cron_summary(action, entry),
    "risk" => cron_risk(action),
    "resource" => %{"type" => "cron_entry", "id" => entry.name, "source" => entry.source}
  }
}
```

**Preview status and drift enforcement pattern to reuse, not fork** ([cron.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/cron.ex:523))
```elixir
defp ensure_preview_available(repo, preview, now) do
  case RepairPreview.execute_status(preview, now) do
    :ok ->
      :ok

    {:error, :preview_expired} ->
      preview
      |> RepairPreview.changeset(%{status: "expired"})
      |> repo.update!()

      {:error, :preview_expired}
```

```elixir
defp ensure_not_drifted(repo, preview, entry, now) do
  current_hash = cron_plan_hash(preview.action, entry, cron_before_snapshot(entry))

  if current_hash == preview.plan_hash do
    :ok
  else
    preview
    |> RepairPreview.changeset(%{
      status: "drifted",
      metadata:
        preview.metadata
        |> Kernel.||(%{})
        |> Map.put("drift_reason", "Cron entry state changed after preview generation.")
        |> Map.put("drifted_at", DateTime.to_iso8601(now))
    })
    |> repo.update!()

    {:error, :preview_drifted}
  end
end
```

### Test surfaces

### `test/oban_powertools/lifeline_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/lifeline_test.exs`

**Workflow-stuck incident evidence and idempotent preview coverage** ([lifeline_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/lifeline_test.exs:108))
```elixir
assert %Incident{incident_class: "workflow_stuck"} = incident
assert incident.workflow_step_id == step.id
assert incident.evidence["step_name"] == "notify"
assert incident.evidence["diagnosis"] == "waiting_on_retryable_dependency"
assert incident.evidence["blocker_summaries"] == ["step is waiting on retryable upstream work"]
```

```elixir
assert {:ok, first_preview} =
         Lifeline.preview_repair(repo(), actor, %{
           incident_fingerprint: incident.incident_fingerprint,
           action: "job_rescue",
           target_type: "job",
           target_id: job.id
         })

assert {:ok, second_preview} = ...
assert first_preview.id == second_preview.id
assert first_preview.status == "ready"
```

**Execute, consume, drift, and workflow-step routing coverage** ([lifeline_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/lifeline_test.exs:225))
```elixir
assert {:error, :reason_required} =
         Lifeline.execute_repair(repo(), actor, preview.preview_token, "   ")

assert {:ok, %{target: repaired_job, preview: executed_preview}} =
         Lifeline.execute_repair(
           repo(),
           actor,
           preview.preview_token,
           "Rescuing the orphaned job after node loss"
         )

assert executed_preview.status == "consumed"
assert {:error, :preview_consumed} = ...
```

```elixir
assert {:error, :preview_drifted} =
         Lifeline.execute_repair(
           repo(),
           actor,
           preview.preview_token,
           "State drifted before I could retry the step"
         )

assert command_attempt.source == "lifeline"
assert command_attempt.reason_message == "Cancelling the stuck step after operator review"
```

### `test/oban_powertools/web/live/lifeline_live_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/web/live/lifeline_live_test.exs`

**UI copy and preview panel expectations** ([lifeline_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/lifeline_live_test.exs:49))
```elixir
assert html =~ "Needs Review"
assert html =~ "Preview Repair Plan"
assert html =~ "Archive Activity"
refute has_element?(view, "button[phx-click='execute']")
```

```elixir
assert html =~ "Preview Ready"
assert html =~ "Audit Consequence"
assert html =~ "One immutable operator event will be written."
assert html =~ "Open Generic Job Inspection in Oban Web"
```

**Drift wording, resolved-view flow, and permission copy** ([lifeline_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/lifeline_live_test.exs:104))
```elixir
assert html =~ "preview_drifted"
assert has_element?(view, "button[phx-click='execute'][disabled]")
```

```elixir
assert html =~ "Repair executed and audit evidence was written."
assert html =~ "Resolved Incidents"
assert html =~ "Manual Intervention History"
```

```elixir
assert html =~
         "Permission: read-only. You can inspect this preview, but you do not have permission to execute this repair."
```

### `test/oban_powertools/web/live/workflows_live_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/web/live/workflows_live_test.exs`

**Patch-based workflow detail and existing read-only workflow posture** ([workflows_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/workflows_live_test.exs:43))
```elixir
{:ok, view, html} = live(conn, "/ops/jobs/workflows/#{workflow.id}?step=sync_billing")
assert html =~ "Workflows"
assert html =~ "Permission: read-only."
assert html =~ "Powertools-native pages"
assert html =~ "Open generic job inspection in Oban Web"
```

**Shared rejection vocabulary is already rendered here** ([workflows_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/workflows_live_test.exs:115))
```elixir
assert html =~ "Latest refusal: unsupported_legacy_semantics"
assert html =~ "migrate_via_compatibility_path"
assert html =~ "Semantics: legacy_v1 (compatibility_path)"
```

### `test/oban_powertools/explain_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/explain_test.exs`

**`workflow_story/3` is already tested as the explanation seam** ([explain_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/explain_test.exs:69))
```elixir
story =
  Explain.workflow_story(
    repo().get!(ObanPowertools.Workflow.Workflow, workflow.id),
    steps,
    repo: repo()
  )

assert story.callback_posture.total >= 1
assert story.latest_recovery_session.id
assert story.latest_recovery_session.trigger == "recover_step"
```

### `test/oban_powertools/workflow_runtime_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/workflow_runtime_test.exs`

**Workflow-level cancel semantics and bounded rejection vocabulary** ([workflow_runtime_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_test.exs:379))
```elixir
assert {:ok, _workflow} =
         Workflow.request_cancel(TestRepo, workflow.id,
           actor_id: "ops-1",
           reason: "stop requested"
         )
```

```elixir
assert rejection.reason_code == "illegal_transition"
assert rejection.legal_next_steps == ["inspect_step_result"]

assert rejection.reason_code == "unsupported_legacy_semantics"
assert rejection.legal_next_steps == ["migrate_via_compatibility_path"]
```

### `test/oban_powertools/cron_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/cron_test.exs`

**Existing proof that the preview envelope is already shared across another surface** ([cron_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/cron_test.exs:99))
```elixir
assert {:ok, first_preview} = Cron.preview_entry_action(repo(), "pause_cron_entry", entry)
assert {:ok, second_preview} = Cron.preview_entry_action(repo(), "pause_cron_entry", entry)

assert first_preview.id == second_preview.id
assert first_preview.status == "ready"
assert first_preview.reason_required == false
```

```elixir
assert {:error, :preview_consumed} =
         Cron.pause_cron_entry(repo(), paused_preview.preview_token, "operator-1")

assert {:error, :preview_expired} =
         Cron.resume_cron_entry(repo(), resume_preview.preview_token, "operator-1")

assert {:error, :preview_drifted} =
         Cron.run_cron_entry(repo(), run_preview.preview_token, "operator-1")
```

## Shared Patterns

### Authentication and durable principal checks
**Source:** `lib/oban_powertools/web/live_auth.ex`
**Apply to:** `LifelineLive`, `WorkflowsLive`, any new handoff or preview UI
```elixir
def authorize_action(socket, action, resource, opts \\ []) do
  case Auth.authorization_outcome(Map.get(socket.assigns, :current_actor), action, resource) do
    :ok ->
      :ok

    {:error, _reason} ->
      {:error, Keyword.get(opts, :message, permission_message(action))}
  end
end

def principal_for_action(socket, opts \\ []) do
  case Auth.audit_principal(Map.get(socket.assigns, :current_actor)) do
    {:ok, principal} -> {:ok, principal}
    {:error, _reason} -> {:error, Keyword.get(opts, :message, @missing_principal_message)}
  end
end
```

### Shared preview lifecycle
**Source:** `lib/oban_powertools/lifeline/repair_preview.ex`
**Apply to:** Lifeline workflow actions, cron reuse points, any generalized preview wrapper
```elixir
def execute_status(%__MODULE__{status: "drifted"}, _now), do: {:error, :preview_drifted}
def execute_status(%__MODULE__{status: "expired"}, _now), do: {:error, :preview_expired}

def execute_status(%__MODULE__{expires_at: %DateTime{} = expires_at}, %DateTime{} = now) do
  if DateTime.compare(expires_at, now) == :lt, do: {:error, :preview_expired}, else: :ok
end
```

### Workflow legality and refusal vocabulary are command-core-owned
**Source:** `lib/oban_powertools/workflow/runtime.ex`
**Apply to:** Any new Lifeline workflow action, any workflow-page handoff labels or CTAs
```elixir
defp reject_command(repo, command, rejection) do
  _ =
    %CommandAttempt{}
    |> CommandAttempt.changeset(
      command_attempt_attrs(command, "rejected",
        reason_code: rejection.reason_code,
        reason_message: rejection.message,
        after_snapshot: %{},
        metadata: %{"legal_next_steps" => rejection.legal_next_steps}
      )
    )
    |> repo.insert()
```

### Explanation seam for actionability and handoff text
**Source:** `lib/oban_powertools/explain.ex`
**Apply to:** Workflow page CTA eligibility, Lifeline workflow preview payloads, audit metadata copy
```elixir
%{
  diagnosis: Runtime.step_diagnosis(step),
  blocker_codes: step.blocker_codes,
  blocker_summaries: Enum.map(step.blocker_codes, &blocker_summary/1),
  latest_rejection: latest_rejection,
  rejection_summary: rejection_summary(latest_rejection)
}
```

### Preview drift / expiry enforcement should match cron and Lifeline
**Source:** `lib/oban_powertools/cron.ex`, `lib/oban_powertools/lifeline.ex`
**Apply to:** Any preview-envelope extraction or rename
```elixir
preview
|> RepairPreview.changeset(%{
  status: "drifted",
  metadata:
    preview.metadata
    |> Kernel.||(%{})
    |> Map.put("drift_reason", "Target state changed after preview generation.")
    |> Map.put("drifted_at", DateTime.to_iso8601(now))
})
|> repo.update!()
```

## No Analog Found

None. Every likely Phase 22 touchpoint already has a strong in-repo analog.

## Metadata

**Analog search scope:** `lib/oban_powertools/`, `lib/oban_powertools/web/`, `test/oban_powertools/`
**Files scanned:** 15 targeted files plus roadmap/context inputs
**Pattern extraction date:** 2026-05-24
