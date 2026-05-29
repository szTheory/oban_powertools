defmodule ObanPowertools.OperatorTest do
  use ObanPowertools.DataCase, async: false

  alias Ecto.Changeset
  alias ObanPowertools.Operator

  setup do
    Application.delete_env(:oban_powertools, :host_escalation_handler)
    :ok
  end

  test "retry_job mutates the job and emits telemetry with source: api" do
    job = insert_job!("executing")
    actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

    parent = self()
    handler_id_execute = "test-execute-handler-#{System.unique_integer()}"

    :telemetry.attach(
      handler_id_execute,
      [:oban_powertools, :lifeline, :repair_executed],
      fn _event, _measurements, metadata, _config ->
        send(parent, {:execute_telemetry, metadata})
      end,
      nil
    )

    assert {:ok, %{target: repaired_job}} =
             Operator.retry_job(repo(), actor, job.id, "Retrying job via API")

    assert repaired_job.state == "available"

    assert_receive {:execute_telemetry, execute_metadata}
    assert execute_metadata.source == "api"
    assert execute_metadata.action == "job_retry"
    assert execute_metadata.target_type == "job"

    :telemetry.detach(handler_id_execute)
  end

  test "cancel_job mutates the job and works properly" do
    job = insert_job!("executing")
    actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

    assert {:ok, %{target: cancelled_job}} =
             Operator.cancel_job(repo(), actor, job.id, "Cancelling job via API")

    assert cancelled_job.state == "cancelled"
  end

  test "discard_job mutates the job and works properly" do
    job = insert_job!("executing")
    actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

    assert {:ok, %{target: discarded_job}} =
             Operator.discard_job(repo(), actor, job.id, "Discarding job via API")

    assert discarded_job.state == "discarded"
  end

  test "invalid operations return the underlying Lifeline errors" do
    job = insert_job!("executing")
    actor = %{id: "operator-unauthorized", permissions: []}

    assert {:error, :unauthorized} =
             Operator.retry_job(repo(), actor, job.id, "Unauthorized attempt")

    # Try with empty reason
    actor2 = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

    assert {:error, :reason_required} =
             Operator.retry_job(repo(), actor2, job.id, "   ")
  end

  describe "bulk operations" do
    setup do
      actor = %{id: "operator-bulk", permissions: [:preview_repair, :execute_repair]}
      %{actor: actor}
    end

    test "bulk_retry_jobs succeeds for valid jobs and fails for invalid ones", %{actor: actor} do
      # Valid for retry
      job1 = insert_job!("executing")
      job2 = insert_job!("retryable")

      result = Operator.bulk_retry_jobs(repo(), actor, [job1.id, job2.id, -1], "Bulk retry")

      assert length(result.successes) == 2
      assert job1.id in result.successes
      assert job2.id in result.successes

      assert length(result.failures) == 1
      assert Enum.any?(result.failures, fn {id, err} -> id == -1 and err == :not_found end)
    end

    test "bulk_cancel_jobs processes a batch independently", %{actor: actor} do
      job1 = insert_job!("executing")
      job2 = insert_job!("available")

      result = Operator.bulk_cancel_jobs(repo(), actor, [job1.id, job2.id, -1], "Bulk cancel")

      assert length(result.successes) == 2
      assert Enum.sort(result.successes) == Enum.sort([job1.id, job2.id])

      assert length(result.failures) == 1
      assert [{-1, :not_found}] = result.failures
    end

    test "bulk_discard_jobs works with mixed results", %{actor: actor} do
      job1 = insert_job!("retryable")
      job2 = insert_job!("executing")

      result = Operator.bulk_discard_jobs(repo(), actor, [job1.id, -1, job2.id], "Bulk discard")

      assert length(result.successes) == 2
      assert job1.id in result.successes
      assert job2.id in result.successes

      assert length(result.failures) == 1
      assert [{id, err}] = result.failures
      assert id == -1
      assert err == :not_found
    end
  end

  defp insert_job!(state) do
    %{}
    |> Oban.Job.new(
      worker: "Example.Worker",
      queue: :default,
      meta: %{"executor_id" => "some-executor"}
    )
    |> Changeset.change(state: state)
    |> repo().insert!()
  end

  defp repo, do: ObanPowertools.TestRepo
end
