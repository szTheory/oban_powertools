defmodule ObanPowertools.WorkflowRuntimeTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.{Await, CallbackOutbox, RecoveryAttempt, Result, SignalRecord}
  alias ObanPowertools.Workflow.Step
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord
  alias ObanPowertools.WorkflowFixtures

  defmodule CallbackHandler do
    @behaviour ObanPowertools.Workflow.CallbackHandler

    def handle_workflow_callback(payload) do
      case :persistent_term.get({__MODULE__, :mode}, :ok) do
        :fail ->
          {:error, :boom}

        :ok ->
          if pid = Process.whereis(:workflow_callback_test) do
            send(pid, {:workflow_callback, payload})
          end

          :ok
      end
    end
  end

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

  test "pre-await signals are stored durably and consumed when the wait is registered" do
    workflow =
      Workflow.new(name: "await-pre-signal")
      |> Workflow.add(:approval, %{worker: "ApprovalWorker", input: %{}, queue: "default"})

    {:ok, workflow} = Workflow.insert(workflow, TestRepo)

    assert {:ok, _signal} =
             Workflow.deliver_signal(TestRepo,
               signal_name: "approval_received",
               correlation_key: workflow.id,
               dedupe_key: "approval-1",
               payload: %{approved_by: "ops"}
             )

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
    assert signal.status == "consumed"
    assert await_row.status == "resolved"
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
  end

  test "cancel requests stay visible even when executing work completes afterwards" do
    workflow =
      Workflow.new(name: "cancel-race")
      |> Workflow.add(:ship, %{worker: "ShipWorker", input: %{}, queue: "default"})

    {:ok, workflow} = Workflow.insert(workflow, TestRepo)
    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "ship")
    TestRepo.update!(Step.changeset(step, %{state: "executing"}))
    TestRepo.update!(WorkflowRecord.changeset(workflow, %{state: "running"}))

    assert {:ok, _workflow} =
             Workflow.request_cancel(TestRepo, workflow.id,
               actor_id: "ops-1",
               reason: "stop requested"
             )

    assert {:ok, _step} =
             Workflow.complete_step(TestRepo, workflow.id, :ship,
               status: :completed,
               payload: %{ok: true}
             )

    persisted_workflow = TestRepo.get!(WorkflowRecord, workflow.id)
    persisted_step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "ship")

    assert not is_nil(persisted_workflow.cancel_requested_at)
    assert persisted_workflow.terminal_cause == "completed_after_cancel_request"
    assert persisted_step.terminal_cause == "completed_after_cancel_request"
  end

  test "lifecycle contract exposes explicit v2 vocabulary and legacy compatibility posture" do
    contract = ObanPowertools.Workflow.Runtime.lifecycle_contract()
    policy = ObanPowertools.Workflow.Runtime.compatibility_policy()

    assert contract.current_semantics_version == 2
    assert "cancel_requested" in contract.workflow_states
    assert "awaiting_signal" in contract.step_states
    assert "completed_after_cancel_request" in contract.workflow_terminal_causes
    assert "cancelled_by_dependency" in contract.step_terminal_causes

    assert policy.new_rows == "default_to_v2"
    assert policy.historical_rows == "retain_stored_meaning_until_v2_transition"
    assert policy.unsupported_behavior == "do_not_silently_reclassify_historical_rows"

    legacy_profile =
      ObanPowertools.Workflow.Runtime.semantics_profile(%WorkflowRecord{
        semantics_version: 1,
        state: "pending",
        workflow_context: %{},
        definition_version: 1,
        name: "legacy"
      })

    current_profile =
      ObanPowertools.Workflow.Runtime.semantics_profile(%WorkflowRecord{
        semantics_version: 2,
        state: "pending",
        workflow_context: %{},
        definition_version: 1,
        name: "current"
      })

    assert legacy_profile.mode == "compatibility_path"
    assert legacy_profile.label == "legacy_v1"
    assert current_profile.mode == "current_contract"
    assert current_profile.label == "v2"
  end

  test "step recovery records durable attempt evidence and refuses completed steps" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "recoverable") |> Workflow.insert(TestRepo)

    assert {:ok, recovered} =
             Workflow.recover_step(TestRepo, workflow.id, :sync_billing, :retry,
               actor_id: "ops-1",
               reason: "dependency repaired"
             )

    attempt = TestRepo.get_by!(RecoveryAttempt, workflow_id: workflow.id, step_id: recovered.id)

    assert recovered.state == "available"
    assert attempt.action == "retry"
    assert attempt.status == "completed"

    assert {:ok, _step} =
             Workflow.complete_step(TestRepo, workflow.id, :fetch_customer,
               status: :completed,
               payload: %{customer_id: 1}
             )

    assert {:error, :already_completed} =
             Workflow.recover_step(TestRepo, workflow.id, :fetch_customer, :retry,
               actor_id: "ops-1",
               reason: "should fail"
             )
  end

  test "terminal callbacks are persisted durably and retried through the outbox" do
    original_handler = Application.get_env(:oban_powertools, :workflow_callback_handler)
    Application.put_env(:oban_powertools, :workflow_callback_handler, CallbackHandler)
    Process.register(self(), :workflow_callback_test)
    :persistent_term.put({CallbackHandler, :mode}, :fail)

    on_exit(fn ->
      Application.put_env(:oban_powertools, :workflow_callback_handler, original_handler)
      :persistent_term.erase({CallbackHandler, :mode})

      if Process.whereis(:workflow_callback_test) == self() do
        Process.unregister(:workflow_callback_test)
      end
    end)

    workflow =
      Workflow.new(name: "callback-terminal")
      |> Workflow.add(:ship, %{worker: "ShipWorker", input: %{}, queue: "default"})

    {:ok, workflow} = Workflow.insert(workflow, TestRepo)

    assert {:ok, _step} =
             Workflow.complete_step(TestRepo, workflow.id, :ship,
               status: :completed,
               payload: %{ok: true}
             )

    outbox =
      TestRepo.get_by!(CallbackOutbox, workflow_id: workflow.id, event: "workflow.terminal")

    assert outbox.status == "pending"

    assert %{failed: 1, delivered: 0} = Workflow.dispatch_callbacks(TestRepo)
    failed = TestRepo.get!(CallbackOutbox, outbox.id)
    assert failed.status == "failed"
    assert failed.attempts == 1

    :persistent_term.put({CallbackHandler, :mode}, :ok)

    assert %{failed: 0, delivered: 1} =
             Workflow.dispatch_callbacks(TestRepo,
               now: DateTime.add(DateTime.utc_now(), 31, :second)
             )

    delivered = TestRepo.get!(CallbackOutbox, outbox.id)
    workflow_id = workflow.id

    assert delivered.status == "delivered"
    assert delivered.attempts == 2
    assert_receive {:workflow_callback, %{"workflow_id" => ^workflow_id, "state" => "completed"}}
  end
end
