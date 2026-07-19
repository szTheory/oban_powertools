defmodule ObanPowertools.OperatorPatternStoryCatalog do
  @moduledoc """
  Deterministic dev/test stories for the operator-pattern showcase.

  Fixtures are normalized presentation data only. They deliberately exclude
  backend structs, preview credentials, implementation errors, and original
  secret values while retaining long, hostile-looking, Unicode, and RTL copy.
  """

  @observed_datetime "2026-07-18T14:05:00Z"
  @observed_at "July 18, 2026 at 14:05 UTC"
  @long_id "01JZ8M5P999999999999999999"
  @long_worker "MyApp.Workers.ReconcileAccountNotificationDeliveryWithAnIntentionallyLongIdentifier"
  @hostile_text "<script>alert('group')</script> مرحبا ✅"

  @confirmation_common %{
    intent: :warning,
    lifecycle: :preview,
    title: "Retry job?",
    object_label: "Job #{@long_id}",
    scope: "1 job in the critical-mailer queue.",
    consequence: "Powertools requests a retry for this job.",
    reversibility: "The retry request cannot be undone.",
    support_boundary: "A retry request does not mean the job completed.",
    reason: "Provider recovered; retry the customer notification.",
    reason_error: nil,
    frozen_count: nil,
    entered_count: nil,
    count_error: nil,
    bulk_scope: nil,
    confirm_label: "Retry job",
    dismiss_label: "Keep current state",
    pending_copy: "Retrying 1 job…",
    results: [],
    recovery: nil,
    receipt: nil
  }

  @filter_common %{
    mode: :submit,
    draft: %{queue: "critical-mailer", state: "retryable", worker: ""},
    applied: %{queue: "all", state: "all"},
    errors: %{},
    active_filters: [],
    dirty: true,
    result_summary: "248 jobs match the applied filters.",
    canonical_params: %{},
    clear_destination: "/ops/jobs/_showcase"
  }

  @detail_common %{
    variant: :adaptive,
    content_state: :ready,
    title: "Job #{@long_id} details",
    resource: "Job #{@long_id}",
    close_label: "Close job details",
    loaded_announcement: "Job #{@long_id} details loaded.",
    full_details_destination: "/ops/jobs/jobs/#{@long_id}",
    selected_id: @long_id,
    canonical_params: %{detail: @long_id},
    body: %{
      worker: @long_worker,
      queue: "critical-mailer",
      state: "retryable",
      summary: "The last delivery attempt failed and a retry is scheduled.",
      observed_at: @observed_at,
      observed_datetime: @observed_datetime
    }
  }

  @attention_common %{
    title: "Critical mailer pressure needs attention",
    summary: "Retryable work is increasing while available capacity is exhausted.",
    impact: "Customer notification delivery is delayed for 248 jobs.",
    observed_at: @observed_at,
    observed_datetime: @observed_datetime,
    domain: :job,
    status: :retryable,
    severity: :warning,
    completeness: :complete,
    primary_action: "Open retryable jobs",
    secondary_actions: ["Open Audit", "Open Forensics"]
  }

  @blocker_common %{
    title: "Why this workflow is blocked",
    summary: "Two current blockers prevent the notification workflow from progressing.",
    impact: "The final notification step cannot start.",
    observed_at: @observed_at,
    observed_datetime: @observed_datetime,
    evidence_state: :current,
    completeness: :complete,
    blockers: [
      %{
        id: "sync-support",
        evidence_kind: :current,
        label: "Support sync has not completed",
        summary: "The support sync step remains retryable.",
        clearing_condition: "The support sync must record a terminal result.",
        evidence_source: "Current workflow state",
        technical_code: "step_retryable"
      },
      %{
        id: "notify-disconnected",
        evidence_kind: :current,
        label: "Notification step is disconnected",
        summary: "No executable predecessor can release the notification step.",
        clearing_condition: "Restore an executable predecessor connection.",
        evidence_source: "Current workflow graph",
        technical_code: "predecessor_disconnected"
      }
    ],
    next_action: "Open workflow evidence"
  }

  @audit_common %{
    sentence: "Miyazaki Haruka requested a retry for job #{@long_id}.",
    outcome: "Retry requested",
    outcome_state: :success,
    actor: "Miyazaki Haruka",
    action: "Requested retry",
    target: "Job #{@long_id}",
    reason: "Provider recovered; retry the customer notification. お客様通知 ✅",
    source: "Powertools operator UI",
    correlation: "audit-event-00000000000000000042",
    occurred_at: @observed_at,
    occurred_datetime: @observed_datetime,
    changes: []
  }

  @story_specs [
    %{
      id: "group-confirm-single-reversible",
      kind: :group,
      name: "Single reversible confirmation",
      description:
        "A warning-weight preview names the object, consequence, and safe retained state.",
      components: [:confirm_action_dialog],
      variant: [:single, :reversible],
      state: [:preview, :ready],
      activation: :overlay,
      fixtures: @confirmation_common
    },
    %{
      id: "group-confirm-single-destructive",
      kind: :group,
      name: "Single destructive confirmation",
      description: "An irreversible discard uses consequence-first copy and a danger action.",
      components: [:confirm_action_dialog],
      variant: [:single, :destructive],
      state: [:preview, :ready],
      activation: :overlay,
      fixtures:
        Map.merge(@confirmation_common, %{
          intent: :danger,
          title: "Discard job?",
          consequence: "Powertools permanently discards this job from future execution.",
          reversibility: "Discarding this job cannot be undone.",
          confirm_label: "Discard job",
          pending_copy: "Discarding 1 job…"
        })
    },
    %{
      id: "group-confirm-bulk-count",
      kind: :group,
      name: "Bulk confirmation with frozen count",
      description:
        "The parent supplies an exact frozen count including work outside the current page.",
      components: [:confirm_action_dialog],
      variant: [:bulk, :count_confirmation],
      state: [:preview, :ready],
      activation: :overlay,
      fixtures:
        Map.merge(@confirmation_common, %{
          title: "Retry 12 jobs?",
          object_label: "12 selected jobs",
          scope: "12 jobs across all matching pages.",
          consequence: "Powertools requests a retry for each of the 12 frozen jobs.",
          frozen_count: 12,
          entered_count: "12",
          bulk_scope: "The selection includes jobs outside this page.",
          confirm_label: "Retry 12 jobs",
          pending_copy: "Retrying 12 jobs…"
        })
    },
    %{
      id: "group-confirm-pending",
      kind: :group,
      name: "Accepted confirmation in progress",
      description:
        "A named busy state suppresses duplicate submission without inventing progress.",
      components: [:confirm_action_dialog],
      variant: [:single, :pending],
      state: [:submitting],
      activation: :overlay,
      fixtures:
        Map.merge(@confirmation_common, %{
          lifecycle: :submitting,
          pending_copy:
            "Retrying 1 job… This action has been accepted and can no longer be canceled."
        })
    },
    %{
      id: "group-confirm-partial-results",
      kind: :group,
      name: "Partial bulk confirmation results",
      description: "Ordered success, failed, and skipped results retain exact recovery evidence.",
      components: [:confirm_action_dialog, :status_pill],
      variant: [:bulk, :result_recovery],
      state: [:partial, :success, :failed, :skipped],
      activation: :overlay,
      fixtures:
        Map.merge(@confirmation_common, %{
          lifecycle: :partial,
          title: "Retry requests finished with mixed results",
          scope: "3 frozen jobs were evaluated.",
          frozen_count: 3,
          entered_count: "3",
          bulk_scope: "The frozen selection includes jobs outside this page.",
          results: [
            %{
              id: "job-result-success",
              object_label: "Job #{@long_id}",
              outcome: :success,
              message: "Retry requested.",
              recovery: nil,
              audit_href: "/ops/jobs/audit?resource=job-success"
            },
            %{
              id: "job-result-failed",
              object_label: "Job 01JZ8M5P999999999999999998",
              outcome: :failed,
              message: "The job changed before the request was recorded.",
              recovery: "Create a new preview for this job.",
              audit_href: nil
            },
            %{
              id: "job-result-skipped",
              object_label: "Job 01JZ8M5P999999999999999997",
              outcome: :skipped,
              message: "The operator role cannot retry this queue.",
              recovery: "Ask a queue administrator to review the job.",
              audit_href: nil
            }
          ],
          recovery: "Review failed and skipped jobs before trying again."
        })
    },
    %{
      id: "group-confirm-drifted-error",
      kind: :group,
      name: "Drifted confirmation recovery",
      description: "An out-of-date preview remains open and requires an explicit fresh preview.",
      components: [:confirm_action_dialog],
      variant: [:single, :recovery],
      state: [:drifted, :stale],
      activation: :overlay,
      fixtures:
        Map.merge(@confirmation_common, %{
          lifecycle: :drifted,
          title: "This preview is out of date",
          recovery: "The job changed. Create a new preview before retrying."
        })
    },
    %{
      id: "group-filter-submit",
      kind: :group,
      name: "Submit-mode filters",
      description:
        "Draft changes remain separate from applied results until Apply filters is submitted.",
      components: [:filter_bar],
      variant: [:submit],
      state: [:draft, :applied],
      activation: :none,
      fixtures: @filter_common
    },
    %{
      id: "group-filter-instant",
      kind: :group,
      name: "Instant single-criterion filters",
      description:
        "One cheap state criterion applies immediately without a misleading submit action.",
      components: [:filter_bar],
      variant: [:instant],
      state: [:applied],
      activation: :none,
      fixtures:
        Map.merge(@filter_common, %{
          mode: :instant,
          draft: %{state: "retryable"},
          applied: %{state: "retryable"},
          dirty: false,
          active_filters: [
            %{
              id: "state-retryable",
              label: "State",
              value: "retryable",
              remove_href: "/ops/jobs/_showcase",
              remove_label: "Remove State: retryable filter"
            }
          ],
          result_summary: "74 jobs match the applied state filter.",
          canonical_params: %{state: "retryable"}
        })
    },
    %{
      id: "group-filter-active-clear",
      kind: :group,
      name: "Applied filter removal and clear",
      description: "Named filters, exact results, individual removal, and clear remain visible.",
      components: [:filter_bar],
      variant: [:submit, :active_filters],
      state: [:applied, :current],
      activation: :none,
      fixtures:
        Map.merge(@filter_common, %{
          draft: %{queue: "critical-mailer", state: "retryable"},
          applied: %{queue: "critical-mailer", state: "retryable"},
          dirty: false,
          active_filters: [
            %{
              id: "queue-critical-mailer",
              label: "Queue",
              value: "critical-mailer",
              remove_href: "/ops/jobs/_showcase?state=retryable",
              remove_label: "Remove Queue: critical-mailer filter"
            },
            %{
              id: "state-retryable",
              label: "State",
              value: "retryable",
              remove_href: "/ops/jobs/_showcase?queue=critical-mailer",
              remove_label: "Remove State: retryable filter"
            }
          ],
          result_summary: "42 jobs match the applied filters.",
          canonical_params: %{queue: "critical-mailer", state: "retryable"}
        })
    },
    %{
      id: "group-filter-unapplied-invalid",
      kind: :group,
      name: "Unapplied invalid filter draft",
      description:
        "Invalid draft values and errors remain visible without changing results or URL truth.",
      components: [:filter_bar],
      variant: [:submit, :validation],
      state: [:invalid, :draft, :unapplied],
      activation: :none,
      fixtures:
        Map.merge(@filter_common, %{
          draft: %{queue: "critical-mailer", state: "not-a-real-state", worker: @hostile_text},
          applied: %{queue: "all", state: "all"},
          errors: %{state: "Choose a known job state."},
          dirty: true,
          canonical_params: %{}
        })
    },
    %{
      id: "group-detail-inline",
      kind: :group,
      name: "Inline job detail",
      description: "One modeless detail tree preserves comparison with surrounding results.",
      components: [:detail_surface],
      variant: [:inline],
      state: [:ready],
      activation: :overlay,
      fixtures: Map.put(@detail_common, :variant, :inline)
    },
    %{
      id: "group-detail-modal",
      kind: :group,
      name: "Modal job detail drawer",
      description: "The same detail tree becomes a modal drawer at constrained widths.",
      components: [:detail_surface],
      variant: [:drawer],
      state: [:ready],
      activation: :overlay,
      fixtures: Map.put(@detail_common, :variant, :drawer)
    },
    %{
      id: "group-detail-loading-unavailable",
      kind: :group,
      name: "Loading and unavailable detail",
      description:
        "Explicit loading, unavailable, and permission-denied copy avoids invented data.",
      components: [:detail_surface, :empty_state],
      variant: [:adaptive, :state_matrix],
      state: [:loading, :empty, :unavailable, :permission_denied],
      activation: :overlay,
      fixtures:
        Map.merge(@detail_common, %{
          content_state: :unavailable,
          body: %{
            summary: "Job details are unavailable. Refresh the job or open Forensics.",
            alternate_states: [:loading, :empty, :permission_denied]
          }
        })
    },
    %{
      id: "group-detail-long-content",
      kind: :group,
      name: "Long and internationalized detail",
      description:
        "Long identifiers, HTML-looking copy, Unicode, and RTL text wrap in one detail tree.",
      components: [:detail_surface, :code_block],
      variant: [:adaptive, :long_content],
      state: [:ready, :long_content],
      activation: :overlay,
      fixtures:
        Map.merge(@detail_common, %{
          body: %{
            worker: @long_worker,
            id: @long_id,
            destination:
              "https://operator.example.test/jobs/#{@long_id}?queue=critical-mailer&attempt=20",
            hostile: @hostile_text,
            explanation:
              "The regional reconciliation step retains complete grammatical recovery guidance across narrow layouts."
          }
        })
    },
    %{
      id: "group-attention-status-severity-matrix",
      kind: :group,
      name: "Attention status and severity matrix",
      description:
        "Domain status remains independent from neutral, info, warning, and danger priority.",
      components: [:attention_card, :status_pill],
      variant: [:matrix],
      state: [:current, :complete],
      activation: :none,
      fixtures:
        Map.put(@attention_common, :matrix, [
          %{status: :available, severity: :neutral, completeness: :complete},
          %{status: :retryable, severity: :warning, completeness: :partial},
          %{status: :discarded, severity: :danger, completeness: :unknown},
          %{status: :completed, severity: :info, completeness: :unavailable}
        ])
    },
    %{
      id: "group-attention-long-content-and-actions",
      kind: :group,
      name: "Long attention content and actions",
      description:
        "A calm primary action and restrained destinations remain readable with long copy.",
      components: [:attention_card],
      variant: [:long_content, :permission],
      state: [:current, :permission_denied],
      activation: :none,
      fixtures:
        Map.merge(@attention_common, %{
          title: "#{@long_worker} requires operator review",
          summary: @hostile_text,
          impact:
            "The affected notification window includes #{@long_id} and may delay multilingual customer messages.",
          primary_action: "Open retryable notification jobs",
          primary_action_disabled_reason: "Requires operator role."
        })
    },
    %{
      id: "group-why-blocked-multiple-causes",
      kind: :group,
      name: "Multiple current blockers",
      description:
        "Every supplied blocker and clearing condition remains visible in caller order.",
      components: [:why_blocked],
      variant: [:multiple_causes],
      state: [:current, :complete],
      activation: :none,
      fixtures: @blocker_common
    },
    %{
      id: "group-why-blocked-live-vs-snapshot",
      kind: :group,
      name: "Current evidence versus block-start snapshot",
      description: "Current truth and historical snapshot evidence retain distinct labels.",
      components: [:why_blocked],
      variant: [:current_vs_snapshot],
      state: [:current, :snapshot, :stale],
      activation: :none,
      fixtures:
        @blocker_common
        |> Map.put(:blockers, [
          hd(@blocker_common.blockers),
          @blocker_common.blockers
          |> Enum.at(1)
          |> Map.put(:evidence_kind, :block_start_snapshot)
        ])
        |> Map.put(:evidence, %{
          current: "The support sync remains retryable at #{@observed_at}.",
          snapshot: "At block start, the support sync was executing.",
          snapshot_datetime: "2026-07-18T13:55:00Z"
        })
    },
    %{
      id: "group-why-blocked-unavailable-evidence",
      kind: :group,
      name: "Unavailable blocker evidence",
      description: "Unknown and unavailable evidence never becomes a false no-blockers claim.",
      components: [:why_blocked],
      variant: [:unavailable],
      state: [:unknown, :unavailable, :permission_denied],
      activation: :none,
      fixtures:
        Map.merge(@blocker_common, %{
          summary: "Current blocker evidence is unknown. Refresh the workflow before acting.",
          evidence_state: :unavailable,
          completeness: :unknown,
          blockers: []
        })
    },
    %{
      id: "group-audit-entry-actor-outcome-matrix",
      kind: :group,
      name: "Audit actor and outcome matrix",
      description:
        "Human, system, and policy actors retain immutable explicit outcomes and absolute time.",
      components: [:audit_entry, :status_pill],
      variant: [:matrix],
      state: [:success, :failed, :skipped],
      activation: :none,
      fixtures:
        Map.put(@audit_common, :matrix, [
          %{actor: "Miyazaki Haruka", outcome: "Retry requested", outcome_state: :success},
          %{actor: "Powertools system", outcome: "Request failed", outcome_state: :failed},
          %{actor: "Queue policy", outcome: "Request skipped", outcome_state: :skipped}
        ])
    },
    %{
      id: "group-audit-entry-missing-fields",
      kind: :group,
      name: "Audit entry with missing fields",
      description:
        "Missing reason, outcome, and correlation stay explicit instead of becoming invented success.",
      components: [:audit_entry],
      variant: [:missing_fields],
      state: [:unknown],
      activation: :none,
      fixtures:
        Map.merge(@audit_common, %{
          sentence: "Powertools system evaluated job #{@long_id}.",
          actor: "Powertools system",
          reason: "No operator reason recorded",
          outcome: "Outcome not recorded",
          outcome_state: :unknown,
          correlation: "Correlation not recorded"
        })
    },
    %{
      id: "group-audit-entry-redacted-changes",
      kind: :group,
      name: "Audit entry with redacted changes",
      description: "Only already-redacted before and after values enter progressive evidence.",
      components: [:audit_entry, :code_block],
      variant: [:redacted_changes],
      state: [:current, :complete],
      activation: :none,
      fixtures:
        Map.put(@audit_common, :changes, [
          %{field: "credential", before: "[redacted]", after: "[redacted]"},
          %{field: "queue", before: "critical-mailer", after: "default"}
        ])
    },
    %{
      id: "group-explain-audit-narrow-layout",
      kind: :group,
      name: "Explanation and audit chain at narrow width",
      description:
        "Attention, blockers, safe action, and immutable audit evidence form one readable chain.",
      components: [:attention_card, :why_blocked, :confirm_action_dialog, :audit_entry],
      variant: [:narrow, :operator_chain],
      state: [:current, :partial, :snapshot],
      activation: :none,
      fixtures: %{
        attention: @attention_common,
        explanation: @blocker_common,
        confirmation_summary: %{
          title: "Retry 12 jobs?",
          consequence: "Powertools requests a retry and records exact per-job results."
        },
        audit: @audit_common,
        hostile: @hostile_text
      }
    }
  ]

  @stories Enum.map(@story_specs, fn story ->
             id = story.id

             Map.put(story, :test_targets, %{
               story: "obpt-group-story-#{id}",
               snapshot: "showcase/#{id}",
               a11y: ~s([data-obpt-group-story="#{id}"])
             })
           end)

  @stories_by_id Map.new(@stories, &{&1.id, &1})

  def stories, do: @stories

  def story!(id) when is_binary(id) do
    Map.fetch!(@stories_by_id, id)
  rescue
    KeyError -> raise ArgumentError, "unknown operator-pattern story: #{inspect(id)}"
  end

  def story!(id), do: raise(ArgumentError, "unknown operator-pattern story: #{inspect(id)}")
  def snapshot_name(id), do: "showcase/#{story!(id).id}"
  def a11y_target(id), do: ~s([data-obpt-group-story="#{story!(id).id}"])
end
