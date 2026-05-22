# Phase 12: Fresh Host Install Path & Example Fixture Repair - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Restore the documented day-0 install path so a fresh Phoenix host and the canonical example fixture
both prove the public host-owned setup contract end to end.

This phase repairs the real adoption path:
the installer must work again,
the example fixture must stop overstating provenance,
and the first successful operator session must be honestly provable.

This phase does not broaden the optional `oban_web` support surface,
does not turn the library into an app template,
and does not add broad browser-E2E parity for all operator pages.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Shift decision defaults left for this project and within GSD where possible. Downstream agents should prefer decisive recommendations over reopening choices unless a decision would materially change public contract shape, support truth, or maintainer burden.
- **D-02:** Phase 12 should optimize for least surprise and honest host-owned seams over demo polish or maximal installer magic.

### Installer Completion Threshold
- **D-03:** Phase 12 should repair the installer to a strong paved-road standard: after `mix phx.new` plus `mix oban_powertools.install`, a fresh host should be able to compile, migrate, and boot once the adopter completes only the true host-owned policy seams.
- **D-04:** The installer should own obvious library-side wiring and scaffolding:
  config insertion,
  router mount shape,
  Powertools migrations,
  and thin starter host seam modules where needed.
- **D-05:** The installer must not cross into fake business logic or app-template behavior. Real auth/session policy, production redaction rules, and domain-specific operator setup remain host-owned.
- **D-06:** Avoid maximal scaffolding that blurs host-vs-library ownership or generates misleading “works in demo, unsafe in production” defaults.
- **D-07:** Optional dependency behavior must remain explicit and bounded. Phase 12 should not preserve any compile-time or docs path that silently assumes `oban_web` is present.

### Example Fixture Provenance
- **D-08:** For Phase 12, the canonical fixture should follow an honest curated-fixture standard, not a showcase-demo standard.
- **D-09:** `examples/phoenix_host` must stay thin, real, and support-truth aligned:
  explicit auth seam,
  explicit display-policy seam,
  explicit host-owned router scope,
  explicit runtime wiring,
  and narrow seeded operator assumptions.
- **D-10:** The fixture README and regeneration path must clearly distinguish:
  what comes from `mix phx.new`,
  what comes from `mix oban_powertools.install`,
  and what remains irreducibly host-owned manual follow-up.
- **D-11:** The long-term direction is stricter generator provenance, but Phase 12 should not overclaim that standard until the installer and generated migration story are actually end-to-end trustworthy.
- **D-12:** Do not evolve the canonical fixture into a polished showcase app or second product. If richer demos ever exist later, they should be clearly non-canonical.

### First-Session Proof Depth
- **D-13:** Phase 12 should prove a functional paved road, not mere structural green checks and not broad browser parity.
- **D-14:** The minimum honest proof for `DOC-01` is:
  a fresh or fixture host can compile,
  run the required migrations/reset path,
  seed operator-visible data,
  and complete one real native operator flow that writes durable audit evidence.
- **D-15:** The single native proof flow should reinforce existing project support truth:
  native Powertools pages own audited mutations,
  and the optional `/ops/jobs/oban` bridge remains a bounded read-only inspection surface.
- **D-16:** Prefer idiomatic Phoenix/LiveView integration proof for the operator flow over expensive browser-E2E parity.
  The proof should be deterministic, CI-friendly, and focused on the exact day-0/day-1 contract this phase claims.
- **D-17:** Broad UI/E2E coverage across multiple native pages and the bridge is explicitly out of scope for Phase 12 unless required to close a concrete broken contract claim.

### the agent's Discretion
- Exact installer shape for starter host seam modules, provided generated code stays thin, explicit, and visibly host-owned.
- Exact audited mutation used for the first-session proof, provided it is native, deterministic, and representative of the public operator contract.
- Exact fixture diff/rebuild mechanism, provided maintainers can clearly compare generated output against the checked-in canonical host.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone authority
- `.planning/ROADMAP.md` — Phase 12 goal, dependency on Phase 11, and milestone ordering.
- `.planning/PROJECT.md` — host-owned OSS posture, least-surprise product intent, and v1.1 adoption-hardening goals.
- `.planning/REQUIREMENTS.md` — `PKG-01` and `DOC-01` traceability for this phase.
- `.planning/STATE.md` — current milestone posture and recent closeout context.
- `.planning/milestones/v1.1-MILESTONE-AUDIT.md` — exact broken-flow evidence Phase 12 is meant to close.

### Prior phase decisions that constrain Phase 12
- `.planning/phases/8-host-contract-install-surface/8-VERIFICATION.md` — original install/config/router/migration contract claims that must become end-to-end truthful again.
- `.planning/phases/8-host-contract-install-surface/8-PATTERNS.md` — established installer and host-wiring patterns.
- `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md` — host-owned auth/display seams and bounded optional bridge contract.
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md` — native audited mutation ownership and bridge read-only support truth.
- `.planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md` — example-host, docs, and layered-proof decisions that Phase 12 is repairing rather than replacing.
- `.planning/phases/11-docs-example-app-compatibility-contract-proof/11-02-PLAN.md` — intended canonical fixture posture and proof expectations.
- `.planning/phases/11-docs-example-app-compatibility-contract-proof/11-04-PLAN.md` — intended docs/example-host proof stack and lane naming.

### Current implementation targets
- `lib/mix/tasks/oban_powertools.install.ex` — installer behavior, generated host seams, router insertion, and migration generation pipeline.
- `lib/oban_powertools/runtime_config.ex` — fail-fast host wiring contract for runtime seams.
- `lib/oban_powertools/web/router.ex` — host-owned outer shell plus optional nested bridge contract.
- `README.md` — public 60-second install contract and support-truth copy.
- `guides/installation.md` — exact day-0 host-owned setup path.
- `guides/first-operator-session.md` — stated definition of a successful first operator session.
- `guides/example-app-walkthrough.md` — current claim about what the canonical fixture proves.
- `guides/optional-oban-web-bridge.md` — explicit bounded bridge posture.
- `guides/support-truth-and-ownership-boundaries.md` — host-vs-library ownership contract.
- `examples/phoenix_host/README.md` — fixture support-truth and provenance wording.
- `examples/phoenix_host/regenerate.sh` — current regeneration/provenance story.
- `examples/phoenix_host/config/config.exs` — example host runtime config shape.
- `examples/phoenix_host/config/runtime.exs` — runtime caveats and deployment posture.
- `examples/phoenix_host/lib/phoenix_host/application.ex` — host supervision shape.
- `examples/phoenix_host/lib/phoenix_host_web/router.ex` — example host route ownership and mount contract.
- `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex` — example auth seam.
- `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_display_policy.ex` — example display-policy seam.
- `examples/phoenix_host/priv/repo/seeds.exs` — current first-session seed story.
- `examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs` — current fixture migration baseline.
- `test/mix/tasks/oban_powertools.install_test.exs` — current structural installer contract assertions.
- `test/support/example_host_contract.ex` — fixture proof harness.
- `test/oban_powertools/docs_contract_test.exs` — docs contract markers currently enforced.

### Product and research posture
- `prompts/oban_powertools_context.md` — personas, JTBDs, host-owned philosophy, and lessons-learned framing.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — bridge-first architecture, support-truth posture, and operator UX guidance.
- `prompts/oban-powertools-deep-research-original-prompt.md` — explicit DX, support-truth, ecosystem-lessons, and shift-left design intent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/oban_powertools.install.ex`: existing Igniter-based installer entrypoint where the Phase 12 public paved road must be repaired rather than replaced.
- `lib/oban_powertools/runtime_config.ex`: centralized fail-fast contract pattern for missing host wiring.
- `lib/oban_powertools/web/router.ex`: established outer `/ops/jobs` plus nested optional bridge ownership boundary.
- `examples/phoenix_host/*`: thin fixture host already carrying the intended auth, display-policy, router, runtime, and seed seams.
- `test/support/example_host_contract.ex`: reusable proof helper for compile/reset/seed contract lanes.
- Existing native LiveView tests in cron/lifeline/audit flows: strong precedent for proving native operator behavior without broad browser E2E.

### Established Patterns
- Host-owned configuration and library-owned adapters are already the repo’s preferred public integration pattern.
- Public support truth is meant to stay explicit, narrow, and tied to what the docs plus tests genuinely prove.
- Native Powertools pages own audited mutations; the optional bridge remains bounded and read-only.
- Phase verification should be layered: cheap structural contract tests first, then targeted real-host proof for claims that matter.

### Integration Points
- Installer repair must connect docs, fixture regeneration, and proof harnesses so the same public contract is described, generated, and tested.
- Fixture provenance work must connect `examples/phoenix_host`, `regenerate.sh`, README/guides wording, and contract tests.
- First-session proof must connect the fixture app, Powertools migrations/tables, seeded actor story, and one real native operator mutation path.

</code_context>

<specifics>
## Specific Ideas

- Preferred Phase 12 outcome:
  “A fresh Phoenix host can follow the documented paved road, reach `/ops/jobs`, and complete one real native operator action without hidden manual archaeology.”
- Preferred installer posture:
  generate the obvious host-facing seams and library wiring,
  but stop at the boundary where business auth/session policy and real production display rules become host-specific.
- Preferred fixture posture:
  canonical, thin, diffable, and obviously host-owned,
  not a polished showcase app.
- Preferred proof posture:
  one real native operator flow with durable audit evidence,
  plus bounded bridge smoke truth,
  not a sprawling UI matrix.
- User preference to carry forward:
  shift recommendations left within GSD and downstream planning by default,
  except for unusually impactful public-semantic choices the user is likely to care about directly.
- Ecosystem lessons to honor:
  successful mounted operator/admin tools keep host auth and routing explicit,
  examples should not become second products,
  and day-0 support claims should be backed by deterministic proof rather than structural source assertions alone.

</specifics>

<deferred>
## Deferred Ideas

- Broad browser-E2E or multi-page UI parity across native and bridge surfaces — not needed to close the Phase 12 contract truthfully.
- Turning Powertools into a near-app-template with maximal generated business logic — outside the intended library posture.
- Shipping a polished showcase/demo host separate from the canonical contract fixture — future optional artifact only if clearly non-canonical.

</deferred>

---

*Phase: 12-fresh-host-install-path-example-fixture-repair*
*Context gathered: 2026-05-22*
