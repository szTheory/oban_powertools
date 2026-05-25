defmodule ObanPowertools.WorkflowRuntimeTransitionsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.{Result, Step}
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord
  alias ObanPowertools.WorkflowFixtures

  test "completing a step persists a result and releases runnable children" do
    {:ok, workflow} = WorkflowFixtures.workflow_fixture() |> Workflow.insert(TestRepo)

    assert {:ok, _step} =
             Workflow.complete_step(TestRepo, workflow.id, :fetch_customer,
               status: :completed,
               payload: %{customer_id: 1}
             )

    fetch = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "fetch_customer")
    billing = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_billing")
    support = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_support")
    notify = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "notify")
    persisted_workflow = TestRepo.get!(WorkflowRecord, workflow.id)

    assert fetch.state == "completed"
    assert billing.state == "available"
    assert support.state == "available"
    assert notify.state == "pending"
    assert persisted_workflow.runnable_step_count == 2
    assert persisted_workflow.completed_step_count == 1

    assert %Result{status: "completed", payload: %{"customer_id" => 1}} =
             TestRepo.get_by!(Result, workflow_id: workflow.id, step_id: fetch.id)
  end

  test "retryable upstream work keeps descendants blocked" do
    {:ok, workflow} = WorkflowFixtures.workflow_fixture() |> Workflow.insert(TestRepo)

    assert {:ok, _step} =
             Workflow.complete_step(TestRepo, workflow.id, :fetch_customer,
               status: :retryable,
               payload: %{reason: "network"}
             )

    billing = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_billing")

    assert billing.state == "pending"
    assert billing.blocker_codes == ["waiting_on_retryable_dependency"]
  end

  test "terminal failures cascade-cancel by default but explicit continue edges still unblock cleanup work" do
    workflow =
      Workflow.new(name: "cleanup_flow")
      |> Workflow.add(:fetch, ObanPowertools.WorkflowFixtures.fetch_customer_job(1))
      |> Workflow.add(:cleanup, ObanPowertools.WorkflowFixtures.sync_support_job(1))
      |> Workflow.add(
        :notify,
        %{worker: "NotifyWorker", input: %{"reason" => Workflow.result(:fetch)}, queue: "default"}
      )
      |> Workflow.connect(:fetch, :cleanup, policy: :continue)
      |> Workflow.connect(:fetch, :notify)

    {:ok, workflow} = Workflow.insert(workflow, TestRepo)

    assert {:ok, _step} =
             Workflow.complete_step(TestRepo, workflow.id, :fetch,
               status: :cancelled,
               payload: %{reason: "upstream failed"}
             )

    cleanup = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "cleanup")
    notify = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "notify")

    assert cleanup.state == "available"
    assert notify.state == "cancelled"
    assert notify.blocker_codes == ["cancelled_by_dependency"]
  end
end
