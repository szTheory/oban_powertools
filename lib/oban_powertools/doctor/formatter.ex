defmodule ObanPowertools.Doctor.Formatter do
  @moduledoc """
  Pure rendering module for `ObanPowertools.Doctor` findings.

  Supports two output formats:

  - `:human` — a sectioned, human-readable text report with severity labels,
    finding messages, and remediation hints. ANSI color is used when stdout is a
    TTY and automatically degraded to plain text in CI / non-TTY environments
    (pipes, redirects, `NO_COLOR`, `TERM=dumb`) via `IO.ANSI.enabled?/0`. (D-01)

  - `:json` — a structured JSON payload for machine consumers. The top-level
    `schema_version` field is a **stability contract**: its value is `1` and any
    future breaking change to the JSON shape will increment it. This is a
    CHANGELOG-tracked, semver-aware guarantee consistent with the v1.6
    "explicit, inspectable, honest" ethos. (D-03)

  ## JSON Schema (schema_version: 1)

      {
        "schema_version": 1,
        "prefix": "public",
        "oban_version_installed": 14,
        "oban_version_db": 14,
        "exit_code": 0,
        "findings": [
          {
            "check": "index_validity",
            "severity": "error",
            "message": "INVALID index …",
            "remediation": "Run: REINDEX INDEX CONCURRENTLY …"
          }
        ]
      }
  """

  alias ObanPowertools.Doctor.Finding

  @doc """
  Prints the formatted findings to stdout.

  Accepts the same `opts` as `format/2`.
  """
  @spec print([Finding.t()], keyword()) :: :ok
  def print(findings, opts \\ []) do
    IO.puts(format(findings, opts))
  end

  @doc """
  Formats findings as a string in the requested format.

  ## Options

    - `:format` — `:human` (default) or `:json`
    - `:prefix` — Oban schema prefix (used in JSON output; default `"public"`)
    - `:exit_code` — integer exit code (used in JSON output; default `0`)
    - `:oban_version_installed` — installed Oban migration version (used in JSON output)
    - `:oban_version_db` — DB Oban migration version (used in JSON output)
  """
  @spec format([Finding.t()], keyword()) :: String.t()
  def format(findings, opts \\ []) do
    case Keyword.get(opts, :format, :human) do
      :json -> json(findings, opts)
      _ -> human(findings, opts)
    end
  end

  # ---------------------------------------------------------------------------
  # Human renderer
  # ---------------------------------------------------------------------------

  defp human([], _opts) do
    """
    #{colorize("Oban Powertools Doctor", IO.ANSI.bright())}
    #{colorize("Status: OK — no issues found", IO.ANSI.green())}
    All checks passed. Your Oban DB and configuration look healthy.
    """
    |> String.trim_trailing()
  end

  defp human(findings, _opts) do
    errors = Enum.filter(findings, &(&1.severity == :error))
    warnings = Enum.filter(findings, &(&1.severity == :warning))

    header = colorize("Oban Powertools Doctor", IO.ANSI.bright())

    summary_color =
      cond do
        errors != [] -> IO.ANSI.red()
        warnings != [] -> IO.ANSI.yellow()
        true -> IO.ANSI.green()
      end

    status =
      cond do
        errors != [] -> "Status: #{length(errors)} error(s), #{length(warnings)} warning(s)"
        warnings != [] -> "Status: #{length(warnings)} warning(s)"
        true -> "Status: OK"
      end

    lines = [header, colorize(status, summary_color), ""]

    lines =
      if errors != [] do
        section_header = colorize("ERRORS", IO.ANSI.red())
        error_lines = Enum.flat_map(errors, &finding_lines(&1, :error))
        lines ++ [section_header | error_lines] ++ [""]
      else
        lines
      end

    lines =
      if warnings != [] do
        section_header = colorize("WARNINGS", IO.ANSI.yellow())
        warning_lines = Enum.flat_map(warnings, &finding_lines(&1, :warning))
        lines ++ [section_header | warning_lines] ++ [""]
      else
        lines
      end

    Enum.join(lines, "\n") |> String.trim_trailing()
  end

  defp finding_lines(%Finding{message: message, remediation: remediation}, severity) do
    label_color =
      case severity do
        :error -> IO.ANSI.red()
        :warning -> IO.ANSI.yellow()
        _ -> IO.ANSI.green()
      end

    label = colorize("[#{String.upcase(to_string(severity))}]", label_color)
    lines = ["  #{label} #{message}"]

    if remediation do
      lines ++ ["    Hint: #{remediation}"]
    else
      lines
    end
  end

  defp colorize(text, color) do
    if IO.ANSI.enabled?() do
      [color, text, IO.ANSI.reset()] |> IO.ANSI.format() |> IO.iodata_to_binary()
    else
      text
    end
  end

  # ---------------------------------------------------------------------------
  # JSON renderer
  # ---------------------------------------------------------------------------

  defp json(findings, opts) do
    prefix = Keyword.get(opts, :prefix, "public")
    exit_code = Keyword.get(opts, :exit_code, 0)
    oban_version_installed = Keyword.get(opts, :oban_version_installed)
    oban_version_db = Keyword.get(opts, :oban_version_db)

    payload = %{
      schema_version: 1,
      prefix: prefix,
      oban_version_installed: oban_version_installed,
      oban_version_db: oban_version_db,
      exit_code: exit_code,
      findings: Enum.map(findings, &finding_to_map/1)
    }

    Jason.encode!(payload)
  end

  defp finding_to_map(%Finding{
         check: check,
         severity: severity,
         message: message,
         remediation: remediation
       }) do
    %{
      check: to_string(check),
      severity: to_string(severity),
      message: message,
      remediation: remediation
    }
  end
end
