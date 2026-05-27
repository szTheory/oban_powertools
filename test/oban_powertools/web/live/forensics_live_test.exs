defmodule ObanPowertools.Web.ForensicsLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.Audit
  alias ObanPowertools.Cron
  alias ObanPowertools.Forensics.LimiterHistoryFact
  alias ObanPowertools.Lifeline.Incident
  alias ObanPowertools.Limits.{Resource, State}
  alias ObanPowertools.Workflow
  alias ObanPowertools.WorkflowFixtures

  @allowed_selector_keys MapSet.new([
    "resource_type",
    "resource_id",
    "workflow_id",
    "step",
    "incident_fingerprint",
    "view"
  ])

  test "mounts the workflow forensic bundle and preserves step scope across remount", %{
    conn: conn
  } do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "forensics-live-workflow")
      |> Workflow.insert(TestRepo)

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_forensics, :view_workflows]}
      )

    {:ok, _view, html} =
      live(
        conn,
        "/ops/jobs/forensics?workflow_id=#{workflow.id}&step=sync_billing&resource_type=workflow_step"
      )

    assert html =~ "Forensics"
    assert html =~ "Diagnosis Summary"
    assert html =~ "Timeline"
    assert html =~ "supporting evidence"
    assert html =~ "partial evidence"
    assert html =~ "workflow_id=#{workflow.id}"
    assert html =~ "step=sync_billing"

    {:ok, _remounted_view, remounted_html} =
      live(
        conn,
        "/ops/jobs/forensics?workflow_id=#{workflow.id}&step=sync_billing&resource_type=workflow_step"
      )

    assert remounted_html =~ "sync_billing"
    refute remounted_html =~ "preview_token="
    refute remounted_html =~ "reason="
    refute remounted_html =~ "diagnosis="
    refute remounted_html =~ "refusal="
  end

  test "mounts the lifeline forensic bundle and preserves incident scope across remount", %{
    conn: conn
  } do
    incident =
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "dead_executor",
        status: "active",
        executor_id: "forensics-live-executor",
        incident_fingerprint: "dead_executor:forensics-live-executor",
        health_state: "missing",
        summary: "missing executor forensics-live-executor",
        affected_counts: %{"jobs" => 1, "workflow_steps" => 0},
        evidence: %{"job_ids" => [123], "workflow_step_ids" => []},
        first_detected_at: DateTime.utc_now(),
        last_detected_at: DateTime.utc_now(),
        metadata: %{}
      })
      |> TestRepo.insert!()

    {:ok, _event} =
      Audit.record(
        "lifeline.repair_executed",
        %{type: :job, id: 123},
        %{
          "event_type" => "lifeline.repair_executed",
          "incident_fingerprint" => incident.incident_fingerprint,
          "reason" => "Operator rescued orphaned execution",
          "runbook_context" => %{
            "selected_path" => %{
              "ownership" => "Powertools-native",
              "venue" => "Powertools-native Lifeline"
            },
            "attempt" => %{
              "state" => "succeeded",
              "action" => "job_rescue",
              "target_type" => "job",
              "target_id" => "123"
            }
          }
        },
        repo: TestRepo,
        actor_id: "ops-1"
      )

    {:ok, _follow_up_event} =
      Audit.record(
        "lifeline.host_follow_up",
        %{type: :job, id: 123},
        %{
          "event_type" => "lifeline.host_follow_up",
          "incident_fingerprint" => incident.incident_fingerprint,
          "status" => "host_owned_follow_up_callback_invoked",
          "details" => %{"result" => "ok"},
          "preview_token" => "preview-123"
        },
        repo: TestRepo,
        actor_id: "ops-1"
      )

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_forensics, :view_lifeline]}
      )

    path =
      "/ops/jobs/forensics?incident_fingerprint=#{URI.encode_www_form(incident.incident_fingerprint)}&view=active&resource_type=job&resource_id=123"

    {:ok, _view, html} = live(conn, path)

    assert html =~ "Powertools-native Lifeline"
    assert html =~ "Inspection only"
    assert html =~ "resource_type=job"
    assert html =~ "resource_id=123"
    assert html =~ "Latest runbook continuity"
    assert html =~ "Diagnosis:"
    assert html =~ "Legal next path:"
    assert html =~ "Venue:"
    assert html =~ "Attempt state:"
    assert html =~ "Evidence link:"
    assert html =~ "Audit follow-up:"
    assert html =~ "Reason:"
    assert html =~ "host-owned follow-up status:"
    assert html =~ "Host-owned follow-up callback invoked"
    assert html =~ "Operator rescued orphaned execution"
    assert html =~ "host-owned follow-up"

    diagnosis_position = html_position(html, "Diagnosis:")
    legal_path_position = html_position(html, "Legal next path:")
    venue_position = html_position(html, "Venue:")
    attempt_position = html_position(html, "Attempt state:")
    evidence_link_position = html_position(html, "Evidence link:")
    audit_follow_up_position = html_position(html, "Audit follow-up:")

    assert diagnosis_position < legal_path_position
    assert legal_path_position < venue_position
    assert venue_position < attempt_position
    assert attempt_position < evidence_link_position
    assert evidence_link_position < audit_follow_up_position
    assert_forensics_selector_allowlist(html)

    {:ok, _remounted_view, remounted_html} = live(conn, path)

    assert remounted_html =~ incident.incident_fingerprint
    assert remounted_html =~ "Latest runbook continuity"
  end

  test "renders failed host-owned follow-up status with explicit warning detail", %{conn: conn} do
    incident =
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "dead_executor",
        status: "active",
        executor_id: "forensics-live-failed-follow-up",
        incident_fingerprint: "dead_executor:forensics-live-failed-follow-up",
        health_state: "missing",
        summary: "missing executor forensics-live-failed-follow-up",
        affected_counts: %{"jobs" => 1, "workflow_steps" => 0},
        evidence: %{"job_ids" => [321], "workflow_step_ids" => []},
        first_detected_at: DateTime.utc_now(),
        last_detected_at: DateTime.utc_now(),
        metadata: %{}
      })
      |> TestRepo.insert!()

    {:ok, _repair_event} =
      Audit.record(
        "lifeline.repair_executed",
        %{type: :job, id: 321},
        %{
          "event_type" => "lifeline.repair_executed",
          "incident_fingerprint" => incident.incident_fingerprint,
          "reason" => "Operator retried job",
          "runbook_context" => %{
            "selected_path" => %{
              "ownership" => "Powertools-native",
              "venue" => "Powertools-native Lifeline"
            },
            "attempt" => %{
              "state" => "succeeded",
              "action" => "job_retry",
              "target_type" => "job",
              "target_id" => "321"
            }
          }
        },
        repo: TestRepo,
        actor_id: "ops-1"
      )

    {:ok, _follow_up_event} =
      Audit.record(
        "lifeline.host_follow_up",
        %{type: :job, id: 321},
        %{
          "event_type" => "lifeline.host_follow_up",
          "incident_fingerprint" => incident.incident_fingerprint,
          "status" => "host_owned_follow_up_callback_failed",
          "details" => %{"reason" => "callback timeout"},
          "preview_token" => "preview-321"
        },
        repo: TestRepo,
        actor_id: "ops-1"
      )

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_forensics, :view_lifeline]}
      )

    path =
      "/ops/jobs/forensics?incident_fingerprint=#{URI.encode_www_form(incident.incident_fingerprint)}&view=active&resource_type=job&resource_id=321"

    {:ok, _view, html} = live(conn, path)

    assert html =~ "host-owned follow-up status:"
    assert html =~ "Host-owned follow-up callback failed"
    assert html =~ "callback timeout"
  end

  test "redirects unauthorized viewers", %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-2", permissions: []})
    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/forensics")
  end

  test "mounts the cron forensic bundle from stable resource selectors", %{conn: conn} do
    {:ok, entry} =
      Cron.sync_entry(TestRepo, %{
        name: "forensics-cron",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    slot_at = truncate_minute(DateTime.add(DateTime.utc_now(), -120, :second))
    assert {:ok, _coverage} = Cron.record_coverage(TestRepo, entry, slot_at, status: "healthy")

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-3", permissions: [:view_forensics, :view_cron]}
      )

    {:ok, _view, html} =
      live(conn, "/ops/jobs/forensics?resource_type=cron_entry&resource_id=#{entry.name}")

    assert html =~ "Powertools-native cron"
    assert html =~ "Missed fire"
    assert html =~ "complete"
  end

  test "renders canonical runbook entry after diagnosis and before timeline", %{conn: conn} do
    {:ok, entry} =
      Cron.sync_entry(TestRepo, %{
        name: "forensics-runbook-cron",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    slot_at = truncate_minute(DateTime.add(DateTime.utc_now(), -120, :second))
    assert {:ok, _coverage} = Cron.record_coverage(TestRepo, entry, slot_at, status: "healthy")

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-5", permissions: [:view_forensics, :view_cron]}
      )

    {:ok, _view, html} =
      live(conn, "/ops/jobs/forensics?resource_type=cron_entry&resource_id=#{entry.name}")

    diagnosis_position = html_position(html, "Diagnosis Summary")
    runbook_position = html_position(html, "Open runbook entry")
    timeline_position = html_position(html, "Timeline")

    assert diagnosis_position < runbook_position
    assert runbook_position < timeline_position

    assert html =~ "Diagnosis state"
    assert html =~ "Why it matters now"
    assert html =~ "Prerequisites"
    assert html =~ "Cautions"
    assert html =~ "Recommended order"
    assert html =~ "Unsupported boundaries"
    assert html =~ "Evidence link"
    assert html =~ "Evidence completeness"
    assert html =~ "Powertools-native"
    assert html =~ "Oban Web bridge"
    assert html =~ "host-owned follow-up"
  end

  test "renders degraded runbook guidance and non-native next paths as bordered guidance", %{
    conn: conn
  } do
    {:ok, entry} =
      Cron.sync_entry(TestRepo, %{
        name: "forensics-runbook-unknown",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-6", permissions: [:view_forensics, :view_cron]}
      )

    {:ok, _view, html} =
      live(conn, "/ops/jobs/forensics?resource_type=cron_entry&resource_id=#{entry.name}")

    assert html =~ "history unavailable"
    assert html =~ "unknown"
    assert html =~ ~s(data-runbook-ownership="Oban Web bridge")
    assert html =~ ~s(data-runbook-ownership="host-owned follow-up")
    refute html =~ ~s(data-runbook-ownership="Oban Web bridge" class="rounded bg-indigo-700)
    refute html =~ ~s(data-runbook-ownership="host-owned follow-up" class="rounded bg-indigo-700)
    refute html =~ "bridge-only completed"
    refute html =~ "host-owned follow-up succeeded"
  end

  test "ownership boundary remains explicit", %{conn: conn} do
    {:ok, entry} =
      Cron.sync_entry(TestRepo, %{
        name: "forensics-ownership-boundary",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    connection =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-7", permissions: [:view_forensics, :view_cron]}
      )

    {:ok, view, html} =
      live(connection, "/ops/jobs/forensics?resource_type=cron_entry&resource_id=#{entry.name}")

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

  test "mounts the limiter forensic bundle from stable resource selectors", %{conn: conn} do
    resource =
      TestRepo.insert!(%Resource{
        name: "forensics-limiter",
        scope_kind: "global",
        algorithm: "token_bucket",
        bucket_span_ms: 60_000,
        bucket_capacity: 5,
        default_weight: 1,
        partition_strategy: "global",
        partition_config: %{},
        cooldown_enabled: true,
        metadata: %{}
      })

    TestRepo.insert!(%State{
      resource_id: resource.id,
      partition_key: "__global__",
      tokens_used: 0,
      bucket_started_at: DateTime.utc_now(),
      reservation_snapshot: %{}
    })

    TestRepo.insert!(%LimiterHistoryFact{
      resource_name: resource.name,
      partition_key: "__global__",
      event_type: "limiter.reconfigured",
      cause_kind: "policy",
      occurred_at: DateTime.utc_now(),
      metadata: %{"config_diff" => %{"bucket_capacity" => %{"before" => 3, "after" => 5}}}
    })

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-4", permissions: [:view_forensics, :view_limiters]}
      )

    {:ok, _view, html} =
      live(conn, "/ops/jobs/forensics?resource_type=limiter&resource_id=#{resource.name}")

    assert html =~ "Powertools-native limiters"
    assert html =~ "Limiter reconfigured"
    assert html =~ "complete"
  end

  defp truncate_minute(%DateTime{} = dt), do: %DateTime{dt | second: 0, microsecond: {0, 0}}

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
