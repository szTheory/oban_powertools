defmodule ObanPowertools.TelemetryTest do
  use ExUnit.Case, async: true

  test "emits operator action complete event" do
    :telemetry.attach(
      "test-handler",
      [:oban_powertools, :operator_action, :complete],
      fn name, measurements, metadata, _config ->
        send(self(), {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    ObanPowertools.Telemetry.execute_operator_action(:complete, %{count: 1}, %{action: "test"})

    assert_receive {:telemetry_event, [:oban_powertools, :operator_action, :complete], %{count: 1}, %{action: "test"}}
  after
    :telemetry.detach("test-handler")
  end
end