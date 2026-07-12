defmodule ObanPowertools.DataDisplayStoryCatalogTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.DataDisplayStoryCatalog

  @ids ~w[
    data-table-sort-states
    data-table-320-stacked
    data-table-explicit-states
    data-status-taxonomy-all
    data-description-list-long-values
    data-timeline-event-log
    data-progress-metric-cards
    data-code-args-redaction
    data-empty-toast-flash
    data-table-thousands-row-stress
  ]

  @components ~w[
    data_table status_pill description_list key_value machine_value timeline
    progress_bar metric_card code_block args_viewer redacted_value empty_state
    toast flash_group
  ]a

  test "keeps exactly ten deterministic data stories in locked order" do
    assert Code.ensure_loaded?(DataDisplayStoryCatalog),
           "Phase 77 requires #{DataDisplayStoryCatalog}"

    stories = DataDisplayStoryCatalog.stories()
    ids = Enum.map(stories, & &1.id)

    assert stories == DataDisplayStoryCatalog.stories()
    assert ids == @ids
    assert ids == Enum.uniq(ids)
    assert Enum.all?(stories, &(&1.kind == :data))
  end

  test "target helpers derive stable story, snapshot, and a11y names" do
    for id <- @ids do
      story = DataDisplayStoryCatalog.story!(id)

      assert story.id == id
      assert DataDisplayStoryCatalog.snapshot_name(id) == "showcase/#{id}"
      assert DataDisplayStoryCatalog.a11y_target(id) == ~s([data-obpt-data-story="#{id}"])
      assert story.test_targets.story == "obpt-data-story-#{id}"
      assert story.test_targets.snapshot == "showcase/#{id}"
      assert story.test_targets.a11y == ~s([data-obpt-data-story="#{id}"])
    end

    assert_raise ArgumentError, fn -> DataDisplayStoryCatalog.story!("missing") end
  end

  test "stories cover all components, states, taxonomy, and adversarial fixtures" do
    stories = DataDisplayStoryCatalog.stories()
    covered_components = stories |> Enum.flat_map(& &1.components) |> Enum.uniq() |> Enum.sort()
    metadata = inspect(stories, limit: :infinity)

    assert covered_components == Enum.sort(@components)

    for required <- [
          "available",
          "retryable",
          "permission_denied",
          "Redacted at enqueue",
          "Hidden by display policy",
          "[redacted]",
          "<script>",
          "مرحبا",
          "01JZ8M5P999999999999999999",
          "MyApp.Workers.ReconcileAccountNotificationDeliveryWithAnIntentionallyLongIdentifier"
        ] do
      assert metadata =~ required
    end

    refute metadata =~ "PHASE77-SECRET-SENTINEL"
  end

  test "large-row story reports truthful totals while keeping a bounded stable window" do
    assert DataDisplayStoryCatalog.large_row_total() >= 1_000

    window = DataDisplayStoryCatalog.large_row_window()
    assert length(window) <= 25
    assert hd(window).id == "job-0001"
    assert List.last(window).id =~ ~r/^job-\d{4}$/
  end

  test "huge args and long-value fixtures are deterministic and normalized" do
    assert DataDisplayStoryCatalog.huge_args_fixture() ==
             DataDisplayStoryCatalog.huge_args_fixture()

    assert DataDisplayStoryCatalog.long_value_fixture() ==
             DataDisplayStoryCatalog.long_value_fixture()

    assert DataDisplayStoryCatalog.timeline_fixture() ==
             DataDisplayStoryCatalog.timeline_fixture()

    args = inspect(DataDisplayStoryCatalog.huge_args_fixture(), limit: :infinity)
    assert args =~ "safe sibling"
    assert args =~ "redacted?"
    refute args =~ "PHASE77-SECRET-SENTINEL"
  end
end
