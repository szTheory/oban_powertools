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
      "Keep current state",
      "Retry 12 jobs"
    ])

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
        dismissible: false,
        pending_copy: "Retrying 12 jobs…",
        progress: %{value: 3, max: 12}
      )

    assert pending =~ ~s(aria-busy="true")
    assert pending =~ "Retrying 12 jobs…"
    assert pending =~ "This action has been accepted and can no longer be canceled."
    assert pending =~ "3/12"
    refute pending =~ ~s(phx-key="Escape")
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
      assert html =~ ~s(aria-label="Close job details")
      assert html =~ ~s(data-obpt-detail-fallback="job-results-heading")
      assert html =~ ~s(data-obpt-detail-state="#{state}")
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
        secondary_actions: [slot(:secondary_actions, %{}, fn -> @secret end)]
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
end
