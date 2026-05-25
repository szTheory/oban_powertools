defmodule ObanPowertools.Workflow.CallbackOutbox do
  @moduledoc """
  Durable workflow callback outbox row.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_workflow_callback_outbox" do
    field(:event, :string)
    field(:dedupe_key, :string)
    field(:status, :string, default: "pending")
    field(:payload, :map, default: %{})
    field(:attempts, :integer, default: 0)
    field(:available_at, :utc_datetime_usec)
    field(:claimed_at, :utc_datetime_usec)
    field(:claimed_by, :string)
    field(:lease_expires_at, :utc_datetime_usec)
    field(:delivered_at, :utc_datetime_usec)
    field(:last_error, :string)

    belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
    belongs_to(:recovery_attempt, ObanPowertools.Workflow.RecoveryAttempt, type: :binary_id)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :workflow_id,
      :recovery_attempt_id,
      :event,
      :dedupe_key,
      :status,
      :payload,
      :attempts,
      :available_at,
      :claimed_at,
      :claimed_by,
      :lease_expires_at,
      :delivered_at,
      :last_error
    ])
    |> validate_required([
      :workflow_id,
      :event,
      :dedupe_key,
      :status,
      :payload,
      :attempts
    ])
    |> validate_inclusion(:event, ["workflow.terminal", "workflow.recovery_completed"])
    |> validate_number(:attempts, greater_than_or_equal_to: 0)
    |> unique_constraint(:dedupe_key)
  end
end
