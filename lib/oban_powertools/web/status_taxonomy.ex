defmodule ObanPowertools.Web.StatusTaxonomy do
  @moduledoc """
  Domain-aware presentation mapping for Oban Powertools status values.

  The registry is intentionally pure and string-keyed. External state can be
  supplied as atoms or binaries, but unknown binary states never create atoms.
  """

  @type domain :: atom() | String.t()
  @type state :: atom() | String.t()
  @type spec :: %{label: String.t(), tone: atom(), icon: atom(), sr_prefix: String.t()}

  @domains %{
    "batch" => %{domain: :batch, sr_prefix: "Batch status"},
    "batch_member" => %{domain: :batch_member, sr_prefix: "Batch member state"},
    "callback_outbox" => %{domain: :callback_outbox, sr_prefix: "Callback outbox status"},
    "continuity" => %{domain: :continuity, sr_prefix: "Continuity attempt"},
    "cron" => %{domain: :cron, sr_prefix: "Cron status"},
    "data_availability" => %{domain: :data_availability, sr_prefix: "Data availability"},
    "forensics" => %{domain: :forensics, sr_prefix: "Forensics completeness"},
    "host_follow_up" => %{domain: :host_follow_up, sr_prefix: "Host follow-up status"},
    "job" => %{domain: :job, sr_prefix: "Job state"},
    "limiter" => %{domain: :limiter, sr_prefix: "Limiter status"},
    "lifeline_health" => %{domain: :lifeline_health, sr_prefix: "Lifeline health"},
    "lifeline_incident" => %{domain: :lifeline_incident, sr_prefix: "Lifeline incident status"},
    "lifeline_preview" => %{domain: :lifeline_preview, sr_prefix: "Lifeline preview status"},
    "output" => %{domain: :output, sr_prefix: "Output availability"},
    "workflow" => %{domain: :workflow, sr_prefix: "Workflow state"},
    "workflow_await" => %{domain: :workflow_await, sr_prefix: "Workflow await status"},
    "workflow_result" => %{domain: :workflow_result, sr_prefix: "Workflow result status"},
    "workflow_signal" => %{domain: :workflow_signal, sr_prefix: "Workflow signal status"},
    "workflow_step" => %{domain: :workflow_step, sr_prefix: "Workflow step state"}
  }

  @aliases %{
    {"lifeline_preview", "pending"} => "ready",
    {"lifeline_preview", "executed"} => "consumed"
  }

  @known_states ~w[
    active all ambiguous attempted available awaiting_signal blocked bridge_only callback_failed
    cancel_requested cancelled claimed complete completed consumed delivered deleted discarded
    disconnected drifted error executed executing exhausted expired failed healthy
    history_unavailable host_owned_follow_up_callback_failed
    host_owned_follow_up_callback_invoked host_owned_follow_up_unconfigured incomplete
    insert_failed inserting late lease_expired missed_fire missing needs_review not_attempted ok
    overlap_relevant partial_evidence paused pending permission_denied previewed
    queued_follow_up ready recorded redacted resolved retryable runnable running scheduled skipped
    stale succeeded success unknown unmatched unavailable waiting
  ]a
  @state_atoms Map.new(@known_states, &{Atom.to_string(&1), &1})

  @doc """
  Returns the four-key presentation map for a known domain and status.
  """
  @spec spec(domain(), state()) :: spec()
  def spec(domain, state) do
    domain_key = domain!(domain)
    state_key = state |> normalize_state() |> resolve_alias(domain_key)

    get_in(registry(), [domain_key, state_key]) ||
      unknown_spec(domain_key, state_key)
  end

  @doc """
  Returns deterministic audit records for every explicitly registered state.
  """
  @spec all_specs() :: [%{domain: atom(), state: atom(), spec: spec()}]
  def all_specs do
    registry()
    |> Enum.flat_map(fn {domain_key, states} ->
      domain = @domains |> Map.fetch!(domain_key) |> Map.fetch!(:domain)

      Enum.map(states, fn {state_key, state_spec} ->
        %{domain: domain, state: Map.fetch!(@state_atoms, state_key), spec: state_spec}
      end)
    end)
    |> Enum.sort_by(&{to_string(&1.domain), to_string(&1.state)})
  end

  defp spec(label, tone, icon, sr_prefix),
    do: %{label: label, tone: tone, icon: icon, sr_prefix: sr_prefix}

  defp registry do
    %{
      "batch" => %{
        "all" => spec("All", :neutral, :dot, "Batch status"),
        "callback_failed" => spec("Callback failed", :warning, :alert, "Batch status"),
        "completed" => spec("Completed", :success, :check, "Batch status"),
        "executing" => spec("Executing", :info, :info, "Batch status"),
        "exhausted" => spec("Exhausted", :warning, :alert, "Batch status"),
        "insert_failed" => spec("Insert failed", :warning, :alert, "Batch status"),
        "inserting" => spec("Inserting", :info, :info, "Batch status")
      },
      "batch_member" => job_like_specs("Batch member state"),
      "callback_outbox" => %{
        "claimed" => spec("Claimed", :info, :info, "Callback outbox status"),
        "delivered" => spec("Delivered", :success, :check, "Callback outbox status"),
        "failed" => spec("Failed", :danger, :alert, "Callback outbox status"),
        "lease_expired" => spec("Lease expired", :warning, :alert, "Callback outbox status"),
        "pending" => spec("Pending", :neutral, :dot, "Callback outbox status")
      },
      "continuity" => %{
        "attempted" => spec("Attempted", :info, :info, "Continuity attempt"),
        "consumed" => spec("Consumed", :success, :check, "Continuity attempt"),
        "drifted" => spec("Drifted", :warning, :alert, "Continuity attempt"),
        "expired" => spec("Expired", :danger, :alert, "Continuity attempt"),
        "not_attempted" => spec("Not attempted", :neutral, :dot, "Continuity attempt"),
        "previewed" => spec("Previewed", :info, :info, "Continuity attempt"),
        "succeeded" => spec("Succeeded", :success, :check, "Continuity attempt")
      },
      "cron" => %{
        "cancelled" => spec("Cancelled", :danger, :alert, "Cron status"),
        "claimed" => spec("Claimed", :info, :info, "Cron status"),
        "healthy" => spec("Healthy", :success, :check, "Cron status"),
        "missed_fire" => spec("Missed fire", :warning, :alert, "Cron status"),
        "overlap_relevant" => spec("Overlap relevant", :warning, :alert, "Cron status"),
        "paused" => spec("Paused", :warning, :alert, "Cron status"),
        "queued_follow_up" => spec("Queued follow-up", :warning, :alert, "Cron status"),
        "ready" => spec("Ready", :info, :info, "Cron status"),
        "runnable" => spec("Runnable", :info, :info, "Cron status"),
        "skipped" => spec("Skipped", :warning, :alert, "Cron status"),
        "unknown" => spec("Unknown", :neutral, :dot, "Cron status"),
        "waiting" => spec("Waiting", :warning, :alert, "Cron status")
      },
      "data_availability" => %{
        "disconnected" => spec("Disconnected", :warning, :alert, "Data availability"),
        "permission_denied" => spec("Permission denied", :danger, :alert, "Data availability"),
        "stale" => spec("Stale", :warning, :alert, "Data availability"),
        "unknown" => spec("Unknown", :neutral, :dot, "Data availability"),
        "unavailable" => spec("Unavailable", :warning, :alert, "Data availability")
      },
      "forensics" => %{
        "complete" => spec("Complete", :success, :check, "Forensics completeness"),
        "history_unavailable" =>
          spec("History unavailable", :warning, :alert, "Forensics completeness"),
        "incomplete" => spec("Incomplete", :warning, :alert, "Forensics completeness"),
        "partial_evidence" =>
          spec("Partial evidence", :warning, :alert, "Forensics completeness"),
        "unknown" => spec("Unknown", :neutral, :dot, "Forensics completeness")
      },
      "host_follow_up" => %{
        "host_owned_follow_up_callback_failed" =>
          spec(
            "Host-owned follow-up callback failed",
            :danger,
            :alert,
            "Host follow-up status"
          ),
        "host_owned_follow_up_callback_invoked" =>
          spec(
            "Host-owned follow-up callback invoked",
            :success,
            :check,
            "Host follow-up status"
          ),
        "host_owned_follow_up_unconfigured" =>
          spec("Host-owned follow-up unavailable", :warning, :alert, "Host follow-up status")
      },
      "job" => job_like_specs("Job state"),
      "limiter" => %{
        "blocked" => spec("Blocked", :danger, :alert, "Limiter status"),
        "bridge_only" => spec("Bridge only", :neutral, :dot, "Limiter status"),
        "needs_review" => spec("Needs review", :warning, :alert, "Limiter status"),
        "resolved" => spec("Resolved", :success, :check, "Limiter status"),
        "runnable" => spec("Runnable", :info, :info, "Limiter status"),
        "waiting" => spec("Waiting", :warning, :alert, "Limiter status")
      },
      "lifeline_incident" => %{
        "active" => spec("Active", :warning, :alert, "Lifeline incident status"),
        "blocked" => spec("Blocked", :warning, :alert, "Lifeline incident status"),
        "completed" => spec("Completed", :success, :check, "Lifeline incident status"),
        "failed" => spec("Failed", :danger, :alert, "Lifeline incident status"),
        "pending" => spec("Pending", :neutral, :dot, "Lifeline incident status"),
        "resolved" => spec("Resolved", :success, :check, "Lifeline incident status"),
        "running" => spec("Running", :info, :info, "Lifeline incident status")
      },
      "lifeline_health" => %{
        "healthy" => spec("Healthy", :success, :check, "Lifeline health"),
        "late" => spec("Heartbeat late", :warning, :alert, "Lifeline health"),
        "missing" => spec("Executor missing", :danger, :alert, "Lifeline health")
      },
      "lifeline_preview" => %{
        "consumed" => spec("Consumed", :success, :check, "Lifeline preview status"),
        "drifted" => spec("Drifted", :warning, :alert, "Lifeline preview status"),
        "executed" => spec("Consumed", :success, :check, "Lifeline preview status"),
        "expired" => spec("Expired", :danger, :alert, "Lifeline preview status"),
        "pending" => spec("Ready", :info, :info, "Lifeline preview status"),
        "ready" => spec("Ready", :info, :info, "Lifeline preview status")
      },
      "output" => %{
        "available" => spec("Output available", :success, :check, "Output availability"),
        "expired" => spec("Output expired", :warning, :alert, "Output availability"),
        "unavailable" => spec("Output unavailable", :warning, :alert, "Output availability")
      },
      "workflow" => %{
        "available" => spec("Available", :neutral, :dot, "Workflow state"),
        "cancel_requested" => spec("Cancel requested", :warning, :alert, "Workflow state"),
        "cancelled" => spec("Cancelled", :danger, :alert, "Workflow state"),
        "completed" => spec("Completed", :success, :check, "Workflow state"),
        "expired" => spec("Expired", :danger, :alert, "Workflow state"),
        "failed" => spec("Failed", :danger, :alert, "Workflow state"),
        "pending" => spec("Pending", :neutral, :dot, "Workflow state"),
        "running" => spec("Running", :info, :info, "Workflow state")
      },
      "workflow_await" => %{
        "expired" => spec("Expired", :danger, :alert, "Workflow await status"),
        "resolved" => spec("Resolved", :success, :check, "Workflow await status"),
        "waiting" => spec("Waiting", :warning, :alert, "Workflow await status")
      },
      "workflow_result" => %{
        "completed" => spec("Completed", :success, :check, "Workflow result status"),
        "error" => spec("Error", :danger, :alert, "Workflow result status"),
        "failed" => spec("Failed", :danger, :alert, "Workflow result status"),
        "ok" => spec("Ok", :success, :check, "Workflow result status"),
        "redacted" => spec("Redacted", :warning, :alert, "Workflow result status"),
        "success" => spec("Success", :success, :check, "Workflow result status")
      },
      "workflow_signal" => %{
        "ambiguous" => spec("Ambiguous", :warning, :alert, "Workflow signal status"),
        "consumed" => spec("Consumed", :success, :check, "Workflow signal status"),
        "late" => spec("Late", :warning, :alert, "Workflow signal status"),
        "recorded" => spec("Recorded", :neutral, :dot, "Workflow signal status"),
        "unmatched" => spec("Unmatched", :warning, :alert, "Workflow signal status")
      },
      "workflow_step" => %{
        "available" => spec("Available", :neutral, :dot, "Workflow step state"),
        "awaiting_signal" => spec("Awaiting signal", :warning, :alert, "Workflow step state"),
        "cancelled" => spec("Cancelled", :danger, :alert, "Workflow step state"),
        "completed" => spec("Completed", :success, :check, "Workflow step state"),
        "deleted" => spec("Deleted", :danger, :alert, "Workflow step state"),
        "discarded" => spec("Discarded", :danger, :alert, "Workflow step state"),
        "error" => spec("Error", :danger, :alert, "Workflow step state"),
        "executing" => spec("Executing", :info, :info, "Workflow step state"),
        "expired" => spec("Expired", :danger, :alert, "Workflow step state"),
        "failed" => spec("Failed", :danger, :alert, "Workflow step state"),
        "ok" => spec("Ok", :success, :check, "Workflow step state"),
        "pending" => spec("Pending", :neutral, :dot, "Workflow step state"),
        "retryable" => spec("Retryable", :warning, :alert, "Workflow step state"),
        "running" => spec("Running", :info, :info, "Workflow step state"),
        "success" => spec("Success", :success, :check, "Workflow step state")
      }
    }
  end

  defp job_like_specs(sr_prefix) do
    %{
      "available" => spec("Available", :neutral, :dot, sr_prefix),
      "cancelled" => spec("Cancelled", :danger, :alert, sr_prefix),
      "completed" => spec("Completed", :success, :check, sr_prefix),
      "discarded" => spec("Discarded", :danger, :alert, sr_prefix),
      "executing" => spec("Executing", :info, :info, sr_prefix),
      "failed" => spec("Failed", :danger, :alert, sr_prefix),
      "retryable" => spec("Retryable", :warning, :alert, sr_prefix),
      "scheduled" => spec("Scheduled", :neutral, :dot, sr_prefix)
    }
  end

  defp domain!(domain) when is_atom(domain), do: domain |> Atom.to_string() |> domain!()

  defp domain!(domain) when is_binary(domain) do
    if Map.has_key?(@domains, domain) do
      domain
    else
      accepted = @domains |> Map.keys() |> Enum.sort() |> Enum.join(", ")

      raise ArgumentError,
            "unknown status domain #{inspect(domain)}; accepted domains: #{accepted}"
    end
  end

  defp domain!(domain) do
    accepted = @domains |> Map.keys() |> Enum.sort() |> Enum.join(", ")

    raise ArgumentError,
          "unknown status domain #{inspect(domain)}; accepted domains: #{accepted}"
  end

  defp normalize_state(state) when is_atom(state), do: Atom.to_string(state)
  defp normalize_state(state) when is_binary(state), do: state
  defp normalize_state(state), do: to_string(state)

  defp resolve_alias(state_key, domain_key),
    do: Map.get(@aliases, {domain_key, state_key}, state_key)

  defp unknown_spec(domain_key, state_key) do
    %{sr_prefix: sr_prefix} = Map.fetch!(@domains, domain_key)
    spec(humanize(state_key), :neutral, :dot, sr_prefix)
  end

  defp humanize(value) do
    value
    |> String.replace(["_", "-"], " ")
    |> String.split(" ", trim: true)
    |> Enum.join(" ")
    |> String.trim()
    |> case do
      "" -> "Unknown"
      text -> String.capitalize(text)
    end
  end
end
