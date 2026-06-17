defmodule ObanPowertools.TestRepo.Migrations.Phase3Tables do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
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

    create(unique_index(:oban_powertools_workflows, [:name]))
    create(index(:oban_powertools_workflows, [:state]))

    create table(:oban_powertools_workflow_steps, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :workflow_id,
        references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:step_name, :string, null: false)
      add(:worker, :string, null: false)
      add(:input, :map, null: false, default: %{})
      add(:context, :map, null: false, default: %{})
      add(:state, :string, null: false, default: "pending")
      add(:job_id, :bigint)
      add(:queue, :string, null: false, default: "default")
      add(:attempt, :integer, null: false, default: 0)
      add(:position, :integer, null: false, default: 0)
      add(:dependency_count, :integer, null: false, default: 0)
      add(:dependency_snapshot, :map, null: false, default: %{})
      add(:blocker_codes, {:array, :string}, null: false, default: [])
      add(:blocker_details, :map, null: false, default: %{})
      add(:terminal_cause, :string)
      add(:active_await_id, :uuid)
      add(:awaiting_signal_name, :string)
      add(:await_correlation_key, :string)
      add(:await_dedupe_key, :string)
      add(:await_deadline_at, :utc_datetime_usec)
      add(:cancel_requested_at, :utc_datetime_usec)
      add(:last_transition_at, :utc_datetime_usec)

      add(
        :nested_workflow_id,
        references(:oban_powertools_workflows, type: :uuid, on_delete: :nilify_all)
      )

      add(:started_at, :utc_datetime_usec)
      add(:finished_at, :utc_datetime_usec)
      add(:cancelled_at, :utc_datetime_usec)

      timestamps()
    end

    create(unique_index(:oban_powertools_workflow_steps, [:workflow_id, :step_name]))
    create(index(:oban_powertools_workflow_steps, [:state]))
    create(index(:oban_powertools_workflow_steps, [:job_id]))
    create(index(:oban_powertools_workflow_steps, [:nested_workflow_id]))

    create table(:oban_powertools_workflow_edges, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :workflow_id,
        references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(
        :from_step_id,
        references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(
        :to_step_id,
        references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:policy, :string, null: false, default: "cancel")
      add(:terminal_snapshot, :map, null: false, default: %{})

      timestamps()
    end

    create(
      unique_index(:oban_powertools_workflow_edges, [:workflow_id, :from_step_id, :to_step_id])
    )

    create(index(:oban_powertools_workflow_edges, [:to_step_id]))
    create(index(:oban_powertools_workflow_edges, [:from_step_id]))
    create(index(:oban_powertools_workflow_edges, [:policy]))

    create table(:oban_powertools_workflow_results, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :workflow_id,
        references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(
        :step_id,
        references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:attempt, :integer, null: false, default: 1)
      add(:status, :string, null: false, default: "ok")
      add(:payload, :map, null: false, default: %{})
      add(:payload_bytes, :integer, null: false, default: 0)
      add(:retention, :string, null: false, default: "standard")
      add(:redacted, :boolean, null: false, default: false)
      add(:summary, :string)
      add(:recorded_at, :utc_datetime_usec, null: false)
      add(:expires_at, :utc_datetime_usec)

      timestamps(updated_at: false)
    end

    create(unique_index(:oban_powertools_workflow_results, [:step_id, :attempt]))
    create(index(:oban_powertools_workflow_results, [:workflow_id]))
    create(index(:oban_powertools_workflow_results, [:status]))
    create(index(:oban_powertools_workflow_results, [:expires_at]))

    create table(:oban_powertools_workflow_awaits, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :workflow_id,
        references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(
        :step_id,
        references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:signal_name, :string, null: false)
      add(:correlation_key, :string, null: false)
      add(:dedupe_key, :string, null: false)
      add(:status, :string, null: false, default: "waiting")
      add(:resolution_policy, :string, null: false, default: "ignore_late")
      add(:deadline_at, :utc_datetime_usec)
      add(:resolved_at, :utc_datetime_usec)
      add(:resolved_signal_id, :uuid)

      timestamps(updated_at: false)
    end

    create(index(:oban_powertools_workflow_awaits, [:workflow_id]))
    create(index(:oban_powertools_workflow_awaits, [:signal_name, :correlation_key]))

    create(
      unique_index(:oban_powertools_workflow_awaits, [:step_id, :status],
        name: :oban_powertools_workflow_awaits_step_id_status_index
      )
    )

    create table(:oban_powertools_workflow_signals, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :workflow_id,
        references(:oban_powertools_workflows, type: :uuid, on_delete: :nilify_all)
      )

      add(
        :matched_step_id,
        references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :nilify_all)
      )

      add(
        :await_id,
        references(:oban_powertools_workflow_awaits, type: :uuid, on_delete: :nilify_all)
      )

      add(:signal_name, :string, null: false)
      add(:correlation_key, :string, null: false)
      add(:dedupe_key, :string, null: false)
      add(:status, :string, null: false, default: "recorded")
      add(:payload, :map, null: false, default: %{})
      add(:received_at, :utc_datetime_usec, null: false)

      timestamps(updated_at: false)
    end

    create(
      unique_index(
        :oban_powertools_workflow_signals,
        [:signal_name, :correlation_key, :dedupe_key],
        name: :oban_powertools_workflow_signals_dedupe_index
      )
    )

    create(index(:oban_powertools_workflow_signals, [:workflow_id]))
    create(index(:oban_powertools_workflow_signals, [:status]))
    create(index(:oban_powertools_workflow_signals, [:signal_name, :correlation_key]))

    create table(:oban_powertools_workflow_recovery_sessions, primary_key: false) do
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

    create(index(:oban_powertools_workflow_recovery_sessions, [:workflow_id]))
    create(index(:oban_powertools_workflow_recovery_sessions, [:status]))
    create(index(:oban_powertools_workflow_recovery_sessions, [:requested_at]))

    create table(:oban_powertools_workflow_recovery_attempts, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :workflow_id,
        references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(
        :step_id,
        references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :nilify_all)
      )

      add(:scope, :string, null: false, default: "step")
      add(:action, :string, null: false)
      add(:status, :string, null: false, default: "requested")
      add(:reason, :string)
      add(:actor_id, :string)
      add(:requested_at, :utc_datetime_usec, null: false)
      add(:completed_at, :utc_datetime_usec)
      add(:before_snapshot, :map, null: false, default: %{})
      add(:after_snapshot, :map, null: false, default: %{})
      add(:metadata, :map, null: false, default: %{})

      add(
        :recovery_session_id,
        references(:oban_powertools_workflow_recovery_sessions,
          type: :uuid,
          on_delete: :delete_all
        )
      )

      timestamps(updated_at: false)
    end

    create(index(:oban_powertools_workflow_recovery_attempts, [:workflow_id]))
    create(index(:oban_powertools_workflow_recovery_attempts, [:step_id]))
    create(index(:oban_powertools_workflow_recovery_attempts, [:status]))
    create(index(:oban_powertools_workflow_recovery_attempts, [:recovery_session_id]))

    create table(:oban_powertools_workflow_callback_outbox, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :workflow_id,
        references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(
        :recovery_attempt_id,
        references(:oban_powertools_workflow_recovery_attempts,
          type: :uuid,
          on_delete: :nilify_all
        )
      )

      add(:event, :string, null: false)
      add(:dedupe_key, :string, null: false)
      add(:status, :string, null: false, default: "pending")
      add(:payload, :map, null: false, default: %{})
      add(:attempts, :integer, null: false, default: 0)
      add(:available_at, :utc_datetime_usec)
      add(:claimed_at, :utc_datetime_usec)
      add(:claimed_by, :string)
      add(:lease_expires_at, :utc_datetime_usec)
      add(:delivered_at, :utc_datetime_usec)
      add(:last_error, :string)

      timestamps()
    end

    create(unique_index(:oban_powertools_workflow_callback_outbox, [:dedupe_key]))
    create(index(:oban_powertools_workflow_callback_outbox, [:workflow_id]))
    create(index(:oban_powertools_workflow_callback_outbox, [:status, :available_at]))
    create(index(:oban_powertools_workflow_callback_outbox, [:status, :lease_expires_at]))
    create(index(:oban_powertools_workflow_callback_outbox, [:claimed_by]))
  end

  def down do
    drop(table(:oban_powertools_workflow_callback_outbox))
    drop(table(:oban_powertools_workflow_recovery_attempts))
    drop(table(:oban_powertools_workflow_recovery_sessions))
    drop(table(:oban_powertools_workflow_signals))
    drop(table(:oban_powertools_workflow_awaits))
    drop(table(:oban_powertools_workflow_results))
    drop(table(:oban_powertools_workflow_edges))
    drop(table(:oban_powertools_workflow_steps))
    drop(table(:oban_powertools_workflows))
  end
end
