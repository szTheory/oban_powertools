# The brand book LiveView and its route only exist when dev_routes is enabled
# (dev/test). Guard the whole test module with the same compile_env check the
# router macro and the module body use, so this file compiles only where the
# route is mounted and never under MIX_ENV=prod.
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  defmodule ObanPowertools.Web.Dev.BrandBookLiveTest do
    use ObanPowertools.LiveCase, async: true

    test "renders the brand book at the dev-only route", %{conn: conn} do
      {:ok, _live, html} = live(conn, "/ops/jobs/_brand_book")

      assert html =~ "Brand Book"
      assert html =~ "D-01"
      assert html =~ "explain, then act"
    end
  end
end
