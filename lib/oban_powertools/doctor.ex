defmodule ObanPowertools.Doctor.Finding do
  @enforce_keys [:check, :severity, :message]
  defstruct [:check, :severity, :message, :remediation]
end

defmodule ObanPowertools.Doctor do
  alias ObanPowertools.Doctor.Checks

  @spec run(module(), keyword()) :: [ObanPowertools.Doctor.Finding.t()]
  def run(repo, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "public")
    strict = Keyword.get(opts, :strict, false)

    []
    |> Kernel.++(Checks.index_validity(repo, prefix))
    |> Kernel.++(Checks.missing_indexes(repo, prefix))
    |> Kernel.++(Checks.oban_migration_version(repo, prefix))
    |> Kernel.++(Checks.powertools_tables(repo))
    |> Kernel.++(Checks.uniqueness_timeout_risk(repo, prefix, strict: strict))
    |> Kernel.++(Checks.expired_deadline_jobs(repo, prefix))
  end

  @spec exit_code_for([ObanPowertools.Doctor.Finding.t()]) :: 0 | 1 | 2
  def exit_code_for(findings) do
    findings
    |> Enum.map(& &1.severity)
    |> Enum.reduce(0, fn
      :error, _acc -> 2
      :warning, acc when acc < 2 -> max(acc, 1)
      _, acc -> acc
    end)
  end
end
