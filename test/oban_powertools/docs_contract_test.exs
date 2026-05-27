defmodule ObanPowertools.DocsContractTest do
  use ExUnit.Case, async: true

  @docs_files [
    "README.md",
    "guides/installation.md",
    "guides/first-operator-session.md",
    "guides/forensics-and-runbook-handoffs.md",
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
  @workflow_semantics_block """
  <!-- workflow-semantics-contract:start -->
  ## Canonical Workflow Semantics Contract

  - Semantics version `2` is the current workflow lifecycle contract.
  - Durable workflow, step, await, signal, callback, and recovery rows are the source of truth.
  - Duplicate, late, ambiguous, dropped, and replayed signal paths remain durable evidence instead of hidden retries.
  - Cancel requests remain durable request evidence, while final workflow outcome is recorded separately.
  - Public workflow telemetry stays under `[:oban_powertools, :workflow, *]` with bounded metadata only.
  <!-- workflow-semantics-contract:end -->
  """

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
    assert source =~ "unified native `/ops/jobs` control plane"
    assert source =~ "native `/ops/jobs` shell"
    assert source =~ "/ops/jobs/oban"
    assert source =~ "read-only"
    assert source =~ "supported mutation surface"
    assert source =~ "Powertools-native"
    assert source =~ "Oban Web bridge"
    assert source =~ "Inspection only"
    assert source =~ "Audited action"
    assert source =~ "overview"
    assert source =~ "audit"
  end

  test "doc-05 forensics claims are file-scoped and complete" do
    canonical = File.read!("guides/forensics-and-runbook-handoffs.md")
    walkthrough = File.read!("guides/example-app-walkthrough.md")
    fixture = File.read!("examples/phoenix_host/README.md")

    assert canonical =~ "DOC05-C1"
    assert canonical =~ "DOC05-C2"
    assert canonical =~ "DOC05-C3"
    assert canonical =~ "/ops/jobs/forensics"
    assert canonical =~ "/ops/jobs/audit"
    assert canonical =~ "partial evidence"
    assert canonical =~ "history unavailable"
    assert canonical =~ "unknown"
    assert canonical =~ "Powertools-native"
    assert canonical =~ "Oban Web bridge"
    assert canonical =~ "host-owned follow-up"
    assert canonical =~ "unconfigured"
    assert canonical =~ "invoked"
    assert canonical =~ "failed"
    assert canonical =~ "does not claim provider delivery certainty"
    assert canonical =~ "external runbook truth"

    assert walkthrough =~ "DOC05-C4"
    assert walkthrough =~ "DOC05-C5"
    assert walkthrough =~ "ops-demo"
    assert walkthrough =~ "pause_cron_entry"
    assert walkthrough =~ "nightly_sync"
    assert walkthrough =~ "/ops/jobs/forensics"
    assert walkthrough =~ "/ops/jobs/audit"
    assert walkthrough =~ "forensics-and-runbook-handoffs"

    assert fixture =~ "DOC05-C6"
    assert fixture =~ "/ops/jobs/forensics"
    assert fixture =~ "/ops/jobs/audit"
    assert fixture =~ "forensics-and-runbook-handoffs"
    assert fixture =~ "example-app-walkthrough"
    assert fixture =~ "host-owned follow-up"
    assert fixture =~ "does not guarantee provider delivery"
  end

  test "docs reject provider-delivery over-claims" do
    canonical = File.read!("guides/forensics-and-runbook-handoffs.md")
    walkthrough = File.read!("guides/example-app-walkthrough.md")
    fixture = File.read!("examples/phoenix_host/README.md")

    assert canonical =~ "does not claim provider delivery certainty"
    assert fixture =~ "does not guarantee provider delivery"
    assert canonical =~ "host-owned responsibilities"

    refute canonical =~ "Powertools delivered the page"
    refute canonical =~ "Powertools guarantees downstream completion"
    refute walkthrough =~ "Powertools guarantees downstream completion"
    refute fixture =~ "Powertools delivered the page"
    refute fixture =~ "Powertools owns external runbook outcomes"
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

  test "workflow docs keep the canonical semantics block exact" do
    source = File.read!("guides/workflows.md")

    assert source =~ @workflow_semantics_block
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
    assert source =~ "control-plane:"
    assert source =~ "upgrade-proof:"
    assert source =~ "workflow-compatibility:"
    assert source =~ "continuity-ver04-c1:"
    assert source =~ "continuity-ver04-c2:"
    assert source =~ "continuity-ver04-c3:"
    assert source =~ "continuity-ver04-c4:"
    assert source =~ "continuity-proof-status:"
    assert source =~ "test/oban_powertools/fresh_host_contract_test.exs"
    assert source =~ "test/oban_powertools/example_host_contract_test.exs"
    assert source =~ "test/oban_powertools/workflow_compatibility_test.exs"
    assert source =~ "--only first_session"
    assert source =~ "--only control-plane"
    assert source =~ "--only upgrade-proof"
  end

  test "workflow keeps Phase 40 shift-left coverage markers" do
    source = File.read!(@workflow_file)

    assert source =~ "engine_overview_live_test.exs"
    assert source =~ "workflows_live_test.exs"
    assert source =~ "runbook_copy_contract_test.exs"
    assert source =~ "phase40-gate-report.json"
    assert source =~ "phase40-gate-report"
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
