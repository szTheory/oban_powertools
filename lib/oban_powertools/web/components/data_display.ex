defmodule ObanPowertools.Web.Components.DataDisplay do
  @moduledoc """
  Stateless data-display function components for Powertools operator surfaces.
  """

  use Phoenix.Component

  alias ObanPowertools.Web.Components.Primitives
  alias ObanPowertools.Web.StatusTaxonomy

  @status_domains ~w[
    batch batch_member callback_outbox continuity cron data_availability forensics
    host_follow_up job lifeline_health lifeline_incident lifeline_preview limiter output
    operator_result workflow workflow_await workflow_result workflow_signal workflow_step
  ]a
  @data_states ~w[ready loading empty error unavailable permission_denied]a
  @sort_directions ~w[asc desc none]a
  @machine_kinds ~w[id module url literal]a
  @code_languages ~w[json text elixir stacktrace]
  @args_kinds ~w[
    args meta callback_payload callback_error job_error recorded_output workflow_result stacktrace
  ]a
  @tones ~w[neutral info success warning danger]a
  @urgencies ~w[polite assertive]a
  @redaction_reasons ~w[enqueue policy fallback]a

  attr(:id, :string, default: nil)
  attr(:domain, :atom, required: true, values: @status_domains)
  attr(:state, :any, required: true)
  attr(:rest, :global, default: %{})

  def status_pill(assigns) do
    assigns =
      assigns
      |> assign(:spec, StatusTaxonomy.spec(assigns.domain, assigns.state))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <Primitives.status_pill id={@id} spec={@spec} {@rest} />
    """
  end

  attr(:id, :string, required: true)
  attr(:caption, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, required: true)
  attr(:state, :atom, default: :ready, values: @data_states)
  attr(:resource, :string, default: nil)
  attr(:row_count, :integer, default: nil)
  attr(:pagination_summary, :string, default: nil)
  attr(:sort_key, :string, default: nil)
  attr(:sort_direction, :atom, default: :none, values: @sort_directions)
  attr(:sort_event, :string, default: nil)
  attr(:rest, :global, default: %{})
  slot(:toolbar)
  slot(:selection)

  slot(:col) do
    attr(:label, :string, required: true)
    attr(:sort_key, :string)
    attr(:value_kind, :atom)
  end

  slot(:action)
  slot(:state_detail)

  def data_table(assigns) do
    assigns =
      assigns
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))
      |> assign(:data_state, data_state(assigns.state))
      |> assign(:aria_busy, if(assigns.state == :loading, do: "true"))
      |> assign(:state_resource, assigns.resource || String.downcase(assigns.caption))
      |> assign(:row_count_text, row_count_text(assigns))

    ~H"""
    <section id={@id} class="obpt-data-table" data-obpt-data-state={@data_state} aria-busy={@aria_busy} {@rest}>
      <div :if={@toolbar != []} class="obpt-data-table__toolbar">{render_slot(@toolbar)}</div>
      <table class="obpt-data-table__table">
        <caption>
          <span>{@caption}</span>
          <span class="obpt-data-table__summary">{@row_count_text}</span>
          <span :if={@pagination_summary} class="obpt-data-table__summary">{@pagination_summary}</span>
        </caption>
        <thead>
          <tr class="obpt-data-table__header-row">
            <th :if={@selection != []} scope="col" class="obpt-data-table__header">Selection</th>
            <th
              :for={col <- @col}
              scope="col"
              class="obpt-data-table__header"
              aria-sort={aria_sort(col, @sort_key, @sort_direction)}
            >
              <button :if={sortable?(col, @sort_event)} type="button" phx-click={@sort_event} phx-value-sort-key={col.sort_key}>
                {col.label}
              </button>
              <span :if={!sortable?(col, @sort_event)}>{col.label}</span>
            </th>
            <th :if={@action != []} scope="col" class="obpt-data-table__header">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr :if={@state != :ready} class="obpt-data-table__state-row">
            <td class="obpt-data-table__state-cell" colspan={state_colspan(assigns)}>
              <.state_message id={"#{@id}-state"} state={@state} resource={@state_resource}>
                {render_slot(@state_detail)}
              </.state_message>
            </td>
          </tr>
          <tr
            :for={row <- @rows}
            :if={@state == :ready}
            id={row_dom_id(@id, row_key(row, @row_id))}
            class="obpt-data-table__row"
          >
            <td :if={@selection != []} class="obpt-data-table__cell" data-obpt-mobile-label="Selection">
              <span class="obpt-data-table__mobile-label" aria-hidden="true">Selection</span>
              <div class="obpt-data-table__cell-value">{render_slot(@selection, row)}</div>
            </td>
            <td
              :for={col <- @col}
              class="obpt-data-table__cell"
              data-obpt-mobile-label={col.label}
              data-obpt-value-kind={Map.get(col, :value_kind)}
            >
              <span class="obpt-data-table__mobile-label" aria-hidden="true">{col.label}</span>
              <div class="obpt-data-table__cell-value">{render_slot(col, row)}</div>
            </td>
            <td :if={@action != []} class="obpt-data-table__cell" data-obpt-mobile-label="Actions">
              <span class="obpt-data-table__mobile-label" aria-hidden="true">Actions</span>
              <div class="obpt-data-table__cell-value">{render_slot(@action, row)}</div>
            </td>
          </tr>
        </tbody>
      </table>
    </section>
    """
  end

  attr(:id, :string, required: true)
  attr(:state, :atom, required: true)
  attr(:resource, :string, required: true)
  slot(:inner_block)

  def state_message(assigns) do
    assigns =
      assigns
      |> assign(:copy, state_copy(assigns.state, assigns.resource))
      |> assign(:role, if(assigns.state == :error, do: "alert", else: "status"))

    ~H"""
    <div id={@id} class="obpt-data-state" data-obpt-data-state={data_state(@state)} role={@role}>
      <.empty_state
        :if={@state == :empty}
        id={"#{@id}-empty"}
        heading={@copy.heading}
        body={@copy.body}
      />
      <div :if={@state != :empty} class="obpt-data-state__copy">
        <p class="obpt-data-state__heading">{@copy.heading}</p>
        <p class="obpt-data-state__body">{@copy.body}</p>
      </div>
      <Primitives.skeleton :if={@state == :loading} label={@copy.heading} lines={3} />
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:state, :atom, default: :ready, values: @data_states)
  attr(:resource, :string, default: "details")
  attr(:rest, :global, default: %{})

  slot(:item) do
    attr(:label, :string, required: true)
    attr(:value_kind, :atom)
  end

  def description_list(assigns) do
    assigns =
      assigns
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))
      |> assign(:aria_busy, if(assigns.state == :loading, do: "true"))

    ~H"""
    <section
      id={@id}
      class="obpt-description-list"
      data-obpt-data-state={data_state(@state)}
      aria-busy={@aria_busy}
      {@rest}
    >
      <.state_message
        :if={@state != :ready}
        id={"#{@id}-state"}
        state={@state}
        resource={@resource}
      />
      <dl :if={@state == :ready} class="obpt-description-list__list">
        <div :for={item <- @item} class="obpt-description-list__item" data-obpt-value-kind={Map.get(item, :value_kind)}>
          <dt class="obpt-description-list__term">{item.label}</dt>
          <dd class="obpt-description-list__value">{render_slot(item)}</dd>
        </div>
      </dl>
    </section>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:value, :any, required: true)
  attr(:value_kind, :atom, default: :text)
  attr(:rest, :global, default: %{})

  def key_value(assigns) do
    assigns = assign(assigns, :rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <dl id={@id} class="obpt-key-value" data-obpt-value-kind={@value_kind} {@rest}>
      <dt class="obpt-key-value__term">{@label}</dt>
      <dd class="obpt-key-value__value">{@value}</dd>
    </dl>
    """
  end

  attr(:id, :string, required: true)
  attr(:value, :string, required: true)
  attr(:kind, :atom, default: :id, values: @machine_kinds)
  attr(:truncate, :boolean, default: true)
  attr(:expand, :boolean, default: false)
  attr(:rest, :global, default: %{})

  def machine_value(assigns) do
    display = machine_display(assigns.value, assigns.kind, assigns.truncate)

    assigns =
      assign(assigns,
        display: display,
        rest: visual_safe_rest(assigns.rest, suppress_actions?: true)
      )

    ~H"""
    <span id={@id} class="obpt-machine-value" data-obpt-kind={@kind} {@rest}>
      <details :if={@expand} class="obpt-machine-value__details">
        <summary class="obpt-machine-value__summary">{@display}</summary>
        <span class="obpt-machine-value__full">{@value}</span>
      </details>
      <span :if={!@expand} class="obpt-machine-value__display">{@display}</span>
    </span>
    """
  end

  attr(:id, :string, required: true)
  attr(:state, :atom, default: :ready, values: @data_states)
  attr(:resource, :string, default: "events")
  attr(:rest, :global, default: %{})

  slot(:event) do
    attr(:timestamp, :string, required: true)
    attr(:title, :string, required: true)
    attr(:source, :string)
    attr(:domain, :any)
    attr(:state, :any)
  end

  def timeline(assigns) do
    assigns =
      assigns
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))
      |> assign(:aria_busy, if(assigns.state == :loading, do: "true"))

    ~H"""
    <section
      id={@id}
      class="obpt-timeline"
      data-obpt-data-state={data_state(@state)}
      aria-busy={@aria_busy}
      {@rest}
    >
      <.state_message
        :if={@state != :ready}
        id={"#{@id}-state"}
        state={@state}
        resource={@resource}
      />
      <ol :if={@state == :ready} class="obpt-timeline__list">
        <li :for={{event, index} <- Enum.with_index(@event)} id={"#{@id}-event-#{index}"} class="obpt-timeline__item">
          <time class="obpt-timeline__time" datetime={event.timestamp}>{event.timestamp}</time>
          <p class="obpt-timeline__title">{event.title}</p>
          <span :if={Map.get(event, :source)} class="obpt-timeline__source">{event.source}</span>
          <.status_pill
            :if={Map.get(event, :domain) && Map.get(event, :state)}
            id={"#{@id}-event-#{index}-status"}
            domain={event.domain}
            state={event.state}
          />
          <div class="obpt-timeline__detail">{render_slot(event)}</div>
        </li>
      </ol>
    </section>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:value, :integer, default: nil)
  attr(:max, :integer, default: 100)
  attr(:state, :atom, default: :ready, values: @data_states)
  attr(:rest, :global, default: %{})

  def progress_bar(assigns) do
    max = positive_max(assigns.max)
    measurement = progress_measurement(assigns.value, max)
    effective_state = if measurement, do: assigns.state, else: :unavailable

    assigns =
      assigns
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))
      |> assign(:measurement, measurement)
      |> assign(:effective_state, effective_state)

    ~H"""
    <div id={@id} class="obpt-progress" data-obpt-data-state={data_state(@effective_state)} {@rest}>
      <span id={"#{@id}-label"} class="obpt-progress__label">{@label}</span>
      <p :if={@effective_state == :unavailable} class="obpt-progress__unavailable">Progress unavailable</p>
      <div :if={@effective_state != :unavailable} class="obpt-progress__value">
        <progress
          id={"#{@id}-progress"}
          value={@measurement.value}
          max={@measurement.max}
          aria-labelledby={"#{@id}-label"}
        >
          {@measurement.value}
        </progress>
        <span class="obpt-progress__count">{@measurement.value}/{@measurement.max}</span>
        <span class="obpt-progress__percent">{@measurement.percent}%</span>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:value, :string, required: true)
  attr(:trend, :string, default: nil)
  attr(:status, :any, default: nil)
  attr(:tone, :atom, default: :neutral, values: @tones)
  attr(:rest, :global, default: %{})
  slot(:action)

  def metric_card(assigns) do
    assigns =
      assigns
      |> assign(:label, require_text!(assigns.label, "metric label"))
      |> assign(:value, require_text!(assigns.value, "metric value"))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <article id={@id} class="obpt-metric-card" data-obpt-tone={@tone} {@rest}>
      <Primitives.stat label={@label} value={@value} trend={@trend} tone={@tone} />
      <p :if={@status} class="obpt-metric-card__status">{@status}</p>
      <div :if={@action != []} class="obpt-metric-card__action">{render_slot(@action)}</div>
    </article>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:content, :string, required: true)
  attr(:language, :string, default: "text", values: @code_languages)
  attr(:rest, :global, default: %{})

  def code_block(assigns) do
    assigns =
      assigns
      |> assign(:label, require_text!(assigns.label, "code block label"))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <figure id={@id} class="obpt-code-block" data-obpt-language={@language} {@rest}>
      <figcaption>{@label}</figcaption>
      <pre class="obpt-code-block__region" tabindex="0"><code class="obpt-code-block__code">{@content}</code></pre>
    </figure>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:display, :any, required: true)
  attr(:kind, :atom, default: :args, values: @args_kinds)

  def args_viewer(assigns) do
    assigns =
      assigns
      |> assign(:label, require_text!(assigns.label, "args viewer label"))
      |> assign(:rendered_display, render_normalized_display(assigns.display))

    ~H"""
    <section
      id={@id}
      class="obpt-args-viewer"
      data-obpt-kind={@kind}
      data-obpt-display-state={@rendered_display.state}
    >
      <div
        :if={@rendered_display.summary || @rendered_display.status}
        class="obpt-args-viewer__context"
      >
        <p :if={@rendered_display.summary} class="obpt-args-viewer__summary">
          {@rendered_display.summary}
        </p>
        <span :if={@rendered_display.status} class="obpt-args-viewer__status">
          {@rendered_display.status}
        </span>
      </div>
      <.code_block
        :if={@rendered_display.kind == :code}
        id={"#{@id}-code"}
        label={@label}
        content={@rendered_display.content}
        language={@rendered_display.language}
      />
      <.redacted_value
        :if={@rendered_display.kind == :redacted}
        id={"#{@id}-redacted"}
        reason={@rendered_display.reason}
        message={@rendered_display.message}
      />
      <div
        :if={@rendered_display.kind == :unavailable}
        class="obpt-args-viewer__unavailable"
        role="status"
      >
        Data unavailable
      </div>
    </section>
    """
  end

  attr(:id, :string, required: true)
  attr(:reason, :atom, default: :policy, values: @redaction_reasons)
  attr(:message, :string, default: nil)

  def redacted_value(assigns) do
    copy =
      case assigns.reason do
        :enqueue -> "Redacted at enqueue"
        :policy -> "Hidden by display policy"
        :fallback -> fallback_copy(assigns.message)
      end

    assigns = assign(assigns, :copy, copy)

    ~H"""
    <span id={@id} class="obpt-redacted-value" data-obpt-redaction-reason={@reason}>
      <span class="obpt-redacted-value__icon" aria-hidden="true">!</span>
      <span class="obpt-redacted-value__copy">{@copy}</span>
      <span class="obpt-sr-only">Sensitive value hidden</span>
    </span>
    """
  end

  attr(:id, :string, required: true)
  attr(:heading, :string, required: true)
  attr(:body, :string, required: true)
  attr(:rest, :global, default: %{})
  slot(:action)

  def empty_state(assigns) do
    assigns =
      assigns
      |> assign(:heading, require_text!(assigns.heading, "empty state heading"))
      |> assign(:body, require_text!(assigns.body, "empty state body"))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <section id={@id} class="obpt-empty-state" {@rest}>
      <h2 class="obpt-empty-state__heading">{@heading}</h2>
      <p class="obpt-empty-state__body">{@body}</p>
      <div :if={@action != []} class="obpt-empty-state__action">{render_slot(@action)}</div>
    </section>
    """
  end

  attr(:id, :string, required: true)
  attr(:tone, :atom, default: :info, values: @tones)
  attr(:urgency, :atom, default: :polite, values: @urgencies)
  attr(:dismiss_event, :string, default: nil)
  attr(:dismiss_key, :string, default: nil)
  attr(:rest, :global, default: %{})
  slot(:inner_block, required: true)

  def toast(assigns) do
    assigns =
      assigns
      |> assign(:role, toast_role(assigns.urgency, assigns.tone))
      |> assign(:icon, toast_icon(assigns.tone))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <div id={@id} class="obpt-toast" data-obpt-tone={@tone} role={@role} {@rest}>
      <span class="obpt-toast__icon" aria-hidden="true">{@icon}</span>
      <div class="obpt-toast__content">{render_slot(@inner_block)}</div>
      <button
        :if={@dismiss_event}
        type="button"
        class="obpt-toast__dismiss"
        phx-click={@dismiss_event}
        phx-value-key={@dismiss_key}
        aria-label="Dismiss notification"
      >
        Dismiss
      </button>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:flash, :map, default: %{})
  attr(:dismiss_event, :string, default: "lv:clear-flash")
  attr(:rest, :global, default: %{})

  def flash_group(assigns) do
    assigns =
      assigns
      |> assign(:items, flash_items(assigns.id, assigns.flash))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <div id={@id} class="obpt-flash-group" {@rest}>
      <.toast
        :for={item <- @items}
        id={item.id}
        tone={item.tone}
        urgency={item.urgency}
        dismiss_event={@dismiss_event}
        dismiss_key={item.key}
      >
        {item.message}
      </.toast>
    </div>
    """
  end

  defp visual_safe_rest(rest, opts) do
    suppress_actions? = Keyword.get(opts, :suppress_actions?, false)

    rest
    |> normalize_rest()
    |> Enum.reject(fn {key, _value} ->
      key in [
        "aria-hidden",
        "aria-label",
        "aria-labelledby",
        "aria-live",
        "class",
        "data-obpt-language",
        "data-obpt-icon",
        "data-obpt-size",
        "data-obpt-tone",
        "role",
        "style",
        "title"
      ] or String.starts_with?(key, "on") or
        (suppress_actions? and action_attr?(key))
    end)
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == false end)
    |> Map.new()
  end

  defp normalize_rest(nil), do: %{}
  defp normalize_rest(rest), do: Map.new(rest, fn {key, value} -> {to_string(key), value} end)

  defp action_attr?(key) do
    key == "href" or key == "form" or key == "name" or key == "value" or
      String.starts_with?(key, "phx-")
  end

  defp data_state(:permission_denied), do: "permission_denied"
  defp data_state(state), do: to_string(state || :ready)

  defp sortable?(col, sort_event),
    do: is_binary(Map.get(col, :sort_key)) and is_binary(sort_event)

  defp aria_sort(col, current_key, direction) do
    if Map.get(col, :sort_key) == current_key do
      case direction do
        :asc -> "ascending"
        :desc -> "descending"
        _ -> nil
      end
    end
  end

  defp row_dom_id(prefix, key) do
    "#{prefix}-row-#{key || :unknown}"
  end

  defp row_key(row, row_id) when is_function(row_id, 1), do: row_id.(row)
  defp row_key(row, _row_id) when is_map(row), do: Map.get(row, :id) || Map.get(row, "id")
  defp row_key(_row, _row_id), do: nil

  defp row_count_text(assigns) do
    count = assigns.row_count || length(assigns.rows)
    "#{count} #{assigns.resource || "rows"}"
  end

  defp state_colspan(assigns),
    do:
      length(assigns.col) + if(assigns.selection == [], do: 0, else: 1) +
        if(assigns.action == [], do: 0, else: 1)

  defp state_copy(:loading, resource), do: %{heading: "Loading #{resource}", body: "Refresh data"}

  defp state_copy(:empty, _resource),
    do: %{
      heading: "No rows match the current filters",
      body: "Clear filters or widen the time window."
    }

  defp state_copy(:error, _resource),
    do: %{heading: "Data did not load", body: "Retry the request or check the host logs."}

  defp state_copy(:unavailable, _resource),
    do: %{heading: "Data unavailable", body: "Refresh data"}

  defp state_copy(:permission_denied, _resource),
    do: %{heading: "Permission denied", body: "Ask an administrator for access."}

  defp state_copy(_state, resource), do: %{heading: "Showing #{resource}", body: ""}

  defp truncate_middle(value, max) when is_binary(value) do
    if String.length(value) <= max do
      value
    else
      keep = div(max - 3, 2)
      String.slice(value, 0, keep) <> "..." <> String.slice(value, -keep, keep)
    end
  end

  defp preserve_suffix(value, max) when is_binary(value) do
    if String.length(value) <= max do
      value
    else
      keep = max - 3
      "..." <> String.slice(value, -keep, keep)
    end
  end

  defp machine_display(value, _kind, false), do: value
  defp machine_display(value, :module, true), do: preserve_suffix(value, 48)
  defp machine_display(value, :url, true), do: truncate_middle(value, 64)
  defp machine_display(value, _kind, true), do: truncate_middle(value, 48)

  defp progress_measurement(nil, _max), do: nil

  defp progress_measurement(value, max) when is_integer(value) do
    clamped = clamp_progress(value, max)
    %{value: clamped, max: max, percent: progress_percent(clamped, max)}
  end

  defp clamp_progress(value, max) when is_integer(value), do: value |> max(0) |> min(max)
  defp positive_max(max) when is_integer(max) and max > 0, do: max
  defp positive_max(_max), do: 100
  defp progress_percent(value, max), do: round(value / max * 100)

  defp render_normalized_display({:raw_json, json}) when is_binary(json),
    do: display_view(:code, %{content: json, language: "json", state: :ready})

  defp render_normalized_display({:string, text}) when is_binary(text),
    do: display_view(:code, %{content: text, language: "text", state: :ready})

  defp render_normalized_display({:fallback, _message}),
    do: display_view(:redacted, %{reason: :fallback, message: "[redacted]", state: :redacted})

  defp render_normalized_display(display) when is_map(display) do
    available? = display_value!(display, :available?)
    redacted? = display_value!(display, :redacted?)
    summary = display_value(display, :summary)
    status = display_value!(display, :status)

    case {available?, redacted?} do
      {false, _redacted?} ->
        display_view(:unavailable, %{
          state: :unavailable,
          summary: summary,
          status: status
        })

      {true, true} ->
        display_view(:redacted, %{
          reason: :policy,
          state: :redacted,
          summary: summary,
          status: status
        })

      {true, false} ->
        display_view(:code, %{
          content: normalized_payload(display_value!(display, :payload)),
          language: "text",
          state: :ready,
          summary: summary,
          status: status
        })

      _other ->
        raise ArgumentError, "normalized display flags must be booleans"
    end
  end

  defp render_normalized_display(_display) do
    raise ArgumentError, "unsupported normalized display shape"
  end

  defp display_view(kind, attrs) do
    Map.merge(
      %{
        kind: kind,
        content: nil,
        language: nil,
        message: nil,
        reason: nil,
        state: :ready,
        status: nil,
        summary: nil
      },
      attrs
    )
  end

  defp display_value(display, key) do
    case fetch_display_value(display, key) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  defp display_value!(display, key) do
    case fetch_display_value(display, key) do
      {:ok, value} -> value
      :error -> raise ArgumentError, "normalized display is missing #{key}"
    end
  end

  defp fetch_display_value(display, key) do
    case Map.fetch(display, key) do
      {:ok, value} -> {:ok, value}
      :error -> Map.fetch(display, Atom.to_string(key))
    end
  end

  defp normalized_payload(payload) when is_binary(payload), do: payload

  defp normalized_payload(payload) when is_map(payload) or is_list(payload),
    do: inspect(payload, pretty: false, limit: :infinity, printable_limit: :infinity)

  defp normalized_payload(payload), do: to_string(payload)

  defp fallback_copy("[redacted]"), do: "[redacted]"
  defp fallback_copy(_message), do: "[redacted]"

  defp flash_items(group_id, flash) do
    flash
    |> Enum.reduce(%{}, fn {source_key, message}, items ->
      key = normalize_flash_key(source_key)

      if is_binary(source_key) or not Map.has_key?(items, key) do
        Map.put(items, key, message)
      else
        items
      end
    end)
    |> Enum.reject(fn {_key, message} -> message in [nil, ""] end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {key, message} ->
      tone = flash_tone(key)

      %{
        id: flash_item_id(group_id, key),
        key: key,
        message: message,
        tone: tone,
        urgency: flash_urgency(tone)
      }
    end)
  end

  defp normalize_flash_key(key) when is_binary(key), do: key
  defp normalize_flash_key(key) when is_atom(key), do: Atom.to_string(key)

  defp normalize_flash_key(key) do
    raise ArgumentError, "unsupported flash key: #{inspect(key)}"
  end

  defp flash_item_id(group_id, key) do
    "#{group_id}-#{Base.url_encode64(key, padding: false)}"
  end

  defp flash_tone("info"), do: :info
  defp flash_tone("error"), do: :danger
  defp flash_tone("warning"), do: :warning
  defp flash_tone("success"), do: :success
  defp flash_tone(_kind), do: :neutral

  defp flash_urgency(tone) when tone in [:warning, :danger], do: :assertive
  defp flash_urgency(_tone), do: :polite

  defp toast_role(:assertive, tone) when tone in [:warning, :danger], do: "alert"
  defp toast_role(_urgency, _tone), do: "status"

  defp toast_icon(:success), do: "+"
  defp toast_icon(:warning), do: "!"
  defp toast_icon(:danger), do: "!"
  defp toast_icon(:info), do: "i"
  defp toast_icon(:neutral), do: "•"

  defp require_text!(value, name) do
    present_text(value) || raise ArgumentError, "#{name} must be non-empty"
  end

  defp present_text(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      text -> text
    end
  end

  defp present_text(value) when is_atom(value), do: value |> to_string() |> present_text()
  defp present_text(_value), do: nil
end
