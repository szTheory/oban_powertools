defmodule ObanPowertools.WorkflowCompatibilityTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Workflow.Runtime
  alias ObanPowertools.Workflow.{RecoveryAttempt, RecoverySession, Step}
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord
  alias ObanPowertools.WorkflowFixtures

  test "legacy waiting rows stay explainable on the compatibility path" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "legacy-waiting")
      |> ObanPowertools.Workflow.insert(TestRepo)

    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_billing")

    legacy_workflow =
      workflow
      |> WorkflowRecord.changeset(%{semantics_version: 1, state: "pending"})
      |> TestRepo.update!()

    legacy_step =
      step
      |> Step.changeset(%{
        state: "awaiting_signal",
        blocker_codes: ["waiting_on_signal"],
        awaiting_signal_name: "approval_received"
      })
      |> TestRepo.update!()

    assert Runtime.semantics_profile(legacy_workflow).mode == "compatibility_path"
    assert Runtime.workflow_diagnosis(legacy_workflow, [legacy_step]) == "waiting_on_signal"
  end

  test "legacy retryable rows preserve cancel-request evidence without reclassification" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "legacy-cancel-requested")
      |> ObanPowertools.Workflow.insert(TestRepo)

    legacy_workflow =
      workflow
      |> WorkflowRecord.changeset(%{
        semantics_version: 1,
        state: "running",
        cancel_requested_at: DateTime.utc_now()
      })
      |> TestRepo.update!()

    legacy_step =
      TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_billing")
      |> Step.changeset(%{
        state: "retryable",
        blocker_codes: ["cancel_requested"],
        cancel_requested_at: DateTime.utc_now()
      })
      |> TestRepo.update!()

    assert Runtime.semantics_profile(legacy_workflow).label == "legacy_v1"
    assert Runtime.workflow_diagnosis(legacy_workflow, [legacy_step]) == "cancel_requested"
    assert Runtime.step_diagnosis(legacy_step) == "cancel_requested"
  end

  test "legacy cancelled rows keep stored terminal meaning available to support" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "legacy-cancelled")
      |> ObanPowertools.Workflow.insert(TestRepo)

    legacy_workflow =
      workflow
      |> WorkflowRecord.changeset(%{
        semantics_version: 1,
        state: "cancelled",
        terminal_cause: "operator_cancelled"
      })
      |> TestRepo.update!()

    legacy_step =
      TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_billing")
      |> Step.changeset(%{
        state: "cancelled",
        blocker_codes: ["cancel_requested"],
        terminal_cause: "operator_cancelled"
      })
      |> TestRepo.update!()

    assert Runtime.workflow_diagnosis(legacy_workflow, [legacy_step]) == "operator_cancelled"
    assert Runtime.step_diagnosis(legacy_step) == "cancel_requested"
  end

  test "legacy recovery evidence remains repo-local proof instead of host-lane support" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "legacy-recovery")
      |> ObanPowertools.Workflow.insert(TestRepo)

    legacy_workflow =
      workflow
      |> WorkflowRecord.changeset(%{semantics_version: 1})
      |> TestRepo.update!()

    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_billing")

    session =
      TestRepo.insert!(
        RecoverySession.changeset(%RecoverySession{}, %{
          workflow_id: legacy_workflow.id,
          status: "completed",
          trigger: "recover_step",
          reason: "legacy repair",
          actor_id: "ops-1",
          requested_at: DateTime.utc_now(),
          completed_at: DateTime.utc_now(),
          metadata: %{"action" => "retry", "step_name" => step.step_name}
        })
      )

    attempt =
      TestRepo.insert!(
        RecoveryAttempt.changeset(%RecoveryAttempt{}, %{
          workflow_id: legacy_workflow.id,
          step_id: step.id,
          recovery_session_id: session.id,
          scope: "step",
          action: "retry",
          status: "completed",
          reason: "legacy repair",
          actor_id: "ops-1",
          requested_at: DateTime.utc_now(),
          completed_at: DateTime.utc_now(),
          before_snapshot: %{"state" => "retryable"},
          after_snapshot: %{"state" => "available"},
          metadata: %{}
        })
      )

    assert Runtime.semantics_profile(legacy_workflow).mode == "compatibility_path"
    assert attempt.recovery_session_id == session.id
  end
end
