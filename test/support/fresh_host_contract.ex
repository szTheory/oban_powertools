defmodule ObanPowertools.FreshHostContract do
  @moduledoc false

  @app "fresh_host"
  @module "FreshHost"
  @repo_root Path.expand("../..", __DIR__)

  def proof! do
    dir = prepare_host!()
    add_powertools_dependency!(dir)

    _deps_output = run!(dir, [], "mix", ["deps.get"])
    install_output = run!(dir, [], "mix", ["oban_powertools.install"])

    write_auth_module!(dir)
    write_display_policy_module!(dir)

    compile_output = run!(dir, [], "mix", ["compile"])
    migrate_output = run!(dir, [{"MIX_ENV", "test"}], "mix", ["ecto.reset"])

    boot_output =
      run!(dir, [{"MIX_ENV", "test"}], "mix", [
        "run",
        "-e",
        ~S|case Application.ensure_all_started(:fresh_host) do
  {:ok, _} ->
    IO.puts("fresh_host booted")
    System.halt(0)

  {:error, reason} ->
    IO.puts("fresh_host failed to boot: #{inspect(reason)}")
    System.halt(1)
end|
      ])

    %{
      dir: dir,
      install_output: install_output,
      compile_output: compile_output,
      migrate_output: migrate_output,
      boot_output: boot_output
    }
  end

  defp prepare_host! do
    target =
      System.tmp_dir!()
      |> Path.join("oban-powertools-fresh-host-#{System.unique_integer([:positive])}")

    File.rm_rf!(target)

    _phx_output =
      run!(@repo_root, [], "mix", [
        "phx.new",
        target,
        "--app",
        @app,
        "--module",
        @module,
        "--database",
        "postgres",
        "--no-assets",
        "--no-dashboard",
        "--no-install",
        "--no-mailer",
        "--no-gettext",
        "--no-agents-md"
      ])

    ensure_postgres_password_config!(target)
    target
  end

  defp add_powertools_dependency!(dir) do
    mix_path = Path.join(dir, "mix.exs")
    source = File.read!(mix_path)

    updated =
      String.replace(
        source,
        ~s|      {:postgrex, ">= 0.0.0"},|,
        """
              {:postgrex, ">= 0.0.0"},
              {:oban_powertools, path: "#{@repo_root}"},
        """
      )

    if updated == source do
      raise "failed to add oban_powertools dependency to fresh host mix.exs"
    end

    File.write!(mix_path, updated)
  end

  defp write_auth_module!(dir) do
    path = Path.join([dir, "lib", "fresh_host_web", "oban_powertools_auth.ex"])

    File.write!(
      path,
      """
      defmodule FreshHostWeb.ObanPowertoolsAuth do
        @moduledoc \"\"\"
        Thin host-owned Powertools auth seam for the fresh host proof.
        \"\"\"

        @behaviour ObanPowertools.Auth

        @impl true
        def current_actor(%Plug.Conn{assigns: %{current_actor: actor}}), do: actor
        def current_actor(%{"ops_actor" => actor}), do: actor
        def current_actor(%{ops_actor: actor}), do: actor
        def current_actor(_), do: nil

        @impl true
        def authorize(nil, _action, _resource), do: {:error, :unauthorized}

        def authorize(actor, _action, _resource) when is_map(actor) do
          if Map.get(actor, :role, Map.get(actor, "role")) in [:ops, "ops"] do
            :ok
          else
            {:error, :unauthorized}
          end
        end

        def authorize(_actor, _action, _resource), do: {:error, :unauthorized}

        @impl true
        def audit_principal(actor) when is_map(actor) do
          id = actor[:id] || actor["id"]

          if is_nil(id) do
            nil
          else
            %{id: to_string(id), type: :user, label: actor[:label] || actor["label"]}
          end
        end

        def audit_principal(_actor), do: nil
      end
      """
    )
  end

  defp write_display_policy_module!(dir) do
    path = Path.join([dir, "lib", "fresh_host_web", "oban_powertools_display_policy.ex"])

    File.write!(
      path,
      """
      defmodule FreshHostWeb.ObanPowertoolsDisplayPolicy do
        @moduledoc \"\"\"
        Thin host-owned Powertools display policy seam for the fresh host proof.
        \"\"\"

        def display(:actor_label, actor, _context) when is_map(actor) do
          actor[:label] || actor["label"] || actor[:id] || actor["id"]
        end

        def display(:reason, reason, _context) when is_binary(reason), do: reason

        def display(_kind, _value, _context), do: nil
      end
      """
    )
  end

  defp ensure_postgres_password_config!(dir) do
    ["dev.exs", "test.exs"]
    |> Enum.map(&Path.join([dir, "config", &1]))
    |> Enum.each(fn path ->
      source = File.read!(path)

      updated =
        if String.contains?(source, ~s(password: "postgres")) do
          source
        else
          String.replace(
            source,
            ~s(username: "postgres",),
            ~s(username: "postgres",\n  password: "postgres",)
          )
        end

      if updated == source and not String.contains?(source, ~s(password: "postgres")) do
        raise "failed to inject postgres password into generated config: #{path}"
      end

      File.write!(path, updated)
    end)
  end

  defp run!(dir, env, command, args) do
    {output, status} =
      System.cmd(command, args,
        cd: dir,
        env: env,
        stderr_to_stdout: true
      )

    rendered = "$ #{Enum.join([command | args], " ")}\n#{output}"

    if status != 0 do
      raise """
      command failed: #{command} #{Enum.join(args, " ")}
      status: #{status}

      #{rendered}
      """
    end

    rendered
  end
end
