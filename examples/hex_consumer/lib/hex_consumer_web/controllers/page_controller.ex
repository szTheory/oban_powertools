defmodule HexConsumerWeb.PageController do
  use HexConsumerWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: "/ops/jobs")
  end
end
