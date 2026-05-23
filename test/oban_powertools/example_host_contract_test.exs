defmodule ObanPowertools.ExampleHostContractTest do
  use ExUnit.Case
  @moduletag timeout: 180_000

  alias ObanPowertools.ExampleHostContract

  @tag :"native-only"
  test "native-only lane compiles and resets cleanly" do
    result = ExampleHostContract.proof!("native-only")
    mix_source = File.read!(Path.join(result.dir, "mix.exs"))
    deps_output = ExampleHostContract.run!(result.dir, [], "mix", ["deps"])
    compile_guard_output =
      ExampleHostContract.run!(result.dir, [], "mix", [
        "compile",
        "--no-optional-deps",
        "--warnings-as-errors"
      ])

    refute mix_source =~ ":oban_web"
    refute deps_output =~ "oban_web"
    assert result.compile_output =~ "Generated phoenix_host app"
    assert result.reset_output =~ "Migrated"
    assert compile_guard_output =~ "Generated phoenix_host app"
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
