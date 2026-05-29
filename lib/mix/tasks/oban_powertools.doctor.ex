defmodule Mix.Tasks.ObanPowertools.Doctor do
  use Mix.Task

  @shortdoc "Diagnose Oban DB/config health (read-only)"

  @moduledoc """
  Runs read-only Oban health checks against `pg_catalog` and `information_schema`,
  then exits with an honest exit code for CI pipelines.

  ## Exit Codes

  | Code | Meaning |
  |------|---------|
  | 0    | All checks passed — DB and configuration are healthy |
  | 1    | Warnings only (e.g. uniqueness-timeout risk without `--strict`) |
  | 2    | One or more errors (INVALID index, missing index, migration drift, cannot-run) |

  ## Flags

      --repo MyApp.Repo     Ecto repo module to connect with. Falls back to
                            `config :oban_powertools, repo: MyApp.Repo`.
      --prefix public       Oban schema prefix. Falls back to the host Oban
                            config in application env, then "public". See note below.
      --oban-name Oban      Which Oban instance name to look up when reading the
                            prefix from application env (default: "Oban").
      --format human|json   Output format. "human" (default) renders a sectioned
                            report with ANSI color that auto-degrades in CI/non-TTY.
                            "json" emits a machine-readable payload with a
                            `schema_version: 1` stability contract.
      --strict              Promote the warning tier (uniqueness-timeout risk) to
                            errors. Scope: uniqueness_timeout_risk check only.

  ## Severity Table

  | Finding                              | Default   | Under --strict |
  |--------------------------------------|-----------|----------------|
  | INVALID index                        | error (2) | error (2)      |
  | Missing expected Oban index          | error (2) | error (2)      |
  | Migration drift (Oban/Powertools)    | error (2) | error (2)      |
  | Uniqueness-timeout risk              | warning(1)| error (2)      |
  | Cannot-run (no repo / DB unreachable)| error (2) | error (2)      |

  ## Prefix Resolution

  Prefix auto-detection reads the host Oban configuration from the loaded
  application environment without starting Oban. Because Oban is typically
  configured under the host OTP app key (e.g. `config :my_app, Oban, ...`),
  auto-detection may fall back to `"public"` when the host app hasn't started.
  **Use `--prefix` for reliable production results.**

  ## Boot Strategy

  This task starts only the Ecto repo via `Ecto.Migrator.with_repo/2`. It does
  **not** start Oban or any queue/worker supervision tree. It is safe to run
  around deploys without triggering job processing.
  """

  @switches [
    repo: :string,
    prefix: :string,
    oban_name: :string,
    format: :string,
    strict: :boolean
  ]

  @impl Mix.Task
  def run(argv) do
    # Load the host application's configuration and code paths so the repo module
    # and Oban app env are available, WITHOUT starting any application (D-09/D-10).
    # "app.config" loads config + code paths but never *starts* apps, so Oban's
    # supervision tree stays down. Called inline (not via a module-attribute task
    # requirement) and never via "app.start", which would start Oban (Pitfall 1).
    Mix.Task.run("app.config")

    {opts, _args, _invalid} = OptionParser.parse(argv, strict: @switches)

    repo_module = resolve_repo(opts)

    result =
      Ecto.Migrator.with_repo(
        repo_module,
        fn repo ->
          prefix = resolve_prefix(opts)
          strict = Keyword.get(opts, :strict, false)

          findings = ObanPowertools.Doctor.run(repo, prefix: prefix, strict: strict)
          exit_code = ObanPowertools.Doctor.exit_code_for(findings)

          # Map the --format string flag to a known atom explicitly. Avoids
          # String.to_existing_atom (fragile: the target atom may not be
          # registered yet at runtime) and never creates atoms from arbitrary
          # CLI input (T-48-05). Unknown values fall back to the human report.
          format =
            case Keyword.get(opts, :format, "human") do
              "json" -> :json
              _ -> :human
            end

          ObanPowertools.Doctor.Formatter.print(
            findings,
            format: format,
            prefix: prefix,
            exit_code: exit_code,
            oban_version_installed: Oban.Migrations.Postgres.current_version(),
            oban_version_db: ObanPowertools.Doctor.Checks.oban_db_version(repo, prefix)
          )

          exit_code
        end,
        pool_size: 2
      )

    case result do
      {:ok, exit_code, _apps} ->
        System.halt(exit_code)

      {:error, reason} ->
        Mix.shell().error(
          "Oban Powertools Doctor: cannot start repo — #{inspect(reason)}\n" <>
            "Configure your repo with: config :oban_powertools, repo: MyApp.Repo\n" <>
            "Or pass the flag: mix oban_powertools.doctor --repo MyApp.Repo"
        )

        System.halt(2)
    end
  end

  # ---------------------------------------------------------------------------
  # Repo resolution (D-07 / D-08 / T-48-05)
  # ---------------------------------------------------------------------------

  defp resolve_repo(opts) do
    case Keyword.get(opts, :repo) do
      nil ->
        # Fallback to the project's ObanPowertools.RuntimeConfig contract.
        # repo!/0 raises with a "config :oban_powertools, repo: MyApp.Repo" message if absent.
        ObanPowertools.RuntimeConfig.repo!()

      repo_string ->
        # Safe atom resolution: use Module.safe_concat which normalises the string
        # into a proper module atom without invoking String.to_atom on raw CLI input
        # (T-48-05 mitigation — never String.to_atom/1 on user-supplied input).
        Module.safe_concat([repo_string])
    end
  end

  # ---------------------------------------------------------------------------
  # Prefix resolution (D-07 / D-10)
  # ---------------------------------------------------------------------------

  defp resolve_prefix(opts) do
    cond do
      prefix = Keyword.get(opts, :prefix) ->
        prefix

      true ->
        # Attempt to read from the host's Oban application env without starting Oban.
        # Note: Oban is typically configured under the host app key
        # (e.g. `config :my_app, Oban, prefix: "..."`) so auto-detection is
        # best-effort. Use --prefix for reliable production results (RESEARCH Pitfall 6).
        oban_name = Keyword.get(opts, :oban_name, "Oban")

        oban_key =
          try do
            String.to_existing_atom(oban_name)
          rescue
            ArgumentError -> nil
          end

        case oban_key && Application.get_env(:oban, oban_key) do
          config when is_list(config) ->
            Keyword.get(config, :prefix, "public")

          _ ->
            "public"
        end
    end
  end
end
