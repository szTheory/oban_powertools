defmodule WorkflowTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.Edge
  alias ObanPowertools.Workflow.Step
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord
  alias ObanPowertools.WorkflowFixtures
  alias ObanPowertools.WorkflowTestWorkers.FetchCustomerWorker

  test "builder-authored workflows persist through one normalized insert path" do
    workflow = WorkflowFixtures.workflow_fixture()

    assert {:ok, %WorkflowRecord{} = persisted} = Workflow.insert(workflow, TestRepo)

    assert persisted.name == "sync_customer"
    assert persisted.state == "available"
    assert persisted.step_count == 4
    assert persisted.runnable_step_count == 1
    assert persisted.workflow_context["account_id"] == 123

    steps =
      TestRepo.all(from(step in Step, where: step.workflow_id == ^persisted.id, order_by: step.position))

    assert Enum.map(steps, & &1.step_name) == [
             "fetch_customer",
             "sync_billing",
             "sync_support",
             "notify"
           ]

    assert Enum.map(steps, & &1.position) == [0, 1, 2, 3]
    assert Enum.map(steps, & &1.state) == ["available", "pending", "pending", "pending"]

    sync_billing = Enum.find(steps, &(&1.step_name == "sync_billing"))
    notify = Enum.find(steps, &(&1.step_name == "notify"))

    assert sync_billing.input["customer"] == %{"$result" => "fetch_customer"}
    assert notify.input["billing"] == %{"$result" => "sync_billing"}
    assert notify.input["support"] == %{"$result" => "sync_support"}
    assert notify.dependency_snapshot["dependencies"] == ["sync_billing", "sync_support"]
    assert notify.blocker_codes == ["waiting_on_dependencies"]

    edges =
      TestRepo.all(
        from(edge in Edge,
          where: edge.workflow_id == ^persisted.id,
          order_by: [asc: edge.from_step_id, asc: edge.to_step_id]
        )
      )

    assert length(edges) == 4
    assert Enum.all?(edges, &(&1.policy == "cancel"))
  end

  test "raw workflow structs normalize through the same insert path" do
    workflow = %Workflow{
      name: "raw_import",
      workflow_context: %{"source" => "fixture"},
      steps: [
        %{name: :fetch, worker: "FetchWorker", input: %{"id" => 1}, context: %{}, queue: "default"},
        %{name: :deliver, worker: "DeliverWorker", input: %{"fetch" => Workflow.result(:fetch)}, context: %{}, queue: "default"}
      ],
      edges: [%{from: :fetch, to: :deliver, policy: :cancel}]
    }

    assert {:ok, %WorkflowRecord{} = persisted} = Workflow.insert(workflow, TestRepo)
    assert persisted.name == "raw_import"
    assert persisted.step_count == 2
    assert persisted.runnable_step_count == 1
  end

  test "insert rejects duplicate step names" do
    workflow =
      Workflow.new(name: "duplicate_names")
      |> Workflow.add(:fetch, FetchCustomerWorker.new(%{"account_id" => 1}))
      |> Workflow.add(:fetch, FetchCustomerWorker.new(%{"account_id" => 2}))

    assert {:error, {:validation, {:duplicate_step_name, "fetch"}}} =
             Workflow.insert(workflow, TestRepo)
  end

  test "insert rejects missing dependencies and orphan edges" do
    workflow =
      Workflow.new(name: "missing_dependency")
      |> Workflow.add(:fetch, FetchCustomerWorker.new(%{"account_id" => 1}))
      |> Workflow.connect(:fetch, :notify)

    assert {:error, {:validation, {:missing_dependency, %{from: "fetch", to: "notify", policy: "cancel"}}}} =
             Workflow.insert(workflow, TestRepo)
  end

  test "insert rejects self-loops" do
    workflow =
      Workflow.new(name: "self_loop")
      |> Workflow.add(:fetch, FetchCustomerWorker.new(%{"account_id" => 1}))
      |> Workflow.connect(:fetch, :fetch)

    assert {:error, {:validation, {:self_loop, "fetch"}}} = Workflow.insert(workflow, TestRepo)
  end

  test "rejects cycles before persistence" do
    workflow =
      Workflow.new(name: "cycle")
      |> Workflow.add(:a, FetchCustomerWorker.new(%{"account_id" => 1}), deps: [:c])
      |> Workflow.add(:b, FetchCustomerWorker.new(%{"account_id" => 2}), deps: [:a])
      |> Workflow.add(:c, FetchCustomerWorker.new(%{"account_id" => 3}), deps: [:b])

    assert {:error, {:validation, {:cycle_detected, _node}}} = Workflow.insert(workflow, TestRepo)
    assert TestRepo.aggregate(WorkflowRecord, :count, :id) == 0
  end
end
