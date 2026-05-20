defmodule ObanPowertools.Web.WorkflowsLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.Step
  alias ObanPowertools.WorkflowFixtures

  test "renders blocked workflows and selected-node detail", %{conn: conn} do
    {:ok, workflow} = WorkflowFixtures.workflow_fixture() |> Workflow.insert(TestRepo)

    sync_billing = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_billing")
    TestRepo.update!(Ecto.Changeset.change(sync_billing, job_id: 123))

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_workflows]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/workflows/#{workflow.id}?step=sync_billing")
    assert html =~ "Workflows"
    assert html =~ "sync_billing"
    assert html =~ "waiting_on_dependencies"

    html =
      view
      |> element("a[href*='step=notify']")
      |> render_click()

    assert html =~ "notify"
    assert html =~ "Dependencies"
  end

  test "preserves selected node across workflow refresh", %{conn: conn} do
    {:ok, workflow} = WorkflowFixtures.workflow_fixture() |> Workflow.insert(TestRepo)

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_workflows]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/workflows/#{workflow.id}?step=notify")

    Workflow.Signal.broadcast(Workflow.Signal.step_completed(workflow.id, :fetch_customer))
    Process.sleep(20)

    assert render(view) =~ "notify"
  end

  test "redirects unauthorized viewers", %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-2", permissions: []})

    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/workflows")
  end
end
