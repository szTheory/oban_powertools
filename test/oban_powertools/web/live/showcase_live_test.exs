# The showcase LiveView and route only exist when dev_routes is enabled
# (dev/test). Guard this RED contract the same way the router and eventual
# module body are guarded, so prod compilation remains free of dev-only code.
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  defmodule ObanPowertools.Web.Dev.ShowcaseLiveTest do
    use ObanPowertools.LiveCase, async: true

    @theme_choices ~w[system light dark high-contrast]
    @viewport_choices ~w[320 tablet wide]
    @section_ids ~w[
      app-shell
      tokens
      primitives
      forms
      data-display
      operator-groups
      pages
      stress-fixtures
    ]
    @open_state_targets ~w[confirm_action_open tooltip_open drawer_open]
    @primitive_story_contracts [
      %{
        id: "primitive-button-matrix",
        component: "button",
        variant: "neutral primary warning danger ghost",
        state: "default disabled disabled_reason"
      },
      %{
        id: "primitive-icon-button-accessible-names",
        component: "icon_button",
        variant: "neutral primary danger",
        state: "labelled tooltip disabled_reason"
      },
      %{
        id: "primitive-link-badge-tag-status",
        component: "link badge tag status_pill",
        variant: "navigation tone_matrix",
        state: "metadata representative_status"
      },
      %{
        id: "primitive-surface-card-divider-density",
        component: "surface card divider",
        variant: "plain elevated inset attention",
        state: "density structure"
      },
      %{
        id: "primitive-tooltip-open",
        component: "tooltip",
        variant: "text_only",
        state: "open focus"
      },
      %{
        id: "primitive-spinner-skeleton-loading",
        component: "spinner skeleton",
        variant: "bounded progressive",
        state: "loading busy"
      },
      %{
        id: "primitive-kbd-stat-values",
        component: "kbd stat",
        variant: "literal metric",
        state: "dense_values"
      }
    ]
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
    @form_story_ids ~w[
      form-input-states form-textarea-select form-checkbox-modes form-radio-group
      form-switch-states form-validation-wiring form-disabled-readonly
      form-filter-ready form-long-content
    ]
    @shell_story_contracts [
      %{id: "shell-nine-surface-nav", state: "default", nav_state: "closed"},
      %{id: "shell-mobile-collapsed", state: "collapsed", nav_state: "closed"},
      %{id: "shell-mobile-expanded", state: "expanded", nav_state: "open"},
      %{id: "shell-active-breadcrumb", state: "detail", nav_state: "closed"},
      %{id: "shell-theme-actor-context", state: "actor_context", nav_state: "closed"},
      %{id: "shell-long-context-wrapping", state: "long_context", nav_state: "closed"}
    ]
    @data_story_ids ~w[
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

    test "renders the showcase through the Powertools theme shell", %{conn: conn} do
      {:ok, _view, html} = mount_showcase!(conn)

      assert count(html, "obpt-root") == 1
      assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.css|
      assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.js|
      assert html =~ "data-obpt-showcase"
      refute html =~ ~s(role="row")
    end

    test "theme controls expose the Phase 72 choices as stable attributes", %{conn: conn} do
      {:ok, view, _html} = mount_showcase!(conn)

      for theme <- @theme_choices do
        assert has_element?(
                 view,
                 "[data-obpt-showcase] [data-obpt-theme-controls] [data-obpt-theme-choice='#{theme}']"
               )
      end
    end

    test "viewport controls expose the stable audit widths", %{conn: conn} do
      {:ok, _view, html} = mount_showcase!(conn)

      assert_attribute_values(html, "data-obpt-viewport", @viewport_choices)
    end

    test "future showcase sections reserve stable anchors", %{conn: conn} do
      {:ok, _view, html} = mount_showcase!(conn)

      assert_attribute_values(html, "data-obpt-section", @section_ids)
    end

    test "app shell section renders six real shell stories with deterministic nav state", %{
      conn: conn
    } do
      {:ok, view, html} = mount_showcase!(conn)

      assert_attribute_values(
        html,
        "data-obpt-shell-story",
        Enum.map(@shell_story_contracts, & &1.id)
      )

      refute has_element?(view, "[data-obpt-section='app-shell'] .obpt-showcase-placeholder")

      for %{id: id, state: state, nav_state: nav_state} <- @shell_story_contracts do
        assert has_element?(
                 view,
                 "#obpt-shell-story-#{id}[data-obpt-shell-story='#{id}'][data-obpt-component='app_shell'][data-obpt-variant][data-obpt-state='#{state}'][data-obpt-nav-state='#{nav_state}'][data-obpt-a11y-target]"
               )

        assert has_element?(
                 view,
                 "#obpt-shell-story-#{id} [data-obpt-app-shell][data-obpt-nav-state='#{nav_state}']"
               )
      end

      for required_copy <- [
            "Oban Powertools",
            "Navigation",
            "Overview",
            "Jobs",
            "Batches",
            "Workflows",
            "Cron",
            "Limiters",
            "Lifeline",
            "Audit",
            "Forensics",
            "Job detail",
            "Actor: ops@example.test",
            "Actor context unavailable",
            "High contrast"
          ] do
        assert html =~ required_copy
      end

      assert html =~ "&lt;script&gt;alert(&#39;shell&#39;)&lt;/script&gt;"
      refute html =~ "<script>alert('shell')</script>"
      refute html =~ "/ops/jobs/oban"
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

    test "primitive section renders stable primitive story cells", %{conn: conn} do
      {:ok, view, html} = mount_showcase!(conn)

      assert_attribute_values(
        html,
        "data-obpt-primitive-story",
        Enum.map(@primitive_story_contracts, & &1.id)
      )

      refute has_element?(
               view,
               "[data-obpt-section='primitives'] .obpt-showcase-placeholder"
             )

      for %{id: id, component: component, variant: variant, state: state} <-
            @primitive_story_contracts do
        assert has_element?(
                 view,
                 "#obpt-primitive-story-#{id}[data-obpt-primitive-story='#{id}'][data-obpt-component='#{component}'][data-obpt-variant='#{variant}'][data-obpt-state='#{state}'][data-obpt-a11y-target]"
               )
      end

      for required_copy <- [
            "Retry job",
            "Refresh jobs",
            "View audit log",
            "Retryable",
            "Filter summary",
            "Retries the selected job once",
            "Loading job history",
            "Esc",
            "Retryable jobs"
          ] do
        assert html =~ required_copy
      end
    end

    test "reserved D-09 open-state targets are exposed as metadata only", %{conn: conn} do
      {:ok, _view, html} = mount_showcase!(conn)

      assert_attribute_values(html, "data-obpt-open-state-target", @open_state_targets)
    end

    test "forms section renders nine real catalog-backed form stories", %{conn: conn} do
      {:ok, view, html} = mount_showcase!(conn)

      assert_attribute_values(html, "data-obpt-form-story", @form_story_ids)
      refute has_element?(view, "[data-obpt-section='forms'] .obpt-showcase-placeholder")

      for id <- @form_story_ids do
        assert has_element?(
                 view,
                 "#obpt-form-story-#{id}[data-obpt-form-story='#{id}'][data-obpt-component][data-obpt-variant][data-obpt-state][data-obpt-a11y-target]"
               )
      end

      assert has_element?(view, "#obpt-form-story-form-input-states input[name$='[worker]']")
      assert has_element?(view, "#obpt-form-story-form-textarea-select textarea")
      assert has_element?(view, "#obpt-form-story-form-textarea-select select")
      assert has_element?(view, "#obpt-form-story-form-checkbox-modes input[type='checkbox']")
      assert has_element?(view, "#obpt-form-story-form-radio-group fieldset input[type='radio']")
      assert has_element?(view, "#obpt-form-story-form-switch-states input[type='checkbox']")
      assert html =~ "&lt;script&gt;alert(&#39;escaped&#39;)&lt;/script&gt;"
      refute html =~ "<script>alert('escaped')</script>"
    end

    test "data-display section renders ten metadata-complete real component stories", %{
      conn: conn
    } do
      {:ok, view, html} = mount_showcase!(conn)

      assert_attribute_values(html, "data-obpt-data-story", @data_story_ids)
      refute has_element?(view, "[data-obpt-section='data-display'] .obpt-showcase-placeholder")

      for id <- @data_story_ids do
        assert has_element?(
                 view,
                 "#obpt-data-story-#{id}[data-obpt-data-story='#{id}'][data-obpt-component][data-obpt-variant][data-obpt-state][data-obpt-a11y-target]"
               )
      end

      assert has_element?(view, "#obpt-data-story-data-table-sort-states table")
      assert has_element?(view, "#obpt-data-story-data-description-list-long-values dl")
      assert has_element?(view, "#obpt-data-story-data-timeline-event-log ol")
      assert has_element?(view, "#obpt-data-story-data-progress-metric-cards progress")

      assert has_element?(
               view,
               "#obpt-data-story-data-code-args-redaction pre[tabindex='0'] code"
             )

      assert has_element?(view, "#obpt-data-story-data-empty-toast-flash [role='alert']")

      for copy <- [
            "No rows match the current filters",
            "Data did not load",
            "Permission denied",
            "Redacted at enqueue",
            "Hidden by display policy",
            "[redacted]",
            "مرحبا",
            "✅"
          ] do
        assert html =~ copy
      end

      assert html =~ "&lt;script&gt;alert(&#39;data&#39;)&lt;/script&gt;"
      refute html =~ "<script>alert('data')</script>"
      refute html =~ "PHASE77-SECRET-SENTINEL"

      assert count(html, ~s(id="data-thousands-table-row-job-)) == 20
      assert html =~ ~s(id="data-thousands-table-row-job-0001")
      assert html =~ ~s(id="data-thousands-table-row-job-0020")
      assert html =~ "2,500 jobs"
    end

    test "data sort story keeps sort state in ShowcaseLive and updates truthful aria-sort", %{
      conn: conn
    } do
      {:ok, view, _html} = mount_showcase!(conn)
      story = "#obpt-data-story-data-table-sort-states"

      assert has_element?(
               view,
               "#{story} th[aria-sort='ascending'] button[phx-value-sort-key='worker']"
             )

      view
      |> element("#{story} button[phx-click='sort-data-table'][phx-value-sort-key='id']")
      |> render_click()

      assert has_element?(
               view,
               "#{story} th[aria-sort='ascending'] button[phx-value-sort-key='id']"
             )

      refute has_element?(view, "#{story} th[aria-sort] button[phx-value-sort-key='worker']")

      view
      |> element("#{story} button[phx-click='sort-data-table'][phx-value-sort-key='id']")
      |> render_click()

      assert has_element?(
               view,
               "#{story} th[aria-sort='descending'] button[phx-value-sort-key='id']"
             )
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
