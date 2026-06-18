defmodule ObanPowertools.TestRepo.Migrations.Phase55Tables do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    create table(:oban_powertools_job_records, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:oban_job_id, :bigint)
      add(:worker, :string, null: false)
      add(:attempt, :integer, null: false, default: 1)
      add(:status, :string, null: false, default: "ok")
      add(:payload, :map, null: false, default: %{})
      add(:payload_bytes, :integer, null: false, default: 0)
      add(:retention, :string, null: false, default: "standard")
      add(:redacted, :boolean, null: false, default: false)
      add(:summary, :string)
      add(:recorded_at, :utc_datetime_usec, null: false)
      add(:expires_at, :utc_datetime_usec, null: false)

      timestamps(updated_at: false)
    end

    create(
      unique_index(:oban_powertools_job_records, [:oban_job_id, :attempt], concurrently: true)
    )

    create(index(:oban_powertools_job_records, [:worker], concurrently: true))
    create(index(:oban_powertools_job_records, [:status], concurrently: true))
    create(index(:oban_powertools_job_records, [:expires_at], concurrently: true))
  end

  def down do
    drop(table(:oban_powertools_job_records))
  end
end
