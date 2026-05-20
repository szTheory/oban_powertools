defmodule ObanPowertools.TestLayouts do
  use Phoenix.Component

  attr(:inner_content, :any, required: true)

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <body><%= @inner_content %></body>
    </html>
    """
  end
end
