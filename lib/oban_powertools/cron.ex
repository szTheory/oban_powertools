defmodule ObanPowertools.Cron do
  @moduledoc """
  Durable cron entry sync, slot claim, and operator actions.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias ObanPowertools.{Audit, Telemetry}
  alias ObanPowertools.Cron.{Entry, Slot}

  @default_queue "default"
  @default_timezone "Etc/UTC"
  @default_overlap_policy "queue_one"
  @default_catch_up_policy "latest"

  def sync_entry(repo, attrs) do
    source = Map.get(attrs, :source) || Map.get(attrs, "source") || "runtime"
    name = Map.get(attrs, :name) || Map.get(attrs, "name")

    case repo.get_by(Entry, name: name) do
      nil ->
        %Entry{}
        |> Entry.changeset(normalize_entry_attrs(attrs))
        |> repo.insert()

      %Entry{source: "code"} when source == "runtime" ->
        {:error, :code_managed_entry}

      %Entry{} = entry ->
        entry
        |> Entry.changeset(normalize_entry_attrs(attrs))
        |> repo.update()
    end
  end

  def claim_slot(repo, entry, slot_at, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    args = normalize_job_args(entry.args)
    source = entry.source

    Multi.new()
    |> Multi.insert(
      :slot,
      Slot.changeset(%Slot{}, %{
        entry_id: entry.id,
        slot_at: slot_at,
        state: "pending",
        claimed_at: now,
        attempt_count: 0,
        policy_snapshot: policy_snapshot(entry),
        metadata: %{"source" => source}
      }),
      on_conflict: :nothing,
      conflict_target: [:entry_id, :slot_at],
      returning: true
    )
    |> Multi.run(:current_slot, fn repo, _changes ->
      {:ok, repo.get_by!(Slot, entry_id: entry.id, slot_at: slot_at)}
    end)
    |> Multi.run(:decision, fn repo, %{slot: inserted_slot, current_slot: current_slot} ->
      inserted? = inserted_slot && inserted_slot.id == current_slot.id

      if not inserted? and current_slot.state != "pending" do
        {:ok, %{decision: "duplicate", args: args, active_job: nil}}
      else
        apply_overlap_policy(repo, entry, current_slot, args, now)
      end
    end)
    |> Multi.run(:job, fn repo, %{decision: decision} ->
      maybe_insert_job(repo, entry, args, decision)
    end)
    |> Multi.run(:updated_slot, fn repo,
                                   %{decision: decision, job: job, current_slot: current_slot} ->
      update_slot(repo, current_slot, decision, job, now)
    end)
    |> repo.transaction()
    |> case do
      {:ok, %{decision: decision, job: job, updated_slot: slot}} ->
        emit_claim_telemetry(entry, slot, decision)
        {:ok, %{slot: slot, job: job, decision: decision}}

      {:error, :decision, reason, _} ->
        {:error, reason}

      {:error, _step, reason, _} ->
        {:error, reason}
    end
  end

  def due_slots(_repo, entry, now, opts \\ []) do
    case entry.catch_up_policy do
      "latest" ->
        [truncate_to_minute(now)]

      "all" ->
        max = min(entry.max_catch_up, Keyword.get(opts, :max_catch_up, entry.max_catch_up))

        0..max
        |> Enum.map(fn index -> DateTime.add(truncate_to_minute(now), -60 * index, :second) end)
        |> Enum.reverse()
    end
  end

  def pause_entry(repo, entry, actor_id, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    metadata = operator_metadata(entry, opts)

    entry
    |> Entry.changeset(%{paused_at: now})
    |> repo.update()
    |> case do
      {:ok, updated} ->
        Audit.record(
          "cron.paused",
          %{type: :cron_entry, id: entry.name},
          metadata,
          repo: repo,
          actor_id: actor_id
        )

        Telemetry.execute_cron_event(:paused, %{count: 1}, %{
          action: "paused",
          source: entry.source,
          overlap_policy: entry.overlap_policy
        })

        Telemetry.execute_operator_action(:complete, %{count: 1}, %{
          action: "pause_cron_entry",
          source: entry.source
        })

        {:ok, updated}

      error ->
        error
    end
  end

  def resume_entry(repo, entry, actor_id, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    metadata = operator_metadata(entry, opts)

    entry
    |> Entry.changeset(%{paused_at: nil, last_run_at: entry.last_run_at || now})
    |> repo.update()
    |> case do
      {:ok, updated} ->
        Audit.record(
          "cron.resumed",
          %{type: :cron_entry, id: entry.name},
          metadata,
          repo: repo,
          actor_id: actor_id
        )

        Telemetry.execute_cron_event(:resumed, %{count: 1}, %{
          action: "resumed",
          source: entry.source,
          overlap_policy: entry.overlap_policy
        })

        Telemetry.execute_operator_action(:complete, %{count: 1}, %{
          action: "resume_cron_entry",
          source: entry.source
        })

        {:ok, updated}

      error ->
        error
    end
  end

  def run_now(repo, entry, actor_id, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    metadata = operator_metadata(entry, opts)

    Audit.record(
      "cron.run_now_previewed",
      %{type: :cron_entry, id: entry.name},
      metadata,
      repo: repo,
      actor_id: actor_id
    )

    Telemetry.execute_operator_action(:previewed, %{count: 1}, %{
      action: "run_now",
      source: entry.source
    })

    claim_slot(repo, entry, truncate_to_minute(now), now: now, manual?: true)
    |> case do
      {:ok, result} ->
        Audit.record(
          "cron.run_now",
          %{type: :cron_entry, id: entry.name},
          Map.put(metadata, "decision", result.decision),
          repo: repo,
          actor_id: actor_id
        )

        Telemetry.execute_cron_event(:run_now, %{count: 1}, %{
          action: "run_now",
          source: entry.source,
          overlap_policy: entry.overlap_policy
        })

        Telemetry.execute_operator_action(:complete, %{count: 1}, %{
          action: "run_cron_entry",
          source: entry.source
        })

        {:ok, result}

      other ->
        other
    end
  end

  def list_entries(repo), do: repo.all(from(entry in Entry, order_by: [asc: entry.name]))

  def list_slots(repo, entry_id),
    do:
      repo.all(
        from(slot in Slot, where: slot.entry_id == ^entry_id, order_by: [desc: slot.slot_at])
      )

  def latest_audit(repo, entry_name) do
    Audit.list(%{type: :cron_entry, id: entry_name}, repo: repo)
  end

  defp normalize_entry_attrs(attrs) do
    attrs
    |> Map.new(fn {key, value} -> {key, value} end)
    |> Map.put_new(:queue, @default_queue)
    |> Map.put_new(:timezone, @default_timezone)
    |> Map.put_new(:source, "runtime")
    |> Map.put_new(:args, %{})
    |> Map.put_new(:opts, %{})
    |> Map.put_new(:overlap_policy, @default_overlap_policy)
    |> Map.put_new(:catch_up_policy, @default_catch_up_policy)
    |> Map.put_new(:max_catch_up, 1)
    |> Map.put_new(:metadata, %{})
  end

  defp apply_overlap_policy(repo, entry, slot, args, now) do
    active_job =
      if entry.overlap_policy in ["queue_one", "skip", "cancel_previous"] do
        repo.one(
          from(oban_job in Oban.Job,
            where:
              oban_job.worker == ^entry.worker and oban_job.queue == ^entry.queue and
                oban_job.state in ["available", "scheduled", "executing", "retryable"],
            order_by: [desc: oban_job.inserted_at],
            limit: 1
          )
        )
      end

    cond do
      entry.paused_at ->
        {:error, :paused}

      entry.overlap_policy == "allow" ->
        {:ok, %{decision: "allow", args: args, active_job: nil}}

      entry.overlap_policy == "skip" and active_job ->
        {:ok, %{decision: "skipped", args: args, active_job: active_job}}

      entry.overlap_policy == "queue_one" and active_job ->
        pending_exists? =
          repo.exists?(
            from(existing in Slot,
              where:
                existing.entry_id == ^entry.id and existing.state == "queued_follow_up" and
                  existing.slot_at < ^slot.slot_at
            )
          )

        if pending_exists? do
          {:ok, %{decision: "skipped", args: args, active_job: active_job}}
        else
          {:ok, %{decision: "queued_follow_up", args: args, active_job: active_job}}
        end

      entry.overlap_policy == "cancel_previous" and active_job ->
        repo.update_all(
          from(job in Oban.Job, where: job.id == ^active_job.id),
          set: [state: "cancelled", cancelled_at: now]
        )

        {:ok, %{decision: "cancelled_previous", args: args, active_job: active_job}}

      true ->
        {:ok, %{decision: "enqueued", args: args, active_job: active_job}}
    end
  end

  defp maybe_insert_job(_repo, _entry, _args, %{decision: "skipped"}), do: {:ok, nil}
  defp maybe_insert_job(_repo, _entry, _args, %{decision: "queued_follow_up"}), do: {:ok, nil}
  defp maybe_insert_job(_repo, _entry, _args, %{decision: "duplicate"}), do: {:ok, nil}

  defp maybe_insert_job(repo, entry, args, _decision) do
    repo.insert(Oban.Job.new(args, worker: entry.worker, queue: String.to_atom(entry.queue)))
  end

  defp update_slot(repo, slot, %{decision: decision}, job, now) do
    if decision == "duplicate" do
      {:ok, slot}
    else
      state =
        case decision do
          "skipped" -> "skipped"
          "queued_follow_up" -> "queued_follow_up"
          "cancelled_previous" -> "claimed"
          _ -> "claimed"
        end

      slot
      |> Slot.changeset(%{
        state: state,
        job_id: job && job.id,
        claim_token: slot.claim_token || Ecto.UUID.generate(),
        claimed_at: slot.claimed_at || now,
        attempt_count: slot.attempt_count + 1,
        metadata: Map.put(slot.metadata || %{}, "decision", decision)
      })
      |> repo.update()
    end
  end

  defp emit_claim_telemetry(entry, slot, %{decision: decision}) do
    Telemetry.execute_cron_event(:slot_claimed, %{count: 1}, %{
      action: decision,
      source: entry.source,
      overlap_policy: entry.overlap_policy,
      catch_up_policy: entry.catch_up_policy
    })

    Audit.record(
      "cron.slot_claimed",
      %{type: :cron_entry, id: entry.name},
      %{"slot_at" => slot.slot_at, "decision" => decision, "source" => entry.source},
      repo: Application.get_env(:oban_powertools, :repo)
    )
  end

  defp normalize_job_args(args) when is_map(args), do: args
  defp normalize_job_args(args), do: %{"payload" => args}

  defp policy_snapshot(entry) do
    %{
      "source" => entry.source,
      "overlap_policy" => entry.overlap_policy,
      "catch_up_policy" => entry.catch_up_policy,
      "timezone" => entry.timezone
    }
  end

  defp truncate_to_minute(%DateTime{} = dt) do
    %DateTime{dt | second: 0, microsecond: {0, 0}}
  end

  defp operator_metadata(entry, opts) do
    %{"source" => entry.source}
    |> maybe_put("reason", Keyword.get(opts, :reason))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
