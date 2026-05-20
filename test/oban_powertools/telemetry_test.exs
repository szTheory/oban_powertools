defmodule ObanPowertools.TelemetryTest do
  use ExUnit.Case, async: false

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

    assert_receive {:telemetry_event, [:oban_powertools, :operator_action, :complete],
                    %{count: 1}, %{action: "test"}}
  after
    :telemetry.detach("test-handler")
  end

  test "emits limiter blocked event" do
    :telemetry.attach(
      "limiter-handler",
      [:oban_powertools, :limiter, :blocked],
      fn name, measurements, metadata, _config ->
        send(self(), {:limiter_event, name, measurements, metadata})
      end,
      nil
    )

    ObanPowertools.Telemetry.execute_limiter_event(:blocked, %{count: 1}, %{
      action: "blocked",
      blocker_code: "limit_reached",
      resource: "user-api",
      scope: "partitioned"
    })

    assert_receive {:limiter_event, [:oban_powertools, :limiter, :blocked], %{count: 1},
                    %{
                      action: "blocked",
                      blocker_code: "limit_reached",
                      resource: "user-api",
                      scope: "partitioned"
                    }}
  after
    :telemetry.detach("limiter-handler")
  end

  test "emits workflow events" do
    :telemetry.attach(
      "workflow-handler",
      [:oban_powertools, :workflow, :step_completed],
      fn name, measurements, metadata, _config ->
        send(self(), {:workflow_event, name, measurements, metadata})
      end,
      nil
    )

    ObanPowertools.Telemetry.execute_workflow_event(:step_completed, %{count: 1}, %{status: "completed"})

    assert_receive {:workflow_event, [:oban_powertools, :workflow, :step_completed], %{count: 1},
                    %{status: "completed"}}
  after
    :telemetry.detach("workflow-handler")
  end
end
