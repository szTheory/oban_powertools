defmodule ObanPowertools.CallbackTest do
  use ObanPowertools.DataCase, async: true

  alias ObanPowertools.Callback

  describe "changeset/2" do
    test "validates required fields" do
      changeset = Callback.changeset(%Callback{}, %{})

      assert %{
               event: ["can't be blank"],
               dedupe_key: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "does not require workflow_id or batch_id" do
      changeset = Callback.changeset(%Callback{}, %{
        event: "batch.completed",
        dedupe_key: "batch_1_completed",
        status: "pending",
        payload: %{},
        attempts: 0
      })

      assert changeset.valid?
    end

    test "validates allowed events" do
      changeset = Callback.changeset(%Callback{}, %{
        event: "unknown.event",
        dedupe_key: "key",
        status: "pending",
        payload: %{},
        attempts: 0
      })

      assert %{event: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid params" do
      changeset =
        Callback.changeset(%Callback{}, %{
          batch_id: Ecto.UUID.generate(),
          event: "batch.exhausted",
          dedupe_key: "batch_2_exhausted",
          status: "pending",
          payload: %{},
          attempts: 0
        })

      assert changeset.valid?
    end
  end
end
