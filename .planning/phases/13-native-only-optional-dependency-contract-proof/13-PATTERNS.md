# Phase 13: native-only-optional-dependency-contract-proof - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 11 primary targets + 1 conditional fixture-smoke target
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/support/example_host_contract.ex` | utility | file-I/O, batch | `test/support/example_host_contract.ex` | exact |
| `test/oban_powertools/example_host_contract_test.exs` | test | batch | `test/oban_powertools/example_host_contract_test.exs` | exact |
| `test/oban_powertools/web/router_test.exs` | test | request-response | `test/oban_powertools/web/router_test.exs` | exact |
| `test/oban_powertools/docs_contract_test.exs` | test | transform | `test/oban_powertools/docs_contract_test.exs` | exact |
| `.github/workflows/host-contract-proof.yml` | config | batch | `.github/workflows/host-contract-proof.yml` | exact |
| `README.md` | config | transform | `README.md` | exact |
| `guides/installation.md` | config | transform | `guides/installation.md` | exact |
| `guides/first-operator-session.md` | config | transform | `guides/first-operator-session.md` | exact |
| `guides/optional-oban-web-bridge.md` | config | transform | `guides/optional-oban-web-bridge.md` | exact |
| `guides/upgrade-and-compatibility.md` | config | transform | `guides/upgrade-and-compatibility.md` | exact |
| `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` | test | request-response | `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` | exact |
| `examples/phoenix_host/test/phoenix_host_web/*` bridge render smoke target if Phase 13 pushes the smoke into the fixture app instead of the top-level contract test | test | request-response | `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` | role-match |

## Pattern Assignments

### `test/support/example_host_contract.ex` (utility, file-I/O + batch)

**Primary analog:** `test/support/example_host_contract.ex`

**Imports/constants pattern** (lines 1-5):
```elixir
defmodule ObanPowertools.ExampleHostContract do
  @moduledoc false

  @fixture_dir Path.expand("../../examples/phoenix_host", __DIR__)
  @repo_root Path.expand("../..", __DIR__)
```

**Temp fixture preparation + narrow lane switch** (lines 7-23):
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

  case lane do
    "upgrade" -> simulate_upgrade_source!(target)
    _ -> :ok
  end

  target
end
```

**Command runner + failure surfacing** (lines 26-44):
```elixir
def run!(dir, env, command, args) do
  {output, status} =
    System.cmd(command, args,
      cd: dir,
      env: env,
      stderr_to_stdout: true
    )

  if status != 0 do
    raise """
    command failed: #{command} #{Enum.join(args, " ")}
    status: #{status}

    #{output}
    """
  end

  output
end
```

**Proof command orchestration** (lines 46-56):
```elixir
def proof!(lane) do
  dir = prepare_host!(lane)

  _ = run!(dir, [], "mix", ["deps.get"])

  compile_output = run!(dir, [], "mix", ["compile"])
  reset_output = run!(dir, [{"MIX_ENV", "test"}], "mix", ["ecto.reset"])
  seeds_output = run!(dir, [{"MIX_ENV", "test"}], "mix", ["run", "priv/repo/seeds.exs"])

  %{dir: dir, compile_output: compile_output, reset_output: reset_output, seeds_output: seeds_output}
end
```

**Secondary analog for file mutation and richer command rendering:** `test/support/fresh_host_contract.ex` lines 73-92 and 166-186.

Planner note: keep Phase 13 rewrites inside the existing `case lane do` block and keep them as tiny temp-fixture edits only. Do not turn this into a second host generator.

---

### `test/oban_powertools/example_host_contract_test.exs` (test, batch)

**Analog:** `test/oban_powertools/example_host_contract_test.exs`

**Imports/tagging pattern** (lines 1-7):
```elixir
defmodule ObanPowertools.ExampleHostContractTest do
  use ExUnit.Case
  @moduletag timeout: 180_000

  alias ObanPowertools.ExampleHostContract

  @tag :"native-only"
```

**Per-lane assertion style** (lines 8-21):
```elixir
test "native-only lane compiles and resets cleanly" do
  result = ExampleHostContract.proof!("native-only")

  assert result.compile_output =~ "Generated phoenix_host app"
  assert result.reset_output =~ "Migrated"
end

@tag :"bridge-enabled"
test "bridge-enabled lane compiles and resets cleanly" do
  result = ExampleHostContract.proof!("bridge-enabled")

  assert result.compile_output =~ "Generated phoenix_host app"
  assert result.seeds_output =~ "ops-demo"
end
```

**Output-marker proof style** (lines 32-40):
```elixir
@tag :first_session
test "first-session lane proves ops-demo pauses nightly_sync with pause_cron_entry" do
  result = ExampleHostContract.first_session!()

  assert result.output =~ "PhoenixHostWeb.ObanPowertoolsFirstSessionTest"
  assert result.output =~ "1 test, 0 failures"
  assert result.output =~ "ops-demo"
  assert result.output =~ "nightly_sync"
  assert result.output =~ "pause_cron_entry"
end
```

Planner note: add the bridge smoke in the same style as existing lane proofs: run one lane-specific command through `ExampleHostContract`, then assert stable output markers instead of broad HTML snapshots.

---

### `test/oban_powertools/web/router_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/web/router_test.exs`

**Imports/aliases pattern** (lines 1-5):
```elixir
defmodule ObanPowertools.Web.RouterTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Web.ObanWebBridge
  alias ObanPowertools.TestRouter
```

**Route shape assertions** (lines 12-48):
```elixir
test "native powertools routes mount inside the ops/jobs shell" do
  assert %{
           plug: Phoenix.LiveView.Plug,
           phoenix_live_view: {ObanPowertools.Web.EngineOverviewLive, :index, _, _}
         } =
           Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs", "localhost")

  assert %{
           plug: Phoenix.LiveView.Plug,
           phoenix_live_view: {ObanPowertools.Web.LifelineLive, :index, _, _}
         } =
           Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/lifeline", "localhost")
```

**Dependency-gated bridge route assertion** (lines 54-80):
```elixir
test "the optional oban_web bridge mounts under /ops/jobs/oban with the bounded powertools bridge contract" do
  if Code.ensure_loaded?(Oban.Web.Router) do
    assert %{
             plug: Phoenix.LiveView.Plug,
             route: "/ops/jobs/oban",
             phoenix_live_view: {Oban.Web.DashboardLive, :home, _, metadata}
           } =
             Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/oban", "localhost")

    assert %{
             extra: %{
               session:
                 {Oban.Web.Router, :__session__, ["/ops/jobs/oban", nil, resolver, _, _, _, _]},
               on_mount: on_mount_hooks
             }
           } = metadata
```

**Read-only access contract** (lines 83-89):
```elixir
test "the optional oban_web bridge stays a read-only inspection surface behind the shared powertools auth seam" do
  if Code.ensure_loaded?(Oban.Web.Router) do
    assert ObanWebBridge.resolve_access(%{id: "ops-1", permissions: [:view_oban_web]}) == :read_only

    assert ObanWebBridge.resolve_access(%{id: "ops-2", permissions: []}) ==
             {:forbidden, "/ops/jobs"}
  end
end
```

Planner note: keep this file focused on source-level route/resolver/auth/read-only seams. Do not move render-smoke coverage here.

---

### `test/oban_powertools/docs_contract_test.exs` (test, transform)

**Analog:** `test/oban_powertools/docs_contract_test.exs`

**Docs file list + workflow constant** (lines 4-13):
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
@workflow_file ".github/workflows/host-contract-proof.yml"
```

**Contract-marker assertion style** (lines 15-30):
```elixir
test "day-0 docs keep the repaired install contract markers" do
  source = joined_docs()

  assert source =~ "mix phx.new"
  assert source =~ "mix oban_powertools.install"
  assert source =~ "mix compile"
  assert source =~ "mix ecto.migrate"
  assert source =~ "mix ecto.reset"
  assert source =~ "mix phx.server"
  assert source =~ "ObanPowertoolsAuth"
  assert source =~ "ObanPowertoolsDisplayPolicy"
  assert source =~ "/ops/jobs"
  assert source =~ "/ops/jobs/oban"
  assert source =~ "read-only"
```

**Workflow-lane assertion style** (lines 48-60):
```elixir
test "workflow keeps the repaired proof lanes explicit" do
  source = File.read!(@workflow_file)

  assert source =~ "structural:"
  assert source =~ "fresh-host:"
  assert source =~ "docs-contract:"
  assert source =~ "native-only:"
  assert source =~ "first-session:"
  assert source =~ "bridge-enabled:"
  assert source =~ "test/oban_powertools/fresh_host_contract_test.exs"
  assert source =~ "test/oban_powertools/example_host_contract_test.exs"
  assert source =~ "--only first_session"
end
```

Planner note: extend marker checks with native-first language, but keep them as cheap joined-string assertions rather than parsing Markdown structure.

---

### `.github/workflows/host-contract-proof.yml` (config, batch)

**Analog:** `.github/workflows/host-contract-proof.yml`

**Shared job setup pattern** (lines 8-31):
```yaml
jobs:
  structural:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: oban_powertools_test
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"
      - run: mix deps.get
      - run: mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/web/router_test.exs
```

**Lane-per-job pattern** (lines 68-138):
```yaml
  native-only:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"
      - run: mix deps.get
      - run: mix test test/oban_powertools/example_host_contract_test.exs --only native-only

  bridge-enabled:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"
      - run: mix deps.get
      - run: mix test test/oban_powertools/example_host_contract_test.exs --only bridge-enabled
```

Planner note: preserve the one-job-per-lane shape and the separate `fresh-host` lane. Tighten naming and commands only enough to reflect native-first truth.

---

### `README.md` (config, transform)

**Analog:** `README.md`

**Top-level support-truth framing** (lines 3-10):
```md
Oban Powertools is a host-owned operations layer for Oban-backed Phoenix applications. The
library owns internal runtime helpers, native pages, and bridge adapters. The host app owns
router scope, browser pipeline, auth, display policy, runtime config, and seeded operator data.

## 60-Second Install

Start from a fresh Phoenix host, then add Oban Powertools. `oban_web` stays optional and only
enables the nested read-only bridge at `/ops/jobs/oban`.
```

**Native-first mount explanation** (lines 43-56):
````md
Run the generated migrations, then mount the Powertools route tree inside a host-owned browser
scope:

```elixir
scope "/ops/jobs" do
  pipe_through(:browser)

  require ObanPowertools.Web.Router
  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

Native Powertools pages then mount at `/ops/jobs`, and the optional `oban_web` bridge mounts at
`/ops/jobs/oban` when `oban_web` is installed.
````

**Support-truth bullet style** (lines 70-76):
```md
- The host owns the outer `/ops/jobs` shell, browser pipeline, auth module, display policy, and
  runtime config.
- The optional `/ops/jobs/oban` bridge is read-only.
- Native Powertools pages own audited mutations.
- `oban_web` is optional and narrower than the native Powertools surface.
```

Planner note: keep README as short contract summary; detailed caveats belong in guides and the docs contract test should enforce the key sentences.

---

### `guides/installation.md` (config, transform)

**Analog:** `guides/installation.md`

**Dependency wording pattern** (lines 15-27):
````md
## 1. Add Dependencies

Add Oban Powertools to your host app. Add `oban_web` only if you want the nested read-only bridge
at `/ops/jobs/oban`.

```elixir
def deps do
  [
    {:oban_powertools, "~> 0.1.0"},
    {:oban_web, "~> 2.10", optional: true}
  ]
end
```
````

**Host-owned router seam wording** (lines 57-71):
````md
## 4. Confirm the Router Mount

Your host owns the outer browser scope. The library owns only the nested routes mounted inside it:

```elixir
scope "/ops/jobs" do
  pipe_through(:browser)

  require ObanPowertools.Web.Router
  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

That mount gives you native Powertools pages at `/ops/jobs` and the optional read-only bridge at
`/ops/jobs/oban`.
````

**Optional dependency caveat pattern** (lines 104-111):
```md
## 8. Optional `oban_web` Dependency

`oban_web` is optional. If you install it, Powertools mounts the nested bridge at
`/ops/jobs/oban`. That bridge remains read-only and narrower than the native Powertools pages.
```

---

### `guides/first-operator-session.md` (config, transform)

**Analog:** `guides/first-operator-session.md`

**Native-first success criteria pattern** (lines 41-61):
```md
Visit `/ops/jobs`. This is the native Powertools shell. It should render through your host-owned
browser pipeline, your host-owned auth module, and your host-owned display policy.

## 4. Complete One Native Audited Mutation

Use one native Powertools page to perform an audited mutation. The canonical proof is
`pause_cron_entry` on `nightly_sync` as operator `ops-demo`.

This matters because the native pages are the supported mutation surface:

- every audited mutation goes through the host-owned auth seam
- display and redaction still flow through your `display_policy`
- audit evidence stays with the native Powertools operator flow
```

**Bridge caveat wording** (lines 55-71):
```md
## 5. Check the Optional Bridge Boundary

If `oban_web` is installed, open `/ops/jobs/oban`.

That route is a read-only bridge. It shares the same host-owned actor and display seams, but it is
not a mutation equivalent. Use it for bounded inspection. Keep audited mutation work on the native
Powertools pages.
```

---

### `guides/optional-oban-web-bridge.md` (config, transform)

**Analog:** `guides/optional-oban-web-bridge.md`

**Bridge scope bullets** (lines 6-19):
```md
## What the bridge is

- mounted at `/ops/jobs/oban`
- read-only
- powered by the same host auth and display seams
- useful for inspection alongside native pages

## What the bridge is not

- not a write surface
- not native-feature parity
- not a replacement for preview-backed native operator flows

Native Powertools pages own audited mutations.
```

Planner note: this guide is the right place for additive-inspection language, not parity or broad product-surface claims.

---

### `guides/upgrade-and-compatibility.md` (config, transform)

**Analog:** `guides/upgrade-and-compatibility.md`

**Upgrade action list pattern** (lines 16-31):
````md
## Required upgrade actions

1. Add the explicit display policy:

```elixir
config :oban_powertools,
  repo: MyApp.Repo,
  auth_module: MyAppWeb.ObanPowertoolsAuth,
  display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy
```

2. Re-check the host-owned `/ops/jobs` scope and browser pipeline.
3. Decide whether this host should enable `oban_web`.
4. Run the current migrations.
5. Run the Phase 11 proof commands against the documented host path.
````

**Compatibility-table pattern** (lines 32-46):
```md
## Compatibility promise

| Lane | Meaning |
|------|---------|
| tested native-only lane | Powertools native pages mounted under `/ops/jobs` without relying on the bridge |
| tested bridge-enabled lane | Native pages plus the optional read-only `/ops/jobs/oban` bridge |
| best-effort | Semver-allowed combinations outside the tested lanes |

The tested native-only lane and tested bridge-enabled lane are the only lanes this phase proves
directly. Everything else is best-effort unless later CI coverage expands it.
```

Planner note: this file is the most likely place to tighten lane wording from symmetric to native-first while still acknowledging both tested lanes.

---

### `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` (test, request-response)

**Analog:** `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs`

**Fixture-host integration test imports** (lines 1-10):
```elixir
defmodule PhoenixHostWeb.ObanPowertoolsFirstSessionTest do
  use PhoenixHostWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias ObanPowertools.{Audit, Cron}
  alias ObanPowertools.Cron.Entry
  alias ObanPowertools.Lifeline.RepairPreview
  alias PhoenixHost.Repo
```

**Real session-backed LiveView mount pattern** (lines 15-21):
```elixir
actor = PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()

conn = Plug.Test.init_test_session(conn, %{"ops_actor" => actor})

{:ok, view, html} = live(conn, "/ops/jobs/cron")

assert html =~ "Cron"
```

**Action/assertion style to reuse for one render smoke** (lines 27-41):
```elixir
refute html =~ "Oban Web"

html =
  view
  |> element("button[phx-value-action='pause_cron_entry'][phx-value-entry='nightly_sync']")
  |> render_click()

assert html =~ "Preview Action"
assert html =~ "pause cron entry"
assert html =~ "cron_entry:nightly_sync"
assert html =~ "ops-demo"
```

Planner note: if the bridge render smoke lives inside the fixture app instead of the top-level contract test, copy this exact pattern: real host session, `live(conn, path)`, and a few stable text assertions only.

## Shared Patterns

### Temp Fixture Mutation + Command Execution
**Source:** `test/support/example_host_contract.ex` lines 7-56
**Also copy from:** `test/support/fresh_host_contract.ex` lines 45-92 and 166-186
**Apply to:** `test/support/example_host_contract.ex`, `test/oban_powertools/example_host_contract_test.exs`
```elixir
case lane do
  "upgrade" -> simulate_upgrade_source!(target)
  _ -> :ok
end

{output, status} =
  System.cmd(command, args,
    cd: dir,
    env: env,
    stderr_to_stdout: true
  )
```

### Compile-Time Optional Bridge Gating
**Source:** `lib/oban_powertools/web/router.ex` lines 32-66
**Apply to:** `test/oban_powertools/web/router_test.exs`, docs wording that describes the route contract
```elixir
defmacro oban_powertools_routes(path) do
  oban_web_router = Module.concat([Oban, Web, Router])

  bridge_routes =
    if Code.ensure_loaded?(oban_web_router) do
      quote do
        import unquote(oban_web_router), only: [oban_dashboard: 2]

        oban_dashboard(unquote(path),
          resolver: ObanPowertools.Web.ObanWebBridge,
          on_mount: [ObanPowertools.Web.LiveAuth]
        )
      end
```

### Read-Only Access Mapping
**Source:** `lib/oban_powertools/web/oban_web_bridge.ex` lines 20-29
**Apply to:** `test/oban_powertools/web/router_test.exs`, bridge-smoke assertions, docs wording
```elixir
@impl true
def resolve_user(conn), do: Auth.current_actor(conn)

@impl true
def resolve_access(actor) do
  case Auth.authorization_outcome(actor, @view_action, @view_resource) do
    :ok -> :read_only
    {:error, _reason} -> {:forbidden, @dashboard_redirect}
  end
end
```

### Session-Backed LiveView Smoke Test
**Source:** `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` lines 15-21
**Apply to:** any bridge-enabled fixture render smoke
```elixir
actor = PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()
conn = Plug.Test.init_test_session(conn, %{"ops_actor" => actor})

{:ok, _view, html} = live(conn, "/ops/jobs/cron")
```

### Docs Contract Marker Style
**Source:** `test/oban_powertools/docs_contract_test.exs` lines 15-60
**Apply to:** `README.md`, `guides/installation.md`, `guides/first-operator-session.md`, `guides/optional-oban-web-bridge.md`, `guides/upgrade-and-compatibility.md`, workflow lane naming
```elixir
source = joined_docs()
assert source =~ "/ops/jobs"
assert source =~ "/ops/jobs/oban"
assert source =~ "read-only"

source = File.read!(@workflow_file)
assert source =~ "native-only:"
assert source =~ "bridge-enabled:"
```

## No Analog Found

None. Every likely Phase 13 target already has a direct in-repo analog. The only conditional choice is whether the bridge render smoke lives in `test/oban_powertools/example_host_contract_test.exs` via command-output proof or inside `examples/phoenix_host/test/phoenix_host_web/` as a fixture-host LiveView test.

## Metadata

**Analog search scope:** `test/support`, `test/oban_powertools`, `examples/phoenix_host/test`, `.github/workflows`, `guides`, `README.md`, `lib/oban_powertools/web`
**Files scanned:** 15
**Pattern extraction date:** 2026-05-23
