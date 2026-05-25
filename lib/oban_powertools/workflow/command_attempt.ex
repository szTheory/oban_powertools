defmodule ObanPowertools.Workflow.CommandAttempt do
  @moduledoc """
  Durable accepted and rejected workflow command evidence.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_workflow_command_attempts" do
    field(:scope, :string, default: "workflow")
    field(:action, :string)
    field(:status, :string, default: "completed")
    field(:reason_code, :string)
    field(:reason_message, :string)
    field(:actor_id, :string)
    field(:source, :string, default: "runtime")
    field(:requested_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)
    field(:before_snapshot, :map, default: %{})
    field(:after_snapshot, :map, default: %{})
    field(:metadata, :map, default: %{})

    belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
    belongs_to(:step, ObanPowertools.Workflow.Step, type: :binary_id)
    belongs_to(:signal_record, ObanPowertools.Workflow.SignalRecord, type: :binary_id)

    timestamps(updated_at: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :workflow_id,
      :step_id,
      :signal_record_id,
      :scope,
      :action,
      :status,
      :reason_code,
      :reason_message,
      :actor_id,
      :source,
      :requested_at,
      :completed_at,
      :before_snapshot,
      :after_snapshot,
      :metadata
    ])
    |> validate_required([
      :scope,
      :action,
      :status,
      :source,
      :requested_at,
      :before_snapshot,
      :after_snapshot,
      :metadata
    ])
  end
end
