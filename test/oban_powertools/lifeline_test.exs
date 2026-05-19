defmodule ObanPowertools.LifelineTest do
  use ObanPowertools.DataCase, async: false

  alias Ecto.Changeset
  alias ObanPowertools.Audit
  alias ObanPowertools.Lifeline
  alias ObanPowertools.Lifeline.{Heartbeat, Incident}
  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.Step
  alias ObanPowertools.WorkflowFixtures

  test "refresh_heartbeats upserts one durable row per executor identity" do
    now = DateTime.utc_now()

    assert {:ok, [%Heartbeat{} = first]} =
             Lifeline.refresh_heartbeats(repo(), [
               %{executor_id: "app:oban:default:node-a:producer-1", node: "node-a", producer_scope: "producer-1"}
             ], now: now)

    later = DateTime.add(now, 30, :second)

    assert {:ok, [%Heartbeat{} = second]} =
             Lifeline.refresh_heartbeats(repo(), [
               %{executor_id: "app:oban:default:node-a:producer-1", node: "node-a", producer_scope: "producer-1"}
             ], now: later)

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
             Enum.find(incidents, &(&1.executor_id == "executor-missing" and &1.incident_class == "dead_executor"))
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
    {:ok, workflow} = WorkflowFixtures.workflow_fixture(name: "stuck-flow") |> Workflow.insert(repo())
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
  end

  test "execute_repair requires a reason, enforces single-use, and writes immutable audit evidence for jobs" do
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

    [audit_event] = Audit.list(%{type: :job, id: Integer.to_string(job.id)}, repo: repo())
    assert audit_event.action == "lifeline.repair_executed"
    assert audit_event.metadata["reason"] =~ "orphaned job"

    assert {:error, :preview_consumed} =
             Lifeline.execute_repair(
               repo(),
               actor,
               preview.preview_token,
               "Trying again after the preview was consumed"
             )
  end

  test "execute_repair rejects drifted previews and supports workflow-step repair" do
    {:ok, workflow} = WorkflowFixtures.workflow_fixture(name: "repair-flow") |> Workflow.insert(repo())
    step = repo().get_by!(Step, workflow_id: workflow.id, step_name: "notify")
    actor = %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

    {:ok, preview} =
      Lifeline.preview_repair(repo(), actor, %{
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

    fresh_step = repo().get!(Step, step.id)

    {:ok, fresh_preview} =
      Lifeline.preview_repair(repo(), actor, %{
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
  end

  test "run_archive_prune archives manual repair evidence before deleting old audit rows" do
    old_inserted_at = DateTime.utc_now() |> DateTime.add(-(91 * 24 * 60 * 60), :second) |> DateTime.to_naive()

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
             Lifeline.run_archive_prune(repo(), %{id: "operator-1"}, reason: "prune heartbeat spam")

    assert run.pruned_count >= 1
    assert repo().aggregate(Heartbeat, :count, :id) == 0
    assert archived_repairs_count() == 0
  end

  test "run_archive_prune blocks deletion when archive persistence fails" do
    old_inserted_at = DateTime.utc_now() |> DateTime.add(-(91 * 24 * 60 * 60), :second) |> DateTime.to_naive()
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
    |> Oban.Job.new(worker: "Example.Worker", queue: :default, meta: %{"executor_id" => executor_id})
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

  defp archived_repairs_count do
    %{rows: [[count]]} =
      Ecto.Adapters.SQL.query!(repo(), "SELECT count(*) FROM oban_powertools_repair_archives", [])

    count
  end

  defp repo, do: ObanPowertools.TestRepo
end
