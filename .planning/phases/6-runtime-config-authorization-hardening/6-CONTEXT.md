# Phase 6: Runtime Config & Authorization Hardening - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the remaining foundational runtime-safety gaps that were deliberately deferred from earlier phases:
installer/runtime wiring for required Powertools dependencies, and authorization ordering for cron mutation flows.

This phase is about making host integration explicit, safe, and unsurprising in real host-app conditions.
It is not a broader redesign of the auth model, not a general permissions framework, and not a new cron product surface.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Downstream GSD agents should treat the recommendations in this context as locked defaults and avoid reopening them unless a later choice would materially affect correctness, security, operator trust, or public integration shape.
- **D-02:** Shift decision defaults left for this project: prefer best-practice recommendations without re-asking, except for unusually high-impact product-semantic choices the user is likely to care about directly.

### Runtime Wiring Model
- **D-03:** Powertools should use explicit host-owned runtime wiring, not automatic inference, for core dependencies.
- **D-04:** The installer should write explicit host config for `:repo` and `:auth_module` rather than trying to infer either from `ecto_repos`, Oban config, or runtime discovery.
- **D-05:** Preferred adopter shape is explicit and boring:
  `config :oban_powertools, repo: MyApp.Repo, auth_module: MyAppWeb.ObanPowertoolsAuth`
- **D-06:** Existing explicit per-call overrides such as `opts[:repo]` may remain as advanced/internal escape hatches, but they are not the primary integration story and must not weaken the explicit default path.
- **D-07:** Do not infer the Powertools repo from repo ordering, default Oban instance config, or any “first repo wins” heuristic. Multi-repo and multi-instance ambiguity is a real footgun.

### Missing-Config Failure Posture
- **D-08:** Use a hybrid fail-fast posture with a strong bias toward explicit failure: required surfaces must fail immediately and clearly when required config is missing, while genuinely unused optional surfaces need not block unrelated usage.
- **D-09:** Persistence-backed runtime services and mutation-capable Powertools pages should fail immediately with precise setup errors if `:repo` is missing.
- **D-10:** Auth-gated Powertools web surfaces should fail explicitly before exposing page state, preview state, or mutation affordances if `:auth_module` is missing.
- **D-11:** Soft degradation through silent `nil` actor handling, implicit falsey auth, or delayed `repo` crashes is out of bounds for this phase.
- **D-12:** Runtime validation should be centralized so every repo/auth lookup uses one consistent config contract and one consistent error story.

### Cron Authorization and Preview Semantics
- **D-13:** Cron mutation preview is a privileged operation. Unauthorized viewers must not be allowed to open preview state and then be denied only at confirm time.
- **D-14:** Preview authorization should be checked in the preview event path itself, not only on confirm.
- **D-15:** In v1, preview permission should inherit from the corresponding mutation permission rather than introducing a separate `preview_*` permission matrix.
- **D-16:** No preview telemetry, preview assignments, or preview-side state should be emitted/generated for unauthorized attempts.

### Unauthorized-Action Presentation
- **D-17:** For users who can view cron pages but not perform some cron mutations, action controls should remain visible but disabled with a persistent explanation.
- **D-18:** Do not hide cron actions by default when the user can see the cron resource; disabled-with-explanation is the least-surprise admin UX for mixed viewer/operator roles.
- **D-19:** Do not use “clickable then denied” as the primary UX pattern. Server-side rejection remains mandatory as defense in depth, but the UI should communicate lack of permission before click.
- **D-20:** Explanations for disabled actions must be accessible and inline enough to avoid tooltip-only ambiguity.

### UX and Product Coherence
- **D-21:** Preserve the existing project direction of “explain, then act,” but make authorization a prerequisite for entering mutation preview flows.
- **D-22:** Read-only users may inspect cron entries, source badges, policies, and current state, but not privileged preview-state behavior for `pause`, `resume`, or `run now`.
- **D-23:** Error copy and disabled-state copy should be explicit about what is missing:
  either missing host configuration,
  or missing operator permission.

### the agent's Discretion
- Exact config helper API and error-module shape, provided runtime validation is centralized and explicit.
- Exact file placement between config helpers and web helpers, provided the host-owned config contract stays grep-able and stable.
- Exact disabled-control presentation details, provided they remain accessible, explanatory, and consistent across cron actions.

</decisions>

<specifics>
## Specific Ideas

- Treat this phase as a “remove ambiguity” pass:
  no hidden repo inference,
  no silent auth fallback,
  no preview-before-auth loophole.
- Preferred installer outcome is that a host app can grep for `config :oban_powertools` and immediately see the required integration contract.
- Preferred failure feel is:
  “Oban Powertools requires `:repo` to use cron/audit/workflow/lifeline persistence”
  or
  “Oban Powertools requires `:auth_module` before mounting native operator pages”
  rather than a later `UndefinedFunctionError` or falsey redirect mystery.
- Preferred cron UX feel:
  viewers can understand what exists,
  operators can act safely,
  unauthorized users never enter preview state,
  and disabled controls explain why action is unavailable.
- The user explicitly prefers a shift-left GSD posture:
  downstream agents should accept these recommendations by default and only escalate follow-up questions when the choice is unusually impactful.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and audit authority
- `.planning/ROADMAP.md` — Phase 6 scope, dependencies, gap-closure framing, and success criteria.
- `.planning/REQUIREMENTS.md` — `FND-01`, `FND-02`, and `ENG-03` requirement ownership and closure target.
- `.planning/STATE.md` — current milestone posture and explicit Phase 6 next action.
- `.planning/v1-v1-MILESTONE-AUDIT.md` — authoritative statement of the remaining installer/runtime wiring and cron auth-ordering defects.

### Prior phase decisions
- `.planning/phases/0-CONTEXT.md` — host-owned installer/auth posture and hybrid shell direction.
- `.planning/phases/2-CONTEXT.md` — explicit operator actions, auth gating, cron semantics, and explain-then-act posture.
- `.planning/phases/4-CONTEXT.md` — preview-first mutation safety and separate preview/execute authorization expectations.
- `.planning/phases/5-CONTEXT.md` — shift-left decision-making preference and explicit boundary against silently absorbing runtime ambiguity.

### Project research and product posture
- `.planning/research/SUMMARY.md` — host-owned, Ecto-native, operator-first architectural posture.
- `.planning/research/PITFALLS.md` — warnings against hidden state, direct UI bypasses, and operational ambiguity.
- `.planning/research/STACK.md` — Igniter/Ecto/Phoenix LiveView stack guidance.
- `prompts/oban_powertools_context.md` — domain language, product posture, and explicit host-owned OSS philosophy.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — hybrid UI strategy and operator-trust posture.
- `prompts/oban-powertools-deep-research-original-prompt.md` — maintainer intent around batteries-included DX, least surprise, and lessons learned from adjacent ecosystems.

### Current implementation targets
- `lib/mix/tasks/oban_powertools.install.ex` — current installer output and missing runtime config injection gap.
- `lib/oban_powertools/auth.ex` — current auth module lookup and silent-fallback behavior.
- `lib/oban_powertools/application.ex` — supervised runtime entrypoints affected by config posture.
- `lib/oban_powertools/web/live_auth.ex` — current page/action authorization boundary.
- `lib/oban_powertools/web/cron_live.ex` — current preview-before-auth defect and cron action UX.
- `lib/oban_powertools/cron.ex` — cron mutation behavior, audit, and telemetry flow.
- `config/test.exs` — current test-only wiring that Phase 6 must stop relying on as the real integration story.
- `test/mix/tasks/oban_powertools.install_test.exs` — current installer coverage baseline.
- `test/oban_powertools/web/live/cron_live_test.exs` — current cron auth and preview behavior baseline.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/oban_powertools.install.ex`: established Igniter-based installer entrypoint where explicit config injection should be added.
- `lib/oban_powertools/auth.ex`: natural place to centralize explicit auth-module lookup and fail-fast errors.
- `lib/oban_powertools/web/live_auth.ex`: existing page/action auth boundary that should remain the single UI authorization gatekeeper.
- `lib/oban_powertools/web/cron_live.ex`: current preview flow already isolates the relevant event path, making auth-before-preview a focused fix.
- `test/oban_powertools/web/live/cron_live_test.exs`: existing LiveView tests already capture the current confirm-time denial path and can be extended to assert no unauthorized preview entry.

### Established Patterns
- Host-owned installer output is the paved road; Powertools should generate explicit code/config rather than rely on hidden runtime magic.
- Persistence-backed semantics should route through explicit repo-aware APIs, not ambient assumptions.
- Operator actions are expected to be explicit, auditable, and safe by default.
- Native Powertools pages should make capability boundaries clear rather than surprising operators after click.

### Integration Points
- Runtime config hardening touches the installer, repo/auth lookup helpers, and any LiveView or service that currently reaches into `Application.get_env/2` ad hoc.
- Cron auth hardening should connect UI affordance state, preview event auth, and telemetry/audit semantics into one consistent permission model.
- Verification must prove behavior in host-app-like conditions rather than only the repo’s current test-only wiring.

</code_context>

<deferred>
## Deferred Ideas

- A broader cross-feature config abstraction beyond `repo` and `auth_module`.
- Separate read-only preview permissions distinct from mutation permissions.
- A general RBAC or policy DSL for all Powertools operator surfaces.
- Hiding unauthorized controls by role/persona as a future product decision for more sensitive surfaces.

</deferred>

---

*Phase: 6-runtime-config-authorization-hardening*
*Context gathered: 2026-05-20*
