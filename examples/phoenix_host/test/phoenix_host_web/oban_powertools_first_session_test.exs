defmodule PhoenixHostWeb.ObanPowertoolsFirstSessionTest do
  use PhoenixHostWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias ObanPowertools.{Audit, Cron}
  alias ObanPowertools.Cron.Entry
  alias ObanPowertools.Lifeline.RepairPreview
  alias PhoenixHost.Repo

  test "ops-demo pauses nightly_sync through the native cron page and writes durable audit evidence",
       %{
         conn: conn
       } do
    actor = PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()

    conn = Plug.Test.init_test_session(conn, %{"ops_actor" => actor})

    {:ok, view, html} = live(conn, "/ops/jobs/cron?entry=nightly_sync")

    assert html =~ "Cron"

    assert html =~
             "Review schedules, inspect one cron entry, and take deliberate action with recorded evidence."

    assert html =~ "nightly_sync"
    assert html =~ "Runtime"
    assert html =~ "Queue One"
    assert html =~ "Latest Only"
    assert html =~ "Oban Web bridge"

    html =
      view
      |> element("button", "Pause cron entry")
      |> render_click()

    assert html =~ "Pause nightly_sync"

    assert html =~
             "Future schedule claims stop. Work that is already running or enqueued is unaffected."

    assert html =~ "One immutable operator event will be written."
    assert html =~ "Actor: ops-demo"
    assert html =~ "Do not enter secrets"

    preview =
      Repo.one!(
        from(record in RepairPreview,
          where:
            record.action == "pause_cron_entry" and
              record.target_type == "cron_entry" and record.status == "ready",
          order_by: [desc: record.inserted_at],
          limit: 1
        )
      )

    assert get_in(preview.metadata, ["resource", "id"]) == "nightly_sync"
    assert get_in(preview.metadata, ["resource", "source"]) == "fixture"
    refute html =~ preview.preview_token

    reason = "fixture maintenance"

    html =
      view
      |> form("#cron-confirmation-form", %{
        "confirmation" => %{"reason" => reason}
      })
      |> render_submit()

    assert html =~ "Waiting"
    assert html =~ "Resume cron entry"
    assert html =~ "Cron entry nightly_sync paused. Audit evidence recorded."
    assert html =~ "Open audit evidence"

    entry = Repo.get_by!(Entry, name: "nightly_sync")
    refute is_nil(entry.paused_at)

    consumed_preview = Repo.get!(RepairPreview, preview.id)
    assert consumed_preview.status == "consumed"
    assert consumed_preview.metadata["reason"] == reason

    [event] = Audit.list(%{type: :cron_entry, id: "nightly_sync"}, repo: Repo)
    assert event.action == "cron.paused"
    assert event.resource == "cron_entry:nightly_sync"
    assert event.actor_id == "ops-demo"
    assert event.metadata["reason"] == reason
    assert event.metadata["preview_token"] == preview.preview_token
    assert get_in(event.metadata, ["resource", "id"]) == "nightly_sync"
    assert get_in(event.metadata, ["resource", "source"]) == "fixture"

    principal = Audit.event_principal(event)
    assert principal.id == "ops-demo"
    assert principal.type == :user

    assert Enum.any?(
             Cron.list_entries(Repo),
             &(&1.name == "nightly_sync" and not is_nil(&1.paused_at))
           )
  end
end
