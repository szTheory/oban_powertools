defmodule Mix.Tasks.ObanPowertools.InstallTest do
  use ExUnit.Case

  @installer_path "lib/mix/tasks/oban_powertools.install.ex"

  test "defines an igniter task" do
    Code.ensure_loaded?(Mix.Tasks.ObanPowertools.Install)
    assert function_exported?(Mix.Tasks.ObanPowertools.Install, :igniter, 1)
  end

  test "installer emits the thin host-owned config and seam contract" do
    source = File.read!(@installer_path)

    assert source =~ "config :oban_powertools"
    assert source =~ "repo: MyApp.Repo"
    assert source =~ "auth_module: MyAppWeb.ObanPowertoolsAuth"
    assert source =~ "display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy"
    assert source =~ "ObanPowertoolsAuth"
    assert source =~ "ObanPowertoolsDisplayPolicy"
    assert source =~ "# TODO: Return the current actor from your session/assigns"
    assert source =~ "# TODO: Authorize Powertools actions for your real operator roles"
    assert source =~ "# TODO: Redact or format operator-visible values for your host"

    refute source =~ "ops-demo"
    refute source =~ "demo_actor"
    refute source =~ "[hidden by example host display policy]"
  end

  test "installer emits the host-owned route scope without a hard oban_web dependency" do
    source = File.read!(@installer_path)

    assert source =~ ~s(scope "/ops/jobs")
    assert source =~ "pipe_through :browser"
    assert source =~ ~s|ObanPowertools.Web.Router.oban_powertools_routes("/oban")|

    refute source =~ "{:oban_web,"
    refute source =~ "Oban.Web.Router"
  end

  test "installer keeps the deterministic migration pipeline and powertools tables" do
    source = File.read!(@installer_path)

    assert source =~ "|> setup_migration()"
    assert source =~ "|> setup_smart_engine_migrations()"
    assert source =~ "|> setup_workflow_migrations()"
    assert source =~ "|> setup_batch_migrations()"
    assert source =~ "|> setup_phase_4_migrations()"
    assert source =~ "create table(:oban_powertools_audit_events)"
    assert source =~ "create table(:oban_powertools_idempotency_receipts, primary_key: false)"
    assert source =~ "create table(:oban_powertools_cron_entries, primary_key: false)"
    assert source =~ "create table(:oban_powertools_workflows, primary_key: false)"

    assert source =~
             "rename table(:oban_powertools_workflow_callback_outbox), to: table(:oban_powertools_callbacks)"

    assert source =~ "alter table(:oban_powertools_callbacks)"
    assert source =~ "add :batch_id, :uuid"
    assert source =~ "modify :workflow_id, :uuid, null: true"
    assert source =~ "create index(:oban_powertools_callbacks, [:batch_id])"
    assert source =~ "create table(:oban_powertools_batches, primary_key: false)"
    assert source =~ "create table(:oban_powertools_batch_jobs, primary_key: false)"
    assert source =~ "create table(:oban_powertools_heartbeats, primary_key: false)"
  end

  test "installer emits durable batch insertion metadata fields and indexes" do
    source = File.read!(@installer_path)

    assert source =~ "add :name, :string"
    assert source =~ "add :inserted_count, :integer, null: false, default: 0"
    assert source =~ "add :insert_chunk_count, :integer, null: false, default: 0"
    assert source =~ "add :insert_failed_chunk, :integer"
    assert source =~ "add :insert_failure, :map, null: false, default: %{}"
    assert source =~ "add :insert_failed_at, :utc_datetime_usec"
    assert source =~ "add :completed_at, :utc_datetime_usec"
    assert source =~ "create index(:oban_powertools_batches, [:status])"
    assert source =~ "create index(:oban_powertools_batches, [:name])"
  end

  test "installer emits job record storage without an oban_jobs foreign key" do
    source = File.read!(@installer_path)

    assert source =~ "oban_powertools_job_records"
    assert source =~ "create table(:oban_powertools_job_records, primary_key: false)"
    assert source =~ "add :id, :uuid, primary_key: true"
    assert source =~ "add :oban_job_id, :bigint"
    assert source =~ "add :worker, :string, null: false"
    assert source =~ "add :attempt, :integer, null: false, default: 1"
    assert source =~ "add :status, :string, null: false, default: \"ok\""
    assert source =~ "add :payload, :map, null: false, default: %{}"
    assert source =~ "add :payload_bytes, :integer, null: false, default: 0"
    assert source =~ "add :retention, :string, null: false, default: \"standard\""
    assert source =~ "add :redacted, :boolean, null: false, default: false"
    assert source =~ "add :summary, :string"
    assert source =~ "add :recorded_at, :utc_datetime_usec, null: false"
    assert source =~ "add :expires_at, :utc_datetime_usec, null: false"
    assert source =~ "timestamps(updated_at: false)"

    assert source =~
             "create unique_index(:oban_powertools_job_records, [:oban_job_id, :attempt])"

    assert source =~ "create index(:oban_powertools_job_records, [:worker])"
    assert source =~ "create index(:oban_powertools_job_records, [:status])"
    assert source =~ "create index(:oban_powertools_job_records, [:expires_at])"

    refute source =~ "references(:oban_jobs"
  end

  test "test support migration creates job record storage" do
    migration_path = "test/support/migrations/6_phase_55_tables.exs"

    assert File.exists?(migration_path)

    source = File.read!(migration_path)

    assert source =~ "defmodule ObanPowertools.TestRepo.Migrations.Phase55Tables"
    assert source =~ "def up do"
    assert source =~ "create table(:oban_powertools_job_records, primary_key: false)"
    assert source =~ "add(:oban_job_id, :bigint)"
    assert source =~ "add(:worker, :string, null: false)"

    assert source =~
             "create(unique_index(:oban_powertools_job_records, [:oban_job_id, :attempt]))"

    assert source =~ "create(index(:oban_powertools_job_records, [:worker]))"
    assert source =~ "create(index(:oban_powertools_job_records, [:status]))"
    assert source =~ "create(index(:oban_powertools_job_records, [:expires_at]))"

    refute source =~ "references(:oban_jobs"
  end
end
