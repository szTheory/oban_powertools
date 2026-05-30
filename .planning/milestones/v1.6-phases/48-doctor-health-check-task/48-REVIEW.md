---
phase: 48-doctor-health-check-task
reviewed: 2026-05-29T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - lib/oban_powertools/doctor.ex
  - lib/oban_powertools/doctor/checks.ex
  - lib/oban_powertools/doctor/formatter.ex
  - lib/mix/tasks/oban_powertools.doctor.ex
  - test/oban_powertools/doctor_test.exs
  - test/oban_powertools/doctor/checks_test.exs
  - test/oban_powertools/doctor/formatter_test.exs
  - test/mix/tasks/oban_powertools.doctor_test.exs
  - test/support/example_host_contract.ex
  - test/oban_powertools/example_host_contract_test.exs
  - .github/workflows/host-contract-proof.yml
findings:
  critical: 3
  warning: 5
  info: 1
  total: 9
status: issues_found
---

# Phase 48: Code Review Report

**Reviewed:** 2026-05-29
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

This phase implements `mix oban_powertools.doctor`, a read-only Oban health-check Mix task. The core
architecture is sound: SQL is parameterized where possible, `System.halt` is correctly placed after
`with_repo` returns, atoms are not created from CLI input for the repo flag, and the JSON
`schema_version: 1` field is present. Three blockers were found: an unguarded
`String.to_integer/1` call that will crash on a non-numeric DB comment, a hardcoded `nil` for
`oban_version_db` in the JSON output (breaking the documented schema), and silent error suppression
in two sub-checks that causes them to report clean when the DB is actually unreachable. Five
warnings round out the review.

---

## Critical Issues

### CR-01: `String.to_integer/1` on unvalidated pg_class comment — crashes on non-integer DB value

**File:** `lib/oban_powertools/doctor/checks.ex:170`

**Issue:** The `oban_migration_version/2` check matches the `obj_description` result with `is_binary(v)`
and passes it directly to `String.to_integer/1`. `obj_description` on `oban_jobs` returns whatever
Oban stored as the table comment. If the comment is absent (matched by the `{:ok, _} -> 0` arm) or
a non-integer string (e.g. a DBA manually set a prose comment, or Oban's future migration format
changes), `String.to_integer/1` raises `ArgumentError` at runtime. This is an unhandled exception
inside a `case` branch that has no rescue, so it propagates out of `oban_migration_version/2` and
crashes the entire `Doctor.run/2` pipeline — producing no findings and a non-zero exit for a
completely unexpected reason.

```elixir
# CURRENT — crashes on non-integer comment
{:ok, %{rows: [[v]]}} when is_binary(v) -> String.to_integer(v)

# FIX — guard against parse failure
{:ok, %{rows: [[v]]}} when is_binary(v) ->
  case Integer.parse(v) do
    {n, ""} -> n
    _ -> 0
  end
```

---

### CR-02: `oban_version_db` is hardcoded `nil` in the Mix task — JSON schema contract broken

**File:** `lib/mix/tasks/oban_powertools.doctor.ex:105`

**Issue:** The documented `schema_version: 1` JSON schema includes `"oban_version_db"` as the
database's installed Oban migration version. The formatter docstring explicitly defines this field.
But the Mix task passes `oban_version_db: nil` unconditionally — the value is never read from the
checks. The `oban_migration_version/2` check does compute `db_version` internally but does not
return it to the caller; and `Doctor.run/2` returns only `[Finding.t()]` with no way to surface the
version integer.

Result: every `--format json` invocation emits `"oban_version_db": null`, regardless of what the
database actually contains. The host-contract test asserts `json["exit_code"] == result.json_status`
(correct) but does not assert that `oban_version_db` is non-null on a healthy host, so this
breakage is invisible to the test suite.

**Fix:** Either:

(a) Add `db_version` to the `Doctor.run/2` return shape (e.g. return `{findings, meta}` or a
dedicated result struct), and thread it through to the Mix task; or

(b) Make `oban_migration_version/2` return a `{findings, db_version}` tuple and have
`Doctor.run/2` accumulate it alongside findings.

The simplest minimal fix is option (b):

```elixir
# checks.ex — return {findings, db_version}
def oban_migration_version(repo, prefix) do
  # ... (query same as now)
  {findings, db_version}
end

# doctor.ex — accumulate db_version from the tuple
def run(repo, opts \\ []) do
  {version_findings, db_version} = Checks.oban_migration_version(repo, prefix)
  findings = [] ++ ... ++ version_findings ++ ...
  {findings, db_version}
end

# mix task — pass it through
{findings, oban_version_db} = ObanPowertools.Doctor.run(repo, ...)
ObanPowertools.Doctor.Formatter.print(findings,
  oban_version_db: oban_version_db, ...)
```

---

### CR-03: Two sub-checks silently swallow DB errors and report clean — masks connectivity failures

**File:** `lib/oban_powertools/doctor/checks.ex:340-342` and `lib/oban_powertools/doctor/checks.ex:376-378`

**Issue:** Both `check_gin_indexes/3` and `check_eligible_job_count/3` return `[]` on query
failure:

```elixir
# check_gin_indexes — line 340
{:error, _reason} ->
  []

# check_eligible_job_count — line 376
{:error, _reason} ->
  []
```

An empty findings list is indistinguishable from "check passed." If the DB is unreachable for
these specific queries (temporary network blip, permission change, statement timeout), these two
sub-checks silently report healthy. The outer `uniqueness_timeout_risk/3` check then returns `[]`,
and the caller adds nothing to the findings list. The task exits 0 — falsely indicating the system
is healthy.

This is inconsistent with all other checks in the module, which return a cannot-run `:error`
finding on DB failure. The inconsistency is not documented as intentional.

**Fix:** Return a cannot-run finding on error, consistent with the other checks:

```elixir
# check_gin_indexes error arm
{:error, reason} ->
  [%Finding{
    check: :uniqueness_timeout_risk,
    severity: :error,
    message: "Cannot query pg_catalog (check_gin_indexes): #{inspect(reason)}",
    remediation: "Check DB connectivity and permissions."
  }]

# check_eligible_job_count error arm
{:error, reason} ->
  [%Finding{
    check: :uniqueness_timeout_risk,
    severity: :error,
    message: "Cannot query eligible job count: #{inspect(reason)}",
    remediation: "Check DB connectivity and permissions."
  }]
```

---

## Warnings

### WR-01: `db_version > expected_version` silently passes — forward-migration drift is undetected

**File:** `lib/oban_powertools/doctor/checks.ex:177-202`

**Issue:** The `cond` in `oban_migration_version/2` handles `db_version == 0` (missing table),
`db_version < expected_version` (drift behind), and `true` (everything else, including `db_version
> expected_version`). A database that has been migrated ahead of the installed library version
silently passes the check. Oban's migrations are forward-compatible by design, so this is not a
crash, but the doctor task claiming `Status: OK` when the DB is running a migration version the
library does not know about is misleading and could hide operator errors (wrong app version
deployed against a pre-migrated DB).

**Fix:** Add an explicit arm for `db_version > expected_version`:

```elixir
db_version > expected_version ->
  [%Finding{
    check: :oban_migration_version,
    severity: :warning,
    message:
      "DB Oban migrations at v#{db_version} exceed installed library version v#{expected_version} " <>
        "— ensure the deployed library matches the DB migration state",
    remediation: "Check that oban_powertools and :oban dependencies are pinned to matching versions."
  }]
```

---

### WR-02: `valid_identifier?/1` rejects mixed-case Postgres schema names — false error finding

**File:** `lib/oban_powertools/doctor/checks.ex:397-401`

**Issue:** The regex `~r/^[a-z_][a-z0-9_]*$/` rejects any prefix containing uppercase letters.
Postgres schema names are case-folded to lowercase by the server when unquoted, but a user who
configured Oban with `prefix: "MySchema"` (a quoted identifier requiring exact case) passes this
value through CLI flags as `--prefix MySchema`. The `valid_identifier?/1` guard returns `false`,
so `check_eligible_job_count/3` returns an `:error` finding stating the prefix is invalid — even
though the schema exists and is perfectly valid. The other four checks still run correctly (they
parameterize the prefix via `$1`), so the task exits 2 for a phantom reason.

**Fix:** Either document that only lowercase schema names are supported (doc-only change) and emit
a clearer error message, or broaden the regex to match Postgres's actual unquoted-identifier rules:

```elixir
# Allow uppercase (they will be folded by PG for unquoted identifiers)
defp valid_identifier?(prefix) when is_binary(prefix) do
  Regex.match?(~r/^[a-zA-Z_][a-zA-Z0-9_]*$/, prefix)
end
```

---

### WR-03: Unknown finding severity silently contributes exit code 0 — severity typos go undetected

**File:** `lib/oban_powertools/doctor.ex:26-30`

**Issue:** The `exit_code_for/1` reducer has a catch-all `_, acc -> acc` clause:

```elixir
|> Enum.reduce(0, fn
  :error, _acc -> 2
  :warning, acc when acc < 2 -> max(acc, 1)
  _, acc -> acc
end)
```

A `Finding` struct with an unexpected `:severity` value (e.g. `:info`, `:critical`, or a typo
like `:err`) will silently contribute `0` to the exit code. The Finding struct has no typespec
enforcement on the `:severity` field (it could be any term). Future contributors adding a new
severity tier (e.g. `:info`) will get no signal that it is being silently ignored by the exit-code
logic.

**Fix:** Add a `@type severity :: :error | :warning` typespec to the `Finding` struct and change
the catch-all to raise or warn:

```elixir
_, acc ->
  # Unknown severity — treat as warning to avoid silent false-healthy
  max(acc, 1)
```

Or, more defensively, add a typespec guard:

```elixir
defmodule ObanPowertools.Doctor.Finding do
  @type severity :: :error | :warning
  @type t :: %__MODULE__{
    check: atom(),
    severity: severity(),
    message: String.t(),
    remediation: String.t() | nil
  }
  @enforce_keys [:check, :severity, :message]
  defstruct [:check, :severity, :message, :remediation]
end
```

---

### WR-04: `check_eligible_job_count/3` constructs SQL with interpolated string literals instead of parameters

**File:** `lib/oban_powertools/doctor/checks.ex:354-357`

**Issue:** Although `@eligible_states` is a compile-time constant (not user input), the SQL is
constructed via string interpolation of unquoted string values:

```elixir
states_list = Enum.map_join(@eligible_states, ",", &"'#{&1}'")
sql = "SELECT count(*) FROM #{prefix}.oban_jobs WHERE state IN (#{states_list})"
```

The `prefix` is validated by `valid_identifier?/1` before reaching this point, and `@eligible_states`
is truly a module attribute — so there is no injection vector today. However, the approach:

1. Embeds a pattern that looks like SQL injection — future contributors who copy this pattern for
   mutable data will introduce a real vulnerability.
2. Bypasses Postgres's `$N`-parameterized query protocol entirely for the `IN` clause, preventing
   the DB from caching the plan.
3. The `ANY($1)` pattern used in `powertools_tables/1` (line 222) is the correct approach and
   already proven to work with array parameters.

**Fix:** Use `ANY($2)` with a parameterized array:

```elixir
sql = "SELECT count(*) FROM #{prefix}.oban_jobs WHERE state = ANY($1)"
case repo.query(sql, [@eligible_states], log: false) do
  {:ok, %{rows: [[count]]}} when count >= @uniqueness_backlog_threshold -> ...
```

The prefix still requires identifier injection (no `$N` for schema names in Postgres), so the
`valid_identifier?/1` guard remains necessary.

---

### WR-05: `example_host_contract.ex` passes `env: []` to `System.cmd` — replaces PATH in subprocess

**File:** `test/support/example_host_contract.ex:83-85`

**Issue:** The `doctor!` function calls:

```elixir
_ = run!(dir, [], "mix", ["deps.get"])
_ = run!(dir, [], "mix", ["compile"])
_ = run!(dir, [{"MIX_ENV", "test"}], "mix", ["ecto.reset"])
```

`run!/4` passes the env list directly to `System.cmd/3` as `env:`. Per Elixir docs, when `env:`
is provided, it is *merged* with the parent environment only when the values are `{key, value}`
tuples — but an empty list `[]` means "no additional env vars," which is fine. Elixir's `System.cmd`
does merge the parent environment with the provided list (it is additive, not a replacement).
However, the inconsistency between `run!(dir, [], ...)` (no extra env) and
`run!(dir, [{"MIX_ENV", "test"}], ...)` (test env set) means `mix deps.get` and `mix compile`
run in the wrong `MIX_ENV` (production default), which can cause compiled artifacts to mismatch
when `mix ecto.reset` runs with `MIX_ENV=test`. If the fixture app has environment-specific
configuration (e.g., different adapters per env), deps.get/compile in `prod` followed by
ecto.reset in `test` will silently use the wrong compile target.

**Fix:** Apply `MIX_ENV=test` consistently for all doctor fixture commands:

```elixir
_ = run!(dir, [{"MIX_ENV", "test"}], "mix", ["deps.get"])
_ = run!(dir, [{"MIX_ENV", "test"}], "mix", ["compile"])
_ = run!(dir, [{"MIX_ENV", "test"}], "mix", ["ecto.reset"])
```

---

## Info

### IN-01: `checks_test.exs` — index-dropping `on_exit` callbacks have no failure handling

**File:** `test/oban_powertools/doctor/checks_test.exs:67-71`, `128-131`, `144-147`

**Issue:** Three tests drop an index and restore it via a direct Postgrex `on_exit` callback. If
the `on_exit` restore query fails (Postgrex connection refused, authentication error, permission
change), the index remains dropped permanently for the lifetime of that test DB. All subsequent
tests relying on that index being present (e.g., the `missing_indexes` "returns []" test, the
integration test in `doctor_test.exs`) will fail with misleading errors — potentially including
the `on_exit` of a different test attempting the same restore.

There is no assertion that the restore succeeded, and the `GenServer.stop(conn)` call after the
query means errors from `Postgrex.query!` (which raises) would be surfaced, but any connection
failure in `Postgrex.start_link/1` returns `{:error, reason}` which is silently ignored by
pattern-match on `{:ok, conn}`.

**Fix:** The `direct_postgrex_query!` helper should handle the connection error case:

```elixir
defp direct_postgrex_query!(sql) do
  db_config = ...
  {:ok, conn} = Postgrex.start_link(db_config)  # already raises on failure via match
  Postgrex.query!(conn, sql, [])                 # raises on query failure
  GenServer.stop(conn)
end
```

Actually the current code does crash `on_exit` if `start_link` fails (the `{:ok, conn} = ...`
match raises `MatchError`). The real gap is that `on_exit` failures in ExUnit are reported as
warnings, not test failures. Consider wrapping the restore in an explicit `assert`:

```elixir
on_exit(fn ->
  assert {:ok, _} = direct_postgrex_start_and_query!(
    "CREATE INDEX IF NOT EXISTS oban_jobs_args_index ON public.oban_jobs USING GIN (args)"
  )
end)
```

Or document the acceptance of this fragility explicitly.

---

_Reviewed: 2026-05-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
