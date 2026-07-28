defmodule ObanPowertools.Forensics.EvidenceBundle do
  @moduledoc """
  Assembles one closed internal forensic evidence bundle.

  Every nested collection is projected through a finite key contract. Unknown
  fields, source structs, and implementation-shaped maps are discarded before
  the bundle can reach the presentation boundary.
  """

  alias ObanPowertools.Forensics.{Chronology, Provenance}

  @subject_keys ~w(type id label step view resource_type resource_id entry_surface)a
  @diagnosis_keys ~w(title current detail provenance)a
  @related_evidence_keys ~w(title summary provenance type resource_id resource_type)a
  @destination_keys ~w(label path venue)a

  def build(attrs) when is_map(attrs) and not is_struct(attrs) do
    chronology =
      attrs
      |> field(:chronology, [])
      |> normalize_plain_maps(&Chronology.item/1)
      |> Chronology.sort()

    %{
      subject: attrs |> field(:subject, %{}) |> project(@subject_keys),
      diagnosis_summary:
        attrs
        |> field(:diagnosis_summary, %{})
        |> project(@diagnosis_keys)
        |> normalize_diagnosis(),
      chronology: chronology,
      related_evidence:
        attrs
        |> field(:related_evidence, [])
        |> normalize_plain_maps(&normalize_related_evidence/1),
      linked_resources:
        attrs
        |> field(:linked_resources, [])
        |> normalize_plain_maps(&project(&1, @destination_keys)),
      legal_next_paths:
        attrs
        |> field(:legal_next_paths, [])
        |> normalize_plain_maps(&project(&1, @destination_keys)),
      completeness:
        attrs
        |> field(:completeness, %{})
        |> normalize_completeness(),
      coverage:
        attrs
        |> field(:coverage, %{})
        |> normalize_coverage(chronology)
    }
  end

  def build(_attrs), do: build(%{})

  defp normalize_diagnosis(diagnosis) do
    case Map.fetch(diagnosis, :provenance) do
      {:ok, provenance} ->
        Map.put(diagnosis, :provenance, Provenance.normalize_provenance(provenance))

      :error ->
        diagnosis
    end
  end

  defp normalize_related_evidence(item) do
    item
    |> project(@related_evidence_keys)
    |> case do
      %{provenance: provenance} = projected ->
        %{projected | provenance: Provenance.normalize_provenance(provenance)}

      projected ->
        projected
    end
  end

  defp normalize_completeness(completeness) when is_map(completeness) do
    %{
      state:
        completeness
        |> field(:state)
        |> Provenance.normalize_completeness(),
      details:
        completeness
        |> field(:details)
        |> finite_text("No evidence completeness details available.")
    }
  end

  defp normalize_completeness(_completeness) do
    %{state: :unknown, details: "No evidence completeness details available."}
  end

  defp normalize_coverage(coverage, chronology) when is_map(coverage) do
    shown_count = nonnegative_integer(field(coverage, :shown_count), length(chronology))

    %{
      shown_count: shown_count,
      total_count: optional_nonnegative_integer(field(coverage, :total_count)),
      has_more?: optional_boolean(field(coverage, :has_more?), nil),
      bounded?: optional_boolean(field(coverage, :bounded?), true),
      retention:
        coverage
        |> field(:retention)
        |> finite_text("Only the retained evidence available to this source is shown."),
      sources:
        coverage
        |> field(:sources, [])
        |> normalize_plain_maps(&normalize_coverage_source/1)
    }
  end

  defp normalize_coverage(_coverage, chronology),
    do: normalize_coverage(%{shown_count: length(chronology)}, chronology)

  defp normalize_coverage_source(source) when is_map(source) and not is_struct(source) do
    %{
      id: source |> field(:id) |> finite_text("unknown"),
      label: source |> field(:label) |> finite_text("Unknown source"),
      shown_count: source |> field(:shown_count) |> nonnegative_integer(0),
      total_count: source |> field(:total_count) |> optional_nonnegative_integer(),
      has_more?: source |> field(:has_more?) |> optional_boolean(nil),
      limit: source |> field(:limit) |> optional_nonnegative_integer(),
      provenance:
        source
        |> field(:provenance)
        |> Provenance.normalize_provenance(),
      completeness:
        source
        |> field(:completeness)
        |> Provenance.normalize_completeness(),
      retention:
        source
        |> field(:retention)
        |> finite_text("No source retention detail is available.")
    }
  end

  defp normalize_coverage_source(_source),
    do:
      normalize_coverage_source(%{
        id: "unknown",
        label: "Unknown source",
        provenance: :missing,
        completeness: :unknown
      })

  defp project(value, keys) when is_map(value) and not is_struct(value) do
    Enum.reduce(keys, %{}, fn key, projected ->
      case field(value, key) do
        nil -> projected
        nested when is_map(nested) or is_list(nested) -> projected
        nested -> Map.put(projected, key, nested)
      end
    end)
  end

  defp project(_value, _keys), do: %{}

  defp normalize_plain_maps(value, mapper) when is_list(value) do
    value
    |> Enum.filter(&(is_map(&1) and not is_struct(&1)))
    |> Enum.map(mapper)
  end

  defp normalize_plain_maps(_value, _mapper), do: []

  defp field(map, key, default \\ nil)

  defp field(map, key, default) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key), default)
    end
  end

  defp field(_map, _key, default), do: default

  defp finite_text(nil, fallback), do: fallback
  defp finite_text(value, _fallback) when is_atom(value), do: Atom.to_string(value)
  defp finite_text(value, _fallback) when is_integer(value), do: Integer.to_string(value)

  defp finite_text(value, fallback) when is_binary(value) do
    case String.trim(value) do
      "" -> fallback
      text -> text
    end
  end

  defp finite_text(_value, fallback), do: fallback

  defp nonnegative_integer(value, _fallback) when is_integer(value) and value >= 0, do: value
  defp nonnegative_integer(_value, fallback), do: fallback

  defp optional_nonnegative_integer(nil), do: nil
  defp optional_nonnegative_integer(value) when is_integer(value) and value >= 0, do: value
  defp optional_nonnegative_integer(_value), do: nil

  defp optional_boolean(value, _fallback) when is_boolean(value), do: value
  defp optional_boolean(nil, fallback), do: fallback
  defp optional_boolean(_value, fallback), do: fallback
end
