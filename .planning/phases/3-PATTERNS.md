# Phase 3: Workflows (DAGs) & Signaling - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** 20
**Analogs found:** 17 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/workflow.ex` | service | CRUD | `lib/oban_powertools/idempotency.ex` + `lib/oban_powertools/cron.ex` | role-match |
| `lib/oban_powertools/workflow/workflow.ex` | model | CRUD | `lib/oban_powertools/cron/entry.ex` | role-match |
| `lib/oban_powertools/workflow/step.ex` | model | CRUD | `lib/oban_powertools/cron/slot.ex` | role-match |
| `lib/oban_powertools/workflow/edge.ex` | model | CRUD | `lib/oban_powertools/cron/slot.ex` | partial |
| `lib/oban_powertools/workflow/result.ex` | model | CRUD | `lib/oban_powertools/explain.ex` | partial |
| `lib/oban_powertools/workflow/coordinator.ex` | service | event-driven | `lib/oban_powertools/application.ex` + `lib/oban_powertools/telemetry.ex` | partial |
| `lib/oban_powertools/workflow/signal.ex` | utility | event-driven | `lib/oban_powertools/telemetry.ex` | partial |
| `lib/oban_powertools/application.ex` | config | event-driven | `lib/oban_powertools/application.ex` | exact |
| `lib/oban_powertools/explain.ex` | service | request-response | `lib/oban_powertools/explain.ex` | exact |
| `lib/oban_powertools/audit.ex` | utility | CRUD | `lib/oban_powertools/audit.ex` | exact |
| `lib/oban_powertools/telemetry.ex` | utility | event-driven | `lib/oban_powertools/telemetry.ex` | exact |
| `lib/oban_powertools/web/router.ex` | route | request-response | `lib/oban_powertools/web/router.ex` | exact |
| `lib/oban_powertools/web/engine_overview_live.ex` | component | request-response | `lib/oban_powertools/web/engine_overview_live.ex` | exact |
| `lib/oban_powertools/web/workflows_live.ex` | component | request-response | `lib/oban_powertools/web/limiters_live.ex` + `lib/oban_powertools/web/cron_live.ex` | role-match |
| `test/support/migrations/2_phase_3_tables.exs` | migration | CRUD | `test/support/migrations/1_phase_2_tables.exs` | exact |
| `test/oban_powertools/workflow_test.exs` | test | CRUD | `test/oban_powertools/cron_test.exs` | role-match |
| `test/oban_powertools/explain_test.exs` | test | request-response | `test/oban_powertools/explain_test.exs` | exact |
| `test/oban_powertools/telemetry_test.exs` | test | event-driven | `test/oban_powertools/telemetry_test.exs` | exact |
| `test/oban_powertools/web/live/workflows_live_test.exs` | test | request-response | `test/oban_powertools/web/live/limiters_live_test.exs` + `test/oban_powertools/web/live/cron_live_test.exs` | role-match |
| `test/oban_powertools/web/router_test.exs` | test | request-response | `test/oban_powertools/web/router_test.exs` | exact |

## Existing Modules Most Likely To Change

- `lib/oban_powertools/application.ex` for workflow coordinator supervision.
- `lib/oban_powertools/explain.ex` for workflow blocker codes, snapshots, and result-resolution explain payloads.
- `lib/oban_powertools/audit.ex` as the durable event sink for `workflow.*` lifecycle rows.
- `lib/oban_powertools/telemetry.ex` for `[:oban_powertools, :workflow, ...]` wrappers.
- `lib/oban_powertools/web/router.ex` for `/ops/jobs/workflows` index/detail routes.
- `lib/oban_powertools/web/engine_overview_live.ex` for workflow metrics and “next step” links.
- `test/support/migrations/1_phase_2_tables.exs` as the closest migration style reference; Phase 3 will need the same table/index conventions in a new migration file.
- `lib/oban_powertools/worker.ex` if workflow insertion stores standardized workflow metadata on child jobs the same way limits metadata is merged today.

## Pattern Assignments

### `lib/oban_powertools/workflow.ex` for public API, validation, and insert/progress transactions

**Analogs:** `lib/oban_powertools/worker.ex`, `lib/oban_powertools/idempotency.ex`, `lib/oban_powertools/cron.ex`

**Explicit public API shape** from `worker.ex` lines 6-11, 53-85:
```elixir
defmacro __using__(opts) do
  args_config = Keyword.get(opts, :args, [])
  limits_config = Keyword.get(opts, :limits, [])
  oban_opts = opts |> Keyword.delete(:args) |> Keyword.delete(:limits)
  validate_args_config!(args_config)
  normalized_limits = normalize_limits_config!(limits_config, __CALLER__.module)
```
```elixir
def validate(params) do
  %Args{}
  |> Args.changeset(params)
  |> case do
    %{valid?: true} = changeset -> {:ok, apply_changes(changeset)}
    changeset -> {:error, changeset}
  end
end

def enqueue(args, opts \\ []) do
  ObanPowertools.Idempotency.transaction(__MODULE__, args, opts)
end
```

**Atomic insert/progression flow** from `idempotency.ex` lines 54-107:
```elixir
Multi.new()
|> Multi.insert(:receipt, ...)
|> Multi.run(:job, fn repo, %{receipt: receipt} -> ... end)
|> Multi.run(:update_receipt, fn repo, %{job: job, receipt: receipt} -> ... end)
|> repo.transaction()
|> case do
  {:ok, %{job: job}} -> {:ok, job}
  {:error, :job, :conflict, _} -> {:conflict, existing_job}
  {:error, _name, reason, _} -> {:error, reason}
end
```

**Decision-in-transaction pattern** from `cron.ex` lines 42-88:
```elixir
Multi.new()
|> Multi.insert(:slot, ..., on_conflict: :nothing, conflict_target: [:entry_id, :slot_at], returning: true)
|> Multi.run(:current_slot, fn repo, _changes -> {:ok, repo.get_by!(Slot, ...)} end)
|> Multi.run(:decision, fn repo, %{slot: inserted_slot, current_slot: current_slot} -> ... end)
|> Multi.run(:job, fn repo, %{decision: decision} -> ... end)
|> Multi.run(:updated_slot, fn repo, %{decision: decision, job: job, current_slot: current_slot} -> ... end)
```

**Planner note**
- Treat `Workflow.new/1 |> add/3 |> add_many/3 |> connect/3 |> insert/2` as Phase 3’s equivalent of the worker API: explicit, grep-able, validation-first.
- Use one `Ecto.Multi` for insertion and another for step completion / child release. Do not split correctness-sensitive state changes across ad hoc repo calls.
- Return tagged tuples for non-runnable states (`{:blocked, blockers}`, `{:error, reason}`, `{:ok, workflow}`), not exceptions.

### `lib/oban_powertools/workflow/workflow.ex`, `step.ex`, `edge.ex`, `result.ex` for durable workflow schemas

**Analogs:** `lib/oban_powertools/cron/entry.ex`, `lib/oban_powertools/cron/slot.ex`, `lib/oban_powertools/explain.ex`

**Top-level definition schema** from `cron/entry.ex` lines 6-30:
```elixir
use Ecto.Schema
import Ecto.Changeset

@primary_key {:id, :binary_id, autogenerate: true}

schema "oban_powertools_cron_entries" do
  field(:name, :string)
  field(:source, :string)
  ...
  has_many(:slots, ObanPowertools.Cron.Slot, foreign_key: :entry_id)

  timestamps()
end
```

**Per-instance child ledger schema** from `cron/slot.ex` lines 11-24:
```elixir
schema "oban_powertools_cron_slots" do
  field(:slot_at, :utc_datetime_usec)
  field(:state, :string, default: "pending")
  field(:job_id, :integer)
  field(:policy_snapshot, :map, default: %{})
  field(:metadata, :map, default: %{})

  belongs_to(:entry, ObanPowertools.Cron.Entry, type: :binary_id)

  timestamps()
end
```

**Snapshot/result storage shape** from `explain.ex` lines 14-25 and 66-84:
```elixir
schema "oban_powertools_blocker_snapshots" do
  field(:job_id, :integer)
  field(:worker, :string)
  field(:status, :string, default: "blocked")
  field(:scope_kind, :string)
  field(:scope_id, :string)
  field(:blocker_codes, {:array, :string}, default: [])
  field(:details, :map, default: %{})
  field(:captured_at, :utc_datetime_usec)
```
```elixir
%__MODULE__{}
|> changeset(%{
  job_id: Keyword.get(opts, :job_id, 0),
  worker: limit_snapshot.worker,
  status: "blocked",
  ...
  details: %{"partition_key" => ..., "weight" => ..., "live_now" => ...},
  captured_at: now
})
|> repo.insert()
```

**Planner note**
- `Workflow` should hold logical definition + runtime summary, like `Entry`.
- `Step` should act like a durable execution ledger row, like `Slot`.
- `Edge` has no direct in-repo analog for graph topology. Copy the `belongs_to`/`binary_id`/`unique_constraint` mechanics from `Slot`, then add `from_step_id`, `to_step_id`, `policy`, and dependency snapshot fields.
- `Result` likewise has no direct analog. Use the `details`/`blocker_codes` style from `Explain` for persisted result payloads, redaction metadata, and retention markers.

### `lib/oban_powertools/workflow/coordinator.ex` and `application.ex` for coordinator supervision and signaling

**Analogs:** `lib/oban_powertools/application.ex`, `lib/oban_powertools/telemetry.ex`

**Supervisor insertion point** from `application.ex` lines 9-18:
```elixir
def start(_type, _args) do
  children = [
    # Starts a worker by calling: ObanPowertools.Worker.start_link(arg)
    # {ObanPowertools.Worker, arg}
  ]

  opts = [strategy: :one_for_one, name: ObanPowertools.Supervisor]
  Supervisor.start_link(children, opts)
end
```

**Event wrapper style** from `telemetry.ex` lines 9-30:
```elixir
def execute_operator_action(event_suffix, measurements \\ %{}, metadata \\ %{}) do
  :telemetry.execute([:oban_powertools, :operator_action, event_suffix], measurements, metadata)
end

def execute_cron_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
  :telemetry.execute([:oban_powertools, :cron, event_suffix], measurements, metadata)
end
```

**Planner note**
- There is no direct GenServer analog yet. Build a small coordinator supervised under `ObanPowertools.Supervisor`; keep Postgres as truth and Phoenix.PubSub as acceleration only.
- Mirror the telemetry wrapper style with `execute_workflow_event/3` rather than calling `:telemetry.execute/3` inline across the coordinator and service.
- The coordinator should respond to persisted step completion, then publish low-cardinality events such as `:step_completed`, `:step_unblocked`, and `:completed`.

### `lib/oban_powertools/explain.ex` for workflow blockers and node-detail explanations

**Analog:** `lib/oban_powertools/explain.ex`

**Explain return contract** from lines 50-63:
```elixir
%{
  status: if(live_now == [], do: :runnable, else: :blocked),
  blockers: live_now,
  live_now: live_now,
  snapshot_at_block_start: latest_snapshot(repo, inspect(worker_mod), snapshot)
}
```

**Snapshot persistence contract** from lines 66-84:
```elixir
%__MODULE__{}
|> changeset(%{
  status: "blocked",
  blocker_codes: Enum.map(blockers, & &1.code) |> Enum.sort(),
  details: %{
    "partition_key" => limit_snapshot.partition_key,
    "weight" => limit_snapshot.weight,
    "live_now" => Enum.map(blockers, &normalize_blocker/1)
  },
  captured_at: now
})
|> repo.insert()
```

**Live reconstruction pattern** from lines 128-173:
```elixir
resource_name = snapshot.scope_id
partition_key = get_in(snapshot.details, ["partition_key"]) || "__global__"
weight = get_in(snapshot.details, ["weight"]) || 1

...
state -> blockers_for(state, resource, %{weight: weight}, now)
```

**Planner note**
- Reuse the existing `status` / `blockers` / `live_now` / `snapshot_at_block_start` contract for workflow detail pages.
- Add explicit workflow blocker codes for missing dependency result, upstream retryable, terminal cascade-cancel, and unresolved dependency edge policy.
- Persist dependency snapshots on the child step so `explain_snapshot/2` can explain exact causality even after the graph moves on.

### `lib/oban_powertools/audit.ex` and `telemetry.ex` for workflow lifecycle visibility

**Analogs:** `lib/oban_powertools/audit.ex`, `lib/oban_powertools/telemetry.ex`

**Audit write/read pattern** from `audit.ex` lines 27-39 and 41-60:
```elixir
def record(action, resource, metadata \\ %{}, opts \\ []) do
  repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
  actor_id = Keyword.get(opts, :actor_id)

  %__MODULE__{}
  |> changeset(%{actor_id: actor_id, action: action, resource: normalize_resource(resource), metadata: metadata})
  |> repo.insert()
end
```
```elixir
repo.all(
  from(event in __MODULE__,
    where: event.resource == ^normalized,
    order_by: [desc: event.inserted_at]
  )
)
```

**Telemetry test pattern** from `test/oban_powertools/telemetry_test.exs` lines 4-47:
```elixir
:telemetry.attach("handler", [:oban_powertools, :limiter, :blocked], fn name, measurements, metadata, _config ->
  send(self(), {:limiter_event, name, measurements, metadata})
end, nil)

ObanPowertools.Telemetry.execute_limiter_event(:blocked, %{count: 1}, %{...})

assert_receive {:limiter_event, [:oban_powertools, :limiter, :blocked], %{count: 1}, %{...}}
```

**Planner note**
- Use `resource` strings like `workflow:<workflow_id>` and `workflow_step:<step_id>`.
- Keep telemetry metadata low-cardinality: action, status, blocker_code, edge_policy, source. Do not emit step names or workflow ids as labels.

### `lib/oban_powertools/web/router.ex`, `engine_overview_live.ex`, and `workflows_live.ex` for the native workflow UI

**Analogs:** `lib/oban_powertools/web/router.ex`, `lib/oban_powertools/web/engine_overview_live.ex`, `lib/oban_powertools/web/limiters_live.ex`, `lib/oban_powertools/web/cron_live.ex`, `lib/oban_powertools/web/live_auth.ex`

**Route mounting pattern** from `web/router.ex` lines 12-27:
```elixir
live_session :oban_powertools_native,
  on_mount: [ObanPowertools.Web.LiveAuth],
  session: %{"oban_dashboard_path" => unquote(path)} do
  live("/", ObanPowertools.Web.EngineOverviewLive, :index)
  live("/limiters", ObanPowertools.Web.LimitersLive, :index)
  live("/cron", ObanPowertools.Web.CronLive, :index)
  live("/audit", ObanPowertools.Web.AuditLive, :index)
end
```

**Page auth + shell metric pattern** from `engine_overview_live.ex` lines 14-25 and 76-90:
```elixir
with {:ok, socket} <-
       LiveAuth.authorize_page(socket, :view_overview, %{type: :page, id: "overview"}) do
  {:ok, assign_metrics(socket, dashboard_path)}
end
```
```elixir
metrics = %{
  resources: repo.aggregate(Resource, :count, :id),
  blocked_jobs: repo.aggregate(ObanPowertools.Explain, :count, :id),
  paused_entries: repo.aggregate(from(entry in Entry, where: not is_nil(entry.paused_at)), :count, :id),
  missed_slots: repo.aggregate(from(slot in Slot, where: slot.state == "skipped"), :count, :id)
}
```

**Master/detail read-only inspection pattern** from `limiters_live.ex` lines 32-62 and 119-165:
```elixir
def handle_event("inspect", %{"resource" => name}, socket) do
  snapshot = repo().one(from(event in Explain, where: event.scope_id == ^name, order_by: [desc: event.captured_at], limit: 1))
  ...
  {:noreply, socket |> assign(:selected_resource, name) |> assign(:detail, detail)}
end
```
```elixir
<%= if @detail do %>
  <h2 class="text-base font-semibold"><%= @selected_resource %></h2>
  ...
  <a :if={@detail.oban_job_path} href={@detail.oban_job_path}>Open generic job inspection in Oban Web</a>
<% end %>
```

**Preview-state pattern to copy only if Phase 3 adds any operator interaction later** from `cron_live.ex` lines 26-69 and 143-169:
```elixir
def handle_event("preview", %{"action" => action, "entry" => entry_name}, socket) do
  ...
  {:noreply, assign(socket, :preview, %{action: action, entry: entry})}
end
```

**Live auth helper** from `live_auth.ex` lines 15-29:
```elixir
def authorize_page(socket, action, resource) do
  if Auth.authorize(Map.get(socket.assigns, :current_actor), action, resource) do
    {:ok, socket}
  else
    {:error, redirect(socket, to: "/")}
  end
end
```

**Planner note**
- Phase 3 is read-only, so `WorkflowsLive` should copy `LimitersLive` more closely than `CronLive`: table on the left, selected workflow/node detail on the right, deep links to Oban Web jobs.
- Use router actions like `:index` and `:show` in the same LiveView if that keeps graph selection state stable across live updates.
- Add a workflow summary card/link on the overview page using the same `metric_card` / “Next Steps” structure.

### Tests and migrations

**Migration style** from `test/support/migrations/1_phase_2_tables.exs` lines 4-115:
```elixir
create table(:oban_powertools_cron_entries, primary_key: false) do
  add(:id, :uuid, primary_key: true)
  ...
  timestamps()
end

create(unique_index(:oban_powertools_cron_entries, [:name]))
create(index(:oban_powertools_cron_entries, [:source]))
```

**Service integration test style** from `test/oban_powertools/cron_test.exs` lines 28-118:
```elixir
assert {:ok, %{slot: %Slot{} = slot, job: %Oban.Job{} = job, decision: %{decision: "allow"}}} =
         Cron.claim_slot(repo(), entry, slot_at)

assert slot.job_id == job.id
```

**Explain/audit assertion style** from `test/oban_powertools/explain_test.exs` lines 21-52:
```elixir
explanation = Explain.explain(ExplainWorker, %{user_id: 10}, repo: repo())
assert explanation.status == :blocked
assert [%{code: "limit_reached"}] = explanation.live_now

[event | _] = Audit.list(%{type: :limiter, id: "explain-user-api"}, repo: repo())
assert event.action == "limiter.blocked"
```

**LiveView test style** from `test/oban_powertools/web/live/limiters_live_test.exs` lines 55-72 and `cron_live_test.exs` lines 44-91:
```elixir
{:ok, view, html} = live(conn, "/ops/jobs/limiters")
assert html =~ "Inspect Job Blockers"

html =
  view
  |> element("button[phx-value-resource='user-api']")
  |> render_click()
```

**Router test style** from `test/oban_powertools/web/router_test.exs` lines 11-35:
```elixir
assert %{plug: Phoenix.LiveView.Plug, phoenix_live_view: {ObanPowertools.Web.CronLive, :index, _, _}} =
         Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/cron", "localhost")
```

**Planner note**
- Add migration coverage for all new workflow tables in the test repo harness before service/UI tests.
- Service tests should assert normalized row creation, child unblocking, cascade-cancel behavior, and audit/telemetry side effects in one pass.
- LiveView tests should pin blocked-node copy, reason badges, and Oban Web deep links rather than CSS layout details.

## Shared Patterns

### Transactional State Changes
**Source:** `lib/oban_powertools/idempotency.ex:54-107`, `lib/oban_powertools/cron.ex:42-88`

Apply to workflow insertion, step completion, child release, and terminal propagation. Use `Ecto.Multi` plus explicit tagged-tuple result normalization.

### Audit Logging
**Source:** `lib/oban_powertools/audit.ex:27-39`

Apply to workflow inserted/completed/cancelled/unblocked events that materially affect operator understanding.

### Low-Cardinality Telemetry
**Source:** `lib/oban_powertools/telemetry.ex:9-30`

Add one wrapper per workflow event family. Keep labels coarse and leave high-cardinality evidence in workflow/result/snapshot rows.

### Explain-First UI
**Source:** `lib/oban_powertools/explain.ex:50-97`, `lib/oban_powertools/web/limiters_live.ex:119-165`

Show current status plus preserved “why” evidence side by side. The workflow detail page should answer what is blocked, why, and what dependency caused it.

### Auth-Gated LiveViews
**Source:** `lib/oban_powertools/web/live_auth.ex:15-29`

All new workflow pages should authorize in `mount/3` and redirect unauthorized viewers rather than rendering partial content.

## No Direct Analog Found

| File | Role | Data Flow | Gap | Planner Guidance |
|---|---|---|---|---|
| `lib/oban_powertools/workflow/coordinator.ex` | service | event-driven | No existing GenServer/PubSub runtime in repo | Keep the process thin: load durable state from Postgres, publish local acceleration events, and let service modules own DB mutations. |
| `lib/oban_powertools/workflow/edge.ex` | model | CRUD | No existing graph-edge schema | Copy `binary_id` / `belongs_to` / unique-index conventions from `Cron.Slot`; add graph-specific validation for duplicate edges, self-loops, and policy values. |
| `lib/oban_powertools/web/workflows_live.ex` DAG view internals | component | request-response | No graph rendering component exists | Reuse `LimitersLive` master/detail data loading first; keep the first graph renderer simple and stable, with selected-node detail driving most of the explanation payload. |

## Metadata

**Analog search scope:** `lib/oban_powertools/*.ex`, `lib/oban_powertools/cron/*.ex`, `lib/oban_powertools/web/*.ex`, `test/oban_powertools/**/*`, `test/support/migrations/*.exs`, `.planning/*`
**Files scanned:** 24
**Pattern extraction date:** 2026-05-19
