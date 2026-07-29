defmodule ObanPowertools.PageStoryCatalogTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.PageStoryCatalog

  @ids ~w[
    page-overview-all-quiet
    page-overview-fixed-order-nonzero
    page-overview-long-unicode
    page-cron-selected-detail
    page-cron-permission-denied
    page-cron-pause-confirmation
    page-cron-resume-confirmation
    page-cron-run-now-confirmation
    page-cron-expired-recovery
    page-cron-drifted-recovery
    page-cron-skipped-partial-recovery
    page-limiters-runnable-empty-current
    page-limiters-blocked-evidence-layers
    page-limiters-unavailable
    page-limiters-forensics-unavailable
    page-audit-empty
    page-audit-filtered-boundary-page
    page-audit-selected-long-unicode
    page-audit-selected-missing-fields
    page-jobs-empty-browse
    page-jobs-review-one
    page-jobs-many-filtered
    page-jobs-thousands-bounded
    page-jobs-final-page-exact
    page-jobs-invalid-json
    page-jobs-adversarial-redacted
    page-jobs-explicit-selection
    page-jobs-frozen-all-matching
    page-jobs-bulk-oversized
    page-jobs-bulk-zero-ready
    page-jobs-bulk-progress
    page-jobs-bulk-success
    page-jobs-bulk-mixed-results
    page-jobs-bulk-drifted
    page-jobs-bulk-disconnected
    page-jobs-bulk-interrupted
    page-jobs-full-detail
    page-forensics-empty-chooser
    page-forensics-workflow-complete
    page-forensics-incident-partial-remediation
    page-forensics-cron-bounded
    page-forensics-limiter-bounded
    page-forensics-unavailable
    page-forensics-conflicting-scope
    page-forensics-unknown-coverage
    page-forensics-history-unavailable
    page-forensics-deep-timeline
    page-forensics-adversarial-redacted
    page-forensics-restricted-guidance
  ]

  @phase79_ids Enum.take(@ids, 19)
  @jobs_ids Enum.slice(@ids, 19, 18)
  @forensics_ids Enum.slice(@ids, 37, 12)

  @confirmation_ids Enum.slice(@ids, 5, 6) ++
                      Enum.map([8, 10, 11, 13, 14, 15, 16], &Enum.at(@jobs_ids, &1))

  @detail_ids Enum.slice(@ids, 3, 2) ++
                Enum.slice(@ids, 11, 4) ++
                Enum.slice(@ids, 17, 2) ++
                [Enum.at(@jobs_ids, 1)]

  @story_fields ~w[
    id kind page name description components variant state fixtures activation test_targets
  ]a

  @pages ~w[overview cron limiters audit jobs forensics]a

  @components ~w[
    app_shell surface button link reason_field attention_card metric_card status_pill
    empty_state data_table description_list code_block toast filter_bar detail_surface
    confirm_action_dialog why_blocked audit_entry timeline progress_bar
  ]a

  @explicit_states ~w[
    loading empty ready unavailable permission_denied stale partial success error
  ]

  @authority_markers ~w[
    PHASE79-PAGE-SECRET-SENTINEL
    PHASE79-PAGE-TOKEN-SENTINEL
    PHASE79-PAGE-HASH-SENTINEL
    PHASE79-PAGE-CREDENTIAL-SENTINEL
    PHASE79-PAGE-RAW-ERROR-SENTINEL
    preview_token
    plan_hash
    credential
    password
    authorization
    bearer
    raw_metadata
    raw_exception
    stacktrace
  ]

  @d86_coverage [
    empty_browse: "page-jobs-empty-browse",
    review_one: "page-jobs-review-one",
    many_filtered: "page-jobs-many-filtered",
    thousands_bounded: "page-jobs-thousands-bounded",
    final_page_exact: "page-jobs-final-page-exact",
    invalid_json: "page-jobs-invalid-json",
    adversarial_redacted: "page-jobs-adversarial-redacted",
    explicit_selection: "page-jobs-explicit-selection",
    frozen_all_matching: "page-jobs-frozen-all-matching",
    bulk_oversized: "page-jobs-bulk-oversized",
    bulk_zero_ready: "page-jobs-bulk-zero-ready",
    bulk_progress: "page-jobs-bulk-progress",
    bulk_success: "page-jobs-bulk-success",
    bulk_mixed_results: "page-jobs-bulk-mixed-results",
    bulk_drifted: "page-jobs-bulk-drifted",
    bulk_disconnected: "page-jobs-bulk-disconnected",
    bulk_interrupted: "page-jobs-bulk-interrupted",
    full_detail: "page-jobs-full-detail"
  ]

  @d87_coverage [
    empty_chooser: "page-forensics-empty-chooser",
    workflow_complete: "page-forensics-workflow-complete",
    incident_partial_remediation: "page-forensics-incident-partial-remediation",
    cron_bounded: "page-forensics-cron-bounded",
    limiter_bounded: "page-forensics-limiter-bounded",
    unavailable: "page-forensics-unavailable",
    conflicting_scope: "page-forensics-conflicting-scope",
    unknown_coverage: "page-forensics-unknown-coverage",
    history_unavailable: "page-forensics-history-unavailable",
    deep_timeline: "page-forensics-deep-timeline",
    adversarial_redacted: "page-forensics-adversarial-redacted",
    restricted_guidance: "page-forensics-restricted-guidance"
  ]

  test "keeps the exact 49-story prefix in binding UI-SPEC order" do
    stories = stories!()
    ids = Enum.map(stories, & &1.id)
    prefix = Enum.take(stories, 49)

    assert length(@ids) == 49
    assert stories == PageStoryCatalog.stories()
    assert Enum.take(ids, 49) == @ids
    assert ids == Enum.uniq(ids)
    assert Enum.take(ids, 19) == @phase79_ids
    assert Enum.slice(ids, 19, 18) == @jobs_ids
    assert Enum.slice(ids, 37, 12) == @forensics_ids
    assert Enum.all?(ids, &String.starts_with?(&1, "page-"))

    for story <- prefix do
      expected_fields =
        if story.id in (@jobs_ids ++ @forensics_ids) do
          Enum.uniq([:acceptance | @story_fields])
        else
          @story_fields
        end

      assert story |> Map.keys() |> Enum.sort() == Enum.sort(expected_fields)
      assert story.kind == :page
      assert story.page in @pages
      assert is_binary(story.name) and story.name != ""
      assert is_binary(story.description) and story.description != ""
      assert is_list(story.components) and story.components != []
      assert Enum.all?(story.components, &(&1 in @components))
      assert is_list(story.variant) and story.variant != []
      assert is_list(story.state) and story.state != []
      assert is_map(story.fixtures) and map_size(story.fixtures) > 0
      assert story.activation in [:none, :detail, :confirmation]
    end

    assert prefix |> Enum.map(& &1.page) |> Enum.frequencies() == %{
             overview: 3,
             cron: 8,
             limiters: 4,
             audit: 4,
             jobs: 18,
             forensics: 12
           }
  end

  test "maps every D-86 and D-87 production-composition state to one named story" do
    ids = stories!() |> Enum.map(& &1.id) |> MapSet.new()

    assert Keyword.values(@d86_coverage) == @jobs_ids
    assert Keyword.values(@d87_coverage) == @forensics_ids
    assert Enum.all?(@d86_coverage ++ @d87_coverage, &MapSet.member?(ids, elem(&1, 1)))
  end

  test "keeps large source totals bounded to the locked Jobs and Forensics DOM windows" do
    thousands = PageStoryCatalog.story!("page-jobs-thousands-bounded")
    deep = PageStoryCatalog.story!("page-forensics-deep-timeline")

    assert thousands.fixtures.pagination.total_count >= 1_000
    assert length(thousands.fixtures.rows) == 20
    assert deep.fixtures.coverage.total_count > 50
    assert length(deep.fixtures.events) == 50
  end

  test "uses exact explicit copy for invalid, conflicting, and unavailable states" do
    invalid = PageStoryCatalog.story!("page-jobs-invalid-json")
    conflicting = PageStoryCatalog.story!("page-forensics-conflicting-scope")
    unavailable = PageStoryCatalog.story!("page-forensics-unavailable")

    assert invalid.fixtures.filter_errors.args == ["Enter a valid JSON object."]
    assert conflicting.fixtures.scope_notice.heading == "Choose one evidence type"
    assert unavailable.fixtures.scope_state == :unavailable
    assert "Evidence unavailable" in unavailable.acceptance.required_text
  end

  test "locks drifted recovery copy and full-detail page-mode contracts" do
    drifted = PageStoryCatalog.story!("page-jobs-bulk-drifted")
    full_detail = PageStoryCatalog.story!("page-jobs-full-detail")

    assert drifted.activation == :confirmation
    assert drifted.acceptance.required_text == ["Jobs", "This preview is out of date"]

    assert full_detail.activation == :none
    assert full_detail.fixtures.page_mode == :detail
    assert full_detail.acceptance.required_text == ["Job #8077", "Failure details are redacted."]

    assert full_detail.acceptance.roles == [
             %{role: "heading", name: "Job #8077", level: 1, states: %{}}
           ]
  end

  test "keeps Phase 80 confidentiality sentinels out of serialized story data" do
    serialized = inspect(stories!(), limit: :infinity, printable_limit: :infinity)

    for sentinel <- [
          "PHASE80-JOBS-TOKEN-SENTINEL",
          "PHASE80-JOBS-HASH-SENTINEL",
          "PHASE80-JOBS-RAW-ERROR-SENTINEL",
          "PHASE80-FORENSICS-PAYLOAD-SENTINEL",
          "PHASE80-FORENSICS-SECRET-SENTINEL"
        ] do
      refute serialized =~ sentinel
    end

    assert serialized =~ "[redacted]"
    assert serialized =~ "Failure details are redacted."
  end

  test "derives stable page story, snapshot, and accessibility targets" do
    stories!()

    for id <- @ids do
      story = PageStoryCatalog.story!(id)

      assert story.id == id
      assert PageStoryCatalog.snapshot_name(id) == "showcase/#{id}"
      assert PageStoryCatalog.a11y_target(id) == ~s([data-obpt-page-story="#{id}"])

      assert story.test_targets == %{
               story: "obpt-page-story-#{id}",
               snapshot: "showcase/#{id}",
               a11y: ~s([data-obpt-page-story="#{id}"])
             }
    end

    assert_raise ArgumentError, fn -> PageStoryCatalog.story!("missing") end
  end

  test "uses closed initial activation without duplicating selected detail or confirmation" do
    stories = stories!()
    prefix = Enum.take(stories, 49)

    assert prefix
           |> Enum.filter(&(&1.activation == :confirmation))
           |> Enum.map(& &1.id) == @confirmation_ids

    assert prefix
           |> Enum.filter(&(&1.activation == :detail))
           |> Enum.map(& &1.id) == @detail_ids

    assert Enum.count(prefix, &(&1.activation == :none)) == 27

    for story <- stories do
      refute story.fixtures[:detail_open] == true and story.fixtures[:confirmation_open] == true
      refute story.fixtures[:duplicate_mobile_tree] == true
      refute story.fixtures[:duplicate_desktop_tree] == true
    end
  end

  test "fixtures cover every explicit state and adversarial long international content" do
    stories = stories!()
    metadata = inspect(stories, limit: :infinity, printable_limit: :infinity)

    for state <- @explicit_states do
      assert metadata =~ state
    end

    for required <- [
          "Needs Review",
          "Blocked",
          "Waiting",
          "Bridge-only Follow-up",
          "Runnable",
          "Resolved continuity",
          "Snapshot at block start",
          "Retained history",
          "Repair evidence retention",
          "<script>alert('page')</script>",
          "مرحبا",
          "שלום",
          "お客様通知",
          "01JZ8M5P999999999999999999",
          "MyApp.Workers.ReconcileAccountNotificationDeliveryWithAnIntentionallyLongIdentifier"
        ] do
      assert metadata =~ required
    end

    timestamps =
      stories
      |> Enum.flat_map(&all_values(&1.fixtures))
      |> Enum.filter(&(is_binary(&1) and Regex.match?(~r/^\d{4}-\d{2}-\d{2}T/, &1)))

    assert timestamps != []

    for timestamp <- timestamps do
      assert {:ok, _datetime, 0} = DateTime.from_iso8601(timestamp)
    end
  end

  test "fixtures are normalized deterministic presentation data without authority or secrets" do
    stories = stories!()
    fixtures = Enum.map(stories, & &1.fixtures)
    values = Enum.flat_map(fixtures, &all_values/1)

    assert fixtures == Enum.map(PageStoryCatalog.stories(), & &1.fixtures)
    refute Enum.any?(fixtures, &contains_struct?/1)
    assert Enum.all?(fixtures, &normalized_fixture?/1)

    for value <- values, is_atom(value) or is_binary(value) do
      rendered = value |> to_string() |> String.downcase()

      for marker <- @authority_markers do
        refute String.contains?(rendered, String.downcase(marker)),
               "page fixture contains forbidden authority marker #{inspect(marker)}"
      end
    end

    source = File.read!("test/support/page_story_catalog.ex")

    for forbidden <- [
          "DateTime.utc_now",
          "NaiveDateTime.utc_now",
          "System.system_time",
          "System.monotonic_time",
          "Enum.random",
          ":rand.",
          "Faker.",
          "TestRepo.",
          "Repo."
        ] do
      refute source =~ forbidden
    end
  end

  @tag phase81_slice: "contracts"
  test "appends the exact ordered 50-story Wave 3 inventory after the unchanged prefix" do
    batches = ~w[
      page-batches-empty-unfiltered
      page-batches-empty-filtered
      page-batches-one-progress
      page-batches-many-boundary-page
      page-batches-high-count-progress
      page-batches-adversarial-redacted
      page-batches-output-unavailable-chain
      page-batches-output-expired-chain
      page-batches-mixed-selection
      page-batches-permission-denied
      page-batches-saturated-failed-members
      page-batches-stuck-callbacks
      page-batches-callback-unavailable
      page-batches-bulk-confirmation
      page-batches-callback-confirmation
      page-batches-drifted-recovery
      page-batches-partial-disconnected
      page-batches-clean-receipt-audit
    ]

    workflows = ~w[
      page-workflows-empty-chooser
      page-workflows-one-running
      page-workflows-many-deep-bounded
      page-workflows-all-complete
      page-workflows-blocked-dag
      page-workflows-selected-blocked-step
      page-workflows-dependency-reasons
      page-workflows-callback-recovery-posture
      page-workflows-result-unavailable
      page-workflows-adversarial-redacted
      page-workflows-refusal-lifeline-handoff
      page-workflows-unavailable-restricted
    ]

    lifeline = ~w[
      page-lifeline-no-active-incidents
      page-lifeline-active-one
      page-lifeline-active-saturated
      page-lifeline-resolved-history
      page-lifeline-healthy-archive
      page-lifeline-dead-executor
      page-lifeline-stuck-workflow
      page-lifeline-callback-variant
      page-lifeline-adversarial-redacted
      page-lifeline-permission-restricted
      page-lifeline-unavailable
      page-lifeline-partial-unknown-evidence
      page-lifeline-host-follow-up-states
      page-lifeline-preview-open
      page-lifeline-invalid-short-reason
      page-lifeline-execute-loading-auth-race
      page-lifeline-drifted-expired-consumed
      page-lifeline-partial-skipped-failed
      page-lifeline-disconnected-interrupted
      page-lifeline-clean-success-audit
    ]

    stories = stories!()
    ids = Enum.map(stories, & &1.id)
    wave3 = batches ++ workflows ++ lifeline

    assert Enum.take(ids, 49) == @ids
    assert Enum.drop(ids, 49) == wave3
    assert length(stories) == 99

    assert Enum.frequencies_by(stories, & &1.page) ==
             %{
               overview: 3,
               cron: 8,
               limiters: 4,
               audit: 4,
               jobs: 18,
               forensics: 12,
               batches: 18,
               workflows: 12,
               lifeline: 20
             }

    for story <- Enum.drop(stories, 49) do
      assert story.activation in [:none, :detail, :confirmation]
      refute contains_struct?(story.fixtures)

      serialized = inspect(story, printable_limit: :infinity, limit: :infinity)

      for forbidden <- ~w[
            preview_token plan_hash before_snapshot after_snapshot raw_metadata raw_exception
            provider_error authorization credential password bearer
          ] do
        refute String.contains?(String.downcase(serialized), forbidden)
      end
    end

    workflow_stories = Map.new(stories, &{&1.id, &1})
    blocked = workflow_stories["page-workflows-selected-blocked-step"].fixtures
    recovery = workflow_stories["page-workflows-callback-recovery-posture"].fixtures
    refusal = workflow_stories["page-workflows-refusal-lifeline-handoff"].fixtures

    assert blocked.workflow.name == "Nightly reconciliation workflow"
    assert Enum.map(blocked.steps, & &1.step_name) == ~w[ingest normalize publish notify]
    assert blocked.selected_step.step_name == "publish"
    assert blocked.selected_step.blocker_codes == ["waiting_on_retryable_dependency"]

    assert blocked.selected_step_story.blocker_summaries == [
             "A retryable dependency must complete before this step can run."
           ]

    assert recovery.workflow_story.callback_posture == %{
             total: 3,
             pending: 1,
             claimed: 0,
             failed: 1,
             delivered: 1,
             latest_status: "failed",
             latest_error: nil
           }

    assert recovery.workflow_story.latest_recovery_session.id == "repair-session-redacted"
    assert refusal.workflow_story.rejection_summary.code == "dependency_not_ready"

    assert refusal.selected_step_story.executable_actions == [
             %{id: "retry_step", label: "Retry blocked step", target_type: "workflow_step"}
           ]
  end

  defp stories! do
    assert Code.ensure_loaded?(PageStoryCatalog),
           "Phase 79 requires #{PageStoryCatalog} from the future page-story catalog wave"

    PageStoryCatalog.stories()
  end

  defp all_values(value) when is_map(value) do
    Enum.flat_map(value, fn {key, nested} -> [key | all_values(nested)] end)
  end

  defp all_values(value) when is_list(value), do: Enum.flat_map(value, &all_values/1)
  defp all_values(value), do: [value]

  defp contains_struct?(%{__struct__: _module}), do: true

  defp contains_struct?(value) when is_map(value) do
    Enum.any?(value, fn {key, nested} -> contains_struct?(key) or contains_struct?(nested) end)
  end

  defp contains_struct?(value) when is_list(value), do: Enum.any?(value, &contains_struct?/1)
  defp contains_struct?(_value), do: false

  defp normalized_fixture?(value) when is_map(value) do
    Enum.all?(value, fn {key, nested} ->
      (is_atom(key) or is_binary(key)) and normalized_fixture?(nested)
    end)
  end

  defp normalized_fixture?(value) when is_list(value),
    do: Enum.all?(value, &normalized_fixture?/1)

  defp normalized_fixture?(value) when is_atom(value), do: true
  defp normalized_fixture?(value) when is_binary(value), do: true
  defp normalized_fixture?(value) when is_integer(value), do: true
  defp normalized_fixture?(nil), do: true
  defp normalized_fixture?(_value), do: false
end
