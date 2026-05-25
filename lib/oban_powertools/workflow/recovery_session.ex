defmodule ObanPowertools.Workflow.RecoverySession do
  @moduledoc """
  Workflow-scoped recovery session header that groups one or more append-only recovery attempts.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_workflow_recovery_sessions" do
    field(:status, :string, default: "completed")
    field(:trigger, :string, default: "recover_step")
    field(:reason, :string)
    field(:actor_id, :string)
    field(:requested_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)

    has_many(:attempts, ObanPowertools.Workflow.RecoveryAttempt,
      foreign_key: :recovery_session_id
    )

    timestamps(updated_at: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :workflow_id,
      :status,
      :trigger,
      :reason,
      :actor_id,
      :requested_at,
      :completed_at,
      :metadata
    ])
    |> validate_required([
      :workflow_id,
      :status,
      :trigger,
      :requested_at,
      :metadata
    ])
  end
end
