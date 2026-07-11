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

    alias ObanPowertools.Web.Components.Primitives

    @catalog_module ObanPowertools.ShowcaseCatalog
    @catalog_path Path.expand("../../../../test/support/showcase_catalog.ex", __DIR__)
    @primitive_catalog_module ObanPowertools.PrimitiveStoryCatalog
    @primitive_catalog_path Path.expand(
                              "../../../../test/support/primitive_story_catalog.ex",
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

      {:ok,
       socket
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
       |> assign(:primitive_stories, primitive_catalog.stories)}
    end

    @impl Phoenix.LiveView
    def handle_event("select_viewport", %{"viewport" => viewport}, socket) do
      if viewport in Enum.map(@viewport_choices, & &1.value) do
        {:noreply, assign(socket, :selected_viewport, viewport)}
      else
        {:noreply, socket}
      end
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
                <div class="obpt-showcase-fixture-index-head" role="row">
                  <span>Scenario</span>
                  <span>Domain</span>
                  <span>Persona</span>
                  <span>States</span>
                </div>
                <div
                  :for={scenario <- @catalog_scenarios}
                  class="obpt-showcase-fixture-index-row"
                  role="row"
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

    defp ensure_catalog_module do
      ensure_support_module(@catalog_module, @catalog_path)
    end

    defp ensure_primitive_catalog_module do
      ensure_support_module(@primitive_catalog_module, @primitive_catalog_path)
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
  end
end
