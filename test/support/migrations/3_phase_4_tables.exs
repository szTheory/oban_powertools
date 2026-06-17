defmodule ObanPowertools.TestRepo.Migrations.Phase4Tables do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    create table(:oban_powertools_heartbeats, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:executor_id, :string, null: false)
      add(:oban_name, :string, null: false, default: "Oban")
      add(:node, :string, null: false)
      add(:queue, :string, null: false, default: "default")
      add(:producer_scope, :string, null: false)
      add(:health_state, :string, null: false, default: "healthy")
      add(:last_heartbeat_at, :utc_datetime_usec, null: false)
      add(:warning_threshold_ms, :bigint, null: false, default: 45_000)
      add(:missing_threshold_ms, :bigint, null: false, default: 120_000)
      add(:metadata, :map, null: false, default: %{})

      timestamps()
    end

    create(unique_index(:oban_powertools_heartbeats, [:executor_id]))
    create(index(:oban_powertools_heartbeats, [:health_state]))
    create(index(:oban_powertools_heartbeats, [:last_heartbeat_at]))

    create table(:oban_powertools_lifeline_incidents, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:incident_class, :string, null: false)
      add(:status, :string, null: false, default: "active")
      add(:executor_id, :string)
      add(:workflow_id, :uuid)
      add(:workflow_step_id, :uuid)
      add(:incident_fingerprint, :string, null: false)
      add(:health_state, :string)
      add(:summary, :string)
      add(:affected_counts, :map, null: false, default: %{})
      add(:evidence, :map, null: false, default: %{})
      add(:first_detected_at, :utc_datetime_usec, null: false)
      add(:last_detected_at, :utc_datetime_usec, null: false)
      add(:resolved_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: %{})

      timestamps()
    end

    create(unique_index(:oban_powertools_lifeline_incidents, [:incident_fingerprint]))
    create(index(:oban_powertools_lifeline_incidents, [:incident_class]))
    create(index(:oban_powertools_lifeline_incidents, [:status]))
    create(index(:oban_powertools_lifeline_incidents, [:health_state]))

    create table(:oban_powertools_repair_previews, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:incident_id, :uuid)
      add(:incident_class, :string, null: false)
      add(:incident_fingerprint, :string, null: false)
      add(:plan_hash, :string, null: false)
      add(:preview_token, :uuid, null: false)
      add(:action, :string, null: false)
      add(:target_type, :string, null: false)
      add(:target_id, :string, null: false)
      add(:health_state, :string)
      add(:status, :string, null: false, default: "pending")
      add(:affected_counts, :map, null: false, default: %{})
      add(:before_snapshot, :map, null: false, default: %{})
      add(:after_snapshot, :map, null: false, default: %{})
      add(:evidence, :map, null: false, default: %{})
      add(:reason_required, :boolean, null: false, default: true)
      add(:executed_at, :utc_datetime_usec)
      add(:consumed_at, :utc_datetime_usec)
      add(:expires_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: %{})

      timestamps()
    end

    create(unique_index(:oban_powertools_repair_previews, [:preview_token]))
    create(index(:oban_powertools_repair_previews, [:incident_class]))
    create(index(:oban_powertools_repair_previews, [:status]))
    create(index(:oban_powertools_repair_previews, [:incident_fingerprint]))
    create(index(:oban_powertools_repair_previews, [:plan_hash]))

    create table(:oban_powertools_archive_runs, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:run_type, :string, null: false)
      add(:status, :string, null: false, default: "pending")
      add(:retention_class, :string, null: false)
      add(:actor_id, :string)
      add(:reason, :string)
      add(:batch_size, :integer, null: false, default: 100)
      add(:archived_count, :integer, null: false, default: 0)
      add(:pruned_count, :integer, null: false, default: 0)
      add(:blocked_count, :integer, null: false, default: 0)
      add(:started_at, :utc_datetime_usec)
      add(:finished_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: %{})

      timestamps()
    end

    create(index(:oban_powertools_archive_runs, [:run_type]))
    create(index(:oban_powertools_archive_runs, [:status]))
    create(index(:oban_powertools_archive_runs, [:retention_class]))
    create(index(:oban_powertools_archive_runs, [:started_at]))

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

  def down do
    drop(table(:oban_powertools_repair_archives))
    drop(table(:oban_powertools_archive_runs))
    drop(table(:oban_powertools_repair_previews))
    drop(table(:oban_powertools_lifeline_incidents))
    drop(table(:oban_powertools_heartbeats))
  end
end
