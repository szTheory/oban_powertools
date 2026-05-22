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
    assert source =~ "|> setup_phase_4_migrations()"
    assert source =~ "create table(:oban_powertools_audit_events)"
    assert source =~ "create table(:oban_powertools_idempotency_receipts, primary_key: false)"
    assert source =~ "create table(:oban_powertools_cron_entries, primary_key: false)"
    assert source =~ "create table(:oban_powertools_workflows, primary_key: false)"
    assert source =~ "create table(:oban_powertools_heartbeats, primary_key: false)"
  end
end
