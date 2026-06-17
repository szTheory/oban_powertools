defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsAuditEvents do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_audit_events) do
      add(:actor_id, :string)
      add(:action, :string, null: false)
      add(:command_key, :string)
      add(:event_type, :string)
      add(:resource, :string)
      add(:resource_type, :string)
      add(:resource_id, :string)
      add(:metadata, :map, default: %{})

      timestamps(updated_at: false)
    end

    create(index(:oban_powertools_audit_events, [:actor_id]))
    create(index(:oban_powertools_audit_events, [:action]))
    create(index(:oban_powertools_audit_events, [:event_type]))
    create(index(:oban_powertools_audit_events, [:resource_type, :resource_id]))
  end
end
