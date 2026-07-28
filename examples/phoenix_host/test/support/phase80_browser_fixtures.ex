defmodule PhoenixHostWeb.Phase80BrowserFixturesCompileGate do
  @moduledoc false

  # The source is re-evaluated between opt-in and route-off test runs so no
  # fixture controller beam can survive a flag transition.
  def __mix_recompile__?, do: Mix.env() == :test
end

defmodule PhoenixHostWeb.Phase80BrowserFixtureErrorHTML do
  @moduledoc false

  # Unmatched disabled fixture paths must be byte-equivalent to authenticated
  # fixture denials. This renderer is loaded only from the example host's test
  # support path and never enters a production or Hex build.
  def render("404.html", _assigns), do: ""

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

if Mix.env() == :test and System.get_env("PHASE80_BROWSER_FIXTURES") == "1" do
  defmodule PhoenixHostWeb.Phase80BrowserFixtures do
    @moduledoc false

    import Ecto.Query

    alias ObanPowertools.{Audit, JobRecord}
    alias ObanPowertools.Cron.Entry
    alias ObanPowertools.Forensics.LimiterHistoryFact
    alias ObanPowertools.Lifeline.{Incident, RepairPreview}
    alias ObanPowertools.Limits.Resource
    alias ObanPowertools.Workflow.{Step, Workflow}
    alias PhoenixHost.Repo

    @projects ~w(chromium-320 chromium-tablet chromium-wide)
    @actors ~w(ops restricted)
    @states ~w(available scheduled executing retryable cancelled discarded completed)
    @targets ~w(eligible excluded drifted expired consumed skipped failed success)
    @run_pattern ~r/\A[a-z0-9][a-z0-9_-]{0,47}\z/
    @fixed_now ~U[2036-02-20 12:00:00.000000Z]
    @expired_at ~U[2000-01-01 00:00:00.000000Z]
    @barrier_table :phoenix_host_phase80_browser_fixture_barriers

    def reset(%{"project" => project, "run" => run} = params) when map_size(params) == 2 do
      with :ok <- validate_project(project),
           :ok <- validate_run(run) do
        names = fixture_names(project, run)
        release_barrier(names.key)

        Repo.transaction(fn ->
          cleanup(names)
          jobs = insert_jobs(names)
          forensics = insert_forensics(names)
          public_state(names, jobs, forensics)
        end)
      end
    end

    def reset(_params), do: {:error, :not_found}

    def set_actor(%{"project" => project, "run" => run, "actor" => actor} = params, actor)
        when map_size(params) == 3 do
      with :ok <- validate_project(project),
           :ok <- validate_run(run),
           true <- actor in @actors,
           true <- fixture_exists?(project, run) do
        role = if actor == "ops", do: "ops", else: "read_only"

        session_actor = %{
          "id" => "phase80-#{actor}-#{project}-#{run}",
          "label" => actor,
          "role" => role
        }

        {:ok, session_actor, %{"actor" => actor, "state" => "authenticated"}}
      else
        _invalid -> {:error, :not_found}
      end
    end

    def set_actor(_params, _actor), do: {:error, :not_found}

    def control_batch(
          %{"project" => project, "run" => run, "command" => command} = params,
          command,
          repo
        )
        when command in ~w(hold release status) and map_size(params) == 3 do
      with :ok <- validate_identity(project, run),
           true <- fixture_or_barrier_exists?(project, run, command) do
        names = fixture_names(project, run)
        apply_batch_command(command, names, repo)
      else
        _invalid -> {:error, :not_found}
      end
    end

    def control_batch(
          %{
            "project" => project,
            "run" => run,
            "command" => "perturb",
            "target" => target
          } = params,
          "perturb",
          repo
        )
        when target in @targets and map_size(params) == 4 do
      with :ok <- validate_identity(project, run),
           true <- fixture_exists?(project, run) do
        names = fixture_names(project, run)
        perturb_target(names, target, repo)
      else
        _invalid -> {:error, :not_found}
      end
    end

    def control_batch(_params, _command, _repo), do: {:error, :not_found}

    def public_evidence(%{"project" => project, "run" => run} = params, repo)
        when map_size(params) == 2 do
      with :ok <- validate_identity(project, run),
           true <- fixture_exists?(project, run) do
        names = fixture_names(project, run)
        target_states = target_states(names, repo)
        audited_effects = audited_effect_count(names, repo)

        {:ok,
         %{
           "project" => project,
           "run" => run,
           "counts" => %{
             "jobs" => fixture_job_count(names, repo),
             "auditedEffects" => audited_effects
           },
           "states" => target_states,
           "audit" => %{"complete" => audited_effects > 0}
         }}
      else
        _invalid -> {:error, :not_found}
      end
    end

    def public_evidence(_params, _repo), do: {:error, :not_found}

    defp validate_identity(project, run) do
      with :ok <- validate_project(project), do: validate_run(run)
    end

    defp validate_project(project) when project in @projects, do: :ok
    defp validate_project(_project), do: {:error, :not_found}

    defp validate_run(run) when is_binary(run) do
      if Regex.match?(@run_pattern, run), do: :ok, else: {:error, :not_found}
    end

    defp validate_run(_run), do: {:error, :not_found}

    defp fixture_names(project, run) do
      key = "#{project}:#{run}"
      prefix = "phase80-#{project}-#{run}"
      job_base = deterministic_base("job:" <> key, 20_000_000_000, 10_000)
      audit_base = deterministic_base("audit:" <> key, 2_000_000_000_000, 1_000)

      %{
        project: project,
        run: run,
        key: key,
        prefix: prefix,
        job_base: job_base,
        audit_base: audit_base,
        boundary_queue: "#{prefix}-boundary",
        under_queue: "#{prefix}-under-limit",
        over_queue: "#{prefix}-over-limit",
        workflow_id: deterministic_uuid("workflow:" <> key),
        step_id: deterministic_uuid("step:" <> key),
        workflow_name: "#{prefix}-workflow-معالجة",
        workflow_step: "review-مرحبا",
        incident_id: deterministic_uuid("incident:" <> key),
        incident_fingerprint: "#{prefix}:incident:rtl-مرحبا",
        cron_entry: "#{prefix}-cron",
        limiter_resource: "#{prefix}-limiter",
        args_sentinel: "phase80-args-sentinel-#{key}",
        meta_sentinel: "phase80-meta-sentinel-#{key}",
        output_sentinel: "phase80-output-sentinel-#{key}",
        error_sentinel: "phase80-error-sentinel-#{key}",
        reason_sentinel: "phase80-reason-sentinel-#{key}",
        runbook_sentinel: "phase80-runbook-sentinel-#{key}"
      }
    end

    defp cleanup(names) do
      job_ids =
        Repo.all(
          from(job in Oban.Job,
            where: fragment("?->>'phase80_key' = ?", job.meta, ^names.key),
            select: job.id
          )
        )

      target_ids = Enum.map(job_ids, &Integer.to_string/1)

      Repo.delete_all(from(record in JobRecord, where: record.oban_job_id in ^job_ids))
      Repo.delete_all(from(preview in RepairPreview, where: preview.target_id in ^target_ids))
      Repo.delete_all(from(job in Oban.Job, where: job.id in ^job_ids))

      Repo.delete_all(
        from(event in Audit,
          where: fragment("?->>'phase80_key' = ?", event.metadata, ^names.key)
        )
      )

      Repo.delete_all(from(step in Step, where: step.workflow_id == ^names.workflow_id))
      Repo.delete_all(from(workflow in Workflow, where: workflow.id == ^names.workflow_id))

      Repo.delete_all(
        from(incident in Incident,
          where: incident.incident_fingerprint == ^names.incident_fingerprint
        )
      )

      Repo.delete_all(from(entry in Entry, where: entry.name == ^names.cron_entry))

      Repo.delete_all(
        from(fact in LimiterHistoryFact, where: fact.resource_name == ^names.limiter_resource)
      )

      Repo.delete_all(from(resource in Resource, where: resource.name == ^names.limiter_resource))
    end

    defp insert_jobs(names) do
      rows = Enum.map(0..2_499, &job_row(names, &1))
      {2_500, _rows} = Repo.insert_all(Oban.Job, rows)

      targets =
        @targets
        |> Enum.with_index(60)
        |> Map.new(fn {target, index} -> {target, names.job_base + index} end)

      insert_output_record(names, Map.fetch!(targets, "success"))

      %{
        state_ids:
          @states
          |> Enum.with_index()
          |> Map.new(fn {state, index} -> {state, names.job_base + index} end),
        targets: targets,
        cross_page_ids: [names.job_base, names.job_base + 20],
        under_limit_ids: Enum.map(70..72, &(names.job_base + &1))
      }
    end

    defp job_row(names, index) do
      id = names.job_base + index
      state = job_state(index)
      queue = job_queue(names, index)
      scheduled_at = DateTime.add(@fixed_now, -index, :second)

      %{
        id: id,
        state: state,
        queue: queue,
        worker: job_worker(names, index),
        args: %{
          "phase80_key" => names.key,
          "private" => names.args_sentinel,
          "operator_copy" => "Long Unicode مرحبا — עבודה — नमस्ते #{index}"
        },
        meta: %{
          "phase80_fixture" => true,
          "phase80_key" => names.key,
          "private" => names.meta_sentinel,
          "fixture_group" => fixture_group(index)
        },
        tags: ["phase80-fixture", names.project, names.run],
        errors: job_errors(names, index),
        attempt: if(state in ["retryable", "discarded"], do: 1, else: 0),
        attempted_by: [],
        max_attempts: 20,
        priority: 0,
        attempted_at: if(state in ["executing", "retryable"], do: scheduled_at),
        cancelled_at: if(state == "cancelled", do: scheduled_at),
        completed_at: if(state == "completed", do: scheduled_at),
        discarded_at: if(state == "discarded", do: scheduled_at),
        inserted_at: DateTime.add(@fixed_now, -5_000 - index, :second),
        scheduled_at: scheduled_at
      }
    end

    defp job_state(index) when index in 0..6, do: Enum.at(@states, index)
    defp job_state(index) when index in 7..46, do: "retryable"
    defp job_state(index) when index in 60..200, do: "retryable"
    defp job_state(index), do: Enum.at(@states, rem(index, length(@states)))

    defp job_queue(names, index) when index in 7..46, do: names.boundary_queue
    defp job_queue(names, index) when index in 70..72, do: names.under_queue
    defp job_queue(names, index) when index in 100..200, do: names.over_queue
    defp job_queue(names, _index), do: "#{names.prefix}-default"

    defp job_worker(names, 59) do
      "PhoenixHost.Phase80Fixture." <>
        String.duplicate("LongWorkerSegment", 4) <> ".RTL." <> names.project
    end

    defp job_worker(names, index),
      do: "PhoenixHost.Phase80Fixture.#{names.project}.#{names.run}.Worker#{rem(index, 17)}"

    defp job_errors(names, 66) do
      [
        %{
          "attempt" => 1,
          "at" => DateTime.to_iso8601(DateTime.add(@fixed_now, -60, :second)),
          "error" => names.error_sentinel
        }
      ]
    end

    defp job_errors(_names, _index), do: []

    defp fixture_group(index) when index in 7..46, do: "boundary"
    defp fixture_group(index) when index in 70..72, do: "under_limit"
    defp fixture_group(index) when index in 100..200, do: "over_limit"
    defp fixture_group(index) when index in 60..67, do: Enum.at(@targets, index - 60)
    defp fixture_group(_index), do: "bulk"

    defp insert_output_record(names, job_id) do
      payload = %{"private" => names.output_sentinel}
      encoded = Jason.encode!(payload)

      %JobRecord{}
      |> JobRecord.changeset(%{
        oban_job_id: job_id,
        worker: "PhoenixHost.Phase80Fixture.Output",
        attempt: 1,
        status: "ok",
        payload: payload,
        payload_bytes: byte_size(encoded),
        retention: "standard",
        redacted: false,
        summary: "Fixture output",
        recorded_at: @fixed_now,
        expires_at: DateTime.add(@fixed_now, 7 * 24 * 60 * 60, :second)
      })
      |> Repo.insert!()
    end

    defp insert_forensics(names) do
      workflow =
        %Workflow{id: names.workflow_id}
        |> Workflow.changeset(%{
          name: names.workflow_name,
          state: "executing",
          workflow_context: %{
            "phase80_key" => names.key,
            "runbook" => names.runbook_sentinel
          },
          definition_version: 1,
          semantics_version: 2,
          step_count: 1,
          runnable_step_count: 0,
          completed_step_count: 0,
          cancelled_step_count: 0,
          failed_step_count: 0,
          started_at: @fixed_now,
          last_transition_at: @fixed_now
        })
        |> Repo.insert!()

      %Step{id: names.step_id}
      |> Step.changeset(%{
        workflow_id: workflow.id,
        step_name: names.workflow_step,
        worker: "PhoenixHost.Phase80Fixture.WorkflowWorker",
        input: %{"phase80_key" => names.key},
        context: %{"private" => names.meta_sentinel},
        state: "executing",
        queue: "default",
        attempt: 1,
        position: 0,
        dependency_count: 0,
        dependency_snapshot: %{},
        blocker_codes: [],
        blocker_details: %{},
        started_at: @fixed_now,
        last_transition_at: @fixed_now
      })
      |> Repo.insert!()

      %Incident{id: names.incident_id}
      |> Incident.changeset(%{
        incident_class: "phase80_fixture",
        status: "active",
        workflow_id: names.workflow_id,
        workflow_step_id: names.step_id,
        incident_fingerprint: names.incident_fingerprint,
        health_state: "missing",
        summary: "Phase 80 incident مرحبا for #{names.key}",
        affected_counts: %{"jobs" => 8},
        evidence: %{"private" => names.error_sentinel},
        first_detected_at: DateTime.add(@fixed_now, -7_200, :second),
        last_detected_at: @fixed_now,
        metadata: %{"phase80_key" => names.key, "private" => names.meta_sentinel}
      })
      |> Repo.insert!()

      %Entry{}
      |> Entry.changeset(%{
        name: names.cron_entry,
        source: "phase80_fixture",
        worker: "PhoenixHost.Phase80Fixture.CronWorker",
        queue: "default",
        expression: "*/5 * * * *",
        timezone: "Etc/UTC",
        args: %{"phase80_key" => names.key},
        opts: %{},
        overlap_policy: "queue_one",
        catch_up_policy: "latest",
        max_catch_up: 1,
        metadata: %{"phase80_key" => names.key, "private" => names.meta_sentinel}
      })
      |> Repo.insert!()

      %Resource{}
      |> Resource.changeset(%{
        name: names.limiter_resource,
        scope_kind: "global",
        algorithm: "fixed_window",
        bucket_span_ms: 60_000,
        bucket_capacity: 8,
        default_weight: 1,
        partition_strategy: "global",
        partition_config: %{},
        cooldown_enabled: true,
        metadata: %{"phase80_key" => names.key, "private" => names.meta_sentinel}
      })
      |> Repo.insert!()

      Enum.each(1..8, fn index ->
        %LimiterHistoryFact{}
        |> LimiterHistoryFact.changeset(%{
          resource_name: names.limiter_resource,
          partition_key: "__global__",
          event_type: "limiter.pressure_observed",
          cause_kind: "transient_pressure",
          occurred_at: DateTime.add(@fixed_now, -index * 60, :second),
          eligible_at: DateTime.add(@fixed_now, index * 60, :second),
          metadata: %{"phase80_key" => names.key, "private" => names.meta_sentinel}
        })
        |> Repo.insert!()
      end)

      insert_forensic_audit(names)

      %{
        workflow_id: workflow.id,
        workflow_step: names.workflow_step,
        incident_fingerprint: names.incident_fingerprint,
        cron_entry: names.cron_entry,
        limiter_resource: names.limiter_resource
      }
    end

    defp insert_forensic_audit(names) do
      workflow_rows =
        Enum.map(1..55, fn index ->
          audit_row(names, index, %{
            action: "workflow.step_completed",
            event_type: "workflow.step_completed",
            resource: "workflow:#{names.workflow_id}",
            resource_type: "workflow",
            resource_id: names.workflow_id,
            inserted_at: DateTime.add(@fixed_now, -index, :second)
          })
        end)

      incident_rows =
        Enum.map(1..55, fn index ->
          audit_row(names, 100 + index, %{
            action: "lifeline.repair_executed",
            event_type: "lifeline.repair_executed",
            resource: "incident:#{names.incident_fingerprint}",
            resource_type: "incident",
            resource_id: names.incident_fingerprint,
            inserted_at: DateTime.add(@fixed_now, -1_000 - index, :second)
          })
        end)

      {110, _rows} = Repo.insert_all(Audit, workflow_rows ++ incident_rows)
    end

    defp audit_row(names, offset, attrs) do
      %{
        id: names.audit_base + offset,
        actor_id: "phase80-operator",
        action: attrs.action,
        command_key: nil,
        event_type: attrs.event_type,
        resource: attrs.resource,
        resource_type: attrs.resource_type,
        resource_id: attrs.resource_id,
        metadata: %{
          "phase80_fixture" => true,
          "phase80_key" => names.key,
          "incident_fingerprint" => names.incident_fingerprint,
          "reason" => names.reason_sentinel,
          "runbook_context" => %{"private" => names.runbook_sentinel}
        },
        inserted_at:
          attrs.inserted_at
          |> DateTime.to_naive()
          |> NaiveDateTime.truncate(:second)
      }
    end

    defp public_state(names, jobs, forensics) do
      %{
        "project" => names.project,
        "run" => names.run,
        "actors" => @actors,
        "jobs" => %{
          "pageSize" => 20,
          "totalCount" => 2_500,
          "finalPage" => 125,
          "finalPageCount" => 20,
          "boundaryQueue" => names.boundary_queue,
          "crossPageIds" => jobs.cross_page_ids,
          "underLimitIds" => jobs.under_limit_ids,
          "underLimitCount" => length(jobs.under_limit_ids),
          "overLimitCount" => 101,
          "stateIds" => jobs.state_ids,
          "targets" => jobs.targets
        },
        "forensics" => %{
          "workflowId" => forensics.workflow_id,
          "workflowStep" => forensics.workflow_step,
          "incidentFingerprint" => forensics.incident_fingerprint,
          "cronEntry" => forensics.cron_entry,
          "limiterResource" => forensics.limiter_resource,
          "eventWindow" => 55
        },
        "batch" => %{"state" => "idle"},
        "counts" => %{
          "jobs" => 2_500,
          "workflowEvents" => 55,
          "incidentEvents" => 55
        }
      }
    end

    defp apply_batch_command("hold", names, repo), do: hold_barrier(names, repo)
    defp apply_batch_command("release", names, _repo), do: release_barrier(names.key)
    defp apply_batch_command("status", names, _repo), do: barrier_status(names.key)

    defp hold_barrier(names, repo) do
      ensure_barrier_table()

      case :ets.lookup(@barrier_table, names.key) do
        [{_key, %{pid: pid}}] when is_pid(pid) ->
          if Process.alive?(pid) do
            {:ok, %{"command" => "hold", "state" => "held"}}
          else
            :ets.delete(@barrier_table, names.key)
            start_barrier(names, repo)
          end

        _missing ->
          start_barrier(names, repo)
      end
    end

    defp start_barrier(names, repo) do
      owner = self()

      {:ok, pid} =
        Task.start(fn ->
          result =
            repo.transaction(fn ->
              Ecto.Adapters.SQL.query!(
                repo,
                """
                SELECT id
                FROM oban_jobs
                WHERE meta->>'phase80_key' = $1
                  AND meta->>'fixture_group' IN ('eligible', 'success')
                ORDER BY id
                FOR UPDATE
                """,
                [names.key]
              )

              send(owner, {:phase80_barrier_ready, names.key, self()})

              receive do
                {:phase80_release, key, release_owner} when key == names.key ->
                  release_owner
              end
            end)

          case result do
            {:ok, release_owner} when is_pid(release_owner) ->
              send(release_owner, {:phase80_barrier_released, names.key})

            _failed ->
              send(owner, {:phase80_barrier_failed, names.key})
          end
        end)

      receive do
        {:phase80_barrier_ready, key, ^pid} when key == names.key ->
          :ets.insert(@barrier_table, {names.key, %{pid: pid, state: "held"}})
          {:ok, %{"command" => "hold", "state" => "held"}}

        {:phase80_barrier_failed, key} when key == names.key ->
          {:error, :not_found}
      after
        5_000 ->
          Process.exit(pid, :kill)
          {:error, :not_found}
      end
    end

    defp release_barrier(key) do
      ensure_barrier_table()

      case :ets.lookup(@barrier_table, key) do
        [{^key, %{pid: pid}}] when is_pid(pid) ->
          if Process.alive?(pid) do
            send(pid, {:phase80_release, key, self()})

            receive do
              {:phase80_barrier_released, ^key} ->
                :ets.insert(@barrier_table, {key, %{pid: nil, state: "released"}})
                {:ok, %{"command" => "release", "state" => "released"}}
            after
              5_000 -> {:error, :not_found}
            end
          else
            :ets.insert(@barrier_table, {key, %{pid: nil, state: "released"}})
            {:ok, %{"command" => "release", "state" => "released"}}
          end

        _missing ->
          {:ok, %{"command" => "release", "state" => "released"}}
      end
    end

    defp barrier_status(key) do
      ensure_barrier_table()

      case :ets.lookup(@barrier_table, key) do
        [{^key, %{pid: pid, state: "held"}}] when is_pid(pid) ->
          if Process.alive?(pid),
            do: {:ok, %{"command" => "hold", "state" => "held"}},
            else: {:ok, %{"command" => "release", "state" => "released"}}

        [{^key, %{state: "released"}}] ->
          {:ok, %{"command" => "release", "state" => "released"}}

        _missing ->
          {:ok, %{"command" => "status", "state" => "idle"}}
      end
    end

    defp perturb_target(names, target, repo) do
      target_id = names.job_base + 60 + Enum.find_index(@targets, &(&1 == target))

      repo.transaction(fn ->
        job = repo.get(Oban.Job, target_id) || repo.rollback(:not_found)

        case target do
          "drifted" ->
            job |> Ecto.Changeset.change(state: "scheduled") |> repo.update!()

          "expired" ->
            update_preview(repo, target_id, %{expires_at: @expired_at})

          "consumed" ->
            update_preview(repo, target_id, %{
              status: "consumed",
              consumed_at: @fixed_now
            })

          "skipped" ->
            update_preview(repo, target_id, %{
              status: "consumed",
              consumed_at: @fixed_now
            })

          "failed" ->
            repo.delete!(job)

          _unchanged ->
            :ok
        end

        %{"command" => "perturb", "state" => "prepared"}
      end)
    end

    defp update_preview(repo, target_id, attrs) do
      preview =
        repo.one(
          from(preview in RepairPreview,
            where: preview.target_id == ^Integer.to_string(target_id),
            order_by: [desc: preview.inserted_at],
            limit: 1
          )
        ) || repo.rollback(:not_found)

      preview
      |> RepairPreview.changeset(attrs)
      |> repo.update!()
    end

    defp target_states(names, repo) do
      @targets
      |> Enum.with_index(60)
      |> Map.new(fn {target, index} ->
        state =
          case repo.get(Oban.Job, names.job_base + index) do
            %Oban.Job{state: state} -> state
            nil -> "unavailable"
          end

        {target, state}
      end)
    end

    defp audited_effect_count(names, repo) do
      target_ids =
        @targets
        |> Enum.with_index(60)
        |> Enum.map(fn {_target, index} -> Integer.to_string(names.job_base + index) end)

      repo.aggregate(
        from(event in Audit,
          where:
            event.resource_type == "job" and event.resource_id in ^target_ids and
              event.event_type == "lifeline.repair_executed"
        ),
        :count
      )
    end

    defp fixture_job_count(names, repo) do
      repo.aggregate(
        from(job in Oban.Job,
          where: fragment("?->>'phase80_key' = ?", job.meta, ^names.key)
        ),
        :count
      )
    end

    defp fixture_exists?(project, run) do
      names = fixture_names(project, run)

      Repo.exists?(
        from(job in Oban.Job,
          where:
            job.id == ^names.job_base and
              fragment("?->>'phase80_key' = ?", job.meta, ^names.key)
        )
      )
    end

    defp fixture_or_barrier_exists?(project, run, command) when command in ~w(release status) do
      names = fixture_names(project, run)
      ensure_barrier_table()

      case :ets.lookup(@barrier_table, names.key) do
        [{_key, _state}] -> true
        [] -> fixture_exists?(project, run)
      end
    end

    defp fixture_or_barrier_exists?(project, run, _command), do: fixture_exists?(project, run)

    defp ensure_barrier_table do
      case :ets.whereis(@barrier_table) do
        :undefined ->
          try do
            :ets.new(@barrier_table, [:named_table, :public, :set])
          rescue
            ArgumentError -> @barrier_table
          end

        _table ->
          @barrier_table
      end
    end

    defp deterministic_base(key, offset, width) do
      <<number::unsigned-64, _rest::binary>> = :crypto.hash(:sha256, key)
      offset + rem(number, 100_000) * width
    end

    defp deterministic_uuid(key) do
      <<raw::binary-size(16), _rest::binary>> = :crypto.hash(:sha256, key)
      {:ok, uuid} = Ecto.UUID.load(raw)
      uuid
    end
  end

  defmodule PhoenixHostWeb.Phase80BrowserFixturesController do
    @moduledoc false

    use PhoenixHostWeb, :controller

    def __mix_recompile__?, do: Mix.env() == :test

    alias PhoenixHostWeb.Phase80BrowserFixtures

    def reset(conn, params) do
      with :ok <- authenticate(conn),
           {:ok, state} <- Phase80BrowserFixtures.reset(params) do
        json(conn, state)
      else
        _denied_or_unavailable -> not_found(conn)
      end
    end

    def actor(conn, params) do
      with :ok <- authenticate(conn),
           {:ok, session_actor, state} <-
             Phase80BrowserFixtures.set_actor(params, Map.get(params, "actor")) do
        conn
        |> put_session("ops_actor", session_actor)
        |> json(state)
      else
        _denied_or_unavailable -> not_found(conn)
      end
    end

    def batch(conn, params) do
      with :ok <- authenticate(conn),
           {:ok, state} <-
             Phase80BrowserFixtures.control_batch(
               params,
               Map.get(params, "command"),
               PhoenixHost.Repo
             ) do
        json(conn, state)
      else
        _denied_or_unavailable -> not_found(conn)
      end
    end

    def evidence(conn, params) do
      with :ok <- authenticate(conn),
           {:ok, state} <-
             Phase80BrowserFixtures.public_evidence(params, PhoenixHost.Repo) do
        json(conn, state)
      else
        _denied_or_unavailable -> not_found(conn)
      end
    end

    defp authenticate(conn) do
      expected = System.get_env("PHASE80_BROWSER_FIXTURE_SECRET") || ""
      provided = conn |> get_req_header("x-phase80-fixture-secret") |> List.first() || ""

      if expected != "" and provided != "" and constant_time_equal?(expected, provided),
        do: :ok,
        else: {:error, :not_found}
    end

    defp constant_time_equal?(left, right) do
      Plug.Crypto.secure_compare(:crypto.hash(:sha256, left), :crypto.hash(:sha256, right))
    end

    defp not_found(conn), do: send_resp(conn, 404, "")
  end
end
