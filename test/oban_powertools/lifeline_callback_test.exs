defmodule ObanPowertools.LifelineCallbackTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.{Audit, Batch, Callback, Lifeline, TestRepo}

  @actor %{id: "operator-1", permissions: [:preview_repair, :execute_repair]}

  @tag :phase62_callback_preview
  test "preview_repair accepts failed callbacks and includes callback evidence" do
    batch = insert_batch!()
    callback = insert_callback!(batch, status: "failed", attempts: 3, last_error: "timeout")

    {:ok, preview} =
      Lifeline.preview_repair(TestRepo, @actor, %{
        action: "callback_retry",
        target_type: "callback",
        target_id: callback.id
      })

    assert preview.action == "callback_retry"
    assert preview.target_type == "callback"
    assert preview.target_id == callback.id
    assert preview.reason_required == true
    assert preview.affected_counts["callbacks"] == 1
    assert preview.before_snapshot["status"] == "failed"
    assert preview.before_snapshot["event"] == callback.event
    assert preview.before_snapshot["dedupe_key"] == callback.dedupe_key
    assert preview.before_snapshot["attempts"] == 3
    assert preview.before_snapshot["last_error"] == "timeout"
    assert preview.after_snapshot["status"] == "pending"
    assert preview.metadata["risk"] == "high"
    assert preview.metadata["resource"]["type"] == "callback"
    assert preview.metadata["batch"]["id"] == batch.id
    assert preview.evidence["preview_status"] == "ready"
    assert preview.evidence["preview_token"] == preview.preview_token
  end

  @tag :phase62_callback_preview
  test "preview_repair accepts expired claimed callbacks and rejects healthy callback states" do
    batch = insert_batch!()
    expired = DateTime.add(now(), -60, :second)
    future = DateTime.add(now(), 60, :second)

    expired_claimed = insert_callback!(batch, status: "claimed", lease_expires_at: expired)
    delivered = insert_callback!(batch, status: "delivered", delivered_at: now())
    pending = insert_callback!(batch, status: "pending")
    healthy_claimed = insert_callback!(batch, status: "claimed", lease_expires_at: future)

    assert {:ok, _preview} =
             Lifeline.preview_repair(TestRepo, @actor, %{
               action: "callback_retry",
               target_type: "callback",
               target_id: expired_claimed.id
             })

    for callback <- [delivered, pending, healthy_claimed] do
      assert {:error, :callback_not_retryable} =
               Lifeline.preview_repair(TestRepo, @actor, %{
                 action: "callback_retry",
                 target_type: "callback",
                 target_id: callback.id
               })
    end
  end

  @tag :phase62_callback_preview
  test "preview_repair rejects unauthorized and unsupported callback requests" do
    batch = insert_batch!()
    callback = insert_callback!(batch, status: "failed")

    assert {:error, :unauthorized} =
             Lifeline.preview_repair(TestRepo, %{id: "operator-2", permissions: []}, %{
               action: "callback_retry",
               target_type: "callback",
               target_id: callback.id
             })

    assert {:error, :unsupported_action} =
             Lifeline.preview_repair(TestRepo, @actor, %{
               action: "callback_cancel",
               target_type: "callback",
               target_id: callback.id
             })
  end

  @tag :phase62_callback_execute
  test "execute_repair resets callback to pending, consumes preview, and audits callback resource" do
    Application.delete_env(:oban_powertools, :host_escalation_handler)

    batch = insert_batch!()

    callback =
      insert_callback!(batch,
        status: "failed",
        attempts: 4,
        claimed_at: now(),
        claimed_by: "node-a",
        lease_expires_at: DateTime.add(now(), -60, :second),
        delivered_at: now(),
        last_error: "temporary outage"
      )

    {:ok, preview} =
      Lifeline.preview_repair(TestRepo, @actor, %{
        action: "callback_retry",
        target_type: "callback",
        target_id: callback.id
      })

    assert {:error, :reason_required} =
             Lifeline.execute_repair(TestRepo, @actor, preview.preview_token, "   ")

    assert {:ok, %{target: repaired, preview: consumed}} =
             Lifeline.execute_repair(
               TestRepo,
               @actor,
               preview.preview_token,
               "Retry after downstream outage resolved"
             )

    assert repaired.status == "pending"
    assert repaired.attempts == 4
    assert is_nil(repaired.claimed_at)
    assert is_nil(repaired.claimed_by)
    assert is_nil(repaired.lease_expires_at)
    assert is_nil(repaired.delivered_at)
    assert is_nil(repaired.last_error)
    assert consumed.status == "consumed"
    assert consumed.metadata["reason"] =~ "downstream outage"
    assert consumed.metadata["before"]["last_error"] == "temporary outage"

    repair_audit =
      Audit.list(%{type: :callback, id: callback.id}, repo: TestRepo)
      |> Enum.find(&(&1.action == "lifeline.repair_executed"))

    assert repair_audit
    assert repair_audit.resource_type == "callback"
    assert repair_audit.resource_id == callback.id

    assert {:error, :preview_consumed} =
             Lifeline.execute_repair(
               TestRepo,
               @actor,
               preview.preview_token,
               "Trying to consume a callback preview twice"
             )
  end

  @tag :phase62_callback_execute
  test "execute_repair rejects expired, drifted, and unauthorized callback previews" do
    batch = insert_batch!()
    callback = insert_callback!(batch, status: "failed", last_error: "before")

    {:ok, preview} =
      Lifeline.preview_repair(TestRepo, @actor, %{
        action: "callback_retry",
        target_type: "callback",
        target_id: callback.id
      })

    callback
    |> Callback.changeset(%{last_error: "after"})
    |> TestRepo.update!()

    assert {:error, :preview_drifted} =
             Lifeline.execute_repair(
               TestRepo,
               @actor,
               preview.preview_token,
               "Retry after dependency was corrected"
             )

    expired_callback = insert_callback!(batch, status: "failed")

    {:ok, expired_preview} =
      Lifeline.preview_repair(TestRepo, @actor, %{
        action: "callback_retry",
        target_type: "callback",
        target_id: expired_callback.id
      })

    expired_preview
    |> Ecto.Changeset.change(expires_at: DateTime.add(now(), -10, :second))
    |> TestRepo.update!()

    assert {:error, :preview_expired} =
             Lifeline.execute_repair(
               TestRepo,
               @actor,
               expired_preview.preview_token,
               "Retry after dependency was corrected"
             )

    unauthorized_callback = insert_callback!(batch, status: "failed")

    {:ok, unauthorized_preview} =
      Lifeline.preview_repair(TestRepo, @actor, %{
        action: "callback_retry",
        target_type: "callback",
        target_id: unauthorized_callback.id
      })

    assert {:error, :unauthorized} =
             Lifeline.execute_repair(
               TestRepo,
               %{id: "operator-2", permissions: []},
               unauthorized_preview.preview_token,
               "Unauthorized actor cannot retry callback"
             )
  end

  defp insert_batch! do
    %Batch{}
    |> Batch.changeset(%{
      status: "callback_failed",
      total_count: 1,
      success_count: 0,
      discard_count: 0,
      cancelled_count: 0,
      snooze_count: 0,
      inserted_count: 1,
      insert_chunk_count: 1,
      insert_failure: %{}
    })
    |> TestRepo.insert!()
  end

  defp insert_callback!(batch, attrs) do
    defaults = %{
      batch_id: batch.id,
      event: "batch.exhausted",
      dedupe_key: Ecto.UUID.generate(),
      status: "failed",
      payload: %{"batch_id" => batch.id, "chain_id" => "chain-a"},
      attempts: 1,
      available_at: now()
    }

    %Callback{}
    |> Callback.changeset(Map.merge(defaults, Map.new(attrs)))
    |> TestRepo.insert!()
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:microsecond)
end
