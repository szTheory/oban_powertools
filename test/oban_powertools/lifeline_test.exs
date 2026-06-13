defmodule ObanPowertools.LifelineHostEscalationOkTestHandler do
  @behaviour ObanPowertools.HostEscalationHandler

  @impl true
  def handle_escalation(_event_facts), do: :ok
end

defmodule ObanPowertools.LifelineHostEscalationFailTestHandler do
  @behaviour ObanPowertools.HostEscalationHandler

  @impl true
  def handle_escalation(_event_facts), do: {:error, :host_callback_failed}
end

defmodule ObanPowertools.LifelineTest do
  use ObanPowertools.DataCase, async: false

  alias Ecto.Changeset
  alias ObanPowertools.Audit
  alias ObanPowertools.{JobRecord, Lifeline}
  alias ObanPowertools.Lifeline.{ArchiveRun, Heartbeat, Incident}
  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.{CommandAttempt, Step}
  alias ObanPowertools.WorkflowFixtures

  setup do
    original_handler = Application.get_env(:oban_powertools, :host_escalation_handler)

    on_exit(fn ->
      Application.put_env(:oban_powertools, :host_escalation_handler, original_handler)
    end)

    :ok
  end

  test "refresh_heartbeats upserts one durable row per executor identity" do
    now = DateTime.utc_now()

    assert {:ok, [%Heartbeat{} = first]} =
             Lifeline.refresh_heartbeats(
               repo(),
               [
                 %{
                   executor_id: "app:oban:default:node-a:producer-1",
                   node: "node-a",
                   producer_scope: "producer-1"
                 }
               ],
               now: now
             )

    later = DateTime.add(now, 30, :second)

    assert {:ok, [%Heartbeat{} = second]} =
             Lifeline.refresh_heartbeats(
               repo(),
               [
                 %{
                   executor_id: "app:oban:default:node-a:producer-1",
                   node: "node-a",
                   producer_scope: "producer-1"
                 }
               ],
               now: later
             )

    assert first.id == second.id
    assert repo().aggregate(Heartbeat, :count, :id) == 1
    assert DateTime.compare(second.last_heartbeat_at, later) == :eq
  end

  test "list_executor_health classifies healthy, late, and missing executors" do
    now = DateTime.utc_now()

    insert_heartbeat!("executor-healthy", DateTime.add(now, -10, :second))
    insert_heartbeat!("executor-late", DateTime.add(now, -60, :second))
    insert_heartbeat!("executor-missing", DateTime.add(now, -180, :second))

    health =
      Lifeline.list_executor_health(repo(), now: now)
      |> Map.new(&{&1.executor_id, &1.health_label})

    assert health["executor-healthy"] == "Healthy"
    assert health["executor-late"] == "Heartbeat Late"
    assert health["executor-missing"] == "Executor Missing"
  end

  test "late executors do not project dead_executor incidents but missing executors do" do
    now = DateTime.utc_now()
    insert_heartbeat!("executor-late", DateTime.add(now, -60, :second))
    insert_heartbeat!("executor-missing", DateTime.add(now, -180, :second))

    insert_executing_job!("executor-missing")

    incidents = Lifeline.project_incidents(repo(), now: now)

    refute Enum.any?(incidents, &(&1.executor_id == "executor-late"))

    assert %Incident{} =
             Enum.find(
               incidents,
               &(&1.executor_id == "executor-missing" and &1.incident_class == "dead_executor")
             )
  end

  test "project_incidents resolves repaired dead executor incidents on reprojection and reuses the same row on reopen" do
    now = DateTime.utc_now()
    insert_heartbeat!("executor-missing", DateTime.add(now, -180, :second))
    job = insert_executing_job!("executor-missing")

    [incident] =
      Lifeline.project_incidents(repo(), now: now)
      |> Enum.filter(&(&1.incident_class == "dead_executor"))

    repo().update!(Ecto.Changeset.change(job, state: "available"))

    refute Enum.any?(
             Lifeline.project_incidents(repo(), now: DateTime.add(now, 5, :second)),
             &(&1.incident_fingerprint == incident.incident_fingerprint)
           )

    resolved = repo().get!(Incident, incident.id)
    assert resolved.status == "resolved"
    assert resolved.resolved_at

    insert_executing_job!("executor-missing")

    [reopened] =
      Lifeline.project_incidents(repo(), now: DateTime.add(now, 10, :second))
      |> Enum.filter(&(&1.incident_class == "dead_executor"))

    assert reopened.id == incident.id
    assert reopened.first_detected_at == incident.first_detected_at
    assert is_nil(reopened.resolved_at)
  end

  test "dead executor incidents carry affected job counts from persisted evidence" do
    now = DateTime.utc_now()
    insert_heartbeat!("executor-missing", DateTime.add(now, -180, :second))
    insert_executing_job!("executor-missing")
    insert_executing_job!("executor-missing")

    [incident] =
      Lifeline.project_incidents(repo(), now: now)
      |> Enum.filter(&(&1.incident_class == "dead_executor"))

    assert incident.affected_counts["jobs"] == 2
    assert incident.summary =~ "Executor Missing"
  end

  test "workflow stuck incidents surface durable evidence before any repair preview is requested" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "stuck-flow") |> Workflow.insert(repo())

    step = repo().get_by!(Step, workflow_id: workflow.id, step_name: "notify")

    {:ok, _step} =
      step
      |> Step.changeset(%{
        state: "pending",
        blocker_codes: ["waiting_on_retryable_dependency"],
        blocker_details: %{"reason" => "upstream still running"}
      })
      |> repo().update()

    incidents = Lifeline.project_incidents(repo())

    incident = Enum.find(incidents, &(&1.workflow_step_id == step.id))

    assert %Incident{incident_class: "workflow_stuck"} = incident
    assert incident.workflow_step_id == step.id
    assert incident.evidence["step_name"] == "notify"
    assert incident.evidence["diagnosis"] == "waiting_on_retryable_dependency"

    assert incident.evidence["blocker_summaries"] == [
             "step is waiting on retryable upstream work"
           ]
  end

  test "workflow stuck incidents resolve when the current step no longer qualifies as blocked" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "stuck-flow") |> Workflow.insert(repo())

    step = repo().get_by!(Step, workflow_id: workflow.id, step_name: "notify")

    {:ok, _step} =
      step
      |> Step.changeset(%{
        state: "pending",
        blocker_codes: ["waiting_on_retryable_dependency"],
        blocker_details: %{"reason" => "upstream still running"}
      })
      |> repo().update()

    [incident] =
      Lifeline.project_incidents(repo())
      |> Enum.filter(&(&1.workflow_step_id == step.id))

    step = repo().get!(Step, step.id)

    {:ok, _step} =
      step
      |> Step.changeset(%{
        state: "available",
        blocker_codes: [],
        blocker_details: %{}
      })
      |> repo().update()

    refute Enum.any?(Lifeline.project_incidents(repo()), &(&1.id == incident.id))

    resolved = repo().get!(Incident, incident.id)
    assert resolved.status == "resolved"
    assert resolved.resolved_at
  end

  test "preview_repair persists a durable preview and is idempotent for the same input" do
    incident = insert_dead_executor_incident!("executor-missing")
    job = insert_executing_job!("executor-missing")
    actor = %{id: "operator-1", permissions: [:preview_repair]}

    assert {:ok, first_preview} =
             Lifeline.preview_repair(repo(), actor, %{
               incident_fingerprint: incident.incident_fingerprint,
               action: "job_rescue",
               target_type: "job",
               target_id: job.id
             })

    assert {:ok, second_preview} =
             Lifeline.preview_repair(repo(), actor, %{
               incident_fingerprint: incident.incident_fingerprint,
               action: "job_rescue",
               target_type: "job",
               target_id: job.id
             })

    assert first_preview.id == second_preview.id
    assert repo().aggregate(ObanPowertools.Lifeline.RepairPreview, :count, :id) == 1
    assert first_preview.status == "ready"
    assert first_preview.reason_required == true
    assert first_preview.metadata["summary"] =~ "job"
    assert first_preview.metadata["risk"] == "high"
    assert first_preview.metadata["resource"]["type"] == "job"
    assert first_preview.metadata["runbook_context"]["entry"]["title"] == "Open runbook entry"
    assert first_preview.metadata["runbook_context"]["diagnosis_state"] == "missing"
    assert first_preview.metadata["runbook_context"]["evidence_completeness"] == "complete"

    assert first_preview.metadata["runbook_context"]["selected_path"]["ownership"] ==
             "Powertools-native"

    assert first_preview.metadata["runbook_context"]["selected_path"]["venue"] ==
             "Powertools-native Lifeline"

    assert first_preview.metadata["runbook_context"]["selected_path"]["intent"] == "remediate"
    assert first_preview.metadata["runbook_context"]["attempt"]["state"] == "previewed"
    assert first_preview.metadata["runbook_context"]["attempt"]["action"] == "job_rescue"
    assert first_preview.metadata["runbook_context"]["attempt"]["target_type"] == "job"
    assert first_preview.metadata["runbook_context"]["attempt"]["target_id"] == to_string(job.id)

    assert first_preview.metadata["runbook_context"]["selectors"]["incident_fingerprint"] ==
             incident.incident_fingerprint

    assert first_preview.metadata["runbook_context"]["selectors"]["resource_type"] == "job"

    assert first_preview.metadata["runbook_context"]["selectors"]["resource_id"] ==
             to_string(job.id)

    assert first_preview.metadata["runbook_context"]["plan_hash"] == first_preview.plan_hash

    assert first_preview.metadata["runbook_context"]["preview_token"] ==
             first_preview.preview_token
  end

  test "preview_repair rejects late incidents and unsupported targets" do
    late_incident = insert_dead_executor_incident!("executor-late", "late")
    actor = %{id: "operator-1", permissions: [:preview_repair]}
    job = insert_executing_job!("executor-late")

    assert {:error, :heartbeat_late} =
             Lifeline.preview_repair(repo(), actor, %{
               incident_fingerprint: late_incident.incident_fingerprint,
               action: "job_rescue",
               target_type: "job",
               target_id: job.id
             })

    assert {:error, :unsupported_target} =
             Lifeline.preview_repair(repo(), actor, %{
               action: "job_rescue",
               target_type: "workflow",
               target_id: "1"
             })

    unchanged_incident = repo().get!(Incident, late_incident.id)
    assert unchanged_incident.status == "active"
    assert is_nil(unchanged_incident.resolved_at)
  end

  test "execute_repair requires a reason, enforces single-use, and writes immutable audit evidence for jobs" do
    Application.delete_env(:oban_powertools, :host_escalation_handler)

    incident = insert_dead_executor_incident!("executor-missing")
    job = insert_executing_job!("executor-missing")
    actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

    {:ok, preview} =
      Lifeline.preview_repair(repo(), actor, %{
        incident_fingerprint: incident.incident_fingerprint,
        action: "job_rescue",
        target_type: "job",
        target_id: job.id
      })

    assert {:error, :reason_required} =
             Lifeline.execute_repair(repo(), actor, preview.preview_token, "   ")

    assert {:ok, %{target: repaired_job, preview: executed_preview}} =
             Lifeline.execute_repair(
               repo(),
               actor,
               preview.preview_token,
               "Rescuing the orphaned job after node loss"
             )

    assert repaired_job.state == "available"
    assert executed_preview.consumed_at
    assert executed_preview.status == "consumed"
    assert executed_preview.metadata["runbook_context"]["attempt"]["state"] == "consumed"

    resolved_incident = repo().get!(Incident, incident.id)
    assert resolved_incident.status == "resolved"
    assert resolved_incident.resolved_at

    audit_events = Audit.list(%{type: :job, id: Integer.to_string(job.id)}, repo: repo())
    assert length(audit_events) == 2

    repair_audit_event =
      Enum.find(audit_events, &(&1.action == "lifeline.repair_executed"))

    host_follow_up_event =
      Enum.find(audit_events, &(&1.action == "lifeline.host_follow_up"))

    assert repair_audit_event
    assert repair_audit_event.event_type == "lifeline.repair_executed"
    assert repair_audit_event.command_key == "execute_repair"
    assert repair_audit_event.resource_type == "job"
    assert repair_audit_event.resource_id == Integer.to_string(job.id)
    assert repair_audit_event.metadata["reason"] =~ "orphaned job"
    assert repair_audit_event.metadata["runbook_context"]["attempt"]["state"] == "succeeded"
    assert repair_audit_event.metadata["runbook_context"]["attempt"]["action"] == "job_rescue"
    assert repair_audit_event.metadata["runbook_context"]["attempt"]["target_type"] == "job"

    assert repair_audit_event.metadata["runbook_context"]["attempt"]["target_id"] ==
             Integer.to_string(job.id)

    assert repair_audit_event.metadata["runbook_context"]["selectors"]["resource_type"] == "job"

    assert repair_audit_event.metadata["runbook_context"]["selectors"]["resource_id"] ==
             Integer.to_string(job.id)

    assert repair_audit_event.metadata["runbook_context"]["plan_hash"] == preview.plan_hash

    assert repair_audit_event.metadata["runbook_context"]["preview_token"] ==
             preview.preview_token

    assert host_follow_up_event
    assert host_follow_up_event.metadata["status"] == "host_owned_follow_up_unconfigured"

    assert host_follow_up_event.metadata["details"]["fallback"] ==
             "host-owned follow-up unavailable"

    assert host_follow_up_event.metadata["details"]["configuration"] ==
             "No host escalation hook configured"

    assert host_follow_up_event.metadata["incident_fingerprint"] == incident.incident_fingerprint
    assert host_follow_up_event.metadata["preview_token"] == preview.preview_token
    assert host_follow_up_event.metadata["plan_hash"] == preview.plan_hash
    assert host_follow_up_event.metadata["runbook_context"]["attempt"]["state"] == "succeeded"
    assert host_follow_up_event.metadata["runbook_context"]["attempt"]["action"] == "job_rescue"

    assert {:error, :preview_consumed} =
             Lifeline.execute_repair(
               repo(),
               actor,
               preview.preview_token,
               "Trying again after the preview was consumed"
             )
  end

  test "execute_repair records callback failure status without rolling back successful remediation" do
    Application.put_env(
      :oban_powertools,
      :host_escalation_handler,
      ObanPowertools.LifelineHostEscalationFailTestHandler
    )

    incident = insert_dead_executor_incident!("executor-missing-failed-callback")
    job = insert_executing_job!("executor-missing-failed-callback")
    actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

    {:ok, preview} =
      Lifeline.preview_repair(repo(), actor, %{
        incident_fingerprint: incident.incident_fingerprint,
        action: "job_rescue",
        target_type: "job",
        target_id: job.id
      })

    assert {:ok, %{target: repaired_job}} =
             Lifeline.execute_repair(
               repo(),
               actor,
               preview.preview_token,
               "Apply native remediation even if host callback fails"
             )

    assert repaired_job.state == "available"

    host_follow_up_event =
      Audit.list(%{type: :job, id: Integer.to_string(job.id)}, repo: repo())
      |> Enum.find(&(&1.action == "lifeline.host_follow_up"))

    assert host_follow_up_event
    assert host_follow_up_event.metadata["status"] == "host_owned_follow_up_callback_failed"
    assert host_follow_up_event.metadata["details"]["reason"] =~ "host_callback_failed"
  end

  test "execute_repair records callback invoked status when host follow-up is configured" do
    Application.put_env(
      :oban_powertools,
      :host_escalation_handler,
      ObanPowertools.LifelineHostEscalationOkTestHandler
    )

    incident = insert_dead_executor_incident!("executor-missing-callback-ok")
    job = insert_executing_job!("executor-missing-callback-ok")
    actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

    {:ok, preview} =
      Lifeline.preview_repair(repo(), actor, %{
        incident_fingerprint: incident.incident_fingerprint,
        action: "job_rescue",
        target_type: "job",
        target_id: job.id
      })

    assert {:ok, %{target: repaired_job}} =
             Lifeline.execute_repair(
               repo(),
               actor,
               preview.preview_token,
               "Call host follow-up callback after successful remediation"
             )

    assert repaired_job.state == "available"

    host_follow_up_event =
      Audit.list(%{type: :job, id: Integer.to_string(job.id)}, repo: repo())
      |> Enum.find(&(&1.action == "lifeline.host_follow_up"))

    assert host_follow_up_event
    assert host_follow_up_event.metadata["status"] == "host_owned_follow_up_callback_invoked"
    assert host_follow_up_event.metadata["details"]["result"] == "ok"
  end

  test "execute_repair leaves the incident active for unauthorized execution attempts" do
    incident = insert_dead_executor_incident!("executor-missing")
    job = insert_executing_job!("executor-missing")

    {:ok, preview} =
      Lifeline.preview_repair(repo(), %{id: "operator-1", permissions: [:preview_repair]}, %{
        incident_fingerprint: incident.incident_fingerprint,
        action: "job_rescue",
        target_type: "job",
        target_id: job.id
      })

    assert {:error, :unauthorized} =
             Lifeline.execute_repair(
               repo(),
               %{id: "operator-2", permissions: []},
               preview.preview_token,
               "Unauthorized operator should not retire the incident"
             )

    unchanged_incident = repo().get!(Incident, incident.id)
    assert unchanged_incident.status == "active"
    assert is_nil(unchanged_incident.resolved_at)
  end

  test "execute_repair rejects drifted previews and supports workflow-step repair" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "repair-flow") |> Workflow.insert(repo())

    step = repo().get_by!(Step, workflow_id: workflow.id, step_name: "notify")
    actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

    {:ok, _step} =
      step
      |> Step.changeset(%{
        state: "pending",
        blocker_codes: ["waiting_on_retryable_dependency"],
        blocker_details: %{"reason" => "blocked before repair"}
      })
      |> repo().update()

    workflow_incident =
      Lifeline.project_incidents(repo())
      |> Enum.find(&(&1.workflow_step_id == step.id))

    {:ok, preview} =
      Lifeline.preview_repair(repo(), actor, %{
        incident_fingerprint: workflow_incident.incident_fingerprint,
        action: "workflow_step_retry",
        target_type: "workflow_step",
        target_id: step.id
      })

    repo().update!(
      Step.changeset(step, %{
        state: "retryable",
        blocker_codes: ["waiting_on_retryable_dependency"],
        blocker_details: %{"reason" => "state changed after preview"}
      })
    )

    assert {:error, :preview_drifted} =
             Lifeline.execute_repair(
               repo(),
               actor,
               preview.preview_token,
               "State drifted before I could retry the step"
             )

    drifted_preview =
      repo().get_by!(ObanPowertools.Lifeline.RepairPreview, preview_token: preview.preview_token)

    assert drifted_preview.status == "drifted"
    assert drifted_preview.metadata["drift_reason"]
    assert drifted_preview.metadata["runbook_context"]["attempt"]["state"] == "drifted"

    drifted_incident = repo().get!(Incident, workflow_incident.id)
    assert drifted_incident.status == "active"
    assert is_nil(drifted_incident.resolved_at)

    fresh_step = repo().get!(Step, step.id)

    {:ok, fresh_preview} =
      Lifeline.preview_repair(repo(), actor, %{
        incident_fingerprint: workflow_incident.incident_fingerprint,
        action: "workflow_step_cancel",
        target_type: "workflow_step",
        target_id: fresh_step.id
      })

    assert {:ok, %{target: cancelled_step}} =
             Lifeline.execute_repair(
               repo(),
               actor,
               fresh_preview.preview_token,
               "Cancelling the stuck step after operator review"
             )

    assert cancelled_step.state == "cancelled"

    consumed_preview =
      repo().get_by!(
        ObanPowertools.Lifeline.RepairPreview,
        preview_token: fresh_preview.preview_token
      )

    assert consumed_preview.status == "consumed"
    assert consumed_preview.metadata["runbook_context"]["attempt"]["state"] == "consumed"

    command_attempt =
      repo().get_by!(CommandAttempt,
        workflow_id: workflow.id,
        step_id: cancelled_step.id,
        action: "recover_step:cancel",
        source: "lifeline",
        status: "completed"
      )

    assert command_attempt.actor_id == "operator-1"
    assert command_attempt.reason_message == "Cancelling the stuck step after operator review"

    resolved_incident = repo().get!(Incident, workflow_incident.id)
    assert resolved_incident.status == "resolved"
    assert resolved_incident.resolved_at
  end

  test "expired previews preserve continuity metadata while setting attempt state to expired" do
    incident = insert_dead_executor_incident!("executor-missing")
    job = insert_executing_job!("executor-missing")
    actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}
    now = DateTime.utc_now()

    {:ok, preview} =
      Lifeline.preview_repair(
        repo(),
        actor,
        %{
          incident_fingerprint: incident.incident_fingerprint,
          action: "job_rescue",
          target_type: "job",
          target_id: job.id
        },
        now: now
      )

    assert {:error, :preview_expired} =
             Lifeline.execute_repair(
               repo(),
               actor,
               preview.preview_token,
               "Expired remediation request should not execute",
               now: DateTime.add(now, 8 * 24 * 60 * 60, :second)
             )

    expired_preview =
      repo().get_by!(ObanPowertools.Lifeline.RepairPreview, preview_token: preview.preview_token)

    assert expired_preview.status == "expired"
    assert expired_preview.metadata["runbook_context"]["attempt"]["state"] == "expired"
    assert expired_preview.metadata["runbook_context"]["plan_hash"] == preview.plan_hash
    assert expired_preview.metadata["runbook_context"]["preview_token"] == preview.preview_token
  end

  test "preview_repair and execute_repair support workflow_request_cancel without an incident row" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "workflow-request-cancel")
      |> Workflow.insert(repo())

    actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

    assert {:ok, preview} =
             Lifeline.preview_repair(repo(), actor, %{
               action: "workflow_request_cancel",
               target_type: "workflow",
               target_id: workflow.id
             })

    assert preview.status == "ready"
    assert preview.incident_id == nil
    assert preview.metadata["summary"] =~ "Request cancel"

    assert {:ok, %{target: cancelled_workflow}} =
             Lifeline.execute_repair(
               repo(),
               actor,
               preview.preview_token,
               "Requesting cooperative cancellation after operator review"
             )

    assert cancelled_workflow.cancel_requested_at
    assert cancelled_workflow.state in ["cancel_requested", "cancelled"]

    command_attempt =
      repo().get_by!(CommandAttempt,
        workflow_id: workflow.id,
        action: "request_cancel",
        source: "lifeline",
        status: "completed"
      )

    assert command_attempt.actor_id == "operator-1"

    assert command_attempt.reason_message ==
             "Requesting cooperative cancellation after operator review"
  end

  test "run_archive_prune archives manual repair evidence before deleting old audit rows" do
    old_inserted_at =
      DateTime.utc_now() |> DateTime.add(-(91 * 24 * 60 * 60), :second) |> DateTime.to_naive()

    insert_old_repair_audit!("job:123", old_inserted_at)

    assert {:ok, run} =
             Lifeline.run_archive_prune(repo(), %{id: "operator-1"}, reason: "routine archive")

    assert run.archived_count == 1
    assert run.status == "completed"
    assert archived_repairs_count() == 1
    assert repo().aggregate(Audit, :count, :id) == 0
  end

  test "run_archive_prune prunes old heartbeat samples without archiving them" do
    insert_heartbeat!("executor-old", DateTime.add(DateTime.utc_now(), -(7 * 60 * 60), :second))

    assert {:ok, run} =
             Lifeline.run_archive_prune(repo(), %{id: "operator-1"},
               reason: "prune heartbeat spam"
             )

    assert run.pruned_count >= 1
    assert repo().aggregate(Heartbeat, :count, :id) == 0
    assert archived_repairs_count() == 0
  end

  test "run_archive_prune prunes expired job records with the existing batch size" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    expired_1 = insert_job_record!(expires_at: DateTime.add(now, -60, :second))
    expired_2 = insert_job_record!(expires_at: now)
    active = insert_job_record!(expires_at: DateTime.add(now, 60, :second))

    assert {:ok, run} =
             Lifeline.run_archive_prune(repo(), %{id: "operator-1"},
               now: now,
               batch_size: 1,
               reason: "prune expired outputs"
             )

    assert run.pruned_count == 1
    assert repo().aggregate(JobRecord, :count, :id) == 2
    assert repo().get(JobRecord, active.id)

    remaining_expired_ids =
      repo().all(
        from(record in JobRecord,
          where: record.id in ^[expired_1.id, expired_2.id],
          select: record.id
        )
      )

    assert length(remaining_expired_ids) == 1
  end

  test "run_archive_prune adds deleted job records to archive run pruned_count" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    insert_job_record!(expires_at: DateTime.add(now, -120, :second))
    insert_job_record!(expires_at: DateTime.add(now, -60, :second))
    insert_job_record!(expires_at: DateTime.add(now, 60, :second))

    assert {:ok, run} =
             Lifeline.run_archive_prune(repo(), %{id: "operator-1"},
               now: now,
               reason: "account for output pruning"
             )

    assert run.pruned_count == 2
    assert repo().aggregate(JobRecord, :count, :id) == 1

    persisted_run = repo().get!(ArchiveRun, run.id)
    assert persisted_run.pruned_count == 2
    assert persisted_run.archived_count == 0
  end

  test "run_archive_prune telemetry includes pruned job records in pruned_count" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    insert_job_record!(expires_at: DateTime.add(now, -60, :second))

    parent = self()
    handler_id = "test-archive-prune-job-records-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:oban_powertools, :lifeline, :archive_prune_completed],
      fn _event, _measurements, metadata, _config ->
        send(parent, {:archive_prune_completed, metadata})
      end,
      nil
    )

    assert {:ok, run} =
             Lifeline.run_archive_prune(repo(), %{id: "operator-1"},
               now: now,
               reason: "emit output prune telemetry"
             )

    assert run.pruned_count == 1
    assert_receive {:archive_prune_completed, %{outcome: "ok", pruned_count: 1}}

    :telemetry.detach(handler_id)
  end

  test "run_archive_prune blocks deletion when archive persistence fails" do
    old_inserted_at =
      DateTime.utc_now() |> DateTime.add(-(91 * 24 * 60 * 60), :second) |> DateTime.to_naive()

    insert_old_repair_audit!("job:123", old_inserted_at)

    assert {:error, {:archive_failed, failed_run}} =
             Lifeline.run_archive_prune(
               repo(),
               %{id: "operator-1"},
               reason: "simulate archive failure",
               force_archive_failure: true
             )

    assert failed_run.status == "failed"
    assert repo().aggregate(Audit, :count, :id) == 1
    assert archived_repairs_count() == 0
  end

  defp insert_heartbeat!(executor_id, last_heartbeat_at) do
    %Heartbeat{}
    |> Heartbeat.changeset(%{
      executor_id: executor_id,
      oban_name: "Oban",
      node: "node-a",
      queue: "default",
      producer_scope: "producer-1",
      health_state: "healthy",
      last_heartbeat_at: last_heartbeat_at,
      warning_threshold_ms: 45_000,
      missing_threshold_ms: 120_000,
      metadata: %{}
    })
    |> repo().insert!()
  end

  defp insert_executing_job!(executor_id) do
    %{}
    |> Oban.Job.new(
      worker: "Example.Worker",
      queue: :default,
      meta: %{"executor_id" => executor_id}
    )
    |> Changeset.change(state: "executing")
    |> repo().insert!()
  end

  defp insert_dead_executor_incident!(executor_id, health_state \\ "missing") do
    %Incident{}
    |> Incident.changeset(%{
      incident_class: "dead_executor",
      status: "active",
      executor_id: executor_id,
      incident_fingerprint: "dead_executor:#{executor_id}",
      health_state: health_state,
      summary: "#{health_state} executor #{executor_id}",
      affected_counts: %{"jobs" => 0, "workflow_steps" => 0},
      evidence: %{},
      first_detected_at: DateTime.utc_now(),
      last_detected_at: DateTime.utc_now(),
      metadata: %{}
    })
    |> repo().insert!()
  end

  defp insert_old_repair_audit!(resource, inserted_at) do
    repo().insert_all("oban_powertools_audit_events", [
      %{
        actor_id: "operator-1",
        action: "lifeline.repair_executed",
        resource: resource,
        metadata: %{
          "incident_class" => "dead_executor",
          "incident_fingerprint" => "dead_executor:executor-missing",
          "plan_hash" => "abc123",
          "reason" => "archivable repair",
          "affected_counts" => %{"jobs" => 1, "workflow_steps" => 0},
          "result" => "ok"
        },
        inserted_at: inserted_at
      }
    ])
  end

  defp insert_job_record!(attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    expires_at = Keyword.fetch!(attrs, :expires_at)
    unique_id = System.unique_integer([:positive])

    %JobRecord{}
    |> JobRecord.changeset(%{
      oban_job_id: unique_id,
      worker: "Example.Worker",
      attempt: 1,
      status: "ok",
      payload: %{"job_record" => unique_id},
      payload_bytes: 24,
      retention: "ephemeral",
      redacted: false,
      recorded_at: Keyword.get(attrs, :recorded_at, DateTime.add(now, -120, :second)),
      expires_at: expires_at
    })
    |> repo().insert!()
  end

  defp archived_repairs_count do
    %{rows: [[count]]} =
      Ecto.Adapters.SQL.query!(repo(), "SELECT count(*) FROM oban_powertools_repair_archives", [])

    count
  end

  test "execute_repair correctly discards a job via job_discard action" do
    incident = insert_dead_executor_incident!("executor-missing-for-discard")
    job = insert_executing_job!("executor-missing-for-discard")
    actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

    {:ok, preview} =
      Lifeline.preview_repair(repo(), actor, %{
        incident_fingerprint: incident.incident_fingerprint,
        action: "job_discard",
        target_type: "job",
        target_id: job.id
      })

    assert {:ok, %{target: discarded_job, preview: executed_preview}} =
             Lifeline.execute_repair(
               repo(),
               actor,
               preview.preview_token,
               "Discarding the job"
             )

    assert discarded_job.state == "discarded"
    assert discarded_job.discarded_at
    assert executed_preview.consumed_at
  end

  test "preview_repair and execute_repair inject telemetry_metadata from opts" do
    Application.delete_env(:oban_powertools, :host_escalation_handler)

    incident = insert_dead_executor_incident!("executor-missing-telemetry")
    job = insert_executing_job!("executor-missing-telemetry")
    actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

    parent = self()
    handler_id_preview = "test-preview-handler-#{System.unique_integer()}"
    handler_id_execute = "test-execute-handler-#{System.unique_integer()}"

    :telemetry.attach(
      handler_id_preview,
      [:oban_powertools, :lifeline, :repair_previewed],
      fn _event, _measurements, metadata, _config ->
        send(parent, {:preview_telemetry, metadata})
      end,
      nil
    )

    :telemetry.attach(
      handler_id_execute,
      [:oban_powertools, :lifeline, :repair_executed],
      fn _event, _measurements, metadata, _config ->
        send(parent, {:execute_telemetry, metadata})
      end,
      nil
    )

    assert {:ok, preview} =
             Lifeline.preview_repair(
               repo(),
               actor,
               %{
                 incident_fingerprint: incident.incident_fingerprint,
                 action: "job_rescue",
                 target_type: "job",
                 target_id: job.id
               },
               telemetry_metadata: %{source: "api"}
             )

    assert_receive {:preview_telemetry, preview_metadata}
    assert preview_metadata.source == "api"
    assert preview_metadata.action == "job_rescue"

    assert {:ok, _result} =
             Lifeline.execute_repair(
               repo(),
               actor,
               preview.preview_token,
               "Rescuing with telemetry",
               telemetry_metadata: %{source: "api"}
             )

    assert_receive {:execute_telemetry, execute_metadata}
    assert execute_metadata.source == "api"
    assert execute_metadata.action == "job_rescue"

    :telemetry.detach(handler_id_preview)
    :telemetry.detach(handler_id_execute)
  end

  defp repo, do: ObanPowertools.TestRepo
end
