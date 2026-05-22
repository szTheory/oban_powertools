# Phase 10: Operator UX Coherence & Mutation Safety - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Unify permission, read-only, preview, reason, and audit behavior across the Powertools shell and the optional `oban_web` bridge so operators get one coherent trust model.

This phase is about consistency of operator-facing mutation semantics and support-truth.
It is not a full native replacement for Oban Web,
not a new RBAC framework,
and not a broad expansion of mutation surface area.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Downstream agents should treat the recommendations in this context as locked defaults and avoid reopening them unless a later choice would materially affect operator trust, public contract shape, safety posture, or support-truth.
- **D-02:** Shift defaults left for this project and within GSD workflows where possible: prefer decisive best-practice recommendations over re-asking, except for unusually high-impact public-semantic changes the user is likely to care about directly.
- **D-03:** Phase 10 must stay coherent with the existing project DNA:
  host-owned policy seams,
  hybrid shell plus bounded bridge,
  explain-then-act,
  durable audit evidence,
  and least-surprise operator UX.

### Surface Ownership and Support-Truth
- **D-04:** Native Powertools pages are the authoritative mutation surface.
- **D-05:** The optional `/ops/jobs/oban` bridge remains a bounded Oban Web inspection surface in Phase 10, not a fully equivalent mutation surface.
- **D-06:** Do not promise full UX parity between native Powertools pages and the bridge.
  Promise policy coherence instead:
  same auth seam,
  same display/redaction seam,
  same actor vocabulary,
  same read-only vocabulary,
  and the same support-truth about where audited mutations belong.
- **D-07:** The bridge should be described plainly as “Oban Web inside the Powertools ops area” rather than pretending it is a native Powertools screen.

### Permission and Read-Only Posture
- **D-08:** When an operator can inspect a resource but cannot mutate it, native Powertools pages should show mutation controls in a disabled state with inline explanation text.
- **D-09:** Do not hide native mutation controls by default on viewable resources.
  Hiding makes capability boundaries ambiguous and increases surprise.
- **D-10:** Do not use “clickable then denied” as the primary UX pattern.
  Server-side denial remains mandatory as defense in depth,
  but the UI should communicate lack of permission before click.
- **D-11:** Preview entry is privileged.
  Unauthorized users must not enter preview state.
- **D-12:** Read-only explanations must be accessible and inline enough to avoid tooltip-only or hover-only ambiguity.
- **D-13:** Phase 10 should establish consistent permission copy and disabled-state semantics across cron, lifeline, workflows, and future native operator pages.

### Native Mutation Contract
- **D-14:** Phase 10 should standardize on one server-authoritative native mutation path:
  `preview -> reason -> execute`.
- **D-15:** Native operator mutations should use durable preview records rather than purely ephemeral LiveView assign state.
- **D-16:** The shared preview contract should include:
  `preview_token`,
  `action`,
  `resource`,
  `risk`,
  `summary`,
  `before`,
  `after`,
  `affected_scope`,
  `reason_requirement`,
  `generated_at`,
  `expires_at`,
  `status`,
  and optional `drift_reason`.
- **D-17:** Preview status should be explicit and operator-visible.
  Default lifecycle is:
  `ready`,
  `drifted`,
  `expired`,
  `consumed`.
- **D-18:** Direct execute should remain an internal/system path, not the operator UI path.
- **D-19:** Preview generation and execute must be separately authorized.
- **D-20:** Execute must re-check safety conditions server-side before mutation,
  including preview availability and drift/expiry where relevant.

### Preview Depth and Consequence Visibility
- **D-21:** The shared default preview UX for native mutations is a structured consequence preview.
- **D-22:** A structured consequence preview must show:
  actor,
  action,
  resource,
  intended effect,
  rendered reason,
  and the audit consequence before confirm.
- **D-23:** Minimal “this action will be audited” copy is not sufficient as the default contract.
- **D-24:** Richer receipt-like previews with before/after state, affected records, preview token, and detailed evidence should be reserved for high-risk, destructive, or drift-prone flows.
- **D-25:** Lifeline is the pattern library for high-trust dangerous actions.
  Cron and future control-plane surfaces should move toward the same consequence-preview contract,
  but do not need full Lifeline-level detail for every low-risk action.

### Reason Policy
- **D-26:** Keep the reason field visible on every native preview for consistency.
- **D-27:** Reason requiredness should be risk-based, not universal.
- **D-28:** Default reason policy:
  `pause_cron_entry`,
  `resume_cron_entry`,
  and `run_cron_entry` are optional;
  evidence-bearing, destructive, repair, retry, cancel, and bulk actions require an operator-readable reason.
- **D-29:** Required reasons must be validated for specificity.
  Blank or trivial text should be rejected.
- **D-30:** Reason policy should remain library-owned in shape but host-overridable through a bounded seam if needed.
- **D-31:** Do not force filler reasons for low-risk actions merely for consistency theater.
  That degrades operator ergonomics and audit quality.

### Audit, Durability, and Transaction Boundaries
- **D-32:** Native mutation flows should preserve a single durable story:
  authorize,
  preview,
  confirm,
  mutate,
  consume preview,
  write audit evidence.
- **D-33:** For correctness-sensitive UI actions, mutation and durable audit evidence should succeed together through one explicit transactional boundary.
- **D-34:** `Ecto.Multi` is the idiomatic transaction boundary for these flows in this codebase and ecosystem.
- **D-35:** Telemetry remains useful operational signal, but it is not the audit contract.
  Actor identity,
  reasons,
  preview tokens,
  and rich mutation evidence belong in durable audit paths, not public telemetry metadata.
- **D-36:** “No durable principal” remains a hard stop for preview generation and execute across all native mutation flows.

### Bridge Mutation Boundary
- **D-37:** Keep the Oban Web bridge read-only in Phase 10, even for users who can mutate through native Powertools pages.
- **D-38:** Do not enable raw Oban Web fine-grained writes as the default bridge posture.
  Raw upstream writes cannot satisfy Powertools’ preview/reason/durable-audit contract.
- **D-39:** If future demand justifies bridge mutations, only a narrow allowlisted subset may be adapted into Powertools-owned preview/reason/audit semantics.
- **D-40:** Do not let the bridge become a shadow dashboard layer or broad plugin surface around undocumented upstream internals.
- **D-41:** Bridge coherence should come from shared seams and clear labeling,
  not from pretending upstream Oban Web behavior and native Powertools behavior are identical.

### UX Coherence and Vocabulary
- **D-42:** Use one shared mutation vocabulary across native surfaces:
  permission,
  read-only,
  preview,
  reason,
  audit,
  drift,
  expired,
  consumed.
- **D-43:** Keep provenance and audit visibility close to the acted-on resource.
  Operators should not have to navigate to the global audit page to understand what just happened.
- **D-44:** Page-level read-only framing plus control-level disabled reasons is the default coherence pattern.
- **D-45:** Error states should be explicit and reusable across surfaces, including:
  `unauthorized`,
  `preview_not_available`,
  `preview_drifted`,
  `preview_expired`,
  `preview_consumed`,
  `reason_required`,
  `reason_too_short`,
  and `mutation_conflict`.

### the agent's Discretion
- Exact module/schema names for the shared preview contract, provided the public behavior remains explicit, durable, and coherent.
- Exact UI component names and layout, provided native mutation flows converge on one consistent preview and read-only model.
- Exact reason-policy callback shape, provided hosts do not need separate policy systems for native pages versus the bridge.
- Exact bridge messaging copy, provided support-truth remains plain:
  native Powertools pages own audited mutations,
  the bridge is read-only unless explicitly upgraded later.

</decisions>

<specifics>
## Specific Ideas

- Preferred operator trust feel:
  “I can see what I’m allowed to do,
  what I’m not allowed to do,
  and what evidence will be written if I continue.”
- Preferred native mutation preview:
  “Actor: operator:ops-1.
  Action: pause cron entry.
  Resource: nightly sync.
  Effect: future claims stop until resumed.
  Reason: maintenance.
  Audit: one immutable operator event will be written.”
- Preferred bridge posture:
  “You are in the Oban Web bridge.
  Shared auth and redaction apply here.
  Use Powertools-native pages for audited mutations.”
- Preferred cron evolution:
  keep its lower-friction posture,
  but lift it onto the same durable preview and atomic audit model as Lifeline.
- Preferred shift-left posture:
  downstream GSD agents should default to these recommendations rather than reopening them unless a later implementation constraint clearly forces a revisit.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone authority
- `.planning/ROADMAP.md` — Phase 10 scope, dependency on Phase 9, and Phase 11 follow-on.
- `.planning/PROJECT.md` — host-owned OSS posture, least-surprise operator intent, and active v1.1 goals.
- `.planning/REQUIREMENTS.md` — `HST-02` as the requirement this phase closes.
- `.planning/STATE.md` — current milestone posture and explicit Phase 10 next-action framing.
- `.planning/MILESTONE-ARC.md` — host-owned, bridge-first, explain-then-act, and telemetry-boundary principles.

### Prior phase decisions that constrain Phase 10
- `.planning/phases/4-CONTEXT.md` — preview-first repair semantics, durable preview, reason-required dangerous actions, and evidence-first operator trust.
- `.planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md` — auth-before-preview, explicit permission posture, and disabled-with-explanation precedent.
- `.planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md` — resolved-state continuity, durable audit visibility, and least-surprise closure semantics.
- `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md` — shared auth/display seams, explicit audit principal, bounded bridge contract, and support-truth boundary.

### Current implementation targets
- `README.md` — public route/bridge/support-truth contract as currently documented.
- `lib/oban_powertools/web/live_auth.ex` — shared `on_mount`, page auth, action auth, and durable-principal gate.
- `lib/oban_powertools/web/router.ex` — native route tree and optional bridge mount contract.
- `lib/oban_powertools/web/oban_web_bridge.ex` — current bridge access mapping and formatting posture.
- `lib/oban_powertools/web/cron_live.ex` — current thin preview UX and disabled-control semantics.
- `lib/oban_powertools/cron.ex` — cron mutation/audit flow that needs Phase 10 coherence hardening.
- `lib/oban_powertools/web/lifeline_live.ex` — strongest current example of consequence preview and inline audit context.
- `lib/oban_powertools/lifeline.ex` — durable preview and transactional execute precedent.
- `lib/oban_powertools/web/audit_live.ex` — global audit index posture.
- `lib/oban_powertools/web/workflows_live.ex` — read-only workflow inspection surface that should stay coherent with the shared policy story.
- `test/oban_powertools/web/live/cron_live_test.exs` — permission/preview/audit-principal baseline for cron.
- `test/oban_powertools/web/live/lifeline_live_test.exs` — durable preview, reason, execute, and audit-history baseline for Lifeline.
- `test/oban_powertools/web/router_test.exs` — current bridge mount and resolver invariants.

### Product and project guidance
- `prompts/oban_powertools_context.md` — personas, domain language, and operational-product posture.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — hybrid shell strategy, bridge-first guidance, and operator trust emphasis.
- `prompts/oban-powertools-deep-research-original-prompt.md` — maintainer intent around batteries-included DX, support-truth honesty, and ecosystem lessons.

### Support-truth note
- External official docs and ecosystem examples informed this context, especially Phoenix LiveView security guidance, `Ecto.Multi`, Oban Web resolver/access patterns, and admin dashboard read-only models from adjacent ecosystems.
  Those are advisory inputs, not canonical downstream refs, because they are not repo-local artifacts.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/oban_powertools/web/live_auth.ex`: existing shared auth and principal gate that should remain the single native authorization adapter.
- `lib/oban_powertools/lifeline.ex` and `lib/oban_powertools/web/lifeline_live.ex`: strongest in-repo precedent for durable preview, drift handling, execute safety, and inline audit visibility.
- `lib/oban_powertools/web/cron_live.ex`: existing disabled-with-explanation precedent and the simplest candidate for convergence onto the shared preview contract.
- `lib/oban_powertools/web/oban_web_bridge.ex`: current bounded bridge adapter that already enforces a conservative read-only contract.
- `lib/oban_powertools/audit.ex`: durable audit writer/reader that should remain the evidence authority.
- `lib/oban_powertools/runtime_config.ex` and `DisplayPolicy`: existing host-owned display seam to keep actor/reason rendering coherent across surfaces.

### Established Patterns
- Host-owned configuration and policy, library-owned adapters, is the repo’s preferred public integration model.
- Correctness-sensitive operator actions should be explicit, durable, and auditable.
- Native Powertools pages own Powertools-specific operator value; generic Oban inspection can remain in the bridge.
- Telemetry is a public API and must stay low-cardinality; rich operator evidence belongs in DB-backed audit paths.
- Phase 6 and Phase 7 already established least-surprise, auth-before-preview, and evidence-first behavior as the paved road.

### Integration Points
- A shared preview contract should connect native LiveViews, service-layer mutation APIs, preview retention/cleanup, and audit writes.
- Cron is the most immediate convergence target because it already has preview-first UX but lacks durable preview and transactional audit semantics.
- Bridge coherence should connect `LiveAuth`, the Oban Web resolver, display policy, and docs/test wording rather than broadening write surface area.
- Verification for Phase 10 should prove consistent permission/read-only/preview/reason/audit semantics across cron, lifeline, and bridge posture.

</code_context>

<deferred>
## Deferred Ideas

- Broad bridge write support inside `/ops/jobs/oban`.
- A full native replacement for generic Oban Web job and queue administration.
- A generalized RBAC/ABAC policy DSL or in-app role editor.
- Two-person approvals or more advanced approval workflows for dangerous actions.
- A global host-owned read-only runtime mode beyond the current per-action permission model.
- Rich cross-surface bulk mutation expansion before the shared preview contract is stable.

</deferred>

---

*Phase: 10-operator-ux-coherence-mutation-safety*
*Context gathered: 2026-05-21*
