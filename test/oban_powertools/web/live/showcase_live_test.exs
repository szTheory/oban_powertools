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
    @group_story_ids Enum.map(
                       ObanPowertools.OperatorPatternStoryCatalog.stories(),
                       & &1.id
                     )
    @page_story_ids Enum.map(ObanPowertools.PageStoryCatalog.stories(), & &1.id)
    @optional_catalog_modules [
      ObanPowertools.ShowcaseCatalog,
      ObanPowertools.PrimitiveStoryCatalog,
      ObanPowertools.FormStoryCatalog,
      ObanPowertools.ShellStoryCatalog,
      ObanPowertools.DataDisplayStoryCatalog,
      ObanPowertools.OperatorPatternStoryCatalog,
      ObanPowertools.PageStoryCatalog
    ]
    @isolated_data_catalog_cases [
      %{
        id: "absent",
        stub: nil,
        expected_available?: false,
        expected_stories: [],
        render_placeholder?: true
      },
      %{
        id: "non-list",
        stub: :non_list,
        expected_available?: false,
        expected_stories: [],
        render_placeholder?: true
      },
      %{
        id: "empty-list",
        stub: :empty_list,
        expected_available?: true,
        expected_stories: [],
        render_placeholder?: true
      },
      %{
        id: "missing-flash",
        stub: :missing_flash,
        expected_available?: true,
        expected_stories: [%{id: "data-empty-toast-flash", fixtures: %{}}],
        render_placeholder?: false
      },
      %{
        id: "non-map-flash",
        stub: :non_map_flash,
        expected_available?: true,
        expected_stories: [
          %{
            id: "data-empty-toast-flash",
            fixtures: %{flash: [{"info", "must not be seeded"}]}
          }
        ],
        render_placeholder?: false
      }
    ]

    for package_case <- @isolated_data_catalog_cases do
      @package_case package_case

      test "isolated package boundary fails closed for #{@package_case.id} data catalog" do
        assert_isolated_data_catalog_case!(@package_case)
      end
    end

    @isolated_group_catalog_cases [
      %{id: "absent", stub: nil},
      %{id: "non-list", stub: :non_list}
    ]

    for package_case <- @isolated_group_catalog_cases do
      @group_package_case package_case

      test "isolated package boundary fails closed for #{@group_package_case.id} group catalog" do
        assert_isolated_group_catalog_case!(@group_package_case)
      end
    end

    @isolated_page_catalog_cases [
      %{id: "absent", stub: nil},
      %{id: "non-list", stub: :non_list},
      %{id: "malformed-list", stub: :malformed_list}
    ]

    for package_case <- @isolated_page_catalog_cases do
      @page_package_case package_case

      test "isolated package boundary fails closed for #{@page_package_case.id} page catalog" do
        assert_isolated_page_catalog_case!(@page_package_case)
      end
    end

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
               "#data-progress-unavailable[data-obpt-data-state='unavailable']"
             )

      refute has_element?(view, "#data-progress-unavailable progress")
      refute has_element?(view, "#data-progress-unavailable .obpt-progress__count")
      refute has_element?(view, "#data-progress-unavailable .obpt-progress__percent")

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

    test "operator groups render exactly 23 metadata-complete stories with every overlay closed",
         %{conn: conn} do
      {:ok, view, html} = mount_showcase!(conn)

      assert_attribute_values(html, "data-obpt-group-story", @group_story_ids)

      refute has_element?(
               view,
               "[data-obpt-section='operator-groups'] .obpt-showcase-placeholder[data-obpt-group-index]"
             )

      for id <- @group_story_ids do
        assert has_element?(
                 view,
                 "#obpt-group-story-#{id}[data-obpt-group-story='#{id}'][data-obpt-component][data-obpt-variant][data-obpt-state][data-obpt-activation][data-obpt-overlay-active='false'][data-obpt-a11y-target]"
               )
      end

      refute has_element?(view, "[data-obpt-group-story][data-obpt-overlay-active='true']")
      refute has_element?(view, "[role='dialog']")
      refute has_element?(view, "dialog[open]")
      assert html =~ "&lt;script&gt;alert(&#39;group&#39;)&lt;/script&gt;"
      refute html =~ "<script>alert('group')</script>"
      refute html =~ "PHASE78-GROUP-SECRET-SENTINEL"
    end

    test "group activation validates catalog ids and keeps exactly one requested overlay", %{
      conn: conn
    } do
      {:ok, view, _html} = mount_showcase!(conn)

      render_hook(view, "activate-group-story", %{"id" => "group-confirm-bulk-count"})

      assert has_element?(
               view,
               "[data-obpt-group-story='group-confirm-bulk-count'][data-obpt-overlay-active='true'] [role='dialog']"
             )

      assert active_group_overlay_count(view) == 1

      render_hook(view, "activate-group-story", %{"id" => "group-detail-modal"})

      assert has_element?(
               view,
               "[data-obpt-group-story='group-detail-modal'][data-obpt-overlay-active='true'] dialog[open]"
             )

      refute has_element?(
               view,
               "[data-obpt-group-story='group-confirm-bulk-count'] [role='dialog']"
             )

      assert active_group_overlay_count(view) == 1
      assert count(render(view), "<dialog") == 1

      render_hook(view, "activate-group-story", %{"id" => "missing-group-story"})

      assert has_element?(
               view,
               "[data-obpt-group-story='group-detail-modal'][data-obpt-overlay-active='true']"
             )

      assert active_group_overlay_count(view) == 1
    end

    test "connected group confirmation validates reason and count once and preserves stale or partial truth",
         %{conn: conn} do
      {:ok, view, _html} = mount_showcase!(conn)
      render_hook(view, "activate-group-story", %{"id" => "group-confirm-bulk-count"})

      html =
        view
        |> form("#showcase-group-confirm-bulk-count-form", %{
          "group_confirmation" => %{
            "reason" => "short",
            "confirmation_count" => "11"
          }
        })
        |> render_submit()

      assert html =~ "Reason must be at least 8 characters."
      assert html =~ "Type 12 to confirm."
      assert has_element?(view, "#showcase-group-confirm-bulk-count-dialog[role='dialog']")
      refute has_element?(view, "#obpt-group-receipt")

      params = %{
        "group_confirmation" => %{
          "reason" => "Provider recovered; retry safely.",
          "confirmation_count" => "12"
        }
      }

      render_hook(view, "submit-group-confirmation", params)
      render_hook(view, "submit-group-confirmation", params)

      assert has_element?(
               view,
               "#obpt-group-receipt[data-obpt-group-receipt-count='1']",
               "Retry requested for 12 jobs. Audit evidence recorded."
             )

      refute has_element?(view, "[data-obpt-group-story][data-obpt-overlay-active='true']")
      assert count(render(view), "Retry requested for 12 jobs. Audit evidence recorded.") == 1

      render_hook(view, "activate-group-story", %{"id" => "group-confirm-drifted-error"})
      assert render(view) =~ "This preview is out of date because the job changed."
      render_hook(view, "fresh-group-preview", %{})
      assert has_element?(view, "#showcase-group-confirm-drifted-error-form")

      render_hook(view, "activate-group-story", %{"id" => "group-confirm-partial-results"})
      partial = render(view)

      assert_in_order(partial, [
        ~s(id="showcase-group-confirm-partial-results-job-result-success"),
        ~s(id="showcase-group-confirm-partial-results-job-result-failed"),
        ~s(id="showcase-group-confirm-partial-results-job-result-skipped")
      ])

      assert has_element?(view, "[data-obpt-result='success']", "Success")
      assert has_element?(view, "[data-obpt-result='failed']", "Failed")
      assert has_element?(view, "[data-obpt-result='skipped']", "Skipped")
      assert partial =~ "Review failed and skipped jobs before trying again."
      assert active_group_overlay_count(view) == 1
    end

    test "connected group filters, detail history, explanation, and audit remain parent owned",
         %{conn: conn} do
      {:ok, view, html} = mount_showcase!(conn)

      assert html =~ "Current workflow state"
      assert html =~ "Block-start snapshot"
      assert html =~ "No operator reason recorded"
      assert html =~ "Outcome not recorded"
      assert html =~ "July 18, 2026 at 14:05 UTC"

      for {index, severity, completeness, status_label, severity_label} <- [
            {1, "neutral", "complete", "Available", "Neutral"},
            {2, "warning", "partial", "Retryable", "Warning"},
            {3, "danger", "unknown", "Discarded", "Danger"},
            {4, "info", "unavailable", "Completed", "Info"}
          ] do
        selector =
          "#showcase-group-attention-status-severity-matrix-#{index}" <>
            "[data-obpt-severity='#{severity}']" <>
            "[data-obpt-completeness='#{completeness}']"

        assert has_element?(view, selector, status_label)
        assert has_element?(view, selector, severity_label)
      end

      render_hook(view, "validate-group-filters", %{
        "group_filters" => %{
          "story_id" => "group-filter-submit",
          "queue" => "unknown",
          "state" => "retryable",
          "worker" => ""
        }
      })

      assert render(view) =~ "Choose a known queue."

      render_hook(view, "apply-group-filters", %{
        "group_filters" => %{
          "story_id" => "group-filter-submit",
          "queue" => "critical-mailer",
          "state" => "retryable",
          "worker" => ""
        }
      })

      filter_url = "/ops/jobs/_showcase?queue=critical-mailer&state=retryable"

      assert has_element?(
               view,
               "#group-filter-submit-results[data-obpt-group-filter-url='#{filter_url}'][data-obpt-group-filter-history='push:#{filter_url}']"
             )

      render_hook(view, "remove-group-filter", %{
        "id" => "group-filter-submit",
        "field" => "queue"
      })

      assert has_element?(
               view,
               "#group-filter-submit-results[data-obpt-group-filter-url='/ops/jobs/_showcase?state=retryable']"
             )

      render_hook(view, "clear-group-filters", %{"id" => "group-filter-submit"})

      assert has_element?(
               view,
               "#group-filter-submit-results[data-obpt-group-filter-url='/ops/jobs/_showcase']"
             )

      render_hook(view, "open-group-detail", %{"id" => "group-detail-modal"})
      render_hook(view, "select-group-detail", %{"resource-id" => "01JZ8M5P999999999999999998"})

      assert render(view) =~ "Job 01JZ8M5P999999999999999998 details loaded."

      assert has_element?(
               view,
               "[data-obpt-group-detail-history*='replace:/ops/jobs/_showcase?detail=01JZ8M5P999999999999999998']"
             )

      render_hook(view, "activate-group-story", %{"id" => "group-confirm-single-reversible"})
      assert count(render(view), "<dialog") == 0
      assert has_element?(view, "#showcase-group-confirm-single-reversible-dialog[role='dialog']")
      refute render(view) =~ "PHASE78-GROUP-SECRET-SENTINEL"
    end

    test "pages section registers exactly 19 production-composition stories with no active tree",
         %{conn: conn} do
      {:ok, view, html} = mount_showcase!(conn)

      assert_attribute_values(html, "data-obpt-page-story", @page_story_ids)

      refute has_element?(
               view,
               "[data-obpt-section='pages'] .obpt-showcase-placeholder[data-obpt-page-index]"
             )

      for id <- @page_story_ids do
        assert has_element?(
                 view,
                 "#obpt-page-story-#{id}[data-obpt-page-story='#{id}'][data-obpt-page][data-obpt-component][data-obpt-variant][data-obpt-state][data-obpt-activation][data-obpt-page-active='false'][data-obpt-a11y-target]"
               )
      end

      refute has_element?(view, "[data-obpt-page-story][data-obpt-page-active='true']")
      refute has_element?(view, "#overview-page, #cron-page, #limiters-page, #audit-page")
      refute has_element?(view, "[role='dialog'], dialog[open]")
    end

    test "page activation calls each production composition and keeps one story and one overlay",
         %{conn: conn} do
      {:ok, view, _html} = mount_showcase!(conn)

      render_hook(view, "activate-page-story", %{"id" => "page-overview-all-quiet"})
      assert_active_page_story(view, "page-overview-all-quiet", "#overview-page")
      assert has_element?(view, "#overview-page h1#overview-title", "Overview")
      assert has_element?(view, "#overview-all-quiet", "No current follow-up identified")
      assert active_page_overlay_count(view) == 0

      render_hook(view, "activate-page-story", %{"id" => "page-cron-pause-confirmation"})
      assert_active_page_story(view, "page-cron-pause-confirmation", "#cron-page")
      assert has_element?(view, "#cron-page h1#cron-page-title", "Cron")
      assert has_element?(view, "#cron-page table")
      assert has_element?(view, "#cron-confirmation-dialog[role='dialog']")
      refute has_element?(view, "#cron-entry-detail")
      assert active_page_overlay_count(view) == 1

      render_hook(view, "activate-page-story", %{
        "id" => "page-limiters-blocked-evidence-layers"
      })

      assert_active_page_story(
        view,
        "page-limiters-blocked-evidence-layers",
        "#limiters-page"
      )

      assert has_element?(view, "#limiters-page h1#limiters-page-title", "Limiters")
      assert has_element?(view, "#limiters-page table")
      assert has_element?(view, "#limiter-detail")
      assert has_element?(view, "#limiter-current-blockers", "Current blockers")
      assert active_page_overlay_count(view) == 1

      render_hook(view, "activate-page-story", %{
        "id" => "page-audit-selected-long-unicode"
      })

      assert_active_page_story(view, "page-audit-selected-long-unicode", "#audit-page")
      assert has_element?(view, "#audit-page h1#audit-page-title", "Audit")
      assert has_element?(view, "#audit-page table")
      assert has_element?(view, "#audit-detail")
      assert has_element?(view, "#audit-entry-42", "Recorded at")
      assert active_page_overlay_count(view) == 1

      render_hook(view, "activate-page-story", %{"id" => "missing-page-story"})
      assert_active_page_story(view, "page-audit-selected-long-unicode", "#audit-page")
      assert active_page_overlay_count(view) == 1
    end

    test "group and page activation atomically replace the opposite active surface", %{
      conn: conn
    } do
      {:ok, view, _html} = mount_showcase!(conn)

      render_hook(view, "activate-group-story", %{"id" => "group-confirm-bulk-count"})
      assert active_group_overlay_count(view) == 1
      assert active_page_story_count(view) == 0

      render_hook(view, "activate-page-story", %{"id" => "page-cron-pause-confirmation"})
      assert active_group_overlay_count(view) == 0
      assert active_page_story_count(view) == 1
      assert active_page_overlay_count(view) == 1

      render_hook(view, "activate-group-story", %{"id" => "group-detail-modal"})
      assert active_group_overlay_count(view) == 1
      assert active_page_story_count(view) == 0
      assert active_page_overlay_count(view) == 1
    end

    test "every page story renders one matching production tree within the overlay bound", %{
      conn: conn
    } do
      {:ok, view, _html} = mount_showcase!(conn)

      for story <- ObanPowertools.PageStoryCatalog.stories() do
        render_hook(view, "activate-page-story", %{"id" => story.id})

        root_selector = page_root_selector(story.page)
        assert_active_page_story(view, story.id, root_selector)
        assert has_element?(view, "#{root_selector} h1")

        assert Enum.count(
                 ~w[#overview-page #cron-page #limiters-page #audit-page],
                 &has_element?(view, &1)
               ) == 1

        if story.page != :overview do
          assert has_element?(view, "#{root_selector} table")
        end

        assert active_page_overlay_count(view) <= 1

        case story.activation do
          :confirmation ->
            assert has_element?(view, "#cron-confirmation-dialog[role='dialog']")
            refute has_element?(view, "#cron-entry-detail")

          :detail ->
            refute has_element?(view, "#cron-confirmation-dialog")

          :none ->
            assert active_page_overlay_count(view) == 0
        end

        if story.id in ["page-overview-long-unicode", "page-audit-selected-long-unicode"] do
          assert render(view) =~ "&lt;script&gt;alert(&#39;page&#39;)&lt;/script&gt;"

          refute has_element?(
                   view,
                   "[data-obpt-page-story='#{story.id}'][data-obpt-page-active='true'] script"
                 )
        end
      end
    end

    test "showcase source delegates page markup to all four production page_content seams" do
      source = File.read!("lib/oban_powertools/web/dev/showcase_live.ex")

      for call <- [
            "EngineOverviewLive.page_content",
            "CronLive.page_content",
            "LimitersLive.page_content",
            "AuditLive.page_content"
          ] do
        assert source =~ call
      end

      for copied_markup <- [
            ~s(<h1 id="overview-title">),
            ~s(<h1 id="cron-page-title">),
            ~s(<h1 id="limiters-page-title">),
            ~s(<h1 id="audit-page-title">)
          ] do
        refute source =~ copied_markup
      end
    end

    test "default flash dismissal removes only the selected canonical Phoenix key", %{
      conn: conn
    } do
      {:ok, view, _html} = mount_showcase!(conn)
      story = "#obpt-data-story-data-empty-toast-flash"

      assert has_element?(
               view,
               "#{story} #data-flash-group-ZXJyb3I[data-obpt-tone='danger'][role='alert'] button[phx-click='lv:clear-flash'][phx-value-key='error']"
             )

      assert has_element?(
               view,
               "#{story} #data-flash-group-aW5mbw[data-obpt-tone='info'][role='status'] button[phx-click='lv:clear-flash'][phx-value-key='info']"
             )

      view
      |> element("#{story} button[phx-click='lv:clear-flash'][phx-value-key='error']")
      |> render_click()

      refute has_element?(view, "#{story} #data-flash-group-ZXJyb3I")
      assert has_element?(view, "#{story} #data-flash-group-aW5mbw")

      view
      |> element("#{story} button[phx-click='lv:clear-flash'][phx-value-key='info']")
      |> render_click()

      refute has_element?(view, "#{story} #data-flash-group-aW5mbw")
    end

    defp assert_isolated_data_catalog_case!(package_case) do
      temp_dir =
        Path.join(
          System.tmp_dir!(),
          "oban-powertools-showcase-package-#{package_case.id}-#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(temp_dir)

      try do
        source = isolated_data_catalog_source(package_case, temp_dir)

        {output, status} =
          System.cmd(
            "mix",
            ["run", "--no-start", "--no-compile", "-e", source],
            cd: File.cwd!(),
            env: [{"MIX_ENV", "test"}],
            stderr_to_stdout: true
          )

        assert status == 0,
               "isolated package case #{package_case.id} failed with status #{status}:\n#{output}"

        assert output =~ "PACKAGE_CASE_OK #{package_case.id}",
               "isolated package case #{package_case.id} omitted its success marker:\n#{output}"
      after
        File.rm_rf!(temp_dir)
      end
    end

    defp assert_isolated_group_catalog_case!(package_case) do
      temp_dir =
        Path.join(
          System.tmp_dir!(),
          "oban-powertools-group-package-#{package_case.id}-#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(temp_dir)

      try do
        source = isolated_group_catalog_source(package_case, temp_dir)

        {output, status} =
          System.cmd(
            "mix",
            ["run", "--no-start", "--no-compile", "-e", source],
            cd: File.cwd!(),
            env: [{"MIX_ENV", "test"}],
            stderr_to_stdout: true
          )

        assert status == 0,
               "isolated group package case #{package_case.id} failed with status #{status}:\n#{output}"

        assert output =~ "GROUP_PACKAGE_CASE_OK #{package_case.id}",
               "isolated group package case #{package_case.id} omitted its success marker:\n#{output}"
      after
        File.rm_rf!(temp_dir)
      end
    end

    defp assert_isolated_page_catalog_case!(package_case) do
      temp_dir =
        Path.join(
          System.tmp_dir!(),
          "oban-powertools-page-package-#{package_case.id}-#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(temp_dir)

      try do
        source = isolated_page_catalog_source(package_case, temp_dir)

        {output, status} =
          System.cmd(
            "mix",
            ["run", "--no-start", "--no-compile", "-e", source],
            cd: File.cwd!(),
            env: [{"MIX_ENV", "test"}],
            stderr_to_stdout: true
          )

        assert status == 0,
               "isolated page package case #{package_case.id} failed with status #{status}:\n#{output}"

        assert output =~ "PAGE_PACKAGE_CASE_OK #{package_case.id}",
               "isolated page package case #{package_case.id} omitted its success marker:\n#{output}"
      after
        File.rm_rf!(temp_dir)
      end
    end

    defp isolated_data_catalog_source(package_case, temp_dir) do
      excluded_beams =
        Enum.map(@optional_catalog_modules, fn module ->
          "#{Atom.to_string(module)}.beam"
        end)

      stub_source = isolated_data_catalog_stub(package_case.stub)

      """
      original_ebin = :oban_powertools |> :code.lib_dir(:ebin) |> List.to_string()
      isolated_ebin = Path.join(#{inspect(temp_dir)}, "ebin")
      File.mkdir_p!(isolated_ebin)
      excluded_beams = MapSet.new(#{inspect(excluded_beams)})

      original_ebin
      |> Path.join("*.beam")
      |> Path.wildcard()
      |> Enum.reject(&MapSet.member?(excluded_beams, Path.basename(&1)))
      |> Enum.each(fn source ->
        File.cp!(source, Path.join(isolated_ebin, Path.basename(source)))
      end)

      true = :code.del_path(String.to_charlist(original_ebin))
      true = :code.add_patha(String.to_charlist(isolated_ebin))

      for module <- #{inspect(@optional_catalog_modules)} do
        :code.purge(module)
        :code.delete(module)
      end

      #{stub_source}

      socket = %Phoenix.LiveView.Socket{
        assigns: %{__changed__: %{}, flash: %{}},
        private: %{live_temp: %{}}
      }

      {:ok, mounted_socket} =
        ObanPowertools.Web.Dev.ShowcaseLive.mount(%{}, %{}, socket)

      assigns = mounted_socket.assigns

      unless assigns.data_catalog_available? == #{inspect(package_case.expected_available?)} do
        raise "#{package_case.id}: unexpected availability: \#{inspect(assigns.data_catalog_available?)}"
      end

      unless assigns.data_stories == #{inspect(package_case.expected_stories)} do
        raise "#{package_case.id}: unexpected stories: \#{inspect(assigns.data_stories)}"
      end

      unless assigns.flash == %{} do
        raise "#{package_case.id}: expected empty flash, got: \#{inspect(assigns.flash)}"
      end

      if #{inspect(package_case.render_placeholder?)} do
        html =
          assigns
          |> ObanPowertools.Web.Dev.ShowcaseLive.render()
          |> Phoenix.HTML.Safe.to_iodata()
          |> IO.iodata_to_binary()

        unless html =~ ~s(data-obpt-data-index="empty") do
          raise "#{package_case.id}: existing data-display unavailable marker was not rendered"
        end
      end

      IO.puts("PACKAGE_CASE_OK #{package_case.id}")
      """
    end

    defp isolated_data_catalog_stub(nil), do: ""

    defp isolated_data_catalog_stub(stub) do
      stories =
        case stub do
          :non_list ->
            :invalid_catalog_shape

          :empty_list ->
            []

          :missing_flash ->
            [%{id: "data-empty-toast-flash", fixtures: %{}}]

          :non_map_flash ->
            [
              %{
                id: "data-empty-toast-flash",
                fixtures: %{flash: [{"info", "must not be seeded"}]}
              }
            ]
        end

      """
      Code.compile_string(\"\"\"
      defmodule ObanPowertools.DataDisplayStoryCatalog do
        def stories, do: #{inspect(stories)}
      end
      \"\"\")
      """
    end

    defp isolated_group_catalog_source(package_case, temp_dir) do
      excluded_beams =
        Enum.map(@optional_catalog_modules, fn module -> "#{Atom.to_string(module)}.beam" end)

      stub_source =
        case package_case.stub do
          nil ->
            ""

          :non_list ->
            ~S'''
            Code.compile_string("""
            defmodule ObanPowertools.OperatorPatternStoryCatalog do
              def stories, do: :invalid_catalog_shape
            end
            """)
            '''
        end

      """
      original_ebin = :oban_powertools |> :code.lib_dir(:ebin) |> List.to_string()
      isolated_ebin = Path.join(#{inspect(temp_dir)}, "ebin")
      File.mkdir_p!(isolated_ebin)
      excluded_beams = MapSet.new(#{inspect(excluded_beams)})

      original_ebin
      |> Path.join("*.beam")
      |> Path.wildcard()
      |> Enum.reject(&MapSet.member?(excluded_beams, Path.basename(&1)))
      |> Enum.each(fn source -> File.cp!(source, Path.join(isolated_ebin, Path.basename(source))) end)

      true = :code.del_path(String.to_charlist(original_ebin))
      true = :code.add_patha(String.to_charlist(isolated_ebin))

      for module <- #{inspect(@optional_catalog_modules)} do
        :code.purge(module)
        :code.delete(module)
      end

      #{stub_source}

      socket = %Phoenix.LiveView.Socket{
        assigns: %{__changed__: %{}, flash: %{}},
        private: %{live_temp: %{}}
      }

      {:ok, mounted_socket} = ObanPowertools.Web.Dev.ShowcaseLive.mount(%{}, %{}, socket)
      assigns = mounted_socket.assigns

      unless assigns.group_catalog_available? == false do
        raise "#{package_case.id}: malformed group catalog must fail closed"
      end

      unless assigns.group_stories == [] do
        raise "#{package_case.id}: malformed group stories must be empty"
      end

      html =
        assigns
        |> ObanPowertools.Web.Dev.ShowcaseLive.render()
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      unless html =~ ~s(data-obpt-group-index="empty") do
        raise "#{package_case.id}: existing operator groups placeholder was not rendered"
      end

      IO.puts("GROUP_PACKAGE_CASE_OK #{package_case.id}")
      """
    end

    defp isolated_page_catalog_source(package_case, temp_dir) do
      excluded_beams =
        Enum.map(@optional_catalog_modules, fn module -> "#{Atom.to_string(module)}.beam" end)

      stub_source =
        case package_case.stub do
          nil ->
            ""

          :non_list ->
            ~S'''
            Code.compile_string("""
            defmodule ObanPowertools.PageStoryCatalog do
              def stories, do: :invalid_catalog_shape
            end
            """)
            '''

          :malformed_list ->
            ~S'''
            Code.compile_string("""
            defmodule ObanPowertools.PageStoryCatalog do
              def stories, do: [%{id: "incomplete-page-story"}]
            end
            """)
            '''
        end

      """
      original_ebin = :oban_powertools |> :code.lib_dir(:ebin) |> List.to_string()
      isolated_ebin = Path.join(#{inspect(temp_dir)}, "ebin")
      File.mkdir_p!(isolated_ebin)
      excluded_beams = MapSet.new(#{inspect(excluded_beams)})

      original_ebin
      |> Path.join("*.beam")
      |> Path.wildcard()
      |> Enum.reject(&MapSet.member?(excluded_beams, Path.basename(&1)))
      |> Enum.each(fn source -> File.cp!(source, Path.join(isolated_ebin, Path.basename(source))) end)

      true = :code.del_path(String.to_charlist(original_ebin))
      true = :code.add_patha(String.to_charlist(isolated_ebin))

      for module <- #{inspect(@optional_catalog_modules)} do
        :code.purge(module)
        :code.delete(module)
      end

      #{stub_source}

      socket = %Phoenix.LiveView.Socket{
        assigns: %{__changed__: %{}, flash: %{}},
        private: %{live_temp: %{}}
      }

      {:ok, mounted_socket} = ObanPowertools.Web.Dev.ShowcaseLive.mount(%{}, %{}, socket)
      assigns = mounted_socket.assigns

      unless assigns.page_catalog_available? == false do
        raise "#{package_case.id}: malformed page catalog must fail closed"
      end

      unless assigns.page_stories == [] do
        raise "#{package_case.id}: malformed page stories must be empty"
      end

      unless assigns.active_page_story == nil do
        raise "#{package_case.id}: no page story may become active"
      end

      html =
        assigns
        |> ObanPowertools.Web.Dev.ShowcaseLive.render()
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      unless html =~ ~s(data-obpt-page-index="empty") do
        raise "#{package_case.id}: page placeholder was not rendered"
      end

      IO.puts("PAGE_PACKAGE_CASE_OK #{package_case.id}")
      """
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

    defp active_group_overlay_count(view) do
      ~r/data-obpt-group-story="[^"]+"[^>]*data-obpt-overlay-active="true"/
      |> Regex.scan(render(view))
      |> length()
    end

    defp assert_active_page_story(view, id, root_selector) do
      assert has_element?(
               view,
               "[data-obpt-page-story='#{id}'][data-obpt-page-active='true'] #{root_selector}"
             )

      assert active_page_story_count(view) == 1
      assert count(render(view), ~s(id="#{String.trim_leading(root_selector, "#")}")) == 1
    end

    defp active_page_story_count(view) do
      ~r/data-obpt-page-story="[^"]+"[^>]*data-obpt-page-active="true"/
      |> Regex.scan(render(view))
      |> length()
    end

    defp active_page_overlay_count(view) do
      html = render(view)
      count(html, ~s(role="dialog")) + count(html, "<dialog")
    end

    defp page_root_selector(:overview), do: "#overview-page"
    defp page_root_selector(:cron), do: "#cron-page"
    defp page_root_selector(:limiters), do: "#limiters-page"
    defp page_root_selector(:audit), do: "#audit-page"

    defp assert_in_order(html, values) do
      indexes = Enum.map(values, &(:binary.match(html, &1) |> elem(0)))
      assert indexes == Enum.sort(indexes)
    end
  end
end
