defmodule ObanPowertools.Web.ThemeShell do
  @moduledoc false

  use Phoenix.Component

  alias ObanPowertools.Web.Assets

  attr(:inner_content, :any, required: true)

  def live(assigns) do
    ~H"""
    <link phx-track-static rel="stylesheet" href={Assets.path(:css)} />
    <div
      id="oban-powertools"
      class="obpt-root"
      data-obpt-theme="system"
      data-obpt-effective-theme="light"
      data-obpt-motion="safe"
    >
      <script type="text/javascript" src={Assets.path(:js)}></script>
      <main class="obpt-shell" data-obpt-shell>
        <%= @inner_content %>
      </main>
    </div>
    """
  end
end
