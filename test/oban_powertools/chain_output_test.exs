defmodule ObanPowertools.ChainOutputTest do
  use ObanPowertools.DataCase, async: false

  import ObanPowertools.Chain

  alias ObanPowertools.Batch
  alias ObanPowertools.Batch.Tracker
  alias ObanPowertools.Callback
  alias ObanPowertools.Chain
  alias ObanPowertools.Chain.Progression
  alias ObanPowertools.JobRecord

  defmodule RecordingFetchWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [import_id: :integer],
      record_output: true

    @impl true
    def process(_job), do: {:ok, %{"path" => "imports/1.csv", "private" => "upstream"}}
  end

  defmodule NonRecordingFetchWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [import_id: :integer]

    @impl true
    def process(_job), do: {:ok, %{"path" => "imports/1.csv"}}
  end

  defmodule ParseWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [import_id: :integer, path: :string]

    @impl true
    def process(_job), do: {:ok, %{"rows_ref" => "rows:1"}}
  end

  defmodule UnsafeArgsBuilder do
    def parse(_upstream_payload, _extra_args), do: %{"import_id" => 1}
  end

  defmodule ImportChainArgs do
    use ObanPowertools.Chain.ArgsBuilder

    def parse(upstream_payload, [import_id]) do
      {:ok, %{"import_id" => import_id, "path" => upstream_payload["path"]}}
    end
  end

  describe "fetch_upstream_result/2" do
    test "returns durable upstream payload for a job meta upstream reference" do
      upstream = insert_job!()

      assert :ok =
               JobRecord.record(
                 TestRepo,
                 RecordingFetchWorker,
                 upstream,
                 %{"path" => "x.csv"},
                 []
               )

      downstream = %Oban.Job{meta: %{"upstream_job_id" => upstream.id}}

      assert {:ok, %{"path" => "x.csv"}} = Chain.fetch_upstream_result(TestRepo, downstream)
    end

    test "returns explicit missing upstream id and unavailable output errors" do
      assert {:error, :missing_upstream_job_id} =
               Chain.fetch_upstream_result(TestRepo, %Oban.Job{meta: %{}})

      assert {:error, :output_unavailable} = Chain.fetch_upstream_result(TestRepo, -1)
    end

    test "returns output_expired for expired recorded output" do
      upstream = insert_job!()

      assert :ok =
               JobRecord.record(
                 TestRepo,
                 RecordingFetchWorker,
                 upstream,
                 %{"path" => "old.csv"},
                 []
               )

      record = TestRepo.get_by!(JobRecord, oban_job_id: upstream.id)

      record
      |> Ecto.Changeset.change(expires_at: DateTime.add(DateTime.utc_now(), -60, :second))
      |> TestRepo.update!()

      assert {:error, :output_expired} = Chain.fetch_upstream_result(TestRepo, upstream.id)
    end
  end

  describe "output-dependent chain validation" do
    test "requires the immediately preceding worker to record output" do
      assert {:error, {:validation, {:record_output_required, NonRecordingFetchWorker}}} =
               NonRecordingFetchWorker.new(%{import_id: 1})
               |> chain(:parse, ParseWorker, args: {ImportChainArgs, :parse, [1]})
               |> Chain.insert(TestRepo, name: "import:1")
    end

    test "rejects unsafe persisted args builder references" do
      assert {:error, {:validation, {:unsafe_args_builder, UnsafeArgsBuilder}}} =
               RecordingFetchWorker.new(%{import_id: 1})
               |> chain(:parse, ParseWorker, args: {UnsafeArgsBuilder, :parse, [1]})
               |> Chain.insert(TestRepo, name: "import:1")
    end
  end

  describe "output-dependent progression" do
    test "fetches upstream output, calls safe builder, and inserts only builder-returned args" do
      chain =
        RecordingFetchWorker.new(%{import_id: 1})
        |> chain(:parse, ParseWorker, args: {ImportChainArgs, :parse, [1]})

      assert {:ok, %Chain.InsertResult{batch_id: batch_id, first_job_id: fetch_id}} =
               Chain.insert(chain, TestRepo, name: "import:1")

      fetch = TestRepo.get!(Oban.Job, fetch_id)

      assert :ok =
               JobRecord.record(
                 TestRepo,
                 RecordingFetchWorker,
                 %{fetch | attempt: 1},
                 %{
                   "path" => "imports/1.csv",
                   "private" => "do-not-copy"
                 },
                 []
               )

      assert {:ok, :tracked} = Tracker.record_progress(TestRepo, fetch, :success)
      assert %{delivered: 1, failed: 0} = Progression.dispatch_callbacks(TestRepo)

      parse = newest_job!()
      assert parse.worker == inspect(ParseWorker)
      assert parse.meta["batch_id"] == batch_id
      assert parse.meta["upstream_job_id"] == fetch.id
      assert parse.args == %{"import_id" => 1, "path" => "imports/1.csv"}
      refute Map.has_key?(parse.args, "private")
      refute Map.has_key?(parse.args, "upstream_payload")
    end

    test "marks callback failed with output_unavailable when upstream output is absent" do
      batch = insert_batch!(total_count: 2)

      callback =
        insert_chain_callback!(batch,
          upstream_job_id: 404_404,
          next_step: %{
            "step" => %{
              "name" => "parse",
              "index" => 1,
              "worker" => inspect(ParseWorker),
              "args" => %{},
              "queue" => "default",
              "meta" => %{},
              "requires_output" => true,
              "args_builder" => %{
                "module" => inspect(ImportChainArgs),
                "function" => "parse",
                "extra_args" => [1]
              }
            },
            "remaining" => []
          }
        )

      assert %{delivered: 0, failed: 1} = Progression.dispatch_callbacks(TestRepo)

      failed = TestRepo.get!(Callback, callback.id)
      assert failed.status == "failed"
      assert failed.last_error =~ "output_unavailable"
      assert [] = TestRepo.all(Oban.Job)
    end
  end

  defp insert_job! do
    %{}
    |> Oban.Job.new(worker: inspect(RecordingFetchWorker), queue: :default)
    |> Ecto.Changeset.change(attempt: 1)
    |> TestRepo.insert!()
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

  defp insert_chain_callback!(batch, opts) do
    upstream_job_id = Keyword.fetch!(opts, :upstream_job_id)
    next_step = Keyword.fetch!(opts, :next_step)

    %Callback{}
    |> Callback.changeset(%{
      batch_id: batch.id,
      event: "chain.step_succeeded",
      dedupe_key: "chain.step_succeeded:#{batch.id}:0:#{upstream_job_id}",
      status: "pending",
      payload: %{
        "event" => "chain.step_succeeded",
        "chain_id" => batch.id,
        "batch_id" => batch.id,
        "step_name" => "fetch",
        "step_index" => 0,
        "step_count" => batch.total_count,
        "upstream_job_id" => upstream_job_id,
        "next_step" => next_step
      },
      attempts: 0
    })
    |> TestRepo.insert!()
  end

  defp newest_job! do
    TestRepo.one!(from(job in Oban.Job, order_by: [desc: job.id], limit: 1))
  end
end
