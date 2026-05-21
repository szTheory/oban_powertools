defmodule Mix.Tasks.ObanPowertools.InstallTest do
  use ExUnit.Case

  test "defines an igniter task" do
    Code.ensure_loaded?(Mix.Tasks.ObanPowertools.Install)
    assert function_exported?(Mix.Tasks.ObanPowertools.Install, :igniter, 1)
  end

  test "installer defines the idempotency receipts migration contract" do
    source =
      "lib/mix/tasks/oban_powertools.install.ex"
      |> File.read!()

    assert source =~ "create table(:oban_powertools_idempotency_receipts, primary_key: false)"
    assert source =~ "add :worker, :string, null: false"
    assert source =~ "add :fingerprint, :string, null: false"
    assert source =~ "add :job_id, :bigint"
    assert source =~ "add :state, :string, null: false"
    assert source =~ "add :expires_at, :utc_datetime"

    assert source =~
             "create unique_index(:oban_powertools_idempotency_receipts, [:worker, :fingerprint])"
  end

  test "installer defines the smart-engine persistence contract" do
    source =
      "lib/mix/tasks/oban_powertools.install.ex"
      |> File.read!()

    assert source =~ "create table(:oban_powertools_limit_resources, primary_key: false)"
    assert source =~ "create table(:oban_powertools_limit_states, primary_key: false)"
    assert source =~ "create table(:oban_powertools_cron_entries, primary_key: false)"
    assert source =~ "create table(:oban_powertools_cron_slots, primary_key: false)"
    assert source =~ "create table(:oban_powertools_blocker_snapshots, primary_key: false)"

    assert source =~ "create unique_index(:oban_powertools_limit_resources, [:name])"

    assert source =~
             "create unique_index(:oban_powertools_limit_states, [:resource_id, :partition_key])"

    assert source =~ "create unique_index(:oban_powertools_cron_entries, [:name])"
    assert source =~ "create unique_index(:oban_powertools_cron_slots, [:entry_id, :slot_at])"
  end

  test "installer defines the workflow persistence contract" do
    source =
      "lib/mix/tasks/oban_powertools.install.ex"
      |> File.read!()

    assert source =~ "create table(:oban_powertools_workflows, primary_key: false)"
    assert source =~ "add :name, :string, null: false"
    assert source =~ "add :state, :string, null: false, default: \"pending\""
    assert source =~ "add :workflow_context, :map, null: false, default: %{}"
    assert source =~ "add :definition_version, :integer, null: false, default: 1"

    assert source =~ "create table(:oban_powertools_workflow_steps, primary_key: false)"
    assert source =~ "add :step_name, :string, null: false"
    assert source =~ "add :worker, :string, null: false"
    assert source =~ "add :input, :map, null: false, default: %{}"
    assert source =~ "add :context, :map, null: false, default: %{}"
    assert source =~ "add :position, :integer, null: false, default: 0"
    assert source =~ "add :dependency_snapshot, :map, null: false, default: %{}"

    assert source =~ "create table(:oban_powertools_workflow_edges, primary_key: false)"
    assert source =~ "add :policy, :string, null: false, default: \"cancel\""
    assert source =~ "add :terminal_snapshot, :map, null: false, default: %{}"

    assert source =~ "create table(:oban_powertools_workflow_results, primary_key: false)"
    assert source =~ "add :payload, :map, null: false, default: %{}"
    assert source =~ "add :payload_bytes, :integer, null: false, default: 0"
    assert source =~ "add :retention, :string, null: false, default: \"standard\""
    assert source =~ "add :redacted, :boolean, null: false, default: false"

    assert source =~ "create unique_index(:oban_powertools_workflows, [:name])"

    assert source =~
             "create unique_index(:oban_powertools_workflow_steps, [:workflow_id, :step_name])"

    assert source =~
             "create unique_index(:oban_powertools_workflow_edges, [:workflow_id, :from_step_id, :to_step_id])"

    assert source =~
             "create unique_index(:oban_powertools_workflow_results, [:step_id, :attempt])"
  end

  test "installer defines the phase 4 lifeline persistence contract" do
    source =
      "lib/mix/tasks/oban_powertools.install.ex"
      |> File.read!()

    assert source =~ "create table(:oban_powertools_heartbeats, primary_key: false)"
    assert source =~ "add :executor_id, :string, null: false"
    assert source =~ "add :last_heartbeat_at, :utc_datetime_usec, null: false"
    assert source =~ "create table(:oban_powertools_lifeline_incidents, primary_key: false)"
    assert source =~ "add :incident_class, :string, null: false"
    assert source =~ "add :incident_fingerprint, :string, null: false"
    assert source =~ "create table(:oban_powertools_repair_previews, primary_key: false)"
    assert source =~ "add :plan_hash, :string, null: false"
    assert source =~ "add :preview_token, :uuid, null: false"
    assert source =~ "create table(:oban_powertools_archive_runs, primary_key: false)"
    assert source =~ "create table(:oban_powertools_repair_archives, primary_key: false)"
    assert source =~ "add :archived_at, :utc_datetime_usec, null: false"
  end

  test "installer emits explicit runtime wiring for repo and auth module" do
    source =
      "lib/mix/tasks/oban_powertools.install.ex"
      |> File.read!()

    assert source =~ "config :oban_powertools"
    assert source =~ "repo:"
    assert source =~ "auth_module:"
    assert source =~ "ObanPowertools.Application"
    assert source =~ "ObanPowertools.Lifeline.HeartbeatWriter"
    assert source =~ "only starts ObanPowertools.Lifeline.HeartbeatWriter after repo wiring exists"
  end

  test "installer keeps the deterministic migration pipeline contract" do
    source =
      "lib/mix/tasks/oban_powertools.install.ex"
      |> File.read!()

    assert source =~ "|> setup_migration()"
    assert source =~ "|> setup_smart_engine_migrations()"
    assert source =~ "|> setup_workflow_migrations()"
    assert source =~ "|> setup_phase_4_migrations()"
  end
end
