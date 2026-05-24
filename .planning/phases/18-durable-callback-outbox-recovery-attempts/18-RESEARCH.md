# Phase 18: Durable Callback Outbox & Recovery Attempts - Research

**Researched:** 2026-05-24
**Domain:** Crash-safe workflow callbacks, outbox delivery ownership, recovery session modeling, and support-truthful callback/recovery contracts.
**Confidence:** HIGH [VERIFIED: repo-local code, tests, roadmap, requirements, and prior phase artifacts]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Keep Postgres-backed workflow rows as the sole correctness-bearing truth source; callback delivery and future UI refresh paths remain separate from workflow truth. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md]
- Support exactly two workflow-scoped callback events in this phase: `workflow.terminal` and `workflow.recovery_completed`. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md]
- Use thin, versioned callback envelopes with stable IDs and durable semantic fields only; richer details stay fetchable by ID from durable rows. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md]
- Callback delivery is post-commit and at-least-once. Delivery failure becomes durable outbox evidence and must never roll back workflow truth. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md]
- Recovery truth stays step-targeted, but Phase 18 should add a workflow-level recovery session header that groups append-only per-step attempts. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md]
- Avoid broad callback policy matrices, rich snapshot payloads, generic event history, and any callback-ack-gated workflow success semantics. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md]

### the agent's Discretion
- Exact dispatcher or leasing helper module split, provided callback ownership becomes durable and multi-node safe.
- Exact typed columns for callback delivery attempts and recovery sessions, provided queryable fields remain primary over metadata blobs.
- Exact retry/backoff schedule, provided it stays explicit, durable, and support-truthful.

### Deferred Ideas (OUT OF SCOPE)
- Per-step callbacks or a broader callback policy matrix.
- Rich snapshot callback payloads or host-custom payload builders.
- A generic event-sourced workflow history or broad workflow-redrive API.
- UI-first callback delivery visualization beyond the read-model seams later phases need.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `REC-01` | A host app can receive post-commit workflow callbacks through a durable outbox so workflow completion, failure, cancellation, expiry, and recovery side effects survive crashes and retries. | The repo already persists `workflow.terminal` and `workflow.recovery_completed` rows in `CallbackOutbox`, but dispatch is still a simple scan-and-update loop without row leasing, delivery ownership, or durable envelope identity beyond `dedupe_key`. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/workflow/callback_outbox.ex; test/oban_powertools/workflow_runtime_test.exs] |
| `POL-04` | The public telemetry and support-truth docs describe the new workflow semantics with low-cardinality events, explicit non-goals, and no present-tense guarantees that lack durable proof. | The callback contract is currently code-and-test visible but not yet hardened into a narrow supportable public seam; Phase 18 needs the envelope, config seam, runtime behavior, and docs/tests to say the same thing. [VERIFIED: .planning/REQUIREMENTS.md; lib/oban_powertools/runtime_config.ex; lib/oban_powertools/workflow/callback_handler.ex] |
| `REC-02` | An operator or runtime can request scoped workflow recovery without silently re-running already successful side-effecting steps, and the new attempt evidence remains durable and auditable. | Current `recover_step/5` already rejects successful-step recovery and persists append-only `RecoveryAttempt` rows, but it lacks the workflow-level grouped session header that the locked Phase 18 context now requires. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/workflow/recovery_attempt.ex; test/oban_powertools/workflow_runtime_test.exs] |
| `VER-02` | A maintainer can upgrade hosts with in-flight waiting, retrying, cancelling, or recovering workflows without breaking semantics or leaving support unable to explain stored state. | Any callback/recovery schema reshape must land together in installer migrations, example-host fixtures, and test-support migrations or supported hosts will drift from runtime truth. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex; test/support/migrations/2_phase_3_tables.exs; examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs] |
</phase_requirements>

## Summary

Phase 18 should be planned as a durability and modeling hardening phase over real existing seams, not as a first introduction of callbacks or recovery evidence. The runtime already inserts outbox rows for terminal and recovery-complete events, already requires a host callback handler config seam, and already proves retry-after-failure behavior in focused ExUnit. The gap is that delivery ownership is still too weak for multi-node support truth, the public callback envelope is only partially explicit, and recovery grouping stops at step-level attempts instead of a workflow-scoped session header. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/runtime_config.ex; test/oban_powertools/workflow_runtime_test.exs]

The highest-value architectural move is to separate three concerns that are currently compressed together:
1. enqueueing thin, stable callback obligations inside workflow/recovery transactions,
2. claiming and delivering those obligations through an explicit leased dispatcher path,
3. grouping recovery intent at the workflow level while preserving append-only per-step truth.

That sequencing keeps Postgres as the correctness source while making callback delivery and recovery auditability supportable on their own terms. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]

The other planning constraint is contract honesty. The code already has a `Workflow.CallbackHandler` behaviour and `workflow_callback_handler` config seam, so Phase 18 should not widen into a general webhook/event-bus story. It should instead tighten the current promise around exactly two events, thin versioned payloads, at-least-once delivery, handler idempotency, and durable failure evidence. [VERIFIED: lib/oban_powertools/workflow/callback_handler.ex; lib/oban_powertools/runtime_config.ex; .planning/REQUIREMENTS.md]

## Current Gaps That Matter For Planning

### Gap 1: Callback delivery has no explicit row-leasing or ownership model
- `dispatch_callbacks/2` loads all pending or failed rows by `available_at` and iterates them directly. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- There is no `claimed_at`, `claimed_by`, lease expiration, or `FOR UPDATE SKIP LOCKED`-style ownership path in the current query or schema. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/workflow/callback_outbox.ex]
- The locked context explicitly requires Postgres-safe leasing so multiple nodes do not deliver the same callback concurrently. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md]

### Gap 2: The callback outbox row is durable but not yet modeled as a full support-truth delivery contract
- `CallbackOutbox` stores `event`, `dedupe_key`, `status`, `payload`, `attempts`, `available_at`, `delivered_at`, and `last_error`. [VERIFIED: lib/oban_powertools/workflow/callback_outbox.ex]
- That is enough for basic retries, but not enough to expose stable delivery identity, claim state, bounded failure classification, or future operator diagnosis without inferring too much from a blob. [VERIFIED: lib/oban_powertools/workflow/callback_outbox.ex; test/support/migrations/2_phase_3_tables.exs]
- Phase 18 context prefers typed, queryable fields first and bounded metadata second. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md]

### Gap 3: Recovery evidence is append-only but stops at per-step attempts
- `recover_step/5` already persists `RecoveryAttempt` rows with before/after snapshots and then enqueues a callback. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- `RecoveryAttempt` has no workflow-scoped session/header relationship, so grouped operator/runtime intent must be inferred from ad hoc timing or metadata. [VERIFIED: lib/oban_powertools/workflow/recovery_attempt.ex]
- The locked phase context now requires one workflow-level recovery session header linked to append-only step attempts. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md]

### Gap 4: The public callback contract is under-specified relative to the repo's support-truth bar
- The runtime already sends `workflow_id`, `state`, `terminal_cause`, `semantics_version`, `cancel_requested_at`, and `finished_at` for terminal callbacks, and step/recovery fields for recovery callbacks. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- The repo has tests for retry behavior, but there is no plan-local proof yet for the narrow “two events only, thin payload only, at-least-once only” public promise. [VERIFIED: test/oban_powertools/workflow_runtime_test.exs; .planning/REQUIREMENTS.md]
- Phase 18 needs code, docs, and verification to converge on the same small contract instead of letting the shape drift through runtime-only convenience additions. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md]

### Gap 5: Migration truth will drift unless callback and recovery changes land across every supported schema path
- Installer migrations, example-host migrations, and test-support migrations already own the Phase 17 workflow schema contract. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex; examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs; test/support/migrations/2_phase_3_tables.exs]
- Phase 18 necessarily touches workflow callback and recovery persistence, so the schema contract must be updated in all three places in the same slice. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public workflow callback API seam | `ObanPowertools.Workflow` + `Workflow.CallbackHandler` | `RuntimeConfig` | Preserve one simple host-facing seam: one handler callback with one thin envelope map. [VERIFIED: lib/oban_powertools/workflow.ex; lib/oban_powertools/workflow/callback_handler.ex; lib/oban_powertools/runtime_config.ex] |
| Durable callback obligation row | `Workflow.CallbackOutbox` schema + migrations | runtime enqueue helpers | Outbox truth must be queryable and stable before any dispatcher concerns. [VERIFIED: lib/oban_powertools/workflow/callback_outbox.ex; lib/oban_powertools/workflow/runtime.ex] |
| Callback claiming and delivery | runtime dispatcher helper or dedicated dispatcher module | future Oban job or supervisor seam | Delivery is operational behavior layered on committed workflow truth, not the workflow truth itself. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md] |
| Recovery grouped intent | new recovery-session schema | `RecoveryAttempt` rows | Session headers give operator/runtime grouping without replacing per-step truth. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md; lib/oban_powertools/workflow/recovery_attempt.ex] |
| Support-truth contract | requirements/docs/tests | runtime comments/config errors | The repo must prove only the narrow guarantee it can support durably. [VERIFIED: .planning/REQUIREMENTS.md; lib/oban_powertools/runtime_config.ex; test/oban_powertools/workflow_runtime_test.exs] |

## Recommended Plan Slices

### Slice 1: Harden callback outbox rows and delivery ownership
**Why first:** `REC-01` depends on real durable delivery ownership more than on richer host API surface.  
**Likely files:** `lib/oban_powertools/workflow/runtime.ex`, `lib/oban_powertools/workflow/callback_outbox.ex`, `lib/mix/tasks/oban_powertools.install.ex`, `test/support/migrations/2_phase_3_tables.exs`, example-host workflow migration files, `test/oban_powertools/workflow_runtime_test.exs`.  
**Expected outcome:** explicit lease-safe callback claiming, bounded failure accounting, stable envelope identity, and schema parity across runtime and supported hosts.

### Slice 2: Add recovery session headers while preserving step-oriented recovery truth
**Why second:** once callback rows are trustworthy, recovery grouping can build on the same post-commit evidence posture without widening the public API.  
**Likely files:** new `workflow/recovery_session.ex`, `workflow/recovery_attempt.ex`, `workflow/runtime.ex`, `workflow.ex`, migrations, and focused runtime or Lifeline tests.  
**Expected outcome:** one workflow-scoped recovery session header per grouped recovery action, append-only per-step attempts linked to it, and unchanged public `recover_step` paved-road ergonomics.

### Slice 3: Lock contract proof, host wiring truth, and support-language boundaries
**Why third:** the phase closes only if runtime behavior, schema adoption, and docs/tests all describe the same small callback/recovery promise.  
**Likely files:** workflow runtime tests, docs or contract tests, `RuntimeConfig`, `Workflow.CallbackHandler`, installer/example/test migrations, `.planning/REQUIREMENTS.md`, maybe `.planning/PROJECT.md` if ownership/closure truth changes.  
**Expected outcome:** focused crash/retry/duplicate proof, explicit host handler and idempotency guidance, and traceable requirement/support posture for later phases.

## Validation Architecture

Focused ExUnit remains the correct proof posture. The existing workflow runtime suite already exercises callback enqueue and retry behavior without relying on browser flows or multi-service harnesses, and the new risk surface is row-state, lease, dedupe, and audit truth rather than UI polish. [VERIFIED: test/oban_powertools/workflow_runtime_test.exs]

Recommended verification bundle after execution:
`mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/workflows_live_test.exs`

Plus contract and migration integrity checks:
`rg -n "workflow_callback_handler|workflow\\.terminal|workflow\\.recovery_completed|skip locked|claimed_at|recovery_session|at-least-once|idempotent" lib test guides README.md .planning`

The minimum Phase 18 proof bar should cover:
- terminal and recovery callbacks are enqueued once per durable semantic event with stable envelope fields,
- dispatcher retries and failure accounting are durable and multi-node safe in design,
- recovery sessions group related step attempts without replacing step-level truth,
- installer, example-host fixtures, and repo test migrations all generate the same callback/recovery schema surface,
- docs and config seams state only the narrow two-event, thin-envelope, post-commit, at-least-once contract.

## Anti-Patterns To Avoid

- Do not turn the callback system into a generic event bus or webhook platform.
- Do not let callback success or failure rewrite workflow terminal truth.
- Do not make payload blobs the primary query surface for delivery or recovery diagnosis.
- Do not replace append-only step recovery attempts with a workflow-level session row that hides what actually changed.
- Do not publish exactly-once, synchronous, or callback-ack-gated semantics that the current architecture does not prove.

## RESEARCH COMPLETE
