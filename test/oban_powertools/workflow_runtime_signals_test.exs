defmodule ObanPowertools.WorkflowRuntimeSignalsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.{Await, CommandAttempt, SignalRecord, Step}
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord

  test "pre-await signals are stored durably and consumed when the wait is registered" do
    workflow =
      Workflow.new(name: "await-pre-signal")
      |> Workflow.add(:approval, %{worker: "ApprovalWorker", input: %{}, queue: "default"})

    {:ok, workflow} = Workflow.insert(workflow, TestRepo)

    assert {:ok, signal} =
             Workflow.deliver_signal(TestRepo,
               signal_name: "approval_received",
               correlation_key: workflow.id,
               dedupe_key: "approval-1",
               payload: %{approved_by: "ops"}
             )

    assert signal.status == "unmatched"
    assert is_nil(signal.workflow_id)

    assert {:ok, _await} =
             Workflow.await_step(TestRepo, workflow.id, :approval,
               signal_name: "approval_received",
               correlation_key: workflow.id,
               dedupe_key: "approval-1"
             )

    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "approval")
    signal = TestRepo.get_by!(SignalRecord, dedupe_key: "approval-1")
    await_row = TestRepo.get_by!(Await, workflow_id: workflow.id, step_id: step.id)

    assert step.state == "available"
    assert is_nil(step.active_await_id)
    assert signal.status == "consumed"
    assert signal.workflow_id == workflow.id
    assert await_row.status == "resolved"
    assert await_row.resolved_signal_id == signal.id
  end

  test "await registration keeps a thin step mirror with an active await pointer" do
    workflow =
      Workflow.new(name: "await-pointer")
      |> Workflow.add(:approval, %{worker: "ApprovalWorker", input: %{}, queue: "default"})

    {:ok, workflow} = Workflow.insert(workflow, TestRepo)

    assert {:ok, _await} =
             Workflow.await_step(TestRepo, workflow.id, :approval,
               signal_name: "approval_received",
               correlation_key: workflow.id,
               dedupe_key: "approval-pointer"
             )

    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "approval")
    await_row = TestRepo.get_by!(Await, workflow_id: workflow.id, step_id: step.id)

    assert step.state == "awaiting_signal"
    assert step.active_await_id == await_row.id
    assert step.awaiting_signal_name == "approval_received"
    assert step.await_correlation_key == workflow.id
    assert step.await_dedupe_key == "approval-pointer"
  end

  test "ambiguous correlation-only signals stay durable evidence and do not wake waits" do
    workflow_a =
      Workflow.new(name: "await-ambiguous-a")
      |> Workflow.add(:approval, %{worker: "ApprovalWorker", input: %{}, queue: "default"})

    workflow_b =
      Workflow.new(name: "await-ambiguous-b")
      |> Workflow.add(:approval, %{worker: "ApprovalWorker", input: %{}, queue: "default"})

    {:ok, workflow_a} = Workflow.insert(workflow_a, TestRepo)
    {:ok, workflow_b} = Workflow.insert(workflow_b, TestRepo)

    for workflow <- [workflow_a, workflow_b] do
      assert {:ok, _await} =
               Workflow.await_step(TestRepo, workflow.id, :approval,
                 signal_name: "approval_received",
                 correlation_key: "shared-correlation",
                 dedupe_key: "#{workflow.id}-approval"
               )
    end

    assert {:ok, signal} =
             Workflow.deliver_signal(TestRepo,
               signal_name: "approval_received",
               correlation_key: "shared-correlation",
               dedupe_key: "shared-signal",
               payload: %{approved_by: "ops"}
             )

    assert signal.status == "ambiguous"
    assert is_nil(signal.workflow_id)

    for workflow <- [workflow_a, workflow_b] do
      step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "approval")
      await_row = TestRepo.get_by!(Await, workflow_id: workflow.id, step_id: step.id)

      assert step.state == "awaiting_signal"
      assert step.active_await_id == await_row.id
      assert await_row.status == "waiting"
    end
  end

  test "duplicate and already-consumed signal attempts remain durable evidence" do
    workflow =
      Workflow.new(name: "await-duplicate-evidence")
      |> Workflow.add(:approval, %{worker: "ApprovalWorker", input: %{}, queue: "default"})

    {:ok, workflow} = Workflow.insert(workflow, TestRepo)

    assert {:ok, signal} =
             Workflow.deliver_signal(TestRepo,
               signal_name: "approval_received",
               correlation_key: workflow.id,
               dedupe_key: "approval-duplicate",
               payload: %{approved_by: "ops"}
             )

    assert signal.status == "unmatched"

    assert {:ok, replayed_unmatched} =
             Workflow.deliver_signal(TestRepo,
               signal_name: "approval_received",
               correlation_key: workflow.id,
               dedupe_key: "approval-duplicate",
               payload: %{approved_by: "ops"}
             )

    assert replayed_unmatched.id == signal.id

    duplicate_attempt =
      TestRepo.get_by!(CommandAttempt,
        signal_record_id: signal.id,
        status: "duplicate",
        reason_code: "duplicate_signal"
      )

    assert duplicate_attempt.action == "deliver_signal"

    assert {:ok, _await} =
             Workflow.await_step(TestRepo, workflow.id, :approval,
               signal_name: "approval_received",
               correlation_key: workflow.id,
               dedupe_key: "approval-duplicate"
             )

    assert {:ok, replayed_consumed} =
             Workflow.deliver_signal(TestRepo,
               signal_name: "approval_received",
               correlation_key: workflow.id,
               dedupe_key: "approval-duplicate",
               payload: %{approved_by: "ops"}
             )

    assert replayed_consumed.id == signal.id

    consumed_attempt =
      TestRepo.get_by!(CommandAttempt,
        signal_record_id: signal.id,
        status: "already_consumed",
        reason_code: "already_consumed_signal"
      )

    assert consumed_attempt.action == "deliver_signal"
  end

  test "expired waits remain durable and late signals are marked late" do
    now = DateTime.utc_now()

    workflow =
      Workflow.new(name: "await-expiry")
      |> Workflow.add(:approval, %{worker: "ApprovalWorker", input: %{}, queue: "default"})

    {:ok, workflow} = Workflow.insert(workflow, TestRepo)

    assert {:ok, _await} =
             Workflow.await_step(TestRepo, workflow.id, :approval,
               signal_name: "approval_received",
               correlation_key: workflow.id,
               dedupe_key: "approval-expired",
               registered_at: now,
               deadline_at: DateTime.add(now, -5, :second)
             )

    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "approval")
    persisted_workflow = TestRepo.get!(WorkflowRecord, workflow.id)

    assert step.state == "expired"
    assert step.terminal_cause == "expired_wait"
    assert persisted_workflow.state == "expired"

    assert {:ok, signal} =
             Workflow.deliver_signal(TestRepo,
               signal_name: "approval_received",
               correlation_key: workflow.id,
               dedupe_key: "approval-expired",
               payload: %{approved_by: "ops"}
             )

    assert signal.status == "late"
    assert signal.workflow_id == workflow.id

    assert {:ok, _steps} =
             ObanPowertools.Workflow.Runtime.reconcile_workflow(TestRepo, workflow.id)

    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "approval")
    signal = TestRepo.get_by!(SignalRecord, dedupe_key: "approval-expired")

    assert step.state == "expired"
    assert is_nil(step.active_await_id)
    assert signal.status == "late"
  end

  test "row-only reconcile consumes authoritative signal facts without advisory wakeups" do
    workflow =
      Workflow.new(name: "await-row-only-reconcile")
      |> Workflow.add(:approval, %{worker: "ApprovalWorker", input: %{}, queue: "default"})

    {:ok, workflow} = Workflow.insert(workflow, TestRepo)

    assert {:ok, _await} =
             Workflow.await_step(TestRepo, workflow.id, :approval,
               signal_name: "approval_received",
               correlation_key: workflow.id,
               dedupe_key: "approval-row-only"
             )

    await_row = TestRepo.get_by!(Await, workflow_id: workflow.id)

    signal =
      TestRepo.insert!(
        SignalRecord.changeset(%SignalRecord{}, %{
          workflow_id: workflow.id,
          signal_name: "approval_received",
          correlation_key: workflow.id,
          dedupe_key: "approval-row-only-manual",
          status: "recorded",
          payload: %{"approved_by" => "ops"},
          received_at: DateTime.utc_now()
        })
      )

    assert {:ok, _steps} =
             ObanPowertools.Workflow.Runtime.reconcile_workflow(TestRepo, workflow.id)

    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "approval")
    signal = TestRepo.get!(SignalRecord, signal.id)
    await_row = TestRepo.get!(Await, await_row.id)

    assert step.state == "available"
    assert is_nil(step.active_await_id)
    assert signal.status == "consumed"
    assert signal.await_id == await_row.id
    assert await_row.status == "resolved"
  end
end
