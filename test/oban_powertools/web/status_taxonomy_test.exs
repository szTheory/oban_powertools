defmodule ObanPowertools.Web.StatusTaxonomyTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Web.StatusTaxonomy

  @source_path "lib/oban_powertools/web/status_taxonomy.ex"

  @known_specs [
    {:job, :available, %{label: "Available", tone: :neutral, icon: :dot, sr_prefix: "Job state"}},
    {:job, :scheduled, %{label: "Scheduled", tone: :neutral, icon: :dot, sr_prefix: "Job state"}},
    {:job, :executing, %{label: "Executing", tone: :info, icon: :info, sr_prefix: "Job state"}},
    {:job, :retryable,
     %{label: "Retryable", tone: :warning, icon: :alert, sr_prefix: "Job state"}},
    {:job, :cancelled,
     %{label: "Cancelled", tone: :danger, icon: :alert, sr_prefix: "Job state"}},
    {:job, :discarded,
     %{label: "Discarded", tone: :danger, icon: :alert, sr_prefix: "Job state"}},
    {:job, :completed,
     %{label: "Completed", tone: :success, icon: :check, sr_prefix: "Job state"}},
    {:batch, :inserting,
     %{label: "Inserting", tone: :info, icon: :info, sr_prefix: "Batch status"}},
    {:batch, :exhausted,
     %{label: "Exhausted", tone: :warning, icon: :alert, sr_prefix: "Batch status"}},
    {:batch, :callback_failed,
     %{label: "Callback failed", tone: :warning, icon: :alert, sr_prefix: "Batch status"}},
    {:workflow, :running,
     %{label: "Running", tone: :info, icon: :info, sr_prefix: "Workflow state"}},
    {:workflow, :cancel_requested,
     %{label: "Cancel requested", tone: :warning, icon: :alert, sr_prefix: "Workflow state"}},
    {:workflow_step, :awaiting_signal,
     %{label: "Awaiting signal", tone: :warning, icon: :alert, sr_prefix: "Workflow step state"}},
    {:workflow_signal, :ambiguous,
     %{label: "Ambiguous", tone: :warning, icon: :alert, sr_prefix: "Workflow signal status"}},
    {:lifeline_preview, :ready,
     %{label: "Ready", tone: :info, icon: :info, sr_prefix: "Lifeline preview status"}},
    {:lifeline_preview, :drifted,
     %{label: "Drifted", tone: :warning, icon: :alert, sr_prefix: "Lifeline preview status"}},
    {:lifeline_preview, :consumed,
     %{label: "Consumed", tone: :success, icon: :check, sr_prefix: "Lifeline preview status"}},
    {:cron, :queued_follow_up,
     %{label: "Queued follow-up", tone: :warning, icon: :alert, sr_prefix: "Cron status"}},
    {:cron, :healthy,
     %{label: "Healthy", tone: :success, icon: :check, sr_prefix: "Cron status"}},
    {:limiter, :bridge_only,
     %{label: "Bridge only", tone: :neutral, icon: :dot, sr_prefix: "Limiter status"}},
    {:data_availability, :permission_denied,
     %{label: "Permission denied", tone: :danger, icon: :alert, sr_prefix: "Data availability"}},
    {:data_availability, :unavailable,
     %{label: "Unavailable", tone: :warning, icon: :alert, sr_prefix: "Data availability"}},
    {:forensics, :incomplete,
     %{label: "Incomplete", tone: :warning, icon: :alert, sr_prefix: "Forensics completeness"}},
    {:continuity, :attempted,
     %{label: "Attempted", tone: :info, icon: :info, sr_prefix: "Continuity attempt"}},
    {:output, :unavailable,
     %{
       label: "Output unavailable",
       tone: :warning,
       icon: :alert,
       sr_prefix: "Output availability"
     }},
    {:operator_result, :success,
     %{label: "Success", tone: :success, icon: :check, sr_prefix: "Operator result"}},
    {:operator_result, :failed,
     %{label: "Failed", tone: :danger, icon: :alert, sr_prefix: "Operator result"}},
    {:operator_result, :skipped,
     %{label: "Skipped", tone: :warning, icon: :alert, sr_prefix: "Operator result"}}
  ]

  @source_audited_specs [
    {:callback_outbox, :pending,
     %{label: "Pending", tone: :neutral, icon: :dot, sr_prefix: "Callback outbox status"}},
    {:callback_outbox, :claimed,
     %{label: "Claimed", tone: :info, icon: :info, sr_prefix: "Callback outbox status"}},
    {:callback_outbox, :failed,
     %{label: "Failed", tone: :danger, icon: :alert, sr_prefix: "Callback outbox status"}},
    {:callback_outbox, :delivered,
     %{label: "Delivered", tone: :success, icon: :check, sr_prefix: "Callback outbox status"}},
    {:lifeline_health, :healthy,
     %{label: "Healthy", tone: :success, icon: :check, sr_prefix: "Lifeline health"}},
    {:lifeline_health, :late,
     %{label: "Heartbeat late", tone: :warning, icon: :alert, sr_prefix: "Lifeline health"}},
    {:lifeline_health, :missing,
     %{label: "Executor missing", tone: :danger, icon: :alert, sr_prefix: "Lifeline health"}},
    {:cron, :claimed, %{label: "Claimed", tone: :info, icon: :info, sr_prefix: "Cron status"}},
    {:cron, :cancelled,
     %{label: "Cancelled", tone: :danger, icon: :alert, sr_prefix: "Cron status"}},
    {:cron, :missed_fire,
     %{label: "Missed fire", tone: :warning, icon: :alert, sr_prefix: "Cron status"}},
    {:cron, :overlap_relevant,
     %{label: "Overlap relevant", tone: :warning, icon: :alert, sr_prefix: "Cron status"}},
    {:cron, :unknown, %{label: "Unknown", tone: :neutral, icon: :dot, sr_prefix: "Cron status"}},
    {:forensics, :partial_evidence,
     %{
       label: "Partial evidence",
       tone: :warning,
       icon: :alert,
       sr_prefix: "Forensics completeness"
     }},
    {:forensics, :history_unavailable,
     %{
       label: "History unavailable",
       tone: :warning,
       icon: :alert,
       sr_prefix: "Forensics completeness"
     }},
    {:forensics, :unknown,
     %{label: "Unknown", tone: :neutral, icon: :dot, sr_prefix: "Forensics completeness"}},
    {:continuity, :previewed,
     %{label: "Previewed", tone: :info, icon: :info, sr_prefix: "Continuity attempt"}},
    {:continuity, :succeeded,
     %{label: "Succeeded", tone: :success, icon: :check, sr_prefix: "Continuity attempt"}},
    {:continuity, :drifted,
     %{label: "Drifted", tone: :warning, icon: :alert, sr_prefix: "Continuity attempt"}},
    {:continuity, :expired,
     %{label: "Expired", tone: :danger, icon: :alert, sr_prefix: "Continuity attempt"}},
    {:continuity, :consumed,
     %{label: "Consumed", tone: :success, icon: :check, sr_prefix: "Continuity attempt"}},
    {:host_follow_up, :host_owned_follow_up_unconfigured,
     %{
       label: "Host-owned follow-up unavailable",
       tone: :warning,
       icon: :alert,
       sr_prefix: "Host follow-up status"
     }},
    {:host_follow_up, :host_owned_follow_up_callback_invoked,
     %{
       label: "Host-owned follow-up callback invoked",
       tone: :success,
       icon: :check,
       sr_prefix: "Host follow-up status"
     }},
    {:host_follow_up, :host_owned_follow_up_callback_failed,
     %{
       label: "Host-owned follow-up callback failed",
       tone: :danger,
       icon: :alert,
       sr_prefix: "Host follow-up status"
     }}
  ]

  @all_expected_specs @known_specs ++ @source_audited_specs

  test "exports exact presentation specs for every locked domain/state" do
    assert Code.ensure_loaded?(StatusTaxonomy), "Phase 77 requires #{inspect(StatusTaxonomy)}"

    for {domain, state, expected} <- @all_expected_specs do
      assert StatusTaxonomy.spec(domain, state) == expected
      assert StatusTaxonomy.spec(to_string(domain), to_string(state)) == expected
    end
  end

  test "resolves approved preview aliases without dynamic atoms" do
    assert StatusTaxonomy.spec(:lifeline_preview, :pending) ==
             StatusTaxonomy.spec(:lifeline_preview, :ready)

    assert StatusTaxonomy.spec(:lifeline_preview, :executed) ==
             StatusTaxonomy.spec(:lifeline_preview, :consumed)

    assert StatusTaxonomy.spec(:callback_outbox, :lease_expired) == %{
             label: "Lease expired",
             tone: :warning,
             icon: :alert,
             sr_prefix: "Callback outbox status"
           }
  end

  test "humanizes unknown known-domain states and rejects unknown domains" do
    assert StatusTaxonomy.spec(:job, "worker_snoozed") == %{
             label: "Worker snoozed",
             tone: :neutral,
             icon: :dot,
             sr_prefix: "Job state"
           }

    assert_raise ArgumentError, ~r/unknown status domain/i, fn ->
      StatusTaxonomy.spec(:invented_domain, :available)
    end

    assert_raise ArgumentError, ~r/accepted domains:.*job.*workflow/s, fn ->
      StatusTaxonomy.spec(:invented_domain, :available)
    end

    huge_state = String.duplicate("worker_snoozed-", 1_000)
    assert StatusTaxonomy.spec(:job, huge_state) == StatusTaxonomy.spec(:job, huge_state)
  end

  test "all_specs is deterministic, unique, ordered, and includes known mappings" do
    specs = StatusTaxonomy.all_specs()

    assert specs == StatusTaxonomy.all_specs()
    assert specs == Enum.sort_by(specs, &{to_string(&1.domain), to_string(&1.state)})
    assert Enum.uniq_by(specs, &{&1.domain, &1.state}) == specs

    for {domain, state, expected} <- @all_expected_specs do
      assert %{domain: ^domain, state: ^state, spec: ^expected} =
               Enum.find(specs, &(&1.domain == domain and &1.state == state))
    end

    for %{domain: domain, state: state, spec: expected} <- specs do
      assert StatusTaxonomy.spec(domain, state) == expected
      assert StatusTaxonomy.spec(to_string(domain), to_string(state)) == expected
    end
  end

  test "taxonomy source forbids dynamic atom creation" do
    assert File.exists?(@source_path), "Phase 77 requires #{@source_path}"
    source = File.read!(@source_path)

    refute source =~ "String.to_atom"
    refute source =~ "String.to_existing_atom"
    refute source =~ "List.to_atom"
    refute source =~ "binary_to_atom"
    refute source =~ "list_to_atom"
  end
end
