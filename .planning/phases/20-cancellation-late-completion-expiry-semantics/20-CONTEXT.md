# Phase 20: Cancellation, Late Completion & Expiry Semantics - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Make cancel, completion, expiry, dependency failure, and late-arrival races explainable and support-truthful.

This phase owns precedence rules, cancellation propagation, late completion/failure classification, and late evidence preservation on top of the await/signal and DB-first command core already locked in Phases 17-19.

This phase does not introduce a second orchestration engine, does not pivot the library into a full event-sourced workflow platform, does not add a broad multi-mode operator control surface, and does not move diagnosis/UI ownership ahead of Phase 21.

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Treat the recommendations in this context as locked defaults for downstream GSD planning and implementation. Do not reopen them unless a later choice would materially change public semantics, support truth, upgrade safety, or maintainer burden.
- **D-02:** Shift strong recommendations left within GSD for this project. Prefer decisive defaults over interactive re-litigation except for unusually high-impact product calls the user is likely to care about directly.
- **D-03:** Keep Postgres-backed rows as the only correctness-bearing truth source. PubSub, coordinator wakeups, notifier paths, and LiveView refreshes remain advisory only.
- **D-04:** Preserve Powertools' Phoenix/Ecto posture: explicit context functions, DB-first `Ecto.Multi` writes, bounded cause vocabulary, append-only evidence where needed, and operator/support semantics that follow the principle of least surprise.

### Race Precedence Model
- **D-05:** Use one canonical outcome reducer with a request/evidence/outcome split rather than a first-write-wins rule or a cancel-always-wins rule.
- **D-06:** `cancel_requested_at` is durable request evidence, not automatically the final workflow outcome.
- **D-07:** Final workflow and step outcomes must reduce from durable step facts after reconciliation, not from PubSub timing, process timing, or which subsystem observed the race first.
- **D-08:** Wait expiry remains authoritative once reconciled. A signal may satisfy only an active non-expired await; after expiry is finalized, later signals are evidence only.
- **D-09:** Dependency failure remains branch-local and edge-policy-local. Do not introduce a global “failure always wins” rule that erases edge semantics already expressed by `cancel` versus `continue`.
- **D-10:** The reducer should preserve the existing and now-locked semantic that successful work finishing after a cancel request is represented explicitly as `completed_after_cancel_request` rather than being rewritten to plain `cancelled`.

### Cancellation Propagation
- **D-11:** Cancellation is eager for idle work and cooperative for in-flight work.
- **D-12:** `pending`, `available`, and `awaiting_signal` steps should be cancelled immediately when a workflow cancel request is accepted.
- **D-13:** `retryable` steps should be cancelled immediately only when they represent queued future retry work rather than actively executing leased work. If that state becomes ambiguous later, split it before broadening semantics.
- **D-14:** `executing` and `running` steps should not be force-reclassified to terminal cancel outcomes at request time. Stamp cancel intent durably, keep the workflow in `cancel_requested` while outcome is unsettled, and let the real step result determine the terminal truth.
- **D-15:** Suppress new downstream scheduling after cancel request except where a downstream step is already durably entitled to proceed under existing branch semantics.
- **D-16:** If all surviving work ends through cancellation paths, the workflow terminal cause should remain `operator_cancelled`.
- **D-17:** If in-flight work succeeds after cancel request, preserve `completed_after_cancel_request` at the step level and project that to the workflow when all surviving work ultimately succeeds.
- **D-18:** If in-flight work fails after cancel request, do not collapse that to plain `step_failed`. Introduce explicit durable causes for the post-cancel failure path so support can distinguish ordinary failure from failure-after-cancel.

### Late Evidence Policy
- **D-19:** Preserve terminal truth once a workflow or step is terminal. Do not rewrite terminal workflow/step meaning when later evidence arrives.
- **D-20:** Preserve late arrivals as evidence rather than discarding them. This includes late signals, late completions, late failures, duplicate post-terminal arrivals, and callback-delivery failures that occur after workflow truth is already committed.
- **D-21:** Use a hybrid evidence model: canonical workflow/step rows stay authoritative for outcome, while append-only evidence rows capture late or duplicate arrivals when canonical rows alone would collapse meaningful support history.
- **D-22:** Prefer typed late-evidence classifications over opaque metadata. The bounded vocabulary should cover at least: late signal after expiry, late signal after cancellation, late completion after cancel request, late failure after cancel request, and post-terminal duplicate arrival.
- **D-23:** Continue to reuse existing typed evidence surfaces where they already fit, especially `SignalRecord` and `CommandAttempt`, and add new append-only evidence only where current rows collapse distinct post-terminal facts that Phase 21/22 UI and Lifeline will need to explain.

### Diagnosis, Callback, And UX Posture
- **D-24:** Diagnosis must present terminal truth before lingering request evidence. Once a workflow or step is terminal, UI and explainability layers must not keep showing generic `cancel_requested` if a more specific final outcome is known.
- **D-25:** Keep callback semantics narrow and honest. `workflow.terminal` should describe the true final state plus terminal cause, including post-cancel outcomes, rather than pretending the cancel request itself “won.”
- **D-26:** Native workflow and Lifeline surfaces should eventually be able to render concise operator-facing narratives such as “cancel requested, then step completed” or “wait expired, then signal arrived late” without requiring database spelunking.
- **D-27:** Documentation and support-truth copy should explicitly say that cancel is immediate for idle/waiting work and cooperative for in-flight work.

### Ecosystem Lessons To Carry Forward
- **D-28:** Borrow the good part of mature orchestrators: make waits and signals durable facts first, keep timeouts explicit, keep request-versus-outcome visible, and preserve successful prior work during later recovery work.
- **D-29:** Avoid the common footguns seen across orchestration systems: hard-abort semantics that over-promise, global failure rules that erase local dependency policy, terminal-state rewriting based on later arrivals, and UI states that require tribal knowledge to interpret.
- **D-30:** Do not add a broad “stop vs terminate” public control surface in this phase. That is a plausible future follow-on, but it widens semantics and operator burden before the single cancel contract is fully hardened.

### the agent's Discretion
- Exact terminal-cause strings for late failure and late-arrival categories, as long as the vocabulary stays bounded, support-truthful, and coherent with existing `completed_after_cancel_request` / `expired_wait` naming.
- Whether new late-evidence rows are modeled through a widened `CommandAttempt` posture, a new narrowly scoped evidence table, or a combination, as long as canonical workflow/step truth remains separate from append-only evidence.
- Exact reducer decomposition inside the runtime, provided there is one canonical implementation used by reconciliation, diagnosis, and callback emission rather than duplicated precedence logic.

</decisions>

<specifics>
## Specific Ideas

- The right mental model for Phase 20 is `request -> evidence -> outcome`, not “who won the race first.”
- Preserve the repo’s current good instinct: facts first, support-truthful second-order interpretation after that.
- Mature systems point in the same direction even when their APIs differ:
  - Waits and callbacks need explicit timeout/deadline semantics.
  - In-flight work may still finish after cancellation is requested.
  - Late or duplicate arrivals should be preserved as evidence, not hidden.
  - Recovery should preserve prior successful work whenever possible.
- If a future phase adds a stronger operator verb than cancel, it should be a separately named action with separately documented semantics rather than an overloaded cancel contract.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone framing
- `.planning/ROADMAP.md` — Phase 20 goal, dependency chain, and ownership boundary for cancellation/late-arrival semantics.
- `.planning/milestones/v1.2-ROADMAP.md` — active v1.2 sequence and the planned focus for precedence and explainability work.
- `.planning/PROJECT.md` — active milestone posture, Postgres-first truth model, support-truth framing, and current repo-wide constraints.
- `.planning/REQUIREMENTS.md` — `REC-03`, `SIG-03`, `DIA-01`, `VER-01`, `VER-02`, proof posture, and support-truth rules that constrain this phase.

### Prior locked decisions
- `.planning/phases/16-semantics-contract-cause-vocabulary-compatibility-baseline/16-CONTEXT.md` — semantics version baseline, durable cause vocabulary, and compatibility posture.
- `.planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md` — one legal DB-first mutation path, operator/runtime parity, rejection evidence, and narrow public API posture.
- `.planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md` — narrow callback contract, post-commit delivery semantics, and recovery evidence posture.
- `.planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md` — workflow-scoped signal authority, one active await per step, expiry authority, and durable late-signal posture.

### Research and architectural guidance
- `.planning/research/SUMMARY.md` — milestone-level recommendation for explicit command/semantics separation, cooperative cancellation, durable waits/signals, and race-path proof.
- `.planning/research/ARCHITECTURE.md` — DB-first command/semantics layering, facts-first persistence, and anti-patterns to avoid.
- `.planning/research/PITFALLS.md` — specific warnings about treating cancellation as immediate finality, underspecifying late arrivals, and using time-based diagnosis without causal evidence.
- `prompts/oban_powertools_context.md` — domain language, personas, product posture, and support-truth framing.
- `prompts/oban-powertools-deep-research-original-prompt.md` — project-wide emphasis on coherent recommendations, DX, lessons learned, and idiomatic Elixir architecture.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — native operator-surface expectations and the need for explicit cause/evidence/allowed next action in Powertools-owned UI.

### Current implementation surfaces
- `lib/oban_powertools/workflow.ex` — stable public workflow API seam that should remain the paved road.
- `lib/oban_powertools/workflow/runtime.ex` — current cancellation, completion, await/signal, reconciliation, callback, and diagnosis logic that Phase 20 should harden and centralize.
- `lib/oban_powertools/workflow/workflow.ex` — workflow summary counters and terminal/request fields that anchor durable workflow truth.
- `lib/oban_powertools/workflow/step.ex` — step state, blocker, await, and cancel metadata that anchor durable step truth.
- `lib/oban_powertools/workflow/await.ex` — durable await contract baseline.
- `lib/oban_powertools/workflow/signal_record.ex` — durable signal fact baseline and current late-signal posture.
- `lib/oban_powertools/workflow/command_attempt.ex` — durable mutation/arrival evidence baseline.
- `test/oban_powertools/workflow_runtime_test.exs` — current proof lane for expiry, late signal, cancel-versus-complete race, and command evidence.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Workflow.Runtime` already has the beginnings of the right contract: idle work is cancelled eagerly, in-flight work may still complete, expired waits stay explicit, and late signals are preserved instead of reopening terminal truth.
- `SignalRecord` and `CommandAttempt` already provide durable, typed evidence seams that can likely absorb part of the late-evidence burden without forcing an architecture pivot.
- `Workflow` and `Step` rows already carry enough request/outcome metadata to support a clearer reducer and diagnosis projector without replacing the whole state model.
- Existing callback outbox logic already separates workflow truth commit from host callback delivery, which Phase 20 can preserve while broadening terminal-cause accuracy.

### Established Patterns
- Repo-wide workflow mutations already prefer DB-first `Ecto.Multi` transactions plus reconciliation over process-local truth.
- Public APIs stay context-like and explicit rather than exposing generic orchestration internals.
- Native operator surfaces are expected to be explainable from durable evidence and to avoid invented semantics in the UI layer.
- Prior phases consistently favor bounded explicit vocabularies over highly configurable policy matrices when broader surfaces would increase semver and support burden.

### Integration Points
- Phase 20’s reducer and late-evidence model will feed directly into Phase 21 workflow diagnosis projection and the native workflow UI.
- Phase 22 Lifeline integration should consume the same terminal-cause and late-evidence vocabulary rather than inventing a second repair/diagnosis language.
- Phase 23 verification and upgrade-proof work will depend on Phase 20 defining crisp race-path semantics and stable callback/support wording.

</code_context>

<deferred>
## Deferred Ideas

- Add a separate stronger operator verb such as `terminate` or `abort_now` with semantics distinct from cooperative cancel — valuable later, but too much support-surface expansion for Phase 20.
- Full event-sourced workflow history and projection architecture — overbuilt for the current Powertools posture and not necessary to achieve support-truthful race handling.
- Multi-wait fan-in, broad callback policy matrices, or generic workflow event-bus semantics — explicitly outside this phase’s boundary.

</deferred>

---

*Phase: 20-cancellation-late-completion-expiry-semantics*
*Context gathered: 2026-05-24*
