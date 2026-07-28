defmodule ObanPowertools.Web.Components.OperatorPatternsTest do
  use ExUnit.Case, async: true

  @module ObanPowertools.Web.Components.OperatorPatterns
  @source_path "lib/oban_powertools/web/components/operator_patterns.ex"
  @hostile ~s|<script dir="rtl">مرحبا & steal()</script>|
  @secret "PHASE78-SECRET-SENTINEL"

  @components ~w[
    confirm_action_dialog filter_bar detail_surface attention_card audit_entry why_blocked
  ]a

  test "exports exactly the six public Phase 78 operator-pattern components" do
    assert Code.ensure_loaded?(@module),
           "GROUP-01 requires #{@module} before any Phase 78 implementation slice can pass"

    for component <- @components do
      assert function_exported?(@module, component, 1),
             "GROUP-01 requires #{inspect(@module)}.#{component}/1"
    end

    exported_components =
      apply(@module, :__info__, [:functions])
      |> Enum.filter(fn {_name, arity} -> arity == 1 end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.filter(&(&1 in @components))
      |> Enum.sort()

    assert exported_components == Enum.sort(@components)
  end

  test "source pins closed lifecycle, content-state, composition, and ownership contracts" do
    source = read_source!()

    assert source =~ "use Phoenix.Component"
    assert source =~ "Primitives"
    assert source =~ "Forms"
    assert source =~ "DataDisplay"

    for component <- @components do
      assert source =~ ~r/^\s*def #{component}\(/m,
             "GROUP-01 requires a public #{component}/1 function"
    end

    for literal <- ~w[
          preview submitting partial failed expired drifted consumed warning danger
          submit instant adaptive inline drawer loading empty ready stale unavailable
          permission_denied invalid pending success error complete unknown current
          block_start_snapshot off polite assertive neutral info
        ] do
      assert source =~ literal, "closed Phase 78 contract must contain #{literal}"
    end

    for forbidden <- [
          "Phoenix.HTML.raw",
          "String.to_atom",
          "inspect(error)",
          "Oban.Job",
          "RepairPreview",
          "Ecto.Schema",
          "JobsLive",
          "WorkflowsLive",
          "LifelineLive",
          "phx-hook",
          "@rest",
          "attr(:rest",
          "attr(:class",
          "attr(:style"
        ] do
      refute source =~ forbidden, "OperatorPatterns must not contain #{forbidden}"
    end

    refute source =~ ~r/#[0-9a-fA-F]{3,8}/
    refute source =~ ~r/\b\d+(?:\.\d+)?px\b/
  end

  @tag phase78_slice: "explanation"
  test "AttentionCard separates current status, severity, explanation, impact, and evidence" do
    html =
      render_pattern(:attention_card,
        id: "queue-attention",
        title: "Queue pressure needs attention",
        summary: @hostile,
        impact: "12 jobs are waiting outside the current page.",
        observed_at: "July 18, 2026 at 21:00 UTC",
        observed_datetime: "2026-07-18T21:00:00Z",
        domain: :limiter,
        status: :blocked,
        severity: :warning,
        completeness: :unknown,
        live: :off,
        primary_action: [slot(:primary_action, %{}, fn -> "Review current blockers" end)],
        secondary_actions: [slot(:secondary_actions, %{}, fn -> "Open Forensics" end)]
      )

    assert html =~ ~s(id="queue-attention")
    assert html =~ ~s(class="obpt-attention-card)
    assert html =~ "Queue pressure needs attention"
    assert html =~ "Blocked"
    assert html =~ "Warning"
    assert html =~ "12 jobs are waiting outside the current page."
    assert html =~ ~s(datetime="2026-07-18T21:00:00Z")
    assert html =~ "Unknown"

    assert_in_order(html, [
      "Queue pressure needs attention",
      "Blocked",
      "12 jobs are waiting outside the current page.",
      "Review current blockers",
      "Unknown",
      "Open Forensics"
    ])

    refute html =~ ~s(role="alert")
    refute html =~ ~s(role="status")
    assert_escaped(html)
  end

  @tag phase78_slice: "explanation"
  test "WhyBlocked preserves every current and snapshot blocker without inferring truth" do
    blockers = [
      %{
        id: "queue-paused",
        evidence_kind: :current,
        label: "Current state",
        summary: "The critical queue is paused.",
        clearing_condition: "Resume the queue after reviewing the incident.",
        evidence_source: "Live queue state",
        technical_code: "queue_paused"
      },
      %{
        id: "limiter-snapshot",
        evidence_kind: :block_start_snapshot,
        label: "Block-start snapshot",
        summary: @hostile,
        clearing_condition: "Refresh current limiter evidence before acting.",
        evidence_source: "Snapshot captured at block start",
        technical_code: nil
      }
    ]

    html =
      render_pattern(:why_blocked,
        id: "workflow-blockers",
        title: "Why this workflow is blocked",
        summary: "Current blocker evidence is unknown. Refresh the workflow before acting.",
        impact: "Three workflow steps cannot progress.",
        observed_at: "July 18, 2026 at 21:00 UTC",
        observed_datetime: "2026-07-18T21:00:00Z",
        evidence_state: :stale,
        completeness: :partial,
        blockers: blockers,
        next_action: [slot(:next_action, %{}, fn -> "Refresh workflow" end)],
        evidence: [slot(:evidence, %{}, fn -> "Redaction-safe evidence" end)]
      )

    assert html =~ ~s(class="obpt-why-blocked)
    assert count(html, ~s(data-obpt-blocker-id=)) == 2

    assert_in_order(html, [
      "Current blocker evidence is unknown",
      "Current state",
      "The critical queue is paused.",
      "Block-start snapshot",
      "Three workflow steps cannot progress.",
      "Refresh workflow",
      "Partial",
      "Redaction-safe evidence"
    ])

    refute html =~ "No blockers"
    refute html =~ "root cause"
    assert_escaped(html)
  end

  @tag phase78_slice: "explanation"
  test "AuditEntry is immutable historical evidence with explicit missing facts" do
    entry = %{
      sentence: "System policy requested a retry for job job-123.",
      outcome: "Outcome not recorded",
      outcome_state: :unknown,
      actor: "System policy",
      action: "Retry requested",
      target: @hostile,
      reason: "No operator reason recorded",
      source: "Powertools-native",
      correlation: "audit-2026-0001",
      occurred_at: "July 18, 2026 at 21:00 UTC",
      occurred_datetime: "2026-07-18T21:00:00Z",
      changes: nil,
      evidence: nil
    }

    html =
      render_pattern(:audit_entry,
        id: "audit-entry-1",
        entry: entry,
        evidence: [slot(:evidence, %{}, fn -> "Redaction-safe audit evidence" end)]
      )

    assert count(html, "<article") == 1
    assert html =~ ~s(class="obpt-audit-entry)
    assert html =~ "System policy requested a retry for job job-123."
    assert html =~ "No operator reason recorded"
    assert html =~ "Outcome not recorded"
    assert html =~ ~s(<time datetime="2026-07-18T21:00:00Z")
    assert html =~ "July 18, 2026 at 21:00 UTC"
    assert html =~ "Redaction-safe audit evidence"
    refute html =~ "N/A"
    assert_escaped(html)
  end

  test "AuditEntry renders finite outcome state semantics separately from human outcome copy" do
    common = %{
      sentence: "System policy evaluated job job-123.",
      actor: "System policy",
      action: "Evaluated retry",
      target: "job-123",
      reason: "Incident response",
      source: "Powertools-native",
      correlation: "audit-2026-0001",
      occurred_at: "July 18, 2026 at 21:00 UTC",
      occurred_datetime: "2026-07-18T21:00:00Z",
      changes: nil,
      evidence: nil
    }

    for {state, outcome, label, tone, icon} <- [
          {:success, "Retry requested", "Success", "success", "check"},
          {:failed, "Request failed", "Failed", "danger", "alert"},
          {:skipped, "Request skipped", "Skipped", "warning", "alert"}
        ] do
      html =
        render_pattern(:audit_entry,
          id: "audit-entry-#{state}",
          entry: Map.merge(common, %{outcome: outcome, outcome_state: state})
        )

      assert html =~ ~s(data-obpt-audit-outcome="#{state}")
      assert html =~ ~s(data-obpt-tone="#{tone}")
      assert html =~ ~s(data-obpt-icon="#{icon}")
      assert html =~ ~s(class="obpt-status-pill-label">#{label}</span>)
      assert html =~ outcome
    end
  end

  @tag phase79_slice: "shared"
  test "WhyBlocked renders optional affected scope and never exposes technical classifier codes" do
    html =
      render_pattern(:why_blocked,
        id: "limiter-current-blockers",
        title: "Current blockers",
        summary: "Current limiter evidence identifies one blocker.",
        impact: "New reservations are waiting.",
        observed_at: "July 19, 2026 at 14:00 UTC",
        observed_datetime: "2026-07-19T14:00:00Z",
        evidence_state: :current,
        completeness: :complete,
        blockers: [
          %{
            id: "billing-cooldown",
            evidence_kind: :current,
            label: "Cooldown is active",
            summary: "New reservations wait until the cooldown clears.",
            affected_scope: "All queues using the billing limiter",
            clearing_condition: "Wait for the cooldown window to end.",
            evidence_source: "Current limiter state",
            technical_code: "cooldown_active"
          }
        ]
      )

    assert html =~ "Cooldown is active"
    assert html =~ "Affected scope"
    assert html =~ "All queues using the billing limiter"
    refute html =~ "Technical code"
    refute html =~ "cooldown_active"
    assert count(html, "Affected scope") == 1
  end

  @tag phase79_slice: "shared"
  test "WhyBlocked reserves Runnable truth for complete empty current evidence" do
    complete_html =
      render_pattern(:why_blocked,
        id: "limiter-runnable",
        title: "Current blockers",
        summary: "Current limiter evidence is complete.",
        impact: "No current limiter condition prevents new reservations.",
        observed_at: "July 19, 2026 at 14:00 UTC",
        observed_datetime: "2026-07-19T14:00:00Z",
        evidence_state: :current,
        completeness: :complete,
        blockers: []
      )

    unavailable_html =
      render_pattern(:why_blocked,
        id: "limiter-unavailable",
        title: "Current blockers",
        summary: "Current limiter evidence is unavailable.",
        impact: "Current availability cannot be determined.",
        observed_at: "July 19, 2026 at 14:00 UTC",
        observed_datetime: "2026-07-19T14:00:00Z",
        evidence_state: :unavailable,
        completeness: :unavailable,
        blockers: []
      )

    assert complete_html =~ "Runnable"
    refute complete_html =~ "No blockers"
    refute unavailable_html =~ "Runnable"
    refute unavailable_html =~ "No blockers"
  end

  @tag phase79_slice: "shared"
  test "AuditEntry visibly associates Recorded at with its absolute machine-readable time" do
    entry = %{
      sentence: "Operator One paused cron entry nightly.",
      outcome: "Cron entry paused",
      outcome_state: :success,
      actor: "Operator One",
      action: "Pause cron entry",
      target: "cron entry nightly",
      reason: "Scheduled maintenance",
      source: "Powertools-native",
      correlation: "Correlation not recorded",
      occurred_at: "July 19, 2026 at 14:30 UTC",
      occurred_datetime: "2026-07-19T14:30:00Z",
      recorded_at_label: "Recorded at",
      changes: nil,
      evidence: nil
    }

    html = render_pattern(:audit_entry, id: "audit-entry-recorded-at", entry: entry)

    assert html =~ "Recorded at"
    assert html =~ ~s(<time datetime="2026-07-19T14:30:00Z")
    assert_in_order(html, ["Recorded at", "July 19, 2026 at 14:30 UTC"])
    assert count(html, "Recorded at") == 1
  end

  @tag phase79_slice: "shared"
  test "AuditEntry keeps missing source and correlation explicit and neutral" do
    entry = %{
      sentence: "Operator One requested a retry for job 123.",
      outcome: nil,
      outcome_state: :unknown,
      actor: "Operator One",
      action: "Retry requested",
      target: "job 123",
      reason: nil,
      source: nil,
      correlation: nil,
      occurred_at: "July 19, 2026 at 14:45 UTC",
      occurred_datetime: "2026-07-19T14:45:00Z",
      changes: nil,
      evidence: nil
    }

    html = render_pattern(:audit_entry, id: "audit-entry-missing-facts", entry: entry)

    assert html =~ "No operator reason recorded"
    assert html =~ "Outcome not recorded"
    assert html =~ "Source not recorded"
    assert html =~ "Correlation not recorded"
    assert html =~ "Recorded at"
    refute html =~ "N/A"
  end

  test "AuditEntry rejects credential and raw-error evidence before rendering" do
    entry = %{
      sentence: "System policy requested a retry for job job-123.",
      outcome: "Retry requested",
      outcome_state: :success,
      actor: "System policy",
      action: "Retry requested",
      target: "job-123",
      reason: "Incident response",
      source: "Powertools-native",
      correlation: "audit-2026-0001",
      occurred_at: "July 18, 2026 at 21:00 UTC",
      occurred_datetime: "2026-07-18T21:00:00Z",
      changes: nil,
      evidence: nil
    }

    for unsafe_evidence <- [
          %{token: @secret},
          %{authorization: "Bearer #{@secret}"},
          %{password: @secret},
          %{"previewToken" => @secret},
          %{"planHash" => @secret},
          %{"rawError" => "database password: #{@secret}"},
          %{"APIKey" => @secret},
          %{"apikey" => @secret},
          %{"secretKey" => @secret},
          %{"credentials" => @secret},
          %{"clientSecret" => @secret},
          %{"accessToken" => @secret},
          %{"auth_token" => @secret},
          %{"passwd" => @secret},
          %{"sessionToken" => @secret}
        ] do
      unsafe_entry = %{entry | evidence: %{recorded: unsafe_evidence}}

      assert_raise ArgumentError, ~r/prohibited source field/, fn ->
        render_pattern(:audit_entry, id: "unsafe-audit-entry", entry: unsafe_entry)
      end
    end

    assert_raise ArgumentError, ~r/unsupported presentation field/, fn ->
      render_pattern(:audit_entry,
        id: "unclassified-audit-entry",
        entry: %{entry | evidence: %{"unclassifiedMetadata" => @secret}}
      )
    end
  end

  @tag phase78_slice: "filter"
  test "FilterBar submit mode keeps one form tree and applied truth outside disclosure" do
    html =
      render_pattern(:filter_bar,
        id: "job-filters",
        form: filter_form(),
        mode: :submit,
        result_summary: "42 jobs match the applied filters.",
        results_target_id: "job-results",
        active_filters: [
          %{
            id: "queue-critical",
            label: "Queue",
            value: "critical",
            remove_href: "/ops/jobs/jobs?state=available",
            remove_label: "Remove Queue: critical filter"
          }
        ],
        dirty: true,
        filters_expanded: false,
        change_event: "validate-filters",
        submit_event: "apply-filters",
        clear_href: "/ops/jobs/jobs",
        fields: [slot(:fields, %{}, fn -> "Queue field" end)],
        advanced_fields: [slot(:advanced_fields, %{}, fn -> "Worker field" end)]
      )

    assert count(html, "<form") == 1
    assert count(html, ~s(data-obpt-filter-fields)) == 1
    assert html =~ ~s(data-obpt-filter-bar)
    assert html =~ ~s(aria-expanded="false")
    assert html =~ ~s(aria-controls="job-filters-fields")
    assert html =~ "Filters (1 applied)"
    assert html =~ "Queue: critical"
    assert html =~ "Remove Queue: critical filter"
    assert html =~ "Clear filters"
    assert html =~ "Changes not applied."
    assert html =~ "Apply filters"
    assert html =~ ~s(role="status")
    assert html =~ ~s(aria-controls="job-results")
    assert_in_order(html, ["Queue field", "Worker field", "Apply filters"])
    assert outside_controlled_region?(html, "42 jobs match the applied filters.")
    assert outside_controlled_region?(html, "Queue: critical")
  end

  @tag phase80_slice: "forensics"
  test "FilterBar submit mode accepts a page-specific label without changing its default" do
    custom_html =
      render_pattern(:filter_bar,
        id: "forensics-scope",
        form: filter_form(),
        mode: :submit,
        submit_label: "Inspect evidence",
        result_summary: "Choose one supported evidence scope.",
        results_target_id: "forensics-results",
        submit_event: "inspect-evidence",
        fields: [slot(:fields, %{}, fn -> "Evidence type field" end)]
      )

    default_html =
      render_pattern(:filter_bar,
        id: "default-submit-label",
        form: filter_form(),
        mode: :submit,
        result_summary: "42 jobs match the applied filters.",
        results_target_id: "job-results",
        submit_event: "apply-filters",
        fields: [slot(:fields, %{}, fn -> "Queue field" end)]
      )

    assert custom_html =~ "Inspect evidence"
    refute custom_html =~ "Apply filters"
    assert count(custom_html, "<form") == 1
    assert count(custom_html, "Inspect evidence") == 1
    assert default_html =~ "Apply filters"
    refute default_html =~ "Inspect evidence"
  end

  @tag phase78_slice: "filter"
  test "FilterBar instant mode has no submit-only affordance or duplicate field tree" do
    html =
      render_pattern(:filter_bar,
        id: "state-filter",
        form: filter_form(),
        mode: :instant,
        result_summary: "8 jobs match the applied filter.",
        results_target_id: "state-results",
        active_filters: [],
        dirty: true,
        filters_expanded: true,
        change_event: "change-state-filter",
        submit_event: nil,
        clear_href: nil,
        fields: [slot(:fields, %{}, fn -> @hostile end)]
      )

    assert count(html, "<form") == 1
    assert count(html, ~s(data-obpt-filter-fields)) == 1
    refute html =~ "Apply filters"
    refute html =~ "Changes not applied."
    assert_escaped(html)
  end

  @tag phase78_slice: "filter"
  test "FilterBar defaults to submit and keeps canonical destinations parent-owned" do
    html =
      render_pattern(:filter_bar,
        id: "default-filters",
        form: filter_form(),
        result_summary: "1 job matches the applied filters.",
        results_target_id: "default-results",
        active_filters: [
          %{
            "id" => "worker-unicode",
            "label" => "Worker",
            "value" => @hostile,
            "remove_href" => "/ops/jobs/jobs?queue=critical",
            "remove_label" => "Remove Worker filter"
          }
        ],
        clear_href: "/ops/jobs/jobs",
        fields: [slot(:fields, %{}, fn -> "Worker field" end)]
      )

    assert html =~ "Apply filters"
    refute html =~ "Changes not applied."
    assert html =~ ~s(href="/ops/jobs/jobs?queue=critical")
    assert html =~ ~s(href="/ops/jobs/jobs")
    assert_escaped(html)

    filter_source = read_source!() |> function_source(:filter_bar)

    for forbidden <- [
          "Ecto.Query",
          "Repo.",
          "push_patch",
          "push_navigate",
          "StatusPill",
          "URI.encode_query",
          "Plug.Conn.Query"
        ] do
      refute filter_source =~ forbidden
    end
  end

  @tag phase78_slice: "confirmation"
  test "ConfirmActionDialog preview pins consequence-first copy, form, and focus semantics" do
    html =
      render_confirmation(:preview,
        bulk_count: 12,
        bulk_scope: "Includes jobs outside the current page."
      )

    assert count(html, ~s(role="dialog")) == 1
    assert html =~ ~s(aria-modal="true")
    assert html =~ ~s(aria-labelledby="retry-jobs-title")
    assert html =~ ~s(id="retry-jobs-focus-wrap")
    assert html =~ ~s(class="obpt-confirm-action__dialog" tabindex="0")
    assert html =~ ~s(id="retry-jobs-title")
    assert html =~ ~s(tabindex="-1")
    assert html =~ ~s(data-obpt-focus-fallback="job-results-heading")
    assert html =~ ~s(phx-window-keydown)
    assert html =~ ~s(phx-key="Escape")
    assert html =~ "Reason"
    assert html =~ "Explain why this action is needed. Do not enter secrets."
    assert html =~ "Type 12 to confirm"
    assert html =~ "Retry 12 jobs"
    assert html =~ "Keep current state"

    assert_in_order(html, [
      "12 selected jobs",
      "Includes jobs outside the current page.",
      "Powertools requests a retry for each selected job.",
      "A retry request cannot be undone.",
      "Completion remains host-owned.",
      "Reason",
      "Type 12 to confirm",
      "Keep current state"
    ])

    assert last_index_of(html, "Retry 12 jobs") > index_of(html, "Keep current state")

    for generic <- ["Are you sure?", ">Confirm<", ">Cancel<", "Something went wrong", "N/A"] do
      refute html =~ generic
    end

    refute html =~ ~s(role="alertdialog")
    refute html =~ @secret
  end

  @tag phase78_slice: "confirmation"
  test "ConfirmActionDialog exposes named pending, ordered mixed results, and fresh-preview states" do
    pending =
      render_confirmation(:submitting,
        pending_copy: "Retrying 12 jobs…",
        progress: %{value: 3, max: 12}
      )

    assert pending =~ ~s(aria-busy="true")
    assert pending =~ "Retrying 12 jobs…"
    assert pending =~ "This action has been accepted and can no longer be canceled."
    assert pending =~ "3/12"
    refute pending =~ ~s(phx-key="Escape")
    refute pending =~ "Keep current state"
    refute pending =~ "obpt-spinner"

    partial = render_confirmation(:partial)
    assert partial =~ ~s(id="retry-jobs-result-heading")
    assert partial =~ ~s(tabindex="-1")
    assert_in_order(partial, ["Success", "Failed", "Skipped"])
    assert partial =~ "Review failed and skipped jobs before trying again."

    for {state, copy} <- [
          expired: "This preview expired. Create a new preview before continuing.",
          drifted:
            "This preview is out of date because the job changed. Create a new preview before retrying.",
          consumed: "This preview was already used. Create a new preview to run the action again."
        ] do
      html = render_confirmation(state)
      assert html =~ copy
      assert html =~ "Create new preview"
      refute html =~ "Something went wrong"
    end
  end

  @tag phase78_slice: "confirmation"
  test "ConfirmActionDialog source stays presentation-only and excludes disclosure channels" do
    source = read_source!()
    confirmation_source = function_source(source, :confirm_action_dialog)

    assert confirmation_source =~ "<.focus_wrap"
    assert confirmation_source =~ "Forms.textarea"
    assert confirmation_source =~ "Forms.input"
    assert confirmation_source =~ ~s(role="dialog")
    assert confirmation_source =~ "aria-busy"
    assert confirmation_source =~ "data-obpt-focus-fallback"
    assert source =~ "JS.pop_focus"

    for forbidden <- [
          "phx-click-away",
          "alertdialog",
          "preview_token",
          "plan_hash",
          "raw_error",
          "action_atom",
          "Lifeline",
          "Repo.",
          "Ecto.Query",
          "Phoenix.HTML.raw"
        ] do
      refute confirmation_source =~ forbidden
    end
  end

  @tag phase78_slice: "detail"
  test "DetailSurface renders one labelled native tree for every closed variant and state" do
    variants = [:adaptive, :inline, :drawer]
    states = [:loading, :empty, :ready, :unavailable, :permission_denied, :error]

    for variant <- variants, state <- states do
      html =
        render_pattern(:detail_surface,
          id: "job-detail-#{variant}-#{state}",
          title: "Job #{@hostile} details",
          close_label: "Close job details",
          open: true,
          variant: variant,
          state: state,
          resource: "job details",
          logical_fallback_id: "job-results-heading",
          close_event: "close-job-detail",
          loaded_announcement: if(state == :ready, do: "Job 123 details loaded"),
          full_details_href: "/ops/jobs/jobs/123?queue=critical",
          body: [slot(:body, %{}, fn -> "One sensitive-safe body" end)],
          actions: [slot(:actions, %{}, fn -> "Inspect audit" end)],
          evidence: [slot(:evidence, %{}, fn -> "Redaction-safe evidence" end)]
        )

      assert count(html, "<dialog") == 1
      assert count(html, ~s(class="obpt-detail-surface__body")) == 1
      assert count(html, "One sensitive-safe body") <= 1
      assert html =~ ~s(data-obpt-detail-surface)
      assert html =~ ~s(data-obpt-detail-variant="#{variant}")
      assert html =~ ~s(data-obpt-detail-requested="open")
      assert html =~ ~s(aria-labelledby="job-detail-#{variant}-#{state}-title")
      assert html =~ ~s(id="job-detail-#{variant}-#{state}-body")
      assert html =~ ~s(data-obpt-detail-body)
      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(id="job-detail-#{variant}-#{state}-status")
      assert html =~ ~s(aria-label="Close job details")
      assert html =~ ~s(data-obpt-detail-fallback="job-results-heading")
      assert html =~ ~s(data-obpt-detail-state="#{state}")
      assert html =~ ~s(data-obpt-focus-fallback="job-results-heading")
      assert html =~ "Open full details"
      refute html =~ "Phoenix.FocusWrap"
      refute html =~ ~s(aria-modal="true")
      assert_escaped(html)
    end
  end

  @tag phase78_slice: "detail"
  test "DetailSurface source forbids duplicate trees, nested dialogs, fetching, and server ownership" do
    source = read_source!()
    detail_source = function_source(source, :detail_surface)

    assert count(detail_source, "<dialog") == 1
    assert count(detail_source, "render_slot(@body)") == 1
    assert detail_source =~ "JS.ignore_attributes"
    assert detail_source =~ "DataDisplay.state_message"
    assert detail_source =~ "data-obpt-detail-mode"
    assert detail_source =~ "data-obpt-detail-close"
    refute detail_source =~ "focus_wrap"
    refute detail_source =~ ~s(aria-modal="true")

    for forbidden <- [
          "Repo.",
          "Ecto.Query",
          "push_patch",
          "push_navigate",
          "authorize",
          "DisplayPolicy",
          "preview_token",
          "plan_hash",
          "raw_error"
        ] do
      refute detail_source =~ forbidden
    end
  end

  test "every rendered channel escapes hostile text and omits secret originals" do
    html =
      render_pattern(:attention_card,
        id: "hostile-card",
        title: @hostile,
        summary: @hostile,
        impact: @hostile,
        observed_at: @hostile,
        observed_datetime: "2026-07-18T21:00:00Z",
        domain: :limiter,
        status: :unknown,
        severity: :neutral,
        completeness: :unknown,
        live: :off,
        secondary_actions: [slot(:secondary_actions, %{}, fn -> @hostile end)]
      )

    assert_escaped(html)
    refute html =~ @secret
    refute html =~ ~r/(?:title|data-[^=]*)="[^"]*#{@secret}/
    refute html =~ ~r/<(?:script|style)\b/
  end

  defp render_confirmation(state, overrides \\ []) do
    render_pattern(
      :confirm_action_dialog,
      Keyword.merge(
        [
          id: "retry-jobs",
          intent: :danger,
          state: state,
          title: "Retry 12 jobs?",
          object_label: "12 selected jobs",
          scope: "Includes the frozen 12-job selection.",
          consequence: "Powertools requests a retry for each selected job.",
          reversibility: "A retry request cannot be undone.",
          support_boundary: "Completion remains host-owned.",
          form: confirmation_form(),
          bulk_count: nil,
          bulk_scope: nil,
          confirm_label: "Retry 12 jobs",
          dismiss_label: "Keep current state",
          pending_copy: "Retrying 12 jobs…",
          logical_fallback_id: "job-results-heading",
          submit_event: "submit-retry",
          dismiss_event: "dismiss-retry",
          dismissible: true,
          progress: nil,
          results: operator_results(),
          recovery: [slot(:recovery, %{}, fn -> "Create new preview" end)],
          audit: [slot(:audit, %{}, fn -> "Open audit evidence" end)],
          support_details: [slot(:support_details, %{}, fn -> "Support boundary details" end)]
        ],
        overrides
      )
    )
  end

  defp operator_results do
    [
      %{
        id: "result-success",
        object_label: "Job 1",
        outcome: :success,
        message: "Retry requested.",
        recovery: nil,
        audit_href: "/ops/jobs/audit?resource_id=1"
      },
      %{
        id: "result-failed",
        object_label: "Job 2",
        outcome: :failed,
        message: "Retry request failed.",
        recovery: "Create a fresh preview.",
        audit_href: nil
      },
      %{
        id: "result-skipped",
        object_label: "Job 3",
        outcome: :skipped,
        message: "Retry was skipped because the job changed.",
        recovery: "Refresh the job before acting.",
        audit_href: nil
      }
    ]
  end

  defp filter_form do
    Phoenix.Component.to_form(%{"queue" => "critical", "worker" => ""}, as: :filters)
  end

  defp confirmation_form do
    Phoenix.Component.to_form(
      %{"reason" => "Incident response", "confirmation_count" => "12"},
      as: :confirmation
    )
  end

  defp render_pattern(component, assigns) do
    assert Code.ensure_loaded?(@module),
           "GROUP-01 requires #{@module} before rendering #{component}/1"

    assert function_exported?(@module, component, 1),
           "GROUP-01 requires #{inspect(@module)}.#{component}/1"

    Phoenix.LiveViewTest.__render_component__(
      ObanPowertools.TestEndpoint,
      Function.capture(@module, component, 1),
      Map.new(assigns),
      []
    )
  end

  defp slot(name, attrs, fun) do
    %{__slot__: name, inner_block: fn _changed, argument -> call_slot_fun(fun, argument) end}
    |> Map.merge(attrs)
  end

  defp call_slot_fun(fun, [value]), do: fun.(value)
  defp call_slot_fun(fun, _argument) when is_function(fun, 0), do: fun.()
  defp call_slot_fun(fun, value) when is_function(fun, 1), do: fun.(value)

  defp read_source! do
    assert File.exists?(@source_path),
           "GROUP-01 requires the missing #{@source_path} OperatorPatterns module"

    File.read!(@source_path)
  end

  defp assert_escaped(html) do
    assert html =~ "&lt;script"
    assert html =~ "مرحبا"
    refute html =~ @hostile
    refute html =~ ~r/<script\b/
  end

  defp outside_controlled_region?(html, copy) do
    [before_fields, after_fields_open] = String.split(html, ~s(data-obpt-filter-fields), parts: 2)
    [_fields, after_fields] = String.split(after_fields_open, "</div>", parts: 2)
    before_fields =~ copy or after_fields =~ copy
  end

  defp function_source(source, function) do
    pattern = ~r/^  def #{function}\(.*?(?=^  def [a-z_]+\(|^end\s*$)/ms

    case Regex.run(pattern, source) do
      [body] -> body
      _ -> flunk("missing source body for #{function}/1")
    end
  end

  defp assert_in_order(html, values) do
    indexes = Enum.map(values, &index_of(html, &1))
    assert indexes == Enum.sort(indexes)
  end

  defp count(text, needle), do: length(String.split(text, needle)) - 1
  defp index_of(text, needle), do: :binary.match(text, needle) |> elem(0)
  defp last_index_of(text, needle), do: :binary.matches(text, needle) |> List.last() |> elem(0)
end
