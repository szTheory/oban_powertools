defmodule ObanPowertools.ShowcaseCatalog do
  @moduledoc """
  Deterministic dev/test scenario catalog for the Powertools showcase.

  The scenario IDs and targets are public contracts for ExUnit, future VRT
  snapshots, and accessibility scans. Keep values constant and synthetic.
  """

  @domains [
    :overview,
    :jobs,
    :batches,
    :workflows,
    :cron,
    :limiters,
    :lifeline,
    :audit,
    :forensics
  ]

  @required_state_tags [
    :empty,
    :one,
    :many,
    :long_id,
    :long_module,
    :long_url,
    :non_ascii,
    :emoji,
    :rtl,
    :high_count,
    :mixed_severity,
    :permission_denied,
    :stale,
    :disconnected,
    :boundary_pagination
  ]

  @required_personas [
    :triage,
    :incident_response,
    :repair,
    :audit_review
  ]

  @scenarios [
    %{
      id: "overview-operational-empty",
      domain: :overview,
      name: "Operational overview with no active pressure",
      persona: :triage,
      jtbd: "Confirm the control plane is empty before starting an incident triage pass.",
      states: [:empty],
      fixtures: %{summary: %{queues: 0, running: 0, blocked: 0, incidents: []}},
      test_targets: %{
        story: "obpt-story-overview-operational-empty",
        snapshot: "showcase/overview-operational-empty",
        a11y: ~s([data-obpt-story="overview-operational-empty"])
      }
    },
    %{
      id: "jobs-long-identifiers-many",
      domain: :jobs,
      name: "Jobs table with long identifiers and many rows",
      persona: :triage,
      jtbd: "Scan many jobs and preserve the discriminating parts of long IDs and modules.",
      states: [:many, :long_id, :long_module],
      fixtures: %{jobs: [%{id: "job_01", worker: "Acme.Workers.SyncCustomer"}]},
      test_targets: %{
        story: "obpt-story-jobs-long-identifiers-many",
        snapshot: "showcase/jobs-long-identifiers-many",
        a11y: ~s([data-obpt-story="jobs-long-identifiers-many"])
      }
    },
    %{
      id: "batches-high-count-mixed-severity",
      domain: :batches,
      name: "Batch list with high counts and mixed severity",
      persona: :incident_response,
      jtbd: "Find which large batch needs attention without confusing warnings and errors.",
      states: [:high_count, :mixed_severity],
      fixtures: %{batches: [%{id: "batch_01", total: 12_000, severity: :warning}]},
      test_targets: %{
        story: "obpt-story-batches-high-count-mixed-severity",
        snapshot: "showcase/batches-high-count-mixed-severity",
        a11y: ~s([data-obpt-story="batches-high-count-mixed-severity"])
      }
    },
    %{
      id: "workflows-stale-disconnected-dag",
      domain: :workflows,
      name: "Workflow DAG with stale and disconnected nodes",
      persona: :incident_response,
      jtbd: "Explain why a workflow stopped progressing and identify disconnected work.",
      states: [:stale, :disconnected],
      fixtures: %{workflow: %{id: "workflow_01", disconnected_nodes: ["notify"]}},
      test_targets: %{
        story: "obpt-story-workflows-stale-disconnected-dag",
        snapshot: "showcase/workflows-stale-disconnected-dag",
        a11y: ~s([data-obpt-story="workflows-stale-disconnected-dag"])
      }
    },
    %{
      id: "cron-permission-denied",
      domain: :cron,
      name: "Cron schedule with permission-denied controls",
      persona: :audit_review,
      jtbd: "Review why a protected cron action is visible but unavailable.",
      states: [:permission_denied],
      fixtures: %{cron: %{name: "nightly_rollup", can_pause: false}},
      test_targets: %{
        story: "obpt-story-cron-permission-denied",
        snapshot: "showcase/cron-permission-denied",
        a11y: ~s([data-obpt-story="cron-permission-denied"])
      }
    },
    %{
      id: "limiters-boundary-pagination",
      domain: :limiters,
      name: "Limiter table at a pagination boundary",
      persona: :triage,
      jtbd: "Move through saturated limiter pages without losing the current boundary.",
      states: [:boundary_pagination],
      fixtures: %{limiters: %{page: 10, per_page: 25, total: 250}},
      test_targets: %{
        story: "obpt-story-limiters-boundary-pagination",
        snapshot: "showcase/limiters-boundary-pagination",
        a11y: ~s([data-obpt-story="limiters-boundary-pagination"])
      }
    },
    %{
      id: "lifeline-repair-preview",
      domain: :lifeline,
      name: "Lifeline repair preview for one job",
      persona: :repair,
      jtbd: "Preview the exact repair consequence before recording an operator reason.",
      states: [:one],
      fixtures: %{repair: %{target_id: "job_01", action: :retry}},
      test_targets: %{
        story: "obpt-story-lifeline-repair-preview",
        snapshot: "showcase/lifeline-repair-preview",
        a11y: ~s([data-obpt-story="lifeline-repair-preview"])
      }
    },
    %{
      id: "audit-non-ascii-rtl",
      domain: :audit,
      name: "Audit trail with non-ASCII, emoji, and RTL text",
      persona: :audit_review,
      jtbd: "Verify audit evidence remains legible across international operator notes.",
      states: [:non_ascii, :emoji, :rtl],
      fixtures: %{audit_events: [%{actor: "Miyazaki", reason: "בדיקה ✅"}]},
      test_targets: %{
        story: "obpt-story-audit-non-ascii-rtl",
        snapshot: "showcase/audit-non-ascii-rtl",
        a11y: ~s([data-obpt-story="audit-non-ascii-rtl"])
      }
    },
    %{
      id: "forensics-long-url-stacktrace",
      domain: :forensics,
      name: "Forensics bundle with a long URL and stacktrace",
      persona: :incident_response,
      jtbd: "Inspect a long evidence URL and stacktrace without breaking the layout.",
      states: [:long_url],
      fixtures: %{evidence: %{url: "https://example.invalid/ops/jobs/forensics/very-long"}},
      test_targets: %{
        story: "obpt-story-forensics-long-url-stacktrace",
        snapshot: "showcase/forensics-long-url-stacktrace",
        a11y: ~s([data-obpt-story="forensics-long-url-stacktrace"])
      }
    }
  ]

  @scenarios_by_id Map.new(@scenarios, &{Map.fetch!(&1, :id), &1})
  @scenarios_by_domain Map.new(@domains, fn domain ->
                         {domain, Enum.filter(@scenarios, &(&1.domain == domain))}
                       end)

  def domains, do: @domains

  def required_state_tags, do: @required_state_tags

  def required_personas, do: @required_personas

  def scenarios, do: @scenarios

  def scenarios_by_domain, do: @scenarios_by_domain

  def scenario!(id) when is_binary(id) do
    Map.fetch!(@scenarios_by_id, id)
  rescue
    KeyError ->
      raise ArgumentError, "unknown showcase scenario: #{inspect(id)}"
  end

  def scenario!(id) do
    raise ArgumentError, "unknown showcase scenario: #{inspect(id)}"
  end

  def snapshot_name(id) when is_binary(id) do
    "showcase/#{scenario!(id).id}"
  end

  def a11y_target(id) when is_binary(id) do
    ~s([data-obpt-story="#{scenario!(id).id}"])
  end
end
