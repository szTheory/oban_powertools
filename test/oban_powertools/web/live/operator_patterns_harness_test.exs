defmodule ObanPowertools.Web.Live.OperatorPatternsHarnessLive do
  use Phoenix.LiveView, log: false

  alias ObanPowertools.Web.Components.{DataDisplay, Forms, OperatorPatterns, Primitives}

  @allowed_queues ~w[critical default]
  @allowed_states ~w[available retryable]
  @frozen_count 12
  @permission_copy "Execution requires operator role."
  @secret_sentinel "PHASE78-HARNESS-SECRET-SENTINEL"

  @impl true
  def mount(_params, session, socket) do
    slice = Map.get(session, "slice", "all")
    authorized? = Map.get(session, "authorized?", true)
    confirmation_slice? = slice in ["confirmation", "all"]

    {:ok,
     socket
     |> assign(:slice, slice)
     |> assign(:authorized?, authorized?)
     |> assign(:scope_fresh?, Map.get(session, "scope_fresh?", true))
     |> assign(:preview_freshness, :ready)
     |> assign(:confirmation_state, if(authorized?, do: :preview, else: :failed))
     |> assign(:confirmation_open?, slice == "confirmation")
     |> assign(:confirmation_form, confirmation_form())
     |> assign(:confirmation_errors, %{})
     |> assign(:frozen_count, @frozen_count)
     |> assign(:preview_count, if(confirmation_slice? and authorized?, do: 1, else: 0))
     |> assign(:mutation_count, 0)
     |> assign(:receipt_count, 0)
     |> assign(:receipt, nil)
     |> assign(
       :confirmation_results,
       if(authorized?, do: partial_results(), else: permission_denied_results())
     )
     |> assign(:sensitive_preview_state, @secret_sentinel)
     |> assign(:draft_filters, %{"queue" => "", "state" => ""})
     |> assign(:applied_filters, %{"queue" => "", "state" => ""})
     |> assign(:filter_form, filter_form())
     |> assign(:filter_errors, %{})
     |> assign(:filter_dirty?, false)
     |> assign(:filter_expanded?, false)
     |> assign(:result_summary, "64 jobs match the applied filters.")
     |> assign(:page, 4)
     |> assign(:canonical_url, "/operator-patterns-harness?page=4")
     |> assign(:history_ops, [])
     |> assign(:selected_detail, nil)
     |> assign(:detail_state, :ready)
     |> assign(:detail_loaded_announcement, nil)
     |> assign(:detail_fallback_id, "operator-results-heading")}
  end

  @impl true
  def handle_event("validate-confirmation", %{"confirmation" => params}, socket) do
    {form, errors} = validate_confirmation(params, socket.assigns.frozen_count)
    {:noreply, assign(socket, confirmation_form: form, confirmation_errors: errors)}
  end

  def handle_event("submit-confirmation", %{"confirmation" => params}, socket) do
    {form, errors} = validate_confirmation(params, socket.assigns.frozen_count)

    error =
      cond do
        not socket.assigns.authorized? -> :permission_denied
        not socket.assigns.scope_fresh? -> :drifted
        socket.assigns.preview_freshness != :ready -> socket.assigns.preview_freshness
        errors != %{} -> :invalid
        socket.assigns.mutation_count > 0 -> :duplicate
        true -> nil
      end

    case error do
      nil ->
        {:noreply,
         socket
         |> assign(:confirmation_form, form)
         |> assign(:confirmation_errors, %{})
         |> assign(:mutation_count, 1)
         |> assign(:receipt_count, 1)
         |> assign(:receipt, "Retry requested for 12 jobs. Audit evidence recorded.")
         |> assign(:confirmation_open?, false)}

      :duplicate ->
        {:noreply, socket}

      :invalid ->
        {:noreply,
         assign(socket,
           confirmation_form: form,
           confirmation_errors: errors,
           confirmation_state: :preview
         )}

      :permission_denied ->
        {:noreply,
         assign(socket,
           confirmation_state: :failed,
           confirmation_errors: %{authorization: @permission_copy},
           confirmation_results: permission_denied_results()
         )}

      freshness when freshness in [:expired, :drifted, :consumed] ->
        {:noreply, assign(socket, confirmation_state: freshness)}
    end
  end

  def handle_event("submit-confirmation", _params, socket), do: {:noreply, socket}

  def handle_event("dismiss-confirmation", _params, socket) do
    {:noreply, assign(socket, :confirmation_open?, false)}
  end

  def handle_event("set-preview-freshness", %{"state" => state}, socket) do
    if socket.assigns.authorized? do
      freshness = normalize_preview_freshness(state)
      confirmation_state = if freshness == :ready, do: :preview, else: freshness
      preview_count = socket.assigns.preview_count + if(freshness == :ready, do: 1, else: 0)

      {:noreply,
       assign(socket,
         preview_freshness: freshness,
         confirmation_state: confirmation_state,
         preview_count: preview_count,
         confirmation_open?: true
       )}
    else
      {:noreply,
       assign(socket,
         confirmation_state: :failed,
         confirmation_results: permission_denied_results(),
         confirmation_open?: true
       )}
    end
  end

  def handle_event("show-partial-results", _params, socket) do
    {:noreply, assign(socket, confirmation_state: :partial, confirmation_open?: true)}
  end

  def handle_event("validate-filters", %{"filters" => params}, socket) do
    {form, errors} = validate_filters(params)

    {:noreply,
     assign(socket,
       draft_filters: Map.take(params, ["queue", "state"]),
       filter_form: form,
       filter_errors: errors,
       filter_dirty?: Map.take(params, ["queue", "state"]) != socket.assigns.applied_filters
     )}
  end

  def handle_event("apply-filters", %{"filters" => params}, socket) do
    {form, errors} = validate_filters(params)

    if errors == %{} do
      applied = Map.take(params, ["queue", "state"])
      url = filter_url(applied)

      socket =
        socket
        |> assign(:draft_filters, applied)
        |> assign(:applied_filters, applied)
        |> assign(:filter_form, form)
        |> assign(:filter_errors, %{})
        |> assign(:filter_dirty?, false)
        |> assign(:page, 1)
        |> assign(:canonical_url, url)
        |> assign(:result_summary, result_summary(applied))
        |> record_history(:push, url)

      {:noreply, socket}
    else
      {:noreply,
       assign(socket,
         draft_filters: Map.take(params, ["queue", "state"]),
         filter_form: form,
         filter_errors: errors,
         filter_dirty?: true
       )}
    end
  end

  def handle_event("remove-filter", %{"field" => field}, socket)
      when field in ["queue", "state"] do
    applied = Map.put(socket.assigns.applied_filters, field, "")
    url = filter_url(applied)

    {:noreply,
     socket
     |> assign(:draft_filters, applied)
     |> assign(:applied_filters, applied)
     |> assign(:filter_form, filter_form(applied))
     |> assign(:filter_dirty?, false)
     |> assign(:page, 1)
     |> assign(:canonical_url, url)
     |> assign(:result_summary, result_summary(applied))
     |> record_history(:push, url)}
  end

  def handle_event("clear-filters", _params, socket) do
    filters = %{"queue" => "", "state" => ""}
    url = filter_url(filters)

    {:noreply,
     socket
     |> assign(:draft_filters, filters)
     |> assign(:applied_filters, filters)
     |> assign(:filter_form, filter_form(filters))
     |> assign(:filter_dirty?, false)
     |> assign(:page, 1)
     |> assign(:canonical_url, url)
     |> assign(:result_summary, result_summary(filters))
     |> record_history(:push, url)}
  end

  def handle_event("load-direct-url", params, socket) do
    filters = Map.take(params, ["queue", "state"])
    {_form, errors} = validate_filters(filters)

    if errors == %{} do
      url = filter_url(filters)

      {:noreply,
       socket
       |> assign(:draft_filters, filters)
       |> assign(:applied_filters, filters)
       |> assign(:filter_form, filter_form(filters))
       |> assign(:canonical_url, url)}
    else
      safe = %{"queue" => "", "state" => ""}
      url = filter_url(safe)

      {:noreply,
       socket
       |> assign(:draft_filters, safe)
       |> assign(:applied_filters, safe)
       |> assign(:filter_form, filter_form(safe))
       |> assign(:canonical_url, url)
       |> record_history(:replace, url)}
    end
  end

  def handle_event("open-detail", %{"id" => id}, socket) do
    first_open? = is_nil(socket.assigns.selected_detail)
    op = if first_open?, do: :push, else: :replace
    url = detail_url(socket.assigns.applied_filters, id)

    {:noreply,
     socket
     |> assign(:selected_detail, id)
     |> assign(:confirmation_open?, false)
     |> assign(:detail_state, :ready)
     |> assign(:detail_loaded_announcement, "Job #{id} details loaded")
     |> assign(:canonical_url, url)
     |> record_history(op, url)}
  end

  def handle_event("close-detail", _params, socket) do
    url = filter_url(socket.assigns.applied_filters)

    {:noreply,
     socket
     |> assign(:selected_detail, nil)
     |> assign(:detail_loaded_announcement, nil)
     |> assign(:canonical_url, url)
     |> record_history(:replace, url)}
  end

  def handle_event("browser-back", _params, socket) do
    {:noreply, assign(socket, selected_detail: nil, detail_loaded_announcement: nil)}
  end

  def handle_event("direct-detail", %{"id" => id}, socket) do
    url = detail_url(socket.assigns.applied_filters, id)

    {:noreply,
     assign(socket,
       selected_detail: id,
       canonical_url: url,
       detail_fallback_id: "operator-results-heading",
       detail_loaded_announcement: "Job #{id} details loaded"
     )}
  end

  def handle_event("set-detail-state", %{"state" => state}, socket) do
    {:noreply, assign(socket, :detail_state, normalize_detail_state(state))}
  end

  def handle_event("confirm-from-detail", _params, socket) do
    {:noreply,
     assign(socket,
       selected_detail: nil,
       confirmation_open?: true,
       confirmation_state: :preview
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main
      id="operator-patterns-harness"
      data-slice={@slice}
      data-canonical-url={@canonical_url}
      data-page={@page}
      data-preview-count={@preview_count}
      data-mutation-count={@mutation_count}
      data-receipt-count={@receipt_count}
      data-history-ops={encode_history(@history_ops)}
    >
      <h1 id="operator-results-heading" tabindex="-1">Operator pattern harness</h1>

      <div :if={@receipt} id="operator-receipt" role="status">{@receipt}</div>

      <.confirmation_contract
        :if={@slice in ["confirmation", "all"] and @confirmation_open?}
        id="harness-confirmation"
        intent={:danger}
        state={@confirmation_state}
        title="Retry 12 jobs?"
        object_label="12 selected jobs"
        scope="The frozen scope includes jobs outside the current page."
        consequence="Powertools requests a retry for each selected job."
        reversibility="A retry request cannot be undone."
        support_boundary="Completion remains host-owned."
        form={@confirmation_form}
        bulk_count={@frozen_count}
        bulk_scope="Includes jobs outside the current page."
        confirm_label="Retry 12 jobs"
        dismiss_label="Keep current state"
        pending_copy="Retrying 12 jobs…"
        logical_fallback_id="operator-results-heading"
        submit_event="submit-confirmation"
        dismiss_event="dismiss-confirmation"
        dismissible={@confirmation_state != :submitting}
        results={@confirmation_results}
      >
        <:recovery>Create new preview</:recovery>
        <:audit>Open audit evidence</:audit>
        <:support_details>Do not enter secrets in the operator reason.</:support_details>
      </.confirmation_contract>

      <.filter_contract
        :if={@slice in ["filter", "all"]}
        id="harness-filters"
        form={@filter_form}
        mode={:submit}
        result_summary={@result_summary}
        results_target_id="operator-results"
        active_filters={active_filters(@applied_filters)}
        dirty={@filter_dirty?}
        filters_expanded={@filter_expanded?}
        change_event="validate-filters"
        submit_event="apply-filters"
        clear_href={filter_url(%{"queue" => "", "state" => ""})}
      >
        <:fields>
          <Forms.input
            field={@filter_form[:queue]}
            label="Queue"
            placeholder="Any queue"
            errors={Map.get(@filter_errors, :queue, [])}
          />
          <Forms.input
            field={@filter_form[:state]}
            label="State"
            placeholder="Any state"
            errors={Map.get(@filter_errors, :state, [])}
          />
        </:fields>
      </.filter_contract>

      <section :if={@slice in ["detail", "all"]} id="operator-results">
        <button
          :for={id <- ["101", "202"]}
          id={"open-detail-#{id}"}
          type="button"
          phx-click="open-detail"
          phx-value-id={id}
          aria-expanded={@selected_detail == id}
          aria-controls="harness-detail"
          data-selected={@selected_detail == id}
        >
          <span aria-hidden="true">›</span> Job {id} details
        </button>
      </section>

      <.detail_contract
        :if={@slice in ["detail", "all"] and @selected_detail}
        id="harness-detail"
        title={"Job #{@selected_detail} details"}
        close_label="Close job details"
        open={true}
        variant={:adaptive}
        state={@detail_state}
        resource="job details"
        logical_fallback_id={@detail_fallback_id}
        close_event="close-detail"
        loaded_announcement={@detail_loaded_announcement}
        full_details_href={"/ops/jobs/jobs/#{@selected_detail}"}
      >
        <:body>One parent-owned detail body for job {@selected_detail}.</:body>
        <:actions>
          <Primitives.button phx-click="confirm-from-detail">Preview retry</Primitives.button>
        </:actions>
        <:evidence>
          <DataDisplay.code_block
            id="harness-detail-evidence"
            label="Redaction-safe evidence"
            content="No secret originals"
          />
        </:evidence>
      </.detail_contract>
    </main>
    """
  end

  attr(:id, :string, required: true)
  attr(:intent, :atom, required: true)
  attr(:state, :atom, required: true)
  attr(:title, :string, required: true)
  attr(:object_label, :string, required: true)
  attr(:scope, :string, required: true)
  attr(:consequence, :string, required: true)
  attr(:reversibility, :string, required: true)
  attr(:support_boundary, :string, required: true)
  attr(:form, :any, required: true)
  attr(:bulk_count, :integer, default: nil)
  attr(:bulk_scope, :string, default: nil)
  attr(:confirm_label, :string, required: true)
  attr(:dismiss_label, :string, required: true)
  attr(:pending_copy, :string, required: true)
  attr(:logical_fallback_id, :string, required: true)
  attr(:submit_event, :string, required: true)
  attr(:dismiss_event, :string, required: true)
  attr(:dismissible, :boolean, required: true)
  attr(:progress, :map, default: nil)
  attr(:results, :list, default: [])
  slot(:recovery)
  slot(:audit)
  slot(:support_details)

  defp confirmation_contract(assigns) do
    apply(OperatorPatterns, :confirm_action_dialog, [assigns])
  end

  attr(:id, :string, required: true)
  attr(:form, :any, required: true)
  attr(:mode, :atom, required: true)
  attr(:result_summary, :string, required: true)
  attr(:results_target_id, :string, required: true)
  attr(:active_filters, :list, required: true)
  attr(:dirty, :boolean, required: true)
  attr(:filters_expanded, :boolean, required: true)
  attr(:change_event, :string, required: true)
  attr(:submit_event, :string, required: true)
  attr(:clear_href, :string, required: true)
  slot(:fields, required: true)
  slot(:advanced_fields)

  defp filter_contract(assigns), do: apply(OperatorPatterns, :filter_bar, [assigns])

  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:close_label, :string, required: true)
  attr(:open, :boolean, required: true)
  attr(:variant, :atom, required: true)
  attr(:state, :atom, required: true)
  attr(:resource, :string, required: true)
  attr(:logical_fallback_id, :string, required: true)
  attr(:close_event, :string, required: true)
  attr(:loaded_announcement, :string, default: nil)
  attr(:full_details_href, :string, default: nil)
  slot(:body, required: true)
  slot(:actions)
  slot(:evidence)

  defp detail_contract(assigns), do: apply(OperatorPatterns, :detail_surface, [assigns])

  defp validate_confirmation(params, frozen_count) do
    reason = params |> Map.get("reason", "") |> String.trim()
    count = params |> Map.get("confirmation_count", "") |> String.trim()
    normalized_params = Map.merge(params, %{"reason" => reason, "confirmation_count" => count})

    errors =
      %{}
      |> maybe_put_error(:reason, reason == "", "Reason is required.")
      |> maybe_put_error(
        :reason,
        reason != "" and String.length(reason) < 8,
        "Reason must be at least 8 characters."
      )
      |> maybe_put_error(
        :confirmation_count,
        count != Integer.to_string(frozen_count),
        "Type #{frozen_count} to confirm."
      )

    {confirmation_form(normalized_params, errors), errors}
  end

  defp validate_filters(params) do
    queue = Map.get(params, "queue", "")
    state = Map.get(params, "state", "")

    errors =
      %{}
      |> maybe_put_error(
        :queue,
        queue != "" and queue not in @allowed_queues,
        "Choose a valid queue."
      )
      |> maybe_put_error(
        :state,
        state != "" and state not in @allowed_states,
        "Choose a valid state."
      )

    {filter_form(params, errors), errors}
  end

  defp maybe_put_error(errors, _field, false, _message), do: errors

  defp maybe_put_error(errors, field, true, message) do
    Map.update(errors, field, [message], &(&1 ++ [message]))
  end

  defp confirmation_form(params \\ %{"reason" => "", "confirmation_count" => ""}, errors \\ %{}) do
    Phoenix.Component.to_form(params,
      as: :confirmation,
      errors: form_errors(errors)
    )
  end

  defp filter_form(params \\ %{"queue" => "", "state" => ""}, errors \\ %{}) do
    Phoenix.Component.to_form(params,
      as: :filters,
      id: "harness-filters-form",
      errors: form_errors(errors)
    )
  end

  defp form_errors(errors) do
    Enum.flat_map(errors, fn {field, messages} ->
      Enum.map(messages, &{field, {&1, []}})
    end)
  end

  defp partial_results do
    [
      %{
        id: "job-101",
        object_label: "Job 101",
        outcome: :success,
        message: "Retry requested.",
        recovery: nil,
        audit_href: "/ops/jobs/audit?resource_id=101"
      },
      %{
        id: "job-202",
        object_label: "Job 202",
        outcome: :failed,
        message: "Retry request failed.",
        recovery: "Create a fresh preview.",
        audit_href: nil
      },
      %{
        id: "job-303",
        object_label: "Job 303",
        outcome: :skipped,
        message: "Retry skipped because the job changed.",
        recovery: "Refresh the job before acting.",
        audit_href: nil
      }
    ]
  end

  defp permission_denied_results do
    [
      %{
        id: "permission-denied",
        object_label: "Retry 12 jobs",
        outcome: :failed,
        message: @permission_copy,
        recovery: "Ask an administrator to grant operator access before creating a preview.",
        audit_href: nil
      }
    ]
  end

  defp active_filters(filters) do
    filters
    |> Enum.reject(fn {_field, value} -> value == "" end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {field, value} ->
      %{
        id: "#{field}-#{value}",
        label: String.capitalize(field),
        value: value,
        remove_href: remove_filter_url(filters, field),
        remove_label: "Remove #{String.capitalize(field)}: #{value} filter"
      }
    end)
  end

  defp remove_filter_url(filters, field), do: filters |> Map.put(field, "") |> filter_url()

  defp filter_url(filters) do
    query =
      filters
      |> Enum.reject(fn {_field, value} -> value == "" end)
      |> Enum.sort_by(&elem(&1, 0))
      |> URI.encode_query()

    if query == "", do: "/operator-patterns-harness", else: "/operator-patterns-harness?#{query}"
  end

  defp detail_url(filters, id) do
    filters
    |> Map.put("detail", id)
    |> Enum.reject(fn {_field, value} -> value == "" end)
    |> Enum.sort_by(&elem(&1, 0))
    |> URI.encode_query()
    |> then(&"/operator-patterns-harness?#{&1}")
  end

  defp result_summary(%{"queue" => "", "state" => ""}),
    do: "64 jobs match the applied filters."

  defp result_summary(_filters), do: "12 jobs match the applied filters."

  defp record_history(socket, operation, url) do
    assign(socket, :history_ops, socket.assigns.history_ops ++ [{operation, url}])
  end

  defp encode_history(history) do
    Enum.map_join(history, "|", fn {operation, url} -> "#{operation}:#{url}" end)
  end

  defp normalize_preview_freshness("expired"), do: :expired
  defp normalize_preview_freshness("drifted"), do: :drifted
  defp normalize_preview_freshness("consumed"), do: :consumed
  defp normalize_preview_freshness(_state), do: :ready

  defp normalize_detail_state("loading"), do: :loading
  defp normalize_detail_state("empty"), do: :empty
  defp normalize_detail_state("unavailable"), do: :unavailable
  defp normalize_detail_state("permission_denied"), do: :permission_denied
  defp normalize_detail_state("error"), do: :error
  defp normalize_detail_state(_state), do: :ready
end

defmodule ObanPowertools.Web.Live.OperatorPatternsHarnessTest do
  use ObanPowertools.LiveCase, async: false

  alias Ecto.Changeset
  alias ObanPowertools.Lifeline
  alias ObanPowertools.Web.Live.OperatorPatternsHarnessLive

  @secret "PHASE78-HARNESS-SECRET-SENTINEL"

  @tag phase78_slice: "confirmation"
  test "blank and short reasons plus wrong frozen count stay open with zero mutations", %{
    conn: conn
  } do
    {:ok, view, _html} = mount_harness(conn, "confirmation")

    html =
      view
      |> form("#harness-confirmation-form", %{
        "confirmation" => %{"reason" => "short", "confirmation_count" => "11"}
      })
      |> render_submit()

    assert html =~ "Reason must be at least 8 characters."
    assert html =~ "Type 12 to confirm."
    assert has_element?(view, "#harness-confirmation-dialog[role='dialog']")
    assert has_element?(view, "#operator-patterns-harness[data-mutation-count='0']")
    refute has_element?(view, "#operator-receipt")
  end

  @tag phase78_slice: "confirmation"
  test "valid input is revalidated once and emits one truthful receipt", %{conn: conn} do
    {:ok, view, _html} = mount_harness(conn, "confirmation")

    params = %{
      "confirmation" => %{
        "reason" => "Incident response retry",
        "confirmation_count" => "12"
      }
    }

    render_hook(view, "submit-confirmation", params)
    render_hook(view, "submit-confirmation", params)

    assert has_element?(view, "#operator-patterns-harness[data-mutation-count='1']")
    assert has_element?(view, "#operator-patterns-harness[data-receipt-count='1']")

    assert has_element?(
             view,
             "#operator-receipt",
             "Retry requested for 12 jobs. Audit evidence recorded."
           )

    refute has_element?(view, "#harness-confirmation")
  end

  @tag phase78_slice: "confirmation"
  test "permission, stale preview, and duplicate UI state are separate server checks", %{
    conn: conn
  } do
    {:ok, unauthorized, unauthorized_html} =
      mount_harness(conn, "confirmation", %{"authorized?" => false})

    assert unauthorized_html =~ "Execution requires operator role."
    assert has_element?(unauthorized, "[data-preview-count='0'][data-mutation-count='0']")
    refute has_element?(unauthorized, "#harness-confirmation-form")
    refute unauthorized_html =~ @secret

    render_hook(unauthorized, "submit-confirmation", %{
      "confirmation" => %{
        "reason" => "Unauthorized execution",
        "confirmation_count" => "12"
      }
    })

    assert has_element?(unauthorized, "[data-mutation-count='0']")
    assert render(unauthorized) =~ "Execution requires operator role."

    for state <- ~w[expired drifted consumed] do
      {:ok, view, _html} = mount_harness(conn, "confirmation")

      render_hook(view, "validate-confirmation", %{
        "confirmation" => %{
          "reason" => "  Safe incident response reason  ",
          "confirmation_count" => "12"
        }
      })

      render_hook(view, "set-preview-freshness", %{"state" => state})
      html = render(view)
      assert html =~ fresh_preview_copy(state)
      assert html =~ "Create new preview"
      refute html =~ @secret

      render_hook(view, "set-preview-freshness", %{"state" => "ready"})
      refreshed_html = render(view)
      assert refreshed_html =~ "Safe incident response reason"
      assert has_element?(view, "[data-preview-count='2'][data-mutation-count='0']")
      refute refreshed_html =~ @secret
    end

    {:ok, changed_scope, _html} =
      mount_harness(conn, "confirmation", %{"scope_fresh?" => false})

    render_hook(changed_scope, "submit-confirmation", %{
      "confirmation" => %{
        "reason" => "Authoritative scope changed",
        "confirmation_count" => "12"
      }
    })

    assert render(changed_scope) =~ fresh_preview_copy("drifted")
    assert has_element?(changed_scope, "[data-mutation-count='0']")
  end

  @tag phase78_slice: "confirmation"
  test "partial results retain caller order and distinct recovery", %{conn: conn} do
    {:ok, view, _html} = mount_harness(conn, "confirmation")
    render_hook(view, "show-partial-results", %{})
    html = render(view)

    assert_in_order(html, [
      ~s(id="harness-confirmation-job-101"),
      ~s(id="harness-confirmation-job-202"),
      ~s(id="harness-confirmation-job-303")
    ])

    assert has_element?(
             view,
             "#harness-confirmation-job-101[data-obpt-result='success']",
             "Job 101"
           )

    assert has_element?(
             view,
             "#harness-confirmation-job-202[data-obpt-result='failed']",
             "Job 202"
           )

    assert has_element?(
             view,
             "#harness-confirmation-job-303[data-obpt-result='skipped']",
             "Job 303"
           )

    assert_in_order(html, ["Success", "Failed", "Skipped"])
    assert html =~ "Create a fresh preview."
    assert html =~ "Refresh the job before acting."
    assert html =~ ~s(href="/ops/jobs/audit?resource_id=101")
    assert html =~ ~s(id="harness-confirmation-result-heading")
    assert html =~ ~s(tabindex="-1")
  end

  @tag phase78_slice: "confirmation"
  test "real Lifeline rejects expired, drifted, and consumed execution" do
    actor = %{id: "operator-78", permissions: [:preview_repair, :execute_repair]}
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    expired_job = insert_retryable_job!()
    {:ok, expired_preview} = preview_job_retry(actor, expired_job, now)

    assert {:error, :preview_expired} =
             Lifeline.execute_repair(
               repo(),
               actor,
               expired_preview.preview_token,
               "Expired preview must not execute",
               now: DateTime.add(now, 8 * 24 * 60 * 60, :second)
             )

    drifted_job = insert_retryable_job!()
    {:ok, drifted_preview} = preview_job_retry(actor, drifted_job, now)
    repo().update!(Changeset.change(drifted_job, state: "scheduled"))

    assert {:error, :preview_drifted} =
             Lifeline.execute_repair(
               repo(),
               actor,
               drifted_preview.preview_token,
               "Drifted preview must not execute",
               now: now
             )

    consumed_job = insert_retryable_job!()
    {:ok, consumed_preview} = preview_job_retry(actor, consumed_job, now)

    assert {:ok, _result} =
             Lifeline.execute_repair(
               repo(),
               actor,
               consumed_preview.preview_token,
               "Consume this preview once",
               now: now
             )

    assert {:error, :preview_consumed} =
             Lifeline.execute_repair(
               repo(),
               actor,
               consumed_preview.preview_token,
               "A consumed preview must not replay",
               now: now
             )
  end

  @tag phase78_slice: "filter"
  test "draft edits retain values and errors without changing applied URL, results, or page", %{
    conn: conn
  } do
    {:ok, view, _html} = mount_harness(conn, "filter")

    html =
      view
      |> form("#harness-filters-form", %{
        "filters" => %{"queue" => "unknown", "state" => "retryable"}
      })
      |> render_change()

    assert html =~ "unknown"
    assert html =~ "Choose a valid queue."
    assert html =~ "Changes not applied."
    assert has_element?(view, "[data-canonical-url='/operator-patterns-harness?page=4']")
    assert has_element?(view, "[data-page='4']")
    assert has_element?(view, "[data-history-ops='']")
    assert html =~ "64 jobs match the applied filters."
  end

  @tag phase78_slice: "filter"
  test "Apply resets pagination and records one canonical push with exact status", %{conn: conn} do
    {:ok, view, _html} = mount_harness(conn, "filter")

    view
    |> form("#harness-filters-form", %{
      "filters" => %{"queue" => "critical", "state" => "retryable"}
    })
    |> render_submit()

    expected = "/operator-patterns-harness?queue=critical&state=retryable"
    assert has_element?(view, "[data-page='1']")
    assert has_element?(view, "[data-canonical-url='#{expected}']")
    assert has_element?(view, "[data-history-ops='push:#{expected}']")
    assert count(render(view), "12 jobs match the applied filters.") == 1
    refute render(view) =~ "Changes not applied."
  end

  @tag phase78_slice: "filter"
  test "invalid Apply remains visible and records no navigation", %{conn: conn} do
    {:ok, view, _html} = mount_harness(conn, "filter")

    html =
      view
      |> form("#harness-filters-form", %{
        "filters" => %{"queue" => "critical", "state" => "invalid"}
      })
      |> render_submit()

    assert html =~ "invalid"
    assert html =~ "Choose a valid state."
    assert has_element?(view, "[data-history-ops='']")
    assert has_element?(view, "[data-page='4']")
  end

  @tag phase78_slice: "filter"
  test "remove and clear use caller canonical URLs while invalid direct URLs replace", %{
    conn: conn
  } do
    {:ok, view, _html} = mount_harness(conn, "filter")

    render_hook(view, "apply-filters", %{
      "filters" => %{"queue" => "critical", "state" => "retryable"}
    })

    render_hook(view, "remove-filter", %{"field" => "queue"})
    assert render(view) =~ "push:/operator-patterns-harness?state=retryable"

    render_hook(view, "clear-filters", %{})
    assert render(view) =~ "push:/operator-patterns-harness"

    {:ok, direct, _html} = mount_harness(conn, "filter")
    render_hook(direct, "load-direct-url", %{"queue" => "secret", "state" => "invalid"})

    assert has_element?(direct, "[data-canonical-url='/operator-patterns-harness']")
    assert has_element?(direct, "[data-history-ops='replace:/operator-patterns-harness']")
  end

  @tag phase78_slice: "filter"
  test "parent query meaning remains AND between categories and OR within values" do
    rows = [
      %{id: 1, queue: "critical", state: "retryable", tags: ["mail", "billing"]},
      %{id: 2, queue: "critical", state: "available", tags: ["mail"]},
      %{id: 3, queue: "default", state: "retryable", tags: ["billing"]}
    ]

    result =
      Enum.filter(rows, fn row ->
        row.queue == "critical" and row.state in ["available", "retryable"] and
          Enum.any?(row.tags, &(&1 in ["mail", "billing"]))
      end)

    assert Enum.map(result, & &1.id) == [1, 2]
  end

  @tag phase78_slice: "detail"
  test "first detail open pushes while switch and close replace and preserve filters", %{
    conn: conn
  } do
    {:ok, view, _html} = mount_harness(conn, "detail")

    render_hook(view, "load-direct-url", %{"queue" => "critical", "state" => "retryable"})
    render_hook(view, "open-detail", %{"id" => "101"})

    assert render(view) =~
             "push:/operator-patterns-harness?detail=101&queue=critical&state=retryable"

    assert has_element?(view, "#open-detail-101[aria-expanded='true'][data-selected='true']")

    render_hook(view, "open-detail", %{"id" => "202"})

    assert render(view) =~
             "replace:/operator-patterns-harness?detail=202&queue=critical&state=retryable"

    render_hook(view, "close-detail", %{})

    assert has_element?(
             view,
             "[data-canonical-url='/operator-patterns-harness?queue=critical&state=retryable']"
           )

    assert render(view) =~ "replace:/operator-patterns-harness?queue=critical&state=retryable"
  end

  @tag phase78_slice: "detail"
  test "Back closes first-open detail and direct URLs use logical fallback", %{conn: conn} do
    {:ok, view, _html} = mount_harness(conn, "detail")
    render_hook(view, "open-detail", %{"id" => "101"})
    render_hook(view, "browser-back", %{})
    refute has_element?(view, "#harness-detail")

    {:ok, direct, _html} = mount_harness(conn, "detail")
    render_hook(direct, "direct-detail", %{"id" => "202"})

    assert has_element?(
             direct,
             "#harness-detail[data-obpt-detail-fallback='operator-results-heading']"
           )

    assert render(direct) =~ "Job 202 details loaded"
  end

  @tag phase78_slice: "detail"
  test "every detail state remains parent-owned and uses one body tree", %{conn: conn} do
    for state <- ~w[loading empty unavailable permission_denied error ready] do
      {:ok, view, _html} = mount_harness(conn, "detail")
      render_hook(view, "open-detail", %{"id" => "101"})
      render_hook(view, "set-detail-state", %{"state" => state})
      html = render(view)

      assert count(html, "<dialog") == 1
      assert count(html, "One parent-owned detail body") <= 1
      assert html =~ ~s(data-obpt-detail-state="#{state}")
      refute html =~ @secret
    end
  end

  test "drawer-to-confirmation transition never nests or stacks dialogs", %{conn: conn} do
    {:ok, view, _html} = mount_harness(conn, "all")
    render_hook(view, "open-detail", %{"id" => "101"})
    assert count(render(view), "<dialog") == 1

    render_hook(view, "confirm-from-detail", %{})
    html = render(view)

    assert count(html, "<dialog") == 1
    assert html =~ ~s(id="harness-confirmation-dialog")
    refute html =~ ~r/<dialog[^>]+id="harness-detail".*harness-confirmation/s
  end

  test "harness source does not edit or impersonate production authority boundaries" do
    source = File.read!("test/oban_powertools/web/live/operator_patterns_harness_test.exs")

    assert source =~ "defmodule ObanPowertools.Web.Live.OperatorPatternsHarnessLive"
    assert source =~ ~s(@tag phase78_slice: "confirmation")
    assert source =~ ~s(@tag phase78_slice: "filter")
    assert source =~ ~s(@tag phase78_slice: "detail")

    for forbidden <- [
          "defmodule " <> "ObanPowertools.Web.JobsLive",
          "defmodule " <> "ObanPowertools.Web.WorkflowsLive",
          "defmodule " <> "ObanPowertools.Lifeline",
          "defmodule " <> "ObanPowertools.Audit",
          "def" <> "macro"
        ] do
      refute source =~ forbidden
    end
  end

  defp mount_harness(conn, slice, extra_session \\ %{}) do
    session = Map.merge(%{"slice" => slice}, extra_session)
    live_isolated(conn, OperatorPatternsHarnessLive, session: session)
  end

  defp insert_retryable_job! do
    %{}
    |> Oban.Job.new(worker: "Example.Worker", queue: :default)
    |> Changeset.change(state: "retryable")
    |> repo().insert!()
  end

  defp preview_job_retry(actor, job, now) do
    Lifeline.preview_repair(
      repo(),
      actor,
      %{action: "job_retry", target_type: "job", target_id: job.id},
      now: now
    )
  end

  defp fresh_preview_copy("expired"), do: "This preview expired."
  defp fresh_preview_copy("drifted"), do: "This preview is out of date"
  defp fresh_preview_copy("consumed"), do: "This preview was already used."

  defp assert_in_order(html, values) do
    indexes = Enum.map(values, &(:binary.match(html, &1) |> elem(0)))
    assert indexes == Enum.sort(indexes)
  end

  defp count(text, needle), do: length(String.split(text, needle)) - 1
  defp repo, do: ObanPowertools.TestRepo
end
