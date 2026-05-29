# Phase 48: Doctor Health-Check Task - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship `mix oban_powertools.doctor` — a strictly read-only Mix task that diagnoses Oban DB/config health (over `pg_catalog`/`information_schema`) before and after deploys: Oban index presence + `INVALID` indexes left by failed `CREATE INDEX CONCURRENTLY`, migration drift, config validation honoring a custom Oban prefix/schema, and uniqueness-timeout risk. Returns CI-honest exit codes 0/1/2 with actionable remediation hints.

Requirements **OPS-03, OPS-04, OPS-05** define *what* to check and the exit-code triad — those are locked. This discussion settled *how* to implement, under the v1.6 zero-new-dependency / near-zero-runtime-risk mandate.

</domain>

<decisions>
## Implementation Decisions

### Output Format
- **D-01:** Dual output — human-readable sectioned report (default) **plus** `--format json`. Auto-degrade ANSI color via `IO.ANSI.enabled?` (off in non-TTY/CI). Exit codes 0/1/2 remain the primary machine contract; JSON is the structured-consumer path.
- **D-02:** `--format json` adds **no new dependency** — `{:jason, "~> 1.4"}` is already a declared non-optional runtime dep (`mix.exs:50`). The v1.6 zero-dep mandate is satisfied; do NOT treat JSON as requiring a dep addition.
- **D-03:** The JSON payload carries a top-level **`schema_version`** field and is documented as a **stability contract** (CHANGELOG-tracked, semver-aware). Field/shape changes are deliberate, not incidental — consistent with the project's "explicit, inspectable, honest" ethos and the first-public-hex-release era.

### Severity → Exit-Code Mapping
- **D-04:** Strategy = **fixed conservative default + `--strict` override**. The default mapping must be credible (a "doctor" that exits 0 on an INVALID index destroys trust). `--strict` promotes the warning tier to errors; its scope is narrow and fully enumerable in docs.
- **D-05:** Per-finding severity table (LOCKED):
  | Finding | Default | Under `--strict` |
  |---|---|---|
  | INVALID index (failed CREATE INDEX CONCURRENTLY) | error (2) | error (2) |
  | Missing expected Oban index | error (2) | error (2) |
  | Migration drift (Oban core out of date OR Powertools tables missing/old) | error (2) | error (2) |
  | Uniqueness-timeout risk | warning (1) | error (2) |
  | Cannot-run (DB unreachable / no repo config) | error (2) | error (2) |
- **D-06:** `cannot-run` is an **error (2)**, never a silent skip. A check that cannot execute is indistinguishable from one that would have failed; silently passing an unchecked gate is dishonest by definition. This is a deliberate departure from lint tools that treat "missing plugin" as a warning.

### Target / Config Discovery
- **D-07:** **Layered precedence** for resolution: explicit CLI flags > project config > defaults.
  - Repo: `--repo MyApp.Repo` flag > `ObanPowertools.RuntimeConfig.repo/1` (existing `config :oban_powertools, repo:` contract).
  - Prefix: `--prefix` flag > the host's Oban config read from application env (NOT a running Oban) > `"public"`.
  - `--oban-name` flag (default `Oban`) selects which Oban instance's config key to read when resolving prefix.
- **D-08:** No-repo-configured path halts with a clear, actionable error referencing the `config :oban_powertools, repo:` contract — match the tone of `RuntimeConfig.repo!/1`'s existing setup error.

### Boot Strategy (read-only safety) — overrides the "live introspection" lane
- **D-09:** **Repo-only boot. Do NOT start Oban.** Start just the Ecto Repo (`Ecto.Migrator.with_repo/2`-style, or equivalent manual Repo start) so the task is genuinely side-effect-free and safe to run in production around deploys. Using `@requirements ["app.start"]` is **rejected** because booting the full app starts Oban queues/workers — a "read-only health check" must never begin processing jobs.
- **D-10:** Consequence of D-09: there is **no live `Oban.Registry` introspection**. Prefix comes from the flag or the host's Oban config read out of application env without starting Oban (per D-07). This intentionally trades "authoritative live prefix" for "zero side effects" — the right call for a deploy-time doctor.

### Migration-Drift Detection (read-only)
- **D-11:** **Two-lane detection**, both strictly read-only and prefix-aware, requiring no migration source files (releases often don't ship `priv/repo/migrations`):
  - **Lane 1 — Oban core version:** run the same `pg_catalog.obj_description` query Oban uses on `oban_jobs` in the target prefix, compare the queried integer against the installed dep's `Oban.Migrations.Postgres.current_version()`. Reports "Oban core: vN, expected vM — OUTDATED" or "table absent" (version 0).
  - **Lane 2 — Powertools table presence:** check expected `oban_powertools_*` tables via `information_schema.tables` / `pg_catalog.pg_class` against a hardcoded manifest grouped by migration set. Reports named signals per group (e.g. "workflow tables present / heartbeat tables MISSING").
- **D-12:** The Powertools table manifest must be **versioned alongside `mix oban_powertools.install`** — adding a migration set to the installer requires a corresponding manifest update. The full current table list is enumerated in Code Context below.
- **D-13:** `Oban.Migration.verify_migrated!` is **rejected** as the mechanism — it raises, is `@doc false` internal API, needs a running pool, and gives no Powertools coverage. Lane 1 reuses Oban's *query approach*, not this boot-time helper.

### Claude's Discretion
- Exact section ordering and visual layout of the human report.
- Precise JSON field names/nesting (subject to the `schema_version` contract once chosen).
- How uniqueness-timeout risk is heuristically detected (queue size threshold, partial-index presence) — research/planning to specify.
- Internal module decomposition (e.g. a `Doctor` orchestrator + per-check modules + formatter).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 48: Doctor Health-Check Task" — goal + 5 success criteria (the acceptance bar).
- `.planning/REQUIREMENTS.md` — OPS-03 (index presence/validity incl INVALID, read-only), OPS-04 (migration drift + config validation honoring custom prefix/schema + uniqueness-timeout risk), OPS-05 (exit codes 0/1/2 + remediation hints).
- `.planning/PROJECT.md` §"Current Milestone: v1.6" — zero-new-dep / near-zero-runtime-risk mandate, "explicit, inspectable, honest" ethos, mild-overbuilding caution.

### Reusable seams in this repo
- `lib/oban_powertools/runtime_config.ex` — `repo/1`, `repo!/1` repo resolution + setup-error tone (basis for D-07/D-08).
- `lib/mix/tasks/oban_powertools.install.ex` — existing Mix task precedent. NOTE: it is `use Igniter.Mix.Task` (installer shape); doctor is a plain `Mix.Task` — different structure, source of the migration-set manifest (D-12).

### Oban API to mirror (in host deps, not this repo's source)
- `Oban.Migrations.Postgres.current_version/0` and the `obj_description(oban_jobs)` version query — Lane 1 of D-11. Reference copy visible at `examples/phoenix_host/deps/oban/lib/oban/migration.ex` for the query shape; the real call resolves against the installed `oban ~> 2.18` dep at runtime.

[No external ADRs/specs beyond the above — implementation decisions are fully captured in this CONTEXT.]

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.RuntimeConfig.repo/1` / `repo!/1`: repo resolution + error messaging for D-07/D-08.
- Jason (`{:jason, "~> 1.4"}`, already a runtime dep): JSON encoding for `--format json` — no dep change needed.
- `IO.ANSI.enabled?`: stdlib TTY detection for D-01 color degradation.

### Established Patterns
- Plain `Mix.Task` is new territory here — the only existing task (`oban_powertools.install`) is Igniter-based and not a structural template for doctor.
- Custom-prefix handling already threads through the codebase (`cron.ex`, `idempotency.ex`, `limits.ex`, `explain.ex`, etc.) — prefix-aware queries are an established norm to follow.

### Integration Points
- Read-only DB access via the resolved Ecto Repo started with `Ecto.Migrator.with_repo/2` (D-09); no Oban supervision tree.
- Powertools table manifest (D-12) — current full set to validate presence against:
  `oban_powertools_archive_runs`, `oban_powertools_audit_events`, `oban_powertools_blocker_snapshots`, `oban_powertools_cron_coverages`, `oban_powertools_cron_entries`, `oban_powertools_cron_slots`, `oban_powertools_heartbeats`, `oban_powertools_idempotency_receipts`, `oban_powertools_lifeline_incidents`, `oban_powertools_limit_resources`, `oban_powertools_limit_states`, `oban_powertools_limiter_history_facts`, `oban_powertools_repair_archives`, `oban_powertools_repair_previews`, `oban_powertools_workflow_awaits`, `oban_powertools_workflow_callback_outbox`, `oban_powertools_workflow_command_attempts`, `oban_powertools_workflow_edges`, `oban_powertools_workflow_recovery_attempts`, `oban_powertools_workflow_recovery_sessions`, `oban_powertools_workflow_results`, `oban_powertools_workflow_signals`, `oban_powertools_workflow_steps`, `oban_powertools_workflows`.
  (Grouping into migration sets — smart-engine / workflow / heartbeat-lifeline — is a planning detail; source the authoritative grouping from the install task's migration steps.)

</code_context>

<specifics>
## Specific Ideas

- The doctor's value proposition is **honesty**: it must never exit 0 on a real problem and never silently skip a check (D-06). Remediation hints should be concrete (e.g. cite `REINDEX INDEX CONCURRENTLY ...` for an INVALID index, point at the Oban `Reindexer` plugin, name the missing migration set).
- `--strict` should be documentable as an exact, enumerable promotion of the warning tier — not a vague "be stricter" mode (D-04/D-05).

</specifics>

<deferred>
## Deferred Ideas

- **Live count / `oban_met` integration in doctor output** — out of scope; v1.6 keeps `oban_met` as an optional read source only, and doctor is read-only catalog inspection, not a metrics surface.
- **Multi-instance `--all` enumeration via running Oban** — superseded by the no-side-effects boot decision (D-09/D-10). A live-introspection variant could be a future enhancement if adopters need cross-instance reporting, but it conflicts with the deploy-time read-only safety goal and is not built now.
- **Auto-repair / fix mode** — explicitly out of scope; doctor diagnoses read-only and emits hints, it does not mutate.

None of these block Phase 48 — discussion stayed within the read-only-diagnosis boundary.

</deferred>

---

*Phase: 48-doctor-health-check-task*
*Context gathered: 2026-05-29*
