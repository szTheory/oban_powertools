defmodule ObanPowertools.Forensics.EvidenceBundleTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Forensics.EvidenceBundle

  test "normalizes known string keys in related_evidence to atoms" do
    bundle =
      EvidenceBundle.build(%{
        related_evidence: [
          %{
            "title" => "Orphaned execution",
            "summary" => "Job 123 was running when executor died",
            "provenance" => "durable",
            "type" => "job_evidence",
            "resource_id" => "123",
            "resource_type" => "job"
          }
        ]
      })

    [item] = bundle.related_evidence
    assert Map.has_key?(item, :title)
    assert Map.has_key?(item, :summary)
    assert Map.has_key?(item, :provenance)
    assert Map.has_key?(item, :type)
    assert Map.has_key?(item, :resource_id)
    assert Map.has_key?(item, :resource_type)
    assert item.title == "Orphaned execution"
    assert item.summary == "Job 123 was running when executor died"
    assert item.resource_id == "123"
    assert item.resource_type == "job"
  end

  test "preserves unknown string keys as binaries in related_evidence" do
    bundle =
      EvidenceBundle.build(%{
        related_evidence: [
          %{
            "title" => "Test evidence",
            "future_unspecified_field" => "some_value",
            "another_unknown_key" => "other_value"
          }
        ]
      })

    [item] = bundle.related_evidence
    # Known key is atomized
    assert Map.has_key?(item, :title)
    # Unknown keys remain as binaries (D-28 partial-evidence visibility)
    assert Map.has_key?(item, "future_unspecified_field")
    assert Map.has_key?(item, "another_unknown_key")
    assert item["future_unspecified_field"] == "some_value"
  end

  test "does not grow the atom table for unknown related_evidence keys" do
    canary = "phase_41_atom_safety_canary_#{System.unique_integer([:positive])}"

    _bundle =
      EvidenceBundle.build(%{
        related_evidence: [
          %{canary => "some_value", "title" => "Test"}
        ]
      })

    # The canary key must not have been converted to an atom
    assert_raise ArgumentError, fn -> String.to_existing_atom(canary) end
  end
end
