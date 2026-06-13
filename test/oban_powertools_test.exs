defmodule ObanPowertoolsTestJobRecordedNilPolicy do
  def display(:job_recorded, _value, _context), do: nil
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertoolsTestJobRecordedRaisingPolicy do
  def display(:job_recorded, _value, _context), do: raise("display failure")
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertoolsTestJobRecordedUnavailablePolicy do
  def display(:job_recorded, _value, _context) do
    %{
      available?: false,
      summary: "suppressed",
      payload: nil,
      redacted?: false
    }
  end

  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertoolsTestWorkflowResultUnredactedPolicy do
  def display(:workflow_result, _value, _context) do
    %{
      payload: nil,
      redacted?: false
    }
  end

  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertoolsTest do
  use ExUnit.Case
  doctest ObanPowertools

  test "top-level module documents the supported surface" do
    docs = Code.fetch_docs(ObanPowertools)

    assert {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} = docs
    assert moduledoc =~ "ObanPowertools.Worker"
    assert moduledoc =~ "ObanPowertools.Workflow"
  end

  describe "DisplayPolicy job recorded output" do
    setup do
      original_display_policy = Application.get_env(:oban_powertools, :display_policy)

      on_exit(fn ->
        Application.put_env(:oban_powertools, :display_policy, original_display_policy)
      end)

      :ok
    end

    test "render_job_field/3 normalizes :job_recorded to default display metadata" do
      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertoolsTestJobRecordedNilPolicy
      )

      record_input = %{
        payload: %{"ok" => true},
        summary: "email sent",
        status: "ok",
        attempt: 2,
        payload_bytes: 11,
        recorded_at: ~U[2026-06-13 01:00:00Z],
        retention: "standard",
        expires_at: ~U[2026-06-20 01:00:00Z],
        redacted: false
      }

      assert %{
               available?: true,
               summary: "email sent",
               status: "ok",
               attempt: 2,
               payload_bytes: 11,
               recorded_at: ~U[2026-06-13 01:00:00Z],
               retention: "standard",
               expires_at: ~U[2026-06-20 01:00:00Z],
               payload: %{"ok" => true},
               redacted?: false
             } =
               ObanPowertools.DisplayPolicy.render_job_field(:job_recorded, record_input, %{
                 surface: :jobs,
                 field: :recorded
               })
    end

    test "render_job_field/3 safely falls back when :job_recorded policy raises" do
      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertoolsTestJobRecordedRaisingPolicy
      )

      assert %{
               available?: true,
               payload: "Recorded output hidden by display policy fallback."
             } =
               ObanPowertools.DisplayPolicy.render_job_field(:job_recorded, %{payload: %{}}, %{
                 surface: :jobs,
                 field: :recorded
               })
    end

    test "render_job_field/3 preserves explicit unavailable policy values" do
      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertoolsTestJobRecordedUnavailablePolicy
      )

      record_input = %{
        payload: %{"secret" => true},
        summary: "stored summary",
        redacted: true
      }

      assert %{
               available?: false,
               summary: "suppressed",
               payload: nil,
               redacted?: false
             } =
               ObanPowertools.DisplayPolicy.render_job_field(:job_recorded, record_input, %{
                 surface: :jobs,
                 field: :recorded
               })
    end

    test "render_job_field/3 preserves missing-output state when :job_recorded policy raises" do
      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertoolsTestJobRecordedRaisingPolicy
      )

      assert %{
               available?: false,
               payload: "No recorded output found for this job.",
               summary: "No recorded output found for this job."
             } =
               ObanPowertools.DisplayPolicy.render_job_field(:job_recorded, nil, %{
                 surface: :jobs,
                 field: :recorded
               })
    end
  end

  describe "DisplayPolicy workflow result output" do
    setup do
      original_display_policy = Application.get_env(:oban_powertools, :display_policy)

      on_exit(fn ->
        Application.put_env(:oban_powertools, :display_policy, original_display_policy)
      end)

      :ok
    end

    test "workflow_result/2 preserves explicit false and nil policy values" do
      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertoolsTestWorkflowResultUnredactedPolicy
      )

      result_input = %{
        payload: %{"secret" => true},
        summary: "stored summary",
        redacted: true,
        status: "completed"
      }

      assert %{
               available?: true,
               payload: nil,
               redacted?: false,
               summary: "stored summary",
               status: "completed"
             } =
               ObanPowertools.DisplayPolicy.workflow_result(result_input, %{
                 surface: :workflows,
                 field: :result
               })
    end

    test "workflow_result/2 uses defaults and preserves false payload when policy returns nil" do
      Application.put_env(
        :oban_powertools,
        :display_policy,
        ObanPowertoolsTestJobRecordedNilPolicy
      )

      result_input = %{
        payload: false,
        redacted: false,
        status: "completed"
      }

      assert %{
               available?: true,
               payload: "false",
               redacted?: false,
               summary: "Result available",
               status: "completed"
             } =
               ObanPowertools.DisplayPolicy.workflow_result(result_input, %{
                 surface: :workflows,
                 field: :result
               })
    end
  end
end
