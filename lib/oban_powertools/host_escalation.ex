defmodule ObanPowertools.HostEscalation do
  @moduledoc """
  Dispatches optional host-owned follow-up callbacks after native remediation.
  """

  alias ObanPowertools.RuntimeConfig

  @unconfigured_status "host_owned_follow_up_unconfigured"
  @invoked_status "host_owned_follow_up_callback_invoked"
  @failed_status "host_owned_follow_up_callback_failed"

  def dispatch(event_facts, opts \\ []) when is_map(event_facts) do
    case RuntimeConfig.host_escalation_handler(opts) do
      nil ->
        %{
          status: @unconfigured_status,
          details: %{
            "fallback" => "host-owned follow-up unavailable",
            "configuration" => "No host escalation hook configured"
          }
        }

      handler ->
        try do
          normalize_handler_result(handler.handle_escalation(event_facts))
        rescue
          error ->
            %{
              status: @failed_status,
              details: %{"reason" => Exception.message(error)}
            }
        catch
          kind, value ->
            %{
              status: @failed_status,
              details: %{"reason" => "#{kind}: #{inspect(value)}"}
            }
        end
    end
  end

  def dispatch_status(%{status: status}) when is_binary(status), do: status
  def dispatch_status(_result), do: @failed_status

  def normalize_handler_result(:ok) do
    %{status: @invoked_status, details: %{"result" => "ok"}}
  end

  def normalize_handler_result({:ok, details}) when is_map(details) do
    %{status: @invoked_status, details: details}
  end

  def normalize_handler_result({:error, reason}) do
    %{status: @failed_status, details: %{"reason" => inspect(reason)}}
  end

  def normalize_handler_result(other) do
    %{status: @failed_status, details: %{"reason" => "unexpected_return: #{inspect(other)}"}}
  end
end
