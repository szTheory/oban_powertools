defmodule ObanPowertools.Lifeline do
  @moduledoc """
  Durable heartbeat refresh, health classification, and incident projection.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias ObanPowertools.{Audit, Auth, Explain}
  alias ObanPowertools.Lifeline.{ArchiveRun, Heartbeat, Incident, RepairPreview}
  alias ObanPowertools.Telemetry
  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.{Runtime, Step}
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord

  @heartbeat_warning_ms 45_000
  @heartbeat_missing_ms 120_000
  @heartbeat_retention_seconds 6 * 60 * 60
  @preview_retention_seconds 7 * 24 * 60 * 60
  @audit_retention_seconds 90 * 24 * 60 * 60
  @supported_actions ~w(job_rescue job_retry job_cancel workflow_step_retry workflow_step_cancel workflow_request_cancel)

  def refresh_heartbeats(repo, executors, opts \\ []) when is_list(executors) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    result =
      Enum.reduce_while(executors, {:ok, []}, fn executor, {:ok, acc} ->
        attrs = normalize_heartbeat(executor, now)

        changeset =
          %Heartbeat{}
          |> Heartbeat.changeset(attrs)

        case repo.insert(changeset,
               on_conflict: {:replace, heartbeat_upsert_fields()},
               conflict_target: [:executor_id],
               returning: true
             ) do
          {:ok, heartbeat} -> {:cont, {:ok, [heartbeat | acc]}}
          {:error, changeset} -> {:halt, {:error, changeset}}
        end
      end)

    case result do
      {:ok, heartbeats} ->
        Telemetry.execute_lifeline_event(:heartbeat_refresh, %{count: length(heartbeats)}, %{
          action: "heartbeat_refresh"
        })

        {:ok, Enum.reverse(heartbeats)}

      error ->
        error
    end
  end

  def list_executor_health(repo, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    repo.all(from(heartbeat in Heartbeat, order_by: [asc: heartbeat.executor_id]))
    |> Enum.map(fn heartbeat ->
      status = classify_heartbeat(heartbeat, now)

      if heartbeat.health_state != status do
        {:ok, _heartbeat} =
          heartbeat
          |> Heartbeat.changeset(%{health_state: status})
          |> repo.update()
      end

      %{
        heartbeat: heartbeat,
        health_state: status,
        health_label: health_label(status),
        executor_id: heartbeat.executor_id,
        last_heartbeat_at: heartbeat.last_heartbeat_at
      }
    end)
  end

  def list_incidents(repo, opts \\ []) do
    status = Keyword.get(opts, :status)

    query =
      from(incident in Incident,
        order_by: [asc: incident.incident_class, asc: incident.inserted_at]
      )

    query =
      if status do
        from(incident in query, where: incident.status == ^status)
      else
        query
      end

    repo.all(query)
  end

  def project_incidents(repo, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    health_rows = list_executor_health(repo, now: now)

    dead_executor_incidents =
      Enum.flat_map(health_rows, fn row ->
        if row.health_state == "missing" do
          case upsert_dead_executor_incident(repo, row.heartbeat, now) do
            nil -> []
            incident -> [incident]
          end
        else
          []
        end
      end)

    workflow_stuck_incidents =
      repo.all(from(step in Step, order_by: [asc: step.inserted_at]))
      |> Enum.filter(&workflow_stuck?/1)
      |> Enum.map(&upsert_workflow_stuck_incident(repo, &1, now))

    active_incidents = dead_executor_incidents ++ workflow_stuck_incidents

    reconcile_inactive_incidents(repo, active_incidents, now)

    Telemetry.execute_lifeline_event(
      :incident_projection,
      %{count: length(active_incidents)},
      %{action: "incident_projection"}
    )

    active_incidents
  end

  def classify_heartbeat(%Heartbeat{} = heartbeat, now \\ DateTime.utc_now()) do
    age_ms = DateTime.diff(now, heartbeat.last_heartbeat_at, :millisecond)

    cond do
      age_ms >= heartbeat.missing_threshold_ms -> "missing"
      age_ms >= heartbeat.warning_threshold_ms -> "late"
      true -> "healthy"
    end
  end

  def health_label("healthy"), do: "Healthy"
  def health_label("late"), do: "Heartbeat Late"
  def health_label("missing"), do: "Executor Missing"
  def health_label(other), do: other

  def preview_repair(repo, actor, attrs, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    attrs = Enum.into(attrs, %{})

    with :ok <- authorize(actor, :preview_repair, attrs),
         {:ok, preview_attrs} <- build_preview(repo, attrs, now) do
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

      preview =
        existing ||
          repo.insert!(RepairPreview.changeset(%RepairPreview{}, preview_attrs))

      Telemetry.execute_lifeline_event(:repair_previewed, %{count: 1}, %{
        action: preview.action,
        incident_class: preview.incident_class,
        target_type: preview.target_type
      })

      {:ok, preview}
    end
  end

  def execute_repair(repo, actor, preview_token, reason, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    with %RepairPreview{} = preview <- repo.get_by(RepairPreview, preview_token: preview_token),
         :ok <- authorize(actor, :execute_repair, %{preview_token: preview.preview_token}),
         :ok <- ensure_preview_available(repo, preview, now),
         :ok <- validate_reason(reason, preview.reason_required),
         {:ok, current_hash} <- recompute_plan_hash(repo, preview),
         :ok <- ensure_not_drifted(repo, preview, current_hash, now),
         {:ok, result} <- apply_repair(repo, preview, actor, reason, now) do
      {:ok, result}
    else
      nil -> {:error, :preview_not_found}
      error -> error
    end
  end

  def run_archive_prune(repo, actor, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    reason = Keyword.get(opts, :reason)
    batch_size = Keyword.get(opts, :batch_size, 100)
    run_type = Keyword.get(opts, :run_type, "manual")

    {:ok, run} =
      %ArchiveRun{}
      |> ArchiveRun.changeset(%{
        run_type: run_type,
        status: "running",
        retention_class: "phase_4",
        actor_id: Auth.actor_id(actor),
        reason: reason,
        batch_size: batch_size,
        started_at: now,
        metadata: %{}
      })
      |> repo.insert()

    result =
      repo.transaction(fn ->
        archive_count =
          archive_due_repair_audits(
            repo,
            run,
            now,
            batch_size,
            Keyword.get(opts, :force_archive_failure, false)
          )

        audit_cutoff =
          DateTime.add(now, -@audit_retention_seconds, :second) |> DateTime.to_naive()

        preview_cutoff = DateTime.add(now, -@preview_retention_seconds, :second)
        heartbeat_cutoff = DateTime.add(now, -@heartbeat_retention_seconds, :second)

        {deleted_audits, _} =
          repo.delete_all(
            from(event in Audit,
              where:
                event.action == "lifeline.repair_executed" and event.inserted_at < ^audit_cutoff
            )
          )

        if deleted_audits != archive_count do
          repo.rollback(:archive_mismatch)
        end

        {pruned_previews, _} =
          repo.delete_all(
            from(preview in ObanPowertools.Lifeline.RepairPreview,
              where:
                not is_nil(preview.consumed_at) and
                  preview.inserted_at < ^DateTime.to_naive(preview_cutoff)
            )
          )

        {pruned_heartbeats, _} =
          repo.delete_all(
            from(heartbeat in Heartbeat, where: heartbeat.last_heartbeat_at < ^heartbeat_cutoff)
          )

        {archive_count, deleted_audits, pruned_previews, pruned_heartbeats}
      end)

    case result do
      {:ok, {archive_count, _deleted_audits, pruned_previews, pruned_heartbeats}} ->
        {:ok, updated_run} =
          run
          |> ArchiveRun.changeset(%{
            status: "completed",
            archived_count: archive_count,
            pruned_count: pruned_previews + pruned_heartbeats,
            blocked_count: 0,
            finished_at: now
          })
          |> repo.update()

        Telemetry.execute_lifeline_event(:archive_prune_completed, %{count: 1}, %{
          action: "archive_prune",
          outcome: "ok",
          archived_count: archive_count,
          pruned_count: pruned_previews + pruned_heartbeats
        })

        {:ok, updated_run}

      {:error, reason_error} ->
        {:ok, failed_run} =
          run
          |> ArchiveRun.changeset(%{
            status: "failed",
            blocked_count: 1,
            finished_at: now
          })
          |> repo.update()

        Telemetry.execute_lifeline_event(:archive_prune_completed, %{count: 1}, %{
          action: "archive_prune",
          outcome: "blocked",
          archived_count: 0,
          pruned_count: 0
        })

        {:error, {reason_error, failed_run}}
    end
  end

  def retention_status(repo) do
    last_run =
      repo.one(
        from(run in ArchiveRun,
          order_by: [desc: run.inserted_at],
          limit: 1
        )
      )

    %{
      last_run: last_run,
      heartbeat_samples: repo.aggregate(Heartbeat, :count, :id),
      pending_previews:
        repo.aggregate(
          from(preview in RepairPreview, where: preview.status in ["ready", "drifted"]),
          :count,
          :id
        ),
      archived_repairs: archive_table_count(repo)
    }
  end

  defp normalize_heartbeat(attrs, now) do
    attrs = Enum.into(attrs, %{})

    %{
      executor_id: fetch_value!(attrs, :executor_id),
      oban_name: Map.get(attrs, :oban_name) || Map.get(attrs, "oban_name") || "Oban",
      node: fetch_value!(attrs, :node),
      queue: Map.get(attrs, :queue) || Map.get(attrs, "queue") || "default",
      producer_scope: fetch_value!(attrs, :producer_scope),
      health_state: "healthy",
      last_heartbeat_at:
        Map.get(attrs, :last_heartbeat_at) || Map.get(attrs, "last_heartbeat_at") || now,
      warning_threshold_ms:
        Map.get(attrs, :warning_threshold_ms) || Map.get(attrs, "warning_threshold_ms") ||
          @heartbeat_warning_ms,
      missing_threshold_ms:
        Map.get(attrs, :missing_threshold_ms) || Map.get(attrs, "missing_threshold_ms") ||
          @heartbeat_missing_ms,
      metadata: Map.get(attrs, :metadata) || Map.get(attrs, "metadata") || %{}
    }
  end

  defp heartbeat_upsert_fields do
    [
      :oban_name,
      :node,
      :queue,
      :producer_scope,
      :health_state,
      :last_heartbeat_at,
      :warning_threshold_ms,
      :missing_threshold_ms,
      :metadata,
      :updated_at
    ]
  end

  defp upsert_dead_executor_incident(repo, heartbeat, now) do
    %{jobs: jobs, workflow_steps: workflow_steps} =
      dead_executor_evidence(repo, heartbeat.executor_id)

    if jobs == [] and workflow_steps == [] do
      nil
    else
      attrs = %{
        incident_class: "dead_executor",
        status: "active",
        executor_id: heartbeat.executor_id,
        incident_fingerprint: "dead_executor:#{heartbeat.executor_id}",
        health_state: "missing",
        summary: "#{health_label("missing")} for #{heartbeat.executor_id}",
        affected_counts: %{
          "jobs" => length(jobs),
          "workflow_steps" => length(workflow_steps)
        },
        evidence: %{
          "last_heartbeat_at" => heartbeat.last_heartbeat_at,
          "job_ids" => Enum.map(jobs, & &1.id),
          "workflow_step_ids" => Enum.map(workflow_steps, & &1.id)
        },
        first_detected_at: now,
        last_detected_at: now,
        metadata: %{
          "queue" => heartbeat.queue,
          "producer_scope" => heartbeat.producer_scope
        }
      }

      upsert_incident(repo, attrs)
    end
  end

  defp upsert_workflow_stuck_incident(repo, step, now) do
    story = Explain.step_story(step, repo: repo)
    diagnosis = story.diagnosis || "blocked"

    attrs = %{
      incident_class: "workflow_stuck",
      status: "active",
      workflow_id: step.workflow_id,
      workflow_step_id: step.id,
      incident_fingerprint: "workflow_stuck:#{step.workflow_id}:#{step.step_name}",
      health_state: nil,
      summary: "Workflow step #{step.step_name} is #{diagnosis}",
      affected_counts: %{
        "workflow_steps" => 1,
        "blocked_descendants" =>
          step.dependency_snapshot
          |> Map.get("dependencies", [])
          |> length()
      },
      evidence: %{
        "step_name" => step.step_name,
        "diagnosis" => diagnosis,
        "blocker_codes" => step.blocker_codes,
        "blocker_summaries" => story.blocker_summaries,
        "dependency_snapshot" => step.dependency_snapshot,
        "latest_rejection" => story.rejection_summary
      },
      first_detected_at: now,
      last_detected_at: now,
      metadata: %{}
    }

    upsert_incident(repo, attrs)
  end

  defp upsert_incident(repo, attrs) do
    attrs =
      attrs
      |> Map.put(:status, "active")
      |> Map.put(:resolved_at, nil)

    case repo.get_by(Incident, incident_fingerprint: attrs.incident_fingerprint) do
      nil ->
        {:ok, incident} =
          %Incident{}
          |> Incident.changeset(attrs)
          |> repo.insert()

        incident

      incident ->
        {:ok, updated} =
          incident
          |> Incident.changeset(Map.put(attrs, :first_detected_at, incident.first_detected_at))
          |> repo.update()

        updated
    end
  end

  defp reconcile_inactive_incidents(repo, active_incidents, now) do
    active_fingerprints =
      active_incidents
      |> Enum.map(& &1.incident_fingerprint)
      |> MapSet.new()

    repo.all(from(incident in Incident, where: incident.status == "active"))
    |> Enum.reject(&MapSet.member?(active_fingerprints, &1.incident_fingerprint))
    |> Enum.each(&resolve_incident_row(repo, &1, now))
  end

  defp resolve_incident_row(repo, incident, now) do
    {:ok, resolved} =
      incident
      |> Incident.changeset(%{
        status: "resolved",
        resolved_at: now,
        last_detected_at: now
      })
      |> repo.update()

    resolved
  end

  defp dead_executor_evidence(repo, executor_id) do
    %{
      jobs:
        repo.all(
          from(job in Oban.Job,
            where:
              job.state == "executing" and
                fragment("?->>'executor_id' = ?", job.meta, ^executor_id)
          )
        ),
      workflow_steps:
        repo.all(
          from(step in Step,
            where:
              step.state == "executing" and
                fragment("?->>'executor_id' = ?", step.context, ^executor_id)
          )
        )
    }
  end

  defp workflow_stuck?(%Step{state: state, blocker_codes: blocker_codes})
       when state in ["pending", "retryable"] do
    blocker_codes != []
  end

  defp workflow_stuck?(_step), do: false

  defp archive_due_repair_audits(repo, run, now, batch_size, force_failure?) do
    if force_failure? do
      repo.rollback(:archive_failed)
    end

    audit_cutoff = DateTime.add(now, -@audit_retention_seconds, :second) |> DateTime.to_naive()

    rows =
      repo.all(
        from(event in Audit,
          where: event.action == "lifeline.repair_executed" and event.inserted_at < ^audit_cutoff,
          order_by: [asc: event.inserted_at],
          limit: ^batch_size
        )
      )
      |> Enum.map(fn event ->
        %{
          id: Ecto.UUID.dump!(Ecto.UUID.generate()),
          archive_run_id: Ecto.UUID.dump!(run.id),
          audit_event_id: event.id,
          resource_type: archive_resource_type(event.resource),
          resource_id: archive_resource_id(event.resource),
          action: event.action,
          incident_class: event.metadata["incident_class"],
          incident_fingerprint: event.metadata["incident_fingerprint"],
          plan_hash: event.metadata["plan_hash"],
          reason: event.metadata["reason"],
          actor_id: event.actor_id,
          affected_counts: event.metadata["affected_counts"] || %{},
          evidence: event.metadata,
          archived_at: now,
          metadata: %{},
          inserted_at: DateTime.to_naive(now)
        }
      end)

    case rows do
      [] ->
        0

      _ ->
        {count, _} = repo.insert_all("oban_powertools_repair_archives", rows)
        count
    end
  end

  defp archive_resource_type(resource) do
    resource |> String.split(":", parts: 2) |> List.first()
  end

  defp archive_resource_id(resource) do
    case String.split(resource, ":", parts: 2) do
      [_type, id] -> id
      [id] -> id
    end
  end

  defp archive_table_count(repo) do
    %{rows: [[count]]} =
      Ecto.Adapters.SQL.query!(repo, "SELECT count(*) FROM oban_powertools_repair_archives", [])

    count
  end

  defp authorize(actor, action, resource) do
    if Auth.authorize(actor, action, resource), do: :ok, else: {:error, :unauthorized}
  end

  defp build_preview(repo, attrs, now) do
    action = fetch_value!(attrs, :action)
    target_type = fetch_value!(attrs, :target_type)
    target_id = fetch_value!(attrs, :target_id)

    if action not in @supported_actions do
      {:error, :unsupported_action}
    else
      incident = resolve_incident(repo, attrs)

      case {target_type, action} do
        {"job", action} when action in ["job_rescue", "job_retry", "job_cancel"] ->
          build_job_preview(repo, incident, target_id, action, now)

        {"workflow_step", action}
        when action in ["workflow_step_retry", "workflow_step_cancel"] ->
          build_workflow_step_preview(repo, incident, target_id, action, now)

        {"workflow", "workflow_request_cancel"} ->
          build_workflow_preview(repo, incident, target_id, action, now)

        _ ->
          {:error, :unsupported_target}
      end
    end
  end

  defp build_job_preview(repo, incident, target_id, action, now) do
    job = repo.get!(Oban.Job, target_id)
    incident_fingerprint = incident_fingerprint_for_job(job, incident)
    health_state = incident && incident.health_state

    cond do
      health_state == "late" ->
        {:error, :heartbeat_late}

      action == "job_rescue" and health_state != "missing" ->
        {:error, :repair_requires_missing_executor}

      true ->
        before_state = %{
          "job_id" => job.id,
          "state" => job.state,
          "executor_id" => get_in(job.meta, ["executor_id"])
        }

        after_state = %{"job_id" => job.id, "state" => next_job_state(action)}

        preview = %{
          incident_id: incident && incident.id,
          incident_class: (incident && incident.incident_class) || infer_incident_class(action),
          incident_fingerprint: incident_fingerprint,
          plan_hash: plan_hash(action, "job", target_id, before_state, health_state),
          preview_token: Ecto.UUID.generate(),
          action: action,
          target_type: "job",
          target_id: to_string(target_id),
          health_state: health_state,
          status: "ready",
          affected_counts: %{"jobs" => 1, "workflow_steps" => 0},
          before_snapshot: before_state,
          after_snapshot: after_state,
          evidence: %{"previewed_at" => now},
          reason_required: true,
          expires_at: DateTime.add(now, 7 * 24 * 60 * 60, :second),
          metadata: %{
            "summary" => repair_summary(action, "job", target_id),
            "risk" => "high",
            "resource" => %{"type" => "job", "id" => to_string(target_id)}
          }
        }

        {:ok,
         put_preview_runbook_context(preview, %{
           "diagnosis_state" => diagnosis_state_for_preview(incident, health_state),
           "evidence_completeness" => evidence_completeness_for_preview(incident)
         })}
    end
  end

  defp build_workflow_step_preview(repo, incident, target_id, action, now) do
    step = repo.get!(Step, target_id)
    story = Explain.step_story(step, repo: repo)

    before_state = %{
      "step_id" => step.id,
      "state" => step.state,
      "blocker_codes" => step.blocker_codes,
      "diagnosis" => story.diagnosis,
      "latest_rejection" => story.rejection_summary
    }

    after_state = %{"step_id" => step.id, "state" => next_step_state(action)}

    incident_fingerprint =
      (incident && incident.incident_fingerprint) || "workflow_step:#{step.id}"

    preview = %{
      incident_id: incident && incident.id,
      incident_class: (incident && incident.incident_class) || "workflow_stuck",
      incident_fingerprint: incident_fingerprint,
      plan_hash:
        plan_hash(
          action,
          "workflow_step",
          target_id,
          before_state,
          incident && incident.health_state
        ),
      preview_token: Ecto.UUID.generate(),
      action: action,
      target_type: "workflow_step",
      target_id: to_string(target_id),
      health_state: incident && incident.health_state,
      status: "ready",
      affected_counts: %{"jobs" => 0, "workflow_steps" => 1},
      before_snapshot: before_state,
      after_snapshot: after_state,
      evidence: %{"previewed_at" => now},
      reason_required: true,
      expires_at: DateTime.add(now, 7 * 24 * 60 * 60, :second),
      metadata: %{
        "summary" => repair_summary(action, "workflow_step", target_id),
        "risk" => "high",
        "diagnosis" => story.diagnosis,
        "latest_rejection" => story.rejection_summary,
        "resource" => %{"type" => "workflow_step", "id" => to_string(target_id)}
      }
    }

    {:ok,
     put_preview_runbook_context(preview, %{
       "diagnosis_state" => story.diagnosis || "needs_review",
       "evidence_completeness" => evidence_completeness_for_preview(incident)
     })}
  end

  defp build_workflow_preview(repo, incident, target_id, action, now) do
    workflow = repo.get!(WorkflowRecord, target_id)

    steps =
      repo.all(
        from(step in Step,
          where: step.workflow_id == ^workflow.id,
          order_by: [asc: step.position]
        )
      )

    story = Explain.workflow_story(workflow, steps, repo: repo)

    before_state = %{
      "workflow_id" => workflow.id,
      "state" => workflow.state,
      "diagnosis" => story.diagnosis,
      "cancel_requested_at" => workflow.cancel_requested_at,
      "latest_rejection" => story.rejection_summary
    }

    after_state = %{
      "workflow_id" => workflow.id,
      "state" => "cancel_requested",
      "diagnosis" => "cancel_requested"
    }

    incident_fingerprint =
      (incident && incident.incident_fingerprint) || "workflow:#{workflow.id}"

    preview = %{
      incident_id: incident && incident.id,
      incident_class: (incident && incident.incident_class) || "workflow_action",
      incident_fingerprint: incident_fingerprint,
      plan_hash:
        plan_hash(action, "workflow", target_id, before_state, incident && incident.health_state),
      preview_token: Ecto.UUID.generate(),
      action: action,
      target_type: "workflow",
      target_id: to_string(target_id),
      health_state: incident && incident.health_state,
      status: "ready",
      affected_counts: %{"jobs" => 0, "workflow_steps" => length(steps)},
      before_snapshot: before_state,
      after_snapshot: after_state,
      evidence: %{"previewed_at" => now},
      reason_required: true,
      expires_at: DateTime.add(now, 7 * 24 * 60 * 60, :second),
      metadata: %{
        "summary" => repair_summary(action, "workflow", target_id),
        "risk" => "medium",
        "diagnosis" => story.diagnosis,
        "latest_rejection" => story.rejection_summary,
        "resource" => %{"type" => "workflow", "id" => to_string(target_id)}
      }
    }

    {:ok,
     put_preview_runbook_context(preview, %{
       "diagnosis_state" => story.diagnosis || "needs_review",
       "evidence_completeness" => evidence_completeness_for_preview(incident)
     })}
  end

  defp resolve_incident(repo, attrs) do
    cond do
      value = Map.get(attrs, :incident_id) || Map.get(attrs, "incident_id") ->
        repo.get(Incident, value)

      value = Map.get(attrs, :incident_fingerprint) || Map.get(attrs, "incident_fingerprint") ->
        repo.get_by(Incident, incident_fingerprint: value)

      true ->
        nil
    end
  end

  defp infer_incident_class("job_rescue"), do: "dead_executor"
  defp infer_incident_class("workflow_request_cancel"), do: "workflow_action"
  defp infer_incident_class(_), do: "workflow_stuck"

  defp incident_fingerprint_for_job(job, nil),
    do: "job:#{get_in(job.meta, ["executor_id"]) || "manual"}:#{job.id}"

  defp incident_fingerprint_for_job(_job, incident), do: incident.incident_fingerprint

  defp next_job_state(action) when action in ["job_rescue", "job_retry"], do: "available"
  defp next_job_state("job_cancel"), do: "cancelled"

  defp next_step_state("workflow_step_retry"), do: "available"
  defp next_step_state("workflow_step_cancel"), do: "cancelled"

  defp plan_hash(action, target_type, target_id, before_state, health_state) do
    Jason.encode!(%{
      action: action,
      target_type: target_type,
      target_id: to_string(target_id),
      before_state: before_state,
      health_state: health_state
    })
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp put_preview_runbook_context(preview, context_overrides) do
    metadata = preview.metadata || %{}

    Map.put(
      preview,
      :metadata,
      Map.put(
        metadata,
        "runbook_context",
        runbook_context_for_preview(preview, context_overrides)
      )
    )
  end

  defp runbook_context_for_preview(preview, context_overrides) do
    overrides = context_overrides || %{}

    %{
      "entry" => %{"title" => Map.get(overrides, "entry_title", "Open runbook entry")},
      "diagnosis_state" => Map.get(overrides, "diagnosis_state", "needs_review"),
      "evidence_completeness" => Map.get(overrides, "evidence_completeness", "unknown"),
      "selected_path" => %{
        "ownership" => "Powertools-native",
        "venue" => "Powertools-native Lifeline",
        "intent" => "remediate"
      },
      "attempt" => %{
        "state" => "previewed",
        "action" => preview.action,
        "target_type" => preview.target_type,
        "target_id" => to_string(preview.target_id)
      },
      "selectors" => %{
        "incident_fingerprint" => preview.incident_fingerprint,
        "resource_type" => preview.target_type,
        "resource_id" => to_string(preview.target_id)
      },
      "plan_hash" => preview.plan_hash,
      "preview_token" => preview.preview_token
    }
  end

  defp runbook_context_for_attempt(preview, attempt_state, reason) do
    runbook_context =
      preview.metadata
      |> Kernel.||(%{})
      |> Map.get("runbook_context")
      |> case do
        %{} = context -> context
        _missing -> runbook_context_for_preview(preview, %{})
      end

    runbook_context
    |> with_attempt_state(attempt_state)
    |> then(fn context ->
      if is_binary(reason) and String.trim(reason) != "" do
        put_in(context, ["attempt", "reason"], String.trim(reason))
      else
        context
      end
    end)
  end

  defp with_attempt_state(runbook_context, attempt_state) when is_map(runbook_context) do
    attempt =
      runbook_context
      |> Map.get("attempt", %{})
      |> Map.put("state", attempt_state)

    Map.put(runbook_context, "attempt", attempt)
  end

  defp diagnosis_state_for_preview(%Incident{health_state: health_state}, _fallback)
       when is_binary(health_state),
       do: health_state

  defp diagnosis_state_for_preview(_incident, health_state) when is_binary(health_state),
    do: health_state

  defp diagnosis_state_for_preview(_incident, _health_state), do: "needs_review"

  defp evidence_completeness_for_preview(%Incident{}), do: "complete"
  defp evidence_completeness_for_preview(nil), do: "partial_evidence"

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

  defp ensure_preview_available(repo, %RepairPreview{} = preview, now) do
    case RepairPreview.execute_status(preview, now) do
      :ok ->
        :ok

      {:error, :preview_expired} ->
        preview
        |> RepairPreview.changeset(%{
          status: "expired",
          metadata:
            preview.metadata
            |> Kernel.||(%{})
            |> Map.put("runbook_context", runbook_context_for_attempt(preview, "expired", nil))
        })
        |> repo.update!()

        {:error, :preview_expired}

      other ->
        other
    end
  end

  defp recompute_plan_hash(repo, preview) do
    case preview.target_type do
      "job" ->
        job = repo.get!(Oban.Job, preview.target_id)

        before_state = %{
          "job_id" => job.id,
          "state" => job.state,
          "executor_id" => get_in(job.meta, ["executor_id"])
        }

        {:ok,
         plan_hash(preview.action, "job", preview.target_id, before_state, preview.health_state)}

      "workflow_step" ->
        step = repo.get!(Step, preview.target_id)
        story = Explain.step_story(step, repo: repo)

        before_state = %{
          "step_id" => step.id,
          "state" => step.state,
          "blocker_codes" => step.blocker_codes,
          "diagnosis" => story.diagnosis,
          "latest_rejection" => story.rejection_summary
        }

        {:ok,
         plan_hash(
           preview.action,
           "workflow_step",
           preview.target_id,
           before_state,
           preview.health_state
         )}

      "workflow" ->
        workflow = repo.get!(WorkflowRecord, preview.target_id)

        steps =
          repo.all(
            from(step in Step,
              where: step.workflow_id == ^workflow.id,
              order_by: [asc: step.position]
            )
          )

        story = Explain.workflow_story(workflow, steps, repo: repo)

        before_state = %{
          "workflow_id" => workflow.id,
          "state" => workflow.state,
          "diagnosis" => story.diagnosis,
          "cancel_requested_at" => workflow.cancel_requested_at,
          "latest_rejection" => story.rejection_summary
        }

        {:ok,
         plan_hash(
           preview.action,
           "workflow",
           preview.target_id,
           before_state,
           preview.health_state
         )}
    end
  end

  defp ensure_not_drifted(repo, preview, current_hash, now) do
    if current_hash == preview.plan_hash do
      :ok
    else
      preview
      |> RepairPreview.changeset(%{
        status: "drifted",
        metadata:
          preview.metadata
          |> Kernel.||(%{})
          |> Map.put("drift_reason", "Target state changed after preview generation.")
          |> Map.put("drifted_at", DateTime.to_iso8601(now))
          |> Map.put("runbook_context", runbook_context_for_attempt(preview, "drifted", nil))
      })
      |> repo.update!()

      {:error, :preview_drifted}
    end
  end

  defp apply_repair(repo, preview, actor, reason, now) do
    trimmed_reason = String.trim(reason)

    Multi.new()
    |> Multi.run(:target, fn repo, _changes ->
      mutate_target(repo, preview, actor, trimmed_reason, now)
    end)
    |> Multi.run(:incident, fn repo, _changes ->
      resolve_incident_after_repair(repo, preview, now)
    end)
    |> Multi.update(
      :preview,
      RepairPreview.changeset(preview, %{
        status: "consumed",
        executed_at: now,
        consumed_at: now,
        metadata:
          preview.metadata
          |> Kernel.||(%{})
          |> Map.put("reason", trimmed_reason)
          |> Map.put(
            "runbook_context",
            runbook_context_for_attempt(preview, "consumed", trimmed_reason)
          )
      })
    )
    |> Multi.run(:audit, fn repo, %{preview: preview_record} ->
      metadata = %{
        "preview_token" => preview_record.preview_token,
        "incident_class" => preview_record.incident_class,
        "incident_fingerprint" => preview_record.incident_fingerprint,
        "plan_hash" => preview_record.plan_hash,
        "reason" => trimmed_reason,
        "affected_counts" => preview_record.affected_counts,
        "result" => "ok",
        "runbook_context" =>
          runbook_context_for_attempt(preview_record, "succeeded", trimmed_reason)
      }

      Audit.record(
        "lifeline.repair_executed",
        %{type: String.to_atom(preview.target_type), id: preview.target_id},
        metadata,
        repo: repo,
        actor_id: Auth.actor_id(actor)
      )
    end)
    |> repo.transaction()
    |> case do
      {:ok, %{target: target, preview: preview_record}} ->
        Telemetry.execute_lifeline_event(:repair_executed, %{count: 1}, %{
          action: preview.action,
          incident_class: preview.incident_class,
          target_type: preview.target_type
        })

        {:ok, %{target: target, preview: preview_record}}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  defp resolve_incident_after_repair(repo, preview, now) do
    case resolve_incident(repo, %{
           incident_id: preview.incident_id,
           incident_fingerprint: preview.incident_fingerprint
         }) do
      nil ->
        {:ok, nil}

      incident ->
        if incident_still_active?(repo, incident, preview) do
          {:error, :incident_still_active}
        else
          {:ok, resolve_incident_row(repo, incident, now)}
        end
    end
  end

  defp incident_still_active?(
         repo,
         %Incident{incident_class: "dead_executor"} = incident,
         preview
       ) do
    executor_id = incident.executor_id || get_in(preview.before_snapshot || %{}, ["executor_id"])

    case executor_id do
      nil ->
        true

      executor_id ->
        %{jobs: jobs, workflow_steps: workflow_steps} = dead_executor_evidence(repo, executor_id)
        jobs != [] or workflow_steps != []
    end
  end

  defp incident_still_active?(
         repo,
         %Incident{incident_class: "workflow_stuck"} = incident,
         preview
       ) do
    step_id = incident.workflow_step_id || preview.target_id

    case repo.get(Step, step_id) do
      nil -> false
      step -> workflow_stuck?(step)
    end
  end

  defp incident_still_active?(_repo, _incident, _preview), do: true

  defp mutate_target(repo, preview, actor, reason, now) do
    case {preview.target_type, preview.action} do
      {"job", action} when action in ["job_rescue", "job_retry"] ->
        job = repo.get!(Oban.Job, preview.target_id)
        {:ok, repo.update!(Ecto.Changeset.change(job, state: "available", scheduled_at: now))}

      {"job", "job_cancel"} ->
        job = repo.get!(Oban.Job, preview.target_id)
        {:ok, repo.update!(Ecto.Changeset.change(job, state: "cancelled", cancelled_at: now))}

      {"workflow_step", "workflow_step_retry"} ->
        Runtime.recover_step_by_id(repo, preview.target_id, :retry,
          actor_id: Auth.actor_id(actor),
          reason: String.trim(reason),
          source: "lifeline"
        )

      {"workflow_step", "workflow_step_cancel"} ->
        Runtime.recover_step_by_id(repo, preview.target_id, :cancel,
          actor_id: Auth.actor_id(actor),
          reason: String.trim(reason),
          source: "lifeline"
        )

      {"workflow", "workflow_request_cancel"} ->
        Workflow.request_cancel(repo, preview.target_id,
          actor_id: Auth.actor_id(actor),
          reason: String.trim(reason),
          source: "lifeline"
        )
    end
  end

  defp repair_summary("job_rescue", "job", target_id),
    do: "Return job #{target_id} to available state."

  defp repair_summary("job_retry", "job", target_id),
    do: "Retry job #{target_id} from the native repair flow."

  defp repair_summary("job_cancel", "job", target_id),
    do: "Cancel job #{target_id} from the native repair flow."

  defp repair_summary("workflow_step_retry", "workflow_step", target_id),
    do: "Retry workflow step #{target_id} from the native repair flow."

  defp repair_summary("workflow_step_cancel", "workflow_step", target_id),
    do: "Cancel workflow step #{target_id} from the native repair flow."

  defp repair_summary("workflow_request_cancel", "workflow", target_id),
    do:
      "Request cancel for workflow #{target_id}. Idle work may stop immediately while in-flight work can still finish."

  defp fetch_value!(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key)) ||
      raise ArgumentError, "missing heartbeat field #{inspect(key)}"
  end
end
