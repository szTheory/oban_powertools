# Phase 44: Single-Job Actions - Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/lifeline.ex` | service | CRUD / state mutation | `lib/oban_powertools/lifeline.ex` | exact |
| `lib/oban_powertools/web/jobs_live.ex` | controller (LiveView) | UI interaction | `lib/oban_powertools/web/lifeline_live.ex` | exact |

## Pattern Assignments

### `lib/oban_powertools/lifeline.ex` (service, CRUD)

**Analog:** `lib/oban_powertools/lifeline.ex` (existing `"job_cancel"` logic)

**Supported Actions pattern** (line 23):
```elixir
  @supported_actions ~w(job_rescue job_retry job_cancel workflow_step_retry workflow_step_cancel workflow_request_cancel)
```

**Build Preview pattern** (lines 591-593):
```elixir
      case {target_type, action} do
        {"job", action} when action in ["job_rescue", "job_retry", "job_cancel"] ->
          build_job_preview(repo, incident, target_id, action, now)
```

**Next State pattern** (lines 804-805):
```elixir
  defp next_job_state(action) when action in ["job_rescue", "job_retry"], do: "available"
  defp next_job_state("job_cancel"), do: "cancelled"
```

**Mutate Target pattern** (lines 1155-1157):
```elixir
      {"job", "job_cancel"} ->
        job = repo.get!(Oban.Job, preview.target_id)
        {:ok, repo.update!(Ecto.Changeset.change(job, state: "cancelled", cancelled_at: now))}
```

**Repair Summary pattern** (lines 1235-1236):
```elixir
  defp repair_summary("job_cancel", "job", target_id),
    do: "Cancel job #{target_id} from the native repair flow."
```

---

### `lib/oban_powertools/web/jobs_live.ex` (controller, UI interaction)

**Analog:** `lib/oban_powertools/web/lifeline_live.ex`

**Imports pattern** (lines 7-11):
```elixir
    alias ObanPowertools.{Audit, DisplayPolicy, Explain, Lifeline}
    alias ObanPowertools.Lifeline.{ArchiveRun, Incident, RepairPreview, TargetType}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}
```

**Preview Mutation pattern** (lines 74-96):
```elixir
    def handle_event("preview", %{"action" => action}, socket) do
      # Note: JobsLive will not have an incident_id
      with :ok <-
             LiveAuth.authorize_action(socket, :preview_repair, %{type: :job, id: to_string(socket.assigns.job.id)},
               message: LiveAuth.permission_message(:preview_repair)
             ),
           {:ok, _principal} <- LiveAuth.principal_for_action(socket),
           {:ok, preview} <-
             Lifeline.preview_repair(
               repo(),
               socket.assigns.current_actor,
               %{
                 incident_id: nil,
                 action: action,
                 target_type: "job",
                 target_id: socket.assigns.job.id
               }
             ) do
        {:noreply,
         socket
         |> assign(:preview, preview)
         |> assign(:reason, "")
         |> assign(:error_message, nil)
         |> assign(:success_message, nil)}
      # ... error handling omitted for brevity
```

**Execute Mutation pattern** (lines 133-148):
```elixir
    def handle_event("execute", _params, socket) do
      preview = socket.assigns.preview
      job = socket.assigns.job

      with :ok <-
             LiveAuth.authorize_action(socket, :execute_repair, %{type: :job, id: to_string(job.id)},
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
         |> assign(:success_message, "Action executed successfully.")
         |> assign(:preview, nil)
         # Re-fetch the job detail
         |> load_job_detail(job.id)}
      # ... error handling omitted for brevity
```

**Reason Tracking pattern** (lines 125-127):
```elixir
    def handle_event("reason", %{"reason" => reason}, socket) do
      {:noreply, assign(socket, :reason, reason)}
    end
```

## Shared Patterns

### Action Preview Modal (UI)
**Source:** Phase 44 UI-SPEC.md explicitly states that `oban_powertools` must NOT use Phoenix CoreComponents. The modal overlay and UI must be pure inline HTML and Tailwind CSS classes inside `jobs_live.ex`.
**Apply to:** `jobs_live.ex` modal layer.
```html
<div class="fixed inset-0 bg-zinc-900/50 backdrop-blur-sm">...</div>
```

### Concurrent Modification Guard
**Source:** Phase 44 CONTEXT.md explicit decision D-05.
**Apply to:** `jobs_live.ex` Execute pattern.
When `Lifeline.execute_repair/4` returns `{:error, :preview_drifted}`, surface an explicit error message based on the UI-SPEC:
"Could not execute action. The job's state was changed by another process or operator. Please refresh to see the latest state."

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| Action Preview Modal | Component | UI | Per D-01, an explicit inline Tailwind design must be built from the UI-SPEC since Shadcn and Phoenix CoreComponents cannot be used in the library context. |

## Metadata

**Analog search scope:** `lib/oban_powertools/web/**/*.ex`, `lib/oban_powertools/lifeline.ex`
**Files scanned:** 2
**Pattern extraction date:** 2026-05-28
