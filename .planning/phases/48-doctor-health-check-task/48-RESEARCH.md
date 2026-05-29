# Phase 48: Doctor Health-Check Task — Research

**Researched:** 2026-05-29
**Domain:** Plain Mix.Task, pg_catalog/information_schema catalog queries, Ecto.Migrator.with_repo/2 boot, Oban migration version introspection
**Confidence:** HIGH (all critical claims verified from in-repo source code)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Dual output — human-readable sectioned report (default) + `--format json`. Auto-degrade ANSI color via `IO.ANSI.enabled?`.
- **D-02:** `{:jason, "~> 1.4"}` already declared — no new dep. Zero-dep mandate satisfied.
- **D-03:** JSON payload carries top-level `schema_version` field; payload shape is a stability contract (CHANGELOG-tracked).
- **D-04:** Fixed conservative default severity + `--strict` override. `--strict` promotes the warning tier to errors.
- **D-05:** Per-finding severity table (LOCKED):
  | Finding | Default | Under `--strict` |
  |---|---|---|
  | INVALID index (failed CREATE INDEX CONCURRENTLY) | error (2) | error (2) |
  | Missing expected Oban index | error (2) | error (2) |
  | Migration drift (Oban core OR Powertools tables) | error (2) | error (2) |
  | Uniqueness-timeout risk | warning (1) | error (2) |
  | Cannot-run (DB unreachable / no repo config) | error (2) | error (2) |
- **D-06:** `cannot-run` is always error (2), never a silent skip.
- **D-07:** Layered precedence: CLI flags > project config > defaults. Repo from `--repo` or `ObanPowertools.RuntimeConfig.repo/1`. Prefix from `--prefix` > host Oban config (application env, not a running Oban) > `"public"`. `--oban-name` (default `Oban`) selects which Oban instance config key to read.
- **D-08:** No-repo-configured path halts with a clear actionable error referencing the `config :oban_powertools, repo:` contract — matching `RuntimeConfig.repo!/1` tone.
- **D-09:** Repo-only boot via `Ecto.Migrator.with_repo/2`. Do NOT start Oban. No `@requirements ["app.start"]`.
- **D-10:** No live `Oban.Registry` introspection. Prefix from flag or application env only.
- **D-11:** Two-lane detection: Lane 1 = `pg_catalog.obj_description` query on `oban_jobs` vs `Oban.Migrations.Postgres.current_version/0`; Lane 2 = `information_schema.tables`/`pg_catalog.pg_class` presence check against Powertools manifest grouped by migration set.
- **D-12:** Powertools table manifest versioned alongside the install task.
- **D-13:** `Oban.Migration.verify_migrated!` is REJECTED — `@doc false`, raises, needs running pool, no Powertools coverage.

### Claude's Discretion

- Exact section ordering and visual layout of the human report.
- Precise JSON field names/nesting (subject to `schema_version` contract once chosen).
- How uniqueness-timeout risk is heuristically detected (queue size threshold, partial-index presence) — research/planning to specify.
- Internal module decomposition (Doctor orchestrator + per-check modules + formatter).

### Deferred Ideas (OUT OF SCOPE)

- Live count / `oban_met` integration in doctor output.
- Multi-instance `--all` enumeration via running Oban.
- Auto-repair / fix mode.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS-03 | Operator can run `mix oban_powertools.doctor` to check Oban index presence and validity, including INVALID indexes, fully read-only over `pg_catalog`. | Index catalog SQL (Section "Read-Only Catalog Queries"), expected index manifest (Section "Expected Oban Indexes at v14"), INVALID-index detection (pg_index columns verified). |
| OPS-04 | Detects migration drift and validates configuration honoring a custom Oban prefix/schema; flags uniqueness-timeout risk. | Lane 1 obj_description SQL verified from Oban source; Lane 2 manifest grouping derived from install.ex; prefix resolution pattern documented; uniqueness-timeout heuristic proposed. |
| OPS-05 | Returns honest exit codes 0/1/2 for CI; actionable remediation hints in output. | Exit-code pattern via `System.halt/1`; remediation hint content specified per check. |
</phase_requirements>

---

## Summary

Phase 48 ships `mix oban_powertools.doctor` — a plain Mix task (not Igniter) that performs five read-only health checks against `pg_catalog`/`information_schema` via a minimal Ecto Repo boot. All decisions about what to check and how to exit are locked in CONTEXT.md; this research answers "how exactly do you implement each check."

The critical implementation reference is already in the repo: `Oban.Migrations.Postgres.migrated_version/1` in `examples/phoenix_host/deps/oban/lib/oban/migrations/postgres.ex` contains the exact `obj_description` SQL for Lane 1. The `current_version/0` function returns the integer `14` for the installed Oban 2.22.1. The `Ecto.Migrator.with_repo/2` pattern is well-established in `deps/ecto_sql` and used in this repo's own `test_helper.exs`. Jason is already a declared dep — JSON output adds no new dependency.

The uniqueness-timeout risk check (Claude's Discretion) has a concrete, defensible read-only heuristic: query `count(*)` of jobs in `available + scheduled + retryable` states from `oban_jobs` in the target prefix, plus check whether the GIN indexes on `args` and `meta` are present (added in Oban migration v10 specifically to "keep unique checks fast in large tables"). The heuristic threshold recommended is 50,000 combined eligible-unique-state jobs.

**Primary recommendation:** Implement as four modules — `Mix.Tasks.ObanPowertools.Doctor` (CLI entry, option parsing, repo boot, exit), `ObanPowertools.Doctor` (orchestrator returning structured results), `ObanPowertools.Doctor.Checks` (five pure-DB check functions), `ObanPowertools.Doctor.Formatter` (human/JSON rendering). All five checks share the same single repo connection from `with_repo/2`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CLI flag parsing / option resolution | Mix.Task (compile-time CLI) | — | Standard Mix.Task pattern; no Phoenix/runtime involvement |
| Repo boot (read-only) | Ecto Migrator infrastructure | — | `with_repo/2` manages start/stop without the app supervision tree |
| Index presence/validity queries | Database (pg_catalog) | — | Catalog-only, no ORM mapping needed — raw SQL via `repo.query/3` |
| Migration version read (Lane 1) | Database (pg_catalog) | Oban dep (compile-time constant) | `obj_description` reads DB comment; `current_version/0` is a compile-time `@current_version 14` attribute |
| Powertools table presence (Lane 2) | Database (information_schema) | Hardcoded manifest | Table presence is a DB fact; manifest is a library constant |
| Uniqueness-timeout risk | Database (oban_jobs count) | pg_catalog (GIN index presence) | Two sub-queries: job count in eligible states + GIN index existence |
| Severity calculation + exit-code mapping | Library logic (pure) | — | No DB involved; pure Elixir reduction over check results |
| Output rendering (human/JSON) | Library logic (pure) | IO.ANSI (stdlib) | Format is an in-process decision; no external renderer |

---

## Standard Stack

### Core (all already declared in mix.exs — zero new deps)

| Library | Version (locked in mix.exs) | Purpose | Why Standard |
|---------|----------------------------|---------|--------------|
| ecto_sql | `~> 3.10` | `Ecto.Migrator.with_repo/2` for repo-only boot | Already required by project; canonical pattern for Mix tasks |
| postgrex | `~> 0.17` | PostgreSQL driver for raw `repo.query/3` | Already declared |
| jason | `~> 1.4` | `--format json` encoding | Already declared runtime dep (D-02) |
| oban | `~> 2.18` | `Oban.Migrations.Postgres.current_version/0` at runtime | Already declared; installed at 2.22.1 |

**No new dependencies.** This phase satisfies the v1.6 zero-dep mandate without exception.

### Reusable Seams (repo-internal)

| Module | Use |
|--------|-----|
| `ObanPowertools.RuntimeConfig.repo/1` and `repo!/1` | Resolve the configured repo; match D-07/D-08 error tone |
| `IO.ANSI.enabled?/0` | Auto-degrade color in CI/non-TTY (stdlib, no dep) |

---

## Package Legitimacy Audit

> No new packages to install. All dependencies are already declared in mix.exs.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
mix oban_powertools.doctor [flags]
          |
          v
Mix.Tasks.ObanPowertools.Doctor.run/1
  1. parse_opts/1  (OptionParser)
  2. resolve_config/1  (RuntimeConfig.repo/1 + Oban app env)
  3. Ecto.Migrator.with_repo(repo, fn repo -> ...)
       |
       v
  ObanPowertools.Doctor.run(repo, opts)
    |----> Checks.index_validity(repo, prefix)      -> [%Finding{}]
    |----> Checks.missing_indexes(repo, prefix)     -> [%Finding{}]
    |----> Checks.oban_migration_version(repo, prefix)  -> [%Finding{}]
    |----> Checks.powertools_tables(repo)            -> [%Finding{}]
    |----> Checks.uniqueness_timeout_risk(repo, prefix) -> [%Finding{}]
    |
    v
  List of %Finding{check, severity, message, remediation}
          |
          v
  Formatter.format(findings, format: :human | :json)
          |
          v
  exit_code = max_severity(findings)  [0 / 1 / 2]
          |
          v
  System.halt(exit_code)
```

### Recommended Project Structure

```
lib/mix/tasks/
└── oban_powertools.doctor.ex      # Mix.Task entry point only

lib/oban_powertools/
├── doctor.ex                      # Orchestrator: run/2, Finding struct, exit_code_for/1
├── doctor/
│   ├── checks.ex                  # All five DB check functions
│   └── formatter.ex               # Human + JSON renderers

test/mix/tasks/
└── oban_powertools.doctor_test.exs  # CLI flag / config resolution tests (no DB)

test/oban_powertools/
├── doctor_test.exs                # Orchestrator integration (uses TestRepo + DataCase)
└── doctor/
    ├── checks_test.exs            # Per-check DB tests (manipulate catalog state)
    └── formatter_test.exs         # Pure output rendering tests
```

---

## Pattern 1: Plain Mix.Task Structure

```elixir
# Source: verified from deps/ecto_sql/lib/mix/tasks/ecto.migrate.ex + Elixir stdlib
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

    repo_module = resolve_repo(opts)   # RuntimeConfig.repo/1 with CLI override

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

[VERIFIED: source at `/deps/ecto_sql/lib/ecto/migrator.ex:149`]

**`with_repo/2` signature and behaviour:**
- `Ecto.Migrator.with_repo(repo, fun, opts \\ [])` starts `[:ecto_sql | config[:start_apps_before_migration]]`, starts the repo adapter, calls `fun.(repo)`, then shuts down what it started.
- Returns `{:ok, fun_result, started_apps}` on success, `{:error, reason}` if repo cannot start.
- `pool_size: 2` is the conventional minimum for read-only work (one connection active + one spare).
- This is identical to what `mix ecto.migrate` does (`[mode: :temporary] ++ opts`). [VERIFIED: source at `/deps/ecto_sql/lib/mix/tasks/ecto.migrate.ex:151`]

---

## Pattern 2: Exit Codes from Mix.Task

```elixir
# Source: Elixir stdlib — System.halt/1 [ASSUMED: stdlib behaviour; no Context7 lookup needed]
# Pattern: DO use System.halt/1, NOT exit/1 or raise.
#
# exit/1 raises an EXIT signal that Mix catches and treats as exit code 1 always.
# System.halt/1 terminates the BEAM with the given integer code immediately.
# This is what ecto.migrate, mix test, and every CI-honest Mix task uses.

System.halt(0)   # all checks green
System.halt(1)   # warnings only (uniqueness-timeout risk without --strict)
System.halt(2)   # one or more errors
```

**Landmine:** Do NOT call `System.halt/1` inside the `with_repo` callback — call it **after** `with_repo` returns, so Ecto can cleanly close the pool. The pattern above captures exit_code from the callback return value, then halts after the `case`. [ASSUMED: based on Ecto pool shutdown semantics]

---

## Pattern 3: ANSI Color Auto-Degradation

```elixir
# Source: Elixir stdlib IO.ANSI module [ASSUMED: stdlib, stable since Elixir 1.0]
defp colorize(text, color) do
  if IO.ANSI.enabled?() do
    [color, text, IO.ANSI.reset()] |> IO.ANSI.format() |> IO.iodata_to_binary()
  else
    text
  end
end

# IO.ANSI.enabled?/0 returns false when:
# - stdout is not a TTY (piped, redirected, CI without FORCE_COLOR)
# - TERM=dumb
# - NO_COLOR env var is set
```

---

## Research Question 1: Read-Only Catalog SQL

### 1a. Index Presence + INVALID Detection (pg_catalog)

```sql
-- Source: verified from Oban migration source + pg_catalog schema
-- Prefix-safe: joins pg_namespace so it resolves to the correct schema.
-- Returns ALL indexes on oban_jobs in the target prefix/schema.

SELECT
  i.relname        AS index_name,
  ix.indisvalid    AS is_valid,
  ix.indisready    AS is_ready,
  ix.indisprimary  AS is_primary,
  array_agg(a.attname ORDER BY k.ord) AS columns
FROM pg_catalog.pg_class  c
JOIN pg_catalog.pg_namespace  n  ON n.oid = c.relnamespace
JOIN pg_catalog.pg_index      ix ON ix.indrelid = c.oid
JOIN pg_catalog.pg_class      i  ON i.oid = ix.indexrelid
JOIN LATERAL unnest(ix.indkey) WITH ORDINALITY AS k(attnum, ord) ON true
JOIN pg_catalog.pg_attribute  a  ON a.attrelid = c.oid AND a.attnum = k.attnum
WHERE c.relname   = 'oban_jobs'
  AND n.nspname   = $1          -- the prefix, e.g. 'public'
  AND NOT ix.indisprimary
GROUP BY i.relname, ix.indisvalid, ix.indisready, ix.indisprimary
ORDER BY i.relname;
```

**Key columns for INVALID detection:**
- `indisvalid = false` — index is present but invalid (left by failed `CREATE INDEX CONCURRENTLY`). This is the canonical signal. [VERIFIED: pg_catalog docs embedded in Postgres source, verified from Oban's own migration source which reads `pg_class`]
- `indisready = false` — index is not ready for writes (can coexist with `indisvalid = false` during a failed CONCURRENTLY build). Flag both.
- A job in state `INVALID index` means queries still run (Postgres will not use an invalid index) but the index is wasting space and must be fixed with `REINDEX INDEX CONCURRENTLY`.

**Call via `repo.query/3`:**
```elixir
{:ok, %{columns: cols, rows: rows}} = repo.query(sql, [prefix], log: false)
```
[VERIFIED: pattern from `Oban.Migrations.Postgres.migrated_version/1` at `examples/phoenix_host/deps/oban/lib/oban/migrations/postgres.ex:60`]

**Prefix injection landmine:** Never use string interpolation with user-supplied prefix — use parameterized `$1`. The Oban source itself uses string interpolation only because the prefix is validated/escaped by `with_defaults/2` before being put in the query. For doctor we should use `$1` binding instead. [ASSUMED: standard parameterization best practice]

### 1b. Expected Oban Indexes at v14 (the Final State)

Tracking through all Oban migration versions v01→v14 for indexes that survive to the final state:

| Index name (pg default naming) | Columns | Type | Added | Notes |
|-------------------------------|---------|------|-------|-------|
| `oban_jobs_state_queue_priority_scheduled_at_id_index` | `(state, queue, priority, scheduled_at, id)` | btree | v08/v09 | Primary fetch index; replaces old v01 indexes |
| `oban_jobs_args_index` | `(args)` | GIN | v10 | "necessary to keep unique checks fast in large tables" |
| `oban_jobs_meta_index` | `(meta)` | GIN | v10 | Same rationale as args GIN |
| `oban_jobs_state_cancelled_at_index` | `(state, cancelled_at)` | btree | v13 | |
| `oban_jobs_state_discarded_at_index` | `(state, discarded_at)` | btree | v13 | |

[VERIFIED: derived from exhaustive reading of v01.ex through v14.ex at `examples/phoenix_host/deps/oban/lib/oban/migrations/postgres/`]

**Indexes removed by migration (must NOT be in the expected set):**
- `oban_jobs_queue_index`, `oban_jobs_state_index`, `oban_jobs_scheduled_at_index` — removed in v05
- `oban_jobs_args_vector` (GiST on args), `oban_jobs_worker_gist` (GiST on worker), `oban_jobs_attempted_at_id_index` — removed in v10

**The doctor must check that the 5 listed indexes exist AND that old removed indexes are absent.** Finding an old removed index is not an error (it's just a deprecated leftover), but an absent expected index IS an error (D-05).

### 1c. Powertools Table Presence (information_schema)

```sql
-- Source: information_schema is SQL standard; confirmed prefix-safe via table_schema column
SELECT table_name
FROM information_schema.tables
WHERE table_schema = $1       -- the prefix
  AND table_name = ANY($2)    -- array of expected table names
  AND table_type = 'BASE TABLE';
```

The `ANY($2)` binding accepts a `list()` via Postgrex. Tables absent from the result set are missing. [ASSUMED: Postgrex array binding; works identically to `pg_catalog.pg_class` approach]

**Alternative (simpler, no information_schema lock-in):**
```sql
SELECT relname
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = $1
  AND c.relname = ANY($2)
  AND c.relkind = 'r';
```
[VERIFIED: Oban codebase uses `pg_class + pg_namespace` join for namespace-scoped queries; same pattern as the index query above]

---

## Research Question 2: Oban Core Version (Lane 1, D-11)

### The Exact `obj_description` Query

```elixir
# Source: VERIFIED from examples/phoenix_host/deps/oban/lib/oban/migrations/postgres.ex:52-63
query = """
SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
FROM pg_class
LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE pg_class.relname = 'oban_jobs'
AND pg_namespace.nspname = '#{escaped_prefix}'
"""

case repo.query(query, [], log: false) do
  {:ok, %{rows: [[version]]}} when is_binary(version) -> String.to_integer(version)
  _ -> 0
end
```

**Doctor version:** Use a parameterized query (`$1`) instead of string interpolation:
```elixir
query = """
SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
FROM pg_class
LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE pg_class.relname = 'oban_jobs'
AND pg_namespace.nspname = $1
"""
case repo.query(query, [prefix], log: false) do
  {:ok, %{rows: [[version]]}} when is_binary(version) -> {:ok, String.to_integer(version)}
  {:ok, %{rows: [[nil]]}}  -> {:ok, 0}   # table exists, no comment set
  {:ok, %{rows: []}}       -> {:ok, 0}   # table absent — treat as version 0
  {:error, _}              -> {:error, :db_unreachable}
end
```
[VERIFIED: query shape from Oban source; parameterization is a safe substitution]

**"Table absent" = version 0:** The Oban source itself maps any non-binary result to `0`, which is the "no migrations run" sentinel. [VERIFIED: `examples/phoenix_host/deps/oban/lib/oban/migrations/postgres.ex:61-63`]

### `Oban.Migrations.Postgres.current_version/0`

```elixir
# Source: VERIFIED from examples/phoenix_host/deps/oban/lib/oban/migrations/postgres.ex:9,13
@current_version 14
def current_version, do: @current_version
```

At runtime in the doctor task, call:
```elixir
installed_version = Oban.Migrations.Postgres.current_version()
# Returns: 14  (for oban 2.22.1)
```

This is a compile-time constant — it does NOT require a running pool or any DB connection. The module is available at compile time because `oban` is a declared dep. [VERIFIED: module source confirmed `@doc false` is NOT on `current_version/0` — it is on `verify_migrated!/1` only. `current_version/0` is a public function. See `@doc false` annotation at line 208.]

**Version sensitivity:** The `current_version` constant will change if Oban is upgraded. The comparison `installed_version == db_version` tells the operator the DB is at parity. `db_version < installed_version` means the migration hasn't been run yet. `db_version == 0` means Oban is not installed at all.

---

## Research Question 3: Repo-Only Boot (D-09)

### `Ecto.Migrator.with_repo/2` — Canonical Idiom

```elixir
# Source: VERIFIED from deps/ecto_sql/lib/ecto/migrator.ex:149-183
# and deps/ecto_sql/lib/mix/tasks/ecto.migrate.ex:151

{:ok, result, _started} = Ecto.Migrator.with_repo(MyApp.Repo, fn repo ->
  # repo is the started repo module — use repo.query/3 here
  run_checks(repo)
end, pool_size: 2)
```

**What `with_repo/2` does:**
1. Starts `[:ecto_sql | config[:start_apps_before_migration] || []]` (ensures the SQL adapter is running).
2. Calls `repo.__adapter__().ensure_all_started(config, mode)` which starts `:postgrex` and related OTP apps.
3. Starts the repo itself if not already started (`ensure_repo_started` with a pool of `pool_size`).
4. Calls the provided function.
5. Cleans up what it started (shuts down the repo if it started it).

**This is exactly what `mix ecto.migrate` does** — it's the idiomatic plain Mix.Task repo boot. [VERIFIED: ecto_sql source]

**Pitfalls to avoid:**

1. **`@requirements ["app.start"]` is forbidden (D-09).** This boots the full application supervision tree including Oban queues/workers. Never use it for the doctor task.

2. **Sandbox pool in test env.** In test, `ObanPowertools.TestRepo` uses `Ecto.Adapters.SQL.Sandbox`. `with_repo/2` will start the repo in sandbox mode if the config says so — this is fine for testing doctor checks. The existing test_helper.exs already starts TestRepo before tests run, so `with_repo` will use the already-started repo (it calls `ensure_repo_started` which detects the running repo). [VERIFIED: `with_repo/2` source — it calls `ensure_repo_started` which returns `{:ok, :already_started}` if already up]

3. **DB unreachable / misconfigured repo.** `with_repo/2` returns `{:error, reason}` if the repo cannot start. The doctor must catch this and emit a `cannot-run` finding with severity `error (2)` (D-06).

4. **`Mix.Task.run("app.config", [])` before `with_repo`.** Standard Mix tasks do NOT need to manually load config — Mix loads `config/config.exs` and env-specific configs automatically when the task runs. The repo module will already be configured. [ASSUMED: standard Mix behaviour]

5. **Compile-time Repo module resolution.** If `--repo MyApp.Repo` is passed as a string, use `Module.safe_concat([String.to_atom(repo_str)])` or `String.to_existing_atom/1` + `Module.safe_concat` to resolve it safely without allowing arbitrary atom creation. [ASSUMED: standard safe module resolution pattern]

---

## Research Question 4: Uniqueness-Timeout Risk Heuristic

This is **Claude's Discretion** — the CONTEXT marks it open. Here is the researched proposal.

### How Oban Unique Jobs Work (Context for Risk)

Oban's unique job deduplication uses a `pg_try_advisory_xact_lock` (transaction-scoped advisory lock) plus a SELECT query against `oban_jobs` filtered by `state IN (...)` and `args @> $1` or `meta @> $1`. The GIN indexes on `args` and `meta` are explicitly described as "necessary to keep unique checks fast in large tables" (Oban migration v10 comment). [VERIFIED: `examples/phoenix_host/deps/oban/lib/oban/migrations/postgres/v10.ex:38`]

The states checked during uniqueness are configurable per job but default to `['available', 'scheduled', 'executing', 'retryable', 'completed']`. The timeout risk arises from:
1. The GIN indexes being absent (seqscan over `oban_jobs` at high volume).
2. Large counts of jobs in unique-eligible states causing slow GIN scans even with indexes present.

### Proposed Heuristic (Two Sub-Checks)

**Sub-check A — GIN index absence (strongest predictor):**
The absence of `oban_jobs_args_index` (GIN on args) or `oban_jobs_meta_index` (GIN on meta) means every uniqueness check is a sequential scan. At any scale above ~10,000 jobs this is a risk. Mark as warning.

```sql
-- Already covered by the index catalog query (Research Question 1a)
-- Missing GIN index => uniqueness_timeout_risk finding
```

**Sub-check B — eligible job count threshold:**
Even with GIN indexes, very large tables can see slow GIN scans. Count jobs in states that Oban's default unique checker queries:

```sql
-- Source: [ASSUMED] — derived from Oban engine logic at basic.ex:469-487
SELECT count(*)
FROM <prefix>.oban_jobs
WHERE state IN ('available', 'scheduled', 'retryable', 'executing')
```

**Recommended threshold: 50,000.** Rationale: GIN indexes remain fast up to millions of rows on modern hardware, but 50K eligible-unique-state jobs is a strong operational signal that the queue has an unhealthy backlog independent of the uniqueness mechanism. The combination of a large backlog AND missing GIN indexes is especially dangerous.

**Severity:** Warning (1) by default, escalates to error (2) under `--strict` (D-05 locked).

**Remediation hint:**
- If GIN missing: "Run `CREATE INDEX CONCURRENTLY oban_jobs_args_index ON {prefix}.oban_jobs USING GIN (args)` — required for uniqueness check performance. See Oban migration v10."
- If count high: "Queue backlog exceeds {threshold}. High eligible-job counts slow Oban unique-job checks. Consider adding the Oban Reindexer plugin or draining the queue before enabling `unique:` on new workers."

---

## Research Question 5: Migration-Set Manifest Grouping (D-12)

Derived from the install task's migration setup functions. Groupings are authoritative because they match the install task's `setup_*` function structure.

### Migration Sets (4 groups, 24 tables total)

```
# Source: VERIFIED from lib/mix/tasks/oban_powertools.install.ex migration functions
```

**Set 1: Foundation** (`setup_migration/1` — timestamps 0..1)
- `oban_powertools_audit_events`
- `oban_powertools_idempotency_receipts`

**Set 2: Smart Engine** (`setup_smart_engine_migrations/1` — timestamps 10..16)
- `oban_powertools_limit_resources`
- `oban_powertools_limit_states`
- `oban_powertools_cron_entries`
- `oban_powertools_cron_slots`
- `oban_powertools_blocker_snapshots`
- `oban_powertools_limiter_history_facts`
- `oban_powertools_cron_coverages`

**Set 3: Workflow** (`setup_workflow_migrations/1` — timestamps 20..25)
- `oban_powertools_workflows`
- `oban_powertools_workflow_steps`
- `oban_powertools_workflow_edges`
- `oban_powertools_workflow_results`
- `oban_powertools_workflow_awaits`
- `oban_powertools_workflow_signals`
- `oban_powertools_workflow_recovery_sessions`
- `oban_powertools_workflow_recovery_attempts`
- `oban_powertools_workflow_callback_outbox`
- `oban_powertools_workflow_command_attempts`

**Set 4: Heartbeat-Lifeline** (`setup_phase_4_migrations/1` — timestamps 30..34)
- `oban_powertools_heartbeats`
- `oban_powertools_lifeline_incidents`
- `oban_powertools_repair_previews`
- `oban_powertools_archive_runs`
- `oban_powertools_repair_archives`

**Total: 24 tables.** [VERIFIED: counted from CONTEXT.md code_context list cross-referenced with install.ex]

### Lane 2 Doctor Reporting Shape

Lane 2 reports per-group presence signals:
- "foundation: present" / "foundation: MISSING (2/2 tables absent)"
- "smart-engine: partial (5/7 present — missing: oban_powertools_cron_coverages, oban_powertools_limiter_history_facts)"
- "workflow: present" / "workflow: MISSING"
- "heartbeat-lifeline: present" / "heartbeat-lifeline: MISSING"

Any absent table is severity `error (2)` (D-05: migration drift = error).

---

## Research Question 6: Plain Mix.Task Structure + Exit Codes

### OptionParser Flags

```elixir
# Source: [VERIFIED: OptionParser docs embedded in Elixir stdlib; ecto.migrate uses same pattern]
@switches [
  repo:       :string,    # --repo MyApp.Repo
  prefix:     :string,    # --prefix private
  oban_name:  :string,    # --oban-name MyOban  (CLI converts kebab to snake automatically)
  format:     :string,    # --format json
  strict:     :boolean    # --strict
]

{opts, _remaining, _invalid} = OptionParser.parse(argv, strict: @switches)
```

### Prefix Resolution (D-07)

```elixir
defp resolve_prefix(opts) do
  cond do
    prefix = Keyword.get(opts, :prefix) ->
      prefix
    true ->
      oban_name = Keyword.get(opts, :oban_name, "Oban")
      oban_key  = String.to_existing_atom(oban_name) rescue nil
      # Read from application env without starting Oban (D-10)
      case oban_key && Application.get_env(:oban, oban_key) do
        config when is_list(config) -> Keyword.get(config, :prefix, "public")
        _                           -> "public"
      end
  end
end
```

Note: `Application.get_env(:oban, key)` where `key` is the Oban instance name (an atom) reads the host's Oban configuration from the loaded application environment. This is correct per D-10 — no running Oban process needed. [ASSUMED: depends on how the host configures Oban; typically `config :my_app, Oban, prefix: "..."` but `Application.get_env(:oban, Oban)` reads `config :oban, Oban, ...`. The doctor should document that prefix auto-detection requires host Oban config to be under the `:oban` app key.]

**Important distinction:** Oban config is typically in the host's `config.exs` as `config :my_app, Oban, queues: [...], prefix: "..."` — this is read as `Application.get_env(:my_app, Oban)`, NOT `Application.get_env(:oban, Oban)`. The `--oban-name` flag resolves which config key (atom name) to look up, but the OTP app key requires knowing the host app name. Since the doctor cannot know the host app at compile time, the safest approach is: if prefix resolution from app env fails, fall back to `"public"` and note this in help text. The `--prefix` flag is the reliable production path. [ASSUMED: Oban application env topology; planner should flag this for documentation]

---

## Research Question 7: Internal Decomposition + Testability

### Module Shape

**`Mix.Tasks.ObanPowertools.Doctor`** — thin CLI adapter only:
- `run/1` — option parsing, config resolution, `with_repo/2` boot, print, `System.halt/1`
- No business logic lives here
- Testing: unit tests for flag parsing without DB (no `DataCase`)

**`ObanPowertools.Doctor`** — orchestrator:
- `run(repo, opts)` → `[%Finding{}]` — calls all five checks, returns structured findings
- `%Finding{check: atom, severity: :ok | :warning | :error, message: String.t(), remediation: String.t() | nil}`
- `exit_code_for([%Finding{}])` → `0 | 1 | 2` — pure reduction
- Testing: integration test against TestRepo + DataCase

**`ObanPowertools.Doctor.Checks`** — five pure-DB functions:
- `index_validity(repo, prefix)` → `[%Finding{}]`
- `missing_indexes(repo, prefix)` → `[%Finding{}]`
- `oban_migration_version(repo, prefix)` → `[%Finding{}]`
- `powertools_tables(repo)` → `[%Finding{}]` (always queries the `public` schema — Powertools tables are not Oban-prefixed; see RESOLVED Open Q3)
- `uniqueness_timeout_risk(repo, prefix, opts)` → `[%Finding{}]`
- Each function: runs its SQL, returns zero or more findings
- Testing: DataCase, manipulate catalog state in test setup (e.g., `CREATE INDEX`, `ALTER INDEX ... REBUILD`, check presence/absence)

**`ObanPowertools.Doctor.Formatter`** — pure rendering:
- `format(findings, opts)` → `String.t()` or `iodata`
- `print(findings, opts)` — wraps `format` + `IO.puts`
- Two private renderers: `human/2` and `json/2`
- Testing: pure unit tests — no DB, no repo

### Testing Catalog Checks Without Starting Oban

The test harness already has:
- `ObanPowertools.TestRepo` (started in test_helper.exs, Sandbox mode)
- `ObanPowertools.DataCase` (checks out a Sandbox connection)
- The test database has `oban_jobs` (created by Oban migrations) in the `public` schema

For catalog check tests, the test can:
```elixir
# Drop an expected index to test "missing index" detection
Ecto.Adapters.SQL.query!(TestRepo, "DROP INDEX CONCURRENTLY IF EXISTS public.oban_jobs_args_index", [])
# ... test the check ...
# Restore it (or let the test be async:false and use on_exit cleanup)
```

For INVALID index testing:
```elixir
# Cannot reliably create an INVALID index in a test without a concurrent transaction;
# test via directly updating pg_index.indisvalid is not user-accessible.
# Best approach: mock the catalog query result OR test the finding-construction logic
# separately from the raw SQL execution.
```

[ASSUMED: test isolation approach; alternative is to move the raw-SQL step behind a behaviour for testability. Planner should decide.]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Repo lifecycle in Mix task | Custom OTP start/stop | `Ecto.Migrator.with_repo/2` | Handles ecto_sql start, adapter start, pool, cleanup |
| JSON encoding | Custom serializer | `Jason.encode!/1` (already dep) | Already tested, handles all Elixir term types |
| Oban installed version | Parsing source files or hex metadata | `Oban.Migrations.Postgres.current_version/0` | Compile-time constant, guaranteed correct for installed version |
| ANSI TTY detection | Env var sniffing | `IO.ANSI.enabled?/0` | Stdlib, handles `NO_COLOR`, `TERM=dumb`, non-TTY |
| Exit code propagation | `raise` or `exit` | `System.halt/1` | Only reliable way to set integer exit code from Mix task |

**Key insight:** Every sharp edge in this domain (repo boot, JSON, version detection, TTY, exit codes) has an idiomatic Elixir/Ecto solution already in the dependency graph. Nothing needs to be invented.

---

## Common Pitfalls

### Pitfall 1: `@requirements ["app.start"]` Silently Starts Oban

**What goes wrong:** Developer adds `@requirements ["app.start"]` thinking it's needed to start the DB — it actually starts the full application including Oban queues, which begin processing jobs.
**Why it happens:** Many Mix tasks that need DB access use `app.start`. It works, but it's not read-only safe.
**How to avoid:** Use `Ecto.Migrator.with_repo/2` exclusively. Do not add `@requirements` at all.
**Warning signs:** `Oban started` log lines appearing during doctor execution.

### Pitfall 2: String-Interpolated Prefix in SQL (SQL Injection Surface)

**What goes wrong:** Directly interpolating `prefix` into SQL — `"WHERE nspname = '#{prefix}'"` — allows injection if prefix comes from user CLI input.
**Why it happens:** Oban's own migration code does this safely (it normalises the prefix internally), so copying the Oban query shape directly.
**How to avoid:** Use `$1` binding with `repo.query(sql, [prefix], log: false)` for ALL prefix values coming from CLI flags.
**Warning signs:** The query string contains `#{}` interpolation of user-supplied values.

### Pitfall 3: `System.halt/1` Called Inside `with_repo/2` Callback

**What goes wrong:** Calling `System.halt/1` inside the `with_repo` callback terminates the BEAM before Ecto closes the connection pool, potentially leaving dangling DB connections.
**Why it happens:** Feels natural to halt as soon as you have a result.
**How to avoid:** Return the exit code from the callback as a value; call `System.halt/1` after `with_repo` completes.
**Warning signs:** DB connection pool warnings in logs after task completes.

### Pitfall 4: `String.to_atom/1` for Repo Module Resolution

**What goes wrong:** `String.to_atom("MyApp.Repo")` creates a new atom — if called many times or with adversarial input, it exhausts the atom table.
**Why it happens:** Feels like the obvious conversion from `--repo` flag string.
**How to avoid:** Use `Module.safe_concat([repo_string])` after splitting on `.`, or `String.to_existing_atom/1` wrapped in a rescue (safer — only converts atoms that already exist).
**Warning signs:** `ArgumentError` on `String.to_existing_atom` when the module isn't loaded yet; resolve with `Code.ensure_loaded?` before the atom conversion.

### Pitfall 5: Testing INVALID Index State Is Non-Trivial

**What goes wrong:** Tests for the INVALID-index finder cannot easily create a real INVALID index (requires a concurrent DDL failure during another transaction).
**Why it happens:** `CREATE INDEX CONCURRENTLY` failures that leave `indisvalid = false` require interrupting the index build mid-flight — not straightforward in a test setup.
**How to avoid:** Separate the SQL-execution layer from the finding-construction layer. Test the SQL query by verifying it runs and returns no INVALID indexes on a clean DB. Test the finding-construction logic (what happens when `indisvalid = false` is returned) with a unit test that passes fake catalog rows. The integration test verifies the query structure is correct; the unit test verifies the severity mapping.
**Warning signs:** Tests that `UPDATE pg_index SET indisvalid = false` — this requires superuser and is fragile.

### Pitfall 6: Prefix Auto-Detection via `Application.get_env(:oban, ...)`

**What goes wrong:** The doctor tries to read the Oban prefix from `Application.get_env(:oban, Oban)` — but the host's Oban is typically configured under `Application.get_env(:my_app, Oban)`, not the `:oban` app key.
**Why it happens:** Reasonable assumption that Oban config lives under `:oban` app.
**How to avoid:** Document in `--help` that `--prefix` is the reliable path. Make prefix auto-detection a best-effort with explicit fallback to `"public"`. Never fail silently — if prefix cannot be determined, emit a notice that `"public"` was assumed.
**Warning signs:** Doctor runs against wrong prefix without error.

---

## Code Examples

### Complete Index Validity Check

```elixir
# Source: SQL columns verified from pg_catalog schema + Oban migration source
defmodule ObanPowertools.Doctor.Checks do
  def index_validity(repo, prefix) do
    sql = """
    SELECT
      i.relname        AS index_name,
      ix.indisvalid    AS is_valid,
      ix.indisready    AS is_ready
    FROM pg_catalog.pg_class     c
    JOIN pg_catalog.pg_namespace n  ON n.oid = c.relnamespace
    JOIN pg_catalog.pg_index     ix ON ix.indrelid = c.oid
    JOIN pg_catalog.pg_class     i  ON i.oid = ix.indexrelid
    WHERE c.relname  = 'oban_jobs'
      AND n.nspname  = $1
      AND NOT ix.indisprimary
    ORDER BY i.relname
    """

    case repo.query(sql, [prefix], log: false) do
      {:ok, %{rows: rows}} ->
        rows
        |> Enum.filter(fn [_name, valid, ready] -> not valid or not ready end)
        |> Enum.map(fn [name, _valid, _ready] ->
          %Finding{
            check: :index_validity,
            severity: :error,
            message: "INVALID index #{name} on #{prefix}.oban_jobs (failed CREATE INDEX CONCURRENTLY)",
            remediation: "Run: REINDEX INDEX CONCURRENTLY #{prefix}.#{name}"
          }
        end)

      {:error, reason} ->
        [%Finding{check: :index_validity, severity: :error,
                  message: "Cannot query pg_catalog: #{inspect(reason)}",
                  remediation: "Check DB connectivity and permissions."}]
    end
  end
end
```

### Oban Version Lane 1 Check

```elixir
# Source: query shape VERIFIED from examples/phoenix_host/deps/oban/lib/oban/migrations/postgres.ex:52-63
def oban_migration_version(repo, prefix) do
  sql = """
  SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
  FROM pg_class
  LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
  WHERE pg_class.relname = 'oban_jobs'
  AND pg_namespace.nspname = $1
  """

  db_version =
    case repo.query(sql, [prefix], log: false) do
      {:ok, %{rows: [[v]]}} when is_binary(v) -> String.to_integer(v)
      _                                        -> 0
    end

  expected_version = Oban.Migrations.Postgres.current_version()

  cond do
    db_version == 0 ->
      [%Finding{check: :oban_migration_version, severity: :error,
                message: "oban_jobs table absent in schema '#{prefix}' (Oban not migrated)",
                remediation: "Run `mix ecto.migrate` to install Oban migrations."}]

    db_version < expected_version ->
      [%Finding{check: :oban_migration_version, severity: :error,
                message: "Oban migrations at v#{db_version}, expected v#{expected_version}",
                remediation: "Run `mix ecto.migrate` to apply pending Oban migrations."}]

    db_version == expected_version ->
      []  # no finding = clean
  end
end
```

### JSON Output Schema (schema_version: 1)

```json
{
  "schema_version": 1,
  "prefix": "public",
  "oban_version_installed": 14,
  "oban_version_db": 14,
  "exit_code": 0,
  "findings": [
    {
      "check": "index_validity",
      "severity": "error",
      "message": "INVALID index oban_jobs_args_index on public.oban_jobs",
      "remediation": "Run: REINDEX INDEX CONCURRENTLY public.oban_jobs_args_index"
    }
  ]
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `@requirements ["app.start"]` for DB access in Mix tasks | `Ecto.Migrator.with_repo/2` | Ecto SQL 3.x | Start only the repo; don't boot the full app |
| String interpolation for prefix in migration SQL | Parameterized `$1` binding | Best practice always | SQL injection prevention |
| `Oban.Migration.verify_migrated!` (raises, needs pool) | `obj_description` catalog query | Oban internal | Read-only, no pool dependency, prefix-safe |

**Deprecated/outdated:**
- `Oban.Migration.verify_migrated!/1`: `@doc false` internal, raises on drift, requires a running pool. Not usable for doctor (D-13 — locked).
- Old Oban v5-era indexes (`oban_jobs_queue_index`, `oban_jobs_scheduled_at_index`): removed in migrations v05/v10; finding them in a DB is not an error but is noteworthy.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `System.halt/1` is the correct exit-code mechanism for CI-honest Mix tasks | Pattern 2 | Low — stdlib, well established |
| A2 | Postgrex accepts `list()` as `$2` binding for `ANY($2)` in WHERE | Research Q1c | Medium — if wrong, use repeated `OR relname = $N` params or `string_to_array($2, ',')` |
| A3 | `Application.get_env(:oban, ObanName)` reads the host Oban prefix correctly | Research Q6 | Medium — host may configure under a different OTP app key; `--prefix` flag is the reliable path |
| A4 | `IO.ANSI.enabled?/0` auto-detects CI non-TTY correctly | Pattern 3 | Low — stdlib, handles most cases; edge case: CI with `FORCE_COLOR` |
| A5 | Calling `System.halt` after `with_repo` returns (not inside callback) is sufficient for clean pool shutdown | Pitfall 3 | Low — standard Ecto cleanup; `with_repo` already handles this in its `after` block |
| A6 | Uniqueness-timeout risk threshold of 50,000 eligible jobs is defensible | Research Q4 | Low — threshold is advisory; operator can tune via `--strict` |
| A7 | `Module.safe_concat` + `String.to_existing_atom` is sufficient for `--repo` string resolution | Pitfall 4 | Low — well-established pattern in Mix tasks |

**If this table is empty for any item:** The core SQL queries, version APIs, and `with_repo/2` behaviour are all VERIFIED from repo source. The assumptions above are primarily about integration behaviour that cannot be verified without running the code.

---

## Open Questions (RESOLVED)

1. **Oban prefix auto-detection OTP app key**
   - What we know: Host Oban config is typically `config :my_app, Oban, prefix: "..."` — OTP app key is the host app, not `:oban`.
   - What's unclear: There is no reliable way for the doctor to know the host OTP app name at compile time.
   - Recommendation: Document `--prefix` as the canonical production flag. Implement best-effort auto-detect that iterates `Application.started_applications()` looking for config key `Oban` or the `--oban-name` atom, but always falls back to `"public"` with a notice. Planner to decide how much effort to invest here.
   - **RESOLVED:** Prefix auto-detection is best-effort only — read the host Oban config from application env (no Oban started); on any failure fall back to `"public"` and emit a notice that `"public"` was assumed. `--prefix` is documented as the reliable production path (Plan 48-02 Task 2 @moduledoc + resolve_prefix/1). No iteration of `Application.started_applications()` is required for v1; the flag-first fallback-to-public path is sufficient and side-effect-free (D-07/D-10).

2. **Test isolation for INVALID index findings**
   - What we know: Creating a real INVALID index requires a concurrent DDL failure.
   - What's unclear: Whether to introduce a thin behaviour/mock or accept a narrower integration test.
   - Recommendation: Add a `@doc false` test helper that accepts pre-formed catalog rows and tests the finding-construction logic directly. Integration test just verifies the query succeeds on a clean DB. Planner to decide.
   - **RESOLVED:** Split the SQL-execution layer from finding construction. `Checks.index_validity/2` extracts a separately-testable private `findings_for_index_rows/2` (rows → findings) helper; unit-test it directly with fake catalog rows where `indisvalid=false` to exercise the `:error` mapping (no real INVALID index needed). Add an integration smoke test asserting `index_validity/2` returns `[]` on the clean migrated test DB. (Plan 48-01 Task 2 behavior + action.)

3. **`powertools_tables` check prefix awareness**
   - What we know: Powertools tables are always in the `public` schema (they don't follow the Oban prefix — Oban's prefix is for `oban_jobs`, not Powertools tables).
   - What's unclear: Whether Lane 2 should use `prefix` for Powertools table lookup or always use `public`.
   - Recommendation: Always check Powertools tables in `public` schema (they are Powertools-owned, not Oban-prefixed). The `prefix` flag only affects Lane 1 (oban_jobs) and the index checks. Planner should confirm this is the correct interpretation.
   - **RESOLVED:** Powertools tables are always checked in the `public` schema regardless of `--prefix`. The check signature is therefore arity-1, `powertools_tables(repo)` — it takes no prefix argument. `--prefix` affects only Lane 1 (`oban_jobs` migration version) and the index checks. (Plan 48-01 Task 2 action; architecture diagram and Research Q7 module shape updated to arity-1.)
---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | All catalog checks | Assumed present | — | DB-unreachable maps to cannot-run error |
| Elixir/OTP | Mix.Task | Present (project runs) | Elixir ~> 1.19 | — |
| ecto_sql | `with_repo/2` | Present (declared dep) | ~> 3.10 | — |
| jason | JSON output | Present (declared dep) | ~> 1.4 | — |
| oban | `current_version/0` | Present (declared dep) | 2.22.1 | — |

No missing dependencies.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `test/test_helper.exs` (exists) |
| Quick run command | `mix test test/oban_powertools/doctor_test.exs test/mix/tasks/oban_powertools.doctor_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPS-03 | Index presence check returns findings for missing expected indexes | integration (DB) | `mix test test/oban_powertools/doctor/checks_test.exs` | No — Wave 0 |
| OPS-03 | INVALID index produces error finding | unit (fake catalog rows) | `mix test test/oban_powertools/doctor/checks_test.exs` | No — Wave 0 |
| OPS-03 | Read-only — no writes to DB during run | integration (DB) | Assert no INSERT/UPDATE/DELETE in query log | No — Wave 0 |
| OPS-04 | Migration drift (db_version < current_version) produces error finding | integration (DB) | `mix test test/oban_powertools/doctor/checks_test.exs` | No — Wave 0 |
| OPS-04 | Powertools table presence — missing set produces named error | integration (DB) | `mix test test/oban_powertools/doctor/checks_test.exs` | No — Wave 0 |
| OPS-04 | Prefix flag routes catalog queries to correct schema | integration (DB) | `mix test test/oban_powertools/doctor/checks_test.exs` | No — Wave 0 |
| OPS-04 | Uniqueness-timeout risk — missing GIN index produces warning finding | integration (DB) | `mix test test/oban_powertools/doctor/checks_test.exs` | No — Wave 0 |
| OPS-05 | exit_code_for/1 returns 0/1/2 correctly based on max severity | unit | `mix test test/oban_powertools/doctor_test.exs` | No — Wave 0 |
| OPS-05 | `--strict` promotes warning to error | unit | `mix test test/oban_powertools/doctor_test.exs` | No — Wave 0 |
| OPS-05 | Human formatter includes remediation hints | unit | `mix test test/oban_powertools/doctor/formatter_test.exs` | No — Wave 0 |
| OPS-05 | JSON formatter includes schema_version and all finding fields | unit | `mix test test/oban_powertools/doctor/formatter_test.exs` | No — Wave 0 |
| OPS-05 | CLI --format json produces valid JSON | integration (CLI) | `mix test test/mix/tasks/oban_powertools.doctor_test.exs` | No — Wave 0 |

### Sampling Rate

- Per task commit: `mix test test/oban_powertools/doctor_test.exs test/oban_powertools/doctor/ test/mix/tasks/oban_powertools.doctor_test.exs --max-failures 3`
- Per wave merge: `mix test`
- Phase gate: Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

All test files are new — none exist yet:
- [ ] `test/oban_powertools/doctor_test.exs` — covers OPS-05 orchestrator + exit codes
- [ ] `test/oban_powertools/doctor/checks_test.exs` — covers OPS-03 + OPS-04 DB checks
- [ ] `test/oban_powertools/doctor/formatter_test.exs` — covers OPS-05 output rendering
- [ ] `test/mix/tasks/oban_powertools.doctor_test.exs` — covers CLI flag parsing + JSON contract

---

## Security Domain

> `security_enforcement` absent from config — treating as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Doctor is a local Mix task; no web auth surface |
| V3 Session Management | no | No session |
| V4 Access Control | no | Mix tasks inherit shell user permissions |
| V5 Input Validation | yes | `--repo`, `--prefix`, `--oban-name` flags are user input; sanitize before SQL binding |
| V6 Cryptography | no | No crypto |

### Known Threat Patterns for pg_catalog Read-Only SQL

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via `--prefix` flag | Tampering | Use `$1` parameterized binding for ALL user-supplied values in SQL |
| Arbitrary atom creation via `--repo` flag | Information Disclosure | `String.to_existing_atom/1` with rescue; never `String.to_atom/1` on CLI input |
| Scope escape (wrong schema exposed) | Information Disclosure | Always bind `n.nspname = $1`; never use `pg_catalog` table listing without namespace filter |

---

## Sources

### Primary (HIGH confidence)

- `examples/phoenix_host/deps/oban/lib/oban/migrations/postgres.ex` — `migrated_version/1` SQL query shape, `current_version/0` return value (`14`), `@doc false` annotation placement
- `examples/phoenix_host/deps/oban/lib/oban/migrations/postgres/v01.ex` through `v14.ex` — complete index lifecycle, final expected index set at v14
- `examples/phoenix_host/deps/oban/lib/oban/migrations/postgres/v10.ex` — GIN index rationale ("necessary to keep unique checks fast in large tables")
- `deps/ecto_sql/lib/ecto/migrator.ex:149-183` — `with_repo/2` signature, what it starts/stops, return type
- `deps/ecto_sql/lib/mix/tasks/ecto.migrate.ex:151` — canonical `with_repo` usage in a Mix task
- `lib/mix/tasks/oban_powertools.install.ex` — migration-set grouping (4 sets, 24 tables)
- `lib/oban_powertools/runtime_config.ex` — `repo/1`, `repo!/1` error tone for D-07/D-08
- `test/test_helper.exs` — existing `with_repo` usage pattern, test DB setup
- `examples/phoenix_host/deps/oban/lib/oban/engines/basic.ex:469-543` — `unique_query/1` + `acquire_lock/2` — uniqueness heuristic basis

### Secondary (MEDIUM confidence)

- `examples/phoenix_host/deps/oban/lib/oban/migration.ex` — `verify_migrated!/1` confirmed `@doc false`; `current_version/1` confirmed public

### Tertiary (LOW confidence — verified via multiple primary sources)

- Uniqueness-timeout risk threshold (50,000) — derived from Oban engine analysis; not a documented Oban threshold

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all deps verified from mix.exs; no new deps needed
- Read-only catalog SQL: HIGH — queries verified from Oban migration source in repo
- `with_repo/2` boot pattern: HIGH — source code verified in deps
- Expected index set at v14: HIGH — exhaustively traced all v01-v14 migrations
- Migration-set manifest: HIGH — derived from install.ex source (authoritative)
- Uniqueness-timeout heuristic: MEDIUM — reasoning is sound but threshold is a judgment call
- Exit-code mechanism: HIGH — System.halt/1 is stdlib

**Research date:** 2026-05-29
**Valid until:** 2026-07-01 (Oban 2.x migration version could change on Oban upgrade; re-verify if oban dep is bumped beyond 2.22.x)
