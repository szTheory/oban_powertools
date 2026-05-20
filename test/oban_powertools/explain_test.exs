defmodule ObanPowertools.ExplainTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.{Audit, Explain, Workflow}
  alias ObanPowertools.WorkflowFixtures

  defmodule ExplainWorker do
    use ObanPowertools.Worker,
      args: [user_id: :integer],
      limits: [
        name: "explain-user-api",
        scope: :partitioned,
        partition_by: {:args, :user_id},
        bucket_capacity: 1,
        bucket_span_ms: 60_000
      ]

    @impl true
    def process(_job), do: :ok
  end

  test "explain returns blocked payloads with live and snapshot evidence" do
    assert {:ok, _job} = ExplainWorker.enqueue(%{user_id: 10})
    assert {:blocked, [%{code: "limit_reached"}]} = ExplainWorker.enqueue(%{user_id: 10})

    explanation = Explain.explain(ExplainWorker, %{user_id: 10}, repo: repo())

    assert explanation.status == :blocked
    assert [%{code: "limit_reached"}] = explanation.live_now
    assert [%{code: "limit_reached"}] = explanation.blockers
    assert explanation.snapshot_at_block_start.worker == inspect(ExplainWorker)
    assert explanation.snapshot_at_block_start.blocker_codes == ["limit_reached"]
    assert explanation.snapshot_at_block_start.details["partition_key"] == "10"
  end

  test "explain returns runnable payload when no live blockers remain" do
    explanation = Explain.explain(ExplainWorker, %{user_id: 99}, repo: repo())

    assert explanation.status == :runnable
    assert explanation.blockers == []
    assert explanation.live_now == []
  end

  test "blocked limiter outcomes write normalized audit rows" do
    assert {:ok, _job} = ExplainWorker.enqueue(%{user_id: 12})
    assert {:blocked, [%{code: "limit_reached"}]} = ExplainWorker.enqueue(%{user_id: 12})

    [event | _] = Audit.list(%{type: :limiter, id: "explain-user-api"}, repo: repo())

    assert event.action == "limiter.blocked"
    assert event.metadata["blocker_codes"] == ["limit_reached"]
    assert event.metadata["partition_key"] == "12"
  end

  test "workflow explain returns blocker details for blocked steps" do
    {:ok, workflow} = WorkflowFixtures.workflow_fixture() |> Workflow.insert(repo())

    explanation = Explain.workflow_step(workflow.id, :notify, repo: repo())

    assert explanation.status == :pending
    assert [%{code: "waiting_on_dependencies"}] = explanation.blockers

    assert explanation.snapshot_at_block_start["dependencies"] == [
             "sync_billing",
             "sync_support"
           ]
  end

  defp repo, do: ObanPowertools.TestRepo
end
