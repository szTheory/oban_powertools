defmodule ObanPowertools.OperatorPatternStoryCatalogTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.OperatorPatternStoryCatalog

  @ids ~w[
    group-confirm-single-reversible
    group-confirm-single-destructive
    group-confirm-bulk-count
    group-confirm-pending
    group-confirm-partial-results
    group-confirm-drifted-error
    group-filter-submit
    group-filter-instant
    group-filter-active-clear
    group-filter-unapplied-invalid
    group-detail-inline
    group-detail-modal
    group-detail-loading-unavailable
    group-detail-long-content
    group-attention-status-severity-matrix
    group-attention-long-content-and-actions
    group-why-blocked-multiple-causes
    group-why-blocked-live-vs-snapshot
    group-why-blocked-unavailable-evidence
    group-audit-entry-actor-outcome-matrix
    group-audit-entry-missing-fields
    group-audit-entry-redacted-changes
    group-explain-audit-narrow-layout
  ]

  @overlay_ids Enum.take(@ids, 6) ++ Enum.slice(@ids, 10, 4)

  @story_fields ~w[
    id kind name description components variant state fixtures activation test_targets
  ]a

  @components ~w[
    confirm_action_dialog filter_bar detail_surface attention_card audit_entry why_blocked
    status_pill empty_state code_block
  ]a

  test "keeps exactly 23 deterministic operator-pattern stories in binding order" do
    stories = stories!()
    ids = Enum.map(stories, & &1.id)

    assert length(@ids) == 23
    assert stories == OperatorPatternStoryCatalog.stories()
    assert ids == @ids
    assert ids == Enum.uniq(ids)
    assert Enum.all?(stories, &(&1.kind == :group))

    for story <- stories do
      assert story |> Map.keys() |> Enum.sort() == Enum.sort(@story_fields)
      assert is_list(story.components) and story.components != []
      assert is_binary(story.name) and story.name != ""
      assert is_binary(story.description) and story.description != ""
      assert is_list(story.variant) and story.variant != []
      assert is_list(story.state) and story.state != []
      assert is_map(story.fixtures)
      assert story.activation in [:none, :overlay]
    end
  end

  test "derives stable group story, snapshot, and accessibility targets" do
    stories!()

    for id <- @ids do
      story = OperatorPatternStoryCatalog.story!(id)

      assert story.id == id
      assert OperatorPatternStoryCatalog.snapshot_name(id) == "showcase/#{id}"

      assert OperatorPatternStoryCatalog.a11y_target(id) ==
               ~s([data-obpt-group-story="#{id}"])

      assert story.test_targets == %{
               story: "obpt-group-story-#{id}",
               snapshot: "showcase/#{id}",
               a11y: ~s([data-obpt-group-story="#{id}"])
             }
    end

    assert_raise ArgumentError, fn -> OperatorPatternStoryCatalog.story!("missing") end
  end

  test "uses closed activation metadata without opening top-layer UI on initial mount" do
    stories = stories!()

    assert stories
           |> Enum.filter(&(&1.activation == :overlay))
           |> Enum.map(& &1.id) == @overlay_ids

    assert Enum.all?(stories, fn story ->
             story.activation == :none or
               String.starts_with?(story.id, "group-confirm-") or
               String.starts_with?(story.id, "group-detail-")
           end)

    assert Enum.count(stories, &(&1.activation == :overlay)) == 10
    assert Enum.count(stories, &(&1.activation == :none)) == 13

    refute Enum.any?(stories, fn story ->
             story.fixtures[:open] == true or story.fixtures[:initially_open] == true
           end)
  end

  test "fixtures cover explicit truth states and deterministic adversarial content" do
    stories = stories!()
    metadata = inspect(stories, limit: :infinity, printable_limit: :infinity)
    covered_components = stories |> Enum.flat_map(& &1.components) |> Enum.uniq() |> Enum.sort()

    assert covered_components == Enum.sort(@components)

    for required <- [
          "loading",
          "empty",
          "unavailable",
          "permission_denied",
          "stale",
          "unknown",
          "partial",
          "success",
          "failed",
          "skipped",
          "current",
          "snapshot",
          "<script>",
          "مرحبا",
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

  test "fixtures are normalized presentation data and contain no secret authority values" do
    stories = stories!()
    fixtures = Enum.map(stories, & &1.fixtures)
    metadata = inspect(fixtures, limit: :infinity, printable_limit: :infinity)

    assert fixtures == Enum.map(OperatorPatternStoryCatalog.stories(), & &1.fixtures)
    refute Enum.any?(fixtures, &contains_struct?/1)
    assert Enum.all?(fixtures, &normalized_fixture?/1)

    for forbidden <- [
          "PHASE78-GROUP-SECRET-SENTINEL",
          "preview_token",
          "plan_hash",
          "raw_error",
          "password",
          "authorization",
          "bearer ",
          "#Ecto.",
          "#Oban.",
          "Faker"
        ] do
      refute String.contains?(String.downcase(metadata), String.downcase(forbidden))
    end
  end

  defp stories! do
    assert Code.ensure_loaded?(OperatorPatternStoryCatalog),
           "Phase 78 requires #{OperatorPatternStoryCatalog}"

    OperatorPatternStoryCatalog.stories()
  end

  defp all_values(value) when is_map(value) do
    Enum.flat_map(value, fn {key, nested} -> [key | all_values(nested)] end)
  end

  defp all_values(value) when is_list(value), do: Enum.flat_map(value, &all_values/1)
  defp all_values(value) when is_tuple(value), do: value |> Tuple.to_list() |> all_values()
  defp all_values(value), do: [value]

  defp contains_struct?(%{__struct__: _module}), do: true

  defp contains_struct?(value) when is_map(value) do
    Enum.any?(value, fn {key, nested} -> contains_struct?(key) or contains_struct?(nested) end)
  end

  defp contains_struct?(value) when is_list(value), do: Enum.any?(value, &contains_struct?/1)

  defp contains_struct?(value) when is_tuple(value) do
    value |> Tuple.to_list() |> Enum.any?(&contains_struct?/1)
  end

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
