defmodule ObanPowertools.TelemetryTest do
  use ExUnit.Case, async: false

  @expected_contract %{
    measurement_keys: [:count],
    families: %{
      operator_action: [:action, :source],
      limiter: [:action, :blocker_code, :resource, :scope],
      cron: [:action, :source, :overlap_policy, :catch_up_policy],
      workflow: [:status, :state],
      lifeline: [:action, :incident_class, :target_type, :outcome, :archived_count, :pruned_count]
    }
  }

  test "publishes the telemetry public contract" do
    assert ObanPowertools.Telemetry.contract() == @expected_contract
  end

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

  test "emits cron events within documented metadata boundaries" do
    :telemetry.attach(
      "cron-handler",
      [:oban_powertools, :cron, :previewed],
      fn name, measurements, metadata, _config ->
        send(self(), {:cron_event, name, measurements, metadata})
      end,
      nil
    )

    metadata = %{
      action: "preview",
      source: "ops_ui",
      overlap_policy: "forbid",
      catch_up_policy: "all"
    }

    ObanPowertools.Telemetry.execute_cron_event(:previewed, %{count: 1}, metadata)

    assert_receive {:cron_event, [:oban_powertools, :cron, :previewed], %{count: 1}, ^metadata}
    assert Map.keys(metadata) |> Enum.sort() == Enum.sort(@expected_contract.families.cron)
  after
    :telemetry.detach("cron-handler")
  end

  test "emits lifeline events within documented metadata boundaries" do
    :telemetry.attach(
      "lifeline-handler",
      [:oban_powertools, :lifeline, :repair_completed],
      fn name, measurements, metadata, _config ->
        send(self(), {:lifeline_event, name, measurements, metadata})
      end,
      nil
    )

    metadata = %{
      action: "repair",
      incident_class: "workflow_stuck",
      target_type: "workflow",
      outcome: "resolved",
      archived_count: 2,
      pruned_count: 1
    }

    ObanPowertools.Telemetry.execute_lifeline_event(:repair_completed, %{count: 1}, metadata)

    assert_receive {:lifeline_event, [:oban_powertools, :lifeline, :repair_completed], %{count: 1},
                    ^metadata}

    assert Map.keys(metadata) |> Enum.sort() == Enum.sort(@expected_contract.families.lifeline)
  after
    :telemetry.detach("lifeline-handler")
  end
end
