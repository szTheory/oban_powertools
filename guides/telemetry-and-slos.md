# Telemetry and SLOs

`ObanPowertools.Telemetry.metrics/0` is opt-in and reporter-agnostic. It returns a list of
`Telemetry.Metrics` definitions covering the five frozen Powertools control-plane event
families. Powertools does not start a Telemetry supervisor or bundle a reporter — the host owns
both. Swap in any reporter your stack already uses.

## Wire it up

Add `:telemetry_metrics` to your host application's deps:

```elixir
# mix.exs
defp deps do
  [
    {:telemetry_metrics, "~> 1.0"},
    # Optional: periodic VM and custom measurements
    {:telemetry_poller, "~> 1.0"}
  ]
end
```

Then mount `ObanPowertools.Telemetry.metrics/0` inside your own `Telemetry` supervisor. Use
`Telemetry.Metrics.ConsoleReporter` for local smoke-testing — it ships with `:telemetry_metrics`
and requires no extra dependency. Replace it with your production reporter (Prometheus, StatsD,
Datadog, etc.) before go-live.

```elixir
defmodule MyApp.Telemetry do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      # Swap ConsoleReporter for your chosen reporter in production
      {Telemetry.Metrics.ConsoleReporter,
       metrics: ObanPowertools.Telemetry.metrics()},
      # Optional: periodic VM measurements
      {:telemetry_poller,
       measurements: periodic_measurements(),
       period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp periodic_measurements do
    [
      {:process_info,
       event: [:my_app, :vm],
       name: self(),
       keys: [:message_queue_len, :memory]}
    ]
  end
end
```

Add `MyApp.Telemetry` to your application's supervision tree:

```elixir
# lib/my_app/application.ex
children = [
  ...,
  MyApp.Telemetry
]
```

`ObanPowertools.Telemetry.metrics/0` raises a clear error if `:telemetry_metrics` is not
loaded — it does not silently return an empty list.

## The four golden signals for Oban-backed work

Latency, throughput, errors, and saturation are the four golden signals for any Oban-backed
system. Three of the four come from **Oban-core events**, not Powertools.

| Signal | Event | Measurement |
|--------|-------|-------------|
| Latency | `[:oban, :job, :stop]` | `:duration` (execution), `:queue_time` (wait) |
| Throughput | `[:oban, :job, :stop]` | `:count` over time |
| Errors | `[:oban, :job, :exception]` | `:count` by worker/queue |
| Saturation | host-sourced queue depth | deferred to v1.9 (QRY-06) |

These events are emitted by **Oban**, not by Powertools. `ObanPowertools.Telemetry.metrics/0`
deliberately does not re-emit them — duplicating Oban-core signals would create drift. Parapet's
Universal Phoenix Metrics and every standard reporter already instrument these events
out-of-the-box.

For saturation (live `available`/`executing` counts), a query-backed measurement over
`oban_jobs` is deferred to v1.9 and will require an optional `oban_met` read source. It is not
part of this phase.

## Powertools control-plane SLIs

`ObanPowertools.Telemetry.metrics/0` contributes the **control-plane SLIs** that Oban-core
cannot see: what your limiters, lifeline repair pipeline, workflows, and cron scheduler are
doing. These are the events Oban itself is unaware of.

All tags are low-cardinality string values (e.g. `scope: "partitioned"`, `outcome: "ok"`). The
frozen contract explicitly excludes `job_id`, `args`, preview tokens, and free-form reasons.

### Limiter saturation

| Metric | Tags | What it tracks |
|--------|------|---------------|
| `oban_powertools.limiter.blocked.count` | `blocker_code`, `resource`, `scope` | Job enqueues blocked by limiter |
| `oban_powertools.limiter.released.count` | `resource`, `scope` | Limiter reservations released |
| `oban_powertools.limiter.cooled_down.count` | `resource`, `scope` | Limiter buckets cooled down |

Use `blocker_code` to distinguish `limit_reached` from `window_exhausted`. Use `resource` and
`scope` to isolate which partitioned or global limiter is firing.

### Lifeline repair and incident outcomes

| Metric | Tags | What it tracks |
|--------|------|---------------|
| `oban_powertools.lifeline.repair_previewed.count` | `action`, `incident_class`, `target_type` | Repair actions previewed |
| `oban_powertools.lifeline.repair_executed.count` | `action`, `incident_class`, `target_type` | Repair actions executed |
| `oban_powertools.lifeline.archive_prune_completed.count` | `outcome` | Archive-prune cycle completions |
| `oban_powertools.lifeline.heartbeat_refresh.count` | _(none)_ | Heartbeat refresh cycles |
| `oban_powertools.lifeline.incident_projection.count` | _(none)_ | Incident projection cycles |

`incident_class` values (e.g. `workflow_stuck`, `orphaned_job`) let you break down repair
activity by the type of issue being resolved. `heartbeat_refresh` and `incident_projection`
counters are useful liveness signals confirming the Lifeline process is cycling.

### Workflow terminal causes

| Metric | Tags | What it tracks |
|--------|------|---------------|
| `oban_powertools.workflow.workflow_terminal.count` | `state`, `outcome`, `terminal_cause`, `semantics_version` | Workflows reaching terminal state |
| `oban_powertools.workflow.step_completed.count` | `outcome`, `terminal_cause`, `semantics_version` | Individual workflow steps completed |
| `oban_powertools.workflow.step_unblocked.count` | `scope`, `state`, `semantics_version` | Workflow steps unblocked by dependency |
| `oban_powertools.workflow.cascade_cancelled.count` | `scope`, `outcome`, `terminal_cause`, `semantics_version` | Cascade cancellations |

`terminal_cause` (e.g. `"completed"`, `"failed_after_retries"`, `"cancelled_by_dependency"`)
gives you visibility into why workflows ended — not just that they did.

### Cron schedule events

| Metric | Tags | What it tracks |
|--------|------|---------------|
| `oban_powertools.cron.slot_claimed.count` | `source`, `overlap_policy`, `catch_up_policy` | Cron slots claimed at schedule time |
| `oban_powertools.cron.paused.count` | `source`, `overlap_policy` | Cron entries paused by operator |
| `oban_powertools.cron.resumed.count` | `source`, `overlap_policy` | Cron entries resumed by operator |
| `oban_powertools.cron.run_now.count` | `source`, `overlap_policy` | Cron entries triggered run-now by operator |

### Operator actions

| Metric | Tags | What it tracks |
|--------|------|---------------|
| `oban_powertools.operator_action.complete.count` | `action`, `source` | Operator actions completed (pause, resume, run-now) |
| `oban_powertools.operator_action.previewed.count` | `action`, `source` | Operator actions previewed |

## Feeding Parapet SLOs

Powertools telemetry drops cleanly into Parapet SLO alerting because the frozen contract
already satisfies Parapet's core tenets:

- **Telemetry as a Strict Public API** — the `@contract` is versioned, documented, and
  SemVer-governed. Event names and tag sets do not change without a major version.
- **Cardinality Safety** — the contract explicitly excludes `job_id`, `args`, preview tokens,
  and free-form reasons. Every tag is a low-cardinality string enum.

**No `oban_met` dependency is required, referenced, or needed.** The metrics surface described
here uses only `:telemetry`, `:telemetry_metrics`, and the Powertools event families. `oban_met`
is an optional live queue-depth read source for a future release (v1.9, QRY-06) and has no
connection to these control-plane SLIs.

### Example: repair success rate SLO

Track the ratio of successful to total repair executions — a burn-rate SLO on your Lifeline
pipeline:

```elixir
# Prometheus/Grafana example (no Parapet required — any reporter works)
#
# SLO: 99% of repair_executed events should have outcome = "ok"
# Alert if error budget burns faster than your chosen rate
#
# Numerator:   oban_powertools_lifeline_repair_executed_count{action="retry", incident_class="orphaned_job", target_type="job"}
# Denominator: oban_powertools_lifeline_repair_executed_count (all outcomes)
#
# In Parapet (one consumer — works identically with Prometheus + Grafana without Parapet):
#
# Parapet.SLO.define(:lifeline_repair_success,
#   target: 0.99,
#   window: :rolling_28d,
#   good_events: [
#     metric: "oban_powertools.lifeline.repair_executed.count",
#     tag_filters: [outcome: "ok"]
#   ],
#   total_events: [
#     metric: "oban_powertools.lifeline.repair_executed.count"
#   ]
# )
```

Because the event names are stable, documented public API and the tag sets are low-cardinality,
any alerting system (Parapet, Prometheus alerting rules, Datadog monitors) can consume them with
confidence that the signal will not change without a SemVer-major announcement.

Parapet is **one consumer**, not a coupling. The same metrics work equally well with Prometheus
+ Grafana, Datadog, or any reporter that understands `Telemetry.Metrics` definitions.

## What this is not

- `metrics/0` returns **metric definitions**, not a reporter or a running process.
- Powertools does not start a Telemetry supervisor. The host owns the supervision tree.
- Reporter choice is the host's. The library never bundles `telemetry_metrics_prometheus`,
  StatsD exporters, or any other reporter.
- Tag values are strings (e.g. `scope: "partitioned"`, `outcome: "ok"`), not atoms.
- Powertools does not re-emit Oban-core `[:oban, :job, :stop|:exception]` events. Golden-signal
  latency, throughput, and error-rate come from Oban itself.
- `oban_met` is not required and is not referenced by this feature.
