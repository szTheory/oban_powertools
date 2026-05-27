defmodule ObanPowertools.Web.RunbookCopyContractDisplayPolicy do
  def display(_kind, value, _context), do: value
end

defmodule ObanPowertools.Web.RunbookCopyContractTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.Lifeline.Incident
  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord
  alias ObanPowertools.WorkflowFixtures

  setup do
    original_display_policy = Application.get_env(:oban_powertools, :display_policy)

    Application.put_env(
      :oban_powertools,
      :display_policy,
      ObanPowertools.Web.RunbookCopyContractDisplayPolicy
    )

    on_exit(fn ->
      Application.put_env(:oban_powertools, :display_policy, original_display_policy)
    end)

    :ok
  end

  @ownership_triad ["Powertools-native", "Oban Web bridge", "host-owned follow-up"]

  @evidence_boundary_markers ["partial evidence", "history unavailable", "unknown"]

  @forbidden_phrases [
    "executed remediation",
    "completed remediation",
    "delivered alert",
    "alert delivery",
    "runbook session",
    "session persists",
    "persisted session",
    "we will execute",
    "we executed"
  ]

  test "runbook surfaces honor the automated copy contract across workflow and lifeline bundles",
       %{conn: conn} do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "phase40-copy-contract")
      |> Workflow.insert(TestRepo)

    workflow
    |> WorkflowRecord.changeset(%{semantics_version: 1})
    |> TestRepo.update!()

    assert {:error, rejection} =
             Workflow.complete_step(TestRepo, workflow.id, :fetch_customer,
               status: :completed,
               payload: %{customer_id: 1}
             )

    assert rejection.reason_code == "unsupported_legacy_semantics"

    incident =
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "dead_executor",
        status: "active",
        executor_id: "phase40-copy-contract-executor",
        incident_fingerprint: "dead_executor:phase40-copy-contract-executor",
        health_state: "missing",
        summary: "missing executor phase40-copy-contract-executor",
        affected_counts: %{"jobs" => 1, "workflow_steps" => 0},
        evidence: %{"job_ids" => [9001], "workflow_step_ids" => []},
        first_detected_at: DateTime.utc_now(),
        last_detected_at: DateTime.utc_now(),
        metadata: %{}
      })
      |> TestRepo.insert!()

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{
          id: "ops-phase40",
          permissions: [
            :view_forensics,
            :view_workflows,
            :view_lifeline
          ]
        }
      )

    {:ok, _workflow_view, workflows_html} =
      live(conn, "/ops/jobs/workflows/#{workflow.id}?step=fetch_customer")

    {:ok, _forensics_workflow_view, forensics_workflow_html} =
      live(
        conn,
        "/ops/jobs/forensics?workflow_id=#{workflow.id}&step=fetch_customer&resource_type=workflow_step"
      )

    {:ok, _forensics_lifeline_view, forensics_lifeline_html} =
      live(
        conn,
        "/ops/jobs/forensics?incident_fingerprint=#{URI.encode_www_form(incident.incident_fingerprint)}"
      )

    runbook_surface =
      Enum.join(
        [workflows_html, forensics_workflow_html, forensics_lifeline_html],
        "\n----RUNBOOK-SURFACE-BOUNDARY----\n"
      )

    for label <- @ownership_triad do
      assert runbook_surface =~ label,
             "runbook surface missing required ownership triad label #{inspect(label)}"
    end

    assert Enum.any?(@evidence_boundary_markers, &String.contains?(runbook_surface, &1)),
           "runbook surface missing at least one evidence-boundary marker (any of #{inspect(@evidence_boundary_markers)})"

    assert_occurs_in_order(workflows_html, [
      "Outcome:",
      "Reason:",
      "Legal next move:",
      "Venue:"
    ])

    for forbidden <- @forbidden_phrases do
      refute runbook_surface =~ forbidden,
             "runbook surface contains forbidden execution/certainty phrase #{inspect(forbidden)}"
    end

    refute Regex.match?(~r/phx-click="[^"]*runbook[^"]*"/, runbook_surface),
           "runbook surface contains a phx-click handler bound to runbook copy (faux-native action shortcut)"

    refute runbook_surface =~ "checklist",
           "runbook surface contains the word \"checklist\" (forbidden faux-native session marker)"
  end

  defp assert_occurs_in_order(text, markers) do
    Enum.reduce(markers, {text, 0}, fn marker, {remaining, offset} ->
      assert String.contains?(remaining, marker),
             "expected #{inspect(marker)} after byte offset #{offset} (not found in remaining slice)"

      {index, _len} = :binary.match(remaining, marker)
      next_offset = offset + index + byte_size(marker)

      next_remaining =
        binary_part(
          remaining,
          index + byte_size(marker),
          byte_size(remaining) - index - byte_size(marker)
        )

      {next_remaining, next_offset}
    end)
  end
end
