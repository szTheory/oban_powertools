alias ObanPowertools.Cron.Entry
alias PhoenixHost.Repo

ops_actor = PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()

nightly_sync_attrs = %{
  name: "nightly_sync",
  source: "fixture",
  worker: "PhoenixHost.Workers.NightlySyncWorker",
  queue: "default",
  expression: "0 2 * * *",
  timezone: "Etc/UTC",
  args: %{"scope" => "ops-demo"},
  opts: %{},
  overlap_policy: "queue_one",
  catch_up_policy: "latest",
  max_catch_up: 1,
  metadata: %{
    "seeded_for" => "first-session-proof",
    "actor_id" => ops_actor.id
  }
}

%Entry{}
|> Entry.changeset(nightly_sync_attrs)
|> Repo.insert!(
  on_conflict: [
    set: [
      source: nightly_sync_attrs.source,
      worker: nightly_sync_attrs.worker,
      queue: nightly_sync_attrs.queue,
      expression: nightly_sync_attrs.expression,
      timezone: nightly_sync_attrs.timezone,
      args: nightly_sync_attrs.args,
      opts: nightly_sync_attrs.opts,
      overlap_policy: nightly_sync_attrs.overlap_policy,
      catch_up_policy: nightly_sync_attrs.catch_up_policy,
      max_catch_up: nightly_sync_attrs.max_catch_up,
      metadata: nightly_sync_attrs.metadata,
      updated_at: DateTime.utc_now()
    ]
  ],
  conflict_target: [:name]
)

IO.puts("""
Seeded PhoenixHost first-session fixture:

- ops actor: #{ops_actor.id}
- label: #{ops_actor.label}
- role: #{ops_actor.role}
- canonical cron entry: nightly_sync
- /ops/jobs is the native operator shell
- /ops/jobs/oban is the read-only bridge when oban_web is available
""")
