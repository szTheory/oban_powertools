# Phase 13: Native-Only Optional Dependency Contract Proof - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the native-only host path compile and verify cleanly without `oban_web`, while preserving
the bounded bridge contract when the dependency is present.

This phase closes the optional-dependency proof gap honestly:
native-only must mean the host truly works when `oban_web` is absent,
and bridge-enabled must prove only the bounded read-only bridge contract Powertools actually owns.

This phase does not broaden the bridge into a parity surface,
does not create multiple competing public example hosts,
and does not turn optional-dependency proof into a broad browser-E2E/dashboard-rebuild effort.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Shift recommendations left by default for this project and within GSD. Downstream agents should treat the recommendations here as locked defaults unless a later choice would materially change public contract shape, support truth, or maintainer burden.
- **D-02:** Phase 13 should optimize for least surprise, support-truth honesty, and host-owned explicitness over proof theatrics or broader bridge ambition.

### Native-Only Proof Strictness
- **D-03:** `native-only` must mean `oban_web` is actually absent from the proof host for that lane, not merely present-but-unused.
- **D-04:** The canonical native-only proof should remove `oban_web` from the copied proof host before `mix deps.get`, then run the normal compile/reset/native-proof flow.
- **D-05:** A supplemental `--no-optional-deps` style compile check is welcome later as an extra guard, but it is not the primary definition of native-only truth.
- **D-06:** Do not redefine Phase 13 around “native screens do not call bridge code.” The requirement is stronger: host apps that omit `oban_web` entirely must still compile and verify cleanly.

### Proof Host Shape
- **D-07:** Keep one canonical curated fixture host as the primary proof host for Phase 13.
- **D-08:** Preserve the separate fresh-host installer lane as the day-0 generator backstop, but do not replace the canonical fixture with generated-per-lane hosts for this phase.
- **D-09:** Allow only narrow, auditable lane rewrites in the proof harness:
  dependency presence/absence,
  and similarly small contract toggles if needed.
  Do not let the harness evolve into a hidden second fixture generator.
- **D-10:** Do not introduce separate checked-in native-only and bridge-enabled fixture trees unless a future phase intentionally changes the public host contract into multiple supported host shapes.

### Bridge-Enabled Regression Scope
- **D-11:** The bridge-enabled lane should prove a bounded host contract plus one render smoke, not parity with native Powertools pages and not broad upstream-UI behavior.
- **D-12:** The bridge lane should cover only Powertools-owned seams that materially affect host trust:
  dependency-gated nested mount shape,
  resolver wiring,
  shared `on_mount`/auth path,
  enforced read-only access,
  shared display-policy formatting hooks,
  and one successful bridge render under the fixture host.
- **D-13:** Do not add richer bridge interaction assertions that would couple the suite to Oban Web internals, upstream UI churn, or a broader support promise than the project intends.

### Docs and Support-Truth Posture
- **D-14:** Native `/ops/jobs` is the default paved road and the supported mutation surface.
- **D-15:** The optional `/ops/jobs/oban` bridge should be documented as an additive read-only inspection annex, not as a co-equal product surface and not as the default mental model.
- **D-16:** Docs should still acknowledge two tested lanes, but the wording should not imply equal semantic weight between them.
- **D-17:** Recommended default wording:
  Oban Powertools ships a native, host-owned operator shell at `/ops/jobs`.
  `oban_web` is optional; when installed, Powertools mounts a nested read-only Oban Web bridge at `/ops/jobs/oban` for additional inspection.
  Native Powertools pages are the supported mutation surface.
  The host owns router scope, browser pipeline, auth, display policy, and runtime config.

### the agent's Discretion
- Exact proof-harness implementation for removing `oban_web` from the copied host, provided the behavior is narrow, obvious, and documented.
- Exact smoke-proof shape for the bridge-enabled lane, provided it proves a real render without asserting broad Oban Web internals.
- Exact docs section edits and test-marker wording, provided the native-first support truth above remains intact everywhere.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone authority
- `.planning/ROADMAP.md` — Phase 13 goal, dependency on Phase 12, and milestone ordering.
- `.planning/PROJECT.md` — host-owned OSS posture, active v1.1 adoption-hardening goals, and optional-dependency/support-truth intent.
- `.planning/REQUIREMENTS.md` — `PKG-03` and `DOC-03` are the requirements Phase 13 must close.
- `.planning/STATE.md` — current milestone posture and explicit focus on Phase 13.
- `.planning/MILESTONE-ARC.md` — default decision rule, host-owned principles, bridge-first UI posture, and support-truth hardening guidance.
- `.planning/milestones/v1.1-MILESTONE-AUDIT.md` — the concrete Phase 13 gap report for native-only compile truth and optional-dependency proof closure.

### Prior phase decisions that constrain Phase 13
- `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md` — shared auth/display seams and the bounded optional `oban_web` bridge contract.
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md` — native pages own audited mutations and the bridge remains read-only.
- `.planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md` — one canonical host path, layered proof, separate native-only and bridge-enabled tested lanes, and support-truth messaging.
- `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md` — curated fixture honesty, separate fresh-host installer proof, and explicit optional-dependency boundaries.

### Current implementation targets
- `lib/oban_powertools/web/router.ex` — dependency-gated nested bridge mount and public route/support-truth contract.
- `lib/oban_powertools/web/oban_web_bridge.ex` — read-only bridge adapter and shared display-policy seam.
- `test/oban_powertools/web/router_test.exs` — current route, resolver, and read-only bridge assertions.
- `test/support/example_host_contract.ex` — current canonical fixture proof harness and lane behavior.
- `test/oban_powertools/example_host_contract_test.exs` — current native-only, bridge-enabled, upgrade, and first-session lane tests.
- `test/support/fresh_host_contract.ex` — separate fresh-host generator/install proof harness from Phase 12.
- `.github/workflows/host-contract-proof.yml` — current proof-lane matrix that Phase 13 will tighten.
- `examples/phoenix_host/mix.exs` — current canonical fixture dependency shape, including optional `oban_web`.
- `examples/phoenix_host/regenerate.sh` — curated-fixture regeneration path and provenance notes.
- `README.md` — public install/support-truth summary that Phase 13 must keep honest.
- `guides/installation.md` — native host-owned install path and optional dependency wording.
- `guides/first-operator-session.md` — canonical native operator proof story.
- `guides/optional-oban-web-bridge.md` — explicit bridge posture and caveats.
- `guides/upgrade-and-compatibility.md` — tested-lane and compatibility wording that Phase 13 must narrow honestly.
- `test/oban_powertools/docs_contract_test.exs` — docs/workflow contract markers that will need alignment with the Phase 13 truth.

### Product and repo-local research posture
- `prompts/oban_powertools_context.md` — product posture, personas, host-owned/operator-first framing, and DX expectations.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — bridge-first UI strategy and explicit “do not rebuild commodity dashboard UI first” guidance.
- `prompts/oban-powertools-deep-research-original-prompt.md` — cross-ecosystem research posture, DX emphasis, and lessons-learned framing for this product family.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/oban_powertools/web/router.ex`: already gates the nested bridge at macro expansion time and documents the bounded public route contract.
- `lib/oban_powertools/web/oban_web_bridge.ex`: already centralizes the bridge’s read-only access and shared formatting posture.
- `test/oban_powertools/web/router_test.exs`: strong baseline for proving nested route shape, resolver wiring, and read-only support truth.
- `test/support/example_host_contract.ex`: existing per-lane fixture-copy harness is the natural place for narrow dependency rewrites.
- `test/support/fresh_host_contract.ex`: already proves the installer-backed fresh-host path separately, so Phase 13 does not need to overload the canonical fixture with day-0 concerns.
- `test/oban_powertools/docs_contract_test.exs`: cheap support-truth guardrail for wording drift across README/guides/workflow names.

### Established Patterns
- One canonical curated fixture plus a separate fresh-host installer lane is already the repo’s preferred proof architecture.
- Host-owned routing, auth, display policy, and runtime config are the stable public seams.
- Native Powertools pages own audited mutations; the optional bridge remains bounded and read-only.
- The project consistently prefers narrow truthful claims over broader but weakly-proven promises.

### Integration Points
- Native-only proof tightening should connect the fixture host dependency shape, the proof harness lane setup, and the CI lane names so they all mean the same thing.
- Bridge-enabled proof tightening should connect router/bridge assertions, docs wording, and one real render smoke so the optional lane is both bounded and honest.
- Docs updates should connect README, installation, first-session, optional bridge, compatibility guide, and docs-contract tests around one native-first support story.

</code_context>

<specifics>
## Specific Ideas

- Preferred Phase 13 outcome:
  “If a host omits `oban_web`, Powertools still compiles, boots, and proves its native operator path honestly.
  If a host adds `oban_web`, the nested bridge works as a read-only inspection surface without implying parity or broader support.”
- User preference to carry forward:
  shift decisions left inside GSD and downstream planning by default,
  except for unusually impactful public-semantic choices the user is likely to care about directly.
- Ecosystem lessons to honor:
  mounted admin/job dashboards work best when the host owns router/auth/session policy,
  optional integration surfaces should be explicit and bounded,
  and example/proof infrastructure should not fork into multiple competing “canonical” hosts unless the public contract truly differs.
- Repo-local posture to preserve:
  bridge-first architecture without bridge-first support language,
  one inspectable host story,
  and DX/operator trust over demo polish.

</specifics>

<deferred>
## Deferred Ideas

- Adding a second checked-in native-only fixture tree — defer unless a future phase intentionally broadens the support matrix.
- Broad bridge parity tests or browser-E2E coverage over Oban Web internals — out of scope for Phase 13.
- Reframing the bridge as the default operator plane — conflicts with the native mutation ownership contract and belongs in a future strategic pivot, not this phase.

</deferred>

---

*Phase: 13-native-only-optional-dependency-contract-proof*
*Context gathered: 2026-05-23*
