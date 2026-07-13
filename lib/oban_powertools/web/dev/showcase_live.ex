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

    alias ObanPowertools.Web.Components.{AppShell, DataDisplay, Forms, Primitives}

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
       |> assign(:data_sort_direction, :asc)}
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
           true <- function_exported?(module, :stories, 0) do
        %{available?: true, stories: apply(module, :stories, [])}
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

    defp ensure_support_module(module, path) do
      cond do
        Code.ensure_loaded?(module) ->
          {:ok, module}

        Mix.env() != :test and File.exists?(path) ->
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

    defp toggle_sort_direction(:asc), do: :desc
    defp toggle_sort_direction(_direction), do: :asc

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
            <DataDisplay.progress_bar id="data-progress-unavailable" label="Remote progress" state={:unavailable} />
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
        stories
        |> Enum.find(&(&1.id == "data-empty-toast-flash"))
        |> then(&get_in(&1, [:fixtures, :flash]))

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
  end
end
