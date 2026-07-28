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
  alias ObanPowertools.Web.JobsLive

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

  describe "bounded browse and quick review" do
    test "canonicalizes missing and invalid URL values before loading", %{conn: conn} do
      conn = jobs_conn(conn)

      {{:ok, _view, html}, queries} =
        capture_job_queries(fn ->
          live(
            conn,
            "/ops/jobs/jobs?state=unknown&page=nope&args=%7Bbad&job=not-an-id&surprise=true"
          )
        end)

      assert length(queries) == 3
      assert html =~ "Some filters were not applied"

      assert html =~
               "The invalid filter values were removed. Review the applied filters and try again."

      assert html =~ "0 available jobs"
      assert html =~ "Showing 0 of 0"
    end

    test "renders the shared filter, semantic table, exact hierarchy, and empty truth", %{
      conn: conn
    } do
      insert_job!(worker: "MyApp.Full.AvailableWorker", queue: :default)
      insert_job!(worker: "MyApp.ExecutingWorker", queue: :default, state: "executing")

      {:ok, _view, html} = live(jobs_conn(conn), "/ops/jobs/jobs?state=available")

      assert count(html, "<h1") == 1
      assert count(html, "<table") == 1
      refute html =~ "role=\"grid\""
      assert html =~ "Review current job state, apply precise filters"
      assert html =~ ~s(data-obpt-filter-bar)
      assert html =~ ~s(phx-change="validate_filters")
      assert html =~ ~s(phx-submit="apply_filters")

      for label <- [
            "Selection",
            "Worker",
            "State",
            "Queue",
            "Scheduled",
            "Attempts",
            "Job ID",
            "Review job"
          ] do
        assert html =~ label
      end

      assert html =~ "MyApp.Full.AvailableWorker"
      assert html =~ "1 available job"
      assert html =~ "Showing 1–1 of 1"
      refute html =~ "sort"
      refute html =~ "cursor"

      {:ok, _view, empty_html} =
        live(jobs_conn(conn), "/ops/jobs/jobs?state=discarded")

      assert empty_html =~ "No jobs match the applied filters"
      assert empty_html =~ "Remove a filter or clear all filters to widen the review."
    end

    test "draft change validates without queries or navigation and apply patches once", %{
      conn: conn
    } do
      insert_job!(worker: "MyApp.AlphaWorker", queue: :alpha)
      insert_job!(worker: "MyApp.DefaultWorker", queue: :default)
      {:ok, view, _html} = live(jobs_conn(conn), "/ops/jobs/jobs?state=available")

      {html, queries} =
        capture_job_queries(fn ->
          view
          |> form("#jobs-filter-form",
            filter: %{
              queue: "alpha",
              worker: "",
              tags: "",
              args: "",
              meta: ""
            }
          )
          |> render_change()
        end)

      assert queries == []
      assert html =~ "Changes not applied."
      assert html =~ ~s(value="alpha")
      assert html =~ "2 available jobs"
      assert html =~ "MyApp.DefaultWorker"

      {_html, queries} =
        capture_job_queries(fn ->
          view
          |> form("#jobs-filter-form",
            filter: %{
              queue: "alpha",
              worker: "",
              tags: "",
              args: "",
              meta: ""
            }
          )
          |> render_submit()
        end)

      assert_patch(view, "/ops/jobs/jobs?state=available&queue=alpha")
      assert length(queries) == 3
      html = render(view)
      assert html =~ "<strong>Queue:</strong> alpha"
      assert html =~ "MyApp.AlphaWorker"
      refute html =~ "MyApp.DefaultWorker"
    end

    test "retains invalid JSON draft with exact help and errors without a load", %{conn: conn} do
      {:ok, view, _html} = live(jobs_conn(conn), "/ops/jobs/jobs?state=available")

      {html, queries} =
        capture_job_queries(fn ->
          view
          |> form("#jobs-filter-form",
            filter: %{
              queue: "",
              worker: "status:executing",
              tags: "urgent, billing",
              args: "{invalid",
              meta: "[]"
            }
          )
          |> render_change()
        end)

      assert queries == []
      assert html =~ "status:executing"
      assert html =~ "{invalid"
      assert html =~ "Separate tags with commas. Jobs must contain every listed tag."

      assert html =~
               "Enter a JSON object. Filter values are stored in the URL; do not enter secrets."

      assert count(html, "Enter a valid JSON object.") == 2
    end

    test "renders human applied filters with canonical remove and clear destinations", %{
      conn: conn
    } do
      url =
        "/ops/jobs/jobs?state=retryable&queue=alpha&worker=MyApp.Worker&tags=urgent%2Cbilling&page=2"

      {:ok, _view, html} = live(jobs_conn(conn), url)

      assert html =~ "<strong>Queue:</strong> alpha"
      assert html =~ "<strong>Worker module:</strong> MyApp.Worker"
      assert html =~ "<strong>Tags:</strong> urgent, billing"

      assert html =~
               "/ops/jobs/jobs?state=retryable&amp;worker=MyApp.Worker&amp;tags=urgent%2Cbilling"

      assert html =~ "/ops/jobs/jobs?state=retryable"
    end

    test "uses exact counts to disable Next on a full final page", %{conn: conn} do
      for index <- 1..40 do
        insert_job!(worker: "MyApp.PageWorker#{index}", queue: :default)
      end

      {:ok, view, html} = live(jobs_conn(conn), "/ops/jobs/jobs?state=available&page=2")

      assert html =~ "40 available jobs"
      assert html =~ "Showing 21–40 of 40"
      assert has_element?(view, "#jobs-next-page[disabled]")
      assert has_element?(view, "#jobs-previous-page[phx-click=paginate]")
    end

    test "explicit selection persists across pagination and exposes page tri-state", %{conn: conn} do
      jobs =
        for index <- 1..21 do
          insert_job!(worker: "MyApp.SelectionWorker#{index}", queue: :default)
        end

      selected = List.last(jobs)
      {:ok, view, _html} = live(jobs_conn(conn), "/ops/jobs/jobs?state=available")

      html =
        view
        |> element("#job-select-#{selected.id}")
        |> render_click()

      assert html =~ "1 job selected"
      assert html =~ ~s(data-obpt-page-selection="mixed")

      view |> element("#jobs-next-page") |> render_click()
      assert_patch(view, "/ops/jobs/jobs?state=available&page=2")
      assert render(view) =~ "1 job selected"

      view |> element("#jobs-previous-page") |> render_click()
      assert_patch(view, "/ops/jobs/jobs?state=available")
      assert render(view) =~ ~r/id="job-select-#{selected.id}"[^>]*checked/
    end

    test "opens, switches, closes, and reloads one redacted quick review", %{conn: conn} do
      first =
        insert_job!(
          worker: "MyApp.FirstWorker",
          queue: :default,
          args: %{"secret" => "QUICK_REVIEW_SENTINEL"}
        )

      second = insert_job!(worker: "MyApp.SecondWorker", queue: :default)
      conn = jobs_conn(conn, [:view_job_detail])
      {:ok, view, _html} = live(conn, "/ops/jobs/jobs?state=available")

      html = view |> element("#job-review-#{first.id}") |> render_click()
      assert_patch(view, "/ops/jobs/jobs?state=available&job=#{first.id}")
      assert html =~ "Review job #{first.id}"
      assert html =~ "Open full job details"
      assert html =~ "MyApp.FirstWorker"
      refute html =~ "QUICK_REVIEW_SENTINEL"

      view |> element("#job-review-#{second.id}") |> render_click()
      assert_patch(view, "/ops/jobs/jobs?state=available&job=#{second.id}")
      assert render(view) =~ "MyApp.SecondWorker"

      view |> element("button[phx-click=close_review]") |> render_click()
      assert_patch(view, "/ops/jobs/jobs?state=available")
      refute render(view) =~ ~s(data-obpt-detail-surface)

      {:ok, _view, deep_link_html} =
        live(conn, "/ops/jobs/jobs?state=available&job=#{first.id}")

      assert deep_link_html =~ "Review job #{first.id}"
    end

    test "missing and unauthorized review IDs have one unavailable outcome", %{conn: conn} do
      job = insert_job!(worker: "MyApp.PrivateWorker", queue: :default)

      {:ok, unauthorized_view, _html} =
        live(jobs_conn(conn), "/ops/jobs/jobs?state=available")

      unauthorized_html =
        render_patch(
          unauthorized_view,
          "/ops/jobs/jobs?state=available&job=#{job.id}"
        )

      assert_patch(unauthorized_view, "/ops/jobs/jobs?state=available")
      assert unauthorized_html =~ "Job unavailable"
      refute has_element?(unauthorized_view, "#job-quick-review")

      {:ok, missing_view, _html} =
        live(jobs_conn(conn, [:view_job_detail]), "/ops/jobs/jobs?state=available")

      missing_html =
        render_patch(
          missing_view,
          "/ops/jobs/jobs?state=available&job=999999999"
        )

      assert_patch(missing_view, "/ops/jobs/jobs?state=available")
      assert missing_html =~ "Job unavailable"
    end

    test "exports pure index composition",
      do: assert(function_exported?(JobsLive, :page_content, 1))
  end

  # ---------------------------------------------------------------------------
  # Detail page tests
  # ---------------------------------------------------------------------------

  describe "Detail page" do
    test "pure detail composition is incident-first and uses shared data components" do
      job = %Oban.Job{
        id: 88,
        state: "retryable",
        worker: "MyApp.PureDetailWorker",
        queue: "critical",
        attempt: 2,
        max_attempts: 10,
        priority: 1,
        inserted_at: ~U[2026-07-28 01:00:00Z],
        scheduled_at: ~U[2026-07-28 01:05:00Z],
        attempted_at: ~U[2026-07-28 01:10:00Z],
        errors: [
          %{
            "attempt" => 2,
            "at" => "2026-07-28T01:10:00Z",
            "error" => "** (RuntimeError) safe failure summary"
          }
        ],
        meta: %{"__redacted_fields__" => ["credential"]}
      }

      detail =
        ObanPowertools.Web.ControlPlanePresenter.present_job_detail(job, %{
          args_display: {:raw_json, ~s({"account_id":"[redacted]"})},
          meta_display: {:string, "Metadata hidden by host policy."},
          recorded_output_display: %{
            available?: false,
            summary: "No recorded output found for this job.",
            status: nil,
            payload: "No recorded output found for this job.",
            redacted?: false
          },
          audit_href: "/ops/jobs/audit?resource_type=job&resource_id=88"
        })

      html =
        render_component(&JobsLive.page_content/1, %{
          page_mode: :detail,
          detail: detail,
          detail_unavailable?: false,
          back_path: "/ops/jobs/jobs?state=retryable&page=2",
          read_only?: false,
          confirmation: nil,
          receipt: nil
        })

      assert count(html, "<h1") == 1
      assert html =~ "Job #88"
      assert html =~ ~s(id="job-current-state")
      assert html =~ ~s(id="job-actions")
      assert html =~ ~s(id="job-identity")
      assert html =~ ~s(id="job-timing")
      assert html =~ ~s(id="job-errors")
      assert html =~ ~s(id="job-arguments")
      assert html =~ ~s(id="job-metadata")
      assert html =~ ~s(id="job-recorded-output")
      assert html =~ ~s(id="job-destinations")
      assert html =~ ~s(class="obpt-description-list")
      assert html =~ ~s(class="obpt-args-viewer")

      assert ordered?(html, [
               ~s(id="job-current-state"),
               ~s(id="job-actions"),
               ~s(id="job-identity"),
               ~s(id="job-timing"),
               ~s(id="job-errors"),
               ~s(id="job-arguments"),
               ~s(id="job-destinations")
             ])

      refute html =~ "__redacted_fields__"
      refute html =~ "credential"
    end

    test "detail return context is reconstructed from allowlisted list params", %{conn: conn} do
      job = insert_job!(worker: "MyApp.ReturnWorker", queue: :default)

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail, :view_audit]}
        )

      {:ok, _view, html} =
        live(
          conn,
          "/ops/jobs/jobs/#{job.id}?state=retryable&queue=critical%26urgent&page=2&job=77&return_to=https%3A%2F%2Fattacker.invalid%2F%3Ftoken%3DSYNTHETIC_TOKEN&surprise=true"
        )

      assert html =~
               "/ops/jobs/jobs?state=retryable&amp;queue=critical%26urgent&amp;page=2"

      refute html =~ "return_to"
      refute html =~ "attacker.invalid"
      refute html =~ "SYNTHETIC_TOKEN"
      refute html =~ "job=77"
    end

    test "malformed and missing detail targets render the same unavailable content", %{conn: conn} do
      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _missing_view, missing_html} = live(conn, "/ops/jobs/jobs/999999999")
      {:ok, _malformed_view, malformed_html} = live(conn, "/ops/jobs/jobs/not-an-id")

      for html <- [missing_html, malformed_html] do
        assert html =~ "Job unavailable"

        assert html =~
                 "It may not exist, may no longer be available, or you may not have access. Return to Jobs and choose another job."

        refute html =~ "pruned"
        refute html =~ "invalid"
      end

      assert body_text(missing_html) == body_text(malformed_html)
    end

    test "detail renders bounded error summaries without raw failures or manufactured Forensics",
         %{conn: conn} do
      job = insert_job!(worker: "MyApp.SafeErrorWorker", queue: :default)

      job
      |> Ecto.Changeset.change(
        state: "retryable",
        errors: [
          %{
            "at" => "2026-07-28T10:00:00Z",
            "attempt" => 1,
            "error" =>
              "** (RuntimeError) request failed at https://secret.invalid/?token=RAW_ERROR_SENTINEL"
          }
        ],
        attempt: 1
      )
      |> TestRepo.update!()

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail, :view_audit]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")

      assert html =~ "Failure details are redacted."
      assert html =~ "View matching audit evidence"
      refute html =~ "RAW_ERROR_SENTINEL"
      refute html =~ "secret.invalid"
      refute html =~ "Open job forensics"
    end

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
      assert html =~ "Arguments"
      assert html =~ "Metadata"
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

    test "renders uniform unavailable message for unknown id", %{conn: conn} do
      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{id: "ops-1", permissions: [:view_job_detail]}
        )

      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/999999999")

      assert html =~ "Job unavailable"

      assert html =~
               "It may not exist, may no longer be available, or you may not have access. Return to Jobs and choose another job."

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
      assert html =~ "Failure details are unavailable."
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

      assert html =~ "Recorded output"
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

      assert html =~ "Recorded output"
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

      assert html =~ "Recorded output"
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
      assert html =~ "Hidden by display policy"
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
      assert html =~ "Cancel job"
      assert html =~ "Discard job"
      refute html =~ "Retry job"

      # Retryable job
      job_retryable = insert_job!(worker: "W2", queue: :default, state: "retryable")
      {:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job_retryable.id}")
      assert html =~ "Cancel job"
      assert html =~ "Discard job"
      assert html =~ "Retry job"
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

      assert html =~ "Cancel job"

      html =
        view
        |> element("button[phx-click=\"preview\"][phx-value-action=\"job_cancel\"]")
        |> render_click()

      assert html =~ "Cancel this job for job ##{job.id}"
      assert html =~ "Reason"
      assert html =~ "obpt-modal-backdrop"
      assert html =~ "obpt-modal"
      assert html =~ "obpt-modal-summary"

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

      assert html =~ "2 argument fields were redacted at enqueue."
      refute html =~ ":ssn"
      refute html =~ ":token"
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

  defp count(html, needle) do
    html
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end

  defp ordered?(html, needles) do
    {positions, _offset} =
      Enum.map_reduce(needles, 0, fn needle, offset ->
        case :binary.match(html, needle, scope: {offset, byte_size(html) - offset}) do
          {position, _length} -> {position, position + byte_size(needle)}
          :nomatch -> {-1, offset}
        end
      end)

    Enum.all?(positions, &(&1 >= 0)) and positions == Enum.sort(positions)
  end

  defp body_text(html) do
    case Regex.run(~r/<section id="job-unavailable".*?<\/section>/s, html) do
      [fragment] -> fragment |> String.replace(~r/\s+/, " ") |> String.trim()
      nil -> ""
    end
  end

  defp jobs_conn(conn, extra_permissions \\ []) do
    Plug.Test.init_test_session(conn,
      current_actor: %{
        id: "ops-1",
        permissions: [:view_jobs | extra_permissions]
      }
    )
  end

  defp capture_job_queries(fun) do
    handler_id = {__MODULE__, make_ref()}
    event = TestRepo.config() |> Keyword.fetch!(:telemetry_prefix) |> Kernel.++([:query])
    test_pid = self()

    :telemetry.attach(
      handler_id,
      event,
      fn _event, _measurements, metadata, pid ->
        if metadata[:source] == "oban_jobs" do
          send(pid, {:job_query, metadata.query})
        end
      end,
      test_pid
    )

    try do
      result = fun.()
      {result, collect_job_queries([])}
    after
      :telemetry.detach(handler_id)
    end
  end

  defp collect_job_queries(queries) do
    receive do
      {:job_query, query} -> collect_job_queries([query | queries])
    after
      0 -> Enum.reverse(queries)
    end
  end

  # ---------------------------------------------------------------------------
  # Test 11: Bulk Job Selection and Execution
  # ---------------------------------------------------------------------------

  describe "Bulk actions" do
    test "job selection state and UI", %{conn: conn} do
      job1 = insert_job!(worker: "MyApp.Worker1", queue: :default)
      _job2 = insert_job!(worker: "MyApp.Worker2", queue: :default)

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

      assert html =~ "1 job selected"

      html = render_hook(view, "toggle_job", %{"id" => "not-an-integer"})
      assert html =~ "1 job selected"

      # Toggle all jobs
      html = view |> element("input[phx-click=\"toggle_page\"]") |> render_click()
      assert html =~ "2 jobs selected"

      # Change state to clear selection
      view |> element("button[phx-value-state=executing]") |> render_click()
      html = render(view)
      refute html =~ "jobs selected"
    end

    test "executing bulk action", %{conn: conn} do
      _job1 = insert_job!(worker: "MyApp.Worker1", queue: :default, state: "retryable")
      _job2 = insert_job!(worker: "MyApp.Worker2", queue: :default, state: "retryable")

      conn =
        Plug.Test.init_test_session(conn,
          current_actor: %{
            id: "ops-1",
            permissions: [:view_jobs, :retry_job, :preview_repair, :execute_repair]
          }
        )

      {:ok, view, _html} = live(conn, "/ops/jobs/jobs?state=retryable")

      # Select all
      view |> element("input[phx-click=\"toggle_page\"]") |> render_click()

      # Click preview
      html =
        view
        |> element("button[phx-click=\"preview_bulk\"][phx-value-action=\"job_discard\"]")
        |> render_click()

      assert html =~ "Bulk Discard 2 Jobs"
      assert html =~ "obpt-modal-backdrop"
      assert html =~ "obpt-modal"

      # Execute
      view
      |> form("form[phx-submit=\"execute_bulk\"]", %{"reason" => "Bulk discard test"})
      |> render_submit()

      html = render(view)
      assert html =~ "No jobs match the applied filters"

      # Selection should be cleared
      refute html =~ "jobs selected"
    end
  end
end
