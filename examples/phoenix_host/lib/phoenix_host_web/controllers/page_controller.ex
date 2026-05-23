defmodule PhoenixHostWeb.PageController do
  use PhoenixHostWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
