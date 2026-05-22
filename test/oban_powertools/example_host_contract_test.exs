defmodule ObanPowertools.ExampleHostContractTest do
  use ExUnit.Case
  @moduletag timeout: 180_000

  alias ObanPowertools.ExampleHostContract

  @tag :"native-only"
  test "native-only lane compiles and resets cleanly" do
    result = ExampleHostContract.proof!("native-only")

    assert result.compile_output =~ "Generated phoenix_host app"
    assert result.reset_output =~ "Migrated"
  end

  @tag :"bridge-enabled"
  test "bridge-enabled lane compiles and resets cleanly" do
    result = ExampleHostContract.proof!("bridge-enabled")

    assert result.compile_output =~ "Generated phoenix_host app"
    assert result.seeds_output =~ "ops-demo"
  end

  @tag :"upgrade-proof"
  test "upgrade lane restores display_policy before proof commands run" do
    result = ExampleHostContract.proof!("upgrade")
    config_source = File.read!(Path.join(result.dir, "config/config.exs"))

    assert config_source =~ "display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy"
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
