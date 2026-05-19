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
    |> setup_router_scope()
    |> setup_migration()
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
      [
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
      ]
    )
    |> Igniter.Libs.Ecto.gen_migration(
      nil,
      "oban_powertools_idempotency_receipts",
      [
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
      ]
    )
  end
end