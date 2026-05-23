defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsHeartbeats do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_heartbeats, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :executor_id, :string, null: false
      add :oban_name, :string, null: false, default: "Oban"
      add :node, :string, null: false
      add :queue, :string, null: false, default: "default"
      add :producer_scope, :string, null: false
      add :health_state, :string, null: false, default: "healthy"
      add :last_heartbeat_at, :utc_datetime_usec, null: false
      add :warning_threshold_ms, :bigint, null: false, default: 45000
      add :missing_threshold_ms, :bigint, null: false, default: 120_000
      add :metadata, :map, null: false, default: %{}

      timestamps()
    end

    create unique_index(:oban_powertools_heartbeats, [:executor_id])
    create index(:oban_powertools_heartbeats, [:health_state])
    create index(:oban_powertools_heartbeats, [:last_heartbeat_at])
  end
end
