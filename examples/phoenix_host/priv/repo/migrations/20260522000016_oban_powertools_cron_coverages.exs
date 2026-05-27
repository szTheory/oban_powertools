defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsCronCoverages do
  use Ecto.Migration

  def change do
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
end
