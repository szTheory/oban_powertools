defmodule ObanPowertools.ChainTest do
  use ObanPowertools.DataCase, async: false

  import ObanPowertools.Chain

  alias ObanPowertools.Batch
  alias ObanPowertools.Chain

  defmodule FetchWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [import_id: :integer]

    @impl ObanPowertools.Worker
    def process(_job), do: {:ok, %{"path" => "imports/1.csv"}}
  end

  defmodule ParseWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [import_id: :integer]

    @impl ObanPowertools.Worker
    def process(_job), do: {:ok, %{"rows_ref" => "rows:1"}}
  end

  defmodule WriteWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [import_id: :integer]

    @impl ObanPowertools.Worker
    def process(_job), do: :ok
  end

  defmodule NotifyWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [import_id: :integer]

    @impl ObanPowertools.Worker
    def process(_job), do: :ok
  end

  defmodule ImportChainArgs do
    def parse(_job, import_id), do: %{"import_id" => import_id}
  end

  describe "chain/3 and chain/4" do
    test "builds a four-step linear chain from a pipeable job changeset" do
      assert %Chain{steps: steps} =
               FetchWorker.new(%{import_id: 1})
               |> chain(:parse, ParseWorker, args: {ImportChainArgs, :parse, [1]})
               |> chain(:write, WriteWorker.new(%{import_id: 1}))
               |> chain(:notify, NotifyWorker.new(%{import_id: 1}))

      assert Enum.map(steps, & &1.name) == ["fetch", "parse", "write", "notify"]
      assert Enum.map(steps, & &1.index) == [0, 1, 2, 3]

      assert %{args_builder: {ImportChainArgs, :parse, [1]}, requires_output?: true} =
               Enum.find(steps, &(&1.name == "parse"))
    end

    test "rejects anonymous args builders" do
      assert {:error, {:validation, :anonymous_builder_not_allowed}} =
               FetchWorker.new(%{import_id: 1})
               |> chain(:parse, ParseWorker, args: fn _job -> %{"import_id" => 1} end)
    end
  end

  describe "from_list/2" do
    test "accepts a nonempty list of named job changesets" do
      assert %Chain{steps: steps} =
               Chain.from_list(
                 [
                   {:fetch, FetchWorker.new(%{import_id: 1})},
                   {:parse, ParseWorker.new(%{import_id: 1})},
                   {:write, WriteWorker.new(%{import_id: 1})},
                   {:notify, NotifyWorker.new(%{import_id: 1})}
                 ],
                 name: "import:1"
               )

      assert Enum.map(steps, & &1.name) == ["fetch", "parse", "write", "notify"]
    end

    test "rejects duplicate step names" do
      assert {:error, {:validation, {:duplicate_step_name, "parse"}}} =
               Chain.from_list([
                 {:parse, ParseWorker.new(%{import_id: 1})},
                 {"parse", WriteWorker.new(%{import_id: 1})}
               ])
    end

    test "rejects branch-like inputs as non_linear_chain" do
      assert {:error, {:validation, :non_linear_chain}} =
               Chain.from_list([
                 {:fetch,
                  [
                    ParseWorker.new(%{import_id: 1}),
                    WriteWorker.new(%{import_id: 1})
                  ]}
               ])
    end
  end

  describe "insert/3" do
    test "creates one batch row and inserts only the first Oban job with chain metadata" do
      chain =
        FetchWorker.new(%{import_id: 1})
        |> chain(:parse, ParseWorker, args: {ImportChainArgs, :parse, [1]})
        |> chain(:write, WriteWorker.new(%{import_id: 1}))
        |> chain(:notify, NotifyWorker.new(%{import_id: 1}))

      assert {:ok,
              %Chain.InsertResult{
                chain_id: chain_id,
                batch_id: batch_id,
                first_job_id: first_job_id,
                step_count: 4
              }} = Chain.insert(chain, TestRepo, name: "import:1")

      assert chain_id == batch_id

      batch = TestRepo.get!(Batch, batch_id)
      assert batch.total_count == 4
      assert batch.status == "executing"
      assert batch.name == "import:1"

      assert [first_job] = TestRepo.all(from(job in Oban.Job, order_by: job.id))
      assert first_job.id == first_job_id

      assert %{
               "batch_id" => ^batch_id,
               "chain_id" => ^chain_id,
               "chain_name" => "import:1",
               "chain_step_name" => "fetch",
               "chain_step_index" => 0,
               "chain_step_count" => 4
             } = first_job.meta

      assert %{"step" => parse_descriptor, "remaining" => [write_descriptor, notify_descriptor]} =
               first_job.meta["chain_next_step"]

      assert parse_descriptor["name"] == "parse"
      assert parse_descriptor["worker"] == inspect(ParseWorker)
      assert parse_descriptor["args"] == %{}

      assert parse_descriptor["args_builder"] == %{
               "module" => inspect(ImportChainArgs),
               "function" => "parse",
               "extra_args" => [1]
             }

      assert write_descriptor["name"] == "write"
      assert notify_descriptor["name"] == "notify"
      refute Map.has_key?(parse_descriptor, "upstream_payload")
      refute File.exists?("lib/oban_powertools/chain/schema.ex")
    end
  end
end
