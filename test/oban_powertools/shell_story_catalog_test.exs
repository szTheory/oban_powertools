defmodule ObanPowertools.ShellStoryCatalogTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.ShellStoryCatalog

  @ids ~w[
    shell-nine-surface-nav
    shell-mobile-collapsed
    shell-mobile-expanded
    shell-active-breadcrumb
    shell-theme-actor-context
    shell-long-context-wrapping
  ]
  @nav_items [
    {"Overview", "/ops/jobs"},
    {"Jobs", "/ops/jobs/jobs"},
    {"Batches", "/ops/jobs/batches"},
    {"Workflows", "/ops/jobs/workflows"},
    {"Cron", "/ops/jobs/cron"},
    {"Limiters", "/ops/jobs/limiters"},
    {"Lifeline", "/ops/jobs/lifeline"},
    {"Audit", "/ops/jobs/audit"},
    {"Forensics", "/ops/jobs/forensics"}
  ]
  @required_hooks ~w[
    data-obpt-app-shell
    data-obpt-nav-toggle
    data-obpt-primary-nav
    data-obpt-nav-state
    data-obpt-nav-item
    data-obpt-breadcrumb
  ]

  test "keeps exactly six deterministic UI-SPEC shell stories in a separate catalog" do
    stories = stories!()
    ids = Enum.map(stories, & &1.id)

    assert stories == ShellStoryCatalog.stories()
    assert ids == @ids
    assert ids == Enum.uniq(ids)
    assert Enum.all?(ids, &Regex.match?(~r/^shell-[a-z0-9]+(?:-[a-z0-9]+)*$/, &1))
    assert Enum.all?(stories, &(field(&1, :kind) == :shell))
    assert Enum.all?(stories, &(field(&1, :component) == :app_shell))
  end

  test "targets and lookup helpers derive only from stable story ids" do
    for story <- stories!() do
      id = story.id

      assert ShellStoryCatalog.story!(id) == story
      assert ShellStoryCatalog.snapshot_name(id) == "showcase/#{id}"
      assert ShellStoryCatalog.a11y_target(id) == ~s([data-obpt-shell-story="#{id}"])
      assert story.test_targets.story == "obpt-shell-story-#{id}"
      assert story.test_targets.snapshot == "showcase/#{id}"
      assert story.test_targets.a11y == ~s([data-obpt-shell-story="#{id}"])
    end

    assert_raise ArgumentError, fn -> ShellStoryCatalog.story!("missing") end
  end

  test "story nav states are deterministic for closed and expanded shell evidence" do
    stories = Map.new(stories!(), &{&1.id, &1})

    assert stories["shell-mobile-expanded"].nav_state == :open

    for id <- @ids -- ["shell-mobile-expanded"] do
      assert stories[id].nav_state == :closed
    end
  end

  test "stories carry canonical shell copy, nav labels, paths, and shared DOM hooks" do
    stories = stories!()
    metadata = inspect(stories, limit: :infinity)

    for required_copy <- [
          "Oban Powertools",
          "Navigation",
          "Skip to main content",
          "Actor:",
          "System",
          "Light",
          "Dark",
          "High contrast",
          "Actor context unavailable",
          "Job detail",
          "Batch detail",
          "Workflow detail"
        ] do
      assert metadata =~ required_copy
    end

    for {label, path} <- @nav_items do
      assert metadata =~ label
      assert metadata =~ path
    end

    for hook <- @required_hooks do
      assert metadata =~ hook
    end

    refute metadata =~ "/ops/jobs/oban"
  end

  defp stories! do
    assert Code.ensure_loaded?(ShellStoryCatalog),
           "NAV-03/SHOW-01 require #{ShellStoryCatalog} to define deterministic shell stories"

    ShellStoryCatalog.stories()
  end

  defp field(map, key) when is_map(map),
    do: Map.get(map, key) || Map.get(map, Atom.to_string(key))
end
