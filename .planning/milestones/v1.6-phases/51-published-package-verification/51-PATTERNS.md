# Phase 51: Published-Package Verification - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 11 new/modified files
**Analogs found:** 11 / 11

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/hex_consumer/mix.exs` | config | CRUD | `examples/phoenix_host/mix.exs` | exact |
| `examples/hex_consumer/regenerate.sh` | utility | batch | `examples/phoenix_host/regenerate.sh` | exact |
| `examples/hex_consumer/config/config.exs` | config | request-response | `examples/phoenix_host/config/config.exs` | exact |
| `examples/hex_consumer/config/dev.exs` | config | request-response | `examples/phoenix_host/config/dev.exs` | exact |
| `examples/hex_consumer/config/test.exs` | config | request-response | `examples/phoenix_host/config/test.exs` | exact |
| `examples/hex_consumer/config/runtime.exs` | config | request-response | `examples/phoenix_host/config/runtime.exs` | exact |
| `examples/hex_consumer/test/test_helper.exs` | test | CRUD | `examples/phoenix_host/test/test_helper.exs` | exact |
| `examples/hex_consumer/test/support/conn_case.ex` | test | request-response | `examples/phoenix_host/test/support/conn_case.ex` | exact |
| `examples/hex_consumer/test/support/data_case.ex` | test | CRUD | `examples/phoenix_host/test/support/data_case.ex` | exact |
| `examples/hex_consumer/priv/repo/seeds.exs` | utility | CRUD | `examples/phoenix_host/priv/repo/seeds.exs` | exact |
| `examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs` | test | event-driven | `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` | exact |
| `.github/workflows/release.yml` (add `verify-published` job) | config | event-driven | `.github/workflows/release.yml` `publish-hex` job + `.github/workflows/host-contract-proof.yml` `first-session` job | exact |

---

## Pattern Assignments

### `examples/hex_consumer/mix.exs` (config)

**Analog:** `examples/phoenix_host/mix.exs` (all 77 lines)

**Core pattern** (lines 1–77 of analog) — copy in full, then apply these deltas:

| Line/section | phoenix_host value | hex_consumer value |
|---|---|---|
| Module name (L1) | `PhoenixHost.MixProject` | `HexConsumer.MixProject` |
| `app:` (L6) | `:phoenix_host` | `:hex_consumer` |
| `elixir:` (L8) | `"~> 1.15"` | `"~> 1.19"` (match library minimum) |
| `{:oban_powertools, ...}` (L48) | `path: "../.."` | `{:oban_powertools, "~> 0.5"}` — **the whole point** |
| `{:oban_web, ...}` (L49) | present | **omit entirely** — first-session test asserts `refute html =~ "Oban Web"` |
| `phoenix:` version (L43) | `"~> 1.8.7"` | `"~> 1.8"` (relax patch pin — version was just to match what was current; any 1.8 is fine) |
| `ecto_sql:` version (L45) | `"~> 3.13"` | `"~> 3.10"` (match RESEARCH.md recommendation) |

**Full analog imports/project block** (analog lines 1–16):
```elixir
defmodule PhoenixHost.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_host,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
    ]
  end
```

**Deps block** (analog lines 41–60) — exact analog, minus `oban_web`, with `oban_powertools` as hex dep:
```elixir
  defp deps do
    [
      {:phoenix, "~> 1.8.7"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:oban, "~> 2.18"},
      {:oban_powertools, path: "../.."},      # <-- CHANGE TO: {:oban_powertools, "~> 0.5"}
      {:oban_web, "~> 2.10", optional: true}, # <-- DELETE THIS LINE
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"}
    ]
  end
```

**Aliases block** (analog lines 68–76) — copy verbatim, only rename `PhoenixHost` → `HexConsumer` within alias strings if any reference module names (none do; these are mix task strings only — copy verbatim):
```elixir
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
```

**No committed `mix.lock`:** Add to repo-root `.gitignore`:
```
examples/hex_consumer/mix.lock
examples/hex_consumer/priv/repo/migrations/
examples/hex_consumer/_build/
examples/hex_consumer/deps/
```
Note: the existing `.gitignore` only covers root-level `/_build/` and `/deps/` — the `examples/hex_consumer/` subdirectory paths must be added explicitly.

---

### `examples/hex_consumer/regenerate.sh` (utility, batch)

**Analog:** `examples/phoenix_host/regenerate.sh` (all 68 lines)

**Core structure to copy verbatim** (analog lines 1–19) — the `set -euo pipefail`, `ROOT_DIR` derivation, `CANONICAL_DIR`/`TARGET_DIR` setup, and `replace_once` Ruby helper:
```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANONICAL_DIR="${ROOT_DIR}/examples/phoenix_host"
TARGET_DIR="${ROOT_DIR}/examples/.phoenix_host_regen"

replace_once() {
  local file="$1"
  local search="$2"
  local replace="$3"

  ruby -e '
    file, search, replace = ARGV
    source = File.read(file)
    abort("pattern not found in #{file}: #{search}") unless source.include?(search)
    File.write(file, source.sub(search, replace))
  ' "$file" "$search" "$replace"
}
```

**`mix phx.new` invocation** (analog lines 23–31) — copy verbatim, change `--app` and `--module`:
```bash
mix phx.new "${TARGET_DIR}" \
  --app phoenix_host \       # CHANGE TO: --app hex_consumer
  --module PhoenixHost \     # CHANGE TO: --module HexConsumer
  --database postgres \
  --no-assets \
  --no-dashboard \
  --no-mailer \
  --no-gettext \
  --no-install
```

**`replace_once` call** (analog lines 33–36) — change dep insertion to hex dep, omit `oban_web`:
```bash
# Analog inserts:
replace_once \
  "${TARGET_DIR}/mix.exs" \
  "{:postgrex, \">= 0.0.0\"}," \
  "{:postgrex, \">= 0.0.0\"},\n      {:oban, \"~> 2.18\"},\n      {:oban_powertools, path: \"../..\"},\n      {:oban_web, \"~> 2.10\", optional: true},"

# hex_consumer version:
replace_once \
  "${TARGET_DIR}/mix.exs" \
  "{:postgrex, \">= 0.0.0\"}," \
  "{:postgrex, \">= 0.0.0\"},\n      {:oban, \"~> 2.18\"},\n      {:oban_powertools, \"~> 0.5\"},"
```

**`mix deps.get` + install block** (analog lines 38–42) — copy verbatim; hex dep requires internet:
```bash
(
  cd "${TARGET_DIR}"
  mix deps.get          # requires hex.pm reachability (unlike phoenix_host's path dep)
  mix oban_powertools.install
)
```

**Migration copy step** (analog lines 44–46) — copy verbatim (hex_consumer committed migrations if any; or skip if not committed):
```bash
rm -rf "${TARGET_DIR}/priv/repo/migrations"
mkdir -p "${TARGET_DIR}/priv/repo"
cp -R "${CANONICAL_DIR}/priv/repo/migrations" "${TARGET_DIR}/priv/repo/migrations"
```

**Closing heredoc** (analog lines 48–67) — copy verbatim, update wording. Add internet-access warning not present in analog:
```bash
cat <<EOF

NOTE: This regenerate.sh requires hex.pm to be reachable (hex dep, not path dep).
Run only when oban_powertools is live on hex.pm.

Regenerated fixture tree: ${TARGET_DIR}
...
EOF
```

**Variable name deltas:**
- `CANONICAL_DIR` → `"${ROOT_DIR}/examples/hex_consumer"`
- `TARGET_DIR` → `"${ROOT_DIR}/examples/.hex_consumer_regen"`

---

### `examples/hex_consumer/config/config.exs` (config, request-response)

**Analog:** `examples/phoenix_host/config/config.exs` (all 46 lines)

**Copy verbatim, apply namespace substitution only:**

| Occurrence | phoenix_host value | hex_consumer value |
|---|---|---|
| `config :phoenix_host,` (L10) | `:phoenix_host` | `:hex_consumer` |
| `PhoenixHost.Repo` (L11, L14, L21) | `PhoenixHost.Repo` | `HexConsumer.Repo` |
| `config :phoenix_host, Oban,` (L14) | `:phoenix_host` | `:hex_consumer` |
| `config :oban_powertools,` (L19–22) auth_module | `PhoenixHostWeb.ObanPowertoolsAuth` | `HexConsumerWeb.ObanPowertoolsAuth` |
| display_policy | `PhoenixHostWeb.ObanPowertoolsDisplayPolicy` | `HexConsumerWeb.ObanPowertoolsDisplayPolicy` |
| `config :phoenix_host, PhoenixHostWeb.Endpoint,` (L25) | both atoms | `:hex_consumer`, `HexConsumerWeb.Endpoint` |
| `PhoenixHostWeb.ErrorHTML`, `ErrorJSON` (L28) | `PhoenixHostWeb.*` | `HexConsumerWeb.*` |
| `PhoenixHost.PubSub` (L31) | `PhoenixHost.PubSub` | `HexConsumer.PubSub` |

**Full critical block** (analog lines 19–22 — `:oban_powertools` config):
```elixir
config :oban_powertools,
  repo: PhoenixHost.Repo,           # -> HexConsumer.Repo
  auth_module: PhoenixHostWeb.ObanPowertoolsAuth,   # -> HexConsumerWeb.ObanPowertoolsAuth
  display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy  # -> HexConsumerWeb.ObanPowertoolsDisplayPolicy
```

---

### `examples/hex_consumer/config/dev.exs` (config)

**Analog:** `examples/phoenix_host/config/dev.exs` (all 85 lines)

**Copy verbatim, apply namespace substitution:**

| Occurrence | phoenix_host value | hex_consumer value |
|---|---|---|
| `config :phoenix_host, PhoenixHost.Repo,` (L4) | both atoms | `:hex_consumer`, `HexConsumer.Repo` |
| `database:` (L8) | `"phoenix_host_dev"` | `"hex_consumer_dev"` |
| `config :phoenix_host, PhoenixHostWeb.Endpoint,` (L14, L53) | both atoms | `:hex_consumer`, `HexConsumerWeb.Endpoint` |
| `phoenix_host_web` in live_reload patterns (L58–62) | `phoenix_host_web` | `hex_consumer_web` |
| `config :phoenix_host, dev_routes:` (L65) | `:phoenix_host` | `:hex_consumer` |

---

### `examples/hex_consumer/config/test.exs` (config, request-response)

**Analog:** `examples/phoenix_host/config/test.exs` (all 36 lines)

**Copy verbatim, apply namespace substitution:**

| Occurrence | phoenix_host value | hex_consumer value |
|---|---|---|
| `config :phoenix_host, PhoenixHost.Repo,` (L8) | both atoms | `:hex_consumer`, `HexConsumer.Repo` |
| `database:` (L12) | `"phoenix_host_test..."` | `"hex_consumer_test..."` |
| `config :phoenix_host, PhoenixHostWeb.Endpoint,` (L18) | both atoms | `:hex_consumer`, `HexConsumerWeb.Endpoint` |

**Critical DB name excerpt** (analog lines 8–14):
```elixir
config :phoenix_host, PhoenixHost.Repo,   # -> config :hex_consumer, HexConsumer.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phoenix_host_test#{System.get_env("MIX_TEST_PARTITION")}",  # -> "hex_consumer_test..."
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2
```

The `MIX_TEST_PARTITION` interpolation is preserved as-is — copy verbatim except the database name prefix.

---

### `examples/hex_consumer/config/runtime.exs` (config)

**Analog:** `examples/phoenix_host/config/runtime.exs` (all 107 lines)

**Copy verbatim, apply namespace substitution:**

| Occurrence | phoenix_host value | hex_consumer value |
|---|---|---|
| `config :phoenix_host, PhoenixHostWeb.Endpoint, server: true` (L20) | both atoms | `:hex_consumer`, `HexConsumerWeb.Endpoint` |
| `config :phoenix_host, PhoenixHostWeb.Endpoint,` http port (L23) | both atoms | `:hex_consumer`, `HexConsumerWeb.Endpoint` |
| `config :phoenix_host,` reverse_proxy block (L26–28) | `:phoenix_host` | `:hex_consumer` |
| `config :phoenix_host, PhoenixHost.Repo,` in prod block (L40) | both atoms | `:hex_consumer`, `HexConsumer.Repo` |
| `config :phoenix_host,` dns_cluster_query (L61) | `:phoenix_host` | `:hex_consumer` |
| `config :phoenix_host, PhoenixHostWeb.Endpoint,` url block (L63) | both atoms | `:hex_consumer`, `HexConsumerWeb.Endpoint` |

Note: the `reverse_proxy_headers` and `websocket_transport_expected` keys in the analog (lines 26–28) are specific to `phoenix_host` — these can be omitted in `hex_consumer` as they are not part of the minimal verification surface. All other blocks copy verbatim with module rename.

---

### `examples/hex_consumer/test/test_helper.exs` (test)

**Analog:** `examples/phoenix_host/test/test_helper.exs` (2 lines)

**Copy verbatim, substitute module name:**
```elixir
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(PhoenixHost.Repo, :manual)  # -> HexConsumer.Repo
```

Result:
```elixir
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(HexConsumer.Repo, :manual)
```

---

### `examples/hex_consumer/test/support/conn_case.ex` (test, request-response)

**Analog:** `examples/phoenix_host/test/support/conn_case.ex` (all 38 lines)

**Copy verbatim, apply namespace substitution:**

| Occurrence | phoenix_host value | hex_consumer value |
|---|---|---|
| Module name (L1) | `PhoenixHostWeb.ConnCase` | `HexConsumerWeb.ConnCase` |
| `@endpoint` (L23) | `PhoenixHostWeb.Endpoint` | `HexConsumerWeb.Endpoint` |
| `use PhoenixHostWeb, :verified_routes` (L25) | `PhoenixHostWeb` | `HexConsumerWeb` |
| `import PhoenixHostWeb.ConnCase` (L29) | `PhoenixHostWeb.ConnCase` | `HexConsumerWeb.ConnCase` |
| `PhoenixHost.DataCase.setup_sandbox` (L35) | `PhoenixHost.DataCase` | `HexConsumer.DataCase` |

**Full file** (analog lines 1–38):
```elixir
defmodule PhoenixHostWeb.ConnCase do          # -> HexConsumerWeb.ConnCase
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint PhoenixHostWeb.Endpoint       # -> HexConsumerWeb.Endpoint

      use PhoenixHostWeb, :verified_routes    # -> HexConsumerWeb

      import Plug.Conn
      import Phoenix.ConnTest
      import PhoenixHostWeb.ConnCase          # -> HexConsumerWeb.ConnCase
    end
  end

  setup tags do
    PhoenixHost.DataCase.setup_sandbox(tags)  # -> HexConsumer.DataCase
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
```

---

### `examples/hex_consumer/test/support/data_case.ex` (test, CRUD)

**Analog:** `examples/phoenix_host/test/support/data_case.ex` (all 58 lines)

**Copy verbatim, apply namespace substitution:**

| Occurrence | phoenix_host value | hex_consumer value |
|---|---|---|
| Module name (L1) | `PhoenixHost.DataCase` | `HexConsumer.DataCase` |
| `alias PhoenixHost.Repo` (L21) | `PhoenixHost.Repo` | `HexConsumer.Repo` |
| `import PhoenixHost.DataCase` (L26) | `PhoenixHost.DataCase` | `HexConsumer.DataCase` |
| `PhoenixHost.DataCase.setup_sandbox` (L32) | `PhoenixHost.DataCase` | `HexConsumer.DataCase` |
| `Ecto.Adapters.SQL.Sandbox.start_owner!(PhoenixHost.Repo, ...)` (L39) | `PhoenixHost.Repo` | `HexConsumer.Repo` |

**Critical sandbox setup** (analog lines 38–41):
```elixir
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(PhoenixHost.Repo, shared: not tags[:async])
    # -> HexConsumer.Repo
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
```

---

### `examples/hex_consumer/priv/repo/seeds.exs` (utility, CRUD)

**Analog:** `examples/phoenix_host/priv/repo/seeds.exs` (all 56 lines)

**Copy verbatim, apply namespace substitution. Seed data values are identical — the `nightly_sync` fixture must match exactly what the first-session test asserts.**

| Occurrence | phoenix_host value | hex_consumer value |
|---|---|---|
| `alias PhoenixHost.Repo` (L2) | `PhoenixHost.Repo` | `HexConsumer.Repo` |
| `PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()` (L4) | `PhoenixHostWeb.*` | `HexConsumerWeb.*` |
| `Repo.insert!` (L25) | implicit `PhoenixHost.Repo` via alias | implicit `HexConsumer.Repo` via alias |
| `IO.puts` string (L46) | `"Seeded PhoenixHost first-session fixture:"` | `"Seeded HexConsumer first-session fixture:"` |

**Critical: all `nightly_sync_attrs` values are identical** (analog lines 6–22) — copy verbatim. The test asserts specific field values (`source: "fixture"`, `overlap_policy: "queue_one"`, `catch_up_policy: "latest"`, etc.).

---

### `examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs` (test, event-driven)

**Analog:** `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` (all 91 lines)

**Copy verbatim, apply namespace substitution. No logic changes — the entire test body, all assertions, all selectors are identical.**

| Occurrence | phoenix_host value | hex_consumer value |
|---|---|---|
| Module name (L1) | `PhoenixHostWeb.ObanPowertoolsFirstSessionTest` | `HexConsumerWeb.ObanPowertoolsFirstSessionTest` |
| `use PhoenixHostWeb.ConnCase` (L2) | `PhoenixHostWeb.ConnCase` | `HexConsumerWeb.ConnCase` |
| `alias PhoenixHost.Repo` (L10) | `PhoenixHost.Repo` | `HexConsumer.Repo` |
| `PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()` (L15) | `PhoenixHostWeb.*` | `HexConsumerWeb.*` |

**Test body** (analog lines 12–90) — copy 100% verbatim. Every LiveView selector, assertion string, DB query, and field name is identical. The only file-level changes are the four namespace substitutions above.

**Full substitution summary for this file:**
```
s/PhoenixHostWeb.ObanPowertoolsFirstSessionTest/HexConsumerWeb.ObanPowertoolsFirstSessionTest/
s/use PhoenixHostWeb.ConnCase/use HexConsumerWeb.ConnCase/
s/alias PhoenixHost.Repo/alias HexConsumer.Repo/
s/PhoenixHostWeb.ObanPowertoolsAuth/HexConsumerWeb.ObanPowertoolsAuth/
```

---

### `.github/workflows/release.yml` — add `verify-published` job (config, event-driven)

**Primary analog:** `publish-hex` job in `.github/workflows/release.yml` (lines 136–213) — for job header structure (`needs:`, `if:`, `permissions:`, `env:`, `steps:` skeleton, checkout/setup-beam/cache pattern).

**Secondary analog:** `first-session` job in `.github/workflows/host-contract-proof.yml` (lines 127–151) — for Postgres service block with `OBAN_POWERTOOLS_SKIP_DB_BOOT: "1"`, `POSTGRES_DB: hex_consumer_test` variant.

**Job header** — from `publish-hex` analog (release.yml lines 136–144):
```yaml
  publish-hex:
    name: Publish to Hex.pm
    runs-on: ubuntu-latest
    needs: [release-please, gate-ci-green]
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    permissions:
      contents: read
    env:
      RELEASE_VERSION: ${{ needs.release-please.outputs.version }}
```

For `verify-published`, change to:
```yaml
  verify-published:
    name: Verify published package (REL-04)
    runs-on: ubuntu-latest
    needs: [release-please, publish-hex]           # publish-hex not gate-ci-green
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    permissions:
      contents: read
    env:
      OBAN_POWERTOOLS_SKIP_DB_BOOT: "1"            # suppress DB boot (from host-contract-proof analog)
```

**Postgres service block** — from `first-session` job in `host-contract-proof.yml` (lines 128–143):
```yaml
    env:
      OBAN_POWERTOOLS_SKIP_DB_BOOT: "1"
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: phoenix_host_test           # CHANGE TO: hex_consumer_test
        ports: ["5432:5432"]
        options: >-
          --health-cmd "pg_isready -U postgres"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
```

**Checkout + setup-beam + cache steps** — from `publish-hex` analog (release.yml lines 146–158):
```yaml
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
        with:
          ref: ${{ needs.release-please.outputs.tag_name }}
      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"
      - uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5
        with:
          path: |
            deps                                   # CHANGE TO: examples/hex_consumer/deps
            _build                                 # CHANGE TO: examples/hex_consumer/_build
          key: ${{ runner.os }}-publish-${{ hashFiles('mix.lock') }}
          # CHANGE KEY TO: ${{ runner.os }}-hex-consumer-${{ needs.release-please.outputs.version }}
```

**Install Hex + Rebar step** — from `publish-hex` analog (release.yml lines 160–163):
```yaml
      - name: Install Hex + Rebar
        run: |
          mix local.hex --force
          mix local.rebar --force
```
Copy verbatim — no change needed.

**Version-pin step** — NEW, no analog in existing codebase. From RESEARCH.md Focus Q1:
```yaml
      - name: Pin consumer to exact published version
        run: |
          VERSION="${{ needs.release-please.outputs.version }}"
          sed -i "s|{:oban_powertools, \"~> 0.5\"}|{:oban_powertools, \"== ${VERSION}\"}|" \
            examples/hex_consumer/mix.exs
```

**Remaining steps** (all use `working-directory: examples/hex_consumer`) — no direct analog; RESEARCH.md Focus Q3 provides the full sequence:
```yaml
      - name: Fetch hex consumer deps (from hex.pm)
        run: mix deps.get
        working-directory: examples/hex_consumer

      - name: Run installer from published tarball
        run: mix oban_powertools.install
        working-directory: examples/hex_consumer

      - name: Compile hex consumer
        run: mix compile --warnings-as-errors
        working-directory: examples/hex_consumer

      - name: Create and migrate database
        env:
          MIX_ENV: test
        run: mix ecto.create && mix ecto.migrate
        working-directory: examples/hex_consumer

      - name: Seed nightly_sync cron entry
        env:
          MIX_ENV: test
        run: mix run priv/repo/seeds.exs
        working-directory: examples/hex_consumer

      - name: Run first-session proof (REL-04)
        env:
          MIX_ENV: test
        run: mix test test/hex_consumer_web/oban_powertools_first_session_test.exs --trace
        working-directory: examples/hex_consumer
```

**Placement in release.yml:** Append after the closing line of the `publish-hex` job (line 213). No other jobs need modification.

---

## Shared Patterns

### Namespace Substitution Rule
**Apply to:** All 10 `examples/hex_consumer/` files.

Every occurrence of `PhoenixHost` → `HexConsumer` and `PhoenixHostWeb` → `HexConsumerWeb`. No other logic changes in any file.

```
PhoenixHost.MixProject    -> HexConsumer.MixProject
PhoenixHost.Application   -> HexConsumer.Application
PhoenixHost.Repo          -> HexConsumer.Repo
PhoenixHost.DataCase      -> HexConsumer.DataCase
PhoenixHost.PubSub        -> HexConsumer.PubSub
PhoenixHostWeb            -> HexConsumerWeb
:phoenix_host             -> :hex_consumer
"phoenix_host"            -> "hex_consumer"   (in DB names, app names)
"phoenix_host_test"       -> "hex_consumer_test"
"phoenix_host_dev"        -> "hex_consumer_dev"
```

### Postgres Service Block
**Source:** `host-contract-proof.yml` lines 128–143 (repeated in every DB-needing job)
**Apply to:** `verify-published` job in `release.yml`
```yaml
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: phoenix_host_test     # use hex_consumer_test in verify-published
        ports: ["5432:5432"]
        options: >-
          --health-cmd "pg_isready -U postgres"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
```

### OBAN_POWERTOOLS_SKIP_DB_BOOT env
**Source:** `host-contract-proof.yml` line 130 (present in every CI job in that workflow)
**Apply to:** `verify-published` job `env:` block
```yaml
    env:
      OBAN_POWERTOOLS_SKIP_DB_BOOT: "1"
```

### Action Pin Hashes
**Source:** `release.yml` and `host-contract-proof.yml` (verified pinned SHAs)
**Apply to:** `verify-published` job steps — use these exact pinned hashes:
```yaml
actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd        # v6
erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93        # v1.24.0
actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae           # v5
```

### Version Propagation via `needs.release-please.outputs`
**Source:** `release.yml` lines 31–35 (outputs declaration) and lines 144, 148 (consumption in `publish-hex`)
**Apply to:** `verify-published` job header and version-pin step
```yaml
# Already declared in release-please job:
outputs:
  release_created: ${{ steps.release.outputs.release_created }}
  tag_name:        ${{ steps.release.outputs.tag_name }}
  version:         ${{ steps.release.outputs.version }}
  sha:             ${{ steps.release.outputs.sha }}

# Consumed in verify-published exactly as publish-hex consumes it:
needs: [release-please, publish-hex]
# -> needs.release-please.outputs.version  (for sed pin and cache key)
# -> needs.release-please.outputs.tag_name (for checkout ref)
# -> needs.release-please.outputs.release_created (for if: condition)
```

---

## No Analog Found

No files in this phase lack a close analog. All 10 `examples/hex_consumer/` files are direct namespace-substitution copies of `examples/phoenix_host/` counterparts. The `verify-published` CI job composes patterns from two existing jobs (`publish-hex` + `first-session`) with one novel step (the version-pin `sed` command documented in RESEARCH.md).

---

## Metadata

**Analog search scope:** `examples/phoenix_host/`, `.github/workflows/`
**Files scanned:** 14 analog files read directly
**Pattern extraction date:** 2026-05-29
