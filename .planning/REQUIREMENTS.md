# Requirements: Oban Powertools v1.7 Worker Lifecycle & Safety

## Overview

Equip every `ObanPowertools.Worker` with observable, durable lifecycle hooks, a generalised output recording contract, and at-rest redaction before adding Batches.

**Milestone:** v1.7  
**Status:** Active  
**Phase start:** 53 (continues from v1.6 last phase 52.1)

---

## v1.7 Requirements

### Worker Lifecycle Hooks

- [ ] **HOOK-01**: Worker can declare `on_start/1` callback that fires before `process/1` — observe-only, crash-caught, no-op default
- [ ] **HOOK-02**: Worker can declare `on_success/2` callback that fires when `process/1` returns `:ok` or `{:ok, _}` — observe-only, crash-caught, no-op default
- [ ] **HOOK-03**: Worker can declare `on_failure/2` callback that fires when `process/1` returns `{:error, _}` or raises — observe-only, crash-caught, no-op default
- [ ] **HOOK-04**: Worker can declare `on_discard/2` callback that fires when job is discarded after exhausting all retries — observe-only, crash-caught, no-op default
- [ ] **HOOK-05**: Worker hook invocations emit telemetry under a new `worker_hook` family in the frozen low-cardinality contract (`hook`, `outcome` keys)

### Deadline & Timeout

- [ ] **SAFE-01**: Worker can declare `timeout: milliseconds` in `use ObanPowertools.Worker` opts to generate a compile-time `timeout/1` callback default
- [ ] **SAFE-02**: Worker can declare `deadline: duration` in `use ObanPowertools.Worker` opts; job stores `__deadline_at__` ISO8601 timestamp in meta at enqueue time
- [ ] **SAFE-03**: `perform/1` checks `__deadline_at__` before calling `process/1`; returns `{:cancel, :deadline_expired}` if wall-clock deadline has passed
- [ ] **SAFE-04**: `mix oban_powertools.doctor` surfaces `retryable` jobs whose `__deadline_at__` has passed as a warning

### Output Recording

- [ ] **REC-01**: Worker can declare `record_output: true` in `use ObanPowertools.Worker` opts to opt in to persisting `{:ok, payload}` return values from `process/1`
- [ ] **REC-02**: `ObanPowertools.JobRecord` Ecto schema with `oban_powertools_job_records` table — standalone-job output storage independent of `Workflow.Result`
- [ ] **REC-03**: Host can retrieve latest recorded output for a job via `fetch_result/1` returning `{:ok, result}` or `{:error, :not_found}`
- [ ] **REC-04**: Recorded output is visible in the `/ops/jobs` job detail view via a new `:job_recorded` DisplayPolicy kind
- [ ] **REC-05**: Worker can declare `output_limit: bytes` (byte cap) and `output_retention: policy` (`:standard`/`:extended`/`:ephemeral`) as compile-time opts

### At-rest Redaction

- [ ] **REDACT-01**: Worker can declare `redact: [:field]` in `use ObanPowertools.Worker` opts; listed fields are dropped from `args` via `Map.drop` at enqueue time, strictly after idempotency fingerprint calculation
- [ ] **REDACT-02**: Redacted field names stored in job meta as `__redacted_fields__` at enqueue time
- [ ] **REDACT-03**: `/ops/jobs` job detail view renders "Fields redacted at enqueue: [:field]" from `meta["__redacted_fields__"]`
- [ ] **REDACT-04**: `DisplayPolicy.render_job_field/3` default rendering shows "Redacted at enqueue" for fields listed in `__redacted_fields__` meta

---

## Future Requirements

*(Deferred from v1.7 — revisit in v1.8 or later)*

- Global `attach_hook/1` registry across workers — defer until adoption signal
- Hard deadline (interrupt running job) — requires Oban Pro DynamicLifeline supervision pattern
- `encrypt:` at-rest — explicitly deferred (see PROJECT.md Key Decisions: collides with fingerprint, blinds job filter, leaks via meta/errors)
- Retroactive redaction (`Redactor.scrub_past_jobs/2`) — requires full Lifeline preview/reason/audit wrapping
- `on_discard` from Lifeline discard path (operator-initiated discards) — v1.7 scope covers Oban-native retry exhaustion only
- `record_output/2` callable explicitly from inside `process/1` without auto-recording — evaluate after v1.7 adopter feedback

---

## Out of Scope

- Per-worker runtime rate limiting outside the existing global/partitioned limiter model (retained from v1.0)
- Non-Postgres coordination layers
- Hard deadline (interrupt mid-execution) — requires Oban Pro supervision; out of scope for free-tier
- `encrypt:` — deferred indefinitely per PROJECT.md decision
- Hook-based pre-execution short-circuit (hooks are observe-only; execution control lives in the enqueue path)

---

## Traceability

| Requirement | Phase | Status  |
|-------------|-------|---------|
| HOOK-01     | 53    | Pending |
| HOOK-02     | 53    | Pending |
| HOOK-03     | 53    | Pending |
| HOOK-04     | 53    | Pending |
| HOOK-05     | 53    | Pending |
| SAFE-01     | 54    | Pending |
| SAFE-02     | 54    | Pending |
| SAFE-03     | 54    | Pending |
| SAFE-04     | 54    | Pending |
| REC-01      | 55    | Pending |
| REC-02      | 55    | Pending |
| REC-03      | 55    | Pending |
| REC-04      | 55    | Pending |
| REC-05      | 55    | Pending |
| REDACT-01   | 56    | Pending |
| REDACT-02   | 56    | Pending |
| REDACT-03   | 56    | Pending |
| REDACT-04   | 56    | Pending |
