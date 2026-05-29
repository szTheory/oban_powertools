defmodule ObanPowertools.ExampleHostContractTest do
  use ExUnit.Case
  @moduletag timeout: 180_000
  # Heavy host-contract integration lanes (generate the ops-demo example host, need
  # the host-contract-proof CI harness). Excluded from the general `test` lane via
  # `--exclude host_contract`; run explicitly (per --only tag) in host-contract-proof.yml.
  @moduletag :host_contract

  alias ObanPowertools.ExampleHostContract

  @tag :"native-only"
  test "native-only lane compiles and resets cleanly" do
    result = ExampleHostContract.proof!("native-only")
    mix_source = File.read!(Path.join(result.dir, "mix.exs"))
    deps_output = ExampleHostContract.run!(result.dir, [], "mix", ["deps"])

    refute mix_source =~ ":oban_web"
    refute deps_output =~ "oban_web"
    assert result.compile_output =~ "Generated phoenix_host app"
    assert result.reset_output =~ "Migrated"
  end

  @tag :"bridge-enabled"
  test "bridge-enabled lane proves one bounded oban web render through the shared session" do
    result = ExampleHostContract.proof!("bridge-enabled")

    assert result.compile_output =~ "Generated phoenix_host app"
    assert result.seeds_output =~ "ops-demo"
    assert result.render_output =~ "PhoenixHostWeb.ObanWebBridgeSmokeTest"
    assert result.render_output =~ "1 test, 0 failures"
    assert result.render_output =~ "/ops/jobs/oban"
    assert result.render_output =~ "Oban Web"
  end

  @tag :"control-plane"
  test "control-plane lane proves overview, audit, and bridge-only follow-up through the canonical fixture" do
    result = ExampleHostContract.proof!("control-plane")

    assert result.compile_output =~ "Generated phoenix_host app"
    assert result.seeds_output =~ "ops-demo"
    assert result.control_plane_output =~ "PhoenixHostWeb.ObanPowertoolsControlPlaneSmokeTest"
    assert result.control_plane_output =~ "1 test, 0 failures"
    assert result.control_plane_output =~ "/ops/jobs"
    assert result.control_plane_output =~ "Diagnosis-first overview"
    assert result.control_plane_output =~ "/ops/jobs/audit"
    assert result.control_plane_output =~ "/ops/jobs/oban"
    assert result.control_plane_output =~ "Inspection only"
  end

  @tag :"upgrade-proof"
  test "upgrade lane proves ops-demo pauses nightly_sync with pause_cron_entry after the documented host updates" do
    result = ExampleHostContract.proof!("upgrade")
    config_source = File.read!(Path.join(result.dir, "config/config.exs"))

    assert config_source =~ "display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy"
    assert result.proof_output =~ "PhoenixHostWeb.ObanPowertoolsFirstSessionTest"
    assert result.proof_output =~ "1 test, 0 failures"
    assert result.proof_output =~ "ops-demo"
    assert result.proof_output =~ "nightly_sync"
    assert result.proof_output =~ "pause_cron_entry"
    assert result.phase_19_output =~ "phase19-upgrade-proof"
    assert result.phase_19_output =~ "active_await_id"
    assert result.phase_19_output =~ "waiting_signal"
    assert result.phase_19_output =~ "consumed"
    assert result.phase_19_output =~ "resolved"
    assert result.reset_output =~ "Migrated"
  end

  @tag :first_session
  test "first-session lane proves ops-demo pauses nightly_sync with pause_cron_entry" do
    result = ExampleHostContract.first_session!()

    assert result.output =~ "PhoenixHostWeb.ObanPowertoolsFirstSessionTest"
    assert result.output =~ "1 test, 0 failures"
    assert result.output =~ "ops-demo"
    assert result.output =~ "nightly_sync"
    assert result.output =~ "pause_cron_entry"
  end

  @tag :doctor
  test "doctor lane proves the read-only health-check CLI end-to-end against the example host" do
    result = ExampleHostContract.doctor!()

    # Healthy migrated host: honest exit 0 with a sectioned human report.
    assert result.healthy_status == 0,
           "expected `mix oban_powertools.doctor` to exit 0 on a healthy host, got " <>
             "#{result.healthy_status}:\n#{result.healthy_output}"

    assert result.healthy_output =~ "Oban Powertools Doctor"

    # --format json: valid JSON carrying the schema_version: 1 stability contract,
    # and an exit_code field that matches the process's real exit status (honesty).
    json = result.json_output |> extract_json!() |> Jason.decode!()
    assert json["schema_version"] == 1
    assert is_list(json["findings"])
    assert json["exit_code"] == result.json_status

    # Honest failure path: pointing at an absent schema yields error finding(s),
    # exit 2, and an actionable remediation hint — the exact outcomes the former
    # manual human-verify gate confirmed, now asserted automatically.
    assert result.missing_status == 2,
           "expected exit 2 for an absent --prefix, got " <>
             "#{result.missing_status}:\n#{result.missing_output}"

    assert result.missing_output =~ ~r/(absent|missing|migrate|REINDEX|CREATE INDEX)/i
  end

  # Doctor JSON is the only brace-delimited block in the CLI output (the human
  # header carries none), so a greedy dotall match cleanly isolates the payload
  # from any leading Mix noise.
  defp extract_json!(output) do
    case Regex.run(~r/\{.*\}/s, output) do
      [json] -> json
      _ -> flunk("no JSON object found in `doctor --format json` output:\n#{output}")
    end
  end
end
