defmodule ObanPowertools.Workflow.RecoveryAttempt do
  @moduledoc """
  Durable workflow recovery request and outcome evidence.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_workflow_recovery_attempts" do
    field(:scope, :string, default: "step")
    field(:action, :string)
    field(:status, :string, default: "requested")
    field(:reason, :string)
    field(:actor_id, :string)
    field(:requested_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)
    field(:before_snapshot, :map, default: %{})
    field(:after_snapshot, :map, default: %{})
    field(:metadata, :map, default: %{})

    belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
    belongs_to(:step, ObanPowertools.Workflow.Step, type: :binary_id)
    belongs_to(:recovery_session, ObanPowertools.Workflow.RecoverySession, type: :binary_id)

    timestamps(updated_at: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :workflow_id,
      :step_id,
      :scope,
      :action,
      :status,
      :reason,
      :actor_id,
      :requested_at,
      :completed_at,
      :before_snapshot,
      :after_snapshot,
      :metadata,
      :recovery_session_id
    ])
    |> validate_required([
      :workflow_id,
      :scope,
      :action,
      :status,
      :requested_at,
      :before_snapshot,
      :after_snapshot,
      :metadata
    ])
  end
end
