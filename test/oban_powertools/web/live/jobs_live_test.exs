defmodule ObanPowertools.Web.JobsLiveTestDisplayPolicy do
  def display(:job_args, _value, _context), do: nil
  def display(:job_meta, _value, _context), do: nil
  def display(_kind, _value, _context), do: nil
end

# Detail-page redaction policy modules — used by the "Detail page" describe block below.
# Each exercises one arm of DisplayPolicy.render_job_field/3.

defmodule ObanPowertools.Web.JobsLiveDetailNilPolicy do
  # nil → {:raw_json, pretty-encoded JSON}
  def display(:job_args, _value, _context), do: nil
  def display(:job_meta, _value, _context), do: nil
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertools.Web.JobsLiveDetailStringPolicy do
  # String → {:string, text}
  def display(:job_args, _value, _context), do: "args text from policy"
  def display(:job_meta, _value, _context), do: "meta text from policy"
  def display(:job_recorded, _value, _context), do: "recorded output from policy"
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertools.Web.JobsLiveDetailMapPolicy do
  # Map → {:raw_json, encoded redacted map}
  def display(:job_args, args, _context), do: Map.put(args, "secret", "REDACTED")
  def display(:job_meta, _meta, _context), do: %{"trace_id" => "abc-redacted"}

  def display(:job_recorded, _record, _context) do
    %{
      summary: "policy summary",
      payload: %{"policy" => "payload"},
      redacted?: true
    }
  end

  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertools.Web.JobsLiveDetailRaisingPolicy do
  # raise → {:fallback, "[redacted]"}
  def display(:job_args, _value, _context), do: raise("intentional test failure")
  def display(:job_meta, _value, _context), do: "meta ok"
  def display(:job_recorded, _value, _context), do: raise("recorded output failure")
  def display(_kind, _value, _context), do: nil
end

# REDACT-04: host policy that returns a custom map for :job_args — overlay must NOT be applied
defmodule ObanPowertools.Web.JobsLiveDetailCustomArgsPolicy do
  # Returns a custom map → host owns this, Powertools overlay must NOT be applied
  def display(:job_args, _value, _context), do: %{"custom" => "host_redacted"}
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertools.Web.JobsLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.JobRecord
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
      |> form("form[phx-change=filter]",
        filter: %{queue: "", worker: "MyApp.TargetWorker", tags: ""}
      )
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
  # Test 6b: Filters by JSON args/meta
  # ---------------------------------------------------------------------------

  test "filters by args/meta JSON", %{conn: conn} do
    insert_job!(worker: "MyApp.Worker1", queue: :default, args: %{"user_id" => 123}, meta: %{"batch_id" => 1})
    insert_job!(worker: "MyApp.Worker2", queue: :default, args: %{"user_id" => 456}, meta: %{"batch_id" => 2})

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_jobs]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/jobs?state=available")

    html =
      view
      |> form("form[phx-change=filter]",
        filter: %{queue: "", worker: "", tags: "", args: "{\"user_id\": 123}", meta: ""}
      )
      |> render_change()

    assert_patch(view, "/ops/jobs/jobs?state=available&args=%7B%22user_id%22%3A123%7D")
    assert html =~ "Worker1"
    refute html =~ "Worker2"

    html =
      view
      |> form("form[phx-change=filter]",
        filter: %{queue: "", worker: "", tags: "", args: "", meta: "{\"batch_id\": 2}"}
      )
      |> render_change()

    assert_patch(view, "/ops/jobs/jobs?state=available&meta=%7B%22batch_id%22%3A2%7D")
    assert html =~ "Worker2"
    refute html =~ "Worker1"
  end

  # ---------------------------------------------------------------------------
  # Test 6c: Invalid JSON args/meta blocks filter application
  # ---------------------------------------------------------------------------

  test "invalid JSON args/meta blocks filter application and shows error", %{conn: conn} do
    insert_job!(worker: "MyApp.Worker1", queue: :default)

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_jobs]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/jobs?state=available")

    html =
      view
      |> form("form[phx-change=filter]",
        filter: %{queue: "", worker: "", tags: "", args: "{invalid", meta: ""}
      )
      |> render_change()

    assert html =~ "Invalid JSON"
    assert html =~ "border-red-500"

    html =
      view
      |> form("form[phx-change=filter]",
        filter: %{queue: "", worker: "", tags: "", args: "", meta: "[1,2,"}
      )
      |> render_change()

    assert html =~ "Invalid JSON"
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

    assert html =~ "No jobs found"
  end

  # ---------------------------------------------------------------------------
  # Detail page tests
  # ---------------------------------------------------------------------------

  describe "Detail page" do
    test "redirects unauthorized viewers from detail page", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-2", permissions: []})

      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/jobs/1")
    end

    test "renders job detail with identity, timing, and panel headings", %{conn: conn} do
      job = insert_job!(worker: "MyApp.DetailWorker", queue: :default)

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      assert html =~ "Job ##{job.id}"
      assert html =~ "Back to Jobs"
      assert html =~ "Args"
      assert html =~ "Meta"
      assert html =~ "Errors"
      assert html =~ "Attempt History"
      # Short worker name (last segment)
      assert html =~ "DetailWorker"
      # Timing: inserted_at is always present — formatted timestamp contains "ago" or "UTC"
      assert html =~ "ago" or html =~ "UTC"
    end

    test "renders args as raw pretty JSON when policy returns nil", %{conn: conn} do
      original = Application.get_env(:oban_powertools, :display_policy)

      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertools.Web.JobsLiveDetailNilPolicy
      )

      on_exit(fn -> Application.put_env(:oban_powertools, :display_policy, original) end)

      job =
        insert_job!(
          worker: "MyApp.Worker",
          queue: :default,
          args: %{"id" => 42, "action" => "ingest"}
        )

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      # nil policy → raw JSON rendered inside <pre>
      assert html =~ "&quot;id&quot;" or html =~ "\"id\""
      assert html =~ "&quot;action&quot;" or html =~ "\"action\""
      assert html =~ "<pre"
    end

    test "renders args as host string when policy returns a String", %{conn: conn} do
      original = Application.get_env(:oban_powertools, :display_policy)

      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertools.Web.JobsLiveDetailStringPolicy
      )

      on_exit(fn -> Application.put_env(:oban_powertools, :display_policy, original) end)

      job = insert_job!(worker: "MyApp.Worker", queue: :default)

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      assert html =~ "args text from policy"
      assert html =~ "meta text from policy"
    end

    test "renders args/meta as redacted JSON when policy returns a Map", %{conn: conn} do
      original = Application.get_env(:oban_powertools, :display_policy)

      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertools.Web.JobsLiveDetailMapPolicy
      )

      on_exit(fn -> Application.put_env(:oban_powertools, :display_policy, original) end)

      job =
        insert_job!(
          worker: "MyApp.Worker",
          queue: :default,
          args: %{"id" => 7, "secret" => "TOP"}
        )

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      # Map policy puts "REDACTED" as the value for "secret" in args
      assert html =~ "REDACTED"
      # Meta policy returns %{"trace_id" => "abc-redacted"}
      assert html =~ "trace_id"
    end

    test "renders [redacted] fallback when policy raises", %{conn: conn} do
      original = Application.get_env(:oban_powertools, :display_policy)

      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertools.Web.JobsLiveDetailRaisingPolicy
      )

      on_exit(fn -> Application.put_env(:oban_powertools, :display_policy, original) end)

      job = insert_job!(worker: "MyApp.Worker", queue: :default)

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      # Must not crash despite policy raising for args
      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      # args panel shows [redacted] fallback
      assert html =~ "[redacted]"
      # meta panel shows the string "meta ok" (meta policy does not raise)
      assert html =~ "meta ok"
    end

    test "renders 'Job not found' message for unknown id", %{conn: conn} do
      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/999999999")

      assert html =~ "Job not found. It may have been pruned or the ID is invalid."
      assert html =~ "Back to Jobs"
    end

    test "renders errors panel with attempt records when errors exist", %{conn: conn} do
      job = insert_job!(worker: "MyApp.Worker", queue: :default)

      job
      |> Ecto.Changeset.change(
        state: "retryable",
        errors: [
          %{
            "at" => "2026-05-27T10:00:00Z",
            "attempt" => 1,
            "error" => "some failure\nbacktrace line"
          }
        ],
        attempt: 1
      )
      |> TestRepo.update!()

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      assert html =~ "Attempt 1"
      assert html =~ "some failure"
    end

    test "renders 'No errors recorded' empty state", %{conn: conn} do
      job = insert_job!(worker: "MyApp.Worker", queue: :default)

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      assert html =~ "No errors recorded for this job."
    end

    test "renders recorded output payload and retention metadata", %{conn: conn} do
      job = insert_job!(worker: "MyApp.RecordedWorker", queue: :default, state: "completed")

      assert :ok =
               JobRecord.record(
                 TestRepo,
                 "MyApp.RecordedWorker",
                 %{job | attempt: 2},
                 %{"message_id" => "msg_123", "delivered" => true},
                 summary: "notification delivered",
                 output_retention: :ephemeral
               )

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      assert html =~ "Recorded Output"
      assert html =~ "Available"
      assert html =~ "notification delivered"
      assert html =~ "ok"
      assert html =~ "Attempt"
      assert html =~ "2"
      assert html =~ "Payload Bytes"
      assert html =~ "Recorded At"
      assert html =~ "Retention"
      assert html =~ "ephemeral"
      assert html =~ "Expires At"
      assert html =~ "message_id"
      assert html =~ "msg_123"
    end

    test "renders neutral recorded output empty state when no record exists", %{conn: conn} do
      job = insert_job!(worker: "MyApp.Worker", queue: :default)

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      assert html =~ "Recorded Output"
      assert html =~ "No recorded output found for this job."
      refute html =~ "recording was disabled"
    end

    test "renders recorded output string policy with default metadata", %{conn: conn} do
      original = Application.get_env(:oban_powertools, :display_policy)

      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertools.Web.JobsLiveDetailStringPolicy
      )

      on_exit(fn -> Application.put_env(:oban_powertools, :display_policy, original) end)

      job = insert_job!(worker: "MyApp.RecordedWorker", queue: :default, state: "completed")

      assert :ok =
               JobRecord.record(
                 TestRepo,
                 "MyApp.RecordedWorker",
                 %{job | attempt: 1},
                 %{"raw" => "payload"},
                 summary: "default summary",
                 output_retention: :standard
               )

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      assert html =~ "Recorded Output"
      assert html =~ "default summary"
      assert html =~ "recorded output from policy"
      assert html =~ "standard"
    end

    test "renders recorded output map policy and fallback without crashing", %{conn: conn} do
      original = Application.get_env(:oban_powertools, :display_policy)
      job = insert_job!(worker: "MyApp.RecordedWorker", queue: :default, state: "completed")

      assert :ok =
               JobRecord.record(
                 TestRepo,
                 "MyApp.RecordedWorker",
                 %{job | attempt: 1},
                 %{"raw" => "payload"},
                 summary: "default summary"
               )

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertools.Web.JobsLiveDetailMapPolicy
      )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      assert html =~ "policy summary"
      assert html =~ "policy"
      assert html =~ "payload"
      assert html =~ "Redacted Metadata"

      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertools.Web.JobsLiveDetailRaisingPolicy
      )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      assert html =~ "Recorded output hidden by display policy fallback."

      on_exit(fn -> Application.put_env(:oban_powertools, :display_policy, original) end)
    end

    test "detail page read-only banner appears for actor without retry permission", %{conn: conn} do
      job = insert_job!(worker: "MyApp.Worker", queue: :default)

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      assert html =~ "Job detail stays visible"
    end

    test "detail page back link points to /ops/jobs/jobs", %{conn: conn} do
      job = insert_job!(worker: "MyApp.Worker", queue: :default)

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      # Back link should point to the jobs list path
      assert html =~ "/ops/jobs/jobs"
    end

    test "renders action buttons depending on state when operator has retry permission", %{
      conn: conn
    } do
      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail, :retry_job]}
        )

      # Executing job
      job_executing = insert_job!(worker: "W1", queue: :default, state: "executing")
      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job_executing.id}")
      assert html =~ "Cancel Job"
      assert html =~ "Discard Job"
      refute html =~ "Retry Job"

      # Retryable job
      job_retryable = insert_job!(worker: "W2", queue: :default, state: "retryable")
      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job_retryable.id}")
      assert html =~ "Cancel Job"
      assert html =~ "Discard Job"
      assert html =~ "Retry Job"
    end

    test "executing an action opens preview, accepts reason, and executes", %{conn: conn} do
      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{
            id: "ops-1",
            permissions: [:view_job_detail, :retry_job, :preview_repair, :execute_repair]
          }
        )

      job = insert_job!(worker: "W", queue: :default, state: "retryable")

      {:ok, view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      assert html =~ "Cancel Job"

      html =
        view
        |> element("button[phx-click=\"preview\"][phx-value-action=\"job_cancel\"]")
        |> render_click()

      assert html =~ "Cancel Job ##{job.id}"
      assert html =~ "Reason (required)"

      # Execute with reason
      view
      |> form("form[phx-submit=\"execute\"]", %{"reason" => "Operator requested cancellation"})
      |> render_submit()

      # Should flash success and reload (modal closes, state updates)
      assert_patch(view, "/ops/jobs/jobs/#{job.id}")
      assert view |> render() |> String.contains?("cancelled")
    end

    test "concurrent modification displays drift error in modal", %{conn: conn} do
      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{
            id: "ops-1",
            permissions: [:view_job_detail, :retry_job, :preview_repair, :execute_repair]
          }
        )

      job = insert_job!(worker: "W", queue: :default, state: "retryable")

      {:ok, view, _html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      view
      |> element("button[phx-click=\"preview\"][phx-value-action=\"job_discard\"]")
      |> render_click()

      # Drift the state
      job |> Ecto.Changeset.change(state: "cancelled") |> TestRepo.update!()

      html =
        view
        |> form("form[phx-submit=\"execute\"]", %{"reason" => "Discard it"})
        |> render_submit()

      assert html =~
               "Could not execute action. The job&#39;s state was changed by another process or operator."
    end
  end

  # ---------------------------------------------------------------------------
  # REDACT-03 / REDACT-04: Redaction disclosure + render_job_field overlay
  # ---------------------------------------------------------------------------

  describe "Redaction disclosure (REDACT-03)" do
    test "renders 'Fields redacted at enqueue' disclosure with comma-joined atom form when __redacted_fields__ present",
         %{conn: conn} do
      original = Application.get_env(:oban_powertools, :display_policy)

      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertools.Web.JobsLiveDetailNilPolicy
      )

      on_exit(fn -> Application.put_env(:oban_powertools, :display_policy, original) end)

      job =
        insert_job!(
          worker: "MyApp.RedactWorker",
          queue: :default,
          args: %{"user_id" => 42},
          meta: %{"__redacted_fields__" => ["ssn", "token"]}
        )

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      # Disclosure header must appear
      assert html =~ "Fields redacted at enqueue"

      # Comma-joined atom-presentation form (D-13/D-17/UI-SPEC) — locked joined form, not separate assertions
      assert html =~ ":ssn, :token"
    end

    test "renders no disclosure block when __redacted_fields__ is absent (honest empty state)",
         %{conn: conn} do
      job =
        insert_job!(
          worker: "MyApp.NoRedactWorker",
          queue: :default,
          args: %{"user_id" => 99}
        )

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      refute html =~ "Fields redacted at enqueue"
    end
  end

  describe "render_job_field :job_args overlay (REDACT-04)" do
    test "render_job_field(:job_args) overlays 'Redacted at enqueue' for each redacted field when host policy returns nil",
         %{conn: conn} do
      original = Application.get_env(:oban_powertools, :display_policy)

      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertools.Web.JobsLiveDetailNilPolicy
      )

      on_exit(fn -> Application.put_env(:oban_powertools, :display_policy, original) end)

      job =
        insert_job!(
          worker: "MyApp.RedactArgsWorker",
          queue: :default,
          args: %{"user_id" => 42},
          meta: %{"__redacted_fields__" => ["ssn", "token"]}
        )

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      # The args panel must show "Redacted at enqueue" for the listed fields
      assert html =~ "Redacted at enqueue"
    end

    test "render_job_field(:job_args) does NOT apply overlay when host policy returns a custom map (OQ3 passthrough)",
         %{conn: conn} do
      original = Application.get_env(:oban_powertools, :display_policy)

      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertools.Web.JobsLiveDetailCustomArgsPolicy
      )

      on_exit(fn -> Application.put_env(:oban_powertools, :display_policy, original) end)

      job =
        insert_job!(
          worker: "MyApp.CustomPolicyWorker",
          queue: :default,
          args: %{"user_id" => 42},
          meta: %{"__redacted_fields__" => ["ssn"]}
        )

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      # Host policy custom map returned → "custom" key present, NOT Powertools overlay
      assert html =~ "host_redacted"
      refute html =~ "Redacted at enqueue"
    end

    test "render_job_field(:job_args) returns [redacted] fallback when host policy raises",
         %{conn: conn} do
      original = Application.get_env(:oban_powertools, :display_policy)

      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertools.Web.JobsLiveDetailRaisingPolicy
      )

      on_exit(fn -> Application.put_env(:oban_powertools, :display_policy, original) end)

      job =
        insert_job!(
          worker: "MyApp.FallbackWorker",
          queue: :default,
          args: %{"user_id" => 42},
          meta: %{"__redacted_fields__" => ["ssn"]}
        )

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      # Raising policy → bounded [redacted] fallback, never raw args exposed
      assert html =~ "[redacted]"
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp insert_job!(opts) do
    {state, opts} = Keyword.pop(opts, :state, "available")
    {args, opts} = Keyword.pop(opts, :args, %{})

    job =
      args
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

  # ---------------------------------------------------------------------------
  # Test 11: Bulk Job Selection and Execution
  # ---------------------------------------------------------------------------

  describe "Bulk actions" do
    test "job selection state and UI", %{conn: conn} do
      job1 = insert_job!(worker: "MyApp.Worker1", queue: :default)
      job2 = insert_job!(worker: "MyApp.Worker2", queue: :default)

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_jobs]}
        )

      {:ok, view, html} = live(conn, "/ops/jobs/jobs?state=available")

      # Checkboxes are rendered
      assert html =~ "type=\"checkbox\""
      refute html =~ "jobs selected"

      # Toggle one job
      html =
        view
        |> element("input[phx-click=\"toggle_job\"][phx-value-id=\"#{job1.id}\"]")
        |> render_click()

      assert html =~ "1 jobs selected"

      html = render_hook(view, "toggle_job", %{"id" => "not-an-integer"})
      assert html =~ "1 jobs selected"

      # Toggle all jobs
      html = view |> element("input[phx-click=\"toggle_all\"]") |> render_click()
      assert html =~ "2 jobs selected"

      # Change state to clear selection
      view |> element("button[phx-value-state=executing]") |> render_click()
      html = render(view)
      refute html =~ "jobs selected"
    end

    test "executing bulk action", %{conn: conn} do
      job1 = insert_job!(worker: "MyApp.Worker1", queue: :default, state: "retryable")
      job2 = insert_job!(worker: "MyApp.Worker2", queue: :default, state: "retryable")

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{
            id: "ops-1",
            permissions: [:view_jobs, :retry_job, :preview_repair, :execute_repair]
          }
        )

      {:ok, view, _html} = live(conn, "/ops/jobs/jobs?state=retryable")

      # Select all
      view |> element("input[phx-click=\"toggle_all\"]") |> render_click()

      # Click preview
      html =
        view
        |> element("button[phx-click=\"preview_bulk\"][phx-value-action=\"job_discard\"]")
        |> render_click()

      assert html =~ "Bulk Discard 2 Jobs"

      # Execute
      view
      |> form("form[phx-submit=\"execute_bulk\"]", %{"reason" => "Bulk discard test"})
      |> render_submit()

      html = render(view)
      assert html =~ "No jobs found"

      # Selection should be cleared
      refute html =~ "jobs selected"
    end
  end
end
