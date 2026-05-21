# Phase 8: Host Contract & Install Surface - Pattern Map

**Mapped:** 2026-05-21
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/oban_powertools.install.ex` | utility | file-I/O | `lib/mix/tasks/oban_powertools.install.ex` | exact |
| `lib/oban_powertools/runtime_config.ex` | utility | request-response | `lib/oban_powertools/runtime_config.ex` + `lib/oban_powertools/auth.ex` | exact |
| `lib/oban_powertools/application.ex` | provider | event-driven | `lib/oban_powertools/application.ex` + `lib/oban_powertools/workflow/coordinator.ex` | exact |
| `lib/oban_powertools/lifeline/heartbeat_writer.ex` | service | event-driven | `lib/oban_powertools/lifeline/heartbeat_writer.ex` | exact |
| `lib/oban_powertools/web/router.ex` | route | request-response | `lib/oban_powertools/web/router.ex` | exact |
| `lib/oban_powertools/web/live_auth.ex` | middleware | request-response | `lib/oban_powertools/web/live_auth.ex` | exact |
| `lib/oban_powertools/telemetry.ex` | utility | event-driven | `lib/oban_powertools/telemetry.ex` | exact |
| `test/mix/tasks/oban_powertools.install_test.exs` | test | file-I/O | `test/mix/tasks/oban_powertools.install_test.exs` | exact |
| `test/oban_powertools/auth_test.exs` | test | request-response | `test/oban_powertools/auth_test.exs` | exact |
| `test/oban_powertools/web/router_test.exs` | test | request-response | `test/oban_powertools/web/router_test.exs` + `test/support/test_router.ex` | exact |
| `test/oban_powertools/telemetry_test.exs` | test | event-driven | `test/oban_powertools/telemetry_test.exs` + `test/oban_powertools/workflow_coordinator_test.exs` | exact |
| `test/oban_powertools/application_test.exs` | test | event-driven | `test/oban_powertools/auth_test.exs` + `test/oban_powertools/workflow_coordinator_test.exs` | role-match |

## Pattern Assignments

### `lib/mix/tasks/oban_powertools.install.ex` (utility, file-I/O)

**Analog:** `lib/mix/tasks/oban_powertools.install.ex`

**Task pipeline pattern** (lines 13-21):
```elixir
def igniter(igniter) do
  igniter
  |> setup_auth_module()
  |> setup_runtime_config()
  |> setup_router_scope()
  |> setup_migration()
  |> setup_smart_engine_migrations()
  |> setup_workflow_migrations()
  |> setup_phase_4_migrations()
end
```

**Runtime config injection pattern** (lines 49-70):
```elixir
defp setup_runtime_config(igniter) do
  app_module = Igniter.Project.Module.module_name_prefix(igniter)
  web_module = Igniter.Libs.Phoenix.web_module(igniter)
  auth_module_name = Module.concat(web_module, "ObanPowertoolsAuth")

  Igniter.Project.Config.configure_group(
    igniter,
    "config.exs",
    :oban_powertools,
    [],
    [
      {[:repo], {:code, Macro.escape(Module.concat(app_module, "Repo"))}},
      {[:auth_module], {:code, Macro.escape(auth_module_name)}}
    ],
    comment: """
    Explicit Powertools host wiring:
```

**Router scope injection pattern** (lines 73-84):
```elixir
defp setup_router_scope(igniter) do
  router_contents = """
    require ObanPowertools.Web.Router
    ObanPowertools.Web.Router.oban_powertools_routes("/oban")
  """

  Igniter.Libs.Phoenix.add_scope(
    igniter,
    "/ops/jobs",
    router_contents,
    []
  )
end
```

**Apply to Phase 8**
- Keep install/config/router changes in the single `igniter/1` pipeline.
- Freeze any new host contract copy as explicit generated text or `configure_group` values, not implicit defaults.
- If supervision guidance needs generated config comments, add it adjacent to `setup_runtime_config/1` rather than in a second installer path.

---

### `lib/oban_powertools/runtime_config.ex` (utility, request-response)

**Analog:** `lib/oban_powertools/runtime_config.ex`

**Centralized config lookup pattern** (lines 8-22):
```elixir
def repo(opts \\ []) do
  Keyword.get(opts, :repo) || configured(:repo, opts)
end

def repo!(opts \\ []) do
  repo(opts ++ [required: true])
end

def auth_module(opts \\ []) do
  Keyword.get(opts, :auth_module) || configured(:auth_module, opts)
end

def auth_module!(opts \\ []) do
  auth_module(opts ++ [required: true])
end
```

**Explicit setup-error pattern** (lines 24-44):
```elixir
defp configured(key, opts) do
  case Application.get_env(@app, key) do
    nil ->
      if Keyword.get(opts, :required, false) do
        raise setup_error(key)
      end

    value ->
      value
  end
end

defp setup_error(:repo) do
  "Oban Powertools requires :repo in config :oban_powertools, repo: MyApp.Repo " <>
    "before using persistence-backed features."
end
```

**Host-facing delegate pattern from `lib/oban_powertools/auth.ex`** (lines 21-33):
```elixir
def auth_module(opts \\ []), do: RuntimeConfig.auth_module(opts)

def current_actor(conn_or_socket_or_session) do
  auth_module!().current_actor(conn_or_socket_or_session)
end

def authorize(actor, action, resource) do
  auth_module!().can_perform_action?(actor, action, resource)
end
```

**Apply to Phase 8**
- Route all new supervision/install contract checks through `RuntimeConfig` helpers rather than duplicating `Application.fetch_env!`.
- Preserve stable, asserted error copy for missing host wiring.
- Prefer `foo!/1` for fail-fast public contract points and `foo/1` when Phase 8 needs non-crashing verification seams.

---

### `lib/oban_powertools/application.ex` (provider, event-driven)

**Analog:** `lib/oban_powertools/application.ex`

**Child assembly pattern** (lines 8-19):
```elixir
@impl true
def start(_type, _args) do
  children =
    []
    |> maybe_add_pubsub()
    |> maybe_add_workflow_coordinator()
    |> maybe_add_heartbeat_writer()

  opts = [strategy: :one_for_one, name: ObanPowertools.Supervisor]
  Supervisor.start_link(children, opts)
end
```

**Optional child gating pattern** (lines 22-44):
```elixir
defp maybe_add_pubsub(children) do
  if Code.ensure_loaded?(Phoenix.PubSub) do
    children ++ [{Phoenix.PubSub, name: ObanPowertools.PubSub}]
  else
    children
  end
end

defp maybe_add_heartbeat_writer(children) do
  if Code.ensure_loaded?(ObanPowertools.Lifeline.HeartbeatWriter) do
    children ++ [ObanPowertools.Lifeline.HeartbeatWriter]
  else
    children
  end
end
```

**Sibling child init posture from `lib/oban_powertools/workflow/coordinator.ex`** (lines 14-18):
```elixir
@impl true
def init(_opts) do
  if Code.ensure_loaded?(Phoenix.PubSub) do
    Phoenix.PubSub.subscribe(ObanPowertools.PubSub, ObanPowertools.Workflow.Signal.topic())
  end

  {:ok, %{}}
end
```

**Apply to Phase 8**
- Keep supervision ownership inside `Application.start/2`; the host contract should be expressed through child gating or explicit startup failure, not by moving child ownership out to the host app.
- If Phase 8 changes boot posture, mirror the existing `maybe_add_*` style for deterministic inclusion/exclusion.
- Favor child-specific config checks at the seam where the dependency becomes mandatory.

---

### `lib/oban_powertools/lifeline/heartbeat_writer.ex` (service, event-driven)

**Analog:** `lib/oban_powertools/lifeline/heartbeat_writer.ex`

**GenServer start/init pattern** (lines 12-31):
```elixir
def start_link(opts \\ []) do
  GenServer.start_link(__MODULE__, opts, name: __MODULE__)
end

@impl true
def init(opts) do
  state = %{
    repo: Keyword.get(opts, :repo, Application.fetch_env!(:oban_powertools, :repo)),
    interval_ms:
      Keyword.get(
        opts,
        :interval_ms,
        Application.get_env(:oban_powertools, :lifeline_heartbeat_interval_ms, @default_interval_ms)
      ),
    provider:
      Keyword.get(opts, :provider, Application.get_env(:oban_powertools, :lifeline_executor_provider))
  }
```

**Periodic refresh pattern** (lines 34-49):
```elixir
@impl true
def handle_info(:refresh, state) do
  executors =
    case state.provider do
      provider when is_function(provider, 0) -> provider.()
      _ -> []
    end

  _ = Lifeline.refresh_heartbeats(state.repo, executors)
  schedule_refresh(state.interval_ms)
  {:noreply, state}
end
```

**Apply to Phase 8**
- This is the current hard boot dependency seam for `:repo`; if the contract changes, change this file and `Application` together.
- Replace direct `Application.fetch_env!` with `RuntimeConfig.repo!` if the phase wants one shared public error contract.
- Keep refresh loops boring: resolve config once in `init/1`, do work in `handle_info/2`, re-schedule at the end.

---

### `lib/oban_powertools/web/router.ex` (route, request-response)

**Analog:** `lib/oban_powertools/web/router.ex`

**LiveView route macro pattern** (lines 9-24):
```elixir
defmacro oban_powertools_routes(path) do
  if Code.ensure_loaded?(Phoenix.LiveView.Router) do
    quote do
      import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 3]

      live_session :oban_powertools_native,
        on_mount: [ObanPowertools.Web.LiveAuth],
        session: %{"oban_dashboard_path" => unquote(path)} do
        live("/", ObanPowertools.Web.EngineOverviewLive, :index)
        live("/lifeline", ObanPowertools.Web.LifelineLive, :index)
        live("/limiters", ObanPowertools.Web.LimitersLive, :index)
        live("/cron", ObanPowertools.Web.CronLive, :index)
```

**Optional bridge pattern** (lines 26-30):
```elixir
if Code.ensure_loaded?(Oban.Web.Router) do
  import Oban.Web.Router, only: [oban_dashboard: 2]

  oban_dashboard(unquote(path), on_mount: [ObanPowertools.Web.LiveAuth])
end
```

**Host router fixture pattern from `test/support/test_router.ex`** (lines 20-24):
```elixir
scope "/ops/jobs" do
  pipe_through(:browser)

  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

**Apply to Phase 8**
- Keep the ownership split intact: host owns outer scope/pipeline, this macro owns the inner route tree and optional bridge.
- Any contract freezing for the bridge should be expressed as macro output shape plus route tests, not ad hoc host docs only.
- Reuse the session key `oban_dashboard_path` if native pages and bridge pages must stay path-consistent.

---

### `lib/oban_powertools/web/live_auth.ex` (middleware, request-response)

**Analog:** `lib/oban_powertools/web/live_auth.ex`

**Mount/auth assignment pattern** (lines 10-13):
```elixir
def on_mount(:default, _params, session, socket) do
  actor = Auth.current_actor(session)
  {:cont, assign(socket, :current_actor, actor)}
end
```

**Shared authorization helpers** (lines 15-29):
```elixir
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

**Apply to Phase 8**
- Reuse the same `on_mount` for native routes and the optional `oban_dashboard/2` bridge.
- If the host contract adds more bridge guarantees, keep them expressed through this shared mount seam rather than introducing a separate router-only auth mechanism.

---

### `lib/oban_powertools/telemetry.ex` (utility, event-driven)

**Analog:** `lib/oban_powertools/telemetry.ex`

**Prefix-specific wrapper pattern** (lines 9-47):
```elixir
def execute_operator_action(event_suffix, measurements \\ %{}, metadata \\ %{}) do
  :telemetry.execute(
    [:oban_powertools, :operator_action, event_suffix],
    measurements,
    metadata
  )
end

def execute_limiter_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
  :telemetry.execute(
    [:oban_powertools, :limiter, event_suffix],
    measurements,
    metadata
  )
end
```

**Apply to Phase 8**
- Add or document telemetry surface area in this wrapper only.
- Preserve low-cardinality structure by fixing the top-level prefixes here and treating `event_suffix`, `measurements`, and `metadata` shape as the public contract.
- If contract tests expand, group them by wrapper family rather than by feature module internals.

---

### `test/mix/tasks/oban_powertools.install_test.exs` (test, file-I/O)

**Analog:** `test/mix/tasks/oban_powertools.install_test.exs`

**Source-contract assertion pattern** (lines 9-23):
```elixir
test "installer defines the idempotency receipts migration contract" do
  source =
    "lib/mix/tasks/oban_powertools.install.ex"
    |> File.read!()

  assert source =~ "create table(:oban_powertools_idempotency_receipts, primary_key: false)"
  assert source =~ "add :worker, :string, null: false"
  assert source =~ "add :fingerprint, :string, null: false"
```

**Runtime wiring proof style** (lines 105-113):
```elixir
test "installer emits explicit runtime wiring for repo and auth module" do
  source =
    "lib/mix/tasks/oban_powertools.install.ex"
    |> File.read!()

  assert source =~ "config :oban_powertools"
  assert source =~ "repo:"
  assert source =~ "auth_module:"
end
```

**Apply to Phase 8**
- Keep installer verification cheap and deterministic by asserting on generated-source fragments in the task file.
- Add install/supervision contract assertions here if the contract is embodied as explicit generated text or comments.

---

### `test/oban_powertools/auth_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/auth_test.exs`

**Runtime env override pattern** (lines 16-25):
```elixir
Application.put_env(:oban_powertools, :repo, ObanPowertools.TestRepo)
Application.put_env(:oban_powertools, :auth_module, ObanPowertools.TestAuth)

assert RuntimeConfig.repo!() == ObanPowertools.TestRepo
assert RuntimeConfig.repo([]) == ObanPowertools.TestRepo
assert RuntimeConfig.auth_module!() == ObanPowertools.TestAuth
assert ObanPowertools.Auth.current_actor(%{"current_actor" => %{id: "ops-1"}}) == %{id: "ops-1"}
```

**Setup error assertion pattern** (lines 43-63):
```elixir
Application.delete_env(:oban_powertools, :repo)
Application.delete_env(:oban_powertools, :auth_module)

assert_raise RuntimeError, @repo_error, fn ->
  RuntimeConfig.repo!()
end

assert_raise RuntimeError, @auth_error, fn ->
  RuntimeConfig.auth_module!()
end
```

**Env restoration pattern** (lines 66-73):
```elixir
on_exit(fn ->
  Application.put_env(:oban_powertools, :repo, original_repo)
  Application.put_env(:oban_powertools, :auth_module, original_auth_module)
end)
```

**Apply to Phase 8**
- Use this structure for supervision contract tests that need temporary runtime wiring changes.
- Keep failure-mode assertions on the exact public error strings when host wiring is intentionally required.

---

### `test/oban_powertools/web/router_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/web/router_test.exs`

**Route shape assertion pattern** (lines 11-47):
```elixir
assert %{
         plug: Phoenix.LiveView.Plug,
         phoenix_live_view: {ObanPowertools.Web.EngineOverviewLive, :index, _, _}
       } =
         Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs", "localhost")

assert %{
         plug: Phoenix.LiveView.Plug,
         phoenix_live_view: {ObanPowertools.Web.CronLive, :index, _, _}
       } =
         Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/cron", "localhost")
```

**Host router fixture** (from `test/support/test_router.ex`, lines 1-24):
```elixir
defmodule ObanPowertools.TestRouter do
  use Phoenix.Router

  require ObanPowertools.Web.Router

  scope "/ops/jobs" do
    pipe_through(:browser)

    ObanPowertools.Web.Router.oban_powertools_routes("/oban")
  end
end
```

**Apply to Phase 8**
- Verify native and optional bridge routes through `Phoenix.Router.route_info/4`.
- If Phase 8 adds bridge-path proof, extend the same fixture router instead of building a separate fake host.

---

### `test/oban_powertools/telemetry_test.exs` (test, event-driven)

**Analog:** `test/oban_powertools/telemetry_test.exs`

**Single-event attach/assert pattern** (lines 4-20):
```elixir
:telemetry.attach(
  "test-handler",
  [:oban_powertools, :operator_action, :complete],
  fn name, measurements, metadata, _config ->
    send(self(), {:telemetry_event, name, measurements, metadata})
  end,
  nil
)

ObanPowertools.Telemetry.execute_operator_action(:complete, %{count: 1}, %{action: "test"})

assert_receive {:telemetry_event, [:oban_powertools, :operator_action, :complete],
                %{count: 1}, %{action: "test"}}
```

**Multi-event attach pattern from `test/oban_powertools/workflow_coordinator_test.exs`** (lines 8-27):
```elixir
setup do
  test_pid = self()

  :telemetry.attach_many(
    "workflow-coordinator-test",
    [
      [:oban_powertools, :workflow, :step_completed],
      [:oban_powertools, :workflow, :step_unblocked],
      [:oban_powertools, :workflow, :cascade_cancelled],
      [:oban_powertools, :workflow, :workflow_completed]
    ],
```

**Apply to Phase 8**
- Use `attach/4` for one-event contract tests and `attach_many/4` when asserting the frozen public event family.
- Keep contract proof at the wrapper boundary: assert event name, measurements, and metadata, not downstream handler side effects.

---

### `test/oban_powertools/application_test.exs` (test, event-driven)

**Analog:** `test/oban_powertools/auth_test.exs` + `test/oban_powertools/workflow_coordinator_test.exs`

**Env mutation/restoration to copy from `test/oban_powertools/auth_test.exs`** (lines 66-73):
```elixir
on_exit(fn ->
  Application.put_env(:oban_powertools, :repo, original_repo)
  Application.put_env(:oban_powertools, :auth_module, original_auth_module)
end)
```

**OTP/process assertion posture to copy from `test/oban_powertools/workflow_coordinator_test.exs`** (lines 8-10):
```elixir
setup do
  test_pid = self()
  Ecto.Adapters.SQL.Sandbox.allow(TestRepo, self(), Process.whereis(ObanPowertools.Workflow.Coordinator))
```

**Apply to Phase 8**
- If a new supervision contract test is added, build it as a focused OTP/env test instead of a full install/integration harness.
- Assert either deterministic startup failure or deterministic child omission, whichever Phase 8 chooses to freeze.

## Shared Patterns

### Host runtime wiring
**Source:** `lib/oban_powertools/runtime_config.ex` lines 8-44
**Apply to:** `application.ex`, `heartbeat_writer.ex`, router/auth contract tests
```elixir
def repo!(opts \\ []) do
  repo(opts ++ [required: true])
end

def auth_module!(opts \\ []) do
  auth_module(opts ++ [required: true])
end
```

### Host-owned outer route scope
**Source:** `lib/mix/tasks/oban_powertools.install.ex` lines 73-84 and `test/support/test_router.ex` lines 20-24
**Apply to:** installer output, router tests, optional bridge proof
```elixir
Igniter.Libs.Phoenix.add_scope(
  igniter,
  "/ops/jobs",
  router_contents,
  []
)
```

### Shared LiveView and bridge auth seam
**Source:** `lib/oban_powertools/web/router.ex` lines 14-30 and `lib/oban_powertools/web/live_auth.ex` lines 10-29
**Apply to:** native shell, optional `oban_web` bridge
```elixir
live_session :oban_powertools_native,
  on_mount: [ObanPowertools.Web.LiveAuth],
  session: %{"oban_dashboard_path" => unquote(path)} do

if Code.ensure_loaded?(Oban.Web.Router) do
  oban_dashboard(unquote(path), on_mount: [ObanPowertools.Web.LiveAuth])
end
```

### Telemetry wrapper boundary
**Source:** `lib/oban_powertools/telemetry.ex` lines 9-47
**Apply to:** all public telemetry contract changes and tests
```elixir
:telemetry.execute(
  [:oban_powertools, :workflow, event_suffix],
  measurements,
  metadata
)
```

### Contract-test style
**Source:** `test/mix/tasks/oban_powertools.install_test.exs`, `test/oban_powertools/auth_test.exs`, `test/oban_powertools/web/router_test.exs`, `test/oban_powertools/telemetry_test.exs`
**Apply to:** all Phase 8 proof work
```elixir
assert source =~ "config :oban_powertools"
assert_raise RuntimeError, @repo_error, fn -> RuntimeConfig.repo!() end
assert %{plug: Phoenix.LiveView.Plug} = Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs", "localhost")
assert_receive {:telemetry_event, [:oban_powertools, :operator_action, :complete], %{count: 1}, %{action: "test"}}
```

## No Analog Found

None. The only likely new file is `test/oban_powertools/application_test.exs`, and it has strong role-match analogs in the existing env-contract and OTP event-driven tests.

## Metadata

**Analog search scope:** `lib/oban_powertools`, `lib/mix/tasks`, `test/oban_powertools`, `test/mix/tasks`, `test/support`, `.planning/phases/8-host-contract-install-surface`
**Files scanned:** 21
**Pattern extraction date:** 2026-05-21
