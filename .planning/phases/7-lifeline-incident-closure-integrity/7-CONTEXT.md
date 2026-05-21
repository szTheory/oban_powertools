# Phase 7: Lifeline Incident Closure Integrity - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the remaining Lifeline correctness gap so a successful repair fully retires the acted-on incident,
refreshes cleanly in the native Lifeline UI,
and preserves a trustworthy end-to-end incident lifecycle.

This phase is about incident retirement, re-projection correctness, closure visibility, and proof.
It is not a broader redesign of Lifeline semantics,
not a new self-healing system,
and not a generic incident-management product.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Downstream agents should treat the recommendations in this context as locked defaults and avoid reopening them unless a later choice would materially affect correctness, operator trust, durability, or the public behavior of the repair flow.
- **D-02:** Shift defaults left for this project: prefer decisive best-practice recommendations over re-asking, except for unusually high-impact semantic changes.

### Incident Retirement Model
- **D-03:** Phase 7 should use a hybrid closure model: a successful repair explicitly transitions the incident row from `active` to `resolved`, while future projection still validates against current stranded state before reopening anything.
- **D-04:** Incident retirement must happen inside the same `Ecto.Multi` as target mutation, preview consumption, and immutable audit write. A repair is not considered complete unless the incident lifecycle transitions atomically with the rest of the action.
- **D-05:** Resolved incidents remain in the durable `oban_powertools_lifeline_incidents` table. Do not hard-delete, archive-move, or otherwise make closure history disappear as part of the Phase 7 hot-path fix.
- **D-06:** Incident lifecycle metadata should stay explicit and grep-able on the incident row. At minimum, planning should preserve/use `status` and `resolved_at`; if additional lifecycle fields are added they should support reopen/history clarity rather than introduce opaque suppression state.

### Re-Projection and Reopen Rules
- **D-07:** `active` status must be derived from current stranded state, not from historical incident existence alone.
- **D-08:** `project_incidents/2` must reconcile stale active rows to `resolved` when their fingerprint is no longer present in the current candidate set.
- **D-09:** For `dead_executor` incidents, only currently stranded targets should qualify as active evidence. Jobs that have already been rescued into `available` or `retryable` must not keep the incident active merely because historical `executor_id` metadata is still present.
- **D-10:** For `workflow_stuck` incidents, only workflow steps whose current state and current blocker fields still make them stuck should qualify as active evidence.
- **D-11:** Reopen behavior should reuse the same logical incident identity (`incident_fingerprint`) and lifecycle row rather than creating noisy successor rows for the same underlying issue class. If extra lifecycle counters/timestamps are added, they should reinforce this stable-identity model.
- **D-12:** Do not use cooldown windows, silent suppression markers, or other “magic” anti-reprojection tricks as the primary fix. If projection is correct, closure should come from real state reconciliation, not timers.

### Repair Failure and Safety Semantics
- **D-13:** Unauthorized, drifted, invalid-reason, or otherwise failed repair attempts must not retire the incident.
- **D-14:** `Heartbeat Late` remains a warning posture only. Preview/execute rejection for late executors should continue to leave the incident lifecycle unchanged.
- **D-15:** Resolution semantics should stay conservative and evidence-first: an incident may only resolve when the acted-on target mutation succeeds and the resulting system state no longer satisfies the active incident criteria.

### UI Closure Behavior
- **D-16:** The Lifeline UI should separate active and resolved incident views instead of making repaired incidents simply disappear with no durable destination.
- **D-17:** Default landing posture remains active incidents / `Needs Review`.
- **D-18:** After a successful repair, the acted-on incident should leave the active list but remain visible in a resolved state long enough for the operator to confirm the success message, after-state, and inline audit evidence.
- **D-19:** The UI should preserve semantic clarity: active views answer “what still needs action,” while resolved views answer “what just happened and what proof was written.”
- **D-20:** Do not keep resolved rows mixed into the active list by default. That muddies `Needs Review` semantics and increases re-action risk.
- **D-21:** Do not rely on toast-only or transient-only confirmation for repair closure. Correctness-sensitive operator actions need a durable resolved destination and inline evidence.

### Verification Bar
- **D-22:** Phase 7’s minimum verification bar is backend plus LiveView refresh/remount regression coverage, not backend-only proof.
- **D-23:** Verification must prove all of the following:
  successful repair retires the incident durably,
  rerunning projection does not leave it active when no qualifying evidence remains,
  failed/drifted/unauthorized paths do not retire it,
  and a fresh Lifeline mount no longer shows the repaired incident in the active list while preserving closure evidence.
- **D-24:** Browser E2E is not required for this phase. The idiomatic test posture for this library is DB-backed integration tests plus `Phoenix.LiveViewTest`.
- **D-25:** Add a targeted compat/backfill test only if the chosen implementation changes incident persistence shape or requires migration semantics for pre-Phase-7 rows.

### the agent's Discretion
- Exact lifecycle field names beyond the already-existing `status` and `resolved_at`, provided the resulting model stays explicit, durable, and easy to query.
- Exact `Ecto.Multi` composition and projection batching, provided reconciliation remains atomic and operator-trustworthy.
- Exact Active/Resolved tab wording and detail-pane behavior, provided the page remains incident-first, evidence-first, and least-surprise.

</decisions>

<specifics>
## Specific Ideas

- Preferred closure posture:
  mutate target,
  retire incident,
  consume preview,
  write audit,
  then reload the UI into a stable resolved state.
- Preferred reprojection posture:
  “active if currently stranded, resolved otherwise”
  instead of
  “once projected, stays active until some side path cleans it up.”
- Preferred dead-executor interpretation:
  a rescued job should stop contributing to active incident evidence immediately,
  even if historical metadata still remembers the old executor.
- Preferred UI feel:
  the operator should never wonder whether the success message applies to the incident they just repaired or to a different row that happened to become selected after refresh.
- Preferred trust model:
  no silent cooldowns,
  no magical suppression,
  no disappearing evidence.
- The user explicitly prefers a shift-left GSD posture here as well:
  downstream agents should accept these recommendations by default and only escalate follow-up questions when a choice is unusually impactful.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and authority
- `.planning/ROADMAP.md` — Phase 7 scope, gap-closure framing, and success criteria.
- `.planning/REQUIREMENTS.md` — `LIF-02` ownership and the remaining open-gap statement.
- `.planning/STATE.md` — current milestone posture and next-action framing.
- `.planning/phases/4-VERIFICATION.md` — explicit statement that active incident retirement remained open after Phase 4.

### Prior phase decisions
- `.planning/phases/4-CONTEXT.md` — core Lifeline semantics, preview/execute safety model, incident-first operator posture, and repair non-goals.
- `.planning/phases/4-UI-SPEC.md` — active incident page contract, preview-first flow, and evidence-first UI expectations.
- `.planning/phases/5-CONTEXT.md` — shift-left decision preference and explicit boundary against silently absorbing adjacent runtime defects elsewhere.
- `.planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md` — least-surprise operator UX, auth-before-preview precedent, and explicit shift-left defaults.

### Current implementation targets
- `lib/oban_powertools/lifeline.ex` — current incident projection, repair execution, and the retirement gap.
- `lib/oban_powertools/lifeline/incident.ex` — current durable incident schema and lifecycle fields.
- `lib/oban_powertools/web/lifeline_live.ex` — current active-incident page behavior and post-execute reload path.
- `test/oban_powertools/lifeline_test.exs` — existing backend coverage baseline for projection and repair.
- `test/oban_powertools/web/live/lifeline_live_test.exs` — existing LiveView coverage baseline for preview/execute UX.

### Project research and product posture
- `.planning/research/SUMMARY.md` — Ecto-native, operator-first, host-owned product direction.
- `.planning/research/PITFALLS.md` — warnings against hidden state, operational ambiguity, and correctness footguns.
- `.planning/research/operator_ux.md` — explain-then-act operator UX posture for manual interventions.
- `prompts/oban_powertools_context.md` — product posture, domain language, and host-owned OSS philosophy.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — hybrid shell guidance, native Powertools ownership of repair flows, and operator-trust posture.
- `prompts/oban-powertools-deep-research-original-prompt.md` — maintainer intent around batteries-included DX, least surprise, and lessons learned from adjacent ecosystems.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/oban_powertools/lifeline.ex`: already centralizes projection, preview, execute, and audit wiring; this is the natural place to make incident retirement and re-projection coherent.
- `lib/oban_powertools/lifeline/incident.ex`: already has `status` and `resolved_at`, which makes an explicit durable lifecycle the path of least surprise.
- `lib/oban_powertools/audit.ex`: existing durable audit writer should remain the authoritative proof surface for manual repair actions.
- `lib/oban_powertools/web/lifeline_live.ex`: existing selected-row/detail-pane structure can support resolved-state continuity after execute without inventing a separate product surface.
- `test/oban_powertools/lifeline_test.exs` and `test/oban_powertools/web/live/lifeline_live_test.exs`: existing test shape already matches the recommended backend + LiveView regression bar.

### Established Patterns
- This repo prefers explicit lifecycle state over hidden cleanup magic.
- Correctness-sensitive operations are expected to use `Ecto.Multi` and durable audit evidence.
- Native Powertools operator pages are expected to be explain-first, action-safe, and least-surprise.
- Durable DB evidence is the source of truth for historical operator actions; transient UI state is not.

### Integration Points
- Incident retirement should connect target mutation, preview consumption, incident lifecycle transition, and audit evidence into one transactional story.
- Projection reconciliation should align the hot incident table with current stranded reality without throwing away closure history.
- LiveView refresh behavior should follow the durable lifecycle model rather than inventing local closure heuristics.
- Verification artifacts for Phase 7 should map directly to the repaired backend and LiveView flows so `LIF-02` can be credibly closed.

</code_context>

<deferred>
## Deferred Ideas

- A broader generic incident-management model beyond Powertools-owned repair flows.
- Cooldown-based or suppression-based anti-noise systems for incident reappearance.
- Browser-level E2E infrastructure for this phase.
- Hard-retirement/archive movement of resolved incidents as part of the immediate correctness fix.
- Broad self-healing or automatic rescue expansion beyond the conservative repair semantics already established in Phase 4.

</deferred>

---

*Phase: 7-lifeline-incident-closure-integrity*
*Context gathered: 2026-05-20*
