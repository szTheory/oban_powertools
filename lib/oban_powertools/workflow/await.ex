defmodule ObanPowertools.Workflow.Await do
  @moduledoc """
  Durable await registration for signal-driven workflow steps.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @statuses ["waiting", "resolved", "expired"]

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_workflow_awaits" do
    field(:signal_name, :string)
    field(:correlation_key, :string)
    field(:dedupe_key, :string)
    field(:status, :string, default: "waiting")
    field(:resolution_policy, :string, default: "ignore_late")
    field(:deadline_at, :utc_datetime_usec)
    field(:resolved_at, :utc_datetime_usec)

    belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
    belongs_to(:step, ObanPowertools.Workflow.Step, type: :binary_id)
    belongs_to(:resolved_signal, ObanPowertools.Workflow.SignalRecord, type: :binary_id)

    timestamps(updated_at: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :workflow_id,
      :step_id,
      :signal_name,
      :correlation_key,
      :dedupe_key,
      :status,
      :resolution_policy,
      :deadline_at,
      :resolved_at,
      :resolved_signal_id
    ])
    |> validate_required([
      :workflow_id,
      :step_id,
      :signal_name,
      :correlation_key,
      :dedupe_key,
      :status,
      :resolution_policy
    ])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:step_id, name: :oban_powertools_workflow_awaits_step_id_status_index)
  end
end
