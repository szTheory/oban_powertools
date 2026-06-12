defmodule ObanPowertools.WorkerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

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

  defmodule NoHookGeneratedWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [
        user_id: :integer
      ]

    @impl true
    def process(%Oban.Job{args: %__MODULE__.Args{user_id: user_id}}) do
      send(self(), {:no_hook_processed, user_id})
      :ok
    end
  end

  defmodule HookedGeneratedWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [
        user_id: :integer,
        mode: :string
      ]

    @impl true
    def on_start(%Oban.Job{args: %__MODULE__.Args{user_id: user_id}}) do
      send(self(), {:generated_hook, :on_start, user_id})
      :ignored
    end

    @impl true
    def process(%Oban.Job{args: %__MODULE__.Args{user_id: user_id, mode: mode}}) do
      send(self(), {:generated_hook, :process, user_id})

      case mode do
        "ok" -> :ok
        "ok_value" -> {:ok, %{user_id: user_id}}
        "error" -> {:error, :temporary}
        "discard" -> {:discard, :manual}
        "cancel" -> {:cancel, :stop}
        "snooze" -> {:snooze, 60}
        "raise" -> raise "process failed"
        "throw" -> throw(:process_thrown)
        "exit" -> exit(:process_exited)
      end
    end

    @impl true
    def on_success(_job, event), do: send(self(), {:generated_hook, :on_success, event})

    @impl true
    def on_failure(_job, event), do: send(self(), {:generated_hook, :on_failure, event})

    @impl true
    def on_discard(_job, event), do: send(self(), {:generated_hook, :on_discard, event})
  end

  defmodule CrashingGeneratedHookWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [
        mode: :string
      ]

    @impl true
    def on_start(_job), do: raise("start hook failed")

    @impl true
    def process(%Oban.Job{args: %__MODULE__.Args{mode: mode}}) do
      case mode do
        "ok" -> :ok
        "error" -> {:error, :temporary}
        "discard" -> {:discard, :manual}
        "raise" -> raise "process failed"
      end
    end

    @impl true
    def on_success(_job, _event), do: raise("success hook failed")

    @impl true
    def on_failure(_job, _event), do: raise("failure hook failed")

    @impl true
    def on_discard(_job, _event), do: raise("discard hook failed")
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

  test "generated workers expose no-op hook defaults and override tracking" do
    attach_worker_hook_handler("generated-no-hook-handler")
    job = worker_job(%{user_id: 123})

    assert :ok = NoHookGeneratedWorker.perform(job)
    assert_receive {:no_hook_processed, 123}

    refute NoHookGeneratedWorker.__powertools_hook_overridden?(:on_start)
    refute NoHookGeneratedWorker.__powertools_hook_overridden?(:on_success)
    refute NoHookGeneratedWorker.__powertools_hook_overridden?(:on_failure)
    refute NoHookGeneratedWorker.__powertools_hook_overridden?(:on_discard)
    refute_receive {:worker_hook_event, _, _, _}
  after
    :telemetry.detach("generated-no-hook-handler")
  end

  test "generated perform validates args before on_start and process" do
    job = worker_job(%{user_id: "not-an-int", mode: "ok"})

    assert {:error, %Ecto.Changeset{}} = HookedGeneratedWorker.perform(job)
    refute_receive {:generated_hook, _, _}
    refute_receive {:generated_hook, _, _, _}
  end

  test "generated perform dispatches on_start before process and on_success after process" do
    job = worker_job(%{user_id: 123, mode: "ok"})

    assert :ok = HookedGeneratedWorker.perform(job)

    assert_receive_in_order([
      {:generated_hook, :on_start, 123},
      {:generated_hook, :process, 123},
      {:generated_hook, :on_success, %{state: :success, result: :ok, value: nil}}
    ])

    assert HookedGeneratedWorker.__powertools_hook_overridden?(:on_start)
    assert HookedGeneratedWorker.__powertools_hook_overridden?(:on_success)
  end

  test "generated perform routes success values, retry failures, final failures, and explicit discards" do
    assert {:ok, %{user_id: 123}} =
             HookedGeneratedWorker.perform(worker_job(%{user_id: 123, mode: "ok_value"}))

    assert_receive {:generated_hook, :on_success,
                    %{state: :success, result: {:ok, %{user_id: 123}}, value: %{user_id: 123}}}

    assert {:error, :temporary} =
             HookedGeneratedWorker.perform(
               worker_job(%{user_id: 123, mode: "error"}, attempt: 1, max_attempts: 3)
             )

    assert_receive {:generated_hook, :on_failure,
                    %{
                      state: :failure,
                      reason: :temporary,
                      result: {:error, :temporary},
                      kind: nil,
                      stacktrace: nil,
                      terminal?: false
                    }}

    assert {:error, :temporary} =
             HookedGeneratedWorker.perform(
               worker_job(%{user_id: 123, mode: "error"}, attempt: 3, max_attempts: 3)
             )

    assert_receive {:generated_hook, :on_discard,
                    %{
                      state: :discard,
                      reason: :temporary,
                      result: {:error, :temporary},
                      kind: nil,
                      stacktrace: nil,
                      terminal?: true
                    }}

    refute_receive {:generated_hook, :on_failure, %{terminal?: true}}

    assert {:discard, :manual} =
             HookedGeneratedWorker.perform(worker_job(%{user_id: 123, mode: "discard"}))

    assert_receive {:generated_hook, :on_discard,
                    %{
                      state: :discard,
                      reason: :manual,
                      result: {:discard, :manual},
                      kind: nil,
                      stacktrace: nil,
                      terminal?: true
                    }}
  end

  test "generated perform leaves cancel and snooze unchanged without post-hook dispatch" do
    assert {:cancel, :stop} =
             HookedGeneratedWorker.perform(worker_job(%{user_id: 123, mode: "cancel"}))

    assert_receive {:generated_hook, :on_start, 123}
    assert_receive {:generated_hook, :process, 123}
    refute_receive {:generated_hook, :on_failure, _}
    refute_receive {:generated_hook, :on_discard, _}
    refute_receive {:generated_hook, :on_success, _}

    assert {:snooze, 60} =
             HookedGeneratedWorker.perform(worker_job(%{user_id: 456, mode: "snooze"}))

    assert_receive {:generated_hook, :on_start, 456}
    assert_receive {:generated_hook, :process, 456}
    refute_receive {:generated_hook, :on_failure, _}
    refute_receive {:generated_hook, :on_discard, _}
    refute_receive {:generated_hook, :on_success, _}
  end

  test "generated perform dispatches hooks then preserves process raises, throws, and exits" do
    assert_raise RuntimeError, "process failed", fn ->
      HookedGeneratedWorker.perform(
        worker_job(%{user_id: 123, mode: "raise"}, attempt: 1, max_attempts: 3)
      )
    end

    assert_receive {:generated_hook, :on_failure,
                    %{
                      state: :failure,
                      reason: %RuntimeError{message: "process failed"},
                      result: nil,
                      kind: :error,
                      terminal?: false
                    }}

    assert catch_throw(HookedGeneratedWorker.perform(worker_job(%{user_id: 123, mode: "throw"}))) ==
             :process_thrown

    assert_receive {:generated_hook, :on_failure,
                    %{
                      state: :failure,
                      reason: :process_thrown,
                      result: nil,
                      kind: :throw,
                      terminal?: false
                    }}

    assert catch_exit(HookedGeneratedWorker.perform(worker_job(%{user_id: 123, mode: "exit"}))) ==
             :process_exited

    assert_receive {:generated_hook, :on_failure,
                    %{
                      state: :failure,
                      reason: :process_exited,
                      result: nil,
                      kind: :exit,
                      terminal?: false
                    }}
  end

  test "generated hook crashes do not change process returns or preserved exceptions" do
    capture_log(fn ->
      assert :ok = CrashingGeneratedHookWorker.perform(worker_job(%{mode: "ok"}))

      assert {:error, :temporary} =
               CrashingGeneratedHookWorker.perform(
                 worker_job(%{mode: "error"}, attempt: 1, max_attempts: 3)
               )

      assert {:discard, :manual} =
               CrashingGeneratedHookWorker.perform(worker_job(%{mode: "discard"}))

      assert_raise RuntimeError, "process failed", fn ->
        CrashingGeneratedHookWorker.perform(
          worker_job(%{mode: "raise"}, attempt: 1, max_attempts: 3)
        )
      end
    end)
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

  defp worker_job(args, opts \\ []) do
    %Oban.Job{
      args: args,
      attempt: Keyword.get(opts, :attempt, 1),
      max_attempts: Keyword.get(opts, :max_attempts, 3)
    }
  end

  defp assert_receive_in_order(expected_messages) do
    received_messages =
      for _message <- expected_messages do
        receive do
          message -> message
        after
          100 -> flunk("expected #{length(expected_messages)} messages, received fewer")
        end
      end

    assert received_messages == expected_messages
  end
end
