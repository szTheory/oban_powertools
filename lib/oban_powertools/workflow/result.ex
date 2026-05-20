defmodule ObanPowertools.Workflow.Result do
  @moduledoc """
  Durable workflow step result evidence with bounded payload metadata.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_workflow_results" do
    field(:attempt, :integer, default: 1)
    field(:status, :string, default: "ok")
    field(:payload, :map, default: %{})
    field(:payload_bytes, :integer, default: 0)
    field(:retention, :string, default: "standard")
    field(:redacted, :boolean, default: false)
    field(:summary, :string)
    field(:recorded_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)

    belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
    belongs_to(:step, ObanPowertools.Workflow.Step, type: :binary_id)

    timestamps(updated_at: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :workflow_id,
      :step_id,
      :attempt,
      :status,
      :payload,
      :payload_bytes,
      :retention,
      :redacted,
      :summary,
      :recorded_at,
      :expires_at
    ])
    |> validate_required([
      :workflow_id,
      :step_id,
      :attempt,
      :status,
      :payload,
      :payload_bytes,
      :retention,
      :redacted,
      :recorded_at
    ])
    |> validate_number(:attempt, greater_than: 0)
    |> validate_number(:payload_bytes, greater_than_or_equal_to: 0)
    |> unique_constraint([:step_id, :attempt])
  end
end
