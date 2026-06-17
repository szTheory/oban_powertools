defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsRepairArchives do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_repair_archives, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :archive_run_id,
        references(:oban_powertools_archive_runs, type: :uuid, on_delete: :nilify_all)
      )

      add(:audit_event_id, references(:oban_powertools_audit_events, on_delete: :nilify_all))
      add(:resource_type, :string, null: false)
      add(:resource_id, :string, null: false)
      add(:action, :string, null: false)
      add(:incident_class, :string)
      add(:incident_fingerprint, :string)
      add(:plan_hash, :string)
      add(:reason, :string)
      add(:actor_id, :string)
      add(:affected_counts, :map, null: false, default: %{})
      add(:evidence, :map, null: false, default: %{})
      add(:archived_at, :utc_datetime_usec, null: false)
      add(:metadata, :map, null: false, default: %{})

      timestamps(updated_at: false)
    end

    create(index(:oban_powertools_repair_archives, [:archive_run_id]))
    create(index(:oban_powertools_repair_archives, [:audit_event_id]))
    create(index(:oban_powertools_repair_archives, [:resource_type, :resource_id]))
    create(index(:oban_powertools_repair_archives, [:incident_class]))
    create(index(:oban_powertools_repair_archives, [:archived_at]))
  end
end
