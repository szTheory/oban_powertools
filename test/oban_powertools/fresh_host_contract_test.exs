defmodule ObanPowertools.FreshHostContractTest do
  use ExUnit.Case
  @moduletag timeout: 180_000

  alias ObanPowertools.FreshHostContract

  test "fresh host lane installs, compiles, migrates, and boots" do
    result = FreshHostContract.proof!()

    assert result.install_output =~ "oban_powertools.install"
    assert result.compile_output =~ "Generated fresh_host app"
    assert result.migrate_output =~ "Migrated"
    assert result.boot_output =~ "fresh_host booted"

    config_source = File.read!(Path.join(result.dir, "config/config.exs"))
    router_source = File.read!(Path.join([result.dir, "lib", "fresh_host_web", "router.ex"]))

    assert config_source =~ "repo: FreshHost.Repo"
    assert config_source =~ "auth_module: FreshHostWeb.ObanPowertoolsAuth"
    assert config_source =~ "display_policy: FreshHostWeb.ObanPowertoolsDisplayPolicy"
    assert router_source =~ ~s(scope "/ops/jobs")
    assert router_source =~ "pipe_through :browser"
    assert router_source =~ ~s|ObanPowertools.Web.Router.oban_powertools_routes("/oban")|
  end
end
