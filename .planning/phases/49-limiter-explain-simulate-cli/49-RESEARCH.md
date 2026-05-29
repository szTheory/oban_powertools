# Phase 49: Limiter Explain/Simulate CLI - Research

**Researched:** 2026-05-29
**Domain:** Elixir Mix task CLI, token-bucket limiter seams, pure-function extraction, Hex library packaging
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Both tasks mirror `Mix.Tasks.ObanPowertools.Doctor` wholesale: `--repo`/`--prefix`/`--oban-name` resolution with identical boot strategy; `--format human|json` with `schema_version: 1` (independent from doctor's schema, version 1 for both new tasks). Boot via `Mix.Task.run("app.config")` + `Ecto.Migrator.with_repo/2`. Never starts Oban. Module-name flags via `Module.safe_concat` — never `String.to_atom` on raw CLI input.
- **D-02:** Explain exits `0` normally, `2` on cannot-run (no repo / DB unreachable / unknown worker). Simulate exits `0` on success, `2` on bad input/unknown worker.
- **D-03:** Explain primary path: `--resource NAME [--partition KEY]` (partition defaults to `__global__`). Resolves live state from `Limits.Resource`/`State` and renders via `Explain.explain_snapshot/2` over latest persisted blocker snapshot. Secondary path: `--worker MOD --args JSON` maps onto `Explain.explain/3`.
- **D-04:** Honest empty state: no Resource/State row and no snapshot → report `runnable` / "no limiter state recorded yet" rather than error. Unknown `--worker` module is a cannot-run error (exit 2).
- **D-05:** Simulate reads `--worker MOD` via `ObanPowertools.Worker.limit_snapshot/2`; operator may override `--bucket-capacity`, `--bucket-span-ms`, `--weight`, `--count`, `--partition`.
- **D-06:** Zero side effects via extracted pure token-bucket core. Extract `normalize_bucket/3` + the cooldown/`tokens_used + weight > bucket_capacity` cond from `attempt_reservation/5` into a pure function called by both `Limits.reserve/3` and simulate. Rejected alternative: rolled-back transaction (telemetry/audit/history fire outside transaction boundary).
- **D-07:** Simulate output: per-request verdict for `--count N` sequential reservations against a fresh (empty) bucket: `reserved` vs `blocked` with blocker code and `retry_at`. Human = readable sequence; JSON = `schema_version: 1`.
- **D-08:** Rate-limit glossary as a `@moduledoc` section, sourced from a single shared string that also feeds `guides/limits-and-explain.md`. Covers: `token_bucket`, `bucket_capacity`, `bucket_span_ms`, `weight`/`weight_by`, `partition`/`partition_by`/`scope` (global vs partitioned), `cooldown`, blocker codes `limit_reached`/`cooldown`.

### Claude's Discretion
- Exact human-format layout (sectioning, ANSI/TTY-degradation style), flag short-forms, and whether a `--glossary` print flag is added in addition to `mix help`.
- Whether the pure-core lives in `ObanPowertools.Limits` directly or a small `ObanPowertools.Limits.Bucket`-style submodule.

### Deferred Ideas (OUT OF SCOPE)
- Mutating limiter actions from the CLI (cooldown/reserve/release).
- Telemetry/SLO metrics surface and Parapet guide (Phase 50).
- Richer multi-step / time-advancing simulation timeline across multiple bucket spans.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS-06 | Operator can run `mix oban_powertools.limiter.explain` to explain a limiter's current blocking state, reusing the existing `Explain` API rather than duplicating limiter logic. | D-03/D-04 + `Explain.explain/3` and `Explain.explain_snapshot/2` verified signatures; UI confirms resource-primary vocabulary. |
| OPS-07 | Operator can run `mix oban_powertools.limiter.simulate` to preview limiter behavior for a given config without mutating any real limiter state. | D-05/D-06/D-07 + pure-core extraction boundary precisely identified in `Limits.attempt_reservation/5`. |
| OPS-08 | The limiter CLI ships the rate-limit glossary in its help/documentation output. | D-08 + single-source-of-truth mechanism via `@moduledoc`/guide confirmed; glossary terms enumerated from live code. |
</phase_requirements>

---

## Summary

Phase 49 ships two new Mix tasks (`oban_powertools.limiter.explain` and `oban_powertools.limiter.simulate`) plus the rate-limit glossary as CLI help text. All design decisions are locked in CONTEXT.md. This research validates those decisions against the live source code, identifies exact extraction boundaries for the D-06 pure-core refactor, and surfaces implementation landmines.

The Doctor task (`lib/mix/tasks/oban_powertools.doctor.ex`) is a complete, working template. Its CLI conventions — `OptionParser.parse/2` with `@switches`, `Module.safe_concat` for module resolution, `Mix.Task.run("app.config")` before `Ecto.Migrator.with_repo/2`, format-atom mapping via `case` (not `String.to_atom`), and `System.halt` outside the callback — must be replicated verbatim. The `Doctor.Formatter` pattern (`:human` with `IO.ANSI.enabled?/0`-gated color, `:json` with `Jason.encode!` and `schema_version: 1`) is the formatter template.

The riskiest task is D-06: extracting the pure token-bucket decision core from `Limits.attempt_reservation/5`. The exact boundary is identified: `normalize_bucket/3` + the three-clause `cond` in `attempt_reservation/5` are pure and extractable; `blocked/4` (which fires `Telemetry.execute_limiter_event`, `record_history_fact`, and `Explain.persist_snapshot` indirectly) must stay in the side-effecting path. The pure function takes a `%State{}`, `%Resource{}`, weight, and `now` and returns `{:ok, tokens_used_delta}` or `{:blocked, [blocker_map]}`.

**Primary recommendation:** Follow CONTEXT.md decisions exactly. Read the Doctor task line-by-line as the implementation template. Extract the pure core in `ObanPowertools.Limits` (not a submodule) for minimal diff surface and call it from both `reserve/3` and simulate.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CLI flag parsing + boot | Mix Task | — | Mix task layer handles operator input; Ecto.Migrator.with_repo for repo-only boot |
| Explain (live state read) | API / Backend (`Explain` module) | Database / Storage | Reads Resource/State tables; task is a thin adapter |
| Simulate (pure computation) | API / Backend (pure Limits core) | — | No DB write; worker config read-only from module attributes |
| Glossary text | Mix Task `@moduledoc` | Guide (`guides/limits-and-explain.md`) | Single shared string, two consumers |
| Pure token-bucket math | API / Backend (`ObanPowertools.Limits`) | — | Extracted from `attempt_reservation/5`; no DB interaction |
| Output formatting | Mix Task formatter | — | Mirrors `Doctor.Formatter` pattern |

---

## Standard Stack

No new runtime dependencies. All required modules already exist in the library. [VERIFIED: live codebase read]

### Core — Existing Modules Reused

| Module | Current Location | Role in Phase 49 |
|--------|-----------------|-----------------|
| `Mix.Tasks.ObanPowertools.Doctor` | `lib/mix/tasks/oban_powertools.doctor.ex` | Convention donor; replicate wholesale |
| `ObanPowertools.Doctor.Formatter` | `lib/oban_powertools/doctor/formatter.ex` | Formatter pattern (human/JSON with ANSI degradation) |
| `ObanPowertools.Explain` | `lib/oban_powertools/explain.ex` | `explain/3` and `explain_snapshot/2` |
| `ObanPowertools.Limits` | `lib/oban_powertools/limits.ex` | `reserve/3`, `partition_defaults/0`, and the pure core to extract |
| `ObanPowertools.Limits.Resource` | `lib/oban_powertools/limits/resource.ex` | Schema for limiter config |
| `ObanPowertools.Limits.State` | `lib/oban_powertools/limits/state.ex` | Schema for live runtime state |
| `ObanPowertools.Worker` | `lib/oban_powertools/worker.ex` | `limit_snapshot/2` for simulate's `--worker` flag |
| `ObanPowertools.RuntimeConfig` | `lib/oban_powertools/runtime_config.ex` | `repo!/0` fallback |
| `Jason` | already a dep | JSON output encoding |

### New Files to Create

| File | Module | Purpose |
|------|--------|---------|
| `lib/mix/tasks/oban_powertools.limiter.explain.ex` | `Mix.Tasks.ObanPowertools.Limiter.Explain` | OPS-06 CLI entry point |
| `lib/mix/tasks/oban_powertools.limiter.simulate.ex` | `Mix.Tasks.ObanPowertools.Limiter.Simulate` | OPS-07 CLI entry point |

### One Existing File to Modify

| File | Change |
|------|--------|
| `lib/oban_powertools/limits.ex` | Extract pure token-bucket core; add new pure function called by `reserve/3` and simulate |
| `guides/limits-and-explain.md` | Add/source the shared glossary string |

### Package Legitimacy Audit

No new packages are installed. Zero-new-runtime-deps constraint (REQUIREMENTS.md) is satisfied by reusing existing modules. [VERIFIED: live codebase]

| Package | Status |
|---------|--------|
| New runtime packages | None — constraint satisfied |

---

## Architecture Patterns

### System Architecture Diagram

```
Operator CLI
     │
     ▼
mix oban_powertools.limiter.explain
     │ --resource NAME [--partition KEY]   (primary path, D-03)
     │ --worker MOD --args JSON            (secondary path, D-03)
     │ --repo / --prefix / --oban-name / --format
     │
     ▼
Mix.Task.run("app.config")   ← loads config + code paths, no apps started
     │
     ▼
Ecto.Migrator.with_repo(repo_module, fn repo -> ... end)
     │
     ├──[primary path]──► repo.get_by(Resource, name: name)
     │                         │
     │                    repo.one(from Explain, where scope_id == name, limit 1)
     │                         │
     │                    Explain.explain_snapshot(snapshot, repo: repo)
     │                         │ reads Resource + State for live_now
     │                         ▼
     │                    %{status, blockers, live_now, snapshot_at_block_start}
     │
     └──[secondary path]─► Explain.explain(worker_mod, parsed_args, repo: repo)
                               │ calls Worker.limit_snapshot/2 internally
                               │ reads Resource + State
                               ▼
                          %{status, blockers, live_now, snapshot_at_block_start}
     │
     ▼
Formatter (human | json schema_version:1) → stdout → System.halt(exit_code)


mix oban_powertools.limiter.simulate
     │ --worker MOD [--bucket-capacity N] [--bucket-span-ms N]
     │ [--weight N] [--count N] [--partition KEY] [--format human|json]
     │
     ▼
Mix.Task.run("app.config")
     │
     ▼
Worker.limit_snapshot(worker_mod, %{})  ← reads @powertools_limits compile-time config
     │ apply flag overrides (capacity/span/weight/partition)
     │
     ▼
Pure token-bucket core (no DB, no side effects)
     │ simulate N sequential reservations against a fresh in-memory bucket
     │ for each: normalize_bucket_pure(state, span_ms, now) → check cond
     │           → {:reserved, new_tokens_used} | {:blocked, blocker_code, retry_at}
     │
     ▼
Formatter (per-request verdict sequence) → stdout → System.halt(0 | 2)
```

### Recommended Project Structure

```
lib/
├── mix/tasks/
│   ├── oban_powertools.doctor.ex            # existing template
│   ├── oban_powertools.limiter.explain.ex   # new — OPS-06
│   └── oban_powertools.limiter.simulate.ex  # new — OPS-07
├── oban_powertools/
│   ├── limits.ex                            # modified — pure core extracted
│   └── ...
guides/
└── limits-and-explain.md                   # modified — glossary added/sourced
test/
└── mix/tasks/
    ├── oban_powertools.doctor_test.exs      # existing pattern
    ├── oban_powertools.limiter.explain_test.exs   # new
    └── oban_powertools.limiter.simulate_test.exs  # new
```

---

## Key Pattern: Doctor Task Template (Read in Full Before Implementing)

The Doctor task is the exact template. Every line below must be understood before writing the new tasks. [VERIFIED: `lib/mix/tasks/oban_powertools.doctor.ex`]

### @switches Declaration

```elixir
# Doctor's switches — verbatim pattern to replicate
@switches [
  repo: :string,
  prefix: :string,
  oban_name: :string,
  format: :string,
  strict: :boolean
]

# Explain's switches will be:
@switches [
  repo: :string,
  prefix: :string,
  oban_name: :string,
  format: :string,
  resource: :string,   # primary path
  partition: :string,  # primary path (defaults to "__global__")
  worker: :string,     # secondary path
  args: :string        # secondary path (JSON string)
]

# Simulate's switches will be:
@switches [
  repo: :string,
  prefix: :string,
  oban_name: :string,
  format: :string,
  worker: :string,
  bucket_capacity: :integer,
  bucket_span_ms: :integer,
  weight: :integer,
  count: :integer,
  partition: :string
]
```

### Boot Strategy (verbatim)

```elixir
# Source: lib/mix/tasks/oban_powertools.doctor.ex lines 73-74
# MANDATORY: run before OptionParser.parse; never use @requirements or "app.start"
Mix.Task.run("app.config")

{opts, _args, _invalid} = OptionParser.parse(argv, strict: @switches)

repo_module = resolve_repo(opts)

result =
  Ecto.Migrator.with_repo(
    repo_module,
    fn repo ->
      # ... all work here; System.halt NOT called inside callback
      exit_code  # return exit code from callback
    end,
    pool_size: 2
  )

case result do
  {:ok, exit_code, _apps} -> System.halt(exit_code)
  {:error, reason} ->
    Mix.shell().error("cannot start repo — ...")
    System.halt(2)
end
```

### Module Resolution (verbatim — T-48-05 safety)

```elixir
# Source: lib/mix/tasks/oban_powertools.doctor.ex lines 132-144
defp resolve_repo(opts) do
  case Keyword.get(opts, :repo) do
    nil -> ObanPowertools.RuntimeConfig.repo!()
    repo_string -> Module.safe_concat([repo_string])
  end
end

# Reuse this for --worker flag resolution in explain/simulate:
defp resolve_worker(opts) do
  case Keyword.get(opts, :worker) do
    nil -> {:error, :no_worker}
    worker_string -> {:ok, Module.safe_concat([worker_string])}
  end
end
```

### Format Mapping (verbatim — no String.to_atom on user input)

```elixir
# Source: lib/mix/tasks/oban_powertools.doctor.ex lines 92-97
format =
  case Keyword.get(opts, :format, "human") do
    "json" -> :json
    _ -> :human
  end
```

### Prefix Resolution (verbatim — explain may need prefix for Oban schema)

```elixir
# Source: lib/mix/tasks/oban_powertools.doctor.ex lines 151-178
# Note: String.to_existing_atom is acceptable for oban_name (pre-existing atoms)
# but NEVER String.to_atom on raw user-supplied values (T-48-05)
defp resolve_prefix(opts) do
  cond do
    prefix = Keyword.get(opts, :prefix) ->
      prefix
    true ->
      oban_name = Keyword.get(opts, :oban_name, "Oban")
      oban_key =
        try do
          String.to_existing_atom(oban_name)
        rescue
          ArgumentError -> nil
        end
      case oban_key && Application.get_env(:oban, oban_key) do
        config when is_list(config) -> Keyword.get(config, :prefix, "public")
        _ -> "public"
      end
  end
end
```

### Human Formatter Pattern (from Doctor.Formatter)

```elixir
# Source: lib/oban_powertools/doctor/formatter.ex
# ANSI degradation: IO.ANSI.enabled?() guards all colorization
defp colorize(text, color) do
  if IO.ANSI.enabled?() do
    [color, text, IO.ANSI.reset()] |> IO.ANSI.format() |> IO.iodata_to_binary()
  else
    text
  end
end
```

### JSON Schema Pattern (from Doctor.Formatter)

```elixir
# Source: lib/oban_powertools/doctor/formatter.ex lines 154-169
# schema_version: 1 is a stability contract — must appear at top level
payload = %{
  schema_version: 1,
  # ... task-specific fields
}
Jason.encode!(payload)
```

---

## D-06 Critical: Pure Token-Bucket Core Extraction

This is the riskiest task. The extraction boundary must be precise. [VERIFIED: `lib/oban_powertools/limits.ex`]

### What Is Pure (Safe to Extract)

These two private functions contain zero side effects:

```elixir
# Source: lib/oban_powertools/limits.ex lines 249-257
defp normalize_bucket(%State{} = state, bucket_span_ms, now) do
  reset_at = DateTime.add(state.bucket_started_at, bucket_span_ms, :millisecond)
  if DateTime.compare(now, reset_at) == :lt do
    state
  else
    %{state | tokens_used: 0, bucket_started_at: now}
  end
end

# Source: lib/oban_powertools/limits.ex lines 259-261
defp cooldown_active?(state, now) do
  match?(%DateTime{}, state.cooldown_until) and
    DateTime.compare(state.cooldown_until, now) == :gt
end
```

The three-clause `cond` inside `attempt_reservation/5` (lines 213-246) is also pure logic, but the arms call side-effecting private functions:
- `blocked(repo, snapshot, blockers, now)` — fires `Telemetry.execute_limiter_event`, `record_history_fact` — **NOT pure**
- The reservation success arm calls `repo.update/1` — **NOT pure**

### Exact Extraction Boundary

The extracted pure function must receive everything it needs as arguments (no repo, no side-effecting calls) and return a verdict:

```elixir
# Proposed pure function — to live in ObanPowertools.Limits (or Limits.Bucket submodule)
# Called by: reserve/3 (to drive the cond) AND simulate (to compute verdict without DB)
@spec compute_reservation(State.t(), Resource.t(), weight :: pos_integer(), now :: DateTime.t()) ::
  {:reserved, tokens_used_after :: non_neg_integer()} |
  {:blocked, code :: String.t(), retry_at :: DateTime.t() | nil, reason :: map()}
def compute_reservation(%State{} = state, %Resource{} = resource, weight, now) do
  normalized = normalize_bucket(state, resource.bucket_span_ms, now)

  cond do
    cooldown_active?(normalized, now) ->
      {:blocked, "cooldown", normalized.cooldown_until, %{reason: normalized.cooldown_reason}}

    normalized.tokens_used + weight > resource.bucket_capacity ->
      retry_at =
        normalized.bucket_started_at
        |> DateTime.add(resource.bucket_span_ms, :millisecond)
        |> max_datetime(now)
      {:blocked, "limit_reached", retry_at,
       %{capacity: resource.bucket_capacity, used: normalized.tokens_used}}

    true ->
      {:reserved, normalized.tokens_used + weight}
  end
end
```

`normalize_bucket/3` and `cooldown_active?/2` stay as private helpers called by `compute_reservation/4`.

### How `reserve/3` Is Refactored

`attempt_reservation/5` calls `compute_reservation/4` and then drives the side-effecting actions:

```elixir
defp attempt_reservation(repo, resource, state, snapshot, now) do
  case compute_reservation(state, resource, snapshot.weight, now) do
    {:reserved, new_tokens_used} ->
      # ... repo.update + return {:ok, reservation}

    {:blocked, code, retry_at, details} ->
      blocker = build_blocker(code, resource, state, retry_at, details)
      blocked(repo, snapshot, [blocker], now)  # side effects stay here
  end
end
```

### Side Effects That Must NOT Run in Simulate

In `blocked/4` (lines 296-320): [VERIFIED: `lib/oban_powertools/limits.ex`]

1. `Telemetry.execute_limiter_event(:blocked, ...)` — fires `:blocked` telemetry event
2. `record_history_fact(repo, ...)` — writes to `oban_powertools_limiter_history_facts`
3. `Audit.record(...)` — implicit via the blocked write path (actually in `reserve/3` via `blocked/4`)

In `upsert_resource/2` (lines 144-190): writes/updates the `oban_powertools_limit_resources` table — **simulate must not call `upsert_resource`**.

In `get_or_create_state/4` (lines 192-208): creates `oban_powertools_limit_states` rows — **simulate must not call this**.

Simulate builds its own in-memory `%State{}` (tokens_used: 0, bucket_started_at: now, cooldown_until: nil) and calls only `compute_reservation/4` in a loop. No repo interaction needed for the computation itself; repo is only needed if `--worker` is used to read an existing resource's state to start from (but D-07 says "fresh empty bucket", so no DB needed for the simulation loop at all).

### Simulate — DB Interaction Scope

Per D-07: simulate runs against a "fresh (empty) bucket" — so no State row is read from the DB. Simulate may need DB access only to resolve the worker's compiled `@powertools_limits` via the module itself (which is a compile-time attribute — no DB needed). The `--resource NAME` flag for simulate can optionally read the live Resource row to get current capacity/span as defaults, but the simulation state is always synthetic (tokens_used: 0).

**Decision:** Simulate needs `Ecto.Migrator.with_repo` only if it supports `--resource` as a config-source flag. For `--worker`-only simulate (D-05), no DB access is required after `app.config` loads. The task can skip `with_repo` for simulate if only `--worker` is supported. Given D-05 locks `--worker MOD` as the input path, DB access is optional (used only if `--resource` is also supported for config lookup — out of scope per CONTEXT.md). Recommend: still wrap in `with_repo` for consistency with the CLI family, but the simulation loop itself is pure.

---

## Explain Seam — Verified Signatures

[VERIFIED: `lib/oban_powertools/explain.ex`]

### `Explain.explain/3`

```elixir
# Source: lib/oban_powertools/explain.ex lines 59-73
def explain(worker_mod, args, opts \\ []) do
  repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
  now = Keyword.get(opts, :now, DateTime.utc_now())

  with {:ok, snapshot} <- ObanPowertools.Worker.limit_snapshot(worker_mod, args) do
    live_now = live_blockers(repo, snapshot, now)

    %{
      status: if(live_now == [], do: :runnable, else: :blocked),
      blockers: live_now,
      live_now: live_now,
      snapshot_at_block_start: latest_snapshot(repo, inspect(worker_mod), snapshot)
    }
  end
end
```

- Returns `{:ok, nil}` if worker has no limits declared (passthrough from `limit_snapshot/2`).
- Returns `%{status: :runnable | :blocked, blockers: [...], live_now: [...], snapshot_at_block_start: Explain.t() | nil}`.
- `explain/3` returns the map directly (not tagged `{:ok, map}`); the `with` unwraps the snapshot tuple.

### `Explain.explain_snapshot/2`

```elixir
# Source: lib/oban_powertools/explain.ex lines 96-106
def explain_snapshot(%__MODULE__{} = snapshot, opts \\ []) do
  repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
  now = Keyword.get(opts, :now, DateTime.utc_now())

  %{
    status: snapshot.status,
    blockers: live_blockers_from_snapshot(repo, snapshot, now),
    live_now: live_blockers_from_snapshot(repo, snapshot, now),
    snapshot_at_block_start: snapshot
  }
end
```

- Accepts an `%ObanPowertools.Explain{}` struct (a persisted blocker snapshot row).
- Note: `live_blockers_from_snapshot/3` is called twice (minor inefficiency — not a correctness issue).
- The `status` field comes from the snapshot record's `:status` string field (e.g. `"blocked"`); the CLI will render this as-is.

### Blocker Codes (VERIFIED)

From `blockers_for/4` (lines 244-273):
- `"cooldown"` — `state.cooldown_until` is in the future; `retry_at = state.cooldown_until`
- `"limit_reached"` — `state.tokens_used + weight > resource.bucket_capacity`; `retry_at = bucket_started_at + bucket_span_ms`

The `blocker_summary/1` function handles workflow-step blocker codes (`waiting_on_dependencies`, `waiting_on_signal`, etc.) but NOT limiter codes — limiter codes are handled inline in `blockers_for/4`. There is no `blocker_summary/1` clause for `"cooldown"` or `"limit_reached"`.

### UI Confirmation of Resource-Primary Path (D-03)

[VERIFIED: `lib/oban_powertools/web/limiters_live.ex` lines 266-288]

The Limiters UI drives explain exactly as D-03 specifies:
1. `repo.one(from event in Explain, where: event.scope_id == ^name, ...)` — fetches latest snapshot by resource name
2. `Explain.explain_snapshot(snapshot, repo: repo)` — resolves live blockers from current Resource/State
3. Renders `live_now` and `snapshot_at_block_start`

The CLI explain primary path must mirror this exactly: fetch latest snapshot by `scope_id == resource_name`, then call `explain_snapshot/2`.

### D-04: Honest Empty State Implementation

When no snapshot exists for a resource (UI handles this at line 277-279):
```elixir
# Source: lib/oban_powertools/web/limiters_live.ex lines 276-279
case snapshot do
  nil -> %{snapshot: nil, live_now: [], oban_job_path: nil}
  snapshot -> Explain.explain_snapshot(snapshot, repo: repo)
end
```

The CLI must similarly handle `nil` snapshot by reporting `runnable` / "no limiter state recorded yet". When `repo.get_by(Resource, name: name)` returns `nil` (no resource row at all), report the same honest empty-state message.

---

## Worker Config for Simulate (D-05)

[VERIFIED: `lib/oban_powertools/worker.ex` lines 89-125]

### `Worker.limit_snapshot/2` — How It Works

```elixir
def limit_snapshot(worker_mod, args) do
  limits =
    if function_exported?(worker_mod, :__powertools_limits__, 0) do
      worker_mod.__powertools_limits__()
    else
      []
    end
  # ...
  if limits == [] do
    {:ok, nil}   # worker has no limits — simulate should exit 2 with clear message
  else
    {:ok, %{
      worker: inspect(worker_mod),
      resource_name: limits[:name],
      scope_kind: Atom.to_string(limits[:scope]),
      bucket_capacity: limits[:bucket_capacity],
      bucket_span_ms: limits[:bucket_span_ms],
      default_weight: limits[:default_weight],
      partition_strategy: limits[:partition_strategy],
      partition_config: limits[:partition_config],
      partition_key: partition_key,  # resolved from partition_by + args
      weight: weight,                # resolved from weight_by + args
      binding: %{...}
    }}
  end
end
```

### Simulate Flag Override Strategy

Simulate reads the worker's limits snapshot, then applies CLI overrides:

```elixir
# After Worker.limit_snapshot(worker_mod, %{})
# (empty args because simulate doesn't have real job args;
#  weight/partition_key fall back to default_weight and __global__)

# Apply flag overrides
capacity = Keyword.get(opts, :bucket_capacity, snapshot.bucket_capacity)
span_ms  = Keyword.get(opts, :bucket_span_ms, snapshot.bucket_span_ms)
weight   = Keyword.get(opts, :weight, snapshot.weight)
count    = Keyword.get(opts, :count, 1)
partition = Keyword.get(opts, :partition, snapshot.partition_key)
```

**Landmine:** `Worker.limit_snapshot/2` calls `resolve_partition(limits[:partition_by], args_map, worker_mod)` which may raise `ArgumentError` if `partition_by` is `{:args, :some_key}` and args is `%{}` (missing the key). The resolve functions for `{:args, key}` do `Map.get(args, key)` which returns `nil`, then `normalize_partition_key(nil)` raises. Simulate must either pass `%{}` args (accepted if partition_by is nil/global) or detect `scope: :partitioned` workers and require `--partition` flag, or rescue the ArgumentError and default to `__global__`.

**Recommendation:** For partitioned workers where the CLI operator provides `--partition KEY`, skip `limit_snapshot/2`'s partition resolution and use the flag value directly. Build the synthetic snapshot manually rather than through `limit_snapshot/2` when overrides are in play.

---

## Resource/State Schema — Fields for Explain/Simulate

[VERIFIED: `lib/oban_powertools/limits/resource.ex` and `state.ex`]

### Resource Fields Needed

| Field | Type | Default | Usage |
|-------|------|---------|-------|
| `name` | string | required | Lookup key for `--resource NAME` |
| `scope_kind` | string | required | Display in explain output |
| `bucket_capacity` | integer | required | Simulation capacity |
| `bucket_span_ms` | integer | required | Simulation span; also `retry_at` calc |
| `default_weight` | integer | 1 | Simulation default weight |
| `partition_strategy` | string | "global" | Display in explain output |
| `cooldown_enabled` | boolean | true | Not needed in CLI output directly |
| `algorithm` | string | — | Display if needed ("token_bucket") |

### State Fields Needed

| Field | Type | Default | Usage |
|-------|------|---------|-------|
| `partition_key` | string | `"__global__"` | Lookup key |
| `tokens_used` | integer | 0 | Current saturation level |
| `bucket_started_at` | utc_datetime_usec | — | `normalize_bucket/3`; `retry_at` calc |
| `cooldown_until` | utc_datetime_usec | nil | Cooldown detection |
| `cooldown_reason` | string | nil | Cooldown display |
| `last_reserved_at` | utc_datetime_usec | nil | Informational in human output |

### Key Relationship

State is looked up by `resource_id` (from `Resource` by name) and `partition_key`. There can be multiple State rows per Resource (one per partition key). The explain primary path (`--resource NAME [--partition KEY]`) does:
1. `repo.get_by(Resource, name: name)` → gets resource_id
2. `repo.get_by(State, resource_id: resource.id, partition_key: partition_key)`

---

## Packaging — `:files` Whitelist Verified

[VERIFIED: `mix.exs` line 36]

```elixir
files: ~w[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]
```

`lib` is included as a directory glob — new task files at `lib/mix/tasks/oban_powertools.limiter.explain.ex` and `lib/mix/tasks/oban_powertools.limiter.simulate.ex` are automatically included. No `mix.exs` packaging change is needed. [VERIFIED: REL-01 satisfied]

The `hex_release_test.exs` line 99 asserts `"lib" in files` — confirmed passing.

---

## Glossary Single Source of Truth (D-08)

[VERIFIED: `guides/limits-and-explain.md` contents; `mix.exs` docs/0]

The guide is at `guides/limits-and-explain.md` and appears in ExDoc extras under "Builders" group (mix.exs line 76). The guide currently covers: token-bucket declaration, enqueue behavior, `explain/3`, administrative actions, and "when this is the right tool." It does NOT currently contain a glossary section.

### Glossary Terms Required by D-08

All terms extracted from live codebase:

| Term | Source | Definition to Ship |
|------|--------|-------------------|
| `token_bucket` | `@algorithm = "token_bucket"` in limits.ex | The rate-limiting algorithm: each partition has a bucket of capacity tokens; each reservation consumes weight tokens; bucket refills at bucket_started_at + bucket_span_ms |
| `bucket_capacity` | `Resource.bucket_capacity` field | Maximum tokens available per bucket window |
| `bucket_span_ms` | `Resource.bucket_span_ms` field | Duration of one bucket window in milliseconds; bucket resets after this interval |
| `weight` / `weight_by` | `snapshot.weight`, `limits[:weight_by]` | Per-reservation token cost; `weight_by: {:args, :field}` resolves dynamically |
| `partition` / `partition_by` / `scope` | `limits[:scope]` (:global/:partitioned), `limits[:partition_by]` | `:global` = one shared bucket; `:partitioned` = one bucket per resolved key |
| `cooldown` | `State.cooldown_until`, blocker code `"cooldown"` | Operator-set hold until a DateTime; blocks all reservations regardless of capacity |
| `limit_reached` | blocker code in `blockers_for/4` | Bucket saturation: `tokens_used + weight > bucket_capacity` |
| `cooldown` (blocker code) | blocker code in `blockers_for/4` | Resource is in active cooldown; `retry_at = state.cooldown_until` |

### Single-Source Mechanism

D-08 requires one string that feeds both `@moduledoc` (in both task files) and the guide. Implementation options (Claude's discretion):

**Option A (recommended):** Define a module `ObanPowertools.Limits.Glossary` or add a module attribute `@glossary_text` in one task file and reference it from the other. Both tasks `import` or reference the same constant. The guide is updated to include the glossary text as a verbatim section. Since guides are static `.md` files, the guide is updated once manually; the `@moduledoc` references the shared constant.

**Option B:** Keep the glossary only in the guide `.md` and have the `@moduledoc` include it via `@external_resource` and `File.read!`. This is more complex and fragile.

**Recommendation (for planner):** Option A — define `@glossary_text` as a module-level string constant in a shared helper module or in one of the tasks (e.g., `Explain` task exports it; `Simulate` task imports it). The guide is updated to include the same text. Drift prevention: `docs_contract_test.exs` or a new contract test asserts the guide contains the glossary term list.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON output | Custom encoder | `Jason.encode!` (already dep) | Handles encoding, escaping, Unicode |
| ANSI color degradation | Custom TTY check | `IO.ANSI.enabled?()` + `IO.ANSI.format/1` | Handles NO_COLOR, TERM=dumb, CI pipe detection |
| Module name from string | `String.to_atom(user_input)` | `Module.safe_concat([string])` | Prevents atom table exhaustion; T-48-05 |
| Token-bucket verdict | Duplicate cond in simulate task | `compute_reservation/4` extracted pure function | Single source of truth; no drift |
| Worker limits config | Re-parse `@powertools_limits` | `Worker.limit_snapshot/2` | Already handles resolver dispatch and normalization |
| Partition key defaults | Hardcode `"__global__"` | `Limits.partition_defaults().partition_key` | Single source of truth |

**Key insight:** The token-bucket math exists exactly once in `attempt_reservation/5`. Extracting it to a pure function is the correct approach — not duplicating the cond in simulate's task file.

---

## Common Pitfalls

### Pitfall 1: System.halt Inside with_repo Callback
**What goes wrong:** Calling `System.halt(exit_code)` inside the `fn repo -> ... end` callback raises an exception and prevents the repo from being cleanly closed.
**Why it happens:** Forgetting that `with_repo` wraps the callback in a try/catch.
**How to avoid:** Return the exit code from the callback; call `System.halt` in the `case result do` block outside.
**Warning signs:** Doctor task pattern shows this explicitly — `System.halt` only in `{:ok, exit_code, _apps}` and `{:error, reason}` arms.

### Pitfall 2: `String.to_atom` on CLI Worker/Repo Flags (T-48-05)
**What goes wrong:** Arbitrary atoms created from user input; atom table exhaustion in production.
**Why it happens:** `String.to_atom("MyApp.Worker")` creates a new atom even if module doesn't exist.
**How to avoid:** `Module.safe_concat([user_string])` for module name resolution. `String.to_existing_atom` acceptable only for known pre-existing atoms (e.g., Oban name).
**Warning signs:** Doctor test asserts `refute source =~ ~r/String\.to_atom\(/`.

### Pitfall 3: Simulate Calling `upsert_resource` or `blocked/4`
**What goes wrong:** Simulate creates DB rows and fires telemetry events, defeating the "no mutation" requirement (OPS-07).
**Why it happens:** Calling `do_reserve/3` instead of the extracted pure function.
**How to avoid:** Simulate calls only `compute_reservation/4`. Never calls `do_reserve`, `attempt_reservation`, or `blocked`.
**Warning signs:** A test that attaches a telemetry handler for `:blocked` events should assert ZERO events fire during simulate.

### Pitfall 4: `limit_snapshot/2` Raises for Partitioned Workers with Empty Args
**What goes wrong:** `Worker.limit_snapshot(mod, %{})` raises `ArgumentError` if `partition_by: {:args, :key}` and args is `%{}` (key missing → `normalize_partition_key(nil)` raises).
**Why it happens:** Simulate passes `%{}` as args because it has no real job args.
**How to avoid:** Detect partitioned workers (scope == :partitioned) and either require `--partition` flag or rescue the error and use `__global__` default. Alternatively, build the snapshot struct manually from the module's `@powertools_limits` attribute without calling `limit_snapshot/2`.
**Warning signs:** `ArgumentError: expected partition resolver to return a value` at simulate startup.

### Pitfall 5: explain_snapshot Returns Status as String, Not Atom
**What goes wrong:** `explain_snapshot/2` returns `status: snapshot.status` where `snapshot.status` is a string (e.g., `"blocked"`) from the DB field. Formatters expecting `:blocked` atom will fail pattern matches.
**Why it happens:** The Ecto schema field is `field(:status, :string, default: "blocked")` — not an atom type.
**How to avoid:** The formatter must handle both string and atom status, or normalize to atom at the task boundary: `String.to_atom(status)` is safe here since values are a closed set from the codebase.
**Warning signs:** Pattern match `status == :runnable` fails when status is `"runnable"`.

### Pitfall 6: `@requirements ["app.config"]` Instead of Inline `Mix.Task.run`
**What goes wrong:** Using `@requirements ["app.config"]` calls the task before `run/1` and can cause boot-ordering issues with Igniter.
**Why it happens:** It's the "obvious" way to declare task dependencies.
**How to avoid:** Call `Mix.Task.run("app.config")` inline at the start of `run/1`, exactly as Doctor does (line 73).
**Warning signs:** Doctor test asserts `refute source =~ "@requirements"`.

### Pitfall 7: Glossary Drift Between @moduledoc and Guide
**What goes wrong:** Glossary text in `@moduledoc` diverges from `guides/limits-and-explain.md` over time.
**Why it happens:** Two copies of the same text in different files.
**How to avoid:** Single shared constant (module attribute or small module) imported by both task files; guide updated once from the same source.
**Warning signs:** No automated test catches the drift — must add a `docs_contract_test` assertion.

---

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation` absent from config.json = enabled).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `test/test_helper.exs` (no separate ExUnit config file) |
| DB case | `use ObanPowertools.DataCase, async: false` for DB tests |
| Non-DB case | `use ExUnit.Case, async: true` for source-inspection tests |
| Quick run command | `mix test test/mix/tasks/oban_powertools.limiter.explain_test.exs test/mix/tasks/oban_powertools.limiter.simulate_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Test File | Automated Command |
|--------|----------|-----------|-----------|-------------------|
| OPS-06 | `Limiter.Explain` Mix.Task module exists with `run/1` | unit/source | `oban_powertools.limiter.explain_test.exs` | `mix test test/mix/tasks/oban_powertools.limiter.explain_test.exs` |
| OPS-06 | Task uses `Mix.Task` not `Igniter.Mix.Task`, no `@requirements` | source-inspection | same | same |
| OPS-06 | Task declares `--resource`, `--worker`, `--partition`, `--args`, `--repo`, `--format` switches | source-inspection | same | same |
| OPS-06 | Task uses `Ecto.Migrator.with_repo` | source-inspection | same | same |
| OPS-06 | Task uses `System.halt` outside callback | source-inspection | same | same |
| OPS-06 | Task uses `Module.safe_concat` not `String.to_atom` | source-inspection | same | same |
| OPS-06 | `explain_snapshot/2` is called for resource-primary path | unit (DB required) | same | same |
| OPS-06 | Empty/no-state resource reports `runnable` + "no limiter state recorded yet" | unit (DB required) | same | same |
| OPS-07 | `Limiter.Simulate` Mix.Task module exists with `run/1` | unit/source | `oban_powertools.limiter.simulate_test.exs` | `mix test test/mix/tasks/oban_powertools.limiter.simulate_test.exs` |
| OPS-07 | Simulate reports per-request verdicts: `reserved` N-1 times then `blocked` on Nth when count > capacity | unit (pure, no DB) | same | same |
| OPS-07 | Simulate emits ZERO telemetry `:blocked` events (side-effect-freedom proof) | telemetry-handler test | same | same |
| OPS-07 | Simulate does NOT write to `oban_powertools_limit_states` or `oban_powertools_limit_resources` (DB assertion) | DB unit test | same | same |
| OPS-07 | Pure `compute_reservation/4` returns `{:reserved, n}` or `{:blocked, code, retry_at, details}` | unit (pure) | `limits_test.exs` or new test | `mix test test/oban_powertools/limits_test.exs` |
| OPS-07 | `Limits.reserve/3` behavior is unchanged after pure-core extraction (regression) | DB unit test | `limits_test.exs` (existing tests pass) | `mix test test/oban_powertools/limits_test.exs` |
| OPS-08 | Both task `@moduledoc` sections contain the glossary | source-inspection | `docs_contract_test.exs` or new | `mix test test/oban_powertools/docs_contract_test.exs` |
| OPS-08 | `guides/limits-and-explain.md` contains the glossary terms | source-inspection | same | same |
| OPS-08 | Glossary covers all 7 required terms (token_bucket, bucket_capacity, bucket_span_ms, weight/weight_by, partition/partition_by/scope, cooldown, limit_reached/cooldown blocker codes) | source-inspection | same | same |

### Side-Effect-Freedom Test (Critical for OPS-07)

```elixir
# Pattern for proving simulate emits no telemetry events:
test "simulate emits no limiter.blocked telemetry events" do
  # Attach handler that fails the test if event fires
  :telemetry.attach(
    "simulate-side-effect-guard",
    [:oban_powertools, :limiter, :blocked],
    fn _event, _measurements, _metadata, _ ->
      flunk("simulate must not emit limiter.blocked telemetry")
    end,
    nil
  )
  on_exit(fn -> :telemetry.detach("simulate-side-effect-guard") end)

  # Run simulate (call compute_reservation directly or via task)
  # ... assert no events fired
end

# Pattern for proving no DB rows written:
test "simulate does not write limiter state rows" do
  count_before = repo().aggregate(ObanPowertools.Limits.State, :count)
  # ... run simulate
  count_after = repo().aggregate(ObanPowertools.Limits.State, :count)
  assert count_before == count_after
end
```

### Sampling Rate
- **Per task commit:** `mix test test/mix/tasks/oban_powertools.limiter.explain_test.exs test/mix/tasks/oban_powertools.limiter.simulate_test.exs test/oban_powertools/limits_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/mix/tasks/oban_powertools.limiter.explain_test.exs` — covers OPS-06 (source-inspection + DB integration tests)
- [ ] `test/mix/tasks/oban_powertools.limiter.simulate_test.exs` — covers OPS-07 (pure computation + side-effect-freedom + no-DB-writes assertions)
- [ ] New assertions in `test/oban_powertools/docs_contract_test.exs` — covers OPS-08 glossary single-source-of-truth

Existing `test/oban_powertools/limits_test.exs` tests serve as the regression suite for the D-06 pure-core extraction — all existing tests must continue to pass unchanged.

---

## State of the Art

| Area | Current State | Notes |
|------|--------------|-------|
| Mix task CLI pattern | Stable — Doctor task is the established pattern | No changes needed to the approach |
| Token-bucket pure extraction | Not yet done — `normalize_bucket` and cond are private in `Limits` | The extraction is net-new; no prior art in the codebase |
| Glossary | Not present in guide or docs | Entirely new content |

**No deprecated patterns to avoid** — the codebase is consistent and current.

---

## Environment Availability

The phase is purely code/library changes. No external CLI tools, services, or runtimes beyond the existing Elixir/OTP stack and PostgreSQL test DB are required.

| Dependency | Required By | Available | Notes |
|------------|------------|-----------|-------|
| Elixir + Mix | All | ✓ | Already in use |
| PostgreSQL (test DB) | DB-integration tests | ✓ | Already used by existing test suite |
| Jason | JSON output | ✓ | Already a dep (mix.exs line 51) |
| ExUnit | Tests | ✓ | Built-in |
| Telemetry | Side-effect-freedom test | ✓ | Already a dep (mix.exs line 49) |

No missing dependencies.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `explain_snapshot/2` is called with the `%ObanPowertools.Explain{}` struct fetched from DB (scope_id = resource name), not with a synthetically constructed struct | Explain Seam | If UI passes a different struct shape, the CLI's DB query must differ |
| A2 | Simulate is not required to read live State rows as a starting point — D-07 says "fresh (empty) bucket" | D-06 section | If operator expects simulate to start from current live state, the DB interaction scope changes |
| A3 | The `--count N` flag for simulate means N sequential reservations all of weight W against one bucket (not N parallel or N time-spread) | Architecture diagram | If sequential-vs-parallel matters, planner must specify |

---

## Open Questions

1. **Simulate DB interaction for config lookup**
   - What we know: D-05 says `--worker MOD` reads limits via `Worker.limit_snapshot/2`; D-07 says "fresh (empty) bucket"
   - What's unclear: Should `--resource NAME` be a supported simulate input to read the resource's current config (capacity/span) from the DB as defaults? CONTEXT.md only mentions `--worker MOD`.
   - Recommendation: Implement `--worker`-only for simulate (no `--resource` flag for simulate); keep repo connection optional for simulate.

2. **Glossary shared string mechanism**
   - What we know: D-08 says "single shared string"; two consumers are `@moduledoc` and the guide
   - What's unclear: Whether a small module (`ObanPowertools.Limits.Glossary`) is warranted vs. a module attribute in one task file
   - Recommendation: Module attribute in the Explain task file; Simulate imports/references it. Or planner decides (Claude's Discretion).

3. **Explain output for `explain/3` (secondary path) when worker has no limits**
   - What we know: `explain/3` returns `{:ok, nil}` via passthrough when `limit_snapshot` returns `{:ok, nil}`
   - What's unclear: Should the CLI render "worker has no limits configured" or treat it as runnable?
   - Recommendation: Exit 2 with clear "worker has no limits configured" message (consistent with D-04 "honest").

---

## Sources

### Primary (HIGH confidence — verified by direct source code read)
- `lib/mix/tasks/oban_powertools.doctor.ex` — complete CLI template; all patterns extracted verbatim
- `lib/oban_powertools/explain.ex` — verified `explain/3`, `explain_snapshot/2` signatures, return shapes, `blockers_for/4`
- `lib/oban_powertools/limits.ex` — verified `normalize_bucket/3`, `attempt_reservation/5` boundary, `blocked/4` side effects
- `lib/oban_powertools/limits/resource.ex` — verified all schema fields
- `lib/oban_powertools/limits/state.ex` — verified all schema fields
- `lib/oban_powertools/worker.ex` — verified `limit_snapshot/2` signature and partition resolution behavior
- `lib/oban_powertools/web/limiters_live.ex` — confirmed resource-primary UI path (`load_detail/2`) matches D-03
- `lib/oban_powertools/doctor/formatter.ex` — verified ANSI, JSON, `schema_version: 1` patterns
- `mix.exs` — verified `:files` whitelist includes `lib`; confirmed Jason, telemetry as existing deps
- `guides/limits-and-explain.md` — confirmed current content; glossary section absent
- `.planning/config.json` — confirmed `nyquist_validation` key absent (treated as enabled)
- `test/mix/tasks/oban_powertools.doctor_test.exs` — established test conventions for source-inspection tests
- `test/oban_powertools/limits_test.exs` — verified regression test coverage of existing `reserve/3`
- `test/oban_powertools/explain_test.exs` — verified existing explain test patterns

---

## Metadata

**Confidence breakdown:**
- Standard stack (reused modules): HIGH — all verified from source
- Architecture patterns: HIGH — direct code read + UI cross-verification
- D-06 pure extraction boundary: HIGH — exact lines identified with source citations
- Pitfalls: HIGH — derived from direct code analysis
- Glossary terms: HIGH — enumerated from live schema fields and blocker codes

**Research date:** 2026-05-29
**Valid until:** 2026-06-28 (30 days; stable library code)
