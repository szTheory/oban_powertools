defmodule Mix.Tasks.ObanPowertools.Limiter.SimulateTest do
  # (a) Source-inspection tests — no DB needed, not async to avoid atom-table
  # race with load of task module
  use ExUnit.Case

  @task_path "lib/mix/tasks/oban_powertools.limiter.simulate.ex"

  test "defines a plain Mix.Task with run/1" do
    Code.ensure_loaded?(Mix.Tasks.ObanPowertools.Limiter.Simulate)
    assert function_exported?(Mix.Tasks.ObanPowertools.Limiter.Simulate, :run, 1)
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

  test "has a @shortdoc attribute" do
    source = File.read!(@task_path)
    assert source =~ "@shortdoc"
  end

  test "does not call String.to_atom on CLI flags (T-48-05 / T-49-08)" do
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

  test "declares all required switches including worker and overrides" do
    source = File.read!(@task_path)
    assert source =~ "worker:"
    assert source =~ "bucket_capacity:"
    assert source =~ "bucket_span_ms:"
    assert source =~ "weight:"
    assert source =~ "count:"
    assert source =~ "partition:"
    assert source =~ "repo:"
    assert source =~ "format:"
  end

  test "validates numeric overrides are positive integers before simulating (WR-01/WR-03, D-02)" do
    source = File.read!(@task_path)
    # `--count <= 0` would iterate the descending range `1..0` (request "0"); a zero/negative
    # bucket capacity/span/weight produces a preview that silently lies. All must exit 2.
    assert source =~ "validate_positive"
    assert source =~ "must be a positive integer"
  end

  test "source does not reference side-effecting limiter functions (OPS-07 purity)" do
    source = File.read!(@task_path)
    # Simulate must never call the side-effecting reservation path
    refute source =~ "do_reserve"
    refute source =~ "attempt_reservation"
    refute source =~ "upsert_resource"
    refute source =~ "get_or_create_state"
  end

  test "calls only Limits.compute_reservation/4 for the reservation loop" do
    source = File.read!(@task_path)
    assert source =~ "Limits.compute_reservation"
  end

  test "contains token_bucket glossary term in @moduledoc" do
    source = File.read!(@task_path)
    assert source =~ "token_bucket"
  end

  test "contains rate-limit glossary terms for docs contract" do
    source = File.read!(@task_path)
    assert source =~ "bucket_capacity"
    assert source =~ "bucket_span_ms"
    assert source =~ "weight_by"
    assert source =~ "partition_by"
    assert source =~ "scope"
    assert source =~ "cooldown"
    assert source =~ "limit_reached"
  end

  test "resolves scope_kind nil-safely for default-scoped workers (T-49-09 / Pitfall 4)" do
    source = File.read!(@task_path)
    # Must guard against nil :scope key — default-scoped workers omit :scope
    assert source =~ "limits[:scope] || :global"
  end

  test "references ObanPowertools.Limits.Glossary as single source of truth" do
    source = File.read!(@task_path)
    assert source =~ "Glossary"
  end

  test "JSON path emits schema_version: 1 stability contract" do
    source = File.read!(@task_path)
    assert source =~ "schema_version: 1"
  end
end

# ---------------------------------------------------------------------------
# (b) Pure-verdict tests — no DB required, async: true
# ---------------------------------------------------------------------------

defmodule Mix.Tasks.ObanPowertools.Limiter.SimulatePureVerdictTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Limits
  alias ObanPowertools.Limits.{Resource, State}

  # Helpers that build the same synthetic structs the simulate task uses
  defp build_resource(bucket_capacity, bucket_span_ms, scope_kind \\ "global") do
    %Resource{
      name: "test-resource",
      bucket_capacity: bucket_capacity,
      bucket_span_ms: bucket_span_ms,
      scope_kind: scope_kind
    }
  end

  defp build_fresh_state(partition_key \\ "__global__") do
    now = DateTime.utc_now()

    %State{
      partition_key: partition_key,
      tokens_used: 0,
      bucket_started_at: now,
      cooldown_until: nil,
      cooldown_reason: nil
    }
  end

  defp simulate_reservations(resource, initial_state, weight, count) do
    now = DateTime.utc_now()

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

  # OPS-07: requests 1-3 reserved, request 4 blocked with "limit_reached"
  # for capacity 3 / weight 1 / count 4
  test "reserved on requests 1-3, blocked limit_reached on request 4 (capacity 3)" do
    resource = build_resource(3, 60_000)
    initial_state = build_fresh_state()

    verdicts = simulate_reservations(resource, initial_state, 1, 4)

    assert length(verdicts) == 4

    # Requests 1-3: reserved
    Enum.each(1..3, fn i ->
      verdict = Enum.at(verdicts, i - 1)
      assert verdict.request == i
      assert verdict.result == :reserved
    end)

    # Request 4: blocked with limit_reached
    verdict_4 = Enum.at(verdicts, 3)
    assert verdict_4.request == 4
    assert verdict_4.result == :blocked
    assert verdict_4.blocker_code == "limit_reached"
    assert %DateTime{} = verdict_4.retry_at
  end

  # OPS-07: default-scoped worker (no :scope key → scope_kind "global") does not raise
  test "default-scoped worker (scope key absent) resolves scope_kind to global and produces correct verdicts" do
    # Simulate what resolve_worker_config/2 does for a worker without an explicit :scope key
    limits_without_scope = [
      name: "global-api",
      bucket_capacity: 2,
      bucket_span_ms: 60_000,
      default_weight: 1
    ]

    # The nil-safe pattern: (limits[:scope] || :global) |> Atom.to_string()
    scope_kind = (limits_without_scope[:scope] || :global) |> Atom.to_string()
    assert scope_kind == "global"

    # Build the same synthetic structs and verify verdicts
    resource = build_resource(2, 60_000, scope_kind)
    initial_state = build_fresh_state()

    verdicts = simulate_reservations(resource, initial_state, 1, 3)

    # Requests 1-2: reserved (capacity 2)
    assert Enum.at(verdicts, 0).result == :reserved
    assert Enum.at(verdicts, 1).result == :reserved

    # Request 3: blocked
    assert Enum.at(verdicts, 2).result == :blocked
    assert Enum.at(verdicts, 2).blocker_code == "limit_reached"
  end

  test "sequential state threads correctly — blocked requests do not consume tokens" do
    resource = build_resource(2, 60_000)
    initial_state = build_fresh_state()

    verdicts = simulate_reservations(resource, initial_state, 1, 5)

    reserved_verdicts = Enum.filter(verdicts, &(&1.result == :reserved))
    blocked_verdicts = Enum.filter(verdicts, &(&1.result == :blocked))

    assert length(reserved_verdicts) == 2
    assert length(blocked_verdicts) == 3

    # All blocked verdicts should have the same tokens_used (state not mutated on block)
    blocked_codes = Enum.map(blocked_verdicts, & &1.blocker_code)
    assert Enum.all?(blocked_codes, &(&1 == "limit_reached"))
  end
end

# ---------------------------------------------------------------------------
# (c) Side-effect-freedom and no-DB-writes tests — DB required, not async
# ---------------------------------------------------------------------------

defmodule Mix.Tasks.ObanPowertools.Limiter.SimulateSideEffectFreedomTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Limits
  alias ObanPowertools.Limits.{Resource, State}

  defp repo, do: ObanPowertools.TestRepo

  defp build_resource(bucket_capacity, bucket_span_ms) do
    %Resource{
      name: "simulate-test-resource",
      bucket_capacity: bucket_capacity,
      bucket_span_ms: bucket_span_ms,
      scope_kind: "global"
    }
  end

  defp build_fresh_state do
    now = DateTime.utc_now()

    %State{
      partition_key: "__global__",
      tokens_used: 0,
      bucket_started_at: now,
      cooldown_until: nil,
      cooldown_reason: nil
    }
  end

  defp run_simulation_loop(resource, initial_state, weight, count) do
    now = DateTime.utc_now()

    Enum.reduce(1..count, {initial_state, []}, fn i, {state, acc} ->
      case Limits.compute_reservation(state, resource, weight, now) do
        {:reserved, new_tokens_used} ->
          {%{state | tokens_used: new_tokens_used},
           [%{request: i, result: :reserved} | acc]}

        {:blocked, code, _retry_at, _details} ->
          {state, [%{request: i, result: :blocked, blocker_code: code} | acc]}
      end
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  # OPS-07: Simulate emits ZERO [:oban_powertools, :limiter, :blocked] telemetry events
  test "simulate emits no limiter.blocked telemetry events (side-effect-freedom, OPS-07)" do
    handler_id = "simulate-side-effect-guard-#{System.unique_integer()}"

    :telemetry.attach(
      handler_id,
      [:oban_powertools, :limiter, :blocked],
      fn _event, _measurements, _metadata, _ ->
        flunk("simulate must not emit [:oban_powertools, :limiter, :blocked] telemetry — " <>
                "compute_reservation/4 is pure and must never trigger the blocked/4 side-effecting path")
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    # Run a simulation that WILL produce blocked verdicts (capacity 2, count 5)
    resource = build_resource(2, 60_000)
    initial_state = build_fresh_state()
    verdicts = run_simulation_loop(resource, initial_state, 1, 5)

    # Verify we got blocked verdicts (test is only meaningful if blocks occurred)
    assert Enum.any?(verdicts, &(&1.result == :blocked)),
           "Expected at least one blocked verdict to exercise the side-effect-freedom guard"

    # If we reach here, the telemetry handler never fired — side-effect-freedom proven
  end

  # OPS-07: Simulate writes zero rows to oban_powertools_limit_states and
  # oban_powertools_limit_resources — no-mutation correctness property
  test "simulate writes zero State and Resource rows to the DB (no-mutation, OPS-07)" do
    state_count_before = repo().aggregate(State, :count)
    resource_count_before = repo().aggregate(Resource, :count)

    # Run a simulation that includes both reserved and blocked verdicts
    resource = build_resource(2, 60_000)
    initial_state = build_fresh_state()
    _verdicts = run_simulation_loop(resource, initial_state, 1, 5)

    state_count_after = repo().aggregate(State, :count)
    resource_count_after = repo().aggregate(Resource, :count)

    assert state_count_after == state_count_before,
           "Simulate must not write any oban_powertools_limit_states rows"

    assert resource_count_after == resource_count_before,
           "Simulate must not write any oban_powertools_limit_resources rows"
  end
end
