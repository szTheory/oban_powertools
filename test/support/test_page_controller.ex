defmodule ObanPowertools.TestPageController do
  use Phoenix.Controller, formats: [:html]

  def home(conn, _params) do
    Plug.Conn.send_resp(conn, 200, "home")
  end
end
