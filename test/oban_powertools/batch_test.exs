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

    test "accepts durable insertion metadata" do
      now = DateTime.utc_now()

      changeset =
        Batch.changeset(%Batch{}, %{
          status: "insert_failed",
          total_count: 10,
          success_count: 0,
          discard_count: 0,
          cancelled_count: 0,
          snooze_count: 0,
          name: "import:123",
          inserted_count: 5,
          insert_chunk_count: 2,
          insert_failed_chunk: 3,
          insert_failure: %{"kind" => "database_error"},
          insert_failed_at: now
        })

      assert changeset.valid?
      assert get_change(changeset, :name) == "import:123"
      assert get_change(changeset, :inserted_count) == 5
      assert get_change(changeset, :insert_chunk_count) == 2
      assert get_change(changeset, :insert_failed_chunk) == 3
      assert get_change(changeset, :insert_failure) == %{"kind" => "database_error"}
      assert get_change(changeset, :insert_failed_at) == now
    end

    test "validates insertion metadata counters" do
      changeset =
        Batch.changeset(%Batch{}, %{
          status: "insert_failed",
          total_count: 10,
          success_count: 0,
          discard_count: 0,
          cancelled_count: 0,
          snooze_count: 0,
          inserted_count: -1,
          insert_chunk_count: -1,
          insert_failed_chunk: 0,
          insert_failure: %{}
        })

      assert %{
               inserted_count: ["must be greater than or equal to 0"],
               insert_chunk_count: ["must be greater than or equal to 0"],
               insert_failed_chunk: ["must be greater than 0"]
             } = errors_on(changeset)
    end
  end

  describe "test database schema" do
    test "contains durable insertion metadata columns" do
      columns =
        TestRepo
        |> Ecto.Adapters.SQL.query!(
          """
          SELECT column_name
          FROM information_schema.columns
          WHERE table_name = 'oban_powertools_batches'
          AND column_name = ANY($1)
          """,
          [
            [
              "name",
              "inserted_count",
              "insert_chunk_count",
              "insert_failed_chunk",
              "insert_failure",
              "insert_failed_at"
            ]
          ]
        )
        |> Map.fetch!(:rows)
        |> List.flatten()
        |> MapSet.new()

      assert columns ==
               MapSet.new([
                 "name",
                 "inserted_count",
                 "insert_chunk_count",
                 "insert_failed_chunk",
                 "insert_failure",
                 "insert_failed_at"
               ])
    end
  end
end
