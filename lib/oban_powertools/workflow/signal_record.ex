defmodule ObanPowertools.Workflow.SignalRecord do
  @moduledoc """
  Durable incoming workflow signal fact.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @statuses ["recorded", "consumed", "late", "unmatched", "ambiguous"]

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_workflow_signals" do
    field(:signal_name, :string)
    field(:correlation_key, :string)
    field(:dedupe_key, :string)
    field(:status, :string, default: "recorded")
    field(:payload, :map, default: %{})
    field(:received_at, :utc_datetime_usec)

    belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
    belongs_to(:matched_step, ObanPowertools.Workflow.Step, type: :binary_id)
    belongs_to(:await, ObanPowertools.Workflow.Await, type: :binary_id)

    timestamps(updated_at: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :workflow_id,
      :matched_step_id,
      :await_id,
      :signal_name,
      :correlation_key,
      :dedupe_key,
      :status,
      :payload,
      :received_at
    ])
    |> validate_required([
      :signal_name,
      :correlation_key,
      :dedupe_key,
      :status,
      :payload,
      :received_at
    ])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint([:signal_name, :correlation_key, :dedupe_key],
      name: :oban_powertools_workflow_signals_dedupe_index
    )
  end
end
