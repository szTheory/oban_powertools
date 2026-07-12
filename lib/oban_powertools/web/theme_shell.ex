defmodule ObanPowertools.Web.ThemeShell do
  @moduledoc false

  use Phoenix.Component

  alias ObanPowertools.Web.Assets
  alias ObanPowertools.Web.Components.AppShell

  attr(:inner_content, :any, required: true)

  def live(assigns) do
    assigns =
      assigns
      |> assign_new(:current_path, fn -> nil end)
      |> assign_new(:current_uri, fn -> nil end)
      |> assign_new(:current_actor, fn -> nil end)

    ~H"""
    <link phx-track-static rel="stylesheet" href={Assets.path(:css)} />
    <div
      id="oban-powertools"
      class="obpt-root"
      data-obpt-theme="system"
      data-obpt-effective-theme="light"
      data-obpt-motion="safe"
    >
      <script phx-track-static type="text/javascript" src={Assets.path(:js)}></script>
      <AppShell.app_shell
        current_path={@current_path}
        current_uri={@current_uri}
        current_actor={@current_actor}
      >
        <%= @inner_content %>
      </AppShell.app_shell>
    </div>
    """
  end
end
