defmodule ObanPowertools.Web.AuditLiveTestDisplayPolicy do
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

defmodule ObanPowertools.Web.AuditLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.Audit

  setup do
    original_display_policy = Application.get_env(:oban_powertools, :display_policy)

    Application.put_env(
      :oban_powertools,
      :display_policy,
      ObanPowertools.Web.AuditLiveTestDisplayPolicy
    )

    on_exit(fn ->
      Application.put_env(:oban_powertools, :display_policy, original_display_policy)
    end)

    :ok
  end

  test "renders audit history", %{conn: conn} do
    Audit.record(
      "lifeline.repair_executed",
      %{type: :job, id: "123"},
      %{
        "source" => "lifeline",
        "reason" => "maintenance window rescue",
        "principal" => %{"id" => "ops-1", "type" => "user", "label" => "Jane Operator"}
      },
      repo: TestRepo,
      actor_id: "ops-1"
    )

    conn =
      Plug.Test.init_test_session(conn, current_actor: %{id: "ops-1", permissions: [:view_audit]})

    {:ok, _view, html} = live(conn, "/ops/jobs/audit")
    assert html =~ "lifeline.repair_executed"
    assert html =~ "job:123"
    assert html =~ "policy actor: Jane Operator"
    assert html =~ "policy reason: MAINTENANCE WINDOW RESCUE"
    assert html =~ "Archive Activity"
    assert html =~ "Event Time"
  end

  test "redirects unauthorized viewers", %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-3", permissions: []})
    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/audit")
  end
end
