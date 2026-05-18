defmodule ObanPowertools.Web.RouterTest do
  use ExUnit.Case, async: true

  test "oban_powertools_routes is available as a macro" do
    Code.ensure_loaded(ObanPowertools.Web.Router)
    assert Kernel.macro_exported?(ObanPowertools.Web.Router, :oban_powertools_routes, 1)
  end
end