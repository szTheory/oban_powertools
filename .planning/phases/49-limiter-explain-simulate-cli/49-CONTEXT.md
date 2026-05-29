# Phase 49: Limiter Explain/Simulate CLI - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship two new operator `mix` tasks plus the rate-limit glossary, reusing existing seams:

- **`mix oban_powertools.limiter.explain`** — diagnose a limiter's *current* blocking state (OPS-06).
- **`mix oban_powertools.limiter.simulate`** — preview limiter behavior for a config *without mutating any real state* (OPS-07).
- **Rate-limit glossary** shipped in the CLI's help/documentation output (OPS-08).

This is new **public CLI surface** on a library about to ship at `0.5.0`. The CLI is a thin operator front-end over `ObanPowertools.Explain` and `ObanPowertools.Limits` — it adds no new limiter semantics and duplicates no limiter logic (Success Criterion #4).

Out of scope: any new limiter capability, mutating limiter actions from the CLI (cooldown/reserve/release stay in the Elixir API / UI), and the telemetry/SLO work (Phase 50).
</domain>

<decisions>
## Implementation Decisions

### CLI conventions (mirror the Doctor task — Phase 48)
- **D-01:** Both tasks mirror `Mix.Tasks.ObanPowertools.Doctor` wholesale for one consistent CLI family:
  - `--repo MyApp.Repo` with fallback to `ObanPowertools.RuntimeConfig.repo!/0`; `--prefix`/`--oban-name` resolution with the same best-effort app-env auto-detection and "`--prefix` for reliable production results" caveat.
  - `--format human|json`; JSON carries a `schema_version: 1` stability contract (independent from doctor's — its own schema, version 1).
  - Boot via `Mix.Task.run("app.config")` + `Ecto.Migrator.with_repo/2` — **never** starts Oban or queues/workers.
  - Module-name flags resolved with `Module.safe_concat` — **never** `String.to_atom`/`String.to_existing_atom` on raw CLI input (T-48-05).
- **D-02:** Reuse doctor's exit-code posture where meaningful. `explain` is a diagnostic read: exit `0` normally; exit `2` only on cannot-run (no repo / DB unreachable / unknown worker). `simulate` is pure computation: exit `0` on success, `2` on bad input/unknown worker. (No warning tier needed unless planning surfaces one.)

### Explain target contract (OPS-06)
- **D-03:** **Resource + partition is the primary operator path, with a worker+args fallback.**
  - Primary: `--resource NAME [--partition KEY]` (partition defaults to `__global__` / `ObanPowertools.Limits.partition_defaults/0`). This matches the vocabulary operators already see in the Limiters UI (`web/limiters_live.ex`) and forensics. Resolve live state from `Limits.Resource`/`State` (by name + partition_key) and render the explanation via `Explain.explain_snapshot/2` over the latest persisted blocker snapshot, layering current live State.
  - Secondary/precise: `--worker MOD --args JSON` maps 1:1 onto `Explain.explain/3` (args parsed from JSON, never atomized unsafely).
- **D-04:** **Honest empty state.** When no `Resource`/`State` row and no snapshot exist for the target, report `runnable` / "no limiter state recorded yet" rather than erroring or implying a block. Unknown `--worker` module is a cannot-run error (exit 2).

### Simulate input + side-effect-freedom (OPS-07)
- **D-05:** **Worker-declared config with flag overrides.** `--worker MOD` reads the declared `:limits` (capacity / span / weight) via the same path `ObanPowertools.Worker.limit_snapshot/2` uses; operator may override any of `--bucket-capacity`, `--bucket-span-ms`, `--weight`, `--count`, `--partition`. Lets operators sanity-check the limits they actually shipped.
- **D-06:** **Zero side effects via an extracted pure token-bucket core.** Refactor the side-effect-free decision logic (`normalize_bucket/3` + the cooldown/`tokens_used + weight > bucket_capacity` cond from `attempt_reservation/5`) out of `ObanPowertools.Limits` into a pure function that both `Limits.reserve/3` and `simulate` call. This satisfies "reuse, don't duplicate" (#4) **and** "no mutation" (#2) at once.
  - **Rejected alternative:** running real `Limits.reserve/3` inside a rolled-back `Repo.transaction` — the State write rolls back, but `Telemetry.execute_limiter_event/3`, `Audit.record/4`, and `LimiterHistory.record_fact/2` fire as observable side effects (telemetry is not transactional), so a "simulate" would emit spurious `limiter.blocked` events and audit rows. The pure-core extraction avoids this entirely.
- **D-07:** **Output = a per-request verdict.** Simulate `--count N` sequential reservations of `--weight` each against a fresh (empty) bucket and report, per request, `reserved` vs `blocked` with the blocker code and `retry_at` (bucket reset time). Human format renders a readable sequence; JSON mirrors the `schema_version: 1` shape.

### Glossary (OPS-08)
- **D-08:** Ship the rate-limit glossary as a `@moduledoc` section surfaced through `mix help oban_powertools.limiter.explain` / `.simulate`, sourced from a **single shared string** (one module attribute / helper) that also feeds `guides/limits-and-explain.md` — single source of truth, no drift. Glossary covers at least: `token_bucket`, `bucket_capacity`, `bucket_span_ms`, `weight`/`weight_by`, `partition`/`partition_by`/`scope` (`global` vs `partitioned`), `cooldown`, and the blocker codes `limit_reached` / `cooldown`.

### Claude's Discretion
- Exact human-format layout (sectioning, ANSI/TTY-degradation following doctor's formatter style), flag short-forms, and whether a small `--glossary` print flag is added in addition to `mix help` — planner/executor decide. Whether the pure-core lives in `ObanPowertools.Limits` directly or a small `ObanPowertools.Limits.Bucket`-style submodule is an implementation detail.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` — Phase 49 goal, requirements (OPS-06/07/08), and the 4 success criteria.
- `.planning/REQUIREMENTS.md` §"Operability — Limiter CLI" — OPS-06/07/08 acceptance text; zero-new-runtime-deps constraint.

### Primary analog — copy its conventions
- `lib/mix/tasks/oban_powertools.doctor.ex` — the CLI template: `--repo`/`--prefix`/`--oban-name` resolution, `--format human|json`, `schema_version: 1`, `app.config` + `Ecto.Migrator.with_repo/2` boot strategy, `Module.safe_concat` safe resolution, honest exit codes. **Read in full before planning.**

### Seams to reuse (no duplication)
- `lib/oban_powertools/explain.ex` — `explain/3` (worker+args) and `explain_snapshot/2` (snapshot+live State); return shape `%{status, blockers, live_now, snapshot_at_block_start}`; blocker codes + `blocker_summary/1`.
- `lib/oban_powertools/limits.ex` — `reserve/3`, `partition_defaults/0`, and the side-effect-free logic to extract: `normalize_bucket/3` + `attempt_reservation/5` cond. Note the side-effecting calls (`Telemetry.execute_limiter_event`, `Audit.record`, `record_history_fact`) that simulate must avoid.
- `lib/oban_powertools/limits/resource.ex` (+ `state.ex`) — limiter config/state schema (`bucket_capacity`, `bucket_span_ms`, `default_weight`, `partition_strategy`, `cooldown_until`, `tokens_used`, `bucket_started_at`), keyed by `name` + `partition_key`.
- `lib/oban_powertools/worker.ex` — `limit_snapshot/2` and `:limits` config parsing (how declared worker limits become capacity/span/weight/partition) — the path simulate reuses to read `--worker` config.
- `lib/oban_powertools/web/limiters_live.ex` — confirms the operator vocabulary (resource name + partition) and how the UI already drives `Explain.explain_snapshot/2`.

### Glossary source/target
- `guides/limits-and-explain.md` — existing limits guide; natural home/source for the shared glossary string (OPS-08 single source of truth).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.ObanPowertools.Doctor` — wholesale convention donor (flags, boot, format, exit codes, safe module resolution).
- `Explain.explain/3` + `Explain.explain_snapshot/2` — the entire explain behavior; CLI only adapts input/output.
- `Limits.normalize_bucket/3` + `attempt_reservation/5` decision cond — the token-bucket math simulate needs (to be extracted pure).
- `Limits.partition_defaults/0` — `__global__` partition default.
- `Worker.limit_snapshot/2` / `:limits` parsing — reads a worker's declared limiter config for simulate.

### Established Patterns
- CLI tasks load config without starting apps (`app.config`), open only the repo (`Ecto.Migrator.with_repo`), and never start Oban/queues — preserve this; explain reads DB, simulate may need DB only when resolving `--worker`/`--resource`.
- JSON output is a versioned stability contract (`schema_version: 1`); human output degrades ANSI in non-TTY/CI.
- Module names from CLI resolved via `Module.safe_concat`; JSON args parsed but never atomized from untrusted keys.

### Integration Points
- New tasks live under `lib/mix/tasks/` as `oban_powertools.limiter.explain.ex` / `oban_powertools.limiter.simulate.ex` (naming consistent with `oban_powertools.doctor`).
- Pure token-bucket core extracted within `ObanPowertools.Limits` (or a small submodule) and called by both `reserve/3` and simulate — the one source-touch outside the new task files.
- `:files` whitelist (REL-01) already ships `lib/` + Mix tasks; confirm new task files are included by the published package.
</code_context>

<specifics>
## Specific Ideas

- Operators diagnosing production think in **resource name + partition** (what the Limiters UI and forensics show), not worker module + JSON args — hence resource-primary explain (D-03).
- A "simulate" that emits real `limiter.blocked` telemetry/audit would be dishonest; side-effect-freedom is a hard correctness property, achieved by pure-core extraction, not transaction rollback (D-06).
- Glossary must not drift from the guide — one shared string feeds both `mix help` and `guides/limits-and-explain.md` (D-08).
</specifics>

<deferred>
## Deferred Ideas

- Mutating limiter actions from the CLI (cooldown / reserve / release) — stays in the Elixir API + UI; not an operability footgun this milestone targets.
- Telemetry/SLO metrics surface and Parapet guide — Phase 50 (TEL-01/02/03).
- A richer multi-step / time-advancing simulation timeline (e.g. simulating refills across multiple bucket spans) — beyond OPS-07's "preview behavior for a given config"; revisit only if adopters ask.

None of these block Phase 49.
</deferred>

---

*Phase: 49-limiter-explain-simulate-cli*
*Context gathered: 2026-05-29*
