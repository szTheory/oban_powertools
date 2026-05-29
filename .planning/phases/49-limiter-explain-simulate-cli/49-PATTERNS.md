# Phase 49: Limiter Explain/Simulate CLI - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 4 (2 new Mix tasks, 1 modified backend module, 1 modified guide)
**Analogs found:** 4 / 4

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/oban_powertools.limiter.explain.ex` | Mix task (controller) | request-response (read DB) | `lib/mix/tasks/oban_powertools.doctor.ex` | exact |
| `lib/mix/tasks/oban_powertools.limiter.simulate.ex` | Mix task (controller) | transform / pure compute | `lib/mix/tasks/oban_powertools.doctor.ex` | role-match (same shell, different payload) |
| `lib/oban_powertools/limits.ex` | service / pure-function extraction | CRUD + transform | itself (existing file, targeted refactor) | self |
| `guides/limits-and-explain.md` | documentation | n/a | `test/oban_powertools/docs_contract_test.exs` | content-contract |

---

## Pattern Assignments

### `lib/mix/tasks/oban_powertools.limiter.explain.ex` (Mix task, request-response)

**Analog:** `lib/mix/tasks/oban_powertools.doctor.ex`

**Module skeleton** (lines 1-66):
```elixir
defmodule Mix.Tasks.ObanPowertools.Limiter.Explain do
  use Mix.Task

  @shortdoc "Explain a limiter's current blocking state (read-only)"

  @moduledoc """
  ...@glossary_text goes here...

  ## Exit Codes

  | Code | Meaning |
  |------|---------|
  | 0    | Ran successfully — result is in stdout |
  | 2    | Cannot run: no repo, DB unreachable, or unknown --worker module |

  ## Flags

      --resource NAME       Limiter resource name (primary path). Resolves live
                            state from the DB and renders via explain_snapshot/2.
      --partition KEY       Partition key (default: "__global__"). Use with --resource.
      --worker MOD          Worker module (secondary path). Maps to Explain.explain/3.
      --args JSON           JSON args string for --worker (default: "{}").
      --repo MyApp.Repo     Ecto repo module. Falls back to
                            `config :oban_powertools, repo: MyApp.Repo`.
      --prefix public       Oban schema prefix. Falls back to host Oban app env,
                            then "public". Use --prefix for reliable production results.
      --oban-name Oban      Which Oban instance to read prefix from (default: "Oban").
      --format human|json   Output format. "human" degrades ANSI in CI/non-TTY.
                            "json" emits schema_version: 1 stability contract.
  """

  @switches [
    repo: :string,
    prefix: :string,
    oban_name: :string,
    format: :string,
    resource: :string,
    partition: :string,
    worker: :string,
    args: :string
  ]
```

**Boot + run pattern** (lines 67-126 of doctor.ex, verbatim structure):
```elixir
  @impl Mix.Task
  def run(argv) do
    # MUST be inline — not @requirements, not "app.start" (Pitfall 6)
    Mix.Task.run("app.config")

    {opts, _args, _invalid} = OptionParser.parse(argv, strict: @switches)

    repo_module = resolve_repo(opts)

    result =
      Ecto.Migrator.with_repo(
        repo_module,
        fn repo ->
          format =
            case Keyword.get(opts, :format, "human") do
              "json" -> :json
              _ -> :human
            end

          # ... explain work here; return integer exit code, NOT System.halt
          exit_code
        end,
        pool_size: 2
      )

    # System.halt OUTSIDE the callback — never inside fn -> ... end
    case result do
      {:ok, exit_code, _apps} -> System.halt(exit_code)
      {:error, reason} ->
        Mix.shell().error("Oban Powertools Limiter.Explain: cannot start repo — #{inspect(reason)}\n" <>
          "Configure your repo with: config :oban_powertools, repo: MyApp.Repo\n" <>
          "Or pass the flag: mix oban_powertools.limiter.explain --repo MyApp.Repo")
        System.halt(2)
    end
  end
```

**Resource-primary explain path** (mirrors `limiters_live.ex` lines 266-289):
```elixir
  # Primary path: --resource NAME [--partition KEY]
  defp run_explain(repo, opts, format) do
    resource_name = Keyword.get(opts, :resource)
    partition_key = Keyword.get(opts, :partition, "__global__")

    snapshot =
      repo.one(
        from(event in ObanPowertools.Explain,
          where: event.scope_id == ^resource_name,
          order_by: [desc: event.captured_at],
          limit: 1
        )
      )

    case snapshot do
      nil ->
        # Honest empty state (D-04): no snapshot → report runnable
        print_empty_state(resource_name, partition_key, format)
        0

      snapshot ->
        explanation = ObanPowertools.Explain.explain_snapshot(snapshot, repo: repo)
        print_explanation(explanation, format)
        0
    end
  end
```

**Worker-secondary path** (calls `Explain.explain/3`):
```elixir
  # Secondary path: --worker MOD --args JSON
  defp run_explain_worker(repo, opts, format) do
    with {:ok, worker_mod} <- resolve_worker(opts),
         {:ok, parsed_args} <- parse_args_json(opts) do
      case ObanPowertools.Explain.explain(worker_mod, parsed_args, repo: repo) do
        nil ->
          Mix.shell().error("worker has no limits configured")
          2

        explanation ->
          print_explanation(explanation, format)
          0
      end
    else
      {:error, :no_worker} ->
        Mix.shell().error("--worker is required for the secondary path")
        2

      {:error, :unknown_module, mod_string} ->
        Mix.shell().error("unknown --worker module: #{mod_string}")
        2

      {:error, :invalid_json} ->
        Mix.shell().error("--args must be a valid JSON object string")
        2
    end
  end
```

**Module resolution** (lines 132-144 of doctor.ex, verbatim):
```elixir
  defp resolve_repo(opts) do
    case Keyword.get(opts, :repo) do
      nil -> ObanPowertools.RuntimeConfig.repo!()
      repo_string -> Module.safe_concat([repo_string])
    end
  end

  # Worker resolution mirrors repo pattern — Module.safe_concat, never String.to_atom
  defp resolve_worker(opts) do
    case Keyword.get(opts, :worker) do
      nil -> {:error, :no_worker}
      worker_string -> {:ok, Module.safe_concat([worker_string])}
    end
  end
```

**Prefix resolution** (lines 151-178 of doctor.ex, verbatim — copy without modification):
```elixir
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

**Status field normalization** (Pitfall 5 — `explain_snapshot/2` returns `status` as a DB string):
```elixir
  # snapshot.status is a string from the DB (e.g., "blocked"), not an atom.
  # Normalize at the task boundary with a CLOSED case — never String.to_atom
  # (T-48-05 / D-01: never create atoms from values that originate outside
  # the codebase). The status set is known and finite.
  defp normalize_status(status) when is_binary(status) do
    case status do
      "runnable" -> :runnable
      "blocked" -> :blocked
      _ -> :unknown
    end
  end

  defp normalize_status(status) when is_atom(status), do: status
```

---

### `lib/mix/tasks/oban_powertools.limiter.simulate.ex` (Mix task, pure transform)

**Analog:** `lib/mix/tasks/oban_powertools.doctor.ex`

**Module skeleton and switches**:
```elixir
defmodule Mix.Tasks.ObanPowertools.Limiter.Simulate do
  use Mix.Task

  @shortdoc "Preview limiter behavior for a config without mutating state"

  @moduledoc """
  ...same @glossary_text reference as Explain task...

  ## Exit Codes

  | Code | Meaning |
  |------|---------|
  | 0    | Simulation complete — per-request verdicts in stdout |
  | 2    | Bad input: unknown --worker module or worker has no limits |

  ## Flags

      --worker MOD             Worker module to read declared :limits from.
      --bucket-capacity N      Override declared bucket_capacity.
      --bucket-span-ms N       Override declared bucket_span_ms (milliseconds).
      --weight N               Override declared default_weight per reservation.
      --count N                Number of sequential reservations to simulate (default: 1).
      --partition KEY          Override resolved partition_key (default: "__global__").
      --repo MyApp.Repo        Ecto repo (only needed for app.config; simulate is pure).
      --prefix public          Oban schema prefix (default: "public").
      --oban-name Oban         Oban instance name for prefix lookup (default: "Oban").
      --format human|json      Output format. JSON carries schema_version: 1.
  """

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

**Boot strategy** (identical to Doctor/Explain; `with_repo` wraps even the pure simulate for family consistency):
```elixir
  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.config")

    {opts, _args, _invalid} = OptionParser.parse(argv, strict: @switches)

    repo_module = resolve_repo(opts)

    result =
      Ecto.Migrator.with_repo(
        repo_module,
        fn _repo ->
          format =
            case Keyword.get(opts, :format, "human") do
              "json" -> :json
              _ -> :human
            end

          exit_code = run_simulate(opts, format)
          exit_code
        end,
        pool_size: 2
      )

    case result do
      {:ok, exit_code, _apps} -> System.halt(exit_code)
      {:error, reason} ->
        Mix.shell().error("Oban Powertools Limiter.Simulate: cannot start repo — #{inspect(reason)}")
        System.halt(2)
    end
  end
```

**Simulate core — calls only `compute_reservation/4`, never `reserve/3`**:
```elixir
  defp run_simulate(opts, format) do
    with {:ok, worker_mod} <- resolve_worker(opts),
         {:ok, base_snapshot} <- resolve_worker_config(worker_mod, opts) do
      capacity  = Keyword.get(opts, :bucket_capacity, base_snapshot.bucket_capacity)
      span_ms   = Keyword.get(opts, :bucket_span_ms, base_snapshot.bucket_span_ms)
      weight    = Keyword.get(opts, :weight, base_snapshot.weight)
      count     = Keyword.get(opts, :count, 1)
      partition = Keyword.get(opts, :partition, base_snapshot.partition_key)

      # Synthetic Resource and State structs — never touch the DB for simulation
      resource = %ObanPowertools.Limits.Resource{
        name: base_snapshot.resource_name,
        bucket_capacity: capacity,
        bucket_span_ms: span_ms,
        scope_kind: base_snapshot.scope_kind
      }

      now = DateTime.utc_now()
      # Fresh empty bucket per D-07
      initial_state = %ObanPowertools.Limits.State{
        partition_key: partition,
        tokens_used: 0,
        bucket_started_at: now,
        cooldown_until: nil,
        cooldown_reason: nil
      }

      verdicts = simulate_reservations(resource, initial_state, weight, count, now)
      print_simulation(verdicts, resource, weight, count, format)
      0
    else
      {:error, :no_worker} ->
        Mix.shell().error("--worker MOD is required")
        2

      {:error, :unknown_module, mod_string} ->
        Mix.shell().error("unknown --worker module: #{mod_string}")
        2

      {:error, :no_limits} ->
        Mix.shell().error("worker has no :limits configured — nothing to simulate")
        2
    end
  end

  # Sequential reservation loop — pure, no DB, no telemetry
  defp simulate_reservations(resource, initial_state, weight, count, now) do
    Enum.reduce(1..count, {initial_state, []}, fn i, {state, acc} ->
      case ObanPowertools.Limits.compute_reservation(state, resource, weight, now) do
        {:reserved, new_tokens_used} ->
          new_state = %{state | tokens_used: new_tokens_used}
          verdict = %{request: i, result: :reserved, tokens_used: new_tokens_used}
          {new_state, [verdict | acc]}

        {:blocked, code, retry_at, details} ->
          verdict = %{request: i, result: :blocked, blocker_code: code,
                      retry_at: retry_at, details: details}
          {state, [verdict | acc]}
      end
    end)
    |> elem(1)
    |> Enum.reverse()
  end
```

**Partitioned worker landmine workaround** (Pitfall 4 from RESEARCH.md):
```elixir
  # Avoid calling Worker.limit_snapshot/2 directly for partitioned workers with
  # {:args, key} partition_by when args is %{} — raises ArgumentError.
  # Instead, read @powertools_limits directly and apply defaults manually.
  defp resolve_worker_config(worker_mod, opts) do
    if function_exported?(worker_mod, :__powertools_limits__, 0) do
      limits = worker_mod.__powertools_limits__()

      if limits == [] do
        {:error, :no_limits}
      else
        partition_key = Keyword.get(opts, :partition, "__global__")
        weight = Keyword.get(opts, :weight, limits[:default_weight] || 1)

        {:ok, %{
          resource_name: limits[:name],
          scope_kind: Atom.to_string(limits[:scope]),
          bucket_capacity: limits[:bucket_capacity],
          bucket_span_ms: limits[:bucket_span_ms],
          weight: weight,
          partition_key: partition_key
        }}
      end
    else
      {:error, :no_limits}
    end
  end
```

---

### `lib/oban_powertools/limits.ex` (service, pure-function extraction — D-06)

**Analog:** itself. The extraction seam is between the pure decision logic (lines 249-261) and the side-effecting callers (lines 296-320).

**What is pure today** — these two private functions contain zero side effects (lines 249-261):
```elixir
defp normalize_bucket(%State{} = state, bucket_span_ms, now) do
  reset_at = DateTime.add(state.bucket_started_at, bucket_span_ms, :millisecond)

  if DateTime.compare(now, reset_at) == :lt do
    state
  else
    %{state | tokens_used: 0, bucket_started_at: now}
  end
end

defp cooldown_active?(state, now) do
  match?(%DateTime{}, state.cooldown_until) and
    DateTime.compare(state.cooldown_until, now) == :gt
end
```

**The three-clause cond in `attempt_reservation/5`** (lines 210-247) — this is what gets extracted. Currently the `cond` arms call side-effecting helpers (`blocked/4` fires telemetry + history; the `true` arm calls `repo.update`). The extraction pulls out only the decision:

```elixir
# Current private cond (lines 213-246) — arms call side-effecting functions:
defp attempt_reservation(repo, resource, state, snapshot, now) do
  normalized = normalize_bucket(state, resource.bucket_span_ms, now)

  cond do
    cooldown_active?(normalized, now) ->
      blockers = [cooldown_blocker(resource, normalized)]
      blocked(repo, snapshot, blockers, now)           # <-- side effect

    normalized.tokens_used + snapshot.weight > resource.bucket_capacity ->
      blockers = [limit_blocker(resource, normalized, now)]
      blocked(repo, snapshot, blockers, now)           # <-- side effect

    true ->
      normalized
      |> State.changeset(%{tokens_used: normalized.tokens_used + snapshot.weight, ...})
      |> repo.update()                                 # <-- side effect
      |> case do ...
  end
end
```

**New pure public function to add** — receives no repo, makes no calls with side effects:
```elixir
# New: called by both attempt_reservation/5 (via refactor) AND simulate task
@spec compute_reservation(State.t(), Resource.t(), pos_integer(), DateTime.t()) ::
        {:reserved, non_neg_integer()}
        | {:blocked, String.t(), DateTime.t() | nil, map()}
def compute_reservation(%State{} = state, %Resource{} = resource, weight, now) do
  normalized = normalize_bucket(state, resource.bucket_span_ms, now)

  cond do
    cooldown_active?(normalized, now) ->
      {:blocked, "cooldown", normalized.cooldown_until,
       %{reason: normalized.cooldown_reason}}

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

**Refactored `attempt_reservation/5`** — now calls `compute_reservation/4` and dispatches side effects:
```elixir
defp attempt_reservation(repo, resource, state, snapshot, now) do
  case compute_reservation(state, resource, snapshot.weight, now) do
    {:reserved, new_tokens_used} ->
      state
      |> normalize_bucket(resource.bucket_span_ms, now)
      |> State.changeset(%{
        tokens_used: new_tokens_used,
        bucket_started_at: normalize_bucket(state, resource.bucket_span_ms, now).bucket_started_at || now,
        last_reserved_at: now,
        reservation_snapshot: snapshot
      })
      |> repo.update()
      |> case do
        {:ok, updated_state} ->
          {:ok, %{
            resource_id: resource.id,
            state_id: updated_state.id,
            partition_key: updated_state.partition_key,
            weight: snapshot.weight,
            bucket_span_ms: resource.bucket_span_ms,
            snapshot: snapshot
          }}

        {:error, reason} ->
          {:error, reason}
      end

    {:blocked, code, _retry_at, _details} ->
      blocker =
        case code do
          "cooldown" ->
            normalized = normalize_bucket(state, resource.bucket_span_ms, now)
            cooldown_blocker(resource, normalized)

          "limit_reached" ->
            normalized = normalize_bucket(state, resource.bucket_span_ms, now)
            limit_blocker(resource, normalized, now)
        end

      blocked(repo, snapshot, [blocker], now)   # side effects stay here
  end
end
```

**Side effects that MUST stay in `blocked/4`** (lines 296-320 — simulate must never call this):
```elixir
defp blocked(repo, snapshot, blockers, now) do
  blocker = hd(blockers)

  Telemetry.execute_limiter_event(:blocked, %{count: 1}, %{   # <-- fires telemetry
    action: "blocked",
    blocker_code: blocker.code,
    resource: snapshot.resource_name,
    scope: snapshot.scope_kind
  })

  _ = record_history_fact(repo, %{...})                        # <-- writes DB row

  {:blocked, blockers}
end
```

**`do_reserve/3` and `upsert_resource/2`** also must never be called by simulate (they write DB rows).

**`partition_defaults/0`** is safe to call from simulate for the `__global__` default:
```elixir
def partition_defaults do
  %{
    partition_key: @global_partition,       # "__global__"
    partition_strategy: @global_strategy,   # "global"
    partition_config: %{}
  }
end
```

---

### `guides/limits-and-explain.md` (documentation, glossary single source of truth — D-08)

**Analog:** `test/oban_powertools/docs_contract_test.exs` (shows the `joined_docs()` pattern and what assertions lock content)

**Pattern: how docs_contract_test.exs locks guide content** (lines 2-19 and 137-148):
```elixir
@docs_files [
  # ...
  "guides/limits-and-explain.md",
  # ...
]

test "builder docs keep the core primitive contract explicit" do
  source = joined_docs()
  assert source =~ "Explain.explain"
  # ... one assert per locked term
end

defp joined_docs do
  @docs_files
  |> Enum.map(&File.read!/1)
  |> Enum.join("\n")
end
```

**New test to add** for OPS-08 glossary contract — add to `docs_contract_test.exs` following exact same pattern:
```elixir
test "limits-and-explain guide contains the rate-limit glossary terms" do
  source = File.read!("guides/limits-and-explain.md")

  # All 7 required D-08 terms
  assert source =~ "token_bucket"
  assert source =~ "bucket_capacity"
  assert source =~ "bucket_span_ms"
  assert source =~ "weight_by"
  assert source =~ "partition_by"
  assert source =~ "cooldown"
  assert source =~ "limit_reached"
end

test "Limiter.Explain @moduledoc contains the rate-limit glossary terms" do
  source = File.read!("lib/mix/tasks/oban_powertools.limiter.explain.ex")

  assert source =~ "token_bucket"
  assert source =~ "bucket_capacity"
  assert source =~ "bucket_span_ms"
  assert source =~ "weight_by"
  assert source =~ "partition_by"
  assert source =~ "cooldown"
  assert source =~ "limit_reached"
end
```

---

## Shared Patterns

### Boot Strategy — `Mix.Task.run("app.config")` inline
**Source:** `lib/mix/tasks/oban_powertools.doctor.ex` line 73
**Apply to:** Both new task files

The `app.config` call MUST be:
- The very first line of `run/1`
- Inline, not via `@requirements ["app.config"]`
- NOT replaced with `"app.start"` (would start Oban/supervision tree)

```elixir
@impl Mix.Task
def run(argv) do
  Mix.Task.run("app.config")    # <-- first line, always
  # ...
end
```

Doctor test assertion that both new task tests must replicate:
```elixir
test "does not use @requirements or Oban.start_link" do
  source = File.read!(@task_path)
  refute source =~ "@requirements"
  refute source =~ "Oban.start_link"
end
```

### `System.halt` Outside the `with_repo` Callback
**Source:** `lib/mix/tasks/oban_powertools.doctor.ex` lines 113-125
**Apply to:** Both new task files

```elixir
# Pattern: return exit code from callback; halt OUTSIDE
result =
  Ecto.Migrator.with_repo(repo_module, fn repo ->
    # ...work...
    exit_code   # return the integer
  end, pool_size: 2)

case result do
  {:ok, exit_code, _apps} -> System.halt(exit_code)
  {:error, reason} ->
    Mix.shell().error("...")
    System.halt(2)
end
```

Doctor test assertion to replicate:
```elixir
test "System.halt is called after with_repo returns, not inside the callback" do
  source = File.read!(@task_path)
  assert source =~ ~r/->\s+System\.halt/
end
```

### `Module.safe_concat` for All CLI Module Flags
**Source:** `lib/mix/tasks/oban_powertools.doctor.ex` lines 139-143
**Apply to:** Both new task files (`--repo`, `--worker` flags)

```elixir
# Safe: Module.safe_concat normalizes the string into a module atom
# WITHOUT invoking String.to_atom on raw CLI input (T-48-05)
Module.safe_concat([repo_string])
Module.safe_concat([worker_string])
```

Doctor test assertion to replicate:
```elixir
test "does not call String.to_atom on CLI repo flag" do
  source = File.read!(@task_path)
  refute source =~ ~r/String\.to_atom\(/
end
```

### Format Atom Mapping — Closed `case`, Not `String.to_atom`
**Source:** `lib/mix/tasks/oban_powertools.doctor.ex` lines 93-97
**Apply to:** Both new task files

```elixir
format =
  case Keyword.get(opts, :format, "human") do
    "json" -> :json
    _ -> :human
  end
```

### ANSI/TTY Degradation
**Source:** `lib/oban_powertools/doctor/formatter.ex` lines 142-148
**Apply to:** Human-format output in both new task formatters

```elixir
defp colorize(text, color) do
  if IO.ANSI.enabled?() do
    [color, text, IO.ANSI.reset()] |> IO.ANSI.format() |> IO.iodata_to_binary()
  else
    text
  end
end
```

### JSON Output — `schema_version: 1` at Top Level
**Source:** `lib/oban_powertools/doctor/formatter.ex` lines 154-169
**Apply to:** JSON format path in both new task formatters

```elixir
payload = %{
  schema_version: 1,   # stability contract — must be top-level; version is independent of doctor's
  # ... task-specific fields
}
Jason.encode!(payload)
```

### `Ecto.Migrator.with_repo` Pool Size
**Source:** `lib/mix/tasks/oban_powertools.doctor.ex` line 111
**Apply to:** Both new task files

```elixir
Ecto.Migrator.with_repo(repo_module, fn repo -> ... end, pool_size: 2)
```

### Honest Empty State (D-04 — nil snapshot and nil resource)
**Source:** `lib/oban_powertools/web/limiters_live.ex` lines 276-279
**Apply to:** `limiter.explain.ex` resource-primary path

```elixir
case snapshot do
  nil ->
    %{snapshot: nil, live_now: [], oban_job_path: nil}

  snapshot ->
    Explain.explain_snapshot(snapshot, repo: repo())
end
```

Translate to the CLI: when `snapshot` is `nil`, print "no limiter state recorded yet" and exit 0.

### Test: Source Inspection Pattern
**Source:** `test/mix/tasks/oban_powertools.doctor_test.exs` lines 1-70
**Apply to:** Both new task test files

```elixir
defmodule Mix.Tasks.ObanPowertools.Limiter.ExplainTest do
  use ExUnit.Case

  @task_path "lib/mix/tasks/oban_powertools.limiter.explain.ex"

  test "defines a plain Mix.Task" do
    Code.ensure_loaded?(Mix.Tasks.ObanPowertools.Limiter.Explain)
    assert function_exported?(Mix.Tasks.ObanPowertools.Limiter.Explain, :run, 1)
  end

  test "uses Mix.Task and not Igniter.Mix.Task" do
    source = File.read!(@task_path)
    assert source =~ "use Mix.Task"
    refute source =~ "use Igniter.Mix.Task"
  end

  test "does not use @requirements or Oban.start_link" do
    source = File.read!(@task_path)
    refute source =~ "@requirements"
    refute source =~ "Oban.start_link"
  end

  test "uses Ecto.Migrator.with_repo for repo-only boot" do
    source = File.read!(@task_path)
    assert source =~ "Ecto.Migrator.with_repo"
  end

  test "does not call String.to_atom on CLI flags" do
    source = File.read!(@task_path)
    refute source =~ ~r/String\.to_atom\(/
  end

  test "uses Module.safe_concat for module resolution" do
    source = File.read!(@task_path)
    assert source =~ "Module.safe_concat"
  end

  test "System.halt is called after with_repo returns, not inside the callback" do
    source = File.read!(@task_path)
    assert source =~ ~r/->\s+System\.halt/
  end

  test "declares required switches" do
    source = File.read!(@task_path)
    assert source =~ "resource:"
    assert source =~ "partition:"
    assert source =~ "worker:"
    assert source =~ "args:"
    assert source =~ "repo:"
    assert source =~ "format:"
  end

  test "has a @shortdoc attribute" do
    source = File.read!(@task_path)
    assert source =~ "@shortdoc"
  end
end
```

### Test: DB Integration Pattern (DataCase)
**Source:** `test/oban_powertools/limits_test.exs` lines 1-6
**Apply to:** DB-integration portions of new task tests

```elixir
defmodule Mix.Tasks.ObanPowertools.Limiter.ExplainIntegrationTest do
  use ObanPowertools.DataCase, async: false
  # ... tests that require DB (explain with a real Resource/State row, etc.)
end
```

### Test: Side-Effect-Freedom Proof (Critical for OPS-07)
**Source:** Pattern derived from `lib/oban_powertools/limits.ex` lines 296-320 (the `blocked/4` side effects to guard against)

```elixir
test "simulate emits no limiter.blocked telemetry events" do
  :telemetry.attach(
    "simulate-side-effect-guard",
    [:oban_powertools, :limiter, :blocked],
    fn _event, _measurements, _metadata, _ ->
      flunk("simulate must not emit limiter.blocked telemetry")
    end,
    nil
  )

  on_exit(fn -> :telemetry.detach("simulate-side-effect-guard") end)

  # Call compute_reservation directly or run the simulate task in-process
  # Assert no flunk was triggered
end

test "simulate does not write limiter state rows" do
  count_before = repo().aggregate(ObanPowertools.Limits.State, :count)
  # ... run simulate computation ...
  count_after = repo().aggregate(ObanPowertools.Limits.State, :count)
  assert count_before == count_after
end
```

---

## No Analog Found

All files have analogs or are self-analogous. No gaps.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | — |

---

## Key Seam: Explain Schema Field — `scope_id` is Resource Name

From `limiters_live.ex` line 270 and `explain.ex` schema field `:scope_id`:
```elixir
# scope_id holds the resource name (e.g., "global-api"), not a UUID
from(event in Explain,
  where: event.scope_id == ^resource_name,
  order_by: [desc: event.captured_at],
  limit: 1
)
```

The explain task's `--resource NAME` flag value maps directly to `scope_id`, not to `Resource.id`.

## Key Seam: `Explain.explain/3` Returns the Map Directly (Not Tagged)

From `explain.ex` lines 59-73 — the `with` unwraps the snapshot tuple but the outer return is the map:
```elixir
def explain(worker_mod, args, opts \\ []) do
  with {:ok, snapshot} <- ObanPowertools.Worker.limit_snapshot(worker_mod, args) do
    # Returns the map directly — NOT {:ok, map}
    %{status: ..., blockers: ..., live_now: ..., snapshot_at_block_start: ...}
  end
  # Returns {:ok, nil} passthrough (from limit_snapshot) when worker has no limits
end
```

The task must handle both the map case and the `{:ok, nil}` passthrough.

---

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `lib/oban_powertools/`, `test/mix/tasks/`, `test/oban_powertools/`
**Files scanned:** 10 source files read in full
**Pattern extraction date:** 2026-05-29
