defmodule ObanPowertools.WorkflowCallbacksTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Workflow
  alias ObanPowertools.Callback
  alias ObanPowertools.Workflow.{RecoveryAttempt, RecoverySession, Step}
  alias ObanPowertools.WorkflowCallbackTestHandler
  alias ObanPowertools.WorkflowFixtures
  alias ObanPowertools.WorkflowNoopCallbackTestHandler

  test "workflow dispatcher leaves chain progression callbacks pending" do
    original_handler = Application.get_env(:oban_powertools, :workflow_callback_handler)
    Application.put_env(:oban_powertools, :workflow_callback_handler, WorkflowCallbackTestHandler)

    on_exit(fn ->
      Application.put_env(:oban_powertools, :workflow_callback_handler, original_handler)
    end)

    callback =
      %Callback{}
      |> Callback.changeset(%{
        event: "chain.step_succeeded",
        dedupe_key: "chain.step_succeeded:chain-1:0:123",
        status: "pending",
        payload: %{
          "event" => "chain.step_succeeded",
          "chain_id" => Ecto.UUID.generate(),
          "upstream_job_id" => 123
        },
        attempts: 0
      })
      |> TestRepo.insert!()

    assert %{failed: 0, delivered: 0} =
             Workflow.dispatch_callbacks(TestRepo, dispatcher_id: "node-a")

    persisted = TestRepo.get!(Callback, callback.id)
    assert persisted.status == "pending"
    assert persisted.attempts == 0
    assert is_nil(persisted.claimed_by)
  end

  test "batch callbacks still dispatch through the host callback handler path" do
    original_handler = Application.get_env(:oban_powertools, :workflow_callback_handler)
    Application.put_env(:oban_powertools, :workflow_callback_handler, WorkflowCallbackTestHandler)
    Process.register(self(), :workflow_callback_test)

    on_exit(fn ->
      Application.put_env(:oban_powertools, :workflow_callback_handler, original_handler)

      if Process.whereis(:workflow_callback_test) == self() do
        Process.unregister(:workflow_callback_test)
      end
    end)

    completed =
      insert_callback!(
        event: "batch.completed",
        dedupe_key: "batch.completed:batch-1",
        payload: %{"event" => "batch.completed", "batch_id" => Ecto.UUID.generate()}
      )

    exhausted =
      insert_callback!(
        event: "batch.exhausted",
        dedupe_key: "batch.exhausted:batch-2",
        payload: %{"event" => "batch.exhausted", "batch_id" => Ecto.UUID.generate()}
      )

    assert %{failed: 0, delivered: 2} =
             Workflow.dispatch_callbacks(TestRepo, dispatcher_id: "node-a")

    assert TestRepo.get!(Callback, completed.id).status == "delivered"
    assert TestRepo.get!(Callback, exhausted.id).status == "delivered"
    assert_receive {:workflow_callback, %{"event" => "batch.completed"}}
    assert_receive {:workflow_callback, %{"event" => "batch.exhausted"}}
  end

  test "terminal callbacks are persisted durably and retried through the outbox" do
    original_handler = Application.get_env(:oban_powertools, :workflow_callback_handler)
    Application.put_env(:oban_powertools, :workflow_callback_handler, WorkflowCallbackTestHandler)
    Process.register(self(), :workflow_callback_test)
    :persistent_term.put({WorkflowCallbackTestHandler, :mode}, :fail)

    on_exit(fn ->
      Application.put_env(:oban_powertools, :workflow_callback_handler, original_handler)
      :persistent_term.erase({WorkflowCallbackTestHandler, :mode})

      if Process.whereis(:workflow_callback_test) == self() do
        Process.unregister(:workflow_callback_test)
      end
    end)

    workflow =
      Workflow.new(name: "callback-terminal")
      |> Workflow.add(:ship, %{worker: "ShipWorker", input: %{}, queue: "default"})

    {:ok, workflow} = Workflow.insert(workflow, TestRepo)

    assert {:ok, _step} =
             Workflow.complete_step(TestRepo, workflow.id, :ship,
               status: :completed,
               payload: %{ok: true}
             )

    outbox =
      TestRepo.get_by!(Callback, workflow_id: workflow.id, event: "workflow.terminal")

    assert outbox.status == "pending"
    assert outbox.payload["event"] == "workflow.terminal"
    assert outbox.payload["callback_id"] == outbox.id
    assert outbox.payload["envelope_version"] == 1

    assert %{failed: 1, delivered: 0} =
             Workflow.dispatch_callbacks(TestRepo, dispatcher_id: "node-a")

    failed = TestRepo.get!(Callback, outbox.id)
    assert failed.status == "failed"
    assert failed.attempts == 1
    assert failed.claimed_by == "node-a"
    assert failed.claimed_at
    assert is_nil(failed.lease_expires_at)

    :persistent_term.put({WorkflowCallbackTestHandler, :mode}, :ok)

    assert %{failed: 0, delivered: 1} =
             Workflow.dispatch_callbacks(TestRepo,
               dispatcher_id: "node-b",
               now: DateTime.add(DateTime.utc_now(), 31, :second)
             )

    delivered = TestRepo.get!(Callback, outbox.id)
    workflow_id = workflow.id

    assert delivered.status == "delivered"
    assert delivered.attempts == 2
    assert delivered.claimed_by == "node-b"
    assert_receive {:workflow_callback, %{"workflow_id" => ^workflow_id, "state" => "completed"}}
  end

  test "claimed callbacks are lease-protected until the lease expires" do
    workflow =
      Workflow.new(name: "callback-lease")
      |> Workflow.add(:ship, %{worker: "ShipWorker", input: %{}, queue: "default"})

    {:ok, workflow} = Workflow.insert(workflow, TestRepo)

    assert {:ok, _step} =
             Workflow.complete_step(TestRepo, workflow.id, :ship,
               status: :completed,
               payload: %{ok: true}
             )

    outbox =
      TestRepo.get_by!(Callback, workflow_id: workflow.id, event: "workflow.terminal")

    future = DateTime.add(DateTime.utc_now(), 60, :second)

    outbox
    |> Callback.changeset(%{
      status: "claimed",
      claimed_at: DateTime.utc_now(),
      claimed_by: "node-a",
      lease_expires_at: future
    })
    |> TestRepo.update!()

    assert %{failed: 0, delivered: 0} =
             Workflow.dispatch_callbacks(TestRepo,
               dispatcher_id: "node-b",
               handler: WorkflowNoopCallbackTestHandler
             )
  end

  test "recover_step enqueues a workflow-scoped recovery callback payload" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "recovery-session") |> Workflow.insert(TestRepo)

    step = TestRepo.get_by!(Step, workflow_id: workflow.id, step_name: "sync_billing")

    assert {:ok, _step} =
             Workflow.recover_step(TestRepo, workflow.id, :sync_billing, :retry,
               actor_id: "operator-1",
               reason: "retry upstream billing"
             )

    attempt =
      TestRepo.get_by!(RecoveryAttempt,
        workflow_id: workflow.id,
        step_id: step.id,
        status: "completed"
      )

    session = TestRepo.get!(RecoverySession, attempt.recovery_session_id)

    callback =
      TestRepo.get_by!(Callback,
        workflow_id: workflow.id,
        event: "workflow.recovery_completed"
      )

    assert callback.payload["recovery_session_id"] == session.id
  end

  defp insert_callback!(attrs) do
    %Callback{}
    |> Callback.changeset(
      Map.merge(
        %{
          event: "workflow.terminal",
          dedupe_key: Ecto.UUID.generate(),
          status: "pending",
          payload: %{},
          attempts: 0
        },
        Map.new(attrs)
      )
    )
    |> TestRepo.insert!()
  end
end
