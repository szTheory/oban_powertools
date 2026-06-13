defmodule ObanPowertools.TestRepo.Migrations.Phase6Tables do
  use Ecto.Migration

  def up do
    alter table(:oban_powertools_workflow_callback_outbox) do
      add_if_not_exists(:claimed_at, :utc_datetime_usec)
      add_if_not_exists(:claimed_by, :string)
      add_if_not_exists(:lease_expires_at, :utc_datetime_usec)
    end

    create_if_not_exists(
      index(:oban_powertools_workflow_callback_outbox, [:status, :lease_expires_at])
    )

    create_if_not_exists(index(:oban_powertools_workflow_callback_outbox, [:claimed_by]))

    create_if_not_exists table(:oban_powertools_workflow_recovery_sessions, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :workflow_id,
        references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:status, :string, null: false, default: "completed")
      add(:trigger, :string, null: false, default: "recover_step")
      add(:reason, :string)
      add(:actor_id, :string)
      add(:requested_at, :utc_datetime_usec, null: false)
      add(:completed_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: %{})

      timestamps(updated_at: false)
    end

    create_if_not_exists(index(:oban_powertools_workflow_recovery_sessions, [:workflow_id]))
    create_if_not_exists(index(:oban_powertools_workflow_recovery_sessions, [:status]))
    create_if_not_exists(index(:oban_powertools_workflow_recovery_sessions, [:requested_at]))

    create_if_not_exists(
      index(:oban_powertools_workflow_recovery_attempts, [:recovery_session_id])
    )
  end
end
