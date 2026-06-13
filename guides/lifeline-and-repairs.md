# Lifeline And Repairs

`ObanPowertools.Lifeline` is the operator-facing runtime for executor health, projected
incidents, preview-backed repairs, and retention reporting.
It is a `Powertools-native` venue: diagnosis first, then `Audited action`, with the bridge kept separate as `Inspection only`.

Use it when you need a durable answer to “what looks broken right now?” and “what exact repair
will we execute if an operator confirms it?”

## Refresh executor heartbeats

Your host or runtime can upsert one durable heartbeat per executor identity:

```elixir
ObanPowertools.Lifeline.refresh_heartbeats(MyApp.Repo, [
  %{
    executor_id: "app:oban:default:node-a:producer-1",
    node: "node-a",
    producer_scope: "producer-1"
  }
])
```

## Project incidents from durable evidence

```elixir
health_rows = ObanPowertools.Lifeline.list_executor_health(MyApp.Repo)
incidents = ObanPowertools.Lifeline.project_incidents(MyApp.Repo)
```

Current incident projection covers:

- late and missing executors
- dead-executor incidents backed by affected executing jobs
- workflow-stuck incidents backed by persisted step blocker state

## Preview a repair before any mutation

Preview is the important contract. Operators do not jump straight to mutation:

```elixir
actor = %{id: "ops-1", permissions: [:preview_repair, :execute_repair]}

{:ok, preview} =
  ObanPowertools.Lifeline.preview_repair(MyApp.Repo, actor, %{
    incident_fingerprint: incident.incident_fingerprint,
    action: "job_rescue",
    target_type: "job",
    target_id: job.id
  })
```

Preview behavior today:

- authorization is host-owned through `authorize/3`
- the preview is idempotent for the same ready plan
- unsupported targets are rejected early
- repair drift is detected before execution

## Execute the repair with a reason

```elixir
ObanPowertools.Lifeline.execute_repair(
  MyApp.Repo,
  actor,
  preview.preview_token,
  "Rescuing the orphaned job after node loss"
)
```

Execution behavior today:

- reason text is enforced when required
- the preview token is single-use
- immutable audit evidence is written
- the related incident is resolved only when the repair succeeds

## Retention and pruning

The module also reports and prunes retention-managed records:

```elixir
ObanPowertools.Lifeline.retention_status(MyApp.Repo)
ObanPowertools.Lifeline.run_archive_prune(MyApp.Repo, actor, reason: "scheduled retention")
```

`run_archive_prune/3` uses one bounded transaction for the current retention sweep:

- old manual repair audit events are archived before deletion
- consumed repair previews are pruned after their preview retention window
- stale heartbeat samples are pruned after their heartbeat retention window
- expired `ObanPowertools.JobRecord` rows are pruned when `expires_at <= now`

JobRecords are operational context for recent output inspection. They are not archived before
deletion, not immutable audit evidence, and not a substitute for durable domain data. Hosts
that need long-lived reports, files, exports, or business facts should store those artifacts in
host-owned tables or object storage and record only a small JSON reference in the job output.

Deleted JobRecords are counted in the archive run's `pruned_count` and in the
`:archive_prune_completed` telemetry metadata. They are not counted as `archived_count`, and
their pruning does not join `oban_jobs` or wait for Oban's own job pruning.

## Good fit

Use Lifeline when the app needs an operator-visible incident and repair model. If you only need
background telemetry and alerts, this is more operator substrate than simple monitoring.
