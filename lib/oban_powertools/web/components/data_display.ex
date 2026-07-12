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
    workflow workflow_await workflow_result workflow_signal workflow_step
  ]a
  @data_states ~w[ready loading empty error unavailable permission_denied]a
  @sort_directions ~w[asc desc none]a
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
              <.state_message state={@state} resource={@state_resource}>{render_slot(@state_detail)}</.state_message>
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

  attr(:state, :atom, required: true)
  attr(:resource, :string, required: true)
  slot(:inner_block)

  def state_message(assigns) do
    assigns =
      assigns
      |> assign(:copy, state_copy(assigns.state, assigns.resource))
      |> assign(:role, if(assigns.state == :error, do: "alert", else: "status"))

    ~H"""
    <div class="obpt-data-state" data-obpt-data-state={data_state(@state)} role={@role}>
      <p>{@copy.heading}</p>
      <p>{@copy.body}</p>
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
    assigns = assign(assigns, :rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <section id={@id} class="obpt-description-list" data-obpt-data-state={data_state(@state)} {@rest}>
      <.state_message :if={@state != :ready} state={@state} resource={@resource} />
      <dl :if={@state == :ready}>
        <div :for={item <- @item} class="obpt-description-list__item" data-obpt-value-kind={Map.get(item, :value_kind)}>
          <dt>{item.label}</dt>
          <dd>{render_slot(item)}</dd>
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
      <dt>{@label}</dt>
      <dd>{@value}</dd>
    </dl>
    """
  end

  attr(:id, :string, required: true)
  attr(:value, :string, required: true)
  attr(:kind, :atom, default: :id)
  attr(:truncate, :boolean, default: true)
  attr(:expand, :boolean, default: false)
  attr(:rest, :global, default: %{})

  def machine_value(assigns) do
    display = if assigns.truncate, do: truncate_middle(assigns.value, 48), else: assigns.value

    assigns =
      assign(assigns,
        display: display,
        rest: visual_safe_rest(assigns.rest, suppress_actions?: true)
      )

    ~H"""
    <span id={@id} class="obpt-machine-value" data-obpt-kind={@kind} {@rest}>
      <details :if={@expand}>
        <summary>{@display}</summary>
        <span>{@value}</span>
      </details>
      <span :if={!@expand}>{@display}</span>
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
    assigns = assign(assigns, :rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <section id={@id} class="obpt-timeline" data-obpt-data-state={data_state(@state)} {@rest}>
      <.state_message :if={@state != :ready} state={@state} resource={@resource} />
      <ol :if={@state == :ready}>
        <li :for={event <- @event}>
          <time datetime={event.timestamp}>{event.timestamp}</time>
          <p>{event.title}</p>
          <span :if={Map.get(event, :source)}>{event.source}</span>
          <.status_pill :if={Map.get(event, :domain) && Map.get(event, :state)} id={"#{@id}-#{event.timestamp}-status"} domain={event.domain} state={event.state} />
          <div>{render_slot(event)}</div>
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
    assigns =
      assigns
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))
      |> assign(:clamped, clamp_progress(assigns.value, assigns.max))

    ~H"""
    <div id={@id} class="obpt-progress" data-obpt-data-state={data_state(@state)} {@rest}>
      <label for={"#{@id}-progress"}>{@label}</label>
      <p :if={@state == :unavailable}>Progress unavailable</p>
      <progress :if={@state != :unavailable} id={"#{@id}-progress"} value={@clamped} max={positive_max(@max)}>{@clamped}</progress>
      <span :if={@state != :unavailable}>{@clamped}/{positive_max(@max)}</span>
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
    assigns = assign(assigns, :rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <section id={@id} class="obpt-metric-card" data-obpt-tone={@tone} {@rest}>
      <p>{@label}</p>
      <p>{@value}</p>
      <p :if={@trend}>{@trend}</p>
      <p :if={@status}>{@status}</p>
      {render_slot(@action)}
    </section>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:content, :string, required: true)
  attr(:language, :string, default: "text")
  attr(:rest, :global, default: %{})

  def code_block(assigns) do
    assigns = assign(assigns, :rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <figure id={@id} class="obpt-code-block" data-obpt-language={@language} {@rest}>
      <figcaption>{@label}</figcaption>
      <pre tabindex="0"><code>{@content}</code></pre>
    </figure>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:display, :any, required: true)
  attr(:kind, :atom, default: :args)

  def args_viewer(assigns) do
    assigns = assign(assigns, :rendered_display, render_normalized_display(assigns.display))

    ~H"""
    <section id={@id} class="obpt-args-viewer" data-obpt-kind={@kind}>
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
      <span :if={@rendered_display.sibling}>{@rendered_display.sibling}</span>
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
        :fallback -> assigns.message || "[redacted]"
      end

    assigns = assign(assigns, :copy, copy)

    ~H"""
    <span id={@id} class="obpt-redacted-value" data-obpt-redaction-reason={@reason}>
      <span aria-hidden="true">!</span>
      <span>{@copy}</span>
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
    assigns = assign(assigns, :rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <section id={@id} class="obpt-empty-state" {@rest}>
      <h2>{@heading}</h2>
      <p>{@body}</p>
      {render_slot(@action)}
    </section>
    """
  end

  attr(:id, :string, required: true)
  attr(:tone, :atom, default: :info, values: @tones)
  attr(:urgency, :atom, default: :polite, values: @urgencies)
  attr(:dismiss_event, :string, default: nil)
  attr(:rest, :global, default: %{})
  slot(:inner_block, required: true)

  def toast(assigns) do
    role =
      if assigns.urgency == :assertive or assigns.tone in [:warning, :danger],
        do: "alert",
        else: "status"

    assigns =
      assigns
      |> assign(:role, role)
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <div id={@id} class="obpt-toast" data-obpt-tone={@tone} role={@role} {@rest}>
      <div>{render_slot(@inner_block)}</div>
      <button :if={@dismiss_event} type="button" phx-click={@dismiss_event} aria-label="Dismiss notification">Dismiss</button>
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
      |> assign(:items, flash_items(assigns.flash))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <div id={@id} class="obpt-flash-group" {@rest}>
      <.toast :for={{tone, message} <- @items} id={"#{@id}-#{tone}"} tone={tone} dismiss_event={@dismiss_event}>
        {message}
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
        "class",
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

  defp truncate_middle(value, max) when byte_size(value) <= max, do: value

  defp truncate_middle(value, max) do
    keep = div(max - 1, 2)
    binary_part(value, 0, keep) <> "..." <> binary_part(value, byte_size(value) - keep, keep)
  end

  defp clamp_progress(nil, _max), do: 0
  defp clamp_progress(value, max), do: value |> max(0) |> min(positive_max(max))
  defp positive_max(max) when is_integer(max) and max > 0, do: max
  defp positive_max(_max), do: 100

  defp render_normalized_display({:raw_json, json}),
    do: display_view(:code, %{content: json, language: "json"})

  defp render_normalized_display({:string, text}),
    do: display_view(:code, %{content: text, language: "text"})

  defp render_normalized_display({:fallback, message}),
    do: display_view(:redacted, %{reason: :fallback, message: message})

  defp render_normalized_display(display) when is_map(display) do
    cond do
      display_value(display, :available?) == false ->
        display_view(:redacted, %{reason: :policy})

      display_value(display, :redacted?) == true ->
        display_view(:redacted, %{
          reason: :policy,
          sibling: display_value(display, :sibling)
        })

      true ->
        display_view(:code, %{
          content: inspect(display, pretty: true, limit: :infinity),
          language: "elixir"
        })
    end
  end

  defp display_view(kind, attrs) do
    Map.merge(
      %{kind: kind, content: nil, language: nil, message: nil, reason: nil, sibling: nil},
      attrs
    )
  end

  defp display_value(display, key),
    do: Map.get(display, key) || Map.get(display, Atom.to_string(key))

  defp flash_items(flash) do
    for {kind, message} <- flash, message not in [nil, ""] do
      {flash_tone(kind), message}
    end
  end

  defp flash_tone(:info), do: :info
  defp flash_tone(:error), do: :danger
  defp flash_tone(:warning), do: :warning
  defp flash_tone(:success), do: :success
  defp flash_tone(_kind), do: :neutral
end
