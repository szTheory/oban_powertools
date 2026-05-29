# Phase 2: Smart Engine Limits & Cron - Research

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Use a hybrid ownership model where worker modules own limiter bindings and partition extraction, while Postgres owns durable limiter resources, mutable runtime state, cooldowns, and operator toggles.
- Keep queue-local concurrency in Oban config; Phase 2 owns global concurrency, partitioned concurrency, rate limiting, weights, manual cooldowns, explainability, and cron overlap/catch-up semantics.
- Make worker-facing smart-engine participation explicit and grep-able via `use ObanPowertools.Worker`.
- Persist structured `explain/1` blocker evidence and keep the public explain contract machine-readable, ordered, deterministic, and side-effect free.
- Use code-managed and runtime-managed cron entries with a durable slot ledger keyed by entry and slot time.
- Keep telemetry low-cardinality and operator-oriented; put high-cardinality evidence into persisted snapshots and audit records.
- Keep the native UI narrow: overview, limiters, cron, audit, and explanation-first blocked-job detail inside the existing `/ops/jobs` shell.

### the agent's Discretion
- Exact module boundaries and file layout, provided durable resource/state separation stays explicit.
- Internal limiter algorithms, provided they preserve the locked user-visible semantics.
- Exact page composition and copy within the approved UI contract.

### Deferred Ideas (OUT OF SCOPE)
- Full native replacement for generic Oban dashboards.
- Dynamic queues, fairness consoles, workflow-specific blockers, or lifeline/repair features.
- UI-defined partition logic or broad semantic editing of code-managed cron entries.

## Phase Requirements

| Requirement | Meaning for implementation |
|-------------|----------------------------|
| ENG-01 | Build durable global and partitioned limiters with token-bucket semantics and explicit worker bindings. |
| ENG-02 | Provide a structured `explain/1` API plus persisted blocker snapshots and UI-ready evidence. |
| ENG-03 | Build dynamic cron with explicit overlap and catch-up policies, cluster-safe dedupe, and operator controls. |

# Phase 2: Smart Engine Limits & Cron - Research

## Summary

Phase 2 should extend the repo's existing pattern of explicit worker configuration plus Postgres-backed transactional state. The strongest in-repo analog is `ObanPowertools.Idempotency`: it already couples Ecto schemas, `Ecto.Multi`, conflict handling, and deterministic return shapes. The main new work is a smart-engine subsystem that introduces durable limiter resources/state, cron entries/slot ledgers, a structured blocker explanation service, and narrow native operator pages.

The architecture should avoid hidden runtime magic. Worker modules should declare limiter bindings in code, then resolve those bindings to durable named resources at enqueue/runtime boundaries. Cron semantics should follow the same approach: code may seed stable entries, but each firing decision must pass through a Postgres-backed ledger so overlap and catch-up policies remain cluster-safe.

## Architectural Responsibility Map

| Area | Recommended responsibility |
|------|----------------------------|
| Worker declarations | `ObanPowertools.Worker` validates `limits:` config and exposes explicit callbacks for partition/weight extraction. |
| Durable limiter metadata | New Ecto schemas under `ObanPowertools.Limits` for named resources and mutable state rows. |
| Reservation / release / cooldown | Service module using `Ecto.Multi` transactions modeled after `ObanPowertools.Idempotency`. |
| Explain contract | Dedicated `ObanPowertools.Explain` service that assembles deterministic blocker payloads plus historical snapshots. |
| Cron semantics | `ObanPowertools.Cron` with entry persistence, slot claiming, overlap/catch-up policy enforcement, and manual trigger helpers. |
| Operator telemetry | `ObanPowertools.Telemetry` remains the only event-name construction boundary. |
| Native UI/actions | New `/ops/jobs` LiveView surfaces that consume explain/limit/cron services and defer generic job inspection to Oban Web. |

## Standard Stack

### Core
- Ecto schemas plus `Ecto.Multi` for all limiter reservation, slot-claim, cooldown, snapshot, and audit writes.
- Oban worker extension points for explicit `limits:` bindings and deterministic callbacks.
- Phoenix LiveView pages within the existing shell for overview, limiters, cron, and audit.

### Supporting
- Existing installer flow for migrations and host wiring.
- Existing auth behaviour for page-level and action-level authorization.
- Existing telemetry wrapper for low-cardinality smart-engine events.

### Alternatives Considered
- Redis or process-local limiters: rejected because project posture is Postgres-native and cluster safety matters.
- UI-managed worker semantics: rejected because it hides operational behavior and breaks grep-able code ownership.
- Time-based duplicate suppression without a durable slot ledger: rejected because overlap/catch-up guarantees become ambiguous under crash/restart conditions.

## Architecture Patterns

### Recommended Project Structure
- `lib/oban_powertools/limits/resource.ex`
- `lib/oban_powertools/limits/state.ex`
- `lib/oban_powertools/limits.ex`
- `lib/oban_powertools/explain.ex`
- `lib/oban_powertools/cron/entry.ex`
- `lib/oban_powertools/cron/slot.ex`
- `lib/oban_powertools/cron.ex`
- `lib/oban_powertools/web/live/engine_overview_live.ex`
- `lib/oban_powertools/web/live/limiters_live.ex`
- `lib/oban_powertools/web/live/cron_live.ex`
- `lib/oban_powertools/web/live/audit_live.ex`

### Pattern 1: Code-Owned Bindings + Durable Runtime State
- Follow the same explicit compile-time option parsing used by `worker.ex`.
- Validate `limits:` declarations at compile time and snapshot resolved binding metadata onto queued jobs.
- Persist named limiter resources separately from mutable runtime state so operator toggles do not rewrite code semantics.

### Pattern 2: Claim-Then-Commit Transactions
- Model limiter reservations and cron slot claims after the `Receipt` conflict flow in `idempotency.ex`.
- Use `on_conflict`, explicit conflict targets, and tagged tuples instead of exceptions for expected contention or blocked states.
- Write snapshot/audit rows in the same transaction as state changes whenever user-visible meaning changes.

### Pattern 3: Explanation-First Operator Surfaces
- Build `explain/1` around stable blocker codes with coarse scope information, summary text, retry timing, details payloads, and operator-action flags.
- Persist snapshots when blocked state starts or materially changes, but recompute live explanations on demand.
- Keep overview/list pages shallow and deep-link to Oban Web for generic job detail.

### Pattern 4: Durable Slot Ledger
- Persist cron firings as slots keyed by `{entry_id, slot_at}`.
- Encode overlap policy (`queue_one`, `skip`, `allow`, `cancel_previous`) and catch-up policy (`latest`, bounded replay`) in durable entry metadata.
- Treat policy/expression/timezone changes as guarantee-window resets rather than pretending historical continuity.

## Don't Hand-Roll
- Do not build hidden in-memory schedulers as the source of truth.
- Do not attach high-cardinality IDs or partition values to telemetry labels.
- Do not collapse blocker history and live status into one ambiguous payload.

## Common Pitfalls

### Pitfall 1: Partition Logic Drift
If queued jobs recompute partitions from mutable code or resource state without a snapshot, edits after enqueue silently change the meaning of existing jobs.

### Pitfall 2: Naive Overlap Suppression
Using only "is there an active job now?" checks will miss crashes and race conditions. The slot ledger must be the durable source of truth.

### Pitfall 3: Explain Contracts as Strings
English-only explanations make tests brittle and the UI weak. Stable blocker codes and structured details should drive all presentation.

### Pitfall 4: High-Cardinality Telemetry
Raw partition values, job IDs, and full blocker payloads in telemetry metadata will damage metrics usefulness and violate project guidance.

## Code Examples

### Limiter reservation flow
- Validate worker args and limit bindings.
- Resolve named limiter resource and partition key.
- Attempt a reservation transaction that either returns `{:ok, reservation}` or `{:blocked, blockers}`.
- Persist blocker snapshot and emit coarse telemetry when blocked.

### Cron slot flow
- Compute the due slot for an entry.
- Claim `{entry_id, slot_at}` using an insert conflict target.
- Evaluate overlap/catch-up policy from durable metadata.
- Enqueue the job and mark slot state inside one transaction.

## Assumptions Log
- Phoenix LiveView is available or intended for the native operator shell already established in Phase 0.
- Test support can grow with new migrations and repo-backed data tests without introducing external dependencies.
- Phase 2 can add new modules freely because the public surface is still small and controlled.

## Open Questions (Resolved for planning)
- Should limits live in code or in the database? Hybrid ownership is locked.
- Should blocked evidence be recomputed or persisted? Hybrid evidence is locked.
- Should cron semantics be code-only or runtime-editable? Hybrid source model is locked.

## Environment Availability
- Repo already contains Ecto, Oban, and installer wiring patterns.
- Test harness already supports repo-backed transactional tests and source-contract installer tests.
- No external coordinator or Redis layer is present or desired.

## Validation Architecture

### Test Framework
- Repo-backed ExUnit data tests for limiter reservation, blocker snapshots, and cron slot semantics.
- Source-contract tests for installer migration content.
- LiveView/router tests for native shell pages and guarded actions.

### Phase Requirements -> Test Map
- ENG-01: reservation tests covering global limits, partitioned limits, cooldown state, and deterministic conflict/block results.
- ENG-02: explain tests covering runnable vs blocked payloads, blocker ordering, snapshot-vs-live distinction, and low-cardinality telemetry boundaries.
- ENG-03: cron tests covering unique slot claims, overlap policies, catch-up policies, timezone persistence, pause/resume, and run-now controls.

### Wave 0 Gaps
- No existing analog for LiveView pages in the repo.
- No existing analog for enum-like state models or slot-ledger schemas.
- No existing audit writer abstraction beyond the Phase 0 table.

## Security Domain

### Applicable ASVS Themes
- Access control for page views and mutating operator actions.
- Data integrity for limiter state, slot claims, and blocker/audit evidence.
- Availability protections against runaway backfill or limiter bypass.

### Known Threat Patterns for This Phase
- Bypassing operator authorization on preview or action endpoints.
- Duplicate or skipped cron runs under race conditions if slot claims are not transactional.
- Runaway unblocking or cooldown clearing without durable audit trails.
- Silent policy drift when code-managed cron or limiter semantics change without snapshot/version awareness.

## Sources

### Primary (HIGH confidence)
- `.planning/phases/2-CONTEXT.md`
- `.planning/phases/2-PATTERNS.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`
- `.planning/research/operator_ux.md`
- `lib/oban_powertools/worker.ex`
- `lib/oban_powertools/idempotency.ex`
- `lib/oban_powertools/telemetry.ex`

## RESEARCH COMPLETE
