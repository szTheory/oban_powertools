defmodule ObanPowertools.Web.WorkflowsLiveTestDisplayPolicy do
  def display(:workflow_result, result, _context) do
    payload = result["payload"] || %{}
    hidden? = result["redacted"] or Map.has_key?(payload, "secret")

    %{
      summary: "policy summary: #{result["summary"] || "none"}",
      payload:
        if(hidden?,
          do: "policy payload: hidden",
          else: "policy payload: #{inspect(payload)}"
        ),
      redacted?: hidden?
    }
  end
end

defmodule ObanPowertools.Web.WorkflowsLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.Result
  alias ObanPowertools.Workflow.Step
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord
  alias ObanPowertools.WorkflowFixtures
  alias ObanPowertools.Web.ControlPlanePresenter

  setup do
    original_display_policy = Application.get_env(:oban_powertools, :display_policy)

    Application.put_env(
      :oban_powertools,
      :display_policy,
      ObanPowertools.Web.WorkflowsLiveTestDisplayPolicy
    )

    on_exit(fn ->
      Application.put_env(:oban_powertools, :display_policy, original_display_policy)
    end)

    :ok
  end

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
    assert html =~ "Permission: read-only."
    assert html =~ "Powertools-native pages"
    assert html =~ "Open generic job inspection in Oban Web bridge"
    assert html =~ "sync_billing"
    assert html =~ "waiting_on_dependencies"

    html =
      view
      |> element("a[href*='step=notify']")
      |> render_click()

    assert html =~ "notify"
    assert html =~ "Dependencies"
  end

  test "renders workflow result details through the shared display policy seam", %{conn: conn} do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "policy-workflow") |> Workflow.insert(TestRepo)

    assert {:ok, _step} =
             Workflow.complete_step(TestRepo, workflow.id, :fetch_customer,
               status: :completed,
               summary: "fetched customer record",
               payload: %{customer_id: 1, secret: "token-123"}
             )

    fetch_customer = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "fetch_customer")
    result = TestRepo.get_by!(Result, workflow_id: workflow.id, step_id: fetch_customer.id)
    assert result.payload["secret"] == "token-123"

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_workflows]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs/workflows/#{workflow.id}?step=fetch_customer")

    assert html =~ "Result available:"
    assert html =~ "policy summary: fetched customer record"
    assert html =~ "policy payload: hidden"
    assert html =~ "Redaction outcome: hidden by display policy."
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

  test "renders shared rejection vocabulary for refused workflow mutations", %{conn: conn} do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "legacy-visible") |> Workflow.insert(TestRepo)

    workflow
    |> WorkflowRecord.changeset(%{semantics_version: 1})
    |> TestRepo.update!()

    assert {:error, rejection} =
             Workflow.complete_step(TestRepo, workflow.id, :fetch_customer,
               status: :completed,
               payload: %{customer_id: 1}
             )

    assert rejection.reason_code == "unsupported_legacy_semantics"

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_workflows]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs/workflows/#{workflow.id}?step=fetch_customer")

    assert html =~ "Outcome:"
    assert html =~ "Needs Review"
    assert html =~ "Reason:"
    assert html =~ "workflow rows with semantics_version"
    assert html =~ "explicit compatibility adapter"
    assert html =~ "Legal next move:"
    assert html =~ "Migrate via compatibility path"
    assert html =~ "Venue:"
    assert html =~ "Workflow diagnosis"
    assert html_position(html, "Outcome:") < html_position(html, "Reason:")
    assert html_position(html, "Reason:") < html_position(html, "Legal next move:")
    assert html_position(html, "Legal next move:") < html_position(html, "Venue:")
    assert html_position(html, "Venue:") < html_position(html, "Machine code:")
    assert html =~ "Machine code: unsupported_legacy_semantics"
    assert html =~ "Semantics: legacy_v1 (compatibility_path)"
  end

  test "shared runbook ownership helper returns exact control-plane labels" do
    assert ControlPlanePresenter.runbook_ownership_label(:powertools_native) ==
             "Powertools-native"

    assert ControlPlanePresenter.runbook_ownership_label("Powertools-native") ==
             "Powertools-native"

    assert ControlPlanePresenter.runbook_ownership_label(:oban_web_bridge) ==
             "Oban Web bridge"

    assert ControlPlanePresenter.runbook_ownership_label("Inspection only") ==
             "Oban Web bridge"

    assert ControlPlanePresenter.runbook_ownership_label(:host_owned) ==
             "host-owned follow-up"

    assert ControlPlanePresenter.runbook_ownership_label("host-owned follow-up") ==
             "host-owned follow-up"
  end

  test "renders callback posture and recovery session identity", %{conn: conn} do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "callback-contract") |> Workflow.insert(TestRepo)

    assert {:ok, _step} =
             Workflow.recover_step(TestRepo, workflow.id, :sync_billing, :retry,
               actor_id: "ops-1",
               reason: "manual retry"
             )

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_workflows]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs/workflows/#{workflow.id}?step=sync_billing")

    assert html =~ "Callback posture:"
    assert html =~ "Latest recovery session:"
  end

  test "renders a diagnosis-first Lifeline handoff without inline mutation controls", %{
    conn: conn
  } do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "lifeline-handoff") |> Workflow.insert(TestRepo)

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_workflows]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/workflows/#{workflow.id}?step=sync_billing")

    assert html =~ "Review the bounded action in Lifeline."
    assert html =~ "Open runbook entry"
    assert html =~ "Legal next move"
    assert html =~ "Venue"
    assert html =~ "evidence"
    assert html =~ "Review in Lifeline: Retry step"
    assert html =~ "Powertools-native"
    assert html =~ "Oban Web bridge"
    assert html =~ "host-owned follow-up"
    assert html =~ "Audited action"
    assert has_element?(view, "a[href*='/ops/jobs/lifeline?']")
    assert has_element?(view, "a[href*='/ops/jobs/forensics?']")
    assert has_element?(view, "a[href*='workflow_id=#{workflow.id}']")
    assert has_element?(view, "a[href*='step=sync_billing']")
    refute html =~ "Execute Repair Plan"
    refute has_element?(view, "input[name='reason']")
  end

  test "renders a forensic entry link that preserves workflow and step selectors", %{conn: conn} do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "forensics-entry-workflow") |> Workflow.insert(TestRepo)

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_workflows, :view_forensics]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/workflows/#{workflow.id}?step=sync_billing")

    assert html =~ "Open the forensic bundle."
    assert html =~ "supporting evidence"
    assert has_element?(view, "a[href*='/ops/jobs/forensics?']")
    assert has_element?(view, "a[href*='workflow_id=#{workflow.id}']")
    assert has_element?(view, "a[href*='step=sync_billing']")
  end

  test "redirects unauthorized viewers", %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-2", permissions: []})

    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/workflows")
  end

  defp html_position(html, text) do
    case :binary.match(html, text) do
      {position, _length} -> position
      :nomatch -> flunk("expected #{inspect(text)} in rendered HTML")
    end
  end
end
