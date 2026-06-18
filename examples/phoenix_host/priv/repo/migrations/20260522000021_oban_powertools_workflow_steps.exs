defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsWorkflowSteps do
  use Ecto.Migration
  @disable_ddl_transaction true
        @disable_migration_lock true

  def change do
    create table(:oban_powertools_workflow_steps, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :workflow_id,
        references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all), null: false)

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

    create(
      unique_index(:oban_powertools_workflow_steps, [:workflow_id, :step_name],
        concurrently: true
      )
    )

    create(index(:oban_powertools_workflow_steps, [:state], concurrently: true))
    create(index(:oban_powertools_workflow_steps, [:job_id], concurrently: true))
    create(index(:oban_powertools_workflow_steps, [:nested_workflow_id], concurrently: true))
  end
end
