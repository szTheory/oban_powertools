defmodule HexConsumerWeb.ObanPowertoolsFirstSessionTest do
  use HexConsumerWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias ObanPowertools.{Audit, Cron}
  alias ObanPowertools.Cron.Entry
  alias ObanPowertools.Lifeline.RepairPreview
  alias HexConsumer.Repo

  test "ops-demo pauses nightly_sync through the native cron page and writes durable audit evidence", %{
    conn: conn
  } do
    actor = HexConsumerWeb.ObanPowertoolsAuth.demo_actor()

    conn = Plug.Test.init_test_session(conn, %{"ops_actor" => actor})

    {:ok, view, html} = live(conn, "/ops/jobs/cron")

    assert html =~ "Cron"
    assert html =~ "Preview, reason, venue, and audit stay aligned for every cron entry mutation."
    assert html =~ "nightly_sync"
    assert html =~ "Runtime"
    assert html =~ "Queue One"
    assert html =~ "Latest Only"
    refute html =~ "Oban Web"

    html =
      view
      |> element("button[phx-value-action='pause_cron_entry'][phx-value-entry='nightly_sync']")
      |> render_click()

    assert html =~ "Preview Action"
    assert html =~ "pause cron entry"
    assert html =~ "cron_entry:nightly_sync"
    assert html =~ "future claims stop until resumed"
    assert html =~ "One immutable operator event will be written."
    assert html =~ "ops-demo"
    assert html =~ "Preview Status"
    assert html =~ "ready"

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
    assert html =~ preview.preview_token

    reason = "fixture maintenance"

    render_change(view, "reason", %{"reason" => reason})
    html = render_click(view, "confirm", %{})

    assert html =~ "Waiting"
    assert html =~ "Resume Cron Entry"
    assert html =~ "Recent Audit Evidence"
    assert html =~ "Open in Audit"
    assert html =~ "cron.paused"

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

    assert Enum.any?(Cron.list_entries(Repo), &(&1.name == "nightly_sync" and not is_nil(&1.paused_at)))
  end
end
