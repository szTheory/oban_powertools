defmodule PhoenixHostWeb.ErrorJSONTest do
  use PhoenixHostWeb.ConnCase, async: true

  test "renders 404" do
    assert PhoenixHostWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert PhoenixHostWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
