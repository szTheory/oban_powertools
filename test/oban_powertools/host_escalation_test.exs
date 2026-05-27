defmodule ObanPowertools.HostEscalationOkHandler do
  @behaviour ObanPowertools.HostEscalationHandler

  @impl true
  def handle_escalation(_event_facts), do: :ok
end

defmodule ObanPowertools.HostEscalationMapHandler do
  @behaviour ObanPowertools.HostEscalationHandler

  @impl true
  def handle_escalation(_event_facts), do: {:ok, %{"acknowledged" => true}}
end

defmodule ObanPowertools.HostEscalationErrorHandler do
  @behaviour ObanPowertools.HostEscalationHandler

  @impl true
  def handle_escalation(_event_facts), do: {:error, :callback_failed}
end

defmodule ObanPowertools.HostEscalationRaiseHandler do
  @behaviour ObanPowertools.HostEscalationHandler

  @impl true
  def handle_escalation(_event_facts), do: raise("callback exploded")
end

defmodule ObanPowertools.HostEscalationTest do
  use ExUnit.Case, async: false

  alias ObanPowertools.{HostEscalation, RuntimeConfig}

  setup do
    original_handler = Application.get_env(:oban_powertools, :host_escalation_handler)

    on_exit(fn ->
      Application.put_env(:oban_powertools, :host_escalation_handler, original_handler)
    end)

    :ok
  end

  test "returns explicit unconfigured fallback when no host handler is configured" do
    Application.delete_env(:oban_powertools, :host_escalation_handler)

    assert RuntimeConfig.host_escalation_handler() == nil

    result =
      HostEscalation.dispatch(%{
        "event_name" => "lifeline.remediation_attempt",
        "attempt_state" => "succeeded",
        "action" => "job_rescue",
        "target_type" => "job",
        "target_id" => "42",
        "incident_fingerprint" => "dead_executor:node-a",
        "ownership" => "host-owned follow-up",
        "runbook_context" => %{"diagnosis_state" => "missing"}
      })

    assert result.status == "host_owned_follow_up_unconfigured"
    assert result.details["fallback"] == "host-owned follow-up unavailable"
    assert result.details["configuration"] == "No host escalation hook configured"
    assert HostEscalation.dispatch_status(result) == "host_owned_follow_up_unconfigured"
  end

  test "returns callback invoked status when handler returns :ok or {:ok, map}" do
    Application.put_env(
      :oban_powertools,
      :host_escalation_handler,
      ObanPowertools.HostEscalationOkHandler
    )

    ok_result = HostEscalation.dispatch(%{"event_name" => "lifeline.remediation_attempt"})
    assert ok_result.status == "host_owned_follow_up_callback_invoked"
    assert ok_result.details["result"] == "ok"

    Application.put_env(
      :oban_powertools,
      :host_escalation_handler,
      ObanPowertools.HostEscalationMapHandler
    )

    map_result = HostEscalation.dispatch(%{"event_name" => "lifeline.remediation_attempt"})
    assert map_result.status == "host_owned_follow_up_callback_invoked"
    assert map_result.details["acknowledged"] == true
  end

  test "returns callback failed status when handler errors or raises" do
    Application.put_env(
      :oban_powertools,
      :host_escalation_handler,
      ObanPowertools.HostEscalationErrorHandler
    )

    error_result = HostEscalation.dispatch(%{"event_name" => "lifeline.remediation_attempt"})
    assert error_result.status == "host_owned_follow_up_callback_failed"
    assert error_result.details["reason"] =~ "callback_failed"

    Application.put_env(
      :oban_powertools,
      :host_escalation_handler,
      ObanPowertools.HostEscalationRaiseHandler
    )

    raise_result = HostEscalation.dispatch(%{"event_name" => "lifeline.remediation_attempt"})
    assert raise_result.status == "host_owned_follow_up_callback_failed"
    assert raise_result.details["reason"] =~ "callback exploded"
  end
end
