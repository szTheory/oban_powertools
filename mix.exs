defmodule ObanPowertools.MixProject do
  use Mix.Project

  def project do
    [
      app: :oban_powertools,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ObanPowertools.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:igniter, "~> 0.8.0"},
      {:telemetry, "~> 1.4"},
      {:jason, "~> 1.4"},
      {:oban_web, "~> 2.10", optional: true}
    ]
  end
end
