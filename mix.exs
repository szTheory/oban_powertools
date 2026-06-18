defmodule ObanPowertools.MixProject do
  use Mix.Project

  @version "0.5.0"
  @source_url "https://github.com/szTheory/oban_powertools"

  def project do
    [
      app: :oban_powertools,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs(),
      package: package()
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

  defp package do
    [
      description: "A host-owned operations layer for Oban-backed Phoenix applications.",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: ~w[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      # Available in all envs (the lib ships `mix oban_powertools.install`, which
      # `use Igniter.Mix.Task`, so adopters need igniter loadable to compile it).
      # `runtime: false` keeps it out of the started application list. Matches the
      # mailglass installer-lib precedent.
      {:igniter, "~> 0.8.0", runtime: false},
      {:telemetry, "~> 1.4"},
      {:jason, "~> 1.4"},
      {:oban, "~> 2.18"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17"},
      {:oban_web, "~> 2.10", optional: true},
      {:telemetry_metrics, "~> 1.0", only: [:test, :dev], optional: true},
      {:telemetry_poller, "~> 1.0", optional: true},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      source_url_pattern: "#{@source_url}/blob/v#{@version}/%{path}#L%{line}",
      extras: ["README.md", "CHANGELOG.md" | Path.wildcard("guides/*.md")],
      groups_for_extras: [
        "Day 0": [
          "guides/installation.md",
          "guides/powertools-vs-oban-pro.md",
          "guides/first-operator-session.md",
          "guides/example-app-walkthrough.md"
        ],
        Builders: [
          "guides/workers-and-idempotency.md",
          "guides/limits-and-explain.md",
          "guides/workflows.md",
          "guides/lifeline-and-repairs.md",
          "guides/policy-integration-patterns.md"
        ],
        Operations: [
          "guides/optional-oban-web-bridge.md",
          "guides/telemetry-and-slos.md",
          "guides/support-truth-and-ownership-boundaries.md",
          "guides/production-hardening.md",
          "guides/troubleshooting.md",
          "guides/upgrade-and-compatibility.md",
          "guides/forensics-and-runbook-handoffs.md"
        ]
      ]
    ]
  end
end
