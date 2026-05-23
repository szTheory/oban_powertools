# Phase 15: Upgrade Lane, Support Truth & Public Docs Integrity - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the synthetic upgrade proof with one real supported-host upgrade lane, then align public
support-truth, production-hardening, troubleshooting, and compatibility docs with what the
fixture and regression suite actually prove.

This phase is about making the public host contract more honest and more maintainable:
one supported upgrade source lane,
one real upgrade proof path,
sharper support-truth language,
and a disciplined boundary between executable contract and narrative guidance.

This phase does not broaden the optional bridge contract,
does not add new runtime capability,
and does not create a large compatibility matrix that CI cannot prove.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Shift recommendation burden left by default for this phase and downstream GSD work. Planners and implementers should treat the decisions below as locked defaults unless a later choice would materially widen the public support promise or create a new maintainer burden.
- **D-02:** Optimize for support-truth honesty, least surprise, and maintainer DX over broader but weaker upgrade or compatibility claims.
- **D-03:** Keep the native `/ops/jobs` shell as the primary public surface. The optional `/ops/jobs/oban` bridge remains additive and narrower everywhere in docs and proof.

### Supported Upgrade Source Lane
- **D-04:** Support one explicit upgrade source lane, not a fuzzy family of historical hosts.
- **D-05:** The supported source lane is a real native-first Phoenix host generated from `mix phx.new`, using Postgres/Ecto, with Powertools already installed, `repo` and `auth_module` configured, the host-owned `/ops/jobs` scope already mounted, and Powertools migrations already present.
- **D-06:** The supported source lane intentionally starts before the explicit `display_policy` contract is in place. The core upgrade step is moving that host shape onto the required `display_policy` posture and current support-truth docs.
- **D-07:** Public docs must describe this lane in host-shape terms, not internal phase-number terms like “Phase 8/9/10.”
- **D-08:** Bridge-enabled source hosts, manually diverged hosts, partially adopted hosts, and hosts missing `repo`, `auth_module`, or `/ops/jobs` are best-effort rather than supported.

### Upgrade Proof Architecture
- **D-09:** Replace the current synthetic in-place config rewrite with one archived historical upgrade-source fixture generated once from an exact pre-`display_policy` commit.
- **D-10:** Keep the current canonical fixture for current-state native-first, first-session, and optional-bridge proof. Add a second, frozen historical fixture only for the upgrade lane.
- **D-11:** The upgrade lane should point the historical fixture at the current library, apply only the documented upgrade actions, run dependency/install steps and migrations, then prove one meaningful post-upgrade native behavior.
- **D-12:** Do not use full historical generator replay in normal CI. Toolchain drift, network drift, and old installer behavior would create noise unrelated to the host contract being claimed.
- **D-13:** If provenance insurance is needed, use a maintainer-only regeneration script from the exact historical commit, but keep that out of the hot PR proof path.

### Support-Truth Messaging
- **D-14:** Use a sharp layered support-truth contract across README and guides: precise, repeated, and confidence-building, not soft ambiguity and not fatalistic “as-is” nihilism.
- **D-15:** Public docs must distinguish five buckets explicitly:
  supported,
  tested,
  best-effort,
  host-owned,
  and intentionally unsupported.
- **D-16:** `Supported` covers the native `/ops/jobs` shell, the host-owned integration contract, the canonical upgrade lane, and the optional `/ops/jobs/oban` bridge only as a read-only inspection annex.
- **D-17:** `Tested` covers the fresh-host install path, the canonical first-session proof, the native-first fixture lane, the optional-bridge render lane, docs contract assertions, and the real supported upgrade lane.
- **D-18:** `Best-effort` covers semver-allowed combinations outside the tested matrix, bespoke host shells beyond the documented mount shape, unusual reverse-proxy/session setups, and bridge behavior beyond the bounded contract.
- **D-19:** `Host-owned` must stay explicit: auth policy, actor/session lookup, display/redaction policy, outer route scope, browser pipeline, reverse-proxy and WebSocket/session behavior, seeded operator data, and whether to expose the bridge in production.
- **D-20:** `Intentionally unsupported` includes bridge write parity, hidden fallback behavior when required config is missing, non-Postgres support, and broad compatibility claims outside verified lanes.
- **D-21:** Separate product-support posture from support-truth posture. It is acceptable to state there is no commercial support, but docs must not collapse that into “nothing here is dependable.”

### Docs-To-Proof Enforcement Boundary
- **D-22:** Use layered claim-based enforcement as the steady-state posture.
- **D-23:** Executable contract should cover:
  installer-backed host setup,
  required config keys,
  router mount shape,
  missing-config fail-fast behavior,
  native-first compile/reset behavior,
  the canonical first native audited mutation,
  optional bridge read-only render,
  and the real supported upgrade lane.
- **D-24:** Docs contract checks should stay narrow and stable: canonical commands, paths, seam names, tested-lane names, support-truth bullets, and “best-effort outside tested lanes” language.
- **D-25:** Do not treat most guide prose as exact-string spec. Hardening checklists, troubleshooting advice, and operational caveats should remain narrative guidance unless the library actually guarantees or rejects the condition at runtime.
- **D-26:** Do not expand into broad browser-E2E proof for this phase. Compile, migrate/reset, mount, and one meaningful native post-upgrade action are the right proof depth.

### the agent's Discretion
- Exact naming of the historical upgrade fixture and workflow lane, provided the source lane remains singular and explicit.
- Exact post-upgrade proof action, provided it is native, meaningful, deterministic, and aligned with the existing first-session/operator contract.
- Exact docs section structure and marker placement, provided the five support-truth buckets remain explicit and consistently enforced.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone authority
- `.planning/ROADMAP.md` — Phase 15 goal, dependency on Phase 14, and requirement ownership for `PKG-02`, `HST-03`, and `DOC-02`.
- `.planning/PROJECT.md` — host-owned OSS posture, native-first operator surface, and active v1.1 adoption-hardening goals.
- `.planning/REQUIREMENTS.md` — exact requirement language for `PKG-02`, `HST-03`, and `DOC-02`.
- `.planning/STATE.md` — current milestone posture and explicit next action for Phase 15.

### Prior phase decisions that constrain Phase 15
- `.planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md` — one canonical host path, layered proof posture, compatibility-promise discipline, and support-truth messaging defaults.
- `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md` — repaired installer path, curated fixture honesty, and first-session proof threshold.
- `.planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md` — native-first support story, bounded optional bridge, and proof-lane separation.
- `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md` — additive evidence-repair posture and requirement-to-proof honesty.

### Current public docs that Phase 15 must realign
- `README.md` — public install, support-truth, and guide entrypoint language.
- `guides/installation.md` — day-0 host-owned setup path and required seam contract.
- `guides/first-operator-session.md` — canonical native first-session proof story.
- `guides/upgrade-and-compatibility.md` — current upgrade lane and compatibility wording that Phase 15 must narrow and make real.
- `guides/optional-oban-web-bridge.md` — bounded bridge posture and caveats.
- `guides/support-truth-and-ownership-boundaries.md` — host-vs-library contract and support-truth vocabulary.
- `guides/production-hardening.md` — production seam checklist that should stay narrative unless explicitly guaranteed.
- `guides/troubleshooting.md` — fail-fast setup errors and operator-host caveats.
- `guides/example-app-walkthrough.md` — canonical fixture posture and provenance language.

### Current proof and fixture surfaces
- `.github/workflows/host-contract-proof.yml` — current proof-lane split and CI naming.
- `test/support/example_host_contract.ex` — current fixture-copy and synthetic upgrade-lane helper that Phase 15 should replace.
- `test/support/fresh_host_contract.ex` — separate fresh-host install proof harness.
- `test/oban_powertools/example_host_contract_test.exs` — native-only, bridge-enabled, upgrade, and first-session fixture proof expectations.
- `test/oban_powertools/fresh_host_contract_test.exs` — installer-backed fresh-host proof.
- `test/oban_powertools/docs_contract_test.exs` — docs contract boundary and current exact wording locks.
- `examples/phoenix_host/README.md` — canonical fixture support-truth and provenance posture.
- `examples/phoenix_host/config/config.exs` — current config shape for the canonical host contract.
- `examples/phoenix_host/lib/phoenix_host_web/router.ex` — host-owned route mount and nested bridge shape.

### Product posture and research inputs
- `prompts/oban_powertools_context.md` — personas, JTBDs, domain language, host-owned philosophy, and day-0/day-2 product posture.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — native-first shell plus optional bridge strategy and support-truth guidance.
- `prompts/oban-powertools-deep-research-original-prompt.md` — shift-left recommendation preference, OSS maintainer posture, and ecosystem lessons emphasis.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/support/example_host_contract.ex`: already provides the lane-oriented fixture-copy harness; this is the natural place to swap out the synthetic upgrade path for a real archived historical source fixture.
- `test/support/fresh_host_contract.ex`: already isolates the fresh-host generator path, which means Phase 15 does not need to overload upgrade proof with install-path concerns.
- `examples/phoenix_host/*`: remains the canonical current-state host contract fixture for native-first, first-session, and optional-bridge proof.
- `test/oban_powertools/docs_contract_test.exs`: provides a low-cost guardrail for stable public claims and can be narrowed to claim-based assertions instead of broader wording locks.
- `.github/workflows/host-contract-proof.yml`: already expresses a layered proof model with structural, fresh-host, native-first, first-session, bridge, and upgrade lanes.

### Established Patterns
- One canonical curated fixture plus separate proof lanes is already the repo’s preferred architecture.
- Host-owned router, auth, display-policy, runtime config, and seeded data are treated as public seams, not hidden library internals.
- Native pages own audited mutations; the optional bridge is bounded, read-only, and intentionally narrower.
- Public support truth is expected to follow executable proof instead of marketing breadth.

### Integration Points
- Upgrade proof must connect the historical source fixture, the upgrade helper, the workflow lane, and the upgrade guide so they all describe the same source host and the same upgrade steps.
- Docs alignment must connect README, upgrade guide, support-truth guide, production-hardening guide, troubleshooting guide, and docs-contract assertions around one shared vocabulary for supported vs tested vs best-effort.
- The historical upgrade fixture must carry durable provenance documentation so maintainers can tell which old host shape it represents and avoid silently modernizing it into a fake source host.

</code_context>

<specifics>
## Specific Ideas

- Preferred Phase 15 outcome:
  “A maintainer can point to one documented upgrade source lane, one real proof lane, and one coherent support-truth vocabulary without caveats fighting each other.”
- The recommended posture is cohesive rather than locally optimized:
  narrow supported upgrade scope,
  real deterministic proof,
  sharp docs language,
  and only claim-based contract enforcement.
- Lessons carried from adjacent tools:
  mounted operator/admin surfaces work best when host auth and routing are explicit,
  optional dashboard bridges should not masquerade as co-equal product surfaces,
  and upgrade promises should be guide-shaped and versioned rather than broad narrative reassurance.
- User preference to preserve:
  shift recommendations left within GSD and downstream planning by default,
  except where a future choice would materially widen the public contract or create a new support burden.

</specifics>

<deferred>
## Deferred Ideas

- Supporting multiple historical upgrade source lanes in CI — defer unless real adopter volume justifies a permanently wider proof matrix.
- Full historical generator replay on every PR — defer to a maintainer-only regeneration check if provenance reassurance becomes necessary.
- Broad browser-E2E coverage for upgrade proof — outside the proof depth required for this phase.
- Expanding docs contract checks into full prose snapshots — explicitly rejected unless docs become the primary product surface rather than a support-truth layer.

</deferred>

---

*Phase: 15-upgrade-lane-support-truth-public-docs-integrity*
*Context gathered: 2026-05-23*
