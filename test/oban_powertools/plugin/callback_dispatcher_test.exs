defmodule ObanPowertools.Plugin.CallbackDispatcherTest do
  use ObanPowertools.DataCase, async: false

  import Ecto.Query

  alias ObanPowertools.Callback
  alias ObanPowertools.Plugin.CallbackDispatcher

  defmodule PoisonWorker do
    use ObanPowertools.Worker, queue: :default
    def process(_job), do: :ok
  end

  setup do
    conf = Oban.Config.new(repo: TestRepo, testing: :manual)
    
    {:ok, pid} =
      start_supervised(
        {CallbackDispatcher, conf: conf, name: Oban, interval: 60_000}
      )

    %{conf: conf, dispatcher_pid: pid}
  end

  describe "polling callbacks" do
    test "processes chain.step_succeeded callbacks successfully", %{dispatcher_pid: pid} do
      callback = insert_callback!("chain.step_succeeded", %{
        "event" => "chain.step_succeeded",
        "batch_id" => Ecto.UUID.generate(),
        "chain_id" => Ecto.UUID.generate(),
        "step_name" => "fetch",
        "step_index" => 0,
        "step_count" => 2,
        "upstream_job_id" => 101,
        "next_step" => nil
      })

      send(pid, :poll)
      # Give it a moment to process the message
      :sys.get_state(pid)

      delivered = TestRepo.get!(Callback, callback.id)
      assert delivered.status == "delivered"
      assert delivered.attempts == 1
    end

    test "processes batch.completed callbacks successfully", %{dispatcher_pid: pid} do
      callback = insert_callback!("batch.completed", %{
        "batch_id" => Ecto.UUID.generate()
      })

      send(pid, :poll)
      :sys.get_state(pid)

      delivered = TestRepo.get!(Callback, callback.id)
      assert delivered.status == "delivered"
      assert delivered.attempts == 1
    end

    test "handles poison pill callbacks by marking them as failed and continuing", %{dispatcher_pid: pid} do
      # Insert a poison pill (e.g. invalid next_step that will crash dispatching)
      poison = insert_callback!("chain.step_succeeded", %{
        "event" => "chain.step_succeeded",
        "batch_id" => Ecto.UUID.generate(),
        "chain_id" => Ecto.UUID.generate(),
        "step_name" => "fetch",
        "step_index" => 0,
        "step_count" => 2,
        "upstream_job_id" => 102,
        "next_step" => "this is totally invalid and should cause a crash in the domain logic"
      })

      # Insert a valid one after it to ensure it continues processing
      valid = insert_callback!("batch.completed", %{
        "batch_id" => Ecto.UUID.generate()
      })

      send(pid, :poll)
      :sys.get_state(pid)

      failed = TestRepo.get!(Callback, poison.id)
      assert failed.status == "failed"
      assert failed.attempts == 1
      assert is_binary(failed.last_error)
      assert is_nil(failed.lease_expires_at)

      delivered = TestRepo.get!(Callback, valid.id)
      assert delivered.status == "delivered"
      assert delivered.attempts == 1
    end
  end

  defp insert_callback!(event, payload) do
    %Callback{}
    |> Callback.changeset(%{
      batch_id: Map.get(payload, "batch_id", Ecto.UUID.generate()),
      event: event,
      dedupe_key: "#{event}:#{Ecto.UUID.generate()}",
      status: "pending",
      payload: payload,
      attempts: 0
    })
    |> TestRepo.insert!()
  end
end
