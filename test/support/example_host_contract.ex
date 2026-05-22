defmodule ObanPowertools.ExampleHostContract do
  @moduledoc false

  @fixture_dir Path.expand("../../examples/phoenix_host", __DIR__)
  @repo_root Path.expand("../..", __DIR__)

  def prepare_host!(lane) do
    target =
      System.tmp_dir!()
      |> Path.join("oban-powertools-#{lane}-#{System.unique_integer([:positive])}")

    File.rm_rf!(target)
    File.cp_r!(@fixture_dir, target)
    File.rm_rf!(Path.join(target, "_build"))
    File.rm_rf!(Path.join(target, "deps"))
    rewrite_powertools_path!(target)

    case lane do
      "upgrade" -> simulate_upgrade_source!(target)
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

    %{dir: dir, compile_output: compile_output, reset_output: reset_output, seeds_output: seeds_output}
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

  defp simulate_upgrade_source!(dir) do
    config_path = Path.join([dir, "config", "config.exs"])
    source = File.read!(config_path)

    without_policy =
      String.replace(source, ~r/\n\s*display_policy: PhoenixHostWeb\.ObanPowertoolsDisplayPolicy/, "")

    true = !String.contains?(without_policy, "display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy")
    File.write!(config_path, without_policy)

    restored =
      String.replace(
        without_policy,
        "auth_module: PhoenixHostWeb.ObanPowertoolsAuth,",
        "auth_module: PhoenixHostWeb.ObanPowertoolsAuth,\n  display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy"
      )

    File.write!(config_path, restored)
  end
end
