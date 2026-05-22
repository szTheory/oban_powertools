defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsWorkflowResults do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_workflow_results, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :workflow_id,
          references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all), null: false

      add :step_id,
          references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :delete_all),
          null: false

      add :attempt, :integer, null: false, default: 1
      add :status, :string, null: false, default: "ok"
      add :payload, :map, null: false, default: %{}
      add :payload_bytes, :integer, null: false, default: 0
      add :retention, :string, null: false, default: "standard"
      add :redacted, :boolean, null: false, default: false
      add :summary, :string
      add :recorded_at, :utc_datetime_usec, null: false
      add :expires_at, :utc_datetime_usec

      timestamps(updated_at: false)
    end

    create unique_index(:oban_powertools_workflow_results, [:step_id, :attempt])
    create index(:oban_powertools_workflow_results, [:workflow_id])
    create index(:oban_powertools_workflow_results, [:status])
    create index(:oban_powertools_workflow_results, [:expires_at])
  end
end
