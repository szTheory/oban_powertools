# Research Summary: Oban Powertools v1.7 Worker Lifecycle & Safety

**Project:** Oban Powertools v1.7
**Domain:** Elixir job processing library extension (Oban wrapper)
**Researched:** 2026-05-30
**Confidence:** HIGH

---

## Executive Summary

v1.7 adds four features to every `ObanPowertools.Worker`: lifecycle hooks (`on_start`, `on_success`, `on_failure`, `on_discard`), soft deadline and timeout pass-through, output recording, and at-rest field redaction. All four are buildable entirely on the existing locked stack — Oban 2.23.0, Ecto 3.14.0, Telemetry 1.4.2, Jason 1.4.5, Postgrex 0.22.2 — with zero new runtime dependencies. The milestone follows the established pattern of v1.6: extend the existing `Worker.__using__` macro and shared seams rather than introducing new supervision trees, GenServers, or external processes.

The recommended approach is to build all four features as compile-time macro extensions to `ObanPowertools.Worker`, with one new Ecto schema (`ObanPowertools.JobRecord` / `oban_powertools_job_records`) for output recording. Hooks run synchronously inside `perform/1`, crash-caught, observe-only. Deadline is a soft pre-run cancellation check (not a mid-execution interrupt). Redaction drops fields from `oban_jobs.args` at persist time after the idempotency fingerprint is computed. The natural build order is hooks first (establishes the `perform/1` wrapper), then deadline/timeout (compile-time only, depends on wrapper shape), then output recording (new schema), then redaction (depends on recording pipeline).

The primary risks are correctness traps that look like working code: redacting before fingerprinting (causes false dedup collisions), hooks that are not crash-caught (retries the job on hook failure), and outputting PII into recorded payloads despite redacting it from args. A second class of risk is semantic confusion: `timeout:` is per-attempt execution duration in milliseconds; `deadline:` is wall-clock expiry (do not conflate them); `on_failure` fires on retry-eligible failures but NOT after a timeout kill (BEAM EXIT signal bypasses all `rescue`/`after` wrappers); and `on_discard` is terminal-only (retry exhaustion), not every failed attempt.

---

## Stack Additions

**Zero new dependencies.** Every v1.7 capability builds on the existing locked stack. No constraint changes to mix.exs.

| Library | Locked | v1.7 usage |
|---------|--------|------------|
| oban | 2.23.0 | `timeout/1` callback override; `[:oban, :job, :start/:stop/:exception]` telemetry events |
| ecto_sql | 3.14.0 | New `oban_powertools_job_records` migration and schema |
| postgrex | 0.22.2 | JSONB storage for recording payload (no change) |
| telemetry | 1.4.2 | Additive `:worker_hook` family in frozen `@contract` |
| jason | 1.4.5 | `byte_size(Jason.encode!(payload))` for recording byte cap |
| telemetry_metrics | 1.1.0 (optional) | `metrics/0` addendum for new `:worker_hook` counter |

**Do NOT add:** `encrypt:` / Cloak Ecto (fingerprint collision, blinds job filter, stacktrace leakage), custom Task/GenServer for hooks (unnecessary supervision), `oban_met` (deferred to v1.9), large-payload storage (cap at 64 KB in Postgres JSONB).

---

## Feature Table Stakes vs Differentiators

### Worker Hooks

**Must ship (table stakes):**
- `on_start/1`, `on_success/2`, `on_failure/2`, `on_discard/2` — observe-only, crash-caught, `defoverridable` no-op defaults
- Hook return values discarded; exceptions caught and logged at `:warning`; never affect job outcome
- `on_discard` = terminal only (retry-exhausted or `{:discard, reason}` return), NOT every failed attempt
- `on_failure` does NOT fire on `timeout/1` kill — BEAM EXIT signal bypasses `rescue`/`after`; observe via `[:oban, :job, :exception]` telemetry instead

**Differentiators / defer:**
- Hook telemetry (`[:oban_powertools, :worker_hook, :fired]`) — defer to follow-on; add after hooks are proven useful; removing telemetry later is a breaking change
- Global `attach_hook/1` registry — defer until adoption signal

### Deadline / Timeout

**Must ship (table stakes):**
- `timeout: N` (milliseconds) → generates `def timeout(_job), do: N` override at compile time
- `deadline: N` → stores `meta["__deadline_at__"]` at enqueue; check at top of `perform/1`; returns `{:cancel, :deadline_expired}` if elapsed; soft only (no mid-execution interrupt)
- Both stripped from `oban_opts` before passing to `use Oban.Worker`

**Differentiators (include in Phase 2):**
- Deadline visible in `/ops/jobs` detail view (meta is already rendered — zero extra code)

**Out of scope:**
- Hard deadline (interrupt running job) — requires Oban Pro-level supervision
- Per-job dynamic `timeout:` override at enqueue time — defer

### Output Recording

**Must ship (table stakes):**
- `record_output: true` opt-in per worker (never auto-record — unbounded growth risk)
- `{:ok, result, record_opts}` return convention from `process/1` — additive, all existing returns unchanged
- `ObanPowertools.JobRecord` schema / `oban_powertools_job_records` table (NOT a modified `Workflow.Result`)
- `unique_constraint([:oban_job_id, :attempt])` — prevents double-recording on retry
- No FK to `oban_jobs` in migration — Oban prunes its own table; hard FK blocks pruning
- Fault-tolerant: recording failure logs warning but never fails the job
- `max_payload_bytes` enforced before insert (default 64 KB, configurable)
- `fetch_result/1` query helper
- Output visible in `/ops/jobs` detail via new `:job_recorded` DisplayPolicy kind

**Differentiators (include in Phase 3):**
- `output_retention:` policy (reuse existing `retention` field; wire Lifeline prune cycle)
- Workflow step routing: detect `workflow_id`+`step_name` in meta → write to `Workflow.Result` path, not `JobRecord`

**Out of scope:**
- Streaming / large output — workers should record a reference (S3 key, row ID) for large outputs

### At-rest Redaction (redact:)

**Must ship (table stakes):**
- `redact: [:field]` compile-time option
- `Map.drop` on `oban_jobs.args` — key absent from JSONB (not null/placeholder) — applied after fingerprint, before `Oban.Job.new/2`
- `meta["__redacted_fields__"]` written at enqueue; rendered in `/ops/jobs` detail view
- `redacted: true` set on `JobRecord` when any fields dropped from payload
- Compile-time validation: error if field in both `redact:` and `validate_required`
- Compile-time validation: error if field in both `redact:` and `partition_by:` limiter key
- Output recording layer applies same redact list to `record_opts.payload`

**Out of scope:**
- `encrypt:` — explicitly deferred (PROJECT.md decision)
- Retroactive redaction (`scrub_past_jobs/2`) — out of scope for v1.7
- Scrubbing `oban_jobs.errors` / stacktraces — document the boundary; args-at-persist only

---

## Architecture Highlights

All four features are extensions to the single `ObanPowertools.Worker.__using__/1` macro. No new supervision tree. No new GenServer. No changes to Oban internals.

**Canonical `perform/1` wrapper order — all phases build on this:**



**New components:**

| Component | Responsibility |
|-----------|----------------|
| `ObanPowertools.Worker.Hooks` (internal) | `safe_run_hook/3` dispatcher; crash-caught, logs at `:warning`, never re-raises |
| `ObanPowertools.JobRecord` (Ecto schema) | `oban_powertools_job_records` table; mirrors `Workflow.Result` field set minus workflow FKs; `unique_constraint([:oban_job_id, :attempt])` |
| Migration: `oban_powertools_job_records` | Added to Igniter installer and example host |

**Modified components:**

| Component | Change |
|-----------|--------|
| `ObanPowertools.Worker` | Strip `:deadline`, `:timeout`, `:redact`, hook keys from `oban_opts`; generate `timeout/1` override; inject deadline guard and hook dispatch into `perform/1` |
| `ObanPowertools.DisplayPolicy` | Additive `:job_recorded` kind in `render_job_field/3`; existing kinds unchanged |
| `ObanPowertools.Telemetry` | Additive `:worker_hook` family in `@contract`; existing families unchanged |
| `mix oban_powertools.install` | Generates new migration via Igniter |

**Key constraints carried forward:**
- No FK from `oban_powertools_job_records` to `oban_jobs` — Oban prunes its own table
- `{:ok, result, record_opts}` is additive; all existing return shapes unchanged
- `Workflow.Result` and `oban_powertools_workflow_results` are untouched
- Idempotency fingerprint computed over raw args before any redaction; `generate_fingerprint/2` untouched
- v1.8 Batches milestone will reuse `JobRecord` and hook seams — do not gate v1.8 features into v1.7 schema

---

## Watch Out For

1. **Hook not crash-caught retries the job** — Wrap every hook call in `safe_run_hook/3` that `rescue`s all exceptions, logs at `:warning`, never re-raises. One missing `rescue` turns an observability feature into a job-failure amplifier. This is a hard contract, not opt-in.

2. **Redact before fingerprint = false dedup collisions** — Fingerprint MUST be computed from full, unredacted args before `Map.drop`. Correct order: `fingerprint(original_args)` → `Map.drop(args, redact_fields)` → `Oban.Job.new(stripped_args)`. Inverting this causes two jobs with different values in a redacted field to deduplicate incorrectly.

3. **`on_failure` does not fire after timeout kill** — Oban's `timeout/1` kills via `:timer.exit_after/3` (raw BEAM EXIT). All `rescue`/`after` in `perform/1` are bypassed. Do not rely on `on_failure` for timeout observability. Use `[:oban, :job, :exception]` with `kind: :exit` in a telemetry handler. Document this gap explicitly.

4. **PII leaks into recorded output despite args redaction** — `redact:` only drops named keys from `oban_jobs.args` and `record_opts.payload`. If `process/1` constructs its return value using a redacted field loaded from an external source, that value appears in `JobRecord.payload`. Document the boundary: `redact:` prevents args storage; it does not sanitize output payloads. Workers must not include redacted data in return values.

5. **`on_discard` / `on_failure` conflation causes alert storms** — `on_failure` fires on every retry-eligible failure. `on_discard` fires only on terminal exhaustion. A worker with `max_attempts: 20` using `on_failure` for PagerDuty generates 20 alerts. Hook dispatch routing must be precise: `{:ok,_}`/`:ok` → `on_success`; `{:error,_}`/exception → `on_failure` (retry-eligible); `{:discard,_}` or attempt >= max_attempts → `on_discard`; `{:cancel,_}` → `on_discard` (terminal).

**Additional pitfalls:**
- Do NOT modify `Workflow.Result` to support non-workflow jobs — use a separate `oban_powertools_job_records` table (FK constraints and unique constraint semantics differ)
- Enforce `max_payload_bytes` before every `JobRecord.record/3` (Postgres JSONB TOAST triggers at ~2 KB, degrades reads 2-10x above that)
- Never rely on Ecto's `redact: true` for persistence safety — it only affects `Inspect` output, not DB writes
- Validate at compile time that no field is in both `redact:` and `partition_by: {:args, field}` limiter key

---

## Recommended Phase Order

Research from ARCHITECTURE.md and PITFALLS.md converges on this order:

### Phase 1: Worker Hooks

**Rationale:** Fully self-contained within `ObanPowertools.Worker`. No schema migration. Establishes the `perform/1` wrapper shape that all subsequent phases extend. Highest-value observability feature ships first.

**Delivers:** `on_start/1`, `on_success/2`, `on_failure/2`, `on_discard/2`; `safe_run_hook/3` dispatcher; `defoverridable` no-op defaults; additive `:worker_hook` telemetry contract entry (emit deferred).

**Pitfalls addressed:** Hook-not-crash-caught (1), discard/failure conflation (5), timeout/`on_failure` gap documented (3).

**Research phase:** Not needed — seams confirmed in source.

---

### Phase 2: deadline: / timeout: Pass-through

**Rationale:** Compile-time-only macro changes. Depends on Phase 1 `perform/1` wrapper being in place (deadline check slot is at wrapper entry). No schema changes.

**Delivers:** `timeout: N` → `def timeout(_job), do: N`; `deadline: N` → `meta["__deadline_at__"]` at enqueue + check at `perform/1` entry → `{:cancel, :deadline_expired}`; both keys stripped from `oban_opts`; deadline visible in `/ops/jobs` detail.

**Pitfalls addressed:** Timeout unit validation at compile time; soft-only deadline documented (no mid-execution interrupt); timeout/`on_failure` gap documented.

**Research phase:** Not needed — `timeout/1` callback contract verified directly in `deps/oban/lib/oban/worker.ex`.

---

### Phase 3: Output Recording (JobRecord)

**Rationale:** New schema table required. Depends on Phase 1 `perform/1` wrapper to intercept `{:ok, result, record_opts}` three-tuple. Independent of Phase 2 (can be built concurrently after Phase 1 if bandwidth allows).

**Delivers:** `oban_powertools_job_records` migration; `ObanPowertools.JobRecord` schema; `{:ok, result, record_opts}` return convention (additive); `JobRecord.record/3` fault-tolerant persist with byte cap; `unique_constraint([:oban_job_id, :attempt])`; `fetch_result/1`; `:job_recorded` DisplayPolicy kind; output in `/ops/jobs` detail; Igniter installer updated; retention policy wired to Lifeline prune.

**Pitfalls addressed:** Schema not modified (6), byte cap enforced (7), double-recording prevented (unique constraint), recording failure does not fail the job.

**Research phase:** Not needed — schema design confirmed against `Workflow.Result`; FK decision confirmed against Oban pruning behavior.

---

### Phase 4: redact: At-Rest

**Rationale:** Strictly after Phase 3 — extends the `record_opts` pipeline with the same `@powertools_redact_fields` module attribute. Phase 1 `perform/1` wrapper must also be in place.

**Delivers:** `redact: [:field]` compile-time option; `Map.drop` on `oban_jobs.args` (after fingerprint, before `Oban.Job.new/2`); `meta["__redacted_fields__"]` at enqueue; `__redacted_fields__` in `/ops/jobs` detail; same redact list applied to `record_opts.payload`; `redacted: true` on `JobRecord`; compile-time validation against `validate_required` and `partition_by:` overlaps.

**Pitfalls addressed:** Redact-before-fingerprint collision (2), PII in recorded output (4, documented boundary), Ecto `redact: true` confusion (8), limiter partition overlap (compile-time guard).

**Research phase:** Not needed — all seams confirmed; fingerprint ordering is a code-order constraint.

---

### Phase Ordering Summary



Phases 2 and 3 can be built concurrently after Phase 1 completes. Phase 4 is strictly after Phase 3.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Versions verified against mix.lock; Oban 2.23.0 source inspected for timeout/1 and telemetry events |
| Features | HIGH | Verified against Oban OSS docs, Oban Pro docs, and direct codebase inspection; PROJECT.md defer decisions confirmed |
| Architecture | HIGH | All named modules inspected; build order derived from actual dependency analysis; no speculative gaps |
| Pitfalls | HIGH | Verified against Oban source (timeout EXIT behavior), Ecto docs (redact: display-only), Postgres TOAST threshold, and existing Idempotency seam |

**Overall confidence:** HIGH

### Gaps to Address

- **Hook telemetry emit timing:** ARCHITECTURE.md includes telemetry emit in Phase 1 deliverables; FEATURES.md recommends deferring the emit to avoid premature contract extension. Resolution: ship the `:worker_hook` contract extension (new `@contract` family) in Phase 1 so the contract is ready, but defer actual event emission until hooks are validated in production.

- **`{:cancel, reason}` hook routing:** Confirm at Phase 1 planning: `{:cancel, reason}` from `process/1` routes to `on_discard` (not `on_success` or `on_failure`), with `status: "cancelled"` on any `JobRecord` written.

- **Dual application points for `redact:`:** `redact:` applies at enqueue time (drop from `oban_jobs.args`) AND at record time (drop from `record_opts.payload`). Phase 2 owns the enqueue-time drop; Phase 4 owns the record-time drop. Confirm this split is explicit in phase plans so neither phase omits its half.

---

## Sources

### Primary (HIGH confidence — direct source inspection)

- `deps/oban/lib/oban/worker.ex` — `timeout/1` callback (line 415), default impl (line 545)
- `deps/oban/lib/oban/queue/executor.ex` — timeout kill via `:timer.exit_after` (lines 128-139), telemetry dispatch (lines 97, 285, 299)
- `deps/oban/lib/oban/telemetry.ex` — full event table including `:state` values (lines 24-64)
- `lib/oban_powertools/worker.ex` — `__using__` macro structure, `perform/1` shape
- `lib/oban_powertools/workflow/result.ex` — FK constraints, field set
- `lib/oban_powertools/telemetry.ex` — frozen `@contract`, `metrics/0` pattern
- `lib/oban_powertools/idempotency.ex` — fingerprint-before-args dependency
- `lib/oban_powertools/runtime_config.ex` — `DisplayPolicy` seam
- `.planning/PROJECT.md` — v1.7 feature list, defer decisions, fingerprint constraint
- `mix.lock` — locked versions verified 2026-05-30
- `.planning/threads/2026-05-28-post-v1.5-next-milestone.md` — hooks-in-executor, no halt semantics, generalise Workflow.Result, defer encrypt

### Secondary (HIGH confidence — official docs)

- https://oban.hexdocs.pm/Oban.Worker.html — `timeout/1` callback contract
- https://oban.hexdocs.pm/Oban.Telemetry.html — telemetry event table
- https://oban.pro/docs/pro/Oban.Pro.Worker.html — `after_process/3`, `on_cancelled/2`, `on_discarded/2`, safety guarantees

### Tertiary (MEDIUM confidence)

- https://github.com/sidekiq/sidekiq/wiki/Middleware — middleware pattern (reference comparison)
- https://pganalyze.com/blog/5mins-postgres-jsonb-toast — JSONB TOAST ~2 KB threshold (byte cap rationale)

---

*Research completed: 2026-05-30*
*Ready for roadmap: yes*
