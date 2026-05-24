# Phase 19: Await Registration, Signal Facts & Expiry Authority - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Persist durable wait and signal truth so waiting survives restarts, signal arrival timing is reconciled idempotently from Postgres-backed facts, and wait expiry is finalized through one authoritative DB-first path.

This phase owns await registration shape, signal fact ingestion/matching, dedupe/replay posture, and expiry authority for waits.

This phase does not broaden Powertools into a generic event bus, does not add advanced multi-wait fan-in semantics on a single step, does not reopen the DB-first command-core decisions from Phase 17, and does not fully settle every cancel/completion/late-arrival precedence question that belongs to Phase 20.

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Treat the recommendations in this context as locked defaults for downstream GSD planning and implementation. Do not reopen them unless a later choice would materially change public semantics, support truth, upgrade safety, or maintainer burden.
- **D-02:** Shift preference-left within GSD for this phase and adjacent workflow work. Prefer decisive defaults over re-asking unless a choice is truly high-impact and user-visible.
- **D-03:** Keep Postgres rows as the only correctness-bearing truth source. PubSub, notifier wakeups, workers, and UI refreshes remain advisory only.
- **D-04:** Keep the public API narrow and Phoenix/Ecto-idiomatic. Richer orchestration mechanics may exist internally, but Powertools should still feel like a context library rather than a new workflow platform.

### Signal Routing Contract
- **D-05:** Use a hybrid scoped signal contract. Accept external/business correlation data at ingress, but require the runtime to resolve and persist explicit `workflow_id` authority before a signal may wake a wait.
- **D-06:** Final matching authority is workflow-scoped, not correlation-only. Correlation keys remain part of the durable contract, but ambiguous correlation-only signals must stay unmatched durable facts rather than waking a wait speculatively.
- **D-07:** Keep `signal_name` + correlation identity as the external/business lookup seam, but treat resolved `workflow_id` as the correctness-bearing target scope for durable wait satisfaction.
- **D-08:** If deterministic resolution cannot be made from durable state, preserve the signal as durable unmatched evidence with an explicit status or diagnosis rather than guessing.

### Active Wait Shape
- **D-09:** Phase 19 owns exactly one active await per step as the supported contract.
- **D-10:** Keep `workflow_awaits` as the detailed truth store for wait semantics. Mirror only a thin operator-facing summary onto `workflow_steps` for diagnosis and UI.
- **D-11:** The step-row mirror may include fields close to diagnosis needs such as signal name, correlation key, dedupe key, deadline, and optionally an `active_await_id` pointer. Resolution policy, resolved linkage, and wait history belong in await rows.
- **D-12:** Do not introduce multi-wait fan-in or aggregate `wait_any` / `wait_all` semantics on a single step in Phase 19. That expands race, expiry, and operator-explanation complexity too early.

### Signal Dedupe And Replay Posture
- **D-13:** Treat one canonical signal fact row as the semantic signal identity, keyed by durable signal identity such as `signal_name + correlation scope + dedupe_key`.
- **D-14:** Preserve duplicate or replay attempts as separate durable evidence instead of rewriting the canonical signal fact or pretending exactly-once delivery.
- **D-15:** Preferred operator-facing signal truth is explicit and narrow: canonical signal facts progress through states such as `recorded`, `consumed`, or `late`; duplicate, replayed, unmatched, and already-consumed attempts are explained through linked evidence and diagnosis, not destructive upserts.
- **D-16:** Keep the contract support-truthful and at-least-once. Do not promise exactly-once signal delivery or exactly-once wake behavior.

### Expiry Authority
- **D-17:** Use a single authoritative DB-first reconciliation path to finalize wait expiry and its downstream workflow/step truth.
- **D-18:** Sweepers, scheduled jobs, or notifier wakeups may discover due waits and trigger reconciliation, but they must not own expiry semantics independently from the shared reconcile path.
- **D-19:** Collapse split-authority shortcuts over time. Signal ingress may record that an arrival is late relative to durable state, but the legal expiry outcome itself must come from the shared reconciliation authority.
- **D-20:** Keep expiry idempotent, replayable, and explainable from durable rows alone. Operators should not need tribal knowledge about which subsystem “won the race.”

### Operator And DX Posture
- **D-21:** Bias the design toward support truth and least surprise over maximal flexibility. A maintainer should be able to explain, from rows alone, what signal arrived, which wait it matched or failed to match, why a wait expired, and what evidence exists for duplicates or late arrivals.
- **D-22:** Preserve the current Phoenix/Ecto ergonomics: explicit context functions, narrow changesets, unique constraints for correctness, `Ecto.Multi` for grouped writes, and bounded statuses rather than opaque metadata blobs.
- **D-23:** Keep future operator UX in mind now. Native workflow screens should later be able to show “waiting on signal,” “signal recorded but unmatched,” “wait expired,” “duplicate signal ignored,” and “late signal preserved as evidence” without inventing semantics in the UI layer.

### the agent's Discretion
- Exact status atom/string vocabulary for unmatched, ambiguous, duplicate, replayed, and already-consumed signal evidence, as long as the overall contract stays narrow and support-truthful.
- Whether duplicate/replay evidence is modeled through a dedicated ingress/evidence schema or through stronger use of the existing command-attempt ledger, as long as canonical signal truth is not destructively rewritten.
- Exact pointer/projection shape from `workflow_steps` to the active await row, provided the step row remains a thin mirror and not the primary wait truth store.
- Exact worker/query shape for due-wait discovery, provided expiry authority still routes through the shared reconciliation path.

</decisions>

<specifics>
## Specific Ideas

- The right shape here is closer to Temporal/Azure/Step Functions durable waiting discipline than to a loose event bus: persist facts first, resolve deterministically, and never guess across ambiguity.
- Keep external ergonomics good for Phoenix webhook/controller entrypoints: hosts may naturally know business correlation keys first, but Powertools should resolve that into explicit workflow-target truth before waking a wait.
- Treat signals like Stripe-style thin durable events rather than rich snapshots. Richer context should stay fetchable by durable IDs.
- Favor a model where operators can eventually see “signal received, still unmatched” or “late after expiry” as first-class evidence rather than hidden edge cases.
- If future workflow design truly needs multi-wait fan-in on one logical step, introduce it later as an explicit contract rather than smuggling it into Phase 19.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone framing
- `.planning/ROADMAP.md` — Phase 19 goal, dependency chain, and current ownership boundary.
- `.planning/milestones/v1.2-ROADMAP.md` — active v1.2 sequence and the milestone’s planned focus for await/signal/expiry work.
- `.planning/PROJECT.md` — active milestone posture, Postgres-first truth model, and repo-wide support-truth constraints.
- `.planning/REQUIREMENTS.md` — `SIG-01`, `SIG-02`, `SIG-03`, `VER-01`, the proof posture gate, and support-truth rules that constrain this phase.

### Prior locked decisions
- `.planning/phases/16-semantics-contract-cause-vocabulary-compatibility-baseline/16-CONTEXT.md` — semantics version baseline, durable cause vocabulary, and compatibility posture.
- `.planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md` — one legal DB-first mutation path, operator/runtime parity, and durable rejection evidence.
- `.planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md` — narrow callback contract, step-targeted recovery evidence, and the locked preference to keep workflow semantics support-truthful and explicit.

### Research and architecture guidance
- `.planning/research/SUMMARY.md` — milestone-level recommendation for durable await/signal semantics, dedupe, deadlines, and a single reconciliation authority.
- `.planning/research/ARCHITECTURE.md` — DB-first commands/semantics layering, facts-first persistence, and anti-patterns to avoid.
- `.planning/research/FEATURES.md` — table-stakes expectations for durable waits, timeout semantics, cancellation posture, and diagnosis.
- `.planning/research/PITFALLS.md` — explicit warnings about infinite waits, unkeyed signals, split expiry authority, and ambiguous cancellation/late-arrival semantics.
- `.planning/research/STACK.md` — Postgres-native runtime guidance, due-row scanning, notifier use, and lock-aware concurrency patterns.

### Product posture and prompt guidance
- `prompts/oban_powertools_context.md` — product posture, domain language, personas, and support-truth framing relevant to workflow semantics.
- `prompts/oban-powertools-deep-research-original-prompt.md` — maintainer intent around batteries-included DX, OSS positioning, and lessons-learned product design.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — native operator UX posture and the expectation that Powertools-owned semantics remain explainable in its own surfaces.

### Current implementation surfaces
- `lib/oban_powertools/workflow.ex` — current public API seam that should remain the paved road.
- `lib/oban_powertools/workflow/runtime.ex` — current await registration, signal ingestion, reconcile, and expiry behavior to harden and narrow.
- `lib/oban_powertools/workflow/await.ex` — durable await schema baseline.
- `lib/oban_powertools/workflow/signal_record.ex` — durable signal fact schema baseline.
- `lib/oban_powertools/workflow/step.ex` — step-level wait mirror fields and diagnosis-facing projection seam.
- `test/oban_powertools/workflow_runtime_test.exs` — current proof lane for pre-await signal consumption, expired waits, late signals, and v1.2 workflow semantics.
- `lib/mix/tasks/oban_powertools.install.ex` — installer-owned schema contract for waits, signals, and command evidence.
- `test/support/migrations/2_phase_3_tables.exs` — test migration mirror for workflow semantics tables and indexes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Workflow` already provides the stable public seam for `await_step/4` and `deliver_signal/2`; Phase 19 should preserve that paved road rather than widening the public API into a generic signal bus.
- `ObanPowertools.Workflow.Runtime` already has working baselines for pre-await signal storage, await registration, expiry-on-reconcile, and late-signal marking. This gives Phase 19 a concrete starting point rather than a greenfield design.
- `Await`, `SignalRecord`, and step-level wait mirror fields already exist, which reduces schema churn and supports an incremental narrowing toward a better contract.
- `CommandAttempt` already exists as durable mutation evidence and may be reusable for duplicate/replay signal evidence if that keeps the contract narrow and explicit.

### Established Patterns
- Repo-wide workflow mutation posture is DB-first `Ecto.Multi` plus reconciliation, with Postgres rows as the only correctness-bearing truth source.
- Public surfaces stay context-like and explicit rather than exposing raw orchestration structs or internals.
- Native operator surfaces and later diagnosis work are expected to consume durable evidence, not infer meaning from transient coordinator state.
- Prior phases consistently prefer narrow explicit contracts over broad configuration matrices when a larger surface would increase semver and support burden.

### Integration Points
- Signal ingress and await resolution must continue to re-enter the shared workflow command/reconcile path introduced by Phase 17.
- Phase 20 will build on this phase’s wait/signal evidence to define broader late-arrival, cancel, completion, and expiry precedence rules.
- Phase 21 native workflow diagnosis should be able to consume the statuses and evidence created here without schema repainting.
- Future Lifeline and native workflow actions should be able to inspect and mutate through the same durable evidence model rather than inventing a second recovery surface.

</code_context>

<deferred>
## Deferred Ideas

- Multiple concurrent awaits on one logical step, including `wait_any` / `wait_all` fan-in semantics — defer until the project intentionally broadens the workflow contract beyond the narrow Phase 19 surface.
- A full append-only signal ingress ledger with replay tooling and richer event-history UX — valuable later if replay/audit tooling becomes a first-class product bet, but broader than this phase needs.
- Broader late-arrival, cancel-versus-signal, and completion-versus-expiry precedence rules — Phase 20 ownership.
- Generic event-bus or webhook-platform semantics — explicitly out of scope for v1.2.

</deferred>

---

*Phase: 19-await-registration-signal-facts-expiry-authority*
*Context gathered: 2026-05-24*
