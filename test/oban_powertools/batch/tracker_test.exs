defmodule ObanPowertools.Batch.TrackerTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Batch
  alias ObanPowertools.Batch.Tracker
  alias ObanPowertools.BatchJob
  alias ObanPowertools.Callback

  describe "record_progress/3" do
    test "ignores jobs without batch metadata" do
      job = %Oban.Job{id: 1, meta: %{}}

      assert {:ok, :ignored} = Tracker.record_progress(TestRepo, job, :success)
      assert [] = TestRepo.all(BatchJob)
    end

    test "idempotently records each batch job once" do
      batch = insert_batch!(total_count: 2)
      job = batch_job(batch, id: 11)

      assert {:ok, :tracked} = Tracker.record_progress(TestRepo, job, :success)
      assert {:ok, :duplicate} = Tracker.record_progress(TestRepo, job, :success)

      assert [%BatchJob{batch_id: batch_id, job_id: 11, state: "success"}] =
               TestRepo.all(BatchJob)

      assert batch_id == batch.id

      batch = TestRepo.get!(Batch, batch.id)
      assert batch.success_count == 1
      assert batch.discard_count == 0
    end

    test "increments discard counts on first discard record" do
      batch = insert_batch!(total_count: 2)
      job = batch_job(batch, id: 12)

      assert {:ok, :tracked} = Tracker.record_progress(TestRepo, job, :discard)

      batch = TestRepo.get!(Batch, batch.id)
      assert batch.success_count == 0
      assert batch.discard_count == 1
    end

    test "sets completed_at and enqueues completed callback when all jobs succeed" do
      batch = insert_batch!(total_count: 1)
      job = batch_job(batch, id: 13)

      assert {:ok, :completed} = Tracker.record_progress(TestRepo, job, :success)

      batch = TestRepo.get!(Batch, batch.id)
      assert batch.status == "completed"
      assert batch.success_count == 1
      assert batch.discard_count == 0
      assert %DateTime{} = batch.completed_at

      callback = TestRepo.get_by!(Callback, batch_id: batch.id)
      assert callback.event == "batch.completed"
      assert callback.status == "pending"
      assert callback.dedupe_key == "batch.completed-#{batch.id}"
    end

    test "sets completed_at and enqueues exhausted callback when any job discarded" do
      batch = insert_batch!(total_count: 2, success_count: 1)
      job = batch_job(batch, id: 14)

      assert {:ok, :completed} = Tracker.record_progress(TestRepo, job, :discard)

      batch = TestRepo.get!(Batch, batch.id)
      assert batch.status == "exhausted"
      assert batch.success_count == 1
      assert batch.discard_count == 1
      assert %DateTime{} = batch.completed_at

      callback = TestRepo.get_by!(Callback, batch_id: batch.id)
      assert callback.event == "batch.exhausted"
      assert callback.status == "pending"
      assert callback.dedupe_key == "batch.exhausted-#{batch.id}"
    end
  end

  describe "record_callback_exhaustion/2" do
    test "uses callback_id as the authoritative batch identity" do
      target_batch = insert_batch!(status: "exhausted", total_count: 1, discard_count: 1)
      other_batch = insert_batch!(status: "exhausted", total_count: 1, discard_count: 1)
      callback = insert_callback!(target_batch)

      job = %Oban.Job{
        id: 21,
        meta: %{"callback_id" => callback.id, "batch_id" => other_batch.id}
      }

      assert {:ok, :callback_failed} = Tracker.record_callback_exhaustion(TestRepo, job)

      assert TestRepo.get!(Batch, target_batch.id).status == "callback_failed"
      assert TestRepo.get!(Batch, other_batch.id).status == "exhausted"
    end
  end

  defp insert_batch!(attrs) do
    defaults = %{
      status: "executing",
      total_count: 1,
      success_count: 0,
      discard_count: 0,
      cancelled_count: 0,
      snooze_count: 0
    }

    %Batch{}
    |> Batch.changeset(Map.merge(defaults, Map.new(attrs)))
    |> TestRepo.insert!()
  end

  defp insert_callback!(batch) do
    %Callback{}
    |> Callback.changeset(%{
      batch_id: batch.id,
      event: "batch.exhausted",
      dedupe_key: "batch.exhausted-#{batch.id}",
      status: "pending",
      payload: %{"batch_id" => batch.id},
      attempts: 0
    })
    |> TestRepo.insert!()
  end

  defp batch_job(batch, opts) do
    %Oban.Job{
      id: Keyword.fetch!(opts, :id),
      meta: %{"batch_id" => batch.id}
    }
  end
end
