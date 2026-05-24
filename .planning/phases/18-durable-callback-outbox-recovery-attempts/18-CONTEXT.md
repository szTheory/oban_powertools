# Phase 18: Durable Callback Outbox & Recovery Attempts - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Make workflow callbacks and recovery attempts survive crashes, retries, and operator re-entry.

This phase adds a durable post-commit callback outbox for narrow workflow lifecycle events, strengthens recovery-attempt evidence so successful prior side effects stay preserved, and keeps callback/recovery semantics support-truthful under retries and host-app failures.

This phase does not broaden the contract into a generic event bus, does not add per-step callback policies, does not redefine workflow terminal truth around callback delivery, and does not take ownership of await/signal/expiry semantics that belong to later phases.

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Shift recommendation defaults left for this phase and downstream GSD planning. Treat the decisions below as locked defaults unless a later change would materially affect public semantics, support truth, or maintainer burden.
- **D-02:** Keep Postgres-backed workflow rows as the sole correctness-bearing truth source. Callback delivery, PubSub, and UI refresh remain separate from workflow state truth.
- **D-03:** Favor narrow, explicit library contracts over configurable policy matrices when the broader surface would increase semver and support burden without proving milestone value.

### Callback Event Surface
- **D-04:** Phase 18 should support exactly two workflow-scoped callback events: `workflow.terminal` and `workflow.recovery_completed`.
- **D-05:** `workflow.terminal` is the single terminal event for `completed`, `failed`, `cancelled`, and `expired` outcomes. Hosts branch on durable payload fields such as `state` and `terminal_cause` instead of relying on four separate event names.
- **D-06:** Do not add per-step callbacks, callback policy matrices, or broader workflow event families in Phase 18. Those expand the product toward a generic event bus and are explicitly deferred.

### Callback Payload Contract
- **D-07:** Callback payloads should use one thin, versioned event envelope with stable IDs and durable semantic fields only.
- **D-08:** The envelope should carry stable callback identity and routing data such as `event_id` or dedupe identity, `event`, `workflow_id`, `semantics_version`, and `occurred_at`.
- **D-09:** `workflow.terminal` payloads should include only durable terminal semantics needed by host handlers: `state`, `terminal_cause`, `cancel_requested_at`, and `finished_at`.
- **D-10:** `workflow.recovery_completed` payloads should include only durable recovery semantics needed by host handlers: `recovery_attempt_id`, `step_id`, `step_name`, `action`, `reason`, and workflow identity/version fields.
- **D-11:** Do not embed workflow context, full step trees, result payloads, arbitrary host metadata, or rich snapshots in callback payloads. Richer information should stay fetchable by ID from durable rows.

### Callback Delivery Semantics
- **D-12:** Workflow truth commits first. Callback delivery is a separate durable obligation and must never gate or roll back workflow terminal truth.
- **D-13:** The public callback contract must be documented as post-commit and at-least-once. Host handlers are required to be idempotent.
- **D-14:** Callback delivery failure should be preserved as separate durable evidence in the outbox and exposed later as operator-visible diagnosis, not collapsed into workflow failure semantics.
- **D-15:** The dispatcher should lease callback rows with Postgres-safe concurrency controls rather than scanning deliverable rows without ownership. Use a `SKIP LOCKED`-style claim or equivalent row-leasing pattern so multiple nodes do not deliver the same callback concurrently.
- **D-16:** Handler exceptions must be captured and recorded as failed delivery attempts. Do not allow raised exceptions to bypass failure accounting or leave delivery state ambiguous.

### Recovery Attempt Modeling
- **D-17:** Keep recovery truth step-targeted so already-successful side effects stay preserved and only explicit unsuccessful or operator-selected work is reopened.
- **D-18:** Add a workflow-level recovery session header for the operator/runtime intent, then link append-only per-step recovery attempt rows to that session.
- **D-19:** The recovery session is the UX/audit header for one recovery action. Per-step recovery attempt rows remain the durable truth of what actually changed.
- **D-20:** Keep the public API paved road step-oriented for now. It may create or attach a recovery session under the hood without exposing a broad workflow-redrive API surface yet.
- **D-21:** Avoid a generic event-sourced recovery history in Phase 18. Use typed, queryable columns for the session and attempt model, and keep `metadata` and snapshot maps as bounded overflow rather than the primary query surface.

### Queryability, Auditability, And DX
- **D-22:** Callback and recovery rows should be queryable by durable typed fields first, not by digging through opaque metadata blobs.
- **D-23:** Host callback handling should stay idiomatic Elixir: one behaviour callback, one map envelope, explicit branching on `event` plus durable semantic fields, and a documented “fetch richer details by ID” path.
- **D-24:** Native workflow and Lifeline surfaces should eventually render callback delivery status separately from workflow terminal cause. The data model created here must make that separation explicit.
- **D-25:** Docs and tests should emphasize least surprise: callbacks are notifications about committed workflow truth, not exactly-once transactional extensions of the workflow state machine.

### the agent's Discretion
- Exact module names for the callback dispatcher, leasing helper, and recovery session schema.
- Exact envelope key names for stable callback identity, as long as the contract stays thin and versioned.
- Exact retry/backoff schedule for callback redelivery, provided it remains durable and support-truthful.
- Exact split between recovery session fields and per-attempt snapshot fields, provided typed columns remain the primary query path.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone framing
- `.planning/ROADMAP.md` — Phase 18 goal, dependency chain, and ownership boundary for callback outbox and recovery attempts.
- `.planning/milestones/v1.2-ROADMAP.md` — active v1.2 phase sequence and the planned focus for Phase 18.
- `.planning/PROJECT.md` — active milestone posture, Postgres-first truth model, and support-truth constraints.
- `.planning/REQUIREMENTS.md` — `REC-01`, `REC-02`, `REC-03`, `POL-04`, proof posture, packaging ledger, and support truth gate for callbacks and recovery.

### Prior locked decisions
- `.planning/phases/16-semantics-contract-cause-vocabulary-compatibility-baseline/16-CONTEXT.md` — semantics version baseline, durable cause vocabulary, and compatibility posture that callback payloads must respect.
- `.planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md` — DB-first transition core, durable rejection evidence, operator/runtime parity, and the locked preference to keep public surfaces narrow.
- `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md` — prior project-level preference to shift strong recommendations left.
- `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md` — locked preference to treat recommendations as defaults unless public support truth or maintainer burden changes materially.

### Research and architectural guidance
- `.planning/research/ARCHITECTURE.md` — DB-first architecture guidance, command/semantics layering, and durable outbox patterns.
- `.planning/research/STACK.md` — recommended callback outbox design, concurrency primitives such as `FOR UPDATE SKIP LOCKED`, and alternatives to avoid.
- `.planning/research/FEATURES.md` — milestone-level recommendation for narrow callback semantics, recovery-safe retries, and deferred callback policy expansion.
- `.planning/research/PITFALLS.md` — callback/recovery footguns: execution-hook confusion, PubSub as truth, re-running successful side effects, and support-truth overpromises.

### Product posture and prompt research
- `prompts/oban_powertools_context.md` — product posture, callback footguns, workflow lifecycle guidance, and scriptable API/UI design rules.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — native operator UX posture, callback/batch positioning, and host-owned support expectations.

### Existing implementation surfaces
- `lib/oban_powertools/workflow.ex` — current public workflow API seam that Phase 18 should preserve as the paved road.
- `lib/oban_powertools/workflow/runtime.ex` — current callback enqueueing, recovery attempt writes, and callback dispatch logic to harden in Phase 18.
- `lib/oban_powertools/workflow/callback_outbox.ex` — durable outbox schema baseline.
- `lib/oban_powertools/workflow/recovery_attempt.ex` — durable per-step recovery evidence baseline.
- `lib/oban_powertools/workflow/callback_handler.ex` — host callback behaviour contract.
- `lib/oban_powertools/runtime_config.ex` — required host callback handler config seam.
- `test/oban_powertools/workflow_runtime_test.exs` — existing proof lane for terminal callbacks and step recovery evidence.
- `lib/mix/tasks/oban_powertools.install.ex` — installer-owned schema contract for callback outbox and recovery attempts.
- `test/support/migrations/2_phase_3_tables.exs` — test migration mirror of the runtime schema contract.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Workflow` already provides a stable public API seam; Phase 18 should preserve that paved road while hardening internals underneath it.
- `ObanPowertools.Workflow.Runtime` already writes `workflow.terminal` and `workflow.recovery_completed` outbox rows plus step recovery attempt rows, which gives Phase 18 a concrete baseline instead of a greenfield design.
- `ObanPowertools.Workflow.CallbackOutbox` and `ObanPowertools.Workflow.RecoveryAttempt` already exist as durable schemas, so Phase 18 can evolve rather than replace them.
- `ObanPowertools.RuntimeConfig.workflow_callback_handler!/1` and `ObanPowertools.Workflow.CallbackHandler` already define the host wiring seam for callback delivery.

### Established Patterns
- Repo-wide pattern is DB-first `Ecto.Multi` mutation paths with Postgres truth as the system of record.
- Public APIs stay narrow and context-like while complex legality or orchestration details remain internal.
- Native operator flows separate durable domain legality from auth/read-only/audit UX concerns.
- Prior phases consistently avoid broadening support claims until durable proof exists; Phase 18 should keep the callback contract equally narrow and explicit.

### Integration Points
- Callback outbox writes should stay inside the shared workflow command/transition transaction after durable workflow truth is established.
- Callback dispatch should become a separately owned delivery path with row leasing, failure accounting, and retry semantics that can be surfaced later in native workflow and Lifeline views.
- Recovery session headers must fit the Phase 17 command pipeline and preserve the existing step-oriented `recover_step` paved road.
- Later phases for await/signal/expiry, diagnosis, and native workflow actions should be able to consume the same callback and recovery evidence model without schema repainting.

</code_context>

<specifics>
## Specific Ideas

- Use a CloudEvents-like discipline for the callback envelope shape without turning Powertools into a general event platform: stable ID, type, time, and durable semantic fields first.
- Treat callback delivery like Stripe-style thin events, not rich snapshots: hosts fetch richer workflow or recovery data by ID when needed.
- Treat recovery like Step Functions redrive in spirit: preserve successful prior work, append new durable recovery evidence, and reopen only the specific work that needs it.
- Preserve an explicit distinction between workflow outcome and callback delivery posture so future UI can say “workflow completed, callback retrying” instead of inventing a fake workflow failure.
- Keep the API and docs aligned with least surprise for Phoenix/Ecto users: one behaviour callback, explicit maps, idempotent handlers, no invisible exactly-once promise.

</specifics>

<deferred>
## Deferred Ideas

- Per-step callback hooks or a broader callback policy matrix — defer until the workflow semantics contract is more mature and the project is ready to own the larger semver/support surface.
- Rich snapshot callback payloads or host-custom payload builders — defer unless a later milestone intentionally broadens Powertools into a larger integration/event surface.
- A generic event-sourced workflow history or full redrive event ledger — defer; too much contract expansion for Phase 18.
- Callback-delivery-gated workflow success or required-ack callback modes — defer unless the project explicitly chooses stronger saga-like semantics later.

</deferred>

---

*Phase: 18-durable-callback-outbox-recovery-attempts*
*Context gathered: 2026-05-24*
