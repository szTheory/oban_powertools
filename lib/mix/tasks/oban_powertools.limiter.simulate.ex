defmodule Mix.Tasks.ObanPowertools.Limiter.Simulate do
  use Mix.Task

  @shortdoc "Preview limiter behavior for a config without mutating state"

  @moduledoc """
  Previews the per-request reserved/blocked verdicts for a worker's declared
  limiter config without touching the database, emitting telemetry, or writing
  any audit rows. Runs `--count N` sequential reservations against a fresh
  empty bucket through the pure `Limits.compute_reservation/4` core.

  ## Exit Codes

  | Code | Meaning |
  |------|---------|
  | 0    | Simulation complete — per-request verdicts in stdout |
  | 2    | Bad input: unknown --worker module or worker has no limits |

  ## Flags

      --worker MOD             Worker module to read declared :limits from.
                               (required)
      --bucket-capacity N      Override declared bucket_capacity.
      --bucket-span-ms N       Override declared bucket_span_ms (milliseconds).
      --weight N               Override declared default_weight per reservation.
      --count N                Number of sequential reservations to simulate
                               (default: 1).
      --partition KEY          Override resolved partition_key (default:
                               "__global__").
      --repo MyApp.Repo        Ecto repo module. Falls back to
                               `config :oban_powertools, repo: MyApp.Repo`.
      --format human|json      Output format. "human" (default) renders a
                               readable per-request sequence with ANSI color
                               that auto-degrades in CI/non-TTY. "json" emits
                               a machine-readable payload with a
                               `schema_version: 1` stability contract.

  ## Boot Strategy

  This task starts only the Ecto repo via `Ecto.Migrator.with_repo/2` for
  CLI-family consistency. The simulation loop itself is pure and writes zero
  rows to `oban_powertools_limit_states` or `oban_powertools_limit_resources`.

  ## Rate-Limit Glossary

  Source: `ObanPowertools.Limits.Glossary.text/0`

  **token_bucket** — The rate-limiting algorithm used by ObanPowertools limiters. Each
  partition has a bucket of `bucket_capacity` tokens. Each reservation consumes `weight`
  tokens. The bucket refills (resets to zero tokens used) after `bucket_span_ms`
  milliseconds have elapsed since `bucket_started_at`.

  **bucket_capacity** — The maximum number of tokens available per bucket window. A
  reservation that would bring `tokens_used + weight` above this value is blocked with
  the `limit_reached` blocker code.

  **bucket_span_ms** — The duration of one bucket window in milliseconds. After this
  interval elapses since `bucket_started_at`, the bucket resets and tokens are available
  again. Used to compute `retry_at` for a `limit_reached` block.

  **weight** — The per-reservation token cost. Defaults to the resource's
  `default_weight` (usually 1). Each successful reservation consumes `weight` tokens from
  the bucket.

  **weight_by** — A dynamic weight resolver declared on the worker (e.g.
  `weight_by: {:args, :cost}`). At enqueue time the resolved value is bound to the
  reservation snapshot as the effective `weight`.

  **partition** — A named isolation group within a limiter resource. Each partition
  maintains its own independent token bucket. For `scope: :global` limiters there is
  one partition (`__global__`); for `scope: :partitioned` there is one bucket per
  resolved `partition_key`.

  **partition_by** — A dynamic partition key resolver declared on the worker (e.g.
  `partition_by: {:args, :user_id}`). At enqueue time the resolved value becomes the
  `partition_key` used to look up the correct bucket.

  **scope** — The partitioning strategy for a limiter resource. `global` means one
  shared bucket across all callers. `partitioned` means one independent bucket per
  resolved `partition_key`, enabling per-user, per-account, or per-tenant limits.

  **cooldown** — An operator-set hold on a partition until a specific `DateTime`. While
  a cooldown is active, all reservations for that partition are blocked with the
  `cooldown` blocker code regardless of remaining bucket capacity. Useful for
  propagating backpressure signals (e.g. HTTP 429 responses) into the limiter.

  **limit_reached** — Blocker code returned when `tokens_used + weight > bucket_capacity`.
  The `retry_at` field indicates when the bucket will reset
  (`bucket_started_at + bucket_span_ms`, clamped to at least now).

  **cooldown** (blocker code) — Blocker code returned when a resource partition is under
  an active operator cooldown. The `retry_at` field is `cooldown_until` — the
  `DateTime` at which the cooldown expires and reservations are permitted again.
  """

  alias ObanPowertools.Limits
  alias ObanPowertools.Limits.{Resource, State}

  @switches [
    repo: :string,
    format: :string,
    worker: :string,
    bucket_capacity: :integer,
    bucket_span_ms: :integer,
    weight: :integer,
    count: :integer,
    partition: :string
  ]

  @impl Mix.Task
  def run(argv) do
    # Load the host application's configuration and code paths so the repo module
    # and worker module are available, WITHOUT starting any application (D-09/D-10).
    # "app.config" loads config + code paths but never *starts* apps, so Oban's
    # supervision tree stays down. Called inline (not via a module-attribute task
    # requirement) and never via "app.start", which would start Oban (Pitfall 1).
    Mix.Task.run("app.config")

    {opts, _args, _invalid} = OptionParser.parse(argv, strict: @switches)

    repo_module = resolve_repo(opts)

    result =
      Ecto.Migrator.with_repo(
        repo_module,
        fn _repo ->
          # Map the --format string flag to a known atom explicitly. Avoids
          # String.to_existing_atom (fragile: the target atom may not be
          # registered yet at runtime) and never creates atoms from arbitrary
          # CLI input (T-48-05 mitigation). Unknown values fall back to human.
          format =
            case Keyword.get(opts, :format, "human") do
              "json" -> :json
              _ -> :human
            end

          run_simulate(opts, format)
        end,
        pool_size: 2
      )

    case result do
      {:ok, exit_code, _apps} ->
        System.halt(exit_code)

      {:error, reason} ->
        Mix.shell().error(
          "Oban Powertools Limiter.Simulate: cannot start repo — #{inspect(reason)}\n" <>
            "Configure your repo with: config :oban_powertools, repo: MyApp.Repo\n" <>
            "Or pass the flag: mix oban_powertools.limiter.simulate --repo MyApp.Repo"
        )

        System.halt(2)
    end
  end

  # ---------------------------------------------------------------------------
  # Simulate core — calls ONLY compute_reservation/4, zero side effects
  # ---------------------------------------------------------------------------

  defp run_simulate(opts, format) do
    with {:ok, worker_mod} <- resolve_worker(opts),
         {:ok, config} <- resolve_worker_config(worker_mod, opts),
         capacity = Keyword.get(opts, :bucket_capacity, config.bucket_capacity),
         span_ms = Keyword.get(opts, :bucket_span_ms, config.bucket_span_ms),
         weight = Keyword.get(opts, :weight, config.weight),
         count = Keyword.get(opts, :count, 1),
         partition = Keyword.get(opts, :partition, config.partition_key),
         :ok <-
           validate_positive([
             {capacity, "--bucket-capacity"},
             {span_ms, "--bucket-span-ms"},
             {weight, "--weight"},
             {count, "--count"}
           ]) do
      # Synthetic Resource struct — never touches the DB for simulation
      resource = %Resource{
        name: config.resource_name,
        bucket_capacity: capacity,
        bucket_span_ms: span_ms,
        scope_kind: config.scope_kind
      }

      now = DateTime.utc_now()

      # Fresh empty bucket per D-07 — simulation always starts from zero tokens used
      initial_state = %State{
        partition_key: partition,
        tokens_used: 0,
        bucket_started_at: now,
        cooldown_until: nil,
        cooldown_reason: nil
      }

      verdicts = simulate_reservations(resource, initial_state, weight, count, now)
      print_simulation(verdicts, resource, weight, count, partition, format)
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

      {:error, {:bad_override, message}} ->
        Mix.shell().error(message)
        2
    end
  end

  # Validate effective numeric inputs are positive integers before simulating, mirroring
  # the worker macro's `validate_positive_integer!` contract (WR-03/WR-01). A non-positive
  # bucket/span/weight/count would otherwise produce a preview that silently lies
  # (e.g. `--bucket-span-ms 0` resets every call; `--count 0` iterates the descending
  # range `1..0` and emits a bogus request "0").
  defp validate_positive(pairs) do
    Enum.reduce_while(pairs, :ok, fn {value, flag}, _acc ->
      if is_integer(value) and value > 0 do
        {:cont, :ok}
      else
        {:halt, {:error, {:bad_override, "#{flag} must be a positive integer"}}}
      end
    end)
  end

  # Sequential reservation loop — pure computation, no DB access, no telemetry.
  # Calls ONLY ObanPowertools.Limits.compute_reservation/4.
  defp simulate_reservations(resource, initial_state, weight, count, now) do
    Enum.reduce(1..count, {initial_state, []}, fn i, {state, acc} ->
      case Limits.compute_reservation(state, resource, weight, now) do
        {:reserved, new_tokens_used} ->
          new_state = %{state | tokens_used: new_tokens_used}
          verdict = %{request: i, result: :reserved, tokens_used: new_tokens_used}
          {new_state, [verdict | acc]}

        {:blocked, code, retry_at, details} ->
          verdict = %{
            request: i,
            result: :blocked,
            blocker_code: code,
            retry_at: retry_at,
            details: details
          }

          {state, [verdict | acc]}
      end
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  # ---------------------------------------------------------------------------
  # Formatting
  # ---------------------------------------------------------------------------

  defp print_simulation(verdicts, resource, weight, count, partition, :human) do
    Mix.shell().info(
      "\nSimulating #{count} request(s) against #{colorize(resource.name, IO.ANSI.cyan())} " <>
        "(capacity: #{resource.bucket_capacity}, span: #{resource.bucket_span_ms}ms, " <>
        "weight: #{weight}, partition: #{partition})\n"
    )

    Enum.each(verdicts, fn verdict ->
      case verdict.result do
        :reserved ->
          Mix.shell().info(
            "  Request #{verdict.request}: #{colorize("reserved", IO.ANSI.green())} " <>
              "(tokens_used: #{verdict.tokens_used}/#{resource.bucket_capacity})"
          )

        :blocked ->
          retry_str =
            if verdict.retry_at,
              do: " retry_at=#{DateTime.to_iso8601(verdict.retry_at)}",
              else: ""

          Mix.shell().info(
            "  Request #{verdict.request}: #{colorize("blocked", IO.ANSI.red())} " <>
              "(#{verdict.blocker_code}#{retry_str})"
          )
      end
    end)

    Mix.shell().info("")
  end

  defp print_simulation(verdicts, resource, weight, count, partition, :json) do
    serialized =
      Enum.map(verdicts, fn verdict ->
        base = %{
          request: verdict.request,
          result: verdict.result
        }

        case verdict.result do
          :reserved ->
            Map.put(base, :tokens_used, verdict.tokens_used)

          :blocked ->
            base
            |> Map.put(:blocker_code, verdict.blocker_code)
            |> Map.put(:retry_at, verdict.retry_at && DateTime.to_iso8601(verdict.retry_at))
            |> Map.put(:details, verdict.details)
        end
      end)

    payload = %{
      schema_version: 1,
      resource: resource.name,
      bucket_capacity: resource.bucket_capacity,
      bucket_span_ms: resource.bucket_span_ms,
      weight: weight,
      count: count,
      partition: partition,
      verdicts: serialized
    }

    Mix.shell().info(Jason.encode!(payload))
  end

  defp colorize(text, color) do
    if IO.ANSI.enabled?() do
      [color, text, IO.ANSI.reset()] |> IO.ANSI.format() |> IO.iodata_to_binary()
    else
      text
    end
  end

  # ---------------------------------------------------------------------------
  # Worker config resolution (Pitfall 4 workaround — avoids limit_snapshot/2
  # which raises ArgumentError for partition_by: {:args, key} with empty args)
  # ---------------------------------------------------------------------------

  # Read @powertools_limits directly and apply --partition/defaults manually
  # rather than calling Worker.limit_snapshot(mod, %{}) which raises for
  # partitioned workers when args is %{} (Pitfall 4 / T-49-09 mitigation).
  defp resolve_worker_config(worker_mod, opts) do
    if function_exported?(worker_mod, :__powertools_limits__, 0) do
      limits = worker_mod.__powertools_limits__()

      if limits == [] do
        {:error, :no_limits}
      else
        partition_key = Keyword.get(opts, :partition, "__global__")
        weight = Keyword.get(opts, :weight, limits[:default_weight] || 1)

        # Nil-safe scope_kind: :scope is absent for default-scoped (global) workers,
        # so `limits[:scope]` may be nil. Default nil to :global before converting
        # to avoid ArgumentError from Atom.to_string(nil). (T-49-09 / Pitfall 4)
        scope_kind = (limits[:scope] || :global) |> Atom.to_string()

        {:ok,
         %{
           resource_name: limits[:name],
           scope_kind: scope_kind,
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

  # ---------------------------------------------------------------------------
  # Repo resolution (D-07 / T-48-05)
  # ---------------------------------------------------------------------------

  defp resolve_repo(opts) do
    case Keyword.get(opts, :repo) do
      nil ->
        # Fallback to the project's ObanPowertools.RuntimeConfig contract.
        ObanPowertools.RuntimeConfig.repo!()

      repo_string ->
        # Safe atom resolution: use Module.safe_concat which normalises the string
        # into a proper module atom without invoking String.to_atom on raw CLI input
        # (T-48-05 mitigation — never String.to_atom/1 on user-supplied input).
        Module.safe_concat([repo_string])
    end
  end

  # ---------------------------------------------------------------------------
  # Worker resolution (T-48-05)
  # ---------------------------------------------------------------------------

  defp resolve_worker(opts) do
    case Keyword.get(opts, :worker) do
      nil ->
        {:error, :no_worker}

      worker_string ->
        # Module.safe_concat normalises the string into a module atom without
        # invoking String.to_atom on raw CLI input (T-48-05 mitigation).
        {:ok, Module.safe_concat([worker_string])}
    end
  end
end
