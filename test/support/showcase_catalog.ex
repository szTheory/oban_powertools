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
      fixtures: %{
        headline: "No active work requires attention",
        summary: %{
          queues: 0,
          running_jobs: 0,
          retryable_jobs: 0,
          scheduled_jobs: 0,
          blocked_workflows: 0,
          saturated_limiters: 0,
          open_incidents: []
        },
        empty_states: [
          %{
            surface: "jobs",
            title: "No jobs match the current filters",
            next_action: "Clear filters or widen the time window."
          },
          %{
            surface: "audit",
            title: "No operator actions recorded",
            next_action: "Actions taken through Powertools appear here."
          }
        ],
        filters: %{queue: "all", state: "all", actor: "all"}
      },
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
      fixtures: %{
        pagination: %{page: 4, per_page: 25, total_entries: 248, total_pages: 10},
        jobs: [
          %{
            id: "job_01J3R8V7G6S9Q2K4M6P8T0N1A2B3C4D5E6F7G8H9",
            state: "retryable",
            queue: "critical-mailer",
            attempt: 7,
            max_attempts: 20,
            worker:
              "Acme.Operations.Workers.Deeply.Nested.SendLifecycleNotificationToRegionalEscalationQueue",
            args: %{
              "account_id" => "acct_00000000000000000000000042",
              "region" => "us-east-1",
              "locale" => "en-US"
            },
            meta: %{
              "__redacted_fields__" => ["token", "authorization"],
              "trace_id" => "trc_01J3R8V7G6S9Q2K4M6P8T0N1A2"
            },
            tags: ["customer-facing", "retry-safe"]
          },
          %{
            id: "job_01J3R8V7G6S9Q2K4M6P8T0N1A2B3C4D5E6F7G8HA",
            state: "executing",
            queue: "billing-sync",
            attempt: 1,
            max_attempts: 5,
            worker:
              "Acme.Revenue.Workers.MultiTenant.InvoiceReconciliationAndLedgerPostingWorker",
            args: %{
              "tenant_id" => "tenant_northwind_enterprise",
              "invoice_batch" => "batch_2026_q2_close_000000001"
            },
            meta: %{"trace_id" => "trc_01J3R8V7G6S9Q2K4M6P8T0N1A3"},
            tags: ["ledger", "high-value"]
          },
          %{
            id: "job_01J3R8V7G6S9Q2K4M6P8T0N1A2B3C4D5E6F7G8HB",
            state: "scheduled",
            queue: "reports",
            attempt: 0,
            max_attempts: 3,
            worker: "Acme.Analytics.Workers.GenerateQuarterlyExecutiveSummaryExport",
            args: %{"report_id" => "rpt_2026_q2_exec_summary_long_running"},
            meta: %{"scheduled_reason" => "rate_limiter_reservation"},
            tags: ["export", "scheduled"]
          }
        ]
      },
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
      fixtures: %{
        totals: %{active: 18, completed: 128, exhausted: 3},
        batches: [
          %{
            id: "batch_customer_replay_2026_q2_000001",
            name: "Customer replay backfill",
            state: "running",
            total_jobs: 125_000,
            completed_jobs: 98_412,
            failed_jobs: 74,
            severity: :warning,
            next_step: "Review failed shard workers before increasing concurrency."
          },
          %{
            id: "batch_invoice_close_2026_q2_000017",
            name: "Invoice close",
            state: "exhausted",
            total_jobs: 42_000,
            completed_jobs: 39_008,
            failed_jobs: 2_992,
            severity: :danger,
            next_step: "Open Lifeline repair preview for failed invoices."
          },
          %{
            id: "batch_search_reindex_2026_q2_000004",
            name: "Search reindex",
            state: "completed",
            total_jobs: 250_000,
            completed_jobs: 250_000,
            failed_jobs: 0,
            severity: :success,
            next_step: "No action needed."
          }
        ]
      },
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
      fixtures: %{
        workflow: %{
          id: "workflow_account_sync_01J3R8V7G6S9Q2K4M6P8",
          name: "Account sync with support handoff",
          state: "blocked",
          stale_since: "2026-06-18T14:15:00Z",
          nodes: [
            %{id: "fetch_customer", label: "Fetch customer", state: "completed"},
            %{id: "sync_billing", label: "Sync billing", state: "completed"},
            %{id: "sync_support", label: "Sync support", state: "retryable"},
            %{id: "notify", label: "Notify operator", state: "disconnected"}
          ],
          edges: [
            %{from: "fetch_customer", to: "sync_billing"},
            %{from: "fetch_customer", to: "sync_support"},
            %{from: "sync_billing", to: "notify"},
            %{from: "sync_support", to: "notify"}
          ],
          blocked_by: [
            "sync_support has not recorded a terminal result",
            "notify is disconnected from an executable predecessor"
          ]
        }
      },
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
      fixtures: %{
        cron: %{
          name: "nightly_rollup",
          expression: "15 2 * * *",
          queue: "maintenance",
          worker: "Acme.Cron.Workers.GenerateNightlyOperationalRollup",
          paused: false,
          controls: [
            %{
              action: "pause",
              enabled: false,
              reason: "Pause requires operator role: scheduler_admin"
            },
            %{
              action: "run_now",
              enabled: false,
              reason: "Run now requires operator role: scheduler_admin"
            }
          ],
          last_run: %{state: "completed", at: "2026-06-18T02:15:00Z"}
        }
      },
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
      fixtures: %{
        pagination: %{
          page: 10,
          per_page: 25,
          total_entries: 250,
          total_pages: 10,
          previous_page: 9,
          next_page: nil
        },
        limiters: [
          %{
            name: "global:email-delivery",
            mode: "partitioned",
            available: 0,
            capacity: 500,
            reservation_count: 500,
            saturated: true,
            oldest_reservation: "2026-06-18T13:44:30Z"
          },
          %{
            name: "tenant:acme:billing-sync",
            mode: "rate",
            available: 1,
            capacity: 25,
            reservation_count: 24,
            saturated: false,
            oldest_reservation: "2026-06-18T14:02:10Z"
          }
        ]
      },
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
      fixtures: %{
        repair: %{
          target_type: "job",
          target_id: "job_01J3R8V7G6S9Q2K4M6P8T0N1A2B3C4D5E6F7G8H9",
          action: "retry",
          preview: [
            "Job moves from retryable to available.",
            "Attempt count stays at 7 until the worker starts again.",
            "An audit event records the operator reason."
          ],
          required_reason: "Customer-impacting notification backlog cleared by provider.",
          audit_actor: "ops@example.invalid",
          reversible: false
        }
      },
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
      fixtures: %{
        audit_events: [
          %{
            id: "audit_evt_0000000000000000000000001",
            actor: "Miyazaki Haruka",
            action: "retry",
            resource: "job_01J3R8V7G6S9Q2K4M6P8T0N1A2",
            reason: "Rerun after gateway recovery - お客様通知 ✅",
            outcome: "recorded"
          },
          %{
            id: "audit_evt_0000000000000000000000002",
            actor: "ليلى.العمليات@example.invalid",
            action: "pause",
            resource: "cron:nightly_rollup",
            reason: "مراجعة نافذة الصيانة قبل التشغيل",
            direction: "rtl",
            outcome: "permission_denied"
          }
        ]
      },
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
      fixtures: %{
        evidence: %{
          bundle_id: "forensics_bundle_01J3R8V7G6S9Q2K4M6P8T0N1A2",
          source_url:
            "https://example.invalid/ops/jobs/forensics/bundles/01J3R8V7G6S9Q2K4M6P8T0N1A2/evidence?queue=critical-mailer&worker=Acme.Operations.Workers.Deeply.Nested.SendLifecycleNotificationToRegionalEscalationQueue&trace=trc_01J3R8V7G6S9Q2K4M6P8T0N1A2",
          stacktrace: [
            "Acme.Operations.Workers.Deeply.Nested.SendLifecycleNotificationToRegionalEscalationQueue.perform/1",
            "Oban.Queue.Executor.call/1",
            "ObanPowertools.Workflow.Runtime.Transitions.record_failure/4"
          ],
          timeline: [
            %{at: "2026-06-18T14:01:00Z", event: "job_started"},
            %{at: "2026-06-18T14:01:08Z", event: "provider_timeout"},
            %{at: "2026-06-18T14:01:09Z", event: "retry_scheduled"}
          ]
        }
      },
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
