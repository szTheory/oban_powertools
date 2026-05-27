defmodule ObanPowertools.HostEscalationHandler do
  @moduledoc """
  Host-owned callback behaviour for post-remediation follow-up.

  Powertools emits bounded event facts and records callback outcomes.
  Destination routing, delivery guarantees, and escalation policy remain host-owned.
  """

  @callback handle_escalation(map()) :: :ok | {:ok, map()} | {:error, term()}
end
