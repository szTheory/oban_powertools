defmodule ObanPowertools.CronTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Cron
  alias ObanPowertools.Cron.{Entry, Slot}
  alias ObanPowertools.Lifeline.RepairPreview

  test "sync_entry persists code and runtime entries through one path" do
    assert {:ok, %Entry{} = entry} =
             Cron.sync_entry(repo(), %{
               name: "nightly",
               source: "code",
               worker: "Example.Worker",
               expression: "* * * * *",
               timezone: "Etc/UTC"
             })

    assert entry.source == "code"

    assert {:error, :code_managed_entry} =
             Cron.sync_entry(repo(), %{
               name: "nightly",
               source: "runtime",
               worker: "Example.Worker",
               expression: "* * * * *"
             })
  end

  test "claim_slot creates a durable slot and enqueues a job" do
    {:ok, entry} = runtime_entry(overlap_policy: "allow")
    slot_at = DateTime.utc_now() |> truncate_minute()

    assert {:ok, %{slot: %Slot{} = slot, job: %Oban.Job{} = job, decision: %{decision: "allow"}}} =
             Cron.claim_slot(repo(), entry, slot_at)

    assert slot.job_id == job.id
    assert DateTime.compare(slot.slot_at, slot_at) == :eq
  end

  test "duplicate slot claims reuse the same durable slot" do
    {:ok, entry} = runtime_entry(overlap_policy: "allow")
    slot_at = DateTime.utc_now() |> truncate_minute()

    assert {:ok, %{slot: first_slot}} = Cron.claim_slot(repo(), entry, slot_at)
    assert {:ok, %{slot: second_slot}} = Cron.claim_slot(repo(), entry, slot_at)

    assert first_slot.id == second_slot.id
    assert length(Cron.list_slots(repo(), entry.id)) == 1
  end

  test "queue_one preserves one queued follow-up while work is active" do
    {:ok, entry} = runtime_entry(overlap_policy: "queue_one")
    now = DateTime.utc_now() |> truncate_minute()

    assert {:ok, %{decision: %{decision: "enqueued"}}} = Cron.claim_slot(repo(), entry, now)

    assert {:ok, %{decision: %{decision: "queued_follow_up"}, slot: second_slot}} =
             Cron.claim_slot(repo(), entry, DateTime.add(now, 60, :second))

    assert second_slot.state == "queued_follow_up"

    assert {:ok, %{decision: %{decision: "skipped"}}} =
             Cron.claim_slot(repo(), entry, DateTime.add(now, 120, :second))
  end

  test "skip policy skips when an active run exists" do
    {:ok, entry} = runtime_entry(overlap_policy: "skip")
    now = DateTime.utc_now() |> truncate_minute()

    assert {:ok, %{decision: %{decision: "enqueued"}}} = Cron.claim_slot(repo(), entry, now)

    assert {:ok, %{decision: %{decision: "skipped"}, job: nil}} =
             Cron.claim_slot(repo(), entry, DateTime.add(now, 60, :second))
  end

  test "cancel_previous cancels the active job before enqueuing the next slot" do
    {:ok, entry} = runtime_entry(overlap_policy: "cancel_previous")
    now = DateTime.utc_now() |> truncate_minute()

    assert {:ok, %{job: first_job}} = Cron.claim_slot(repo(), entry, now)

    assert {:ok, %{job: second_job, decision: %{decision: "cancelled_previous"}}} =
             Cron.claim_slot(repo(), entry, DateTime.add(now, 60, :second))

    cancelled = repo().get!(Oban.Job, first_job.id)
    assert cancelled.state == "cancelled"
    assert second_job.id != first_job.id
  end

  test "latest catch-up returns one due slot and all returns bounded replay" do
    {:ok, latest_entry} = runtime_entry(catch_up_policy: "latest", max_catch_up: 3)
    {:ok, all_entry} = runtime_entry(name: "all", catch_up_policy: "all", max_catch_up: 2)
    now = DateTime.utc_now() |> truncate_minute()

    assert [^now] = Cron.due_slots(repo(), latest_entry, now)
    assert [_, _, _] = Cron.due_slots(repo(), all_entry, now)
  end

  test "cron previews persist durable preview rows and reuse them for the same action and entry" do
    {:ok, entry} = runtime_entry(name: "previewable", overlap_policy: "allow")

    assert {:ok, first_preview} = Cron.preview_entry_action(repo(), "pause_cron_entry", entry)
    assert {:ok, second_preview} = Cron.preview_entry_action(repo(), "pause_cron_entry", entry)

    assert first_preview.id == second_preview.id
    assert first_preview.status == "ready"
    assert first_preview.reason_required == false
    assert first_preview.metadata["summary"] =~ entry.name
    assert first_preview.metadata["risk"] == "low"
    assert first_preview.metadata["resource"]["id"] == entry.name
  end

  test "pause, resume, and run_now reject invalid preview states before mutation writes" do
    {:ok, entry} = runtime_entry(name: "stateful", overlap_policy: "allow")
    now = truncate_minute(DateTime.utc_now())

    assert {:ok, paused_preview} = Cron.preview_entry_action(repo(), "pause_cron_entry", entry, now: now)
    assert {:ok, paused} = Cron.pause_cron_entry(repo(), paused_preview.preview_token, "operator-1")
    assert paused.paused_at

    assert {:error, :preview_consumed} =
             Cron.pause_cron_entry(repo(), paused_preview.preview_token, "operator-1")

    assert {:ok, resume_preview} =
             Cron.preview_entry_action(repo(), "resume_cron_entry", paused, now: now)

    resume_preview
    |> RepairPreview.changeset(%{status: "expired"})
    |> repo().update!()

    assert {:error, :preview_expired} =
             Cron.resume_cron_entry(repo(), resume_preview.preview_token, "operator-1")

    assert {:ok, run_preview} =
             Cron.preview_entry_action(repo(), "run_cron_entry", paused, now: now)

    run_preview
    |> RepairPreview.changeset(%{status: "drifted", metadata: %{"drift_reason" => "entry changed"}})
    |> repo().update!()

    assert {:error, :preview_drifted} =
             Cron.run_cron_entry(repo(), run_preview.preview_token, "operator-1")

    unchanged_entry = repo().get!(Entry, entry.id)
    assert unchanged_entry.paused_at
    assert repo().aggregate(Slot, :count, :id) == 0
  end

  test "pause, resume, and run_now are audited and telemetry-visible through durable writes" do
    {:ok, entry} = runtime_entry(name: "manual", overlap_policy: "allow")

    assert {:ok, pause_preview} = Cron.preview_entry_action(repo(), "pause_cron_entry", entry)
    assert {:ok, paused} = Cron.pause_cron_entry(repo(), pause_preview.preview_token, "operator-1")
    assert paused.paused_at

    assert {:ok, resume_preview} = Cron.preview_entry_action(repo(), "resume_cron_entry", paused)
    assert {:ok, resumed} = Cron.resume_cron_entry(repo(), resume_preview.preview_token, "operator-1")
    refute resumed.paused_at

    assert {:ok, run_preview} = Cron.preview_entry_action(repo(), "run_cron_entry", resumed)

    assert {:ok, %{slot: %Slot{}, decision: %{decision: "allow"}}} =
             Cron.run_cron_entry(repo(), run_preview.preview_token, "operator-1")

    actions =
      Cron.latest_audit(repo(), entry.name)
      |> Enum.map(& &1.action)

    assert "cron.paused" in actions
    assert "cron.resumed" in actions
    assert "cron.run_now_previewed" in actions
    assert "cron.run_now" in actions
  end

  defp runtime_entry(overrides) do
    attrs =
      overrides
      |> Enum.into(%{
        name: "runtime-#{System.unique_integer([:positive])}",
        source: "runtime",
        worker: "Example.Worker",
        queue: "default",
        expression: "* * * * *",
        timezone: "Etc/UTC",
        overlap_policy: "queue_one",
        catch_up_policy: "latest",
        max_catch_up: 1
      })

    Cron.sync_entry(repo(), attrs)
  end

  defp truncate_minute(%DateTime{} = dt), do: %DateTime{dt | second: 0, microsecond: {0, 0}}
  defp repo, do: ObanPowertools.TestRepo
end
