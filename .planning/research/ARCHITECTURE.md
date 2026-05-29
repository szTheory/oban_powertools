# Architecture Research

**Domain:** Elixir hex library — release packaging and operability tooling integrated into a mature Oban/Ecto operator platform
**Researched:** 2026-05-28
**Confidence:** HIGH — grounded in direct inspection of all named modules; no speculative gaps

---

## How the Four v1.6 Deliverables Integrate

### System Overview

```
+-----------------------------------------------------------------------------+
|  Host Application (Phoenix)                                                 |
|  config :oban_powertools, repo: MyApp.Repo, auth_module: ..., ...          |
+-----------------------------------------------------------------------------+
|  mix tasks (lib/mix/tasks/)   -- read-only boot, no supervision dependency  |
|  +-----------------------------+  +----------------------------------------+|
|  | oban_powertools.doctor      |  | oban_powertools.limiter.explain        ||
|  |   → Doctor.Checks.*        |  | oban_powertools.limiter.simulate       ||
|  +----------+-----------------+  +------------------+---------------------+|
|             | pg_catalog (read-only SQL)              |                     |
|             | RuntimeConfig.repo!/0                   | Worker.limit_snap.. |
|             v                                         | Explain.explain/3   |
|  Doctor findings map + exit code                      | Limits.reserve/4    |
|  (0=pass, 1=warnings, 2=fail)                         | Limits.release/3    |
+-----------------------------------------------------------------------------+
|  ObanPowertools.Telemetry (FROZEN -- lib/oban_powertools/telemetry.ex)      |
|  @contract: families operator_action, limiter, cron, workflow, lifeline     |
|             |                                                                |
|             v NEW: Telemetry.metrics/0 (opt-in, no reporter dep)            |
|  Returns [Telemetry.Metrics.counter(...)] structs over the frozen @contract  |
+-----------------------------------------------------------------------------+
|  mix.exs -- MODIFIED for hex publication                                    |
|  version: "0.5.0", package: [...], description: "...", telemetry_metrics   |
+-----------------------------------------------------------------------------+
```

---

## Deliverable 1: Hex Release (mix.exs changes only)

### What Changes

**File modified: `mix.exs`** — the only file requiring edits for hex publication.

Required additions to `project/0`:

1. Bump `version` from `"0.1.0"` to `"0.5.0"`.
2. Add `description:` key — one sentence, under 300 chars for hex.pm listing.
3. Add `package:` key with `maintainers`, `licenses`, `links` (GitHub URL), and `files`. The `files:` list must include `lib/`, `mix.exs`, `README.md`, `guides/` and must exclude `examples/` and `test/` to keep the tarball lean.
4. Update `docs/0` to include new guides added in this milestone (see Deliverables 3 and 4). The existing three doc groups (`"Day 0"`, `"Builders"`, `"Operations"`) remain; new guides land in `"Operations"`.

No new deps are introduced by the hex release itself. The existing dep set (`ex_doc`, `igniter`, `telemetry`, `jason`, `oban`, `ecto_sql`, `postgrex`, `oban_web` optional) stays unchanged, with the one addition in Deliverable 4 below.

### Getting-Started Verification

Manual smoke-test: install the published package (`{:oban_powertools, "~> 0.5"}`) in a clean Phoenix app, run `mix oban_powertools.install`, run migrations, start the app, open `/ops/jobs`. This is not a code change — it is a verification gate before closing v1.6.

### New vs Modified

- **MODIFIED:** `mix.exs` — version, package, description, docs group updates

---

## Deliverable 2: `mix oban_powertools.doctor`

### Module Locations

```
lib/mix/tasks/oban_powertools.doctor.ex      (task entry point)
lib/oban_powertools/doctor/
  checks.ex           (dispatcher + result accumulator)
  index_check.ex      (pg_catalog index + invalid-index check)
  uniqueness_check.ex (lock_timeout / statement_timeout config check)
  config_check.ex     (oban_powertools app config vs RuntimeConfig contract)
  migration_check.ex  (migration drift detection via information_schema)
```

The task file lives at `lib/mix/tasks/oban_powertools.doctor.ex`, exactly matching the naming convention of the existing `lib/mix/tasks/oban_powertools.install.ex`. The internal `Doctor.Checks.*` modules live under `lib/oban_powertools/doctor/` — separate from the task so they are independently testable without invoking Mix machinery.

### How the Task Boots

Mix tasks in a library that need database access must boot the host application's config without starting the full supervision tree. The established Elixir pattern:

```elixir
defmodule Mix.Tasks.ObanPowertools.Doctor do
  use Mix.Task
  @shortdoc "Run read-only health checks against pg_catalog and Oban config"

  def run(_args) do
    Mix.Task.run("app.config")                    # loads config/*.exs, no supervisors
    Application.ensure_all_started(:ecto_sql)     # starts postgrex + ecto_sql OTP apps
    repo = ObanPowertools.RuntimeConfig.repo!()   # raises immediately if not configured
    {:ok, _pid} = repo.start_link()              # starts just the pool
    findings = ObanPowertools.Doctor.Checks.run(repo, oban_prefix())
    print_findings(findings)
    System.halt(exit_code(findings))
  end

  defp oban_prefix do
    Application.get_env(:oban, Oban, [])[:prefix] || "public"
  end
end
```

`Mix.Task.run("app.config")` loads all `config/*.exs` (including the host's `config :oban_powertools, repo: MyApp.Repo`) without starting supervisors. `repo.start_link()` starts only the Ecto adapter pool. This avoids starting `ObanPowertools.Application` (which starts PubSub, WorkflowCoordinator, HeartbeatWriter) — unnecessary and potentially broken for a read-only diagnostic task.

`RuntimeConfig.repo!/0` is the existing canonical seam. The `!` variant raises a clear, on-brand error message if `:repo` is unconfigured — correct for a task that literally cannot run without a repo.

### How Doctor Obtains the Oban Prefix

Oban's `prefix` config key (default `"public"`) determines which schema hosts `oban_jobs` and where `pg_catalog.pg_indexes` finds the Oban indexes. Resolution:

1. `Application.get_env(:oban, Oban, [])[:prefix]` — standard Oban config for the default instance.
2. Fall back to `"public"`.

After `Mix.Task.run("app.config")`, `Application.get_env/3` has the host's full config available. Calling `Oban.config()` would require the Oban supervisor to be running, which the task does not start. The `Application.get_env` path is correct here.

### Data Flow: pg_catalog Checks

```
Doctor task
  └─ Doctor.Checks.run(repo, prefix)
       |
       +─ ConfigCheck.run()
       |    └─ Application.get_env(:oban_powertools, :repo | :auth_module | ...)
       |    → %{status: :ok | :fail, findings: [...]}
       |    (pure Elixir, no DB query)
       |
       +─ IndexCheck.run(repo, prefix)
       |    └─ Ecto.Adapters.SQL.query!(repo, """
       |         SELECT i.relname AS indexname,
       |                ix.indisvalid,
       |                t.relname AS tablename
       |         FROM pg_catalog.pg_index ix
       |         JOIN pg_catalog.pg_class t ON t.oid = ix.indrelid
       |         JOIN pg_catalog.pg_class i ON i.oid = ix.indexrelid
       |         JOIN pg_catalog.pg_namespace n ON n.oid = t.relnamespace
       |         WHERE n.nspname = $1
       |           AND t.relname LIKE 'oban%'
       |       """, [prefix])
       |    → findings: invalid indexes, missing GIN on oban_jobs.tags, etc.
       |
       +─ UniquenessCheck.run(repo)
       |    └─ SELECT name, setting FROM pg_catalog.pg_settings
       |         WHERE name IN ('lock_timeout', 'statement_timeout')
       |    → findings: timeouts at 0 (unset) = warning
       |
       └─ MigrationCheck.run(repo)
            └─ SELECT table_name, column_name
               FROM information_schema.columns
               WHERE table_name LIKE 'oban_powertools_%'
            → compare vs hardcoded expected schema map in migration_check.ex
            → findings: missing tables, missing columns = drift

  → aggregate all findings
  → print to Mix.shell().info / .error
  → System.halt(exit_code)
     0 = all checks pass
     1 = warnings present, no failures
     2 = one or more check failures
```

All queries are read-only SELECT against `pg_catalog` and `information_schema`. The task never writes, never starts Oban, and never calls into `ObanPowertools.Limits`, `ObanPowertools.Lifeline`, or any runtime module.

### Migration Drift Detection

The `oban_powertools.install` task creates a deterministic set of tables with known column signatures. `Doctor.MigrationCheck` encodes the expected schema as a static map (table name to list of required column names) and compares it against `information_schema.columns` for all `oban_powertools_*` tables. A missing table or missing required column is a drift finding. No runtime migration tracking is needed — this is a static comparison against a hardcoded baseline.

### New vs Modified

- **NEW:** `lib/mix/tasks/oban_powertools.doctor.ex`
- **NEW:** `lib/oban_powertools/doctor/checks.ex`
- **NEW:** `lib/oban_powertools/doctor/index_check.ex`
- **NEW:** `lib/oban_powertools/doctor/uniqueness_check.ex`
- **NEW:** `lib/oban_powertools/doctor/config_check.ex`
- **NEW:** `lib/oban_powertools/doctor/migration_check.ex`
- **UNMODIFIED:** `lib/oban_powertools/runtime_config.ex` — `repo!/0` consumed as-is
- **UNMODIFIED:** All runtime modules (Limits, Explain, Lifeline, etc.)

---

## Deliverable 3: `mix oban_powertools.limiter.explain` and `.simulate`

### Module Locations

```
lib/mix/tasks/oban_powertools.limiter.explain.ex
lib/mix/tasks/oban_powertools.limiter.simulate.ex
```

Both tasks follow the same naming convention as `oban_powertools.install.ex` and `oban_powertools.doctor.ex`. No internal helper submodule is needed — the tasks delegate directly to existing `Explain` and `Limits` modules.

### Boot Pattern

Same as doctor: `Mix.Task.run("app.config")` + `Application.ensure_all_started(:ecto_sql)` + `repo.start_link()`. The limiter tasks also need the host's worker modules to be compiled (necessary so `Module.concat/1` resolves a real module and `__powertools_limits__/0` is callable). The mix task lifecycle guarantees compilation before `run/1` is called, so no explicit compilation step is needed.

### How `limiter.explain` Reuses Existing Logic

`ObanPowertools.Explain.explain/3` already accepts `repo:` as a keyword option (confirmed at `explain.ex:60`). The task is a thin CLI adapter:

```
mix oban_powertools.limiter.explain MyApp.Workers.IngestWorker --args '{"user_id":42}'
  → parse: worker_mod = Module.concat([worker_string])
  → parse: args = Jason.decode!(args_json)
  → call: Explain.explain(worker_mod, args, repo: repo)
  → receive: %{status:, blockers:, live_now:, snapshot_at_block_start:}
  → format and print to stdout
```

No changes to `Explain`. The task formats the returned map into human-readable output using `Mix.shell().info/1`.

### How `limiter.simulate` Reuses Existing Logic

`Limits.reserve/4` and `Limits.release/3` are the correct public API. Simulate runs N reserve+release cycles, printing each result:

```
mix oban_powertools.limiter.simulate MyApp.Workers.IngestWorker --count 5
  → for slot in 1..count:
       case Limits.reserve(repo, worker_mod, args) do
         {:ok, reservation} ->
           print "slot #{slot}: reserved"
           Limits.release(repo, reservation)  # immediate release = net-zero state change
         {:blocked, blockers} ->
           print "slot #{slot}: blocked by #{blocker.code} (#{blocker.summary})"
           break  # stop on first block — remaining slots would also block
       end
  → print summary: slots attempted, slots reserved, first-blocked-at
```

Simulate is a write path (real reserve+release cycles), but is safe in development and staging because the release immediately follows each reserve. Net limiter state change is zero when all slots succeed. The task prints a clear disclaimer that it exercises the live limiter state.

No changes to `Limits` or `Explain`.

### Rate-Limit Glossary

The glossary (`bucket_capacity`, `bucket_span_ms`, `scope_kind`, `cooldown`, `weight`, `partition_key`, `partition_strategy`) ships as:

- `--help` output in both limiter tasks (inline `@moduledoc` or `IO.puts/1` in `run/1`)
- A new guide: `guides/limiter-cli-reference.md`

### New vs Modified

- **NEW:** `lib/mix/tasks/oban_powertools.limiter.explain.ex`
- **NEW:** `lib/mix/tasks/oban_powertools.limiter.simulate.ex`
- **NEW guide:** `guides/limiter-cli-reference.md`
- **UNMODIFIED:** `lib/oban_powertools/explain.ex` — called via `explain/3` as-is
- **UNMODIFIED:** `lib/oban_powertools/limits.ex` — called via `reserve/4` + `release/3` as-is
- **MODIFIED (minor):** `mix.exs` `docs/0` — add new guide to `"Operations"` group

---

## Deliverable 4: `Telemetry.metrics/0` over the Frozen Contract

### Integration Point

`ObanPowertools.Telemetry` already has `@contract` (a map of families and low-cardinality metadata keys) and `contract/0` (the public accessor). The contract covers five families: `operator_action`, `limiter`, `cron`, `workflow`, `lifeline`. Each family declares the allowed low-cardinality tag keys.

The new `metrics/0` function is **added to the existing `telemetry.ex`** — not a new module. It generates `Telemetry.Metrics` structs that map directly onto the frozen contract's event names and tag keys.

### What `metrics/0` Returns

```elixir
def metrics do
  [
    # operator_action family
    Telemetry.Metrics.counter("oban_powertools.operator_action.executed",
      tags: [:action, :source]),

    # limiter family -- three key events
    Telemetry.Metrics.counter("oban_powertools.limiter.reserved",
      tags: [:action, :resource, :scope]),
    Telemetry.Metrics.counter("oban_powertools.limiter.blocked",
      tags: [:action, :blocker_code, :resource, :scope]),
    Telemetry.Metrics.counter("oban_powertools.limiter.released",
      tags: [:action, :resource, :scope]),

    # cron family
    Telemetry.Metrics.counter("oban_powertools.cron.triggered",
      tags: [:action, :source, :overlap_policy, :catch_up_policy]),

    # workflow family -- four sub-events, each with their own tag set
    Telemetry.Metrics.counter("oban_powertools.workflow.step_completed",
      tags: [:outcome, :terminal_cause, :semantics_version]),
    Telemetry.Metrics.counter("oban_powertools.workflow.step_unblocked",
      tags: [:scope, :state, :semantics_version]),
    Telemetry.Metrics.counter("oban_powertools.workflow.cascade_cancelled",
      tags: [:scope, :outcome, :terminal_cause, :semantics_version]),
    Telemetry.Metrics.counter("oban_powertools.workflow.workflow_terminal",
      tags: [:state, :outcome, :terminal_cause, :semantics_version]),

    # lifeline family
    Telemetry.Metrics.counter("oban_powertools.lifeline.executed",
      tags: [:action, :incident_class, :target_type, :outcome]),
  ]
end
```

Tags are taken directly from `@contract.families.*`. Event name suffixes (`:executed`, `:blocked`, `:released`, etc.) must match what the `execute_*_event/3` helpers emit — that match must be verified against the actual `execute_limiter_event/3`, `execute_operator_action/3`, etc. calls in `Limits`, `Operator`, and `Lifeline` during implementation.

### Why No `oban_met` Dependency

`oban_met` is a reporter (live ETS store + socket broadcaster). `Telemetry.Metrics` is the standard Elixir library for declaring metric definitions — pure structs, no runtime process. A host app passes `ObanPowertools.Telemetry.metrics()` to their reporter of choice (Parapet, PromEx, StatsD, Datadog). The library ships the definition, not the pipeline. This is identical to how Phoenix ships `Phoenix.LiveDashboard.Metrics` — declare, don't report.

### Dependency Situation

`Telemetry.Metrics` is not currently in `mix.exs`. It is always available in Phoenix host apps (`phoenix_live_dashboard` depends on it), but correctness requires the library to declare it explicitly as optional:

```elixir
{:telemetry_metrics, "~> 1.0", optional: true}
```

This lets hosts that want `metrics/0` use it without forcing it on hosts that only use raw telemetry events. The existing `{:telemetry, "~> 1.4"}` dep is sufficient for raw event emission; `telemetry_metrics` is only needed when `metrics/0` is called.

### Relationship to the Frozen Contract

`metrics/0` is a mechanical translation of `@contract` into `Telemetry.Metrics` structs. No new contract knowledge is introduced. No new events are emitted. If the frozen contract is ever amended (via the existing locked-CONTEXT amendment process), `metrics/0` is updated in the same commit as the contract change.

### New vs Modified

- **MODIFIED:** `lib/oban_powertools/telemetry.ex` — add `metrics/0` function only; no other changes
- **MODIFIED:** `mix.exs` — add `{:telemetry_metrics, "~> 1.0", optional: true}` to `deps/0`
- **NEW guide:** `guides/telemetry-and-slo.md` (Parapet integration walkthrough, PromEx/StatsD examples, SLO dashboard setup)
- **MODIFIED (minor):** `mix.exs` `docs/0` — add new guide to `"Operations"` group

---

## Complete File Change Summary

### New Files

```
lib/mix/tasks/oban_powertools.doctor.ex
lib/mix/tasks/oban_powertools.limiter.explain.ex
lib/mix/tasks/oban_powertools.limiter.simulate.ex
lib/oban_powertools/doctor/checks.ex
lib/oban_powertools/doctor/index_check.ex
lib/oban_powertools/doctor/uniqueness_check.ex
lib/oban_powertools/doctor/config_check.ex
lib/oban_powertools/doctor/migration_check.ex
guides/telemetry-and-slo.md
guides/limiter-cli-reference.md
```

### Modified Files

```
lib/oban_powertools/telemetry.ex   -- add metrics/0 function
mix.exs                            -- version bump, package block, description,
                                      telemetry_metrics optional dep, docs group updates
```

### Unmodified (explicitly confirmed)

```
lib/oban_powertools/explain.ex          -- called as-is via explain/3
lib/oban_powertools/limits.ex           -- called as-is via reserve/4 + release/3
lib/oban_powertools/runtime_config.ex   -- consumed as-is via repo!/0
lib/oban_powertools/application.ex      -- mix tasks do NOT start the supervision tree
lib/oban_powertools/worker.ex           -- limit_snapshot/2 called indirectly via Explain
lib/mix/tasks/oban_powertools.install.ex -- unchanged; naming convention only
```

---

## Project Structure After v1.6

```
lib/
+-- mix/
|   +-- tasks/
|       +-- oban_powertools.install.ex            (existing)
|       +-- oban_powertools.doctor.ex             (NEW)
|       +-- oban_powertools.limiter.explain.ex    (NEW)
|       +-- oban_powertools.limiter.simulate.ex   (NEW)
+-- oban_powertools/
    +-- doctor/                                   (NEW directory)
    |   +-- checks.ex                             (NEW)
    |   +-- index_check.ex                        (NEW)
    |   +-- uniqueness_check.ex                   (NEW)
    |   +-- config_check.ex                       (NEW)
    |   +-- migration_check.ex                    (NEW)
    +-- telemetry.ex                              (MODIFIED: +metrics/0)
    +-- ... (all other modules unmodified)

guides/
    +-- telemetry-and-slo.md                      (NEW)
    +-- limiter-cli-reference.md                  (NEW)

mix.exs                                           (MODIFIED)
```

---

## Architectural Patterns

### Pattern 1: Config-Only Application Boot for Mix Tasks

**What:** Load host config via `Mix.Task.run("app.config")` without starting any OTP application supervisor, then start only the Ecto repo pool directly.

**When to use:** Any mix task needing DB access that must not start Phoenix, PubSub, or Oban supervisors. Applies to `doctor`, `limiter.explain`, and `limiter.simulate`.

**Trade-offs:** Minimal boot means fast task startup and no risk of crashing on missing process dependencies (e.g., no Oban supervisor = no Oban queue polling). The cost is that any feature requiring a live supervision tree (e.g., PubSub broadcast) is unavailable — not relevant for read-only diagnostic tasks.

**Concrete sequence:**
```elixir
Mix.Task.run("app.config")
Application.ensure_all_started(:ecto_sql)
repo = ObanPowertools.RuntimeConfig.repo!()
{:ok, _pid} = repo.start_link()
```

**Why not `Mix.Task.run("app.start")`:** That starts the full OTP application tree including `ObanPowertools.Application` (PubSub + WorkflowCoordinator + HeartbeatWriter). These processes expect a fully configured host and may fail or emit misleading errors when run in a bare mix task context.

### Pattern 2: Thin Task Adapter (no logic in the task)

**What:** Mix tasks as thin CLI adapters — parse args, resolve repo, call existing library function, format output. Zero business logic in the task module itself.

**When to use:** When a public function already exists with the needed signature (`Explain.explain/3`, `Limits.reserve/4`, `Limits.release/3`). The limiter tasks use this pattern.

**Trade-offs:** Tasks become trivially thin and easy to test by testing the library functions directly. Output formatting lives in the task (not in the library), so CLI UX changes never touch the library API.

### Pattern 3: Compile-Time Metric Definitions (no reporter dependency)

**What:** `metrics/0` returns a static list of `Telemetry.Metrics` structs derived directly from the frozen `@contract` module attribute. The function has no side effects and requires no runtime process.

**When to use:** When the event schema is known at compile time (frozen contract) and the library should remain reporter-agnostic.

**Trade-offs:** Host must wire the returned list into their reporter at startup. The library ships the definition; the host owns the pipeline. This is identical to how Phoenix ships LiveDashboard metric definitions.

---

## Data Flows

### Doctor Check Flow

```
mix oban_powertools.doctor
    |
    +- app.config + ecto_sql + repo.start_link()
    |
    +- Doctor.Checks.run(repo, oban_prefix)
    |    |
    |    +- ConfigCheck.run()               → pure Elixir; Application.get_env
    |    +- IndexCheck.run(repo, prefix)    → pg_catalog.pg_index + pg_class + pg_namespace
    |    +- UniquenessCheck.run(repo)       → pg_catalog.pg_settings
    |    +- MigrationCheck.run(repo)        → information_schema.columns
    |
    +- format findings → Mix.shell().info / .error
    |
    +- System.halt(0 | 1 | 2)
```

### Limiter Explain Flow

```
mix oban_powertools.limiter.explain WorkerMod --args '{...}'
    |
    +- app.config + ecto_sql + repo.start_link()
    +- worker_mod = Module.concat([worker_string])
    +- args = Jason.decode!(args_json)
    |
    +- Explain.explain(worker_mod, args, repo: repo)
    |    |
    |    +- Worker.limit_snapshot(worker_mod, args)    # reads @powertools_limits
    |    +- live_blockers(repo, snapshot, now)         # queries limit_resources + limit_states
    |    |
    |    +- %{status:, blockers:, live_now:, snapshot_at_block_start:}
    |
    +- format and print to stdout
```

### Limiter Simulate Flow

```
mix oban_powertools.limiter.simulate WorkerMod --count 5
    |
    +- app.config + ecto_sql + repo.start_link()
    +- worker_mod, args parsed (same as explain)
    |
    +- for slot in 1..count:
    |    Limits.reserve(repo, worker_mod, args)
    |      {:ok, reservation}    → print "slot N: reserved"; Limits.release(repo, reservation)
    |      {:blocked, blockers}  → print "slot N: blocked by X"; stop
    |
    +- print summary table
```

### Telemetry.metrics/0 Host Wiring Flow

```
# Host application.ex or Telemetry module:
def metrics do
  ObanPowertools.Telemetry.metrics()   # pure data, no side effects
  ++ your_app_metrics()
end

# Wired into reporter at supervision startup:
children = [
  {Parapet.Reporter, metrics: MyApp.Telemetry.metrics()}
]
```

---

## Integration Boundaries

### Reused Unchanged

| Existing Module | Reused By | Reuse Mechanism |
|-----------------|-----------|-----------------|
| `RuntimeConfig.repo!/0` | `doctor`, `limiter.explain`, `limiter.simulate` | Direct call in task boot |
| `Explain.explain/3` | `limiter.explain` task | Public API; `repo:` opt passed through |
| `Limits.reserve/4` | `limiter.simulate` task | Public API |
| `Limits.release/3` | `limiter.simulate` task | Public API |
| `Telemetry.@contract` | `Telemetry.metrics/0` | Module attribute read at compile time |
| `Ecto.Adapters.SQL.query!/3` | `Doctor.Checks.*` | Same pattern already used in `lifeline.ex:573` |

### New and Isolated

| New Module | Calls Into | Called By |
|------------|-----------|-----------|
| `Mix.Tasks.ObanPowertools.Doctor` | `RuntimeConfig`, `Doctor.Checks.*`, `System.halt/1` | Developer CLI |
| `Doctor.Checks.*` | `Ecto.Adapters.SQL.query!`, `Application.get_env` | Doctor task only |
| `Mix.Tasks.ObanPowertools.Limiter.Explain` | `RuntimeConfig`, `Explain.explain/3`, `Jason.decode!` | Developer CLI |
| `Mix.Tasks.ObanPowertools.Limiter.Simulate` | `RuntimeConfig`, `Limits.reserve/4`, `Limits.release/3`, `Jason.decode!` | Developer CLI |

### Modified and Why

| Modified Module | Change | Why |
|-----------------|--------|-----|
| `lib/oban_powertools/telemetry.ex` | Add `metrics/0` | Exposes frozen contract as `Telemetry.Metrics` structs for opt-in host wiring |
| `mix.exs` | Version, package, description, optional dep, docs | Hex publication + new guides |

---

## Suggested Build Order

```
1. mix.exs: version + package block
   → Zero risk; unblocks hex tarball verification immediately.

2. Telemetry.metrics/0
   → Single function addition to a frozen, stable module.
   → No runtime deps; the frozen @contract is the complete spec.
   → Build early so the telemetry guide can show working code.

3. Doctor: ConfigCheck (pure Elixir, no DB)
   → Validates RuntimeConfig contract against Application config.
   → No DB or pg_catalog needed; fastest to build and test.

4. Doctor: MigrationCheck
   → information_schema.columns query; validates installer tables.
   → Depends on the boot pattern proved in step 3.

5. Doctor: IndexCheck + UniquenessCheck
   → pg_catalog queries; requires understanding of prefix resolution.
   → Both are independent of each other; can be built in parallel.

6. Doctor: Checks dispatcher + task entry point + exit codes
   → Wires steps 3-5; adds output formatting and System.halt/1.

7. mix oban_powertools.limiter.explain
   → Thin wrapper over Explain.explain/3; boot pattern from doctor reused.
   → No dependency on simulate.

8. mix oban_powertools.limiter.simulate
   → Thin wrapper over Limits.reserve/4 + release/3; real write path.
   → Build after explain confirms the boot pattern and arg parsing.
   → Test fixtures need careful setup (reserve+release against real limiter state).

9. New guides (telemetry-and-slo.md, limiter-cli-reference.md)
   → Write after code is proven; update mix.exs docs/0 at this point.

10. Getting-started verification
    → Install from published hex in clean Phoenix app.
    → Run all four new tasks; confirm exit codes and output.
    → Final gate before closing v1.6.
```

**Hard dependency:** Step 1 (mix.exs) must precede step 10 (hex verification). Step 2 (metrics/0) must precede guide writing in step 9. Steps 3–8 are independent of each other and can be phased as separate plans.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Starting the Full OTP Application in Mix Tasks

**What people do:** Call `Mix.Task.run("app.start")` for "easy" DB access.

**Why it's wrong:** `ObanPowertools.Application.start/2` starts PubSub, WorkflowCoordinator, and HeartbeatWriter. These processes expect a fully configured host app and will crash or emit misleading errors when run in a bare mix task context for a health check.

**Do this instead:** `app.config` + `Application.ensure_all_started(:ecto_sql)` + `repo.start_link()`. This is the minimal boot that provides a working Ecto adapter pool.

### Anti-Pattern 2: Logic in the Task Module

**What people do:** Put blocker parsing, pg_catalog query construction, or resource aggregation directly in the task's `run/1` function.

**Why it's wrong:** Untestable without invoking Mix task machinery. The task becomes a test-hostile monolith.

**Do this instead:** All business logic in `Doctor.Checks.*` modules (for doctor) or delegated to `Explain`/`Limits` (for limiter tasks). Tasks handle arg parsing and output formatting only.

### Anti-Pattern 3: Emitting New Events for `metrics/0`

**What people do:** Add new `Telemetry.execute_*/3` calls to match the metric definitions, thinking each metric definition needs a dedicated event source.

**Why it's wrong:** The existing `execute_limiter_event/3`, `execute_operator_action/3`, etc. already emit the correct events. `metrics/0` defines how to observe those existing events — it does not create new ones.

**Do this instead:** `metrics/0` maps onto events the existing helpers already emit. The metric event name strings must match the actual atom paths those helpers produce.

### Anti-Pattern 4: Adding `oban_met` as a Dependency

**What people do:** Pull in `oban_met` to get "real" metric definitions or live job counts as part of the telemetry story.

**Why it's wrong:** `oban_met` is a reporter with its own ETS store and socket process. It couples the library to a significant runtime footprint, creates version coupling with `oban_web`, and drifts toward "rebuild Oban Web" — explicitly out of scope per the project constraints.

**Do this instead:** `Telemetry.metrics/0` returns pure `Telemetry.Metrics` structs. Hosts wire them into their own reporter. The telemetry guide shows the Parapet wiring pattern. `oban_met` is a v1.9 optional-read concern only.

### Anti-Pattern 5: Blocking Simulate on First Blocked Slot Then Continuing

**What people do:** Continue the reserve+release loop after a blocked result, trying to show "how many out of N would be blocked."

**Why it's wrong:** Once the bucket is saturated for a given partition key, all subsequent reserve attempts for the same worker/args will also block. Continuing produces N-k identical "blocked" results and inflates the simulation table with noise.

**Do this instead:** Stop the loop on the first blocked slot. Print the first-blocked-at index clearly. The output is informative: "3 of 5 slots reserved; slot 4 blocked by limit_reached."

---

## Sources

All findings derived from direct inspection of:

- `/Users/jon/projects/oban_powertools/lib/oban_powertools/telemetry.ex` — frozen `@contract`, existing `execute_*_event/3` helpers
- `/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex` — `explain/3` public API; `repo:` opt at line 60
- `/Users/jon/projects/oban_powertools/lib/oban_powertools/limits.ex` — `reserve/4`, `release/3` public API
- `/Users/jon/projects/oban_powertools/lib/oban_powertools/runtime_config.ex` — `repo!/0` seam
- `/Users/jon/projects/oban_powertools/lib/oban_powertools/application.ex` — supervision tree (what NOT to start in tasks)
- `/Users/jon/projects/oban_powertools/lib/oban_powertools/worker.ex` — `limit_snapshot/2` consumed by `Explain`
- `/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex` — naming convention, Igniter pattern
- `/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:573` — precedent for `Ecto.Adapters.SQL.query!/3` in library code
- `/Users/jon/projects/oban_powertools/mix.exs` — current deps, docs groups, version
- `/Users/jon/projects/oban_powertools/.planning/PROJECT.md` — Decision Posture, Constraints, Key Decisions
- `/Users/jon/projects/oban_powertools/.planning/threads/2026-05-28-post-v1.5-next-milestone.md` — v1.6 scope
- `examples/phoenix_host/deps/oban/lib/oban/config.ex` — Oban `prefix` config key (default `"public"`)

---
*Architecture research for: Oban Powertools v1.6 Release & Operability*
*Researched: 2026-05-28*
