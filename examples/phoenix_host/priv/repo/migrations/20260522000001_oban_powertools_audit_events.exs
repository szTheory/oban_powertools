defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsAuditEvents do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_audit_events) do
      add :actor_id, :string
      add :action, :string, null: false
      add :resource, :string
      add :metadata, :map, default: %{}

      timestamps(updated_at: false)
    end

    create index(:oban_powertools_audit_events, [:actor_id])
    create index(:oban_powertools_audit_events, [:action])
  end
end
