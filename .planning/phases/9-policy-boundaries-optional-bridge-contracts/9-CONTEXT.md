# Phase 9: Policy Boundaries & Optional Bridge Contracts - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Freeze the remaining public policy seams for host adoption:
auth shape, actor attribution, redaction/formatting policy, and the supported optional `oban_web` bridge contract.

This phase is about making those hooks explicit, stable, and coherent across native Powertools pages and the optional bridge.
It is not the broader operator UX unification phase,
not a full RBAC framework,
and not a rewrite of Oban Web or the generic dashboard surface.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Downstream agents should treat the recommendations in this context as locked defaults and avoid reopening them unless a later choice would materially affect public contract shape, security, audit durability, or operator trust.
- **D-02:** Shift decision defaults left for this project: prefer decisive best-practice recommendations without re-asking, except for unusually high-impact public-semantic changes the user is likely to care about directly.

### Policy Architecture
- **D-03:** Phase 9 should freeze a coherent two-seam policy stack:
  one host-owned `auth_module` for actor resolution, authorization, and audit principal derivation;
  and one host-owned `display_policy` for redaction and presentation.
- **D-04:** Powertools should own all adapters over those seams:
  native LiveView auth helpers,
  mutation service wiring,
  and the optional `Oban.Web.Resolver` bridge adapter.
- **D-05:** Do not make hosts define separate policy contracts for native Powertools pages and the optional `oban_web` bridge.
  The bridge must adapt the same Powertools-owned action/resource vocabulary and display policy.

### Auth Contract Shape
- **D-06:** Keep `config :oban_powertools, auth_module: MyAppWeb.ObanPowertoolsAuth` as the public config key for compatibility with the Phase 8 install contract.
- **D-07:** Expand the auth behaviour from a boolean-only contract into an explicit policy contract:
  `current_actor/1` remains the actor-resolution entrypoint,
  and authorization should move to an explicit `authorize/4` style callback that returns `:ok` or `{:error, reason}` rather than a bare boolean.
- **D-08:** Authorization must use a Powertools-owned action/resource vocabulary rather than surface-specific or Oban-Web-specific semantics.
  Preferred shape is tuple-oriented and explicit, such as:
  `{:cron, :pause}`,
  `{:lifeline, :preview_repair}`,
  `{:audit, :view}`,
  `{:oban_web, :view}`.
- **D-09:** LiveView authorization should follow Phoenix’s documented posture:
  host router/pipeline protection is necessary but not sufficient;
  native Powertools pages still authorize on mount and on mutation events.
- **D-10:** The optional `oban_web` bridge must not become the primary host seam.
  Hosts configure Powertools auth once;
  the bridge resolver is library-owned and adapts that contract into Oban Web’s documented access model.

### Actor Attribution Contract
- **D-11:** Separate the rich host actor used for authorization/UI from the durable audit principal used for writes.
- **D-12:** The auth module should expose an explicit `audit_principal/1` callback that returns a stable, small principal envelope rather than relying on permissive late normalization.
- **D-13:** The principal contract should freeze now around:
  stable `id`,
  explicit `type` (for example `:user`, `:service`, `:system`),
  and optional operator-visible `label`.
- **D-14:** Human-triggered mutation flows must fail explicitly if the actor is authorized but no valid audit principal can be derived.
  Do not silently fall back to `inspect(actor)`,
  `nil`,
  or session heuristics.
- **D-15:** Mutation services should accept/pass explicit principal data and write audit evidence in the same transaction as the state change.
  Do not make process-local or ambient attribution the primary public contract.
- **D-16:** System-initiated flows should use explicit system principals such as `system:heartbeat_writer` rather than anonymous `nil` actor ids.

### Redaction and Formatting Policy
- **D-17:** Freeze one host-owned `display_policy` seam for policy-sensitive presentation.
  It should cover native Powertools pages and the optional `oban_web` bridge.
- **D-18:** Keep evidence and display separate:
  durable tables continue to store raw evidence plus bounded helper fields;
  display policy is applied at render time rather than by mutating stored payloads into presentation strings.
- **D-19:** The display policy should be context-driven and library-rendered.
  The host returns structured display decisions for kinds such as job args, job meta, workflow result payloads, audit reasons, and actor labels;
  Powertools renders those through shared helpers/components rather than accepting arbitrary HTML.
- **D-20:** Native LiveViews must stop inventing page-local formatting/redaction helpers for policy-sensitive values.
  Use shared library helpers/components wired through the display policy so native pages and `/ops/jobs/oban` cannot drift.
- **D-21:** Ecto/log redaction remains a useful safety baseline, but it is not the Phase 9 contract by itself.
  Display policy must not rely only on `inspect/1`, schema redaction flags, or ad hoc string truncation.

### Optional `oban_web` Bridge Contract
- **D-22:** Keep the Phase 8 route and ownership contract unchanged:
  host owns the outer `/ops/jobs` shell and browser pipeline;
  Powertools owns the nested `/ops/jobs/oban` bridge mount.
- **D-23:** Phase 9 should add only a thin Powertools-owned bridge adapter over documented Oban Web hooks:
  `resolver:`,
  shared `on_mount`,
  formatter hooks,
  and action telemetry bridging where useful.
- **D-24:** The supported bridge contract should stop at:
  actor handoff,
  access mapping,
  shared redaction/formatting,
  and bounded audit/telemetry integration.
  Do not promise nav injection,
  shadow pages,
  wrapped generic mutations,
  or a pseudo-plugin system inside Oban Web.
- **D-25:** Do not allow the bridge to inherit Oban Web’s dangerous implicit full-access default.
  Powertools must provide an explicit resolver path so host policy remains least-surprise.

### Telemetry, Audit, and Support-Truth Guardrails
- **D-26:** Keep the public telemetry contract low-cardinality and bounded exactly as established in Phase 8.
  Actor ids, labels, reasons, rendered payloads, and sensitive values belong in durable audit/evidence paths, not in telemetry metadata.
- **D-27:** Audit schema can continue using the existing `actor_id` column in the short term, but the public contract should freeze `id`, `type`, and optional `label` now so planning can thread that shape consistently.
- **D-28:** Support truth for Phase 9 is policy parity, not full UX parity.
  Phase 10 owns consistent preview/read-only/reason/audit behavior across all operator surfaces.

### the agent's Discretion
- Exact module names beyond the public config keys and seam names, provided the host-owned vs library-owned ownership boundary stays explicit.
- Exact internal adapter placement between `Auth`, `LiveAuth`, display helpers, and the Oban Web resolver, provided hosts still configure one auth module and one display policy.
- Exact action/resource tuple names, provided they are explicit, stable, and shared by native pages, audit flows, and bridge access mapping.
- Exact audit metadata placement for principal `type` and `label`, provided the durable principal contract remains explicit and no permissive fallback is retained.

</decisions>

<specifics>
## Specific Ideas

- Preferred public contract shape:
  explicit host wiring,
  explicit actor resolution,
  explicit authorization outcome,
  explicit audit principal,
  explicit display policy,
  and thin library-owned adapters over those seams.
- Preferred operator trust posture:
  one policy story across native pages and the bridge,
  one redaction story across native pages and the bridge,
  and no situation where `/ops/jobs` hides data that `/ops/jobs/oban` reveals.
- Preferred durability posture:
  audit principals are small, typed, and stable;
  evidence is written with the state change;
  telemetry stays public and low-cardinality.
- Preferred bridge posture:
  extend Oban Web through documented hooks only.
  Do not build a shadow dashboard layer around undocumented internals.
- Preferred host DX posture:
  the installer contract remains familiar,
  host apps own policy logic,
  Powertools owns the plumbing,
  and downstream agents should default to these recommendations rather than reopening them.
- External ecosystem research that informed these decisions:
  Phoenix LiveView auth/on-mount guidance,
  Oban Web resolver and telemetry hooks,
  Sidekiq/GoodJob/Mission Control host-owned admin auth posture,
  and Elixir audit patterns built around explicit `Ecto.Multi` writes rather than ambient process metadata.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone authority
- `.planning/ROADMAP.md` — Phase 9 scope, dependency on Phase 8, and active milestone ordering.
- `.planning/PROJECT.md` — host-owned OSS posture, low-surprise product intent, and active v1.1 goals.
- `.planning/REQUIREMENTS.md` — `POL-01`, `POL-02`, and `PKG-03` ownership for this phase.
- `.planning/STATE.md` — current milestone posture and explicit Phase 9 next-action framing.
- `.planning/MILESTONE-ARC.md` — hybrid-shell, host-owned, and least-surprise architectural principles.

### Prior phase decisions that constrain Phase 9
- `.planning/phases/5-CONTEXT.md` — shift-left decision defaults and explicit provenance/audit posture.
- `.planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md` — host-owned runtime wiring, auth-before-preview, and explicit permission/error posture.
- `.planning/phases/6-runtime-config-authorization-hardening/6-PATTERNS.md` — established patterns for runtime config, `Auth`, and `LiveAuth`.
- `.planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md` — durable audit/evidence expectations and conservative operator-trust model.
- `.planning/phases/8-host-contract-install-surface/8-VERIFICATION.md` — frozen host-owned route/install contract, optional nested bridge shape, and telemetry public-API boundary.
- `.planning/phases/8-host-contract-install-surface/8-PATTERNS.md` — exact Phase 8 pattern map for runtime config, router, and auth helpers.

### Current implementation targets
- `README.md` — public install/mount/supervision/telemetry contract and the explicit Phase 9 deferral language.
- `lib/oban_powertools/auth.ex` — current auth behaviour and weak `actor_id/1` fallback that Phase 9 must replace.
- `lib/oban_powertools/runtime_config.ex` — centralized host-wiring lookup and config-key contract.
- `lib/oban_powertools/web/live_auth.ex` — current native LiveView auth adapter and mount/event authorization seam.
- `lib/oban_powertools/web/router.ex` — nested bridge shape and current Oban Web deferral boundary.
- `lib/oban_powertools/audit.ex` — audit storage seam that must receive stable principals.
- `lib/oban_powertools/web/cron_live.ex` — current mutation flow and actor passing for cron actions.
- `lib/oban_powertools/web/lifeline_live.ex` — current repair mutation flow, actor display, and audit expectations.
- `lib/oban_powertools/web/audit_live.ex` — current audit rendering posture.
- `lib/oban_powertools/web/workflows_live.ex` — native workflow page that will need shared display policy.
- `lib/oban_powertools/workflow/result.ex` — existing `redacted` flag and durable result evidence model.
- `lib/oban_powertools/workflow/runtime.ex` — workflow evidence writes and payload handling posture.
- `test/oban_powertools/auth_test.exs` — current auth/runtime config expectations.
- `test/oban_powertools/web/router_test.exs` — current bridge-mount invariants and explicit no-`resolver:` assertion.
- `test/oban_powertools/web/live/cron_live_test.exs` — current preview/auth/audit expectations for cron.
- `test/oban_powertools/web/live/lifeline_live_test.exs` — current actor/audit/reason expectations for Lifeline.
- `test/support/test_auth.ex` — current minimal host-auth test double and permission model.

### Product and ecosystem posture docs
- `prompts/oban_powertools_context.md` — domain language, personas, host-owned posture, and day-0/day-2 goals.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — hybrid shell strategy, optional bridge posture, and operator UX principles.
- `prompts/oban-powertools-deep-research-original-prompt.md` — ecosystem lessons, OSS support-truth posture, and best-in-class DX expectations.

### Support-truth note
- External web research informed this context, especially Phoenix LiveView auth guidance, Oban Web resolver/telemetry hooks, and comparable mounted-ops libraries in other ecosystems.
  Those sources guided the recommendations but are not canonical downstream refs because they are not repo-local artifacts.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/oban_powertools/runtime_config.ex`: established, centralized config contract pattern for host-owned runtime seams.
- `lib/oban_powertools/auth.ex`: current public auth seam to evolve rather than replace.
- `lib/oban_powertools/web/live_auth.ex`: existing native LiveView adapter where `current_actor`, authorization, and future principal assignment can converge.
- `lib/oban_powertools/web/router.ex`: already owns the exact nested bridge shape and is the right place to add a thin resolver-based bridge contract.
- `lib/oban_powertools/audit.ex`: durable audit writer/reader that should accept stable principals instead of loose strings.
- `lib/oban_powertools/workflow/result.ex`: existing `redacted` marker that can remain evidence-oriented while display policy handles rendering.
- `test/oban_powertools/auth_test.exs` and LiveView tests: strong baseline for fail-fast config, auth gating, and mutation-audit verification.

### Established Patterns
- Host-owned configuration and library-owned adapters are already the repo’s preferred public-integration pattern.
- Preview/reason/audit-sensitive flows are expected to authorize explicitly and preserve durable evidence.
- Public telemetry is deliberately bounded and low-cardinality; rich operator evidence belongs in tables and UI.
- Optional dependency bridges should use documented hooks and stay narrow rather than becoming shadow abstractions.

### Integration Points
- Auth behaviour, LiveView auth helper, mutation services, audit writes, and the optional Oban Web resolver need to align on one shared action/resource vocabulary.
- Display policy must connect native page render helpers and Oban Web formatter hooks so redaction cannot drift by surface.
- Planning/tests must prove both host-owned seams:
  auth/principal derivation,
  and display-policy-driven redaction/formatting across native pages and the bridge.

</code_context>

<deferred>
## Deferred Ideas

- Full UX parity across native Powertools pages and every Oban Web bridge action — Phase 10.
- Rich RBAC/ABAC DSLs, policy composition frameworks, or in-app role editors.
- Full native replacement of generic Oban Web tables/charts/actions.
- Persisted display summaries or HTML snapshots as primary evidence storage.
- Broad docs/example-app/support-truth proof for these seams — Phase 11.

</deferred>

---

*Phase: 9-policy-boundaries-optional-bridge-contracts*
*Context gathered: 2026-05-21*
