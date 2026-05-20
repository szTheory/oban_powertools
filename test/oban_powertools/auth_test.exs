defmodule ObanPowertools.AuthTest do
  use ExUnit.Case, async: true

  test "defines expected callbacks" do
    Code.ensure_loaded(ObanPowertools.Auth)
    callbacks = ObanPowertools.Auth.behaviour_info(:callbacks)
    assert {:current_actor, 1} in callbacks
    assert {:can_perform_action?, 3} in callbacks
  end
end
