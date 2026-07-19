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
  ]

  @confirmation_ids Enum.slice(@ids, 5, 6)

  @detail_ids Enum.slice(@ids, 3, 2) ++
                Enum.slice(@ids, 11, 4) ++
                Enum.slice(@ids, 17, 2)

  @story_fields ~w[
    id kind page name description components variant state fixtures activation test_targets
  ]a

  @pages ~w[overview cron limiters audit]a

  @components ~w[
    app_shell surface button link reason_field attention_card metric_card status_pill
    empty_state data_table description_list code_block toast filter_bar detail_surface
    confirm_action_dialog why_blocked audit_entry
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
    metadata
    exception
    raw_metadata
    raw_exception
    stacktrace
  ]

  test "keeps exactly 19 deterministic page stories in binding UI-SPEC order" do
    stories = stories!()
    ids = Enum.map(stories, & &1.id)

    assert length(@ids) == 19
    assert stories == PageStoryCatalog.stories()
    assert ids == @ids
    assert ids == Enum.uniq(ids)

    for story <- stories do
      assert story |> Map.keys() |> Enum.sort() == Enum.sort(@story_fields)
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

    assert stories |> Enum.map(& &1.page) |> Enum.frequencies() == %{
             overview: 3,
             cron: 8,
             limiters: 4,
             audit: 4
           }
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

    assert stories
           |> Enum.filter(&(&1.activation == :confirmation))
           |> Enum.map(& &1.id) == @confirmation_ids

    assert stories
           |> Enum.filter(&(&1.activation == :detail))
           |> Enum.map(& &1.id) == @detail_ids

    assert Enum.count(stories, &(&1.activation == :none)) == 5

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
