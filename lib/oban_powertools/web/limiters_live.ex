if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.LimitersLive do
    @moduledoc false

    use Phoenix.LiveView

    import Ecto.Query

    alias ObanPowertools.{ControlPlane, Explain}
    alias ObanPowertools.Forensics.LimiterHistory
    alias ObanPowertools.Limits.{Resource, State}

    alias ObanPowertools.Web.{
      ControlPlanePresenter,
      LiveAuth,
      Selectors
    }

    alias ObanPowertools.Web.Components.{DataDisplay, OperatorPatterns, Primitives}

    @current_blocker_limit 8

    @impl true
    def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(
               socket,
               :view_limiters,
               %{type: :page, id: "limiters"}
             ) do
        {:ok,
         socket
         |> assign(:oban_dashboard_path, dashboard_path)
         |> assign(:resources, [])
         |> assign(:resource_rows, [])
         |> assign(:resource_index, %{})
         |> assign(:resource_scan_loaded?, false)
         |> assign(:selected_resource, nil)
         |> assign(:detail_open?, false)
         |> assign(:detail_state, :empty)
         |> assign(:detail, nil)
         |> assign(:detail_presentation, nil)
         |> assign(:history_summary, nil)
         |> assign(:read_only?, true)
         |> assign(:error_message, nil)}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_params(params, _uri, socket) do
      {:noreply,
       socket
       |> load_resources()
       |> load_selection(Map.get(params, "resource"))}
    end

    @impl true
    def handle_event("inspect", %{"resource" => name}, socket) do
      replace? = not is_nil(socket.assigns.selected_resource)

      {:noreply,
       push_patch(socket,
         to: Selectors.limiter_path(resource: name),
         replace: replace?
       )}
    end

    @impl true
    def handle_event("close_detail", _params, socket) do
      {:noreply, push_patch(socket, to: Selectors.limiter_path([]), replace: true)}
    end

    @impl true
    def render(assigns), do: page_content(assigns)

    attr(:resource_rows, :list, default: [])
    attr(:selected_resource, :string, default: nil)
    attr(:detail_open?, :boolean, default: false)
    attr(:detail_state, :atom, default: :empty)
    attr(:detail_presentation, :map, default: nil)
    attr(:read_only?, :boolean, default: true)
    attr(:error_message, :string, default: nil)

    def page_content(assigns) do
      ~H"""
      <section id="limiters-page" class="obpt-limiters-page" aria-labelledby="limiters-page-title">
        <header class="obpt-limiters-page__header">
          <h1 id="limiters-page-title">Limiters</h1>
          <p>
            Review limiter state, understand what blocks progress now, and follow the right evidence path.
          </p>
        </header>

        <Primitives.surface :if={@read_only?} variant={:inset}>
          <p>
            Limiters is read-only. Powertools-native evidence explains current capacity; changes remain host-owned.
          </p>
        </Primitives.surface>

        <DataDisplay.state_message
          :if={@error_message}
          id="limiters-page-error"
          state={:error}
          resource="limiter state"
        >
          <p>{@error_message}</p>
        </DataDisplay.state_message>

        <DataDisplay.empty_state
          :if={@resource_rows == [] && !@error_message}
          id="limiters-empty"
          heading="No limiters configured"
          body="This host has no limiter resources to review. Open Jobs to review current work."
        />

        <DataDisplay.data_table
          :if={@resource_rows != []}
          id="limiters-table"
          caption="Limiters"
          rows={@resource_rows}
          row_id={& &1.id}
          state={:ready}
          resource="limiters"
          row_count={length(@resource_rows)}
        >
          <:col :let={row} label="Limiter">
            <span>{row.name}</span>
          </:col>
          <:col :let={row} label="Scope">
            <span>{row.scope}</span>
          </:col>
          <:col :let={row} label="State">
            <DataDisplay.status_pill domain={:limiter} state={row.state} />
          </:col>
          <:action :let={row}>
            <.link
              id={"limiter-#{row.id}"}
              patch={Selectors.limiter_path(resource: row.name)}
              replace={not is_nil(@selected_resource)}
              class="obpt-link"
              aria-label={"Review blockers for #{row.name}"}
              aria-expanded={to_string(@selected_resource == row.name)}
              aria-controls="limiter-detail"
            >
              Review blockers
            </.link>
          </:action>
        </DataDisplay.data_table>

        <OperatorPatterns.detail_surface
          :if={@detail_open?}
          id="limiter-detail"
          title={detail_title(@selected_resource)}
          close_label="Close limiter details"
          open={true}
          variant={:adaptive}
          state={@detail_state}
          resource="limiter details"
          logical_fallback_id={detail_fallback_id(@selected_resource, @detail_presentation)}
          close_event="close_detail"
          loaded_announcement={detail_loaded_announcement(@detail_presentation)}
        >
          <:body :if={@detail_presentation}>
            <DataDisplay.description_list id="limiter-current-state">
              <:item label="Limiter">{@detail_presentation.resource.name}</:item>
              <:item label="Current state">
                <DataDisplay.status_pill
                  domain={:limiter}
                  state={@detail_presentation.resource.state}
                />
              </:item>
              <:item label="Scope">{@detail_presentation.resource.scope}</:item>
              <:item label="Support">{ControlPlanePresenter.native_banner()}</:item>
            </DataDisplay.description_list>

            <OperatorPatterns.why_blocked
              id="limiter-current-blockers"
              title="Current blockers"
              summary={@detail_presentation.current.summary}
              impact={@detail_presentation.current.impact}
              observed_at={@detail_presentation.current.observed_at}
              observed_datetime={@detail_presentation.current.observed_datetime}
              evidence_state={@detail_presentation.current.evidence_state}
              completeness={@detail_presentation.current.completeness}
              blockers={@detail_presentation.current.blockers}
            />

            <section
              id="limiter-block-start-snapshot"
              aria-labelledby="limiter-block-start-snapshot-title"
            >
              <h2 id="limiter-block-start-snapshot-title">Snapshot at block start</h2>
              <%= if @detail_presentation.snapshot do %>
                <p>
                  Historical evidence captured
                  <time datetime={@detail_presentation.snapshot.captured_datetime}>
                    {@detail_presentation.snapshot.captured_at}
                  </time>.
                </p>
                <ul :if={@detail_presentation.snapshot.facts != []}>
                  <li :for={fact <- @detail_presentation.snapshot.facts}>
                    <strong>{fact.label}</strong>: {fact.summary}
                    <span :if={fact.affected_scope}> Affected scope: {fact.affected_scope}.</span>
                  </li>
                </ul>
                <p :if={@detail_presentation.snapshot.facts == []}>
                  The snapshot recorded no block-start conditions. It does not establish current state.
                </p>
                <p>
                  Snapshot completeness:
                  <strong>{@detail_presentation.snapshot.completeness}</strong>
                </p>
              <% else %>
                <p>
                  No block-start snapshot is available. Current state and retained history remain separate evidence.
                </p>
              <% end %>
            </section>

            <section
              id="limiter-retained-history"
              aria-labelledby="limiter-retained-history-title"
            >
              <h2 id="limiter-retained-history-title">Retained history</h2>
              <p>{@detail_presentation.history.detail}</p>
              <p>
                History completeness:
                <strong>{@detail_presentation.history.completeness}</strong>
              </p>
              <ol :if={@detail_presentation.history.episodes != []}>
                <li :for={episode <- @detail_presentation.history.episodes}>
                  <strong>{episode.label}</strong>
                  <span :if={episode.occurred_at}> — {episode.occurred_at}</span>
                </li>
              </ol>
            </section>

            <section id="limiter-destinations" aria-labelledby="limiter-destinations-title">
              <h2 id="limiter-destinations-title">Destinations</h2>
              <h3>Open runbook entry</h3>
              <p>
                Use current evidence first. Snapshot and retained history provide continuity, not a causal claim.
              </p>
              <p>
                Caution: partial evidence and history unavailable states stay diagnostic until retained limiter evidence proves what happened.
              </p>
              <ol>
                <li>
                  Return to limiter diagnosis —
                  <span
                    data-runbook-ownership="Powertools-native"
                    data-runbook-variant={follow_up_variant("Powertools-native")}
                  >
                    Powertools-native
                  </span>
                </li>
                <li>
                  Inspect generic job state —
                  <span
                    data-runbook-ownership="Oban Web bridge"
                    data-runbook-variant={follow_up_variant("Oban Web bridge")}
                  >
                    Oban Web bridge
                  </span>
                </li>
                <li>
                  Coordinate capacity policy follow-up —
                  <span
                    data-runbook-ownership="host-owned follow-up"
                    data-runbook-variant={follow_up_variant("host-owned follow-up")}
                  >
                    host-owned follow-up
                  </span>
                </li>
              </ol>
              <nav
                class="obpt-page__actions"
                aria-label="Limiter evidence destinations"
              >
                <Primitives.link
                  :if={@detail_presentation.destinations.forensics_path}
                  href={@detail_presentation.destinations.forensics_path}
                >
                  Open forensic timeline
                </Primitives.link>
                <Primitives.link
                  :if={@detail_presentation.destinations.oban_job_path}
                  href={@detail_presentation.destinations.oban_job_path}
                >
                  Open in Oban Web
                </Primitives.link>
              </nav>
            </section>
          </:body>
          <:evidence :if={@detail_state == :unavailable}>
            <p>
              The selected limiter is unavailable in the current scope. Close these details, then review another limiter.
            </p>
          </:evidence>
        </OperatorPatterns.detail_surface>
      </section>
      """
    end

    defp load_resources(%{assigns: %{resource_scan_loaded?: true}} = socket), do: socket

    defp load_resources(socket) do
      now = DateTime.utc_now()
      resources = repo().all(from(resource in Resource, order_by: [asc: resource.name]))

      states =
        repo().all(
          from(state in State, order_by: [asc: state.resource_id, asc: state.partition_key])
        )

      states_by_resource = Enum.group_by(states, & &1.resource_id)

      resource_entries =
        Enum.map(resources, fn resource ->
          resource_states = Map.get(states_by_resource, resource.id, [])
          resource_data = resource_data(resource, resource_states, now)
          {resource_data.name, %{resource: resource_data, states: resource_states}}
        end)

      resource_index = Map.new(resource_entries)
      normalized_resources = Enum.map(resource_entries, fn {_name, entry} -> entry.resource end)

      resource_rows =
        Enum.map(normalized_resources, fn resource ->
          %{
            id: safe_id(resource.name),
            name: resource.name,
            scope: resource.scope_kind,
            state: resource.state
          }
        end)

      socket
      |> assign(:resources, normalized_resources)
      |> assign(:resource_rows, resource_rows)
      |> assign(:resource_index, resource_index)
      |> assign(:resource_scan_loaded?, true)
      |> assign(:scan_observed_at, now)
      |> assign(:read_only?, true)
      |> assign(:error_message, nil)
    end

    defp resource_data(resource, states, now) do
      cooling_down? = Enum.any?(states, &cooling_down?(&1, now))
      saturated? = Enum.any?(states, &(&1.tokens_used >= resource.bucket_capacity))

      status_resource = %{
        cooling_down?: cooling_down?,
        saturation_label:
          if(saturated?,
            do: ControlPlanePresenter.status_label(:blocked),
            else: ControlPlanePresenter.status_label(:runnable)
          )
      }

      %{
        id: resource.id,
        name: resource.name,
        scope_kind: resource.scope_kind,
        bucket_span_ms: resource.bucket_span_ms,
        bucket_capacity: resource.bucket_capacity,
        state:
          if(states == [],
            do: :unavailable,
            else: ControlPlane.limiter_status(status_resource)
          )
      }
    end

    defp load_selection(socket, nil) do
      socket
      |> assign(:selected_resource, nil)
      |> assign(:detail_open?, false)
      |> assign(:detail_state, :empty)
      |> assign(:detail, nil)
      |> assign(:detail_presentation, nil)
      |> assign(:history_summary, nil)
    end

    defp load_selection(socket, name) do
      case Map.get(socket.assigns.resource_index, name) do
        nil ->
          socket
          |> assign(:selected_resource, nil)
          |> assign(:detail_open?, true)
          |> assign(:detail_state, :unavailable)
          |> assign(:detail, nil)
          |> assign(:detail_presentation, nil)
          |> assign(:history_summary, nil)

        %{resource: resource, states: states} ->
          history_summary = LimiterHistory.summary(repo(), resource.name)

          detail_presentation =
            load_detail(
              resource,
              states,
              history_summary,
              socket.assigns.oban_dashboard_path,
              socket.assigns.current_actor,
              socket.assigns.scan_observed_at
            )

          socket
          |> assign(:selected_resource, resource.name)
          |> assign(:detail_open?, true)
          |> assign(:detail_state, :ready)
          |> assign(:detail, detail_presentation)
          |> assign(:detail_presentation, detail_presentation)
          |> assign(:history_summary, history_summary)
      end
    end

    defp load_detail(resource, states, history_summary, dashboard_path, actor, now) do
      snapshot =
        repo().one(
          from(event in Explain,
            where: event.scope_id == ^resource.name,
            order_by: [desc: event.captured_at],
            limit: 1
          )
        )

      current = current_evidence(resource, states, now)

      %{
        resource: %{
          name: resource.name,
          scope: resource.scope_kind,
          state: resource.state,
          support: ControlPlanePresenter.ownership_badge(:powertools_native)
        },
        current: current,
        snapshot: present_snapshot(snapshot),
        history: present_history(history_summary, resource.name, current.completeness),
        destinations: %{
          forensics_path: authorized_forensics_path(actor, resource.name),
          oban_job_path: snapshot_job_path(snapshot, dashboard_path)
        }
      }
    end

    defp current_evidence(resource, states, now) do
      blocker_specs = Enum.flat_map(states, &current_blocker_specs(&1, resource, now))
      truncated? = length(blocker_specs) > @current_blocker_limit

      blockers =
        blocker_specs
        |> Enum.take(@current_blocker_limit)
        |> Enum.with_index(1)
        |> Enum.map(fn {spec, index} ->
          spec
          |> Map.put(:id, "current-#{index}")
          |> Map.put(:evidence_kind, :current)
          |> ControlPlanePresenter.present_limiter_blocker()
        end)

      {evidence_state, completeness} =
        cond do
          states == [] -> {:unavailable, :unavailable}
          truncated? -> {:current, :partial}
          true -> {:current, :complete}
        end

      %{
        evidence_state: evidence_state,
        completeness: completeness,
        blockers: blockers,
        summary: current_summary(evidence_state, completeness, blockers),
        impact: current_impact(evidence_state, blockers),
        observed_at: format_dt(now),
        observed_datetime: DateTime.to_iso8601(now)
      }
    end

    defp current_blocker_specs(state, resource, now) do
      cond do
        cooling_down?(state, now) ->
          [
            %{
              label: "Cooldown active",
              summary: "This limiter cannot accept work while its cooldown is active.",
              affected_scope: affected_scope(resource, state.partition_key),
              clearing_condition: cooldown_clearing_condition(state.cooldown_until),
              evidence_source: "Current limiter state"
            }
          ]

        state.tokens_used >= resource.bucket_capacity ->
          [
            %{
              label: "Capacity reached",
              summary: "The limiter has reserved its current bucket capacity.",
              affected_scope: affected_scope(resource, state.partition_key),
              clearing_condition: capacity_clearing_condition(resource, state),
              evidence_source: "Current limiter state"
            }
          ]

        true ->
          []
      end
    end

    defp current_summary(:unavailable, _completeness, _blockers),
      do: "Current blocker evidence is unavailable."

    defp current_summary(:current, :partial, blockers),
      do: "#{length(blockers)} current limiter conditions are shown from partial evidence."

    defp current_summary(:current, :complete, []),
      do: "Current limiter state is ready for work."

    defp current_summary(:current, :complete, blockers),
      do: "#{length(blockers)} current limiter conditions affect new reservations."

    defp current_impact(:unavailable, _blockers),
      do: "Powertools cannot determine current limiter availability from the available state."

    defp current_impact(:current, []),
      do: "No current limiter condition prevents new reservations."

    defp current_impact(:current, _blockers),
      do: "New reservations remain limited until the current condition clears."

    defp present_snapshot(nil), do: nil

    defp present_snapshot(snapshot) do
      raw_facts = snapshot_live_now(snapshot)
      scope = snapshot_scope(snapshot)

      facts =
        raw_facts
        |> Enum.take(@current_blocker_limit)
        |> Enum.map(fn fact ->
          kind = finite_blocker_kind(map_value(fact, "code"))

          %{
            label: blocker_label(kind),
            summary: snapshot_summary(kind),
            affected_scope: scope
          }
        end)

      %{
        captured_at: format_dt(snapshot.captured_at),
        captured_datetime: DateTime.to_iso8601(snapshot.captured_at),
        completeness:
          if(length(raw_facts) > @current_blocker_limit, do: "partial", else: "complete"),
        facts: facts
      }
    end

    defp present_history(summary, resource_name, current_completeness) do
      %{
        detail: safe_history_detail(summary.detail, resource_name, current_completeness),
        completeness:
          ControlPlanePresenter.forensic_completeness_label(summary.completeness.state),
        episodes:
          summary.episodes
          |> Enum.take(8)
          |> Enum.map(fn episode ->
            %{
              label: history_label(episode.event_type),
              occurred_at: format_dt(episode.occurred_at)
            }
          end)
      }
    end

    defp safe_history_detail(detail, _resource_name, :complete), do: detail

    defp safe_history_detail(_detail, resource_name, _current_completeness),
      do: "Retained limiter history does not establish current availability for #{resource_name}."

    defp snapshot_live_now(%{details: details}) when is_map(details) do
      case Map.get(details, "live_now") do
        facts when is_list(facts) -> Enum.filter(facts, &(is_map(&1) and not is_struct(&1)))
        _other -> []
      end
    end

    defp snapshot_live_now(_snapshot), do: []

    defp snapshot_scope(%{details: details}) when is_map(details) do
      case Map.get(details, "partition_key") do
        value when is_binary(value) and value != "" -> value
        _other -> nil
      end
    end

    defp snapshot_scope(_snapshot), do: nil

    defp finite_blocker_kind("cooldown"), do: :cooldown
    defp finite_blocker_kind("limit_reached"), do: :capacity
    defp finite_blocker_kind(_code), do: :recorded_condition

    defp blocker_label(:cooldown), do: "Cooldown active"
    defp blocker_label(:capacity), do: "Capacity reached"
    defp blocker_label(:recorded_condition), do: "Limiter condition recorded"

    defp snapshot_summary(:cooldown),
      do: "The limiter was in cooldown when this snapshot was captured."

    defp snapshot_summary(:capacity),
      do: "The limiter bucket was saturated when this snapshot was captured."

    defp snapshot_summary(:recorded_condition),
      do: "A limiter condition was recorded when this snapshot was captured."

    defp history_label("limiter.blocked"), do: "Limiter blocked"
    defp history_label("limiter.cooled_down"), do: "Limiter cooled down"
    defp history_label("limiter.reconfigured"), do: "Limiter reconfigured"
    defp history_label("limiter.released"), do: "Limiter released"
    defp history_label(_event_type), do: "Limiter history recorded"

    defp affected_scope(resource, "__global__"), do: "#{resource.scope_kind} (global)"
    defp affected_scope(_resource, partition_key), do: partition_key

    defp cooldown_clearing_condition(%DateTime{} = cooldown_until),
      do: "Clears when the cooldown ends at #{format_dt(cooldown_until)}."

    defp cooldown_clearing_condition(_cooldown_until),
      do: "Clears when the current cooldown ends."

    defp capacity_clearing_condition(resource, %{bucket_started_at: %DateTime{} = started_at}) do
      eligible_at = DateTime.add(started_at, resource.bucket_span_ms, :millisecond)
      "Clears when the active bucket refreshes at #{format_dt(eligible_at)}."
    end

    defp capacity_clearing_condition(_resource, _state),
      do: "Clears when reservations leave the active bucket."

    defp cooling_down?(state, now) do
      match?(%DateTime{}, state.cooldown_until) and
        DateTime.compare(state.cooldown_until, now) == :gt
    end

    defp authorized_forensics_path(actor, resource_name) do
      if LiveAuth.authorized?(actor, :view_forensics, %{type: :page, id: "forensics"}) do
        Selectors.forensic_path(resource_type: "limiter", resource_id: resource_name)
      end
    end

    defp snapshot_job_path(%{job_id: job_id}, dashboard_path) when is_integer(job_id),
      do: Path.join([dashboard_path, "jobs", Integer.to_string(job_id)])

    defp snapshot_job_path(_snapshot, _dashboard_path), do: nil

    defp detail_title(nil), do: "Limiter unavailable"
    defp detail_title(resource_name), do: resource_name

    defp detail_fallback_id(nil, _detail), do: "limiters-page-title"

    defp detail_fallback_id(resource_name, _detail),
      do: "limiter-#{safe_id(resource_name)}"

    defp detail_loaded_announcement(nil), do: nil

    defp detail_loaded_announcement(%{resource: %{name: name}}),
      do: "Limiter #{name} details loaded"

    defp safe_id(value), do: Base.url_encode64(value, padding: false)

    defp map_value(map, key) do
      Map.get(map, key) ||
        case existing_atom(key) do
          nil -> nil
          atom -> Map.get(map, atom)
        end
    end

    defp existing_atom(key) do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> nil
    end

    defp follow_up_variant(path_or_venue) do
      path_or_venue
      |> ControlPlanePresenter.follow_up_render_variant()
      |> Atom.to_string()
    end

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)

    defp format_dt(nil), do: "Unknown"
    defp format_dt(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S UTC")
  end
end
