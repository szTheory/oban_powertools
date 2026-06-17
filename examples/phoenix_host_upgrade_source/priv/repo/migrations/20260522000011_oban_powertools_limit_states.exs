defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsLimitStates do
  use Ecto.Migration

  def change do
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
  end
end
