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

    :telemetry.attach(handler_id_execute, [:oban_powertools, :lifeline, :repair_executed], fn _event, _measurements, metadata, _config ->
      send(parent, {:execute_telemetry, metadata})
    end, nil)

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
