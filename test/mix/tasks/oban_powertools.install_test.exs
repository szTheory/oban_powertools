defmodule Mix.Tasks.ObanPowertools.InstallTest do
  use ExUnit.Case

  test "defines an igniter task" do
    Code.ensure_loaded?(Mix.Tasks.ObanPowertools.Install)
    assert function_exported?(Mix.Tasks.ObanPowertools.Install, :igniter, 1)
  end
end