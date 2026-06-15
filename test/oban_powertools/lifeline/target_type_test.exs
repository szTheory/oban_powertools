defmodule ObanPowertools.Lifeline.TargetTypeTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Lifeline.TargetType

  test "maps each producer-bounded target_type string to the expected atom" do
    assert TargetType.to_atom("job") == :job
    assert TargetType.to_atom("workflow") == :workflow
    assert TargetType.to_atom("workflow_step") == :workflow_step
    assert TargetType.to_atom("step") == :step
    assert TargetType.to_atom("callback") == :callback
  end

  test "raises FunctionClauseError for unknown target_type strings" do
    assert_raise FunctionClauseError, fn ->
      TargetType.to_atom("unknown")
    end

    assert_raise FunctionClauseError, fn ->
      TargetType.to_atom("job_step")
    end

    assert_raise FunctionClauseError, fn ->
      TargetType.to_atom("")
    end
  end
end
