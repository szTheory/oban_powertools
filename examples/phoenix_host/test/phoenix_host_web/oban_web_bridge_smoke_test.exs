defmodule PhoenixHostWeb.ObanWebBridgeSmokeTest do
  use PhoenixHostWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  test "the optional bridge mounts at /ops/jobs/oban under the shared ops session", %{conn: conn} do
    actor = PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()

    conn = Plug.Test.init_test_session(conn, %{"ops_actor" => actor})

    {:ok, _view, html} = live(conn, "/ops/jobs/oban")

    assert html =~ "Oban Web"
    assert html =~ "/ops/jobs/oban"
  end
end
