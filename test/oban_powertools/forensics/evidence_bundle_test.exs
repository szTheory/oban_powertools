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

  test "drops unknown related-evidence fields at the closed bundle boundary" do
    bundle =
      EvidenceBundle.build(%{
        related_evidence: [
          %{
            "title" => "Test evidence",
            "summary" => "Finite supporting evidence.",
            "provenance" => "supporting",
            "future_unspecified_field" => "some_value",
            "payload" => %{"token" => "SYNTHETIC_TOKEN"}
          }
        ]
      })

    [item] = bundle.related_evidence
    assert Map.keys(item) |> Enum.sort() == [:provenance, :summary, :title]
    refute inspect(item) =~ "future_unspecified_field"
    refute inspect(item) =~ "SYNTHETIC_TOKEN"
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

  test "closes subject diagnosis links paths completeness and coverage to finite keys" do
    bundle =
      EvidenceBundle.build(%{
        subject: %{
          type: "workflow",
          id: "workflow-1",
          label: "Billing workflow",
          entry_surface: "Powertools-native workflows",
          reason: "SYNTHETIC_REASON"
        },
        diagnosis_summary: %{
          title: "Workflow diagnosis",
          current: "waiting",
          detail: "Waiting for a dependency.",
          provenance: :durable,
          raw_error: "SYNTHETIC_ERROR"
        },
        linked_resources: [
          %{
            label: "Workflow detail",
            path: "/ops/jobs/workflows/workflow-1",
            venue: "Powertools-native",
            credentials: "SYNTHETIC_CREDENTIAL"
          }
        ],
        legal_next_paths: [
          %{
            label: "Return to workflow diagnosis",
            path: "/ops/jobs/workflows/workflow-1",
            venue: "Powertools-native",
            preview_token: "SYNTHETIC_TOKEN"
          }
        ],
        completeness: %{
          state: :partial_evidence,
          details: "Some retained history is unavailable.",
          metadata: "SYNTHETIC_METADATA"
        },
        coverage: %{
          shown_count: 2,
          total_count: 5,
          has_more?: true,
          bounded?: true,
          retention: "Newest retained evidence only.",
          sources: [
            %{
              id: "audit",
              label: "Audit",
              shown_count: 2,
              total_count: 5,
              has_more?: true,
              limit: 50,
              provenance: :bridge_only,
              completeness: :partial_evidence,
              retention: "Newest retained Audit window.",
              stacktrace: "SYNTHETIC_STACKTRACE"
            }
          ],
          raw_payload: "SYNTHETIC_PAYLOAD"
        }
      })

    assert Map.keys(bundle) |> Enum.sort() ==
             Enum.sort([
               :subject,
               :diagnosis_summary,
               :chronology,
               :related_evidence,
               :linked_resources,
               :legal_next_paths,
               :completeness,
               :coverage
             ])

    assert Map.keys(bundle.subject) |> Enum.sort() ==
             [:entry_surface, :id, :label, :type]

    assert Map.keys(bundle.diagnosis_summary) |> Enum.sort() ==
             [:current, :detail, :provenance, :title]

    assert [linked] = bundle.linked_resources
    assert Map.keys(linked) |> Enum.sort() == [:label, :path, :venue]

    assert [path] = bundle.legal_next_paths
    assert Map.keys(path) |> Enum.sort() == [:label, :path, :venue]

    assert [source] = bundle.coverage.sources

    assert Map.keys(source) |> Enum.sort() ==
             Enum.sort([
               :id,
               :label,
               :shown_count,
               :total_count,
               :has_more?,
               :limit,
               :provenance,
               :completeness,
               :retention
             ])

    refute inspect(bundle, limit: :infinity, printable_limit: :infinity) =~ "SYNTHETIC_"
  end
end
