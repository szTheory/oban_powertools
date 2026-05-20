defmodule ObanPowertools.Workflow.Edge do
  @moduledoc """
  Durable dependency edge with explicit terminal policy.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_workflow_edges" do
    field(:policy, :string, default: "cancel")
    field(:terminal_snapshot, :map, default: %{})

    belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
    belongs_to(:from_step, ObanPowertools.Workflow.Step, type: :binary_id)
    belongs_to(:to_step, ObanPowertools.Workflow.Step, type: :binary_id)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:workflow_id, :from_step_id, :to_step_id, :policy, :terminal_snapshot])
    |> validate_required([:workflow_id, :from_step_id, :to_step_id, :policy, :terminal_snapshot])
    |> validate_inclusion(:policy, ["cancel", "continue"])
    |> unique_constraint([:workflow_id, :from_step_id, :to_step_id])
  end
end
