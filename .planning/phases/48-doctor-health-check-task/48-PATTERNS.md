# Phase 48: Doctor Health-Check Task - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 8 new files
**Analogs found:** 7 / 8

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/oban_powertools.doctor.ex` | Mix task entry point | request-response | `lib/mix/tasks/oban_powertools.install.ex` (shape only) | partial-match (naming/module convention; not structural — install is Igniter-based) |
| `lib/oban_powertools/doctor.ex` | orchestrator + struct | request-response | `lib/oban_powertools/forensics.ex` | role-match (orchestrator calling sub-modules, returning structured results) |
| `lib/oban_powertools/doctor/checks.ex` | service (raw SQL) | request-response | `lib/oban_powertools/lifeline.ex` (archive_table_count) + `test/test_helper.exs` (catalog SQL idioms) | partial-match (raw `Ecto.Adapters.SQL.query!` against DB) |
| `lib/oban_powertools/doctor/formatter.ex` | utility (pure render) | transform | `lib/oban_powertools/forensics/evidence_bundle.ex` | partial-match (pure data-to-output transform, no DB) |
| `test/mix/tasks/oban_powertools.doctor_test.exs` | test (unit, no DB) | request-response | `test/mix/tasks/oban_powertools.install_test.exs` | exact (same test dir, same ExUnit.Case without DataCase) |
| `test/oban_powertools/doctor_test.exs` | test (integration) | request-response | `test/oban_powertools/cron_test.exs` | role-match (DataCase, async: false, calls module functions with repo()) |
| `test/oban_powertools/doctor/checks_test.exs` | test (DB catalog) | request-response | `test/oban_powertools/cron_test.exs` | role-match (DataCase, async: false, repo() helper) |
| `test/oban_powertools/doctor/formatter_test.exs` | test (pure unit) | transform | `test/mix/tasks/oban_powertools.install_test.exs` | role-match (pure ExUnit.Case, no DB, assert on output) |

---

## Pattern Assignments

### `lib/mix/tasks/oban_powertools.doctor.ex` (Mix task entry point, request-response)

**Analog:** `lib/mix/tasks/oban_powertools.install.ex` (naming convention only — the task file there uses `use Igniter.Mix.Task`, NOT a structural template for doctor)

**What to copy from the analog:**
- Module naming convention: `Mix.Tasks.ObanPowertools.Doctor`
- Location: `lib/mix/tasks/oban_powertools.doctor.ex`
- `@shortdoc` attribute

**What NOT to copy:**
- Do NOT use `use Igniter.Mix.Task` — doctor is a plain `use Mix.Task`
- Do NOT define `info/2` or `igniter/1` — doctor uses `run/1`

**Plain Mix.Task pattern (from RESEARCH.md Pattern 1 — verified from `deps/ecto_sql/lib/mix/tasks/ecto.migrate.ex`):**

```elixir
defmodule Mix.Tasks.ObanPowertools.Doctor do
  use Mix.Task

  @shortdoc "Diagnose Oban DB/config health (read-only)"

  @switches [
    repo: :string,
    prefix: :string,
    oban_name: :string,
    format: :string,
    strict: :boolean
  ]

  @impl Mix.Task
  def run(argv) do
    {opts, _args, _invalid} = OptionParser.parse(argv, strict: @switches)
    repo_module = resolve_repo(opts)

    case Ecto.Migrator.with_repo(repo_module, fn repo ->
      prefix  = resolve_prefix(opts)
      results = ObanPowertools.Doctor.run(repo, prefix: prefix, strict: Keyword.get(opts, :strict, false))
      format  = Keyword.get(opts, :format, "human")
      ObanPowertools.Doctor.Formatter.print(results, format: String.to_atom(format))
      ObanPowertools.Doctor.exit_code_for(results)
    end, pool_size: 2) do
      {:ok, exit_code, _apps} -> System.halt(exit_code)
      {:error, reason}        -> fatal!("Could not start repo: #{inspect(reason)}")
    end
  end
end
```

**Repo resolution pattern** (from `lib/oban_powertools/runtime_config.ex` lines 8-13 and 44-58):

```elixir
# In the Mix task — delegate to RuntimeConfig, applying CLI override:
defp resolve_repo(opts) do
  case Keyword.get(opts, :repo) do
    nil ->
      ObanPowertools.RuntimeConfig.repo!()
    repo_string ->
      # Use String.to_existing_atom only — never String.to_atom on CLI input
      Module.safe_concat([repo_string])
  end
end
```

**Prefix resolution pattern** (from RESEARCH.md Research Question 6):

```elixir
defp resolve_prefix(opts) do
  cond do
    prefix = Keyword.get(opts, :prefix) -> prefix
    true ->
      oban_name = Keyword.get(opts, :oban_name, "Oban")
      oban_key  = String.to_existing_atom(oban_name) rescue nil
      case oban_key && Application.get_env(:oban, oban_key) do
        config when is_list(config) -> Keyword.get(config, :prefix, "public")
        _                           -> "public"
      end
  end
end
```

**Critical pitfall:** Call `System.halt/1` AFTER `with_repo` returns — never inside the callback. The callback must return the exit code as a plain integer value.

---

### `lib/oban_powertools/doctor.ex` (orchestrator + Finding struct, request-response)

**Analog:** `lib/oban_powertools/forensics.ex`

**Imports/alias pattern** (forensics.ex lines 1-13):

```elixir
defmodule ObanPowertools.Doctor do
  alias ObanPowertools.Doctor.Checks
  alias ObanPowertools.Doctor.Formatter
```

**Orchestrator pattern** — `bundle/2` in forensics.ex lines 15-35 shows the shape: accept `repo` + `opts`, delegate to sub-module functions, accumulate structured results:

```elixir
# forensics.ex lines 15-35 (orchestrator shape to copy)
def bundle(params, opts \\ []) when is_map(params) do
  repo = Keyword.get(opts, :repo, Application.fetch_env!(:oban_powertools, :repo))
  selectors = selectors(params)
  cond do
    selectors.workflow_id -> workflow_bundle(repo, selectors)
    ...
  end
end
```

**Doctor's equivalent run/2 shape:**

```elixir
def run(repo, opts \\ []) do
  prefix = Keyword.get(opts, :prefix, "public")
  strict = Keyword.get(opts, :strict, false)

  []
  |> Kernel.++(Checks.index_validity(repo, prefix))
  |> Kernel.++(Checks.missing_indexes(repo, prefix))
  |> Kernel.++(Checks.oban_migration_version(repo, prefix))
  |> Kernel.++(Checks.powertools_tables(repo))          # always public schema — see RESEARCH open Q3
  |> Kernel.++(Checks.uniqueness_timeout_risk(repo, prefix, strict: strict))
end

def exit_code_for(findings) do
  findings
  |> Enum.map(& &1.severity)
  |> Enum.reduce(0, fn
    :error,   _acc -> 2
    :warning, acc when acc < 2 -> max(acc, 1)
    _,        acc -> acc
  end)
end
```

**Finding struct definition** (no existing analog — new struct):

```elixir
defmodule ObanPowertools.Doctor.Finding do
  @enforce_keys [:check, :severity, :message]
  defstruct [:check, :severity, :message, :remediation]
end
```

---

### `lib/oban_powertools/doctor/checks.ex` (service, raw SQL, request-response)

**Analog:** `lib/oban_powertools/lifeline.ex` (line 584-588 for raw `Ecto.Adapters.SQL.query!` against the DB) and `test/test_helper.exs` (lines 26-206 for the `SELECT to_regclass` and `CREATE INDEX` SQL patterns against the test DB)

**Raw SQL invocation pattern** (lifeline.ex lines 584-588):

```elixir
defp archive_table_count(repo) do
  %{rows: [[count]]} =
    Ecto.Adapters.SQL.query!(repo, "SELECT count(*) FROM oban_powertools_repair_archives", [])
  count
end
```

**For doctor, use the non-bang variant** since DB errors are findings, not crashes:

```elixir
case repo.query(sql, [prefix], log: false) do
  {:ok, %{rows: rows}}     -> ...process rows...
  {:error, reason}         -> [%Finding{check: :check_name, severity: :error,
                                        message: "Cannot query catalog: #{inspect(reason)}",
                                        remediation: "Check DB connectivity and permissions."}]
end
```

**Table presence pattern** (test_helper.exs lines 26-30 — `to_regclass` idiom):

```elixir
# test_helper.exs uses this pattern for checking table existence:
repo
|> Ecto.Adapters.SQL.query!("SELECT to_regclass('public.oban_powertools_audit_events')")
|> Map.fetch!(:rows)
|> List.first()
|> List.first()
# nil means absent, non-nil means present
```

Doctor uses parameterized `information_schema` instead (safer, prefix-aware):

```elixir
sql = """
SELECT table_name
FROM information_schema.tables
WHERE table_schema = $1
  AND table_name = ANY($2)
  AND table_type = 'BASE TABLE'
"""
{:ok, %{rows: rows}} = repo.query(sql, [schema, table_list], log: false)
present = Enum.map(rows, fn [name] -> name end)
```

**Index catalog query pattern** (derived from Oban migration source at `examples/phoenix_host/deps/oban/lib/oban/migrations/postgres.ex` lines 52-63 — verified in RESEARCH.md):

```elixir
# NEVER interpolate prefix — use $1 binding
sql = """
SELECT i.relname, ix.indisvalid, ix.indisready
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n  ON n.oid = c.relnamespace
JOIN pg_catalog.pg_index     ix ON ix.indrelid = c.oid
JOIN pg_catalog.pg_class     i  ON i.oid = ix.indexrelid
WHERE c.relname = 'oban_jobs'
  AND n.nspname = $1
  AND NOT ix.indisprimary
ORDER BY i.relname
"""
{:ok, %{columns: _cols, rows: rows}} = repo.query(sql, [prefix], log: false)
```

**Module alias pattern for Finding struct** (copy from forensics.ex lines 1-5 structure):

```elixir
defmodule ObanPowertools.Doctor.Checks do
  alias ObanPowertools.Doctor.Finding
```

---

### `lib/oban_powertools/doctor/formatter.ex` (pure render utility, transform)

**Analog:** No exact analog in this repo — all existing modules have DB access. Closest is the pure-function sections of `lib/oban_powertools/forensics/evidence_bundle.ex` (data-in, structured-output-out, no side effects).

**ANSI pattern** (stdlib, from RESEARCH.md Pattern 3):

```elixir
defp colorize(text, color) do
  if IO.ANSI.enabled?() do
    [color, text, IO.ANSI.reset()] |> IO.ANSI.format() |> IO.iodata_to_binary()
  else
    text
  end
end
```

**Jason pattern** (display_policy.ex line 144 for JSON encoding in this codebase):

```elixir
# From lib/oban_powertools/display_policy.ex line 144:
Jason.encode!(value || %{}, pretty: true)

# Doctor formatter equivalent:
Jason.encode!(%{schema_version: 1, prefix: prefix, findings: findings_list, exit_code: code})
```

**Module structure** (no DB, pure transform — no `use Ecto.Schema`, no `import Ecto.Query`):

```elixir
defmodule ObanPowertools.Doctor.Formatter do
  alias ObanPowertools.Doctor.Finding

  def print(findings, opts \\ []) do
    IO.puts(format(findings, opts))
  end

  def format(findings, opts \\ []) do
    case Keyword.get(opts, :format, :human) do
      :json  -> json(findings, opts)
      _      -> human(findings, opts)
    end
  end

  defp human(findings, _opts) do ... end
  defp json(findings, _opts)  do Jason.encode!(...) end
end
```

---

### `test/mix/tasks/oban_powertools.doctor_test.exs` (unit test, no DB)

**Analog:** `test/mix/tasks/oban_powertools.install_test.exs`

**Full file pattern** (install_test.exs lines 1-53 — exact structural template):

```elixir
# install_test.exs lines 1-9 — use ExUnit.Case (not DataCase — no DB needed)
defmodule Mix.Tasks.ObanPowertools.DoctorTest do
  use ExUnit.Case

  # Pattern: test CLI module is loaded and exports expected functions
  test "defines a plain Mix.Task" do
    Code.ensure_loaded?(Mix.Tasks.ObanPowertools.Doctor)
    assert function_exported?(Mix.Tasks.ObanPowertools.Doctor, :run, 1)
  end

  # Pattern: test source-level contracts (install_test.exs lines 11-27)
  test "source declares all expected switches" do
    # check @switches include :repo, :prefix, :oban_name, :format, :strict
  end
end
```

**Key difference from install test:** Doctor test covers CLI flag parsing and JSON schema contract (not file-content assertions). No Igniter or file-writing to assert.

---

### `test/oban_powertools/doctor_test.exs` (orchestrator integration test)

**Analog:** `test/oban_powertools/cron_test.exs`

**Setup/header pattern** (cron_test.exs lines 1-6):

```elixir
defmodule ObanPowertools.DoctorTest do
  use ObanPowertools.DataCase, async: false   # async: false — catalog tests are not isolated

  alias ObanPowertools.Doctor
  alias ObanPowertools.Doctor.Finding
  alias ObanPowertools.TestRepo
```

**DataCase checkout** (data_case.ex lines 13-21 — automatic via `use ObanPowertools.DataCase`):

```elixir
# data_case.ex provides:
setup tags do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(ObanPowertools.TestRepo)
  unless tags[:async] do
    Ecto.Adapters.SQL.Sandbox.mode(ObanPowertools.TestRepo, {:shared, self()})
  end
  :ok
end
```

**repo() helper pattern** (cron_test.exs — used as `repo()` throughout):

```elixir
# This helper exists in DataCase via the alias ObanPowertools.TestRepo:
defp repo, do: ObanPowertools.TestRepo
```

**Test shape for exit_code_for/1** (pure unit, no DB — no DataCase needed):

```elixir
# In doctor_test.exs, separate describe blocks:
describe "exit_code_for/1" do
  test "returns 0 when findings is empty" do
    assert Doctor.exit_code_for([]) == 0
  end
  test "returns 1 when only warnings present" do
    assert Doctor.exit_code_for([%Finding{check: :x, severity: :warning, message: "w"}]) == 1
  end
  test "returns 2 when any error present" do
    assert Doctor.exit_code_for([
      %Finding{check: :x, severity: :warning, message: "w"},
      %Finding{check: :y, severity: :error, message: "e"}
    ]) == 2
  end
end
```

---

### `test/oban_powertools/doctor/checks_test.exs` (DB catalog tests)

**Analog:** `test/oban_powertools/cron_test.exs`

**DataCase + async:false pattern** (cron_test.exs line 2):

```elixir
defmodule ObanPowertools.Doctor.ChecksTest do
  use ObanPowertools.DataCase, async: false  # REQUIRED — catalog DDL is not transactional

  alias ObanPowertools.Doctor.Checks
  alias ObanPowertools.Doctor.Finding
  alias ObanPowertools.TestRepo
```

**Raw SQL in test setup** (test_helper.exs lines 35-60 — pattern for issuing DDL in tests):

```elixir
# test_helper.exs uses Ecto.Adapters.SQL.query! directly against repo for DDL:
Ecto.Adapters.SQL.query!(
  repo,
  "CREATE INDEX IF NOT EXISTS ... ON ...",
  []
)

# Doctor check tests use the same pattern in setup/on_exit:
setup do
  on_exit(fn ->
    Ecto.Adapters.SQL.query!(
      TestRepo,
      "CREATE INDEX CONCURRENTLY IF NOT EXISTS oban_jobs_args_index ON public.oban_jobs USING GIN (args)",
      []
    )
  end)
  :ok
end
```

**Note on INVALID index tests:** Cannot create a real INVALID index in tests. Pattern: pass fake catalog row data directly to the finding-construction logic (separate private function accepting rows), test that logic as a unit.

---

### `test/oban_powertools/doctor/formatter_test.exs` (pure unit, no DB)

**Analog:** `test/mix/tasks/oban_powertools.install_test.exs` (pure ExUnit.Case, no DataCase)

**Pattern** (install_test.exs lines 1-5):

```elixir
defmodule ObanPowertools.Doctor.FormatterTest do
  use ExUnit.Case  # No DataCase — formatter is pure

  alias ObanPowertools.Doctor.{Finding, Formatter}

  test "human format includes severity labels and remediation hints" do
    findings = [%Finding{check: :index_validity, severity: :error,
                         message: "INVALID index ...", remediation: "REINDEX INDEX CONCURRENTLY ..."}]
    output = Formatter.format(findings, format: :human)
    assert output =~ "INVALID index"
    assert output =~ "REINDEX INDEX CONCURRENTLY"
  end

  test "json format includes schema_version field" do
    output = Formatter.format([], format: :json)
    {:ok, decoded} = Jason.decode(output)
    assert decoded["schema_version"] == 1
  end
end
```

---

## Shared Patterns

### Repo Resolution with Error Tone
**Source:** `lib/oban_powertools/runtime_config.ex` lines 8-13, 44-58
**Apply to:** `lib/mix/tasks/oban_powertools.doctor.ex` (resolve_repo/1)

```elixir
# runtime_config.ex lines 8-13 — layered lookup, raise with setup message on missing
def repo(opts \\ []) do
  Keyword.get(opts, :repo) || configured(:repo, opts)
end

# lines 44-58 — setup error message tone for the :repo key:
defp setup_error(:repo) do
  "Oban Powertools requires :repo in config :oban_powertools, repo: MyApp.Repo " <>
    "before using persistence-backed features."
end
```

Doctor's cannot-run path must match this message tone: "Run `mix oban_powertools.doctor --repo MyApp.Repo` or set `config :oban_powertools, repo: MyApp.Repo`."

### Raw SQL with Repo (Ecto.Adapters.SQL.query!)
**Source:** `lib/oban_powertools/lifeline.ex` lines 584-588
**Apply to:** `lib/oban_powertools/doctor/checks.ex`

```elixir
# lifeline.ex lines 584-588
defp archive_table_count(repo) do
  %{rows: [[count]]} =
    Ecto.Adapters.SQL.query!(repo, "SELECT count(*) FROM oban_powertools_repair_archives", [])
  count
end
```

Doctor uses the non-bang `repo.query/3` instead (errors become findings, not crashes). The `log: false` option silences query logging.

### DataCase + async:false for DB Tests
**Source:** `test/support/data_case.ex` lines 13-21, `test/oban_powertools/cron_test.exs` line 2
**Apply to:** `test/oban_powertools/doctor_test.exs`, `test/oban_powertools/doctor/checks_test.exs`

```elixir
# data_case.ex lines 1-22
defmodule ObanPowertools.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias ObanPowertools.TestRepo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ObanPowertools.TestRepo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(ObanPowertools.TestRepo, {:shared, self()})
    end
    :ok
  end
end
```

### Ecto.Migrator.with_repo/2 Boot
**Source:** `test/test_helper.exs` lines 14-17
**Apply to:** `lib/mix/tasks/oban_powertools.doctor.ex`

```elixir
# test_helper.exs lines 14-17 — shows the with_repo pattern used in this repo:
{:ok, _, _} =
  Ecto.Migrator.with_repo(ObanPowertools.TestRepo, fn repo ->
    Ecto.Migrator.run(repo, ..., :up, all: true)
  end)
```

Doctor's usage is `Ecto.Migrator.with_repo(repo_module, fn repo -> ... end, pool_size: 2)` — same pattern, `pool_size: 2` for minimal connection footprint.

### Module Orchestrator → Sub-module Delegation
**Source:** `lib/oban_powertools/forensics.ex` lines 15-35
**Apply to:** `lib/oban_powertools/doctor.ex`

```elixir
# forensics.ex lines 15-35 — orchestrator accepts repo + opts, delegates to sub-modules,
# accumulates structured results, returns a single map/list
def bundle(params, opts \\ []) when is_map(params) do
  repo = Keyword.get(opts, :repo, Application.fetch_env!(:oban_powertools, :repo))
  selectors = selectors(params)
  cond do
    selectors.workflow_id   -> workflow_bundle(repo, selectors)
    selectors.incident_fingerprint -> lifeline_bundle(repo, selectors)
    ...
  end
end
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/oban_powertools/doctor/formatter.ex` | utility | transform | No existing pure formatter module in this repo; all output rendering is in LiveView components or Jason inline. Use RESEARCH.md Pattern 3 (ANSI) + Jason directly. |

---

## Notes for Planner

1. **Install task is NOT a structural template.** `lib/mix/tasks/oban_powertools.install.ex` uses `use Igniter.Mix.Task` with `igniter/1` callback. Doctor uses plain `use Mix.Task` with `run/1`. The only things to copy from install.ex are: the module naming convention, the `@shortdoc` attribute, and the migration-set grouping (for the D-12 table manifest).

2. **Finding struct location.** The `%Finding{}` struct could live in `doctor.ex` or in a dedicated `doctor/finding.ex`. Given the mild-overbuilding caution from PROJECT.md §v1.6, put it at the top of `doctor.ex` as a nested defstruct — one fewer file.

3. **`powertools_tables` check always uses `"public"` schema** (RESEARCH.md Open Question 3). Powertools tables are not Oban-prefixed. The `prefix` option in doctor affects only `oban_jobs` index/migration checks, not the Powertools table manifest. Planner to confirm and document.

4. **Test for INVALID index** cannot use real DDL. Pattern: extract a private `findings_for_rows/1` function in Checks that accepts `[{name, is_valid, is_ready}]` tuples, test it directly in FormatterTest or a unit block in checks_test.exs.

5. **`Ecto.Adapters.SQL.query!` vs `repo.query/3`:** The codebase uses `Ecto.Adapters.SQL.query!` in test_helper.exs for DDL. The doctor's `checks.ex` should use `repo.query(sql, params, log: false)` (non-bang, returns `{:ok, ...} | {:error, ...}`) so errors become `cannot-run` findings rather than raised exceptions.

---

## Metadata

**Analog search scope:** `lib/`, `test/`, `test/support/`
**Files scanned:** 9 source files + test_helper.exs
**Pattern extraction date:** 2026-05-29
