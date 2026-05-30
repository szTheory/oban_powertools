defmodule ObanPowertools.Telemetry do
  @moduledoc """
  Public telemetry contract for Oban Powertools.

  Phase 8 freezes five event families under the `[:oban_powertools, family, event_suffix]`
  prefix:

  - `:operator_action`
  - `:limiter`
  - `:cron`
  - `:workflow`
  - `:lifeline`

  The public measurement key is `:count`.

  Allowed low-cardinality metadata keys per family:

  - `:operator_action` -> `[:action, :source]`
  - `:limiter` -> `[:action, :blocker_code, :resource, :scope]`
  - `:cron` -> `[:action, :source, :overlap_policy, :catch_up_policy]`
  - `:workflow` ->
    - `:step_completed` -> `[:outcome, :terminal_cause, :semantics_version]`
    - `:step_unblocked` -> `[:scope, :state, :semantics_version]`
    - `:cascade_cancelled` -> `[:scope, :outcome, :terminal_cause, :semantics_version]`
    - `:workflow_terminal` -> `[:state, :outcome, :terminal_cause, :semantics_version]`
  - `:lifeline` -> `[:action, :incident_class, :target_type, :outcome, :archived_count, :pruned_count]`

  IDs, job args, preview tokens, and free-form reasons are intentionally excluded from this
  public API.
  """

  @contract %{
    measurement_keys: [:count],
    families: %{
      operator_action: [:action, :source],
      limiter: [:action, :blocker_code, :resource, :scope],
      cron: [:action, :source, :overlap_policy, :catch_up_policy],
      workflow: %{
        step_completed: [:outcome, :terminal_cause, :semantics_version],
        step_unblocked: [:scope, :state, :semantics_version],
        cascade_cancelled: [:scope, :outcome, :terminal_cause, :semantics_version],
        workflow_terminal: [:state, :outcome, :terminal_cause, :semantics_version]
      },
      lifeline: [:action, :incident_class, :target_type, :outcome, :archived_count, :pruned_count]
    }
  }

  @doc """
  Returns the public telemetry contract for event families, measurements, and metadata keys.
  """
  def contract, do: @contract

  @doc """
  Returns a list of `Telemetry.Metrics` counter definitions for the 5 frozen Oban Powertools
  event families: `:operator_action`, `:limiter`, `:cron`, `:workflow`, and `:lifeline`.

  Each metric's `:tags` is a strict subset of the frozen `@contract` for that family and suffix,
  ensuring low-cardinality safety (SC-4). No Oban-core `[:oban, :job, *]` metrics are emitted —
  these are Powertools control-plane metrics only.

  This function is opt-in. It requires the `:telemetry_metrics` dependency to be present
  in the host application. If called without `:telemetry_metrics` loaded, it raises a
  `RuntimeError` with instructions to add the dependency — it does NOT return an empty list.

  ## Usage

      # In your application's Telemetry supervisor:
      {Telemetry.Metrics.ConsoleReporter,
       metrics: ObanPowertools.Telemetry.metrics()}

  Add `:telemetry_metrics` to your `mix.exs` deps:

      {:telemetry_metrics, "~> 1.0"}

  """
  def metrics do
    unless Code.ensure_loaded?(Telemetry.Metrics) do
      raise """
      ObanPowertools.Telemetry.metrics/0 requires the :telemetry_metrics dependency.
      Add it to your mix.exs:

          {:telemetry_metrics, "~> 1.0"}

      then run `mix deps.get` and restart your application.
      """
    end

    # Use apply/3 to avoid compile-time resolution of Telemetry.Metrics.counter/2.
    # import/1 is a compile-time directive and would fail in a prod build where
    # telemetry_metrics is absent (only: [:test, :dev]). apply/3 defers the call
    # to runtime after the Code.ensure_loaded? guard above confirms the dep is present.
    counter = fn name, opts -> apply(Telemetry.Metrics, :counter, [name, opts]) end

    [
      # operator_action — :action varies across events so it is useful as a tag
      counter.("oban_powertools.operator_action.previewed.count",
        tags: [:action, :source],
        description: "Operator previewed a cron action"
      ),
      counter.("oban_powertools.operator_action.complete.count",
        tags: [:action, :source],
        description:
          "Operator action completed (pause_cron_entry, resume_cron_entry, run_cron_entry)"
      ),

      # limiter — :action omitted where it mirrors the event-name suffix (D-02 / Pitfall 4)
      counter.("oban_powertools.limiter.blocked.count",
        tags: [:blocker_code, :resource, :scope],
        description: "Job enqueue blocked by limiter"
      ),
      counter.("oban_powertools.limiter.released.count",
        tags: [:resource, :scope],
        description: "Limiter reservation released"
      ),
      counter.("oban_powertools.limiter.cooled_down.count",
        tags: [:resource, :scope],
        description: "Limiter bucket cooled down"
      ),

      # cron — :catch_up_policy only emitted by :slot_claimed; omit from others
      counter.("oban_powertools.cron.paused.count",
        tags: [:source, :overlap_policy],
        description: "Cron entry paused by operator"
      ),
      counter.("oban_powertools.cron.resumed.count",
        tags: [:source, :overlap_policy],
        description: "Cron entry resumed by operator"
      ),
      counter.("oban_powertools.cron.run_now.count",
        tags: [:source, :overlap_policy],
        description: "Cron entry triggered run-now by operator"
      ),
      counter.("oban_powertools.cron.slot_claimed.count",
        tags: [:source, :overlap_policy, :catch_up_policy],
        description: "Cron slot claimed"
      ),

      # workflow — per-suffix tags drawn from nested @contract entries
      counter.("oban_powertools.workflow.step_completed.count",
        tags: [:outcome, :terminal_cause, :semantics_version],
        description: "Workflow step completed"
      ),
      counter.("oban_powertools.workflow.step_unblocked.count",
        tags: [:scope, :state, :semantics_version],
        description: "Workflow step unblocked by dependency"
      ),
      counter.("oban_powertools.workflow.cascade_cancelled.count",
        tags: [:scope, :outcome, :terminal_cause, :semantics_version],
        description: "Workflow cascade cancelled"
      ),
      counter.("oban_powertools.workflow.workflow_terminal.count",
        tags: [:state, :outcome, :terminal_cause, :semantics_version],
        description: "Workflow reached terminal state"
      ),

      # lifeline — heartbeat/incident_projection have no useful cardinality-safe tags
      # :archived_count/:pruned_count are variable integer counts in metadata — excluded (SC-4)
      counter.("oban_powertools.lifeline.heartbeat_refresh.count",
        tags: [],
        description: "Lifeline heartbeat refresh cycle completed"
      ),
      counter.("oban_powertools.lifeline.incident_projection.count",
        tags: [],
        description: "Lifeline incident projection cycle completed"
      ),
      counter.("oban_powertools.lifeline.repair_previewed.count",
        tags: [:action, :incident_class, :target_type],
        description: "Lifeline repair previewed"
      ),
      counter.("oban_powertools.lifeline.repair_executed.count",
        tags: [:action, :incident_class, :target_type],
        description: "Lifeline repair executed"
      ),
      counter.("oban_powertools.lifeline.archive_prune_completed.count",
        tags: [:outcome],
        description: "Lifeline archive prune cycle completed"
      )
    ]
  end

  @doc """
  Executes a telemetry event for an operator action.
  """
  def execute_operator_action(event_suffix, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(
      [:oban_powertools, :operator_action, event_suffix],
      measurements,
      metadata
    )
  end

  def execute_limiter_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(
      [:oban_powertools, :limiter, event_suffix],
      measurements,
      metadata
    )
  end

  def execute_cron_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(
      [:oban_powertools, :cron, event_suffix],
      measurements,
      metadata
    )
  end

  def execute_workflow_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(
      [:oban_powertools, :workflow, event_suffix],
      measurements,
      metadata
    )
  end

  def execute_lifeline_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(
      [:oban_powertools, :lifeline, event_suffix],
      measurements,
      metadata
    )
  end
end
