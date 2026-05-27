defmodule ObanPowertools.Forensics.Chronology do
  alias ObanPowertools.Forensics.Provenance

  def sort(items) when is_list(items) do
    Enum.sort_by(items, &sort_key/1, :asc)
  end

  def item(attrs) when is_map(attrs) do
    %{
      occurred_at: Map.get(attrs, :occurred_at) || Map.get(attrs, "occurred_at"),
      label: Map.get(attrs, :label) || Map.get(attrs, "label") || "Unknown event",
      resource_type: Map.get(attrs, :resource_type) || Map.get(attrs, "resource_type"),
      resource_id: Map.get(attrs, :resource_id) || Map.get(attrs, "resource_id"),
      source_family:
        Map.get(attrs, :source_family) || Map.get(attrs, "source_family") || "unknown",
      strength:
        attrs
        |> Map.get(:strength, Map.get(attrs, "strength"))
        |> Provenance.normalize_provenance(),
      event_type: Map.get(attrs, :event_type) || Map.get(attrs, "event_type"),
      notes: Map.get(attrs, :notes) || Map.get(attrs, "notes"),
      reason: Map.get(attrs, :reason) || Map.get(attrs, "reason"),
      action: Map.get(attrs, :action) || Map.get(attrs, "action"),
      attempt_state: Map.get(attrs, :attempt_state) || Map.get(attrs, "attempt_state"),
      selected_path: Map.get(attrs, :selected_path) || Map.get(attrs, "selected_path"),
      runbook_context: Map.get(attrs, :runbook_context) || Map.get(attrs, "runbook_context")
    }
  end

  defp sort_key(item) do
    occurred_at =
      item
      |> Map.get(:occurred_at)
      |> unix_seconds()
      |> Kernel.*(-1)

    {
      occurred_at,
      item |> Map.get(:strength) |> Provenance.strength_rank(),
      Map.get(item, :label) || ""
    }
  end

  defp unix_seconds(nil), do: 0
  defp unix_seconds(%DateTime{} = dt), do: DateTime.to_unix(dt, :second)

  defp unix_seconds(%NaiveDateTime{} = ndt) do
    ndt |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(:second)
  end

  defp unix_seconds(_other), do: 0
end
