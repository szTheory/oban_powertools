defmodule ObanPowertools.WorkerTest do
  use ExUnit.Case, async: true

  defmodule BasicWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [
        user_id: :integer,
        email: :string
      ]

    @impl true
    def process(%Oban.Job{args: %__MODULE__.Args{user_id: user_id}}) do
      send(self(), {:processed, user_id})
      :ok
    end
  end

  test "worker generates Args module" do
    assert Code.ensure_loaded?(BasicWorker.Args)
    assert function_exported?(BasicWorker.Args, :changeset, 2)
  end

  test "validate/1 returns ok with valid args" do
    assert {:ok, %BasicWorker.Args{user_id: 123, email: "foo@bar.com"}} =
             BasicWorker.validate(%{user_id: 123, email: "foo@bar.com"})
  end

  test "validate/1 returns error with invalid args" do
    assert {:error, %Ecto.Changeset{}} = BasicWorker.validate(%{user_id: "not-an-int"})
  end

  test "invalid args definitions fail at compile time" do
    assert_raise ArgumentError, ~r/expected :args/, fn ->
      Code.compile_string("""
      defmodule InvalidWorker do
        use ObanPowertools.Worker, args: ["user_id"]

        @impl true
        def process(_job), do: :ok
      end
      """)
    end
  end

  test "process/1 receives casted struct" do
    # Manual call to process/1 to check pattern matching
    args = %BasicWorker.Args{user_id: 123, email: "foo@bar.com"}
    job = %Oban.Job{args: args}

    assert :ok = BasicWorker.process(job)
    assert_receive {:processed, 123}
  end

  test "valid limits declarations are normalized onto the worker" do
    defmodule LimitedWorker do
      use ObanPowertools.Worker,
        args: [user_id: :integer],
        limits: [
          name: "per-user-api",
          scope: :partitioned,
          partition_by: {:args, :user_id},
          bucket_capacity: 10,
          bucket_span_ms: 60_000
        ]

      @impl true
      def process(_job), do: :ok
    end

    limits = LimitedWorker.__powertools_limits__()

    assert limits[:name] == "per-user-api"
    assert limits[:scope] == :partitioned
    assert limits[:bucket_capacity] == 10
    assert limits[:bucket_span_ms] == 60_000
    assert limits[:default_weight] == 1
    assert limits[:partition_by] == {:args, :user_id}
  end

  test "invalid partitioned limits without a resolver fail at compile time" do
    assert_raise ArgumentError, ~r/partitioned :limits/, fn ->
      Code.compile_string("""
      defmodule InvalidLimitedWorker do
        use ObanPowertools.Worker,
          args: [user_id: :integer],
          limits: [
            name: "per-user-api",
            scope: :partitioned,
            bucket_capacity: 10,
            bucket_span_ms: 60_000
          ]

        @impl true
        def process(_job), do: :ok
      end
      """)
    end
  end
end
