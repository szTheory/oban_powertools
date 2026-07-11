alias ObanPowertools.ShowcaseCatalog
alias ObanPowertools.PrimitiveStoryCatalog
alias ObanPowertools.FormStoryCatalog

themes = ["system", "light", "dark", "high-contrast"]

viewports = [
  %{name: "320", width: 320, height: 900},
  %{name: "tablet", width: 768, height: 1000},
  %{name: "wide", width: 1440, height: 1000}
]

stringify_list = fn values ->
  Enum.map(values, fn
    value when is_atom(value) -> Atom.to_string(value)
    value when is_binary(value) -> value
  end)
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

targets =
  Enum.map(scenarios, &Map.put(&1, :kind, "scenario")) ++
    primitive_stories ++ form_stories

manifest = %{
  schema_version: 3,
  themes: themes,
  viewports: viewports,
  scenarios: scenarios,
  primitive_stories: primitive_stories,
  form_stories: form_stories,
  targets: targets
}

IO.write(Jason.encode!(manifest))
