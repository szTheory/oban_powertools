defmodule ObanPowertools.ExampleHostContractTest do
  use ExUnit.Case
  @moduletag timeout: 180_000
  # Heavy host-contract integration lanes (generate the ops-demo example host, need
  # the host-contract-proof CI harness). Excluded from the general `test` lane via
  # `--exclude host_contract`; run explicitly (per --only tag) in host-contract-proof.yml.
  @moduletag :host_contract

  alias ObanPowertools.ExampleHostContract

  @tag :"native-only"
  test "native-only lane compiles and resets cleanly" do
    result = ExampleHostContract.proof!("native-only")
    mix_source = File.read!(Path.join(result.dir, "mix.exs"))
    deps_output = ExampleHostContract.run!(result.dir, [], "mix", ["deps"])

    refute mix_source =~ ":oban_web"
    refute deps_output =~ "oban_web"
    assert result.compile_output =~ "Generated phoenix_host app"
    assert result.reset_output =~ "Migrated"
  end

  @tag :"bridge-enabled"
  test "bridge-enabled lane proves one bounded oban web render through the shared session" do
    result = ExampleHostContract.proof!("bridge-enabled")

    assert result.compile_output =~ "Generated phoenix_host app"
    assert result.seeds_output =~ "ops-demo"
    assert result.render_output =~ "PhoenixHostWeb.ObanWebBridgeSmokeTest"
    assert result.render_output =~ "1 test, 0 failures"
    assert result.render_output =~ "/ops/jobs/oban"
    assert result.render_output =~ "Oban Web"
  end

  @tag :"control-plane"
  test "control-plane lane proves overview, audit, and bridge-only follow-up through the canonical fixture" do
    result = ExampleHostContract.proof!("control-plane")

    assert result.compile_output =~ "Generated phoenix_host app"
    assert result.seeds_output =~ "ops-demo"
    assert result.control_plane_output =~ "PhoenixHostWeb.ObanPowertoolsControlPlaneSmokeTest"
    assert result.control_plane_output =~ "1 test, 0 failures"
    assert result.control_plane_output =~ "/ops/jobs"
    assert result.control_plane_output =~ "Diagnosis-first overview"
    assert result.control_plane_output =~ "/ops/jobs/audit"
    assert result.control_plane_output =~ "/ops/jobs/oban"
    assert result.control_plane_output =~ "Inspection only"
  end

  @tag :"upgrade-proof"
  test "upgrade lane proves ops-demo pauses nightly_sync with pause_cron_entry after the documented host updates" do
    result = ExampleHostContract.proof!("upgrade")
    config_source = File.read!(Path.join(result.dir, "config/config.exs"))

    assert config_source =~ "display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy"
    assert result.proof_output =~ "PhoenixHostWeb.ObanPowertoolsFirstSessionTest"
    assert result.proof_output =~ "1 test, 0 failures"
    assert result.proof_output =~ "ops-demo"
    assert result.proof_output =~ "nightly_sync"
    assert result.proof_output =~ "pause_cron_entry"
    assert result.phase_19_output =~ "phase19-upgrade-proof"
    assert result.phase_19_output =~ "active_await_id"
    assert result.phase_19_output =~ "waiting_signal"
    assert result.phase_19_output =~ "consumed"
    assert result.phase_19_output =~ "resolved"
    assert result.reset_output =~ "Migrated"
  end

  @tag :first_session
  test "first-session lane proves ops-demo pauses nightly_sync with pause_cron_entry" do
    result = ExampleHostContract.first_session!()

    assert result.output =~ "PhoenixHostWeb.ObanPowertoolsFirstSessionTest"
    assert result.output =~ "1 test, 0 failures"
    assert result.output =~ "ops-demo"
    assert result.output =~ "nightly_sync"
    assert result.output =~ "pause_cron_entry"
  end
end
