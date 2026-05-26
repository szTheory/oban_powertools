defmodule ObanPowertools.Web.ControlPlaneCopyCoherenceTestDisplayPolicy do
  def display(:actor_label, principal, _context) do
    label =
      Map.get(principal, :label) ||
        Map.get(principal, "label") ||
        Map.get(principal, :id) ||
        Map.get(principal, "id") ||
        "system"

    "policy actor: #{label}"
  end

  def display(:reason, nil, _context), do: "policy reason: none provided"
  def display(:reason, "", _context), do: "policy reason: none provided"
  def display(:reason, reason, _context), do: "policy reason: #{String.upcase(to_string(reason))}"
end

defmodule ObanPowertools.Web.ControlPlaneCopyCoherenceTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.Cron
  alias ObanPowertools.Lifeline.{Heartbeat, Incident}
  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord
  alias ObanPowertools.WorkflowFixtures

  setup do
    original_display_policy = Application.get_env(:oban_powertools, :display_policy)

    Application.put_env(
      :oban_powertools,
      :display_policy,
      ObanPowertools.Web.ControlPlaneCopyCoherenceTestDisplayPolicy
    )

    on_exit(fn ->
      Application.put_env(:oban_powertools, :display_policy, original_display_policy)
    end)

    :ok
  end

  test "keeps shared operator copy coherent across cron, lifeline, workflows, and audit", %{
    conn: conn
  } do
    {:ok, _entry} =
      Cron.sync_entry(TestRepo, %{
        name: "nightly-shared-copy",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    insert_missing_heartbeat!("executor-shared-copy")
    incident = insert_dead_executor_incident!("executor-shared-copy")
    job = insert_executing_job!("executor-shared-copy")
    update_incident_job_ids!(incident, [job.id])

    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "shared-copy-workflow") |> Workflow.insert(TestRepo)

    workflow
    |> WorkflowRecord.changeset(%{semantics_version: 1})
    |> TestRepo.update!()

    assert {:error, rejection} =
             Workflow.complete_step(TestRepo, workflow.id, :fetch_customer,
               status: :completed,
               payload: %{customer_id: 1}
             )

    assert rejection.reason_code == "unsupported_legacy_semantics"

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-1",
          permissions: [
            :view_cron,
            :pause_cron_entry,
            :view_lifeline,
            :preview_repair,
            :execute_repair,
            :view_workflows,
            :view_forensics,
            :view_audit
          ]
        }
      )

    {:ok, cron_view, _cron_html} = live(conn, "/ops/jobs/cron")

    cron_preview_html =
      cron_view
      |> element("button[phx-value-entry='nightly-shared-copy'][phx-value-action='pause_cron_entry']")
      |> render_click()

    assert_occurs_in_order(cron_preview_html, [
      "Preview Action",
      "Action:",
      "Resource:",
      "Intended Effect:",
      "Audit Consequence:",
      "Preview Status:",
      "Rendered Reason:"
    ])

    assert cron_preview_html =~ "policy reason: none provided"

    render_change(cron_view, "reason", %{"reason" => "maintenance window"})
    cron_confirmed_html = render_click(cron_view, "confirm", %{})
    assert cron_confirmed_html =~ "Open in Audit"

    {:ok, lifeline_view, _lifeline_html} = live(conn, "/ops/jobs/lifeline")

    lifeline_preview_html =
      lifeline_view
      |> element("button[phx-value-row-id$=':job:#{job.id}'][phx-click='preview']")
      |> render_click()

    assert_occurs_in_order(lifeline_preview_html, [
      "Audit Record to be Written",
      "Actor:",
      "Action:",
      "Resource:",
      "Reason:",
      "Audit Consequence:",
      "Preview Status:",
      "Preview Token:"
    ])

    render_change(lifeline_view, "reason", %{"reason" => "rescuing orphaned job"})
    lifeline_executed_html = render_click(lifeline_view, "execute", %{})

    assert lifeline_executed_html =~ "Repair executed and audit evidence was written."
    assert lifeline_executed_html =~ "Open in Audit"

    {:ok, _workflow_view, workflow_html} =
      live(conn, "/ops/jobs/workflows/#{workflow.id}?step=fetch_customer")

    assert_occurs_in_order(workflow_html, [
      "Outcome:",
      "Reason:",
      "Legal next move:",
      "Venue:",
      "Machine code: unsupported_legacy_semantics"
    ])

    assert workflow_html =~
             "Powertools-native pages own preview, reason, venue, and Audited action controls."

    {:ok, _forensics_view, forensics_html} =
      live(conn, "/ops/jobs/forensics?workflow_id=#{workflow.id}&step=fetch_customer")

    assert_occurs_in_order(forensics_html, [
      "Diagnosis Summary",
      "Timeline",
      "Related Evidence",
      "Linked Resources",
      "Legal Next Paths",
      "Evidence Completeness"
    ])

    assert forensics_html =~ "supporting evidence"
    assert forensics_html =~ "Inspection only"
    refute forensics_html =~ "preview_token="
    refute forensics_html =~ "reason="
    refute forensics_html =~ "diagnosis="
    refute forensics_html =~ "refusal="

    {:ok, _audit_view, audit_html} = live(conn, "/ops/jobs/audit")

    assert audit_html =~ "cross-surface audit destination"
    assert audit_html =~ "Inspection only"
    assert audit_html =~ "cron.paused"
    assert audit_html =~ "lifeline.repair_executed"
    assert audit_html =~ "cron_entry:nightly-shared-copy"
    assert audit_html =~ "job:#{job.id}"
  end

  defp assert_occurs_in_order(text, markers) do
    {_text, _offset} =
      Enum.reduce(markers, {text, 0}, fn marker, {remaining, offset} ->
        assert String.contains?(remaining, marker),
               "expected #{inspect(marker)} after byte offset #{offset}"

        {index, _len} = :binary.match(remaining, marker)
        next_offset = offset + index + byte_size(marker)

        next_remaining =
          binary_part(
            remaining,
            index + byte_size(marker),
            byte_size(remaining) - index - byte_size(marker)
          )

        {next_remaining, next_offset}
      end)
  end

  defp insert_dead_executor_incident!(executor_id) do
    %Incident{}
    |> Incident.changeset(%{
      incident_class: "dead_executor",
      status: "active",
      executor_id: executor_id,
      incident_fingerprint: "dead_executor:#{executor_id}",
      health_state: "missing",
      summary: "missing executor #{executor_id}",
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
      evidence: %{
        "job_ids" => job_ids,
        "workflow_step_ids" => [],
        "last_heartbeat_at" => DateTime.utc_now()
      }
    })
    |> TestRepo.update!()
  end

  defp insert_executing_job!(executor_id) do
    %{}
    |> Oban.Job.new(
      worker: "Example.Worker",
      queue: :default,
      meta: %{"executor_id" => executor_id}
    )
    |> Ecto.Changeset.change(state: "executing")
    |> TestRepo.insert!()
  end

  defp insert_missing_heartbeat!(executor_id) do
    %Heartbeat{}
    |> Heartbeat.changeset(%{
      executor_id: executor_id,
      oban_name: "Oban",
      node: "node-a",
      queue: "default",
      producer_scope: "producer-1",
      health_state: "healthy",
      last_heartbeat_at: DateTime.add(DateTime.utc_now(), -180, :second),
      warning_threshold_ms: 45_000,
      missing_threshold_ms: 120_000,
      metadata: %{}
    })
    |> TestRepo.insert!()
  end
end
