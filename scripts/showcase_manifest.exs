alias ObanPowertools.ShowcaseCatalog
alias ObanPowertools.PrimitiveStoryCatalog
alias ObanPowertools.FormStoryCatalog
alias ObanPowertools.ShellStoryCatalog
alias ObanPowertools.DataDisplayStoryCatalog
alias ObanPowertools.OperatorPatternStoryCatalog
alias ObanPowertools.PageStoryCatalog

themes = ["system", "light", "dark", "high-contrast"]

viewports = [
  %{name: "320", width: 320, height: 900},
  %{name: "tablet", width: 768, height: 1000},
  %{name: "wide", width: 1440, height: 1000}
]

stringify = fn
  value when is_atom(value) -> Atom.to_string(value)
  value when is_binary(value) -> value
end

stringify_list = fn values ->
  values
  |> List.wrap()
  |> Enum.map(stringify)
end

scenarios =
  ShowcaseCatalog.scenarios()
  |> Enum.map(fn scenario ->
    id = Map.fetch!(scenario, :id)
    test_targets = Map.fetch!(scenario, :test_targets)

    %{
      id: id,
      domain: scenario.domain |> Atom.to_string(),
      persona: scenario.persona |> Atom.to_string(),
      states: Enum.map(scenario.states, &Atom.to_string/1),
      story: Map.fetch!(test_targets, :story),
      snapshot: ShowcaseCatalog.snapshot_name(id),
      a11y: ShowcaseCatalog.a11y_target(id)
    }
  end)

primitive_stories =
  PrimitiveStoryCatalog.stories()
  |> Enum.map(fn story ->
    id = Map.fetch!(story, :id)
    test_targets = Map.fetch!(story, :test_targets)

    %{
      id: id,
      kind: story.kind |> Atom.to_string(),
      component: story.component |> Atom.to_string(),
      components: Enum.map(story.components, &Atom.to_string/1),
      name: Map.fetch!(story, :name),
      description: Map.fetch!(story, :description),
      variant: stringify_list.(Map.fetch!(story, :variant)),
      state: stringify_list.(Map.fetch!(story, :state)),
      story: Map.fetch!(test_targets, :story),
      snapshot: PrimitiveStoryCatalog.snapshot_name(id),
      a11y: PrimitiveStoryCatalog.a11y_target(id)
    }
  end)

form_stories =
  FormStoryCatalog.stories()
  |> Enum.map(fn story ->
    id = Map.fetch!(story, :id)
    test_targets = Map.fetch!(story, :test_targets)

    %{
      id: id,
      kind: story.kind |> Atom.to_string(),
      component: story.component |> Atom.to_string(),
      components: Enum.map(story.components, &Atom.to_string/1),
      name: Map.fetch!(story, :name),
      description: Map.fetch!(story, :description),
      variant: stringify_list.(Map.fetch!(story, :variant)),
      state: stringify_list.(Map.fetch!(story, :state)),
      story: Map.fetch!(test_targets, :story),
      snapshot: FormStoryCatalog.snapshot_name(id),
      a11y: FormStoryCatalog.a11y_target(id)
    }
  end)

shell_stories =
  ShellStoryCatalog.stories()
  |> Enum.map(fn story ->
    id = Map.fetch!(story, :id)
    test_targets = Map.fetch!(story, :test_targets)

    %{
      id: id,
      kind: story.kind |> Atom.to_string(),
      component: story.component |> Atom.to_string(),
      components: Enum.map(story.components, &Atom.to_string/1),
      name: Map.fetch!(story, :name),
      description: Map.fetch!(story, :description),
      variant: stringify_list.(Map.fetch!(story, :variant)),
      state: stringify_list.(Map.fetch!(story, :state)),
      nav_state: stringify.(Map.fetch!(story, :nav_state)),
      story: Map.fetch!(test_targets, :story),
      snapshot: ShellStoryCatalog.snapshot_name(id),
      a11y: ShellStoryCatalog.a11y_target(id)
    }
  end)

data_stories =
  DataDisplayStoryCatalog.stories()
  |> Enum.map(fn story ->
    id = Map.fetch!(story, :id)
    test_targets = Map.fetch!(story, :test_targets)

    %{
      id: id,
      kind: story.kind |> Atom.to_string(),
      component: story.component |> Atom.to_string(),
      components: Enum.map(story.components, &Atom.to_string/1),
      name: Map.fetch!(story, :name),
      description: Map.fetch!(story, :description),
      variant: stringify_list.(Map.fetch!(story, :variant)),
      state: stringify_list.(Map.fetch!(story, :state)),
      story: Map.fetch!(test_targets, :story),
      snapshot: DataDisplayStoryCatalog.snapshot_name(id),
      a11y: DataDisplayStoryCatalog.a11y_target(id)
    }
  end)

group_stories =
  OperatorPatternStoryCatalog.stories()
  |> Enum.map(fn story ->
    id = Map.fetch!(story, :id)
    test_targets = Map.fetch!(story, :test_targets)

    %{
      id: id,
      kind: story.kind |> Atom.to_string(),
      component: story.components |> List.first() |> Atom.to_string(),
      components: Enum.map(story.components, &Atom.to_string/1),
      name: Map.fetch!(story, :name),
      description: Map.fetch!(story, :description),
      variant: stringify_list.(Map.fetch!(story, :variant)),
      state: stringify_list.(Map.fetch!(story, :state)),
      activation: stringify.(Map.fetch!(story, :activation)),
      story: Map.fetch!(test_targets, :story),
      snapshot: OperatorPatternStoryCatalog.snapshot_name(id),
      a11y: OperatorPatternStoryCatalog.a11y_target(id)
    }
  end)

page_stories =
  PageStoryCatalog.stories()
  |> Enum.map(fn story ->
    id = Map.fetch!(story, :id)
    test_targets = Map.fetch!(story, :test_targets)

    %{
      id: id,
      kind: story.kind |> Atom.to_string(),
      page: story.page |> Atom.to_string(),
      component: story.components |> List.first() |> Atom.to_string(),
      components: Enum.map(story.components, &Atom.to_string/1),
      name: Map.fetch!(story, :name),
      description: Map.fetch!(story, :description),
      variant: stringify_list.(Map.fetch!(story, :variant)),
      state: stringify_list.(Map.fetch!(story, :state)),
      activation: stringify.(Map.fetch!(story, :activation)),
      acceptance: Map.fetch!(story, :acceptance),
      story: Map.fetch!(test_targets, :story),
      snapshot: PageStoryCatalog.snapshot_name(id),
      a11y: PageStoryCatalog.a11y_target(id)
    }
  end)

unless length(page_stories) == 99 do
  raise "expected exactly 99 page stories, got #{length(page_stories)}"
end

targets =
  Enum.map(scenarios, &Map.put(&1, :kind, "scenario")) ++
    primitive_stories ++
    form_stories ++ shell_stories ++ data_stories ++ group_stories ++ page_stories

unless length(targets) == 163 do
  raise "expected exactly 163 showcase targets, got #{length(targets)}"
end

manifest = %{
  schema_version: 8,
  themes: themes,
  viewports: viewports,
  scenarios: scenarios,
  primitive_stories: primitive_stories,
  form_stories: form_stories,
  shell_stories: shell_stories,
  data_stories: data_stories,
  group_stories: group_stories,
  page_stories: page_stories,
  targets: targets
}

IO.write(Jason.encode!(manifest))
