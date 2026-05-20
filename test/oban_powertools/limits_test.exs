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

  defp repo, do: ObanPowertools.TestRepo
end
