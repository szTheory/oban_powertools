defmodule ObanPowertools.ChainProgressionTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Callback

  describe "callback event vocabulary" do
    test "accepts chain step succeeded callbacks" do
      changeset =
        Callback.changeset(%Callback{}, %{
          event: "chain.step_succeeded",
          dedupe_key: "chain.step_succeeded:chain-1:0:123",
          status: "pending",
          payload: %{"event" => "chain.step_succeeded"},
          attempts: 0
        })

      assert changeset.valid?
    end
  end
end
