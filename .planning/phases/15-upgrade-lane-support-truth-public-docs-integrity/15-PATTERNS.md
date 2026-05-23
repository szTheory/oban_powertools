# Phase 15: Upgrade Lane, Support Truth & Public Docs Integrity - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 16
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/support/example_host_contract.ex` | utility | file-I/O | `test/support/fresh_host_contract.ex` | exact |
| `test/oban_powertools/example_host_contract_test.exs` | test | request-response | `test/oban_powertools/fresh_host_contract_test.exs` | exact |
| `.github/workflows/host-contract-proof.yml` | config | batch | `.github/workflows/host-contract-proof.yml` | exact |
| `test/oban_powertools/docs_contract_test.exs` | test | transform | `test/oban_powertools/docs_contract_test.exs` | exact |
| `README.md` | config | transform | `guides/installation.md` | role-match |
| `guides/upgrade-and-compatibility.md` | config | transform | `guides/first-operator-session.md` | role-match |
| `guides/support-truth-and-ownership-boundaries.md` | config | transform | `README.md` | role-match |
| `guides/production-hardening.md` | config | transform | `guides/troubleshooting.md` | role-match |
| `guides/troubleshooting.md` | config | transform | `lib/oban_powertools/runtime_config.ex` | data-flow match |
| `guides/installation.md` | config | transform | `README.md` | role-match |
| `guides/first-operator-session.md` | config | transform | `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` | data-flow match |
| `guides/optional-oban-web-bridge.md` | config | transform | `examples/phoenix_host/test/phoenix_host_web/oban_web_bridge_smoke_test.exs` | data-flow match |
| `guides/example-app-walkthrough.md` | config | transform | `examples/phoenix_host/README.md` | exact |
| `examples/phoenix_host_upgrade_source/README.md` | config | transform | `examples/phoenix_host/README.md` | exact |
| `examples/phoenix_host_upgrade_source/` fixture tree (`mix.exs`, `config/config.exs`, `lib/phoenix_host_web/router.ex`, auth seam, seeds, migrations) | config | file-I/O | `examples/phoenix_host/` | exact |
| `examples/phoenix_host_upgrade_source/regenerate.sh` | utility | batch | `examples/phoenix_host/regenerate.sh` | exact |

## Pattern Assignments

### `test/support/example_host_contract.ex` (utility, file-I/O)

**Analog:** `test/support/fresh_host_contract.ex`

**Fixture prep + command runner pattern** ([test/support/example_host_contract.ex](/Users/jon/projects/oban_powertools/test/support/example_host_contract.ex:7), [test/support/fresh_host_contract.ex](/Users/jon/projects/oban_powertools/test/support/fresh_host_contract.ex:45)):
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
```

```elixir
defp run!(dir, env, command, args) do
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
end
```

**Use this shape for the real upgrade lane** ([test/support/example_host_contract.ex](/Users/jon/projects/oban_powertools/test/support/example_host_contract.ex:47), [test/support/fresh_host_contract.ex](/Users/jon/projects/oban_powertools/test/support/fresh_host_contract.ex:8)):
```elixir
_ = run!(dir, [], "mix", ["deps.get"])
compile_output = run!(dir, [], "mix", ["compile"])
reset_output = run!(dir, [{"MIX_ENV", "test"}], "mix", ["ecto.reset"])
seeds_output = run!(dir, [{"MIX_ENV", "test"}], "mix", ["run", "priv/repo/seeds.exs"])
```

**Pattern to replace** ([test/support/example_host_contract.ex](/Users/jon/projects/oban_powertools/test/support/example_host_contract.ex:122)):
```elixir
defp simulate_upgrade_source!(dir) do
  config_path = Path.join([dir, "config", "config.exs"])
  source = File.read!(config_path)
  without_policy =
    String.replace(source, ~r/\n\s*display_policy: PhoenixHostWeb\.ObanPowertoolsDisplayPolicy/, "")
  File.write!(config_path, without_policy)
end
```

Planner guidance: keep `proof!/1` and `run!/4` intact, but swap the upgrade lane to copy a second frozen fixture root instead of mutating `examples/phoenix_host` in place.

---

### `test/oban_powertools/example_host_contract_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/fresh_host_contract_test.exs`

**Tagged lane pattern** ([test/oban_powertools/example_host_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/example_host_contract_test.exs:7)):
```elixir
@tag :"upgrade-proof"
test "upgrade lane restores display_policy before proof commands run" do
  result = ExampleHostContract.proof!("upgrade")
  config_source = File.read!(Path.join(result.dir, "config/config.exs"))

  assert config_source =~ "display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy"
  assert result.reset_output =~ "Migrated"
end
```

**Assertion style to copy** ([test/oban_powertools/fresh_host_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/fresh_host_contract_test.exs:15)):
```elixir
config_source = File.read!(Path.join(result.dir, "config/config.exs"))
router_source = File.read!(Path.join([result.dir, "lib", "fresh_host_web", "router.ex"]))

assert config_source =~ "config :oban_powertools"
assert router_source =~ ~s(scope "/ops/jobs")
assert router_source =~ ~s|ObanPowertools.Web.Router.oban_powertools_routes("/oban")|
```

**Post-upgrade proof threshold to reuse** ([test/oban_powertools/example_host_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/example_host_contract_test.exs:47)):
```elixir
@tag :first_session
test "first-session lane proves ops-demo pauses nightly_sync with pause_cron_entry" do
  result = ExampleHostContract.first_session!()

  assert result.output =~ "ops-demo"
  assert result.output =~ "nightly_sync"
  assert result.output =~ "pause_cron_entry"
end
```

Planner guidance: rewrite the upgrade test to assert a meaningful native post-upgrade action, not just config restoration plus migration success.

---

### `.github/workflows/host-contract-proof.yml` (config, batch)

**Analog:** `.github/workflows/host-contract-proof.yml`

**Job layout pattern** ([.github/workflows/host-contract-proof.yml](/Users/jon/projects/oban_powertools/.github/workflows/host-contract-proof.yml:8)):
```yaml
jobs:
  structural:
  fresh-host:
  docs-contract:
  native-first:
  first-session:
  optional-bridge:
  upgrade-proof:
```

**Per-lane execution pattern** ([.github/workflows/host-contract-proof.yml](/Users/jon/projects/oban_powertools/.github/workflows/host-contract-proof.yml:140)):
```yaml
upgrade-proof:
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
    - run: mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof
```

Planner guidance: preserve the current one-job-per-lane naming and service setup; only tighten the upgrade lane’s semantics and names if docs/tests need the same lane label.

---

### `test/oban_powertools/docs_contract_test.exs` (test, transform)

**Analog:** `test/oban_powertools/docs_contract_test.exs`

**Joined-docs helper pattern** ([test/oban_powertools/docs_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/docs_contract_test.exs:4)):
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

defp joined_docs do
  @docs_files
  |> Enum.map(&File.read!/1)
  |> Enum.join("\n")
end
```

**Claim-based assertion pattern** ([test/oban_powertools/docs_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/docs_contract_test.exs:15)):
```elixir
assert source =~ "mix phx.new"
assert source =~ "mix oban_powertools.install"
assert source =~ "ObanPowertoolsAuth"
assert source =~ "ObanPowertoolsDisplayPolicy"
assert source =~ "/ops/jobs"
assert source =~ "/ops/jobs/oban"
assert source =~ "read-only"
```

**Support-truth locks to evolve, not replace** ([test/oban_powertools/docs_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/docs_contract_test.exs:40)):
```elixir
assert source =~ "Oban Powertools ships a native, host-owned operator shell at `/ops/jobs`."
assert source =~ "Native Powertools pages are the supported mutation surface."
assert source =~ "The host owns router scope, browser pipeline, auth, display policy, and runtime config."
```

Planner guidance: keep this file narrow and marker-based. Extend it for five-bucket support-truth language, tested-lane names, and “best-effort outside tested lanes,” but do not snapshot checklist prose.

---

### `README.md` (config, transform)

**Analog:** `guides/installation.md`

**Front-door install + support-truth structure** ([README.md](/Users/jon/projects/oban_powertools/README.md:10), [guides/installation.md](/Users/jon/projects/oban_powertools/guides/installation.md:31)):
```markdown
## 60-Second Install

mix phx.new my_app --database postgres
mix oban_powertools.install
```

**Support-truth bullet style** ([README.md](/Users/jon/projects/oban_powertools/README.md:74)):
```markdown
## Support Truth

- Native Powertools pages are the supported mutation surface.
- The host owns router scope, browser pipeline, auth, display policy, and runtime config.
- The optional `/ops/jobs/oban` bridge is read-only.
```

Planner guidance: keep README concise and repeated. Use it as the short-form version of the five buckets; push long explanations into the guides.

---

### `guides/upgrade-and-compatibility.md` (config, transform)

**Analog:** `guides/first-operator-session.md`

**Lane-description pattern** ([guides/upgrade-and-compatibility.md](/Users/jon/projects/oban_powertools/guides/upgrade-and-compatibility.md:6)):
```markdown
## Source lane for this guide

- `repo` wiring already present
- `auth_module` wiring already present
- `/ops/jobs` already mounted
- `display_policy` still missing or not consistently documented
```

**Step-by-step proof narrative pattern** ([guides/first-operator-session.md](/Users/jon/projects/oban_powertools/guides/first-operator-session.md:45)):
```markdown
## 4. Complete One Native Audited Mutation

Use one native Powertools page to perform an audited mutation. The canonical proof is
`pause_cron_entry` on `nightly_sync` as operator `ops-demo`.
```

**Compatibility table pattern to keep** ([guides/upgrade-and-compatibility.md](/Users/jon/projects/oban_powertools/guides/upgrade-and-compatibility.md:32)):
```markdown
| Lane | Meaning |
|------|---------|
| tested native-first lane | ... |
| tested optional bridge lane | ... |
| best-effort | ... |
```

Planner guidance: replace internal “Phase 8/9/10” wording with a host-shape description, then end the guide at the same native proof threshold the first-session guide already uses.

---

### `guides/support-truth-and-ownership-boundaries.md` (config, transform)

**Analog:** `README.md`

**Ownership split pattern** ([README.md](/Users/jon/projects/oban_powertools/README.md:3), [guides/support-truth-and-ownership-boundaries.md](/Users/jon/projects/oban_powertools/guides/support-truth-and-ownership-boundaries.md:5)):
```markdown
The host app owns router scope, browser pipeline, auth, display policy, runtime config, and seeded operator data.
```

```markdown
## Host owns
- host owns router scope
- browser pipeline in front of `/ops/jobs`
- auth implementation
- runtime config
- display policy
```

**Support-truth bullet style to expand** ([guides/support-truth-and-ownership-boundaries.md](/Users/jon/projects/oban_powertools/guides/support-truth-and-ownership-boundaries.md:21)):
```markdown
## Support truth

- native pages own audited mutations
- the optional `/ops/jobs/oban` bridge is read-only
- the host contract stays explicit instead of relying on hidden defaults
```

Planner guidance: this is the primary home for the five buckets: `supported`, `tested`, `best-effort`, `host-owned`, `intentionally unsupported`.

---

### `guides/production-hardening.md` (config, transform)

**Analog:** `guides/troubleshooting.md`

**Checklist style** ([guides/production-hardening.md](/Users/jon/projects/oban_powertools/guides/production-hardening.md:5)):
```markdown
## Checklist

- Confirm the host browser pipeline around `/ops/jobs` matches your real auth boundary.
- Treat `auth_module` as host-owned application logic, not a generated placeholder.
- Treat `display_policy` as a production redaction boundary.
```

**Narrative, not exact-string-spec style** ([guides/troubleshooting.md](/Users/jon/projects/oban_powertools/guides/troubleshooting.md:11)):
```markdown
## Common operator-host issues

- missing `display_policy`
- route mount present but the host browser pipeline is wrong
- reverse-proxy forwarding that breaks WebSocket transport
```

Planner guidance: keep this guide advisory and operational. The docs contract should only verify stable nouns it shares with runtime seams.

---

### `guides/troubleshooting.md` (config, transform)

**Analog:** `lib/oban_powertools/runtime_config.ex`

**Fail-fast error source to quote exactly** ([lib/oban_powertools/runtime_config.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/runtime_config.ex:44), [guides/troubleshooting.md](/Users/jon/projects/oban_powertools/guides/troubleshooting.md:3)):
```elixir
defp setup_error(:repo) do
  "Oban Powertools requires :repo in config :oban_powertools, repo: MyApp.Repo " <>
    "before using persistence-backed features."
end

defp setup_error(:auth_module) do
  "Oban Powertools requires :auth_module in config :oban_powertools, " <>
    "auth_module: MyAppWeb.ObanPowertoolsAuth before mounting native operator pages."
end

defp setup_error(:display_policy) do
  "Oban Powertools requires :display_policy in config :oban_powertools, " <>
    "display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy before mounting policy-sensitive native operator pages."
end
```

Planner guidance: when troubleshooting text refers to runtime guarantees or rejections, derive those lines from `RuntimeConfig`; everything else stays narrative.

---

### `guides/installation.md` (config, transform)

**Analog:** `README.md`

**Paved-road structure** ([guides/installation.md](/Users/jon/projects/oban_powertools/guides/installation.md:9)):
```markdown
## 0. Start From A Fresh Phoenix Host
## 1. Add Dependencies
## 2. Run the Installer
## 3. Add the Required Host Runtime Config
## 4. Confirm the Router Mount
## 5. Compile The Generated Host Once
## 6. Run The Required Database Path
## 7. Boot The Host Once
```

**Required host wiring snippet** ([guides/installation.md](/Users/jon/projects/oban_powertools/guides/installation.md:48)):
```elixir
config :oban_powertools,
  repo: MyApp.Repo,
  auth_module: MyAppWeb.ObanPowertoolsAuth,
  display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy
```

Planner guidance: preserve the ordered install contract. Any support-truth tightening here should stay subordinate to the operational steps.

---

### `guides/first-operator-session.md` (config, transform)

**Analog:** `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs`

**Proof values and action pattern** ([guides/first-operator-session.md](/Users/jon/projects/oban_powertools/guides/first-operator-session.md:25), [examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs](/Users/jon/projects/oban_powertools/examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs:12)):
```markdown
The canonical proof actor is `ops-demo`. The canonical proof target is the native cron entry
`nightly_sync`.
```

```elixir
test "ops-demo pauses nightly_sync through the native cron page and writes durable audit evidence" do
  {:ok, view, html} = live(conn, "/ops/jobs/cron")
  ...
  assert event.actor_id == "ops-demo"
end
```

Planner guidance: if the upgrade guide needs one meaningful post-upgrade proof action, this is the canonical wording and evidence threshold to mirror.

---

### `guides/optional-oban-web-bridge.md` (config, transform)

**Analog:** `examples/phoenix_host/test/phoenix_host_web/oban_web_bridge_smoke_test.exs`

**Bridge boundary pattern** ([guides/optional-oban-web-bridge.md](/Users/jon/projects/oban_powertools/guides/optional-oban-web-bridge.md:3), [examples/phoenix_host/test/phoenix_host_web/oban_web_bridge_smoke_test.exs](/Users/jon/projects/oban_powertools/examples/phoenix_host/test/phoenix_host_web/oban_web_bridge_smoke_test.exs:6)):
```markdown
`oban_web` is optional. When installed, `/ops/jobs/oban` is an additive read-only inspection annex, not a co-equal operator surface.
```

```elixir
test "the optional bridge mounts at /ops/jobs/oban under the shared ops session" do
  {:ok, _view, html} = live(conn, "/ops/jobs/oban")
  assert html =~ "Oban Web"
  assert html =~ "/ops/jobs/oban"
end
```

Planner guidance: keep the wording bounded to mount path, shared session, and read-only posture.

---

### `guides/example-app-walkthrough.md` and `examples/phoenix_host_upgrade_source/README.md` (config, transform)

**Analog:** `examples/phoenix_host/README.md`

**Provenance bucket pattern** ([guides/example-app-walkthrough.md](/Users/jon/projects/oban_powertools/guides/example-app-walkthrough.md:12), [examples/phoenix_host/README.md](/Users/jon/projects/oban_powertools/examples/phoenix_host/README.md:42)):
```markdown
## Provenance

1. `mix phx.new` generated the baseline Phoenix host.
2. `mix oban_powertools.install` generated the Powertools wiring, route mount, and migration set.
3. Manual host-owned follow-up keeps the auth seam, display-policy seam, and narrow support-truth seed lane explicit.
```

**Fixture proof bullets** ([examples/phoenix_host/README.md](/Users/jon/projects/oban_powertools/examples/phoenix_host/README.md:7)):
```markdown
- a canonical host-owned `/ops/jobs` shell around Powertools routes
- explicit `auth_module: PhoenixHostWeb.ObanPowertoolsAuth`
- explicit `display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy`
- one narrow first-session seed lane: operator `ops-demo` and cron entry `nightly_sync`
```

Planner guidance: the new historical fixture README should copy this provenance-bucket style but explain that the source lane is intentionally pre-`display_policy` and frozen to one exact historical commit.

---

### `examples/phoenix_host_upgrade_source/` fixture tree (config, file-I/O)

**Analog:** `examples/phoenix_host/`

**Dependency and alias pattern** ([examples/phoenix_host/mix.exs](/Users/jon/projects/oban_powertools/examples/phoenix_host/mix.exs:41)):
```elixir
defp deps do
  [
    {:phoenix, "~> 1.8.7"},
    {:phoenix_ecto, "~> 4.5"},
    {:ecto_sql, "~> 3.13"},
    {:postgrex, ">= 0.0.0"},
    {:oban, "~> 2.18"},
    {:oban_powertools, path: "../.."},
    {:oban_web, "~> 2.10", optional: true}
  ]
end
```

**Runtime config pattern** ([examples/phoenix_host/config/config.exs](/Users/jon/projects/oban_powertools/examples/phoenix_host/config/config.exs:19)):
```elixir
config :oban_powertools,
  repo: PhoenixHost.Repo,
  auth_module: PhoenixHostWeb.ObanPowertoolsAuth,
  display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy
```

**Router mount pattern** ([examples/phoenix_host/lib/phoenix_host_web/router.ex](/Users/jon/projects/oban_powertools/examples/phoenix_host/lib/phoenix_host_web/router.ex:25)):
```elixir
scope "/ops/jobs" do
  pipe_through :browser

  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

**Auth seam pattern** ([examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex](/Users/jon/projects/oban_powertools/examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex:1)):
```elixir
defmodule PhoenixHostWeb.ObanPowertoolsAuth do
  @behaviour ObanPowertools.Auth

  def current_actor(%Plug.Conn{assigns: %{current_actor: actor}}), do: actor
  def current_actor(_), do: demo_actor()

  def authorize(actor, _action, _resource) when is_map(actor) do
    if Map.get(actor, :role, Map.get(actor, "role")) in [:ops, "ops"], do: :ok, else: {:error, :unauthorized}
  end
end
```

**Seed lane pattern** ([examples/phoenix_host/priv/repo/seeds.exs](/Users/jon/projects/oban_powertools/examples/phoenix_host/priv/repo/seeds.exs:4)):
```elixir
ops_actor = PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()

nightly_sync_attrs = %{
  name: "nightly_sync",
  source: "fixture",
  args: %{"scope" => "ops-demo"}
}
```

Planner guidance: copy this directory shape closely. For the historical fixture, remove the modern `display_policy` contract from the frozen source state, but keep the same host app structure so the upgrade harness can apply only documented steps.

---

### `examples/phoenix_host_upgrade_source/regenerate.sh` (utility, batch)

**Analog:** `examples/phoenix_host/regenerate.sh`

**Deterministic regeneration script pattern** ([examples/phoenix_host/regenerate.sh](/Users/jon/projects/oban_powertools/examples/phoenix_host/regenerate.sh:4)):
```bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANONICAL_DIR="${ROOT_DIR}/examples/phoenix_host"
TARGET_DIR="${ROOT_DIR}/examples/.phoenix_host_regen"
```

```bash
mix phx.new "${TARGET_DIR}" \
  --app phoenix_host \
  --module PhoenixHost \
  --database postgres \
  --no-assets \
  --no-dashboard \
  --no-mailer \
  --no-gettext \
  --no-install
```

**Manual follow-up notice pattern** ([examples/phoenix_host/regenerate.sh](/Users/jon/projects/oban_powertools/examples/phoenix_host/regenerate.sh:48)):
```bash
Manual host-owned follow-up still required:
- TODO: reapply the real auth/session seam
- TODO: reapply the real display policy
- TODO: restore the curated seeds and README support-truth wording
```

Planner guidance: if Phase 15 adds a maintainer-only regeneration script for the historical source fixture, copy this script’s shape and make the exact source commit explicit.

## Shared Patterns

### Historical Fixture Harness
**Source:** [test/support/example_host_contract.ex](/Users/jon/projects/oban_powertools/test/support/example_host_contract.ex:7), [test/support/fresh_host_contract.ex](/Users/jon/projects/oban_powertools/test/support/fresh_host_contract.ex:45)
**Apply to:** `test/support/example_host_contract.ex`, upgrade fixture copy logic
```elixir
target =
  System.tmp_dir!()
  |> Path.join("oban-powertools-#{lane}-#{System.unique_integer([:positive])}")

File.rm_rf!(target)
File.cp_r!(@fixture_dir, target)
rewrite_powertools_path!(target)
```

### Host Config + Router Contract
**Source:** [lib/mix/tasks/oban_powertools.install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex:5), [examples/phoenix_host/config/config.exs](/Users/jon/projects/oban_powertools/examples/phoenix_host/config/config.exs:19), [examples/phoenix_host/lib/phoenix_host_web/router.ex](/Users/jon/projects/oban_powertools/examples/phoenix_host/lib/phoenix_host_web/router.ex:25)
**Apply to:** docs, tests, historical fixture files
```elixir
config :oban_powertools,
  repo: MyApp.Repo,
  auth_module: MyAppWeb.ObanPowertoolsAuth,
  display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy
```

```elixir
scope "/ops/jobs" do
  pipe_through :browser

  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

### Fail-Fast Runtime Errors
**Source:** [lib/oban_powertools/runtime_config.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/runtime_config.ex:44)
**Apply to:** `guides/troubleshooting.md`, docs contract assertions
```elixir
"Oban Powertools requires :display_policy in config :oban_powertools, " <>
  "display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy before mounting policy-sensitive native operator pages."
```

### Native Proof Threshold
**Source:** [examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs](/Users/jon/projects/oban_powertools/examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs:12), [guides/first-operator-session.md](/Users/jon/projects/oban_powertools/guides/first-operator-session.md:47)
**Apply to:** upgrade guide, upgrade proof test, fixture README
```elixir
assert event.action == "cron.paused"
assert event.resource == "cron_entry:nightly_sync"
assert event.actor_id == "ops-demo"
```

### Claim-Based Docs Contract
**Source:** [test/oban_powertools/docs_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/docs_contract_test.exs:15)
**Apply to:** `test/oban_powertools/docs_contract_test.exs`
```elixir
assert source =~ "supported"
assert source =~ "tested"
assert source =~ "best-effort"
```

## No Analog Found

None. Every likely Phase 15 file has a strong in-repo analog already.

## Metadata

**Analog search scope:** `.github/workflows`, `test/support`, `test/oban_powertools`, `examples/phoenix_host`, `guides`, `README.md`, `lib/mix/tasks`, `lib/oban_powertools`
**Files scanned:** 21
**Pattern extraction date:** 2026-05-23
