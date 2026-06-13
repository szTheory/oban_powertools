# Phase 58: Cron Deadline Injection - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Inject `__deadline_at__` meta on the cron path in `cron.ex maybe_insert_job` for `deadline:`-configured workers.

</domain>

<decisions>
## Implementation Decisions

### Cron Meta Injection
- **D-01:** Thread `now` as the fifth parameter through all four `maybe_insert_job` clause heads. The `now` variable is already bound in `claim_slot/4` at line 52; pass it via the `Multi.run` lambda.
- **D-02:** Inject `Deadlines.build_meta(deadline_ms, now)` inside the `function_exported?(:__powertools_limits__, 0)` true branch only — never in the `else` or `rescue` paths.
- **D-03:** Pass deadline meta as `meta: deadline_meta` in opts before the `worker_module.new/2` call so `Redaction.apply/4` merges `__redacted_fields__` on top. Do not post-process the changeset.
- **D-04:** Use `merge_powertools_meta/4` in `idempotency.ex` as the reference implementation for correct merge ordering.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Implementation Target
- `lib/oban_powertools/cron.ex` — target for `maybe_insert_job` modification.
- `lib/oban_powertools/idempotency.ex` — reference for `merge_powertools_meta/4` meta merge ordering.

### Requirements
- `.planning/REQUIREMENTS.md` §INT-02 — exact change description and file targets.
- `.planning/PROJECT.md` — v1.8 implementation notes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `now` binding in `claim_slot/4` — already available to be threaded through `maybe_insert_job`.

### Established Patterns
- Meta merging order: deadline meta must be passed in opts before `new/2` so redaction logic applies properly.
- Safe worker delegation: only invoke powertools-specific logic inside the `function_exported?` check.

### Integration Points
- `cron.ex` `claim_slot/4` `Multi.run(:job, ...)` connects the generated meta to job insertion.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — implementation is completely determined by `PROJECT.md` v1.8 implementation notes.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 58-Cron Deadline Injection*
*Context gathered: 2026-06-13*