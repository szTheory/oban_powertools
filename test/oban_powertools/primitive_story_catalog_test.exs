defmodule ObanPowertools.PrimitiveStoryCatalogTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.PrimitiveStoryCatalog
  alias ObanPowertools.ShowcaseCatalog

  @story_ids [
    "primitive-button-matrix",
    "primitive-icon-button-accessible-names",
    "primitive-link-badge-tag-status",
    "primitive-surface-card-divider-density",
    "primitive-tooltip-open",
    "primitive-spinner-skeleton-loading",
    "primitive-kbd-stat-values"
  ]

  @primitive_components [
    :button,
    :icon_button,
    :link,
    :badge,
    :tag,
    :status_pill,
    :surface,
    :card,
    :divider,
    :spinner,
    :skeleton,
    :tooltip,
    :kbd,
    :stat
  ]

  @future_components [
    :input,
    :textarea,
    :select,
    :checkbox,
    :radio,
    :switch,
    :combobox,
    :data_table,
    :app_shell,
    :confirm_action_dialog
  ]

  describe "D-17 primitive story registry boundary" do
    test "stories/0 is deterministic and exposes exactly the Phase 74 primitive story ids" do
      stories = PrimitiveStoryCatalog.stories()
      repeated_stories = PrimitiveStoryCatalog.stories()
      ids = Enum.map(stories, &story_field!(&1, :id))

      assert stories == repeated_stories,
             "D-17 requires PrimitiveStoryCatalog.stories/0 to be deterministic across calls"

      assert ids == Enum.uniq(ids),
             "D-19 requires every primitive story id to be unique"

      assert Enum.all?(ids, &(&1 =~ ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/)),
             "D-20 requires slug-like primitive story ids for stable selectors and snapshots"

      assert ids == @story_ids,
             "D-20 requires the initial primitive story id contract to remain stable"
    end

    test "primitive stories do not pollute the existing stress fixture catalog" do
      scenario_ids = Enum.map(ShowcaseCatalog.scenarios(), &story_field!(&1, :id))

      assert length(scenario_ids) == 9,
             "D-17 keeps the stress fixture catalog at its existing domain/persona scenario set"

      assert Enum.all?(@story_ids, &(&1 not in scenario_ids)),
             "D-17 requires primitive stories to live outside ShowcaseCatalog.scenarios/0"
    end
  end

  describe "D-19/D-20 primitive metadata and targets" do
    test "each story exposes required primitive metadata and test target maps" do
      Enum.each(PrimitiveStoryCatalog.stories(), fn story ->
        Enum.each(
          [
            :id,
            :kind,
            :component,
            :components,
            :variant,
            :state,
            :snapshot,
            :a11y,
            :test_targets
          ],
          fn key ->
            value = story_field!(story, key)

            refute value in [nil, "", [], %{}],
                   "D-17 requires every primitive story to expose non-empty #{inspect(key)} metadata"
          end
        )

        assert story_field!(story, :kind) == :primitive,
               "D-17 requires primitive stories to be explicitly typed"
      end)
    end

    test "snapshot_name/1 and a11y_target/1 derive from stable story ids" do
      Enum.each(PrimitiveStoryCatalog.stories(), fn story ->
        id = story_field!(story, :id)
        expected_snapshot_name = "showcase/#{id}"
        expected_a11y_target = ~s([data-obpt-primitive-story="#{id}"])
        test_targets = story_field!(story, :test_targets)

        assert PrimitiveStoryCatalog.story!(id) |> story_field!(:id) == id,
               "D-20 requires story!/1 to fetch primitive stories by stable id"

        assert PrimitiveStoryCatalog.snapshot_name(id) == expected_snapshot_name,
               "D-20 requires snapshot names to derive from #{id}"

        assert PrimitiveStoryCatalog.a11y_target(id) == expected_a11y_target,
               "D-20 requires a11y targets to derive from #{id}"

        assert story_field!(story, :snapshot) == expected_snapshot_name,
               "D-20 requires story.snapshot to match snapshot_name/1"

        assert story_field!(story, :a11y) == expected_a11y_target,
               "D-20 requires story.a11y to match a11y_target/1"

        assert target_field!(test_targets, :story) == "obpt-primitive-story-#{id}",
               "D-20 requires story target ids to derive from #{id}"

        assert target_field!(test_targets, :snapshot) == expected_snapshot_name,
               "D-20 requires test_targets.snapshot to match snapshot_name/1"

        assert target_field!(test_targets, :a11y) == expected_a11y_target,
               "D-20 requires test_targets.a11y to match a11y_target/1"
      end)
    end
  end

  describe "COMP-01 primitive coverage" do
    test "coverage metadata names every Phase 74 primitive and no future placeholders" do
      covered_components =
        PrimitiveStoryCatalog.stories()
        |> Enum.flat_map(&story_field!(&1, :components))
        |> Enum.uniq()
        |> Enum.sort()

      assert covered_components == Enum.sort(@primitive_components),
             "COMP-01 requires primitive stories to cover every Phase 74 primitive exactly"

      refute Enum.any?(covered_components, &(&1 in @future_components)),
             "D-21 forbids future form/data/group/page placeholders in primitive stories"
    end
  end

  defp story_field!(story, key) do
    story
    |> story_map()
    |> Map.fetch!(key)
  rescue
    KeyError ->
      flunk("D-17 requires every primitive story to contain #{inspect(key)}")
  end

  defp story_map(%_{} = struct), do: Map.from_struct(struct)
  defp story_map(%{} = map), do: map

  defp story_map(other) do
    flunk("D-17 requires primitive stories to be maps or structs, got: #{inspect(other)}")
  end

  defp target_field!(targets, key) when is_map(targets) do
    Map.get(targets, key) || Map.get(targets, Atom.to_string(key)) ||
      flunk("D-20 requires test_targets to contain #{inspect(key)}")
  end

  defp target_field!(targets, _key) do
    flunk("D-20 requires test_targets to be a map, got: #{inspect(targets)}")
  end
end
