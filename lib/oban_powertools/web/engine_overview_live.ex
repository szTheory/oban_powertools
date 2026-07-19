if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.EngineOverviewLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, OverviewReadModel}
    alias ObanPowertools.Web.Components.{DataDisplay, OperatorPatterns, Primitives}

    @impl true
    def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(
               socket,
               :view_overview,
               %{type: :page, id: "overview"}
             ) do
        {:ok, assign_metrics(socket, dashboard_path)}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def render(assigns) do
      ~H"""
      <.page_content overview_buckets={@overview_buckets} />
      """
    end

    attr(:overview_buckets, :list, required: true)

    def page_content(assigns) do
      assigns =
        assigns
        |> assign(:needs_review, bucket!(assigns.overview_buckets, "needs_review"))
        |> assign(:blocked, bucket!(assigns.overview_buckets, "blocked"))
        |> assign(:waiting, bucket!(assigns.overview_buckets, "waiting"))
        |> assign(:bridge, bucket!(assigns.overview_buckets, "bridge_follow_up"))
        |> assign(:runnable, bucket!(assigns.overview_buckets, "runnable"))
        |> assign(
          :resolved_continuity,
          bucket!(assigns.overview_buckets, "resolved_continuity")
        )
        |> assign(:all_quiet?, all_quiet?(assigns.overview_buckets))

      ~H"""
      <section id="overview-page" aria-labelledby="overview-title">
        <header>
          <h1 id="overview-title">Overview</h1>
          <p>See what needs attention, why it matters, and where to continue.</p>
        </header>

        <section id="overview-current-attention" aria-labelledby="overview-current-attention-title">
          <h2 id="overview-current-attention-title">Current attention</h2>

          <DataDisplay.empty_state
            :if={@all_quiet?}
            id="overview-all-quiet"
            heading="No current follow-up identified"
            body="Available evidence identifies no current native or bridge follow-up. Open Jobs to review individual job state."
          >
            <:action>
              <Primitives.link navigate="/ops/jobs/jobs">Open Jobs</Primitives.link>
            </:action>
          </DataDisplay.empty_state>

          <.current_attention_lane bucket={@needs_review} />
          <.current_attention_lane bucket={@blocked} />
          <.current_attention_lane bucket={@waiting} />
        </section>

        <section id="overview-bridge-follow-up" aria-labelledby="overview-bridge-follow-up-title">
          <Primitives.surface variant={:elevated}>
            <h2 id="overview-bridge-follow-up-title">{@bridge.title}</h2>
            <p>{@bridge.sample_count_label}</p>
            <p>{@bridge.summary}</p>
            <p>{@bridge.impact}</p>
            <p>Oban Web bridge · Inspection only</p>
            <Primitives.link navigate={@bridge.next_step_path}>
              {@bridge.next_step_label}
            </Primitives.link>
          </Primitives.surface>
          <.exemplar_rows bucket={@bridge} />
        </section>

        <section id="overview-runnable" aria-labelledby="overview-runnable-title">
          <h2 id="overview-runnable-title">{@runnable.title}</h2>
          <DataDisplay.metric_card
            id="overview-runnable-metric"
            label="Current runnable capacity"
            value={Integer.to_string(@runnable.count)}
            status={@runnable.summary}
            tone={:info}
          >
            <:action>
              <Primitives.link navigate={@runnable.next_step_path}>
                {@runnable.next_step_label}
              </Primitives.link>
            </:action>
          </DataDisplay.metric_card>
          <p>{@runnable.impact}</p>
          <.exemplar_rows bucket={@runnable} />
        </section>

        <section
          id="overview-resolved-continuity"
          aria-labelledby="overview-resolved-continuity-title"
        >
          <Primitives.surface variant={:plain}>
            <h2 id="overview-resolved-continuity-title">{@resolved_continuity.title}</h2>
            <p>{@resolved_continuity.sample_count_label}</p>
            <p>{@resolved_continuity.summary}</p>
            <p>{@resolved_continuity.impact}</p>
            <p>Continuity evidence</p>
            <Primitives.link navigate={@resolved_continuity.next_step_path}>
              {@resolved_continuity.next_step_label}
            </Primitives.link>
          </Primitives.surface>
          <.exemplar_rows bucket={@resolved_continuity} />
        </section>
      </section>
      """
    end

    attr(:bucket, :map, required: true)

    defp current_attention_lane(assigns) do
      assigns =
        assigns
        |> assign(:region_id, "overview-#{String.replace(assigns.bucket.id, "_", "-")}")
        |> assign(:empty_heading, empty_lane_heading(assigns.bucket.kind))

      ~H"""
      <section id={@region_id}>
        <OperatorPatterns.attention_card
          :if={@bucket.count > 0}
          id={"#{@region_id}-attention"}
          title={@bucket.title}
          summary={@bucket.summary}
          impact={@bucket.impact}
          observed_at={@bucket.observed_at}
          observed_datetime={@bucket.observed_datetime}
          domain={:limiter}
          status={@bucket.status}
          severity={@bucket.severity}
          completeness={@bucket.completeness}
          live={:off}
        >
          <:primary_action>
            <Primitives.link navigate={@bucket.next_step_path}>
              {@bucket.next_step_label}
            </Primitives.link>
          </:primary_action>
        </OperatorPatterns.attention_card>

        <Primitives.surface :if={@bucket.count == 0} variant={:inset}>
          <DataDisplay.empty_state
            id={"#{@region_id}-empty"}
            heading={@empty_heading}
            body={@bucket.summary}
          >
            <:action>
              <Primitives.link navigate={@bucket.next_step_path}>
                {@bucket.next_step_label}
              </Primitives.link>
            </:action>
          </DataDisplay.empty_state>
        </Primitives.surface>

        <.exemplar_rows bucket={@bucket} />
      </section>
      """
    end

    attr(:bucket, :map, required: true)

    defp exemplar_rows(assigns) do
      ~H"""
      <ul :if={@bucket.exemplars != []} aria-label={"#{@bucket.title} examples"}>
        <li :for={exemplar <- @bucket.exemplars}>
          <p><strong>{exemplar.label}</strong></p>
          <p>{exemplar_detail(exemplar)}</p>
          <p :if={Map.get(exemplar, :venue)}>{exemplar.venue}</p>
          <p :if={Map.get(exemplar, :ownership)}>{exemplar.ownership}</p>
          <p :if={show_completeness?(exemplar)}>{exemplar.evidence_completeness}</p>
          <nav aria-label={"Destinations for #{exemplar.label}"}>
            <Primitives.link
              :if={Map.get(exemplar, :evidence_path)}
              navigate={exemplar.evidence_path}
            >
              Open forensic timeline
            </Primitives.link>
            <Primitives.link navigate={exemplar.path}>
              {exemplar_link_label(exemplar)}
            </Primitives.link>
          </nav>
        </li>
      </ul>
      """
    end

    defp assign_metrics(socket, dashboard_path) do
      overview_buckets =
        repo()
        |> then(&OverviewReadModel.build(repo: &1, dashboard_path: dashboard_path))
        |> Enum.map(&ControlPlanePresenter.present_overview_bucket/1)

      assign(socket, :overview_buckets, overview_buckets)
    end

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)

    defp bucket!(buckets, id), do: Enum.find(buckets, &(&1.id == id)) || raise("missing #{id}")

    defp all_quiet?(buckets) do
      quiet_ids = ~w[needs_review blocked waiting bridge_follow_up]
      Enum.all?(buckets, &(&1.id not in quiet_ids or &1.count == 0))
    end

    defp empty_lane_heading(:needs_review), do: "No needs review identified"
    defp empty_lane_heading(:blocked), do: "No blocked limiters identified"
    defp empty_lane_heading(:waiting), do: "No waiting work identified"

    defp exemplar_detail(exemplar) do
      Map.get(exemplar, :attention_reason) || Map.get(exemplar, :fact)
    end

    defp show_completeness?(%{evidence_completeness: completeness})
         when completeness in ["partial evidence", "history unavailable", "unknown"],
         do: true

    defp show_completeness?(_exemplar), do: false

    defp exemplar_link_label(exemplar) do
      if Map.get(exemplar, :evidence_path), do: "Open runbook entry", else: "Review exemplar"
    end
  end
end
