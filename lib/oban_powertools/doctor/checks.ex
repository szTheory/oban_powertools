defmodule ObanPowertools.Doctor.Checks do
  @moduledoc false

  alias ObanPowertools.Doctor.Finding

  # Stub implementation — will be completed in Tasks 2 and 3

  def index_validity(_repo, _prefix), do: []

  def missing_indexes(_repo, _prefix), do: []

  def oban_migration_version(_repo, _prefix), do: []

  def powertools_tables(_repo), do: []

  def uniqueness_timeout_risk(_repo, _prefix, _opts), do: []

  # Separately testable helper for finding construction from catalog rows.
  # rows: [[index_name, is_valid, is_ready], ...]
  # prefix: schema prefix string
  @doc false
  def findings_for_index_rows(rows, prefix) do
    rows
    |> Enum.filter(fn [_name, valid, ready] -> not valid or not ready end)
    |> Enum.map(fn [name, _valid, _ready] ->
      %Finding{
        check: :index_validity,
        severity: :error,
        message: "INVALID index #{name} on #{prefix}.oban_jobs (failed CREATE INDEX CONCURRENTLY)",
        remediation: "Run: REINDEX INDEX CONCURRENTLY #{prefix}.#{name}"
      }
    end)
  end
end
