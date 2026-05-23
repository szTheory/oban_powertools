defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsRepairPreviews do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_repair_previews, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :incident_id, :uuid
      add :incident_class, :string, null: false
      add :incident_fingerprint, :string, null: false
      add :plan_hash, :string, null: false
      add :preview_token, :uuid, null: false
      add :action, :string, null: false
      add :target_type, :string, null: false
      add :target_id, :string, null: false
      add :health_state, :string
      add :status, :string, null: false, default: "pending"
      add :affected_counts, :map, null: false, default: %{}
      add :before_snapshot, :map, null: false, default: %{}
      add :after_snapshot, :map, null: false, default: %{}
      add :evidence, :map, null: false, default: %{}
      add :reason_required, :boolean, null: false, default: true
      add :executed_at, :utc_datetime_usec
      add :consumed_at, :utc_datetime_usec
      add :expires_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}

      timestamps()
    end

    create unique_index(:oban_powertools_repair_previews, [:preview_token])
    create index(:oban_powertools_repair_previews, [:incident_class])
    create index(:oban_powertools_repair_previews, [:status])
    create index(:oban_powertools_repair_previews, [:incident_fingerprint])
    create index(:oban_powertools_repair_previews, [:plan_hash])
  end
end
