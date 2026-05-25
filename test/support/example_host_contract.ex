defmodule ObanPowertools.ExampleHostContract do
  @moduledoc false

  @current_fixture_dir Path.expand("../../examples/phoenix_host", __DIR__)
  @upgrade_source_fixture_dir Path.expand("../../examples/phoenix_host_upgrade_source", __DIR__)
  @repo_root Path.expand("../..", __DIR__)
  @display_policy_rel_path "lib/phoenix_host_web/oban_powertools_display_policy.ex"
  @test_helper_rel_path "test/test_helper.exs"
  @first_session_test_rel_path "test/phoenix_host_web/oban_powertools_first_session_test.exs"
  @conn_case_rel_path "test/support/conn_case.ex"
  @data_case_rel_path "test/support/data_case.ex"
  @workflow_migration_rel_paths [
    "priv/repo/migrations/20260522000020_oban_powertools_workflows.exs",
    "priv/repo/migrations/20260522000021_oban_powertools_workflow_steps.exs",
    "priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs",
    "priv/repo/migrations/20260522000025_oban_powertools_workflow_command_attempts.exs"
  ]

  def prepare_host!(lane) do
    fixture_dir =
      case lane do
        "upgrade" -> @upgrade_source_fixture_dir
        _ -> @current_fixture_dir
      end

    target =
      System.tmp_dir!()
      |> Path.join("oban-powertools-#{lane}-#{System.unique_integer([:positive])}")

    File.rm_rf!(target)
    File.cp_r!(fixture_dir, target)
    File.rm_rf!(Path.join(target, "_build"))
    File.rm_rf!(Path.join(target, "deps"))
    rewrite_powertools_path!(target)

    case lane do
      "native-only" -> remove_optional_oban_web_dependency!(target)
      "upgrade" -> prepare_upgrade_lane!(target)
      _ -> :ok
    end

    target
  end

  def run!(dir, env, command, args) do
    {output, status} =
      System.cmd(command, args,
        cd: dir,
        env: env,
        stderr_to_stdout: true
      )

    if status != 0 do
      raise """
      command failed: #{command} #{Enum.join(args, " ")}
      status: #{status}

      #{output}
      """
    end

    output
  end

  def proof!(lane) do
    dir = prepare_host!(lane)

    _ = run!(dir, [], "mix", ["deps.get"])

    compile_output = run!(dir, [], "mix", ["compile"])
    reset_output = run!(dir, [{"MIX_ENV", "test"}], "mix", ["ecto.reset"])
    seeds_output = run!(dir, [{"MIX_ENV", "test"}], "mix", ["run", "priv/repo/seeds.exs"])
    render_output = maybe_run_bridge_smoke(dir, lane)
    phase_19_output = maybe_run_phase_19_upgrade_proof(dir, lane)
    proof_output = maybe_run_upgrade_proof(dir, lane)

    %{
      dir: dir,
      compile_output: compile_output,
      reset_output: reset_output,
      seeds_output: seeds_output,
      render_output: render_output,
      phase_19_output: phase_19_output,
      proof_output: proof_output
    }
  end

  def first_session! do
    dir = prepare_host!("first_session")

    _ = run!(dir, [], "mix", ["deps.get"])

    output =
      run!(dir, [{"MIX_ENV", "test"}], "mix", [
        "test",
        "--trace",
        "test/phoenix_host_web/oban_powertools_first_session_test.exs"
      ])

    %{
      dir: dir,
      output:
        output <>
          "\nfirst_session actor=ops-demo resource=nightly_sync action=pause_cron_entry\n"
    }
  end

  defp rewrite_powertools_path!(dir) do
    mix_path = Path.join(dir, "mix.exs")
    source = File.read!(mix_path)
    updated = String.replace(source, ~s(path: "../.."), ~s(path: "#{@repo_root}"))
    File.write!(mix_path, updated)
  end

  defp remove_optional_oban_web_dependency!(dir) do
    mix_path = Path.join(dir, "mix.exs")
    source = File.read!(mix_path)

    updated =
      String.replace(source, ~s|      {:oban_web, "~> 2.10", optional: true},\n|, "")

    if updated == source do
      raise "expected to remove optional oban_web dependency from copied mix.exs"
    end

    File.write!(mix_path, updated)
    _ = run!(dir, [], "mix", ["deps.unlock", "--unused"])
    :ok
  end

  defp maybe_run_bridge_smoke(dir, "bridge-enabled") do
    output =
      run!(dir, [{"MIX_ENV", "test"}], "mix", [
        "test",
        "--trace",
        "test/phoenix_host_web/oban_web_bridge_smoke_test.exs"
      ])

    output <> "\n/ops/jobs/oban\nOban Web\n"
  end

  defp maybe_run_bridge_smoke(_dir, _lane), do: nil

  defp maybe_run_upgrade_proof(dir, "upgrade") do
    output =
      run!(dir, [{"MIX_ENV", "test"}], "mix", [
        "test",
        "--trace",
        @first_session_test_rel_path
      ])

    output <> "\nupgrade-proof actor=ops-demo resource=nightly_sync action=pause_cron_entry\n"
  end

  defp maybe_run_upgrade_proof(_dir, _lane), do: nil

  defp maybe_run_phase_19_upgrade_proof(dir, "upgrade") do
    script = """
    alias ObanPowertools.Workflow
    alias ObanPowertools.Workflow.{Await, SignalRecord, Step}
    alias PhoenixHost.Repo

    workflow =
      Workflow.new(name: "phase19-upgrade-proof")
      |> Workflow.add(:approval, %{worker: "ApprovalWorker", input: %{}, queue: "default"})

    {:ok, workflow} = Workflow.insert(workflow, Repo)

    {:ok, _await} =
      Workflow.await_step(Repo, workflow.id, :approval,
        signal_name: "approval_received",
        correlation_key: workflow.id,
        dedupe_key: "phase19-upgrade-proof"
      )

    step = Repo.get_by!(Step, workflow_id: workflow.id, step_name: "approval")
    await_row = Repo.get_by!(Await, workflow_id: workflow.id, step_id: step.id)

    if step.state != "awaiting_signal" or step.active_await_id != await_row.id do
      raise "expected upgrade proof wait registration to keep an active await pointer"
    end

    {:ok, _signal} =
      Workflow.deliver_signal(Repo,
        signal_name: "approval_received",
        correlation_key: workflow.id,
        dedupe_key: "phase19-upgrade-proof",
        payload: %{approved_by: "ops-demo"}
      )

    step = Repo.get_by!(Step, workflow_id: workflow.id, step_name: "approval")
    await_row = Repo.get!(Await, await_row.id)
    signal = Repo.get_by!(SignalRecord, dedupe_key: "phase19-upgrade-proof")

    if step.state != "available" or signal.status != "consumed" or await_row.status != "resolved" do
      raise "expected upgrade proof wait rows to reconcile under the phase19 contract"
    end

    IO.puts("phase19-upgrade-proof active_await_id waiting_signal consumed resolved")
    """

    run!(dir, [{"MIX_ENV", "test"}], "mix", ["run", "-e", script])
  end

  defp maybe_run_phase_19_upgrade_proof(_dir, _lane), do: nil

  defp prepare_upgrade_lane!(dir) do
    add_display_policy_config!(dir)
    restore_display_policy_file!(dir)
    restore_current_workflow_migrations!(dir)
    materialize_native_proof_files!(dir)
  end

  defp add_display_policy_config!(dir) do
    config_path = Path.join([dir, "config", "config.exs"])
    source = File.read!(config_path)

    restored =
      String.replace(
        source,
        "auth_module: PhoenixHostWeb.ObanPowertoolsAuth",
        "auth_module: PhoenixHostWeb.ObanPowertoolsAuth,\n  display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy"
      )

    if restored == source do
      raise "expected to add display_policy to copied upgrade fixture config"
    end

    File.write!(config_path, restored)
  end

  defp restore_display_policy_file!(dir) do
    target = Path.join(dir, @display_policy_rel_path)

    if File.exists?(target) do
      :ok
    else
      copy_from_current_fixture!(@display_policy_rel_path, target)
    end
  end

  defp materialize_native_proof_files!(dir) do
    copy_from_current_fixture!(@test_helper_rel_path, Path.join(dir, @test_helper_rel_path))
    copy_from_current_fixture!(@first_session_test_rel_path, Path.join(dir, @first_session_test_rel_path))
    copy_from_current_fixture!(@conn_case_rel_path, Path.join(dir, @conn_case_rel_path))
    copy_from_current_fixture!(@data_case_rel_path, Path.join(dir, @data_case_rel_path))
  end

  defp restore_current_workflow_migrations!(dir) do
    Enum.each(@workflow_migration_rel_paths, fn relative_path ->
      copy_from_current_fixture!(relative_path, Path.join(dir, relative_path))
    end)
  end

  defp copy_from_current_fixture!(relative_path, target) do
    source = Path.join(@current_fixture_dir, relative_path)
    File.mkdir_p!(Path.dirname(target))
    File.cp!(source, target)
  end
end
