defmodule ObanPowertools.Workflow.Workflow do
  @moduledoc """
  Durable workflow definition plus runtime summary counters.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_workflows" do
    field(:name, :string)
    field(:state, :string, default: "pending")
    field(:workflow_context, :map, default: %{})
    field(:definition_version, :integer, default: 1)
    field(:step_count, :integer, default: 0)
    field(:runnable_step_count, :integer, default: 0)
    field(:completed_step_count, :integer, default: 0)
    field(:cancelled_step_count, :integer, default: 0)
    field(:failed_step_count, :integer, default: 0)
    field(:started_at, :utc_datetime_usec)
    field(:finished_at, :utc_datetime_usec)
    field(:cancelled_at, :utc_datetime_usec)

    has_many(:steps, ObanPowertools.Workflow.Step, foreign_key: :workflow_id)
    has_many(:edges, ObanPowertools.Workflow.Edge, foreign_key: :workflow_id)
    has_many(:results, ObanPowertools.Workflow.Result, foreign_key: :workflow_id)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :name,
      :state,
      :workflow_context,
      :definition_version,
      :step_count,
      :runnable_step_count,
      :completed_step_count,
      :cancelled_step_count,
      :failed_step_count,
      :started_at,
      :finished_at,
      :cancelled_at
    ])
    |> validate_required([:name, :state, :workflow_context, :definition_version])
    |> validate_number(:definition_version, greater_than: 0)
    |> validate_number(:step_count, greater_than_or_equal_to: 0)
    |> validate_number(:runnable_step_count, greater_than_or_equal_to: 0)
    |> validate_number(:completed_step_count, greater_than_or_equal_to: 0)
    |> validate_number(:cancelled_step_count, greater_than_or_equal_to: 0)
    |> validate_number(:failed_step_count, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
  end
end
