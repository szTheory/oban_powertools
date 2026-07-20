# Dev-only module guard: defined only when dev_routes is enabled at the host's
# compile time (dev/test). In production builds this file defines no fallback
# module, so the route and LiveView stay absent together.
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  defmodule ObanPowertools.Web.Dev.ShowcaseLive do
    @moduledoc """
    Dev-only LiveView for the deterministic Powertools showcase skeleton.

    The canonical scenario data lives in `test/support/showcase_catalog.ex` so it
    stays out of Hex packages. This LiveView resolves that module only at
    runtime, and can require the local support file when the package is used as
    a path dependency in dev.
    """

    use Phoenix.LiveView

    alias ObanPowertools.Web.{AuditLive, CronLive, EngineOverviewLive, LimitersLive}

    alias ObanPowertools.Web.Components.{
      AppShell,
      DataDisplay,
      Forms,
      OperatorPatterns,
      Primitives
    }

    @catalog_module ObanPowertools.ShowcaseCatalog
    @catalog_path Path.expand("../../../../test/support/showcase_catalog.ex", __DIR__)
    @primitive_catalog_module ObanPowertools.PrimitiveStoryCatalog
    @primitive_catalog_path Path.expand(
                              "../../../../test/support/primitive_story_catalog.ex",
                              __DIR__
                            )
    @form_catalog_module ObanPowertools.FormStoryCatalog
    @form_catalog_path Path.expand("../../../../test/support/form_story_catalog.ex", __DIR__)
    @shell_catalog_module ObanPowertools.ShellStoryCatalog
    @shell_catalog_path Path.expand("../../../../test/support/shell_story_catalog.ex", __DIR__)
    @data_catalog_module ObanPowertools.DataDisplayStoryCatalog
    @data_catalog_path Path.expand(
                         "../../../../test/support/data_display_story_catalog.ex",
                         __DIR__
                       )
    @group_catalog_module ObanPowertools.OperatorPatternStoryCatalog
    @group_catalog_path Path.expand(
                          "../../../../test/support/operator_pattern_story_catalog.ex",
                          __DIR__
                        )
    @page_catalog_module ObanPowertools.PageStoryCatalog
    @page_catalog_path Path.expand(
                         "../../../../test/support/page_story_catalog.ex",
                         __DIR__
                       )
    @page_story_count 19
    @page_story_pages [:overview, :cron, :limiters, :audit]
    @page_story_activations [:none, :detail, :confirmation]

    @theme_choices [
      %{value: "system", label: "System"},
      %{value: "light", label: "Light"},
      %{value: "dark", label: "Dark"},
      %{value: "high-contrast", label: "High contrast"}
    ]

    @viewport_choices [
      %{value: "320", label: "320"},
      %{value: "tablet", label: "Tablet"},
      %{value: "wide", label: "Wide"}
    ]

    @section_list [
      %{id: "app-shell", title: "App shell"},
      %{id: "tokens", title: "Tokens"},
      %{id: "primitives", title: "Primitives"},
      %{id: "forms", title: "Forms"},
      %{id: "data-display", title: "Data Display"},
      %{id: "operator-groups", title: "Operator Groups"},
      %{id: "pages", title: "Pages"},
      %{id: "stress-fixtures", title: "Stress Fixtures"}
    ]

    @open_state_targets [
      %{target: "confirm_action_open", owner: "Confirm action dialog"},
      %{target: "tooltip_open", owner: "Tooltip"},
      %{target: "drawer_open", owner: "Drawer"}
    ]

    @impl Phoenix.LiveView
    def mount(_params, _session, socket) do
      catalog = load_catalog()
      primitive_catalog = load_primitive_catalog()
      form_catalog = load_form_catalog()
      shell_catalog = load_shell_catalog()
      data_catalog = load_data_catalog()
      group_catalog = load_group_catalog()
      page_catalog = load_page_catalog()

      {:ok,
       socket
       |> seed_data_flash(data_catalog.stories)
       |> assign(:page_title, "Powertools Showcase")
       |> assign(:theme_choices, @theme_choices)
       |> assign(:viewport_choices, @viewport_choices)
       |> assign(:selected_viewport, "wide")
       |> assign(:sections, @section_list)
       |> assign(:open_state_targets, @open_state_targets)
       |> assign(:catalog_available?, catalog.available?)
       |> assign(:catalog_scenarios, catalog.scenarios)
       |> assign(:catalog_domains, catalog.domains)
       |> assign(:primitive_catalog_available?, primitive_catalog.available?)
       |> assign(:primitive_stories, primitive_catalog.stories)
       |> assign(:form_catalog_available?, form_catalog.available?)
       |> assign(:form_stories, form_catalog.stories)
       |> assign(:shell_catalog_available?, shell_catalog.available?)
       |> assign(:shell_stories, shell_catalog.stories)
       |> assign(:data_catalog_available?, data_catalog.available?)
       |> assign(:data_stories, data_catalog.stories)
       |> assign(:data_sort_key, "worker")
       |> assign(:data_sort_direction, :asc)
       |> assign(:group_catalog_available?, group_catalog.available?)
       |> assign(:group_stories, group_catalog.stories)
       |> assign(:active_group_overlay, nil)
       |> assign(:group_confirmation_story_id, nil)
       |> assign(:group_confirmation_state, :preview)
       |> assign(:group_confirmation_form, group_confirmation_form())
       |> assign(:group_confirmation_errors, %{})
       |> assign(:group_confirmation_results, [])
       |> assign(:group_confirmation_mutation_count, 0)
       |> assign(:group_confirmation_receipt_count, 0)
       |> assign(:group_receipt, nil)
       |> assign(:group_filter_states, initial_group_filter_states(group_catalog.stories))
       |> assign(:group_detail_state, initial_group_detail_state())
       |> assign(:page_catalog_available?, page_catalog.available?)
       |> assign(:page_stories, page_catalog.stories)
       |> assign(:active_page_story, nil)}
    end

    @impl Phoenix.LiveView
    def handle_event("select_viewport", %{"viewport" => viewport}, socket) do
      if viewport in Enum.map(@viewport_choices, & &1.value) do
        {:noreply, assign(socket, :selected_viewport, viewport)}
      else
        {:noreply, socket}
      end
    end

    def handle_event("sort-data-table", %{"sort-key" => sort_key}, socket)
        when sort_key in ["id", "worker", "state"] do
      direction =
        if socket.assigns.data_sort_key == sort_key do
          toggle_sort_direction(socket.assigns.data_sort_direction)
        else
          :asc
        end

      {:noreply, assign(socket, data_sort_key: sort_key, data_sort_direction: direction)}
    end

    def handle_event("activate-group-story", %{"id" => id}, socket) do
      {:noreply, activate_group_story(socket, id)}
    end

    def handle_event("activate-page-story", %{"id" => id}, socket) do
      case Enum.find(socket.assigns.page_stories, &(&1.id == id)) do
        nil -> {:noreply, socket}
        story -> {:noreply, assign(socket, :active_page_story, story.id)}
      end
    end

    def handle_event("validate-group-confirmation", %{"group_confirmation" => params}, socket) do
      with %{fixtures: fixtures} <- active_group_story(socket),
           true <- confirmation_story?(socket.assigns.active_group_overlay) do
        {form, errors} = validate_group_confirmation(params, fixtures.frozen_count)

        {:noreply,
         assign(socket,
           group_confirmation_form: form,
           group_confirmation_errors: errors
         )}
      else
        _ -> {:noreply, socket}
      end
    end

    def handle_event("submit-group-confirmation", %{"group_confirmation" => params}, socket) do
      with %{fixtures: fixtures} <- active_group_story(socket),
           true <- confirmation_story?(socket.assigns.active_group_overlay) do
        {form, errors} = validate_group_confirmation(params, fixtures.frozen_count)

        cond do
          errors != %{} ->
            {:noreply,
             assign(socket,
               group_confirmation_form: form,
               group_confirmation_errors: errors,
               group_confirmation_state: :preview
             )}

          socket.assigns.group_confirmation_mutation_count > 0 ->
            {:noreply, socket}

          fixtures.lifecycle in [:expired, :drifted, :consumed] ->
            {:noreply, assign(socket, :group_confirmation_state, fixtures.lifecycle)}

          fixtures.lifecycle in [:partial, :failed] ->
            {:noreply,
             assign(socket,
               group_confirmation_form: form,
               group_confirmation_state: fixtures.lifecycle,
               group_confirmation_results: fixtures.results
             )}

          fixtures.lifecycle == :submitting ->
            {:noreply, assign(socket, :group_confirmation_state, :submitting)}

          true ->
            {:noreply,
             socket
             |> assign(:group_confirmation_form, form)
             |> assign(:group_confirmation_errors, %{})
             |> assign(:group_confirmation_mutation_count, 1)
             |> assign(:group_confirmation_receipt_count, 1)
             |> assign(:group_receipt, group_confirmation_receipt(fixtures))
             |> assign(:active_group_overlay, nil)}
        end
      else
        _ -> {:noreply, socket}
      end
    end

    def handle_event("submit-group-confirmation", _params, socket), do: {:noreply, socket}

    def handle_event("fresh-group-preview", _params, socket) do
      if confirmation_story?(socket.assigns.active_group_overlay) do
        {:noreply, assign(socket, :group_confirmation_state, :preview)}
      else
        {:noreply, socket}
      end
    end

    def handle_event("validate-group-filters", %{"group_filters" => params}, socket) do
      {:noreply, update_group_filter_state(socket, params, :validate)}
    end

    def handle_event("apply-group-filters", %{"group_filters" => params}, socket) do
      {:noreply, update_group_filter_state(socket, params, :apply)}
    end

    def handle_event("remove-group-filter", %{"id" => id, "field" => field}, socket) do
      {:noreply, remove_group_filter(socket, id, field)}
    end

    def handle_event("clear-group-filters", %{"id" => id}, socket) do
      {:noreply, clear_group_filters(socket, id)}
    end

    def handle_event("open-group-detail", %{"id" => id}, socket) do
      {:noreply, activate_group_story(socket, id)}
    end

    def handle_event("select-group-detail", %{"resource-id" => resource_id}, socket) do
      detail_state = socket.assigns.group_detail_state
      operation = if detail_state.selected_id, do: :replace, else: :push
      url = "/ops/jobs/_showcase?detail=#{URI.encode_www_form(resource_id)}"

      {:noreply,
       assign(socket, :group_detail_state, %{
         detail_state
         | selected_id: resource_id,
           canonical_url: url,
           history: detail_state.history ++ [{operation, url}],
           loaded_announcement: "Job #{resource_id} details loaded."
       })}
    end

    def handle_event("close-group-detail", _params, socket) do
      detail_state = socket.assigns.group_detail_state
      url = "/ops/jobs/_showcase"

      {:noreply,
       socket
       |> assign(:active_group_overlay, nil)
       |> assign(:group_detail_state, %{
         detail_state
         | selected_id: nil,
           canonical_url: url,
           history: detail_state.history ++ [{:replace, url}],
           loaded_announcement: nil
       })}
    end

    def handle_event(_event, _params, socket), do: {:noreply, socket}

    @impl Phoenix.LiveView
    def render(assigns) do
      ~H"""
      <div class="obpt-showcase" data-obpt-showcase>
        <header class="obpt-showcase-header">
          <div>
            <p class="obpt-showcase-eyebrow">Design system guardrail</p>
            <h1>Powertools Showcase</h1>
            <p>
              Token, theme, viewport, and fixture contracts for deterministic design-system audits.
            </p>
          </div>
        </header>

        <section class="obpt-showcase-controls" aria-label="Showcase controls">
          <div class="obpt-showcase-control-group" data-obpt-theme-controls>
            <h2>Theme</h2>
            <div class="obpt-showcase-segmented">
              <button
                :for={theme <- @theme_choices}
                type="button"
                class="obpt-button obpt-button--neutral"
                data-obpt-theme-choice={theme.value}
              >
                {theme.label}
              </button>
            </div>
          </div>

          <div class="obpt-showcase-control-group">
            <h2>Viewport</h2>
            <div class="obpt-showcase-segmented">
              <button
                :for={viewport <- @viewport_choices}
                type="button"
                class={[
                  "obpt-button",
                  if(@selected_viewport == viewport.value,
                    do: "obpt-button--primary",
                    else: "obpt-button--neutral"
                  )
                ]}
                phx-click="select_viewport"
                phx-value-viewport={viewport.value}
                aria-pressed={@selected_viewport == viewport.value}
                data-obpt-viewport={viewport.value}
              >
                {viewport.label}
              </button>
            </div>
          </div>
        </section>

        <nav class="obpt-showcase-section-nav" aria-label="Showcase sections">
          <a :for={section <- @sections} href={"##{section.id}"}>
            {section.title}
          </a>
        </nav>

        <div class={"obpt-showcase-canvas obpt-showcase-canvas--#{@selected_viewport}"}>
          <section
            :for={section <- @sections}
            id={section.id}
            class="obpt-showcase-section"
            data-obpt-section={section.id}
          >
            <header>
              <p class="obpt-showcase-eyebrow">Section</p>
              <h2>{section.title}</h2>
            </header>

            <%= case section.id do %>
              <% "app-shell" -> %>
                <%= if @shell_catalog_available? and @shell_stories != [] do %>
                  <div class="obpt-showcase-story-grid">
                    <article
                      :for={story <- @shell_stories}
                      id={target_value(story.test_targets, :story)}
                      class="obpt-showcase-story"
                      data-obpt-shell-story={story.id}
                      data-obpt-component={component_value(story)}
                      data-obpt-variant={state_value(story.variant)}
                      data-obpt-state={state_value(story.state)}
                      data-obpt-nav-state={state_value(story.nav_state)}
                      data-obpt-a11y-target={target_value(story.test_targets, :a11y)}
                    >
                      <header><p>{component_value(story)}</p><h3>{story.name}</h3></header>
                      <p>{story.description}</p>
                      <.shell_story_body story={story} />
                      <dl>
                        <div>
                          <dt>Snapshot</dt>
                          <dd><code>{target_value(story.test_targets, :snapshot)}</code></dd>
                        </div>
                        <div>
                          <dt>A11y target</dt>
                          <dd><code>{target_value(story.test_targets, :a11y)}</code></dd>
                        </div>
                      </dl>
                    </article>
                  </div>
                <% else %>
                  <p class="obpt-showcase-placeholder" data-obpt-shell-index="empty">
                    No shell stories registered. Add token-backed shell stories before updating visual baselines.
                  </p>
                <% end %>
              <% "tokens" -> %>
              <div class="obpt-showcase-token-grid">
                <div class="obpt-showcase-token" data-obpt-tone="accent">
                  <span>Accent</span>
                  <strong>Safe action</strong>
                </div>
                <div class="obpt-showcase-token" data-obpt-tone="info">
                  <span>Info</span>
                  <strong>Context</strong>
                </div>
                <div class="obpt-showcase-token" data-obpt-tone="warning">
                  <span>Warning</span>
                  <strong>Attention</strong>
                </div>
                <div class="obpt-showcase-token" data-obpt-tone="danger">
                  <span>Danger</span>
                  <strong>Destructive</strong>
                </div>
              </div>
              <% "primitives" -> %>
                <%= if @primitive_catalog_available? and @primitive_stories != [] do %>
                  <div class="obpt-showcase-story-grid">
                    <article
                      :for={story <- @primitive_stories}
                      id={target_value(story.test_targets, :story)}
                      class="obpt-showcase-story"
                      data-obpt-primitive-story={story.id}
                      data-obpt-component={component_value(story)}
                      data-obpt-variant={state_value(story.variant)}
                      data-obpt-state={state_value(story.state)}
                      data-obpt-a11y-target={target_value(story.test_targets, :a11y)}
                    >
                      <header>
                        <p>{component_value(story)}</p>
                        <h3>{story.name}</h3>
                      </header>

                      <p>{story.description}</p>

                      <.primitive_story_body story={story} />

                      <dl>
                        <div>
                          <dt>Snapshot</dt>
                          <dd><code>{target_value(story.test_targets, :snapshot)}</code></dd>
                        </div>
                        <div>
                          <dt>A11y target</dt>
                          <dd><code>{target_value(story.test_targets, :a11y)}</code></dd>
                        </div>
                      </dl>
                    </article>
                  </div>
                <% else %>
                  <p class="obpt-showcase-placeholder" data-obpt-primitive-index="empty">
                    No primitive stories registered. Add token-backed primitive stories before updating visual baselines.
                  </p>
                <% end %>
              <% "forms" -> %>
                <%= if @form_catalog_available? and @form_stories != [] do %>
                  <div class="obpt-showcase-story-grid">
                    <article
                      :for={story <- @form_stories}
                      id={target_value(story.test_targets, :story)}
                      class="obpt-showcase-story"
                      data-obpt-form-story={story.id}
                      data-obpt-component={component_value(story)}
                      data-obpt-variant={state_value(story.variant)}
                      data-obpt-state={state_value(story.state)}
                      data-obpt-a11y-target={target_value(story.test_targets, :a11y)}
                    >
                      <header><p>{component_value(story)}</p><h3>{story.name}</h3></header>
                      <p>{story.description}</p>
                      <.form_story_body story={story} />
                      <dl><div><dt>Snapshot</dt><dd><code>{target_value(story.test_targets, :snapshot)}</code></dd></div></dl>
                    </article>
                  </div>
                <% else %>
                  <p class="obpt-showcase-placeholder" data-obpt-form-index="empty">
                    No form stories registered. Add token-backed form stories before updating visual baselines.
                  </p>
                <% end %>
              <% "data-display" -> %>
                <%= if @data_catalog_available? and @data_stories != [] do %>
                  <div class="obpt-showcase-story-grid">
                    <article
                      :for={story <- @data_stories}
                      id={target_value(story.test_targets, :story)}
                      class="obpt-showcase-story"
                      data-obpt-data-story={story.id}
                      data-obpt-component={component_value(story)}
                      data-obpt-variant={state_value(story.variant)}
                      data-obpt-state={state_value(story.state)}
                      data-obpt-a11y-target={target_value(story.test_targets, :a11y)}
                    >
                      <header><p>{component_value(story)}</p><h3>{story.name}</h3></header>
                      <p>{story.description}</p>
                      <.data_story_body
                        story={story}
                        flash={@flash}
                        sort_key={@data_sort_key}
                        sort_direction={@data_sort_direction}
                      />
                      <dl><div><dt>Snapshot</dt><dd><code>{target_value(story.test_targets, :snapshot)}</code></dd></div></dl>
                    </article>
                  </div>
                <% else %>
                  <p class="obpt-showcase-placeholder" data-obpt-data-index="empty">
                    No data-display stories registered. Add deterministic data stories before updating visual baselines.
                  </p>
                <% end %>
              <% "operator-groups" -> %>
                <%= if @group_catalog_available? and @group_stories != [] do %>
                  <p
                    :if={@group_receipt}
                    id="obpt-group-receipt"
                    class="obpt-showcase-placeholder"
                    role="status"
                    data-obpt-group-receipt-count={@group_confirmation_receipt_count}
                  >
                    {@group_receipt}
                  </p>
                  <div class="obpt-showcase-story-grid">
                    <article
                      :for={story <- @group_stories}
                      id={target_value(story.test_targets, :story)}
                      class="obpt-showcase-story"
                      data-obpt-group-story={story.id}
                      data-obpt-component={component_value(story)}
                      data-obpt-variant={state_value(story.variant)}
                      data-obpt-state={state_value(story.state)}
                      data-obpt-activation={story.activation}
                      data-obpt-overlay-active={to_string(@active_group_overlay == story.id)}
                      data-obpt-a11y-target={target_value(story.test_targets, :a11y)}
                    >
                      <header><p>{component_value(story)}</p><h3>{story.name}</h3></header>
                      <p>{story.description}</p>
                      <div
                        class="obpt-primitive-matrix"
                        data-obpt-group-story-stage={story.id}
                        data-obpt-overlay-active={to_string(@active_group_overlay == story.id)}
                      >
                        <Primitives.button
                          :if={story.activation == :overlay and @active_group_overlay != story.id}
                          type="button"
                          variant={:primary}
                          phx-click="activate-group-story"
                          phx-value-id={story.id}
                        >
                          Open {story.name}
                        </Primitives.button>
                        <.group_story_body
                          :if={story.activation == :none or @active_group_overlay == story.id}
                          story={story}
                          confirmation_state={@group_confirmation_state}
                          confirmation_form={@group_confirmation_form}
                          confirmation_results={@group_confirmation_results}
                          filter_states={@group_filter_states}
                          detail_state={@group_detail_state}
                        />
                      </div>
                      <dl>
                        <div><dt>Snapshot</dt><dd><code>{target_value(story.test_targets, :snapshot)}</code></dd></div>
                        <div><dt>Activation</dt><dd><code>{story.activation}</code></dd></div>
                      </dl>
                    </article>
                  </div>
                <% else %>
                  <p class="obpt-showcase-placeholder" data-obpt-group-index="empty">
                    No operator-pattern stories registered. Add deterministic group stories before updating visual baselines.
                  </p>
                <% end %>
              <% "pages" -> %>
                <%= if @page_catalog_available? and @page_stories != [] do %>
                  <div class="obpt-showcase-story-grid">
                    <article
                      :for={story <- @page_stories}
                      id={target_value(story.test_targets, :story)}
                      class="obpt-showcase-story"
                      data-obpt-page-story={story.id}
                      data-obpt-page={story.page}
                      data-obpt-component={component_value(story)}
                      data-obpt-variant={state_value(story.variant)}
                      data-obpt-state={state_value(story.state)}
                      data-obpt-activation={story.activation}
                      data-obpt-page-active={to_string(@active_page_story == story.id)}
                      data-obpt-a11y-target={target_value(story.test_targets, :a11y)}
                    >
                      <header><p>{stringify(story.page)}</p><h3>{story.name}</h3></header>
                      <p>{story.description}</p>
                      <div
                        class="obpt-primitive-matrix"
                        data-obpt-page-story-stage={story.id}
                        data-obpt-page-active={to_string(@active_page_story == story.id)}
                      >
                        <Primitives.button
                          :if={@active_page_story != story.id}
                          type="button"
                          variant={:primary}
                          phx-click="activate-page-story"
                          phx-value-id={story.id}
                        >
                          Open {story.name}
                        </Primitives.button>
                        <.page_story_body :if={@active_page_story == story.id} story={story} />
                      </div>
                      <dl>
                        <div><dt>Snapshot</dt><dd><code>{target_value(story.test_targets, :snapshot)}</code></dd></div>
                        <div><dt>Activation</dt><dd><code>{story.activation}</code></dd></div>
                      </dl>
                    </article>
                  </div>
                <% else %>
                  <p class="obpt-showcase-placeholder" data-obpt-page-index="empty">
                    No page stories registered. Add deterministic production-composition stories before updating visual baselines.
                  </p>
                <% end %>
              <% _ -> %>
                <p class="obpt-showcase-placeholder">
                  Reserved for Phase-owned stories. The anchor and selector are stable now.
                </p>
            <% end %>
          </section>

          <section
            class="obpt-showcase-section"
            aria-labelledby="open-state-targets-heading"
          >
            <header>
              <p class="obpt-showcase-eyebrow">D-09 metadata</p>
              <h2 id="open-state-targets-heading">Reserved Open States</h2>
            </header>

            <div class="obpt-showcase-open-targets">
              <div
                :for={entry <- @open_state_targets}
                class="obpt-showcase-open-target"
                data-obpt-open-state-target={entry.target}
              >
                <code>{entry.target}</code>
                <span>{entry.owner}</span>
              </div>
            </div>
          </section>

          <section
            id="fixture-index"
            class="obpt-showcase-section"
            aria-labelledby="fixture-index-heading"
          >
            <header>
              <p class="obpt-showcase-eyebrow">Catalog</p>
              <h2 id="fixture-index-heading">Fixture Index</h2>
            </header>

            <%= if @catalog_available? and @catalog_scenarios != [] do %>
              <div class="obpt-showcase-fixture-index">
                <div class="obpt-showcase-fixture-index-head">
                  <span>Scenario</span>
                  <span>Domain</span>
                  <span>Persona</span>
                  <span>States</span>
                </div>
                <div
                  :for={scenario <- @catalog_scenarios}
                  class="obpt-showcase-fixture-index-row"
                  data-obpt-fixture-index={scenario.id}
                >
                  <span>{scenario.name}</span>
                  <code>{stringify(scenario.domain)}</code>
                  <code>{stringify(scenario.persona)}</code>
                  <span>{state_value(scenario.states)}</span>
                </div>
              </div>
            <% else %>
              <p class="obpt-showcase-placeholder" data-obpt-fixture-index="empty">
                Catalog data is unavailable in this build; stable controls and anchors remain mounted.
              </p>
            <% end %>
          </section>

          <section
            id="catalog-stories"
            class="obpt-showcase-section"
            aria-labelledby="catalog-stories-heading"
          >
            <header>
              <p class="obpt-showcase-eyebrow">Stories</p>
              <h2 id="catalog-stories-heading">Catalog-backed Story Cells</h2>
            </header>

            <div class="obpt-showcase-story-grid">
              <article
                :for={scenario <- @catalog_scenarios}
                id={"obpt-story-#{scenario.id}"}
                class="obpt-showcase-story"
                data-obpt-story={scenario.id}
                data-obpt-domain={stringify(scenario.domain)}
                data-obpt-persona={stringify(scenario.persona)}
                data-obpt-state={state_value(scenario.states)}
              >
                <header>
                  <p>{stringify(scenario.domain)}</p>
                  <h3>{scenario.name}</h3>
                </header>

                <p>{scenario.jtbd}</p>

                <dl>
                  <div>
                    <dt>Snapshot</dt>
                    <dd><code>{target_value(scenario.test_targets, :snapshot)}</code></dd>
                  </div>
                  <div>
                    <dt>A11y target</dt>
                    <dd><code>{target_value(scenario.test_targets, :a11y)}</code></dd>
                  </div>
                </dl>

                <pre tabindex="0" aria-label={"#{scenario.name} fixture data"}><code>{inspect(scenario.fixtures, pretty: true, limit: 30)}</code></pre>
              </article>
            </div>
          </section>
        </div>
      </div>
      """
    end

    defp load_catalog do
      with {:ok, module} <- ensure_catalog_module(),
           true <- function_exported?(module, :scenarios, 0),
           true <- function_exported?(module, :domains, 0) do
        %{
          available?: true,
          scenarios: apply(module, :scenarios, []),
          domains: apply(module, :domains, [])
        }
      else
        _ -> %{available?: false, scenarios: [], domains: []}
      end
    end

    defp load_primitive_catalog do
      with {:ok, module} <- ensure_primitive_catalog_module(),
           true <- function_exported?(module, :stories, 0) do
        %{
          available?: true,
          stories: apply(module, :stories, [])
        }
      else
        _ -> %{available?: false, stories: []}
      end
    end

    defp load_form_catalog do
      with {:ok, module} <- ensure_form_catalog_module(),
           true <- function_exported?(module, :stories, 0) do
        %{available?: true, stories: apply(module, :stories, [])}
      else
        _ -> %{available?: false, stories: []}
      end
    end

    defp load_shell_catalog do
      with {:ok, module} <- ensure_shell_catalog_module(),
           true <- function_exported?(module, :stories, 0) do
        %{available?: true, stories: apply(module, :stories, [])}
      else
        _ -> %{available?: false, stories: []}
      end
    end

    defp load_data_catalog do
      with {:ok, module} <- ensure_data_catalog_module(),
           true <- function_exported?(module, :stories, 0),
           stories when is_list(stories) <- apply(module, :stories, []) do
        %{available?: true, stories: stories}
      else
        _ -> %{available?: false, stories: []}
      end
    end

    defp load_group_catalog do
      with {:ok, module} <- ensure_group_catalog_module(),
           true <- function_exported?(module, :stories, 0),
           stories when is_list(stories) <- apply(module, :stories, []) do
        %{available?: true, stories: stories}
      else
        _ -> %{available?: false, stories: []}
      end
    end

    defp load_page_catalog do
      with {:ok, module} <- ensure_page_catalog_module(),
           true <- function_exported?(module, :stories, 0),
           stories when is_list(stories) <- apply(module, :stories, []),
           true <- valid_page_catalog?(stories) do
        %{available?: true, stories: stories}
      else
        _ -> %{available?: false, stories: []}
      end
    end

    defp ensure_catalog_module do
      ensure_support_module(@catalog_module, @catalog_path)
    end

    defp ensure_primitive_catalog_module do
      ensure_support_module(@primitive_catalog_module, @primitive_catalog_path)
    end

    defp ensure_form_catalog_module do
      ensure_support_module(@form_catalog_module, @form_catalog_path)
    end

    defp ensure_shell_catalog_module do
      ensure_support_module(@shell_catalog_module, @shell_catalog_path)
    end

    defp ensure_data_catalog_module do
      ensure_support_module(@data_catalog_module, @data_catalog_path)
    end

    defp ensure_group_catalog_module do
      ensure_support_module(@group_catalog_module, @group_catalog_path)
    end

    defp ensure_page_catalog_module do
      ensure_support_module(@page_catalog_module, @page_catalog_path)
    end

    defp ensure_support_module(module, path) do
      cond do
        Code.ensure_loaded?(module) ->
          {:ok, module}

        (Mix.env() != :test or System.get_env("PHASE79_BROWSER_FIXTURES") == "1") and
            File.exists?(path) ->
          Code.require_file(path)

          if Code.ensure_loaded?(module) do
            {:ok, module}
          else
            :error
          end

        true ->
          :error
      end
    end

    defp stringify(value) when is_atom(value), do: Atom.to_string(value)
    defp stringify(value), do: to_string(value)

    defp state_value(states) when is_list(states) do
      states
      |> Enum.map(&stringify/1)
      |> Enum.join(" ")
    end

    defp state_value(state), do: stringify(state)

    defp component_value(%{components: components}) when is_list(components),
      do: state_value(components)

    defp component_value(%{component: component}), do: stringify(component)

    defp target_value(targets, key) when is_map(targets) do
      Map.get(targets, key) || Map.get(targets, Atom.to_string(key)) || ""
    end

    defp target_value(_targets, _key), do: ""

    defp valid_page_catalog?(stories) do
      ids = Enum.map(stories, &Map.get(&1, :id))

      length(stories) == @page_story_count and
        length(Enum.uniq(ids)) == @page_story_count and
        Enum.all?(stories, &valid_page_story?/1)
    end

    defp valid_page_story?(story) when is_map(story) and not is_struct(story) do
      is_binary(Map.get(story, :id)) and Map.get(story, :id) != "" and
        is_binary(Map.get(story, :name)) and Map.get(story, :name) != "" and
        is_binary(Map.get(story, :description)) and Map.get(story, :description) != "" and
        Map.get(story, :page) in @page_story_pages and
        Map.get(story, :activation) in @page_story_activations and
        is_list(Map.get(story, :components)) and Map.get(story, :components) != [] and
        is_list(Map.get(story, :variant)) and Map.get(story, :variant) != [] and
        is_list(Map.get(story, :state)) and Map.get(story, :state) != [] and
        is_map(Map.get(story, :fixtures)) and not is_struct(Map.get(story, :fixtures)) and
        is_map(Map.get(story, :test_targets)) and
        target_value(story.test_targets, :story) == "obpt-page-story-#{story.id}" and
        target_value(story.test_targets, :snapshot) == "showcase/#{story.id}" and
        target_value(story.test_targets, :a11y) ==
          ~s([data-obpt-page-story="#{story.id}"])
    end

    defp valid_page_story?(_story), do: false

    defp toggle_sort_direction(:asc), do: :desc
    defp toggle_sort_direction(_direction), do: :asc

    attr(:story, :map, required: true)

    defp page_story_body(assigns) do
      assigns = assign(assigns, :page_assigns, materialize_page_assigns(assigns.story))

      ~H"""
      <%= case @story.page do %>
        <% :overview -> %>
          <EngineOverviewLive.page_content overview_buckets={@page_assigns.overview_buckets} />
        <% :cron -> %>
          <CronLive.page_content
            entries={@page_assigns.entries}
            read_only?={@page_assigns.read_only?}
            error_message={@page_assigns.error_message}
            selected_entry={@page_assigns.selected_entry}
            detail_open?={@page_assigns.detail_open?}
            history_summary={@page_assigns.history_summary}
            confirmation_open?={@page_assigns.confirmation_open?}
            confirmation_action={@page_assigns.confirmation_action}
            confirmation_state={@page_assigns.confirmation_state}
            confirmation_form={@page_assigns.confirmation_form}
            confirmation_result={@page_assigns.confirmation_result}
            current_actor={@page_assigns.current_actor}
            reason={@page_assigns.reason}
            receipt={@page_assigns.receipt}
          />
        <% :limiters -> %>
          <LimitersLive.page_content
            resource_rows={@page_assigns.resource_rows}
            selected_resource={@page_assigns.selected_resource}
            detail_open?={@page_assigns.detail_open?}
            detail_state={@page_assigns.detail_state}
            detail_presentation={@page_assigns.detail_presentation}
            read_only?={@page_assigns.read_only?}
            error_message={@page_assigns.error_message}
          />
        <% :audit -> %>
          <AuditLive.page_content
            audit_page={@page_assigns.audit_page}
            event_rows={@page_assigns.event_rows}
            filter_form={@page_assigns.filter_form}
            active_filters={@page_assigns.active_filters}
            result_summary={@page_assigns.result_summary}
            selected_event_id={@page_assigns.selected_event_id}
            selected_detail={@page_assigns.selected_detail}
            detail_state={@page_assigns.detail_state}
            retention_summary={@page_assigns.retention_summary}
            load_state={@page_assigns.load_state}
            clear_filters_href={@page_assigns.clear_filters_href}
            read_only_copy={@page_assigns.read_only_copy}
          />
      <% end %>
      """
    end

    defp materialize_page_assigns(%{page: :overview, fixtures: fixtures}), do: fixtures

    defp materialize_page_assigns(%{page: :cron} = story) do
      story.fixtures
      |> Map.put(:detail_open?, story.activation == :detail)
      |> Map.put(:confirmation_open?, story.activation == :confirmation)
      |> Map.update!(:confirmation_form, &to_form(&1, as: :confirmation))
    end

    defp materialize_page_assigns(%{page: :limiters} = story) do
      Map.put(story.fixtures, :detail_open?, story.activation == :detail)
    end

    defp materialize_page_assigns(%{page: :audit} = story) do
      detail_state =
        if story.activation == :detail and story.fixtures.selected_detail do
          :ready
        else
          story.fixtures.detail_state
        end

      story.fixtures
      |> Map.put(:detail_state, detail_state)
      |> Map.update!(:filter_form, &to_form(&1, as: :filters, id: "page-story-audit-filters"))
    end

    attr(:story, :map, required: true)
    attr(:flash, :map, required: true)
    attr(:sort_key, :string, required: true)
    attr(:sort_direction, :atom, required: true)

    defp data_story_body(assigns) do
      rows = Map.get(assigns.story.fixtures, :rows, [])

      assigns
      |> assign(:sorted_rows, sort_data_rows(rows, assigns.sort_key, assigns.sort_direction))
      |> assign(
        :selection_form,
        to_form(%{"selected" => "false"}, as: "showcase_data_selection")
      )
      |> render_data_story()
    end

    defp render_data_story(assigns) do
      ~H"""
      <div class="obpt-primitive-matrix">
        <%= case @story.id do %>
          <% "data-table-sort-states" -> %>
            <DataDisplay.data_table
              id="data-sort-table"
              caption="Sortable jobs"
              resource="jobs"
              rows={@sorted_rows}
              row_id={& &1.id}
              sort_key={@sort_key}
              sort_direction={@sort_direction}
              sort_event="sort-data-table"
            >
              <:col :let={row} label="Job ID" sort_key="id" value_kind={:id}>
                <DataDisplay.machine_value id={"data-sort-id-#{row.id}"} value={row.id} />
              </:col>
              <:col :let={row} label="Worker" sort_key="worker" value_kind={:module}>
                <DataDisplay.machine_value id={"data-sort-worker-#{row.id}"} value={row.worker} kind={:module} />
              </:col>
              <:col :let={row} label="State" sort_key="state">
                <DataDisplay.status_pill id={"data-sort-state-#{row.id}"} domain={:job} state={row.state} />
              </:col>
            </DataDisplay.data_table>
          <% "data-table-320-stacked" -> %>
            <DataDisplay.data_table
              id="data-stacked-table"
              caption="Selectable jobs at 320 pixels"
              rows={@story.fixtures.rows}
              row_id={& &1.id}
              resource="jobs"
            >
              <:selection :let={row}>
                <Forms.checkbox
                  field={@selection_form[:selected]}
                  id={"data-select-#{row.id}"}
                  label={"Select job #{row.id}"}
                  phx-click="select_data_row"
                  phx-value-id={row.id}
                />
              </:selection>
              <:col :let={row} label="Job ID" value_kind={:id}>
                <DataDisplay.machine_value id={"data-stacked-id-#{row.id}"} value={row.id} />
              </:col>
              <:col :let={row} label="Worker" value_kind={:module}>
                <DataDisplay.machine_value id={"data-stacked-worker-#{row.id}"} value={row.worker} kind={:module} />
              </:col>
            </DataDisplay.data_table>
          <% "data-table-explicit-states" -> %>
            <DataDisplay.data_table
              :for={state <- @story.fixtures.states}
              id={"data-state-table-#{state}"}
              caption={"Jobs: #{String.replace(to_string(state), "_", " ")}"}
              rows={[]}
              row_id={& &1.id}
              state={state}
              resource="jobs"
            >
              <:col :let={row} label="Job ID">{row.id}</:col>
            </DataDisplay.data_table>
          <% "data-status-taxonomy-all" -> %>
            <div class="obpt-primitive-row" aria-label="Complete status taxonomy">
              <DataDisplay.status_pill
                :for={entry <- @story.fixtures.taxonomy}
                id={"data-taxonomy-#{entry.domain}-#{entry.state}"}
                domain={entry.domain}
                state={entry.state}
              />
            </div>
          <% "data-description-list-long-values" -> %>
            <DataDisplay.description_list id="data-long-description-list">
              <:item label="Job ID" value_kind={:id}>
                <DataDisplay.machine_value id="data-long-id" value={@story.fixtures.values.id} expand />
              </:item>
              <:item label="Worker" value_kind={:module}>
                <DataDisplay.machine_value id="data-long-module" value={@story.fixtures.values.module} kind={:module} expand />
              </:item>
              <:item label="URL" value_kind={:url}>
                <DataDisplay.machine_value id="data-long-url" value={@story.fixtures.values.url} kind={:url} expand />
              </:item>
              <:item label="Hostile ordinary text">{@story.fixtures.values.hostile}</:item>
              <:item label="RTL and emoji">{@story.fixtures.values.unicode}</:item>
            </DataDisplay.description_list>
            <DataDisplay.key_value id="data-long-key-value" label="Attempt" value="20 of 20" value_kind={:literal} />
          <% "data-timeline-event-log" -> %>
            <DataDisplay.timeline id="data-event-timeline">
              <:event
                :for={event <- @story.fixtures.events}
                timestamp={event.timestamp}
                title={event.title}
                source={event.source}
                domain={event.domain}
                state={event.state}
              >
                <DataDisplay.code_block
                  id={"data-event-detail-#{event.timestamp}"}
                  label={"#{event.title} detail"}
                  content={event.detail}
                />
              </:event>
            </DataDisplay.timeline>
          <% "data-progress-metric-cards" -> %>
            <DataDisplay.progress_bar
              id="data-progress-ready"
              label="Batch completion"
              value={@story.fixtures.progress.value}
              max={@story.fixtures.progress.max}
            />
            <DataDisplay.progress_bar id="data-progress-unavailable" label="Remote progress" />
            <div class="obpt-primitive-row">
              <DataDisplay.metric_card id="data-metric-retryable" label="Retryable jobs" value={to_string(@story.fixtures.metrics.retryable)} trend="3 blocked" tone={:warning} />
              <DataDisplay.metric_card id="data-metric-completed" label="Completed jobs" value={to_string(@story.fixtures.metrics.completed)} trend="all queues healthy" tone={:success} />
            </div>
          <% "data-code-args-redaction" -> %>
            <DataDisplay.args_viewer id="data-args-json" label="Normalized JSON arguments" display={@story.fixtures.args.raw_json} />
            <DataDisplay.args_viewer id="data-args-policy" label="Policy-redacted arguments" display={@story.fixtures.args.policy} />
            <DataDisplay.args_viewer id="data-args-fallback" label="Fallback-redacted arguments" display={@story.fixtures.args.fallback} />
            <div class="obpt-primitive-row">
              <DataDisplay.redacted_value id="data-redacted-enqueue" reason={:enqueue} />
              <DataDisplay.redacted_value id="data-redacted-policy" reason={:policy} />
              <DataDisplay.redacted_value id="data-redacted-fallback" reason={:fallback} message="[redacted]" />
            </div>
            <DataDisplay.code_block id="data-stacktrace" label="Representative stacktrace" content={@story.fixtures.values.stacktrace} language="stacktrace" />
          <% "data-empty-toast-flash" -> %>
            <DataDisplay.empty_state
              id="data-empty-state"
              heading="No rows match the current filters"
              body="Clear filters or widen the time window."
            />
            <DataDisplay.toast id="data-warning-toast" tone={:warning} urgency={:assertive}>
              Retryable jobs require operator review.
            </DataDisplay.toast>
            <DataDisplay.flash_group id="data-flash-group" flash={@flash} />
          <% "data-table-thousands-row-stress" -> %>
            <DataDisplay.data_table
              id="data-thousands-table"
              caption="2,500 jobs"
              resource="jobs"
              rows={@story.fixtures.window}
              row_id={& &1.id}
              row_count={@story.fixtures.total}
              pagination_summary="Page 50 of 125"
            >
              <:col :let={row} label="Job ID" value_kind={:id}>{row.id}</:col>
              <:col :let={row} label="Worker" value_kind={:module}>{row.worker}</:col>
              <:col :let={row} label="State">{row.state}</:col>
            </DataDisplay.data_table>
        <% end %>
      </div>
      """
    end

    defp sort_data_rows(rows, sort_key, direction) do
      sorted = Enum.sort_by(rows, &sort_value(&1, sort_key))
      if direction == :desc, do: Enum.reverse(sorted), else: sorted
    end

    defp sort_value(row, "id"), do: row.id
    defp sort_value(row, "worker"), do: row.worker
    defp sort_value(row, "state"), do: to_string(row.state)
    defp sort_value(row, _key), do: row.id

    defp seed_data_flash(socket, stories) do
      flash =
        Enum.find_value(stories, %{}, fn
          %{id: "data-empty-toast-flash", fixtures: %{flash: flash}} when is_map(flash) ->
            flash

          _story ->
            nil
        end)

      Enum.reduce(flash, socket, fn {key, message}, socket ->
        put_flash(socket, key, message)
      end)
    end

    attr(:story, :map, required: true)

    defp shell_story_body(assigns) do
      ~H"""
      <AppShell.app_shell
        current_path={@story.current_path}
        current_actor={@story.actor}
        context_label={@story.context_label}
        nav_state={@story.nav_state}
        id_scope={@story.id}
      >
        <section class="obpt-primitive-matrix" aria-label={"#{@story.name} representative content"}>
          <h4>{@story.name}</h4>
          <p>{shell_story_summary(@story.id)}</p>
          <dl>
            <div>
              <dt>Current path</dt>
              <dd><code>{@story.current_path}</code></dd>
            </div>
            <div>
              <dt>Evidence state</dt>
              <dd>{state_value(@story.state)}</dd>
            </div>
          </dl>
        </section>
      </AppShell.app_shell>
      """
    end

    defp shell_story_summary("shell-nine-surface-nav"),
      do: "All nine native Powertools surfaces remain visible and ordered."

    defp shell_story_summary("shell-mobile-collapsed"),
      do: "Collapsed mobile navigation keeps the disclosure source of truth closed."

    defp shell_story_summary("shell-mobile-expanded"),
      do: "Expanded mobile navigation keeps the disclosure source of truth open."

    defp shell_story_summary("shell-active-breadcrumb"),
      do: "The Jobs route and Job detail breadcrumb are active from server path context."

    defp shell_story_summary("shell-theme-actor-context"),
      do: "Theme choices render beside explicit test actor and context labels."

    defp shell_story_summary("shell-long-context-wrapping"),
      do: "Escaped long context text wraps without becoming markup or host state."

    defp shell_story_summary(_id), do: "Representative AppShell evidence."

    attr(:story, :map, required: true)

    defp primitive_story_body(assigns) do
      ~H"""
      <%= case @story.id do %>
        <% "primitive-button-matrix" -> %>
          <div class="obpt-primitive-matrix">
            <div class="obpt-primitive-row">
              <Primitives.button variant={:primary}>Retry job</Primitives.button>
              <Primitives.button variant={:warning}>Pause queue</Primitives.button>
              <Primitives.button
                id="primitive-cancel-job"
                variant={:danger}
                disabled_reason="Cancel job - requires operator role"
                phx-click="cancel"
              >
                Cancel job
              </Primitives.button>
              <Primitives.button variant={:ghost}>View audit log</Primitives.button>
            </div>
          </div>
        <% "primitive-icon-button-accessible-names" -> %>
          <div class="obpt-primitive-row">
            <Primitives.icon_button label="Refresh jobs" tooltip="Refresh the job list">.</Primitives.icon_button>
            <Primitives.icon_button label="Acknowledge warning" tooltip="Mark warning as reviewed" variant={:primary}>+</Primitives.icon_button>
            <Primitives.icon_button
              id="primitive-cancel-selected"
              label="Cancel selected job"
              tooltip="Cancel selected job"
              variant={:danger}
              disabled_reason="Cancel selected job - requires operator role"
            >!</Primitives.icon_button>
          </div>
        <% "primitive-link-badge-tag-status" -> %>
          <div class="obpt-primitive-row">
            <Primitives.link href="/ops/jobs/audit">View audit log</Primitives.link>
            <Primitives.badge label="executing" tone={:info} />
            <Primitives.tag label="queue: critical-mailer" tone={:neutral} />
            <Primitives.status_pill spec={%{label: "Retryable", tone: :warning, icon: :alert, sr_prefix: "Job state"}} />
            <Primitives.status_pill spec={%{label: "Completed", tone: :success, icon: :check, sr_prefix: "Job state"}} />
            <Primitives.status_pill spec={%{label: "Discarded", tone: :danger, icon: :alert, sr_prefix: "Job state"}} />
          </div>
        <% "primitive-surface-card-divider-density" -> %>
          <div class="obpt-primitive-matrix">
            <Primitives.surface variant={:inset}>
              <strong>Filter summary</strong>
              <p>State retryable, queue critical-mailer, actor all.</p>
            </Primitives.surface>
            <Primitives.card variant={:elevated}>
              <strong>Job details</strong>
              <Primitives.divider decorative={true} />
              <p>Attempt 7 of 20 remains available for operator repair.</p>
            </Primitives.card>
            <Primitives.card variant={:attention}>
              <strong>Requires review</strong>
              <p>Pause queue before replaying the customer notification backlog.</p>
            </Primitives.card>
          </div>
        <% "primitive-tooltip-open" -> %>
          <div class="obpt-primitive-row">
            <Primitives.tooltip
              id="primitive-tooltip-open"
              text="Retries the selected job once and records the operator reason."
              data-obpt-tooltip-open="true"
            >
              Retry job
            </Primitives.tooltip>
          </div>
        <% "primitive-spinner-skeleton-loading" -> %>
          <div class="obpt-primitive-matrix">
            <div class="obpt-primitive-row">
              <Primitives.spinner label="Loading job history" />
              <span>Loading job history</span>
            </div>
            <Primitives.skeleton label="Loading retryable job table" lines={3} />
          </div>
        <% "primitive-kbd-stat-values" -> %>
          <div class="obpt-primitive-matrix">
            <div class="obpt-primitive-row">
              <span>Dismiss tooltip</span>
              <Primitives.kbd text="Esc" />
            </div>
            <Primitives.stat label="Retryable jobs" value="12" trend="3 blocked" tone={:warning} />
            <Primitives.stat label="Completed jobs" value="248" trend="all queues healthy" tone={:success} />
          </div>
      <% end %>
      """
    end

    attr(:story, :map, required: true)

    defp form_story_body(assigns) do
      form =
        to_form(
          %{
            "worker" => "ObanPowertools.Workers.ReconcileAccount",
            "note" => "Reviewed during incident response.",
            "queue" => "critical-mailer",
            "enabled" => "true",
            "state" => "retryable",
            "pause" => "false",
            "job_id" => "01JZ8M5PF4Q2V6N7X8Y9Z0ABCD",
            "search" => "mailer"
          },
          as: "showcase_#{String.replace(assigns.story.id, "-", "_")}"
        )

      assign(assigns, :form, form)
      |> render_form_story()
    end

    defp render_form_story(assigns) do
      ~H"""
      <div class="obpt-primitive-matrix">
        <%= case @story.id do %>
          <% "form-input-states" -> %>
            <Forms.input field={@form[:worker]} id="form-input-required" label="Worker name" hint="Enter a full or partial worker module name." required />
            <Forms.input field={@form[:worker]} id="form-input-invalid" label="Worker name" errors={["Enter a worker name."]} />
            <Forms.input field={@form[:note]} label="Operator note (Optional)" />
          <% "form-textarea-select" -> %>
            <Forms.textarea field={@form[:note]} label="Operator note (Optional)" hint="Record context for the next operator." />
            <Forms.select field={@form[:queue]} label="Queue" options={[{"Critical mailer", "critical-mailer"}, {"Default", "default"}]} />
          <% "form-checkbox-modes" -> %>
            <Forms.checkbox field={@form[:enabled]} label="Include scheduled jobs" />
            <Forms.checkbox field={@form[:enabled]} id="form-event-selection" label="Select job 01JZ8M5P" phx-click="select_story_job" phx-value-id="01JZ8M5P" />
          <% "form-radio-group" -> %>
            <Forms.radio_group field={@form[:state]} label="Job state" hint="Choose one state or clear the filter." options={[{"Any state", ""}, {"Retryable", "retryable"}, {"Discarded", "discarded"}]} />
          <% "form-switch-states" -> %>
            <Forms.switch field={@form[:pause]} id="form-switch-off" label="Pause queue processing" hint="Changes apply immediately when owned by a parent view." />
            <Forms.switch field={@form[:enabled]} id="form-switch-pending" label="Pause queue processing" hint="Updating queue setting." disabled />
          <% "form-validation-wiring" -> %>
            <Forms.input field={@form[:worker]} label="Worker name" hint="Enter a full or partial worker module name." errors={["Enter a worker name.", "Reason must be at least 10 characters."]} aria-describedby="form-validation-context" />
            <p id="form-validation-context">Used to narrow the operational job list.</p>
          <% "form-disabled-readonly" -> %>
            <Forms.select field={@form[:queue]} label="Queue" options={[{"Critical mailer", "critical-mailer"}]} disabled hint="Queue selection is unavailable while this job is running." />
            <Forms.input field={@form[:job_id]} label="Job ID" readonly hint="Job ID is assigned when the job is inserted and cannot be changed." />
          <% "form-filter-ready" -> %>
            <Forms.input field={@form[:search]} type="search" variant={:filter} label="Search jobs" hint="Enter a full or partial worker module name." />
            <Forms.select field={@form[:state]} variant={:filter} label="Job state" options={[{"Any state", ""}, {"Retryable", "retryable"}]} />
          <% "form-long-content" -> %>
            <Forms.textarea field={@form[:note]} label="Worker module and operational context that must remain readable on a narrow viewport" value={"<script>alert('escaped')</script> ObanPowertools.Workers.ReconcileAccountNotificationDeliveryWithAnIntentionallyLongIdentifier"} hint="This value is displayed as ordinary escaped text and may wrap across several lines." />
        <% end %>
      </div>
      """
    end

    attr(:story, :map, required: true)
    attr(:confirmation_state, :atom, required: true)
    attr(:confirmation_form, :any, required: true)
    attr(:confirmation_results, :list, required: true)
    attr(:filter_states, :map, required: true)
    attr(:detail_state, :map, required: true)

    defp group_story_body(assigns) do
      assigns = assign(assigns, :category, group_story_category(assigns.story.id))

      ~H"""
      <%= case @category do %>
        <% :confirmation -> %>
          <.group_confirmation_story
            story={@story}
            state={@confirmation_state}
            form={@confirmation_form}
            results={@confirmation_results}
          />
        <% :filter -> %>
          <.group_filter_story story={@story} state={Map.fetch!(@filter_states, @story.id)} />
        <% :detail -> %>
          <.group_detail_story story={@story} state={@detail_state} />
        <% :attention -> %>
          <.group_attention_story id={@story.id} fixture={@story.fixtures} />
        <% :blocked -> %>
          <.group_blocker_story id={@story.id} fixture={@story.fixtures} />
        <% :audit -> %>
          <.group_audit_story id={@story.id} fixture={@story.fixtures} />
        <% :chain -> %>
          <.group_attention_story id={"#{@story.id}-attention"} fixture={@story.fixtures.attention} />
          <.group_blocker_story id={"#{@story.id}-blocked"} fixture={@story.fixtures.explanation} />
          <Primitives.surface variant={:inset}>
            <strong>{@story.fixtures.confirmation_summary.title}</strong>
            <p>{@story.fixtures.confirmation_summary.consequence}</p>
          </Primitives.surface>
          <.group_audit_story id={"#{@story.id}-audit"} fixture={@story.fixtures.audit} />
      <% end %>
      """
    end

    attr(:story, :map, required: true)
    attr(:state, :atom, required: true)
    attr(:form, :any, required: true)
    attr(:results, :list, required: true)

    defp group_confirmation_story(assigns) do
      fixture = assigns.story.fixtures

      assigns =
        assigns
        |> assign(:fixture, fixture)
        |> assign(:dismissible, assigns.state != :submitting)

      ~H"""
      <OperatorPatterns.confirm_action_dialog
        id={"showcase-#{@story.id}"}
        intent={@fixture.intent}
        state={@state}
        title={@fixture.title}
        object_label={@fixture.object_label}
        scope={@fixture.scope}
        consequence={@fixture.consequence}
        reversibility={@fixture.reversibility}
        support_boundary={@fixture.support_boundary}
        form={@form}
        bulk_count={@fixture.frozen_count}
        bulk_scope={@fixture.bulk_scope}
        confirm_label={@fixture.confirm_label}
        dismiss_label={@fixture.dismiss_label}
        pending_copy={@fixture.pending_copy}
        logical_fallback_id={target_value(@story.test_targets, :story)}
        submit_event="submit-group-confirmation"
        dismiss_event="close-group-detail"
        dismissible={@dismissible}
        results={@results}
      >
        <:recovery>
          <Primitives.button type="button" variant={:primary} phx-click="fresh-group-preview">
            Create new preview
          </Primitives.button>
        </:recovery>
        <:audit>
          <Primitives.link href="/ops/jobs/audit">Open audit evidence</Primitives.link>
        </:audit>
        <:support_details>Do not enter secrets in the operator reason.</:support_details>
      </OperatorPatterns.confirm_action_dialog>
      """
    end

    attr(:story, :map, required: true)
    attr(:state, :map, required: true)

    defp group_filter_story(assigns) do
      form = group_filter_form(assigns.story.id, assigns.state.draft, assigns.state.errors)

      assigns =
        assigns
        |> assign(:form, form)
        |> assign(:mode, assigns.story.fixtures.mode)

      ~H"""
      <OperatorPatterns.filter_bar
        id={"showcase-#{@story.id}"}
        form={@form}
        mode={@mode}
        result_summary={@state.result_summary}
        results_target_id={"#{@story.id}-results"}
        active_filters={@state.active_filters}
        dirty={@state.dirty?}
        filters_expanded={@story.id == "group-filter-unapplied-invalid"}
        change_event="validate-group-filters"
        submit_event="apply-group-filters"
        clear_href={@story.fixtures.clear_destination}
      >
        <:fields>
          <input type="hidden" name={@form[:story_id].name} value={@story.id} />
          <Forms.input field={@form[:queue]} label="Queue" placeholder="Any queue" />
          <Forms.input field={@form[:state]} label="State" placeholder="Any state" />
          <Forms.input
            :if={Map.has_key?(@state.draft, "worker")}
            field={@form[:worker]}
            label="Worker"
            placeholder="Any worker"
          />
        </:fields>
      </OperatorPatterns.filter_bar>
      <div
        id={"#{@story.id}-results"}
        class="obpt-showcase-placeholder"
        data-obpt-group-filter-url={@state.canonical_url}
        data-obpt-group-filter-history={encode_group_history(@state.history)}
      >
        Results remain parent-owned at {@state.canonical_url}.
      </div>
      """
    end

    attr(:story, :map, required: true)
    attr(:state, :map, required: true)

    defp group_detail_story(assigns) do
      fixture = assigns.story.fixtures
      selected_id = assigns.state.selected_id || fixture.selected_id
      body_items = detail_body_items(fixture.body)

      assigns =
        assigns
        |> assign(:fixture, fixture)
        |> assign(:selected_id, selected_id)
        |> assign(:body_items, body_items)

      ~H"""
      <OperatorPatterns.detail_surface
        id={"showcase-#{@story.id}-surface"}
        title={"Job #{@selected_id} details"}
        close_label={@fixture.close_label}
        open={true}
        variant={@fixture.variant}
        state={@state.content_state}
        resource="job details"
        logical_fallback_id={target_value(@story.test_targets, :story)}
        close_event="close-group-detail"
        loaded_announcement={@state.loaded_announcement}
        full_details_href={@fixture.full_details_destination}
      >
        <:body>
          <DataDisplay.description_list id={"#{@story.id}-detail-facts"}>
            <:item :for={{label, value} <- @body_items} label={label}>{value}</:item>
          </DataDisplay.description_list>
        </:body>
        <:actions>
          <Primitives.button
            type="button"
            variant={:neutral}
            phx-click="select-group-detail"
            phx-value-resource-id="01JZ8M5P999999999999999998"
          >
            Select next job
          </Primitives.button>
          <Primitives.button
            type="button"
            variant={:primary}
            phx-click="activate-group-story"
            phx-value-id="group-confirm-single-reversible"
          >
            Preview retry
          </Primitives.button>
        </:actions>
        <:evidence>
          <DataDisplay.code_block
            id={"#{@story.id}-detail-evidence"}
            label="Redaction-safe evidence"
            content="Only normalized presentation evidence is available."
          />
        </:evidence>
      </OperatorPatterns.detail_surface>
      <span
        class="obpt-sr-only"
        data-obpt-group-detail-url={@state.canonical_url}
        data-obpt-group-detail-history={encode_group_history(@state.history)}
      >
        Parent-owned detail history
      </span>
      """
    end

    attr(:id, :string, required: true)
    attr(:fixture, :map, required: true)

    defp group_attention_story(assigns) do
      assigns = assign(assigns, :entries, group_attention_entries(assigns.id, assigns.fixture))

      ~H"""
      <div class="obpt-primitive-matrix">
        <OperatorPatterns.attention_card
          :for={entry <- @entries}
          id={"showcase-#{entry.id}"}
          title={entry.fixture.title}
          summary={entry.fixture.summary}
          impact={entry.fixture.impact}
          observed_at={entry.fixture.observed_at}
          observed_datetime={entry.fixture.observed_datetime}
          domain={entry.fixture.domain}
          status={entry.fixture.status}
          severity={entry.fixture.severity}
          completeness={entry.fixture.completeness}
        >
          <:primary_action>
            <Primitives.button
              type="button"
              variant={:primary}
              disabled_reason={Map.get(entry.fixture, :primary_action_disabled_reason)}
            >
              {entry.fixture.primary_action}
            </Primitives.button>
          </:primary_action>
          <:secondary_actions>
            <Primitives.link
              :for={action <- entry.fixture.secondary_actions}
              href="/ops/jobs/audit"
            >
              {action}
            </Primitives.link>
          </:secondary_actions>
        </OperatorPatterns.attention_card>
      </div>
      """
    end

    attr(:id, :string, required: true)
    attr(:fixture, :map, required: true)

    defp group_blocker_story(assigns) do
      ~H"""
      <OperatorPatterns.why_blocked
        id={"showcase-#{@id}"}
        title={@fixture.title}
        summary={@fixture.summary}
        impact={@fixture.impact}
        observed_at={@fixture.observed_at}
        observed_datetime={@fixture.observed_datetime}
        evidence_state={@fixture.evidence_state}
        completeness={@fixture.completeness}
        blockers={@fixture.blockers}
      >
        <:next_action>
          <Primitives.button type="button" variant={:primary}>{@fixture.next_action}</Primitives.button>
        </:next_action>
        <:evidence :if={Map.has_key?(@fixture, :evidence)}>
          <DataDisplay.code_block
            id={"#{@id}-blocker-evidence"}
            label="Current and snapshot evidence"
            content={inspect(@fixture.evidence, pretty: false)}
          />
        </:evidence>
      </OperatorPatterns.why_blocked>
      """
    end

    attr(:id, :string, required: true)
    attr(:fixture, :map, required: true)

    defp group_audit_story(assigns) do
      assigns = assign(assigns, :entries, group_audit_entries(assigns.fixture))

      ~H"""
      <div class="obpt-primitive-matrix">
        <OperatorPatterns.audit_entry
          :for={{entry, index} <- Enum.with_index(@entries, 1)}
          id={"showcase-#{@id}-#{index}"}
          entry={entry}
        />
      </div>
      """
    end

    defp group_story_category("group-confirm-" <> _rest), do: :confirmation
    defp group_story_category("group-filter-" <> _rest), do: :filter
    defp group_story_category("group-detail-" <> _rest), do: :detail
    defp group_story_category("group-attention-" <> _rest), do: :attention
    defp group_story_category("group-why-blocked-" <> _rest), do: :blocked
    defp group_story_category("group-audit-entry-" <> _rest), do: :audit
    defp group_story_category("group-explain-audit-" <> _rest), do: :chain

    defp confirmation_story?("group-confirm-" <> _rest), do: true
    defp confirmation_story?(_id), do: false

    defp detail_story?("group-detail-" <> _rest), do: true
    defp detail_story?(_id), do: false

    defp active_group_story(socket) do
      Enum.find(socket.assigns.group_stories, &(&1.id == socket.assigns.active_group_overlay))
    end

    defp activate_group_story(socket, id) do
      case Enum.find(socket.assigns.group_stories, &(&1.id == id and &1.activation == :overlay)) do
        nil ->
          socket

        %{fixtures: fixture} = story ->
          socket =
            socket
            |> assign(:active_group_overlay, story.id)
            |> assign(:group_receipt, nil)

          cond do
            confirmation_story?(story.id) -> reset_group_confirmation(socket, story)
            detail_story?(story.id) -> reset_group_detail(socket, story, fixture)
          end
      end
    end

    defp reset_group_confirmation(socket, story) do
      fixture = story.fixtures

      params = %{
        "reason" => fixture.reason || "",
        "confirmation_count" => fixture.entered_count || ""
      }

      socket
      |> assign(:group_confirmation_story_id, story.id)
      |> assign(:group_confirmation_state, fixture.lifecycle)
      |> assign(:group_confirmation_form, group_confirmation_form(params))
      |> assign(:group_confirmation_errors, %{})
      |> assign(:group_confirmation_results, fixture.results)
      |> assign(:group_confirmation_mutation_count, 0)
      |> assign(:group_confirmation_receipt_count, 0)
      |> assign(:group_detail_state, initial_group_detail_state())
    end

    defp reset_group_detail(socket, story, fixture) do
      resource_id = fixture.selected_id
      url = "/ops/jobs/_showcase?detail=#{URI.encode_www_form(resource_id)}"

      socket
      |> assign(:group_confirmation_story_id, nil)
      |> assign(:group_detail_state, %{
        story_id: story.id,
        selected_id: resource_id,
        content_state: fixture.content_state,
        canonical_url: url,
        history: [{:push, url}],
        loaded_announcement: fixture.loaded_announcement
      })
    end

    defp validate_group_confirmation(params, frozen_count) do
      reason = params |> Map.get("reason", "") |> String.trim()
      count = params |> Map.get("confirmation_count", "") |> String.trim()
      normalized = %{"reason" => reason, "confirmation_count" => count}

      errors =
        %{}
        |> maybe_group_error(:reason, reason == "", "Reason is required.")
        |> maybe_group_error(
          :reason,
          reason != "" and String.length(reason) < 8,
          "Reason must be at least 8 characters."
        )
        |> maybe_group_error(
          :confirmation_count,
          is_integer(frozen_count) and count != Integer.to_string(frozen_count),
          "Type #{frozen_count} to confirm."
        )

      {group_confirmation_form(normalized, errors), errors}
    end

    defp group_confirmation_form(
           params \\ %{"reason" => "", "confirmation_count" => ""},
           errors \\ %{}
         ) do
      to_form(params,
        as: :group_confirmation,
        id: "group-confirmation-form",
        errors: group_form_errors(errors)
      )
    end

    defp group_confirmation_receipt(%{frozen_count: count, confirm_label: label}) do
      count = count || 1

      action =
        if String.starts_with?(label, "Discard"), do: "Discard requested", else: "Retry requested"

      "#{action} for #{count} #{if(count == 1, do: "job", else: "jobs")}. Audit evidence recorded."
    end

    defp initial_group_filter_states(stories) do
      stories
      |> Enum.filter(&String.starts_with?(&1.id, "group-filter-"))
      |> Map.new(fn story -> {story.id, group_filter_state(story)} end)
    end

    defp group_filter_state(story) do
      draft = stringify_group_filter_values(story.fixtures.draft)
      applied = stringify_group_filter_values(story.fixtures.applied)

      %{
        draft: Map.put(draft, "story_id", story.id),
        applied: applied,
        errors: normalize_group_filter_errors(story.fixtures.errors),
        dirty?: story.fixtures.dirty,
        active_filters: ensure_group_filter_labels(story.fixtures.active_filters),
        result_summary: story.fixtures.result_summary,
        canonical_url: group_filter_url(applied),
        history: []
      }
    end

    defp update_group_filter_state(socket, params, operation) do
      id = Map.get(params, "story_id")

      with %{fixtures: fixture} <- Enum.find(socket.assigns.group_stories, &(&1.id == id)),
           %{^id => state} <- socket.assigns.group_filter_states do
        draft = Map.take(params, ["queue", "state", "worker"]) |> Map.put("story_id", id)
        errors = validate_group_filters(draft)
        apply? = errors == %{} and (operation == :apply or fixture.mode == :instant)

        next_state =
          if apply? do
            applied = Map.drop(draft, ["story_id"])
            url = group_filter_url(applied)
            history_operation = if fixture.mode == :instant, do: :replace, else: :push

            %{
              state
              | draft: draft,
                applied: applied,
                errors: %{},
                dirty?: false,
                active_filters: group_active_filters(applied),
                result_summary: group_filter_result_summary(applied),
                canonical_url: url,
                history: state.history ++ [{history_operation, url}]
            }
          else
            %{
              state
              | draft: draft,
                errors: errors,
                dirty?: Map.drop(draft, ["story_id"]) != state.applied
            }
          end

        assign(
          socket,
          :group_filter_states,
          Map.put(socket.assigns.group_filter_states, id, next_state)
        )
      else
        _ -> socket
      end
    end

    defp remove_group_filter(socket, id, field) when field in ["queue", "state", "worker"] do
      case Map.fetch(socket.assigns.group_filter_states, id) do
        {:ok, state} ->
          applied = Map.put(state.applied, field, "")
          url = group_filter_url(applied)

          next_state = %{
            state
            | draft: Map.put(applied, "story_id", id),
              applied: applied,
              errors: %{},
              dirty?: false,
              active_filters: group_active_filters(applied),
              result_summary: group_filter_result_summary(applied),
              canonical_url: url,
              history: state.history ++ [{:push, url}]
          }

          assign(
            socket,
            :group_filter_states,
            Map.put(socket.assigns.group_filter_states, id, next_state)
          )

        :error ->
          socket
      end
    end

    defp remove_group_filter(socket, _id, _field), do: socket

    defp clear_group_filters(socket, id) do
      case Map.fetch(socket.assigns.group_filter_states, id) do
        {:ok, state} ->
          applied = Map.new(state.applied, fn {field, _value} -> {field, ""} end)
          url = group_filter_url(applied)

          next_state = %{
            state
            | draft: Map.put(applied, "story_id", id),
              applied: applied,
              errors: %{},
              dirty?: false,
              active_filters: [],
              result_summary: group_filter_result_summary(applied),
              canonical_url: url,
              history: state.history ++ [{:push, url}]
          }

          assign(
            socket,
            :group_filter_states,
            Map.put(socket.assigns.group_filter_states, id, next_state)
          )

        :error ->
          socket
      end
    end

    defp group_filter_form(id, draft, errors) do
      to_form(draft,
        as: :group_filters,
        id: "showcase-#{id}-form",
        errors: group_form_errors(errors)
      )
    end

    defp validate_group_filters(params) do
      queue = Map.get(params, "queue", "")
      state = Map.get(params, "state", "")

      %{}
      |> maybe_group_error(
        :queue,
        queue not in ["", "all", "critical-mailer", "default"],
        "Choose a known queue."
      )
      |> maybe_group_error(
        :state,
        state not in ["", "all", "available", "retryable"],
        "Choose a known job state."
      )
    end

    defp maybe_group_error(errors, _field, false, _message), do: errors

    defp maybe_group_error(errors, field, true, message),
      do: Map.update(errors, field, [message], &(&1 ++ [message]))

    defp group_form_errors(errors) do
      Enum.flat_map(errors, fn {field, messages} ->
        Enum.map(List.wrap(messages), &{field, {&1, []}})
      end)
    end

    defp stringify_group_filter_values(values) do
      Map.new(values, fn {key, value} -> {to_string(key), to_string(value)} end)
    end

    defp normalize_group_filter_errors(errors) do
      Map.new(errors, fn {key, message} -> {key, List.wrap(message)} end)
    end

    defp ensure_group_filter_labels(filters) do
      Enum.map(filters, fn filter ->
        Map.put_new(
          filter,
          :remove_label,
          "Remove #{filter.label}: #{filter.value} filter"
        )
      end)
    end

    defp group_active_filters(applied) do
      applied
      |> Enum.reject(fn {_field, value} -> value in ["", "all"] end)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {field, value} ->
        label = String.capitalize(field)

        %{
          id: "#{field}-#{value}",
          label: label,
          value: value,
          remove_href: group_filter_url(Map.put(applied, field, "")),
          remove_label: "Remove #{label}: #{value} filter"
        }
      end)
    end

    defp group_filter_url(applied) do
      query =
        applied
        |> Enum.reject(fn {_field, value} -> value in ["", "all"] end)
        |> Enum.sort_by(&elem(&1, 0))
        |> URI.encode_query()

      if query == "", do: "/ops/jobs/_showcase", else: "/ops/jobs/_showcase?#{query}"
    end

    defp group_filter_result_summary(applied) do
      if Enum.any?(applied, fn {_field, value} -> value not in ["", "all"] end) do
        "42 jobs match the applied filters."
      else
        "248 jobs match the applied filters."
      end
    end

    defp initial_group_detail_state do
      %{
        story_id: nil,
        selected_id: nil,
        content_state: :ready,
        canonical_url: "/ops/jobs/_showcase",
        history: [],
        loaded_announcement: nil
      }
    end

    defp detail_body_items(body) do
      body
      |> Enum.reject(fn {_key, value} -> is_list(value) or is_map(value) end)
      |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
      |> Enum.map(fn {key, value} ->
        label = key |> to_string() |> String.replace("_", " ") |> String.capitalize()
        {label, to_string(value)}
      end)
    end

    defp group_attention_entries(id, %{matrix: matrix} = fixture) when is_list(matrix) do
      base = Map.delete(fixture, :matrix)

      matrix
      |> Enum.with_index(1)
      |> Enum.map(fn {entry, index} ->
        %{id: "#{id}-#{index}", fixture: Map.merge(base, entry)}
      end)
    end

    defp group_attention_entries(id, fixture), do: [%{id: id, fixture: fixture}]

    defp group_audit_entries(%{matrix: matrix} = fixture) when is_list(matrix) do
      base = Map.delete(fixture, :matrix)
      Enum.map(matrix, &Map.merge(base, &1))
    end

    defp group_audit_entries(fixture), do: [fixture]

    defp encode_group_history(history) do
      Enum.map_join(history, "|", fn {operation, url} -> "#{operation}:#{url}" end)
    end
  end
end
