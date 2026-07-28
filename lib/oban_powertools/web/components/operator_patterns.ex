defmodule ObanPowertools.Web.Components.OperatorPatterns do
  @moduledoc """
  Stateless operator meta-components composed from Powertools Primitives, Forms,
  and DataDisplay components.

  Parent LiveViews own authorization, data loading, mutations, navigation, and
  durable evidence. These components render finite presentation truth only.
  """

  use Phoenix.Component

  alias ObanPowertools.Web.Components.{DataDisplay, Forms, Primitives}
  alias ObanPowertools.Web.ControlPlanePresenter
  alias Phoenix.LiveView.JS

  @severities ~w[neutral info warning danger]a
  @completeness_values ~w[complete partial unknown unavailable]a
  @live_values ~w[off polite assertive]a
  @evidence_states ~w[current stale unavailable permission_denied]a
  @filter_modes ~w[submit instant]a
  @confirmation_intents ~w[warning danger]a
  @confirmation_states ~w[preview submitting partial failed expired drifted consumed]a
  @detail_variants ~w[adaptive inline drawer]a
  @detail_states ~w[loading empty ready unavailable permission_denied error]a

  attr(:id, :string, required: true)
  attr(:intent, :atom, required: true, values: @confirmation_intents)
  attr(:state, :atom, required: true, values: @confirmation_states)
  attr(:title, :string, required: true)
  attr(:object_label, :string, required: true)
  attr(:scope, :string, required: true)
  attr(:consequence, :string, required: true)
  attr(:reversibility, :string, required: true)
  attr(:support_boundary, :string, required: true)
  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:bulk_count, :integer, default: nil)
  attr(:bulk_scope, :string, default: nil)
  attr(:confirm_label, :string, required: true)
  attr(:dismiss_label, :string, required: true)
  attr(:pending_copy, :string, required: true)
  attr(:logical_fallback_id, :string, required: true)
  attr(:submit_event, :string, required: true)
  attr(:dismiss_event, :string, required: true)
  attr(:dismissible, :boolean, default: true)
  attr(:progress, :map, default: nil)
  attr(:results, :list, default: [])

  slot(:recovery)
  slot(:audit)
  slot(:support_details)

  @doc """
  Renders consequence-first confirmation from parent-owned preview, form, and result truth.

  The component never authorizes or executes an action. Parents create the preview,
  revalidate submitted fields and frozen scope, normalize results, and remove the dialog
  after an authoritative clean success.
  """
  def confirm_action_dialog(assigns) do
    state = confirmation_state(assigns.state)
    intent = confirmation_intent(assigns.intent)
    id = require_text!(assigns.id, "confirmation id")
    dismissible = confirmation_dismissible?(state, assigns.dismissible)

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:state, state)
      |> assign(:intent, intent)
      |> assign(:title, require_text!(assigns.title, "confirmation title"))
      |> assign(:object_label, require_text!(assigns.object_label, "confirmation object"))
      |> assign(:scope, require_text!(assigns.scope, "confirmation scope"))
      |> assign(
        :consequence,
        require_text!(assigns.consequence, "confirmation consequence")
      )
      |> assign(
        :reversibility,
        require_text!(assigns.reversibility, "confirmation reversibility")
      )
      |> assign(
        :support_boundary,
        require_text!(assigns.support_boundary, "confirmation support boundary")
      )
      |> assign(:bulk_scope, confirmation_bulk_scope(assigns.bulk_count, assigns.bulk_scope))
      |> assign(
        :confirm_label,
        require_action_label!(assigns.confirm_label, "confirmation action")
      )
      |> assign(
        :dismiss_label,
        require_action_label!(assigns.dismiss_label, "safe dismiss action")
      )
      |> assign(:pending_copy, require_text!(assigns.pending_copy, "confirmation pending copy"))
      |> assign(
        :logical_fallback_id,
        require_text!(assigns.logical_fallback_id, "confirmation focus fallback")
      )
      |> assign(:submit_event, require_text!(assigns.submit_event, "confirmation submit event"))
      |> assign(
        :dismiss_event,
        require_text!(assigns.dismiss_event, "confirmation dismiss event")
      )
      |> assign(:dismissible, dismissible)
      |> assign(:dismiss_command, dismiss_confirmation(assigns.dismiss_event, dismissible))
      |> assign(:aria_busy, if(state == :submitting, do: "true"))
      |> assign(:form_visible, state in [:preview, :submitting])
      |> assign(:fields_disabled, state == :submitting)
      |> assign(:progress_measurement, confirmation_progress(assigns.progress))
      |> assign(:results, ControlPlanePresenter.normalize_operator_results(assigns.results))
      |> assign(:result_copy, confirmation_result_copy(state))
      |> assign(:stale_copy, confirmation_stale_copy(state))

    ~H"""
    <.focus_wrap id={"#{@id}-focus-wrap"}>
      <section
        id={"#{@id}-dialog"}
        class="obpt-confirm-action"
        data-obpt-confirm-state={@state}
        data-obpt-confirm-intent={@intent}
        data-obpt-focus-fallback={@logical_fallback_id}
        role="dialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-title"}
        aria-busy={@aria_busy}
        phx-window-keydown={@dismiss_command}
        phx-key={if(@dismissible, do: "Escape")}
      >
        <div class="obpt-confirm-action__overlay" aria-hidden="true"></div>
        <div class="obpt-confirm-action__dialog" tabindex="0">
          <header class="obpt-confirm-action__header">
            <p class="obpt-confirm-action__object">{@object_label}</p>
            <h2
              id={"#{@id}-title"}
              class="obpt-confirm-action__title"
              tabindex="-1"
              phx-mounted={focus_confirmation_title(@id)}
            >
              {@title}
            </h2>
          </header>

          <div class="obpt-confirm-action__preview">
            <section class="obpt-confirm-action__scope" aria-labelledby={"#{@id}-scope-title"}>
              <h3 id={"#{@id}-scope-title"}>Scope</h3>
              <p>{@scope}</p>
              <p :if={@bulk_scope} class="obpt-confirm-action__bulk-scope">{@bulk_scope}</p>
            </section>

            <section
              class="obpt-confirm-action__consequence"
              data-obpt-intent={@intent}
              aria-labelledby={"#{@id}-consequence-title"}
            >
              <h3 id={"#{@id}-consequence-title"}>Consequence</h3>
              <p>{@consequence}</p>
            </section>

            <section
              class="obpt-confirm-action__reversibility"
              aria-labelledby={"#{@id}-reversibility-title"}
            >
              <h3 id={"#{@id}-reversibility-title"}>Reversibility</h3>
              <p>{@reversibility}</p>
            </section>

            <section
              class="obpt-confirm-action__support"
              aria-labelledby={"#{@id}-support-title"}
            >
              <h3 id={"#{@id}-support-title"}>Support boundary</h3>
              <p>{@support_boundary}</p>
              <div :if={@support_details != []} class="obpt-confirm-action__support-details">
                {render_slot(@support_details)}
              </div>
            </section>
          </div>

          <.form
            :if={@form_visible}
            for={@form}
            id={"#{@id}-form"}
            class="obpt-confirm-action__form"
            phx-submit={@submit_event}
          >
            <Forms.textarea
              field={@form[:reason]}
              label="Reason"
              hint="Explain why this action is needed. Do not enter secrets."
              required
              disabled={@fields_disabled}
            />
            <Forms.input
              :if={@bulk_count}
              field={@form[:confirmation_count]}
              label={"Type #{@bulk_count} to confirm"}
              required
              disabled={@fields_disabled}
            />

            <div :if={@state == :submitting} class="obpt-confirm-action__busy" role="status">
              <div :if={@progress_measurement} class="obpt-confirm-action__progress">
                <DataDisplay.progress_bar
                  id={"#{@id}-progress"}
                  label={@pending_copy}
                  value={@progress_measurement.value}
                  max={@progress_measurement.max}
                />
              </div>
              <div :if={!@progress_measurement} class="obpt-confirm-action__spinner">
                <Primitives.spinner label={@pending_copy} />
                <p>{@pending_copy}</p>
              </div>
              <p :if={!@dismissible} class="obpt-confirm-action__accepted-copy">
                This action has been accepted and can no longer be canceled.
              </p>
            </div>

            <div class="obpt-confirm-action__actions">
              <Primitives.button
                :if={@dismissible}
                type="button"
                variant={:neutral}
                phx-click={@dismiss_command}
              >
                {@dismiss_label}
              </Primitives.button>
              <Primitives.button
                type="submit"
                variant={@intent}
                disabled={@fields_disabled}
                phx-disable-with={@pending_copy}
              >
                {@confirm_label}
              </Primitives.button>
            </div>
          </.form>

          <section
            :if={@result_copy}
            class="obpt-confirm-action__result"
            aria-labelledby={"#{@id}-result-heading"}
          >
            <h3
              id={"#{@id}-result-heading"}
              class="obpt-confirm-action__result-heading"
              tabindex="-1"
              phx-mounted={focus_confirmation_result(@id)}
            >
              {@result_copy}
            </h3>

            <ol class="obpt-confirm-action__result-list">
              <li
                :for={result <- @results}
                id={"#{@id}-#{result.id}"}
                class="obpt-confirm-action__result-row"
                data-obpt-result={result.outcome}
              >
                <div class="obpt-confirm-action__result-status">
                  <DataDisplay.status_pill domain={:operator_result} state={result.outcome} />
                </div>
                <p class="obpt-confirm-action__result-object">{result.object_label}</p>
                <p class="obpt-confirm-action__result-message">{result.message}</p>
                <p :if={result.recovery} class="obpt-confirm-action__result-recovery">
                  {result.recovery}
                </p>
                <Primitives.link :if={result.audit_href} href={result.audit_href}>
                  Open audit evidence
                </Primitives.link>
              </li>
            </ol>

            <div :if={@recovery != []} class="obpt-confirm-action__recovery">
              {render_slot(@recovery)}
            </div>
            <div :if={@audit != []} class="obpt-confirm-action__audit">
              {render_slot(@audit)}
            </div>
            <div :if={@dismissible} class="obpt-confirm-action__actions">
              <Primitives.button type="button" variant={:neutral} phx-click={@dismiss_command}>
                {@dismiss_label}
              </Primitives.button>
            </div>
          </section>

          <section
            :if={@stale_copy}
            class="obpt-confirm-action__recovery obpt-confirm-action__recovery--stale"
            aria-labelledby={"#{@id}-result-heading"}
          >
            <h3
              id={"#{@id}-result-heading"}
              class="obpt-confirm-action__result-heading"
              tabindex="-1"
              phx-mounted={focus_confirmation_result(@id)}
            >
              {@stale_copy}
            </h3>
            <div :if={@recovery != []} class="obpt-confirm-action__recovery-action">
              {render_slot(@recovery)}
            </div>
            <div :if={@audit != []} class="obpt-confirm-action__audit">
              {render_slot(@audit)}
            </div>
            <div :if={@dismissible} class="obpt-confirm-action__actions">
              <Primitives.button type="button" variant={:neutral} phx-click={@dismiss_command}>
                {@dismiss_label}
              </Primitives.button>
            </div>
          </section>
        </div>
      </section>
    </.focus_wrap>
    """
  end

  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:close_label, :string, required: true)
  attr(:open, :boolean, required: true)
  attr(:variant, :atom, default: :adaptive, values: @detail_variants)
  attr(:state, :atom, required: true, values: @detail_states)
  attr(:resource, :string, required: true)
  attr(:logical_fallback_id, :string, required: true)
  attr(:close_event, :string, required: true)
  attr(:loaded_announcement, :string, default: nil)
  attr(:full_details_href, :string, default: nil)

  slot(:body, required: true)
  slot(:actions)
  slot(:evidence)

  @doc """
  Renders one adaptive native-dialog tree from parent-owned selection and content truth.

  Callers must close or leave modal detail before opening a confirmation dialog. The
  component never fetches, authorizes, changes URL state, or renders nested dialogs.
  """
  def detail_surface(assigns) do
    id = require_text!(assigns.id, "detail surface id")
    state = detail_state(assigns.state)

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:title, require_text!(assigns.title, "detail surface title"))
      |> assign(
        :close_label,
        require_action_label!(assigns.close_label, "detail surface close action")
      )
      |> assign(:variant, detail_variant(assigns.variant))
      |> assign(:state, state)
      |> assign(:resource, require_text!(assigns.resource, "detail surface resource"))
      |> assign(
        :logical_fallback_id,
        require_text!(assigns.logical_fallback_id, "detail surface focus fallback")
      )
      |> assign(:close_event, require_text!(assigns.close_event, "detail surface close event"))
      |> assign(:loaded_announcement, optional_text(assigns.loaded_announcement))
      |> assign(:full_details_href, optional_text(assigns.full_details_href))
      |> assign(:requested, if(assigns.open, do: "open", else: "closed"))

    ~H"""
    <dialog
      id={@id}
      class="obpt-detail-surface"
      open={@open}
      aria-labelledby={"#{@id}-title"}
      data-obpt-detail-surface
      data-obpt-detail-variant={@variant}
      data-obpt-detail-requested={@requested}
      data-obpt-detail-mode
      data-obpt-detail-state={@state}
      data-obpt-detail-fallback={@logical_fallback_id}
      data-obpt-focus-fallback={@logical_fallback_id}
      phx-mounted={JS.ignore_attributes("open")}
    >
      <header class="obpt-detail-surface__header">
        <h2 id={"#{@id}-title"} class="obpt-detail-surface__title" tabindex="-1">
          {@title}
        </h2>
        <Primitives.icon_button
          label={@close_label}
          phx-click={@close_event}
          data-obpt-detail-close
        >
          <span aria-hidden="true">×</span>
        </Primitives.icon_button>
      </header>

      <div
        id={"#{@id}-body"}
        class="obpt-detail-surface__body"
        data-obpt-detail-body
        tabindex="0"
      >
        <div :if={@state == :ready} class="obpt-detail-surface__content">
          {render_slot(@body)}
        </div>
        <DataDisplay.state_message
          :if={@state != :ready}
          id={"#{@id}-state"}
          state={@state}
          resource={@resource}
        />
        <p
          :if={@state == :ready && @loaded_announcement}
          id={"#{@id}-status"}
          class="obpt-detail-surface__status"
          role="status"
          aria-live="polite"
          aria-atomic="true"
        >
          {@loaded_announcement}
        </p>
        <span
          :if={@state != :ready || !@loaded_announcement}
          id={"#{@id}-status"}
          class="obpt-detail-surface__status obpt-sr-only"
        >
          {humanize(@state)}
        </span>
      </div>

      <section :if={@evidence != []} class="obpt-detail-surface__evidence" aria-label="Technical evidence">
        {render_slot(@evidence)}
      </section>

      <footer :if={@actions != [] || @full_details_href} class="obpt-detail-surface__footer">
        <div :if={@actions != []} class="obpt-detail-surface__actions">
          {render_slot(@actions)}
        </div>
        <Primitives.link :if={@full_details_href} href={@full_details_href}>
          Open full details
        </Primitives.link>
      </footer>
    </dialog>
    """
  end

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
  attr(:submit_label, :string, default: "Apply filters")
  attr(:clear_href, :string, default: nil)

  slot(:fields, required: true)
  slot(:advanced_fields)

  @doc """
  Renders one stateless filter form while the parent retains valid or invalid draft,
  applied, and URL truth.
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
      |> assign(:submit_label, require_text!(assigns.submit_label, "filter submit label"))
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
            <Primitives.button type="submit" variant={:primary}>{@submit_label}</Primitives.button>
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
            <div :if={blocker.affected_scope}>
              <dt>Affected scope</dt>
              <dd>{blocker.affected_scope}</dd>
            </div>
            <div>
              <dt>Clearing condition</dt>
              <dd>{blocker.clearing_condition}</dd>
            </div>
            <div>
              <dt>Evidence source</dt>
              <dd>{blocker.evidence_source}</dd>
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
      |> assign(:recorded_at_label, Map.get(entry, :recorded_at_label, "Recorded at"))
      |> assign(:entry_evidence, audit_evidence(entry))

    ~H"""
    <article
      id={@id}
      class="obpt-audit-entry"
      data-obpt-audit-outcome={@entry.outcome_state}
      aria-labelledby={"#{@id}-title"}
    >
      <header class="obpt-audit-entry__header">
        <h2 id={"#{@id}-title"} class="obpt-audit-entry__title">{@entry.sentence}</h2>
        <DataDisplay.status_pill domain={:operator_result} state={@entry.outcome_state} />
        <p class="obpt-audit-entry__time">
          <span>{@recorded_at_label}</span>
          <time datetime={@entry.occurred_datetime}>{@entry.occurred_at}</time>
        </p>
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

  defp confirmation_state(state) when state in @confirmation_states, do: state
  defp confirmation_state(_state), do: raise(ArgumentError, "unsupported confirmation state")

  defp confirmation_intent(intent) when intent in @confirmation_intents, do: intent
  defp confirmation_intent(_intent), do: raise(ArgumentError, "unsupported confirmation intent")

  defp detail_variant(variant) when variant in @detail_variants, do: variant
  defp detail_variant(_variant), do: raise(ArgumentError, "unsupported detail surface variant")

  defp detail_state(state) when state in @detail_states, do: state
  defp detail_state(_state), do: raise(ArgumentError, "unsupported detail surface state")

  defp confirmation_dismissible?(:submitting, dismissible) when is_boolean(dismissible), do: false

  defp confirmation_dismissible?(_state, dismissible) when is_boolean(dismissible),
    do: dismissible

  defp confirmation_dismissible?(_state, _dismissible),
    do: raise(ArgumentError, "confirmation dismissible must be boolean")

  defp confirmation_bulk_scope(nil, nil), do: nil

  defp confirmation_bulk_scope(count, scope) when is_integer(count) and count > 0,
    do: require_text!(scope, "confirmation bulk scope")

  defp confirmation_bulk_scope(_count, _scope),
    do: raise(ArgumentError, "confirmation bulk count must be a positive integer")

  defp confirmation_progress(nil), do: nil

  defp confirmation_progress(progress) when is_map(progress) do
    value = presentation_map_value(progress, :value)
    max = presentation_map_value(progress, :max)

    if is_integer(value) and is_integer(max) and max > 0 and value >= 0 and value <= max do
      %{value: value, max: max}
    else
      raise ArgumentError, "confirmation progress must contain a real processed value and total"
    end
  end

  defp confirmation_progress(_progress),
    do: raise(ArgumentError, "confirmation progress must be a presentation map")

  defp presentation_map_value(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key))
    end
  end

  defp confirmation_result_copy(:partial),
    do:
      "Retry requests finished with mixed results. Review failed and skipped jobs before trying again."

  defp confirmation_result_copy(:failed),
    do: "The requested action failed. Review each result and recovery step before trying again."

  defp confirmation_result_copy(_state), do: nil

  defp confirmation_stale_copy(:expired),
    do: "This preview expired. Create a new preview before continuing."

  defp confirmation_stale_copy(:drifted),
    do:
      "This preview is out of date because the job changed. Create a new preview before retrying."

  defp confirmation_stale_copy(:consumed),
    do: "This preview was already used. Create a new preview to run the action again."

  defp confirmation_stale_copy(_state), do: nil

  defp focus_confirmation_title(id), do: JS.focus(to: "##{id}-title")
  defp focus_confirmation_result(id), do: JS.focus(to: "##{id}-result-heading")

  defp dismiss_confirmation(_event, false), do: nil

  defp dismiss_confirmation(event, true) do
    event
    |> require_text!("confirmation dismiss event")
    |> JS.push()
    |> JS.pop_focus()
  end

  defp require_action_label!(value, field) do
    label = require_text!(value, field)

    if String.downcase(label) in ["confirm", "cancel"] do
      raise ArgumentError, "#{field} must name the action or retained safe state"
    else
      label
    end
  end

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
    do: "Runnable — complete current evidence contains no blocking conditions."

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

  defp optional_text(nil), do: nil
  defp optional_text(value), do: require_text!(value, "optional detail surface text")

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
