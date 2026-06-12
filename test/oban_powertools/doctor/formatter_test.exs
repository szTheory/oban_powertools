defmodule ObanPowertools.Doctor.FormatterTest do
  use ExUnit.Case

  alias ObanPowertools.Doctor.{Finding, Formatter}

  @error_finding %Finding{
    check: :index_validity,
    severity: :error,
    message: "INVALID index oban_jobs_args_index on public.oban_jobs",
    remediation: "Run: REINDEX INDEX CONCURRENTLY public.oban_jobs_args_index"
  }

  @warning_finding %Finding{
    check: :uniqueness_timeout_risk,
    severity: :warning,
    message: "Uniqueness-timeout risk: GIN index absent",
    remediation:
      "Run: CREATE INDEX CONCURRENTLY oban_jobs_args_index ON public.oban_jobs USING GIN (args)"
  }

  @expired_deadline_finding %Finding{
    check: :expired_deadline_jobs,
    severity: :warning,
    message: "Expired deadline: retryable job 123 (Example.Worker) has __deadline_at__ 2026-06-12T12:00:00Z in the past",
    remediation:
      "Inspect the job, then retry, cancel, discard, or re-enqueue it after confirming whether the work should still run."
  }

  describe "format/2 with human format" do
    test "renders an all-clear/OK report when no findings" do
      output = Formatter.format([], format: :human)
      assert is_binary(output)
      assert output =~ ~r/(ok|clear|healthy|no issues)/i
    end

    test "includes the severity label for an error finding" do
      output = Formatter.format([@error_finding], format: :human)
      assert output =~ ~r/error/i
    end

    test "includes the message for a finding" do
      output = Formatter.format([@error_finding], format: :human)
      assert output =~ "INVALID index oban_jobs_args_index on public.oban_jobs"
    end

    test "includes the remediation hint for a finding" do
      output = Formatter.format([@error_finding], format: :human)
      assert output =~ "REINDEX INDEX CONCURRENTLY public.oban_jobs_args_index"
    end

    test "includes severity label and remediation for a warning finding" do
      output = Formatter.format([@warning_finding], format: :human)
      assert output =~ ~r/warning/i
      assert output =~ "CREATE INDEX CONCURRENTLY oban_jobs_args_index"
    end

    test "renders multiple findings" do
      output = Formatter.format([@error_finding, @warning_finding], format: :human)
      assert output =~ "INVALID index oban_jobs_args_index"
      assert output =~ "Uniqueness-timeout risk"
    end

    test "renders expired deadline warnings through the generic finding shape" do
      output = Formatter.format([@expired_deadline_finding], format: :human)
      assert output =~ "Expired deadline"
      assert output =~ ~r/warning/i
    end
  end

  describe "format/2 with json format" do
    test "decodes to a map with schema_version == 1 when no findings" do
      output = Formatter.format([], format: :json)
      {:ok, decoded} = Jason.decode(output)
      assert decoded["schema_version"] == 1
    end

    test "includes prefix in top-level JSON map" do
      output = Formatter.format([], format: :json, prefix: "myschema")
      {:ok, decoded} = Jason.decode(output)
      assert decoded["prefix"] == "myschema"
    end

    test "includes exit_code in top-level JSON map" do
      output = Formatter.format([], format: :json, exit_code: 0)
      {:ok, decoded} = Jason.decode(output)
      assert decoded["exit_code"] == 0
    end

    test "includes oban_version_installed in top-level JSON map" do
      output = Formatter.format([], format: :json, oban_version_installed: 14)
      {:ok, decoded} = Jason.decode(output)
      assert decoded["oban_version_installed"] == 14
    end

    test "findings list carries check, severity, message, remediation for each finding" do
      output = Formatter.format([@error_finding], format: :json)
      {:ok, decoded} = Jason.decode(output)
      [finding] = decoded["findings"]
      assert finding["check"] == "index_validity"
      assert finding["severity"] == "error"
      assert finding["message"] == "INVALID index oban_jobs_args_index on public.oban_jobs"

      assert finding["remediation"] ==
               "Run: REINDEX INDEX CONCURRENTLY public.oban_jobs_args_index"
    end

    test "findings is an empty list when no findings" do
      output = Formatter.format([], format: :json)
      {:ok, decoded} = Jason.decode(output)
      assert decoded["findings"] == []
    end

    test "all top-level fields present together" do
      output =
        Formatter.format(
          [@error_finding],
          format: :json,
          prefix: "public",
          exit_code: 2,
          oban_version_installed: 14,
          oban_version_db: 14
        )

      {:ok, decoded} = Jason.decode(output)
      assert decoded["schema_version"] == 1
      assert decoded["prefix"] == "public"
      assert decoded["exit_code"] == 2
      assert decoded["oban_version_installed"] == 14
      assert decoded["oban_version_db"] == 14
      assert length(decoded["findings"]) == 1
    end

    test "expired deadline findings keep schema version 1 and render check name" do
      output = Formatter.format([@expired_deadline_finding], format: :json)
      {:ok, decoded} = Jason.decode(output)

      assert decoded["schema_version"] == 1

      [finding] = decoded["findings"]
      assert finding["check"] == "expired_deadline_jobs"
      assert finding["severity"] == "warning"
      assert finding["message"] =~ "Expired deadline"
    end
  end

  describe "print/2" do
    test "outputs the formatted string to stdout" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Formatter.print([@error_finding], format: :human)
        end)

      assert output =~ "INVALID index oban_jobs_args_index on public.oban_jobs"
    end
  end
end
