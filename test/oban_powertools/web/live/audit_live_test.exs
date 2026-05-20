defmodule ObanPowertools.Web.AuditLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.Audit

  test "renders audit history", %{conn: conn} do
    Audit.record(
      "lifeline.repair_executed",
      %{type: :job, id: "123"},
      %{"source" => "lifeline", "reason" => "maintenance window rescue"},
      repo: TestRepo,
      actor_id: "ops-1"
    )

    conn =
      Plug.Test.init_test_session(conn, current_actor: %{id: "ops-1", permissions: [:view_audit]})

    {:ok, _view, html} = live(conn, "/ops/jobs/audit")
    assert html =~ "lifeline.repair_executed"
    assert html =~ "job:123"
    assert html =~ "maintenance window rescue"
    assert html =~ "Archive Activity"
    assert html =~ "Event Time"
  end

  test "redirects unauthorized viewers", %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-3", permissions: []})
    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/audit")
  end
end
