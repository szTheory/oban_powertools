if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.LiveAuth do
    @moduledoc false

    import Phoenix.Component, only: [assign: 3]
    import Phoenix.LiveView

    alias ObanPowertools.Auth

    def on_mount(:default, _params, session, socket) do
      actor = Auth.current_actor(session)
      {:cont, assign(socket, :current_actor, actor)}
    end

    def authorize_page(socket, action, resource) do
      if Auth.authorize(Map.get(socket.assigns, :current_actor), action, resource) do
        {:ok, socket}
      else
        {:error, redirect(socket, to: "/")}
      end
    end

    def authorize_action(socket, action, resource, opts \\ []) do
      if Auth.authorize(Map.get(socket.assigns, :current_actor), action, resource) do
        :ok
      else
        {:error, Keyword.get(opts, :message, "You are not authorized to perform this action.")}
      end
    end
  end
end
