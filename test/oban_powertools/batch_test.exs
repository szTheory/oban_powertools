defmodule ObanPowertools.BatchTest do
  use ObanPowertools.DataCase, async: true

  alias ObanPowertools.Batch

  describe "changeset/2" do
    test "validates integer constraints" do
      changeset =
        Batch.changeset(%Batch{}, %{
          status: "executing",
          total_count: -1,
          success_count: -1,
          discard_count: -1,
          cancelled_count: -1,
          snooze_count: -1
        })

      assert %{
               total_count: ["must be greater than or equal to 0"],
               success_count: ["must be greater than or equal to 0"],
               discard_count: ["must be greater than or equal to 0"],
               cancelled_count: ["must be greater than or equal to 0"],
               snooze_count: ["must be greater than or equal to 0"]
             } = errors_on(changeset)
    end

    test "accepts valid params" do
      changeset =
        Batch.changeset(%Batch{}, %{
          status: "completed",
          total_count: 10,
          success_count: 8,
          discard_count: 1,
          cancelled_count: 0,
          snooze_count: 1
        })

      assert changeset.valid?
    end
  end
end
