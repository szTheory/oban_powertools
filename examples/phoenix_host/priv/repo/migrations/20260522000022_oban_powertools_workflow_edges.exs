defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsWorkflowEdges do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_workflow_edges, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :workflow_id,
          references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all), null: false

      add :from_step_id,
          references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :delete_all),
          null: false

      add :to_step_id,
          references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :delete_all),
          null: false

      add :policy, :string, null: false, default: "cancel"
      add :terminal_snapshot, :map, null: false, default: %{}

      timestamps()
    end

    create unique_index(:oban_powertools_workflow_edges, [
             :workflow_id,
             :from_step_id,
             :to_step_id
           ])

    create index(:oban_powertools_workflow_edges, [:to_step_id])
    create index(:oban_powertools_workflow_edges, [:from_step_id])
    create index(:oban_powertools_workflow_edges, [:policy])
  end
end
