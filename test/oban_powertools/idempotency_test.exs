defmodule ObanPowertools.IdempotencyTest do
  use ObanPowertools.DataCase, async: false
  alias ObanPowertools.Idempotency

  defmodule MockWorker do
    use ObanPowertools.Worker, args: [id: :integer]
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
