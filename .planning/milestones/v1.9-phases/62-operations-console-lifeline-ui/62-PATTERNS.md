# Phase 62: Operations Console & Lifeline UI - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/web/router.ex` | route | request-response | `lib/oban_powertools/web/router.ex` | exact |
| `lib/oban_powertools/web/selectors.ex` | utility | request-response | `lib/oban_powertools/web/selectors.ex` | exact |
| `lib/oban_powertools/web/live_auth.ex` | middleware | request-response | `lib/oban_powertools/web/live_auth.ex` | exact |
| `lib/oban_powertools/batches.ex` | service | CRUD | `lib/oban_powertools/jobs.ex` | role-match |
| `lib/oban_powertools/lifeline.ex` | service | CRUD | `lib/oban_powertools/lifeline.ex` | exact-boundary |
| `lib/oban_powertools/lifeline/target_type.ex` | utility | transform | `lib/oban_powertools/lifeline/target_type.ex` | exact |
| `lib/oban_powertools/web/batches_live.ex` | component | request-response | `lib/oban_powertools/web/jobs_live.ex` | role-match |
| `test/oban_powertools/batches_test.exs` | test | CRUD | `test/oban_powertools/jobs_test.exs` | role-match |
| `test/oban_powertools/lifeline_callback_test.exs` | test | CRUD | `test/oban_powertools/lifeline_test.exs` | role-match |
| `test/oban_powertools/web/live/batches_live_test.exs` | test | request-response | `test/oban_powertools/web/live/jobs_live_test.exs` | role-match |
| `test/oban_powertools/web/router_test.exs` | test | request-response | `test/oban_powertools/web/router_test.exs` | exact |
| `test/oban_powertools/web/selectors_test.exs` | test | request-response | `test/oban_powertools/web/selectors_test.exs` | exact |
| `test/oban_powertools/lifeline/target_type_test.exs` | test | transform | `test/oban_powertools/lifeline/target_type_test.exs` | exact |

## Pattern Assignments

### `lib/oban_powertools/web/router.ex` (route, request-response)

**Analog:** `lib/oban_powertools/web/router.ex`

**Route shell pattern** (lines 50-66):
```elixir
quote do
  import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 3]

  live_session :oban_powertools_native,
    on_mount: [ObanPowertools.Web.LiveAuth],
    session: %{"oban_dashboard_path" => unquote(path)} do
    live("/", ObanPowertools.Web.EngineOverviewLive, :index)
    live("/lifeline", ObanPowertools.Web.LifelineLive, :index)
    live("/limiters", ObanPowertools.Web.LimitersLive, :index)
    live("/cron", ObanPowertools.Web.CronLive, :index)
    live("/audit", ObanPowertools.Web.AuditLive, :index)
    live("/forensics", ObanPowertools.Web.ForensicsLive, :index)
    live("/workflows", ObanPowertools.Web.WorkflowsLive, :index)
    live("/workflows/:id", ObanPowertools.Web.WorkflowsLive, :show)
    live("/jobs", ObanPowertools.Web.JobsLive, :index)
    live("/jobs/:id", ObanPowertools.Web.JobsLive, :show)
  end
```

**Apply:** Add `live("/batches", ObanPowertools.Web.BatchesLive, :index)` and `live("/batches/:id", ObanPowertools.Web.BatchesLive, :show)` inside this same live session. Keep the optional Oban Web bridge after the native routes.

### `lib/oban_powertools/web/selectors.ex` (utility, request-response)

**Analog:** `lib/oban_powertools/web/selectors.ex`

**Canonical path and query encoding pattern** (lines 37-64):
```elixir
@canonical_paths %{
  lifeline: "/ops/jobs/lifeline",
  forensics: "/ops/jobs/forensics",
  audit: "/ops/jobs/audit",
  limiters: "/ops/jobs/limiters",
  cron: "/ops/jobs/cron",
  jobs: "/ops/jobs/jobs"
}

def encode(destination, params) when is_atom(destination) do
  base = Map.fetch!(@canonical_paths, destination)

  query =
    params
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> URI.encode_query()

  if query == "", do: base, else: "#{base}?#{query}"
end
```

**Detail helper pattern** (lines 82-86):
```elixir
def jobs_path(params \\ []), do: encode(:jobs, params)

@doc "Returns the path for a specific job detail page."
def job_detail_path(id), do: "#{@canonical_paths.jobs}/#{id}"
```

**Apply:** Add `batches: "/ops/jobs/batches"`, `batches_path/1`, and `batch_detail_path/1`. Use keyword lists for query params where tests assert order.

### `lib/oban_powertools/web/live_auth.ex` (middleware, request-response)

**Analog:** `lib/oban_powertools/web/live_auth.ex`

**Permission message pattern** (lines 24-45):
```elixir
@permission_messages %{
  preview_repair:
    "Permission: read-only. You can inspect this Powertools-native incident, but you do not have permission to preview this Audited action.",
  execute_repair:
    "Permission: read-only. You can inspect this Powertools-native preview, but you do not have permission to execute this Audited action.",
  view_jobs:
    "Permission: read-only. You can inspect the Powertools-native job list, but mutation controls stay disabled until you receive broader permission.",
  view_job_detail:
    "Permission: read-only. You can inspect this Powertools-native job detail, but mutation controls stay disabled until you receive broader permission.",
  retry_job:
    "Permission: read-only. You can inspect this Powertools-native job, but you do not have permission to retry it."
}
```

**Authorization helpers** (lines 68-85):
```elixir
def authorize_page(socket, action, resource) do
  case Auth.authorization_outcome(Map.get(socket.assigns, :current_actor), action, resource) do
    :ok -> {:ok, socket}
    {:error, _reason} -> {:error, redirect(socket, to: "/")}
  end
end

def authorize_action(socket, action, resource, opts \\ []) do
  case Auth.authorization_outcome(Map.get(socket.assigns, :current_actor), action, resource) do
    :ok -> :ok
    {:error, _reason} -> {:error, Keyword.get(opts, :message, permission_message(action))}
  end
end
```

**Read-only banner pattern** (lines 46-60, 117-119):
```elixir
@page_read_only_banners %{
  jobs:
    "Permission: read-only. Job list stays visible, but mutation controls stay disabled until you receive broader permission.",
  job_detail:
    "Permission: read-only. Job detail stays visible, but retry, cancel, and discard controls stay disabled until you receive broader permission."
}

def page_read_only_banner(surface) do
  Map.fetch!(@page_read_only_banners, surface)
end
```

**Apply:** Add `:view_batches`, `:view_batch_detail`, `:retry_batch_jobs` or equivalent action copy, plus `:batches` and `:batch_detail` read-only banners. Use `authorize_page/3` in mount and `authorize_action/4` before preview/execute.

### `lib/oban_powertools/batches.ex` (service, CRUD)

**Analog:** `lib/oban_powertools/jobs.ex`

**Read-model boundary and explicit repo pattern** (lines 1-7, 38-44):
```elixir
defmodule ObanPowertools.Jobs do
  @moduledoc """
  Native job query context for the read-only job browse surface.

  This module is the single owner of all `oban_jobs` queries for the Phase 43 job browse
  surface. LiveView never queries the `oban_jobs` table directly — all reads go through this
  module (D-10).
  """

  # ...
  # - This module is read-only — it contains no calls to `Oban` runtime functions such as
  #   `Oban.cancel_job/1`, `Oban.retry_job/1`, or `Oban.drain_queue/2`.
  # - Callers pass the repo explicitly (first argument) following the convention established in
  #   `ObanPowertools.Cron` and `ObanPowertools.Lifeline`.
```

**Filter struct and offset pagination pattern** (lines 47-96):
```elixir
import Ecto.Query

defstruct state: :available,
          queue: nil,
          worker: nil,
          tags: nil,
          page: 1,
          page_size: 20

def list(repo, %__MODULE__{} = filter, _opts \\ []) do
  offset = (filter.page - 1) * filter.page_size

  Oban.Job
  |> where([j], j.state == ^to_string(filter.state))
  |> maybe_filter_queue(filter.queue)
  |> maybe_filter_worker(filter.worker)
  |> maybe_filter_tags(filter.tags)
  |> order_by([j], desc: j.scheduled_at, desc: j.id)
  |> limit(^filter.page_size)
  |> offset(^offset)
  |> repo.all()
end
```

**Count map pattern** (lines 119-131):
```elixir
def count_by_state(repo, %__MODULE__{} = base_filter) do
  Map.new(@states, fn state ->
    count =
      Oban.Job
      |> where([j], j.state == ^state)
      |> maybe_filter_queue(base_filter.queue)
      |> maybe_filter_worker(base_filter.worker)
      |> maybe_filter_tags(base_filter.tags)
      |> select([j], count(j.id))
      |> repo.one()

    {state, count}
  end)
end
```

**Apply:** `Batches` should own list/detail/counts/blocked-state derivation and all joins across `Batch`, `BatchJob`, `Callback`, `Oban.Job`, `JobRecord`, and chain metadata. Keep it read-only and pass repo explicitly.

### `lib/oban_powertools/lifeline.ex` (service, CRUD)

**Analog:** `lib/oban_powertools/lifeline.ex`

**Action allowlist and preview/execute public API** (lines 23, 157-213):
```elixir
@supported_actions ~w(job_rescue job_retry job_cancel job_discard workflow_step_retry workflow_step_cancel workflow_request_cancel)

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
              preview.plan_hash == ^preview_attrs.plan_hash and
              preview.action == ^preview_attrs.action and
              preview.target_type == ^preview_attrs.target_type and
              preview.target_id == ^preview_attrs.target_id and preview.status == "ready",
          limit: 1
        )
      )

    preview = existing || repo.insert!(RepairPreview.changeset(%RepairPreview{}, preview_attrs))
    {:ok, preview}
  end
end

def execute_repair(repo, actor, preview_token, reason, opts \\ []) do
  now = Keyword.get(opts, :now, DateTime.utc_now())

  with %RepairPreview{} = preview <- repo.get_by(RepairPreview, preview_token: preview_token),
       :ok <- authorize(actor, :execute_repair, %{preview_token: preview.preview_token}),
       :ok <- ensure_preview_available(repo, preview, now),
       :ok <- validate_reason(reason, preview.reason_required),
       {:ok, current_hash} <- recompute_plan_hash(repo, preview),
       :ok <- ensure_not_drifted(repo, preview, current_hash, now),
       {:ok, result} <- apply_repair(repo, preview, actor, reason, now, opts) do
    {:ok, result}
  else
    nil -> {:error, :preview_not_found}
    error -> error
  end
end
```

**Target dispatch pattern** (lines 613-637):
```elixir
defp build_preview(repo, attrs, now) do
  action = fetch_value!(attrs, :action)
  target_type = fetch_value!(attrs, :target_type)
  target_id = fetch_value!(attrs, :target_id)

  if action not in @supported_actions do
    {:error, :unsupported_action}
  else
    incident = resolve_incident(repo, attrs)

    case {target_type, action} do
      {"job", action} when action in ["job_rescue", "job_retry", "job_cancel", "job_discard"] ->
        build_job_preview(repo, incident, target_id, action, now)
      {"workflow_step", action} when action in ["workflow_step_retry", "workflow_step_cancel"] ->
        build_workflow_step_preview(repo, incident, target_id, action, now)
      {"workflow", "workflow_request_cancel"} ->
        build_workflow_preview(repo, incident, target_id, action, now)
      _ ->
        {:error, :unsupported_target}
    end
  end
end
```

**Execution, audit, and drift pattern** (lines 1045-1139):
```elixir
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

defp apply_repair(repo, preview, actor, reason, now, opts) do
  trimmed_reason = String.trim(reason)

  Multi.new()
  |> Multi.run(:target, fn repo, _changes ->
    mutate_target(repo, preview, actor, trimmed_reason, now)
  end)
  |> Multi.update(:preview, RepairPreview.changeset(preview, %{status: "consumed", executed_at: now, consumed_at: now}))
  |> Multi.run(:audit, fn repo, %{preview: preview_record} ->
    Audit.record(
      "lifeline.repair_executed",
      %{type: TargetType.to_atom(preview.target_type), id: preview.target_id},
      %{"preview_token" => preview_record.preview_token, "reason" => trimmed_reason, "result" => "ok"},
      repo: repo,
      actor_id: Auth.actor_id(actor)
    )
  end)
  |> repo.transaction()
end
```

**Apply:** Add `callback_retry` to the action allowlist and `"callback"` target dispatch. Implement callback preview, recompute hash, and `mutate_target/5` clauses using the same preview-token, reason, drift, audit, and host follow-up flow. Do not mutate callbacks from LiveView.

### `lib/oban_powertools/lifeline/target_type.ex` (utility, transform)

**Analog:** `lib/oban_powertools/lifeline/target_type.ex`

**Closed enum pattern** (lines 1-39):
```elixir
defmodule ObanPowertools.Lifeline.TargetType do
  @moduledoc """
  Closed-enum dispatcher for Lifeline `target_type` string → atom conversion.
  """

  def to_atom("job"), do: :job
  def to_atom("workflow"), do: :workflow
  def to_atom("workflow_step"), do: :workflow_step
  def to_atom("step"), do: :step
end
```

**Apply:** Add `def to_atom("callback"), do: :callback`. Keep no catch-all; unknown values should still raise.

### `lib/oban_powertools/web/batches_live.ex` (component, request-response)

**Analog:** `lib/oban_powertools/web/jobs_live.ex`, with recovery detail from `lib/oban_powertools/web/lifeline_live.ex`

**Imports, mount, auth, display policy** (JobsLive lines 1-30):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.JobsLive do
    use Phoenix.LiveView

    alias ObanPowertools.{DisplayPolicy, JobRecord, Jobs, Lifeline}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}

    def mount(params, %{"oban_dashboard_path" => dashboard_path}, socket) do
      action = socket.assigns.live_action

      {permission, resource_type, resource_id} =
        case action do
          :show -> {:view_job_detail, :job, params["id"]}
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
```

**URL-backed index/detail and filter pattern** (JobsLive lines 36-64, 848-889):
```elixir
def handle_params(%{"id" => id}, _uri, socket) do
  {:noreply, load_job_detail(socket, id)}
end

def handle_params(params, _uri, socket) do
  case {connected?(socket), Map.get(params, "state")} do
    {true, nil} ->
      {:noreply, push_patch(socket, to: Selectors.jobs_path([{"state", "available"}]))}
    _ ->
      filter = filter_from_params(params)
      {:noreply, load_jobs(socket, filter)}
  end
end

def handle_event("select_state", %{"state" => state}, socket) do
  if state in @valid_states do
    filter = socket.assigns.filter
    new_filter = %{filter | state: String.to_existing_atom(state), page: 1}

    {:noreply,
     socket
     |> assign(:selected_jobs, MapSet.new())
     |> push_patch(to: Selectors.jobs_path(filter_path(new_filter)))}
  else
    {:noreply, socket}
  end
end
```

**Dense table-first layout and selected banner** (JobsLive lines 536-655):
```elixir
<div class="space-y-6 p-6">
  <div>
    <h1 class="text-2xl font-semibold">Jobs</h1>
    <p class="text-sm text-zinc-600">
      Browse and inspect Oban jobs by state. <%= ControlPlanePresenter.native_banner() %>
    </p>
  </div>

  <p :if={@read_only?} class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
    <%= LiveAuth.page_read_only_banner(:jobs) %>
  </p>

  <%= if MapSet.size(@selected_jobs) > 0 do %>
    <div class="flex items-center justify-between rounded-lg border border-indigo-200 bg-indigo-50 px-4 py-3">
      <span class="text-sm font-semibold text-indigo-800"><%= MapSet.size(@selected_jobs) %> jobs selected</span>
    </div>
  <% end %>

  <div class="overflow-hidden rounded-lg border bg-white">
    <table class="min-w-full divide-y">
      <thead class="bg-slate-50 text-left text-sm">
```

**Bulk preview/execute pattern** (JobsLive lines 231-269):
```elixir
def handle_event("execute_bulk", params, socket) do
  reason_from_params = Map.get(params, "reason")
  reason = String.trim(reason_from_params || socket.assigns.reason)
  action = socket.assigns.bulk_preview_action

  if reason == "" or is_nil(action) do
    {:noreply, socket}
  else
    actor = socket.assigns.current_actor

    {successes, failures} =
      Enum.reduce(socket.assigns.selected_jobs, {0, 0}, fn job_id, {succ, fail} ->
        case Lifeline.preview_repair(repo(), actor, %{
               incident_id: nil,
               action: action,
               target_type: "job",
               target_id: job_id
             }) do
          {:ok, preview} ->
            case Lifeline.execute_repair(repo(), actor, preview.preview_token, reason) do
              {:ok, _} -> {succ + 1, fail}
              _ -> {succ, fail + 1}
            end
          _ ->
            {succ, fail + 1}
        end
      end)

    socket =
      socket
      |> put_flash(:info, "Bulk action complete: #{successes} successes, #{failures} failures.")
      |> assign(:selected_jobs, MapSet.new())
      |> assign(:bulk_preview_action, nil)

    {:noreply, load_jobs(socket, socket.assigns.filter)}
  end
end
```

**Richer preview detail pattern** (LifelineLive lines 437-516):
```elixir
<section>
  <h3 class="text-sm font-medium">Proposed State Changes</h3>
  <div class="mt-2 rounded border bg-slate-50 p-3 text-sm">
    <%= if @preview do %>
      <p><strong>Plan Summary:</strong> <%= get_in(@preview.metadata, ["summary"]) %></p>
      <div><strong>Before:</strong> <%= state_copy(@preview.before_snapshot) %></div>
      <div class="mt-1"><strong>After:</strong> <%= state_copy(@preview.after_snapshot) %></div>
    <% else %>
      <p>Generate a preview to inspect operator-readable before and after state changes.</p>
    <% end %>
  </div>
</section>

<section>
  <h3 class="text-sm font-medium">Audit Record to be Written</h3>
  <div class="mt-2 rounded border bg-slate-50 p-3 text-sm">
    <p><strong>Actor:</strong> <%= preview_actor_label(@current_actor) %></p>
    <p class="mt-1"><strong>Action:</strong> <%= @selected_row.action %></p>
    <p class="mt-1"><strong>Audit Consequence:</strong> <%= LiveAuth.audit_consequence_copy() %></p>
    <p class="mt-1"><strong>Preview Status:</strong> <%= preview_status_copy(@preview) %></p>
    <p class="mt-1"><strong>Preview Token:</strong> <%= if @preview, do: repair_preview_value(@preview), else: "Generate preview first" %></p>
  </div>
</section>
```

**Apply:** Use `JobsLive` for URL/filter/selection/table/page-local bulk retry. Use `LifelineLive` for callback retry preview detail, preview status, reason gating, drift/expired/consumed/unauthorized errors, audit consequence, and manual intervention history.

### `test/oban_powertools/batches_test.exs` (test, CRUD)

**Analog:** `test/oban_powertools/jobs_test.exs`

**Read model test setup and list/filter assertions** (lines 1-31):
```elixir
defmodule ObanPowertools.JobsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.{Jobs, TestRepo}

  test "list/3 filters by state with state leading the WHERE clause" do
    available_job = insert_job!(%{}, worker: "MyApp.AvailableWorker", queue: :default)
    _executing_job = insert_job!(%{}, worker: "MyApp.ExecutingWorker", queue: :default, state: "executing")

    result = Jobs.list(TestRepo, %Jobs{state: :available})

    assert length(result) == 1
    assert hd(result).id == available_job.id
    assert hd(result).state == "available"
  end
end
```

**Pagination and count assertions** (lines 84-98, 118-143):
```elixir
test "list/3 paginates by page/page_size" do
  page1 = Jobs.list(TestRepo, %Jobs{state: :available, page: 1, page_size: 2})
  page2 = Jobs.list(TestRepo, %Jobs{state: :available, page: 2, page_size: 2})

  assert length(page1) == 2
  assert length(page2) == 1
  assert MapSet.disjoint?(MapSet.new(page1, & &1.id), MapSet.new(page2, & &1.id))
end

test "count_by_state/2 returns map with all 7 state keys including zero counts" do
  counts = Jobs.count_by_state(TestRepo, %Jobs{})
  assert Map.keys(counts) |> Enum.sort() == ["available", "cancelled", "completed", "discarded", "executing", "retryable", "scheduled"]
end
```

**Apply:** Create fixtures for `Batch`, `BatchJob`, `Callback`, and `Oban.Job`. Test list/detail/counts, blocked-state derivation, retry eligibility, chain context, and read-only query ownership.

### `test/oban_powertools/lifeline_callback_test.exs` (test, CRUD)

**Analog:** `test/oban_powertools/lifeline_test.exs`

**Preview/execute/reason/audit pattern** (lines 300-389):
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

  assert {:error, :reason_required} =
           Lifeline.execute_repair(repo(), actor, preview.preview_token, "   ")

  assert {:ok, %{target: repaired_job, preview: executed_preview}} =
           Lifeline.execute_repair(repo(), actor, preview.preview_token, "Rescuing the orphaned job after node loss")

  assert repaired_job.state == "available"
  assert executed_preview.status == "consumed"
  assert repair_audit_event.metadata["reason"] =~ "orphaned job"

  assert {:error, :preview_consumed} =
           Lifeline.execute_repair(repo(), actor, preview.preview_token, "Trying again after the preview was consumed")
end
```

**Unsupported target and unauthorized pattern** (lines 280-293, 467-489):
```elixir
assert {:error, :unsupported_target} =
         Lifeline.preview_repair(repo(), actor, %{
           action: "job_rescue",
           target_type: "workflow",
           target_id: "1"
         })

assert {:error, :unauthorized} =
         Lifeline.execute_repair(
           repo(),
           %{id: "operator-2", permissions: []},
           preview.preview_token,
           "Unauthorized operator should not retire the incident"
         )
```

**Apply:** Test `callback_retry` preview/execute for `failed` and expired-lease `claimed` callbacks, rejection for delivered/healthy pending callbacks, drift when callback state changes, consumed/expired previews, unauthorized actors, reason errors, audit rows with resource type `callback`, and callback row mutation shape.

### `test/oban_powertools/web/live/batches_live_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/web/live/jobs_live_test.exs`

**Existing LiveView test patterns to copy:** line references from grep/read:
- URL filter patches: `jobs_live_test.exs` lines 147-165, 193, 235.
- Single preview/execute flow: `jobs_live_test.exs` lines 665-724.
- Bulk preview/execute flow: `jobs_live_test.exs` lines 953-972.
- Lifeline preview-state errors: `lifeline_live_test.exs` lines 286-320 and 394-427.
- Read-only disabled behavior: `lifeline_live_test.exs` lines 498-521.

**Representative pattern** (`JobsLive` implementation lines 56-64, tested with `assert_patch`):
```elixir
def handle_event("select_state", %{"state" => state}, socket) do
  if state in @valid_states do
    filter = socket.assigns.filter
    new_filter = %{filter | state: String.to_existing_atom(state), page: 1}

    {:noreply,
     socket
     |> assign(:selected_jobs, MapSet.new())
     |> push_patch(to: Selectors.jobs_path(filter_path(new_filter)))}
  else
    {:noreply, socket}
  end
end
```

**Apply:** Cover index/detail rendering, `/ops/jobs/batches/:id`, URL-backed filters/tabs, page-local selection reset, read-only banners/disabled helper copy, bulk retry modal, callback retry modal, empty/load-error states, blocked-state copy, and Oban Web bridge links.

### `test/oban_powertools/web/router_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/web/router_test.exs`

**Route info assertion pattern** (lines 12-54):
```elixir
test "native powertools routes mount inside the ops/jobs shell" do
  assert %{
           plug: Phoenix.LiveView.Plug,
           phoenix_live_view: {ObanPowertools.Web.LifelineLive, :index, _, _}
         } =
           Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/lifeline", "localhost")

  assert %{
           plug: Phoenix.LiveView.Plug,
           phoenix_live_view: {ObanPowertools.Web.WorkflowsLive, :index, _, _}
         } =
           Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/workflows", "localhost")
end
```

**Apply:** Add assertions for `/ops/jobs/batches` -> `{BatchesLive, :index, _, _}` and `/ops/jobs/batches/:id` -> `{BatchesLive, :show, _, _}`.

### `test/oban_powertools/web/selectors_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/web/selectors_test.exs`

**Path and query encoding pattern** (lines 6-32):
```elixir
test "maps each named destination to its canonical path" do
  assert Selectors.lifeline_path([]) == "/ops/jobs/lifeline"
  assert Selectors.forensic_path([]) == "/ops/jobs/forensics"
  assert Selectors.audit_path([]) == "/ops/jobs/audit"
  assert Selectors.limiter_path([]) == "/ops/jobs/limiters"
  assert Selectors.cron_path([]) == "/ops/jobs/cron"
end

test "drops nil and empty string values before encoding" do
  result =
    Selectors.lifeline_path([{"view", "active"}, {"incident_fingerprint", nil}, {"step", ""}])

  assert result == "/ops/jobs/lifeline?view=active"
end
```

**Apply:** Add `batches_path/1` and `batch_detail_path/1` assertions, including nil/empty param dropping and keyword order preservation for batch filters.

### `test/oban_powertools/lifeline/target_type_test.exs` (test, transform)

**Analog:** `test/oban_powertools/lifeline/target_type_test.exs`

**Closed enum test pattern** (lines 6-25):
```elixir
test "maps each producer-bounded target_type string to the expected atom" do
  assert TargetType.to_atom("job") == :job
  assert TargetType.to_atom("workflow") == :workflow
  assert TargetType.to_atom("workflow_step") == :workflow_step
  assert TargetType.to_atom("step") == :step
end

test "raises FunctionClauseError for unknown target_type strings" do
  assert_raise FunctionClauseError, fn ->
    TargetType.to_atom("unknown")
  end
end
```

**Apply:** Add `"callback" -> :callback` assertion and keep the unknown-value raise assertions.

## Shared Patterns

### Batch and Callback Evidence Fields

**Source:** `lib/oban_powertools/batch.ex` lines 31-47 and `lib/oban_powertools/callback.ex` lines 11-29

```elixir
schema "oban_powertools_batches" do
  field(:name, :string)
  field(:status, :string, default: "executing")
  field(:total_count, :integer, default: 0)
  field(:success_count, :integer, default: 0)
  field(:discard_count, :integer, default: 0)
  field(:inserted_count, :integer, default: 0)
  field(:insert_chunk_count, :integer, default: 0)
  field(:insert_failed_chunk, :integer)
  field(:insert_failure, :map, default: %{})
  field(:insert_failed_at, :utc_datetime_usec)
  field(:completed_at, :utc_datetime_usec)
end

schema "oban_powertools_callbacks" do
  field(:event, :string)
  field(:dedupe_key, :string)
  field(:status, :string, default: "pending")
  field(:payload, :map, default: %{})
  field(:attempts, :integer, default: 0)
  field(:available_at, :utc_datetime_usec)
  field(:claimed_at, :utc_datetime_usec)
  field(:claimed_by, :string)
  field(:lease_expires_at, :utc_datetime_usec)
  field(:delivered_at, :utc_datetime_usec)
  field(:last_error, :string)
  belongs_to(:batch, ObanPowertools.Batch, type: :binary_id)
end
```

**Apply to:** `Batches` read model, `BatchesLive`, callback Lifeline preview/execute, and tests. Use these fields for `insert_failed`, `callback_failed`, stuck/expired callback, progress, and callback summary evidence.

### Callback Claim, Failure, and Lease Semantics

**Source:** `lib/oban_powertools/chain/progression.ex` lines 34-49 and 309-330

```elixir
repo.all(
  from(callback in Callback,
    where:
      callback.event == "chain.step_succeeded" and
        callback.status in ["pending", "failed", "claimed"] and
        (is_nil(callback.available_at) or callback.available_at <= ^now) and
        (is_nil(callback.lease_expires_at) or callback.lease_expires_at <= ^now),
    order_by: [asc: callback.available_at, asc: callback.inserted_at],
    limit: ^limit,
    lock: "FOR UPDATE SKIP LOCKED"
  )
)

defp mark_failed(repo, %Callback{} = row, now, reason) do
  repo.update!(
    Callback.changeset(row, %{
      status: "failed",
      attempts: row.attempts + 1,
      available_at: DateTime.add(now, 30, :second),
      lease_expires_at: nil,
      last_error: inspect(reason)
    })
  )
end
```

**Apply to:** callback retry eligibility and drift checks. Eligible recovery states are failed callbacks and claimed callbacks whose lease is expired; delivered and healthy pending callbacks must not show execute controls.

### Chain Context and Output Failure Evidence

**Source:** `lib/oban_powertools/chain/progression.ex` lines 117-146 and 241-253

```elixir
meta =
  (Map.get(step, "meta") || %{})
  |> Map.merge(%{
    "batch_id" => fetch_payload!(payload, "batch_id"),
    "chain_id" => fetch_payload!(payload, "chain_id"),
    "chain_step_name" => fetch_descriptor!(step, "name"),
    "chain_step_index" => fetch_descriptor!(step, "index"),
    "chain_step_count" => fetch_payload!(payload, "step_count"),
    "upstream_job_id" => fetch_payload!(payload, "upstream_job_id"),
    "chain_progression_key" => progression_key
  })

defp resolve_args(repo, %{"args_builder" => %{} = builder}, payload) do
  upstream_job_id = fetch_payload!(payload, "upstream_job_id")

  with {:ok, upstream_payload} <- Chain.fetch_upstream_result(repo, upstream_job_id),
       {:ok, module} <- builder_module(builder),
       {:ok, function} <- builder_function(builder),
       :ok <- safe_builder?(module),
       {:ok, args} <- apply_builder(module, function, upstream_payload, Map.get(builder, "extra_args") || []) do
    args
  else
    {:error, reason} -> throw({:chain_args_builder_failed, reason})
  end
end
```

**Apply to:** chain badge, chain context detail, upstream job id, step index/count, output-unavailable/output-expired blocked-state explanations.

### Display Redaction

**Source:** `lib/oban_powertools/web/jobs_live.ex` lines 739-751

```elixir
%Oban.Job{} = job ->
  args_display = DisplayPolicy.render_job_field(:job_args, job.args, %{job: job})
  meta_display = DisplayPolicy.render_job_field(:job_meta, job.meta, %{job: job})
  recorded_output = recorded_output_display(job)
  redacted_fields = get_in(job.meta || %{}, ["__redacted_fields__"]) || []

  socket
  |> assign(:args_display, args_display)
  |> assign(:meta_display, meta_display)
  |> assign(:recorded_output, recorded_output)
  |> assign(:redacted_fields, redacted_fields)
```

**Apply to:** failed member args/meta/error-like payloads, callback payloads/last_error, and recorded output evidence. Do not render raw sensitive payloads by default.

### LiveView Event Validation

**Source:** `lib/oban_powertools/web/jobs_live.ex` lines 94-111 and 848-863

```elixir
def handle_event("toggle_job", %{"id" => id_str}, socket) do
  case Integer.parse(id_str) do
    {id, ""} ->
      selected_jobs = socket.assigns.selected_jobs
      selected_jobs =
        if MapSet.member?(selected_jobs, id), do: MapSet.delete(selected_jobs, id), else: MapSet.put(selected_jobs, id)

      {:noreply, assign(socket, :selected_jobs, selected_jobs)}
    _invalid ->
      {:noreply, socket}
  end
end

state =
  if state_str in @valid_states do
    String.to_existing_atom(state_str)
  else
    :available
  end
```

**Apply to:** all batch status/filter/page/selection/callback events. Treat LiveView payloads as untrusted; use allowlists and parsing before atom conversion or service calls.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | n/a | n/a | All planned files have exact or role-match analogs. Callback-specific Lifeline target behavior has no exact existing target, but the `Lifeline` job/workflow target dispatcher is the correct extension point. |

## Metadata

**Analog search scope:** `lib/oban_powertools`, `lib/oban_powertools/web`, `test/oban_powertools`, `test/oban_powertools/web`
**Files scanned:** 94 files from `lib` and `test`
**Pattern extraction date:** 2026-06-14
