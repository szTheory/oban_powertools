defmodule ObanPowertools.Lifeline.Incident do
  @moduledoc """
  Durable read model for Phase 4 dead-executor and workflow-stuck incidents.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_lifeline_incidents" do
    field(:incident_class, :string)
    field(:status, :string, default: "active")
    field(:executor_id, :string)
    field(:workflow_id, Ecto.UUID)
    field(:workflow_step_id, Ecto.UUID)
    field(:incident_fingerprint, :string)
    field(:health_state, :string)
    field(:summary, :string)
    field(:affected_counts, :map, default: %{})
    field(:evidence, :map, default: %{})
    field(:first_detected_at, :utc_datetime_usec)
    field(:last_detected_at, :utc_datetime_usec)
    field(:resolved_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :incident_class,
      :status,
      :executor_id,
      :workflow_id,
      :workflow_step_id,
      :incident_fingerprint,
      :health_state,
      :summary,
      :affected_counts,
      :evidence,
      :first_detected_at,
      :last_detected_at,
      :resolved_at,
      :metadata
    ])
    |> validate_required([
      :incident_class,
      :status,
      :incident_fingerprint,
      :affected_counts,
      :evidence,
      :first_detected_at,
      :last_detected_at,
      :metadata
    ])
    |> unique_constraint(:incident_fingerprint)
  end
end
