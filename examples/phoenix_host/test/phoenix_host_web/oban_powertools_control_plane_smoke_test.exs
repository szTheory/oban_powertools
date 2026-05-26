defmodule PhoenixHostWeb.ObanPowertoolsControlPlaneSmokeTest do
  use PhoenixHostWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  test "the supported host renders overview, audit, and bridge-only follow-up through one shared session", %{
    conn: conn
  } do
    actor = PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()

    conn = Plug.Test.init_test_session(conn, %{"ops_actor" => actor})

    {:ok, _overview_view, overview_html} = live(conn, "/ops/jobs")

    assert overview_html =~ "Diagnosis-first overview"
    assert overview_html =~ "Inspection only"

    {:ok, _audit_view, audit_html} = live(conn, "/ops/jobs/audit")

    assert audit_html =~ "cross-surface audit destination"
    assert audit_html =~ "Inspection only"

    {:ok, _bridge_view, bridge_html} = live(conn, "/ops/jobs/oban")

    assert bridge_html =~ "Oban Web"
    assert bridge_html =~ "/ops/jobs/oban"
  end
end
