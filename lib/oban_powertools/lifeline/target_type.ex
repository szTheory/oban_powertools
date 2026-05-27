defmodule ObanPowertools.Lifeline.TargetType do
  @moduledoc """
  Closed-enum dispatcher for Lifeline `target_type` string → atom conversion.

  ## Closed enum

  Converts the producer-bounded `target_type` string values to atoms:

    - `"job"` → `:job`
    - `"workflow"` → `:workflow`
    - `"workflow_step"` → `:workflow_step`
    - `"step"` → `:step`

  ## Current producer set

  The current Lifeline repair preview and workflow handoff producers emit only
  `"job"`, `"workflow"`, and `"workflow_step"`. The `"step"` value is included
  for forward compatibility per Phase 41 D-07.

  ## Unknown values raise

  There is intentionally no catch-all clause. An unknown `target_type` raises
  `FunctionClauseError` because the callers (`Lifeline.repair_executed`,
  `Lifeline.host_follow_up`, and `LifelineLive` workflow handoff) are
  internally trusted paths. An unknown `target_type` in production indicates a
  programming bug — a new producer was added without updating this module. The
  failure surfaces immediately rather than silently coercing an unknown value
  into an unbounded atom.
  """

  @doc """
  Converts a producer-bounded `target_type` binary to the corresponding atom.

  Raises `FunctionClauseError` for unknown inputs.
  """
  def to_atom("job"), do: :job
  def to_atom("workflow"), do: :workflow
  def to_atom("workflow_step"), do: :workflow_step
  def to_atom("step"), do: :step
end
