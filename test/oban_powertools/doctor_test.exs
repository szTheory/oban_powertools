defmodule ObanPowertools.DoctorTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Doctor
  alias ObanPowertools.Doctor.Finding
  alias ObanPowertools.TestRepo

  describe "exit_code_for/1" do
    test "returns 0 when findings is empty" do
      assert Doctor.exit_code_for([]) == 0
    end

    test "returns 1 when only warning findings present" do
      findings = [
        %Finding{check: :uniqueness_timeout_risk, severity: :warning, message: "risk"}
      ]

      assert Doctor.exit_code_for(findings) == 1
    end

    test "returns 2 when any error finding present" do
      findings = [
        %Finding{check: :uniqueness_timeout_risk, severity: :warning, message: "risk"},
        %Finding{check: :index_validity, severity: :error, message: "INVALID index"}
      ]

      assert Doctor.exit_code_for(findings) == 2
    end

    test "returns 2 when all findings are errors" do
      findings = [
        %Finding{check: :missing_indexes, severity: :error, message: "missing"},
        %Finding{check: :index_validity, severity: :error, message: "INVALID index"}
      ]

      assert Doctor.exit_code_for(findings) == 2
    end
  end

  describe "Finding struct" do
    test "enforces required keys :check, :severity, :message" do
      finding = %Finding{check: :index_validity, severity: :error, message: "some error"}
      assert finding.check == :index_validity
      assert finding.severity == :error
      assert finding.message == "some error"
      assert finding.remediation == nil
    end

    test "accepts optional :remediation key" do
      finding = %Finding{
        check: :index_validity,
        severity: :error,
        message: "some error",
        remediation: "do this"
      }

      assert finding.remediation == "do this"
    end
  end

  describe "run/2 integration" do
    test "returns a list of %Finding{} on the healthy migrated test DB" do
      results = Doctor.run(TestRepo, prefix: "public")
      assert is_list(results)
      assert Enum.all?(results, &match?(%Finding{}, &1))
    end

    test "exit_code_for/1 returns 0 on a healthy DB" do
      results = Doctor.run(TestRepo, prefix: "public")
      assert Doctor.exit_code_for(results) == 0
    end

    test "includes expired deadline warnings without strict promotion" do
      past_iso =
        DateTime.utc_now()
        |> DateTime.add(-60, :second)
        |> DateTime.to_iso8601()

      insert_oban_job!(%{"__deadline_at__" => past_iso}, state: "retryable")

      results = Doctor.run(TestRepo, prefix: "public", strict: true)

      assert Enum.any?(results, fn finding ->
               finding.check == :expired_deadline_jobs and finding.severity == :warning
             end)
    end
  end

  defp insert_oban_job!(meta, opts) do
    state = Keyword.fetch!(opts, :state)

    %{}
    |> Oban.Job.new(worker: "Example.Worker", queue: :default, meta: meta)
    |> Ecto.Changeset.change(state: state)
    |> TestRepo.insert!()
  end
end
