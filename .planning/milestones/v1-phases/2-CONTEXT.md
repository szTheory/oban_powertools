# Phase 2: Smart Engine Limits & Cron - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the first Powertools smart-engine primitives for safe cluster-wide throttling and scheduling:
global and partitioned limiters, explainable blocked-job state, and dynamic cron with explicit overlap and catch-up policies.

This phase is about durable backend semantics plus a narrow native operator surface for those semantics.
It is not a full replacement for generic job/queue admin screens.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Downstream agents should default to the recommendations in this document and use the agent's discretion for low-impact implementation details.
- **D-02:** Only surface follow-up questions when a choice materially changes runtime correctness, operator safety, data durability, or the user-visible semantics of limits/cron.

### Limiter Definition Model
- **D-03:** Use a hybrid model: code owns limiter bindings and partition extraction semantics; Postgres owns live limiter resources, mutable state, enable/disable, and operator overrides.
- **D-04:** Keep local queue concurrency in standard Oban queue config. Powertools Phase 2 owns global concurrency, partitioned concurrency, rate limiting, weights, and manual cooldowns.
- **D-05:** Worker-facing limiter configuration should be explicit and grep-able, attached to `use ObanPowertools.Worker` rather than hidden in UI-only records or dynamic code evaluation.
- **D-06:** Persist limiter resources separately from limiter state. Resource definitions are stable named records; partition/token/lease state is mutable runtime data.
- **D-07:** UI/API may edit persisted limiter resources and operator controls, but must not define arbitrary partition logic or runtime code. Partition extraction remains code-owned.
- **D-08:** Weight calculation must be derived from job args/meta only and remain pure/deterministic. No external I/O or ambient state in weight callbacks.
- **D-09:** Snapshot resolved limiter binding metadata onto queued jobs so later resource edits do not silently change the meaning of already-enqueued work.
- **D-10:** Manual cooldown is a first-class limiter capability for external `429` or quota responses and should be modeled as persisted limiter state, not an ad-hoc retry hack.

### Blocked-Job Behavior and `explain/1`
- **D-11:** `explain/1` must return a structured machine-readable contract, not ad-hoc English strings. Human-readable summaries are presentation, not the API contract.
- **D-12:** The outer explain contract should distinguish runnable vs blocked states, with blocked jobs returning an ordered list of blocker objects keyed by stable blocker codes.
- **D-13:** Each blocker should carry stable code, scope kind/id, summary, structured details, retry timing when applicable, and whether operator action is possible.
- **D-14:** Use a hybrid evidence model for blocked jobs: persist blocker snapshots when blocked state begins or materially changes, and recompute live explanations on demand for the current UI.
- **D-15:** Snapshots are historical evidence, not current truth. UI must distinguish “live now” from “snapshot at incident start / last change”.
- **D-16:** Low-cardinality telemetry should record blocker codes and coarse scope only. High-cardinality explanation evidence belongs in persisted snapshots and audit records, not metric labels.
- **D-17:** `explain/1` must be side-effect free. It may inspect state but must not mutate limiter, cron, or job records as part of explanation.

### Cron Scheduling Semantics
- **D-18:** Use a hybrid cron model with two explicit entry sources:
  `:code` entries synced from application config and `:runtime` entries owned in Postgres.
- **D-19:** Code-managed entries may be paused/resumed and manually triggered from the UI, but semantic edits to schedule, worker, args, timezone, overlap, or catch-up remain code-owned unless an entry is explicitly runtime-managed.
- **D-20:** Runtime-managed entries are fully persisted and operator-manageable without deploys.
- **D-21:** Every cron entry needs a stable unique name. Name collisions are treated as configuration errors, not silently merged.
- **D-22:** Persist a durable slot ledger keyed by `{entry_id, slot_at}` so scheduling guarantees, dedupe, missed-run detection, and auditability remain cluster-safe.
- **D-23:** Default cron overlap policy is `:queue_one`: when a slot fires during an active run, persist exactly one pending follow-up run rather than skipping all work or allowing unlimited overlap.
- **D-24:** Support additional explicit overlap policies for advanced use cases:
  `:skip` for freshness-only work,
  `:allow` for safe parallel work,
  and `:cancel_previous` only as an explicit sharp tool, not a default.
- **D-25:** Default catch-up policy is `:latest`: after downtime or missed slots, enqueue only the most recent missed occurrence by default.
- **D-26:** Support bounded replay for catch-up as an opt-in policy, e.g. a windowed/all-bounded mode. Do not allow unbounded backfill by default.
- **D-27:** Timezone is per-entry and must be explicit in persisted cron state. Policy changes to expression/timezone should clearly reset or invalidate prior guarantee windows rather than pretending continuity.

### Operator UX Scope for Phase 2
- **D-28:** Keep the existing hybrid shell direction from Phase 0: native Powertools pages for Powertools-owned concepts, with Oban Web as the bridge for generic jobs/queues when available.
- **D-29:** Native Phase 2 pages should be deliberately narrow:
  overview health cards,
  limiters page,
  cron page,
  and audit trail for limiter/cron/operator actions.
- **D-30:** Blocked-job detail should be explanation-first and deep-link to Oban Web for generic job inspection rather than rebuilding a full native jobs console in this phase.
- **D-31:** Phase 2 operator actions should stay minimal and safe:
  pause/resume cron entry,
  run-now when policy permits,
  inspect limiter state,
  and only narrowly scoped limiter unblock/clear actions if backend safety can be proven.
- **D-32:** All mutating native actions must follow “explain, then act”: preview impact, require actor/reason where appropriate, emit telemetry, and write audit events.
- **D-33:** Auth and access control should continue through the host-owned `ObanPowertools.Auth` behaviour and apply at both page and action level.

### Data/Telemetry/Audit Defaults
- **D-34:** Favor explicit Ecto schemas and `Ecto.Multi`-style transactions for slot claims, limiter reservations, state updates, and audit writes.
- **D-35:** Keep telemetry low-cardinality and operator-oriented. Metric/event labels should use stable resource type, action, blocker code, overlap policy, and coarse limiter kind rather than job IDs or raw partition values.
- **D-36:** Manual limiter actions, cron mutations, and bridge-originated Oban Web actions should converge into one normalized Powertools audit trail.

### Non-Goals for Phase 2
- **D-37:** Do not rebuild a full native generic jobs dashboard, queue charts, or bulk mutation UX in this phase.
- **D-38:** Do not introduce dynamic queues, scaler behavior, workflows, or lifeline repair features here except where future compatibility affects schema/explain contract design.
- **D-39:** Do not make the UI the sole source of truth for worker semantics, partition logic, or schedule semantics.
- **D-40:** Do not hide important policy differences behind implicit uniqueness or retry behavior. Overlap and catch-up must be explicit first-class concepts.

### the agent's Discretion
- Exact schema names and module boundaries, provided they preserve the durable resource/state split.
- Exact blocker ordering heuristics, provided primary blockers remain deterministic and operator-relevant.
- Exact LiveView layout, spacing, and copy, provided it stays explanation-first and consistent with the hybrid shell strategy.
- Internal algorithm choice between token-bucket/sliding-window variants where it does not contradict the product semantics locked above.

</decisions>

<specifics>
## Specific Ideas

- Favor a worker API shape that looks like `limits: [...]` on `use ObanPowertools.Worker`, because it matches the typed-worker direction from Phase 1 and keeps smart-engine participation explicit in code.
- Treat limiter resources as named durable objects and limiter state as separate per-partition runtime rows.
- Treat cron entries as either code-managed or runtime-managed, with visible source badges in the UI so operators are not surprised about what can be edited where.
- The cron page should show overlap policy, catch-up policy, timezone, last run, next run, missed runs, and whether an active run currently blocks a new slot.
- The limiters page should show limiter name, scope/partition policy summary, algorithm, current saturation, recent throttle/cooldown state, and sampled blocked-job explanations.
- The blocked-job UX should answer:
  what is happening,
  why it is blocked,
  when it may run again,
  and what is safe to do next.
- The audit trail should unify native Powertools actions and Oban Web bridge actions into one operator story.
- Preference from this discussion: shift defaults left in GSD/planning so downstream agents assume best-practice recommendations here unless a decision is truly impactful.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and project state
- `.planning/ROADMAP.md` — Phase 2 scope, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` — ENG-01, ENG-02, and ENG-03 requirements.
- `.planning/STATE.md` — current project posture and explicit anti-magic/operator-first constraints.

### Prior phase context
- `.planning/phases/0-CONTEXT.md` — Hybrid shell/bridge decision, host-owned auth, and low-cardinality telemetry posture.
- `.planning/phases/1-01-SUMMARY.md` — typed worker and enqueue-path patterns established in Phase 1.

### Product and research guidance
- `prompts/oban_powertools_context.md` — product posture, personas, domain language, and smart-engine vocabulary.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — hybrid UI strategy, explain-then-act UX, and Phase 2 UI scope direction.
- `prompts/oban-powertools-deep-research-original-prompt.md` — maintainer goals around DX, operator UX, ecosystem lessons, and principle-of-least-surprise expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/oban_powertools/worker.ex`: natural place to extend worker declarations with explicit `limits:` bindings and optional weight callbacks.
- `lib/oban_powertools/idempotency.ex`: existing `Ecto.Multi` enqueue path and conflict handling provide a pattern for atomic limiter reservations and cron slot claims.
- `lib/oban_powertools/telemetry.ex`: already establishes a Powertools-controlled low-cardinality telemetry boundary.
- `lib/oban_powertools/auth.ex`: host-owned behavior for page/action auth should remain the single source of truth for native Phase 2 actions.
- `lib/oban_powertools/web/router.ex`: existing bridge shell makes hybrid native-pages-plus-Oban-Web routing the path of least surprise.
- `lib/mix/tasks/oban_powertools.install.ex`: installer/migration generation pattern is already established for adding Phase 2 tables and host wiring.

### Established Patterns
- Typed worker arguments and explicit enqueue validation are already part of the public worker story.
- Durable Postgres-backed state is preferred over opaque in-memory or Redis-style coordination.
- Operator actions should be explicit, auditable, and safe by default.
- Low-cardinality telemetry with richer evidence in database tables is already a project-level principle.

### Integration Points
- Smart-engine semantics should plug into the existing worker API rather than introducing a separate parallel worker abstraction.
- Native Phase 2 pages should live inside the existing `/ops/jobs` shell and deep-link to Oban Web for generic job details/actions.
- Future phases for workflows and lifeline should be able to reuse the blocker/explain contract and audit/telemetry patterns established here.

</code_context>

<deferred>
## Deferred Ideas

- Full native replacement for generic Oban job/queue dashboards.
- Dynamic queues, scalers, and fairness pages beyond what is necessary to avoid painting Phase 2 into a corner.
- Workflow- and lifeline-specific blocker types beyond reserving room in the explain contract.
- Broad self-service editing of code-managed cron semantics from the UI.
- Advanced burst/fairness tuning and richer historical analytics once the core limiter/cron semantics are stable.

</deferred>

---

*Phase: 2-smart-engine-limits-cron*
*Context gathered: 2026-05-19*
