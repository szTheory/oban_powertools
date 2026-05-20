defmodule Mix.Tasks.ObanPowertools.Install do
  use Igniter.Mix.Task

  @shortdoc "Installs Oban Powertools into a Phoenix application"

  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [],
      positional: []
    }
  end

  def igniter(igniter) do
    igniter
    |> setup_auth_module()
    |> setup_runtime_config()
    |> setup_router_scope()
    |> setup_migration()
    |> setup_smart_engine_migrations()
    |> setup_workflow_migrations()
    |> setup_phase_4_migrations()
  end

  defp setup_auth_module(igniter) do
    web_module = Igniter.Libs.Phoenix.web_module(igniter)

    auth_module_name = Module.concat(web_module, "ObanPowertoolsAuth")

    contents = """
      @moduledoc "Host-implemented authorization for Powertools actions."
      @behaviour ObanPowertools.Auth

      @impl true
      def current_actor(_conn_or_socket) do
        # TODO: Return the current actor from your session/assigns
        nil
      end

      @impl true
      def can_perform_action?(_actor, _action, _resource) do
        # TODO: Implement your authorization logic
        false
      end
    """

    Igniter.Project.Module.create_module(igniter, auth_module_name, contents)
  end

  defp setup_runtime_config(igniter) do
    app_module = Igniter.Project.Module.module_name_prefix(igniter)
    web_module = Igniter.Libs.Phoenix.web_module(igniter)
    auth_module_name = Module.concat(web_module, "ObanPowertoolsAuth")

    Igniter.Project.Config.configure_group(
      igniter,
      "config.exs",
      :oban_powertools,
      [],
      [
        {[:repo], {:code, Macro.escape(Module.concat(app_module, "Repo"))}},
        {[:auth_module], {:code, Macro.escape(auth_module_name)}}
      ],
      comment: """
      Explicit Powertools host wiring:

      config :oban_powertools,
        repo: MyApp.Repo,
        auth_module: MyAppWeb.ObanPowertoolsAuth
      """
    )
  end

  defp setup_router_scope(igniter) do
    router_contents = """
      require ObanPowertools.Web.Router
      ObanPowertools.Web.Router.oban_powertools_routes("/oban")
    """

    Igniter.Libs.Phoenix.add_scope(
      igniter,
      "/ops/jobs",
      router_contents,
      []
    )
  end

  defp setup_migration(igniter) do
    igniter
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_audit_events",
      body: """
        def change do
          create table(:oban_powertools_audit_events) do
            add :actor_id, :string
            add :action, :string, null: false
            add :resource, :string
            add :metadata, :map, default: %{}

            timestamps(updated_at: false)
          end
          
          create index(:oban_powertools_audit_events, [:actor_id])
          create index(:oban_powertools_audit_events, [:action])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_idempotency_receipts",
      body: """
        def change do
          create table(:oban_powertools_idempotency_receipts, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :worker, :string, null: false
            add :fingerprint, :string, null: false
            add :job_id, :bigint
            add :state, :string, null: false
            add :expires_at, :utc_datetime

            timestamps()
          end

          create unique_index(:oban_powertools_idempotency_receipts, [:worker, :fingerprint])
          create index(:oban_powertools_idempotency_receipts, [:job_id])
        end
      """
    )
  end

  defp setup_smart_engine_migrations(igniter) do
    igniter
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_limit_resources",
      body: """
        def change do
          create table(:oban_powertools_limit_resources, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :name, :string, null: false
            add :scope_kind, :string, null: false
            add :algorithm, :string, null: false
            add :bucket_span_ms, :bigint, null: false
            add :bucket_capacity, :integer, null: false
            add :default_weight, :integer, null: false, default: 1
            add :partition_strategy, :string, null: false, default: "global"
            add :partition_config, :map, null: false, default: %{}
            add :cooldown_enabled, :boolean, null: false, default: true
            add :metadata, :map, null: false, default: %{}

            timestamps()
          end

          create unique_index(:oban_powertools_limit_resources, [:name])
          create index(:oban_powertools_limit_resources, [:scope_kind])
          create index(:oban_powertools_limit_resources, [:algorithm])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_limit_states",
      body: """
        def change do
          create table(:oban_powertools_limit_states, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :resource_id, references(:oban_powertools_limit_resources, type: :uuid, on_delete: :delete_all), null: false
            add :partition_key, :string, null: false, default: "__global__"
            add :tokens_used, :integer, null: false, default: 0
            add :bucket_started_at, :utc_datetime_usec, null: false
            add :last_reserved_at, :utc_datetime_usec
            add :cooldown_until, :utc_datetime_usec
            add :cooldown_reason, :string
            add :reservation_snapshot, :map, null: false, default: %{}

            timestamps()
          end

          create unique_index(:oban_powertools_limit_states, [:resource_id, :partition_key])
          create index(:oban_powertools_limit_states, [:cooldown_until])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_cron_entries",
      body: """
        def change do
          create table(:oban_powertools_cron_entries, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :name, :string, null: false
            add :source, :string, null: false
            add :worker, :string, null: false
            add :queue, :string, null: false, default: "default"
            add :expression, :string, null: false
            add :timezone, :string, null: false, default: "Etc/UTC"
            add :args, :map, null: false, default: %{}
            add :opts, :map, null: false, default: %{}
            add :overlap_policy, :string, null: false, default: "queue_one"
            add :catch_up_policy, :string, null: false, default: "latest"
            add :max_catch_up, :integer, null: false, default: 1
            add :paused_at, :utc_datetime_usec
            add :last_run_at, :utc_datetime_usec
            add :metadata, :map, null: false, default: %{}

            timestamps()
          end

          create unique_index(:oban_powertools_cron_entries, [:name])
          create index(:oban_powertools_cron_entries, [:source])
          create index(:oban_powertools_cron_entries, [:paused_at])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_cron_slots",
      body: """
        def change do
          create table(:oban_powertools_cron_slots, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :entry_id, references(:oban_powertools_cron_entries, type: :uuid, on_delete: :delete_all), null: false
            add :slot_at, :utc_datetime_usec, null: false
            add :state, :string, null: false, default: "pending"
            add :job_id, :bigint
            add :claim_token, :uuid
            add :claimed_at, :utc_datetime_usec
            add :finished_at, :utc_datetime_usec
            add :attempt_count, :integer, null: false, default: 0
            add :policy_snapshot, :map, null: false, default: %{}
            add :metadata, :map, null: false, default: %{}

            timestamps()
          end

          create unique_index(:oban_powertools_cron_slots, [:entry_id, :slot_at])
          create index(:oban_powertools_cron_slots, [:state])
          create index(:oban_powertools_cron_slots, [:job_id])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_blocker_snapshots",
      body: """
        def change do
          create table(:oban_powertools_blocker_snapshots, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :job_id, :bigint, null: false
            add :worker, :string, null: false
            add :status, :string, null: false, default: "blocked"
            add :scope_kind, :string, null: false
            add :scope_id, :string, null: false
            add :blocker_codes, {:array, :string}, null: false, default: []
            add :details, :map, null: false, default: %{}
            add :captured_at, :utc_datetime_usec, null: false

            timestamps(updated_at: false)
          end

          create index(:oban_powertools_blocker_snapshots, [:job_id])
          create index(:oban_powertools_blocker_snapshots, [:worker])
          create index(:oban_powertools_blocker_snapshots, [:scope_kind, :scope_id])
        end
      """
    )
  end

  defp setup_workflow_migrations(igniter) do
    igniter
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_workflows",
      body: """
        def change do
          create table(:oban_powertools_workflows, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :name, :string, null: false
            add :state, :string, null: false, default: "pending"
            add :workflow_context, :map, null: false, default: %{}
            add :definition_version, :integer, null: false, default: 1
            add :step_count, :integer, null: false, default: 0
            add :runnable_step_count, :integer, null: false, default: 0
            add :completed_step_count, :integer, null: false, default: 0
            add :cancelled_step_count, :integer, null: false, default: 0
            add :failed_step_count, :integer, null: false, default: 0
            add :started_at, :utc_datetime_usec
            add :finished_at, :utc_datetime_usec
            add :cancelled_at, :utc_datetime_usec

            timestamps()
          end

          create unique_index(:oban_powertools_workflows, [:name])
          create index(:oban_powertools_workflows, [:state])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_workflow_steps",
      body: """
        def change do
          create table(:oban_powertools_workflow_steps, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :workflow_id, references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all), null: false
            add :step_name, :string, null: false
            add :worker, :string, null: false
            add :input, :map, null: false, default: %{}
            add :context, :map, null: false, default: %{}
            add :state, :string, null: false, default: "pending"
            add :job_id, :bigint
            add :queue, :string, null: false, default: "default"
            add :attempt, :integer, null: false, default: 0
            add :position, :integer, null: false, default: 0
            add :dependency_count, :integer, null: false, default: 0
            add :dependency_snapshot, :map, null: false, default: %{}
            add :blocker_codes, {:array, :string}, null: false, default: []
            add :blocker_details, :map, null: false, default: %{}
            add :nested_workflow_id, references(:oban_powertools_workflows, type: :uuid, on_delete: :nilify_all)
            add :started_at, :utc_datetime_usec
            add :finished_at, :utc_datetime_usec
            add :cancelled_at, :utc_datetime_usec

            timestamps()
          end

          create unique_index(:oban_powertools_workflow_steps, [:workflow_id, :step_name])
          create index(:oban_powertools_workflow_steps, [:state])
          create index(:oban_powertools_workflow_steps, [:job_id])
          create index(:oban_powertools_workflow_steps, [:nested_workflow_id])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_workflow_edges",
      body: """
        def change do
          create table(:oban_powertools_workflow_edges, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :workflow_id, references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all), null: false
            add :from_step_id, references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :delete_all), null: false
            add :to_step_id, references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :delete_all), null: false
            add :policy, :string, null: false, default: "cancel"
            add :terminal_snapshot, :map, null: false, default: %{}

            timestamps()
          end

          create unique_index(:oban_powertools_workflow_edges, [:workflow_id, :from_step_id, :to_step_id])
          create index(:oban_powertools_workflow_edges, [:to_step_id])
          create index(:oban_powertools_workflow_edges, [:from_step_id])
          create index(:oban_powertools_workflow_edges, [:policy])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_workflow_results",
      body: """
        def change do
          create table(:oban_powertools_workflow_results, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :workflow_id, references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all), null: false
            add :step_id, references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :delete_all), null: false
            add :attempt, :integer, null: false, default: 1
            add :status, :string, null: false, default: "ok"
            add :payload, :map, null: false, default: %{}
            add :payload_bytes, :integer, null: false, default: 0
            add :retention, :string, null: false, default: "standard"
            add :redacted, :boolean, null: false, default: false
            add :summary, :string
            add :recorded_at, :utc_datetime_usec, null: false
            add :expires_at, :utc_datetime_usec

            timestamps(updated_at: false)
          end

          create unique_index(:oban_powertools_workflow_results, [:step_id, :attempt])
          create index(:oban_powertools_workflow_results, [:workflow_id])
          create index(:oban_powertools_workflow_results, [:status])
          create index(:oban_powertools_workflow_results, [:expires_at])
        end
      """
    )
  end

  defp setup_phase_4_migrations(igniter) do
    igniter
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_heartbeats",
      body: """
        def change do
          create table(:oban_powertools_heartbeats, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :executor_id, :string, null: false
            add :oban_name, :string, null: false, default: "Oban"
            add :node, :string, null: false
            add :queue, :string, null: false, default: "default"
            add :producer_scope, :string, null: false
            add :health_state, :string, null: false, default: "healthy"
            add :last_heartbeat_at, :utc_datetime_usec, null: false
            add :warning_threshold_ms, :bigint, null: false, default: 45000
            add :missing_threshold_ms, :bigint, null: false, default: 120000
            add :metadata, :map, null: false, default: %{}

            timestamps()
          end

          create unique_index(:oban_powertools_heartbeats, [:executor_id])
          create index(:oban_powertools_heartbeats, [:health_state])
          create index(:oban_powertools_heartbeats, [:last_heartbeat_at])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_lifeline_incidents",
      body: """
        def change do
          create table(:oban_powertools_lifeline_incidents, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :incident_class, :string, null: false
            add :status, :string, null: false, default: "active"
            add :executor_id, :string
            add :workflow_id, :uuid
            add :workflow_step_id, :uuid
            add :incident_fingerprint, :string, null: false
            add :health_state, :string
            add :summary, :string
            add :affected_counts, :map, null: false, default: %{}
            add :evidence, :map, null: false, default: %{}
            add :first_detected_at, :utc_datetime_usec, null: false
            add :last_detected_at, :utc_datetime_usec, null: false
            add :resolved_at, :utc_datetime_usec
            add :metadata, :map, null: false, default: %{}

            timestamps()
          end

          create unique_index(:oban_powertools_lifeline_incidents, [:incident_fingerprint])
          create index(:oban_powertools_lifeline_incidents, [:incident_class])
          create index(:oban_powertools_lifeline_incidents, [:status])
          create index(:oban_powertools_lifeline_incidents, [:health_state])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_repair_previews",
      body: """
        def change do
          create table(:oban_powertools_repair_previews, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :incident_id, :uuid
            add :incident_class, :string, null: false
            add :incident_fingerprint, :string, null: false
            add :plan_hash, :string, null: false
            add :preview_token, :uuid, null: false
            add :action, :string, null: false
            add :target_type, :string, null: false
            add :target_id, :string, null: false
            add :health_state, :string
            add :status, :string, null: false, default: "pending"
            add :affected_counts, :map, null: false, default: %{}
            add :before_snapshot, :map, null: false, default: %{}
            add :after_snapshot, :map, null: false, default: %{}
            add :evidence, :map, null: false, default: %{}
            add :reason_required, :boolean, null: false, default: true
            add :executed_at, :utc_datetime_usec
            add :consumed_at, :utc_datetime_usec
            add :expires_at, :utc_datetime_usec
            add :metadata, :map, null: false, default: %{}

            timestamps()
          end

          create unique_index(:oban_powertools_repair_previews, [:preview_token])
          create index(:oban_powertools_repair_previews, [:incident_class])
          create index(:oban_powertools_repair_previews, [:status])
          create index(:oban_powertools_repair_previews, [:incident_fingerprint])
          create index(:oban_powertools_repair_previews, [:plan_hash])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_archive_runs",
      body: """
        def change do
          create table(:oban_powertools_archive_runs, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :run_type, :string, null: false
            add :status, :string, null: false, default: "pending"
            add :retention_class, :string, null: false
            add :actor_id, :string
            add :reason, :string
            add :batch_size, :integer, null: false, default: 100
            add :archived_count, :integer, null: false, default: 0
            add :pruned_count, :integer, null: false, default: 0
            add :blocked_count, :integer, null: false, default: 0
            add :started_at, :utc_datetime_usec
            add :finished_at, :utc_datetime_usec
            add :metadata, :map, null: false, default: %{}

            timestamps()
          end

          create index(:oban_powertools_archive_runs, [:run_type])
          create index(:oban_powertools_archive_runs, [:status])
          create index(:oban_powertools_archive_runs, [:retention_class])
          create index(:oban_powertools_archive_runs, [:started_at])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_repair_archives",
      body: """
        def change do
          create table(:oban_powertools_repair_archives, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :archive_run_id, references(:oban_powertools_archive_runs, type: :uuid, on_delete: :nilify_all)
            add :audit_event_id, references(:oban_powertools_audit_events, on_delete: :nilify_all)
            add :resource_type, :string, null: false
            add :resource_id, :string, null: false
            add :action, :string, null: false
            add :incident_class, :string
            add :incident_fingerprint, :string
            add :plan_hash, :string
            add :reason, :string
            add :actor_id, :string
            add :affected_counts, :map, null: false, default: %{}
            add :evidence, :map, null: false, default: %{}
            add :archived_at, :utc_datetime_usec, null: false
            add :metadata, :map, null: false, default: %{}

            timestamps(updated_at: false)
          end

          create index(:oban_powertools_repair_archives, [:archive_run_id])
          create index(:oban_powertools_repair_archives, [:audit_event_id])
          create index(:oban_powertools_repair_archives, [:resource_type, :resource_id])
          create index(:oban_powertools_repair_archives, [:incident_class])
          create index(:oban_powertools_repair_archives, [:archived_at])
        end
      """
    )
  end
end
