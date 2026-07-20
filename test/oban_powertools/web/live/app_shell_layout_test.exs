defmodule ObanPowertools.Web.Live.AppShellLayoutTestDisplayPolicy do
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertools.Web.Live.AppShellLayoutTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.Workflow
  alias ObanPowertools.WorkflowFixtures
  alias ObanPowertools.Web.Live.AppShellLayoutTestDisplayPolicy

  @nav_labels ~w[Overview Jobs Batches Workflows Cron Limiters Lifeline Audit Forensics]

  setup do
    original_display_policy = Application.get_env(:oban_powertools, :display_policy)
    Application.put_env(:oban_powertools, :display_policy, AppShellLayoutTestDisplayPolicy)

    on_exit(fn ->
      case original_display_policy do
        nil -> Application.delete_env(:oban_powertools, :display_policy)
        policy -> Application.put_env(:oban_powertools, :display_policy, policy)
      end
    end)

    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "app-shell-layout-contract")
      |> Workflow.insert(TestRepo)

    {:ok, workflow: workflow}
  end

  test "native routes render inside one ThemeShell root and one AppShell wrapper", %{
    conn: conn,
    workflow: workflow
  } do
    for path <- representative_paths(workflow) do
      html = mount_native!(conn, path)

      assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.css|
      assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.js|

      assert html =~
               ~r/<script[^>]+phx-track-static[^>]+src="\/ops\/jobs\/_assets\/oban_powertools-[a-f0-9]{32}\.js"/

      assert count(html, ~s(class="obpt-root")) == 1
      assert count(html, ~s(data-obpt-app-shell)) == 1
      assert count(html, ~s(data-obpt-nav-toggle)) == 1
      assert count(html, ~s(data-obpt-primary-nav)) == 1
      assert count(html, ~s(data-obpt-nav-state="closed")) >= 1
      assert count(html, ~s(data-obpt-nav-item)) == 9
      assert count_main_targets(html) == 1
      assert html =~ "Actor: ops@example.test"

      refute html =~ ~r/<a[^>]+data-obpt-nav-item[^>]+href="\/ops\/jobs\/oban"/,
             "NAV-01 keeps the optional Oban Web bridge out of primary nav"
    end
  end

  test "server-side current path drives active nav and breadcrumb fallbacks", %{
    conn: conn,
    workflow: workflow
  } do
    cases = [
      {"/ops/jobs", "Overview", "Overview"},
      {"/ops/jobs/jobs", "Jobs", "Jobs"},
      {"/ops/jobs/jobs/123", "Jobs", "Job detail"},
      {"/ops/jobs/batches/batch-1", "Batches", "Batch detail"},
      {"/ops/jobs/workflows/#{workflow.id}", "Workflows", "Workflow detail"}
    ]

    for {path, active_label, current_crumb} <- cases do
      html = mount_native!(conn, path)

      assert_current_nav(html, active_label)
      assert html =~ ~s(aria-label="Breadcrumb")
      assert html =~ ~s(data-obpt-breadcrumb="root")
      assert html =~ ~s(data-obpt-breadcrumb="current")
      assert html =~ ~r/data-obpt-breadcrumb="root"[^>]*>Overview/s

      assert html =~
               ~r/data-obpt-breadcrumb="current"[^>]+aria-current="page"[^>]*>#{Regex.escape(current_crumb)}/s
    end
  end

  test "shell wraps native page content without asserting page-body migrations", %{
    conn: conn,
    workflow: workflow
  } do
    for {path, page_copy} <- [
          {"/ops/jobs", "Overview"},
          {"/ops/jobs/jobs", "Jobs"},
          {"/ops/jobs/jobs/123", "Job not found"},
          {"/ops/jobs/batches/batch-1", "Batch not found"},
          {"/ops/jobs/workflows/#{workflow.id}", "Workflows"}
        ] do
      html = mount_native!(conn, path)

      assert html =~ page_copy
      assert html =~ ~r/<main[^>]+id="obpt-main"[^>]+tabindex="-1"/s
      assert html =~ ~s(Skip to main content)
    end
  end

  defp representative_paths(workflow) do
    [
      "/ops/jobs",
      "/ops/jobs/jobs",
      "/ops/jobs/jobs/123",
      "/ops/jobs/batches/batch-1",
      "/ops/jobs/workflows/#{workflow.id}"
    ]
  end

  defp mount_native!(conn, path) do
    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-1",
          permissions: [:all],
          audit_principal: %{id: "ops-1", type: :user, label: "ops@example.test"}
        }
      )

    {:ok, _view, html} = live(conn, path)
    html
  end

  defp assert_current_nav(html, label) when label in @nav_labels do
    assert html =~
             ~r/<a(?=[^>]*data-obpt-nav-item)(?=[^>]*aria-current="page")[^>]*>[^<]*#{Regex.escape(label)}/s,
           "expected #{label} primary nav link to be current"
  end

  defp count_main_targets(html) do
    Regex.scan(~r/<main(?=[^>]*id="obpt-main")(?=[^>]*tabindex="-1")/s, html)
    |> length()
  end

  defp count(html, needle), do: length(String.split(html, needle)) - 1
end
