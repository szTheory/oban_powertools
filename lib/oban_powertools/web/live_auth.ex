if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.LiveAuth do
    @moduledoc false

    import Phoenix.Component, only: [assign: 3]
    import Phoenix.LiveView

    alias ObanPowertools.Auth
    alias ObanPowertools.Web.ControlPlanePresenter

    @missing_principal_message "Oban Powertools could not derive a durable audit principal for this action."
    @audit_consequence "One immutable operator event will be written."
    @mutation_errors %{
      preview_not_found: "preview_not_available",
      preview_not_available: "preview_not_available",
      preview_drifted: "preview_drifted",
      preview_expired: "preview_expired",
      preview_consumed: "preview_consumed",
      reason_required: "reason_required",
      reason_too_short: "reason_too_short",
      mutation_conflict: "mutation_conflict",
      unauthorized: "unauthorized"
    }
    @permission_messages %{
      pause_cron_entry:
        "Permission: read-only. You can inspect this Powertools-native cron entry, but you do not have permission to preview or execute this Audited action.",
      resume_cron_entry:
        "Permission: read-only. You can inspect this Powertools-native cron entry, but you do not have permission to preview or execute this Audited action.",
      run_cron_entry:
        "Permission: read-only. You can inspect this Powertools-native cron entry, but you do not have permission to preview or execute this Audited action.",
      preview_repair:
        "Permission: read-only. You can inspect this Powertools-native incident, but you do not have permission to preview this Audited action.",
      execute_repair:
        "Permission: read-only. You can inspect this Powertools-native preview, but you do not have permission to execute this Audited action."
    }
    @page_read_only_banners %{
      cron:
        "Permission: read-only. Powertools-native cron stays visible, but preview, reason, and Audited action controls stay disabled until you receive broader permission.",
      lifeline:
        "Permission: read-only. Powertools-native incident evidence stays visible, but preview, reason, and Audited action controls stay disabled until you receive broader permission.",
      audit:
        "Permission: read-only. This page is the cross-surface audit destination. Powertools-native pages keep preview, reason, and local audit evidence close to the acted-on resource.",
      workflows:
        "Permission: read-only. Diagnose workflow causality here, but use Powertools-native pages for preview, reason, and Audited action controls."
    }

    def on_mount(:default, _params, session, socket) do
      actor = Auth.current_actor(session)
      {:cont, assign(socket, :current_actor, actor)}
    end

    def authorize_page(socket, action, resource) do
      case Auth.authorization_outcome(Map.get(socket.assigns, :current_actor), action, resource) do
        :ok ->
          {:ok, socket}

        {:error, _reason} ->
          {:error, redirect(socket, to: "/")}
      end
    end

    def authorize_action(socket, action, resource, opts \\ []) do
      case Auth.authorization_outcome(Map.get(socket.assigns, :current_actor), action, resource) do
        :ok ->
          :ok

        {:error, _reason} ->
          {:error, Keyword.get(opts, :message, permission_message(action))}
      end
    end

    def principal_for_action(socket, opts \\ []) do
      case Auth.audit_principal(Map.get(socket.assigns, :current_actor)) do
        {:ok, principal} ->
          {:ok, principal}

        {:error, _reason} ->
          {:error, Keyword.get(opts, :message, @missing_principal_message)}
      end
    end

    def authorized?(actor, action, resource) do
      Auth.authorization_outcome(actor, action, resource) == :ok
    end

    def any_authorized?(actor, checks) do
      Enum.any?(checks, fn {action, resource} -> authorized?(actor, action, resource) end)
    end

    def permission_message(action) do
      Map.get(@permission_messages, action, @mutation_errors[:unauthorized])
    end

    def mutation_error(reason) do
      Map.get(@mutation_errors, reason, inspect(reason))
    end

    def audit_consequence_copy, do: @audit_consequence <> " " <> ControlPlanePresenter.native_banner()

    def page_read_only_banner(surface) do
      Map.fetch!(@page_read_only_banners, surface)
    end
  end
end
