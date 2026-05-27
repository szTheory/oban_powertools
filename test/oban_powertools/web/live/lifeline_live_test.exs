defmodule ObanPowertools.Web.LifelineLiveTestDisplayPolicy do
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

defmodule ObanPowertools.Web.LifelineLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias Ecto.Changeset
  alias ObanPowertools.Audit
  alias ObanPowertools.Lifeline.{ArchiveRun, Incident}
  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.Step
  alias ObanPowertools.WorkflowFixtures

  @allowed_selector_keys MapSet.new([
    "resource_type",
    "resource_id",
    "workflow_id",
    "step",
    "incident_fingerprint",
    "view"
  ])

  setup do
    original_display_policy = Application.get_env(:oban_powertools, :display_policy)

    Application.put_env(
      :oban_powertools,
      :display_policy,
      ObanPowertools.Web.LifelineLiveTestDisplayPolicy
    )

    on_exit(fn ->
      Application.put_env(:oban_powertools, :display_policy, original_display_policy)
    end)

    :ok
  end

  test "redirects unauthorized viewers", %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-3", permissions: []})
    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/lifeline")
  end

  test "renders incident-first page with preview as the only primary row action and archive activity read-only",
       %{conn: conn} do
    insert_missing_heartbeat!("executor-missing")
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
    assert html =~ "Preview Native Remediation"
    assert html =~ "Archive Activity"
    assert html =~ "Archive and prune visibility is read-only here."
    assert html =~ "No remediation attempts recorded yet"

    assert html =~
             "This diagnosis has not entered a supported native remediation flow. Review legal next paths, then start a native preview to capture attempt context."

    refute has_element?(view, "button[phx-click='execute']")
  end

  test "creates durable preview, requires reason for execute, and deep-links generic job inspection",
       %{conn: conn} do
    insert_missing_heartbeat!("executor-missing")
    incident = insert_dead_executor_incident!("executor-missing")
    job = insert_executing_job!("executor-missing")
    update_incident_job_ids!(incident, [job.id])

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-1",
          permissions: [:view_lifeline, :preview_repair, :execute_repair]
        }
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

    html =
      view
      |> element("button[phx-value-row-id$=':job:#{job.id}'][phx-click='preview']")
      |> render_click()

    assert html =~ "Runbook continuity"
    assert html =~ "Diagnosis:"
    assert html =~ "Legal next path:"
    assert html =~ "Venue:"
    assert html =~ "Attempt state:"
    assert html =~ "host-owned follow-up status:"
    assert html =~ "Host-owned follow-up unavailable"
    assert html =~ "No host escalation hook configured"
    assert html =~ "Evidence link"
    assert html =~ "Powertools-native"
    assert html =~ "Oban Web bridge"
    assert html =~ "host-owned follow-up"

    assert html =~
             "/ops/jobs/forensics?incident_fingerprint=#{URI.encode_www_form(incident.incident_fingerprint)}&amp;view=active"

    assert html =~ "Preview Ready"
    assert html =~ "Preview Status"
    assert html =~ "Audit Record to be Written"
    assert html =~ "Audit Consequence"

    assert html =~
             "Execute Remediation: This writes a native remediation attempt to audit and forensic evidence. Confirm only after reviewing reason, ownership, and expected outcome."

    assert html =~ "policy actor: operator:ops-1"
    assert html =~ "policy reason: none provided"
    assert html =~ "Open Generic Job Inspection in Oban Web bridge"
    assert html =~ "/oban/jobs/#{job.id}"

    diagnosis_position = html_position(html, "Diagnosis:")
    legal_path_position = html_position(html, "Legal next path:")
    venue_position = html_position(html, "Venue:")
    attempt_state_position = html_position(html, "Attempt state:")
    evidence_link_position = html_position(html, "Evidence link:")
    audit_follow_up_position = html_position(html, "Audit follow-up:")

    assert diagnosis_position < legal_path_position
    assert legal_path_position < venue_position
    assert venue_position < attempt_state_position
    assert attempt_state_position < evidence_link_position
    assert evidence_link_position < audit_follow_up_position

    assert [%{status: "ready"}] = TestRepo.all(ObanPowertools.Lifeline.RepairPreview)

    render_change(view, "reason", %{"reason" => "reviewed"})
    assert render(view) =~ "policy reason: REVIEWED"
  end

  test "renders host-owned follow-up status labels from audit metadata", %{conn: conn} do
    for {status, details, expected_label, expected_detail} <- [
          {
            "host_owned_follow_up_unconfigured",
            %{"configuration" => "No host escalation hook configured"},
            "Host-owned follow-up unavailable",
            "No host escalation hook configured"
          },
          {
            "host_owned_follow_up_callback_invoked",
            %{"result" => "ok"},
            "Host-owned follow-up callback invoked",
            nil
          },
          {
            "host_owned_follow_up_callback_failed",
            %{"reason" => "callback timeout"},
            "Host-owned follow-up callback failed",
            "callback timeout"
          }
        ] do
      executor_id = "host-status-#{System.unique_integer([:positive])}"
      insert_missing_heartbeat!(executor_id)
      incident = insert_dead_executor_incident!(executor_id)
      job = insert_executing_job!(executor_id)
      update_incident_job_ids!(incident, [job.id])

      {:ok, _event} =
        Audit.record(
          "lifeline.host_follow_up",
          %{type: :job, id: job.id},
          %{
            "event_type" => "lifeline.host_follow_up",
            "incident_fingerprint" => incident.incident_fingerprint,
            "status" => status,
            "details" => details,
            "runbook_context" => %{
              "selected_path" => %{
                "ownership" => "Powertools-native",
                "venue" => "Powertools-native Lifeline"
              },
              "attempt" => %{
                "state" => "succeeded",
                "action" => "job_rescue",
                "target_type" => "job",
                "target_id" => Integer.to_string(job.id)
              }
            }
          },
          repo: TestRepo,
          actor_id: "ops-1"
        )

      status_conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_lifeline]}
        )

      {:ok, view, _html} = live(status_conn, "/ops/jobs/lifeline")

      html =
        view
        |> element("button[phx-value-row-id$=':job:#{job.id}'][phx-click='select_incident']")
        |> render_click()

      assert html =~ "host-owned follow-up status:"
      assert html =~ expected_label

      if expected_detail do
        assert html =~ expected_detail
      end
    end
  end

  test "ownership boundary remains explicit", %{conn: conn} do
    insert_missing_heartbeat!("ownership-boundary")
    incident = insert_dead_executor_incident!("ownership-boundary")
    job = insert_executing_job!("ownership-boundary")
    update_incident_job_ids!(incident, [job.id])

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-1",
          permissions: [:view_lifeline, :preview_repair]
        }
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

    html =
      view
      |> element("button[phx-value-row-id$=':job:#{job.id}'][phx-click='preview']")
      |> render_click()

    assert html =~ "Powertools-native"
    assert html =~ "Oban Web bridge"
    assert html =~ "host-owned follow-up"

    assert has_element?(
             view,
             ~s([data-runbook-ownership="Powertools-native"][data-runbook-variant="native_primary"])
           )

    assert has_element?(
             view,
             ~s([data-runbook-ownership="Oban Web bridge"][data-runbook-variant="bridge_guidance"])
           )

    assert has_element?(
             view,
             ~s([data-runbook-ownership="host-owned follow-up"][data-runbook-variant="host_guidance"])
           )

    refute has_element?(
             view,
             ~s([data-runbook-ownership="Oban Web bridge"][data-runbook-variant="native_primary"])
           )

    refute has_element?(
             view,
             ~s([data-runbook-ownership="host-owned follow-up"][data-runbook-variant="native_primary"])
           )

    refute html =~ "alert delivered"
    refute html =~ "ticket created"
    refute html =~ "page sent"
    refute html =~ "PagerDuty"
    refute html =~ "Slack"
  end

  test "shows shared preview_drifted wording when target state changes after preview", %{
    conn: conn
  } do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "repair-flow") |> Workflow.insert(TestRepo)

    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "notify")
    _incident = insert_workflow_incident!(workflow.id, step.id)

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-1",
          permissions: [:view_lifeline, :preview_repair, :execute_repair]
        }
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

    view
    |> element("button[phx-value-row-id$=':workflow_step:#{step.id}'][phx-click='preview']")
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

    assert html =~ "preview_drifted"
    assert has_element?(view, "button[phx-click='execute'][disabled]")
  end

  test "opens directly into a workflow-directed handoff and uses the canonical ready preview status",
       %{
         conn: conn
       } do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "workflow-directed-lifeline")
      |> Workflow.insert(TestRepo)

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-1",
          permissions: [:view_lifeline, :preview_repair, :execute_repair]
        }
      )

    {:ok, view, html} =
      live(
        conn,
        "/ops/jobs/lifeline?workflow_id=#{workflow.id}&step=sync_billing&action=workflow_step_retry"
      )

    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_billing")

    assert html =~ "Retry step for sync_billing"
    assert html =~ "Workflow blocker evidence"

    preview_html =
      view
      |> element(
        "button[phx-value-row-id='workflow_action:#{workflow.id}:#{step.id}:workflow_step_retry'][phx-click='preview']"
      )
      |> render_click()

    assert preview_html =~ "Preview Ready"
    assert preview_html =~ "Preview Status:"
    assert preview_html =~ "<strong>Preview Status:</strong> ready"
  end

  test "supports workflow-level request-cancel handoff copy without incident ownership", %{
    conn: conn
  } do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "request-cancel-handoff")
      |> Workflow.insert(TestRepo)

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-1",
          permissions: [:view_lifeline, :preview_repair, :execute_repair]
        }
      )

    {:ok, view, html} =
      live(conn, "/ops/jobs/lifeline?workflow_id=#{workflow.id}&action=workflow_request_cancel")

    assert html =~ "Request cancel for workflow"

    preview_html =
      view
      |> element(
        "button[phx-value-row-id='workflow_action:#{workflow.id}:workflow:workflow_request_cancel'][phx-click='preview']"
      )
      |> render_click()

    assert preview_html =~ "Request cancel"
    assert preview_html =~ "Idle work may stop immediately while in-flight work can still finish."
  end

  test "executes repair, moves the incident into resolved view, and preserves inline audit history across remount",
       %{conn: conn} do
    insert_missing_heartbeat!("executor-missing")
    incident = insert_dead_executor_incident!("executor-missing")
    job = insert_executing_job!("executor-missing")
    update_incident_job_ids!(incident, [job.id])

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-1",
          permissions: [:view_lifeline, :preview_repair, :execute_repair]
        }
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

    view
    |> element("button[phx-value-row-id$=':job:#{job.id}'][phx-click='preview']")
    |> render_click()

    render_change(view, "reason", %{"reason" => "Rescuing orphaned job after node loss"})
    html = render_click(view, "execute", %{})

    assert html =~ "Repair executed and audit evidence was written."
    assert html =~ "Resolved Incidents"
    assert html =~ "Manual Intervention History"
    assert html =~ "policy reason: RESCUING ORPHANED JOB AFTER NODE LOSS"

    assert html =~
             "/ops/jobs/audit?resource_type=job&amp;resource_id=#{job.id}&amp;event_type=lifeline.repair_executed"

    refute html =~ "Preview Native Remediation"
    refute has_element?(view, "button[phx-value-row-id$=':job:#{job.id}'][phx-click='preview']")

    remounted_conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-1",
          permissions: [:view_lifeline, :preview_repair, :execute_repair]
        }
      )

    {:ok, remounted_view, remounted_html} = live(remounted_conn, "/ops/jobs/lifeline")

    assert remounted_html =~ "Needs Review"
    refute remounted_html =~ "Rescuing orphaned job after node loss"

    refute has_element?(
             remounted_view,
             "button[phx-value-row-id$=':job:#{job.id}'][phx-click='preview']"
           )

    resolved_html =
      remounted_view
      |> element("button[phx-click='toggle_view'][phx-value-view='resolved']")
      |> render_click()

    assert resolved_html =~ "Resolved Incidents"
    assert resolved_html =~ "policy reason: RESCUING ORPHANED JOB AFTER NODE LOSS"
    assert resolved_html =~ "Manual Intervention History"

    events = Audit.list(%{type: :job, id: Integer.to_string(job.id)}, repo: TestRepo)
    assert Enum.any?(events, &(&1.action == "lifeline.repair_executed"))
    assert Enum.any?(events, &(&1.action == "lifeline.host_follow_up"))
  end

  test "unauthorized execute keeps the incident in Needs Review instead of moving it into resolved",
       %{conn: conn} do
    insert_missing_heartbeat!("executor-missing")
    incident = insert_dead_executor_incident!("executor-missing")
    job = insert_executing_job!("executor-missing")
    update_incident_job_ids!(incident, [job.id])

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_lifeline, :preview_repair]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

    view
    |> element("button[phx-value-row-id$=':job:#{job.id}'][phx-click='preview']")
    |> render_click()

    render_change(view, "reason", %{"reason" => "Operator can preview but cannot execute"})
    html = render_click(view, "execute", %{})

    assert html =~ "Permission: read-only."

    assert html =~
             "Permission: read-only. You can inspect this Powertools-native preview, but you do not have permission to execute this Audited action."

    assert html =~ "Needs Review"

    resolved_html =
      view
      |> element("button[phx-click='toggle_view'][phx-value-view='resolved']")
      |> render_click()

    refute resolved_html =~ "Rescuing orphaned job after node loss"
    refute resolved_html =~ "Repair executed and audit evidence was written."
  end

  test "renders page-level read-only framing and disabled preview explanation for viewers", %{
    conn: conn
  } do
    insert_missing_heartbeat!("viewer-missing")
    incident = insert_dead_executor_incident!("viewer-missing")
    job = insert_executing_job!("viewer-missing")
    update_incident_job_ids!(incident, [job.id])

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-viewer", permissions: [:view_lifeline]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/lifeline")

    assert html =~ "Permission: read-only."

    assert has_element?(
             view,
             "button[phx-value-row-id$=':job:#{job.id}'][phx-click='preview'][disabled]"
           )

    assert html =~
             "Permission: read-only. You can inspect this Powertools-native incident, but you do not have permission to preview this Audited action."
  end

  test "patches durable params for selected incidents and resolved continuity", %{conn: conn} do
    insert_missing_heartbeat!("patch-missing")
    active_incident = insert_dead_executor_incident!("patch-missing")
    active_job = insert_executing_job!("patch-missing")
    update_incident_job_ids!(active_incident, [active_job.id])

    resolved_incident =
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "dead_executor",
        status: "resolved",
        executor_id: "patch-resolved",
        incident_fingerprint: "dead_executor:patch-resolved",
        health_state: "resolved",
        summary: "resolved executor patch-resolved",
        affected_counts: %{"jobs" => 1, "workflow_steps" => 0},
        evidence: %{"job_ids" => [999], "workflow_step_ids" => []},
        first_detected_at: DateTime.utc_now(),
        last_detected_at: DateTime.utc_now(),
        resolved_at: DateTime.utc_now(),
        metadata: %{}
      })
      |> TestRepo.insert!()

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-viewer", permissions: [:view_lifeline]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

    view
    |> element("button[phx-value-row-id$=':job:#{active_job.id}'][phx-click='select_incident']")
    |> render_click()

    assert_patch(
      view,
      "/ops/jobs/lifeline?view=active&incident_fingerprint=#{URI.encode_www_form(active_incident.incident_fingerprint)}&row-id=#{URI.encode_www_form("#{active_incident.id}:job:#{active_job.id}")}"
    )

    view
    |> element("button[phx-click='toggle_view'][phx-value-view='resolved']")
    |> render_click()

    assert_patch(
      view,
      "/ops/jobs/lifeline?view=resolved&incident_fingerprint=#{URI.encode_www_form(active_incident.incident_fingerprint)}&row-id=#{URI.encode_www_form("#{active_incident.id}:job:#{active_job.id}")}"
    )

    {:ok, _remounted_view, remounted_html} =
      live(
        conn,
        "/ops/jobs/lifeline?view=resolved&incident_fingerprint=#{resolved_incident.incident_fingerprint}"
      )

    assert remounted_html =~ "Resolved Incidents"
    assert remounted_html =~ "resolved executor patch-resolved"
  end

  test "authorized but unattributable operators cannot create durable preview or execute writes",
       %{
         conn: conn
       } do
    insert_missing_heartbeat!("executor-missing")
    incident = insert_dead_executor_incident!("executor-missing")
    job = insert_executing_job!("executor-missing")
    update_incident_job_ids!(incident, [job.id])

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-7",
          permissions: [:view_lifeline, :preview_repair, :execute_repair],
          audit_principal: nil
        }
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

    preview_html =
      view
      |> element("button[phx-value-row-id$=':job:#{job.id}'][phx-click='preview']")
      |> render_click()

    assert preview_html =~
             "Oban Powertools could not derive a durable audit principal for this action."

    refute preview_html =~ "Preview Ready"
    assert TestRepo.all(ObanPowertools.Lifeline.RepairPreview) == []

    render_change(view, "reason", %{"reason" => "Rescuing orphaned job after node loss"})
    execute_html = render_click(view, "execute", %{})

    assert execute_html =~
             "Oban Powertools could not derive a durable audit principal for this action."

    refute execute_html =~ "Repair executed and audit evidence was written."
    assert Audit.list(%{type: :job, id: Integer.to_string(job.id)}, repo: TestRepo) == []
  end

  test "renders a forensic entry link that preserves incident scope and view selectors", %{
    conn: conn
  } do
    insert_missing_heartbeat!("forensics-link-executor")
    incident = insert_dead_executor_incident!("forensics-link-executor")
    job = insert_executing_job!("forensics-link-executor")
    update_incident_job_ids!(incident, [job.id])

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_lifeline, :view_forensics]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

    view
    |> element("button[phx-value-row-id$=':job:#{job.id}'][phx-click='select_incident']")
    |> render_click()

    selected_html = render(view)

    assert selected_html =~ "Open the forensic bundle."
    assert selected_html =~ "Inspection only"
    assert has_element?(view, "a[href*='/ops/jobs/forensics?']")

    assert has_element?(
             view,
             "a[href*='incident_fingerprint=#{URI.encode_www_form(incident.incident_fingerprint)}']"
           )

    assert has_element?(view, "a[href*='view=active']")
    assert has_element?(view, "a[href*='resource_type=job']")
    assert_forensics_selector_allowlist(selected_html)
    refute selected_html =~ "preview_token="
    refute selected_html =~ "reason="
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
      evidence: %{
        "job_ids" => job_ids,
        "workflow_step_ids" => [],
        "last_heartbeat_at" => DateTime.utc_now()
      }
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
    |> Oban.Job.new(
      worker: "Example.Worker",
      queue: :default,
      meta: %{"executor_id" => executor_id}
    )
    |> Changeset.change(state: "executing")
    |> TestRepo.insert!()
  end

  defp insert_missing_heartbeat!(executor_id) do
    %ObanPowertools.Lifeline.Heartbeat{}
    |> ObanPowertools.Lifeline.Heartbeat.changeset(%{
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

  defp html_position(html, text) do
    {position, _length} = :binary.match(html, text)
    position
  end

  defp assert_forensics_selector_allowlist(html) do
    Regex.scan(~r{/ops/jobs/forensics\?[^"']+}, html)
    |> Enum.map(&List.first/1)
    |> Enum.each(fn encoded_path ->
      query =
        encoded_path
        |> String.split("?", parts: 2)
        |> List.last()
        |> String.replace("&amp;", "&")
        |> URI.decode_query()
        |> Map.keys()
        |> MapSet.new()

      assert MapSet.subset?(query, @allowed_selector_keys)
    end)
  end
end
