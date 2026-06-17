defmodule Mix.Tasks.ObanPowertools.Limiter.Explain do
  use Mix.Task
  import Ecto.Query

  @shortdoc "Explain a limiter's current blocking state (read-only)"

  @moduledoc """
  Explains a limiter's current blocking state by querying the live limiter state
  and the latest persisted blocker snapshot. Read-only — never mutates limiter state.

  ## Usage

      # Resource-primary path (matches vocabulary in the Limiters UI):
      mix oban_powertools.limiter.explain --resource my-resource
      mix oban_powertools.limiter.explain --resource my-resource --partition user-42

      # Worker + args secondary path (maps to Explain.explain/3):
      mix oban_powertools.limiter.explain --worker MyApp.Workers.ApiWorker
      mix oban_powertools.limiter.explain --worker MyApp.Workers.ApiWorker --args '{"user_id":1}'

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
      --format human|json   Output format. "human" degrades ANSI in CI/non-TTY.
                            "json" emits schema_version: 1 stability contract.

  ## Boot Strategy

  This task starts only the Ecto repo via `Ecto.Migrator.with_repo/2`. It does **not**
  start Oban or any queue/worker supervision tree. It is safe to run around deploys
  without triggering job processing.

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

  @switches [
    repo: :string,
    format: :string,
    resource: :string,
    partition: :string,
    worker: :string,
    args: :string
  ]

  @impl Mix.Task
  def run(argv) do
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

          dispatch(repo, opts, format)
        end,
        pool_size: 2
      )

    case result do
      {:ok, exit_code, _apps} ->
        System.halt(exit_code)

      {:error, reason} ->
        Mix.shell().error(
          "Oban Powertools Limiter.Explain: cannot start repo — #{inspect(reason)}\n" <>
            "Configure your repo with: config :oban_powertools, repo: MyApp.Repo\n" <>
            "Or pass the flag: mix oban_powertools.limiter.explain --repo MyApp.Repo"
        )

        System.halt(2)
    end
  end

  # ---------------------------------------------------------------------------
  # Dispatch: resource-primary, worker-secondary, or usage error
  # ---------------------------------------------------------------------------

  @doc false
  def dispatch(repo, opts, format) do
    cond do
      Keyword.has_key?(opts, :resource) ->
        run_resource_path(repo, opts, format)

      Keyword.has_key?(opts, :worker) ->
        run_worker_path(repo, opts, format)

      true ->
        Mix.shell().error(
          "Oban Powertools Limiter.Explain: provide --resource NAME or --worker MOD\n" <>
            "  Resource path:  mix oban_powertools.limiter.explain --resource my-limiter\n" <>
            "  Worker path:    mix oban_powertools.limiter.explain --worker MyApp.MyWorker"
        )

        2
    end
  end

  # ---------------------------------------------------------------------------
  # Resource-primary path (D-03/D-04)
  # ---------------------------------------------------------------------------

  defp run_resource_path(repo, opts, format) do
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
        # Honest empty state (D-04): no snapshot recorded yet → report runnable
        print_empty_state(resource_name, partition_key, format)
        0

      snap ->
        explanation = ObanPowertools.Explain.explain_snapshot(snap, repo: repo)
        normalized_status = normalize_status(explanation.status)
        print_explanation(%{explanation | status: normalized_status}, resource_name, format)
        0
    end
  end

  # ---------------------------------------------------------------------------
  # Worker-secondary path (D-03)
  # ---------------------------------------------------------------------------

  defp run_worker_path(repo, opts, format) do
    # Resolve the worker's declared limiter snapshot FIRST. `Explain.explain/3` returns
    # a plain map even for a no-limits worker (its `with {:ok, snapshot}` binds nil and
    # falls through to status: :runnable), so we cannot distinguish "no limiter at all"
    # from "runnable" downstream — we must detect the nil snapshot here (CR-01, D-02).
    with {:ok, worker_mod} <- resolve_worker(opts),
         {:ok, parsed_args} <- parse_args_json(opts),
         {:ok, snapshot} when not is_nil(snapshot) <-
           worker_limit_snapshot(worker_mod, parsed_args) do
      explanation = ObanPowertools.Explain.explain(worker_mod, parsed_args, repo: repo)
      normalized = normalize_status(explanation.status)
      print_explanation(%{explanation | status: normalized}, inspect(worker_mod), format)
      0
    else
      {:ok, nil} ->
        Mix.shell().error("worker has no limits configured")
        2

      {:error, :not_loaded, mod_string} ->
        Mix.shell().error("unknown --worker module: #{mod_string}")
        2

      {:error, :invalid_json} ->
        Mix.shell().error(
          "--args must be a valid JSON object string (e.g. '{\"key\":\"value\"}')"
        )

        2

      {:error, :bad_args, message} ->
        Mix.shell().error(message)
        2
    end
  end

  # `Worker.limit_snapshot/2` can raise ArgumentError for `partition_by`/`weight_by`
  # workers when the required args key is missing (Pitfall 4). Rescue and map to a
  # cannot-run exit 2 instead of letting the task crash.
  defp worker_limit_snapshot(worker_mod, args) do
    ObanPowertools.Worker.limit_snapshot(worker_mod, args)
  rescue
    ArgumentError ->
      {:error, :bad_args,
       "worker requires args to resolve its limiter (partition_by/weight_by); " <>
         "pass --args with the required keys"}
  end

  # ---------------------------------------------------------------------------
  # Output formatting
  # ---------------------------------------------------------------------------

  defp print_empty_state(resource_name, partition_key, :json) do
    payload = %{
      schema_version: 1,
      resource: resource_name,
      partition: partition_key,
      status: "runnable",
      message: "no limiter state recorded yet",
      blockers: []
    }

    IO.puts(Jason.encode!(payload))
  end

  defp print_empty_state(resource_name, partition_key, :human) do
    Mix.shell().info(
      colorize("Limiter: #{resource_name} (partition: #{partition_key})", IO.ANSI.cyan()) <>
        "\n" <>
        colorize("Status: ", IO.ANSI.bright()) <>
        colorize("runnable", IO.ANSI.green()) <>
        "\nMessage: no limiter state recorded yet"
    )
  end

  defp print_explanation(explanation, resource_name, :json) do
    payload = %{
      schema_version: 1,
      resource: resource_name,
      status: to_string(explanation.status),
      blockers: format_blockers_json(explanation.blockers),
      live_now: format_blockers_json(explanation.live_now)
    }

    IO.puts(Jason.encode!(payload))
  end

  defp print_explanation(explanation, resource_name, :human) do
    status_text =
      case explanation.status do
        :runnable -> colorize("runnable", IO.ANSI.green())
        :blocked -> colorize("blocked", IO.ANSI.red())
        _ -> colorize(to_string(explanation.status), IO.ANSI.yellow())
      end

    header = colorize("Limiter: #{resource_name}", IO.ANSI.cyan())
    status_line = colorize("Status: ", IO.ANSI.bright()) <> status_text

    blocker_lines =
      case explanation.blockers do
        [] ->
          ""

        blockers ->
          formatted =
            Enum.map_join(blockers, "\n", fn b ->
              retry_str =
                if b[:retry_at],
                  do: " (retry at: #{b.retry_at})",
                  else: ""

              "  [#{b.code}] #{b.summary}#{retry_str}"
            end)

          "\nBlockers:\n" <> formatted
      end

    Mix.shell().info(header <> "\n" <> status_line <> blocker_lines)
  end

  defp format_blockers_json(blockers) when is_list(blockers) do
    Enum.map(blockers, fn b ->
      %{
        code: b[:code] || b.code,
        summary: b[:summary] || b.summary,
        retry_at: format_datetime(b[:retry_at] || b.retry_at),
        scope: b[:scope] || b.scope,
        details: b[:details] || b.details
      }
    end)
  end

  defp format_blockers_json(_), do: []

  defp format_datetime(nil), do: nil
  defp format_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp format_datetime(other), do: inspect(other)

  defp colorize(text, color) do
    if IO.ANSI.enabled?() do
      [color, text, IO.ANSI.reset()] |> IO.ANSI.format() |> IO.iodata_to_binary()
    else
      text
    end
  end

  # ---------------------------------------------------------------------------
  # Status normalization (T-49-03 / T-48-05: never String.to_atom on raw values)
  # ---------------------------------------------------------------------------

  defp normalize_status(status) when is_binary(status) do
    case status do
      "runnable" -> :runnable
      "blocked" -> :blocked
      _ -> :unknown
    end
  end

  defp normalize_status(status) when is_atom(status), do: status

  # ---------------------------------------------------------------------------
  # Repo resolution (T-48-05 / T-49-03)
  # ---------------------------------------------------------------------------

  defp resolve_repo(opts) do
    case Keyword.get(opts, :repo) do
      nil ->
        ObanPowertools.RuntimeConfig.repo!()

      repo_string ->
        Module.safe_concat([repo_string])
    end
  end

  # ---------------------------------------------------------------------------
  # Worker resolution (T-49-03)
  # ---------------------------------------------------------------------------

  defp resolve_worker(opts) do
    case Keyword.get(opts, :worker) do
      nil ->
        # Should not happen given the dispatch guard, but be explicit
        {:error, :not_loaded, "nil"}

      worker_string ->
        try do
          mod = Module.safe_concat([worker_string])

          if Code.ensure_loaded?(mod) do
            {:ok, mod}
          else
            {:error, :not_loaded, worker_string}
          end
        rescue
          ArgumentError ->
            # Module.safe_concat raises ArgumentError if the module atom does not
            # already exist in the VM — treat as unknown module (T-49-03, D-04)
            {:error, :not_loaded, worker_string}
        end
    end
  end

  # ---------------------------------------------------------------------------
  # JSON args parsing (T-49-04: never atomize untrusted keys)
  # ---------------------------------------------------------------------------

  defp parse_args_json(opts) do
    json_string = Keyword.get(opts, :args, "{}")

    case Jason.decode(json_string) do
      {:ok, map} when is_map(map) ->
        {:ok, map}

      {:ok, _other} ->
        {:error, :invalid_json}

      {:error, _} ->
        {:error, :invalid_json}
    end
  end
end
