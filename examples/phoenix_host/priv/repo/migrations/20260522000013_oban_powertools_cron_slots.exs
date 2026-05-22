defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsCronSlots do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_cron_slots, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :entry_id,
          references(:oban_powertools_cron_entries, type: :uuid, on_delete: :delete_all),
          null: false

      add :slot_at, :utc_datetime_usec, null: false
      add :state, :string, null: false, default: "pending"
      add :job_id, :bigint
      add :claim_token, :uuid
      add :claimed_at, :utc_datetime_usec
      add :finished_at, :utc_datetime_usec
      add :attempt_count, :integer, null: false, default: 0
      add :policy_snapshot, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}

      timestamps()
    end

    create unique_index(:oban_powertools_cron_slots, [:entry_id, :slot_at])
    create index(:oban_powertools_cron_slots, [:state])
    create index(:oban_powertools_cron_slots, [:job_id])
  end
end
