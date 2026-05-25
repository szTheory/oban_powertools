defmodule ObanPowertools.Workflow.CallbackHandler do
  @moduledoc """
  Host callback behaviour for workflow outbox delivery.

  Powertools delivers exactly two workflow-scoped events in this phase:
  `workflow.terminal` and `workflow.recovery_completed`.
  Delivery is post-commit and at-least-once, so handler implementations must be idempotent.
  """

  @callback handle_workflow_callback(map()) :: :ok | {:error, term()}
end
