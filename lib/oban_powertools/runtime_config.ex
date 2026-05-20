defmodule ObanPowertools.RuntimeConfig do
  @moduledoc """
  Centralized runtime configuration contract for required host wiring.
  """

  @app :oban_powertools

  def repo(opts \\ []) do
    Keyword.get(opts, :repo) || configured(:repo, opts)
  end

  def repo!(opts \\ []) do
    repo(opts ++ [required: true])
  end

  def auth_module(opts \\ []) do
    Keyword.get(opts, :auth_module) || configured(:auth_module, opts)
  end

  def auth_module!(opts \\ []) do
    auth_module(opts ++ [required: true])
  end

  defp configured(key, opts) do
    case Application.get_env(@app, key) do
      nil ->
        if Keyword.get(opts, :required, false) do
          raise setup_error(key)
        end

      value ->
        value
    end
  end

  defp setup_error(:repo) do
    "Oban Powertools requires :repo in config :oban_powertools, repo: MyApp.Repo " <>
      "before using persistence-backed features."
  end

  defp setup_error(:auth_module) do
    "Oban Powertools requires :auth_module in config :oban_powertools, " <>
      "auth_module: MyAppWeb.ObanPowertoolsAuth before mounting native operator pages."
  end
end
