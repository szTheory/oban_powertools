if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.CronLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{Audit, Cron, DisplayPolicy, Telemetry}
    alias ObanPowertools.Web.LiveAuth

    @impl true
    def mount(_params, _session, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(socket, :view_cron, %{type: :page, id: "cron"}) do
        :ok = DisplayPolicy.assert_configured!()

        {:ok,
         socket
         |> assign(:entries, Cron.list_entries(repo()))
         |> assign(:preview, nil)
         |> assign(:reason, "")
         |> assign(:error_message, nil)}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_event("preview", %{"action" => action, "entry" => entry_name}, socket) do
      entry = find_entry!(entry_name)
      resource = %{type: :cron_entry, id: entry.name}

      with :ok <-
             LiveAuth.authorize_action(socket, auth_action(action), resource,
               message: unauthorized_preview_message(action)
             ) do
        Telemetry.execute_operator_action(:previewed, %{count: 1}, %{
          action: action,
          source: entry.source
        })

        {:noreply,
         socket
         |> assign(:preview, %{action: action, entry: entry})
         |> assign(:error_message, nil)}
      else
        {:error, message} ->
          {:noreply,
           socket
           |> assign(:preview, nil)
           |> assign(:reason, "")
           |> assign(:error_message, message)}
      end
    end

    def handle_event("reason", %{"reason" => reason}, socket) do
      {:noreply, assign(socket, :reason, reason)}
    end

    def handle_event("cancel_preview", _params, socket) do
      {:noreply,
       socket |> assign(:preview, nil) |> assign(:reason, "") |> assign(:error_message, nil)}
    end

    def handle_event("confirm", _params, %{assigns: %{preview: nil}} = socket) do
      {:noreply, socket}
    end

    def handle_event("confirm", _params, socket) do
      %{action: action, entry: entry} = socket.assigns.preview
      resource = %{type: :cron_entry, id: entry.name}

      with :ok <- LiveAuth.authorize_action(socket, auth_action(action), resource),
           {:ok, principal} <- LiveAuth.principal_for_action(socket),
           {:ok, _result} <- perform_action(action, entry, principal, socket.assigns.reason) do
        {:noreply,
         socket
         |> assign(:preview, nil)
         |> assign(:reason, "")
         |> assign(:error_message, nil)
         |> assign(:entries, Cron.list_entries(repo()))}
      else
        {:error, message} when is_binary(message) ->
          {:noreply, assign(socket, :error_message, message)}

        {:error, reason} ->
          {:noreply, assign(socket, :error_message, inspect(reason))}
      end
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="space-y-6 p-6">
        <div>
          <h1 class="text-2xl font-semibold">Cron</h1>
          <p class="text-sm text-zinc-600">
            Code and Runtime ownership stay visible. Mutations stay preview-first.
          </p>
        </div>

        <p :if={@error_message} class="rounded border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          <%= @error_message %>
        </p>

        <div class="overflow-hidden rounded-lg border bg-white">
          <table class="min-w-full divide-y">
            <thead class="bg-slate-50 text-left text-sm">
              <tr>
                <th class="px-4 py-3 font-medium">Entry</th>
                <th class="px-4 py-3 font-medium">Source</th>
                <th class="px-4 py-3 font-medium">Policies</th>
                <th class="px-4 py-3 font-medium">State</th>
                <th class="px-4 py-3 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y text-sm">
              <tr :for={entry <- @entries}>
                <td class="px-4 py-3 font-medium"><%= entry.name %></td>
                <td class="px-4 py-3">
                  <span class="rounded border px-2 py-1"><%= source_label(entry.source) %></span>
                </td>
                <td class="px-4 py-3">
                  <div><%= overlap_label(entry.overlap_policy) %></div>
                  <div class="text-zinc-500"><%= catch_up_label(entry.catch_up_policy) %></div>
                </td>
                <td class="px-4 py-3"><%= if entry.paused_at, do: "Paused", else: "Runnable" %></td>
                <td class="px-4 py-3">
                  <div class="space-y-3">
                    <div :for={action <- entry_actions(entry, @current_actor)} class="space-y-1">
                      <button
                        type="button"
                        phx-click="preview"
                        phx-value-action={action.action}
                        phx-value-entry={entry.name}
                        disabled={not action.enabled?}
                        class={action_button_class(action)}
                      >
                        <%= action.label %>
                      </button>
                      <p :if={not action.enabled?} class="text-xs text-zinc-500">
                        <%= action.disabled_reason %>
                      </p>
                    </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div :if={@preview} class="rounded-lg border bg-slate-50 p-4">
          <h2 class="text-base font-semibold">Preview Action</h2>
          <p class="mt-2 text-sm">
            <%= preview_copy(@preview.action, @preview.entry) %>
          </p>
          <p class="mt-2 text-sm text-zinc-600">
            This action will be written to the Powertools audit trail with the acting operator and reason.
          </p>
          <p class="mt-2 text-sm">
            <strong>Actor:</strong> <%= preview_actor_label(@current_actor) %>
          </p>
          <label class="mt-4 block text-sm font-medium">
            Reason
            <input
              type="text"
              name="reason"
              value={@reason}
              phx-change="reason"
              class="mt-2 w-full rounded border px-3 py-2"
            />
          </label>
          <p class="mt-2 text-sm">
            <strong>Rendered Reason:</strong> <%= preview_reason(@reason) %>
          </p>
          <p :if={@error_message} class="mt-3 text-sm text-red-700"><%= @error_message %></p>
          <div class="mt-4 flex gap-3">
            <button type="button" phx-click="confirm" class="rounded bg-indigo-600 px-3 py-2 text-white">
              Confirm
            </button>
            <button type="button" phx-click="cancel_preview" class="rounded border px-3 py-2">
              Cancel
            </button>
          </div>
        </div>

        <div class="rounded-lg border bg-white p-4">
          <h2 class="text-base font-semibold">Recent Audit</h2>
          <ul class="mt-3 space-y-2 text-sm">
            <li :for={event <- recent_audit(@entries)}>
              <strong><%= event.action %></strong> <span class="text-zinc-500"><%= event.resource %></span>
            </li>
          </ul>
        </div>
      </div>
      """
    end

    defp perform_action("pause_cron_entry", entry, principal, reason),
      do: Cron.pause_entry(repo(), entry, principal.id, reason: blank_to_nil(reason))

    defp perform_action("resume_cron_entry", entry, principal, reason),
      do: Cron.resume_entry(repo(), entry, principal.id, reason: blank_to_nil(reason))

    defp perform_action("run_cron_entry", entry, principal, reason),
      do: Cron.run_now(repo(), entry, principal.id, reason: blank_to_nil(reason))

    defp find_entry!(entry_name) do
      Enum.find(Cron.list_entries(repo()), &(&1.name == entry_name)) || raise "entry not found"
    end

    defp auth_action("pause_cron_entry"), do: :pause_cron_entry
    defp auth_action("resume_cron_entry"), do: :resume_cron_entry
    defp auth_action("run_cron_entry"), do: :run_cron_entry

    defp preview_copy("pause_cron_entry", entry),
      do: "Pause #{entry.name}. New slots will stop claiming until you resume it."

    defp preview_copy("resume_cron_entry", entry),
      do: "Resume #{entry.name}. Eligible slots can begin claiming again."

    defp preview_copy("run_cron_entry", entry),
      do: "Run #{entry.name} now. This may enqueue work immediately based on overlap policy."

    defp entry_actions(entry, actor) do
      entry
      |> base_actions()
      |> Enum.map(fn action ->
        Map.put(
          action,
          :enabled?,
          ObanPowertools.Auth.authorization_outcome(
            actor,
            auth_action(action.action),
            %{type: :cron_entry, id: entry.name}
          ) == :ok
        )
      end)
      |> Enum.map(fn action ->
        Map.put(action, :disabled_reason, disabled_reason(action))
      end)
    end

    defp base_actions(%{paused_at: nil}) do
      [
        %{action: "pause_cron_entry", label: "Pause Cron Entry", emphasis: :secondary},
        %{action: "run_cron_entry", label: "Run Now", emphasis: :primary}
      ]
    end

    defp base_actions(_entry) do
      [
        %{action: "resume_cron_entry", label: "Resume Cron Entry", emphasis: :secondary},
        %{action: "run_cron_entry", label: "Run Now", emphasis: :primary}
      ]
    end

    defp disabled_reason(%{enabled?: true}), do: nil
    defp disabled_reason(%{action: "pause_cron_entry"}), do: unauthorized_preview_message("pause_cron_entry")
    defp disabled_reason(%{action: "resume_cron_entry"}), do: unauthorized_preview_message("resume_cron_entry")
    defp disabled_reason(%{action: "run_cron_entry"}), do: unauthorized_preview_message("run_cron_entry")

    defp action_button_class(%{enabled?: true, emphasis: :primary}),
      do: "rounded bg-indigo-600 px-3 py-2 text-white"

    defp action_button_class(%{enabled?: true}),
      do: "rounded border px-3 py-2"

    defp action_button_class(_action),
      do: "cursor-not-allowed rounded border border-zinc-200 px-3 py-2 text-zinc-400"

    defp unauthorized_preview_message("pause_cron_entry"),
      do: "You do not have permission to pause cron entries."

    defp unauthorized_preview_message("resume_cron_entry"),
      do: "You do not have permission to resume cron entries."

    defp unauthorized_preview_message("run_cron_entry"),
      do: "You do not have permission to run cron entries now."

    defp preview_actor_label(actor) do
      case ObanPowertools.Auth.audit_principal(actor) do
        {:ok, principal} ->
          DisplayPolicy.actor_label(principal, %{surface: :cron, section: :preview})

        {:error, _reason} ->
          "Audit principal unavailable"
      end
    end

    defp preview_reason(reason) do
      DisplayPolicy.reason(reason, %{surface: :cron, section: :preview})
    end

    defp recent_audit(entries) do
      entry_names = MapSet.new(Enum.map(entries, &"cron_entry:#{&1.name}"))

      Audit.list_all(repo: repo())
      |> Enum.filter(&MapSet.member?(entry_names, &1.resource))
      |> Enum.take(5)
    end

    defp source_label("code"), do: "Code"
    defp source_label(_), do: "Runtime"
    defp overlap_label("queue_one"), do: "Queue One"
    defp overlap_label(policy), do: Phoenix.Naming.humanize(policy)
    defp catch_up_label("latest"), do: "Latest Only"
    defp catch_up_label(policy), do: Phoenix.Naming.humanize(policy)
    defp blank_to_nil(""), do: nil
    defp blank_to_nil(value), do: value
    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
