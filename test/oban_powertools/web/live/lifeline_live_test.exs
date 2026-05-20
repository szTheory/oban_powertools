defmodule ObanPowertools.Web.LifelineLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias Ecto.Changeset
  alias ObanPowertools.Audit
  alias ObanPowertools.Lifeline.{ArchiveRun, Incident}
  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.Step
  alias ObanPowertools.WorkflowFixtures

  test "redirects unauthorized viewers", %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-3", permissions: []})
    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/lifeline")
  end

  test "renders incident-first page with preview as the only primary row action and archive activity read-only", %{conn: conn} do
    incident = insert_dead_executor_incident!("executor-missing")
    job = insert_executing_job!("executor-missing")
    update_incident_job_ids!(incident, [job.id])
    insert_archive_run!()

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_lifeline, :preview_repair]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/lifeline")

    assert html =~ "Needs Review"
    assert html =~ "Preview Repair Plan"
    assert html =~ "Archive Activity"
    assert html =~ "read-only here"
    refute has_element?(view, "button[phx-click='execute']")
  end

  test "creates durable preview, requires reason for execute, and deep-links generic job inspection", %{conn: conn} do
    incident = insert_dead_executor_incident!("executor-missing")
    job = insert_executing_job!("executor-missing")
    update_incident_job_ids!(incident, [job.id])

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_lifeline, :preview_repair, :execute_repair]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

    html =
      view
      |> element("button[phx-value-row-id='#{incident.id}:job:#{job.id}'][phx-click='preview']")
      |> render_click()

    assert html =~ "Preview Ready"
    assert html =~ "Audit Record to be Written"
    assert html =~ "Open Generic Job Inspection in Oban Web"
    assert html =~ "/oban/jobs/#{job.id}"
    assert has_element?(view, "button[phx-click='execute'][disabled]")

    assert [%{status: "pending"}] = TestRepo.all(ObanPowertools.Lifeline.RepairPreview)

    render_change(view, "reason", %{"reason" => "reviewed"})
    refute has_element?(view, "button[phx-click='execute'][disabled]")
  end

  test "shows Preview Drifted when target state changes after preview", %{conn: conn} do
    {:ok, workflow} = WorkflowFixtures.workflow_fixture(name: "repair-flow") |> Workflow.insert(TestRepo)
    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "notify")
    incident = insert_workflow_incident!(workflow.id, step.id)

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_lifeline, :preview_repair, :execute_repair]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

    view
    |> element("button[phx-value-row-id='#{incident.id}:workflow_step:#{step.id}'][phx-click='preview']")
    |> render_click()

    TestRepo.update!(
      Step.changeset(step, %{
        state: "retryable",
        blocker_codes: ["waiting_on_retryable_dependency"],
        blocker_details: %{"reason" => "drifted"}
      })
    )

    render_change(view, "reason", %{"reason" => "operator reviewed drift"})
    html = render_click(view, "execute", %{})

    assert html =~ "Preview Drifted"
    assert has_element?(view, "button[phx-click='execute'][disabled]")
  end

  test "executes repair and renders inline audit history for selected incident", %{conn: conn} do
    incident = insert_dead_executor_incident!("executor-missing")
    job = insert_executing_job!("executor-missing")
    update_incident_job_ids!(incident, [job.id])

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_lifeline, :preview_repair, :execute_repair]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

    view
    |> element("button[phx-value-row-id='#{incident.id}:job:#{job.id}'][phx-click='preview']")
    |> render_click()

    render_change(view, "reason", %{"reason" => "Rescuing orphaned job after node loss"})
    html = render_click(view, "execute", %{})

    assert html =~ "Repair executed and audit evidence was written."
    assert html =~ "Manual Intervention History"
    assert html =~ "Rescuing orphaned job after node loss"

    [event] = Audit.list(%{type: :job, id: Integer.to_string(job.id)}, repo: TestRepo)
    assert event.action == "lifeline.repair_executed"
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
      evidence: %{"job_ids" => [], "workflow_step_ids" => []},
      first_detected_at: DateTime.utc_now(),
      last_detected_at: DateTime.utc_now(),
      metadata: %{}
    })
    |> TestRepo.insert!()
  end

  defp update_incident_job_ids!(incident, job_ids) do
    incident
    |> Incident.changeset(%{
      affected_counts: %{"jobs" => length(job_ids), "workflow_steps" => 0},
      evidence: %{"job_ids" => job_ids, "workflow_step_ids" => [], "last_heartbeat_at" => DateTime.utc_now()}
    })
    |> TestRepo.update!()
  end

  defp insert_workflow_incident!(workflow_id, step_id) do
    %Incident{}
    |> Incident.changeset(%{
      incident_class: "workflow_stuck",
      status: "active",
      workflow_id: workflow_id,
      workflow_step_id: step_id,
      incident_fingerprint: "workflow_stuck:#{workflow_id}:#{step_id}",
      summary: "Workflow step notify is blocked",
      affected_counts: %{"jobs" => 0, "workflow_steps" => 1},
      evidence: %{"step_name" => "notify", "blocker_codes" => ["waiting_on_dependencies"]},
      first_detected_at: DateTime.utc_now(),
      last_detected_at: DateTime.utc_now(),
      metadata: %{}
    })
    |> TestRepo.insert!()
  end

  defp insert_archive_run! do
    %ArchiveRun{}
    |> ArchiveRun.changeset(%{
      run_type: "manual",
      status: "completed",
      retention_class: "phase_4",
      actor_id: "ops-1",
      reason: "routine archive",
      batch_size: 100,
      archived_count: 2,
      pruned_count: 1,
      blocked_count: 0,
      started_at: DateTime.utc_now(),
      finished_at: DateTime.utc_now(),
      metadata: %{}
    })
    |> TestRepo.insert!()
  end

  defp insert_executing_job!(executor_id) do
    %{}
    |> Oban.Job.new(worker: "Example.Worker", queue: :default, meta: %{"executor_id" => executor_id})
    |> Changeset.change(state: "executing")
    |> TestRepo.insert!()
  end
end
