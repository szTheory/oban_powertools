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

  defmodule DispatcherWorker do
    def __powertools_hook_overridden?(hook) do
      hook in [:on_start, :on_success, :on_failure, :on_discard]
    end

    def on_start(job), do: send(self(), {:hook, :on_start, job})
    def on_success(job, event), do: send(self(), {:hook, :on_success, job, event})
    def on_failure(job, event), do: send(self(), {:hook, :on_failure, job, event})
    def on_discard(job, event), do: send(self(), {:hook, :on_discard, job, event})
  end

  defmodule OmittedHookWorker do
    def __powertools_hook_overridden?(_hook), do: false
  end

  defmodule CrashingHookWorker do
    def __powertools_hook_overridden?(:on_start), do: true
    def __powertools_hook_overridden?(_hook), do: false

    def on_start(_job), do: raise("host hook failed")
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

  test "dispatcher invokes overridden start hook and emits bounded telemetry" do
    attach_worker_hook_handler("worker-start-handler")
    job = %Oban.Job{args: %{user_id: 123}}

    assert :ok = ObanPowertools.Worker.Hooks.on_start(DispatcherWorker, job)

    assert_receive {:hook, :on_start, ^job}

    assert_receive {:worker_hook_event, [:oban_powertools, :worker_hook, :invoked], %{count: 1},
                    %{hook: "on_start", outcome: "ok"}}
  after
    :telemetry.detach("worker-start-handler")
  end

  test "dispatcher builds success and retry failure envelopes" do
    attach_worker_hook_handler("worker-result-handler")
    retry_job = %Oban.Job{args: %{}, attempt: 1, max_attempts: 3}
    success_result = {:ok, %{id: 123}}

    assert :ok = ObanPowertools.Worker.Hooks.after_result(DispatcherWorker, retry_job, :ok)

    assert_receive {:hook, :on_success, ^retry_job, %{state: :success, result: :ok, value: nil}}

    assert_receive {:worker_hook_event, [:oban_powertools, :worker_hook, :invoked], %{count: 1},
                    %{hook: "on_success", outcome: "ok"}}

    assert :ok =
             ObanPowertools.Worker.Hooks.after_result(
               DispatcherWorker,
               retry_job,
               success_result
             )

    assert_receive {:hook, :on_success, ^retry_job,
                    %{state: :success, result: ^success_result, value: %{id: 123}}}

    assert :ok =
             ObanPowertools.Worker.Hooks.after_result(
               DispatcherWorker,
               retry_job,
               {:error, :temporary}
             )

    assert_receive {:hook, :on_failure, ^retry_job,
                    %{
                      state: :failure,
                      reason: :temporary,
                      result: {:error, :temporary},
                      kind: nil,
                      stacktrace: nil,
                      terminal?: false
                    }}
  after
    :telemetry.detach("worker-result-handler")
  end

  test "dispatcher routes terminal failures and explicit discards to discard hook only" do
    terminal_job = %Oban.Job{args: %{}, attempt: 3, max_attempts: 3}

    assert :ok =
             ObanPowertools.Worker.Hooks.after_result(
               DispatcherWorker,
               terminal_job,
               {:error, :exhausted}
             )

    assert_receive {:hook, :on_discard, ^terminal_job,
                    %{
                      state: :discard,
                      reason: :exhausted,
                      result: {:error, :exhausted},
                      kind: nil,
                      stacktrace: nil,
                      terminal?: true
                    }}

    refute_receive {:hook, :on_failure, _, _}

    assert :ok =
             ObanPowertools.Worker.Hooks.after_result(
               DispatcherWorker,
               terminal_job,
               {:discard, :manual}
             )

    assert_receive {:hook, :on_discard, ^terminal_job,
                    %{
                      state: :discard,
                      reason: :manual,
                      result: {:discard, :manual},
                      kind: nil,
                      stacktrace: nil,
                      terminal?: true
                    }}
  end

  test "dispatcher routes caught process failures by retry eligibility" do
    retry_job = %Oban.Job{args: %{}, attempt: 1, max_attempts: 3}
    terminal_job = %Oban.Job{args: %{}, attempt: 3, max_attempts: 3}
    stacktrace = [{__MODULE__, :test, 0, []}]

    assert :ok =
             ObanPowertools.Worker.Hooks.after_exception(
               DispatcherWorker,
               retry_job,
               :error,
               :bad_state,
               stacktrace
             )

    assert_receive {:hook, :on_failure, ^retry_job,
                    %{
                      state: :failure,
                      reason: :bad_state,
                      result: nil,
                      kind: :error,
                      stacktrace: ^stacktrace,
                      terminal?: false
                    }}

    assert :ok =
             ObanPowertools.Worker.Hooks.after_exception(
               DispatcherWorker,
               terminal_job,
               :exit,
               :shutdown,
               stacktrace
             )

    assert_receive {:hook, :on_discard, ^terminal_job,
                    %{
                      state: :discard,
                      reason: :shutdown,
                      result: nil,
                      kind: :exit,
                      stacktrace: ^stacktrace,
                      terminal?: true
                    }}
  end

  test "dispatcher swallows crashing hooks and emits crash_caught telemetry" do
    attach_worker_hook_handler("worker-crash-handler")
    job = %Oban.Job{args: %{}}

    assert :ok = ObanPowertools.Worker.Hooks.on_start(CrashingHookWorker, job)

    assert_receive {:worker_hook_event, [:oban_powertools, :worker_hook, :invoked], %{count: 1},
                    %{hook: "on_start", outcome: "crash_caught"}}
  after
    :telemetry.detach("worker-crash-handler")
  end

  test "dispatcher skips omitted hooks and non-dispatch outcomes without telemetry" do
    attach_worker_hook_handler("worker-omitted-handler")
    job = %Oban.Job{args: %{}, attempt: 1, max_attempts: 3}

    assert :ok = ObanPowertools.Worker.Hooks.on_start(OmittedHookWorker, job)
    assert :ok = ObanPowertools.Worker.Hooks.after_result(DispatcherWorker, job, {:cancel, :stop})
    assert :ok = ObanPowertools.Worker.Hooks.after_result(DispatcherWorker, job, {:snooze, 60})

    refute_receive {:worker_hook_event, _, _, _}
    refute_receive {:hook, _, _, _}
  after
    :telemetry.detach("worker-omitted-handler")
  end

  defp attach_worker_hook_handler(handler_id) do
    :telemetry.attach(
      handler_id,
      [:oban_powertools, :worker_hook, :invoked],
      fn name, measurements, metadata, _config ->
        send(self(), {:worker_hook_event, name, measurements, metadata})
      end,
      nil
    )
  end
end
