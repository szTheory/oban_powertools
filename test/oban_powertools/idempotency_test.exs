defmodule ObanPowertools.IdempotencyTest do
  use ObanPowertools.DataCase, async: false
  alias ObanPowertools.Idempotency

  defmodule MockWorker do
    use ObanPowertools.Worker, args: [id: :integer]
    @impl true
    def process(_), do: :ok
  end

  defmodule DeadlineWorker do
    use ObanPowertools.Worker,
      args: [id: :integer],
      deadline: :timer.hours(24)

    @impl true
    def process(_), do: :ok
  end

  defmodule LimitedDeadlineWorker do
    use ObanPowertools.Worker,
      args: [id: :integer],
      deadline: :timer.hours(24),
      limits: [
        name: "deadline-worker",
        scope: :partitioned,
        partition_by: {:args, :id},
        bucket_capacity: 10,
        bucket_span_ms: 60_000
      ]

    @impl true
    def process(_), do: :ok
  end

  test "enqueue/2 inserts job and receipt" do
    assert {:ok, job} = MockWorker.enqueue(%{id: 123})
    assert job.worker == "ObanPowertools.IdempotencyTest.MockWorker"
    assert job.args == %{id: 123}

    # Verify receipt exists
    assert repo().get_by(Idempotency.Receipt, worker: inspect(MockWorker), job_id: job.id)
  end

  test "enqueue/2 returns conflict on duplicate" do
    assert {:ok, job1} = MockWorker.enqueue(%{id: 456})
    assert {:conflict, job2} = MockWorker.enqueue(%{id: 456})

    assert job1.id == job2.id
  end

  test "deadline worker writes top-level deadline meta at enqueue time" do
    assert {:ok, job} =
             DeadlineWorker.enqueue(%{id: 100}, now: ~U[2026-06-12 12:00:00Z])

    assert job.meta["__deadline_at__"] == "2026-06-13T12:00:00Z"
  end

  test "deadline meta preserves caller meta while reserved key wins" do
    assert {:ok, job} =
             DeadlineWorker.enqueue(%{id: 101},
               now: ~U[2026-06-12 12:00:00Z],
               meta: %{"source" => "host", "__deadline_at__" => "1999-01-01T00:00:00Z"}
             )

    assert job.meta["source"] == "host"
    assert job.meta["__deadline_at__"] == "2026-06-13T12:00:00Z"
  end

  test "deadline timestamp is not part of duplicate fingerprint" do
    assert {:ok, job1} =
             DeadlineWorker.enqueue(%{id: 102}, now: ~U[2026-06-12 12:00:00Z])

    assert {:conflict, job2} =
             DeadlineWorker.enqueue(%{id: 102}, now: ~U[2026-06-13 12:00:00Z])

    assert job1.id == job2.id
    assert job2.meta["__deadline_at__"] == "2026-06-13T12:00:00Z"
  end

  test "deadline metadata coexists with limiter and idempotency meta" do
    assert {:ok, job} =
             LimitedDeadlineWorker.enqueue(%{id: 103}, now: ~U[2026-06-12 12:00:00Z])

    assert job.meta["__deadline_at__"] == "2026-06-13T12:00:00Z"
    assert job.meta["oban_powertools"]["idempotency_fingerprint"]
    assert job.meta["oban_powertools"]["limits"]["resource"] == "deadline-worker"
  end

  test "enqueue/2 returns error on invalid args" do
    assert {:error, %Ecto.Changeset{}} = MockWorker.enqueue(%{id: "not-int"})
  end

  test "fingerprints are stable across map key ordering" do
    assert {:ok, job1} = MockWorker.enqueue(%{id: 789})
    assert {:conflict, job2} = Idempotency.transaction(MockWorker, %{id: 789})

    assert job1.id == job2.id
  end

  defp repo, do: ObanPowertools.TestRepo
end
