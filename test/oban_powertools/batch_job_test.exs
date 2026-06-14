defmodule ObanPowertools.BatchJobTest do
  use ObanPowertools.DataCase, async: true

  alias ObanPowertools.BatchJob

  describe "changeset/2" do
    test "uses standard inserted_at and updated_at timestamps" do
      assert :inserted_at in BatchJob.__schema__(:fields)
      assert :updated_at in BatchJob.__schema__(:fields)
      refute true in BatchJob.__schema__(:fields)
    end

    test "validates required fields" do
      changeset = BatchJob.changeset(%BatchJob{}, %{})

      assert %{
               batch_id: ["can't be blank"],
               job_id: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "accepts valid params" do
      changeset =
        BatchJob.changeset(%BatchJob{}, %{
          batch_id: Ecto.UUID.generate(),
          job_id: 12345,
          state: "available"
        })

      assert changeset.valid?
    end
  end
end
