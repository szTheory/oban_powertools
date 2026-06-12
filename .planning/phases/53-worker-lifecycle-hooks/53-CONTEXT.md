# Phase 53: Worker Lifecycle Hooks - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 53 adds worker-local lifecycle hooks to `ObanPowertools.Worker`: `on_start/1`, `on_success/2`, `on_failure/2`, and `on_discard/2`. Hooks are observe-only, crash-caught, optional via no-op `defoverridable` defaults, and visible through a minimal low-cardinality `:worker_hook` telemetry family.

This phase establishes the execution wrapper seam that later v1.7 phases extend for `deadline:`, `timeout:`, output recording, and at-rest redaction. It does not add global hook registries, hook-based short-circuiting, operator/Lifeline discard hooks, output persistence, deadline enforcement, or redaction behavior.

</domain>

<decisions>
## Implementation Decisions

### Lifecycle Semantics
- **D-01:** Hook dispatch is state-transition-oriented, not event fan-out. A single post-execution hook fires for a given process outcome.
- **D-02:** `on_start/1` fires after Powertools args validation/casting and before `process/1`. It receives the typed `%Oban.Job{}` that `process/1` will receive.
- **D-03:** `:ok` and `{:ok, value}` route to `on_success/2`.
- **D-04:** Retry-eligible `{:error, reason}` returns and rescued/caught process failures route to `on_failure/2`.
- **D-05:** Final-attempt `{:error, reason}` returns and final-attempt raised/caught failures route to `on_discard/2` only. Do not dual-fire `on_failure/2` and `on_discard/2`; that creates duplicate alerts and side effects.
- **D-06:** `:discard` and `{:discard, reason}` route to `on_discard/2`.
- **D-07:** `{:cancel, reason}` remains Oban `cancelled` semantics and does not route to `on_failure/2` or `on_discard/2` in Phase 53. If Powertools needs cancellation callbacks, that is a future explicit `on_cancel/2` decision or handled through Oban job telemetry, not by overloading discard.
- **D-08:** Timeout kills may bypass wrapper-level failure hooks because Oban uses BEAM exit timers around `perform/1`. Timeout observability belongs to Oban `[:oban, :job, :exception]` telemetry and future docs, not `on_failure/2`.
- **D-09:** Operator-initiated Lifeline discards do not fire worker execution hooks. They are already audited through the Lifeline repair pipeline and are not in this phase.

### Callback Payload Shape
- **D-10:** `on_start/1` receives only the typed `%Oban.Job{}`.
- **D-11:** Post hooks use a small event envelope map as their second argument rather than only raw tuples. This gives downstream users stable, pattern-matchable context without callback arity churn.
- **D-12:** `on_success/2` receives `%{state: :success, result: :ok | {:ok, term()}, value: term() | nil}`.
- **D-13:** `on_failure/2` receives `%{state: :failure, reason: term(), result: {:error, term()} | nil, kind: :error | :exit | :throw | nil, stacktrace: list() | nil, terminal?: false}`.
- **D-14:** `on_discard/2` receives `%{state: :discard, reason: term(), result: :discard | {:discard, term()} | {:error, term()} | nil, kind: atom() | nil, stacktrace: list() | nil, terminal?: true}`.
- **D-15:** Keep envelopes intentionally narrow. Do not include job ids, args, queue, worker name, reasons, or stacktraces in Powertools telemetry metadata. Rich event data can be passed to hooks but must not become metric labels.
- **D-16:** Hook return values are ignored. Hook exceptions and throws are caught, logged at warning level, and never change the job result returned to Oban.

### Dispatch Architecture
- **D-17:** Primary hook dispatch is owned by the generated `ObanPowertools.Worker.perform/1` wrapper, not by per-worker `:telemetry.attach` handlers on Oban job events.
- **D-18:** Add a private/internal dispatcher module, recommended as `ObanPowertools.Worker.Hooks`, so quoted macro code stays small. The wrapper owns lifecycle ordering; the dispatcher owns crash-catching, event envelope construction, telemetry emission, and callback invocation.
- **D-19:** Do not add a GenServer, ETS registry, global `attach_hook/1`, or new supervision tree for Phase 53. Hooks run synchronously in the job process.
- **D-20:** Recommended wrapper order for Phase 53: validate/cast args -> call `on_start/1` safely -> call `process/1` under wrapper rescue/catch -> normalize result against attempt/max_attempts -> dispatch exactly one post hook safely -> return the original Oban-compatible result.
- **D-21:** Later phases may insert behavior into this wrapper in fixed positions: deadline pre-check before `on_start`/`process`, output recording before `on_success`, redaction at enqueue/recording boundaries. Do not choose a dispatch architecture that blocks this composition.

### Telemetry Contract
- **D-22:** Phase 53 must emit hook telemetry because HOOK-05 and the roadmap success criteria require it. Do not defer all telemetry or create a contract-only no-op.
- **D-23:** Add `worker_hook: [:hook, :outcome]` to `ObanPowertools.Telemetry.contract/0`.
- **D-24:** Add helper `execute_worker_hook_event/3` following the existing telemetry helper pattern.
- **D-25:** Emit event `[:oban_powertools, :worker_hook, :invoked]` with measurement `%{count: 1}`.
- **D-26:** Emit metadata as low-cardinality strings: `hook: "on_start" | "on_success" | "on_failure" | "on_discard"` and `outcome: "ok" | "crash_caught"`.
- **D-27:** Emit hook telemetry only for actual hook dispatch attempts after the hook returns or is caught. Do not emit for omitted no-op defaults if the planner can cheaply detect that the worker did not override the hook; otherwise document the chosen behavior explicitly in the plan.
- **D-28:** Add one `metrics/0` counter: `oban_powertools.worker_hook.invoked.count`, with tags `[:hook, :outcome]`.
- **D-29:** Do not emit span-style hook telemetry, hook durations, worker module names, job ids, queue names, args, reasons, or stacktraces in the public Powertools telemetry contract for this phase.

### Documentation and Tests
- **D-30:** Document four support-truth answers for hooks: they run in the job process, outside any Powertools transaction; hook failure does not fail the job; hook failure does not crash the queue; hook execution is not retried independently.
- **D-31:** Tests must cover every routing branch: start, success, retry-eligible failure, terminal failure, explicit discard, explicit cancel non-dispatch, hook crash swallowed, omitted hooks no-op, and telemetry emitted with only allowed metadata.
- **D-32:** Include a test proving final-attempt failure does not double-fire `on_failure/2` and `on_discard/2`.

### the agent's Discretion
- The user explicitly asked for subagent-backed research and a one-shot cohesive recommendation set so they would not need to select implementation options manually. The locked decisions above reflect the synthesized recommendation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Project Posture
- `.planning/ROADMAP.md` — Phase 53 goal and success criteria.
- `.planning/REQUIREMENTS.md` — HOOK-01 through HOOK-05.
- `.planning/PROJECT.md` — v1.7 milestone goals, zero-new-dependency posture, telemetry constraints, and decision posture.
- `.planning/STATE.md` — current milestone state and prior v1.7 research decisions; note that this CONTEXT supersedes the earlier cancel-routes-to-discard note for Phase 53.

### v1.7 Research
- `.planning/research/SUMMARY.md` — milestone-level architecture, build order, and known hook pitfalls.
- `.planning/research/FEATURES.md` — ecosystem comparison, worker hook feature table, anti-features, and telemetry debate.
- `.planning/research/ARCHITECTURE.md` — existing `Worker.__using__/1` seam and wrapper-order discussion.
- `.planning/research/PITFALLS.md` — hook/workflow callback separation, timeout gap, telemetry contract warnings, discard/failure footguns.
- `.planning/research/STACK.md` — locked dependency versions and hook-dispatch alternatives; read with this CONTEXT because the telemetry-handler recommendation is superseded by D-17 through D-21.
- `.planning/threads/2026-05-28-post-v1.5-next-milestone.md` — worker-lifecycle milestone ordering and support-truth constraints.

### Prompt Corpus
- `prompts/oban_powertools_context.md` — product posture, research-first decision posture, worker hook semantics, and public telemetry API posture.
- `prompts/oban-powertools-deep-research-original-prompt.md` — original DX/architecture/SRE lens for paid-tier-equivalent OSS library design.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — operator-first, host-owned, telemetry/audit/redaction cohesion; mostly background for support-truth language.

### Code and Existing Patterns
- `lib/oban_powertools/worker.ex` — current `use ObanPowertools.Worker` macro, args validation, generated `perform/1`, and `enqueue/2`.
- `lib/oban_powertools/telemetry.ex` — frozen telemetry contract, `metrics/0`, and helper pattern for new `execute_worker_hook_event/3`.
- `test/oban_powertools/worker_test.exs` — worker macro tests to extend.
- `test/oban_powertools/telemetry_test.exs` — contract and metric-tag containment tests to extend.
- `lib/oban_powertools/idempotency.ex` — enqueue path used by later redaction/deadline phases; read to avoid ordering regressions.
- `lib/oban_powertools/workflow/result.ex` and `lib/oban_powertools/workflow/callback_outbox.ex` — later output-recording and batch-callback reference points; do not conflate workflow callbacks with worker hooks.

### External Official References
- `https://hexdocs.pm/oban/Oban.Worker.html` — Oban worker return semantics and `timeout/1`.
- `https://hexdocs.pm/oban/Oban.Telemetry.html` — Oban job lifecycle telemetry.
- `https://oban.pro/docs/pro/Oban.Pro.Worker.html` — clean-room comparison for synchronous, crash-caught worker hooks and state separation.
- `https://github.com/sidekiq/sidekiq/wiki/Error-Handling` and `https://github.com/sidekiq/sidekiq/wiki/Middleware` — terminal retry/death and around-execution lessons.
- `https://api.rubyonrails.org/classes/ActiveJob/Callbacks.html` — callback lifecycle comparison.
- `https://docs.celeryq.dev/en/main/userguide/signals.html` — signal payload/extensibility comparison and process-boundary caveats.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Worker.__using__/1`: already generates the only wrapper around `process/1`; this is the correct lifecycle coordination point.
- `ObanPowertools.Telemetry`: already centralizes public event families, `metrics/0`, and helper functions. Add `worker_hook` here rather than emitting raw telemetry from worker code.
- `ObanPowertools.Idempotency.transaction/3`: later phases rely on this path for enqueue-time deadline/redaction changes; Phase 53 should avoid disturbing it.

### Established Patterns
- Public telemetry uses `%{count: 1}` counters and strict low-cardinality metadata. Existing tests compare the contract map and assert metric tags stay within the contract.
- Operational truth is separated by surface: metrics are low-cardinality and ephemeral; durable evidence/audit/details live elsewhere. Worker hook events follow the metrics side, not the evidence side.
- Host-owned callbacks are optional, crash-caught, and support-truthful. Existing host escalation code catches and normalizes callback failures without rolling back the primary operation.

### Integration Points
- `lib/oban_powertools/worker.ex`: add default callbacks, `defoverridable`, and wrapper dispatch.
- New internal module likely `lib/oban_powertools/worker/hooks.ex`: safe callback invocation, envelope construction, and telemetry emission.
- `lib/oban_powertools/telemetry.ex`: add `worker_hook` contract, metric counter, and helper.
- `test/oban_powertools/worker_test.exs`: add lifecycle routing and crash-caught behavior tests.
- `test/oban_powertools/telemetry_test.exs`: add contract/metrics/event tests.

</code_context>

<specifics>
## Specific Ideas

- Use an internal dispatcher to keep macro-generated code readable and testable.
- Prefer string metadata values in telemetry (`"on_success"`, `"crash_caught"`) to match the existing public low-cardinality style.
- Keep the hook envelope map narrow and documented; the hook receives rich enough data for DX, but metrics stay intentionally sparse.
- Final-attempt failure must be tested as terminal discard only, because duplicate failure+discard hooks are the highest-risk footgun.

</specifics>

<deferred>
## Deferred Ideas

- `on_cancel/2` for explicit cancellation/deadline expiry belongs in a later phase if adopter demand or Phase 54 deadline UX needs it.
- Global `attach_hook/1` registry remains deferred until adoption signal.
- Hook latency spans or duration summaries are deferred; Phase 53 only needs counter-style invocation/health telemetry.
- Operator/Lifeline-initiated discard callbacks are out of scope; Lifeline already owns audited operator actions.
- Output recording, deadline/timeout pass-through, and redaction are separate v1.7 phases that should reuse this wrapper seam without expanding Phase 53 scope.

</deferred>

---

*Phase: 53-Worker Lifecycle Hooks*
*Context gathered: 2026-06-12*
