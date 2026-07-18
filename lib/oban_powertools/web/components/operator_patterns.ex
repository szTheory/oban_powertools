defmodule ObanPowertools.Web.Components.OperatorPatterns do
  @moduledoc """
  Stateless operator meta-components composed from Powertools Primitives, Forms,
  and DataDisplay components.

  Parent LiveViews own authorization, data loading, mutations, navigation, and
  durable evidence. These components render finite presentation truth only.
  """

  use Phoenix.Component

  alias ObanPowertools.Web.Components.{DataDisplay, Primitives}
  alias ObanPowertools.Web.ControlPlanePresenter

  @severities ~w[neutral info warning danger]a
  @completeness_values ~w[complete partial unknown unavailable]a
  @live_values ~w[off polite assertive]a
  @evidence_states ~w[current stale unavailable permission_denied]a
  @filter_modes ~w[submit instant]a

  attr(:id, :string, required: true)
  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:mode, :atom, default: :submit, values: @filter_modes)
  attr(:result_summary, :string, required: true)
  attr(:results_target_id, :string, required: true)
  attr(:active_filters, :list, default: [])
  attr(:dirty, :boolean, default: false)
  attr(:filters_expanded, :boolean, default: false)
  attr(:change_event, :string, default: nil)
  attr(:submit_event, :string, default: nil)
  attr(:clear_href, :string, default: nil)

  slot(:fields, required: true)
  slot(:advanced_fields)

  @doc """
  Renders one stateless filter form while the parent retains draft, applied, and URL truth.
  """
  def filter_bar(assigns) do
    active_filters = ControlPlanePresenter.normalize_active_filters(assigns.active_filters)
    mode = filter_mode(assigns.mode)

    assigns =
      assigns
      |> assign(:id, require_text!(assigns.id, "filter bar id"))
      |> assign(:mode, mode)
      |> assign(
        :result_summary,
        require_text!(assigns.result_summary, "filter result summary")
      )
      |> assign(
        :results_target_id,
        require_text!(assigns.results_target_id, "filter results target id")
      )
      |> assign(:active_filters, active_filters)
      |> assign(:clear_href, filter_clear_href(assigns.clear_href, active_filters))
      |> assign(:fields_id, filter_dom_id(assigns.id, "fields"))
      |> assign(:filter_state, if(assigns.filters_expanded, do: "open", else: "closed"))
      |> assign(:disclosure_label, filter_disclosure_label(active_filters))

    ~H"""
    <section
      id={@id}
      class="obpt-filter-bar"
      data-obpt-filter-bar
      data-obpt-filter-state={@filter_state}
      aria-label="Filters"
    >
      <div class="obpt-filter-bar__header">
        <button
          type="button"
          class="obpt-filter-bar__toggle"
          data-obpt-filter-toggle
          aria-expanded={to_string(@filters_expanded)}
          aria-controls={@fields_id}
        >
          {@disclosure_label}
        </button>
      </div>

      <.form
        for={@form}
        class="obpt-filter-bar__form"
        phx-change={@change_event}
        phx-submit={if(@mode == :submit, do: @submit_event)}
      >
        <div id={@fields_id} class="obpt-filter-bar__fields" data-obpt-filter-fields>
          <div class="obpt-filter-bar__primary-fields">
            {render_slot(@fields)}
          </div>

          <div :if={@advanced_fields != []} class="obpt-filter-bar__advanced-fields">
            {render_slot(@advanced_fields)}
          </div>

          <div :if={@mode == :submit} class="obpt-filter-bar__actions">
            <p :if={@dirty} class="obpt-filter-bar__dirty">Changes not applied.</p>
            <Primitives.button type="submit" variant={:primary}>Apply filters</Primitives.button>
          </div>
        </div>
      </.form>

      <section
        :if={@active_filters != []}
        class="obpt-filter-bar__applied"
        aria-label="Applied filters"
      >
        <h2 class="obpt-filter-bar__applied-title">Applied filters</h2>
        <ul class="obpt-filter-bar__applied-list">
          <li :for={filter <- @active_filters} class="obpt-filter-bar__active-filter">
            <span class="obpt-filter-bar__active-value">
              <strong>{filter.label}:</strong> {filter.value}
            </span>
            <Primitives.link href={filter.remove_href} aria-label={filter.remove_label}>
              Remove
            </Primitives.link>
          </li>
        </ul>
        <Primitives.link href={@clear_href}>Clear filters</Primitives.link>
      </section>

      <p
        id={filter_dom_id(@id, "result-summary")}
        class="obpt-filter-bar__result-summary"
        role="status"
        aria-live="polite"
        aria-atomic="true"
        aria-controls={@results_target_id}
      >
        {@result_summary}
      </p>
    </section>
    """
  end

  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:summary, :string, required: true)
  attr(:impact, :string, required: true)
  attr(:observed_at, :string, required: true)
  attr(:observed_datetime, :string, required: true)
  attr(:domain, :atom, required: true)
  attr(:status, :any, required: true)
  attr(:severity, :atom, required: true, values: @severities)
  attr(:completeness, :atom, default: :unknown, values: @completeness_values)
  attr(:live, :atom, default: :off, values: @live_values)
  slot(:primary_action)
  slot(:secondary_actions)

  @doc """
  Renders persistent current-state attention without inferring urgency or authority.
  """
  def attention_card(assigns) do
    assigns =
      assigns
      |> assign(:id, require_text!(assigns.id, "attention card id"))
      |> assign(:title, require_text!(assigns.title, "attention card title"))
      |> assign(:summary, require_text!(assigns.summary, "attention card summary"))
      |> assign(:impact, require_text!(assigns.impact, "attention card impact"))
      |> assign(:observed_at, require_text!(assigns.observed_at, "attention observed time"))
      |> assign(
        :observed_datetime,
        require_datetime!(assigns.observed_datetime, "attention observed datetime")
      )
      |> assign(
        :completeness,
        ControlPlanePresenter.normalize_evidence_completeness(assigns.completeness)
      )
      |> assign(:live_role, live_role(assigns.live))
      |> assign(:severity_spec, severity_spec(assigns.severity))

    ~H"""
    <section
      id={@id}
      class="obpt-attention-card"
      data-obpt-severity={@severity}
      data-obpt-completeness={@completeness}
      role={@live_role}
    >
      <header class="obpt-attention-card__header">
        <h2 class="obpt-attention-card__title">{@title}</h2>
        <div class="obpt-attention-card__states">
          <DataDisplay.status_pill domain={@domain} state={@status} />
          <Primitives.status_pill spec={@severity_spec} />
        </div>
      </header>

      <p class="obpt-attention-card__summary">{@summary}</p>

      <section class="obpt-attention-card__impact" aria-labelledby={"#{@id}-impact-title"}>
        <h3 id={"#{@id}-impact-title"}>Impact</h3>
        <p>{@impact}</p>
      </section>

      <div :if={@primary_action != []} class="obpt-attention-card__primary-action">
        {render_slot(@primary_action)}
      </div>

      <footer class="obpt-attention-card__evidence">
        <p class="obpt-attention-card__freshness">
          Observed <time datetime={@observed_datetime}>{@observed_at}</time>
        </p>
        <p class="obpt-attention-card__completeness">
          Evidence completeness: <strong>{humanize(@completeness)}</strong>
        </p>
      </footer>

      <nav :if={@secondary_actions != []} class="obpt-attention-card__secondary-actions" aria-label="Related evidence">
        {render_slot(@secondary_actions)}
      </nav>
    </section>
    """
  end

  attr(:id, :string, required: true)
  attr(:title, :string, default: "Why this workflow is blocked")
  attr(:summary, :string, required: true)
  attr(:impact, :string, required: true)
  attr(:observed_at, :string, required: true)
  attr(:observed_datetime, :string, required: true)
  attr(:evidence_state, :atom, default: :current, values: @evidence_states)
  attr(:completeness, :atom, default: :unknown, values: @completeness_values)
  attr(:blockers, :list, required: true)
  slot(:next_action)
  slot(:evidence)

  @doc """
  Renders every supplied current or block-start blocker without claiming causality.
  """
  def why_blocked(assigns) do
    completeness =
      ControlPlanePresenter.normalize_evidence_completeness(assigns.completeness)

    blockers = ControlPlanePresenter.normalize_blockers(assigns.blockers)

    assigns =
      assigns
      |> assign(:id, require_text!(assigns.id, "why blocked id"))
      |> assign(:title, require_text!(assigns.title, "why blocked title"))
      |> assign(:summary, require_text!(assigns.summary, "why blocked summary"))
      |> assign(:impact, require_text!(assigns.impact, "why blocked impact"))
      |> assign(:observed_at, require_text!(assigns.observed_at, "blocker observed time"))
      |> assign(
        :observed_datetime,
        require_datetime!(assigns.observed_datetime, "blocker observed datetime")
      )
      |> assign(:completeness, completeness)
      |> assign(:blockers, blockers)
      |> assign(
        :empty_truth,
        blocker_empty_truth(assigns.evidence_state, completeness, blockers)
      )
      |> assign(:evidence_copy, blocker_evidence_copy(assigns.evidence_state, completeness))

    ~H"""
    <section
      id={@id}
      class="obpt-why-blocked"
      data-obpt-evidence-state={@evidence_state}
      data-obpt-completeness={@completeness}
      aria-labelledby={"#{@id}-title"}
    >
      <header class="obpt-why-blocked__header">
        <h2 id={"#{@id}-title"} class="obpt-why-blocked__title">{@title}</h2>
        <p class="obpt-why-blocked__summary">{@summary}</p>
      </header>

      <p :if={@empty_truth} class="obpt-why-blocked__empty-truth">{@empty_truth}</p>

      <ol :if={@blockers != []} class="obpt-why-blocked__list">
        <li
          :for={blocker <- @blockers}
          class="obpt-why-blocked__blocker"
          data-obpt-blocker-id={blocker.id}
          data-obpt-evidence-kind={blocker.evidence_kind}
        >
          <p class="obpt-why-blocked__kind">{blocker_kind_label(blocker.evidence_kind)}</p>
          <h3 class="obpt-why-blocked__blocker-title">{blocker.label}</h3>
          <p class="obpt-why-blocked__blocker-summary">{blocker.summary}</p>
          <dl class="obpt-why-blocked__facts">
            <div>
              <dt>Clearing condition</dt>
              <dd>{blocker.clearing_condition}</dd>
            </div>
            <div>
              <dt>Evidence source</dt>
              <dd>{blocker.evidence_source}</dd>
            </div>
            <div :if={blocker.technical_code}>
              <dt>Technical code</dt>
              <dd><code>{blocker.technical_code}</code></dd>
            </div>
          </dl>
        </li>
      </ol>

      <section class="obpt-why-blocked__impact" aria-labelledby={"#{@id}-impact-title"}>
        <h3 id={"#{@id}-impact-title"}>Impact</h3>
        <p>{@impact}</p>
      </section>

      <div :if={@next_action != []} class="obpt-why-blocked__next-action">
        {render_slot(@next_action)}
      </div>

      <section class="obpt-why-blocked__freshness" aria-labelledby={"#{@id}-freshness-title"}>
        <h3 id={"#{@id}-freshness-title"}>Evidence freshness</h3>
        <p>{@evidence_copy}</p>
        <p>Observed <time datetime={@observed_datetime}>{@observed_at}</time></p>
        <p>Evidence completeness: <strong>{humanize(@completeness)}</strong></p>
      </section>

      <details :if={@evidence != []} class="obpt-why-blocked__evidence">
        <summary>Technical evidence</summary>
        <div>{render_slot(@evidence)}</div>
      </details>
    </section>
    """
  end

  attr(:id, :string, required: true)
  attr(:entry, :map, required: true)
  slot(:evidence)

  @doc """
  Renders one immutable historical audit statement and its normalized facts.
  """
  def audit_entry(assigns) do
    entry = ControlPlanePresenter.normalize_audit_entry(assigns.entry)

    assigns =
      assigns
      |> assign(:id, require_text!(assigns.id, "audit entry id"))
      |> assign(:entry, entry)
      |> assign(:entry_evidence, audit_evidence(entry))

    ~H"""
    <article id={@id} class="obpt-audit-entry" aria-labelledby={"#{@id}-title"}>
      <header class="obpt-audit-entry__header">
        <h2 id={"#{@id}-title"} class="obpt-audit-entry__title">{@entry.sentence}</h2>
        <DataDisplay.status_pill domain={:operator_result} state={@entry.outcome} />
        <time datetime={@entry.occurred_datetime} class="obpt-audit-entry__time">
          {@entry.occurred_at}
        </time>
      </header>

      <DataDisplay.description_list id={"#{@id}-facts"}>
        <:item label="Actor">{@entry.actor}</:item>
        <:item label="Action">{@entry.action}</:item>
        <:item label="Target">{@entry.target}</:item>
        <:item label="Reason">{@entry.reason}</:item>
        <:item label="Source">{@entry.source}</:item>
        <:item label="Correlation">{@entry.correlation}</:item>
        <:item label="Outcome">{@entry.outcome}</:item>
      </DataDisplay.description_list>

      <details
        :if={@entry_evidence || @evidence != []}
        class="obpt-audit-entry__evidence"
      >
        <summary>Technical evidence</summary>
        <DataDisplay.code_block
          :if={@entry_evidence}
          id={"#{@id}-recorded-evidence"}
          label="Recorded audit evidence"
          content={@entry_evidence}
        />
        <div :if={@evidence != []} class="obpt-audit-entry__evidence-slot">
          {render_slot(@evidence)}
        </div>
      </details>
    </article>
    """
  end

  defp live_role(:off), do: nil
  defp live_role(:polite), do: "status"
  defp live_role(:assertive), do: "alert"

  defp filter_mode(mode) when mode in @filter_modes, do: mode
  defp filter_mode(_mode), do: raise(ArgumentError, "unsupported filter mode")

  defp filter_clear_href(clear_href, []) do
    case clear_href do
      nil -> nil
      value -> require_text!(value, "filter clear destination")
    end
  end

  defp filter_clear_href(clear_href, _active_filters),
    do: require_text!(clear_href, "filter clear destination")

  defp filter_disclosure_label(active_filters),
    do: "Filters (#{length(active_filters)} applied)"

  defp filter_dom_id(id, suffix), do: "#{id}-#{suffix}"

  defp severity_spec(severity) do
    %{
      label: humanize(severity),
      tone: severity,
      icon: severity_icon(severity),
      sr_prefix: "Attention severity"
    }
  end

  defp severity_icon(:neutral), do: :dot
  defp severity_icon(:info), do: :info
  defp severity_icon(:warning), do: :alert
  defp severity_icon(:danger), do: :alert

  defp blocker_kind_label(:current), do: "Current state"
  defp blocker_kind_label(:block_start_snapshot), do: "Block-start snapshot"

  defp blocker_empty_truth(:current, :complete, []),
    do: "No blockers are present in the complete current evidence."

  defp blocker_empty_truth(_state, _completeness, _blockers), do: nil

  defp blocker_evidence_copy(:current, :complete),
    do: "Current blocker evidence is complete."

  defp blocker_evidence_copy(:current, :partial),
    do: "Current blocker evidence is partial. Refresh the workflow before acting."

  defp blocker_evidence_copy(:current, :unknown),
    do: "Current blocker evidence is unknown. Refresh the workflow before acting."

  defp blocker_evidence_copy(:current, :unavailable),
    do: "Current blocker evidence is unavailable. Refresh the workflow or open Forensics."

  defp blocker_evidence_copy(:stale, _completeness),
    do: "Current blocker evidence is stale. Refresh the workflow before acting."

  defp blocker_evidence_copy(:unavailable, _completeness),
    do: "Current blocker evidence is unavailable. Refresh the workflow or open Forensics."

  defp blocker_evidence_copy(:permission_denied, _completeness),
    do: "Current blocker evidence is unavailable — requires operator role."

  defp audit_evidence(entry) do
    [presentation_evidence(entry.changes), presentation_evidence(entry.evidence)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
    |> case do
      "" -> nil
      evidence -> evidence
    end
  end

  defp presentation_evidence(nil), do: nil
  defp presentation_evidence(value) when is_binary(value), do: value

  defp presentation_evidence(value) when is_map(value) or is_list(value),
    do: inspect(value, pretty: false, limit: :infinity, printable_limit: :infinity)

  defp presentation_evidence(value), do: to_string(value)

  defp require_datetime!(value, field) do
    datetime = require_text!(value, field)

    case DateTime.from_iso8601(datetime) do
      {:ok, _parsed, _offset} -> datetime
      {:error, _reason} -> raise ArgumentError, "#{field} must be a valid ISO 8601 datetime"
    end
  end

  defp require_text!(value, field) when is_binary(value) do
    case String.trim(value) do
      "" -> raise ArgumentError, "#{field} must be non-empty text"
      text -> text
    end
  end

  defp require_text!(_value, field),
    do: raise(ArgumentError, "#{field} must be non-empty text")

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
