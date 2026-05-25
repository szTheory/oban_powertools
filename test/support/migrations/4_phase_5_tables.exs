defmodule ObanPowertools.TestRepo.Migrations.Phase5Tables do
  use Ecto.Migration

  def up do
    create table(:oban_powertools_workflow_command_attempts, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :workflow_id,
        references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all)
      )

      add(
        :step_id,
        references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :nilify_all)
      )

      add(
        :signal_record_id,
        references(:oban_powertools_workflow_signals, type: :uuid, on_delete: :nilify_all)
      )

      add(:scope, :string, null: false, default: "workflow")
      add(:action, :string, null: false)
      add(:status, :string, null: false, default: "completed")
      add(:reason_code, :string)
      add(:reason_message, :string)
      add(:actor_id, :string)
      add(:source, :string, null: false, default: "runtime")
      add(:requested_at, :utc_datetime_usec, null: false)
      add(:completed_at, :utc_datetime_usec)
      add(:before_snapshot, :map, null: false, default: %{})
      add(:after_snapshot, :map, null: false, default: %{})
      add(:metadata, :map, null: false, default: %{})

      timestamps(updated_at: false)
    end

    create(index(:oban_powertools_workflow_command_attempts, [:workflow_id]))
    create(index(:oban_powertools_workflow_command_attempts, [:step_id]))
    create(index(:oban_powertools_workflow_command_attempts, [:signal_record_id]))
    create(index(:oban_powertools_workflow_command_attempts, [:scope, :action]))
    create(index(:oban_powertools_workflow_command_attempts, [:status]))
    create(index(:oban_powertools_workflow_command_attempts, [:reason_code]))
    create(index(:oban_powertools_workflow_command_attempts, [:requested_at]))
  end

  def down do
    drop(table(:oban_powertools_workflow_command_attempts))
  end
end
