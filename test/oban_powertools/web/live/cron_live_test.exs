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

  test "blocks unauthorized cron mutation at confirm time", %{conn: conn} do
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

    {:ok, view, _html} = live(conn, "/ops/jobs/cron")
    render_click(element(view, "button[phx-value-action='pause_cron_entry']"))
    html = render_click(view, "confirm", %{})

    assert html =~ "not authorized to perform this action"
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

    {:ok, view, _html} = live(conn, "/ops/jobs/cron")

    html =
      view
      |> element("button[phx-value-action='pause_cron_entry']")
      |> render_click()

    refute html =~ "Preview Action"
    assert html =~ "You do not have permission to pause cron entries."

    refute_receive {:telemetry_event, [:oban_powertools, :operator_action, :previewed], _, _}
  end
end
