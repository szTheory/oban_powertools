defmodule ObanPowertools.LimitsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Limits
  alias ObanPowertools.Limits.{Resource, State}

  defmodule GlobalWorker do
    use ObanPowertools.Worker,
      args: [tenant_id: :integer],
      limits: [
        name: "global-api",
        scope: :global,
        bucket_capacity: 2,
        bucket_span_ms: 60_000
      ]

    @impl true
    def process(_job), do: :ok
  end

  defmodule PartitionedWorker do
    use ObanPowertools.Worker,
      args: [user_id: :integer, cost: :integer],
      limits: [
        name: "user-api",
        scope: :partitioned,
        partition_by: {:args, :user_id},
        weight_by: {:args, :cost},
        bucket_capacity: 5,
        bucket_span_ms: 60_000
      ]

    @impl true
    def process(_job), do: :ok
  end

  test "global limiter blocks once the bucket is saturated" do
    assert {:ok, _job} = GlobalWorker.enqueue(%{tenant_id: 1})
    assert {:ok, _job} = GlobalWorker.enqueue(%{tenant_id: 2})
    assert {:blocked, [%{code: "limit_reached"}]} = GlobalWorker.enqueue(%{tenant_id: 3})

    resource = repo().get_by!(Resource, name: "global-api")
    state = repo().get_by!(State, resource_id: resource.id, partition_key: "__global__")

    assert state.tokens_used == 2
  end

  test "partitioned limiter isolates partitions by resolved key" do
    assert {:ok, _job} = PartitionedWorker.enqueue(%{user_id: 10, cost: 3})
    assert {:ok, _job} = PartitionedWorker.enqueue(%{user_id: 11, cost: 3})
    assert {:ok, _job} = PartitionedWorker.enqueue(%{user_id: 10, cost: 2})

    assert {:blocked, [%{code: "limit_reached"}]} =
             PartitionedWorker.enqueue(%{user_id: 10, cost: 1})

    assert repo().get_by!(State, partition_key: "10").tokens_used == 5
    assert repo().get_by!(State, partition_key: "11").tokens_used == 3
  end

  test "weight binding is snapshotted onto the queued job metadata" do
    assert {:ok, job} = PartitionedWorker.enqueue(%{user_id: 77, cost: 2})

    assert %{
             "oban_powertools" => %{
               "limits" => %{
                 "partition_key" => "77",
                 "resource" => "user-api",
                 "scope" => "partitioned",
                 "weight" => 2
               }
             }
           } = job.meta
  end

  test "cooldown blocks reservations until the cooldown expires" do
    now = DateTime.utc_now()

    assert {:ok, reservation} =
             Limits.reserve(repo(), PartitionedWorker, %{user_id: 42, cost: 1}, now: now)

    assert {:ok, _cooldown} =
             Limits.cooldown(
               repo(),
               "user-api",
               reservation.partition_key,
               DateTime.add(now, 30, :second),
               "429 backoff",
               now: now
             )

    assert {:blocked, [%{code: "cooldown"}]} =
             Limits.reserve(repo(), PartitionedWorker, %{user_id: 42, cost: 1}, now: now)
  end

  test "release returns capacity to the partition state" do
    now = DateTime.utc_now()

    assert {:ok, reservation} =
             Limits.reserve(repo(), PartitionedWorker, %{user_id: 15, cost: 2}, now: now)

    assert {:ok, _released} = Limits.release(repo(), reservation, now: now)

    resource = repo().get_by!(Resource, name: "user-api")
    state = repo().get_by!(State, resource_id: resource.id, partition_key: "15")

    assert state.tokens_used == 0
  end

  # compute_reservation/4 pure-function tests (D-06, T-49-01, T-49-02)

  test "compute_reservation/4: fresh empty state returns {:reserved, weight}" do
    now = DateTime.utc_now()
    resource = build_pure_resource(bucket_capacity: 5)
    state = build_pure_state(tokens_used: 0, now: now)

    assert {:reserved, 1} = Limits.compute_reservation(state, resource, 1, now)
  end

  test "compute_reservation/4: accumulates tokens from 4 to 5 with weight 1" do
    now = DateTime.utc_now()
    resource = build_pure_resource(bucket_capacity: 5)
    state = build_pure_state(tokens_used: 4, now: now)

    assert {:reserved, 5} = Limits.compute_reservation(state, resource, 1, now)
  end

  test "compute_reservation/4: saturated bucket returns {:blocked, limit_reached, retry_at, details}" do
    now = DateTime.utc_now()
    resource = build_pure_resource(bucket_capacity: 5)
    state = build_pure_state(tokens_used: 5, now: now)

    assert {:blocked, "limit_reached", retry_at, details} =
             Limits.compute_reservation(state, resource, 1, now)

    assert %{capacity: 5, used: 5} = details
    assert DateTime.compare(retry_at, now) in [:gt, :eq]
  end

  test "compute_reservation/4: expired bucket normalizes then reserves" do
    now = DateTime.utc_now()
    bucket_started_at = DateTime.add(now, -120_000, :millisecond)
    resource = build_pure_resource(bucket_capacity: 5)
    state = build_pure_state(tokens_used: 5, bucket_started_at: bucket_started_at, now: now)

    assert {:reserved, 1} = Limits.compute_reservation(state, resource, 1, now)
  end

  test "compute_reservation/4: cooldown takes precedence over capacity check" do
    now = DateTime.utc_now()
    cooldown_until = DateTime.add(now, 30, :second)
    resource = build_pure_resource(bucket_capacity: 5)

    state =
      build_pure_state(
        tokens_used: 0,
        cooldown_until: cooldown_until,
        cooldown_reason: "429 backoff",
        now: now
      )

    assert {:blocked, "cooldown", ^cooldown_until, %{reason: "429 backoff"}} =
             Limits.compute_reservation(state, resource, 1, now)
  end

  test "compute_reservation/4: fires ZERO limiter.blocked telemetry events" do
    now = DateTime.utc_now()
    resource = build_pure_resource(bucket_capacity: 2)
    state = build_pure_state(tokens_used: 2, now: now)

    test_pid = self()
    handler_id = "compute-reservation-side-effect-guard-#{System.unique_integer()}"

    :telemetry.attach(
      handler_id,
      [:oban_powertools, :limiter, :blocked],
      fn _event, _measurements, _metadata, _ ->
        send(test_pid, :blocked_telemetry_fired)
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    assert {:blocked, "limit_reached", _retry_at, _details} =
             Limits.compute_reservation(state, resource, 1, now)

    state2 = build_pure_state(tokens_used: 0, now: now)
    assert {:reserved, 1} = Limits.compute_reservation(state2, resource, 1, now)

    refute_received :blocked_telemetry_fired
  end

  defp build_pure_resource(opts \\ []) do
    %Resource{
      id: Ecto.UUID.generate(),
      name: "test-resource",
      scope_kind: "global",
      algorithm: "token_bucket",
      bucket_capacity: Keyword.get(opts, :bucket_capacity, 5),
      bucket_span_ms: Keyword.get(opts, :bucket_span_ms, 60_000),
      default_weight: 1,
      partition_strategy: "global",
      partition_config: %{}
    }
  end

  defp build_pure_state(opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    %State{
      id: Ecto.UUID.generate(),
      resource_id: Ecto.UUID.generate(),
      partition_key: "__global__",
      tokens_used: Keyword.get(opts, :tokens_used, 0),
      bucket_started_at: Keyword.get(opts, :bucket_started_at, now),
      last_reserved_at: nil,
      cooldown_until: Keyword.get(opts, :cooldown_until, nil),
      cooldown_reason: Keyword.get(opts, :cooldown_reason, nil),
      reservation_snapshot: nil
    }
  end

  defp repo, do: ObanPowertools.TestRepo
end
