defmodule ObanPowertools.Lifeline.RepairPreview do
  @moduledoc """
  Durable preview token and drift boundary for native operator mutations.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @statuses ~w(ready drifted expired consumed)

  schema "oban_powertools_repair_previews" do
    field(:incident_id, Ecto.UUID)
    field(:incident_class, :string)
    field(:incident_fingerprint, :string)
    field(:plan_hash, :string)
    field(:preview_token, Ecto.UUID)
    field(:action, :string)
    field(:target_type, :string)
    field(:target_id, :string)
    field(:health_state, :string)
    field(:status, :string, default: "ready")
    field(:affected_counts, :map, default: %{})
    field(:before_snapshot, :map, default: %{})
    field(:after_snapshot, :map, default: %{})
    field(:evidence, :map, default: %{})
    field(:reason_required, :boolean, default: true)
    field(:executed_at, :utc_datetime_usec)
    field(:consumed_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :incident_id,
      :incident_class,
      :incident_fingerprint,
      :plan_hash,
      :preview_token,
      :action,
      :target_type,
      :target_id,
      :health_state,
      :status,
      :affected_counts,
      :before_snapshot,
      :after_snapshot,
      :evidence,
      :reason_required,
      :executed_at,
      :consumed_at,
      :expires_at,
      :metadata
    ])
    |> validate_required([
      :incident_class,
      :incident_fingerprint,
      :plan_hash,
      :preview_token,
      :action,
      :target_type,
      :target_id,
      :status,
      :affected_counts,
      :before_snapshot,
      :after_snapshot,
      :evidence,
      :reason_required,
      :metadata
    ])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:preview_token)
  end

  def statuses, do: @statuses

  def canonical_status("pending"), do: "ready"
  def canonical_status("executed"), do: "consumed"
  def canonical_status(status) when status in @statuses, do: status
  def canonical_status(_status), do: "ready"

  def execute_status(preview, now \\ DateTime.utc_now())

  def execute_status(%__MODULE__{consumed_at: consumed_at}, _now) when not is_nil(consumed_at),
    do: {:error, :preview_consumed}

  def execute_status(%__MODULE__{status: status}, _now) when status in ["consumed", "executed"],
    do: {:error, :preview_consumed}

  def execute_status(%__MODULE__{status: "drifted"}, _now), do: {:error, :preview_drifted}
  def execute_status(%__MODULE__{status: "expired"}, _now), do: {:error, :preview_expired}

  def execute_status(%__MODULE__{expires_at: %DateTime{} = expires_at}, %DateTime{} = now) do
    if DateTime.compare(expires_at, now) == :lt, do: {:error, :preview_expired}, else: :ok
  end

  def execute_status(_preview, _now), do: :ok
end
