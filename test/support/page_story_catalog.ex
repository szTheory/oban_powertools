defmodule ObanPowertools.PageStoryCatalog do
  @moduledoc """
  Deterministic dev/test stories for the first migrated Powertools pages.

  Every fixture is finite normalized presentation data. The showcase feeds it
  through the production page composition functions, while this support module
  remains outside the runtime package.
  """

  @observed_datetime "2026-07-19T14:05:00Z"
  @observed_at "2026-07-19 14:05:00 UTC"
  @earlier_datetime "2026-07-19T13:55:00Z"
  @earlier_at "2026-07-19 13:55:00 UTC"
  @long_id "01JZ8M5P999999999999999999"
  @long_worker "MyApp.Workers.ReconcileAccountNotificationDeliveryWithAnIntentionallyLongIdentifier"
  @hostile_text "<script>alert('page')</script> مرحبا שלום お客様通知 ✅"

  @overview_quiet_buckets [
    %{
      id: "needs_review",
      kind: :needs_review,
      title: "Needs Review",
      count: 0,
      sample_count_label: "0 identified",
      summary: "Available evidence identifies no work that needs review.",
      impact: "No operator review is identified from the available evidence.",
      observed_at: @observed_at,
      observed_datetime: @observed_datetime,
      status: :needs_review,
      severity: :warning,
      completeness: :complete,
      next_step_path: "/ops/jobs/jobs?state=retryable",
      next_step_label: "Review retryable jobs",
      exemplars: []
    },
    %{
      id: "blocked",
      kind: :blocked,
      title: "Blocked",
      count: 0,
      sample_count_label: "0 identified",
      summary: "Available evidence identifies no blocked limiter work.",
      impact: "No current blocker is identified from the available evidence.",
      observed_at: @observed_at,
      observed_datetime: @observed_datetime,
      status: :blocked,
      severity: :warning,
      completeness: :complete,
      next_step_path: "/ops/jobs/limiters",
      next_step_label: "Review limiters",
      exemplars: []
    },
    %{
      id: "waiting",
      kind: :waiting,
      title: "Waiting",
      count: 0,
      sample_count_label: "0 identified",
      summary: "Available evidence identifies no waiting work.",
      impact: "No current wait is identified from the available evidence.",
      observed_at: @observed_at,
      observed_datetime: @observed_datetime,
      status: :waiting,
      severity: :info,
      completeness: :complete,
      next_step_path: "/ops/jobs/workflows",
      next_step_label: "Review workflows",
      exemplars: []
    },
    %{
      id: "bridge_follow_up",
      kind: :bridge_only,
      title: "Bridge-only Follow-up",
      count: 0,
      sample_count_label: "0 shown",
      summary: "No representative Oban Web follow-up is identified.",
      impact: "Generic job inspection remains available in Oban Web.",
      observed_at: @observed_at,
      observed_datetime: @observed_datetime,
      status: :bridge_only,
      severity: :neutral,
      completeness: :complete,
      next_step_path: "/ops/jobs/oban",
      next_step_label: "Inspect in Oban Web",
      exemplars: []
    },
    %{
      id: "runnable",
      kind: :runnable,
      title: "Runnable",
      count: 6,
      sample_count_label: "6 current",
      summary: "Six current resources are ready for work.",
      impact: "Runnable state does not guarantee future completion.",
      observed_at: @observed_at,
      observed_datetime: @observed_datetime,
      status: :runnable,
      severity: :info,
      completeness: :complete,
      next_step_path: "/ops/jobs/jobs",
      next_step_label: "Open Jobs",
      exemplars: []
    },
    %{
      id: "resolved_continuity",
      kind: :resolved_continuity,
      title: "Resolved continuity",
      count: 2,
      sample_count_label: "2 retained examples",
      summary: "Two resolved records remain available as continuity evidence.",
      impact: "Historical evidence does not establish current state.",
      observed_at: @observed_at,
      observed_datetime: @observed_datetime,
      status: :resolved,
      severity: :neutral,
      completeness: :complete,
      next_step_path: "/ops/jobs/audit",
      next_step_label: "Open Audit",
      exemplars: []
    }
  ]

  @overview_nonzero_buckets Enum.map(@overview_quiet_buckets, fn bucket ->
                              case bucket.id do
                                "needs_review" ->
                                  %{
                                    bucket
                                    | count: 2,
                                      sample_count_label: "2 identified",
                                      summary:
                                        "Two current records need deliberate operator review.",
                                      impact: "Customer notifications may remain delayed.",
                                      exemplars: [
                                        %{
                                          label: "Notification retry review",
                                          attention_reason:
                                            "A retryable job exhausted ordinary recovery.",
                                          path: "/ops/jobs/jobs?state=retryable",
                                          evidence_path:
                                            "/ops/jobs/forensics?resource_type=job&resource_id=101",
                                          venue: "Powertools-native",
                                          ownership: "Operator review",
                                          evidence_completeness: "complete"
                                        }
                                      ]
                                  }

                                "blocked" ->
                                  %{
                                    bucket
                                    | count: 1,
                                      sample_count_label: "1 identified",
                                      summary: "One limiter currently blocks new reservations.",
                                      impact: "Critical mail delivery cannot reserve more work.",
                                      exemplars: [
                                        %{
                                          label: "critical-mailer limiter",
                                          fact: "Capacity reached for the current bucket.",
                                          path: "/ops/jobs/limiters?resource=critical-mailer",
                                          evidence_path: nil,
                                          venue: "Powertools-native",
                                          ownership: "Read-only diagnosis",
                                          evidence_completeness: "complete"
                                        }
                                      ]
                                  }

                                "waiting" ->
                                  %{
                                    bucket
                                    | count: 1,
                                      sample_count_label: "1 identified",
                                      summary: "One workflow waits on an external signal.",
                                      impact: "The final notification step cannot begin yet.",
                                      exemplars: [
                                        %{
                                          label: "notification workflow",
                                          fact: "Waiting for the provider recovery signal.",
                                          path: "/ops/jobs/workflows",
                                          evidence_path: nil,
                                          venue: "Powertools-native",
                                          ownership: "Workflow evidence",
                                          evidence_completeness: "partial evidence"
                                        }
                                      ]
                                  }

                                "bridge_follow_up" ->
                                  %{
                                    bucket
                                    | count: 2,
                                      sample_count_label: "2 representative follow-ups",
                                      summary:
                                        "Representative generic job follow-up remains in Oban Web.",
                                      exemplars: [
                                        %{
                                          label: "Job #{@long_id}",
                                          fact:
                                            "Inspect the provider-owned job fields in Oban Web.",
                                          path: "/ops/jobs/oban",
                                          evidence_path: nil,
                                          venue: "Oban Web bridge",
                                          ownership: "Inspection only",
                                          evidence_completeness: "partial evidence"
                                        }
                                      ]
                                  }

                                _other ->
                                  bucket
                              end
                            end)

  @overview_long_buckets Enum.map(@overview_nonzero_buckets, fn bucket ->
                           if bucket.id == "needs_review" do
                             %{
                               bucket
                               | title: "Needs Review — お客様通知",
                                 summary: @hostile_text,
                                 impact:
                                   "#{@long_worker} retains a deliberately long recovery explanation for #{@long_id}.",
                                 exemplars: [
                                   %{
                                     label: "#{@long_worker} — مرحبا שלום",
                                     attention_reason: @hostile_text,
                                     path: "/ops/jobs/jobs?state=retryable",
                                     evidence_path: nil,
                                     venue: "Powertools-native",
                                     ownership: "Operator review",
                                     evidence_completeness: "complete"
                                   }
                                 ]
                             }
                           else
                             bucket
                           end
                         end)

  @cron_entry %{
    name: "nightly-notification-reconciliation",
    expression: "0 2 * * *",
    timezone: "Etc/UTC",
    queue: "critical-mailer",
    overlap_policy: "queue_one",
    catch_up_policy: "latest",
    source: "code",
    paused_at: nil
  }
  @paused_cron_entry @cron_entry
                     |> Map.put(:name, "paused-notification-reconciliation")
                     |> Map.put(:paused_at, @earlier_datetime)
  @cron_actor %{
    id: "showcase-operator",
    permissions: [:view_cron, :pause_cron_entry, :resume_cron_entry, :run_cron_entry]
  }
  @cron_read_only_actor %{id: "showcase-reader", permissions: [:view_cron]}
  @cron_base %{
    entries: [@cron_entry, @paused_cron_entry],
    read_only?: false,
    error_message: nil,
    selected_entry: @cron_entry,
    detail_open?: false,
    history_summary: nil,
    confirmation_open?: false,
    confirmation_action: nil,
    confirmation_state: :preview,
    confirmation_form: %{"reason" => ""},
    confirmation_result: nil,
    current_actor: @cron_actor,
    reason: "",
    receipt: nil
  }
  @cron_confirmation_base %{@cron_base | current_actor: nil}
  @pause_action %{
    kind: :pause,
    confirm_label: "Pause cron entry",
    dismiss_label: "Keep running",
    title: "Pause nightly-notification-reconciliation",
    consequence:
      "Future schedule claims stop. Work that is already running or enqueued is unaffected.",
    support_boundary: "The existing schedule and already-claimed work remain unchanged.",
    pending_copy: "Pausing cron entry",
    intent: :warning
  }
  @resume_action %{
    kind: :resume,
    confirm_label: "Resume cron entry",
    dismiss_label: "Keep paused",
    title: "Resume nightly-notification-reconciliation",
    consequence: "Future schedule claims continue. Missed work is not run retroactively.",
    support_boundary: "Only future schedule claims continue after this action.",
    pending_copy: "Resuming cron entry",
    intent: :warning
  }
  @run_now_action %{
    kind: :run_now,
    confirm_label: "Run cron entry now",
    dismiss_label: "Keep current schedule",
    title: "Run nightly-notification-reconciliation now",
    consequence:
      "Powertools attempts a manual schedule-slot claim. Overlap policy may skip, queue, or enqueue it.",
    support_boundary: "A recorded slot claim does not prove that a job ran.",
    pending_copy: "Claiming a manual schedule slot",
    intent: :warning
  }

  @limiter_rows [
    %{id: "critical-mailer", name: "critical-mailer", scope: "worker", state: :blocked},
    %{id: "billing-sync", name: "billing-sync", scope: "global", state: :runnable}
  ]
  @limiter_runnable_detail %{
    resource: %{name: "billing-sync", scope: "global", state: :runnable},
    current: %{
      summary: "Current limiter state is ready for work.",
      impact: "No current limiter condition prevents new reservations.",
      observed_at: @observed_at,
      observed_datetime: @observed_datetime,
      evidence_state: :current,
      completeness: :complete,
      blockers: []
    },
    snapshot: nil,
    history: %{
      detail: "Retained history contains no blocking episode for billing-sync.",
      completeness: "Complete evidence",
      episodes: []
    },
    destinations: %{forensics_path: nil, oban_job_path: nil}
  }
  @limiter_blocked_detail %{
    resource: %{name: "critical-mailer", scope: "worker", state: :blocked},
    current: %{
      summary: "One current limiter condition affects new reservations.",
      impact: "New reservations remain limited until the current condition clears.",
      observed_at: @observed_at,
      observed_datetime: @observed_datetime,
      evidence_state: :current,
      completeness: :complete,
      blockers: [
        %{
          id: "current-1",
          evidence_kind: :current,
          label: "Capacity reached",
          summary: "The limiter has reserved its current bucket capacity.",
          affected_scope: "#{@long_worker} / critical-mailer",
          clearing_condition: "Clears when the active bucket refreshes at #{@observed_at}.",
          evidence_source: "Current limiter state"
        }
      ]
    },
    snapshot: %{
      captured_at: @earlier_at,
      captured_datetime: @earlier_datetime,
      completeness: "complete",
      facts: [
        %{
          label: "Cooldown active",
          summary: "The limiter was in cooldown when this snapshot was captured.",
          affected_scope: "critical-mailer"
        }
      ]
    },
    history: %{
      detail: "Retained history records one earlier limiter episode without claiming causality.",
      completeness: "Complete evidence",
      episodes: [%{label: "Limiter blocked", occurred_at: @earlier_at}]
    },
    destinations: %{
      forensics_path: "/ops/jobs/forensics?resource_type=limiter&resource_id=critical-mailer",
      oban_job_path: "/oban/jobs/42"
    }
  }
  @limiters_base %{
    resource_rows: @limiter_rows,
    selected_resource: "critical-mailer",
    detail_open?: false,
    detail_state: :ready,
    detail_presentation: @limiter_blocked_detail,
    read_only?: true,
    error_message: nil
  }

  @audit_empty_page %{
    total_count: 0,
    page: 1,
    page_size: 20,
    total_pages: 0,
    previous?: false,
    next?: false,
    previous_href: nil,
    next_href: nil
  }
  @audit_retention %{
    title: "Repair evidence retention",
    description:
      "Archived repair evidence is stored separately from the live Audit rows shown here.",
    last_run: "The latest repair archive run completed at #{@earlier_at}."
  }
  @audit_boundary_rows (for id <- 21..40 do
                          %{
                            id: id,
                            event_label: "Limiter blocked",
                            target_label: "limiter:critical-mailer-#{id}",
                            target_href: nil,
                            actor: "operator-#{id}",
                            reason_summary: "Capacity evidence reviewed for boundary row #{id}.",
                            recorded_at: @observed_at,
                            recorded_datetime: @observed_datetime,
                            evidence_label:
                              "View evidence for Limiter blocked on critical-mailer-#{id}"
                          }
                        end)
  @audit_selected_row %{
    id: 42,
    event_label: "Repair executed",
    target_label: "job:#{@long_id}",
    target_href: "/ops/jobs/jobs/#{@long_id}",
    actor: "Miyazaki Haruka — مرحبا",
    reason_summary: @hostile_text,
    recorded_at: @observed_at,
    recorded_datetime: @observed_datetime,
    evidence_label: "View evidence for Repair executed on job #{@long_id}"
  }
  @audit_selected_detail %{
    sentence: "Miyazaki Haruka recorded repair executed for job #{@long_id}.",
    outcome: "Repair request recorded",
    outcome_state: :success,
    actor: "Miyazaki Haruka — مرحبا",
    action: "Repair executed",
    target: "job:#{@long_id}",
    reason: "#{@hostile_text} #{@long_worker}",
    source: "Powertools operator UI",
    correlation: "request-00000000000000000042",
    occurred_at: @observed_at,
    occurred_datetime: @observed_datetime,
    recorded_at_label: "Recorded at",
    changes: [%{field: "queue", before: "default", after: "critical-mailer"}],
    evidence: [%{label: "Recorded result", value: "request accepted for review"}],
    target_href: "/ops/jobs/jobs/#{@long_id}"
  }
  @audit_missing_detail %{
    sentence: "Powertools system recorded an audit event for limiter:critical-mailer.",
    outcome: "Outcome not recorded",
    outcome_state: :unknown,
    actor: "Powertools system",
    action: "Recorded event",
    target: "limiter:critical-mailer",
    reason: "No operator reason recorded",
    source: "Source not recorded",
    correlation: "Correlation not recorded",
    occurred_at: @observed_at,
    occurred_datetime: @observed_datetime,
    recorded_at_label: "Recorded at",
    changes: [],
    evidence: [],
    target_href: nil
  }
  @audit_base %{
    audit_page: @audit_empty_page,
    event_rows: [],
    filter_form: %{"resource_type" => "", "resource_id" => "", "event_type" => ""},
    active_filters: [],
    result_summary: "0 records · Page 1 of 1",
    selected_event_id: nil,
    selected_detail: nil,
    detail_state: :empty,
    retention_summary: @audit_retention,
    load_state: :ready,
    clear_filters_href: "/ops/jobs/audit",
    read_only_copy:
      "Permission: read-only. Review immutable recorded evidence without changing it."
  }

  @story_specs [
    %{
      id: "page-overview-all-quiet",
      kind: :page,
      page: :overview,
      name: "Overview all quiet",
      description: "The stable triage hierarchy states the bounded all-quiet truth.",
      components: [:surface, :link, :empty_state, :metric_card],
      variant: [:all_quiet, :fixed_order],
      state: [:empty, :ready],
      fixtures: %{overview_buckets: @overview_quiet_buckets},
      activation: :none
    },
    %{
      id: "page-overview-fixed-order-nonzero",
      kind: :page,
      page: :overview,
      name: "Overview fixed order with current work",
      description:
        "Nonzero native attention, bridge handoff, capacity, and continuity remain ordered.",
      components: [:surface, :link, :attention_card, :metric_card],
      variant: [:nonzero, :fixed_order],
      state: [:ready],
      fixtures: %{overview_buckets: @overview_nonzero_buckets},
      activation: :none
    },
    %{
      id: "page-overview-long-unicode",
      kind: :page,
      page: :overview,
      name: "Overview long international content",
      description: "Long, Unicode, RTL, and HTML-looking content remains ordinary escaped text.",
      components: [:surface, :link, :attention_card, :metric_card],
      variant: [:long_content, :international],
      state: [:ready],
      fixtures: %{overview_buckets: @overview_long_buckets},
      activation: :none
    },
    %{
      id: "page-cron-selected-detail",
      kind: :page,
      page: :cron,
      name: "Cron selected detail",
      description: "One selected cron entry is the sole action venue.",
      components: [:data_table, :description_list, :detail_surface, :button, :link],
      variant: [:selected_detail],
      state: [:ready],
      fixtures: @cron_base,
      activation: :detail
    },
    %{
      id: "page-cron-permission-denied",
      kind: :page,
      page: :cron,
      name: "Cron read-only detail",
      description: "Server-derived permission truth keeps actions discoverable and disabled.",
      components: [:surface, :data_table, :detail_surface, :button],
      variant: [:selected_detail, :read_only],
      state: [:permission_denied, :ready],
      fixtures: %{@cron_base | read_only?: true, current_actor: @cron_read_only_actor},
      activation: :detail
    },
    %{
      id: "page-cron-pause-confirmation",
      kind: :page,
      page: :cron,
      name: "Pause cron entry confirmation",
      description: "Pause confirmation names its consequence and non-effect.",
      components: [:data_table, :reason_field, :confirm_action_dialog, :button, :link],
      variant: [:pause, :confirmation],
      state: [:ready],
      fixtures: %{
        @cron_confirmation_base
        | confirmation_action: @pause_action,
          confirmation_form: %{"reason" => "Planned provider maintenance."},
          reason: "Planned provider maintenance."
      },
      activation: :confirmation
    },
    %{
      id: "page-cron-resume-confirmation",
      kind: :page,
      page: :cron,
      name: "Resume cron entry confirmation",
      description: "Resume confirmation preserves missed-work truth.",
      components: [:data_table, :reason_field, :confirm_action_dialog, :button, :link],
      variant: [:resume, :confirmation],
      state: [:ready],
      fixtures: %{
        @cron_confirmation_base
        | selected_entry: @paused_cron_entry,
          confirmation_action: @resume_action,
          confirmation_form: %{"reason" => "Capacity is available again."},
          reason: "Capacity is available again."
      },
      activation: :confirmation
    },
    %{
      id: "page-cron-run-now-confirmation",
      kind: :page,
      page: :cron,
      name: "Run cron entry now confirmation",
      description: "Manual slot-claim confirmation does not claim that a job ran.",
      components: [:data_table, :reason_field, :confirm_action_dialog, :button, :link],
      variant: [:run_now, :confirmation],
      state: [:loading, :ready],
      fixtures: %{
        @cron_confirmation_base
        | confirmation_action: @run_now_action,
          confirmation_form: %{"reason" => "Validate the recovered provider path."},
          reason: "Validate the recovered provider path."
      },
      activation: :confirmation
    },
    %{
      id: "page-cron-expired-recovery",
      kind: :page,
      page: :cron,
      name: "Expired cron preview recovery",
      description: "Expired work remains open and requires an explicit new preview.",
      components: [:data_table, :confirm_action_dialog, :button],
      variant: [:expired, :recovery],
      state: [:stale, :error],
      fixtures: %{
        @cron_confirmation_base
        | confirmation_action: @pause_action,
          confirmation_state: :expired,
          confirmation_form: %{"reason" => "Planned provider maintenance."},
          confirmation_result: %{
            state: :expired,
            message: "The action preview expired before execution.",
            recovery: "Create a new preview before trying again.",
            audit_href: nil
          },
          reason: "Planned provider maintenance.",
          error_message: "This preview expired."
      },
      activation: :confirmation
    },
    %{
      id: "page-cron-drifted-recovery",
      kind: :page,
      page: :cron,
      name: "Drifted cron preview recovery",
      description: "Changed cron truth remains visible before a fresh preview.",
      components: [:data_table, :confirm_action_dialog, :button],
      variant: [:drifted, :recovery],
      state: [:stale, :error],
      fixtures: %{
        @cron_confirmation_base
        | confirmation_action: @resume_action,
          confirmation_state: :drifted,
          confirmation_form: %{"reason" => "Capacity is available again."},
          confirmation_result: %{
            state: :drifted,
            message: "The cron entry changed after the preview.",
            recovery: "Review the current cron entry, then create a new preview.",
            audit_href: nil
          },
          reason: "Capacity is available again.",
          error_message: "This preview is out of date."
      },
      activation: :confirmation
    },
    %{
      id: "page-cron-skipped-partial-recovery",
      kind: :page,
      page: :cron,
      name: "Skipped manual claim recovery",
      description: "A skipped slot claim stays open without becoming successful execution.",
      components: [:data_table, :confirm_action_dialog, :button],
      variant: [:run_now, :skipped, :partial],
      state: [:partial, :error],
      fixtures: %{
        @cron_confirmation_base
        | confirmation_action: @run_now_action,
          confirmation_state: :partial,
          confirmation_form: %{"reason" => "Validate the recovered provider path."},
          confirmation_result: %{
            state: :skipped,
            message: "The manual schedule-slot claim was skipped.",
            recovery: "Create a new preview before trying again.",
            audit_href: nil
          },
          reason: "Validate the recovered provider path."
      },
      activation: :confirmation
    },
    %{
      id: "page-limiters-runnable-empty-current",
      kind: :page,
      page: :limiters,
      name: "Limiter complete empty current evidence",
      description: "Only complete empty current evidence is presented as Runnable.",
      components: [:surface, :data_table, :detail_surface, :why_blocked],
      variant: [:runnable, :empty_current],
      state: [:empty, :ready],
      fixtures: %{
        @limiters_base
        | selected_resource: "billing-sync",
          detail_presentation: @limiter_runnable_detail
      },
      activation: :detail
    },
    %{
      id: "page-limiters-blocked-evidence-layers",
      kind: :page,
      page: :limiters,
      name: "Limiter current and historical evidence",
      description:
        "Current blockers, Snapshot at block start, and Retained history stay separate.",
      components: [:surface, :data_table, :detail_surface, :why_blocked, :link],
      variant: [:blocked, :evidence_layers],
      state: [:ready],
      fixtures: @limiters_base,
      activation: :detail
    },
    %{
      id: "page-limiters-unavailable",
      kind: :page,
      page: :limiters,
      name: "Limiter detail unavailable",
      description: "Unavailable selection fails closed without inventing current evidence.",
      components: [:surface, :data_table, :detail_surface, :empty_state],
      variant: [:unavailable],
      state: [:unavailable, :error],
      fixtures: %{
        @limiters_base
        | selected_resource: nil,
          detail_state: :unavailable,
          detail_presentation: nil
      },
      activation: :detail
    },
    %{
      id: "page-limiters-forensics-unavailable",
      kind: :page,
      page: :limiters,
      name: "Limiter Forensics unavailable",
      description:
        "Current evidence remains visible while the unauthorized destination is absent.",
      components: [:surface, :data_table, :detail_surface, :why_blocked, :link],
      variant: [:blocked, :forensics_unavailable],
      state: [:permission_denied, :ready],
      fixtures: %{
        @limiters_base
        | detail_presentation:
            put_in(@limiter_blocked_detail, [:destinations, :forensics_path], nil)
      },
      activation: :detail
    },
    %{
      id: "page-audit-empty",
      kind: :page,
      page: :audit,
      name: "Audit empty",
      description: "The bounded read-only scan states that no records are recorded.",
      components: [:surface, :filter_bar, :data_table, :empty_state, :link],
      variant: [:empty, :unfiltered],
      state: [:empty, :ready],
      fixtures: @audit_base,
      activation: :none
    },
    %{
      id: "page-audit-filtered-boundary-page",
      kind: :page,
      page: :audit,
      name: "Audit filtered boundary page",
      description: "Twenty deterministic rows retain exact filter and pagination truth.",
      components: [:surface, :filter_bar, :data_table, :button, :link],
      variant: [:filtered, :boundary_page],
      state: [:ready],
      fixtures: %{
        @audit_base
        | audit_page: %{
            total_count: 41,
            page: 2,
            page_size: 20,
            total_pages: 3,
            previous?: true,
            next?: true,
            previous_href: "/ops/jobs/audit?resource_type=limiter",
            next_href: "/ops/jobs/audit?resource_type=limiter&page=3"
          },
          event_rows: @audit_boundary_rows,
          filter_form: %{"resource_type" => "limiter", "resource_id" => "", "event_type" => ""},
          active_filters: [
            %{
              id: "audit-filter-resource-type",
              label: "Resource type",
              value: "limiter",
              remove_href: "/ops/jobs/audit",
              remove_label: "Remove Resource type filter"
            }
          ],
          result_summary: "Records 21–40 of 41 · Page 2 of 3"
      },
      activation: :none
    },
    %{
      id: "page-audit-selected-long-unicode",
      kind: :page,
      page: :audit,
      name: "Audit selected long international evidence",
      description:
        "One immutable selected record preserves complete escaped multilingual evidence.",
      components: [:surface, :filter_bar, :data_table, :detail_surface, :audit_entry, :code_block],
      variant: [:selected_detail, :long_content, :international],
      state: [:ready, :success],
      fixtures: %{
        @audit_base
        | audit_page: %{
            total_count: 1,
            page: 1,
            page_size: 20,
            total_pages: 1,
            previous?: false,
            next?: false,
            previous_href: nil,
            next_href: nil
          },
          event_rows: [@audit_selected_row],
          result_summary: "Records 1–1 of 1 · Page 1 of 1",
          selected_event_id: 42,
          selected_detail: @audit_selected_detail
      },
      activation: :detail
    },
    %{
      id: "page-audit-selected-missing-fields",
      kind: :page,
      page: :audit,
      name: "Audit selected missing fields",
      description: "Missing reason, outcome, source, and correlation remain explicit.",
      components: [:surface, :filter_bar, :data_table, :detail_surface, :audit_entry],
      variant: [:selected_detail, :missing_fields],
      state: [:ready, :unavailable],
      fixtures: %{
        @audit_base
        | audit_page: %{
            total_count: 1,
            page: 1,
            page_size: 20,
            total_pages: 1,
            previous?: false,
            next?: false,
            previous_href: nil,
            next_href: nil
          },
          event_rows: [
            %{
              @audit_selected_row
              | id: 43,
                event_label: "Recorded event",
                target_label: "limiter:critical-mailer",
                target_href: nil,
                actor: "Powertools system",
                reason_summary: "No operator reason recorded",
                evidence_label: "View evidence for Recorded event on limiter:critical-mailer"
            }
          ],
          result_summary: "Records 1–1 of 1 · Page 1 of 1",
          selected_event_id: 43,
          selected_detail: @audit_missing_detail
      },
      activation: :detail
    }
  ]

  @stories Enum.map(@story_specs, fn story ->
             id = story.id

             Map.put(story, :test_targets, %{
               story: "obpt-page-story-#{id}",
               snapshot: "showcase/#{id}",
               a11y: ~s([data-obpt-page-story="#{id}"])
             })
           end)

  @stories_by_id Map.new(@stories, &{&1.id, &1})

  def stories, do: @stories

  def story!(id) when is_binary(id) do
    Map.fetch!(@stories_by_id, id)
  rescue
    KeyError -> raise ArgumentError, "unknown page story: #{inspect(id)}"
  end

  def story!(id), do: raise(ArgumentError, "unknown page story: #{inspect(id)}")
  def snapshot_name(id), do: "showcase/#{story!(id).id}"
  def a11y_target(id), do: ~s([data-obpt-page-story="#{story!(id).id}"])
end
