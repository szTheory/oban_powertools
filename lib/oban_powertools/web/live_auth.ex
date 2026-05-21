if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.LiveAuth do
    @moduledoc false

    import Phoenix.Component, only: [assign: 3]
    import Phoenix.LiveView

    alias ObanPowertools.Auth

    @missing_principal_message "Oban Powertools could not derive a durable audit principal for this action."

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
          {:error, Keyword.get(opts, :message, "You are not authorized to perform this action.")}
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
  end
end
