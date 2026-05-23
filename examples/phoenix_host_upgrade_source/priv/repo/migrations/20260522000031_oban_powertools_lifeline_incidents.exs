defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsLifelineIncidents do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_lifeline_incidents, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :incident_class, :string, null: false
      add :status, :string, null: false, default: "active"
      add :executor_id, :string
      add :workflow_id, :uuid
      add :workflow_step_id, :uuid
      add :incident_fingerprint, :string, null: false
      add :health_state, :string
      add :summary, :string
      add :affected_counts, :map, null: false, default: %{}
      add :evidence, :map, null: false, default: %{}
      add :first_detected_at, :utc_datetime_usec, null: false
      add :last_detected_at, :utc_datetime_usec, null: false
      add :resolved_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}

      timestamps()
    end

    create unique_index(:oban_powertools_lifeline_incidents, [:incident_fingerprint])
    create index(:oban_powertools_lifeline_incidents, [:incident_class])
    create index(:oban_powertools_lifeline_incidents, [:status])
    create index(:oban_powertools_lifeline_incidents, [:health_state])
  end
end
