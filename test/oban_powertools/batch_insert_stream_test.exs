defmodule ObanPowertools.BatchInsertStreamTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Batch

  defmodule ImportRowWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [import_id: :integer, row: :integer]

    @impl ObanPowertools.Worker
    def process(_job), do: :ok
  end

  describe "insert_stream/2" do
    test "inserts valid changesets in bounded chunks and returns compact counters" do
      jobs = import_jobs(1..5)

      assert {:ok,
              %Batch.InsertResult{
                batch_id: batch_id,
                total_count: 5,
                inserted_count: 5,
                chunk_count: 3
              }} =
               Batch.insert_stream(jobs,
                 repo: TestRepo,
                 total_count: 5,
                 chunk_size: 2,
                 name: "import:1"
               )

      assert TestRepo.get!(Batch, batch_id).status == "executing"
    end

    test "injects batch metadata into inserted jobs" do
      assert {:ok, %Batch.InsertResult{batch_id: batch_id}} =
               1..2
               |> import_jobs()
               |> Batch.insert_stream(
                 repo: TestRepo,
                 total_count: 2,
                 chunk_size: 2,
                 name: "import:meta"
               )

      inserted_jobs = TestRepo.all(from(job in Oban.Job, order_by: job.id))

      assert Enum.map(inserted_jobs, & &1.meta) == [
               %{"batch_id" => batch_id, "batch_name" => "import:meta"},
               %{"batch_id" => batch_id, "batch_name" => "import:meta"}
             ]

      batch = TestRepo.get!(Batch, batch_id)
      assert batch.status == "executing"
      assert batch.inserted_count == 2
      assert batch.insert_chunk_count == 1
    end

    test "rejects invalid options before inserting jobs or batch rows" do
      invalid_calls = [
        {import_jobs(1..1), [total_count: 1, chunk_size: 1], :repo},
        {import_jobs(1..1), [repo: nil, total_count: 1, chunk_size: 1], :repo},
        {import_jobs(1..1), [repo: TestRepo, chunk_size: 1], :total_count},
        {import_jobs(1..1), [repo: TestRepo, total_count: "1", chunk_size: 1], :total_count},
        {import_jobs(1..1), [repo: TestRepo, total_count: 1, chunk_size: 0], :chunk_size},
        {import_jobs(1..1), [repo: TestRepo, total_count: 1, on_conflict: :skip], :on_conflict}
      ]

      for {stream, opts, option} <- invalid_calls do
        assert {:error,
                %Batch.InsertError{
                  batch_id: nil,
                  inserted_count: 0,
                  failed_chunk: 0,
                  reason: {:invalid_option, ^option}
                }} = Batch.insert_stream(stream, opts)
      end

      assert TestRepo.aggregate(Batch, :count) == 0
      assert TestRepo.aggregate(Oban.Job, :count) == 0
    end

    test "does not append to an existing caller-supplied batch_id" do
      batch_id = Ecto.UUID.generate()

      assert {:ok, %Batch.InsertResult{batch_id: ^batch_id, inserted_count: 1}} =
               1..1
               |> import_jobs()
               |> Batch.insert_stream(
                 repo: TestRepo,
                 total_count: 1,
                 chunk_size: 1,
                 batch_id: batch_id
               )

      assert {:error,
              %Batch.InsertError{
                batch_id: ^batch_id,
                total_count: 1,
                inserted_count: 0,
                failed_chunk: 0,
                reason: :batch_id_exists
              }} =
               2..2
               |> import_jobs()
               |> Batch.insert_stream(
                 repo: TestRepo,
                 total_count: 1,
                 chunk_size: 1,
                 batch_id: batch_id
               )

      assert TestRepo.aggregate(Batch, :count) == 1
      assert TestRepo.aggregate(Oban.Job, :count) == 1
    end

    test "marks the batch insert_failed when a later chunk fails" do
      invalid_changeset = Oban.Job.new(%{}, worker: nil)

      stream =
        [ImportRowWorker.new(%{import_id: 1, row: 1}), invalid_changeset]

      assert {:error,
              %Batch.InsertError{
                batch_id: batch_id,
                total_count: 2,
                inserted_count: 1,
                failed_chunk: 2
              }} =
               Batch.insert_stream(stream,
                 repo: TestRepo,
                 total_count: 2,
                 chunk_size: 1,
                 name: "import:partial"
               )

      batch = TestRepo.get!(Batch, batch_id)
      assert batch.status == "insert_failed"
      assert batch.inserted_count == 1
      assert batch.insert_chunk_count == 1
      assert batch.insert_failed_chunk == 2
      assert %{"kind" => kind, "message" => message, "reason" => reason} = batch.insert_failure
      assert kind != ""
      assert message != ""
      assert reason != ""
      assert %DateTime{} = batch.insert_failed_at
    end

    test "marks the batch insert_failed when stream count mismatches total_count" do
      assert {:error,
              %Batch.InsertError{
                batch_id: fewer_batch_id,
                total_count: 3,
                inserted_count: 2,
                reason: {:count_mismatch, %{expected: 3, actual: 2}}
              }} =
               1..2
               |> import_jobs()
               |> Batch.insert_stream(repo: TestRepo, total_count: 3, chunk_size: 2)

      assert TestRepo.get!(Batch, fewer_batch_id).status == "insert_failed"

      assert {:error,
              %Batch.InsertError{
                batch_id: more_batch_id,
                total_count: 1,
                inserted_count: 2,
                reason: {:count_mismatch, %{expected: 1, actual: 2}}
              }} =
               1..2
               |> import_jobs()
               |> Batch.insert_stream(repo: TestRepo, total_count: 1, chunk_size: 2)

      more_batch = TestRepo.get!(Batch, more_batch_id)
      assert more_batch.status == "insert_failed"
      assert more_batch.insert_failed_chunk == 1
      assert %{"reason" => "count_mismatch"} = more_batch.insert_failure
    end
  end

  defp import_jobs(rows) do
    Enum.map(rows, &ImportRowWorker.new(%{import_id: 1, row: &1}))
  end
end
