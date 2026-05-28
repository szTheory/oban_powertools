# Phase 45: Bulk Operations - Patterns

## Relevant Codebase Patterns

### 1. Single Action Execution (Phase 44)
In `lib/oban_powertools/web/jobs_live.ex`, single actions use a preview step followed by an execution step:
```elixir
with :ok <- LiveAuth.authorize_action(socket, :preview_repair, %{type: :job, id: to_string(socket.assigns.job.id)}),
     {:ok, preview} <- Lifeline.preview_repair(repo(), socket.assigns.current_actor, %{
       incident_id: nil,
       action: action,
       target_type: "job",
       target_id: socket.assigns.job.id
     }) do
  # assign preview
```
And execution:
```elixir
with :ok <- LiveAuth.authorize_action(socket, :execute_repair, %{type: :job, id: to_string(socket.assigns.job.id)}),
     {:ok, %{target: target}} <- Lifeline.execute_repair(repo(), socket.assigns.current_actor, socket.assigns.preview.preview_token, reason) do
  # handle success
```
**Application for Phase 45:**
For bulk execution, we will authorize once for the page (or iterate over individual authorizations), and run the same `Lifeline.preview_repair` -> `Lifeline.execute_repair` pipeline in a loop for each selected job.

### 2. LiveView Filter State Management
When filtering changes, `JobsLive` uses `push_patch` to update the URL:
```elixir
def handle_event("select_state", %{"state" => state}, socket) do
  # ...
  {:noreply, push_patch(socket, to: Selectors.jobs_path(filter_path(new_filter)))}
end
```
**Application for Phase 45:**
We must intercept filter changes (e.g. inside `handle_params` or the event handlers) and clear the `selected_jobs` assign when the core filter (state, queue, worker) changes. Pagination changes can retain the MapSet.

### 3. State-based Button Visibility
In the job detail view, buttons are conditionally rendered based on `@job.state`:
```heex
<button :if={@job.state in ["retryable", ...]} phx-click="preview" phx-value-action="job_retry" ...>
```
**Application for Phase 45:**
Since the job list is always filtered by a single state (e.g., `state="available"`), we can use the `assigns.filter.state` to determine which bulk action buttons to display.

## Architectural Constraints
- **Independent Execution:** No Ecto.Multi wrapping the entire batch. Each job gets its own repair lifecycle.
- **Strict Auditing:** The `Lifeline` layer enforces the reason. We must gather it via the bulk preview modal before executing.
