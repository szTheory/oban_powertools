defmodule ObanPowertools.MixProject do
  use Mix.Project

  def project do
    [
      app: :oban_powertools,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:igniter, "~> 0.8.0"},
      {:telemetry, "~> 1.4"},
      {:jason, "~> 1.4"},
      {:oban, "~> 2.18"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17"},
      {:oban_web, "~> 2.10", optional: true},
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md" | Path.wildcard("guides/*.md")],
      groups_for_extras: [
        "Day 0": [
          "guides/installation.md",
          "guides/first-operator-session.md",
          "guides/example-app-walkthrough.md"
        ],
        "Day 2": ~r"^guides/(?!installation|first-operator-session|example-app-walkthrough).+\\.md$"
      ]
    ]
  end
end
