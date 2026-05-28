defmodule ObanPowertools.Web.JobsLiveTestDisplayPolicy do
  def display(:job_args, _value, _context), do: nil
  def display(:job_meta, _value, _context), do: nil
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertools.Web.JobsLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.TestRepo

  setup do
    original_display_policy = Application.get_env(:oban_powertools, :display_policy)

    Application.put_env(
      :oban_powertools,
      :display_policy,
      ObanPowertools.Web.JobsLiveTestDisplayPolicy
    )

    on_exit(fn ->
      Application.put_env(:oban_powertools, :display_policy, original_display_policy)
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # Test 1: Redirects unauthorized viewers
  # ---------------------------------------------------------------------------

  test "redirects unauthorized viewers", %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-2", permissions: []})

    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/jobs")
  end

  # ---------------------------------------------------------------------------
  # Test 2: Redirects when no state param then loads default state
  # ---------------------------------------------------------------------------

  test "redirects when no state param then loads default state", %{conn: conn} do
    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_jobs]}
      )

    # When no state param is provided, the live (connected) phase's handle_params fires
    # push_patch during mount, causing handle_params to be called again with state=available.
    # The view is fully mounted at ?state=available by the time live/2 returns.
    {:ok, _view, html} = live(conn, "/ops/jobs/jobs")
    assert html =~ "Jobs"
    assert html =~ "Browse and inspect Oban jobs by state."
    # The state tab bar is rendered — available is in the tab bar
    assert html =~ "available"
    # The active state tab class is applied to "available" (the default state)
    assert html =~ "border-indigo-300 bg-indigo-50"
  end

  # ---------------------------------------------------------------------------
  # Test 3: Renders list page with state tabs and headings
  # ---------------------------------------------------------------------------

  test "renders list page with state tabs and headings", %{conn: conn} do
    insert_job!(worker: "MyApp.AvailableWorker", queue: :default)
    insert_job!(worker: "MyApp.AvailableWorker2", queue: :default)
    insert_job!(worker: "MyApp.ExecutingWorker", queue: :default, state: "executing")

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_jobs]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs/jobs?state=available")

    assert html =~ "Jobs"
    assert html =~ "Browse and inspect Oban jobs by state."
    assert html =~ "available"
    assert html =~ "scheduled"
    assert html =~ "executing"
    assert html =~ "retryable"
    assert html =~ "cancelled"
    assert html =~ "discarded"
    assert html =~ "completed"
    assert html =~ "available (2)"
    assert html =~ "executing (1)"

    # 2 rows for available state
    assert html =~ "AvailableWorker"
    assert html =~ "AvailableWorker2"
  end

  # ---------------------------------------------------------------------------
  # Test 4: Filters by queue via push_patch
  # ---------------------------------------------------------------------------

  test "filters by queue via push_patch", %{conn: conn} do
    insert_job!(worker: "MyApp.Worker", queue: :default)
    insert_job!(worker: "MyApp.Worker", queue: :alpha)

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_jobs]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/jobs?state=available")

    html =
      view
      |> form("form[phx-change=filter]", filter: %{queue: "alpha", worker: "", tags: ""})
      |> render_change()

    # After filter change, only the alpha queue job should be in the rendered HTML.
    # The patch URL includes queue=alpha.
    assert_patch(view, "/ops/jobs/jobs?state=available&queue=alpha")
    assert html =~ "alpha"
    refute html =~ ">default<"
  end

  # ---------------------------------------------------------------------------
  # Test 5: Filters by worker
  # ---------------------------------------------------------------------------

  test "filters by worker", %{conn: conn} do
    insert_job!(worker: "MyApp.TargetWorker", queue: :default)
    insert_job!(worker: "MyApp.OtherWorker", queue: :default)

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_jobs]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/jobs?state=available")

    html =
      view
      |> form("form[phx-change=filter]", filter: %{queue: "", worker: "MyApp.TargetWorker", tags: ""})
      |> render_change()

    # After filter change, only the TargetWorker job should appear.
    assert_patch(view, "/ops/jobs/jobs?state=available&worker=MyApp.TargetWorker")
    assert html =~ "TargetWorker"
    refute html =~ "OtherWorker"
  end

  # ---------------------------------------------------------------------------
  # Test 6: Filters by tags
  # ---------------------------------------------------------------------------

  test "filters by tags", %{conn: conn} do
    insert_job!(worker: "MyApp.Worker", queue: :default, tags: ["foo"])
    insert_job!(worker: "MyApp.OtherWorker", queue: :default, tags: ["bar"])

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_jobs]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs/jobs?state=available&tags=foo")

    assert html =~ "Worker"
    refute html =~ "OtherWorker"
  end

  # ---------------------------------------------------------------------------
  # Test 7: Navigates state via tab click
  # ---------------------------------------------------------------------------

  test "navigates state via tab click", %{conn: conn} do
    insert_job!(worker: "MyApp.ExecutingWorker", queue: :default, state: "executing")

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_jobs]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/jobs?state=available")

    view
    |> element("button[phx-value-state=executing]")
    |> render_click()

    assert_patch(view, "/ops/jobs/jobs?state=executing")
    html = render(view)
    assert html =~ "ExecutingWorker"
  end

  # ---------------------------------------------------------------------------
  # Test 8: Read-only banner renders when actor lacks mutation permissions
  # ---------------------------------------------------------------------------

  test "read-only banner renders when actor lacks mutation permissions", %{conn: conn} do
    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_jobs]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs/jobs?state=available")

    assert html =~ "Permission: read-only. Job list stays visible"
  end

  # ---------------------------------------------------------------------------
  # Test 9: Hides read-only banner when actor has retry_job permission
  # ---------------------------------------------------------------------------

  test "hides read-only banner when actor has retry_job permission", %{conn: conn} do
    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_jobs, :retry_job]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs/jobs?state=available")

    refute html =~ "Job list stays visible"
  end

  # ---------------------------------------------------------------------------
  # Test 10: Renders empty state when no jobs match the filter
  # ---------------------------------------------------------------------------

  test "renders empty state when no jobs match the filter", %{conn: conn} do
    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_jobs]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs/jobs?state=available")

    assert html =~ "No available jobs"
    assert html =~ "No jobs are currently in the available state."
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp insert_job!(opts) do
    {state, opts} = Keyword.pop(opts, :state, "available")

    job =
      %{}
      |> Oban.Job.new(opts)
      |> TestRepo.insert!()

    if state == "available" do
      job
    else
      job
      |> Ecto.Changeset.change(state: state)
      |> TestRepo.update!()
    end
  end
end
