defmodule ObanPowertools.JobRecordTest do
  use ObanPowertools.DataCase, async: false

  import ExUnit.CaptureLog

  alias ObanPowertools.JobRecord
  alias ObanPowertools.TestRepo

  test "record/5 normalizes and inserts JSON-compatible payloads" do
    job = insert_job!(attempt: 2)

    assert :ok =
             JobRecord.record(
               TestRepo,
               "MyApp.Worker",
               job,
               %{
                 result: [%{"state" => :ok, id: 1}],
                 count: 2,
                 nil_value: nil
               }, output_limit: 65_536, output_retention: :standard)

    record = TestRepo.get_by!(JobRecord, oban_job_id: job.id, attempt: 2)

    assert record.worker == "MyApp.Worker"
    assert record.status == "ok"
    assert record.retention == "standard"
    assert record.redacted == false

    assert record.payload == %{
             "result" => [%{"id" => 1, "state" => "ok"}],
             "count" => 2,
             "nil_value" => nil
           }

    assert record.payload_bytes == byte_size(Jason.encode!(record.payload))
    assert %DateTime{} = record.recorded_at
    assert %DateTime{} = record.expires_at
  end

  test "record/5 rejects oversized payloads without inserting" do
    job = insert_job!()

    log =
      capture_log(fn ->
        assert :ok =
                 JobRecord.record(
                   TestRepo,
                   "MyApp.Worker",
                   job,
                   %{"data" => String.duplicate("x", 32)},
                   output_limit: 16,
                   output_retention: :standard
                 )
      end)

    assert log =~ "output payload"
    assert log =~ "exceeds"
    assert TestRepo.get_by(JobRecord, oban_job_id: job.id) == nil
  end

  test "record/5 rejects non-encodable payloads without raising" do
    job = insert_job!()

    log =
      capture_log(fn ->
        assert :ok =
                 JobRecord.record(TestRepo, "MyApp.Worker", job, %{pid: self()},
                   output_limit: 65_536,
                   output_retention: :standard
                 )
      end)

    assert log =~ "could not encode"
    assert TestRepo.get_by(JobRecord, oban_job_id: job.id) == nil
  end

  test "record/5 computes expiry from retention policy" do
    job = insert_job!()

    assert :ok =
             JobRecord.record(
               TestRepo,
               "MyApp.Worker",
               %{job | attempt: 1},
               %{"policy" => "ephemeral"}, output_retention: :ephemeral)

    assert :ok =
             JobRecord.record(
               TestRepo,
               "MyApp.Worker",
               %{job | attempt: 2},
               %{"policy" => "standard"}, output_retention: :standard)

    assert :ok =
             JobRecord.record(
               TestRepo,
               "MyApp.Worker",
               %{job | attempt: 3},
               %{"policy" => "extended"}, output_retention: :extended)

    records =
      JobRecord
      |> where([record], record.oban_job_id == ^job.id)
      |> order_by([record], asc: record.attempt)
      |> TestRepo.all()

    assert Enum.map(records, & &1.retention) == ["ephemeral", "standard", "extended"]
    assert_ttl(Enum.at(records, 0), 6 * 60 * 60)
    assert_ttl(Enum.at(records, 1), 7 * 24 * 60 * 60)
    assert_ttl(Enum.at(records, 2), 30 * 24 * 60 * 60)
  end

  test "record/5 preserves the first successful record on duplicate attempt conflicts" do
    job = insert_job!()

    assert :ok = JobRecord.record(TestRepo, "MyApp.Worker", job, %{"value" => 1}, [])

    log =
      capture_log(fn ->
        assert :ok = JobRecord.record(TestRepo, "MyApp.Worker", job, %{"value" => 2}, [])
      end)

    assert log =~ "could not insert"
    assert TestRepo.aggregate(JobRecord, :count, :id) == 1
    assert TestRepo.get_by!(JobRecord, oban_job_id: job.id).payload == %{"value" => 1}
  end

  test "fetch_result/2 retrieves the latest recorded payload for a job" do
    job = insert_job!()

    assert {:error, :not_found} = JobRecord.fetch_result(TestRepo, job.id)

    assert :ok =
             JobRecord.record(
               TestRepo,
               "MyApp.Worker",
               %{job | attempt: 1},
               %{"attempt" => 1},
               []
             )

    assert :ok =
             JobRecord.record(
               TestRepo,
               "MyApp.Worker",
               %{job | attempt: 2},
               %{"attempt" => 2},
               []
             )

    assert {:ok, %{"attempt" => 2}} = JobRecord.fetch_result(TestRepo, job)
  end

  defp assert_ttl(record, expected_seconds) do
    assert DateTime.diff(record.expires_at, record.recorded_at, :second) == expected_seconds
  end

  defp insert_job!(opts \\ []) do
    attempt = Keyword.get(opts, :attempt, 1)

    %{}
    |> Oban.Job.new(worker: "MyApp.Worker", queue: :default)
    |> Ecto.Changeset.change(attempt: attempt)
    |> TestRepo.insert!()
  end
end
