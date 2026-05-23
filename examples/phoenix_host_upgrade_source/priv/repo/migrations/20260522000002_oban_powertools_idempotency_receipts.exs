defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsIdempotencyReceipts do
  use Ecto.Migration

  def change do
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
end
