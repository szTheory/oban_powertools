phase79_fixture_compile_partition =
  Application.compile_env(:phoenix_host, :phase79_fixture_compile_partition)

if Mix.env() == :test and is_binary(phase79_fixture_compile_partition) and
     System.get_env("PHASE79_BROWSER_FIXTURES") == "1" do
  defmodule PhoenixHostWeb.Phase79BrowserFixtures do
    @moduledoc false

    import Ecto.Query

    alias ObanPowertools.{Audit, Cron, Explain}
    alias ObanPowertools.Cron.{Entry, Slot}
    alias ObanPowertools.Forensics.LimiterHistoryFact
    alias ObanPowertools.Lifeline.{Incident, RepairPreview}
    alias ObanPowertools.Limits.{Resource, State}
    alias PhoenixHost.Repo

    @projects ~w(chromium-320 chromium-tablet chromium-wide)
    @actors ~w(operator read_only)
    @recoveries ~w(expired drifted consumed skipped partial)
    @run_pattern ~r/\A[a-z0-9][a-z0-9_-]{0,47}\z/
    @fixed_now ~U[2035-01-15 12:00:00.000000Z]
    @expired_at ~U[2000-01-01 00:00:00.000000Z]

    def reset(%{"project" => project, "run" => run}) do
      with :ok <- validate_project(project),
           :ok <- validate_run(run) do
        Repo.transaction(fn ->
          names = fixture_names(project, run)
          cleanup(names)

          cron = insert_cron(names)
          limiters = insert_limiters(names)
          insert_overview(names)
          audit = insert_audit(names)
          seed_recovery_preview(cron.recovery)

          public_state(names, cron, limiters, audit)
        end)
      end
    end

    def reset(_params), do: {:error, :not_found}

    def set_actor(%{"project" => project, "run" => run}, actor) do
      with :ok <- validate_project(project),
           :ok <- validate_run(run),
           true <- actor in @actors,
           true <- fixture_exists?(project, run) do
        role = if actor == "operator", do: "ops", else: "read_only"

        session_actor = %{
          "id" => "phase79-#{actor}-#{project}-#{run}",
          "label" => actor,
          "role" => role
        }

        {:ok, session_actor, %{"actor" => actor, "state" => "authenticated"}}
      else
        _invalid -> {:error, :not_found}
      end
    end

    def set_actor(_params, _actor), do: {:error, :not_found}

    def perturb_recovery(entry_name, recovery, repo)
        when is_binary(entry_name) and recovery in @recoveries do
      repo.transaction(fn ->
        with %Entry{} = entry <- repo.get_by(Entry, name: entry_name),
             true <- fixture_entry?(entry) do
          prepare_recovery(repo, entry, recovery)
          %{"recovery" => recovery, "state" => "prepared"}
        else
          _missing -> repo.rollback(:not_found)
        end
      end)
    end

    def perturb_recovery(_entry_name, _recovery, _repo), do: {:error, :not_found}

    defp validate_project(project) when project in @projects, do: :ok
    defp validate_project(_project), do: {:error, :not_found}

    defp validate_run(run) when is_binary(run) do
      if Regex.match?(@run_pattern, run), do: :ok, else: {:error, :not_found}
    end

    defp validate_run(_run), do: {:error, :not_found}

    defp fixture_names(project, run) do
      key = "#{project}:#{run}"
      prefix = "phase79-#{project}-#{run}"

      %{
        project: project,
        run: run,
        key: key,
        prefix: prefix,
        cron_first: "#{prefix}-alpha",
        cron_second: "#{prefix}-beta",
        cron_recovery: "#{prefix}-recovery",
        limiter_runnable: "#{prefix}-runnable",
        limiter_blocked: "#{prefix}-blocked",
        worker_first: "PhoenixHost.Phase79Fixture.#{project}.#{run}.Alpha",
        worker_second: "PhoenixHost.Phase79Fixture.#{project}.#{run}.Beta",
        worker_recovery: "PhoenixHost.Phase79Fixture.#{project}.#{run}.Recovery",
        private_metadata: "phase79-private-metadata-#{project}-#{run}",
        credential_sentinel: "phase79-credential-sentinel-#{project}-#{run}"
      }
    end

    defp cleanup(names) do
      entry_names = [names.cron_first, names.cron_second, names.cron_recovery]
      resource_names = [names.limiter_runnable, names.limiter_blocked]
      worker_names = [names.worker_first, names.worker_second, names.worker_recovery]

      entry_ids =
        Repo.all(from(entry in Entry, where: entry.name in ^entry_names, select: entry.id))

      Repo.delete_all(from(preview in RepairPreview, where: preview.target_id in ^entry_ids))
      Repo.delete_all(from(slot in Slot, where: slot.entry_id in ^entry_ids))
      Repo.delete_all(from(job in Oban.Job, where: job.worker in ^worker_names))

      Repo.delete_all(
        from(event in Audit,
          where:
            event.resource_id in ^entry_names or
              fragment("?->>'phase79_key' = ?", event.metadata, ^names.key)
        )
      )

      Repo.delete_all(from(explain in Explain, where: explain.scope_id in ^resource_names))

      Repo.delete_all(
        from(fact in LimiterHistoryFact, where: fact.resource_name in ^resource_names)
      )

      Repo.delete_all(
        from(incident in Incident,
          where:
            incident.incident_fingerprint in ^[
              "phase79:#{names.key}:active",
              "phase79:#{names.key}:resolved"
            ]
        )
      )

      Repo.delete_all(from(resource in Resource, where: resource.name in ^resource_names))
      Repo.delete_all(from(entry in Entry, where: entry.name in ^entry_names))
    end

    defp insert_cron(names) do
      first = insert_entry(names, names.cron_first, names.worker_first, nil, "queue_one")

      second =
        insert_entry(names, names.cron_second, names.worker_second, @fixed_now, "queue_one")

      recovery =
        insert_entry(names, names.cron_recovery, names.worker_recovery, nil, "skip")

      %{first: first, second: second, recovery: recovery}
    end

    defp insert_entry(names, name, worker, paused_at, overlap_policy) do
      %Entry{}
      |> Entry.changeset(%{
        name: name,
        source: "phase79_fixture",
        worker: worker,
        queue: "default",
        expression: "*/5 * * * *",
        timezone: "Etc/UTC",
        args: %{"phase79_key" => names.key},
        opts: %{},
        overlap_policy: overlap_policy,
        catch_up_policy: "latest",
        max_catch_up: 1,
        paused_at: paused_at,
        metadata: fixture_metadata(names)
      })
      |> Repo.insert!()
    end

    defp insert_limiters(names) do
      runnable = insert_resource(names, names.limiter_runnable, 10)
      blocked = insert_resource(names, names.limiter_blocked, 2)

      insert_state(runnable, 1, nil)
      insert_state(blocked, 2, DateTime.add(@fixed_now, 3_600, :second))

      %Explain{}
      |> Explain.changeset(%{
        job_id: deterministic_job_id(names.key),
        worker: names.worker_recovery,
        status: "blocked",
        scope_kind: "global",
        scope_id: blocked.name,
        blocker_codes: ["limit_reached"],
        details: %{
          "phase79_key" => names.key,
          "partition_key" => "__global__",
          "weight" => 1,
          "live_now" => [
            %{
              "code" => "limit_reached",
              "summary" => "resource bucket is saturated"
            }
          ]
        },
        captured_at: @fixed_now
      })
      |> Repo.insert!()

      %LimiterHistoryFact{}
      |> LimiterHistoryFact.changeset(%{
        resource_name: blocked.name,
        partition_key: "__global__",
        event_type: "limiter.pressure_observed",
        cause_kind: "transient_pressure",
        occurred_at: DateTime.add(@fixed_now, -3_600, :second),
        eligible_at: DateTime.add(@fixed_now, 3_600, :second),
        metadata: fixture_metadata(names)
      })
      |> Repo.insert!()

      %{runnable: runnable, blocked: blocked}
    end

    defp insert_resource(names, name, capacity) do
      %Resource{}
      |> Resource.changeset(%{
        name: name,
        scope_kind: "global",
        algorithm: "fixed_window",
        bucket_span_ms: 60_000,
        bucket_capacity: capacity,
        default_weight: 1,
        partition_strategy: "global",
        partition_config: %{},
        cooldown_enabled: true,
        metadata: fixture_metadata(names)
      })
      |> Repo.insert!()
    end

    defp insert_state(resource, tokens_used, cooldown_until) do
      %State{}
      |> State.changeset(%{
        resource_id: resource.id,
        partition_key: "__global__",
        tokens_used: tokens_used,
        bucket_started_at: @fixed_now,
        last_reserved_at: @fixed_now,
        cooldown_until: cooldown_until,
        cooldown_reason: if(cooldown_until, do: "capacity review", else: nil),
        reservation_snapshot: %{"source" => "phase79_fixture"}
      })
      |> Repo.insert!()
    end

    defp insert_overview(names) do
      insert_incident(names, "active", nil)
      insert_incident(names, "resolved", @fixed_now)
    end

    defp insert_incident(names, status, resolved_at) do
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "phase79_fixture",
        status: status,
        incident_fingerprint: "phase79:#{names.key}:#{status}",
        health_state: if(status == "active", do: "degraded", else: "healthy"),
        summary: "Phase 79 #{status} continuity for #{names.key}",
        affected_counts: %{"items" => 1},
        evidence: %{"state" => status},
        first_detected_at: DateTime.add(@fixed_now, -7_200, :second),
        last_detected_at: @fixed_now,
        resolved_at: resolved_at,
        metadata: fixture_metadata(names)
      })
      |> Repo.insert!()
    end

    defp insert_audit(names) do
      base = deterministic_audit_base(names.key)
      old_start = DateTime.add(@fixed_now, -86_400, :second)

      Enum.each(1..45, fn index ->
        insert_audit_event(base + index, names, %{
          action: "phase79.fixture.reviewed",
          event_type: "phase79.fixture.reviewed",
          resource: "phase79_fixture:#{names.key}",
          resource_type: "phase79_fixture",
          resource_id: names.key,
          inserted_at: DateTime.add(old_start, index, :second)
        })
      end)

      newer =
        Enum.map(1..21, fn index ->
          id = base + 100 + index

          insert_audit_event(id, names, %{
            action: "phase79.fixture.noise",
            event_type: "phase79.fixture.noise",
            resource: "cron_entry:#{names.cron_first}",
            resource_type: "cron_entry",
            resource_id: names.cron_first,
            inserted_at: DateTime.add(@fixed_now, index, :second)
          })
        end)

      [first, second | _rest] = Enum.reverse(newer)
      %{first: first, second: second}
    end

    defp insert_audit_event(id, names, attrs) do
      metadata =
        fixture_metadata(names)
        |> Map.put("reason", "Fixture evidence for #{names.key}")
        |> Map.put("outcome", "recorded")
        |> Map.put("source", "phase79_fixture")

      %Audit{id: id}
      |> Audit.changeset(%{
        actor_id: "phase79-operator",
        action: attrs.action,
        event_type: attrs.event_type,
        resource: attrs.resource,
        resource_type: attrs.resource_type,
        resource_id: attrs.resource_id,
        metadata: metadata
      })
      |> Ecto.Changeset.put_change(
        :inserted_at,
        attrs.inserted_at |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      )
      |> Repo.insert!()
    end

    defp seed_recovery_preview(entry) do
      {:ok, preview} = Cron.preview_entry_action(Repo, "run_cron_entry", entry, now: @fixed_now)
      preview
    end

    defp prepare_recovery(repo, entry, recovery) do
      repo.delete_all(from(slot in Slot, where: slot.entry_id == ^entry.id))
      repo.delete_all(from(job in Oban.Job, where: job.worker == ^entry.worker))

      repo.delete_all(
        from(event in Audit,
          where: event.resource_type == "cron_entry" and event.resource_id == ^entry.name
        )
      )

      preview =
        repo.one(
          from(preview in RepairPreview,
            where:
              preview.target_id == ^entry.id and preview.action == "run_cron_entry" and
                preview.status == "ready",
            order_by: [desc: preview.inserted_at],
            limit: 1
          )
        ) || repo.rollback(:not_found)

      case recovery do
        "expired" ->
          preview
          |> RepairPreview.changeset(%{expires_at: @expired_at})
          |> repo.update!()

        "drifted" ->
          entry
          |> Entry.changeset(%{overlap_policy: "queue_one"})
          |> repo.update!()

        "consumed" ->
          preview
          |> RepairPreview.changeset(%{consumed_at: @fixed_now})
          |> repo.update!()

        recovery when recovery in ["skipped", "partial"] ->
          entry.args
          |> Oban.Job.new(worker: entry.worker, queue: entry.queue, scheduled_at: @fixed_now)
          |> repo.insert!()
      end
    end

    defp public_state(names, cron, limiters, audit) do
      %{
        "project" => names.project,
        "run" => names.run,
        "cron" => %{
          "firstEntry" => cron.first.name,
          "secondEntry" => cron.second.name,
          "pausedEntry" => cron.second.name,
          "recoveryEntry" => cron.recovery.name
        },
        "limiters" => %{
          "firstResource" => limiters.runnable.name,
          "secondResource" => limiters.blocked.name,
          "blockedResource" => limiters.blocked.name
        },
        "audit" => %{
          "firstEvent" => Integer.to_string(audit.first.id),
          "secondEvent" => Integer.to_string(audit.second.id),
          "boundaryPage" => 3
        },
        "counts" => %{
          "cronEntries" => 3,
          "limiterResources" => 2,
          "auditFiltered" => 45,
          "auditNewerUnrelated" => 21,
          "overviewActive" => 1,
          "overviewResolved" => 1
        },
        "actors" => @actors,
        "confidentialitySentinels" => [names.private_metadata, names.credential_sentinel]
      }
    end

    defp fixture_metadata(names) do
      %{
        "phase79_fixture" => true,
        "phase79_key" => names.key,
        "private_value" => names.private_metadata,
        "credential" => names.credential_sentinel
      }
    end

    defp fixture_exists?(project, run) do
      names = fixture_names(project, run)
      Repo.exists?(from(entry in Entry, where: entry.name == ^names.cron_first))
    end

    defp fixture_entry?(entry) do
      get_in(entry.metadata || %{}, ["phase79_fixture"]) == true and
        is_binary(get_in(entry.metadata || %{}, ["phase79_key"]))
    end

    defp deterministic_audit_base(key) do
      <<number::unsigned-32, _rest::binary>> = :crypto.hash(:sha256, key)
      100_000_000 + rem(number, 1_800_000) * 1_000
    end

    defp deterministic_job_id(key) do
      <<number::unsigned-32, _rest::binary>> = :crypto.hash(:sha256, "job:" <> key)
      1 + rem(number, 2_000_000_000)
    end
  end

  defmodule PhoenixHostWeb.Phase79BrowserFixturesController do
    @moduledoc false

    use PhoenixHostWeb, :controller

    alias PhoenixHostWeb.Phase79BrowserFixtures

    def reset(conn, params) do
      with :ok <- authenticate(conn),
           {:ok, state} <- Phase79BrowserFixtures.reset(params) do
        json(conn, state)
      else
        _denied_or_unavailable -> not_found(conn)
      end
    end

    def actor(conn, params) do
      with :ok <- authenticate(conn),
           {:ok, session_actor, state} <-
             Phase79BrowserFixtures.set_actor(params, Map.get(params, "actor")) do
        conn
        |> put_session("ops_actor", session_actor)
        |> json(state)
      else
        _denied_or_unavailable -> not_found(conn)
      end
    end

    def recovery(conn, params) do
      with :ok <- authenticate(conn),
           {:ok, state} <-
             Phase79BrowserFixtures.perturb_recovery(
               Map.get(params, "entry"),
               Map.get(params, "recovery"),
               PhoenixHost.Repo
             ) do
        json(conn, state)
      else
        _denied_or_unavailable -> not_found(conn)
      end
    end

    defp authenticate(conn) do
      expected = System.get_env("PHASE79_BROWSER_FIXTURE_SECRET") || ""
      provided = conn |> get_req_header("x-phase79-fixture-secret") |> List.first() || ""

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
