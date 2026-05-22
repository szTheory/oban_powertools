# Phase 12: Fresh Host Install Path & Example Fixture Repair - Pattern Map

**Mapped:** 2026-05-22
**Files analyzed:** 18
**Analogs found:** 18 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/oban_powertools.install.ex` | config | file-I/O | `lib/mix/tasks/oban_powertools.install.ex` | exact |
| `README.md` | config | request-response | `README.md` | exact |
| `guides/installation.md` | config | request-response | `guides/installation.md` | exact |
| `guides/first-operator-session.md` | config | request-response | `guides/first-operator-session.md` | exact |
| `guides/example-app-walkthrough.md` | config | request-response | `guides/example-app-walkthrough.md` | exact |
| `examples/phoenix_host/README.md` | config | request-response | `examples/phoenix_host/README.md` | exact |
| `examples/phoenix_host/regenerate.sh` | utility | batch | `examples/phoenix_host/regenerate.sh` | exact |
| `examples/phoenix_host/config/config.exs` | config | request-response | `examples/phoenix_host/config/config.exs` | exact |
| `examples/phoenix_host/config/runtime.exs` | config | request-response | `examples/phoenix_host/config/runtime.exs` | exact |
| `examples/phoenix_host/lib/phoenix_host/application.ex` | config | request-response | `examples/phoenix_host/lib/phoenix_host/application.ex` | exact |
| `examples/phoenix_host/lib/phoenix_host_web/router.ex` | route | request-response | `examples/phoenix_host/lib/phoenix_host_web/router.ex` | exact |
| `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex` | middleware | request-response | `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex` | exact |
| `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_display_policy.ex` | utility | transform | `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_display_policy.ex` | exact |
| `examples/phoenix_host/priv/repo/seeds.exs` | utility | batch | `examples/phoenix_host/priv/repo/seeds.exs` | exact |
| `examples/phoenix_host/priv/repo/migrations/*.exs` | migration | CRUD | `examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs` | role-match |
| `test/mix/tasks/oban_powertools.install_test.exs` | test | file-I/O | `test/mix/tasks/oban_powertools.install_test.exs` | exact |
| `test/support/example_host_contract.ex` | utility | batch | `test/support/example_host_contract.ex` | exact |
| `test/oban_powertools/example_host_contract_test.exs` | test | batch | `test/oban_powertools/example_host_contract_test.exs` | exact |
| `test/oban_powertools/docs_contract_test.exs` | test | transform | `test/oban_powertools/docs_contract_test.exs` | exact |
| `.github/workflows/host-contract-proof.yml` | config | batch | `.github/workflows/host-contract-proof.yml` | exact |
| `lib/<host_web>/oban_powertools_auth.ex` | middleware | request-response | `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex` | role-match |
| `lib/<host_web>/oban_powertools_display_policy.ex` | utility | transform | `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_display_policy.ex` | role-match |

## Pattern Assignments

### `lib/mix/tasks/oban_powertools.install.ex` (config, file-I/O)

**Analog:** `lib/mix/tasks/oban_powertools.install.ex`

**Imports/task entry** (lines 1-22):
```elixir
defmodule Mix.Tasks.ObanPowertools.Install do
  use Igniter.Mix.Task

  @shortdoc "Installs Oban Powertools into a Phoenix application"

  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [],
      positional: []
    }
  end

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
end
```

**Thin generated seam pattern** (lines 24-47):
```elixir
defp setup_auth_module(igniter) do
  web_module = Igniter.Libs.Phoenix.web_module(igniter)
  auth_module_name = Module.concat(web_module, "ObanPowertoolsAuth")

  contents = """
    @moduledoc "Host-implemented authorization for Powertools actions."
    @behaviour ObanPowertools.Auth

    @impl true
    def current_actor(_conn_or_socket) do
      # TODO: Return the current actor from your session/assigns
      nil
    end
  """

  Igniter.Project.Module.create_module(igniter, auth_module_name, contents)
end
```

**Config insertion pattern** (lines 49-75):
```elixir
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

  config :oban_powertools,
    repo: MyApp.Repo,
    auth_module: MyAppWeb.ObanPowertoolsAuth
  """
)
```

**Router insertion pattern** (lines 78-89):
```elixir
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
```

**Migration emission pattern** (lines 92-134, 136-556):
```elixir
igniter
|> Igniter.Libs.Ecto.gen_migration(
  nil,
  "oban_powertools_audit_events",
  body: """
    def change do
      create table(:oban_powertools_audit_events) do
        add :actor_id, :string
        add :action, :string, null: false
        add :resource, :string
        add :metadata, :map, default: %{}
      end
    end
  """
)
```

Use the existing installer itself as the source of truth for any added starter seam generation. Do not invent a second generation mechanism.

---

### `lib/<host_web>/oban_powertools_auth.ex` and `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex` (middleware, request-response)

**Analog:** `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex`

**Behaviour + actor extraction pattern** (lines 1-13):
```elixir
defmodule PhoenixHostWeb.ObanPowertoolsAuth do
  @moduledoc """
  Thin host-owned Powertools auth seam for the canonical example host.
  """

  @behaviour ObanPowertools.Auth

  @impl true
  def current_actor(%Plug.Conn{assigns: %{current_actor: actor}}), do: actor
  def current_actor(%Plug.Conn{private: %{plug_session: %{"ops_actor" => actor}}}), do: actor
  def current_actor(%{"ops_actor" => actor}), do: actor
  def current_actor(%{ops_actor: actor}), do: actor
  def current_actor(_), do: demo_actor()
end
```

**Authorization + durable principal pattern** (lines 15-41):
```elixir
@impl true
def authorize(nil, _action, _resource), do: {:error, :unauthorized}

def authorize(actor, _action, _resource) when is_map(actor) do
  if Map.get(actor, :role, Map.get(actor, "role")) in [:ops, "ops"] do
    :ok
  else
    {:error, :unauthorized}
  end
end

@impl true
def audit_principal(actor) when is_map(actor) do
  %{
    id: actor[:id] || actor["id"] || "ops-demo",
    type: :user,
    label: actor[:label] || actor["label"] || "ops-demo"
  }
end
```

Use this for both the checked-in fixture seam and any installer-generated starter auth module: thin, explicit, host-owned, with a durable principal shape.

---

### `lib/<host_web>/oban_powertools_display_policy.ex` and `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_display_policy.ex` (utility, transform)

**Analog:** `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_display_policy.ex`

**Display policy contract** (lines 1-26):
```elixir
defmodule PhoenixHostWeb.ObanPowertoolsDisplayPolicy do
  @moduledoc """
  Thin host-owned display policy seam for the canonical example host.
  """

  def display(:actor_label, actor, _context) when is_map(actor) do
    actor[:label] || actor["label"] || actor[:id] || actor["id"] || "ops-demo"
  end

  def display(:reason, reason, _context) when is_binary(reason), do: reason

  def display(kind, _value, context)
      when kind in [:job_args, :job_meta, :job_recorded] and is_map(context) do
    "[hidden by example host display policy]"
  end

  def display(:workflow_result, result, _context) when is_map(result) do
    %{summary: Map.get(result, :summary, Map.get(result, "summary", "Result available")),
      payload: "[hidden by example host display policy]",
      redacted?: true,
      status: Map.get(result, :status, Map.get(result, "status"))}
  end
end
```

This is the exact pattern to reuse when Phase 12 starts generating or updating the display-policy seam instead of documenting it as manual-only.

---

### `examples/phoenix_host/lib/phoenix_host_web/router.ex` (route, request-response)

**Analog:** `examples/phoenix_host/lib/phoenix_host_web/router.ex`

**Host-owned outer scope pattern** (lines 1-29):
```elixir
defmodule PhoenixHostWeb.Router do
  use PhoenixHostWeb, :router

  require ObanPowertools.Web.Router

  scope "/ops/jobs" do
    pipe_through :browser

    ObanPowertools.Web.Router.oban_powertools_routes("/oban")
  end
end
```

Use this exact ownership boundary in docs, fixture code, and installer expectations: host owns the outer scope and pipeline; library owns only the nested route tree.

---

### `lib/oban_powertools/web/router.ex` (route, request-response)

**Analog:** `lib/oban_powertools/web/router.ex`

**Public route contract wording** (lines 2-30):
```elixir
@moduledoc """
Host applications own the outer `"/ops/jobs"` scope and browser pipeline. This
module owns only the native Powertools route tree mounted inside that host-owned
shell. Native Powertools pages own audited mutations, while the optional
`/ops/jobs/oban` bridge stays a nested read-only inspection surface.
"""
```

**LiveView + optional bridge mount pattern** (lines 32-56):
```elixir
defmacro oban_powertools_routes(path) do
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
      live("/workflows", ObanPowertools.Web.WorkflowsLive, :index)
    end

    if Code.ensure_loaded?(Oban.Web.Router) do
      oban_dashboard(unquote(path), resolver: ObanPowertools.Web.ObanWebBridge, on_mount: [ObanPowertools.Web.LiveAuth])
    end
  end
end
```

Use this when aligning installer output, fixture router, and docs wording around native-vs-bridge ownership.

---

### `examples/phoenix_host/config/config.exs`, `examples/phoenix_host/config/runtime.exs`, `examples/phoenix_host/lib/phoenix_host/application.ex` (config, request-response)

**Analogs:** `examples/phoenix_host/config/config.exs`, `examples/phoenix_host/config/runtime.exs`, `examples/phoenix_host/lib/phoenix_host/application.ex`

**Static config pattern** (`config.exs` lines 14-23):
```elixir
config :phoenix_host, Oban,
  repo: PhoenixHost.Repo,
  notifier: Oban.Notifiers.PG,
  queues: [default: 5]

config :oban_powertools,
  repo: PhoenixHost.Repo,
  auth_module: PhoenixHostWeb.ObanPowertoolsAuth,
  display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy
```

**Runtime caveat pattern** (`runtime.exs` lines 23-29):
```elixir
config :phoenix_host, PhoenixHostWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

config :phoenix_host,
  reverse_proxy_headers: System.get_env("PHOENIX_HOST_REVERSE_PROXY", "false") == "true",
  websocket_transport_expected: true
```

**Supervision pattern** (`application.ex` lines 10-20):
```elixir
children = [
  PhoenixHostWeb.Telemetry,
  PhoenixHost.Repo,
  {Oban, Application.fetch_env!(:phoenix_host, Oban)},
  {DNSCluster, query: Application.get_env(:phoenix_host, :dns_cluster_query) || :ignore},
  {Phoenix.PubSub, name: PhoenixHost.PubSub},
  PhoenixHostWeb.Endpoint
]
```

Use these as the canonical host wiring shape. Phase 12 should keep the fixture thin and real, not add app-template behavior here.

---

### `examples/phoenix_host/priv/repo/migrations/*.exs` (migration, CRUD)

**Analog:** `examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs`

**Base migration wrapper pattern** (lines 1-11):
```elixir
defmodule PhoenixHost.Repo.Migrations.InstallOban do
  use Ecto.Migration

  def up do
    Oban.Migrations.up()
  end

  def down do
    Oban.Migrations.down()
  end
end
```

**Powertools table shape source** (installer lines 92-556):
```elixir
Igniter.Libs.Ecto.gen_migration(... "oban_powertools_audit_events", body: """ ... """)
Igniter.Libs.Ecto.gen_migration(... "oban_powertools_idempotency_receipts", body: """ ... """)
...
Igniter.Libs.Ecto.gen_migration(... "oban_powertools_repair_archives", body: """ ... """)
```

For new checked-in fixture migrations, copy the existing Ecto migration wrapper style from the fixture and the exact table bodies from the installer or `test/support/migrations/*.exs`. Do not invent a fixture-only schema.

---

### `examples/phoenix_host/priv/repo/seeds.exs` (utility, batch)

**Analog:** `examples/phoenix_host/priv/repo/seeds.exs`

**Seed proof output pattern** (lines 1-10):
```elixir
ops_actor = PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()

IO.puts("""
Seeded PhoenixHost demo assumptions:

- ops actor: #{ops_actor.id}
- label: #{ops_actor.label}
- role: #{ops_actor.role}
""")
```

Phase 12 proof should keep seeds deterministic and explicit. If the first-session proof needs more setup data, extend this script rather than hiding setup in tests.

---

### `test/support/example_host_contract.ex` and `test/oban_powertools/example_host_contract_test.exs` (utility/test, batch)

**Analogs:** `test/support/example_host_contract.ex`, `test/oban_powertools/example_host_contract_test.exs`

**Fixture copy + proof harness pattern** (`example_host_contract.ex` lines 7-23, 26-56):
```elixir
def prepare_host!(lane) do
  target =
    System.tmp_dir!()
    |> Path.join("oban-powertools-#{lane}-#{System.unique_integer([:positive])}")

  File.rm_rf!(target)
  File.cp_r!(@fixture_dir, target)
  File.rm_rf!(Path.join(target, "_build"))
  File.rm_rf!(Path.join(target, "deps"))
  rewrite_powertools_path!(target)
end

def proof!(lane) do
  dir = prepare_host!(lane)
  _ = run!(dir, [], "mix", ["deps.get"])
  compile_output = run!(dir, [], "mix", ["compile"])
  reset_output = run!(dir, [{"MIX_ENV", "test"}], "mix", ["ecto.reset"])
  seeds_output = run!(dir, [{"MIX_ENV", "test"}], "mix", ["run", "priv/repo/seeds.exs"])
  %{dir: dir, compile_output: compile_output, reset_output: reset_output, seeds_output: seeds_output}
end
```

**Lane-based test pattern** (`example_host_contract_test.exs` lines 7-30):
```elixir
@tag :"native-only"
test "native-only lane compiles and resets cleanly" do
  result = ExampleHostContract.proof!("native-only")
  assert result.compile_output =~ "Generated phoenix_host app"
  assert result.reset_output =~ "Migrated"
end

@tag :"upgrade-proof"
test "upgrade lane restores display_policy before proof commands run" do
  result = ExampleHostContract.proof!("upgrade")
  config_source = File.read!(Path.join(result.dir, "config/config.exs"))
  assert config_source =~ "display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy"
end
```

Use this exact helper/test split for any new fresh-host lane or richer first-session proof lane: helper runs shell commands, test asserts contract markers.

---

### First-session audited mutation proof (`test/oban_powertools/web/live/cron_live_test.exs` and `test/oban_powertools/web/live/lifeline_live_test.exs`)

**Analogs:** `test/oban_powertools/web/live/cron_live_test.exs`, `test/oban_powertools/web/live/lifeline_live_test.exs`

**Cron preview-first mutation pattern** (`cron_live_test.exs` lines 57-114):
```elixir
{:ok, view, html} = live(conn, "/ops/jobs/cron")

html =
  view
  |> element("button[phx-value-action='pause_cron_entry']")
  |> render_click()

assert html =~ "Preview Action"
assert html =~ "Audit Consequence"

render_change(view, "reason", %{"reason" => "maintenance"})
html = render_click(view, "confirm", %{})

[event | _] = Audit.list(%{type: :cron_entry, id: "nightly"}, repo: TestRepo)
assert event.action == "cron.paused"
assert event.actor_id == "ops-1"
assert event.metadata["reason"] == "maintenance"
```

**Lifeline repair proof pattern** (`lifeline_live_test.exs` lines 137-186):
```elixir
{:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

view
|> element("button[phx-value-row-id$=':job:#{job.id}'][phx-click='preview']")
|> render_click()

render_change(view, "reason", %{"reason" => "Rescuing orphaned job after node loss"})
html = render_click(view, "execute", %{})

assert html =~ "Repair executed and audit evidence was written."
[event] = Audit.list(%{type: :job, id: Integer.to_string(job.id)}, repo: TestRepo)
assert event.action == "lifeline.repair_executed"
```

Pick one of these existing preview/reason/audit flows for Phase 12’s first-session proof. Do not add browser E2E if a LiveView test can prove the contract.

---

### `test/mix/tasks/oban_powertools.install_test.exs` (test, file-I/O)

**Analog:** `test/mix/tasks/oban_powertools.install_test.exs`

**Source-contract assertion pattern** (lines 9-127):
```elixir
source =
  "lib/mix/tasks/oban_powertools.install.ex"
  |> File.read!()

assert source =~ "config :oban_powertools"
assert source =~ "repo:"
assert source =~ "auth_module:"
assert source =~ "|> setup_migration()"
assert source =~ "|> setup_smart_engine_migrations()"
```

Keep using focused file-content assertions for structural installer guarantees. Add real execution proof elsewhere; do not overload this file with end-to-end behavior.

---

### `test/oban_powertools/docs_contract_test.exs`, `README.md`, `guides/*.md`, `examples/phoenix_host/README.md` (test/config, request-response)

**Analogs:** `test/oban_powertools/docs_contract_test.exs`, `README.md`, `guides/installation.md`, `guides/first-operator-session.md`, `guides/example-app-walkthrough.md`, `examples/phoenix_host/README.md`

**Docs contract assertion pattern** (`docs_contract_test.exs` lines 4-30):
```elixir
@docs_files [
  "README.md",
  "guides/installation.md",
  "guides/first-operator-session.md",
  "guides/example-app-walkthrough.md",
  "guides/upgrade-and-compatibility.md",
  "guides/optional-oban-web-bridge.md",
  "guides/support-truth-and-ownership-boundaries.md"
]

assert source =~ "display_policy"
assert source =~ "auth_module"
assert source =~ "/ops/jobs"
assert source =~ "/ops/jobs/oban"
assert source =~ "read-only"
assert source =~ "examples/phoenix_host"
assert source =~ "Native Powertools pages own audited mutations."
```

**README install block pattern** (`README.md` lines 21-47):
```markdown
Run the installer:

mix oban_powertools.install

config :oban_powertools,
  repo: MyApp.Repo,
  auth_module: MyAppWeb.ObanPowertoolsAuth,
  display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy
```

**Installation guide pattern** (`guides/installation.md` lines 21-76):
```markdown
The installer adds starter host wiring for `repo` and `auth_module`, creates Powertools
migrations, and mounts the library route tree under a host-owned `/ops/jobs` scope.

`oban_web` is optional.
```

**First-session guide pattern** (`guides/first-operator-session.md` lines 38-65):
```markdown
Use one native Powertools page to perform an audited mutation.

- every audited mutation goes through the host-owned auth seam
- display and redaction still flow through your `display_policy`
- audit evidence stays with the native Powertools operator flow
```

**Fixture provenance wording pattern** (`examples/phoenix_host/README.md` lines 50-54):
```markdown
This fixture is generated from `mix phx.new` plus `mix oban_powertools.install`, then finished
with the thin manual seams captured in this directory.
```

Use these exact docs patterns when Phase 12 repairs provenance wording. Keep one honest story across README, guides, and fixture README.

---

### `examples/phoenix_host/regenerate.sh` (utility, batch)

**Analog:** `examples/phoenix_host/regenerate.sh`

**Canonical rebuild checklist pattern** (lines 10-40):
```bash
mix phx.new "${TMP_DIR}" \
  --app phoenix_host \
  --module PhoenixHost \
  --database postgres \
  --no-assets \
  --no-dashboard \
  --no-mailer \
  --no-gettext \
  --no-install

1. Add the local Powertools dependency and optional oban_web lane to mix.exs.
2. Run:
     cd examples/.phoenix_host_regen
     mix deps.get
     mix oban_powertools.install
3. Re-apply the thin manual seams from examples/phoenix_host:
```

Phase 12 should preserve this “generated baseline plus explicit host-owned follow-up” structure, while tightening any overclaim about what is actually generated.

---

### `.github/workflows/host-contract-proof.yml` (config, batch)

**Analog:** `.github/workflows/host-contract-proof.yml`

**Lane-per-contract pattern** (lines 8-114):
```yaml
jobs:
  structural:
    ...
    - run: mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/web/router_test.exs

  docs-contract:
    ...
    - run: mix test test/oban_powertools/docs_contract_test.exs

  native-only:
    ...
    - run: mix test test/oban_powertools/example_host_contract_test.exs --only native-only

  bridge-enabled:
    ...
    - run: mix test test/oban_powertools/example_host_contract_test.exs --only bridge-enabled
```

If Phase 12 adds a richer fresh-host or first-session proof lane, follow this job-per-lane structure instead of folding everything into one giant job.

## Shared Patterns

### Runtime Wiring
**Source:** `lib/oban_powertools/runtime_config.ex` lines 8-57
**Apply to:** Installer config generation, docs, fixture config, proof assertions
```elixir
def repo!(opts \\ []), do: repo(opts ++ [required: true])
def auth_module!(opts \\ []), do: auth_module(opts ++ [required: true])
def display_policy!(opts \\ []), do: display_policy(opts ++ [required: true])

defp setup_error(:auth_module) do
  "Oban Powertools requires :auth_module in config :oban_powertools, " <>
    "auth_module: MyAppWeb.ObanPowertoolsAuth before mounting native operator pages."
end
```

### Host-Owned Router Boundary
**Source:** `lib/oban_powertools/web/router.ex` lines 5-30 and `examples/phoenix_host/lib/phoenix_host_web/router.ex` lines 25-29
**Apply to:** Installer, docs, fixture, tests
```elixir
scope "/ops/jobs" do
  pipe_through :browser
  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

### Thin Host Seams
**Source:** `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex` lines 1-41 and `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_display_policy.ex` lines 1-26
**Apply to:** Installer-generated starter modules and canonical fixture
```elixir
@behaviour ObanPowertools.Auth
def current_actor(...), do: ...
def authorize(...), do: ...
def audit_principal(...), do: ...

def display(:actor_label, ...), do: ...
def display(:reason, ...), do: ...
```

### Deterministic Proof Harness
**Source:** `test/support/example_host_contract.ex` lines 26-56
**Apply to:** Fresh-host install lane, fixture proof lane, upgrade lane
```elixir
{output, status} =
  System.cmd(command, args, cd: dir, env: env, stderr_to_stdout: true)

if status != 0 do
  raise """
  command failed: #{command} #{Enum.join(args, " ")}
  """
end
```

### Native Audited Mutation Proof
**Source:** `test/oban_powertools/web/live/cron_live_test.exs` lines 79-114 and `test/oban_powertools/web/live/lifeline_live_test.exs` lines 150-186
**Apply to:** First-session proof work
```elixir
render_change(view, "reason", %{"reason" => "..."})
html = render_click(view, "confirm" | "execute", %{})
[event | _] = Audit.list(..., repo: TestRepo)
assert event.metadata["reason"] == "..."
```

### Docs Contract Lock
**Source:** `test/oban_powertools/docs_contract_test.exs` lines 14-30
**Apply to:** README, guides, example fixture README
```elixir
assert source =~ "display_policy"
assert source =~ "/ops/jobs/oban"
assert source =~ "Native Powertools pages own audited mutations."
```

## No Analog Found

None. Phase 12 is a repair phase against existing installer, fixture, docs, and proof infrastructure.

## Metadata

**Analog search scope:** `lib/`, `examples/phoenix_host/`, `test/`, `.github/workflows/`, `guides/`, repo `README.md`
**Files scanned:** 18 primary files plus targeted proof analog searches
**Pattern extraction date:** 2026-05-22
