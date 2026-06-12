# Phase 54: deadline: / timeout: Pass-through - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 54 adds two safety controls to `ObanPowertools.Worker`: a declarative
`timeout:` option that delegates to Oban's native per-attempt `timeout/1`
callback, and a Powertools-defined soft `deadline:` option that stores an
absolute `__deadline_at__` timestamp in job meta at enqueue time and cancels
expired jobs before any host work runs.

This phase delivers SAFE-01 through SAFE-04 only. It does not add hard
mid-execution deadline interruption, runtime per-enqueue timeout overrides,
deadline-specific worker hooks, output recording, redaction, new supervision
processes, or a custom timer implementation.

</domain>

<decisions>
## Implementation Decisions

### Timeout Semantics
- **D-01:** `timeout:` is a compile-time worker default in milliseconds. It must
  generate a `timeout/1` callback that returns the configured value and lets
  Oban 2.23's existing executor enforce the kill timer.
- **D-02:** Do not pass `timeout:` through to `Oban.Job.new/2` or queue/runtime
  options. Oban treats timeout as a worker callback, not a job changeset option.
- **D-03:** The generated timeout callback should remain overridable by an
  explicitly defined host `timeout/1` callback. Host-defined dynamic timeout
  logic is the escape hatch for advanced per-job behavior.
- **D-04:** Validate timeout values as positive integer milliseconds when a
  default is declared. Absence of `timeout:` keeps Oban's default `:infinity`.

### Deadline Semantics
- **D-05:** `deadline:` is a soft wall-clock expiry, not an execution-duration
  timeout. It prevents stale queued work from starting; it never interrupts a
  job that is already running.
- **D-06:** `deadline:` stores `meta["__deadline_at__"]` as an ISO8601 UTC
  timestamp at Powertools enqueue time. The timestamp is derived from enqueue
  time plus the declared deadline duration.
- **D-07:** The deadline duration should accept the roadmap style
  `deadline: :timer.hours(24)` and normalize to positive integer milliseconds
  for runtime use.
- **D-08:** Existing caller `meta` must be preserved, but Powertools reserved
  keys win. A host-supplied `__deadline_at__` must not spoof or override the
  worker's declared deadline.
- **D-09:** Deadline metadata belongs at top-level Oban job meta as
  `__deadline_at__`, matching the requirement and keeping the value visible in
  the existing job detail meta rendering.

### Wrapper Ordering
- **D-10:** Deadline expiry is checked after args validation/casting and before
  `on_start/1`, `process/1`, output recording, or any post hook. Expired jobs
  should not trigger host lifecycle hooks because no host execution is starting.
- **D-11:** If `__deadline_at__` is in the past, `perform/1` returns
  `{:cancel, :deadline_expired}` without calling `process/1`.
- **D-12:** Deadline cancellation follows Phase 53's locked cancellation
  semantics: `{:cancel, reason}` does not route to `on_failure/2` or
  `on_discard/2`.
- **D-13:** Malformed or missing deadline meta must not crash the job wrapper.
  Powertools-generated meta should be parseable; host-corrupted or bypassed
  meta should be handled defensively and leave normal execution behavior intact.

### Idempotency and Enqueue Path
- **D-14:** Keep the idempotency fingerprint based on validated args and worker
  identity. Adding deadline meta must not change the fingerprint or duplicate
  semantics.
- **D-15:** Deadline metadata is added in the existing
  `ObanPowertools.Idempotency.transaction/3` path before `worker_mod.new/2`
  builds the Oban job changeset.
- **D-16:** Deadline expiry does not invalidate active idempotency receipts. A
  duplicate enqueue while a receipt is active should still return the existing
  conflict; fresh deadline behavior comes after the receipt window allows a new
  job.

### Doctor Integration
- **D-17:** `mix oban_powertools.doctor` reports `retryable` jobs whose
  parseable `meta["__deadline_at__"]` is already past as a warning.
- **D-18:** The deadline doctor check should be read-only and prefix-aware,
  following the existing `Doctor.Checks` pattern.
- **D-19:** Do not broaden `--strict` semantics unless planning explicitly
  updates the CLI contract. The existing docs scope `--strict` to the
  uniqueness-timeout risk check; expired deadlines should remain warnings.
- **D-20:** The doctor check should never fail the whole run because a host
  inserted malformed deadline metadata. Query errors are findings; malformed
  values should be ignored or surfaced as bounded warnings, not crashes.

### Support Truth
- **D-21:** Document the distinction clearly: `timeout:` is per-attempt runtime
  enforced by Oban and can produce `Oban.TimeoutError`; `deadline:` is
  Powertools soft pre-run cancellation.
- **D-22:** Document that Oban timeout kills may bypass worker hooks, as locked
  in Phase 53. Timeout observability belongs to Oban job exception telemetry,
  not Powertools lifecycle hooks.
- **D-23:** Do not add a Powertools telemetry family for deadline expiry in this
  phase unless a later plan proves it is required. SAFE-01 through SAFE-04 do
  not require a new public telemetry contract.

### Tests and Documentation
- **D-24:** Worker tests must prove generated `timeout/1`, timeout validation,
  deadline meta insertion, deadline pre-run cancellation, and no `process/1` or
  hook dispatch for expired jobs.
- **D-25:** Idempotency tests must prove deadline meta coexists with existing
  limiter/idempotency meta and does not perturb duplicate detection.
- **D-26:** Doctor tests must cover expired retryable jobs, non-expired
  retryable jobs, malformed meta, prefix handling, formatter output, JSON
  schema stability, and CLI docs.
- **D-27:** Update worker and doctor docs with support-truth language for
  timeout units, soft deadline behavior, and the absence of hard interruption.

### the agent's Discretion
- The user approved the locked-context path after analysis found no material
  unresolved gray areas. Downstream agents should implement the recommendation
  set above rather than reopening ordinary implementation choices.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Locked Prior Decisions
- `.planning/ROADMAP.md` - Phase 54 goal and success criteria.
- `.planning/REQUIREMENTS.md` - SAFE-01 through SAFE-04.
- `.planning/PROJECT.md` - v1.7 milestone posture, zero-new-dependency
  constraint, and research-first decision posture.
- `.planning/STATE.md` - current milestone status and v1.7 build-order
  decisions.
- `.planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md` - authoritative
  wrapper ordering, cancellation semantics, timeout-hook support truth, and
  lifecycle hook behavior. This supersedes older research that placed the
  deadline check after `on_start/1`.

### v1.7 Research
- `.planning/research/SUMMARY.md` - milestone-level architecture, build order,
  timeout/deadline table stakes, and known pitfalls.
- `.planning/research/FEATURES.md` - deadline/timeout ecosystem comparison,
  anti-features, soft-deadline framing, idempotency interaction, and Doctor
  advisory.
- `.planning/research/PITFALLS.md` - timeout/deadline failure modes, unit
  validation, timeout hook gap, and BEAM exit behavior.
- `.planning/research/ARCHITECTURE.md` - macro integration points and older
  timeout/deadline notes; read with this CONTEXT because Phase 53 supersedes
  the suggested post-`on_start` deadline check and `{:discard,
  :deadline_exceeded}` return.
- `.planning/research/STACK.md` - Oban 2.23 timeout callback facts, dependency
  posture, and no-new-library conclusion.
- `.planning/threads/2026-05-28-post-v1.5-next-milestone.md` - worker lifecycle
  ordering and "no custom BEAM task machinery" decision.

### Prompt Corpus
- `prompts/oban_powertools_context.md` - product vocabulary for deadline,
  expiration, timeout, and clean-room commercial-feature parity.

### Code and Existing Patterns
- `lib/oban_powertools/worker.ex` - generated `perform/1`, `enqueue/2`,
  `use Oban.Worker` pass-through, limits option stripping, and validation
  patterns.
- `lib/oban_powertools/worker/hooks.ex` - Phase 53 hook dispatcher and locked
  cancellation non-dispatch behavior.
- `lib/oban_powertools/idempotency.ex` - enqueue transaction, fingerprint
  generation, existing meta merge, limiter snapshot merge, and duplicate
  conflict path.
- `lib/oban_powertools/doctor.ex` - Doctor check composition and exit-code
  calculation.
- `lib/oban_powertools/doctor/checks.ex` - prefix-aware read-only query pattern,
  warning/error finding construction, and safe identifier handling.
- `lib/oban_powertools/doctor/formatter.ex` - human and JSON output shape with
  `schema_version: 1`.
- `lib/mix/tasks/oban_powertools.doctor.ex` - CLI flags, strict-mode support
  truth, prefix resolution, and repo startup strategy.
- `guides/workers-and-idempotency.md` - worker DX docs that need timeout and
  deadline support-truth additions.
- `test/oban_powertools/worker_test.exs` - worker macro and hook routing tests
  to extend.
- `test/oban_powertools/idempotency_test.exs` - enqueue/fingerprint tests to
  extend for deadline meta.
- `test/oban_powertools/doctor/checks_test.exs` - Doctor check tests to extend.
- `test/oban_powertools/doctor/formatter_test.exs` - Doctor output tests to
  extend.
- `test/mix/tasks/oban_powertools.doctor_test.exs` - CLI docs/contract tests to
  extend.
- `test/oban_powertools/web/live/jobs_live_test.exs` - existing job detail meta
  rendering proof if planner decides to add an explicit assertion for
  `__deadline_at__` visibility.

### External and Vendored Oban References
- `deps/oban/lib/oban/worker.ex` - Oban `timeout/1` callback contract,
  generated default implementation, and `new/2` option handling.
- `deps/oban/lib/oban/queue/executor.ex` - Oban executor timeout enforcement via
  `:timer.exit_after/2` and job lifecycle telemetry.
- `deps/oban/lib/oban/job.ex` - Oban job changeset options; confirms timeout is
  not a job insert option and `meta` is the correct sideband.
- `https://hexdocs.pm/oban/Oban.Worker.html` - official timeout and worker
  return semantics.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Worker.__using__/1`: already strips Powertools-only options,
  calls `use Oban.Worker`, validates args, and owns the generated `perform/1`
  wrapper. This is the correct place to add timeout callback generation and
  deadline pre-check insertion.
- `ObanPowertools.Idempotency.transaction/3`: already validates args,
  computes the fingerprint, reserves limits, deep-merges meta, and calls
  `worker_mod.new/2`. This is the correct place to add `__deadline_at__` while
  preserving fingerprint semantics.
- `ObanPowertools.Doctor.Checks`: already has isolated read-only check
  functions returning `%Doctor.Finding{}` values. Add the expired-deadline
  check here and compose it in `Doctor.run/2`.
- `ObanPowertools.Doctor.Formatter`: already renders warnings and stable JSON
  findings. The new check can reuse the existing finding shape without a schema
  version bump.

### Established Patterns
- Powertools-owned metadata uses explicit, inspectable JSON sidebands and keeps
  metrics low-cardinality. Deadline state should live in job meta, not a new
  table or telemetry label.
- Doctor checks favor read-only catalog/table queries, honest nonzero exit
  codes, and defensive failure findings.
- Existing worker macro tests compile small nested worker modules and assert
  generated behavior directly; Phase 54 should follow that style.
- Existing docs emphasize support-truth boundaries. Deadline docs should be
  explicit that this is soft pre-run cancellation, not Oban Pro hard deadline
  parity.

### Integration Points
- `lib/oban_powertools/worker.ex`: strip `:deadline` and `:timeout`, normalize
  worker safety opts, generate `timeout/1`, expose internal deadline config,
  and insert the pre-run deadline cancellation check.
- `lib/oban_powertools/idempotency.ex`: merge top-level `__deadline_at__` into
  job meta after fingerprinting and before `worker_mod.new/2`.
- `lib/oban_powertools/doctor.ex` and `lib/oban_powertools/doctor/checks.ex`:
  add and compose `expired_deadline_jobs` or similarly named check.
- `lib/mix/tasks/oban_powertools.doctor.ex`: update CLI docs and severity table
  for expired deadline warnings without changing existing boot strategy.
- `guides/workers-and-idempotency.md`: add worker examples for `timeout:` and
  `deadline:` and call out timeout-vs-deadline support truth.

</code_context>

<specifics>
## Specific Ideas

- Prefer an internal helper such as `ObanPowertools.Worker.Deadlines` if macro
  code starts to grow; keep generated quoted code small and readable.
- Use string keys in Oban meta: `"__deadline_at__"`.
- Use ISO8601 UTC timestamps via `DateTime.to_iso8601/1`.
- Use `{:cancel, :deadline_expired}` exactly; do not use the older research
  wording `{:discard, :deadline_exceeded}`.
- Keep hard deadline, per-enqueue timeout, and cancellation hooks deferred
  unless adopter demand later justifies them.

</specifics>

<deferred>
## Deferred Ideas

- Hard deadline interruption for already-running jobs - future phase only; it
  requires Oban Pro-level supervision behavior or a custom monitored execution
  model.
- Runtime per-enqueue `timeout:` override - advanced use case; hosts can define
  custom `timeout/1` if needed.
- Deadline-specific telemetry family - not required for SAFE-01 through
  SAFE-04 and would expand the public telemetry contract.
- `on_cancel/2` or deadline cancellation hooks - Phase 53 intentionally left
  `{:cancel, reason}` outside the post-hook lifecycle.

</deferred>

---

*Phase: 54-deadline: / timeout: Pass-through*
*Context gathered: 2026-06-12*
