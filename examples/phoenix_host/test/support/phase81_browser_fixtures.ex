defmodule PhoenixHostWeb.Phase81BrowserFixturesCompileGate do
  @moduledoc false

  def __mix_recompile__?, do: Mix.env() == :test
end

if Mix.env() == :test and System.get_env("PHASE81_BROWSER_FIXTURES") == "1" do
  defmodule PhoenixHostWeb.Phase81BrowserFixtures do
    @moduledoc false

    import Ecto.Query

    alias ObanPowertools.{
      Audit,
      Batch,
      BatchJob,
      Callback
    }

    alias ObanPowertools.Lifeline.{ArchiveRun, Heartbeat, Incident}
    alias ObanPowertools.Workflow.{Result, Step, Workflow}
    alias PhoenixHost.Repo

    @projects ~w(chromium-320 chromium-tablet chromium-wide)
    @actors ~w(ops restricted)
    @race_commands ~w(revoke restore drift duplicate disconnect interrupt status)
    @run_pattern ~r/\A[a-z0-9][a-z0-9_-]{0,47}\z/
    @fixed_now ~U[2036-03-21 12:00:00.000000Z]
    @fixed_naive ~N[2036-03-21 12:00:00]
    @state_table :phoenix_host_phase81_browser_fixture_state

    @counts %{
      "workflows" => 51,
      "workflowSteps" => 101,
      "workflowResults" => 51,
      "workflowEvidence" => 26,
      "batchMembers" => 51,
      "batchCallbacks" => 26,
      "batchResults" => 51,
      "batchAudit" => 26,
      "incidents" => 51,
      "executors" => 26,
      "lifelineAudit" => 51,
      "archiveRows" => 26
    }

    def reset(%{"project" => project, "run" => run} = params) when map_size(params) == 2 do
      with :ok <- validate_identity(project, run) do
        names = names(project, run)

        Repo.transaction(fn ->
          ensure_batch_fixture_columns()
          cleanup(names)
          seed(names)
          put_race(names.key, "authorized")
          public_state(names)
        end)
      end
    end

    def reset(_params), do: {:error, :not_found}

    def set_actor(%{"project" => project, "run" => run, "actor" => actor} = params, actor)
        when map_size(params) == 3 and actor in @actors do
      with :ok <- validate_identity(project, run),
           true <- fixture_exists?(names(project, run)) do
        session_actor = %{
          "id" => "phase81-#{actor}-#{project}-#{run}",
          "label" => actor,
          "role" => if(actor == "ops", do: "ops", else: "read_only"),
          "phase81_key" => "#{project}:#{run}"
        }

        {:ok, session_actor, %{"actor" => actor, "state" => "authenticated"}}
      else
        _ -> {:error, :not_found}
      end
    end

    def set_actor(_params, _actor), do: {:error, :not_found}

    def control_race(
          %{"project" => project, "run" => run, "command" => command} = params,
          command
        )
        when map_size(params) == 3 and command in @race_commands do
      with :ok <- validate_identity(project, run),
           names = names(project, run),
           true <- fixture_exists?(names) do
        state =
          case command do
            "status" -> race_state(names.key)
            "restore" -> "authorized"
            other -> other
          end

        if command != "status", do: put_race(names.key, state)
        {:ok, %{"command" => command, "state" => state}}
      else
        _ -> {:error, :not_found}
      end
    end

    def control_race(_params, _command), do: {:error, :not_found}

    def authorization_state(%{"phase81_key" => key}) when is_binary(key), do: race_state(key)
    def authorization_state(%{phase81_key: key}) when is_binary(key), do: race_state(key)
    def authorization_state(_actor), do: "authorized"

    defp validate_identity(project, run) when project in @projects and is_binary(run) do
      if Regex.match?(@run_pattern, run), do: :ok, else: {:error, :not_found}
    end

    defp validate_identity(_project, _run), do: {:error, :not_found}

    defp names(project, run) do
      key = "#{project}:#{run}"
      prefix = "phase81-#{project}-#{run}"

      %{
        project: project,
        run: run,
        key: key,
        prefix: prefix,
        batch_id: uuid("batch:" <> key),
        workflow_ids: Enum.map(0..50, &uuid("workflow:#{key}:#{&1}")),
        incident_ids: Enum.map(0..50, &uuid("incident:#{key}:#{&1}")),
        heartbeat_ids: Enum.map(0..25, &uuid("heartbeat:#{key}:#{&1}")),
        archive_ids: Enum.map(0..25, &uuid("archive:#{key}:#{&1}"))
      }
    end

    defp cleanup(names) do
      workflow_ids = names.workflow_ids
      incident_ids = names.incident_ids

      Repo.delete_all(from(result in Result, where: result.workflow_id in ^workflow_ids))
      Repo.delete_all(from(callback in Callback, where: callback.workflow_id in ^workflow_ids))
      Repo.delete_all(from(step in Step, where: step.workflow_id in ^workflow_ids))

      Repo.delete_all(
        from(event in Audit,
          where: fragment("?->>'phase81_key' = ?", event.metadata, ^names.key)
        )
      )

      Repo.delete_all(from(workflow in Workflow, where: workflow.id in ^workflow_ids))
      Repo.delete_all(from(callback in Callback, where: callback.batch_id == ^names.batch_id))
      Repo.delete_all(from(member in BatchJob, where: member.batch_id == ^names.batch_id))

      Repo.delete_all(
        from(job in Oban.Job, where: job.id in ^Enum.map(1..51, &job_id(names.key, &1)))
      )

      Repo.delete_all(from(batch in Batch, where: batch.id == ^names.batch_id))
      Repo.delete_all(from(incident in Incident, where: incident.id in ^incident_ids))
      Repo.delete_all(from(heartbeat in Heartbeat, where: heartbeat.id in ^names.heartbeat_ids))
      Repo.delete_all(from(run in ArchiveRun, where: run.id in ^names.archive_ids))
    end

    # The example host intentionally carries the original batch migration while
    # the package test harness layers the later insertion-evidence columns.
    # Add those columns only inside this disposable, explicitly enabled test DB
    # so the real Batches page can exercise the current package schema.
    defp ensure_batch_fixture_columns do
      Ecto.Adapters.SQL.query!(
        Repo,
        """
        ALTER TABLE oban_powertools_batches
          ADD COLUMN IF NOT EXISTS name text,
          ADD COLUMN IF NOT EXISTS inserted_count integer NOT NULL DEFAULT 0,
          ADD COLUMN IF NOT EXISTS insert_chunk_count integer NOT NULL DEFAULT 0,
          ADD COLUMN IF NOT EXISTS insert_failed_chunk integer,
          ADD COLUMN IF NOT EXISTS insert_failure jsonb NOT NULL DEFAULT '{}'::jsonb,
          ADD COLUMN IF NOT EXISTS insert_failed_at timestamp(6) without time zone
        """
      )
    end

    defp seed(names) do
      seed_workflows(names)
      seed_batch(names)
      seed_lifeline(names)
      seed_audit(names)
    end

    defp seed_workflows(names) do
      workflow_rows =
        names.workflow_ids
        |> Enum.with_index()
        |> Enum.map(fn {id, index} ->
          %{
            id: id,
            name: "#{names.prefix}-workflow-#{index}",
            state: if(index == 0, do: "blocked", else: "running"),
            workflow_context: %{"phase81_key" => names.key},
            definition_version: 1,
            semantics_version: 2,
            step_count: if(index == 0, do: 101, else: 0),
            runnable_step_count: 0,
            completed_step_count: 0,
            cancelled_step_count: 0,
            failed_step_count: if(index == 0, do: 1, else: 0),
            last_transition_at: @fixed_now,
            inserted_at: @fixed_naive,
            updated_at: @fixed_naive
          }
        end)

      Repo.insert_all(Workflow, workflow_rows)
      workflow_id = hd(names.workflow_ids)

      step_rows =
        Enum.map(0..100, fn index ->
          %{
            id: uuid("step:#{names.key}:#{index}"),
            workflow_id: workflow_id,
            step_name: "step-#{index}",
            worker: "PhoenixHost.Phase81Fixture.Worker#{rem(index, 7)}",
            input: %{"public" => "fixture"},
            context: %{},
            state: if(index == 0, do: "failed", else: "pending"),
            queue: "default",
            attempt: if(index == 0, do: 1, else: 0),
            position: index,
            dependency_count: if(index == 0, do: 0, else: 1),
            dependency_snapshot: %{},
            blocker_codes: if(index == 0, do: ["dependency_failed"], else: []),
            blocker_details: %{},
            inserted_at: @fixed_naive,
            updated_at: @fixed_naive
          }
        end)

      Repo.insert_all(Step, step_rows)
      first_step = hd(step_rows)

      result_rows =
        Enum.map(1..51, fn attempt ->
          %{
            id: uuid("result:#{names.key}:#{attempt}"),
            workflow_id: workflow_id,
            step_id: first_step.id,
            attempt: attempt,
            status: if(attempt == 51, do: "error", else: "ok"),
            payload: %{"public" => "result-#{attempt}"},
            payload_bytes: 24,
            retention: "standard",
            redacted: false,
            summary: "Fixture result #{attempt}",
            recorded_at: DateTime.add(@fixed_now, -attempt, :second),
            inserted_at: @fixed_naive
          }
        end)

      Repo.insert_all(Result, result_rows)
    end

    defp seed_batch(names) do
      Repo.insert_all(Batch, [
        %{
          id: names.batch_id,
          name: "#{names.prefix}-batch",
          status: "exhausted",
          total_count: 51,
          success_count: 25,
          discard_count: 26,
          cancelled_count: 0,
          snooze_count: 0,
          inserted_count: 51,
          insert_chunk_count: 1,
          insert_failure: %{},
          completed_at: @fixed_now,
          inserted_at: @fixed_naive,
          updated_at: @fixed_naive
        }
      ])

      jobs =
        Enum.map(1..51, fn index ->
          state = if(rem(index, 2) == 0, do: "discarded", else: "completed")

          %{
            id: job_id(names.key, index),
            state: state,
            queue: "#{names.prefix}-default",
            worker: "PhoenixHost.Workers.Phase81BatchWorker",
            args: %{"batch_id" => names.batch_id, "member" => index},
            meta: %{"phase81_fixture" => true, "phase81_key" => names.key},
            tags: ["phase81-fixture", names.project, names.run],
            errors:
              if(state == "discarded",
                do: [%{"attempt" => 1, "error" => "[redacted]"}],
                else: []
              ),
            attempt: if(state == "discarded", do: 1, else: 0),
            attempted_by: [],
            max_attempts: 20,
            priority: 0,
            completed_at: if(state == "completed", do: @fixed_now),
            discarded_at: if(state == "discarded", do: @fixed_now),
            inserted_at: @fixed_now,
            scheduled_at: @fixed_now
          }
        end)

      Repo.insert_all(Oban.Job, jobs)

      members =
        Enum.map(1..51, fn index ->
          %{
            id: uuid("member:#{names.key}:#{index}"),
            batch_id: names.batch_id,
            job_id: job_id(names.key, index),
            state: if(rem(index, 2) == 0, do: "discarded", else: "completed"),
            inserted_at: @fixed_naive,
            updated_at: @fixed_naive
          }
        end)

      Repo.insert_all(BatchJob, members)

      callbacks =
        Enum.map(1..26, fn index ->
          %{
            id: uuid("callback:#{names.key}:#{index}"),
            batch_id: names.batch_id,
            event: "batch.exhausted",
            dedupe_key: "#{names.prefix}-callback-#{index}",
            status: if(index == 26, do: "failed", else: "pending"),
            payload: %{"batch_id" => names.batch_id, "event" => "batch.exhausted"},
            attempts: if(index == 26, do: 1, else: 0),
            available_at: @fixed_now,
            last_error: if(index == 26, do: "[redacted]", else: nil),
            inserted_at: @fixed_naive,
            updated_at: @fixed_naive
          }
        end)

      Repo.insert_all(Callback, callbacks)
    end

    defp seed_lifeline(names) do
      incidents =
        names.incident_ids
        |> Enum.with_index()
        |> Enum.map(fn {id, index} ->
          %{
            id: id,
            incident_class: "executor_missing",
            status: if(index == 50, do: "resolved", else: "active"),
            executor_id: "#{names.prefix}-executor-#{rem(index, 26)}",
            incident_fingerprint: "#{names.prefix}:incident:#{index}",
            health_state: if(index == 50, do: "healthy", else: "missing"),
            summary: "Deterministic fixture incident #{index}",
            affected_counts: %{"jobs" => index + 1},
            evidence: %{"complete" => true},
            first_detected_at: DateTime.add(@fixed_now, -index - 60, :second),
            last_detected_at: DateTime.add(@fixed_now, -index, :second),
            metadata: %{"phase81_key" => names.key},
            inserted_at: @fixed_naive,
            updated_at: @fixed_naive
          }
        end)

      Repo.insert_all(Incident, incidents)

      heartbeats =
        names.heartbeat_ids
        |> Enum.with_index()
        |> Enum.map(fn {id, index} ->
          %{
            id: id,
            executor_id: "#{names.prefix}-executor-#{index}",
            oban_name: "Oban",
            node: "fixture@localhost",
            queue: "default",
            producer_scope: "all",
            health_state: if(index == 25, do: "missing", else: "healthy"),
            last_heartbeat_at: DateTime.add(@fixed_now, -index, :second),
            warning_threshold_ms: 45_000,
            missing_threshold_ms: 120_000,
            metadata: %{"phase81_key" => names.key},
            inserted_at: @fixed_naive,
            updated_at: @fixed_naive
          }
        end)

      Repo.insert_all(Heartbeat, heartbeats)

      archives =
        names.archive_ids
        |> Enum.with_index()
        |> Enum.map(fn {id, index} ->
          %{
            id: id,
            run_type: "repair_archive",
            status: "completed",
            retention_class: "standard",
            actor_id: "phase81-operator",
            reason: "Fixture retention run",
            batch_size: 100,
            archived_count: index,
            pruned_count: 0,
            blocked_count: 0,
            started_at: DateTime.add(@fixed_now, -index - 10, :second),
            finished_at: DateTime.add(@fixed_now, -index, :second),
            metadata: %{"phase81_key" => names.key},
            inserted_at: @fixed_naive,
            updated_at: @fixed_naive
          }
        end)

      Repo.insert_all(ArchiveRun, archives)
    end

    defp seed_audit(names) do
      rows =
        Enum.map(1..103, fn index ->
          {resource_type, resource_id, event_type} =
            cond do
              index <= 26 -> {"workflow", hd(names.workflow_ids), "workflow.step_unblocked"}
              index <= 52 -> {"batch", names.batch_id, "batch.retry_executed"}
              true -> {"incident", hd(names.incident_ids), "lifeline.repair_executed"}
            end

          %{
            actor_id: "phase81-operator",
            action: event_type,
            command_key: "phase81-#{index}",
            event_type: event_type,
            resource: "#{resource_type}:#{resource_id}",
            resource_type: resource_type,
            resource_id: resource_id,
            metadata: %{"phase81_key" => names.key, "public" => true},
            inserted_at:
              @fixed_naive
              |> NaiveDateTime.add(-index, :second)
          }
        end)

      Repo.insert_all(Audit, rows)
    end

    defp public_state(names) do
      %{
        "project" => names.project,
        "run" => names.run,
        "actors" => @actors,
        "counts" => @counts,
        "handles" => %{
          "batchId" => names.batch_id,
          "workflowId" => hd(names.workflow_ids),
          "workflowStep" => "step-0",
          "incidentId" => hd(names.incident_ids)
        },
        "race" => %{"state" => race_state(names.key)}
      }
    end

    defp fixture_exists?(names),
      do: Repo.exists?(from(batch in Batch, where: batch.id == ^names.batch_id))

    defp put_race(key, state) do
      ensure_state_table()
      :ets.insert(@state_table, {key, state})
    end

    defp race_state(key) do
      ensure_state_table()

      case :ets.lookup(@state_table, key) do
        [{^key, state}] -> state
        [] -> "authorized"
      end
    end

    defp ensure_state_table do
      case :ets.whereis(@state_table) do
        :undefined ->
          try do
            :ets.new(@state_table, [:named_table, :public, :set])
          rescue
            ArgumentError -> @state_table
          end

        table ->
          table
      end
    end

    defp job_id(key, index) do
      <<number::unsigned-64, _::binary>> = :crypto.hash(:sha256, "#{key}:job:#{index}")
      30_000_000_000 + rem(number, 1_000_000_000)
    end

    defp uuid(key) do
      <<raw::binary-size(16), _::binary>> = :crypto.hash(:sha256, key)
      {:ok, uuid} = Ecto.UUID.load(raw)
      uuid
    end
  end

  defmodule PhoenixHostWeb.Phase81BrowserFixturesController do
    @moduledoc false

    use PhoenixHostWeb, :controller

    alias PhoenixHostWeb.Phase81BrowserFixtures

    def reset(conn, params) do
      with :ok <- authenticate(conn),
           {:ok, state} <- Phase81BrowserFixtures.reset(params) do
        json(conn, state)
      else
        _ -> not_found(conn)
      end
    end

    def actor(conn, %{"actor" => actor} = params) do
      with :ok <- authenticate(conn),
           {:ok, session_actor, state} <- Phase81BrowserFixtures.set_actor(params, actor) do
        conn
        |> put_session("ops_actor", session_actor)
        |> json(state)
      else
        _ -> not_found(conn)
      end
    end

    def actor(conn, _params), do: not_found(conn)

    def race(conn, %{"command" => command} = params) do
      with :ok <- authenticate(conn),
           {:ok, state} <- Phase81BrowserFixtures.control_race(params, command) do
        json(conn, state)
      else
        _ -> not_found(conn)
      end
    end

    def race(conn, _params), do: not_found(conn)

    defp authenticate(conn) do
      configured = System.get_env("PHASE81_BROWSER_FIXTURE_SECRET", "")
      supplied = get_req_header(conn, "x-phase81-fixture-secret") |> List.first() || ""

      if byte_size(configured) >= 32 and byte_size(configured) == byte_size(supplied) and
           Plug.Crypto.secure_compare(configured, supplied),
         do: :ok,
         else: {:error, :not_found}
    end

    defp not_found(conn), do: send_resp(conn, 404, "")
  end
end
