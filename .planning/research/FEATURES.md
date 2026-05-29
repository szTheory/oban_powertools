# Feature Research

**Domain:** Release & Operability tooling for a mature, unpublished Elixir/Phoenix Hex library (Oban Powertools v1.6)
**Researched:** 2026-05-28
**Confidence:** HIGH

---

## Context: What Already Exists and What v1.6 Is

All five prior milestones delivered: typed workers, idempotency, limiters (Limits + Explain APIs), cron, durable workflow DAGs, native `/ops/jobs` shell, Lifeline repair, and the full Operator Elixir API — all inside a frozen low-cardinality telemetry contract. The library is `0.1.0` and unpublished after all of this.

**v1.6 is not a feature milestone.** It is the release milestone that makes every prior feature real for adopters. Four deliverables:

1. First public hex release at `0.5.0`
2. `mix oban_powertools.doctor` — read-only DB/config health checks
3. `mix oban_powertools.limiter.explain` / `.simulate` — CLI over existing `Explain` + `Limits`
4. Opt-in `ObanPowertools.Telemetry.metrics/0` + Parapet/SLO guide — no `oban_met` dep

Each deliverable is scoped below with table-stakes / differentiators / anti-features, complexity, and dependency on existing modules.

---

## Deliverable 1: First Public Hex Release at `0.5.0`

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Module Dependencies |
|---------|--------------|------------|---------------------|
| Package available on hex.pm at a named version | Without this, adopters cannot `mix deps.get` the library. The entire prior build is invisible. | LOW | `mix.exs` `:package` metadata, `mix hex.publish` |
| README with installation and getting-started verified from the published package | Hex.pm shows the README on the package page. Adopters first encounter the library there, not in the repo. Getting-started must work by following the published docs, not the dev tree. | LOW-MEDIUM | `README.md`, `guides/getting_started.md`, Igniter installer smoke-test |
| HexDocs published at hexdocs.pm/oban_powertools | `mix hex.publish` automatically pushes to hexdocs. An empty or broken hexdocs page signals an immature library. | LOW | `mix.exs` `:docs` key, `ex_doc` already in deps |
| CHANGELOG.md at the root | Adopters and tooling (Dependabot, release-please) expect a CHANGELOG.md adjacent to the package. First entry: `0.5.0 — Initial public release`. | LOW | New file |
| Correct `mix.exs` package metadata: `:licenses`, `:description`, `:links`, `:source_url` | Hex.pm shows these on the package page sidebar. Missing `:licenses` is a publish error. Missing links means no GitHub link from hexdocs. | LOW | `mix.exs` |
| `0.x` versioning contract documented | Per Elixir library guidelines: pre-1.0 libraries provide no stability guarantees; dependents should pin to `"~> 0.5.0"` not `"~> 0.5"`. Document this explicitly so adopters choose the right constraint. | LOW | `README.md`, `CHANGELOG.md` |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Module Dependencies |
|---------|-------------------|------------|---------------------|
| Deliberate `0.5.0` signal with a documented `1.0` graduation path | Shipping `0.1.0` → hex is odd signaling when 40+ test files and 5 milestones exist. `0.5.0` signals "substantial but still gathering adopter feedback before freezing the API." The README explicitly states: "Minor bumps may include breaking API changes until 1.0. After real adoption, we'll freeze and release 1.0." This is honest and manages adopter expectations. | LOW | `README.md`, `CHANGELOG.md` |
| Getting-started smoke-tested from the published package, not dev tree | Generate a test Phoenix app, add `oban_powertools` from hex (not path dep), run Igniter installer, run migrations, boot — and verify it works. This prevents "published but broken install" on day 1. | MEDIUM | Igniter installer (`mix oban_powertools.install`), published hex package, CI step |
| Upgrade guide seam in CHANGELOG | Even 0.x releases benefit from explicit upgrade notes. Establishes the CHANGELOG discipline before 1.0 when it matters. | LOW | `CHANGELOG.md` |

### Anti-Features

| Anti-Feature | Why Requested | Why Problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| Publish at `0.1.0` | Matches the `mix.exs` version already in the tree | Signals "experimental proof-of-concept" when the library is actually a mature 5-milestone op stack. Adopters see `0.1.0` and assume nothing works yet. | Bump to `0.5.0` — the increment honestly reflects the build-up without claiming stability prematurely. |
| Publish at `1.0.0` immediately | "We built 5 milestones, it's stable" | Commits to a stability guarantee before any adopter has battle-tested the install path, config seams, or telemetry contract in their app. Any breaking change then requires `2.0.0`. | Stay `0.x` until at least one external adopter runs it in production. |
| Generate a full changelog from git history | Tools like `git-cliff` can mine commits | Prior commits are dev-internal and messy; a synthetic changelog reads as noise. | Write the first entry manually: "0.5.0 — Initial public release, full feature set from 5 internal milestones." |

---

## Deliverable 2: `mix oban_powertools.doctor`

### What Prior Art Shows

The `mix doctor` tool for documentation health (github.com/akoutmos/doctor), `mix ecto.migrations`, `mix sobelow`, and `mix credo` all follow the same pattern: read-only analysis → structured output → non-zero exit code on failure. Operators and CI pipelines depend on exit codes, not just human-readable text. `ecto_psql_extras` shows the canonical Elixir approach to pg_catalog queries (invalid indexes, bloat, vacuum stats, sequential scan counts) and is itself an optional dep for Phoenix.LiveDashboard.

The context doc explicitly calls out two footguns requiring doctor coverage: index health (especially the uniqueness-timeout case with ~2M jobs) and migration drift.

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Module Dependencies |
|---------|--------------|------------|---------------------|
| Invalid index detection (`pg_index.indisvalid = false`) | `CREATE INDEX CONCURRENTLY` interrupted by deploy or crash leaves an invalid index. The index is not used for queries but is still updated on writes — silent performance drain. Operators expect any DB health tool to surface this immediately. Pattern: `SELECT indexname FROM pg_index JOIN pg_class ON pg_index.indexrelid = pg_class.oid WHERE indisvalid = false`. | LOW | Read-only `Ecto.Adapters.SQL.query/3` against `pg_catalog`, no new schema |
| Missing expected indexes (Oban Powertools migration drift) | If the host skipped or only partially ran migrations, required Powertools indexes may be missing. Surfacing this as a named check ("Index `idx_oban_powertools_limiters_name` is missing") is more actionable than a raw DB error at runtime. | MEDIUM | Query `pg_indexes` for expected index names derived from the current migration version; compare against what's present |
| Migration version drift check | Does the Powertools `schema_migrations` state match the library's current migration count? If the library is at migration 12 and the host DB is at 9, the doctor should report "3 Powertools migrations pending." | MEDIUM | Query `schema_migrations` for Powertools-prefixed versions; compare against `ObanPowertools.Migrations.migrations()` list |
| Uniqueness timeout risk (large job table + uniqueness without covering index) | The context doc names this explicitly: ~2M jobs, uniqueness checks, and inadequate indexes cause timeouts. Doctor checks for the presence of the expected uniqueness partial index and warns if it is missing or invalid. | MEDIUM | Check `pg_indexes` for the Oban uniqueness index; report its `indisvalid` status |
| Config sanity checks (repo is set, Oban is in supervision tree) | The most common day-0 install failure: repo not configured, Oban not supervising, or queue names misconfigured. Doctor should surface "`:repo` is not configured" as a check failure rather than a cryptic runtime error. | LOW | Read `Application.get_env(:oban_powertools, :repo)`; check `Oban.config()` reachability |
| Non-zero exit code on any failing check | CI pipelines (`mix oban_powertools.doctor` in a health step) and deployment scripts depend on exit codes. Exit 0 = all checks passed. Exit 1 = at least one check failed. This is universal across `mix format --check-formatted`, `mix credo`, `mix sobelow`. | LOW | `System.halt(1)` in the Mix task when any check fails; never use `raise` (crashes with stack trace instead of clean exit) |
| Human-readable output with pass/fail per check | Each check outputs a line: `[PASS] Index idx_oban_jobs_unique is valid` or `[FAIL] Migration drift: 3 Powertools migrations pending`. Operators can read the output in a terminal or CI log. | LOW | `Mix.shell().info/1` per check |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Module Dependencies |
|---------|-------------------|------------|---------------------|
| Bloat estimate for the Oban jobs table | High-churn job tables accumulate dead tuples quickly, degrading query performance. The doctor can issue a warning if `pg_stat_user_tables.n_dead_tup / n_live_tup` exceeds a threshold (e.g. 10%), suggesting `VACUUM ANALYZE`. This is a concrete "this will hurt you in production" signal that generic health checks miss. | MEDIUM | `pg_stat_user_tables` query, no writes |
| Cooldown table orphan check | If `oban_powertools_limiter_states` has rows with `cooldown_until` in the distant future (e.g. > 24h), that may indicate a limiter was manually cooled down and forgotten. Surface as a warning, not a hard failure. | LOW | Read-only query on `oban_powertools_limiter_states` via `Ecto` |
| `--format json` flag for machine-readable output | Operators integrating doctor into deployment pipelines or dashboards want structured output. `--format json` emits `[{"check": "invalid_indexes", "status": "pass"}, ...]`. Exit code behavior is identical. | LOW | Parse `--format` from `OptionParser.parse/2` in the Mix task |
| Check for non-concurrent index creation in migration history (advisory) | If any Powertools migration created a large index without `CONCURRENTLY`, and the table is now large, the doctor can advise "future migrations should use CREATE INDEX CONCURRENTLY on the oban_jobs table." This is advisory-only, not a failure. | LOW-MEDIUM | Query `pg_indexes` and estimate table size via `pg_total_relation_size` |

### Anti-Features

| Anti-Feature | Why Requested | Why Problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| Running migrations from the doctor task | "Just fix it" — operators want the tool to remediate, not just report | Doctor must be read-only. A task that writes to the DB can cause data loss during inspections in production, or run at the wrong time in a read-replica setup. | Emit actionable remediation instructions: "Run `mix ecto.migrate` to apply pending migrations." |
| Checking Oban Web's own config or indexes | Oban Web is a separate dep with its own health story | Oban Powertools doctor checks Powertools-owned tables and the Oban core tables it directly queries (the jobs table). It does not audit Oban Web's indexes or oban_met's config. | Scope checks to `oban_powertools_*` tables and the Oban jobs/workers tables that Powertools queries directly |
| Clock skew detection | Looks like a useful infrastructure check | Requires inter-node coordination or NTP queries — well outside the scope of a single-node read-only DB/config task. High complexity, low reliability, wrong layer. | Document clock skew as a known operational concern in the runbook; it belongs at the infrastructure layer |
| Prometheus scrape-target check | "Doctor should verify that my metrics endpoint is reachable" | Deeply host-specific, requires network access from the mix task process, has nothing to do with the DB/config surface doctor owns. | Not doctor's responsibility; belongs to host-app monitoring infra |
| Integration with `oban_met` | "Real-time queue counts would make doctor more useful" | `oban_met` is a hard no as a dep for this milestone. Doctor is a read-only DB/config check, not a live dashboard. | Queue count queries are trivial without `oban_met` — `SELECT state, COUNT(*) FROM oban_jobs GROUP BY state` needs no dependency |

---

## Deliverable 3: `mix oban_powertools.limiter.explain` / `.simulate` CLI

### What Prior Art Shows

The context doc explicitly names this as a required footgun remedy (section 5.3): "Rate limit bugs are often conceptual bugs. Is the limit per node? Per cluster? Per tenant?" and mandates `mix oban_powertools.limiter.explain QUEUE JOB_ID` and `mix oban_powertools.limiter.simulate`. The existing `ObanPowertools.Explain` and `ObanPowertools.Limits` modules already implement the underlying logic; the CLI is a thin Mix task wrapper plus a rate-limit glossary.

### What the Existing Modules Expose

`ObanPowertools.Explain.explain/3` already returns:
- `status`: `:runnable` or `:blocked`
- `blockers`: list of `%{code:, scope:, summary:, retry_at:, details:}` structs
- `snapshot_at_block_start`: the persisted snapshot row

`ObanPowertools.Limits.reserve/4` already returns:
- `{:ok, reservation}` — token reserved, job can run
- `{:blocked, blockers}` — with `code: "limit_reached"` or `code: "cooldown"`

The CLI must format these structs for terminal output. No new business logic is needed.

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Module Dependencies |
|---------|--------------|------------|---------------------|
| `mix oban_powertools.limiter.explain WORKER PARTITION_KEY` — show current blocker state for a worker + partition | Operators hit rate-limit confusion ("why is this job not running?") and need a terminal answer, not a LiveView page. The natural expectation is a CLI command that names the worker and partition key. | LOW | Thin wrapper over `ObanPowertools.Explain.explain/3` — already implemented |
| Human-readable blocker output: code, summary, `retry_at`, token usage | The existing `blockers` list has all the data. The CLI formats it: `[BLOCKED] Worker=MyWorker partition=acme_corp: limit_reached (100/100 tokens used, resets at 13:00 UTC)`. | LOW | Format `%{code:, summary:, retry_at:, details:}` from `Explain.explain/3` |
| `mix oban_powertools.limiter.explain --job-id JOB_ID` — explain by job ID | Operators usually start with a job ID they can see in the dashboard or logs. Resolve the job's worker and partition key from the DB, then delegate to `Explain.explain/3`. | MEDIUM | `Oban.Job` Ecto query to resolve worker + args, then existing Explain API |
| Exit code: 0 = runnable, 1 = blocked | CI/deployment scripts may want to check limiter state programmatically. | LOW | Mix task exit code |
| Rate-limit glossary as a shipped guide | The context doc explicitly requires this. The glossary defines: token bucket vs sliding window vs fixed window, what "capacity" means, what a "partition key" is, local vs global scope, what `cooldown` vs `limit_reached` means. This is docs, not code. | LOW | New `guides/rate_limit_glossary.md` or `RATE_LIMITS.md` in hexdocs |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Module Dependencies |
|---------|-------------------|------------|---------------------|
| `mix oban_powertools.limiter.simulate WORKER --tokens N --period P` — dry-run against the current limiter state | Operators about to deploy a config change ("I want to lower the bucket from 200 to 50") can simulate what that config would do against the live DB state — would my current 73 in-flight tokens be blocked? — without actually changing config. | MEDIUM | `ObanPowertools.Limits` logic called with overridden `bucket_capacity` and `bucket_span_ms` params, read-only, no writes |
| Simulate output shows "X of your Y currently-reserved tokens would be blocked under the proposed config" | Makes the simulate command concrete and actionable, not theoretical. | LOW | Read current `State.tokens_used` from DB, compare against proposed capacity |
| Rate-limit glossary cross-linked from blocker codes | Each blocker code in the explain output links to the glossary section that explains it. In terminal output this means "see: oban_powertools.limiter explain --glossary" or a hexdocs URL. | LOW | Glossary doc + `--glossary` flag on the Mix task |
| `mix oban_powertools.limiter.explain --all` — list all resources and their current saturation | Operators want an at-a-glance view of every limiter and its current token usage, not just one worker at a time. Output: a table of resource name, partition key, tokens used, capacity, status. | MEDIUM | Query `oban_powertools_limiter_resources JOIN oban_powertools_limiter_states` — read-only |

### Anti-Features

| Anti-Feature | Why Requested | Why Problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| Limiter reset / drain from the CLI | "Let me clear the limiter so blocked jobs can run now" | A CLI that mutates production limiter state without the preview/reason/audit pipeline is exactly the footgun the native shell was built to prevent. Also: the LiveView control plane already has the reset/refill surface. | Direct operators to the `/ops/jobs/limiters` control plane for mutations. The CLI is read-only explain + simulate only. |
| Sliding window / token bucket simulation with synthetic load curves | "Simulate what happens over 10 minutes if I inject N jobs/second" | This is a load testing problem, not an operability tool. Building a load simulator belongs in a test helper, not a Mix task that operators run against production. | Simulate is limited to: "given the current state of the DB, would this job be blocked under this config?" |
| Per-job rate-limit override from the CLI | Operators want to "boost" specific jobs past the limit | Changes the concurrency semantics in ways that are not audited and are not visible in the control plane. | Operator-initiated limit changes belong in the UI with preview/reason/audit. |
| `oban_met` dependency for live counts | Real-time token consumption data | Zero new deps for this milestone. Current `State.tokens_used` from the DB is fresh enough for an explain CLI. | Direct DB query via `Ecto` |

---

## Deliverable 4: Opt-In `ObanPowertools.Telemetry.metrics/0` + SLO Guide

### What the Frozen Contract Provides

`ObanPowertools.Telemetry` (Phase 8, frozen) emits five event families under `[:oban_powertools, family, event_suffix]`:

- `:operator_action` — metadata: `[:action, :source]`
- `:limiter` — metadata: `[:action, :blocker_code, :resource, :scope]`
- `:cron` — metadata: `[:action, :source, :overlap_policy, :catch_up_policy]`
- `:workflow` — four event suffixes with varying metadata keys
- `:lifeline` — metadata: `[:action, :incident_class, :target_type, :outcome, :archived_count, :pruned_count]`

The only measurement key is `:count`. All high-cardinality values (job IDs, user IDs, args) are intentionally excluded. This is the ceiling the `metrics/0` function must respect.

### What Prior Art Shows

Phoenix generates a `Telemetry` supervisor in every new app with a `metrics/0` function that returns a list of `Telemetry.Metrics` definitions. Reporters (PromEx, `telemetry_metrics_statsd`, `telemetry_metrics_prometheus`) take this list and attach listeners. The convention for libraries is: **emit events via `:telemetry.execute/3`; let the host app wire metrics definitions in their own supervisor.** Libraries can optionally ship a `metrics/0` helper that returns a pre-built list the host app can include in their supervisor — this is the "opt-in" pattern.

Broadway, Ecto, Phoenix itself, and Oban all document their telemetry events but do not ship a `metrics/0` function — they leave metric definition to the host. Oban Powertools can go one step further by providing a pre-built list that operators can drop into their supervisor.

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Module Dependencies |
|---------|--------------|------------|---------------------|
| Documented telemetry events for each family | Without event documentation, operators cannot wire their own metrics. This is the minimum expectation for any library claiming telemetry support. | LOW | Add hexdocs `@doc` entries to each `execute_*` function in `ObanPowertools.Telemetry` describing event name, measurements, and metadata keys |
| `ObanPowertools.Telemetry.metrics/0` returning a `Telemetry.Metrics` list | The Phoenix-ecosystem convention. Operators call `ObanPowertools.Telemetry.metrics()` inside their own Telemetry supervisor `metrics/0` and the list is included alongside Phoenix/Ecto/Oban metrics. Zero magic, no reporter bundled. | LOW | Add `metrics/0` to existing `ObanPowertools.Telemetry` module; use `Telemetry.Metrics.counter/2` and `Telemetry.Metrics.summary/2` from the `:telemetry_metrics` dep (already in the ecosystem, should be in deps) |
| Counter metrics for operator action events (action, source) | Operators need to count audit events by action type for alerting ("how many retry operations this hour?"). `counter("oban_powertools.operator_action.count", tags: [:action, :source])` is the right primitive. | LOW | Maps directly to `[:oban_powertools, :operator_action, event_suffix]` + `[:action, :source]` metadata |
| Counter metrics for limiter events (action, blocker_code, resource, scope) | Limiter saturation and rejection rate are the primary SLOs for the rate-limiting subsystem. `counter("oban_powertools.limiter.blocked.count", tags: [:blocker_code, :resource, :scope])` directly answers "how often is limiter X exhausted?" | LOW | Maps directly to the `:limiter` family |
| Counter metrics for lifeline events (action, incident_class, outcome) | SRE teams want to know: how many orphan rescues happened? How many failed? `counter("oban_powertools.lifeline.count", tags: [:action, :incident_class, :outcome])` is the right primitive. | LOW | Maps directly to the `:lifeline` family |
| Parapet/SLO guide: what to alert on, what thresholds make sense, how to interpret the events | Operators know the events are there but do not know what SLO to build. A guide saying "alert when `limiter.blocked` rate exceeds X per minute for Y minutes" bridges the gap between raw telemetry and actionable SRE practice. | LOW | New `guides/slo_guide.md` in hexdocs |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Module Dependencies |
|---------|-------------------|------------|---------------------|
| SLO framing around the four golden signals for background jobs | Traffic = jobs inserted/started. Latency = time-in-queue (not directly in the frozen contract, but derivable from limiter blocked duration). Errors = limiter rejected + lifeline failed rescues. Saturation = limiter `tokens_used / bucket_capacity`. A guide that maps each golden signal to specific event counters tells operators exactly what to alert on. | LOW | Docs only — no new code required |
| Pre-built SLO definition examples (PromEx plugin snippet, Prometheus recording rules) | Operators using PromEx want a starter plugin. The guide ships copy-paste examples: `event_metrics([:oban_powertools, :limiter, :blocked], measurement: :count, tags: [:resource, :blocker_code])`. This is docs that compress weeks of SRE trial-and-error. | LOW | Docs + example code snippets; no PromEx dep |
| Explicit cardinality budget table in the guide | The frozen contract's low-cardinality design is intentional but opaque without documentation. A table showing: "`:resource` = limiter name (typically 1-20 distinct values); `:scope` = `global` or `partitioned` (2 values); `:action` = one of 5 values" gives operators confidence that adopting these metrics will not blow up their Prometheus TSDB. | LOW | Docs only |
| `doctor` check: at least one telemetry handler is attached | If no reporter is attached to the Powertools events, the doctor can warn "no telemetry handlers attached to `[:oban_powertools, :lifeline]` — ensure a reporter is configured." Not a failure, but a useful advisory. | LOW | `:telemetry.list_handlers([:oban_powertools])` at doctor time |

### Anti-Features

| Anti-Feature | Why Requested | Why Problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| `oban_met` as a dependency, even optional | "Real-time job counts would make the SLO surface more complete" | `oban_met` is explicitly deferred-until-signal in `PROJECT.md`. It is a high-risk dep-creep that drifts toward rebuilding Oban Web's live metrics dashboard — the exact anti-pattern the thread names. | The frozen `:limiter`, `:lifeline`, and `:operator_action` events provide sufficient counter-based metrics for SLO alerting without live counts. Live counts belong in v1.9 as an optional read source. |
| Bundling a reporter (PromEx plugin, ConsoleReporter) with the library | Operators want "zero config" metrics out of the box | Reporters are host concerns. Every host app has its own reporter choice (PromEx vs statsd vs OTEL). Bundling one forces a dep on every host, including those using a different reporter. The "opt-in `metrics/0`" pattern is the correct answer — ship the list, not the reporter. | Ship `ObanPowertools.Telemetry.metrics/0` that returns the list; let the host pass it to their chosen reporter. |
| Adding new telemetry event families in v1.6 | "The doctor and limiter CLI should emit their own events" | The frozen contract is frozen. v1.6 is about operability tooling, not extending the public API surface. The context doc already has `[:oban_powertools, :doctor, :check_started/:check_failed/:check_passed]` in the vocabulary — but emitting those requires unfreezing the contract and updating all telemetry contract tests. | Doctor is a one-shot Mix task with human-readable output and exit codes. Telemetry events for doctor runs belong in a future milestone when the doctor is a persistent runtime check rather than a one-shot CLI invocation. |
| `Telemetry.Metrics.summary/2` for duration metrics | "I want P95 limiter reservation time" | Duration measurement is not in the frozen contract — only `:count` is the defined measurement key. Adding `:duration` to limiter events requires unfreezing the contract. | Document that duration metrics are not available from the frozen contract; operators wanting latency distribution should instrument at the host-app job level using Oban's own `[:oban, :job, :stop, :duration]` event. |
| Adding high-cardinality tags (worker name, job ID, tenant ID) to the `metrics/0` definitions | "I want per-worker failure rates" | The frozen contract explicitly excludes high-cardinality values from metadata. Even if they were in the events, they would blow up Prometheus cardinality. The contract doc is explicit: IDs, job args, preview tokens, and free-form reasons are excluded. | Per-worker metrics belong in the host app using Oban's own job telemetry events which include worker name. Powertools metrics are for the control-plane operations (limiter state, lifeline actions, operator mutations). |

---

## Feature Dependencies

```
Deliverable 1: Hex Release
    requires: working Igniter installer (already shipped)
    requires: migrations runnable from published hex dep (not path dep) 
    requires: CHANGELOG.md (new file)
    requires: mix.exs :package metadata complete

Deliverable 2: mix oban_powertools.doctor
    requires: Repo configured (checks Application.get_env at runtime)
    requires: read-only Ecto.Adapters.SQL.query/3 access to pg_catalog
    requires: ObanPowertools.Migrations version list (for drift check)
    enhances: Hex release (doctor is a first-class adoption signal: "run this after install")
    does NOT require: oban_met, Limits, Explain, Telemetry modules

Deliverable 3: mix oban_powertools.limiter.explain / .simulate
    requires: ObanPowertools.Explain (already built — explain/3, persist_snapshot/4)
    requires: ObanPowertools.Limits (already built — resource/state DB tables)
    requires: Oban.Job Ecto schema (for --job-id resolution)
    requires: oban_powertools_limiter_resources + oban_powertools_limiter_states tables (from migrations)
    enhances: Hex release (limiter CLI is a named footgun remedy; its existence is a selling point)
    does NOT require: oban_met, Telemetry.metrics/0, doctor

Deliverable 4: Telemetry.metrics/0 + SLO guide
    requires: ObanPowertools.Telemetry (already built — frozen contract with 5 families)
    requires: :telemetry_metrics dep (standard Elixir ecosystem dep, already in Phoenix apps)
    enhances: doctor (doctor can check if handlers are attached)
    does NOT require: oban_met, limiter CLI, doctor task

Hex Release enables all three operability deliverables to be adopted by real users.
Doctor + Limiter CLI + Telemetry guide are independent of each other.
```

### Dependency Notes

- **Deliverable 2 (doctor) does NOT depend on Deliverables 3 or 4.** It is a pure DB/config read task. Can be phased first within v1.6.
- **Deliverable 3 (limiter CLI) wraps existing modules.** The only new work is the Mix task shell and the glossary doc. No new business logic.
- **Deliverable 4 (Telemetry.metrics/0) cannot extend the frozen contract.** It must be disciplined to expose only what the existing five families and `:count` measurement key provide. Any temptation to "just add one more event" triggers a contract change requiring telemetry contract test updates.
- **The hex release (Deliverable 1) is the prerequisite for real-world validation of all three operability tools.** Without it, all three tools are invisible to adopters.

---

## MVP for v1.6

### Ship in v1.6

- [ ] Hex release at `0.5.0` — bump version, complete `:package` metadata, write CHANGELOG.md first entry, verify install from published package in a clean Phoenix app
- [ ] `mix oban_powertools.doctor` — invalid index check, missing index check, migration drift check, config sanity check, non-zero exit on failure
- [ ] `mix oban_powertools.limiter.explain WORKER PARTITION_KEY` — reads current blocker state from `Explain.explain/3`, formats for terminal
- [ ] `mix oban_powertools.limiter.simulate WORKER --capacity N --period P` — dry-run against current DB state
- [ ] Rate-limit glossary (`guides/rate_limit_glossary.md`) — defines token bucket, partition key, cooldown, limit_reached, local vs global scope
- [ ] `ObanPowertools.Telemetry.metrics/0` — returns `Telemetry.Metrics` counter list for all five event families, respects frozen contract
- [ ] Parapet/SLO guide — maps golden signals to event counters, provides PromEx snippet examples, includes cardinality budget table

### Defer Post-v1.6

- [ ] `mix oban_powertools.limiter.explain --all` (list all resources) — useful but not blocking; add if the core explain task lands early
- [ ] Doctor `--format json` — useful for automation but not required to unblock adoption
- [ ] Doctor bloat check — more complex pg_stat query; useful but advisory-only; defer to a patch
- [ ] Doctor telemetry-handler advisory check — nice-to-have signal; add with the SLO guide if time permits
- [ ] Doctor cooldown orphan check — low complexity but narrow use case; defer to a patch
- [ ] New telemetry event families for doctor runs — requires unfreezing the contract; belongs in a future milestone when doctor becomes a runtime check

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Hex publish at 0.5.0 with correct metadata | HIGH | LOW | P1 |
| CHANGELOG.md + 0.x versioning docs | HIGH | LOW | P1 |
| Getting-started verified from published package | HIGH | MEDIUM | P1 |
| `doctor`: invalid index + migration drift + config checks | HIGH | MEDIUM | P1 |
| `doctor` non-zero exit code | HIGH | LOW | P1 |
| `limiter.explain` CLI (wraps Explain.explain/3) | HIGH | LOW | P1 |
| Rate-limit glossary | HIGH | LOW | P1 |
| `ObanPowertools.Telemetry.metrics/0` | MEDIUM | LOW | P1 |
| Parapet/SLO guide | MEDIUM | LOW | P1 |
| `limiter.simulate` CLI | MEDIUM | MEDIUM | P1 |
| `doctor` bloat check | MEDIUM | MEDIUM | P2 |
| `doctor --format json` | LOW | LOW | P2 |
| `limiter.explain --all` | LOW | MEDIUM | P2 |
| Doctor telemetry-handler advisory | LOW | LOW | P2 |
| New telemetry event families | LOW | HIGH | P3 (defer) |
| `oban_met` integration | LOW | HIGH | P3 (defer to v1.9) |

**Priority key:**
- P1: Must have for v1.6 launch
- P2: Add if time permits within v1.6, otherwise patch
- P3: Defer — explicitly out of scope or wrong milestone

---

## Prior Art Comparison

| Feature | Rails/ActiveJob `rails/health` | `mix sobelow` / `mix credo` | Oban's own checks | Our approach |
|---------|-------------------------------|----------------------------|-------------------|--------------|
| Health check task | HTTP endpoint, not a mix task | Mix task, non-zero exit on failure, human-readable output | None native | Mix task with non-zero exit, human-readable + optional JSON |
| Index health | Not included | Not applicable (static analysis) | Not included | pg_catalog queries, Powertools-specific expected index list |
| Migration drift | `db:migrate:status` shows pending | Not applicable | Not included | Query `schema_migrations` vs `ObanPowertools.Migrations` list |
| Limiter explain | Not applicable | Not applicable | None | `Explain.explain/3` wrapped as CLI — directly wraps existing module |
| Rate-limit glossary | Not applicable | Not applicable | ElixirForum thread cited in context doc | Shipped as hexdoc guide, cross-linked from CLI output |
| Telemetry metrics list | Not applicable | Not applicable | Oban documents events, no `metrics/0` helper | `ObanPowertools.Telemetry.metrics/0` opt-in list for host supervisor |
| SLO guide | Not applicable | Not applicable | None | Golden signals mapped to event counters, cardinality budget table |

---

## Sources

- `ObanPowertools.Explain` module: `/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex` — HIGH confidence (direct source read)
- `ObanPowertools.Limits` module: `/Users/jon/projects/oban_powertools/lib/oban_powertools/limits.ex` — HIGH confidence (direct source read)
- `ObanPowertools.Telemetry` module: `/Users/jon/projects/oban_powertools/lib/oban_powertools/telemetry.ex` — HIGH confidence (direct source read; frozen contract confirmed)
- Post-v1.5 thread: `/Users/jon/projects/oban_powertools/.planning/threads/2026-05-28-post-v1.5-next-milestone.md` — HIGH confidence (repo-grounded assessment)
- Context doc footguns (5.3, 5.4): `/Users/jon/projects/oban_powertools/prompts/oban_powertools_context.md` — HIGH confidence (direct read)
- PROJECT.md defer-until-signal list: `/Users/jon/projects/oban_powertools/.planning/PROJECT.md` — HIGH confidence (direct read)
- Phoenix Telemetry `metrics/0` convention: https://hexdocs.pm/phoenix/telemetry.html — HIGH confidence (official docs)
- Elixir library guidelines on 0.x versioning: https://hexdocs.pm/elixir/library-guidelines.html — HIGH confidence (official docs)
- `mix hex.publish` docs and required metadata: https://hex.pm/docs/publish — HIGH confidence (official docs)
- `ecto_psql_extras` pg_catalog query patterns (invalid indexes, bloat, seq_scans): https://hexdocs.pm/ecto_psql_extras/readme.html — HIGH confidence (library docs)
- PostgreSQL `pg_index.indisvalid`: https://www.postgresql.org/docs/current/catalog-pg-index.html — HIGH confidence (official Postgres docs)
- Invalid index overhead and `indisvalid = false` pattern: https://postgres.ai/blog/20260106-invalid-index-overhead — MEDIUM confidence (technical blog, cross-checked with pg docs)
- PromEx plugin convention and `event_metrics/1` callback: https://github.com/akoutmos/prom_ex/blob/master/guides/howtos/Writing%20PromEx%20Plugins.md — MEDIUM confidence (community library, well-established)

---

*Feature research for: Oban Powertools v1.6 Release & Operability*
*Researched: 2026-05-28*
