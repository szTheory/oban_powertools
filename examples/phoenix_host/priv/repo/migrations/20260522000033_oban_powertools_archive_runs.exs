defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsArchiveRuns do
  use Ecto.Migration
  @disable_ddl_transaction true
        @disable_migration_lock true

  def change do
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

    create(index(:oban_powertools_archive_runs, [:run_type], concurrently: true))
    create(index(:oban_powertools_archive_runs, [:status], concurrently: true))
    create(index(:oban_powertools_archive_runs, [:retention_class], concurrently: true))
    create(index(:oban_powertools_archive_runs, [:started_at], concurrently: true))
  end
end
