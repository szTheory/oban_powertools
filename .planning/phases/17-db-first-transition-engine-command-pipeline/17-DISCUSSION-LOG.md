# Phase 17 Discussion Log

**Phase:** 17 - DB-First Transition Engine & Command Pipeline
**Date:** 2026-05-23
**Mode:** Discuss all, one-shot recommendation synthesis with advisor subagents and local ecosystem research

## User Direction

- Discuss all meaningful gray areas for Phase 17.
- Use subagents for tradeoff research.
- Pull in repo-local prompt and research material where applicable.
- Emphasize idiomatic Elixir/Phoenix/Ecto design, developer ergonomics, operator UX, support-truth, and principle of least surprise.
- Prefer coherent recommendations that reduce future re-asking and shift decisions left within GSD unless the choice is truly high-impact.

## Areas Resolved

### 1. Command surface shape

**Options considered**
- Keep `Workflow.*` as the only stable public API and hide the new transition engine internally
- Dual-layer API with `Workflow.*` helpers plus an advanced command surface
- Make a public command API primary and deprecate helper verbs
- Expose transition plans / `Ecto.Multi` builders publicly

**Locked outcome**
- Keep `Workflow.*` as the paved-road public API in Phase 17.
- Build one internal DB-first legality engine underneath it.
- Do not publish low-level transition plans or a generic command API yet.

**Why**
- Best match for Phoenix/Ecto expectations, lowest semver churn, strongest least-surprise DX.

### 2. Illegal transition handling

**Options considered**
- Return errors only
- Audit-only durable evidence
- Dedicated durable rejection rows only
- Hybrid of structured return error plus durable rejection evidence plus operator audit

**Locked outcome**
- Use the hybrid model.
- Illegal mutations return structured errors immediately and also persist durable rejection evidence.
- Operator-originated attempts additionally emit audit records.

**Why**
- Strongest support-truth without forcing a full event-sourcing leap.

### 3. Action boundaries for Phase 17

**Options considered**
- Narrow legal-path core only
- Narrow core plus explicit deferred shells
- Broad command engine that effectively absorbs Phases 18-20
- Broad facade with mixed authority

**Locked outcome**
- Own the narrow legal-path core plus explicit deferred shells.
- Phase 17 fully owns the legal transition engine for core mutations and reserves clean seams for later callback/signal/expiry work.

**Why**
- Best roadmap discipline and lowest surprise while still leaving a complete command-core foundation.

### 4. Operator/runtime parity

**Options considered**
- One unified engine directly used by runtime and operators
- Shared transition core with thin operator wrappers
- Shared core plus async operator inbox
- Separate runtime and operator mutation engines

**Locked outcome**
- Use a shared transition core with thin operator-specific wrappers.
- Keep auth, preview/reason, read-only mode, and human audit concerns outside the low-level core.

**Why**
- Preserves one legal mutation path while keeping host-owned web concerns at the edges.

### 5. Legacy-row behavior during mutations

**Options considered**
- Reject all ambiguous legacy mutations
- Explicit compatibility adapters for a short named set only
- Upgrade-through-transition whitelist
- Full dual-runtime compatibility path

**Locked outcome**
- Default to explicit compatibility adapters for a short named set only if clearly necessary.
- Reject everything else rather than silently upgrading or reinterpreting old rows.

**Why**
- Best support-truth and upgrade-proof posture without forcing operators into magical behavior.

## Cross-Cutting Ecosystem Lessons Used

- Elixir/Oban pattern: keep correctness in Postgres-backed state transitions, not in PubSub wakeups or UI assumptions.
- Phoenix/Ecto pattern: plain function APIs over durable internals are easier to adopt and less surprising than framework-like public command DSLs.
- Sidekiq lesson: be explicit about at-least-once / best-effort edges and avoid pretending retries or uniqueness are perfect guarantees.
- Temporal lesson: centralize durable write paths and make impossible or unsupported transitions explicit rather than inferred.
- Admin/operator UX lesson: action permissions, reasons, and audit trails belong at the operator boundary, not buried in low-level runtime code.

## Repo-Local Guidance Carried Forward

- Shift recommendations left by default for this project and within GSD where possible.
- Treat prior context recommendations as locked defaults unless a later choice would materially affect public semantics, support truth, or maintainer burden.
- Keep Postgres as truth and PubSub as latency hint only.

## Deferred Follow-Ons Captured

- Public advanced command API if concrete host-app needs emerge later
- Async operator action inbox / approval queue for higher-risk flows
- Broader legacy compatibility runtime
- Full callback/signal/late-race semantics, which remain owned by later phases

