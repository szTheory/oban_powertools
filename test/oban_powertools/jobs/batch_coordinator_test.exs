defmodule ObanPowertools.Jobs.BatchCoordinatorTest do
  use ObanPowertools.DataCase, async: false

  alias Ecto.Changeset
  alias ObanPowertools.Audit
  alias ObanPowertools.Jobs.BatchCoordinator
  alias ObanPowertools.Jobs.BatchCoordinator.Scope

  @telemetry_event [:oban_powertools, :jobs, :batch]

  test "freezes ordered unique explicit and all-matching scopes without truncation" do
    observed_at = ~U[2026-07-28 14:00:00Z]

    assert {:ok,
            %Scope{
              mode: :explicit,
              ids: [3, 1, 2],
              filter_identity: "state=retryable",
              selected_count: 3,
              observed_at: ^observed_at
            }} =
             BatchCoordinator.freeze_scope(
               :explicit,
               [3, 1, 3, 2, 1],
               "state=retryable",
               observed_at
             )

    assert {:ok,
            %Scope{
              mode: :all_matching,
              ids: [8, 7],
              selected_count: 2
            }} =
             BatchCoordinator.freeze_scope(
               :all_matching,
               %{ids: [8, 7], overflow?: false, selected_count: 2},
               "state=retryable&queue=critical",
               observed_at
             )

    limit = ObanPowertools.RuntimeConfig.jobs_bulk_target_limit()
    oversized = Enum.to_list(1..(limit + 1))

    assert {:error, {:too_many_targets, ^limit}} =
             BatchCoordinator.freeze_scope(
               :explicit,
               oversized,
               "state=retryable",
               observed_at
             )

    assert {:error, {:too_many_targets, ^limit}} =
             BatchCoordinator.freeze_scope(
               :all_matching,
               %{ids: Enum.take(oversized, limit), overflow?: true, selected_count: limit + 1},
               "state=retryable",
               observed_at
             )

    assert {:error, :invalid_scope} =
             BatchCoordinator.freeze_scope(
               :all_matching,
               %{ids: [1], overflow?: false, selected_count: 2},
               "state=retryable",
               observed_at
             )
  end

  test "previews every frozen target with explicit authorization and no execution capability in messages" do
    test_pid = self()
    token_sentinel = "preview-token-must-stay-server-side"
    target_ids = [91_001, 91_002]
    scope = explicit_scope!(target_ids)

    authorize = fn _actor, permission, resource ->
      send(test_pid, {:authorized, permission, resource})
      :ok
    end

    preview = fn _repo, _actor, attrs, _opts ->
      send(test_pid, {:previewed, attrs.target_id})
      {:ok, %{preview_token: "#{token_sentinel}-#{attrs.target_id}"}}
    end

    assert {:ok, handle} =
             BatchCoordinator.start_preview(
               self(),
               repo(),
               actor(),
               :retry,
               scope,
               authorize: authorize,
               preview: preview
             )

    on_exit(fn -> terminate_handle(handle) end)

    assert_receive {:authorized, :view_jobs, %{type: :page, id: "jobs"}}
    assert_receive {:authorized, :retry_job, %{type: :jobs_bulk_action}}

    for id <- target_ids do
      assert_receive {:authorized, :view_job_detail, %{type: :job, id: ^id}}
      assert_receive {:authorized, :retry_job, %{type: :job, id: ^id}}
      assert_receive {:authorized, :preview_repair, %{type: :job, id: ^id}}
      assert_receive {:previewed, ^id}
    end

    assert_receive {:jobs_batch_complete, run_ref,
                    %{
                      receipt: %{
                        stage: :preview,
                        selected: 2,
                        ready: 2,
                        excluded: 0,
                        execution_available?: true
                      },
                      results: preview_results
                    }}

    assert run_ref == handle.run_ref
    assert Enum.map(preview_results, & &1.position) == [0, 1]
    assert Enum.all?(preview_results, &(&1.outcome == :ready))

    refute inspect({run_ref, preview_results}) =~ token_sentinel
    refute inspect(preview_results) =~ "91001"
    refute inspect(preview_results) =~ "91002"
  end

  test "zero-ready preview is explanatory and cannot enter execution" do
    scope = explicit_scope!([92_001, 92_002])

    preview = fn _repo, _actor, _attrs, _opts ->
      {:error, :heartbeat_late}
    end

    assert {:ok, handle} =
             BatchCoordinator.start_preview(
               self(),
               repo(),
               actor(),
               :cancel,
               scope,
               authorize: allow_all(),
               preview: preview
             )

    on_exit(fn -> terminate_handle(handle) end)

    assert_receive {:jobs_batch_complete, run_ref,
                    %{
                      receipt: %{
                        stage: :preview,
                        ready: 0,
                        excluded: 2,
                        execution_available?: false
                      },
                      results: results
                    }}

    assert run_ref == handle.run_ref
    assert Enum.all?(results, &(&1.outcome == :excluded))
    assert Enum.all?(results, &(&1.message == "This job is not ready for this action."))

    assert {:ok, ^run_ref} =
             BatchCoordinator.start_execution(
               self(),
               repo(),
               actor(),
               handle,
               "Cancel the selected jobs",
               execute: successful_execute()
             )

    assert_receive {:jobs_batch_failed, ^run_ref, :nothing_ready}
    refute Process.alive?(handle.coordinator)
  end

  test "execution never exceeds four workers and reconstructs stable frozen order" do
    test_pid = self()
    ids = Enum.to_list(93_001..93_006)
    scope = explicit_scope!(ids)
    telemetry_id = attach_telemetry(test_pid)

    on_exit(fn -> :telemetry.detach(telemetry_id) end)

    assert {:ok, handle} =
             BatchCoordinator.start_preview(
               self(),
               repo(),
               actor(),
               :discard,
               scope,
               authorize: allow_all(),
               preview: ready_preview()
             )

    on_exit(fn -> terminate_handle(handle) end)
    assert_receive {:jobs_batch_complete, _, %{receipt: %{stage: :preview}}}

    execute = fn _repo, _actor, token, _reason, _opts ->
      id = token_id(token)
      send(test_pid, {:worker_started, id, self()})

      receive do
        {:release, ^id} -> {:ok, %{target: :safe}}
      end
    end

    assert {:ok, run_ref} =
             BatchCoordinator.start_execution(
               self(),
               repo(),
               actor(),
               handle,
               "Discard these reviewed jobs",
               execute: execute
             )

    first_wave = receive_started_workers(4)
    refute_receive {:worker_started, _id, _pid}, 50

    first_wave
    |> Enum.sort_by(fn {id, _pid} -> id end, :desc)
    |> Enum.each(fn {id, pid} -> send(pid, {:release, id}) end)

    second_wave = receive_started_workers(2)

    second_wave
    |> Enum.sort_by(fn {id, _pid} -> id end, :desc)
    |> Enum.each(fn {id, pid} -> send(pid, {:release, id}) end)

    {progress_messages, complete} = collect_until_complete(run_ref, [])

    assert Enum.map(complete.results, & &1.position) == Enum.to_list(0..5)
    assert Enum.all?(complete.results, &(&1.outcome == :success))

    assert complete.receipt == %{
             stage: :execution,
             action: :discard,
             total: 6,
             success: 6,
             skipped: 0,
             failed: 0,
             all_success?: true
           }

    assert Enum.map(progress_messages, & &1.processed) == Enum.to_list(1..6)
    assert Enum.all?(progress_messages, &(&1.total == 6))

    assert_receive {:batch_telemetry, measurements, preview_metadata}
    assert measurements == %{count: 1}
    assert preview_metadata.surface == :jobs
    assert preview_metadata.action == :discard
    assert preview_metadata.scope == :explicit
    assert preview_metadata.result == :preview_ready
    assert preview_metadata.count_bucket == :"1_10"

    assert_receive {:batch_telemetry, %{count: 1}, execution_metadata}
    assert execution_metadata.result == :all_success

    assert Map.keys(execution_metadata) |> Enum.sort() ==
             [:action, :count_bucket, :duration_bucket, :result, :scope, :surface]

    message_dump = inspect({progress_messages, complete, execution_metadata})

    for id <- ids do
      refute message_dump =~ Integer.to_string(id)
    end

    refute message_dump =~ "token-"
    refute message_dump =~ "Discard these reviewed jobs"
    refute message_dump =~ "operator-batch"
  end

  test "timeouts, crashes, and Lifeline drift are isolated into finite outcomes" do
    scope = explicit_scope!([94_001, 94_002, 94_003])

    assert {:ok, handle} =
             BatchCoordinator.start_preview(
               self(),
               repo(),
               actor(),
               :retry,
               scope,
               authorize: allow_all(),
               preview: ready_preview()
             )

    on_exit(fn -> terminate_handle(handle) end)
    assert_receive {:jobs_batch_complete, _, %{receipt: %{stage: :preview}}}

    execute = fn _repo, _actor, token, _reason, _opts ->
      case token_id(token) do
        94_001 ->
          receive do
            :never -> :ok
          end

        94_002 ->
          exit(:injected_crash)

        94_003 ->
          {:error, :preview_drifted}
      end
    end

    assert {:ok, run_ref} =
             BatchCoordinator.start_execution(
               self(),
               repo(),
               actor(),
               handle,
               "Retry the reviewed jobs",
               execute: execute,
               test_target_timeout_ms: 1
             )

    {_progress, complete} = collect_until_complete(run_ref, [])

    assert Enum.map(complete.results, & &1.outcome) == [:failed, :failed, :skipped]

    assert Enum.map(complete.results, & &1.message) == [
             "This job did not finish before the target timeout.",
             "This job could not be processed.",
             "This job changed after the preview."
           ]

    assert complete.receipt.success == 0
    assert complete.receipt.skipped == 1
    assert complete.receipt.failed == 2
    assert Process.alive?(Process.whereis(ObanPowertools.Jobs.TaskSupervisor))
  end

  test "accepted execution continues after its observing owner exits" do
    test_pid = self()
    scope = explicit_scope!([95_001])

    observer =
      spawn(fn ->
        {:ok, handle} =
          BatchCoordinator.start_preview(
            self(),
            repo(),
            actor(),
            :retry,
            scope,
            authorize: allow_all(),
            preview: ready_preview()
          )

        send(test_pid, {:observer_handle, handle})

        receive do
          {:jobs_batch_complete, _run_ref, %{receipt: %{stage: :preview}}} ->
            :ok
        end

        execute = fn _repo, _actor, token, _reason, _opts ->
          send(test_pid, {:accepted_target_started, token_id(token), self()})

          receive do
            :release ->
              send(test_pid, :durable_target_effect)
              {:ok, %{target: :safe}}
          end
        end

        {:ok, _run_ref} =
          BatchCoordinator.start_execution(
            self(),
            repo(),
            actor(),
            handle,
            "Retry after independent review",
            execute: execute
          )

        send(test_pid, :execution_accepted)

        receive do
          :stop_observing -> :ok
        end
      end)

    assert_receive {:observer_handle, handle}
    on_exit(fn -> terminate_handle(handle) end)
    coordinator_monitor = Process.monitor(handle.coordinator)
    assert_receive :execution_accepted
    assert_receive {:accepted_target_started, 95_001, worker}

    Process.exit(observer, :kill)
    refute Process.alive?(observer)
    send(worker, :release)

    assert_receive :durable_target_effect
    assert_receive {:DOWN, ^coordinator_monitor, :process, _, :normal}
  end

  test "real Lifeline preview and execution run once per target with independent Audit evidence" do
    jobs = [insert_job!("executing"), insert_job!("retryable")]
    scope = explicit_scope!(Enum.map(jobs, & &1.id))

    assert {:ok, handle} =
             BatchCoordinator.start_preview(
               self(),
               repo(),
               actor(),
               :retry,
               scope,
               []
             )

    on_exit(fn -> terminate_handle(handle) end)

    assert_receive {:jobs_batch_complete, run_ref,
                    %{receipt: %{stage: :preview, ready: 2, excluded: 0}}}

    assert {:ok, ^run_ref} =
             BatchCoordinator.start_execution(
               self(),
               repo(),
               actor(),
               handle,
               "Retry both reviewed jobs",
               []
             )

    {_progress, complete} = collect_until_complete(run_ref, [])
    assert complete.receipt.all_success?

    for job <- jobs do
      assert repo().get!(Oban.Job, job.id).state == "available"

      repair_events =
        Audit.list(%{type: :job, id: Integer.to_string(job.id)}, repo: repo())
        |> Enum.filter(&(&1.action == "lifeline.repair_executed"))

      assert length(repair_events) == 1
    end
  end

  test "safe result retention is bounded and visible pages contain at most fifty rows" do
    results =
      Enum.map(0..999, fn position ->
        %{position: position, outcome: :failed, message: "Safe failure", recovery: "Review Audit"}
      end)

    assert %{results: first, page: 1, page_size: 50, total_count: 1000, next?: true} =
             BatchCoordinator.result_page(results, 1)

    assert length(first) == 50
    assert hd(first).position == 0

    assert %{results: last, page: 20, previous?: true, next?: false} =
             BatchCoordinator.result_page(results, 20)

    assert length(last) == 50
    assert hd(last).position == 950

    assert_raise ArgumentError, fn ->
      BatchCoordinator.result_page(results ++ [%{position: 1000}], 1)
    end
  end

  defp explicit_scope!(ids) do
    {:ok, scope} =
      BatchCoordinator.freeze_scope(
        :explicit,
        ids,
        "state=retryable&queue=critical",
        ~U[2026-07-28 14:00:00Z]
      )

    scope
  end

  defp actor do
    %{
      id: "operator-batch",
      permissions: [
        :view_jobs,
        :view_job_detail,
        :retry_job,
        :cancel_job,
        :discard_job,
        :preview_repair,
        :execute_repair
      ]
    }
  end

  defp allow_all do
    fn _actor, _permission, _resource -> :ok end
  end

  defp ready_preview do
    fn _repo, _actor, attrs, _opts ->
      {:ok, %{preview_token: "token-#{attrs.target_id}"}}
    end
  end

  defp successful_execute do
    fn _repo, _actor, _token, _reason, _opts ->
      {:ok, %{target: :safe}}
    end
  end

  defp token_id("token-" <> id), do: String.to_integer(id)

  defp receive_started_workers(count) do
    Enum.map(1..count, fn _index ->
      assert_receive {:worker_started, id, pid}
      {id, pid}
    end)
  end

  defp collect_until_complete(run_ref, progress) do
    receive do
      {:jobs_batch_progress, ^run_ref, message} ->
        collect_until_complete(run_ref, [message | progress])

      {:jobs_batch_complete, ^run_ref, complete} ->
        {Enum.reverse(progress), complete}
    after
      5_000 ->
        flunk("timed out waiting for batch completion")
    end
  end

  defp attach_telemetry(test_pid) do
    handler_id = "batch-coordinator-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      @telemetry_event,
      fn _event, measurements, metadata, _config ->
        send(test_pid, {:batch_telemetry, measurements, metadata})
      end,
      nil
    )

    handler_id
  end

  defp terminate_handle(%{coordinator: pid}) do
    if Process.alive?(pid) do
      Task.Supervisor.terminate_child(ObanPowertools.Jobs.TaskSupervisor, pid)
    end
  end

  defp insert_job!(state) do
    %{}
    |> Oban.Job.new(worker: "Example.Worker", queue: :default)
    |> Changeset.change(state: state)
    |> repo().insert!()
  end

  defp repo, do: ObanPowertools.TestRepo
end
