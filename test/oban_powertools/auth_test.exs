defmodule ObanPowertools.AuthTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.RuntimeConfig

  test "defines expected callbacks" do
    Code.ensure_loaded(ObanPowertools.Auth)
    callbacks = ObanPowertools.Auth.behaviour_info(:callbacks)
    assert {:current_actor, 1} in callbacks
    assert {:can_perform_action?, 3} in callbacks
  end

  test "returns configured auth module and repo through the runtime config contract" do
    original_repo = Application.get_env(:oban_powertools, :repo)
    original_auth_module = Application.get_env(:oban_powertools, :auth_module)

    on_exit(fn ->
      Application.put_env(:oban_powertools, :repo, original_repo)
      Application.put_env(:oban_powertools, :auth_module, original_auth_module)
    end)

    Application.put_env(:oban_powertools, :repo, ObanPowertools.TestRepo)
    Application.put_env(:oban_powertools, :auth_module, ObanPowertools.TestAuth)

    assert RuntimeConfig.repo!() == ObanPowertools.TestRepo
    assert RuntimeConfig.repo([]) == ObanPowertools.TestRepo
    assert RuntimeConfig.auth_module!() == ObanPowertools.TestAuth
    assert ObanPowertools.Auth.current_actor(%{"current_actor" => %{id: "ops-1"}}) == %{id: "ops-1"}
  end

  test "raises explicit setup errors when repo and auth module are missing" do
    original_repo = Application.get_env(:oban_powertools, :repo)
    original_auth_module = Application.get_env(:oban_powertools, :auth_module)

    on_exit(fn ->
      Application.put_env(:oban_powertools, :repo, original_repo)
      Application.put_env(:oban_powertools, :auth_module, original_auth_module)
    end)

    Application.delete_env(:oban_powertools, :repo)
    Application.delete_env(:oban_powertools, :auth_module)

    assert_raise RuntimeError, ~r/Oban Powertools requires :repo/, fn ->
      RuntimeConfig.repo!()
    end

    assert_raise RuntimeError, ~r/Oban Powertools requires :auth_module/, fn ->
      RuntimeConfig.auth_module!()
    end

    assert_raise RuntimeError, ~r/Oban Powertools requires :auth_module/, fn ->
      ObanPowertools.Auth.current_actor(%{})
    end

    assert_raise RuntimeError, ~r/Oban Powertools requires :auth_module/, fn ->
      ObanPowertools.Auth.authorize(%{id: "ops-1"}, :view_audit, :audit)
    end
  end
end
