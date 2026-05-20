defmodule ObanPowertools.Workflow.Step do
  @moduledoc """
  Durable workflow step definition with explicit runtime state.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_workflow_steps" do
    field(:step_name, :string)
    field(:worker, :string)
    field(:input, :map, default: %{})
    field(:context, :map, default: %{})
    field(:state, :string, default: "pending")
    field(:job_id, :integer)
    field(:queue, :string, default: "default")
    field(:attempt, :integer, default: 0)
    field(:position, :integer, default: 0)
    field(:dependency_count, :integer, default: 0)
    field(:dependency_snapshot, :map, default: %{})
    field(:blocker_codes, {:array, :string}, default: [])
    field(:blocker_details, :map, default: %{})
    field(:started_at, :utc_datetime_usec)
    field(:finished_at, :utc_datetime_usec)
    field(:cancelled_at, :utc_datetime_usec)

    belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
    belongs_to(:nested_workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)

    has_many(:results, ObanPowertools.Workflow.Result, foreign_key: :step_id)
    has_many(:outgoing_edges, ObanPowertools.Workflow.Edge, foreign_key: :from_step_id)
    has_many(:incoming_edges, ObanPowertools.Workflow.Edge, foreign_key: :to_step_id)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :workflow_id,
      :step_name,
      :worker,
      :input,
      :context,
      :state,
      :job_id,
      :queue,
      :attempt,
      :position,
      :dependency_count,
      :dependency_snapshot,
      :blocker_codes,
      :blocker_details,
      :nested_workflow_id,
      :started_at,
      :finished_at,
      :cancelled_at
    ])
    |> validate_required([
      :workflow_id,
      :step_name,
      :worker,
      :input,
      :context,
      :state,
      :queue,
      :attempt,
      :position,
      :dependency_count,
      :dependency_snapshot,
      :blocker_codes,
      :blocker_details
    ])
    |> validate_number(:attempt, greater_than_or_equal_to: 0)
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> validate_number(:dependency_count, greater_than_or_equal_to: 0)
    |> unique_constraint([:workflow_id, :step_name])
  end
end
