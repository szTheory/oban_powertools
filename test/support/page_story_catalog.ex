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

  @phase80_forbidden_copy [
    "Are you sure?",
    "Something went wrong",
    "An error occurred",
    "N/A"
  ]

  defp phase80_stories do
    [
      phase80_story(
        "page-jobs-empty-browse",
        :jobs,
        "Jobs empty browse",
        "Zero rows retain exact state counts, filters, range truth, and recovery copy.",
        [:filter_bar, :data_table, :empty_state],
        [:empty, :browse],
        [:empty, :ready],
        :none,
        jobs_fixture(:empty_browse),
        ["Jobs", "No jobs match the applied filters"]
      ),
      phase80_story(
        "page-jobs-review-one",
        :jobs,
        "Jobs one-row quick review",
        "One bounded row opens one adaptive production quick-review surface.",
        [:filter_bar, :data_table, :detail_surface],
        [:one, :quick_review],
        [:ready],
        :detail,
        jobs_fixture(:review_one),
        ["Jobs", "Open full job details"]
      ),
      phase80_story(
        "page-jobs-many-filtered",
        :jobs,
        "Jobs many filtered",
        "Applied queue and JSON filters retain exact count and ordinary pagination truth.",
        [:filter_bar, :data_table],
        [:many, :filtered],
        [:ready],
        :none,
        jobs_fixture(:many_filtered),
        ["Jobs", "143 retryable jobs"]
      ),
      phase80_story(
        "page-jobs-thousands-bounded",
        :jobs,
        "Jobs thousands bounded",
        "A count in the thousands projects through exactly one twenty-row page.",
        [:filter_bar, :data_table],
        [:thousands, :bounded],
        [:ready],
        :none,
        jobs_fixture(:thousands_bounded),
        ["Jobs", "2,500 retryable jobs"]
      ),
      phase80_story(
        "page-jobs-final-page-exact",
        :jobs,
        "Jobs exact full final page",
        "The exact-full final page keeps twenty rows and disables forward pagination.",
        [:filter_bar, :data_table],
        [:boundary_pagination, :exact_count],
        [:ready],
        :none,
        jobs_fixture(:final_page_exact),
        ["Jobs", "Showing 41–60 of 60"]
      ),
      phase80_story(
        "page-jobs-invalid-json",
        :jobs,
        "Jobs invalid JSON draft",
        "Invalid JSON remains visible with the production field error and no applied mutation.",
        [:filter_bar, :data_table],
        [:invalid_json, :validation],
        [:error],
        :none,
        jobs_fixture(:invalid_json),
        ["Jobs", "Enter a valid JSON object."]
      ),
      phase80_story(
        "page-jobs-adversarial-redacted",
        :jobs,
        "Jobs adversarial redacted",
        "Long Unicode, emoji, and RTL presentation pressure never exposes source secrets.",
        [:filter_bar, :data_table],
        [:long_module, :non_ascii, :emoji, :rtl, :redacted],
        [:ready],
        :none,
        jobs_fixture(:adversarial_redacted),
        ["Jobs", "לקוחות مرحبا ✅"]
      ),
      phase80_story(
        "page-jobs-explicit-selection",
        :jobs,
        "Jobs explicit cross-page selection",
        "A mixed page checkbox represents selected off-page jobs without duplicating rows.",
        [:filter_bar, :data_table, :button],
        [:explicit_selection, :cross_page],
        [:ready],
        :none,
        jobs_fixture(:explicit_selection),
        ["Jobs", "23 jobs selected"]
      ),
      phase80_story(
        "page-jobs-frozen-all-matching",
        :jobs,
        "Jobs frozen all-matching scope",
        "The confirmation names a frozen exact scope, observation time, and non-atomic boundary.",
        [:filter_bar, :data_table, :confirm_action_dialog],
        [:all_matching, :frozen_scope],
        [:ready],
        :confirmation,
        jobs_fixture(:frozen_all_matching),
        ["Jobs", "This selection was captured at 14:05:00 UTC."]
      ),
      phase80_story(
        "page-jobs-bulk-oversized",
        :jobs,
        "Jobs oversized bulk scope",
        "An oversized selection is rejected without truncation or opening a confirmation.",
        [:filter_bar, :data_table],
        [:oversized, :bounded],
        [:error],
        :none,
        jobs_fixture(:bulk_oversized),
        ["Jobs", "This action is limited to 1,000 jobs."]
      ),
      phase80_story(
        "page-jobs-bulk-zero-ready",
        :jobs,
        "Jobs zero-ready preview",
        "A retained result explains that no selected jobs are ready for execution.",
        [:filter_bar, :data_table, :confirm_action_dialog],
        [:zero_ready, :excluded],
        [:failed],
        :confirmation,
        jobs_fixture(:bulk_zero_ready),
        ["Jobs", "No jobs are ready for this action."]
      ),
      phase80_story(
        "page-jobs-bulk-progress",
        :jobs,
        "Jobs bulk progress",
        "Submitting progress remains coarse, bounded, and non-dismissible.",
        [:filter_bar, :data_table, :confirm_action_dialog, :progress_bar],
        [:submitting, :progress],
        [:loading],
        :confirmation,
        jobs_fixture(:bulk_progress),
        ["Jobs", "Retrying 12 jobs…"]
      ),
      phase80_story(
        "page-jobs-bulk-success",
        :jobs,
        "Jobs bulk success receipt",
        "All-success closes confirmation and leaves one exact durable receipt.",
        [:filter_bar, :data_table, :toast],
        [:success, :receipt],
        [:success],
        :none,
        jobs_fixture(:bulk_success),
        ["Jobs", "Retry requested for 12 jobs. Audit evidence recorded."]
      ),
      phase80_story(
        "page-jobs-bulk-mixed-results",
        :jobs,
        "Jobs mixed bulk results",
        "Partial state visibly retains distinct successful, skipped, and failed rows.",
        [:filter_bar, :data_table, :confirm_action_dialog],
        [:partial, :skipped, :failed],
        [:partial],
        :confirmation,
        jobs_fixture(:bulk_mixed_results),
        ["Jobs", "Retry requests finished with mixed results."]
      ),
      phase80_story(
        "page-jobs-bulk-drifted",
        :jobs,
        "Jobs drifted bulk preview",
        "A changed frozen scope requires a fresh preview before any retry.",
        [:filter_bar, :data_table, :confirm_action_dialog],
        [:drifted, :stale],
        [:stale],
        :confirmation,
        jobs_fixture(:bulk_drifted),
        ["Jobs", "This preview is out of date."]
      ),
      phase80_story(
        "page-jobs-bulk-disconnected",
        :jobs,
        "Jobs disconnected bulk run",
        "Browser disconnect truth keeps accepted work independent of socket ownership.",
        [:filter_bar, :data_table, :confirm_action_dialog, :progress_bar],
        [:disconnected, :submitting],
        [:loading],
        :confirmation,
        jobs_fixture(:bulk_disconnected),
        ["Jobs", "Closing this page will not stop work already started."]
      ),
      phase80_story(
        "page-jobs-bulk-interrupted",
        :jobs,
        "Jobs interrupted bulk run",
        "Interrupted work keeps completed evidence and directs recovery through Audit.",
        [:filter_bar, :data_table, :confirm_action_dialog],
        [:interrupted, :partial],
        [:partial],
        :confirmation,
        jobs_fixture(:bulk_interrupted),
        ["Jobs", "This run may have been interrupted."]
      ),
      phase80_story(
        "page-jobs-full-detail",
        :jobs,
        "Jobs full detail",
        "Full production detail shows legal actions, bounded failures, and redacted data.",
        [:surface, :button, :description_list, :code_block],
        [:full_detail, :redacted],
        [:ready],
        :none,
        jobs_fixture(:full_detail),
        ["Job 8077", "Failure details are redacted."]
      ),
      phase80_story(
        "page-forensics-empty-chooser",
        :forensics,
        "Forensics empty chooser",
        "The typed chooser opens with explicit empty-state instructions.",
        [:filter_bar, :empty_state],
        [:empty, :chooser],
        [:empty],
        :none,
        forensics_fixture(:empty_chooser),
        ["Forensics", "Choose evidence to inspect."]
      ),
      phase80_story(
        "page-forensics-workflow-complete",
        :forensics,
        "Forensics complete workflow evidence",
        "Complete workflow diagnosis leads with current truth and one native next step.",
        [:filter_bar, :description_list, :timeline],
        [:workflow, :complete],
        [:ready],
        :none,
        forensics_fixture(:workflow_complete),
        ["Forensics", "Investigation summary"]
      ),
      phase80_story(
        "page-forensics-incident-partial-remediation",
        :forensics,
        "Forensics partial incident remediation",
        "Partial incident evidence separates current diagnosis from historical remediation.",
        [:filter_bar, :description_list, :timeline],
        [:incident, :partial, :historical_remediation],
        [:partial],
        :none,
        forensics_fixture(:incident_partial_remediation),
        ["Forensics", "Latest remediation evidence"]
      ),
      phase80_story(
        "page-forensics-cron-bounded",
        :forensics,
        "Forensics bounded cron evidence",
        "Cron history names its retained bounded source and authorized destination.",
        [:filter_bar, :description_list, :timeline],
        [:cron, :bounded],
        [:ready],
        :none,
        forensics_fixture(:cron_bounded),
        ["Forensics", "Cron schedule evidence"]
      ),
      phase80_story(
        "page-forensics-limiter-bounded",
        :forensics,
        "Forensics bounded limiter evidence",
        "Limiter history retains current blockers and bounded provenance.",
        [:filter_bar, :description_list, :timeline],
        [:limiter, :bounded],
        [:ready],
        :none,
        forensics_fixture(:limiter_bounded),
        ["Forensics", "Limiter blocker evidence"]
      ),
      phase80_story(
        "page-forensics-unavailable",
        :forensics,
        "Forensics unavailable evidence",
        "Missing and unauthorized scopes remain intentionally indistinguishable.",
        [:filter_bar, :empty_state],
        [:unavailable],
        [:unavailable],
        :none,
        forensics_fixture(:unavailable),
        ["Forensics", "Evidence unavailable"]
      ),
      phase80_story(
        "page-forensics-conflicting-scope",
        :forensics,
        "Forensics conflicting scope",
        "Conflicting direct parameters explain replacement and return to the empty chooser.",
        [:filter_bar, :empty_state],
        [:conflicting_scope, :canonical_empty],
        [:error, :empty],
        :none,
        forensics_fixture(:conflicting_scope),
        ["Forensics", "Choose one evidence type"]
      ),
      phase80_story(
        "page-forensics-unknown-coverage",
        :forensics,
        "Forensics unknown coverage",
        "Retained evidence remains useful while total availability stays explicitly unknown.",
        [:filter_bar, :description_list, :timeline],
        [:unknown_coverage],
        [:ready],
        :none,
        forensics_fixture(:unknown_coverage),
        ["Forensics", "Total availability is unknown."]
      ),
      phase80_story(
        "page-forensics-history-unavailable",
        :forensics,
        "Forensics history unavailable",
        "Current diagnosis remains visible without implying an empty complete history.",
        [:filter_bar, :description_list, :timeline],
        [:history_unavailable],
        [:unavailable],
        :none,
        forensics_fixture(:history_unavailable),
        ["Forensics", "Event history unavailable."]
      ),
      phase80_story(
        "page-forensics-deep-timeline",
        :forensics,
        "Forensics deep bounded timeline",
        "A larger retained source projects newest-first through exactly fifty events.",
        [:filter_bar, :description_list, :timeline],
        [:deep_timeline, :bounded],
        [:ready],
        :none,
        forensics_fixture(:deep_timeline),
        ["Forensics", "Showing the newest 50 of 80 retained events."]
      ),
      phase80_story(
        "page-forensics-adversarial-redacted",
        :forensics,
        "Forensics adversarial redacted",
        "Long Unicode, emoji, RTL, and redacted notes stay safe and bounded.",
        [:filter_bar, :description_list, :timeline],
        [:long_url, :non_ascii, :emoji, :rtl, :redacted],
        [:ready],
        :none,
        forensics_fixture(:adversarial_redacted),
        ["Forensics", "לקוחות مرحبا ✅ — evidence redacted"]
      ),
      phase80_story(
        "page-forensics-restricted-guidance",
        :forensics,
        "Forensics restricted guidance",
        "Unauthorized and duplicate destinations are omitted without inventing authority.",
        [:filter_bar, :description_list, :timeline],
        [:permission_denied, :deduplicated_guidance],
        [:permission_denied, :ready],
        :none,
        forensics_fixture(:restricted_guidance),
        ["Forensics", "No authorized follow-up destination is available"]
      )
    ]
  end

  defp phase80_story(
         id,
         page,
         name,
         description,
         components,
         variant,
         state,
         activation,
         fixtures,
         required_text
       ) do
    %{
      id: id,
      kind: :page,
      page: page,
      name: name,
      description: description,
      components: components,
      variant: variant,
      state: state,
      fixtures: fixtures,
      activation: activation,
      acceptance: %{
        required_text: required_text,
        forbidden_text: @phase80_forbidden_copy,
        ordered_text: required_text,
        roles: [
          %{
            role: "heading",
            name:
              if(page == :jobs and id == "page-jobs-full-detail",
                do: "Job 8077",
                else: page_heading(page)
              ),
            level: 1,
            states: %{}
          }
        ]
      },
      test_targets: %{
        story: "obpt-page-story-#{id}",
        snapshot: "showcase/#{id}",
        a11y: ~s([data-obpt-page-story="#{id}"])
      }
    }
  end

  defp page_heading(:jobs), do: "Jobs"
  defp page_heading(:forensics), do: "Forensics"

  defp jobs_fixture(kind) do
    base = jobs_base_fixture()

    case kind do
      :empty_browse ->
        base

      :review_one ->
        row = job_row(8001, %{reviewing?: true})

        %{base | rows: [row], exact_count: 1, result_summary: "1 retryable job"}
        |> put_in([:pagination], jobs_pagination(1, 1, 1))
        |> Map.merge(%{
          quick_review_id: 8001,
          quick_review: %{
            id: 8001,
            title: "Job 8001",
            state: %{value: "retryable", label: "Retryable"},
            worker: row.worker,
            queue: row.queue,
            attempts: row.attempts,
            relevant_time: %{
              label: "Attempted",
              value: "July 19, 2026 at 14:05 UTC",
              datetime: @observed_datetime
            },
            failure_summary: "Failure details are redacted.",
            recorded_output_available?: false,
            enqueue_redaction: %{redacted?: true, summary: "Sensitive values are [redacted]."},
            full_details_href: "/ops/jobs/jobs/8001"
          }
        })

      :many_filtered ->
        rows = job_rows(20)

        %{base | rows: rows, exact_count: 143, result_summary: "143 retryable jobs"}
        |> put_in([:filter], %{state: "retryable", queue: "critical-mailer"})
        |> put_in(
          [:filter_form],
          %{
            "queue" => "critical-mailer",
            "worker" => "",
            "tags" => "customer, urgent",
            "args" => ~s({"tenant":"east"}),
            "meta" => ""
          }
        )
        |> put_in(
          [:active_filters],
          [
            %{
              id: "queue",
              label: "Queue",
              value: "critical-mailer",
              remove_href: "/ops/jobs/jobs?state=retryable",
              remove_label: "Remove Queue filter"
            },
            %{
              id: "args",
              label: "Args contain",
              value: ~s({"tenant":"east"}),
              remove_href: "/ops/jobs/jobs?state=retryable&queue=critical-mailer",
              remove_label: "Remove Args contain filter"
            }
          ]
        )
        |> put_in([:filters_expanded?], true)
        |> put_in([:pagination], jobs_pagination(1, 143, 20))

      :thousands_bounded ->
        %{base | rows: job_rows(20), exact_count: 2_500, result_summary: "2,500 retryable jobs"}
        |> put_in([:pagination], jobs_pagination(1, 2_500, 20))

      :final_page_exact ->
        rows = job_rows(20, 41)

        %{base | rows: rows, exact_count: 60, result_summary: "60 retryable jobs"}
        |> put_in([:filter], %{state: "retryable", page: 3})
        |> put_in([:pagination], jobs_pagination(3, 60, 20))

      :invalid_json ->
        base
        |> put_in([:filter_form, "args"], "{not-json")
        |> put_in([:filter_errors], %{args: ["Enter a valid JSON object."]})
        |> put_in([:filters_dirty?], true)
        |> put_in([:filters_expanded?], true)

      :adversarial_redacted ->
        row =
          job_row(8061, %{
            worker:
              "MyApp.Workers.ReconcileInternationalCustomerNotificationDeliveryWithLongIdentifier",
            queue: "לקוחות مرحبا ✅",
            attempts: "20 of 20"
          })

        %{base | rows: [row], exact_count: 1, result_summary: "1 retryable job"}
        |> put_in([:pagination], jobs_pagination(1, 1, 1))

      :explicit_selection ->
        rows =
          job_rows(20)
          |> Enum.with_index()
          |> Enum.map(fn {row, index} ->
            put_in(row, [:selection, :checked?], index in [0, 1, 4])
          end)

        %{base | rows: rows, exact_count: 143, result_summary: "143 retryable jobs"}
        |> Map.merge(%{
          selected_count: 23,
          selected_jobs: [8001, 8002, 8005, 7901, 7902],
          page_selection_state: :mixed,
          selection_scope_copy: "23 jobs selected, including 20 jobs from other pages.",
          bulk_action_enabled: %{retry: true, cancel: true, discard: true}
        })
        |> put_in([:pagination], jobs_pagination(1, 143, 20))

      :frozen_all_matching ->
        jobs_bulk_fixture(base, :preview, 143, 143)

      :bulk_oversized ->
        %{base | selected_count: 1_001, exact_count: 1_001}
        |> Map.put(
          :selection_scope_copy,
          "1,001 jobs selected from the applied filters."
        )
        |> Map.put(
          :error_message,
          "This action is limited to 1,000 jobs. Narrow the applied filters before continuing."
        )

      :bulk_zero_ready ->
        jobs_bulk_fixture(base, :failed, 12, 0)
        |> update_in([:bulk_confirmation_action, :bulk_scope], fn _scope -> nil end)
        |> Map.put(
          :bulk_result_summary,
          "No jobs are ready for this action. Review the excluded jobs or create a fresh preview after the jobs change."
        )

      :bulk_progress ->
        jobs_bulk_fixture(base, :submitting, 12, 12)
        |> Map.put(:bulk_progress, %{processed: 7, total: 12})
        |> Map.put(:bulk_announcement, "7 of 12 jobs processed.")

      :bulk_success ->
        Map.put(
          base,
          :success_message,
          "Retry requested for 12 jobs. Audit evidence recorded."
        )

      :bulk_mixed_results ->
        jobs_bulk_fixture(base, :partial, 12, 12)
        |> Map.put(:bulk_result_summary, "Retry finished with mixed results.")
        |> Map.put(:bulk_result_page, %{
          page: 1,
          total_pages: 1,
          previous?: false,
          next?: false,
          results: [
            bulk_result("success-1", "Job 8001", :success, "Retry request recorded.", nil),
            bulk_result(
              "skipped-2",
              "Job 8002",
              :skipped,
              "Job changed before execution.",
              "Create a fresh preview."
            ),
            bulk_result(
              "failed-3",
              "Job 8003",
              :failed,
              "Retry request was not recorded.",
              "Review Audit evidence before retrying."
            )
          ]
        })

      :bulk_drifted ->
        jobs_bulk_fixture(base, :drifted, 12, 12)
        |> Map.put(
          :bulk_result_summary,
          "This preview is out of date because one or more jobs changed. Create a new preview before continuing."
        )

      :bulk_disconnected ->
        jobs_bulk_fixture(base, :submitting, 12, 12)
        |> Map.put(:bulk_progress, %{processed: 4, total: 12})
        |> Map.put(
          :bulk_announcement,
          "Connection lost. Closing this page will not stop work already started."
        )

      :bulk_interrupted ->
        jobs_bulk_fixture(base, :partial, 12, 12)
        |> Map.put(
          :bulk_result_summary,
          "This run may have been interrupted. Review the Audit log for completed actions before creating a fresh preview."
        )
        |> Map.put(:bulk_result_page, %{
          page: 1,
          total_pages: 1,
          previous?: false,
          next?: false,
          results: [
            bulk_result("recorded-1", "Job 8001", :success, "Retry request recorded.", nil),
            bulk_result(
              "unknown-2",
              "Job 8002",
              :failed,
              "Completion could not be established.",
              "Review matching Audit evidence."
            )
          ]
        })

      :full_detail ->
        jobs_detail_fixture()
    end
  end

  defp jobs_base_fixture do
    %{
      page_mode: :index,
      rows: [],
      counts: %{
        "all" => 0,
        "available" => 0,
        "scheduled" => 0,
        "executing" => 0,
        "retryable" => 0,
        "completed" => 0,
        "discarded" => 0,
        "cancelled" => 0
      },
      exact_count: 0,
      filter: %{state: "retryable"},
      filter_form: %{
        "queue" => "",
        "worker" => "",
        "tags" => "",
        "args" => "",
        "meta" => ""
      },
      filter_copy: %{
        tags_help: "Separate tags with commas. Jobs must contain every listed tag.",
        json_help:
          "Enter a JSON object. Filter values are stored in the URL; do not enter secrets."
      },
      filter_errors: %{},
      filters_dirty?: false,
      filters_expanded?: false,
      active_filters: [],
      clear_filters_href: "/ops/jobs/jobs?state=retryable",
      result_summary: "0 retryable jobs",
      pagination: jobs_pagination(1, 0, 0),
      page_selection_state: :unchecked,
      selected_count: 0,
      selected_jobs: [],
      all_matching_offer?: false,
      selection_scope_copy: nil,
      bulk_action_enabled: %{retry: false, cancel: false, discard: false},
      read_only?: false,
      url_notice: nil,
      review_notice: nil,
      quick_review: nil,
      quick_review_id: nil,
      bulk_action_kind: nil,
      bulk_confirmation_action: nil,
      bulk_confirmation_state: :preview,
      bulk_confirmation_form: nil,
      bulk_preview: nil,
      bulk_progress: nil,
      bulk_results: [],
      bulk_result_page: nil,
      bulk_result_summary: nil,
      bulk_announcement: nil,
      error_message: nil,
      success_message: nil
    }
  end

  defp jobs_pagination(page, total_count, row_count) do
    from = if row_count == 0, do: 0, else: (page - 1) * 20 + 1
    to = if row_count == 0, do: 0, else: from + row_count - 1
    total_pages = max(1, ceil(total_count / 20))

    %{
      page: page,
      page_size: 20,
      total_count: total_count,
      from: from,
      to: to,
      previous?: page > 1,
      next?: page < total_pages,
      total_pages: total_pages,
      summary: "Showing #{from}–#{to} of #{total_count}"
    }
  end

  defp job_rows(count, start_id \\ 1) do
    for offset <- 0..(count - 1), do: job_row(8000 + start_id + offset)
  end

  defp job_row(id, overrides \\ %{}) do
    reviewing? = Map.get(overrides, :reviewing?, false)
    selected? = Map.get(overrides, :selected?, false)

    %{
      id: id,
      worker: Map.get(overrides, :worker, "MyApp.Workers.DeliverNotification"),
      state: Map.get(overrides, :state, "retryable"),
      queue: Map.get(overrides, :queue, "critical-mailer"),
      scheduled: %{
        label: "July 19, 2026 at 14:05 UTC",
        datetime: @observed_datetime
      },
      attempts: Map.get(overrides, :attempts, "3 of 20"),
      selection: %{label: "Select job #{id}", checked?: selected?},
      review: %{label: "Review job #{id}", current?: reviewing?}
    }
  end

  defp jobs_bulk_fixture(base, state, selected_count, ready_count) do
    action = %{
      intent: :warning,
      title: "Retry #{ready_count} ready jobs",
      object_label: "#{selected_count} selected jobs",
      scope:
        "#{selected_count} selected, #{ready_count} ready, #{selected_count - ready_count} excluded, 0 off-page. This selection was captured at 14:05:00 UTC. New matching jobs will not be included.",
      bulk_scope: "All matching frozen scope. State Retryable.",
      consequence:
        "Powertools requests a retry for each ready job. A retry request does not mean the job completed.",
      reversibility: "A retry request cannot be undone.",
      support_boundary:
        "Each Lifeline action records independent per-job evidence; the batch is not atomic.",
      confirm_label: "Retry #{ready_count} jobs",
      dismiss_label: "Keep current state",
      pending_copy: "Retrying #{ready_count} jobs…"
    }

    base
    |> Map.merge(%{
      selected_count: selected_count,
      all_matching_offer?: false,
      selection_scope_copy:
        "#{selected_count} jobs selected. This selection was captured at 14:05:00 UTC.",
      bulk_action_enabled: %{retry: true, cancel: false, discard: false},
      bulk_action_kind: :retry,
      bulk_confirmation_action: action,
      bulk_confirmation_state: state,
      bulk_confirmation_form: %{
        "reason" => "Provider recovered; retry safely.",
        "confirmation_count" => Integer.to_string(ready_count)
      },
      bulk_preview: %{
        receipt: %{
          selected: selected_count,
          ready: ready_count,
          excluded: selected_count - ready_count
        }
      }
    })
  end

  defp bulk_result(id, object_label, outcome, message, recovery) do
    %{
      id: id,
      object_label: object_label,
      outcome: outcome,
      message: message,
      recovery: recovery,
      audit_href: nil
    }
  end

  defp jobs_detail_fixture do
    %{
      page_mode: :detail,
      detail_unavailable?: false,
      back_path: "/ops/jobs/jobs?state=retryable&page=2",
      read_only?: false,
      action_controls: [
        %{
          kind: :retry,
          intent: :warning,
          confirm_label: "Retry job",
          disabled_reason: nil
        },
        %{
          kind: :cancel,
          intent: :danger,
          confirm_label: "Cancel job",
          disabled_reason: nil
        }
      ],
      detail: %{
        support: %{
          heading: "Current job state",
          state: "retryable",
          state_label: "Retryable",
          summary: "This job may be retried after operator review.",
          availability: "Current state was observed at July 19, 2026 at 14:05 UTC."
        },
        actions: [],
        identity: [
          %{label: "Job ID", value: "8077", value_kind: :text},
          %{
            label: "Worker",
            value: "MyApp.Workers.DeliverInternationalNotification",
            value_kind: :code
          },
          %{label: "Queue", value: "critical-mailer", value_kind: :text},
          %{label: "State", value: "Retryable", value_kind: :status},
          %{label: "Attempts", value: "20 of 20", value_kind: :text},
          %{label: "Priority", value: "0", value_kind: :text}
        ],
        timing: [
          %{label: "Inserted", value: "July 19, 2026 at 13:55 UTC", datetime: @earlier_datetime},
          %{
            label: "Scheduled",
            value: "July 19, 2026 at 14:05 UTC",
            datetime: @observed_datetime
          },
          %{
            label: "Attempted",
            value: "July 19, 2026 at 14:05 UTC",
            datetime: @observed_datetime
          },
          %{label: "Completed", value: "Unavailable", datetime: nil},
          %{label: "Cancelled", value: "Unavailable", datetime: nil},
          %{label: "Discarded", value: "Unavailable", datetime: nil}
        ],
        errors: [
          %{
            class: "Failure class unavailable",
            message: "Failure details are redacted.",
            occurred_at: "July 19, 2026 at 14:05 UTC",
            occurred_datetime: @observed_datetime,
            attempt: 20,
            truncated?: false
          }
        ],
        data: %{
          arguments: %{
            label: "Arguments",
            kind: :args,
            display: redacted_display("Arguments hidden by display policy.")
          },
          metadata: %{
            label: "Metadata",
            kind: :meta,
            display: redacted_display("Metadata hidden by display policy.")
          },
          recorded_output: %{
            label: "Recorded output",
            kind: :recorded_output,
            display: %{
              available?: true,
              redacted?: true,
              summary: "Recorded output is [redacted].",
              status: "Redacted",
              payload: nil,
              attempt: 20,
              payload_bytes: 384,
              recorded_at: @observed_datetime,
              retention: "Retained for 7 days.",
              expires_at: "2026-07-26T14:05:00Z"
            }
          }
        },
        redaction: %{
          enqueue: %{redacted?: true, summary: "2 argument fields were redacted at enqueue."},
          policy: "Sensitive arguments, metadata, output, and errors remain [redacted]."
        },
        destinations: [
          %{
            id: "job-audit",
            label: "View matching audit evidence",
            href: "/ops/jobs/audit?resource_type=job&resource_id=8077"
          },
          %{
            id: "job-forensics",
            label: "Open job forensics",
            href: "/ops/jobs/forensics?evidence_type=workflow&workflow_id=job-8077"
          }
        ]
      },
      confirmation_action: nil,
      confirmation_state: :preview,
      confirmation_form: nil,
      confirmation_results: [],
      confirmation_object_label: nil,
      confirmation_fallback_id: nil,
      confirmation_audit_href: nil,
      receipt: nil
    }
  end

  defp redacted_display(summary) do
    %{
      available?: true,
      redacted?: true,
      summary: summary,
      status: "Redacted",
      payload: nil
    }
  end

  defp forensics_fixture(kind) do
    base = forensics_base_fixture()

    case kind do
      :empty_chooser ->
        base

      :workflow_complete ->
        forensics_ready_fixture(base, :workflow, %{
          subject: "Workflow nightly-reconciliation · Step deliver",
          diagnosis: "Waiting",
          detail: "The deliver step is waiting for its declared dependency.",
          completeness: "Complete",
          coverage_summary: "Showing all 3 available events in this source window.",
          events: forensic_events(3, "Workflow"),
          next_steps: [
            %{
              id: "open-workflow",
              label: "Open workflow",
              href: "/ops/jobs/workflows/wf-nightly",
              role: :primary,
              support: "Review the current workflow diagnosis before taking any action."
            }
          ]
        })

      :incident_partial_remediation ->
        forensics_ready_fixture(base, :incident, %{
          subject: "Lifeline incident payments-timeout",
          diagnosis: "Needs review",
          detail: "Current incident evidence remains partial after historical remediation.",
          completeness: "Partial evidence",
          coverage_summary: "Showing 4 of 7 retained events.",
          events: forensic_events(4, "Lifeline"),
          next_steps: [
            %{
              id: "review-incident-in-lifeline",
              label: "Review incident in Lifeline",
              href: "/ops/jobs/lifeline?incident=payments-timeout",
              role: :primary,
              support:
                "Review current evidence and reauthorize the incident before taking any action."
            }
          ],
          latest_remediation: %{
            heading: "Latest remediation evidence",
            historical?: true,
            status: "Success",
            summary:
              "Historical Lifeline repair evidence was recorded. It does not change the current diagnosis.",
            occurred_at: "July 19, 2026 at 13:55 UTC",
            occurred_datetime: @earlier_datetime,
            provenance: "Durable evidence"
          }
        })

      :cron_bounded ->
        forensics_ready_fixture(base, :cron, %{
          subject: "Cron schedule evidence · nightly-notifications",
          diagnosis: "Scheduled",
          detail: "The retained schedule shows the latest bounded claims.",
          completeness: "Complete",
          coverage_summary: "Showing 5 of 12 retained events.",
          events: forensic_events(5, "Cron"),
          next_steps: [
            %{
              id: "open-cron-entry",
              label: "Open cron entry",
              href: "/ops/jobs/cron?entry=nightly-notifications",
              role: :primary,
              support: "Review current schedule evidence before taking any action."
            }
          ]
        })

      :limiter_bounded ->
        forensics_ready_fixture(base, :limiter, %{
          subject: "Limiter blocker evidence · critical-mailer",
          diagnosis: "Blocked",
          detail: "Current limiter evidence identifies one active blocker.",
          completeness: "Complete",
          coverage_summary: "Showing 6 of 18 retained events.",
          events: forensic_events(6, "Limiter"),
          next_steps: [
            %{
              id: "review-limiter-blockers",
              label: "Review limiter blockers",
              href: "/ops/jobs/limiters?resource=critical-mailer",
              role: :primary,
              support: "Review current blocker evidence before taking any action."
            }
          ]
        })

      :unavailable ->
        %{base | scope_state: :unavailable}

      :conflicting_scope ->
        %{
          base
          | scope_notice: %{
              heading: "Choose one evidence type",
              copy:
                "Conflicting scope values were not applied. Select one evidence type and inspect it again.",
              focus?: true
            }
        }

      :unknown_coverage ->
        forensics_ready_fixture(base, :workflow, %{
          subject: "Workflow unknown-coverage",
          diagnosis: "Waiting",
          detail:
            "Current evidence is retained, but complete source coverage cannot be established.",
          completeness: "Unknown",
          coverage_summary: "Total availability is unknown.",
          events: forensic_events(3, "Workflow"),
          next_steps: []
        })

      :history_unavailable ->
        forensics_ready_fixture(base, :incident, %{
          subject: "Lifeline incident history-unavailable",
          diagnosis: "Needs review",
          detail: "Current diagnosis is available without retained event history.",
          completeness: "History unavailable",
          coverage_summary: "Showing 0 retained events; total availability is unknown.",
          events: [],
          next_steps: []
        })

      :deep_timeline ->
        forensics_ready_fixture(base, :workflow, %{
          subject: "Workflow deep-history",
          diagnosis: "Waiting",
          detail: "The newest retained evidence is shown in a bounded timeline.",
          completeness: "Partial evidence",
          coverage_summary: "Showing the newest 50 of 80 retained events.",
          events: forensic_events(50, "Workflow"),
          total_count: 80,
          has_more?: true,
          next_steps: []
        })

      :adversarial_redacted ->
        forensics_ready_fixture(base, :incident, %{
          subject: "לקוחות مرحبا ✅ — evidence redacted",
          diagnosis: "Needs review",
          detail:
            "Long international evidence remains bounded. Sensitive source fields are [redacted].",
          completeness: "Partial evidence",
          coverage_summary: "Showing 2 of 4 retained events.",
          events: [
            forensic_event(
              1,
              "לקוחות مرحبا ✅ — evidence redacted",
              "Sensitive source fields are [redacted]."
            ),
            forensic_event(2, "Unicode evidence normalized", "No raw source payload is retained.")
          ],
          next_steps: []
        })

      :restricted_guidance ->
        forensics_ready_fixture(base, :limiter, %{
          subject: "Limiter restricted-guidance",
          diagnosis: "Blocked",
          detail: "Current evidence is visible while follow-up destinations remain restricted.",
          completeness: "Complete",
          coverage_summary: "Showing all 2 available events in this source window.",
          events: forensic_events(2, "Limiter"),
          next_steps: []
        })
    end
  end

  defp forensics_base_fixture do
    %{
      scope_form: %{
        "evidence_type" => "",
        "workflow_id" => "",
        "step" => "",
        "incident_fingerprint" => "",
        "view" => "",
        "resource_id" => ""
      },
      scope_state: :empty,
      scope_notice: nil,
      support: %{
        state: :ready,
        heading: "Read-only evidence",
        copy: "Forensics summarizes retained Powertools evidence and does not prove root cause."
      },
      summary: nil,
      next_steps: [],
      latest_remediation: nil,
      events: [],
      coverage: nil,
      audit_href: nil
    }
  end

  defp forensics_ready_fixture(base, type, attrs) do
    events = Map.fetch!(attrs, :events)
    total_count = Map.get(attrs, :total_count, length(events))
    has_more? = Map.get(attrs, :has_more?, total_count > length(events))

    %{base | scope_state: :ready}
    |> Map.put(:scope_form, forensic_scope_form(type))
    |> Map.put(:summary, %{
      heading: "Investigation summary",
      scope: %{
        subject: Map.fetch!(attrs, :subject),
        type_label: forensic_type_label(type),
        ownership: "Powertools-native retained evidence"
      },
      diagnosis: Map.fetch!(attrs, :diagnosis),
      detail: Map.fetch!(attrs, :detail),
      provenance: "Durable evidence",
      completeness: Map.fetch!(attrs, :completeness),
      coverage: Map.fetch!(attrs, :coverage_summary)
    })
    |> Map.put(:next_steps, Map.fetch!(attrs, :next_steps))
    |> Map.put(:latest_remediation, Map.get(attrs, :latest_remediation))
    |> Map.put(:events, events)
    |> Map.put(:coverage, %{
      heading: "Evidence limits and sources",
      summary: Map.fetch!(attrs, :coverage_summary),
      shown_count: length(events),
      total_count: total_count,
      has_more?: has_more?,
      bounded?: true,
      completeness: Map.fetch!(attrs, :completeness),
      retention: "Only the retained evidence available to this bounded source is shown.",
      sources: [
        %{
          id: "#{type}-source",
          label: "#{forensic_type_label(type)} source",
          shown_count: length(events),
          total_count: total_count,
          has_more?: has_more?,
          limit: 50,
          provenance: "Durable evidence",
          completeness: Map.fetch!(attrs, :completeness),
          retention: "Newest retained evidence first; bounded to 50 events."
        }
      ]
    })
    |> Map.put(:audit_href, "/ops/jobs/audit?resource_type=#{type}")
  end

  defp forensic_scope_form(:workflow) do
    %{
      "evidence_type" => "workflow",
      "workflow_id" => "wf-nightly",
      "step" => "deliver",
      "incident_fingerprint" => "",
      "view" => "",
      "resource_id" => ""
    }
  end

  defp forensic_scope_form(:incident) do
    %{
      "evidence_type" => "incident",
      "workflow_id" => "",
      "step" => "",
      "incident_fingerprint" => "payments-timeout",
      "view" => "active",
      "resource_id" => ""
    }
  end

  defp forensic_scope_form(type) when type in [:cron, :limiter] do
    %{
      "evidence_type" => Atom.to_string(type),
      "workflow_id" => "",
      "step" => "",
      "incident_fingerprint" => "",
      "view" => "",
      "resource_id" => "#{type}-critical-mailer"
    }
  end

  defp forensic_type_label(:workflow), do: "Workflow"
  defp forensic_type_label(:incident), do: "Lifeline incident"
  defp forensic_type_label(:cron), do: "Cron entry"
  defp forensic_type_label(:limiter), do: "Limiter"

  defp forensic_events(count, source) do
    for index <- 1..count,
        do:
          forensic_event(
            index,
            "#{source} evidence #{index} recorded",
            "Bounded retained evidence #{index}."
          )
  end

  defp forensic_event(index, title, notes) do
    minute = rem(60 - index, 60) |> Integer.to_string() |> String.pad_leading(2, "0")

    %{
      id: "forensic-event-#{index}",
      timestamp: "July 19, 2026 at 14:#{minute} UTC",
      datetime: "2026-07-19T14:#{minute}:00Z",
      title: title,
      source: "Durable evidence",
      status: "Recorded",
      domain: :forensics,
      state: :unknown,
      notes: notes,
      follow_ups: []
    }
  end

  def stories, do: @stories ++ phase80_stories()

  def story!(id) when is_binary(id) do
    stories()
    |> Map.new(&{&1.id, &1})
    |> Map.fetch!(id)
  rescue
    KeyError -> raise ArgumentError, "unknown page story: #{inspect(id)}"
  end

  def story!(id), do: raise(ArgumentError, "unknown page story: #{inspect(id)}")
  def snapshot_name(id), do: "showcase/#{story!(id).id}"
  def a11y_target(id), do: ~s([data-obpt-page-story="#{story!(id).id}"])
end
