defmodule ObanPowertools.WorkflowRuntimeCommandsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.{CommandAttempt, RecoveryAttempt, RecoverySession, Step}
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord
  alias ObanPowertools.WorkflowFixtures

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

    assert {:error, rejection} =
             Workflow.recover_step(TestRepo, workflow.id, :fetch_customer, :retry,
               actor_id: "ops-1",
               reason: "should fail"
             )

    assert rejection.status == :rejected
    assert rejection.reason_code == "illegal_transition"
    assert rejection.legal_next_steps == ["inspect_step_result"]

    rejected_attempt =
      TestRepo.get_by!(CommandAttempt,
        workflow_id: workflow.id,
        step_id: TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "fetch_customer").id,
        status: "rejected"
      )

    assert rejected_attempt.action == "recover_step:retry"
    assert rejected_attempt.reason_code == "illegal_transition"
    assert rejected_attempt.source == "operator"
  end

  test "legacy workflows are rejected by the command core and leave durable evidence" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "legacy-gated") |> Workflow.insert(TestRepo)

    legacy_workflow =
      workflow
      |> WorkflowRecord.changeset(%{semantics_version: 1})
      |> TestRepo.update!()

    step = TestRepo.get_by!(Step, workflow_id: legacy_workflow.id, step_name: "fetch_customer")

    assert {:error, rejection} =
             Workflow.complete_step(TestRepo, legacy_workflow.id, :fetch_customer,
               status: :completed,
               payload: %{customer_id: 1}
             )

    assert rejection.status == :rejected
    assert rejection.reason_code == "unsupported_legacy_semantics"
    assert rejection.legal_next_steps == ["migrate_via_compatibility_path"]

    attempt =
      TestRepo.get_by!(CommandAttempt,
        workflow_id: legacy_workflow.id,
        step_id: step.id,
        status: "rejected"
      )

    assert attempt.action == "complete_step"
    assert attempt.reason_code == "unsupported_legacy_semantics"
    assert attempt.source == "runtime"
  end

  test "recover_step creates a workflow-scoped recovery session and links the attempt" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "recovery-session") |> Workflow.insert(TestRepo)

    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_billing")

    assert {:ok, _step} =
             Workflow.recover_step(TestRepo, workflow.id, :sync_billing, :retry,
               actor_id: "operator-1",
               reason: "retry upstream billing"
             )

    attempt =
      TestRepo.get_by!(RecoveryAttempt,
        workflow_id: workflow.id,
        step_id: step.id,
        status: "completed"
      )

    session = TestRepo.get!(RecoverySession, attempt.recovery_session_id)

    assert session.workflow_id == workflow.id
    assert session.trigger == "recover_step"
    assert session.reason == "retry upstream billing"
    assert session.actor_id == "operator-1"
  end
end
