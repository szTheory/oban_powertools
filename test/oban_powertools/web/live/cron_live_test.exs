defmodule ObanPowertools.Web.CronLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.{Audit, Cron}

  setup do
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

    on_exit(fn -> :telemetry.detach("cron-live-test") end)
    :ok
  end

  test "shows source badges and runs preview-first pause flow", %{conn: conn} do
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

    assert_receive {:telemetry_event, [:oban_powertools, :operator_action, :previewed],
                    %{count: 1}, %{action: "pause_cron_entry", source: "code"}}

    render_change(view, "reason", %{"reason" => "maintenance"})
    html = render_click(view, "confirm", %{})

    assert html =~ "Paused"
    assert_receive {:telemetry_event, [:oban_powertools, :cron, :paused], %{count: 1}, _}

    assert_receive {:telemetry_event, [:oban_powertools, :operator_action, :complete],
                    %{count: 1}, %{action: "pause_cron_entry", source: "code"}}

    [event | _] = Audit.list(%{type: :cron_entry, id: "nightly"}, repo: TestRepo)
    assert event.action == "cron.paused"
    assert event.actor_id == "ops-1"
    assert event.metadata["reason"] == "maintenance"
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

    assert html =~ "disabled"
    assert html =~ "You do not have permission to pause cron entries."

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

    assert html =~ "disabled"
    assert html =~ "You do not have permission to pause cron entries."

    html =
      render_click(view, "preview", %{
        "action" => "pause_cron_entry",
        "entry" => "unauthorized-preview"
      })

    assert html =~ "You do not have permission to pause cron entries."
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

    assert has_element?(view, "button[phx-value-entry='#{runnable_entry.name}'][phx-value-action='pause_cron_entry'][disabled]")
    assert has_element?(view, "button[phx-value-entry='#{runnable_entry.name}'][phx-value-action='run_cron_entry'][disabled]")
    assert has_element?(view, "button[phx-value-entry='#{paused_entry.name}'][phx-value-action='resume_cron_entry'][disabled]")
    assert has_element?(view, "button[phx-value-entry='#{paused_entry.name}'][phx-value-action='run_cron_entry'][disabled]")

    assert html =~ "You do not have permission to pause cron entries."
    assert html =~ "You do not have permission to resume cron entries."
    assert html =~ "You do not have permission to run cron entries now."
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
    refute html =~ "Paused"
    refute_receive {:telemetry_event, [:oban_powertools, :cron, :paused], _, _}
    refute_receive {:telemetry_event, [:oban_powertools, :operator_action, :complete], _, _}
    assert Audit.list(%{type: :cron_entry, id: "missing-principal"}, repo: TestRepo) == []

    entry = Enum.find(Cron.list_entries(TestRepo), &(&1.name == "missing-principal"))
    assert is_nil(entry.paused_at)
  end
end
