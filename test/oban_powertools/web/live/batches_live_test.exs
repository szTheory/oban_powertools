defmodule ObanPowertools.Web.BatchesLiveTestDisplayPolicy do
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertools.Web.BatchesLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.{Batch, BatchJob, Callback, TestRepo}

  setup do
    original_display_policy = Application.get_env(:oban_powertools, :display_policy)

    Application.put_env(
      :oban_powertools,
      :display_policy,
      ObanPowertools.Web.BatchesLiveTestDisplayPolicy
    )

    on_exit(fn ->
      Application.put_env(:oban_powertools, :display_policy, original_display_policy)
    end)

    :ok
  end

  @tag :phase62_batches_render
  test "index renders locked copy, metrics, status tabs, empty state, and URL filters", %{
    conn: conn
  } do
    conn = actor_conn(conn, [:view_batches])

    {:ok, view, html} = live(conn, "/ops/jobs/batches?status=all")

    assert html =~ "Batches"

    assert html =~
             "Inspect batch and chain progress, failed members, blocked states, and Lifeline recovery paths."

    assert html =~ "Total Batches"
    assert html =~ "Needs Attention"
    assert html =~ "Executing"
    assert html =~ "Completed"
    assert html =~ "No batches match this view"
    assert html =~ "insert_failed"
    assert html =~ "callback_failed"
    assert html =~ "Permission: read-only"

    html =
      view
      |> form("form[phx-change=filter]",
        filter: %{query: "billing", queue: "", worker: "", chain_only: "false"}
      )
      |> render_change()

    assert_patch(view, "/ops/jobs/batches?status=all&query=billing")
    assert html =~ "No batches match this view"
  end

  @tag :phase62_batches_render
  test "detail renders failed members, callbacks, chain context, bridge copy, and blocked explanation",
       %{
         conn: conn
       } do
    batch = insert_batch!(name: "billing-chain", status: "callback_failed", total_count: 2)

    job =
      insert_job!(
        %{
          "batch_id" => batch.id,
          "chain_id" => "chain-a",
          "chain_step_name" => "charge",
          "chain_step_index" => 2,
          "chain_step_count" => 3,
          "upstream_job_id" => 42
        },
        worker: "MyApp.BillingWorker",
        queue: :billing,
        state: "discarded",
        errors: [%{"attempt" => 1, "error" => "boom"}]
      )

    insert_batch_job!(batch, job, state: "discarded")
    insert_callback!(batch, status: "failed", last_error: "output_unavailable")

    conn = actor_conn(conn, [:view_batch_detail])

    {:ok, _view, html} = live(conn, "/ops/jobs/batches/#{batch.id}")

    assert html =~ "Batch billing-chain"
    assert html =~ "Why this batch is blocked"
    assert html =~ "Failed Members"
    assert html =~ "Callback Outbox"
    assert html =~ "Chain Context"
    assert html =~ "Open Generic Job Inspection in Oban Web bridge"

    assert html =~ "No stuck or dead callbacks are blocking this batch" or
             html =~ "Preview Callback Retry"
  end

  @tag :phase62_batch_bulk_retry
  test "failed-member retry controls are read-only without retry_batch_jobs permission", %{
    conn: conn
  } do
    batch = insert_batch!(status: "exhausted", total_count: 1, discard_count: 1)

    job =
      insert_job!(%{"batch_id" => batch.id},
        worker: "MyApp.Worker",
        queue: :default,
        state: "discarded"
      )

    insert_batch_job!(batch, job, state: "discarded")

    conn = actor_conn(conn, [:view_batch_detail])

    {:ok, _view, html} = live(conn, "/ops/jobs/batches/#{batch.id}")

    assert html =~ "Retry Failed Jobs"
    assert html =~ ":retry_batch_jobs" or html =~ "retry_batch_jobs"
    assert html =~ "Permission: read-only"
  end

  @tag :phase62_batch_bulk_retry
  test "bulk retry is page-local, reason-gated, and reports successes plus failures", %{
    conn: conn
  } do
    batch = insert_batch!(status: "exhausted", total_count: 2, discard_count: 2)

    job1 =
      insert_job!(%{"batch_id" => batch.id},
        worker: "MyApp.Worker1",
        queue: :default,
        state: "discarded"
      )

    job2 =
      insert_job!(%{"batch_id" => batch.id},
        worker: "MyApp.Worker2",
        queue: :default,
        state: "discarded"
      )

    insert_batch_job!(batch, job1, state: "discarded")
    insert_batch_job!(batch, job2, state: "discarded")

    conn =
      actor_conn(conn, [
        :view_batch_detail,
        :retry_batch_jobs,
        :preview_repair,
        :execute_repair
      ])

    {:ok, view, _html} = live(conn, "/ops/jobs/batches/#{batch.id}")

    html =
      view
      |> element("input[phx-click=\"toggle_failed_job\"][phx-value-id=\"#{job1.id}\"]")
      |> render_click()

    assert html =~ "1 failed jobs selected"

    html =
      view
      |> element("button[phx-click=\"preview_bulk_retry\"]")
      |> render_click()

    assert html =~ "Retry Failed Jobs"
    assert html =~ "Reason (required)"

    view
    |> form("form[phx-submit=\"execute_bulk_retry\"]", %{
      "reason" => "upstream outage resolved, safe to replay failed rows"
    })
    |> render_submit()

    assert render(view) =~ "Batch retry complete:"
  end

  @tag :phase62_batch_callback_retry
  test "callback retry controls are read-only without retry_callback permission", %{conn: conn} do
    batch = insert_batch!(status: "callback_failed")
    callback = insert_callback!(batch, status: "failed")

    conn = actor_conn(conn, [:view_batch_detail])

    {:ok, _view, html} = live(conn, "/ops/jobs/batches/#{batch.id}")

    assert html =~ callback.event
    assert html =~ "Preview Callback Retry"
    assert html =~ ":retry_callback" or html =~ "retry_callback"
    assert html =~ "Permission: read-only"
  end

  @tag :phase62_batch_callback_retry
  test "callback retry previews, requires reason, executes, and handles drift errors", %{
    conn: conn
  } do
    batch = insert_batch!(status: "callback_failed")
    callback = insert_callback!(batch, status: "failed", last_error: "temporary outage")

    conn =
      actor_conn(conn, [
        :view_batch_detail,
        :retry_callback,
        :preview_repair,
        :execute_repair
      ])

    {:ok, view, _html} = live(conn, "/ops/jobs/batches/#{batch.id}")

    html =
      view
      |> element("button[phx-click=\"preview_callback_retry\"][phx-value-id=\"#{callback.id}\"]")
      |> render_click()

    assert html =~ "Preview Callback Retry"
    assert html =~ "callback_retry"
    assert html =~ "Reason (required)"

    callback
    |> Callback.changeset(%{last_error: "state drifted"})
    |> TestRepo.update!()

    html =
      view
      |> form("form[phx-submit=\"execute_callback_retry\"]", %{
        "reason" => "upstream outage resolved, safe to retry callback"
      })
      |> render_submit()

    assert html =~ "preview_drifted"
  end

  defp actor_conn(conn, permissions) do
    Plug.Test.init_test_session(conn, current_actor: %{id: "ops-1", permissions: permissions})
  end

  defp insert_batch!(attrs) do
    defaults = %{
      status: "executing",
      total_count: 1,
      success_count: 0,
      discard_count: 0,
      cancelled_count: 0,
      snooze_count: 0,
      inserted_count: 1,
      insert_chunk_count: 1,
      insert_failure: %{}
    }

    %Batch{}
    |> Batch.changeset(Map.merge(defaults, Map.new(attrs)))
    |> TestRepo.insert!()
  end

  defp insert_job!(meta, opts) do
    {state, opts} = Keyword.pop(opts, :state, "available")
    {errors, opts} = Keyword.pop(opts, :errors, [])

    job =
      meta
      |> Oban.Job.new(opts)
      |> Ecto.Changeset.change(errors: errors)
      |> TestRepo.insert!()

    if state == "available" do
      job
    else
      job
      |> Ecto.Changeset.change(state: state)
      |> TestRepo.update!()
    end
  end

  defp insert_batch_job!(batch, job, attrs \\ []) do
    %BatchJob{}
    |> BatchJob.changeset(%{
      batch_id: batch.id,
      job_id: job.id,
      state: Keyword.get(attrs, :state, job.state)
    })
    |> TestRepo.insert!()
  end

  defp insert_callback!(batch, attrs) do
    defaults = %{
      batch_id: batch.id,
      event: "batch.exhausted",
      dedupe_key: Ecto.UUID.generate(),
      status: "failed",
      payload: %{"batch_id" => batch.id, "chain_id" => "chain-a"},
      attempts: 1,
      available_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
    }

    %Callback{}
    |> Callback.changeset(Map.merge(defaults, Map.new(attrs)))
    |> TestRepo.insert!()
  end
end
