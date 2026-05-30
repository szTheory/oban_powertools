defmodule ObanPowertools.TelemetryTest do
  use ExUnit.Case, async: false

  @expected_contract %{
    measurement_keys: [:count],
    families: %{
      operator_action: [:action, :source],
      limiter: [:action, :blocker_code, :resource, :scope],
      cron: [:action, :source, :overlap_policy, :catch_up_policy],
      workflow: %{
        step_completed: [:outcome, :terminal_cause, :semantics_version],
        step_unblocked: [:scope, :state, :semantics_version],
        cascade_cancelled: [:scope, :outcome, :terminal_cause, :semantics_version],
        workflow_terminal: [:state, :outcome, :terminal_cause, :semantics_version]
      },
      lifeline: [:action, :incident_class, :target_type, :outcome, :archived_count, :pruned_count]
    }
  }

  test "publishes the telemetry public contract" do
    assert ObanPowertools.Telemetry.contract() == @expected_contract
  end

  test "metrics/0 returns a non-empty list of Telemetry.Metrics structs" do
    metrics = ObanPowertools.Telemetry.metrics()
    assert is_list(metrics)
    assert length(metrics) > 0

    valid_types = [Telemetry.Metrics.Counter, Telemetry.Metrics.Sum]
    assert Enum.all?(metrics, fn m -> m.__struct__ in valid_types end)
  end

  test "metrics/0 tags stay within frozen contract" do
    contract = ObanPowertools.Telemetry.contract()
    metrics = ObanPowertools.Telemetry.metrics()

    for metric <- metrics do
      [_oban_powertools, family, suffix | _] = metric.event_name

      allowed_tags =
        case get_in(contract, [:families, family]) do
          %{} = per_suffix_map -> Map.get(per_suffix_map, suffix, [])
          tag_list when is_list(tag_list) -> tag_list
        end

      for tag <- metric.tags do
        assert tag in allowed_tags,
               "Tag #{inspect(tag)} for #{inspect(metric.event_name)} not in contract " <>
                 "(allowed: #{inspect(allowed_tags)})"
      end
    end
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

  test "emits workflow step_completed events with bounded metadata" do
    :telemetry.attach(
      "workflow-handler",
      [:oban_powertools, :workflow, :step_completed],
      fn name, measurements, metadata, _config ->
        send(self(), {:workflow_event, name, measurements, metadata})
      end,
      nil
    )

    metadata = %{outcome: "completed", terminal_cause: "completed", semantics_version: 2}

    ObanPowertools.Telemetry.execute_workflow_event(:step_completed, %{count: 1}, metadata)

    assert_receive {:workflow_event, [:oban_powertools, :workflow, :step_completed], %{count: 1},
                    ^metadata}

    assert Map.keys(metadata) |> Enum.sort() ==
             Enum.sort(@expected_contract.families.workflow.step_completed)
  after
    :telemetry.detach("workflow-handler")
  end

  test "emits workflow_terminal events with bounded metadata" do
    :telemetry.attach(
      "workflow-terminal-handler",
      [:oban_powertools, :workflow, :workflow_terminal],
      fn name, measurements, metadata, _config ->
        send(self(), {:workflow_terminal_event, name, measurements, metadata})
      end,
      nil
    )

    metadata = %{
      state: "completed",
      outcome: "terminal",
      terminal_cause: "completed_after_cancel_request",
      semantics_version: 2
    }

    ObanPowertools.Telemetry.execute_workflow_event(:workflow_terminal, %{count: 1}, metadata)

    assert_receive {:workflow_terminal_event, [:oban_powertools, :workflow, :workflow_terminal],
                    %{count: 1}, ^metadata}

    assert Map.keys(metadata) |> Enum.sort() ==
             Enum.sort(@expected_contract.families.workflow.workflow_terminal)
  after
    :telemetry.detach("workflow-terminal-handler")
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

    assert_receive {:cron_event, [:oban_powertools, :cron, :previewed], %{count: 1},
                    received_metadata}

    assert Map.keys(received_metadata) |> Enum.sort() == Enum.sort(@expected_contract.families.cron)
  after
    :telemetry.detach("cron-handler")
  end

  test "emits lifeline repair_executed event with bounded metadata" do
    :telemetry.attach(
      "lifeline-handler",
      [:oban_powertools, :lifeline, :repair_executed],
      fn name, measurements, metadata, _config ->
        send(self(), {:lifeline_event, name, measurements, metadata})
      end,
      nil
    )

    ObanPowertools.Telemetry.execute_lifeline_event(:repair_executed, %{count: 1}, %{
      action: "execute_repair",
      incident_class: "workflow_stuck",
      target_type: "workflow"
    })

    assert_receive {:lifeline_event, [:oban_powertools, :lifeline, :repair_executed],
                    %{count: 1}, received_metadata}

    assert Enum.all?(Map.keys(received_metadata), fn k -> k in @expected_contract.families.lifeline end)
  after
    :telemetry.detach("lifeline-handler")
  end
end
