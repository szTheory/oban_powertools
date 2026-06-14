defmodule ObanPowertools.ChainProgressionTest do
  use ObanPowertools.DataCase, async: false

  import Ecto.Query
  import ObanPowertools.Chain

  alias ObanPowertools.Batch
  alias ObanPowertools.Batch.Tracker
  alias ObanPowertools.BatchJob
  alias ObanPowertools.Callback
  alias ObanPowertools.Chain
  alias ObanPowertools.Chain.Progression
  alias ObanPowertools.JobRecord

  defmodule FetchWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [import_id: :integer],
      record_output: true

    @impl true
    def process(_job), do: {:ok, %{"path" => "imports/1.csv"}}
  end

  defmodule ParseWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [import_id: :integer]

    @impl true
    def process(_job), do: {:ok, %{"rows_ref" => "rows:1"}}
  end

  defmodule WriteWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [import_id: :integer]

    @impl true
    def process(_job), do: :ok
  end

  defmodule NotifyWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [import_id: :integer]

    @impl true
    def process(_job), do: :ok
  end

  defmodule ImportChainArgs do
    use ObanPowertools.Chain.ArgsBuilder

    def parse(_job, import_id), do: %{"import_id" => import_id}
  end

  describe "callback event vocabulary" do
    test "accepts chain step succeeded callbacks" do
      changeset =
        Callback.changeset(%Callback{}, %{
          event: "chain.step_succeeded",
          dedupe_key: "chain.step_succeeded:chain-1:0:123",
          status: "pending",
          payload: %{"event" => "chain.step_succeeded"},
          attempts: 0
        })

      assert changeset.valid?
    end
  end

  describe "tracker bridge" do
    test "emits one chain callback for first-time successful progress with a next step" do
      batch = insert_batch!(total_count: 2)
      next_step = next_step_descriptor(:parse, ParseWorker)

      job =
        chain_job(batch,
          id: 101,
          step_name: "fetch",
          step_index: 0,
          step_count: 2,
          next_step: next_step
        )

      assert {:ok, :tracked} = Tracker.record_progress(TestRepo, job, :success)
      assert {:ok, :duplicate} = Tracker.record_progress(TestRepo, job, :success)

      assert [callback] =
               TestRepo.all(
                 from(callback in Callback, where: callback.event == "chain.step_succeeded")
               )

      assert callback.status == "pending"
      assert callback.attempts == 0
      assert callback.batch_id == batch.id
      assert callback.dedupe_key == "chain.step_succeeded:#{batch.id}:0:101"
      assert callback.payload["event"] == "chain.step_succeeded"
      assert callback.payload["chain_id"] == batch.id
      assert callback.payload["batch_id"] == batch.id
      assert callback.payload["step_name"] == "fetch"
      assert callback.payload["step_index"] == 0
      assert callback.payload["step_count"] == 2
      assert callback.payload["upstream_job_id"] == 101
      assert callback.payload["next_step"] == next_step
    end

    test "does not emit chain callbacks for discarded progress" do
      batch = insert_batch!(total_count: 2)

      job =
        chain_job(batch,
          id: 102,
          step_name: "fetch",
          step_index: 0,
          step_count: 2,
          next_step: next_step_descriptor(:parse, ParseWorker)
        )

      assert {:ok, :tracked} = Tracker.record_progress(TestRepo, job, :discard)

      assert [] =
               TestRepo.all(
                 from(callback in Callback, where: callback.event == "chain.step_succeeded")
               )
    end

    test "rolls back the batch-job dedupe row when batch progress cannot be applied" do
      missing_batch = %Batch{id: Ecto.UUID.generate()}

      job =
        chain_job(missing_batch,
          id: 103,
          step_name: "fetch",
          step_index: 0,
          step_count: 2,
          next_step: next_step_descriptor(:parse, ParseWorker)
        )

      assert {:error, :batch_not_found} = Tracker.record_progress(TestRepo, job, :success)
      assert TestRepo.aggregate(BatchJob, :count) == 0

      assert [] =
               TestRepo.all(
                 from(callback in Callback, where: callback.event == "chain.step_succeeded")
               )
    end
  end

  describe "dispatch_callbacks/2" do
    test "claims chain callbacks, inserts the next job, preserves remaining tail, and marks delivered" do
      batch = insert_batch!(total_count: 3)

      callback =
        insert_chain_callback!(batch,
          upstream_job_id: 201,
          next_step:
            next_step_descriptor(:parse, ParseWorker,
              remaining: [
                step_descriptor(:write, WriteWorker)
              ]
            )
        )

      assert %{delivered: 1, failed: 0} =
               Progression.dispatch_callbacks(TestRepo, dispatcher_id: "node-a")

      delivered = TestRepo.get!(Callback, callback.id)
      assert delivered.status == "delivered"
      assert delivered.attempts == 1
      assert delivered.claimed_by == "node-a"
      assert is_nil(delivered.lease_expires_at)
      assert is_nil(delivered.last_error)

      [job] = TestRepo.all(from(job in Oban.Job, order_by: job.id))
      assert job.worker == inspect(ParseWorker)
      assert job.args == %{"import_id" => 1}
      assert job.queue == "default"
      assert job.meta["batch_id"] == batch.id
      assert job.meta["chain_id"] == batch.id
      assert job.meta["chain_step_name"] == "parse"
      assert job.meta["chain_step_index"] == 1
      assert job.meta["chain_step_count"] == 3
      assert job.meta["upstream_job_id"] == 201
      assert %{"step" => write_descriptor, "remaining" => []} = job.meta["chain_next_step"]
      assert write_descriptor["name"] == "write"
    end

    test "failed next-step insertion leaves the callback retryable with last_error" do
      batch = insert_batch!(total_count: 2)

      callback =
        insert_chain_callback!(batch,
          upstream_job_id: 202,
          next_step: %{"step" => %{"worker" => nil}, "remaining" => []}
        )

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      assert %{delivered: 0, failed: 1} =
               Progression.dispatch_callbacks(TestRepo,
                 dispatcher_id: "node-a",
                 now: now
               )

      failed = TestRepo.get!(Callback, callback.id)
      assert failed.status == "failed"
      assert failed.attempts == 1
      assert DateTime.diff(failed.available_at, now, :second) == 30
      assert is_nil(failed.lease_expires_at)
      assert is_binary(failed.last_error)
    end

    test "claimed callback with nil next_step is delivered without inserting a job" do
      batch = insert_batch!(total_count: 1)

      callback =
        insert_chain_callback!(batch, upstream_job_id: 203, next_step: nil, status: "claimed")

      assert %{delivered: 1, failed: 0} =
               Progression.dispatch_callbacks(TestRepo, dispatcher_id: "node-a")

      assert TestRepo.get!(Callback, callback.id).status == "delivered"
      assert [] = TestRepo.all(Oban.Job)
    end

    test "does not duplicate a downstream job when retrying after the job already exists" do
      batch = insert_batch!(total_count: 2)
      next_step = next_step_descriptor(:parse, ParseWorker)
      upstream_job_id = 204

      callback =
        insert_chain_callback!(batch,
          upstream_job_id: upstream_job_id,
          next_step: next_step,
          status: "failed"
        )

      progression_key = "chain.step_succeeded:#{batch.id}:1:#{upstream_job_id}"

      %{"import_id" => 1}
      |> Oban.Job.new(
        worker: inspect(ParseWorker),
        queue: :default,
        meta: %{"chain_progression_key" => progression_key}
      )
      |> TestRepo.insert!()

      assert %{delivered: 1, failed: 0} =
               Progression.dispatch_callbacks(TestRepo, dispatcher_id: "node-a")

      assert TestRepo.get!(Callback, callback.id).status == "delivered"
      assert TestRepo.aggregate(Oban.Job, :count) == 1
    end

    test "preserves downstream Oban options from chain descriptors" do
      scheduled_at =
        DateTime.utc_now()
        |> DateTime.add(3_600, :second)
        |> DateTime.truncate(:second)

      chain =
        FetchWorker.new(%{import_id: 1})
        |> chain(
          :parse,
          ParseWorker.new(%{import_id: 1},
            max_attempts: 3,
            priority: 4,
            scheduled_at: scheduled_at,
            tags: ["Import", "Urgent"]
          )
        )

      assert {:ok, %Chain.InsertResult{first_job_id: fetch_id}} =
               Chain.insert(chain, TestRepo, name: "import:options")

      fetch = TestRepo.get!(Oban.Job, fetch_id)
      assert %{"step" => %{"opts" => opts}} = fetch.meta["chain_next_step"]
      assert opts["max_attempts"] == 3
      assert opts["priority"] == 4
      assert opts["tags"] == ["import", "urgent"]
      assert is_binary(opts["scheduled_at"])

      assert {:ok, :tracked} = Tracker.record_progress(TestRepo, fetch, :success)
      assert %{delivered: 1, failed: 0} = Progression.dispatch_callbacks(TestRepo)

      parse = newest_job!()
      assert parse.worker == inspect(ParseWorker)
      assert parse.max_attempts == 3
      assert parse.priority == 4
      assert parse.tags == ["import", "urgent"]
      assert parse.state == "scheduled"
      assert DateTime.diff(parse.scheduled_at, scheduled_at, :second) == 0
    end

    test "progresses the D-20 fetch parse write notify chain across repeated cycles" do
      chain =
        FetchWorker.new(%{import_id: 1})
        |> chain(:parse, ParseWorker, args: {ImportChainArgs, :parse, [1]})
        |> chain(:write, WriteWorker.new(%{import_id: 1}))
        |> chain(:notify, NotifyWorker.new(%{import_id: 1}))

      assert {:ok, %Chain.InsertResult{batch_id: batch_id, first_job_id: fetch_id}} =
               Chain.insert(chain, TestRepo, name: "import:1")

      fetch = TestRepo.get!(Oban.Job, fetch_id)

      assert :ok =
               JobRecord.record(
                 TestRepo,
                 FetchWorker,
                 %{fetch | attempt: 1},
                 %{
                   "path" => "imports/1.csv"
                 },
                 []
               )

      assert {:ok, :tracked} = Tracker.record_progress(TestRepo, fetch, :success)
      assert %{delivered: 1, failed: 0} = Progression.dispatch_callbacks(TestRepo)

      parse = newest_job!()
      assert parse.worker == inspect(ParseWorker)
      assert parse.meta["upstream_job_id"] == fetch.id

      assert %{"step" => write_descriptor, "remaining" => [notify_descriptor]} =
               parse.meta["chain_next_step"]

      assert write_descriptor["name"] == "write"
      assert notify_descriptor["name"] == "notify"

      assert {:ok, :tracked} = Tracker.record_progress(TestRepo, parse, :success)
      assert %{delivered: 1, failed: 0} = Progression.dispatch_callbacks(TestRepo)

      write = newest_job!()
      assert write.worker == inspect(WriteWorker)
      assert write.meta["upstream_job_id"] == parse.id
      assert %{"step" => notify_tail, "remaining" => []} = write.meta["chain_next_step"]
      assert notify_tail["name"] == "notify"

      assert {:ok, :tracked} = Tracker.record_progress(TestRepo, write, :success)
      assert %{delivered: 1, failed: 0} = Progression.dispatch_callbacks(TestRepo)

      notify = newest_job!()
      assert notify.worker == inspect(NotifyWorker)
      assert notify.meta["upstream_job_id"] == write.id
      refute Map.has_key?(notify.meta, "chain_next_step")

      assert {:ok, :completed} = Tracker.record_progress(TestRepo, notify, :success)

      batch = TestRepo.get!(Batch, batch_id)
      assert batch.status == "completed"
      assert batch.success_count == 4
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

  defp chain_job(batch, opts) do
    %Oban.Job{
      id: Keyword.fetch!(opts, :id),
      meta:
        %{
          "batch_id" => batch.id,
          "chain_id" => batch.id,
          "chain_step_name" => Keyword.fetch!(opts, :step_name),
          "chain_step_index" => Keyword.fetch!(opts, :step_index),
          "chain_step_count" => Keyword.fetch!(opts, :step_count)
        }
        |> maybe_put("chain_next_step", Keyword.get(opts, :next_step))
    }
  end

  defp insert_chain_callback!(batch, opts) do
    upstream_job_id = Keyword.fetch!(opts, :upstream_job_id)
    status = Keyword.get(opts, :status, "pending")
    step_index = Keyword.get(opts, :step_index, 0)
    next_step = Keyword.get(opts, :next_step)

    %Callback{}
    |> Callback.changeset(%{
      batch_id: batch.id,
      event: "chain.step_succeeded",
      dedupe_key: "chain.step_succeeded:#{batch.id}:#{step_index}:#{upstream_job_id}",
      status: status,
      payload: %{
        "event" => "chain.step_succeeded",
        "chain_id" => batch.id,
        "batch_id" => batch.id,
        "step_name" => Keyword.get(opts, :step_name, "fetch"),
        "step_index" => step_index,
        "step_count" => Keyword.get(opts, :step_count, batch.total_count),
        "upstream_job_id" => upstream_job_id,
        "next_step" => next_step
      },
      attempts: 0
    })
    |> TestRepo.insert!()
  end

  defp next_step_descriptor(name, worker, opts \\ []) do
    %{
      "step" => step_descriptor(name, worker),
      "remaining" => Keyword.get(opts, :remaining, [])
    }
  end

  defp step_descriptor(name, worker) do
    %{
      "name" => Atom.to_string(name),
      "index" => step_index(name),
      "worker" => inspect(worker),
      "args" => %{"import_id" => 1},
      "queue" => "default",
      "meta" => %{},
      "requires_output" => false
    }
  end

  defp step_index(:parse), do: 1
  defp step_index(:write), do: 2
  defp step_index(:notify), do: 3

  defp newest_job! do
    TestRepo.one!(from(job in Oban.Job, order_by: [desc: job.id], limit: 1))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
