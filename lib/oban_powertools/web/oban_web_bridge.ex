if Code.ensure_loaded?(Oban.Web.Resolver) do
  defmodule ObanPowertools.Web.ObanWebBridge do
    @moduledoc """
    Thin adapter from Powertools auth and display seams to documented
    `Oban.Web.Resolver` callbacks for the optional `/ops/jobs/oban` mount.
    """

    @behaviour Oban.Web.Resolver

    alias ObanPowertools.{Auth, RuntimeConfig}

    @dashboard_redirect "/ops/jobs"
    @view_action :view_oban_web
    @view_resource %{type: :page, id: "oban_web"}

    @impl true
    def resolve_user(conn), do: Auth.current_actor(conn)

    @impl true
    def resolve_access(actor) do
      case Auth.authorization_outcome(actor, @view_action, @view_resource) do
        :ok -> :read_only
        {:error, _reason} -> {:forbidden, @dashboard_redirect}
      end
    end

    @impl true
    def format_job_args(job) do
      render_text(:job_args, job.args, %{surface: :oban_web, field: :args, job: job}, fn ->
        Oban.Web.Resolver.format_job_args(job)
      end)
    end

    @impl true
    def format_job_meta(job) do
      render_text(:job_meta, job.meta, %{surface: :oban_web, field: :meta, job: job}, fn ->
        Oban.Web.Resolver.format_job_meta(job)
      end)
    end

    @impl true
    def format_recorded(recorded, job) do
      render_text(
        :job_recorded,
        decode_recorded(recorded),
        %{surface: :oban_web, field: :recorded, job: job},
        fn -> Oban.Web.Resolver.format_recorded(recorded, job) end
      )
    end

    defp render_text(kind, value, context, fallback) do
      case RuntimeConfig.display_policy() do
        nil ->
          fallback.()

        module ->
          Code.ensure_loaded(module)

          if function_exported?(module, :display, 3) do
            try do
              case module.display(kind, value, context) do
                nil -> fallback.()
                rendered when is_binary(rendered) or is_list(rendered) -> rendered
                other -> raise ArgumentError, invalid_display_message(kind, other)
              end
            rescue
              FunctionClauseError -> fallback.()
            end
          else
            raise ArgumentError,
                  "Oban Powertools display_policy #{inspect(module)} must implement display/3."
          end
      end
    end

    defp decode_recorded(recorded) do
      Oban.Web.Resolver.decode_recorded(recorded)
    rescue
      _ -> recorded
    end

    defp invalid_display_message(kind, other) do
      "Oban Powertools display_policy returned an invalid #{kind} display: #{inspect(other)}"
    end
  end
end
