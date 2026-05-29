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
  alias ObanPowertools.Workflow
  alias ObanPowertools.WorkflowFixtures

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
    assert html =~ "Event Type"
    assert html =~ "Resource Identity"
    assert html =~ "Permission: read-only."
    assert html =~ "cross-surface audit destination"

    assert html =~
             "Powertools-native pages keep preview, reason, and local audit evidence close to the acted-on resource."

    assert html =~ "Inspection only"
  end

  test "scopes audit history with durable read-only filters", %{conn: conn} do
    Audit.record(
      "lifeline.repair_executed",
      %{type: :job, id: "123"},
      %{"event_type" => "lifeline.repair_executed", "reason" => "maintenance"},
      repo: TestRepo,
      actor_id: "ops-1"
    )

    Audit.record(
      "cron.paused",
      %{type: :cron_entry, id: "nightly"},
      %{"event_type" => "cron.paused", "reason" => "maintenance"},
      repo: TestRepo,
      actor_id: "ops-1"
    )

    conn =
      Plug.Test.init_test_session(conn, current_actor: %{id: "ops-1", permissions: [:view_audit]})

    {:ok, _view, html} =
      live(
        conn,
        "/ops/jobs/audit?resource_type=job&resource_id=123&event_type=lifeline.repair_executed"
      )

    assert html =~ "Scoped Audit Filter"
    assert html =~ "resource_type=job"
    assert html =~ "resource_id=123"
    assert html =~ "event_type=lifeline.repair_executed"
    assert html =~ "job:123"
    refute html =~ "cron_entry:nightly"
  end

  test "forensic audit follow-up preserves scoped resource and event filters", %{conn: conn} do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "forensic-audit-follow-up")
      |> Workflow.insert(TestRepo)

    Audit.record(
      "workflow.step_completed",
      %{type: :workflow, id: workflow.id},
      %{"event_type" => "workflow.step_completed", "reason" => "follow-up"},
      repo: TestRepo,
      actor_id: "ops-1"
    )

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_audit, :view_forensics]}
      )

    {:ok, _forensic_view, forensic_html} =
      live(conn, "/ops/jobs/forensics?workflow_id=#{workflow.id}")

    assert forensic_html =~
             "/ops/jobs/audit?resource_type=workflow&amp;resource_id=#{workflow.id}&amp;event_type=workflow.step_completed"

    {:ok, _audit_view, audit_html} =
      live(
        conn,
        "/ops/jobs/audit?resource_type=workflow&resource_id=#{workflow.id}&event_type=workflow.step_completed"
      )

    assert audit_html =~ "Scoped Audit Filter"
    assert audit_html =~ "resource_type=workflow"
    assert audit_html =~ "event_type=workflow.step_completed"
  end

  test "redirects unauthorized viewers", %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-3", permissions: []})
    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/audit")
  end
end
