defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsWorkflows do
  use Ecto.Migration
  @disable_ddl_transaction true

  def change do
    create table(:oban_powertools_workflows, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:state, :string, null: false, default: "pending")
      add(:workflow_context, :map, null: false, default: %{})
      add(:definition_version, :integer, null: false, default: 1)
      add(:semantics_version, :integer, null: false, default: 2)
      add(:step_count, :integer, null: false, default: 0)
      add(:runnable_step_count, :integer, null: false, default: 0)
      add(:completed_step_count, :integer, null: false, default: 0)
      add(:cancelled_step_count, :integer, null: false, default: 0)
      add(:failed_step_count, :integer, null: false, default: 0)
      add(:terminal_cause, :string)
      add(:cancel_requested_at, :utc_datetime_usec)
      add(:last_transition_at, :utc_datetime_usec)
      add(:started_at, :utc_datetime_usec)
      add(:finished_at, :utc_datetime_usec)
      add(:cancelled_at, :utc_datetime_usec)

      timestamps()
    end

    create(unique_index(:oban_powertools_workflows, [:name], concurrently: true))
    create(index(:oban_powertools_workflows, [:state], concurrently: true))
  end
end
