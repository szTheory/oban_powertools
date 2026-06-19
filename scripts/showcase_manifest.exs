alias ObanPowertools.ShowcaseCatalog

themes = ["system", "light", "dark", "high-contrast"]

viewports = [
  %{name: "320", width: 320, height: 900},
  %{name: "tablet", width: 768, height: 1000},
  %{name: "wide", width: 1440, height: 1000}
]

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

manifest = %{
  schema_version: 1,
  themes: themes,
  viewports: viewports,
  scenarios: scenarios
}

IO.write(Jason.encode!(manifest))
