defmodule ObanPowertools.BatchesTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.{Audit, Batch, BatchJob, Batches, Callback, TestRepo}

  @output_unavailable_copy "A chain step needs upstream output that is missing, expired, or was not recorded. Review the failed callback and retry only after the upstream output contract is corrected."

  @tag :phase62_read_list
  test "list/3 filters by status, query, chain flag, queue, worker, and paginates" do
    matching_batch =
      insert_batch!(name: "billing-chain", status: "callback_failed", total_count: 3)

    other_batch = insert_batch!(name: "inventory", status: "executing", total_count: 1)

    retryable_job =
      insert_job!(%{"chain_id" => "chain-a", "batch_id" => matching_batch.id},
        worker: "MyApp.BillingWorker",
        queue: :billing,
        state: "discarded"
      )

    _other_job =
      insert_job!(%{"batch_id" => other_batch.id},
        worker: "MyApp.InventoryWorker",
        queue: :inventory,
        state: "available"
      )

    insert_batch_job!(matching_batch, retryable_job, state: "discarded")
    insert_callback!(matching_batch, status: "failed", payload: %{"chain_id" => "chain-a"})

    result =
      Batches.list(
        TestRepo,
        batch_filter(
          status: :callback_failed,
          query: "billing",
          chain_only: true,
          queue: "billing",
          worker: "MyApp.BillingWorker",
          page: 1,
          page_size: 1
        )
      )

    assert [%{id: id, status: "callback_failed"} = row] = result
    assert id == matching_batch.id
    assert row.chain? == true
    assert row.failed_count == 1
    assert row.retryable_failed_count == 1
    assert row.callback_summary.failed == 1
    assert row.blocked_state.name == :callback_failed

    assert [] =
             Batches.list(
               TestRepo,
               batch_filter(
                 status: :callback_failed,
                 query: "billing",
                 chain_only: true,
                 queue: "billing",
                 worker: "MyApp.BillingWorker",
                 page: 2,
                 page_size: 1
               )
             )
  end

  @tag :phase62_read_list
  test "count_by_status/2 returns all batch status keys and honors non-status filters" do
    billing = insert_batch!(name: "billing", status: "callback_failed")
    inventory = insert_batch!(name: "inventory", status: "completed", completed_at: now())

    billing_job =
      insert_job!(%{"batch_id" => billing.id}, worker: "MyApp.Billing", queue: :billing)

    inventory_job =
      insert_job!(%{"batch_id" => inventory.id}, worker: "MyApp.Inventory", queue: :inventory)

    insert_batch_job!(billing, billing_job)
    insert_batch_job!(inventory, inventory_job)

    counts = Batches.count_by_status(TestRepo, batch_filter(queue: "billing"))

    assert Map.keys(counts) |> Enum.sort() ==
             ~w(all callback_failed completed executing exhausted insert_failed inserting)

    assert counts["all"] == 1
    assert counts["callback_failed"] == 1
    assert counts["completed"] == 0
  end

  @tag :phase62_read_detail
  test "get/3 returns identity, failed members, callbacks, chain context, and audit evidence" do
    batch = insert_batch!(name: "billing-chain", status: "callback_failed", total_count: 2)

    failed_job =
      insert_job!(
        %{
          "batch_id" => batch.id,
          "chain_id" => "chain-a",
          "chain_step_name" => "charge",
          "chain_step_index" => 2,
          "chain_step_count" => 3,
          "upstream_job_id" => 101
        },
        worker: "MyApp.BillingWorker",
        queue: :billing,
        state: "discarded",
        errors: [%{"attempt" => 1, "error" => "boom"}]
      )

    insert_batch_job!(batch, failed_job, state: "discarded")

    callback =
      insert_callback!(batch,
        event: "chain.step_succeeded",
        status: "failed",
        attempts: 2,
        last_error: "output_unavailable",
        payload: %{
          "batch_id" => batch.id,
          "chain_id" => "chain-a",
          "chain_step_name" => "charge",
          "chain_step_index" => 2,
          "chain_step_count" => 3,
          "upstream_job_id" => failed_job.id
        }
      )

    {:ok, audit} =
      Audit.record(
        "lifeline.repair_executed",
        %{type: :callback, id: callback.id},
        %{"reason" => "retry after dependency fix"},
        repo: TestRepo,
        actor_id: "ops-1"
      )

    detail = Batches.get(TestRepo, batch.id)

    assert detail.id == batch.id
    assert detail.name == "billing-chain"
    assert detail.progress.total_count == 2
    assert [%{job_id: job_id, retry_eligible?: true} = member] = detail.failed_members
    assert job_id == failed_job.id
    assert member.worker == "MyApp.BillingWorker"
    assert member.oban_state == "discarded"

    assert [%{id: callback_id, retry_eligible?: true} = callback_row] = detail.callbacks
    assert callback_id == callback.id
    assert callback_row.event == "chain.step_succeeded"
    assert callback_row.last_error =~ "output_unavailable"
    assert detail.chain_context.chain_id == "chain-a"
    assert detail.chain_context.upstream_job_id == failed_job.id
    assert Enum.any?(detail.audit_events, &(&1.id == audit.id))
  end

  @tag :phase62_read_detail
  test "callback retry eligibility is limited to failed and expired claimed callbacks" do
    batch = insert_batch!(status: "callback_failed")
    expired = DateTime.add(now(), -60, :second)
    future = DateTime.add(now(), 60, :second)

    failed = insert_callback!(batch, status: "failed")
    expired_claimed = insert_callback!(batch, status: "claimed", lease_expires_at: expired)
    pending = insert_callback!(batch, status: "pending")
    delivered = insert_callback!(batch, status: "delivered", delivered_at: now())
    healthy_claimed = insert_callback!(batch, status: "claimed", lease_expires_at: future)

    detail = Batches.get(TestRepo, batch.id, now: now())

    eligible_ids =
      detail.callbacks
      |> Enum.filter(& &1.retry_eligible?)
      |> MapSet.new(& &1.id)

    assert failed.id in eligible_ids
    assert expired_claimed.id in eligible_ids
    refute pending.id in eligible_ids
    refute delivered.id in eligible_ids
    refute healthy_claimed.id in eligible_ids
  end

  @tag :phase62_blocked
  test "blocked_state/2 explains insert, callback, output, executing, exhausted, and completed states" do
    insert_failed =
      insert_batch!(
        status: "insert_failed",
        total_count: 10,
        inserted_count: 4,
        insert_failed_chunk: 2,
        insert_failure: %{"kind" => "insert", "message" => "bad row"},
        insert_failed_at: now()
      )

    callback_failed = insert_batch!(status: "callback_failed")
    insert_callback!(callback_failed, status: "failed", last_error: "output_unavailable")

    executing = insert_batch!(status: "executing", total_count: 3, success_count: 1)
    exhausted = insert_batch!(status: "exhausted", total_count: 3, discard_count: 1)

    completed =
      insert_batch!(status: "completed", total_count: 3, success_count: 3, completed_at: now())

    assert Batches.blocked_state(insert_failed).name == :insert_failed
    assert Batches.blocked_state(callback_failed).name == :callback_failed
    assert Batches.blocked_state(callback_failed).copy =~ "failed callback"
    assert Batches.blocked_state(%{status: "output_unavailable"}).copy == @output_unavailable_copy
    assert Batches.blocked_state(%{status: "output_expired"}).name == :output_expired
    assert Batches.blocked_state(executing).name == :executing
    assert Batches.blocked_state(exhausted).name == :exhausted
    assert Batches.blocked_state(completed).name == :completed
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
      payload: %{"batch_id" => batch.id},
      attempts: 1,
      available_at: now()
    }

    %Callback{}
    |> Callback.changeset(Map.merge(defaults, Map.new(attrs)))
    |> TestRepo.insert!()
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:microsecond)

  defp batch_filter(attrs) do
    struct(Batches, attrs)
  end
end
