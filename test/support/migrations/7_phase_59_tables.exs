defmodule ObanPowertools.TestRepo.Migrations.Phase59Tables do
  use Ecto.Migration

  def change do
    rename table(:oban_powertools_workflow_callback_outbox), to: table(:oban_powertools_callbacks)

    alter table(:oban_powertools_callbacks) do
      add :batch_id, :uuid
      modify :workflow_id, :uuid, null: true
    end

    create index(:oban_powertools_callbacks, [:batch_id])

    create table(:oban_powertools_batches, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :status, :string, null: false, default: "executing"
      add :total_count, :integer, null: false, default: 0
      add :success_count, :integer, null: false, default: 0
      add :discard_count, :integer, null: false, default: 0
      add :cancelled_count, :integer, null: false, default: 0
      add :snooze_count, :integer, null: false, default: 0
      add :completed_at, :utc_datetime_usec

      timestamps()
    end

    create table(:oban_powertools_batch_jobs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :batch_id, references(:oban_powertools_batches, type: :uuid, on_delete: :delete_all), null: false
      add :job_id, :bigint, null: false
      add :state, :string, null: false, default: "available"

      timestamps(updated_at: true)
    end

    create unique_index(:oban_powertools_batch_jobs, [:batch_id, :job_id])
    create index(:oban_powertools_batch_jobs, [:job_id])
  end
end
