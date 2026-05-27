defmodule ObanPowertools.Forensics.EvidenceBundle do
  @moduledoc """
  Assembles a normalized forensic evidence bundle from raw attrs.

  ## Related evidence key normalization

  Related evidence items may arrive with binary keys (from JSON-decoded payloads or
  host-app forensics integrations). The following keys are normalized to atoms so that
  downstream consumers (e.g., `ForensicsLive`) can access them via atom dot-syntax:

      @related_evidence_atom_keys ~w(title summary provenance type resource_id resource_type)a

  **Unknown binary keys are preserved as binaries** (Phase 41 D-28 / Phase 34 D-09
  partial-evidence posture). Downstream consumers must handle binary-key fall-throughs
  rather than relying on atom access for unknown keys. Unknown keys do NOT grow the atom
  table.

  The compile-time module attribute ensures all known atoms are interned at module load,
  so `String.to_existing_atom/1` cannot raise for known keys at runtime regardless of
  module-load ordering.
  """

  alias ObanPowertools.Forensics.{Chronology, Provenance}

  @related_evidence_atom_keys ~w(title summary provenance type resource_id resource_type)a

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
      {key, value} when is_binary(key) -> {normalize_related_evidence_key(key), value}
      pair -> pair
    end)
  end

  @related_evidence_string_keys Enum.map(@related_evidence_atom_keys, &Atom.to_string/1)

  defp normalize_related_evidence_key(key) when is_binary(key) do
    if key in @related_evidence_string_keys do
      String.to_existing_atom(key)
    else
      key
    end
  rescue
    ArgumentError -> key
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
