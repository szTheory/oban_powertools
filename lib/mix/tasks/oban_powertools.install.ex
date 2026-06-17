defmodule Mix.Tasks.ObanPowertools.Install do
  use Igniter.Mix.Task

  @shortdoc "Installs Oban Powertools into a Phoenix application"
  @powertools_config_contract """
  config :oban_powertools,
    repo: MyApp.Repo,
    auth_module: MyAppWeb.ObanPowertoolsAuth,
    display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy
  """
  @router_scope_contract """
  scope "/ops/jobs" do
    pipe_through :browser

    require ObanPowertools.Web.Router
    ObanPowertools.Web.Router.oban_powertools_routes("/oban")
  end
  """

  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [],
      positional: []
    }
  end

  def igniter(igniter) do
    igniter
    |> setup_auth_module()
    |> setup_display_policy_module()
    |> setup_runtime_config()
    |> setup_router_scope()
    |> setup_migration()
    |> setup_smart_engine_migrations()
    |> setup_workflow_migrations()
    |> setup_batch_migrations()
    |> setup_phase_4_migrations()
    |> setup_job_record_migrations()
  end

  defp setup_auth_module(igniter) do
    web_module = Igniter.Libs.Phoenix.web_module(igniter)
    auth_module_name = Module.concat(web_module, "ObanPowertoolsAuth")

    contents = """
      @moduledoc \"\"\"
      Thin host-owned Powertools auth seam.

      Fill in your real operator actor lookup, authorization policy, and durable
      audit principal envelope before exposing operator routes in production.
      \"\"\"
      @behaviour ObanPowertools.Auth

      @impl true
      def current_actor(_conn_or_socket) do
        # TODO: Return the current actor from your session/assigns
        nil
      end

      @impl true
      def authorize(nil, _action, _resource), do: {:error, :unauthorized}

      def authorize(_actor, _action, _resource) do
        # TODO: Authorize Powertools actions for your real operator roles
        {:error, :unauthorized}
      end

      @impl true
      def audit_principal(_actor) do
        # TODO: Return %{id: ..., type: ..., label: ...} for durable audit attribution
        nil
      end
    """

    Igniter.Project.Module.create_module(igniter, auth_module_name, contents)
  end

  defp setup_display_policy_module(igniter) do
    web_module = Igniter.Libs.Phoenix.web_module(igniter)
    display_policy_module_name = Module.concat(web_module, "ObanPowertoolsDisplayPolicy")

    contents = """
      @moduledoc \"\"\"
      Thin host-owned Powertools display policy seam.

      Return redacted or host-formatted values for operator-visible fields.
      \"\"\"

      def display(_kind, _value, _context) do
        # TODO: Redact or format operator-visible values for your host
        nil
      end
    """

    Igniter.Project.Module.create_module(igniter, display_policy_module_name, contents)
  end

  defp setup_runtime_config(igniter) do
    _ = @powertools_config_contract

    app_module = Igniter.Project.Module.module_name_prefix(igniter)
    web_module = Igniter.Libs.Phoenix.web_module(igniter)
    repo_module = Module.concat(app_module, "Repo")
    auth_module_name = Module.concat(web_module, "ObanPowertoolsAuth")
    display_policy_module_name = Module.concat(web_module, "ObanPowertoolsDisplayPolicy")

    igniter
    |> Igniter.Project.Config.configure_new(
      "config.exs",
      :oban_powertools,
      [:repo],
      {:code, quote(do: unquote(repo_module))}
    )
    |> Igniter.Project.Config.configure_new(
      "config.exs",
      :oban_powertools,
      [:auth_module],
      {:code, quote(do: unquote(auth_module_name))}
    )
    |> Igniter.Project.Config.configure_new(
      "config.exs",
      :oban_powertools,
      [:display_policy],
      {:code, quote(do: unquote(display_policy_module_name))}
    )
  end

  defp setup_router_scope(igniter) do
    _ = @router_scope_contract

    router_contents = """
      pipe_through :browser

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
      repo_module(igniter),
      "oban_powertools_audit_events",
      timestamp: migration_timestamp(0),
      body: """
        def change do
          create table(:oban_powertools_audit_events) do
            add :actor_id, :string
            add :action, :string, null: false
            add :command_key, :string
            add :event_type, :string
            add :resource, :string
            add :resource_type, :string
            add :resource_id, :string
            add :metadata, :map, default: %{}

            timestamps(updated_at: false)
          end
          
          create index(:oban_powertools_audit_events, [:actor_id])
          create index(:oban_powertools_audit_events, [:action])
          create index(:oban_powertools_audit_events, [:event_type])
          create index(:oban_powertools_audit_events, [:resource_type, :resource_id])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_idempotency_receipts",
      timestamp: migration_timestamp(1),
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
      repo_module(igniter),
      "oban_powertools_limit_resources",
      timestamp: migration_timestamp(10),
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
      repo_module(igniter),
      "oban_powertools_limit_states",
      timestamp: migration_timestamp(11),
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
      repo_module(igniter),
      "oban_powertools_cron_entries",
      timestamp: migration_timestamp(12),
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
      repo_module(igniter),
      "oban_powertools_cron_slots",
      timestamp: migration_timestamp(13),
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
      repo_module(igniter),
      "oban_powertools_blocker_snapshots",
      timestamp: migration_timestamp(14),
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
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_limiter_history_facts",
      timestamp: migration_timestamp(15),
      body: """
        @disable_ddl_transaction true
        def change do
          create table(:oban_powertools_limiter_history_facts, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :resource_name, :string, null: false
            add :partition_key, :string, null: false, default: "__global__"
            add :event_type, :string, null: false
            add :cause_kind, :string
            add :occurred_at, :utc_datetime_usec, null: false
            add :eligible_at, :utc_datetime_usec
            add :metadata, :map, null: false, default: %{}

            timestamps(updated_at: false)
          end

          create index(:oban_powertools_limiter_history_facts, [:resource_name, :occurred_at], concurrently: true)
          create index(:oban_powertools_limiter_history_facts, [:event_type], concurrently: true)
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_cron_coverages",
      timestamp: migration_timestamp(16),
      body: """
        def change do
          create table(:oban_powertools_cron_coverages, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :entry_id, references(:oban_powertools_cron_entries, type: :uuid, on_delete: :delete_all), null: false
            add :slot_at, :utc_datetime_usec, null: false
            add :status, :string, null: false, default: "healthy"
            add :metadata, :map, null: false, default: %{}

            timestamps(updated_at: false)
          end

          create unique_index(:oban_powertools_cron_coverages, [:entry_id, :slot_at])
          create index(:oban_powertools_cron_coverages, [:status])
        end
      """
    )
  end

  defp setup_workflow_migrations(igniter) do
    igniter
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_workflows",
      timestamp: migration_timestamp(20),
      body: """
        @disable_ddl_transaction true
        def change do
          create table(:oban_powertools_workflows, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :name, :string, null: false
            add :state, :string, null: false, default: "pending"
            add :workflow_context, :map, null: false, default: %{}
            add :definition_version, :integer, null: false, default: 1
            add :semantics_version, :integer, null: false, default: 2
            add :step_count, :integer, null: false, default: 0
            add :runnable_step_count, :integer, null: false, default: 0
            add :completed_step_count, :integer, null: false, default: 0
            add :cancelled_step_count, :integer, null: false, default: 0
            add :failed_step_count, :integer, null: false, default: 0
            add :terminal_cause, :string
            add :cancel_requested_at, :utc_datetime_usec
            add :last_transition_at, :utc_datetime_usec
            add :started_at, :utc_datetime_usec
            add :finished_at, :utc_datetime_usec
            add :cancelled_at, :utc_datetime_usec

            timestamps()
          end

          create unique_index(:oban_powertools_workflows, [:name], concurrently: true)
          create index(:oban_powertools_workflows, [:state], concurrently: true)
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_workflow_steps",
      timestamp: migration_timestamp(21),
      body: """
        @disable_ddl_transaction true
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
            add :terminal_cause, :string
            add :active_await_id, :uuid
            add :awaiting_signal_name, :string
            add :await_correlation_key, :string
            add :await_dedupe_key, :string
            add :await_deadline_at, :utc_datetime_usec
            add :cancel_requested_at, :utc_datetime_usec
            add :last_transition_at, :utc_datetime_usec
            add :nested_workflow_id, references(:oban_powertools_workflows, type: :uuid, on_delete: :nilify_all)
            add :started_at, :utc_datetime_usec
            add :finished_at, :utc_datetime_usec
            add :cancelled_at, :utc_datetime_usec

            timestamps()
          end

          create unique_index(:oban_powertools_workflow_steps, [:workflow_id, :step_name], concurrently: true)
          create index(:oban_powertools_workflow_steps, [:state], concurrently: true)
          create index(:oban_powertools_workflow_steps, [:job_id], concurrently: true)
          create index(:oban_powertools_workflow_steps, [:nested_workflow_id], concurrently: true)
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_workflow_edges",
      timestamp: migration_timestamp(22),
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
      repo_module(igniter),
      "oban_powertools_workflow_results",
      timestamp: migration_timestamp(23),
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
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_workflow_semantics",
      timestamp: migration_timestamp(24),
      body: """
        def change do
          create table(:oban_powertools_workflow_awaits, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :workflow_id, references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all), null: false
            add :step_id, references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :delete_all), null: false
            add :signal_name, :string, null: false
            add :correlation_key, :string, null: false
            add :dedupe_key, :string, null: false
            add :status, :string, null: false, default: "waiting"
            add :resolution_policy, :string, null: false, default: "ignore_late"
            add :deadline_at, :utc_datetime_usec
            add :resolved_at, :utc_datetime_usec
            add :resolved_signal_id, :uuid

            timestamps(updated_at: false)
          end

          create index(:oban_powertools_workflow_awaits, [:workflow_id])
          create index(:oban_powertools_workflow_awaits, [:signal_name, :correlation_key])
          create unique_index(:oban_powertools_workflow_awaits, [:step_id, :status], name: :oban_powertools_workflow_awaits_step_id_status_index)

          create table(:oban_powertools_workflow_signals, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :workflow_id, references(:oban_powertools_workflows, type: :uuid, on_delete: :nilify_all)
            add :matched_step_id, references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :nilify_all)
            add :await_id, references(:oban_powertools_workflow_awaits, type: :uuid, on_delete: :nilify_all)
            add :signal_name, :string, null: false
            add :correlation_key, :string, null: false
            add :dedupe_key, :string, null: false
            add :status, :string, null: false, default: "recorded"
            add :payload, :map, null: false, default: %{}
            add :received_at, :utc_datetime_usec, null: false

            timestamps(updated_at: false)
          end

          create unique_index(:oban_powertools_workflow_signals, [:signal_name, :correlation_key, :dedupe_key], name: :oban_powertools_workflow_signals_dedupe_index)
          create index(:oban_powertools_workflow_signals, [:workflow_id])
          create index(:oban_powertools_workflow_signals, [:status])
          create index(:oban_powertools_workflow_signals, [:signal_name, :correlation_key])

          create table(:oban_powertools_workflow_recovery_sessions, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :workflow_id, references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all), null: false
            add :status, :string, null: false, default: "completed"
            add :trigger, :string, null: false, default: "recover_step"
            add :reason, :string
            add :actor_id, :string
            add :requested_at, :utc_datetime_usec, null: false
            add :completed_at, :utc_datetime_usec
            add :metadata, :map, null: false, default: %{}

            timestamps(updated_at: false)
          end

          create index(:oban_powertools_workflow_recovery_sessions, [:workflow_id])
          create index(:oban_powertools_workflow_recovery_sessions, [:status])
          create index(:oban_powertools_workflow_recovery_sessions, [:requested_at])

          create table(:oban_powertools_workflow_recovery_attempts, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :workflow_id, references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all), null: false
            add :step_id, references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :nilify_all)
            add :scope, :string, null: false, default: "step"
            add :action, :string, null: false
            add :status, :string, null: false, default: "requested"
            add :reason, :string
            add :actor_id, :string
            add :requested_at, :utc_datetime_usec, null: false
            add :completed_at, :utc_datetime_usec
            add :before_snapshot, :map, null: false, default: %{}
            add :after_snapshot, :map, null: false, default: %{}
            add :metadata, :map, null: false, default: %{}
            add :recovery_session_id, references(:oban_powertools_workflow_recovery_sessions, type: :uuid, on_delete: :delete_all)

            timestamps(updated_at: false)
          end

          create index(:oban_powertools_workflow_recovery_attempts, [:workflow_id])
          create index(:oban_powertools_workflow_recovery_attempts, [:step_id])
          create index(:oban_powertools_workflow_recovery_attempts, [:status])
          create index(:oban_powertools_workflow_recovery_attempts, [:recovery_session_id])

          create table(:oban_powertools_workflow_callback_outbox, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :workflow_id, references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all), null: false
            add :recovery_attempt_id, references(:oban_powertools_workflow_recovery_attempts, type: :uuid, on_delete: :nilify_all)
            add :event, :string, null: false
            add :dedupe_key, :string, null: false
            add :status, :string, null: false, default: "pending"
            add :payload, :map, null: false, default: %{}
            add :attempts, :integer, null: false, default: 0
            add :available_at, :utc_datetime_usec
            add :claimed_at, :utc_datetime_usec
            add :claimed_by, :string
            add :lease_expires_at, :utc_datetime_usec
            add :delivered_at, :utc_datetime_usec
            add :last_error, :string

            timestamps()
          end

          create unique_index(:oban_powertools_workflow_callback_outbox, [:dedupe_key])
          create index(:oban_powertools_workflow_callback_outbox, [:workflow_id])
          create index(:oban_powertools_workflow_callback_outbox, [:status, :available_at])
          create index(:oban_powertools_workflow_callback_outbox, [:status, :lease_expires_at])
          create index(:oban_powertools_workflow_callback_outbox, [:claimed_by])
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_workflow_command_attempts",
      timestamp: migration_timestamp(25),
      body: """
        def change do
          create table(:oban_powertools_workflow_command_attempts, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :workflow_id, references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all)
            add :step_id, references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :nilify_all)
            add :signal_record_id, references(:oban_powertools_workflow_signals, type: :uuid, on_delete: :nilify_all)
            add :scope, :string, null: false, default: "workflow"
            add :action, :string, null: false
            add :status, :string, null: false, default: "completed"
            add :reason_code, :string
            add :reason_message, :string
            add :actor_id, :string
            add :source, :string, null: false, default: "runtime"
            add :requested_at, :utc_datetime_usec, null: false
            add :completed_at, :utc_datetime_usec
            add :before_snapshot, :map, null: false, default: %{}
            add :after_snapshot, :map, null: false, default: %{}
            add :metadata, :map, null: false, default: %{}

            timestamps(updated_at: false)
          end

          create index(:oban_powertools_workflow_command_attempts, [:workflow_id])
          create index(:oban_powertools_workflow_command_attempts, [:step_id])
          create index(:oban_powertools_workflow_command_attempts, [:signal_record_id])
          create index(:oban_powertools_workflow_command_attempts, [:scope, :action])
          create index(:oban_powertools_workflow_command_attempts, [:status])
          create index(:oban_powertools_workflow_command_attempts, [:reason_code])
          create index(:oban_powertools_workflow_command_attempts, [:requested_at])
        end
      """
    )
  end

  defp setup_batch_migrations(igniter) do
    igniter
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_batches_and_callbacks",
      timestamp: migration_timestamp(26),
      body: """
        @disable_ddl_transaction true
        def change do
          rename table(:oban_powertools_workflow_callback_outbox), to: table(:oban_powertools_callbacks)

          alter table(:oban_powertools_callbacks) do
            add :batch_id, :uuid
            modify :workflow_id, :uuid, null: true
          end

          create index(:oban_powertools_callbacks, [:batch_id], concurrently: true)

          create table(:oban_powertools_batches, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :name, :string
            add :status, :string, null: false, default: "executing"
            add :total_count, :integer, null: false, default: 0
            add :success_count, :integer, null: false, default: 0
            add :discard_count, :integer, null: false, default: 0
            add :cancelled_count, :integer, null: false, default: 0
            add :snooze_count, :integer, null: false, default: 0
            add :inserted_count, :integer, null: false, default: 0
            add :insert_chunk_count, :integer, null: false, default: 0
            add :insert_failed_chunk, :integer
            add :insert_failure, :map, null: false, default: %{}
            add :insert_failed_at, :utc_datetime_usec
            add :completed_at, :utc_datetime_usec

            timestamps()
          end

          create index(:oban_powertools_batches, [:status], concurrently: true)
          create index(:oban_powertools_batches, [:name], concurrently: true)

          create table(:oban_powertools_batch_jobs, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :batch_id, references(:oban_powertools_batches, type: :uuid, on_delete: :delete_all), null: false
            add :job_id, :bigint, null: false
            add :state, :string, null: false, default: "available"

            timestamps()
          end

          create unique_index(:oban_powertools_batch_jobs, [:batch_id, :job_id], concurrently: true)
          create index(:oban_powertools_batch_jobs, [:job_id], concurrently: true)
        end
      """
    )
  end

  defp setup_phase_4_migrations(igniter) do
    igniter
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_heartbeats",
      timestamp: migration_timestamp(30),
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
      repo_module(igniter),
      "oban_powertools_lifeline_incidents",
      timestamp: migration_timestamp(31),
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
      repo_module(igniter),
      "oban_powertools_repair_previews",
      timestamp: migration_timestamp(32),
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
      repo_module(igniter),
      "oban_powertools_archive_runs",
      timestamp: migration_timestamp(33),
      body: """
        @disable_ddl_transaction true
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

          create index(:oban_powertools_archive_runs, [:run_type], concurrently: true)
          create index(:oban_powertools_archive_runs, [:status], concurrently: true)
          create index(:oban_powertools_archive_runs, [:retention_class], concurrently: true)
          create index(:oban_powertools_archive_runs, [:started_at], concurrently: true)
        end
      """
    )
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_repair_archives",
      timestamp: migration_timestamp(34),
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

  defp setup_job_record_migrations(igniter) do
    igniter
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_job_records",
      timestamp: migration_timestamp(40),
      body: """
        @disable_ddl_transaction true
        def change do
          create table(:oban_powertools_job_records, primary_key: false) do
            add :id, :uuid, primary_key: true
            add :oban_job_id, :bigint
            add :worker, :string, null: false
            add :attempt, :integer, null: false, default: 1
            add :status, :string, null: false, default: "ok"
            add :payload, :map, null: false, default: %{}
            add :payload_bytes, :integer, null: false, default: 0
            add :retention, :string, null: false, default: "standard"
            add :redacted, :boolean, null: false, default: false
            add :summary, :string
            add :recorded_at, :utc_datetime_usec, null: false
            add :expires_at, :utc_datetime_usec, null: false

            timestamps(updated_at: false)
          end

          create unique_index(:oban_powertools_job_records, [:oban_job_id, :attempt], concurrently: true)
          create index(:oban_powertools_job_records, [:worker], concurrently: true)
          create index(:oban_powertools_job_records, [:status], concurrently: true)
          create index(:oban_powertools_job_records, [:expires_at], concurrently: true)
        end
      """
    )
  end

  defp repo_module(igniter) do
    Module.concat(Igniter.Project.Module.module_name_prefix(igniter), "Repo")
  end

  defp migration_timestamp(offset_seconds) do
    DateTime.utc_now()
    |> DateTime.add(offset_seconds, :second)
    |> Calendar.strftime("%Y%m%d%H%M%S")
  end
end
