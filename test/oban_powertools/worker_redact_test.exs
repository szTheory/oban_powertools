defmodule ObanPowertools.WorkerRedactTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.TestRepo

  # REDACT-01, REDACT-02, D-06: Integration worker for key-absent, string-key, required-field exemption, meta
  defmodule RedactWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [user_id: :integer, ssn: :string],
      redact: [:ssn]

    @impl true
    def process(%Oban.Job{args: %__MODULE__.Args{user_id: user_id}}) do
      send(self(), {:processed, user_id})
      :ok
    end
  end

  # REDACT-02, D-17: Multi-field sorted meta worker
  defmodule MultiRedactWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [user_id: :integer, ssn: :string, token: :string],
      redact: [:token, :ssn]

    @impl true
    def process(_job), do: :ok
  end

  setup do
    original_repo = Application.get_env(:oban_powertools, :repo)
    Application.put_env(:oban_powertools, :repo, TestRepo)

    on_exit(fn ->
      if is_nil(original_repo) do
        Application.delete_env(:oban_powertools, :repo)
      else
        Application.put_env(:oban_powertools, :repo, original_repo)
      end
    end)

    :ok
  end

  # REDACT-01 / D-02: key-absent (not nil) after enqueue via transaction/3
  test "REDACT-01 key-absent: ssn is absent from stored oban_jobs args after enqueue" do
    assert {:ok, job} = RedactWorker.enqueue(%{ssn: "123", user_id: 1})
    stored_job = TestRepo.get!(Oban.Job, job.id)

    refute Map.has_key?(stored_job.args, "ssn")
    refute Map.has_key?(stored_job.args, :ssn)
    assert stored_job.args["user_id"] == 1
  end

  # REDACT-01 / D-16: string-key normalization — direct new/1 with string-keyed args
  test "REDACT-01 string-key: ssn absent when enqueued via direct new with string keys" do
    changeset = RedactWorker.new(%{"ssn" => "x", "user_id" => 1})
    assert {:ok, job} = TestRepo.insert(changeset)
    stored_job = TestRepo.get!(Oban.Job, job.id)

    refute Map.has_key?(stored_job.args, "ssn")
    refute Map.has_key?(stored_job.args, :ssn)
  end

  # REDACT-01 / D-06: required-field exemption — validate succeeds without ssn; perform succeeds
  test "REDACT-01 required-field exemption: validate and perform succeed with ssn absent" do
    # Stored args shape: ssn absent (as they would be after enqueue + JSONB round-trip)
    assert {:ok, _casted} = RedactWorker.validate(%{"user_id" => 1})

    job = %Oban.Job{
      id: System.unique_integer([:positive]),
      args: %{"user_id" => 1},
      attempt: 1,
      max_attempts: 3,
      meta: %{}
    }

    assert :ok = RedactWorker.perform(job)
    assert_receive {:processed, 1}
  end

  # REDACT-02 / D-17: __redacted_fields__ is a sorted string list in meta
  test "REDACT-02 meta: __redacted_fields__ is a sorted string list in job meta" do
    assert {:ok, job} = MultiRedactWorker.enqueue(%{user_id: 1, ssn: "123", token: "abc"})
    stored_job = TestRepo.get!(Oban.Job, job.id)

    assert stored_job.meta["__redacted_fields__"] == ["ssn", "token"]
  end

  # D-07: typo guard — compile-time raise for undeclared redact field
  test "D-07 typo guard: redact with undeclared field raises ArgumentError at compile time" do
    assert_raise ArgumentError, ~r/redact: key :typo_field is not declared/, fn ->
      Code.compile_string("""
      defmodule TypoRedactWorker do
        use ObanPowertools.Worker,
          args: [user_id: :integer],
          redact: [:typo_field]

        @impl true
        def process(_job), do: :ok
      end
      """)
    end
  end

  # D-09: partition guard — compile-time raise when redact overlaps partition_by
  test "D-09 partition guard: redact overlapping partition_by raises ArgumentError at compile time" do
    assert_raise ArgumentError, ~r/partition/, fn ->
      Code.compile_string("""
      defmodule PartitionRedactWorker do
        use ObanPowertools.Worker,
          args: [user_id: :integer],
          limits: [
            name: "r",
            scope: :partitioned,
            partition_by: {:args, :user_id},
            bucket_capacity: 10,
            bucket_span_ms: 60_000
          ],
          redact: [:user_id]

        @impl true
        def process(_job), do: :ok
      end
      """)
    end
  end
end
