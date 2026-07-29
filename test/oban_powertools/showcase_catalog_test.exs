defmodule ObanPowertools.ShowcaseCatalogTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.ShowcaseCatalog

  @domains [
    :overview,
    :jobs,
    :batches,
    :workflows,
    :cron,
    :limiters,
    :lifeline,
    :audit,
    :forensics
  ]

  @required_state_tags [
    :empty,
    :one,
    :many,
    :long_id,
    :long_module,
    :long_url,
    :non_ascii,
    :emoji,
    :rtl,
    :high_count,
    :mixed_severity,
    :permission_denied,
    :stale,
    :disconnected,
    :boundary_pagination
  ]

  @required_personas [
    :triage,
    :incident_response,
    :repair,
    :audit_review
  ]

  @initial_scenario_ids [
    "overview-operational-empty",
    "jobs-long-identifiers-many",
    "batches-high-count-mixed-severity",
    "workflows-stale-disconnected-dag",
    "cron-permission-denied",
    "limiters-boundary-pagination",
    "lifeline-repair-preview",
    "audit-non-ascii-rtl",
    "forensics-long-url-stacktrace"
  ]

  describe "D-01 domain-first catalog contract" do
    test "domains/0 returns exactly the required operator domains in stable order" do
      assert normalize_values(ShowcaseCatalog.domains()) == normalize_values(@domains),
             "D-01 requires domains/0 to return exactly overview, jobs, batches, workflows, cron, limiters, lifeline, audit, and forensics in stable order"
    end

    test "scenarios_by_domain/0 uses the same complete domain set" do
      scenarios_by_domain = ShowcaseCatalog.scenarios_by_domain()

      assert sorted_values(Map.keys(scenarios_by_domain)) == sorted_values(@domains),
             "D-01 requires scenarios_by_domain/0 to be keyed by exactly the nine catalog domains"

      Enum.each(@domains, fn domain ->
        scenarios =
          Map.get(scenarios_by_domain, domain) ||
            Map.get(scenarios_by_domain, Atom.to_string(domain))

        assert is_list(scenarios) and scenarios != [],
               "D-01 requires #{inspect(domain)} to have at least one scenario"
      end)
    end
  end

  describe "D-02 stable scenario identifiers and test targets" do
    test "scenarios/0 is deterministic and exposes unique slug IDs" do
      scenarios = ShowcaseCatalog.scenarios()
      repeated_scenarios = ShowcaseCatalog.scenarios()
      ids = Enum.map(scenarios, &scenario_field!(&1, :id))

      assert scenarios == repeated_scenarios,
             "D-04/D-13 require scenarios/0 to be deterministic across repeated calls"

      assert ids == Enum.uniq(ids),
             "D-02 requires every scenario ID to be unique"

      assert Enum.all?(ids, &(&1 =~ ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/)),
             "D-02 requires slug-like scenario IDs for stable selectors and snapshots"

      assert ids == @initial_scenario_ids,
             "D-02 requires the initial scenario ID contract to remain stable"
    end

    test "each scenario exposes required metadata and fixture/test target maps" do
      Enum.each(ShowcaseCatalog.scenarios(), fn scenario ->
        Enum.each(
          [:id, :domain, :name, :persona, :jtbd, :states, :fixtures, :test_targets],
          fn key ->
            value = scenario_field!(scenario, key)

            refute value in [nil, "", [], %{}],
                   "D-01 requires every scenario to expose a non-empty #{inspect(key)} field"
          end
        )
      end)
    end

    test "snapshot_name/1 and a11y_target/1 derive from scenario ID instead of display copy" do
      Enum.each(ShowcaseCatalog.scenarios(), fn scenario ->
        id = scenario_field!(scenario, :id)
        name = scenario_field!(scenario, :name)
        expected_snapshot_name = "showcase/#{id}"
        expected_a11y_target = ~s([data-obpt-story="#{id}"])
        test_targets = scenario_field!(scenario, :test_targets)

        assert ShowcaseCatalog.scenario!(id) |> scenario_field!(:id) == id,
               "D-02 requires scenario!/1 to fetch scenarios by stable ID"

        assert ShowcaseCatalog.snapshot_name(id) == expected_snapshot_name,
               "D-02 requires snapshot names to derive from #{id}, not display copy #{inspect(name)}"

        assert ShowcaseCatalog.a11y_target(id) == expected_a11y_target,
               "D-02 requires a11y targets to derive from #{id}, not display copy #{inspect(name)}"

        assert target_field!(test_targets, :snapshot) == expected_snapshot_name,
               "D-02 requires scenario test_targets.snapshot to match snapshot_name/1"

        assert target_field!(test_targets, :a11y) == expected_a11y_target,
               "D-02 requires scenario test_targets.a11y to match a11y_target/1"
      end)
    end
  end

  describe "D-03 FIX-01 state and persona/JTBD coverage" do
    test "required_state_tags/0 and aggregate scenario states cover every adversarial state" do
      aggregate_states =
        ShowcaseCatalog.scenarios()
        |> Enum.flat_map(&scenario_field!(&1, :states))
        |> normalize_values()

      assert normalize_values(ShowcaseCatalog.required_state_tags()) ==
               normalize_values(@required_state_tags),
             "FIX-01 requires required_state_tags/0 to name empty, one, many, long_id, long_module, long_url, non_ascii, emoji, rtl, high_count, mixed_severity, permission_denied, stale, disconnected, and boundary_pagination"

      assert Enum.all?(normalize_values(@required_state_tags), &(&1 in aggregate_states)),
             "D-03/FIX-01 require aggregate scenario states to cover every required normal and adversarial tag"
    end

    test "required_personas/0 and scenarios cover triage, incident response, repair, and audit review" do
      aggregate_personas =
        ShowcaseCatalog.scenarios()
        |> Enum.map(&scenario_field!(&1, :persona))
        |> normalize_values()

      aggregate_jtbds =
        ShowcaseCatalog.scenarios()
        |> Enum.map(&scenario_field!(&1, :jtbd))
        |> normalize_values()
        |> Enum.join(" ")

      assert normalize_values(ShowcaseCatalog.required_personas()) ==
               normalize_values(@required_personas),
             "D-03/FIX-03 require triage, incident_response, repair, and audit_review as persona/JTBD categories"

      Enum.each(normalize_values(@required_personas), fn persona ->
        assert persona in aggregate_personas or
                 String.contains?(aggregate_jtbds, String.replace(persona, "_", " ")),
               "D-03/FIX-03 require #{persona} coverage in scenario persona or JTBD metadata"
      end)
    end
  end

  describe "PAGE-02 schema-8 target cardinality" do
    test "the showcase catalogs expose exactly 163 deterministic targets" do
      catalogs = [
        ShowcaseCatalog,
        ObanPowertools.PrimitiveStoryCatalog,
        ObanPowertools.FormStoryCatalog,
        ObanPowertools.ShellStoryCatalog,
        ObanPowertools.DataDisplayStoryCatalog,
        ObanPowertools.OperatorPatternStoryCatalog,
        ObanPowertools.PageStoryCatalog
      ]

      targets =
        Enum.flat_map(catalogs, fn
          ShowcaseCatalog -> ShowcaseCatalog.scenarios()
          catalog -> catalog.stories()
        end)

      assert length(targets) == 163
      assert length(ObanPowertools.PageStoryCatalog.stories()) == 99
    end
  end

  defp scenario_field!(scenario, key) do
    scenario
    |> scenario_map()
    |> Map.fetch!(key)
  rescue
    KeyError ->
      flunk("D-01 requires every scenario to contain #{inspect(key)}")
  end

  defp scenario_map(%_{} = struct), do: Map.from_struct(struct)
  defp scenario_map(%{} = map), do: map

  defp scenario_map(other) do
    flunk("D-01 requires scenarios to be maps or structs, got: #{inspect(other)}")
  end

  defp target_field!(targets, key) when is_map(targets) do
    Map.get(targets, key) || Map.get(targets, Atom.to_string(key)) ||
      flunk("D-02 requires test_targets to contain #{inspect(key)}")
  end

  defp target_field!(targets, _key) do
    flunk("D-02 requires test_targets to be a map, got: #{inspect(targets)}")
  end

  defp normalize_values(values) do
    values
    |> Enum.map(&normalize_value/1)
  end

  defp sorted_values(values) do
    values
    |> normalize_values()
    |> Enum.sort()
  end

  defp normalize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_value(value) when is_binary(value), do: value
  defp normalize_value(value), do: inspect(value)
end
