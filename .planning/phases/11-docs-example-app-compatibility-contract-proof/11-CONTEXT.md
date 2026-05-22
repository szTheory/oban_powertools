# Phase 11: Docs, Example App, Compatibility & Contract Proof - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the public host contract through docs, example-app flows, compatibility guidance, and automated verification.

This phase is about making adoption predictable:
a developer should be able to install Powertools, reach a first successful operator session,
understand what is host-owned versus library-owned,
understand what is and is not supported,
and trust that the documented contract is continuously verified.

This phase is not a broad new runtime capability milestone,
not a full native replacement for generic Oban Web UI,
and not a marketing/demo-app phase detached from the real installer and host-owned seams.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Downstream agents should treat the recommendations in this context as locked defaults and avoid reopening them unless a later choice would materially affect public contract shape, upgrade/support truth, or maintainer cost.
- **D-02:** Shift docs/adoption/support-truth hardening left by default in GSD and downstream planning for this project.
  Prefer decisive recommendations over re-asking unless the choice would materially change the public host contract or support guarantee.
- **D-03:** Phase 11 should optimize for least surprise over maximum demo polish.
  If a choice improves honesty, cohesion, and long-term maintainability at the cost of a flashier showcase, choose the honest/maintainable path.

### Example App Strategy
- **D-04:** Use one generator-driven fixture app as the supported example app.
  It should be produced from the real paved road:
  `mix phx.new` plus `mix oban_powertools.install`,
  then kept intentionally thin.
- **D-05:** Do not make the primary example a handcrafted “full product” demo app.
  That becomes a second product, drifts from the install contract, and creates support-truth ambiguity.
- **D-06:** Do not ship multiple public example apps for install/auth/bridge permutations as the default docs path.
  One canonical host shape is easier to understand and maintain.
- **D-07:** The example app must prove real host-owned seams rather than faking them:
  real router scope,
  real browser pipeline protection,
  real `auth_module`,
  real `display_policy`,
  and real optional `oban_web` behavior.
- **D-08:** The example app should include seeded operator data so docs can walk through a first successful operator session without requiring readers to infer setup steps.
- **D-09:** Support both `oban_web` enabled and disabled modes through the same canonical example path rather than through separate divergent examples.

### Documentation Architecture
- **D-10:** Use a short README backed by versioned HexDocs/ExDoc guides and the example app.
  HexDocs should be the canonical documentation surface, not a bespoke docs site.
- **D-11:** README should stay intentionally concise:
  project positioning,
  support-truth summary,
  60-second install,
  one router example,
  one optional `oban_web` note,
  and links to guides/example app.
- **D-12:** Split the rest of the docs into focused guides rather than growing the README into a wall of prose.
- **D-13:** Recommended guide structure:
  `Installation`,
  `First Operator Session`,
  `Upgrade & Compatibility`,
  `Production Hardening`,
  `Optional Oban Web Bridge`,
  `Troubleshooting`,
  `Support Truth / Ownership Boundaries`,
  and `Example App Walkthrough`.
- **D-14:** Upgrade guidance must be guide-shaped, not changelog-shaped.
  Translate version-to-version changes into concrete host actions:
  config changes,
  migration steps,
  optional dependency changes,
  and proof/verification expectations.
- **D-15:** Optional dependency guidance for `oban_web` must be first-class and explicit, not a footnote.
- **D-16:** Support-truth statements should be repeated deliberately across README, guides, and example app walkthrough where needed.
  Repetition is preferable to accidental ambiguity for this public contract.

### Compatibility Promise
- **D-17:** Publish a tested compatibility matrix plus best-effort tiers outside that matrix.
  Do not rely on vague narrative support language alone.
- **D-18:** The public promise should distinguish:
  tested/supported host combinations,
  tested native-only path,
  tested optional `oban_web` path,
  and best-effort/unproven combinations outside those lanes.
- **D-19:** Do not publish a broad exhaustive matrix that implies more support breadth than CI can prove.
- **D-20:** Do not use an overly narrow pinned-only compatibility posture unless future maintenance pressure forces it.
  That would be unidiomatic for this ecosystem and would unnecessarily slow adoption.
- **D-21:** Native Powertools support and optional `oban_web` bridge support must be documented as separate support surfaces.
  The bridge remains narrower and must not inherit broader promises by implication.
- **D-22:** Version/support truth should align with actual dependency declarations in `mix.exs`, but docs must still spell out which combinations are actively tested versus merely semver-allowed.

### Contract Proof Strategy
- **D-23:** Use a layered proof stack rather than relying on source-level contract tests alone or building a giant demo app.
- **D-24:** Keep the existing fast unit/contract suite as the base layer for installer shape, route shape, and bridge policy invariants.
- **D-25:** Add one minimal Phoenix host fixture app that proves the real generator-backed install path end-to-end:
  install,
  compile,
  migrate,
  mount,
  and first operator-session behavior.
- **D-26:** Add two CI lanes for the fixture app:
  native-only (`oban_web` absent),
  and optional bridge enabled (`oban_web` present).
- **D-27:** Add narrow docs verification for canonical snippets and support-truth markers.
  Verify the install/router/config examples and key promises such as:
  bridge is read-only,
  host owns the outer `/ops/jobs` shell,
  native Powertools pages own audited mutations.
- **D-28:** Add an upgrade-proof lane for the documented supported upgrade path(s) in this milestone.
  Phase 11 should prove the path it documents rather than hand-wave upgrade confidence.
- **D-29:** Keep the fixture small and purpose-built.
  It is proof infrastructure and example infrastructure, not a second app to grow indefinitely.
- **D-30:** Proof should bias toward real host integration and optional-dependency truth,
  not toward expensive browser-E2E parity for every UI surface.

### Day-0 vs Day-2 Emphasis
- **D-31:** Use a balanced documentation posture with a strong day-0 lead-in and immediate day-2 follow-through.
- **D-32:** Concretely, Phase 11 should feel roughly `60/40` toward day-0 first success vs day-2 hardening/troubleshooting.
- **D-33:** README and the example app should optimize for first successful install and first successful operator session.
- **D-34:** The next docs hop after that initial success must be hardening and troubleshooting, not source-diving or issue archaeology.
- **D-35:** Do not let day-0 simplification hide the real host-owned seams:
  auth,
  display policy,
  telemetry boundaries,
  optional bridge posture,
  supervision/runtime wiring,
  and support-truth boundaries.

### Support-Truth and Ownership Messaging
- **D-36:** Keep Phase 10’s support-truth intact:
  native Powertools pages own audited mutations;
  the optional `/ops/jobs/oban` bridge stays a bounded read-only inspection surface.
- **D-37:** Documentation must make host-owned versus library-owned responsibilities explicit:
  host owns router scope, browser pipeline, auth policy implementation, and runtime config;
  library owns internal runtime helpers, pages, adapters, and the nested bridge plumbing.
- **D-38:** The example app and docs should show the real contract with reverse-proxy/WebSocket/auth caveats where they materially affect mounted operator UI behavior.
- **D-39:** Do not let the example app or docs imply broader bridge parity, hidden fallback behavior, or enterprise-style support commitments.

### the agent's Discretion
- Exact file layout for guides and example-fixture directories, provided the information architecture stays layered and the example stays generator-driven.
- Exact tested lane naming and CI wiring, provided the public docs distinguish tested support from best-effort support.
- Exact seed data and walkthrough steps for the first operator session, provided they exercise real host-owned seams and at least one native audited mutation plus bridge read-only behavior.
- Exact snippet/doc verification technique, provided canonical examples and support-truth markers cannot silently drift.

</decisions>

<specifics>
## Specific Ideas

- Preferred Phase 11 feel:
  “I can install this quickly,
  reach a real first operator session,
  see exactly what Powertools owns versus what my host app owns,
  and trust that the documented path is the same one CI proves.”
- Preferred example-app posture:
  a real generated Phoenix host,
  lightly seeded,
  intentionally thin,
  and close enough to the paved road that maintainers can regenerate or diff-check it against installer changes.
- Preferred docs posture:
  short README for orientation,
  versioned guides for everything operational,
  and no dependence on issue threads or source spelunking to understand support truth.
- Preferred compatibility posture:
  “these lanes are tested and supported;
  these other combinations may work but are not guaranteed.”
- Preferred proof posture:
  keep cheap structural tests,
  add one real host fixture,
  prove native-only and bridge-enabled paths separately,
  and verify docs/support-truth claims narrowly but continuously.
- Preferred GSD posture:
  when adoption-hardening questions arise in later phases,
  bias toward left-shifting explicit docs/support/proof work instead of letting public contract ambiguity accumulate.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone authority
- `.planning/ROADMAP.md` — Phase 11 goal and dependency on Phase 10.
- `.planning/PROJECT.md` — host-owned OSS posture, active v1.1 goals, and explicit support-truth/product positioning.
- `.planning/REQUIREMENTS.md` — `PKG-02`, `HST-03`, `DOC-01`, `DOC-02`, and `DOC-03`.
- `.planning/STATE.md` — current milestone posture and explicit next-action framing for docs/example-app/proof work.
- `.planning/MILESTONE-ARC.md` — bridge-first UI, host-owned posture, support-truth hardening, and shift-left decision rule.

### Prior phase decisions that constrain Phase 11
- `.planning/phases/8-host-contract-install-surface/8-VERIFICATION.md` — verified install/config/router/supervision/telemetry contract and residual note that installer proof is still structural rather than fixture-backed.
- `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md` — shared auth/display-policy seams, explicit principal contract, and bounded optional bridge contract.
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md` — support-truth that native pages own audited mutations and bridge remains read-only.

### Current implementation targets
- `README.md` — current public install/mount/support-truth/telemetry contract that Phase 11 must reorganize and extend without widening promises accidentally.
- `mix.exs` — current dependency ranges and optional `oban_web` declaration that compatibility guidance must respect.
- `lib/mix/tasks/oban_powertools.install.ex` — installer-backed public host path that the example and proof fixture must follow.
- `test/mix/tasks/oban_powertools.install_test.exs` — current source-level installer contract proof.
- `lib/oban_powertools/web/router.ex` — mounted route and bridge ownership contract.
- `test/oban_powertools/web/router_test.exs` — current route/bridge/read-only support-truth proof.
- `lib/oban_powertools/auth.ex` — public auth and audit-principal seam docs must teach correctly.
- `lib/oban_powertools/runtime_config.ex` — host-owned config seams and fail-fast setup expectations.
- `lib/oban_powertools/web/oban_web_bridge.ex` — read-only bridge posture and shared policy seam.
- `lib/oban_powertools/telemetry.ex` — public telemetry contract that hardening docs must treat as API.

### Product and repo-local research inputs
- `prompts/oban_powertools_context.md` — personas, JTBDs, host-owned/operator-first posture, and domain language.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — bridge-first UI architecture and support-truth guidance.
- `prompts/oban-powertools-deep-research-original-prompt.md` — lessons-learned framing, DX/operator focus, and left-shifted support-truth expectations.

### Support-truth note
- External ecosystem research informed this context:
  Phoenix/ExDoc/LiveDashboard/Oban/Oban Web patterns,
  plus adjacent admin-UI/job-system lessons from GoodJob, Sidekiq, Mission Control Jobs, and Flower.
  Those sources guide recommendations but are not canonical implementation refs because the downstream work should anchor on repo-local artifacts first.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/oban_powertools.install.ex`: already defines the generator-backed host contract that Phase 11 should prove and document, not replace.
- `test/mix/tasks/oban_powertools.install_test.exs`: cheap structural baseline for install contract proof that should remain as the fast layer.
- `lib/oban_powertools/web/router.ex` and `test/oban_powertools/web/router_test.exs`: strong existing route/bridge ownership proof surface.
- `lib/oban_powertools/auth.ex` and `lib/oban_powertools/runtime_config.ex`: public host seams that docs and example app must teach accurately.
- `lib/oban_powertools/web/oban_web_bridge.ex`: current bounded bridge adapter for the optional read-only path.
- `README.md`: current public contract text can be tightened into a short entrypoint and promoted into a fuller guide set.

### Established Patterns
- Host-owned configuration with library-owned adapters is the repo’s preferred public integration model.
- The bridge-first UI strategy is already locked:
  extend Oban Web where useful, but keep Powertools-native pages as the authoritative mutation surface.
- Public telemetry is treated as API and must stay low-cardinality.
- Support-truth has been getting narrowed and clarified phase by phase rather than widened optimistically.
- Structural proof already exists for public seams; Phase 11 should add real host-fixture proof without discarding those cheap localized tests.

### Integration Points
- The example app, docs, and proof fixture should all converge on the same installer-backed host shape so docs, CI, and public contract stay aligned.
- Compatibility docs need to connect `mix.exs` ranges, optional dependency behavior, and CI-tested lanes into one explicit support story.
- Hardening and troubleshooting guides need to connect auth/principal seams, display policy, bridge read-only truth, and runtime/supervision setup into one operator/developer story.
- Upgrade guidance and proof should connect milestone-to-milestone migration steps with the fixture app so `PKG-02` is evidence-backed rather than narrative-only.

</code_context>

<deferred>
## Deferred Ideas

- A handcrafted, productized showcase demo app with broader domain behavior than the host contract requires.
- Multiple public example apps for every configuration permutation.
- A bespoke documentation website separate from HexDocs/ExDoc.
- A wide compatibility cross-product matrix across many Elixir/Phoenix/Oban/`oban_web` versions beyond what CI can realistically prove.
- Browser-E2E parity proof for every native page and bridge surface.
- Any expansion of the bridge into a write-capable surface or pseudo-native mutation equivalent.

</deferred>

---

*Phase: 11-docs-example-app-compatibility-contract-proof*
*Context gathered: 2026-05-21*
