defmodule ObanPowertools.TestRepo.Migrations.Phase2Tables do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    create table(:oban_powertools_limit_resources, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:scope_kind, :string, null: false)
      add(:algorithm, :string, null: false)
      add(:bucket_span_ms, :bigint, null: false)
      add(:bucket_capacity, :integer, null: false)
      add(:default_weight, :integer, null: false, default: 1)
      add(:partition_strategy, :string, null: false, default: "global")
      add(:partition_config, :map, null: false, default: %{})
      add(:cooldown_enabled, :boolean, null: false, default: true)
      add(:metadata, :map, null: false, default: %{})

      timestamps()
    end

    create(unique_index(:oban_powertools_limit_resources, [:name]))
    create(index(:oban_powertools_limit_resources, [:scope_kind]))
    create(index(:oban_powertools_limit_resources, [:algorithm]))

    create table(:oban_powertools_limit_states, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :resource_id,
        references(:oban_powertools_limit_resources, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:partition_key, :string, null: false, default: "__global__")
      add(:tokens_used, :integer, null: false, default: 0)
      add(:bucket_started_at, :utc_datetime_usec, null: false)
      add(:last_reserved_at, :utc_datetime_usec)
      add(:cooldown_until, :utc_datetime_usec)
      add(:cooldown_reason, :string)
      add(:reservation_snapshot, :map, null: false, default: %{})

      timestamps()
    end

    create(unique_index(:oban_powertools_limit_states, [:resource_id, :partition_key]))
    create(index(:oban_powertools_limit_states, [:cooldown_until]))

    create table(:oban_powertools_cron_entries, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:source, :string, null: false)
      add(:worker, :string, null: false)
      add(:queue, :string, null: false, default: "default")
      add(:expression, :string, null: false)
      add(:timezone, :string, null: false, default: "Etc/UTC")
      add(:args, :map, null: false, default: %{})
      add(:opts, :map, null: false, default: %{})
      add(:overlap_policy, :string, null: false, default: "queue_one")
      add(:catch_up_policy, :string, null: false, default: "latest")
      add(:max_catch_up, :integer, null: false, default: 1)
      add(:paused_at, :utc_datetime_usec)
      add(:last_run_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: %{})

      timestamps()
    end

    create(unique_index(:oban_powertools_cron_entries, [:name]))
    create(index(:oban_powertools_cron_entries, [:source]))
    create(index(:oban_powertools_cron_entries, [:paused_at]))

    create table(:oban_powertools_cron_slots, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :entry_id,
        references(:oban_powertools_cron_entries, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:slot_at, :utc_datetime_usec, null: false)
      add(:state, :string, null: false, default: "pending")
      add(:job_id, :bigint)
      add(:claim_token, :uuid)
      add(:claimed_at, :utc_datetime_usec)
      add(:finished_at, :utc_datetime_usec)
      add(:attempt_count, :integer, null: false, default: 0)
      add(:policy_snapshot, :map, null: false, default: %{})
      add(:metadata, :map, null: false, default: %{})

      timestamps()
    end

    create(unique_index(:oban_powertools_cron_slots, [:entry_id, :slot_at]))
    create(index(:oban_powertools_cron_slots, [:state]))
    create(index(:oban_powertools_cron_slots, [:job_id]))

    create table(:oban_powertools_blocker_snapshots, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:job_id, :bigint, null: false)
      add(:worker, :string, null: false)
      add(:status, :string, null: false, default: "blocked")
      add(:scope_kind, :string, null: false)
      add(:scope_id, :string, null: false)
      add(:blocker_codes, {:array, :string}, null: false, default: [])
      add(:details, :map, null: false, default: %{})
      add(:captured_at, :utc_datetime_usec, null: false)

      timestamps(updated_at: false)
    end

    create(index(:oban_powertools_blocker_snapshots, [:job_id]))
    create(index(:oban_powertools_blocker_snapshots, [:worker]))
    create(index(:oban_powertools_blocker_snapshots, [:scope_kind, :scope_id]))

    create table(:oban_powertools_limiter_history_facts, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:resource_name, :string, null: false)
      add(:partition_key, :string, null: false, default: "__global__")
      add(:event_type, :string, null: false)
      add(:cause_kind, :string)
      add(:occurred_at, :utc_datetime_usec, null: false)
      add(:eligible_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: %{})

      timestamps(updated_at: false)
    end

    create(index(:oban_powertools_limiter_history_facts, [:resource_name, :occurred_at]))
    create(index(:oban_powertools_limiter_history_facts, [:event_type]))

    create table(:oban_powertools_cron_coverages, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :entry_id,
        references(:oban_powertools_cron_entries, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:slot_at, :utc_datetime_usec, null: false)
      add(:status, :string, null: false, default: "healthy")
      add(:metadata, :map, null: false, default: %{})

      timestamps(updated_at: false)
    end

    create(unique_index(:oban_powertools_cron_coverages, [:entry_id, :slot_at]))
    create(index(:oban_powertools_cron_coverages, [:status]))
  end

  def down do
    drop(table(:oban_powertools_cron_coverages))
    drop(table(:oban_powertools_limiter_history_facts))
    drop(table(:oban_powertools_blocker_snapshots))
    drop(table(:oban_powertools_cron_slots))
    drop(table(:oban_powertools_cron_entries))
    drop(table(:oban_powertools_limit_states))
    drop(table(:oban_powertools_limit_resources))
  end
end
