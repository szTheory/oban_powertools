defmodule ObanPowertools.WorkflowCoordinatorTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.{Audit, Workflow}
  alias ObanPowertools.Workflow.{Result, Step}
  alias ObanPowertools.WorkflowFixtures

  setup do
    test_pid = self()
    Ecto.Adapters.SQL.Sandbox.allow(TestRepo, self(), Process.whereis(ObanPowertools.Workflow.Coordinator))

    :telemetry.attach_many(
      "workflow-coordinator-test",
      [
        [:oban_powertools, :workflow, :step_completed],
        [:oban_powertools, :workflow, :step_unblocked],
        [:oban_powertools, :workflow, :cascade_cancelled],
        [:oban_powertools, :workflow, :workflow_completed]
      ],
      fn name, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach("workflow-coordinator-test") end)
    :ok
  end

  test "duplicate PubSub delivery does not duplicate child release or results" do
    {:ok, workflow} = WorkflowFixtures.workflow_fixture() |> Workflow.insert(TestRepo)

    assert {:ok, fetch_step} =
             Workflow.complete_step(TestRepo, workflow.id, :fetch_customer,
               status: :completed,
               payload: %{customer_id: 1}
             )

    assert :ok =
             ObanPowertools.Workflow.Signal.broadcast(
               ObanPowertools.Workflow.Signal.step_completed(workflow.id, :fetch_customer)
             )

    assert :ok =
             ObanPowertools.Workflow.Signal.broadcast(
               ObanPowertools.Workflow.Signal.step_completed(workflow.id, :fetch_customer)
             )

    Process.sleep(20)

    assert TestRepo.aggregate(Result, :count, :id) == 1
    assert TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_billing").state == "available"
    assert TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_support").state == "available"

    assert_receive {:telemetry_event, [:oban_powertools, :workflow, :step_completed], %{count: 1}, %{status: "completed"}}
    assert_receive {:telemetry_event, [:oban_powertools, :workflow, :step_unblocked], %{count: 1}, %{status: "available"}}

    [event | _] = Audit.list(%{type: :workflow_step, id: fetch_step.id}, repo: TestRepo)
    assert event.action == "workflow.step_completed"
  end

  test "db-first runtime remains correct even if no PubSub follow-up is observed" do
    {:ok, workflow} = WorkflowFixtures.workflow_fixture() |> Workflow.insert(TestRepo)

    assert {:ok, _step} =
             Workflow.complete_step(TestRepo, workflow.id, :fetch_customer,
               status: :completed,
               payload: %{customer_id: 1}
             )

    assert TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_billing").state == "available"
    assert TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_support").state == "available"
    assert TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "notify").state == "pending"
  end
end
