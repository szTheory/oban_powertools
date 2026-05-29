# Phase 43: Read-Only Job Browse - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 7 (2 new, 5 modified)
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/jobs.ex` | context (new) | CRUD / request-response | `lib/oban_powertools/cron.ex` | role-match |
| `lib/oban_powertools/web/jobs_live.ex` | LiveView (new) | request-response, CRUD | `lib/oban_powertools/web/workflows_live.ex` + `lib/oban_powertools/web/lifeline_live.ex` | exact |
| `lib/oban_powertools/web/router.ex` | config (modify) | — | itself | exact |
| `lib/oban_powertools/web/live_auth.ex` | middleware (modify) | — | itself | exact |
| `lib/oban_powertools/runtime_config.ex` | utility (modify) | — | itself (DisplayPolicy section) | exact |
| `lib/oban_powertools/web/selectors.ex` | utility (modify) | — | itself | exact |
| `test/oban_powertools/web/live/jobs_live_test.exs` | test (new) | — | `test/oban_powertools/web/live/workflows_live_test.exs` | exact |
| `test/oban_powertools/jobs_test.exs` | test (new) | — | `test/oban_powertools/lifeline_test.exs` | role-match |

---

## Pattern Assignments

### `lib/oban_powertools/jobs.ex` (context, CRUD)

**Analog:** `lib/oban_powertools/cron.ex` (same context-module shape: repo as first arg, no process state)

**Module declaration and imports pattern** (cron.ex lines 1-12):
```elixir
defmodule ObanPowertools.Cron do
  @moduledoc """
  Durable cron entry sync, slot claim, and operator actions.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias ObanPowertools.{Audit, Telemetry}
  alias ObanPowertools.Cron.{Entry, Slot}
```

For `ObanPowertools.Jobs`, the equivalent opening:
```elixir
defmodule ObanPowertools.Jobs do
  @moduledoc """
  Native job query context for the read-only job browse surface.

  ## Tags Filtering and GIN Index
  ...
  """

  import Ecto.Query
```

**Context function signature pattern** — repo is always first arg, no process state. Every public function in `cron.ex` follows `def func(repo, ...)`. The same rule applies to `Jobs.list/3`, `Jobs.get/2`, `Jobs.count_by_state/2`.

**Ecto query composition pattern** (cron.ex — pattern for conditional filters):
```elixir
# From cron.ex — state leads WHERE; optional filters chained with maybe_ helpers
# Jobs.list/3 must follow the same shape:
Oban.Job
|> where([j], j.state == ^to_string(filter.state))
|> maybe_filter_queue(filter.queue)
|> maybe_filter_worker(filter.worker)
|> maybe_filter_tags(filter.tags)
|> order_by([j], [desc: j.scheduled_at, desc: j.id])
|> limit(^filter.page_size)
|> offset(^offset)
|> repo.all()
```

**defp maybe_ guard pattern** — nil-pass clause first, active clause second:
```elixir
defp maybe_filter_queue(query, nil), do: query
defp maybe_filter_queue(query, queue), do: where(query, [j], j.queue == ^queue)
```

**repo/0 private helper** (from `workflows_live.ex` line 472, `lifeline_live.ex` line 1273):
```elixir
defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
```
The `ObanPowertools.Jobs` context module accepts `repo` as the first argument (caller passes it); there is no internal `repo/0` helper inside the context module. The LiveView calls `repo()` locally and passes it in.

---

### `lib/oban_powertools/web/jobs_live.ex` (LiveView, request-response)

**Primary analog:** `lib/oban_powertools/web/workflows_live.ex` — double-route single-module skeleton

**Secondary analog:** `lib/oban_powertools/web/lifeline_live.ex` — `push_patch` / `handle_params` filter flow, `@read_only?` assign, `timestamp_copy/1`

**Module declaration and `use` pattern** (workflows_live.ex lines 1-11):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.WorkflowsLive do
    @moduledoc false

    use Phoenix.LiveView

    import Ecto.Query

    alias ObanPowertools.{ControlPlane, DisplayPolicy, Explain}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}
```

For `JobsLive` the aliased modules will differ but the outer `if Code.ensure_loaded?` guard, `@moduledoc false`, `use Phoenix.LiveView`, and the `alias` style are identical.

**`mount/3` auth pattern** (workflows_live.ex lines 14-39, adapted for two-permission split per D-17/D-18):
```elixir
@impl true
def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
  with {:ok, socket} <-
         LiveAuth.authorize_page(socket, :view_workflows, %{type: :page, id: "workflows"}) do
    :ok = DisplayPolicy.assert_configured!()

    {:ok,
     socket
     |> assign(:oban_dashboard_path, dashboard_path)
     |> assign(:workflows, [])
     ...}
  else
    {:error, socket} -> {:ok, socket}
  end
end
```

For `JobsLive`, `mount/3` must branch on `socket.assigns.live_action` before the `with`:
```elixir
@impl true
def mount(params, %{"oban_dashboard_path" => dashboard_path}, socket) do
  action = socket.assigns.live_action
  permission = if action == :show, do: :view_job_detail, else: :view_jobs
  resource_id = if action == :show, do: params["id"], else: "jobs"
  resource_type = if action == :show, do: :job, else: :page

  with {:ok, socket} <-
         LiveAuth.authorize_page(socket, permission, %{type: resource_type, id: resource_id}) do
    :ok = DisplayPolicy.assert_configured!()
    {:ok, socket |> assign(:oban_dashboard_path, dashboard_path) |> assign_defaults()}
  else
    {:error, socket} -> {:ok, socket}
  end
end
```

**`handle_params/3` dispatch pattern** (workflows_live.ex lines 42-61):
```elixir
@impl true
def handle_params(params, _uri, socket) do
  socket = load_workflows(socket)

  case Map.get(params, "id") do
    nil ->
      {:noreply,
       socket
       |> assign(:workflow, nil)
       ...}

    workflow_id ->
      {:noreply, load_workflow_detail(socket, workflow_id, Map.get(params, "step"))}
  end
end
```

For `JobsLive`, `handle_params/3` additionally handles the missing-state redirect (Pitfall 2 from RESEARCH.md):
```elixir
@impl true
def handle_params(%{"id" => id}, _uri, socket) do
  {:noreply, load_job_detail(socket, id)}
end

def handle_params(params, _uri, socket) do
  case Map.get(params, "state") do
    nil ->
      {:noreply, push_patch(socket, to: Selectors.jobs_path([{"state", "available"}]))}
    _state ->
      {:noreply, load_jobs(socket, filter_from_params(params))}
  end
end
```

**`push_patch` filter event pattern** (lifeline_live.ex lines 60-72):
```elixir
def handle_event("toggle_view", %{"view" => view}, socket) do
  {:noreply,
   socket
   |> assign(:success_message, nil)
   |> push_patch(
     to:
       selection_path(%{
         view: view,
         row_id: socket.assigns.selected_row && socket.assigns.selected_row.id,
         incident_fingerprint: selected_fingerprint(socket.assigns.selected_row)
       })
   )}
end
```

For `JobsLive`, tab click and filter select events follow this same shape:
```elixir
def handle_event("select_state", %{"state" => state}, socket) do
  filter = socket.assigns.filter
  {:noreply,
   push_patch(socket,
     to: Selectors.jobs_path([{"state", state}, {"queue", filter.queue}, {"worker", filter.worker}])
   )}
end
```

**`@read_only?` assign pattern** (lifeline_live.ex lines 645, 1261-1271):
```elixir
# In load_data/2:
|> assign(:read_only?, read_only_page?(socket.assigns.current_actor, visible_incident_rows))

# Helper:
defp read_only_page?(actor, rows) do
  checks = Enum.flat_map(rows, fn row ->
    [{:preview_repair, row.resource}, {:execute_repair, row.resource}]
  end)
  rows != [] and not LiveAuth.any_authorized?(actor, checks)
end
```

For `JobsLive` (read-only in Phase 43, no mutations), `@read_only?` is always `false` for `:index` and the banner is only shown when `LiveAuth.authorized?` returns false for the broader job mutation permissions (Phase 44 will toggle this properly). The pattern for rendering the banner remains the same conditional:
```elixir
# In render/1:
<p :if={@read_only?} class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
  <%= LiveAuth.page_read_only_banner(:jobs) %>
</p>
```

**`timestamp_copy/1` helper** (lifeline_live.ex lines 1072-1096) — copy verbatim for date rendering in job list and detail:
```elixir
defp timestamp_copy(nil), do: "Unknown"

defp timestamp_copy(%NaiveDateTime{} = timestamp) do
  timestamp
  |> DateTime.from_naive!("Etc/UTC")
  |> timestamp_copy()
end

defp timestamp_copy(%DateTime{} = timestamp) do
  seconds = DateTime.diff(DateTime.utc_now(), timestamp, :second)

  relative =
    cond do
      seconds < 60 -> "#{seconds}s ago"
      seconds < 3_600 -> "#{div(seconds, 60)}m ago"
      seconds < 86_400 -> "#{div(seconds, 3_600)}h ago"
      true -> "#{div(seconds, 86_400)}d ago"
    end

  exact = Calendar.strftime(timestamp, "%Y-%m-%d %H:%M:%S UTC")
  "#{relative} (#{exact})"
end

defp timestamp_copy(timestamp) when is_binary(timestamp), do: timestamp
defp timestamp_copy(_timestamp), do: "Unknown"
```

**`repo/0` private helper** (workflows_live.ex line 472, lifeline_live.ex line 1273):
```elixir
defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
```

**`selection_path` / filter-path builder pattern** (lifeline_live.ex lines 867-876):
```elixir
defp selection_path(selection) do
  Selectors.lifeline_path([
    {"view", Map.get(selection, :view)},
    {"incident_fingerprint", Map.get(selection, :incident_fingerprint)},
    ...
  ])
end
```

For `JobsLive`, the equivalent uses `Selectors.jobs_path/1`:
```elixir
defp filter_path(filter) do
  Selectors.jobs_path([
    {"state", filter.state},
    {"queue", filter.queue},
    {"worker", filter.worker},
    {"tags", filter.tags && Enum.join(filter.tags, ",")}
  ])
end
```

**`filter_from_params/1` pattern** (lifeline_live.ex lines 1276-1285):
```elixir
defp selection_from_params(params) do
  %{
    view: params["view"],
    row_id: params["row-id"],
    incident_fingerprint: params["incident_fingerprint"],
    ...
  }
end
```

For `JobsLive`, the equivalent builds a `%JobFilter{}`:
```elixir
defp filter_from_params(params) do
  tags =
    case Map.get(params, "tags") do
      nil -> nil
      "" -> nil
      str -> str |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
    end

  %ObanPowertools.Jobs{
    state: String.to_existing_atom(Map.get(params, "state", "available")),
    queue: Map.get(params, "queue"),
    worker: Map.get(params, "worker"),
    tags: tags,
    page: String.to_integer(Map.get(params, "page", "1")),
    page_size: 20
  }
end
```

**Table row and badge class pattern** (lifeline_live.ex lines 269-329 for table, lines 955-968 for badges):
```elixir
<table class="min-w-full divide-y">
  <thead class="bg-slate-50 text-left text-sm">
    <tr>
      <th class="px-4 py-3 font-medium">...</th>
    </tr>
  </thead>
  <tbody class="divide-y text-sm">
    <tr :for={row <- @rows} class={["align-top", if(selected?, do: "bg-indigo-50", else: "bg-white")]}>
      <td class="px-4 py-3">...</td>
    </tr>
  </tbody>
</table>
```

---

### `lib/oban_powertools/web/router.ex` (config, modify)

**Analog:** itself — additive route insertion only

**Existing `live_session` block** (router.ex lines 53-64):
```elixir
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
end
```

**Insertion point:** Add two lines inside the `do` block, after the `/workflows/:id` line, following the `WorkflowsLive` double-route pattern exactly:
```elixir
live("/jobs", ObanPowertools.Web.JobsLive, :index)
live("/jobs/:id", ObanPowertools.Web.JobsLive, :show)
```

Do NOT create a new `live_session`. Do NOT change the existing routes.

---

### `lib/oban_powertools/web/live_auth.ex` (middleware, modify)

**Analog:** itself — additive map extension only

**`@permission_messages` module attribute** (live_auth.ex lines 24-35):
```elixir
@permission_messages %{
  pause_cron_entry: "Permission: read-only. You can inspect this Powertools-native cron entry, but you do not have permission to preview or execute this Audited action.",
  resume_cron_entry: "Permission: read-only. ...",
  run_cron_entry: "Permission: read-only. ...",
  preview_repair: "Permission: read-only. You can inspect this Powertools-native incident, but you do not have permission to preview this Audited action.",
  execute_repair: "Permission: read-only. You can inspect this Powertools-native preview, but you do not have permission to execute this Audited action."
}
```

**Atoms to add** (D-20): `:view_jobs`, `:view_job_detail`, `:retry_job`, `:cancel_job`, `:discard_job`

Voice pattern — match existing entries exactly. New permission message entries:
```elixir
view_jobs:
  "Permission: read-only. You can inspect the Powertools-native job list, but mutation controls stay disabled until you receive broader permission.",
view_job_detail:
  "Permission: read-only. You can inspect this Powertools-native job detail, but mutation controls stay disabled until you receive broader permission.",
retry_job:
  "Permission: read-only. You can inspect this Powertools-native job, but you do not have permission to retry it.",
cancel_job:
  "Permission: read-only. You can inspect this Powertools-native job, but you do not have permission to cancel it.",
discard_job:
  "Permission: read-only. You can inspect this Powertools-native job, but you do not have permission to discard it."
```

**`@page_read_only_banners` module attribute** (live_auth.ex lines 36-47):
```elixir
@page_read_only_banners %{
  cron:    "Permission: read-only. Powertools-native cron stays visible, but preview, reason, and Audited action controls stay disabled until you receive broader permission.",
  lifeline: "Permission: read-only. Powertools-native incident evidence stays visible, but preview, reason, and Audited action controls stay disabled until you receive broader permission.",
  audit:   "Permission: read-only. This page is the cross-surface audit destination. Powertools-native pages keep preview, reason, and local audit evidence close to the acted-on resource.",
  workflows: "Permission: read-only. Diagnose workflow causality here, but use Powertools-native pages for preview, reason, and Audited action controls.",
  forensics: "Permission: read-only. Powertools-native forensic bundles stay visible, while scoped audit follow-up remains Inspection only."
}
```

**Atoms to add** (D-19): `:jobs`, `:job_detail`

Planner-drafted banner copy following the established voice (short banner, present-tense, "stays visible" framing):
```elixir
jobs:
  "Permission: read-only. Job list stays visible, but mutation controls stay disabled until you receive broader permission.",
job_detail:
  "Permission: read-only. Job detail stays visible, but retry, cancel, and discard controls stay disabled until you receive broader permission."
```

**Critical:** `Map.fetch!(@page_read_only_banners, surface)` raises `KeyError` at runtime if `:jobs` or `:job_detail` are absent. The edit to `live_auth.ex` MUST precede any LiveView render that calls `page_read_only_banner/1`.

---

### `lib/oban_powertools/runtime_config.ex` — `ObanPowertools.DisplayPolicy` section (utility, modify)

**Analog:** itself — additive helper only

**`render_text/4` internal primitive** (runtime_config.ex lines 136-142):
```elixir
defp render_text(kind, value, context, fallback) do
  case apply_policy(kind, value, context) do
    nil -> fallback.()
    text when is_binary(text) -> text
    other -> raise ArgumentError, invalid_return_message(kind, other)
  end
end
```

**`apply_policy/3` internal primitive** (runtime_config.ex lines 144-151):
```elixir
defp apply_policy(kind, value, context) do
  module = policy_module!()

  case module.display(kind, value, context) do
    nil -> nil
    rendered -> rendered
  end
end
```

**New `render_job_field/3` public helper to add** — follows `render_text/4` shape but supports the three-variant return contract (nil → raw JSON, String → string, Map → raw JSON):
```elixir
def render_job_field(kind, value, context) do
  case apply_policy(kind, value, context) do
    nil ->
      {:raw_json, Jason.encode!(value || %{}, pretty: true)}

    text when is_binary(text) ->
      {:string, text}

    %{} = redacted_map ->
      {:raw_json, Jason.encode!(redacted_map, pretty: true)}

    other ->
      raise ArgumentError, invalid_return_message(kind, other)
  end
rescue
  _ -> {:fallback, "[redacted]"}
end
```

**HEEX rendering of the tagged tuple** (to be used in `JobsLive` render/1):
```heex
<%# {:raw_json, json} or {:string, text} %>
<pre class="text-sm bg-slate-50 p-3 rounded overflow-x-auto"><%= elem(@args_display, 1) %></pre>

<%# {:fallback, msg} %>
<span :if={match?({:fallback, _}, @args_display)} class="text-zinc-500">
  <%= elem(@args_display, 1) %>
</span>
```

---

### `lib/oban_powertools/web/selectors.ex` (utility, modify)

**Analog:** itself — additive entry only

**`@canonical_paths` module attribute** (selectors.ex lines 37-43):
```elixir
@canonical_paths %{
  lifeline: "/ops/jobs/lifeline",
  forensics: "/ops/jobs/forensics",
  audit: "/ops/jobs/audit",
  limiters: "/ops/jobs/limiters",
  cron: "/ops/jobs/cron"
}
```

**Add `:jobs` entry:**
```elixir
@canonical_paths %{
  lifeline: "/ops/jobs/lifeline",
  forensics: "/ops/jobs/forensics",
  audit: "/ops/jobs/audit",
  limiters: "/ops/jobs/limiters",
  cron: "/ops/jobs/cron",
  jobs: "/ops/jobs/jobs"
}
```

**`jobs_path/1` helper to add** — mirrors `lifeline_path/1` (selectors.ex line 67) exactly:
```elixir
@doc "Returns the `/ops/jobs/jobs` path with the given params encoded."
def jobs_path(params \\ []), do: encode(:jobs, params)
```

**Detail path construction** — inline, not via `Selectors`, matching `WorkflowsLive` precedent (workflows_live.ex line 118):
```elixir
# WorkflowsLive uses:
<.link navigate={"/ops/jobs/workflows/#{workflow.id}"} ...>

# JobsLive uses:
<.link navigate={"/ops/jobs/jobs/#{job.id}"} ...>
```

**`encode/2` nil-dropping behavior** (selectors.ex lines 51-63) — nil and `""` values are dropped automatically; filter params with nil values need not be guarded by callers:
```elixir
def encode(destination, params) when is_atom(destination) do
  base = Map.fetch!(@canonical_paths, destination)

  query =
    params
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> URI.encode_query()

  if query == "" do
    base
  else
    "#{base}?#{query}"
  end
end
```

---

### `test/oban_powertools/web/live/jobs_live_test.exs` (test, new)

**Analog:** `test/oban_powertools/web/live/workflows_live_test.exs`

**Test module structure with inline display policy** (workflows_live_test.exs lines 1-43):
```elixir
defmodule ObanPowertools.Web.JobsLiveTestDisplayPolicy do
  def display(:job_args, _value, _context), do: nil
  def display(:job_meta, _value, _context), do: nil
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertools.Web.JobsLiveTest do
  use ObanPowertools.LiveCase, async: false

  setup do
    original_display_policy = Application.get_env(:oban_powertools, :display_policy)

    Application.put_env(
      :oban_powertools,
      :display_policy,
      ObanPowertools.Web.JobsLiveTestDisplayPolicy
    )

    on_exit(fn ->
      Application.put_env(:oban_powertools, :display_policy, original_display_policy)
    end)

    :ok
  end
```

**Unauthorized redirect test pattern** (workflows_live_test.exs lines 295-298):
```elixir
test "redirects unauthorized viewers", %{conn: conn} do
  conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-2", permissions: []})
  assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/jobs")
end
```

**Authorized page render test pattern** (workflows_live_test.exs lines 44-69):
```elixir
test "renders ...", %{conn: conn} do
  conn =
    Plug.Test.init_test_session(conn,
      current_actor: %{id: "ops-1", permissions: [:view_jobs]}
    )

  {:ok, view, html} = live(conn, "/ops/jobs/jobs?state=available")
  assert html =~ "Jobs"
  assert has_element?(view, "...")
end
```

**Read-only banner test pattern** (workflows_live_test.exs line 57):
```elixir
assert html =~ "Permission: read-only."
```

---

### `test/oban_powertools/jobs_test.exs` (test, new)

**Analog:** `test/oban_powertools/lifeline_test.exs`

**Test module structure** (lifeline_test.exs lines 15-35):
```elixir
defmodule ObanPowertools.JobsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Jobs

  # helper to insert Oban.Job records for test:
  defp insert_job!(attrs \\ []) do
    %{
      worker: Keyword.get(attrs, :worker, "MyApp.TestWorker"),
      queue: Keyword.get(attrs, :queue, "default"),
      state: Keyword.get(attrs, :state, "available"),
      args: Keyword.get(attrs, :args, %{})
    }
    |> Oban.Job.new()
    |> TestRepo.insert!()
  end
```

**Test patterns to cover** (from RESEARCH.md validation architecture):
- `Jobs.list/3` — state leads WHERE clause (assert no query without `WHERE state =`)
- `Jobs.list/3` — optional queue/worker/tags filters narrow results
- `Jobs.list/3` — pagination via page/page_size
- `Jobs.count_by_state/2` — returns map with all 7 states
- `Jobs.get/2` — returns job by ID

---

## Shared Patterns

### `DisplayPolicy.assert_configured!()` in mount

**Source:** `lib/oban_powertools/web/lifeline_live.ex` line 18, `lib/oban_powertools/web/workflows_live.ex` line 17

**Apply to:** `JobsLive.mount/3` — call immediately after the `LiveAuth.authorize_page/3` succeeds, before any data load:
```elixir
with {:ok, socket} <- LiveAuth.authorize_page(socket, permission, resource) do
  :ok = DisplayPolicy.assert_configured!()
  ...
```

### `LiveAuth.authorize_page/3` auth gate

**Source:** `lib/oban_powertools/web/live_auth.ex` lines 54-61

**Apply to:** `JobsLive.mount/3`
```elixir
def authorize_page(socket, action, resource) do
  case Auth.authorization_outcome(Map.get(socket.assigns, :current_actor), action, resource) do
    :ok -> {:ok, socket}
    {:error, _reason} -> {:error, redirect(socket, to: "/")}
  end
end
```

The `with` / `else {:error, socket} -> {:ok, socket}` pattern is required — do not unwrap `authorize_page` differently.

### `oban_dashboard_path` session assign injection

**Source:** `lib/oban_powertools/web/router.ex` lines 53-55 and every LiveView `mount/3`

**Apply to:** `JobsLive.mount/3` — the `%{"oban_dashboard_path" => dashboard_path}` session pattern destructuring is required:
```elixir
def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
  ...
  |> assign(:oban_dashboard_path, dashboard_path)
```

Use `@oban_dashboard_path` for path construction that needs the outer host scope (e.g., linking to the Oban Web bridge).

### Read-only banner rendering

**Source:** `lib/oban_powertools/web/lifeline_live.ex` lines 212-214

**Apply to:** `JobsLive` render/1 (both `:index` and `:show` actions)
```heex
<p :if={@read_only?} class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
  <%= LiveAuth.page_read_only_banner(:jobs) %>
</p>
```

Use `:jobs` for `:index` action, `:job_detail` for `:show` action.

### `if Code.ensure_loaded?(Phoenix.LiveView)` guard

**Source:** `lib/oban_powertools/web/workflows_live.ex` line 1, `lib/oban_powertools/web/lifeline_live.ex` line 1

**Apply to:** `lib/oban_powertools/web/jobs_live.ex` — wrap the entire module in this guard.

### Test sandbox checkout

**Source:** `test/support/live_case.ex` lines 16-24 (LiveView tests), `test/support/data_case.ex` (unit tests)

**Apply to:** `jobs_live_test.exs` uses `ObanPowertools.LiveCase, async: false`; `jobs_test.exs` uses `ObanPowertools.DataCase, async: false`.

---

## No Analog Found

All files in Phase 43 have strong analogs in the codebase. No files require falling back to RESEARCH.md patterns exclusively.

---

## Metadata

**Analog search scope:** `lib/oban_powertools/web/`, `lib/oban_powertools/`, `test/oban_powertools/web/live/`, `test/support/`
**Files scanned:** 14
**Pattern extraction date:** 2026-05-27
