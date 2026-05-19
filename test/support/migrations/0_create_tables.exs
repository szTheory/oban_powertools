defmodule ObanPowertools.TestRepo.Migrations.CreateTables do
  use Ecto.Migration

  def up do
    Oban.Migrations.up()

    create table(:oban_powertools_audit_events) do
      add :actor_id, :string
      add :action, :string, null: false
      add :resource, :string
      add :metadata, :map, default: %{}

      timestamps(updated_at: false)
    end
    
    create index(:oban_powertools_audit_events, [:actor_id])
    create index(:oban_powertools_audit_events, [:action])

    create table(:oban_powertools_idempotency_receipts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :worker, :string, null: false
      add :fingerprint, :string, null: false
      add :job_id, :bigint
      add :state, :string, null: false
      add :expires_at, :utc_datetime

      timestamps()
    end

    create unique_index(:oban_powertools_idempotency_receipts, [:worker, :fingerprint])
    create index(:oban_powertools_idempotency_receipts, [:job_id])
  end

  def down do
    Oban.Migrations.down()
    drop table(:oban_powertools_audit_events)
    drop table(:oban_powertools_idempotency_receipts)
  end
end
