# Phase 11: Docs, Example App, Compatibility & Contract Proof - Pattern Map

**Mapped:** 2026-05-22
**Files analyzed:** 19
**Analogs found:** 18 / 19

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `README.md` | config | request-response | `README.md` | exact |
| `mix.exs` | config | request-response | `mix.exs` | exact |
| `guides/installation.md` | config | request-response | `README.md` | partial |
| `guides/first-operator-session.md` | config | request-response | `README.md` | partial |
| `guides/upgrade-and-compatibility.md` | config | request-response | `README.md` | partial |
| `guides/production-hardening.md` | config | request-response | `README.md` | partial |
| `guides/optional-oban-web-bridge.md` | config | request-response | `README.md` | partial |
| `guides/troubleshooting.md` | config | request-response | `README.md` | partial |
| `guides/support-truth-and-ownership-boundaries.md` | config | request-response | `README.md` | partial |
| `guides/example-app-walkthrough.md` | config | request-response | `README.md` | partial |
| `examples/phoenix_host/mix.exs` | config | request-response | `mix.exs` | role-match |
| `examples/phoenix_host/lib/phoenix_host_web/router.ex` | route | request-response | `test/support/test_router.ex` | exact |
| `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex` | middleware | request-response | `test/support/test_auth.ex` | role-match |
| `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_display_policy.ex` | middleware | transform | `lib/oban_powertools/web/oban_web_bridge.ex` | partial |
| `examples/phoenix_host/priv/repo/seeds.exs` | config | batch | `test/support/workflow_fixtures.ex` | partial |
| `examples/phoenix_host/README.md` | config | request-response | `README.md` | role-match |
| `test/oban_powertools/docs_contract_test.exs` | test | file-I/O | `test/mix/tasks/oban_powertools.install_test.exs` | exact |
| `test/oban_powertools/example_host_contract_test.exs` | test | request-response | `test/oban_powertools/web/router_test.exs` | role-match |
| `.github/workflows/ci.yml` | config | batch | none in repo | no analog |

## Pattern Assignments

### `README.md` (config, request-response)

**Analog:** `README.md`

**Sectioning pattern** ([README.md](/Users/jon/projects/oban_powertools/README.md:1)):
```markdown
# ObanPowertools

Oban Powertools is a host-owned operations layer for Oban-backed Phoenix applications. The
library owns the internal runtime helpers, pages, and telemetry wrappers; the host app owns
installation, config, router scope, browser pipeline, and policy implementation.

## Installation
```

**Install snippet pattern** ([README.md](/Users/jon/projects/oban_powertools/README.md:12)):
```elixir
def deps do
  [
    {:oban_powertools, "~> 0.1.0"},
    {:oban_web, "~> 2.10", optional: true}
  ]
end
```

**Router/support-truth pattern** ([README.md](/Users/jon/projects/oban_powertools/README.md:40)):
```elixir
scope "/ops/jobs" do
  pipe_through(:browser)

  require ObanPowertools.Web.Router
  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

Reuse the existing README cadence: one short positioning block, one install block, one router block, then explicit support-truth prose.

---

### `guides/*.md` (config, request-response)

**Applies to:** `guides/installation.md`, `guides/first-operator-session.md`, `guides/upgrade-and-compatibility.md`, `guides/production-hardening.md`, `guides/optional-oban-web-bridge.md`, `guides/troubleshooting.md`, `guides/support-truth-and-ownership-boundaries.md`, `guides/example-app-walkthrough.md`

**Primary analog:** `README.md`

**Supporting analogs for factual content:**
- `lib/oban_powertools/web/router.ex` for route ownership wording
- `lib/oban_powertools/auth.ex` for auth seam wording
- `lib/oban_powertools/runtime_config.ex` for fail-fast config wording
- `lib/oban_powertools/web/oban_web_bridge.ex` for bridge read-only wording

**Support-truth prose pattern** ([README.md](/Users/jon/projects/oban_powertools/README.md:57), [lib/oban_powertools/web/router.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/router.ex:14)):
```text
If `oban_web` is installed, the library also mounts the optional `oban_web` bridge at
`/ops/jobs/oban`. The host still owns the dependency choice and the outer `/ops/jobs` shell.
Powertools owns only the nested mount plus its adapter plumbing over documented hooks.

That bridge is read-only.
```

**Required-host-wiring prose pattern** ([README.md](/Users/jon/projects/oban_powertools/README.md:31), [lib/oban_powertools/runtime_config.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/runtime_config.ex:44)):
```elixir
config :oban_powertools,
  repo: MyApp.Repo,
  auth_module: MyAppWeb.ObanPowertoolsAuth,
  display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy
```

There is no existing guide tree. Copy the README’s short-section style, then source deeper explanations from the module docs and setup-error strings rather than inventing new terminology.

---

### `mix.exs` (config, request-response)

**Analog:** `mix.exs`

**Project keyword-list pattern** ([mix.exs](/Users/jon/projects/oban_powertools/mix.exs:4)):
```elixir
def project do
  [
    app: :oban_powertools,
    version: "0.1.0",
    elixir: "~> 1.19",
    start_permanent: Mix.env() == :prod,
    elixirc_paths: elixirc_paths(Mix.env()),
    deps: deps()
  ]
end
```

**Deps pattern with optional dependency** ([mix.exs](/Users/jon/projects/oban_powertools/mix.exs:27)):
```elixir
defp deps do
  [
    {:igniter, "~> 0.8.0"},
    {:telemetry, "~> 1.4"},
    {:jason, "~> 1.4"},
    {:oban, "~> 2.18"},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.17"},
    {:oban_web, "~> 2.10", optional: true}
  ]
end
```

Add ExDoc config by extending this existing `project/0` keyword-list shape. There is no in-repo analog for `docs:` or `groups_for_extras:`, so planner should treat that portion as research-driven.

---

### `examples/phoenix_host/mix.exs` (config, request-response)

**Analog:** `mix.exs`

**Keep the same Mix layout** ([mix.exs](/Users/jon/projects/oban_powertools/mix.exs:1)):
```elixir
defmodule ObanPowertools.MixProject do
  use Mix.Project

  def project do
    [
      app: :oban_powertools,
      version: "0.1.0",
      elixir: "~> 1.19"
    ]
  end
```

Copy the root project’s concise `project/0`, `application/0`, `deps/0` layout. The example app will need Phoenix-generated defaults, but dependency declarations should mirror the README contract and preserve the optional `oban_web` pattern.

---

### `examples/phoenix_host/lib/phoenix_host_web/router.ex` (route, request-response)

**Analog:** `test/support/test_router.ex`

**Browser pipeline + mount shape** ([test/support/test_router.ex](/Users/jon/projects/oban_powertools/test/support/test_router.ex:1)):
```elixir
defmodule ObanPowertools.TestRouter do
  use Phoenix.Router

  require ObanPowertools.Web.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, html: {ObanPowertools.TestLayouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end
```

**Host-owned outer scope pattern** ([test/support/test_router.ex](/Users/jon/projects/oban_powertools/test/support/test_router.ex:20)):
```elixir
scope "/ops/jobs" do
  pipe_through(:browser)

  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

The example host should copy this shape, replacing only the app module names and any generated Phoenix router boilerplate.

---

### `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex` (middleware, request-response)

**Analog:** `test/support/test_auth.ex`

**Behaviour + current-actor pattern** ([test/support/test_auth.ex](/Users/jon/projects/oban_powertools/test/support/test_auth.ex:1)):
```elixir
defmodule ObanPowertools.TestAuth do
  @behaviour ObanPowertools.Auth

  @impl true
  def current_actor(%{"current_actor" => actor}), do: actor
  def current_actor(%{current_actor: actor}), do: actor
  def current_actor(%{assigns: %{current_actor: actor}}), do: actor
  def current_actor(_), do: nil
```

**Explicit authorize/audit-principal pattern** ([test/support/test_auth.ex](/Users/jon/projects/oban_powertools/test/support/test_auth.ex:10), [lib/oban_powertools/auth.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/auth.ex:16)):
```elixir
@impl true
def authorize(nil, _action, _resource), do: {:error, :unauthorized}

def authorize(actor, action, _resource) do
  permissions = Map.get(actor, :permissions, Map.get(actor, "permissions", []))
  cond do
    :all in permissions or action in permissions -> :ok
    true -> {:error, :unauthorized}
  end
end
```

Use this simple explicit-return style in the example app. It matches the public behaviour and is honest about host-owned authorization.

---

### `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_display_policy.ex` (middleware, transform)

**Primary analog:** `lib/oban_powertools/web/oban_web_bridge.ex`

**Supporting analog:** `lib/oban_powertools/runtime_config.ex`

**Display callback usage pattern** ([lib/oban_powertools/web/oban_web_bridge.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/oban_web_bridge.ex:55)):
```elixir
case module.display(kind, value, context) do
  nil -> fallback.()
  rendered when is_binary(rendered) or is_list(rendered) -> rendered
  other -> raise ArgumentError, invalid_display_message(kind, other)
end
```

**Required-config wording to teach in docs/tests** ([lib/oban_powertools/runtime_config.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/runtime_config.ex:54)):
```text
Oban Powertools requires :display_policy in config :oban_powertools,
display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy before mounting policy-sensitive native operator pages.
```

There is no exact example implementation in-repo. The planner should keep the example policy module intentionally tiny and conform to the `display/3` callback shape exercised here.

---

### `examples/phoenix_host/priv/repo/seeds.exs` (config, batch)

**Analog:** `test/support/workflow_fixtures.ex`

There is only a partial analog in the repo: test fixtures seed realistic workflow data for operator-facing flows. Reuse the “small, intentional fixture data” posture from existing test fixtures rather than building a broad demo seed set.

---

### `examples/phoenix_host/README.md` (config, request-response)

**Analog:** `README.md`

Copy the root README’s terse contract-first tone:
- start with what the example proves
- show exact install/run steps
- call out host-owned seams and optional `oban_web`
- link back to the main guides rather than duplicating them

---

### `test/oban_powertools/docs_contract_test.exs` (test, file-I/O)

**Primary analog:** `test/mix/tasks/oban_powertools.install_test.exs`

**Supporting analog:** `test/oban_powertools/web/router_test.exs`

**File-read assertion pattern** ([test/mix/tasks/oban_powertools.install_test.exs](/Users/jon/projects/oban_powertools/test/mix/tasks/oban_powertools.install_test.exs:9)):
```elixir
test "installer defines the idempotency receipts migration contract" do
  source =
    "lib/mix/tasks/oban_powertools.install.ex"
    |> File.read!()

  assert source =~ "create table(:oban_powertools_idempotency_receipts, primary_key: false)"
  assert source =~ "add :worker, :string, null: false"
end
```

**Docs-marker assertion pattern** ([test/oban_powertools/web/router_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/router_test.exs:92)):
```elixir
test "bridge docs state the phase 10 support truth" do
  assert moduledoc(ObanWebBridge) =~ "read-only"
  assert moduledoc(ObanWebBridge) =~ "native Powertools pages"
  assert moduledoc(ObanPowertools.Web.Router) =~ "audited mutations"
end
```

Use the same cheap contract-test approach: `File.read!/1` for README and guide snippets, and exact `=~` markers for support-truth language.

---

### `test/oban_powertools/example_host_contract_test.exs` (test, request-response)

**Primary analog:** `test/oban_powertools/web/router_test.exs`

**Supporting analogs:** `test/support/live_case.ex`, `test/support/test_router.ex`, `test/support/test_auth.ex`

**Route-proof pattern** ([test/oban_powertools/web/router_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/router_test.exs:12)):
```elixir
assert %{
         plug: Phoenix.LiveView.Plug,
         phoenix_live_view: {ObanPowertools.Web.EngineOverviewLive, :index, _, _}
       } =
         Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs", "localhost")
```

**Bridge-proof pattern** ([test/oban_powertools/web/router_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/router_test.exs:54)):
```elixir
assert %{
         plug: Phoenix.LiveView.Plug,
         route: "/ops/jobs/oban",
         phoenix_live_view: {Oban.Web.DashboardLive, :home, _, metadata}
       } =
         Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/oban", "localhost")
```

**Sandbox/live setup pattern** ([test/support/live_case.ex](/Users/jon/projects/oban_powertools/test/support/live_case.ex:1)):
```elixir
defmodule ObanPowertools.LiveCase do
  use ExUnit.CaseTemplate

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ObanPowertools.TestRepo)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
```

Use the router contract assertions as the spine. Add host-fixture compile/migrate/session checks around that style instead of introducing browser-E2E-heavy patterns.

## Shared Patterns

### Installer Contract Assertions
**Source:** [test/mix/tasks/oban_powertools.install_test.exs](/Users/jon/projects/oban_powertools/test/mix/tasks/oban_powertools.install_test.exs:1)
**Apply to:** `test/oban_powertools/docs_contract_test.exs`, any upgrade-proof tests
```elixir
use ExUnit.Case

source =
  "lib/mix/tasks/oban_powertools.install.ex"
  |> File.read!()

assert source =~ "|> setup_migration()"
assert source =~ "|> setup_smart_engine_migrations()"
```

### Host-Owned Router Scope
**Source:** [test/support/test_router.ex](/Users/jon/projects/oban_powertools/test/support/test_router.ex:20), [lib/oban_powertools/web/router.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/router.ex:16)
**Apply to:** example host router, README snippets, installation and walkthrough guides
```elixir
scope "/ops/jobs" do
  pipe_through(:browser)

  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

### Auth Seam
**Source:** [lib/oban_powertools/auth.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/auth.ex:40), [test/support/test_auth.ex](/Users/jon/projects/oban_powertools/test/support/test_auth.ex:10)
**Apply to:** example host auth module, hardening guide, support-truth guide
```elixir
@callback authorize(actor :: any(), action :: atom(), resource :: any()) ::
            :ok | {:error, term()}

def authorize(nil, _action, _resource), do: {:error, :unauthorized}
```

### Fail-Fast Host Config
**Source:** [lib/oban_powertools/runtime_config.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/runtime_config.ex:44)
**Apply to:** README, installation guide, troubleshooting guide, example app config
```text
Oban Powertools requires :repo in config :oban_powertools, repo: MyApp.Repo before using persistence-backed features.
Oban Powertools requires :auth_module in config :oban_powertools, auth_module: MyAppWeb.ObanPowertoolsAuth before mounting native operator pages.
```

### Optional Bridge Is Narrower Than Native
**Source:** [lib/oban_powertools/web/router.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/router.ex:24), [lib/oban_powertools/web/oban_web_bridge.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/oban_web_bridge.ex:24)
**Apply to:** README, bridge guide, compatibility guide, docs contract tests
```elixir
case Auth.authorization_outcome(actor, @view_action, @view_resource) do
  :ok -> :read_only
  {:error, _reason} -> {:forbidden, @dashboard_redirect}
end
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `guides/*.md` as a grouped ExDoc tree | config | request-response | Repo has a README only; no existing guide IA or ExDoc extras grouping exists yet. |
| `examples/phoenix_host/` as a committed generated host app | config | request-response | Repo has no existing checked-in Phoenix fixture app. Use root `mix.exs`, `test/support/test_router.ex`, and `test/support/test_auth.ex` as partial analogs. |
| `.github/workflows/ci.yml` | config | batch | No GitHub Actions workflow exists in the repo to copy lane naming or matrix style from. |

## Metadata

**Analog search scope:** `README.md`, `mix.exs`, `lib/`, `test/`, `.github/workflows/`
**Files scanned:** 11
**Pattern extraction date:** 2026-05-22
