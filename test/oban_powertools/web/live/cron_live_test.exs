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

    {:ok, view, html} = live(conn, "/ops/jobs/cron?entry=nightly")
    assert html =~ "Code"
    assert html =~ "Queue One"
    assert html =~ "Latest Only"
    assert has_element?(view, "button", "Pause cron entry")

    html =
      view
      |> element("button", "Pause cron entry")
      |> render_click()

    assert has_element?(view, "#cron-confirmation-dialog[role='dialog']")

    assert html =~
             "Future schedule claims stop. Work that is already running or enqueued is unaffected."

    assert html =~ "Keep running"
    assert html =~ "policy actor: operator:ops-1"
    assert html =~ "Do not enter secrets"

    [preview] = TestRepo.all(RepairPreview)
    refute html =~ preview.preview_token
    assert preview.status == "ready"

    assert_receive {:telemetry_event, [:oban_powertools, :operator_action, :previewed],
                    %{count: 1}, %{action: "pause_cron_entry", source: "code"}}

    html =
      view
      |> form("#cron-confirmation-form", %{
        "confirmation" => %{"reason" => "maintenance"}
      })
      |> render_submit()

    assert html =~ "Waiting"
    assert html =~ "Cron entry nightly paused. Audit evidence recorded."
    assert_receive {:telemetry_event, [:oban_powertools, :cron, :paused], %{count: 1}, _}

    assert_receive {:telemetry_event, [:oban_powertools, :operator_action, :complete],
                    %{count: 1}, %{action: "pause_cron_entry", source: "code"}}

    [event | _] = Audit.list(%{type: :cron_entry, id: "nightly"}, repo: TestRepo)
    assert event.action == "cron.paused"
    assert event.actor_id == "ops-1"
    assert event.metadata["reason"] == "maintenance"
    assert event.metadata["preview_token"]

    assert html =~ "/ops/jobs/audit?resource_type=cron_entry&amp;resource_id=nightly"
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

    {:ok, view, html} = live(conn, "/ops/jobs/cron?entry=runtime-sync")

    assert html =~ "Permission: read-only."
    assert html =~ "disabled"

    assert html =~
             "Permission: read-only. You can inspect this Powertools-native cron entry, but you do not have permission to preview or execute this Audited action."

    assert has_element?(view, "#cron-entry-detail")
    refute has_element?(view, "#cron-confirmation")
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

    {:ok, view, html} = live(conn, "/ops/jobs/cron?entry=unauthorized-preview")

    assert html =~ "Permission: read-only."
    assert html =~ "disabled"

    assert html =~
             "Permission: read-only. You can inspect this Powertools-native cron entry, but you do not have permission to preview or execute this Audited action."

    assert has_element?(view, "button[disabled]", "Pause cron entry")
    assert has_element?(view, "button[disabled]", "Run cron entry now")
    refute has_element?(view, "#cron-confirmation")
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

    {:ok, view, html} = live(conn, "/ops/jobs/cron?entry=#{runnable_entry.name}")

    assert html =~ "Permission: read-only."

    assert has_element?(
             view,
             "#cron-entry-detail button[disabled]",
             "Pause cron entry"
           )

    assert has_element?(
             view,
             "#cron-entry-detail button[disabled]",
             "Run cron entry now"
           )

    {:ok, paused_view, _paused_html} =
      live(conn, "/ops/jobs/cron?entry=#{paused_entry.name}")

    assert has_element?(paused_view, "#cron-entry-detail button[disabled]", "Resume cron entry")
    assert has_element?(paused_view, "#cron-entry-detail button[disabled]", "Run cron entry now")

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
    refute html =~ "preview_token"
    refute html =~ "plan_hash"

    {:ok, _remounted_view, remounted_html} = live(conn, "/ops/jobs/cron?entry=#{entry.name}")
    assert remounted_html =~ "selected-entry"
    refute remounted_html =~ "preview_token"
    refute remounted_html =~ "plan_hash"
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

    {:ok, view, _html} = live(conn, "/ops/jobs/cron?entry=missing-principal")
    assert has_element?(view, "button", "Pause cron entry")

    view
    |> element("button", "Pause cron entry")
    |> render_click()

    html =
      view
      |> form("#cron-confirmation-form", %{
        "confirmation" => %{"reason" => "missing principal"}
      })
      |> render_submit()

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

    {:ok, view, _html} = live(conn, "/ops/jobs/cron?entry=preview-states")
    assert has_element?(view, "button", "Pause cron entry")

    view
    |> element("button", "Pause cron entry")
    |> render_click()

    [preview] = TestRepo.all(RepairPreview)

    TestRepo.update!(RepairPreview.changeset(preview, %{status: "expired"}))

    expired_html =
      view
      |> form("#cron-confirmation-form", %{
        "confirmation" => %{"reason" => "maintenance window"}
      })
      |> render_submit()

    assert expired_html =~ "This preview expired."
    assert expired_html =~ "Create new preview"

    view
    |> element("button", "Create new preview")
    |> render_click()

    refreshed_preview = TestRepo.get_by!(RepairPreview, status: "ready")

    TestRepo.update!(
      RepairPreview.changeset(refreshed_preview, %{
        status: "drifted",
        metadata: %{"drift_reason" => "entry changed"}
      })
    )

    drifted_html =
      view
      |> form("#cron-confirmation-form", %{
        "confirmation" => %{"reason" => "maintenance window"}
      })
      |> render_submit()

    assert drifted_html =~ "This preview is out of date"
    assert drifted_html =~ "Create new preview"

    view
    |> element("button", "Create new preview")
    |> render_click()

    drifted_preview = TestRepo.get_by!(RepairPreview, status: "ready")

    TestRepo.update!(
      RepairPreview.changeset(drifted_preview, %{
        status: "consumed",
        consumed_at: DateTime.utc_now()
      })
    )

    consumed_html =
      view
      |> form("#cron-confirmation-form", %{
        "confirmation" => %{"reason" => "maintenance window"}
      })
      |> render_submit()

    assert consumed_html =~ "This preview was already used."
    assert consumed_html =~ "Create new preview"

    entry = Enum.find(Cron.list_entries(TestRepo), &(&1.name == "preview-states"))
    assert is_nil(entry.paused_at)
  end

  @tag phase79_slice: "cron"
  test "uses a selection-first DataTable with canonical entry detail history", %{conn: conn} do
    for name <- ["alpha/sync ?&=", "beta-sync"] do
      assert {:ok, _entry} =
               Cron.sync_entry(TestRepo, %{
                 name: name,
                 source: "runtime",
                 worker: "DemoWorker",
                 queue: "default",
                 expression: "* * * * *"
               })
    end

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-79", permissions: [:view_cron]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/cron")
    encoded = URI.encode_www_form("alpha/sync ?&=")

    assert has_element?(view, "#cron-page")
    assert has_element?(view, "#cron-entries.obpt-data-table")
    assert has_element?(view, "#cron-entries caption", "Cron entries")

    assert html =~
             "Review schedules, inspect one cron entry, and take deliberate action with recorded evidence."

    refute has_element?(view, "#cron-entries th", "Actions")
    refute has_element?(view, "#cron-entries tbody button[phx-click]")

    view
    |> element("a[href='/ops/jobs/cron?entry=#{encoded}']", "alpha/sync ?&=")
    |> render_click()

    assert_patch(view, "/ops/jobs/cron?entry=#{encoded}")
    assert has_element?(view, "#cron-entry-detail")
    refute has_element?(view, "#cron-confirmation")

    view
    |> element("a[href='/ops/jobs/cron?entry=beta-sync']", "beta-sync")
    |> render_click()

    assert_patch(view, "/ops/jobs/cron?entry=beta-sync")

    render_hook(view, "close_detail", %{})
    assert_patch(view, "/ops/jobs/cron")
    refute has_element?(view, "#cron-entry-detail")

    {:ok, forged, forged_html} = live(conn, "/ops/jobs/cron?entry=forged%2Fmissing%3Fentry")
    refute has_element?(forged, "#cron-confirmation")
    refute forged_html =~ "preview_token"
    refute forged_html =~ "plan_hash"
  end

  @tag phase79_slice: "cron"
  test "all cron actions use exact warning confirmation copy and reject whitespace", %{conn: conn} do
    {:ok, runnable} =
      Cron.sync_entry(TestRepo, %{
        name: "runnable-contract",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    {:ok, paused} =
      Cron.sync_entry(TestRepo, %{
        name: "paused-contract",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    {:ok, _paused} = Cron.pause_entry(TestRepo, paused, "seed-79", reason: "seed pause")

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-confirm-79",
          permissions: [
            :view_cron,
            :pause_cron_entry,
            :resume_cron_entry,
            :run_cron_entry
          ]
        }
      )

    action_contracts = [
      {runnable.name, "Pause cron entry", "Keep running",
       "Future schedule claims stop. Work that is already running or enqueued is unaffected."},
      {paused.name, "Resume cron entry", "Keep paused",
       "Future schedule claims continue. Missed work is not run retroactively."},
      {runnable.name, "Run cron entry now", "Keep current schedule",
       "Powertools attempts a manual schedule-slot claim. Overlap policy may skip, queue, or enqueue it."}
    ]

    for {entry_name, action_label, dismiss_label, consequence} <- action_contracts do
      {:ok, view, _html} = live(conn, "/ops/jobs/cron?entry=#{entry_name}")

      assert has_element?(view, "button", action_label)
      html = view |> element("button", action_label) |> render_click()

      assert has_element?(view, "#cron-confirmation-dialog[role='dialog']")
      assert html =~ action_label
      assert html =~ dismiss_label
      assert html =~ consequence
      assert html =~ "Reason"
      assert html =~ "Do not enter secrets"
      refute has_element?(view, "#cron-entry-detail")

      html =
        view
        |> form("#cron-confirmation-form", %{
          "confirmation" => %{"reason" => "   \t "}
        })
        |> render_submit()

      assert html =~ "Enter a reason before continuing."
      assert has_element?(view, "#cron-confirmation-dialog[role='dialog']")
      refute has_element?(view, "#cron-receipt")
    end
  end

  @tag phase79_slice: "cron"
  test "clean success uses the current principal and emits one redaction-safe receipt", %{
    conn: conn
  } do
    {:ok, _entry} =
      Cron.sync_entry(TestRepo, %{
        name: "receipt-contract",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *",
        metadata: %{"credential" => "CRON-CREDENTIAL-SENTINEL"}
      })

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "current-principal-79",
          permissions: [:view_cron, :pause_cron_entry]
        }
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/cron?entry=receipt-contract")
    assert has_element?(view, "button", "Pause cron entry")
    preview_html = view |> element("button", "Pause cron entry") |> render_click()

    preview =
      TestRepo.all(RepairPreview)
      |> Enum.find(&(get_in(&1.metadata, ["resource", "id"]) == "receipt-contract"))

    for secret <- [
          preview.preview_token,
          preview.plan_hash,
          "pause_cron_entry",
          "CRON-CREDENTIAL-SENTINEL"
        ] do
      refute preview_html =~ secret
    end

    html =
      view
      |> form("#cron-confirmation-form", %{
        "confirmation" => %{"reason" => "Scheduled maintenance"}
      })
      |> render_submit()

    assert count(html, ~s(id="cron-receipt")) == 1
    assert html =~ "Cron entry receipt-contract paused. Audit evidence recorded."
    assert html =~ "/ops/jobs/audit?resource_type=cron_entry&amp;resource_id=receipt-contract"
    refute has_element?(view, "#cron-confirmation")

    [event | _] = Audit.list(%{type: :cron_entry, id: "receipt-contract"}, repo: TestRepo)
    assert event.action == "cron.paused"
    assert event.actor_id == "current-principal-79"
    assert event.metadata["reason"] == "Scheduled maintenance"
  end

  @tag phase79_slice: "cron"
  test "a skipped manual slot claim stays recoverable with its safe draft and no success receipt",
       %{
         conn: conn
       } do
    {:ok, entry} =
      Cron.sync_entry(TestRepo, %{
        name: "skip-contract",
        source: "runtime",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *",
        overlap_policy: "skip"
      })

    %{}
    |> Oban.Job.new(worker: entry.worker, queue: entry.queue)
    |> TestRepo.insert!()

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "skip-principal-79",
          permissions: [:view_cron, :run_cron_entry]
        }
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/cron?entry=skip-contract")
    assert has_element?(view, "button", "Run cron entry now")
    view |> element("button", "Run cron entry now") |> render_click()

    html =
      view
      |> form("#cron-confirmation-form", %{
        "confirmation" => %{"reason" => "Preserve this safe draft"}
      })
      |> render_submit()

    assert has_element?(view, "#cron-confirmation-dialog[role='dialog']")
    assert html =~ "Preserve this safe draft"
    assert html =~ "skipped"
    assert html =~ "Create new preview"
    refute html =~ "The job ran."
    refute html =~ "completed"
    refute has_element?(view, "#cron-receipt")

    assert Enum.any?(
             Audit.list(%{type: :cron_entry, id: "skip-contract"}, repo: TestRepo),
             &(&1.action == "cron.run_now")
           )
  end

  @tag phase79_slice: "cron"
  test "page source keeps durable APIs and both authorization gates while excluding forged lookup" do
    source = File.read!("lib/oban_powertools/web/cron_live.ex")

    assert function_exported?(ObanPowertools.Web.CronLive, :page_content, 1)
    assert source =~ "def page_content(assigns)"
    assert source =~ "Cron.preview_entry_action"
    assert source =~ "Cron.pause_cron_entry"
    assert source =~ "Cron.resume_cron_entry"
    assert source =~ "Cron.run_cron_entry"
    assert count(source, "LiveAuth.authorize_action") >= 2
    assert source =~ "LiveAuth.principal_for_action"
    assert source =~ "DataDisplay.data_table"
    assert source =~ "OperatorPatterns.detail_surface"
    assert source =~ "OperatorPatterns.confirm_action_dialog"
    refute source =~ "find_entry!"
    refute source =~ "Audit.list_all"
  end

  test "page_content renders the reusable Cron composition without a LiveView socket" do
    html =
      render_component(&ObanPowertools.Web.CronLive.page_content/1,
        entries: [],
        read_only?: false
      )

    assert count(html, "<h1") == 1
    assert html =~ ~s(id="cron-page")
    assert html =~ ~s(id="cron-entries")
    refute html =~ ~s(id="cron-entry-detail")
    refute html =~ ~s(id="cron-confirmation-dialog")
    refute html =~ ~s(id="cron-receipt")
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
  defp count(text, needle), do: length(String.split(text, needle)) - 1
end
