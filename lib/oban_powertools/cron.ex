defmodule ObanPowertools.Cron do
  @moduledoc """
  Durable cron entry sync, slot claim, and operator actions.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias ObanPowertools.{Audit, Telemetry}
  alias ObanPowertools.Cron.{Entry, Slot}
  alias ObanPowertools.Forensics.CronHistory
  alias ObanPowertools.Lifeline.RepairPreview

  @default_queue "default"
  @default_timezone "Etc/UTC"
  @default_overlap_policy "queue_one"
  @default_catch_up_policy "latest"
  @preview_ttl_seconds 30 * 60

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
        config_diff = cron_config_diff(entry, attrs)

        entry
        |> Entry.changeset(normalize_entry_attrs(attrs))
        |> repo.update()
        |> case do
          {:ok, updated_entry} = result ->
            maybe_record_reconfiguration(repo, entry, updated_entry, config_diff)
            result

          error ->
            error
        end
    end
  end

  def claim_slot(repo, entry, slot_at, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    args = normalize_job_args(entry.args)
    source = entry.source
    manual? = Keyword.get(opts, :manual?, false)

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
        metadata: %{"source" => source, "manual" => manual?}
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
        maybe_record_coverage(repo, entry, slot_at, manual?)
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

  def preview_entry_action(repo, action, %Entry{} = entry, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    with :ok <- validate_preview_action(action, entry),
         preview_attrs <- build_preview(entry, action, now) do
      existing =
        repo.one(
          from(preview in RepairPreview,
            where:
              preview.incident_fingerprint == ^preview_attrs.incident_fingerprint and
                preview.plan_hash == ^preview_attrs.plan_hash and
                preview.action == ^preview_attrs.action and
                preview.target_type == ^preview_attrs.target_type and
                preview.target_id == ^preview_attrs.target_id and preview.status == "ready",
            limit: 1
          )
        )

      preview = existing || repo.insert!(RepairPreview.changeset(%RepairPreview{}, preview_attrs))

      maybe_record_preview_audit(repo, action, entry, preview)

      {:ok, preview}
    end
  end

  def pause_cron_entry(repo, preview_token, actor_id, opts \\ []) do
    execute_preview_action(repo, "pause_cron_entry", preview_token, actor_id, opts)
  end

  def resume_cron_entry(repo, preview_token, actor_id, opts \\ []) do
    execute_preview_action(repo, "resume_cron_entry", preview_token, actor_id, opts)
  end

  def run_cron_entry(repo, preview_token, actor_id, opts \\ []) do
    execute_preview_action(repo, "run_cron_entry", preview_token, actor_id, opts)
  end

  def pause_entry(repo, %Entry{} = entry, actor_id, opts \\ []) do
    with {:ok, preview} <- preview_entry_action(repo, "pause_cron_entry", entry, opts) do
      pause_cron_entry(repo, preview.preview_token, actor_id, opts)
    end
  end

  def resume_entry(repo, %Entry{} = entry, actor_id, opts \\ []) do
    with {:ok, preview} <- preview_entry_action(repo, "resume_cron_entry", entry, opts) do
      resume_cron_entry(repo, preview.preview_token, actor_id, opts)
    end
  end

  def run_now(repo, %Entry{} = entry, actor_id, opts \\ []) do
    with {:ok, preview} <- preview_entry_action(repo, "run_cron_entry", entry, opts) do
      run_cron_entry(repo, preview.preview_token, actor_id, opts)
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

  def record_coverage(repo, %Entry{} = entry, slot_at, opts \\ []) do
    CronHistory.record_coverage(repo, entry, slot_at, opts)
  end

  defp execute_preview_action(repo, action, preview_token, actor_id, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    reason = blank_to_nil(Keyword.get(opts, :reason))

    with %RepairPreview{} = preview <- repo.get_by(RepairPreview, preview_token: preview_token),
         :ok <- ensure_preview_action(preview, action),
         {:ok, entry} <- load_preview_entry(repo, preview),
         :ok <- ensure_preview_available(repo, preview, now),
         :ok <- validate_reason(reason, preview.reason_required),
         :ok <- ensure_not_drifted(repo, preview, entry, now) do
      apply_preview_action(repo, action, entry, actor_id, preview, reason, now)
    else
      nil -> {:error, :preview_not_found}
      error -> error
    end
  end

  defp apply_preview_action(repo, "pause_cron_entry", entry, actor_id, preview, reason, now) do
    entry_changeset = Entry.changeset(entry, %{paused_at: now})
    event_metadata = execution_metadata(entry, preview, reason)

    Multi.new()
    |> Multi.update(:entry, entry_changeset)
    |> Multi.update(:preview, consume_preview_changeset(preview, reason, now))
    |> Multi.run(:audit, fn repo, %{entry: updated_entry, preview: preview_record} ->
      Audit.record(
        "cron.paused",
        %{type: :cron_entry, id: updated_entry.name},
        Map.put(event_metadata, "preview_token", preview_record.preview_token),
        repo: repo,
        actor_id: actor_id
      )
    end)
    |> repo.transaction()
    |> case do
      {:ok, %{entry: updated_entry}} ->
        Telemetry.execute_cron_event(:paused, %{count: 1}, %{
          action: "paused",
          source: entry.source,
          overlap_policy: entry.overlap_policy
        })

        Telemetry.execute_operator_action(:complete, %{count: 1}, %{
          action: "pause_cron_entry",
          source: entry.source
        })

        {:ok, updated_entry}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  defp apply_preview_action(repo, "resume_cron_entry", entry, actor_id, preview, reason, now) do
    entry_changeset =
      Entry.changeset(entry, %{paused_at: nil, last_run_at: entry.last_run_at || now})

    event_metadata = execution_metadata(entry, preview, reason)

    Multi.new()
    |> Multi.update(:entry, entry_changeset)
    |> Multi.update(:preview, consume_preview_changeset(preview, reason, now))
    |> Multi.run(:audit, fn repo, %{entry: updated_entry, preview: preview_record} ->
      Audit.record(
        "cron.resumed",
        %{type: :cron_entry, id: updated_entry.name},
        Map.put(event_metadata, "preview_token", preview_record.preview_token),
        repo: repo,
        actor_id: actor_id
      )
    end)
    |> repo.transaction()
    |> case do
      {:ok, %{entry: updated_entry}} ->
        Telemetry.execute_cron_event(:resumed, %{count: 1}, %{
          action: "resumed",
          source: entry.source,
          overlap_policy: entry.overlap_policy
        })

        Telemetry.execute_operator_action(:complete, %{count: 1}, %{
          action: "resume_cron_entry",
          source: entry.source
        })

        {:ok, updated_entry}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  defp apply_preview_action(repo, "run_cron_entry", entry, actor_id, preview, reason, now) do
    event_metadata = execution_metadata(entry, preview, reason)

    Multi.new()
    |> Multi.run(:result, fn repo, _changes ->
      claim_slot(repo, entry, truncate_to_minute(now), now: now, manual?: true)
    end)
    |> Multi.update(:preview, consume_preview_changeset(preview, reason, now))
    |> Multi.run(:audit, fn repo, %{result: result, preview: preview_record} ->
      Audit.record(
        "cron.run_now",
        %{type: :cron_entry, id: entry.name},
        event_metadata
        |> Map.put("decision", result.decision.decision)
        |> Map.put("preview_token", preview_record.preview_token),
        repo: repo,
        actor_id: actor_id
      )
    end)
    |> repo.transaction()
    |> case do
      {:ok, %{result: result}} ->
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

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
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
        {:ok, %{decision: "allow", args: args, active_job: nil, active_job_id: nil}}

      entry.overlap_policy == "skip" and active_job ->
        {:ok,
         %{decision: "skipped", args: args, active_job: active_job, active_job_id: active_job.id}}

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
          {:ok,
           %{
             decision: "skipped",
             args: args,
             active_job: active_job,
             active_job_id: active_job.id
           }}
        else
          {:ok,
           %{
             decision: "queued_follow_up",
             args: args,
             active_job: active_job,
             active_job_id: active_job.id
           }}
        end

      entry.overlap_policy == "cancel_previous" and active_job ->
        repo.update_all(
          from(job in Oban.Job, where: job.id == ^active_job.id),
          set: [state: "cancelled", cancelled_at: now]
        )

        {:ok,
         %{
           decision: "cancelled_previous",
           args: args,
           active_job: active_job,
           active_job_id: active_job.id
         }}

      true ->
        {:ok,
         %{
           decision: "enqueued",
           args: args,
           active_job: active_job,
           active_job_id: active_job && active_job.id
         }}
    end
  end

  defp maybe_insert_job(_repo, _entry, _args, %{decision: "skipped"}), do: {:ok, nil}
  defp maybe_insert_job(_repo, _entry, _args, %{decision: "queued_follow_up"}), do: {:ok, nil}
  defp maybe_insert_job(_repo, _entry, _args, %{decision: "duplicate"}), do: {:ok, nil}

  defp maybe_insert_job(repo, entry, args, _decision) do
    repo.insert(Oban.Job.new(args, worker: entry.worker, queue: String.to_atom(entry.queue)))
  end

  defp update_slot(repo, slot, %{decision: decision} = decision_data, job, now) do
    if decision == "duplicate" do
      {:ok, slot}
    else
      active_job_id = decision_data[:active_job_id]

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
        metadata:
          slot.metadata
          |> Kernel.||(%{})
          |> Map.put("decision", decision)
          |> maybe_put("active_job_id", active_job_id)
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

  defp build_preview(entry, action, now) do
    before_snapshot = cron_before_snapshot(entry)

    %{
      incident_class: "cron_entry",
      incident_fingerprint: "cron_entry:#{entry.name}",
      plan_hash: cron_plan_hash(action, entry, before_snapshot),
      preview_token: Ecto.UUID.generate(),
      action: action,
      target_type: "cron_entry",
      target_id: entry.id,
      status: "ready",
      affected_counts: affected_counts(action),
      before_snapshot: before_snapshot,
      after_snapshot: cron_after_snapshot(action, entry),
      evidence: %{"previewed_at" => now},
      reason_required: false,
      expires_at: DateTime.add(now, @preview_ttl_seconds, :second),
      metadata: %{
        "summary" => cron_summary(action, entry),
        "risk" => cron_risk(action),
        "resource" => %{"type" => "cron_entry", "id" => entry.name, "source" => entry.source}
      }
    }
  end

  defp cron_plan_hash(action, entry, before_snapshot) do
    Jason.encode!(%{
      action: action,
      target_type: "cron_entry",
      target_id: entry.id,
      before_snapshot: before_snapshot
    })
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp cron_before_snapshot(entry) do
    %{
      "name" => entry.name,
      "paused_at" => timestamp_or_nil(entry.paused_at),
      "last_run_at" => timestamp_or_nil(entry.last_run_at),
      "source" => entry.source,
      "overlap_policy" => entry.overlap_policy,
      "catch_up_policy" => entry.catch_up_policy
    }
  end

  defp cron_after_snapshot("pause_cron_entry", entry) do
    %{"name" => entry.name, "state" => "paused", "effect" => "future claims stop until resumed"}
  end

  defp cron_after_snapshot("resume_cron_entry", entry) do
    %{"name" => entry.name, "state" => "runnable", "effect" => "future claims may resume"}
  end

  defp cron_after_snapshot("run_cron_entry", entry) do
    %{"name" => entry.name, "effect" => "manual slot claim may enqueue work immediately"}
  end

  defp affected_counts("run_cron_entry"), do: %{"cron_entries" => 1, "cron_slots" => 1}
  defp affected_counts(_action), do: %{"cron_entries" => 1, "cron_slots" => 0}

  defp cron_summary("pause_cron_entry", entry),
    do: "Pause cron entry #{entry.name} until an operator resumes it."

  defp cron_summary("resume_cron_entry", entry),
    do: "Resume cron entry #{entry.name} so future claims can continue."

  defp cron_summary("run_cron_entry", entry),
    do: "Run cron entry #{entry.name} now through the native operator flow."

  defp cron_risk(_action), do: "low"

  defp maybe_record_preview_audit(repo, "run_cron_entry", entry, preview) do
    Audit.record(
      "cron.run_now_previewed",
      %{type: :cron_entry, id: entry.name},
      %{"preview_token" => preview.preview_token, "source" => entry.source},
      repo: repo
    )
  end

  defp maybe_record_preview_audit(_repo, _action, _entry, _preview), do: :ok

  defp validate_preview_action("pause_cron_entry", %Entry{paused_at: nil}), do: :ok
  defp validate_preview_action("pause_cron_entry", _entry), do: {:error, :preview_not_available}

  defp validate_preview_action("resume_cron_entry", %Entry{paused_at: nil}),
    do: {:error, :preview_not_available}

  defp validate_preview_action("resume_cron_entry", _entry), do: :ok
  defp validate_preview_action("run_cron_entry", _entry), do: :ok
  defp validate_preview_action(_action, _entry), do: {:error, :preview_not_available}

  defp ensure_preview_action(%RepairPreview{action: action}, action), do: :ok
  defp ensure_preview_action(_preview, _action), do: {:error, :preview_not_available}

  defp load_preview_entry(repo, preview) do
    case repo.get(Entry, preview.target_id) do
      nil -> {:error, :preview_not_available}
      entry -> {:ok, entry}
    end
  end

  defp ensure_preview_available(repo, preview, now) do
    case RepairPreview.execute_status(preview, now) do
      :ok ->
        :ok

      {:error, :preview_expired} ->
        preview
        |> RepairPreview.changeset(%{status: "expired"})
        |> repo.update!()

        {:error, :preview_expired}

      other ->
        other
    end
  end

  defp validate_reason(reason, false) when is_binary(reason), do: :ok
  defp validate_reason(nil, false), do: :ok
  defp validate_reason(_reason, false), do: :ok

  defp validate_reason(reason, true) when is_binary(reason) do
    trimmed = String.trim(reason)

    cond do
      trimmed == "" -> {:error, :reason_required}
      String.length(trimmed) < 8 -> {:error, :reason_too_short}
      true -> :ok
    end
  end

  defp validate_reason(_reason, true), do: {:error, :reason_required}

  defp ensure_not_drifted(repo, preview, entry, now) do
    current_hash = cron_plan_hash(preview.action, entry, cron_before_snapshot(entry))

    if current_hash == preview.plan_hash do
      :ok
    else
      preview
      |> RepairPreview.changeset(%{
        status: "drifted",
        metadata:
          preview.metadata
          |> Kernel.||(%{})
          |> Map.put("drift_reason", "Cron entry state changed after preview generation.")
          |> Map.put("drifted_at", DateTime.to_iso8601(now))
      })
      |> repo.update!()

      {:error, :preview_drifted}
    end
  end

  defp consume_preview_changeset(preview, reason, now) do
    RepairPreview.changeset(preview, %{
      status: "consumed",
      executed_at: now,
      consumed_at: now,
      metadata:
        preview.metadata
        |> Kernel.||(%{})
        |> maybe_put("reason", reason)
    })
  end

  defp execution_metadata(entry, preview, reason) do
    %{
      "source" => entry.source,
      "preview_token" => preview.preview_token,
      "summary" => get_in(preview.metadata, ["summary"]),
      "risk" => get_in(preview.metadata, ["risk"]),
      "resource" => get_in(preview.metadata, ["resource"])
    }
    |> maybe_put("reason", reason)
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

  defp maybe_record_coverage(_repo, _entry, _slot_at, true), do: :ok

  defp maybe_record_coverage(repo, entry, slot_at, false) do
    case record_coverage(repo, entry, slot_at, status: "healthy") do
      {:ok, _coverage} -> :ok
      {:error, _reason} -> :ok
    end
  end

  defp cron_config_diff(entry, attrs) do
    normalized = normalize_entry_attrs(attrs)

    tracked = [:expression, :timezone, :overlap_policy, :catch_up_policy, :max_catch_up, :queue]

    Enum.reduce(tracked, %{}, fn key, acc ->
      current = Map.get(entry, key)
      next_value = Map.get(normalized, key)

      if current != next_value do
        Map.put(acc, Atom.to_string(key), %{"before" => current, "after" => next_value})
      else
        acc
      end
    end)
  end

  defp maybe_record_reconfiguration(_repo, _before, _after, diff) when diff == %{}, do: :ok

  defp maybe_record_reconfiguration(repo, before_entry, updated_entry, diff) do
    Audit.record(
      "cron.reconfigured",
      %{type: :cron_entry, id: updated_entry.name},
      %{
        "event_type" => "cron.reconfigured",
        "before_name" => before_entry.name,
        "config_diff" => diff
      },
      repo: repo
    )
  end

  defp timestamp_or_nil(nil), do: nil
  defp timestamp_or_nil(%DateTime{} = value), do: DateTime.to_iso8601(value)

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
