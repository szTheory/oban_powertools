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
    auth_source =
      File.read!(Path.join([result.dir, "lib", "fresh_host_web", "oban_powertools_auth.ex"]))

    display_policy_source =
      File.read!(
        Path.join([result.dir, "lib", "fresh_host_web", "oban_powertools_display_policy.ex"])
      )

    assert config_source =~ "config :oban_powertools"
    assert config_source =~ "repo: FreshHost.Repo"
    assert config_source =~ "auth_module: FreshHostWeb.ObanPowertoolsAuth"
    assert config_source =~ "display_policy: FreshHostWeb.ObanPowertoolsDisplayPolicy"
    assert router_source =~ ~s(scope "/ops/jobs")
    assert router_source =~ "pipe_through :browser"
    assert router_source =~ ~s|ObanPowertools.Web.Router.oban_powertools_routes("/oban")|
    assert auth_source =~ "defmodule FreshHostWeb.ObanPowertoolsAuth"
    assert auth_source =~ "def audit_principal(actor) when is_map(actor)"
    assert display_policy_source =~ "defmodule FreshHostWeb.ObanPowertoolsDisplayPolicy"
    assert display_policy_source =~ "def display(:reason, reason, _context) when is_binary(reason)"
  end
end
