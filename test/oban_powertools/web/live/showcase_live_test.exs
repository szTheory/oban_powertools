# The showcase LiveView and route only exist when dev_routes is enabled
# (dev/test). Guard this RED contract the same way the router and eventual
# module body are guarded, so prod compilation remains free of dev-only code.
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  defmodule ObanPowertools.Web.Dev.ShowcaseLiveTest do
    use ObanPowertools.LiveCase, async: true

    @theme_choices ~w[system light dark high-contrast]
    @viewport_choices ~w[320 tablet wide]
    @section_ids ~w[
      tokens
      primitives
      forms
      data-display
      operator-groups
      pages
      stress-fixtures
    ]
    @open_state_targets ~w[confirm_action_open tooltip_open drawer_open]
    @story_contracts [
      %{id: "overview-operational-empty", domain: "overview", persona: "triage"},
      %{id: "jobs-long-identifiers-many", domain: "jobs", persona: "triage"},
      %{
        id: "batches-high-count-mixed-severity",
        domain: "batches",
        persona: "incident_response"
      },
      %{
        id: "workflows-stale-disconnected-dag",
        domain: "workflows",
        persona: "incident_response"
      },
      %{id: "cron-permission-denied", domain: "cron", persona: "audit_review"},
      %{id: "limiters-boundary-pagination", domain: "limiters", persona: "triage"},
      %{id: "lifeline-repair-preview", domain: "lifeline", persona: "repair"},
      %{id: "audit-non-ascii-rtl", domain: "audit", persona: "audit_review"},
      %{id: "forensics-long-url-stacktrace", domain: "forensics", persona: "repair"}
    ]

    test "renders the showcase through the Powertools theme shell", %{conn: conn} do
      {:ok, _view, html} = mount_showcase!(conn)

      assert count(html, "obpt-root") == 1
      assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.css|
      assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.js|
      assert html =~ "data-obpt-showcase"
    end

    test "theme controls expose the Phase 72 choices as stable attributes", %{conn: conn} do
      {:ok, _view, html} = mount_showcase!(conn)

      assert_attribute_values(html, "data-obpt-theme-choice", @theme_choices)
    end

    test "viewport controls expose the stable audit widths", %{conn: conn} do
      {:ok, _view, html} = mount_showcase!(conn)

      assert_attribute_values(html, "data-obpt-viewport", @viewport_choices)
    end

    test "future showcase sections reserve stable anchors", %{conn: conn} do
      {:ok, _view, html} = mount_showcase!(conn)

      assert_attribute_values(html, "data-obpt-section", @section_ids)
    end

    test "story cells expose stable scenario metadata", %{conn: conn} do
      {:ok, view, html} = mount_showcase!(conn)

      assert_attribute_values(html, "data-obpt-story", Enum.map(@story_contracts, & &1.id))

      for %{id: id, domain: domain, persona: persona} <- @story_contracts do
        assert has_element?(
                 view,
                 "[data-obpt-story='#{id}'][data-obpt-domain='#{domain}'][data-obpt-persona='#{persona}'][data-obpt-state]"
               )
      end
    end

    test "reserved D-09 open-state targets are exposed as metadata only", %{conn: conn} do
      {:ok, _view, html} = mount_showcase!(conn)

      assert_attribute_values(html, "data-obpt-open-state-target", @open_state_targets)
    end

    defp assert_attribute_values(html, attribute, expected_values) do
      assert Enum.sort(attribute_values(html, attribute)) == Enum.sort(expected_values)
    end

    defp mount_showcase!(conn) do
      assert %{
               plug: Phoenix.LiveView.Plug,
               phoenix_live_view: {ObanPowertools.Web.Dev.ShowcaseLive, :index, _, _}
             } =
               Phoenix.Router.route_info(
                 ObanPowertools.TestRouter,
                 "GET",
                 "/ops/jobs/_showcase",
                 "localhost"
               )

      live(conn, "/ops/jobs/_showcase")
    end

    defp attribute_values(html, attribute) do
      Regex.scan(Regex.compile!("#{Regex.escape(attribute)}=\"([^\"]+)\""), html,
        capture: :all_but_first
      )
      |> List.flatten()
    end

    defp count(html, needle) do
      html
      |> String.split(needle)
      |> length()
      |> Kernel.-(1)
    end
  end
end
