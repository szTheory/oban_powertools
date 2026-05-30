# Stack Research: Worker Lifecycle & Safety

**Project:** Oban Powertools v1.7
**Researched:** 2026-05-30
**Confidence:** HIGH — versions verified against mix.lock (Oban 2.23.0 locked), oban source at deps/oban, and existing codebase seams.

---

## Scope

v1.7 adds four capabilities to the existing library:

1. Worker lifecycle hooks: `on_start`, `on_success`, `on_failure`, `on_discard` — observe-only, crash-caught
2. Soft `deadline:` (pre-run cancel) + `timeout:` pass-through to Oban's own `timeout/1`
3. Output recording: generalise `Workflow.Result` across all workers (keyed by `oban_job_id`)
4. `redact:` at-rest: drop declared fields at persist-time, never encrypt

---

## New Dependencies Needed

**None.** Every capability in v1.7 is buildable on the existing locked stack.

| Library | Version | Purpose | Rationale |
|---------|---------|---------|-----------|
| (none) | — | — | All four v1.7 features build on Oban 2.23.0 telemetry events, existing Ecto schemas, and the existing `Worker.__using__` macro. No new runtime or optional dep required. |

This is a hard constraint, consistent with v1.6's zero-new-runtime-dep record. If a future phase needs an optional dep it should be introduced at that phase with an explicit decision.

---

## Existing Libraries to Leverage

Everything needed is already locked in mix.lock (2026-05-30 state):

### Hooks: attach to Oban telemetry, not a custom exec wrapper

Oban 2.23.0 emits three job telemetry events from `Oban.Queue.Executor`:

| Event | When | Key metadata |
|-------|------|-------------|
| `[:oban, :job, :start]` | Job fetched, about to execute | `meta.job` (full `Oban.Job`) |
| `[:oban, :job, :stop]` | Job succeeded (`:ok`, `:cancelled`, `:snoozed`) | `meta.job`, `meta.state` (`:success`, `:cancelled`, `:snoozed`, `:discard`) |
| `[:oban, :job, :exception]` | Job failed or timed out | `meta.job`, `meta.state` (`:failure`, `:discard`), `meta.kind`, `meta.reason`, `meta.stacktrace` |

These cover all four hooks precisely:

- `on_start` ← `[:oban, :job, :start]`
- `on_success` ← `[:oban, :job, :stop]` when `meta.state == :success`
- `on_failure` ← `[:oban, :job, :exception]` when `meta.state == :failure`
- `on_discard` ← `[:oban, :job, :stop]` when `meta.state == :discard`, OR `[:oban, :job, :exception]` when `meta.state == :discard` (retry-exhausted)

The hooks are registered per-worker via `:telemetry.attach` in `Worker.__using__`, filtered by `meta.job.worker == inspect(__MODULE__)`. They run in the Oban executor process (same process as `perform/1`), caught with `try/rescue`, and never allowed to change job outcome.

**Why telemetry, not a custom Task/GenServer supervisor?** The executor process is already running; there is no inter-process overhead. Hook crashes are caught by the existing `try/rescue` wrapper. No new supervision tree. This is what the thread doc (`2026-05-28-post-v1.5-next-milestone.md`) calls out explicitly: "hooks run inside the executor process but outside any Powertools transaction; hook failure NEVER changes the job outcome."

### deadline: and timeout: — Oban.Worker callbacks, not job insert options

Oban 2.23.0's `timeout/1` callback (`@callback timeout(job :: Job.t()) :: :infinity | pos_integer()`) is the only Oban-native timeout mechanism. Verified in `deps/oban/lib/oban/worker.ex` (line 415) and `deps/oban/lib/oban/queue/executor.ex` (lines 128–139): a `:timer.exit_after/2` wraps the perform call; expiry raises `Oban.TimeoutError`.

**`deadline:`** is NOT a native Oban concept (confirmed by exhaustive grep of deps/oban — zero results). It is a Powertools-defined pre-run cancellation check: before calling `perform/1`, the worker macro checks whether the job's `scheduled_at` plus the declared `deadline:` duration has elapsed; if so, it returns `{:cancel, :deadline_exceeded}` instead of calling `perform/1`. This is implementable entirely inside the `Worker.__using__` `perform/1` override — no new library needed.

**`timeout:` pass-through** means the `Worker.__using__` macro generates a `timeout/1` callback override that returns the configured value, delegating to Oban's existing `:timer.exit_after` mechanism. This requires zero new library code — it is a one-line generated callback.

### Output recording — generalise `Workflow.Result`

`ObanPowertools.Workflow.Result` already has the right schema shape (`payload`, `payload_bytes`, `summary`, `redacted`, `retention`, `recorded_at`, `expires_at`, `status`, `attempt`). The only change needed is decoupling it from `belongs_to(:workflow)` and `belongs_to(:step)` so a recording can be attached to any Oban job via an `oban_job_id` foreign key instead.

Two implementation options:
1. Add `oban_job_id` to `Workflow.Result`, make `workflow_id`/`step_id` optional (nullable)
2. Extract a new `ObanPowertools.Recording` schema that the workflow step recording rows are a specialisation of

Option 2 is cleaner (no nullable FKs on the existing schema, no migration that touches workflow result rows) and matches the thread guidance: "output recording generalizes the existing `Workflow.Result`...generalized `Workflow.Result` table keyed by `oban_job_id`."

Either way: uses `ecto_sql ~> 3.10` (already locked at 3.14.0) and `postgrex ~> 0.17` (already locked at 0.22.2). No new dep.

**Byte cap implementation:** `byte_size(Jason.encode!(payload))` before insert, reject or truncate if above cap. Uses `jason ~> 1.4` (already locked at 1.4.5). No new dep.

### redact: at-rest — drop at persist, not encrypt

`redact:` is declared in `use ObanPowertools.Worker, redact: [:field_a, :field_b]`. At persist time (inside `enqueue/2` before the job changeset is built), declared field values are replaced with a sentinel (e.g., `"[redacted]"`) or dropped from the args map before writing to `oban_jobs.args`.

Implementation uses the existing `ObanPowertools.DisplayPolicy` and `ObanPowertools.RuntimeConfig` seams — no new library. The `Workflow.Result.redacted` boolean already signals that a recording was stored with redaction applied. The same pattern extends to the new `Recording` schema.

**Why drop, not encrypt?** The project decisions doc is explicit: field-level encryption collides with the args-hashing idempotency fingerprint, blinds the v1.5 job filter (encrypted args are not searchable), and leaks via meta/errors/stacktraces. `redact:` is the correct at-rest answer for sensitive args that must not be stored.

### telemetry — frozen contract addendum

The existing frozen low-cardinality contract in `ObanPowertools.Telemetry` does not yet include a `:worker_hook` family. v1.7 should add one:

```
[:oban_powertools, :worker_hook, :fired]
  metadata keys: [:hook, :worker, :outcome]
  hook values: "on_start" | "on_success" | "on_failure" | "on_discard"
  outcome values: "ok" | "error" (did the hook itself crash?)
```

This is additive to the frozen contract (new family, no change to existing families). Uses `telemetry ~> 1.4` (already locked at 1.4.2). No new dep.

---

## What NOT to Add

| Avoid | Why | What to do instead |
|-------|-----|--------------------|
| `encrypt:` / field encryption library (e.g. `cloak_ecto`) | Collides with idempotency fingerprint hashing, blinds v1.5 job filter, leaks through meta/errors/stacktraces, no proven adopter demand | Ship `redact:` (at-persist drop). Defer `encrypt:` until an adopter explicitly requests it. |
| Custom Task/GenServer for hook execution | Adds supervision complexity, inter-process overhead, and coordination failure modes | Use `:telemetry.attach` inside `Worker.__using__`; hooks run in the executor process, caught with `try/rescue` |
| Oban Pro-style halting hooks (`before_process` semantics) | Allows hooks to change job outcome, creating a hidden control-flow surface and breaking observability guarantees | Hooks are observe-only: crash-caught, never returning a value that affects `perform/1` |
| `oban_met` | Out-of-scope for v1.7; already deferred to v1.9 as an optional read source | Do not add |
| Any new runtime dep | Zero-new-runtime-dep is the established constraint for this library phase | Everything is buildable on existing locked stack |
| Large payload storage (e.g. S3 or object store) for output recording | Out of scope; Oban Pro's 64 MB default is a footgun | Use a small byte cap (recommend 64 KB) stored in Postgres JSONB. If a worker needs large outputs it should write to its own domain table and record a reference. |
| GenServer-backed hook dispatch (async fan-out) | Adds latency, ordering complexity, and crash isolation that is unnecessary for observe-only hooks | Synchronous in executor process, `try/rescue`-wrapped |

---

## Integration Points with Existing Stack

### Worker.__using__ macro

All four features extend the existing `ObanPowertools.Worker.__using__` macro in `lib/oban_powertools/worker.ex`. The macro already:
- Receives compile-time options (`args:`, `limits:`, Oban pass-through opts)
- Generates `perform/1` that validates args and delegates to `process/1`
- Generates `enqueue/2` that routes through `ObanPowertools.Idempotency`

v1.7 additions to the macro:
1. Accept `deadline:`, `timeout:`, `redact:`, `on_start:`, `on_success:`, `on_failure:`, `on_discard:` options alongside existing ones
2. Generate a `timeout/1` callback override when `timeout:` is declared (delegates to Oban's mechanism)
3. In the generated `perform/1`, insert a pre-run deadline check before calling `process/1`
4. In the generated `enqueue/2`, apply `redact:` field dropping before building the job changeset
5. Register telemetry handlers for declared hooks via `:telemetry.attach` in `__after_compile__` or a module-level `@on_load`

### Workflow.Result / new Recording schema

The existing `Workflow.Result` schema (`lib/oban_powertools/workflow/result.ex`) has `belongs_to(:workflow)` and `belongs_to(:step)`. The generalisation introduces a new `ObanPowertools.Recording` schema (new table `oban_powertools_recordings`) with:
- `oban_job_id` (integer FK to `oban_jobs.id`)
- Reuses the field set: `attempt`, `status`, `payload`, `payload_bytes`, `retention`, `redacted`, `summary`, `recorded_at`, `expires_at`
- Workflow step recordings either migrate to this table or the existing `Workflow.Result` rows are kept as-is with a step-scoped alias

The `DisplayPolicy` seam already handles `workflow_result` display via `ObanPowertools.DisplayPolicy.workflow_result/2`. v1.7 adds a parallel `recording/2` display function for the generalised recording.

### Telemetry contract

The existing frozen `@contract` map in `lib/oban_powertools/telemetry.ex` gains a new `:worker_hook` family. The `metrics/0` function (added in v1.6, opt-in via `telemetry_metrics`) gains corresponding counters. This is additive — existing families and constraints are unchanged.

### Lifeline pipeline

`on_discard` hooks fire on retry-exhaustion (when `meta.state == :discard` on the telemetry event). Operator-initiated discards (via Lifeline `job_discard` action) are already audited through the `Lifeline.execute_repair` path — they do NOT fire `on_discard` hooks (those are Oban executor events, not Powertools operator events). This distinction must be documented clearly to avoid adopter confusion.

### Idempotency fingerprint

`redact:` field dropping must happen AFTER the idempotency fingerprint is computed (the fingerprint is derived from raw args before any transformation). The `ObanPowertools.Idempotency.transaction/3` call in `enqueue/2` currently receives pre-redacted args. The correct order: compute fingerprint from original args → drop redacted fields → build job changeset with redacted args. This ensures uniqueness works on original values while storage is clean.

---

## Version Compatibility Summary

| Package | Constraint in mix.exs | Locked (2026-05-30) | v1.7 usage |
|---------|----------------------|---------------------|------------|
| oban | `~> 2.18` | 2.23.0 | `timeout/1` callback, `[:oban, :job, :start/:stop/:exception]` telemetry |
| ecto_sql | `~> 3.10` | 3.14.0 | New `oban_powertools_recordings` migration and schema |
| postgrex | `~> 0.17` | 0.22.2 | No change — JSONB storage for recording payload |
| telemetry | `~> 1.4` | 1.4.2 | `:telemetry.attach` for hook handlers, new `:worker_hook` family |
| jason | `~> 1.4` | 1.4.5 | `byte_size(Jason.encode!(payload))` for recording byte cap |
| telemetry_metrics | `~> 1.0` (optional) | 1.1.0 | `metrics/0` addendum for new `:worker_hook` counter |

No constraint changes needed in mix.exs for v1.7.

---

## Sources

- `deps/oban/lib/oban/worker.ex` — `@callback timeout/1` (line 415), `timeout/1` default impl (line 545)
- `deps/oban/lib/oban/queue/executor.ex` — `start_timeout/1` (lines 128–139), `[:oban, :job, :start/:stop/:exception]` telemetry dispatch (lines 97, 285, 299)
- `deps/oban/lib/oban/telemetry.ex` — full telemetry event table including `:state` values (lines 24–64)
- `lib/oban_powertools/worker.ex` — current `__using__` macro structure, `@powertools_limits`, `perform/1` shape
- `lib/oban_powertools/workflow/result.ex` — existing schema to generalise
- `lib/oban_powertools/workflow/callback_outbox.ex` — existing outbox pattern (reference for recording dispatch model)
- `lib/oban_powertools/runtime_config.ex` — `DisplayPolicy` seam (existing `workflow_result/2`)
- `lib/oban_powertools/telemetry.ex` — frozen `@contract`, `metrics/0` pattern
- `.planning/threads/2026-05-28-post-v1.5-next-milestone.md` — Worker-Lifecycle research conclusions (hooks-in-executor, no halt semantics, generalise Workflow.Result, defer encrypt)
- `.planning/PROJECT.md` — v1.7 feature list, decision posture, idempotency fingerprint constraint
- `mix.lock` — locked versions verified 2026-05-30

---

*Stack research for: Oban Powertools v1.7 — Worker Lifecycle & Safety*
*Researched: 2026-05-30*
