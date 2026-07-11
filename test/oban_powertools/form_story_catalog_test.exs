defmodule ObanPowertools.FormStoryCatalogTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.FormStoryCatalog

  @ids ~w[
    form-input-states form-textarea-select form-checkbox-modes form-radio-group
    form-switch-states form-validation-wiring form-disabled-readonly
    form-filter-ready form-long-content
  ]
  @components ~w[input textarea select checkbox radio_group switch field_group label hint error]a
  @states ~w[valid invalid required optional disabled readonly pending filter long_content]a
  @forbidden ~w[combobox filter_bar confirm_action_dialog destructive_dialog mutation url page]a

  test "D-22 keeps exactly nine deterministic form stories in a separate catalog" do
    stories = FormStoryCatalog.stories()
    ids = Enum.map(stories, & &1.id)

    assert stories == FormStoryCatalog.stories()
    assert ids == @ids
    assert ids == Enum.uniq(ids)
    assert Enum.all?(ids, &Regex.match?(~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/, &1))
    assert Enum.all?(stories, &(&1.kind == :form))
  end

  test "targets and lookup helpers derive only from stable ids" do
    for story <- FormStoryCatalog.stories() do
      id = story.id
      assert FormStoryCatalog.story!(id) == story
      assert FormStoryCatalog.snapshot_name(id) == "showcase/#{id}"
      assert FormStoryCatalog.a11y_target(id) == ~s([data-obpt-form-story="#{id}"])
      assert story.test_targets.story == "obpt-form-story-#{id}"
      assert story.test_targets.snapshot == "showcase/#{id}"
      assert story.test_targets.a11y == ~s([data-obpt-form-story="#{id}"])
    end

    assert_raise ArgumentError, fn -> FormStoryCatalog.story!("missing") end
  end

  test "D-24 covers all exports and required states without deferred behavior" do
    stories = FormStoryCatalog.stories()
    covered_components = stories |> Enum.flat_map(& &1.components) |> Enum.uniq() |> Enum.sort()
    covered_states = stories |> Enum.flat_map(& &1.state) |> Enum.uniq()

    assert covered_components == Enum.sort(@components)
    assert Enum.all?(@states, &(&1 in covered_states))
    refute Enum.any?(covered_components, &(&1 in @forbidden))

    refute Enum.any?(stories, fn story ->
             metadata = inspect(story) |> String.downcase()
             Enum.any?(@forbidden, &String.contains?(metadata, Atom.to_string(&1)))
           end)
  end

  test "stories carry operator copy plus named boolean and event selection metadata" do
    stories = FormStoryCatalog.stories()
    copy = inspect(stories, limit: :infinity)

    for required <- [
          "Worker name",
          "Search jobs",
          "Enter a full or partial worker module name.",
          "Required",
          "Optional",
          "Enter a worker name.",
          "Queue selection is unavailable while this job is running.",
          "Job ID is assigned when the job is inserted and cannot be changed.",
          "Job state",
          "Any state",
          "Pause queue processing"
        ],
        do: assert(copy =~ required)

    checkbox = FormStoryCatalog.story!("form-checkbox-modes")
    assert checkbox.selection_modes == [:named_boolean, :event_selection]
    assert checkbox.examples.named_boolean.hidden_unchecked
    refute checkbox.examples.event_selection.hidden_unchecked
  end
end
