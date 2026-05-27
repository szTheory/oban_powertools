defmodule ObanPowertools.Forensics.EvidenceBundle do
  alias ObanPowertools.Forensics.{Chronology, Provenance}

  def build(attrs) when is_map(attrs) do
    chronology =
      attrs
      |> Map.get(:chronology, Map.get(attrs, "chronology", []))
      |> Enum.map(&Chronology.item/1)
      |> Chronology.sort()

    %{
      subject: Map.get(attrs, :subject) || Map.get(attrs, "subject") || %{},
      diagnosis_summary:
        Map.get(attrs, :diagnosis_summary) || Map.get(attrs, "diagnosis_summary") || %{},
      chronology: chronology,
      related_evidence:
        attrs
        |> Map.get(:related_evidence, Map.get(attrs, "related_evidence", []))
        |> Enum.map(&normalize_related_evidence/1),
      linked_resources:
        Map.get(attrs, :linked_resources) || Map.get(attrs, "linked_resources") || [],
      legal_next_paths:
        Map.get(attrs, :legal_next_paths) || Map.get(attrs, "legal_next_paths") || [],
      completeness:
        attrs
        |> Map.get(:completeness, Map.get(attrs, "completeness", %{}))
        |> normalize_completeness()
    }
  end

  defp normalize_related_evidence(item) do
    Map.new(item, fn
      {:provenance, value} -> {:provenance, Provenance.normalize_provenance(value)}
      {"provenance", value} -> {:provenance, Provenance.normalize_provenance(value)}
      {key, value} when is_binary(key) -> {String.to_atom(key), value}
      pair -> pair
    end)
  end

  defp normalize_completeness(%{state: state} = item) do
    %{item | state: Provenance.normalize_completeness(state)}
  end

  defp normalize_completeness(%{"state" => _state} = item) do
    item
    |> Map.new(fn
      {"state", value} -> {:state, Provenance.normalize_completeness(value)}
      {"details", value} -> {:details, value}
      pair -> pair
    end)
  end

  defp normalize_completeness(_item),
    do: %{state: :unknown, details: "No evidence completeness details available."}
end
