defmodule ObanPowertools.DocsContractTest do
  use ExUnit.Case, async: true

  @docs_files [
    "README.md",
    "guides/installation.md",
    "guides/first-operator-session.md",
    "guides/example-app-walkthrough.md",
    "guides/workers-and-idempotency.md",
    "guides/limits-and-explain.md",
    "guides/workflows.md",
    "guides/lifeline-and-repairs.md",
    "guides/policy-integration-patterns.md",
    "guides/upgrade-and-compatibility.md",
    "guides/optional-oban-web-bridge.md",
    "guides/support-truth-and-ownership-boundaries.md",
    "guides/production-hardening.md",
    "guides/troubleshooting.md"
  ]
  @workflow_file ".github/workflows/host-contract-proof.yml"

  test "day-0 docs keep the repaired install contract markers" do
    source = joined_docs()

    assert source =~ "mix phx.new"
    assert source =~ "mix oban_powertools.install"
    assert source =~ "mix compile"
    assert source =~ "mix ecto.migrate"
    assert source =~ "mix ecto.reset"
    assert source =~ "mix phx.server"
    assert source =~ "ObanPowertoolsAuth"
    assert source =~ "ObanPowertoolsDisplayPolicy"
    assert source =~ "/ops/jobs"
    assert source =~ "/ops/jobs/oban"
    assert source =~ "read-only"
    assert source =~ "examples/phoenix_host"
  end

  test "first-session docs keep the canonical native proof markers" do
    source = joined_docs()

    assert source =~ "ops-demo"
    assert source =~ "nightly_sync"
    assert source =~ "pause_cron_entry"
  end

  test "support truth stays locked in docs" do
    source = joined_docs()

    assert source =~ "supported"
    assert source =~ "tested"
    assert source =~ "best-effort"
    assert source =~ "host-owned"
    assert source =~ "intentionally unsupported"
    assert source =~ "best-effort outside tested lanes"
    assert source =~ "native `/ops/jobs` shell"
    assert source =~ "/ops/jobs/oban"
    assert source =~ "read-only"
    assert source =~ "supported mutation surface"
  end

  test "builder docs keep the core primitive contract explicit" do
    source = joined_docs()

    assert source =~ "use ObanPowertools.Worker"
    assert source =~ "enqueue/2"
    assert source =~ "{:conflict, job}"
    assert source =~ "Explain.explain"
    assert source =~ "Workflow.new"
    assert source =~ "Workflow.complete_step"
    assert source =~ "Lifeline.preview_repair"
    assert source =~ "Lifeline.execute_repair"
  end

  test "policy docs keep host-owned auth and display seams explicit" do
    source = joined_docs()

    assert source =~ "current_actor/1"
    assert source =~ "authorize/3"
    assert source =~ "audit_principal/1"
    assert source =~ "display/3"
    assert source =~ "host-owned"
    assert source =~ "read-only"
  end

  test "workflow keeps the repaired proof lanes explicit" do
    source = File.read!(@workflow_file)

    assert source =~ "structural:"
    assert source =~ "fresh-host:"
    assert source =~ "docs-contract:"
    assert source =~ "native-first:"
    assert source =~ "first-session:"
    assert source =~ "optional-bridge:"
    assert source =~ "upgrade-proof:"
    assert source =~ "test/oban_powertools/fresh_host_contract_test.exs"
    assert source =~ "test/oban_powertools/example_host_contract_test.exs"
    assert source =~ "--only first_session"
    assert source =~ "--only upgrade-proof"
  end

  test "troubleshooting docs keep the exact fail-fast runtime markers" do
    source = joined_docs()

    assert source =~
             "Oban Powertools requires :repo in config :oban_powertools, repo: MyApp.Repo before using persistence-backed features."

    assert source =~
             "Oban Powertools requires :auth_module in config :oban_powertools, auth_module: MyAppWeb.ObanPowertoolsAuth before mounting native operator pages."

    assert source =~
             "Oban Powertools requires :display_policy in config :oban_powertools, display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy before mounting policy-sensitive native operator pages."
  end

  defp joined_docs do
    @docs_files
    |> Enum.map(&File.read!/1)
    |> Enum.join("\n")
  end
end
