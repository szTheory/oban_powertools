defmodule ObanPowertools.AuthTest do
  use ExUnit.Case, async: false

  alias ObanPowertools.RuntimeConfig

  @repo_error "Oban Powertools requires :repo in config :oban_powertools, repo: MyApp.Repo before using persistence-backed features."
  @auth_error "Oban Powertools requires :auth_module in config :oban_powertools, auth_module: MyAppWeb.ObanPowertoolsAuth before mounting native operator pages."

  test "defines expected callbacks" do
    Code.ensure_loaded(ObanPowertools.Auth)
    callbacks = ObanPowertools.Auth.behaviour_info(:callbacks)
    assert {:current_actor, 1} in callbacks
    assert {:authorize, 3} in callbacks
    assert {:audit_principal, 1} in callbacks
  end

  test "returns configured auth module and repo through the runtime config contract" do
    restore_runtime_config()

    Application.put_env(:oban_powertools, :repo, ObanPowertools.TestRepo)
    Application.put_env(:oban_powertools, :auth_module, ObanPowertools.TestAuth)

    assert RuntimeConfig.repo!() == ObanPowertools.TestRepo
    assert RuntimeConfig.repo([]) == ObanPowertools.TestRepo
    assert RuntimeConfig.auth_module!() == ObanPowertools.TestAuth
    actor = %{id: "ops-1", permissions: [:view_cron]}

    assert ObanPowertools.Auth.current_actor(%{"current_actor" => actor}) == actor
    assert ObanPowertools.Auth.authorization_outcome(actor, :view_cron, %{type: :page, id: "cron"}) ==
             :ok

    assert ObanPowertools.Auth.authorize(actor, :view_cron, %{type: :page, id: "cron"})

    assert ObanPowertools.Auth.audit_principal(actor) ==
             {:ok, %{id: "ops-1", type: :user, label: "operator:ops-1"}}
  end

  test "uses per-call overrides when host runtime wiring is absent" do
    restore_runtime_config()

    Application.delete_env(:oban_powertools, :repo)
    Application.delete_env(:oban_powertools, :auth_module)

    assert RuntimeConfig.repo(repo: ObanPowertools.TestRepo) == ObanPowertools.TestRepo
    assert RuntimeConfig.repo!(repo: ObanPowertools.TestRepo) == ObanPowertools.TestRepo
    assert RuntimeConfig.auth_module(auth_module: ObanPowertools.TestAuth) ==
             ObanPowertools.TestAuth

    assert RuntimeConfig.auth_module!(auth_module: ObanPowertools.TestAuth) ==
             ObanPowertools.TestAuth
  end

  test "raises explicit setup errors when repo and auth module are missing" do
    restore_runtime_config()

    Application.delete_env(:oban_powertools, :repo)
    Application.delete_env(:oban_powertools, :auth_module)

    assert_raise RuntimeError, @repo_error, fn ->
      RuntimeConfig.repo!()
    end

    assert_raise RuntimeError, @auth_error, fn ->
      RuntimeConfig.auth_module!()
    end

    assert_raise RuntimeError, @auth_error, fn ->
      ObanPowertools.Auth.current_actor(%{})
    end

    assert_raise RuntimeError, @auth_error, fn ->
      ObanPowertools.Auth.authorize(%{id: "ops-1"}, :view_audit, :audit)
    end

    assert_raise RuntimeError, @auth_error, fn ->
      ObanPowertools.Auth.authorization_outcome(%{id: "ops-1"}, :view_audit, :audit)
    end

    assert_raise RuntimeError, @auth_error, fn ->
      ObanPowertools.Auth.audit_principal(%{id: "ops-1"})
    end
  end

  test "returns explicit authorization outcomes from the host auth contract" do
    restore_runtime_config()

    Application.put_env(:oban_powertools, :auth_module, ObanPowertools.TestAuth)

    allowed_actor = %{id: "ops-1", permissions: [:view_audit]}
    denied_actor = %{id: "ops-2", permissions: [:view_cron]}
    custom_denial = %{id: "ops-3", authorization_result: {:error, :policy_denied}}

    assert ObanPowertools.Auth.authorization_outcome(allowed_actor, :view_audit, :audit) == :ok

    assert ObanPowertools.Auth.authorization_outcome(denied_actor, :view_audit, :audit) ==
             {:error, :unauthorized}

    assert ObanPowertools.Auth.authorization_outcome(custom_denial, :view_audit, :audit) ==
             {:error, :policy_denied}
  end

  test "fails explicitly when an authorized actor has no valid audit principal" do
    restore_runtime_config()

    Application.put_env(:oban_powertools, :auth_module, ObanPowertools.TestAuth)

    missing_principal_actor = %{
      id: "ops-4",
      permissions: [:execute_repair],
      audit_principal: nil
    }

    invalid_principal_actor = %{
      id: "ops-5",
      permissions: [:execute_repair],
      audit_principal: %{type: :user}
    }

    assert ObanPowertools.Auth.authorization_outcome(
             missing_principal_actor,
             :execute_repair,
             %{type: :repair, id: "preview-1"}
           ) == :ok

    assert ObanPowertools.Auth.audit_principal(missing_principal_actor) ==
             {:error, :missing_audit_principal}

    assert ObanPowertools.Auth.audit_principal(invalid_principal_actor) ==
             {:error, :invalid_audit_principal}
  end

  defp restore_runtime_config do
    original_repo = Application.get_env(:oban_powertools, :repo)
    original_auth_module = Application.get_env(:oban_powertools, :auth_module)

    on_exit(fn ->
      Application.put_env(:oban_powertools, :repo, original_repo)
      Application.put_env(:oban_powertools, :auth_module, original_auth_module)
    end)
  end
end
