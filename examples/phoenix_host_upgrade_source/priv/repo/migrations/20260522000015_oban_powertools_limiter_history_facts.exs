defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsLimiterHistoryFacts do
  use Ecto.Migration

  def change do
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
  end
end
