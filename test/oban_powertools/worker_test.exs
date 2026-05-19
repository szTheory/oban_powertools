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

  test "process/1 receives casted struct" do
    # Manual call to process/1 to check pattern matching
    args = %BasicWorker.Args{user_id: 123, email: "foo@bar.com"}
    job = %Oban.Job{args: args}
    
    assert :ok = BasicWorker.process(job)
    assert_receive {:processed, 123}
  end
end
