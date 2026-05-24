# Phase 17: DB-First Transition Engine & Command Pipeline - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

## Phase Boundary

Route runtime and operator workflow mutations through one legal DB-first transition path backed by Postgres truth. This phase owns the legal mutation core for workflow cancel, complete, recover intent, expire authority handoff, and reconcile, while rejecting unsupported or ambiguous mutations durably instead of inferring truth from PubSub or ad hoc callers.

This phase does not broaden the optional `oban_web` bridge, does not finish callback/signal/expiry semantics ahead of roadmap ownership, and does not silently reinterpret pre-v1.2 rows.

## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Downstream agents should treat the recommendations in this context as locked defaults and avoid reopening them unless a later choice would materially affect public semantics, support truth, upgrade safety, or maintainer burden.
- **D-02:** Shift decision defaults left for this project and within GSD where possible. Prefer decisive best-practice recommendations over re-asking, except for unusually high-impact choices the user is likely to care about directly.
- **D-03:** Postgres rows remain the only correctness-bearing truth source. PubSub, coordinator wakeups, and UI refreshes stay advisory only.

### Command Surface Shape
- **D-04:** Keep `ObanPowertools.Workflow.*` as the stable public API for common mutation verbs in this phase.
- **D-05:** Introduce one internal DB-first transition pipeline as the real legality engine underneath those helpers rather than widening the public API to a generic command framework yet.
- **D-06:** Do not make raw `Ecto.Multi` plans or low-level transition structs public in Phase 17; that would leak orchestration details and increase semver burden too early.
- **D-07:** It is acceptable to reserve an internal command vocabulary now so a future advanced public surface can be added later if concrete host-app needs emerge, but that future surface is deferred.

### Action Boundaries For Phase 17
- **D-08:** Phase 17 should own the authoritative legal path for `complete`, `request_cancel`, `recover intent`, `expire authority handoff`, dependency unblock/reconcile, and workflow refresh/reprojection.
- **D-09:** Phase 17 should expose explicit deferred shells for richer callback outbox, await/signal durability, late-arrival precedence, and expanded recovery evidence rather than fully owning those semantics now.
- **D-10:** Any existing behavior in `Runtime` that effectively finishes Phases 18-20 early should be refactored behind the Phase 17 command core and clearly marked as provisional, deferred, or unsupported rather than left as accidental milestone leakage.

### Operator And Runtime Parity
- **D-11:** Runtime and operator paths must share the same transition core so there is one legal mutation engine.
- **D-12:** Keep operator-specific policy outside that core. Auth, read-only mode, preview/reason UX, and actor/audit handling should live in thin operator-facing wrappers at the host boundary.
- **D-13:** Lifeline and future workflow UI actions should call operator wrappers that delegate into the shared transition core, rather than calling ad hoc `Runtime` functions directly.
- **D-14:** Preserve explicit distinction between system-initiated mutations and operator-initiated mutations in metadata and audit records even when they share the same legal path.

### Illegal Transition Handling
- **D-15:** Unsupported or ambiguous mutations must return structured Elixir errors immediately to the caller and also persist durable rejection evidence.
- **D-16:** Rejection evidence should not rely on audit rows alone. Use a narrow durable mutation-attempt or mutation-rejection ledger so future diagnosis and support flows can query rejected commands from Postgres truth.
- **D-17:** Audit remains the human-action trail, especially for operator attempts, but is not the sole domain truth for rejected mutations.
- **D-18:** Keep the rejection taxonomy tight and low-cardinality. Prefer a bounded set of reason codes such as illegal transition, unsupported legacy semantics, missing prerequisite evidence, or policy-forbidden mutation.

### Legacy Compatibility During Mutations
- **D-19:** Do not silently upgrade or reinterpret `semantics_version < 2` rows during ordinary mutations.
- **D-20:** Default posture is explicit compatibility adapters for a short, named set of legacy commands only if they are truly business-critical; reject everything else as unsupported until a legal v2 transition is defined.
- **D-21:** If no legacy mutation path is clearly required, prefer outright rejection over magical upgrade-through-transition behavior.
- **D-22:** Every supported legacy adapter must be explicitly documented, auditable, and independently verifiable in later upgrade-proof work.

### UX And DX Posture
- **D-23:** Favor least-surprise Phoenix/Ecto ergonomics: plain function calls, explicit `{:ok, result}` / `{:error, reason}` outcomes, narrow domain nouns, and host-owned wrappers over framework-heavy ceremony.
- **D-24:** Error and rejection reasons should be actionable for operators and maintainers. They should say what mutation was refused, why it was refused, and what legal next step exists if any.
- **D-25:** Public docs and later UI copy should describe the system as at-least-once, explicit, and durable rather than implying exactly-once or invisible self-healing semantics.

### the agent's Discretion
- Exact internal module names for the transition pipeline, command validator, and mutation ledger
- Whether the durable rejection evidence is modeled as a dedicated rejection table or as a more general mutation-attempt ledger, as long as the semantics above hold
- Exact shape of reason-code atoms/strings, provided they stay bounded and support-truthful
- Exact split between reducer/planner/executor internals inside the shared transition core

## Specific Ideas

- The Phase 17 core should feel like a Phoenix context, not a new workflow framework. Keep the paved road obvious and narrow.
- The durable mutation path should borrow the best idea from Temporal-style systems: one shared write path over durable truth, but without importing Temporal’s broader conceptual surface.
- The operator path should borrow the best idea from mature admin tooling: actions are explicit, permissioned, and audited, but domain legality remains in one shared core.
- The project preference to carry forward is to bias GSD and downstream planning toward strong recommendations by default, not repeated re-litigation, unless a choice would materially change public semantics or support obligations.

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone framing
- `.planning/ROADMAP.md` — Phase 17 goal, dependency chain, and active milestone sequence
- `.planning/milestones/v1.2-ROADMAP.md` — v1.2 planned phase ownership boundaries and non-goals
- `.planning/PROJECT.md` — active milestone posture, support-truth goals, and repo-wide constraints
- `.planning/REQUIREMENTS.md` — `WFS-02`, `REC-*`, `SIG-*`, `DIA-*`, `VER-*`, and packaging/support rules that constrain Phase 17

### Prior locked decisions
- `.planning/phases/16-semantics-contract-cause-vocabulary-compatibility-baseline/16-CONTEXT.md` — semantics version baseline, durable cause vocabulary, compatibility stance, and DB-first truth source
- `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md` — prior project-level preference to shift recommendations left within GSD where possible
- `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md` — locked preference to treat recommendations as defaults unless public support truth or maintainer burden changes materially

### Architecture and pitfalls
- `.planning/research/ARCHITECTURE.md` — DB-first architecture guidance, Postgres truth, and warning against second orchestrators or non-durable control planes
- `.planning/research/SUMMARY.md` — milestone-level research recommendation for transactional command pipeline and replayable reconciliation
- `.planning/research/PITFALLS.md` — explicit warning against making PubSub or notifier paths correctness-bearing

### Prompt and product guidance
- `prompts/oban_powertools_context.md` — domain language, product posture, personas, and support-truth framing for Powertools
- `prompts/oban-powertools-deep-research-original-prompt.md` — lessons-learned / footguns / DX-oriented product intent for the library
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — host-owned native ops posture, bridge boundary, and operator UX expectations relevant to future workflow actions

### Existing implementation surfaces
- `lib/oban_powertools/workflow.ex` — current public workflow API entrypoints that Phase 17 should preserve as the paved road
- `lib/oban_powertools/workflow/runtime.ex` — current runtime mutation logic to consolidate behind the legal transition core
- `lib/oban_powertools/lifeline.ex` — existing workflow repair caller path that should migrate to operator wrappers over the shared core
- `lib/oban_powertools/web/workflows_live.ex` — current read-only native workflow surface and future integration point for bounded actions

## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Workflow` already provides a clear public API seam for thin helper verbs; it can remain the stable entrypoint while legality moves underneath.
- `ObanPowertools.Workflow.Runtime` already centralizes most workflow mutations in one place, which lowers refactor cost for introducing a transition core.
- Existing schemas for workflows, steps, awaits, signals, recovery attempts, and callback outbox provide durable storage primitives that later phases can own more fully.
- Existing audit and telemetry patterns already exist across runtime and native operator flows, so Phase 17 can align with repo conventions instead of inventing new observability seams.

### Established Patterns
- Repo-wide pattern is host-owned behavior with explicit wrappers, not opaque framework magic.
- `Ecto.Multi` is already the dominant mutation pattern for durable transitions and should remain so.
- Native operator surfaces keep auth/read-only/preview policy at the web boundary rather than embedding those concerns directly inside low-level runtime modules.
- Prior phases consistently separate durable truth from advisory telemetry or UI state; Phase 17 should keep that line sharp.

### Integration Points
- Lifeline workflow repair actions should route through operator wrappers over the shared transition core.
- Future workflow UI mutations should reuse the same wrappers rather than introducing a second write path.
- Later callback, recovery-evidence, and signal/await phases should plug into reserved command-core seams instead of bypassing legality checks.
- Verification and upgrade-proof work in later phases will depend on a crisp mutation reason taxonomy and explicit legacy gating introduced here.

## Deferred Ideas

- Public advanced command API or explicit `Workflow.Command` surface — defer until concrete host-app or automation needs justify widening the semver surface.
- Async operator command inbox / approval queue for high-risk actions — valuable later if bounded workflow actions need delayed execution or dual control.
- Broad legacy compatibility runtime — out of scope unless a small named set of legacy adapters proves necessary.
- Finishing callback outbox semantics, signal/await authority, and late-arrival precedence in this phase — explicitly deferred to Phases 18-20.

---

*Phase: 17-db-first-transition-engine-command-pipeline*
*Context gathered: 2026-05-23*
