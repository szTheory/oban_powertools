defmodule ObanPowertools.TestRepo.Migrations.Phase3Tables do
  use Ecto.Migration

  def up do
    create table(:oban_powertools_workflows, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:state, :string, null: false, default: "pending")
      add(:workflow_context, :map, null: false, default: %{})
      add(:definition_version, :integer, null: false, default: 1)
      add(:step_count, :integer, null: false, default: 0)
      add(:runnable_step_count, :integer, null: false, default: 0)
      add(:completed_step_count, :integer, null: false, default: 0)
      add(:cancelled_step_count, :integer, null: false, default: 0)
      add(:failed_step_count, :integer, null: false, default: 0)
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

    create(unique_index(:oban_powertools_workflow_edges, [:workflow_id, :from_step_id, :to_step_id]))
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
  end

  def down do
    drop(table(:oban_powertools_workflow_results))
    drop(table(:oban_powertools_workflow_edges))
    drop(table(:oban_powertools_workflow_steps))
    drop(table(:oban_powertools_workflows))
  end
end
