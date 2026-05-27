defmodule ObanPowertools.Web.CronLiveTestDisplayPolicy do
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

defmodule ObanPowertools.Web.CronLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.{Audit, Cron}
  alias ObanPowertools.Lifeline.RepairPreview

  setup do
    original_display_policy = Application.get_env(:oban_powertools, :display_policy)

    Application.put_env(
      :oban_powertools,
      :display_policy,
      ObanPowertools.Web.CronLiveTestDisplayPolicy
    )

    test_pid = self()

    :telemetry.attach_many(
      "cron-live-test",
      [
        [:oban_powertools, :operator_action, :previewed],
        [:oban_powertools, :operator_action, :complete],
        [:oban_powertools, :cron, :paused],
        [:oban_powertools, :cron, :run_now]
      ],
      fn name, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach("cron-live-test")
      Application.put_env(:oban_powertools, :display_policy, original_display_policy)
    end)

    :ok
  end

  test "shows source badges and runs durable preview-first pause flow", %{conn: conn} do
    {:ok, _} =
      Cron.sync_entry(TestRepo, %{
        name: "nightly",
        source: "code",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *",
        overlap_policy: "queue_one",
        catch_up_policy: "latest"
      })

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_cron, :pause_cron_entry]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/cron")
    assert html =~ "Code"
    assert html =~ "Queue One"
    assert html =~ "Latest Only"

    html =
      view
      |> element("button[phx-value-action='pause_cron_entry']")
      |> render_click()

    assert html =~ "Preview Action"
    assert html =~ "Preview Status"
    assert html =~ "Preview Token"
    assert html =~ "Audit Consequence"
    assert html =~ "One immutable operator event will be written."
    assert html =~ "policy actor: operator:ops-1"
    assert html =~ "policy reason: none provided"

    [preview] = TestRepo.all(RepairPreview)
    assert html =~ preview.preview_token
    assert preview.status == "ready"

    assert_receive {:telemetry_event, [:oban_powertools, :operator_action, :previewed],
                    %{count: 1}, %{action: "pause_cron_entry", source: "code"}}

    render_change(view, "reason", %{"reason" => "maintenance"})
    assert render(view) =~ "policy reason: MAINTENANCE"
    html = render_click(view, "confirm", %{})

    assert html =~ "Waiting"
    assert_receive {:telemetry_event, [:oban_powertools, :cron, :paused], %{count: 1}, _}

    assert_receive {:telemetry_event, [:oban_powertools, :operator_action, :complete],
                    %{count: 1}, %{action: "pause_cron_entry", source: "code"}}

    [event | _] = Audit.list(%{type: :cron_entry, id: "nightly"}, repo: TestRepo)
    assert event.action == "cron.paused"
    assert event.actor_id == "ops-1"
    assert event.metadata["reason"] == "maintenance"
    assert event.metadata["preview_token"]

    assert html =~
             "/ops/jobs/audit?resource_type=cron_entry&amp;resource_id=nightly&amp;event_type=cron.paused"
  end

  test "blocks unauthorized cron mutation before preview state", %{conn: conn} do
    {:ok, _} =
      Cron.sync_entry(TestRepo, %{
        name: "runtime-sync",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    conn =
      Plug.Test.init_test_session(conn, current_actor: %{id: "ops-2", permissions: [:view_cron]})

    {:ok, view, html} = live(conn, "/ops/jobs/cron")

    assert html =~ "Permission: read-only."
    assert html =~ "disabled"

    assert html =~
             "Permission: read-only. You can inspect this Powertools-native cron entry, but you do not have permission to preview or execute this Audited action."

    refute has_element?(view, "h2", "Preview Action")
  end

  test "blocks unauthorized cron preview before preview state or telemetry", %{conn: conn} do
    {:ok, _} =
      Cron.sync_entry(TestRepo, %{
        name: "unauthorized-preview",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    conn =
      Plug.Test.init_test_session(conn, current_actor: %{id: "ops-4", permissions: [:view_cron]})

    {:ok, view, html} = live(conn, "/ops/jobs/cron")

    assert html =~ "Permission: read-only."
    assert html =~ "disabled"

    assert html =~
             "Permission: read-only. You can inspect this Powertools-native cron entry, but you do not have permission to preview or execute this Audited action."

    html =
      render_click(view, "preview", %{
        "action" => "pause_cron_entry",
        "entry" => "unauthorized-preview"
      })

    assert html =~
             "Permission: read-only. You can inspect this Powertools-native cron entry, but you do not have permission to preview or execute this Audited action."

    refute has_element?(view, "h2", "Preview Action")
    refute_receive {:telemetry_event, [:oban_powertools, :operator_action, :previewed], _, _}
    refute_receive {:telemetry_event, [:oban_powertools, :operator_action, :complete], _, _}
    assert Audit.list(%{type: :cron_entry, id: "unauthorized-preview"}, repo: TestRepo) == []
  end

  test "renders disabled cron actions with inline permission explanations for viewers", %{
    conn: conn
  } do
    {:ok, runnable_entry} =
      Cron.sync_entry(TestRepo, %{
        name: "viewer-runnable",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    {:ok, paused_entry} =
      Cron.sync_entry(TestRepo, %{
        name: "viewer-paused",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    {:ok, _paused_entry} = Cron.pause_entry(TestRepo, paused_entry, "ops-seed", reason: "seed")

    conn =
      Plug.Test.init_test_session(conn, current_actor: %{id: "ops-5", permissions: [:view_cron]})

    {:ok, view, html} = live(conn, "/ops/jobs/cron")

    assert html =~ "Permission: read-only."

    assert has_element?(
             view,
             "button[phx-value-entry='#{runnable_entry.name}'][phx-value-action='pause_cron_entry'][disabled]"
           )

    assert has_element?(
             view,
             "button[phx-value-entry='#{runnable_entry.name}'][phx-value-action='run_cron_entry'][disabled]"
           )

    assert has_element?(
             view,
             "button[phx-value-entry='#{paused_entry.name}'][phx-value-action='resume_cron_entry'][disabled]"
           )

    assert has_element?(
             view,
             "button[phx-value-entry='#{paused_entry.name}'][phx-value-action='run_cron_entry'][disabled]"
           )

    assert html =~
             "Permission: read-only. You can inspect this Powertools-native cron entry, but you do not have permission to preview or execute this Audited action."

    assert html =~
             "Permission: read-only. You can inspect this Powertools-native cron entry, but you do not have permission to preview or execute this Audited action."

    assert html =~
             "Permission: read-only. You can inspect this Powertools-native cron entry, but you do not have permission to preview or execute this Audited action."
  end

  test "restores selected cron entry from entry param without restoring preview state", %{
    conn: conn
  } do
    {:ok, entry} =
      Cron.sync_entry(TestRepo, %{
        name: "selected-entry",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    conn =
      Plug.Test.init_test_session(conn, current_actor: %{id: "ops-5", permissions: [:view_cron]})

    {:ok, _view, html} = live(conn, "/ops/jobs/cron?entry=#{entry.name}")
    assert html =~ "selected-entry"
    assert html =~ "entry="
    refute html =~ "Preview Token"

    {:ok, _remounted_view, remounted_html} = live(conn, "/ops/jobs/cron?entry=#{entry.name}")
    assert remounted_html =~ "selected-entry"
    refute remounted_html =~ "Preview Token"
  end

  test "fails explicitly when an authorized cron operator has no durable audit principal", %{
    conn: conn
  } do
    {:ok, _} =
      Cron.sync_entry(TestRepo, %{
        name: "missing-principal",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-6",
          permissions: [:view_cron, :pause_cron_entry],
          audit_principal: nil
        }
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/cron")

    view
    |> element("button[phx-value-action='pause_cron_entry'][phx-value-entry='missing-principal']")
    |> render_click()

    render_change(view, "reason", %{"reason" => "missing principal"})
    html = render_click(view, "confirm", %{})

    assert html =~ "Oban Powertools could not derive a durable audit principal for this action."
    refute html =~ "Waiting"
    refute_receive {:telemetry_event, [:oban_powertools, :cron, :paused], _, _}
    refute_receive {:telemetry_event, [:oban_powertools, :operator_action, :complete], _, _}
    assert Audit.list(%{type: :cron_entry, id: "missing-principal"}, repo: TestRepo) == []

    entry = Enum.find(Cron.list_entries(TestRepo), &(&1.name == "missing-principal"))
    assert is_nil(entry.paused_at)
  end

  test "renders explicit shared preview-state failures from persisted cron previews", %{
    conn: conn
  } do
    {:ok, _} =
      Cron.sync_entry(TestRepo, %{
        name: "preview-states",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-8", permissions: [:view_cron, :pause_cron_entry]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/cron")

    view
    |> element("button[phx-value-action='pause_cron_entry'][phx-value-entry='preview-states']")
    |> render_click()

    [preview] = TestRepo.all(RepairPreview)

    TestRepo.update!(RepairPreview.changeset(preview, %{status: "expired"}))
    expired_html = render_click(view, "confirm", %{})
    assert expired_html =~ "preview_expired"

    refreshed_preview = TestRepo.get!(RepairPreview, preview.id)

    TestRepo.update!(
      RepairPreview.changeset(refreshed_preview, %{
        status: "drifted",
        metadata: %{"drift_reason" => "entry changed"}
      })
    )

    drifted_html = render_click(view, "confirm", %{})
    assert drifted_html =~ "preview_drifted"

    drifted_preview = TestRepo.get!(RepairPreview, preview.id)

    TestRepo.update!(
      RepairPreview.changeset(drifted_preview, %{
        status: "consumed",
        consumed_at: DateTime.utc_now()
      })
    )

    consumed_html = render_click(view, "confirm", %{})
    assert consumed_html =~ "preview_consumed"

    entry = Enum.find(Cron.list_entries(TestRepo), &(&1.name == "preview-states"))
    assert is_nil(entry.paused_at)
  end

  test "renders history summary and forensic handoff for selected entries", %{conn: conn} do
    {:ok, entry} =
      Cron.sync_entry(TestRepo, %{
        name: "forensic-entry",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    slot_at = truncate_minute(DateTime.add(DateTime.utc_now(), -120, :second))
    assert {:ok, _coverage} = Cron.record_coverage(TestRepo, entry, slot_at, status: "healthy")

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-9", permissions: [:view_cron, :view_forensics]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs/cron?entry=#{entry.name}")

    assert html =~ "History Summary"
    assert html =~ "Open runbook entry"
    assert html =~ "No slot claim was recorded while scheduler coverage was healthy."
    assert html =~ "Powertools-native"
    assert html =~ "Oban Web bridge"
    assert html =~ "host-owned follow-up"
    assert html =~ "partial evidence"
    assert html =~ "history unavailable"
    assert html =~ "Open forensic timeline"
    assert html =~ "Missed fire"
    assert html =~ "/ops/jobs/forensics?resource_type=cron_entry&amp;resource_id=forensic-entry"
  end

  test "ownership boundary remains explicit", %{conn: conn} do
    {:ok, entry} =
      Cron.sync_entry(TestRepo, %{
        name: "ownership-boundary-cron",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    slot_at = truncate_minute(DateTime.add(DateTime.utc_now(), -120, :second))
    assert {:ok, _coverage} = Cron.record_coverage(TestRepo, entry, slot_at, status: "healthy")

    connection =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-10", permissions: [:view_cron, :view_forensics]}
      )

    {:ok, view, html} = live(connection, "/ops/jobs/cron?entry=#{entry.name}")

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

  defp truncate_minute(%DateTime{} = dt), do: %DateTime{dt | second: 0, microsecond: {0, 0}}
end
