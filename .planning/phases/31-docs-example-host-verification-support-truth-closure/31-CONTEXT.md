# Phase 31: Docs, Example Host, Verification & Support-Truth Closure - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Close v1.3 by making the public story and repo-local proof agree on the narrower
native control-plane promise that Phases 27-30 already established.

This phase owns:
- support-truthful docs alignment for the native `/ops/jobs` shell and the bounded
  read-only `/ops/jobs/oban` bridge
- proof closure for overview handoffs, cross-surface continuity, read-only
  behavior, audit follow-up, and bridge-boundary claims under the supported host
  contract
- milestone-close archival and traceability hygiene for v1.3

This phase does not:
- reopen generic queue or job dashboard scope
- add new runtime capabilities, mutation surfaces, or API/CLI automation
- create a broad browser-E2E proof family
- turn milestone closeout into a roadmap redesign workshop

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Keep the repo in research-first, recommendation-first mode for discuss and planning work. Ordinary implementation choices should be narrowed automatically from repo context, ecosystem norms, and prior art before asking the user anything.
- **D-02:** Escalate only if a decision would materially change public product semantics, support truth, architecture boundaries, operator trust, or long-term maintainer burden.
- **D-03:** Treat `.planning/config.json` as the repo-level override for this posture: `preferences.vendor_philosophy = thorough-evaluator` and `workflow.research_before_questions = true`.

### Docs Story Scope
- **D-04:** Realign every public entrypoint that shapes the native-control-plane promise, not just the top-level README.
- **D-05:** The scope should cover the promise-shaping docs set:
  `README.md`,
  `guides/support-truth-and-ownership-boundaries.md`,
  `guides/optional-oban-web-bridge.md`,
  `guides/example-app-walkthrough.md`,
  `guides/first-operator-session.md`,
  `guides/upgrade-and-compatibility.md`,
  `examples/phoenix_host/README.md`,
  and any milestone-closeout artifact that states what v1.3 now guarantees.
- **D-06:** Do not turn Phase 31 into a repo-wide editorial sweep. Builder, workflow, and lower-level guides should only change when they make or imply a support-truth claim that now conflicts with the unified control-plane story.
- **D-07:** Keep the public story centered on one explicit contract:
  the native `/ops/jobs` shell is the supported Powertools-native operator surface,
  the nested `/ops/jobs/oban` bridge is a narrower read-only inspection annex,
  and host-owned seams remain explicit rather than hidden behind library magic.

### Verification Closure Bar
- **D-08:** Deepen the existing hermetic proof lanes rather than inventing a new proof family.
- **D-09:** Phase 31 proof should extend the current docs-contract, example-host, host-contract, and targeted LiveView lanes so they cover:
  overview-to-destination handoff,
  URL-owned durable context,
  read-only behavior,
  bridge venue honesty,
  and audit follow-up filters/resource links.
- **D-10:** Prefer claim-based assertions over snapshot-style copy freeze. The suite should prove the public contract, not incidental wording or page chrome.
- **D-11:** Do not add a broad browser-E2E harness for this phase. That proof depth is the wrong cost profile for a host-owned LiveView library whose current promise is already well represented by mounted-route, resolver, LiveView, and example-host tests.
- **D-12:** If a single end-to-end “control-plane story” smoke proof is added, keep it strictly bounded and host-contract-aligned. It must not become a second sprawling proof universe beside the existing hermetic lanes.

### Milestone Closeout Posture
- **D-13:** Keep `31-03` narrow: archive v1.3 with explicit requirement closure evidence, concise learnings, and clearly deferred v1.4+ wedges.
- **D-14:** Do not use Phase 31 closeout to reshape the roadmap unless new evidence shows that the current v1.3 promise is actually wrong on semantics, support truth, or architecture.
- **D-15:** Preserve the repo’s established repair/closeout posture:
  owner phases keep semantic ownership,
  closeout artifacts point to canonical proof,
  chronology stays additive,
  and future wedges stay clearly non-binding until a new milestone activates them.

### Docs / Proof / DX Guardrails
- **D-16:** Keep one canonical host story. Do not create a second example or proof universe that drifts from `examples/phoenix_host`.
- **D-17:** Keep the bridge explicitly labeled and scoped as inspection-only. Never let docs or proof imply native mutation parity.
- **D-18:** Keep host-owned seams explicit in docs and proof:
  router scope,
  browser pipeline,
  auth,
  display policy,
  runtime config,
  session/actor lookup,
  and whether the bridge is exposed in production.
- **D-19:** Optimize for least surprise and maintainer DX:
  a future agent or maintainer should be able to answer what v1.3 promises, how the example host proves it, and which files close `DOC-04`, `VER-03`, and `HST-04` without re-reading phase history.

### the agent's Discretion
- Exact wording and section placement in the touched docs, provided the native-shell versus bridge-only story remains consistent.
- Exact split of proof assertions across docs-contract, example-host, workflow, and LiveView tests, provided the closure bar above is met without creating a second proof system.
- Exact archival artifact shape for v1.3 learnings and future wedges, provided it stays clearly subordinate to roadmap and requirement authority.

</decisions>

<specifics>
## Specific Ideas

- Preferred operator/developer story:
  “Powertools owns a coherent native `/ops/jobs` control plane for diagnosis and bounded audited action; generic inspection beyond that lives in the Oban Web bridge, explicitly and read-only.”
- Preferred docs posture:
  one sharpened story repeated consistently at the README, support-truth, bridge, example-host, and closeout entrypoints rather than a repo-wide prose rewrite.
- Preferred proof posture:
  strengthen the existing hermetic contract lanes around mounted-route truth, LiveView continuity, bridge boundaries, and audit follow-up instead of adding browser theater.
- Preferred milestone-close posture:
  closure evidence and follow-on wedges recorded cleanly, without quietly reopening generic dashboard scope or mutating roadmap authority.
- Preferred maintainer UX:
  clear promise surfaces, clear proof ownership, and grep-able requirement closure for `DOC-04`, `VER-03`, and `HST-04`.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` — Phase 31 goal, plan breakdown, and milestone-close boundary.
- `.planning/PROJECT.md` — v1.3 control-plane posture and repo-level decision posture.
- `.planning/REQUIREMENTS.md` — `DOC-04`, `VER-03`, and `HST-04`, plus the v1.3 support-truth and bridge-boundary constraints.
- `.planning/STATE.md` — current milestone status and next-action framing.
- `.planning/config.json` — repo-level discuss/planning preference override for `thorough-evaluator` plus research-before-questions behavior.

### Prior locked decisions that constrain this phase
- `.planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md` — support-truth layering, one canonical host lane, and claim-based docs enforcement.
- `.planning/phases/27-control-plane-vocabulary-status-taxonomy-ownership-contract/27-CONTEXT.md` — shared operator vocabulary, explicit native-versus-bridge ownership, and support-truth wording discipline.
- `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md` — overview handoff model, URL-owned continuity, and bridge-only posture.
- `.planning/phases/29-shared-preview-reason-refusal-audit-contract/29-CONTEXT.md` — shared native mutation trust model, read-only audit posture, and audit follow-up contract.
- `.planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md` — cross-surface opening-story cohesion, continuity selectors, and bridge honesty.
- `.planning/phases/24-verification-artifact-backfill/24-CONTEXT.md` — canonical proof-chain posture and additive evidence repair.
- `.planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md` — closure ownership, additive chronology, and explicit proof-pointer discipline.
- `.planning/phases/26-historical-closeout-hygiene/26-CONTEXT.md` — narrow closeout hygiene and non-rewrite archival posture.

### Public contract surfaces that Phase 31 must align
- `README.md` — top-level install, support-truth, bridge, and example-host story.
- `guides/support-truth-and-ownership-boundaries.md` — canonical ownership-bucket language.
- `guides/optional-oban-web-bridge.md` — bridge-only contract and read-only scope.
- `guides/example-app-walkthrough.md` — example-host posture and supported operator journey framing.
- `guides/first-operator-session.md` — canonical first-session proof story.
- `guides/upgrade-and-compatibility.md` — support-truth and supported-host language that must stay aligned with the native-shell promise.
- `examples/phoenix_host/README.md` — canonical current-state host fixture story.

### Proof and implementation surfaces
- `test/oban_powertools/docs_contract_test.exs` — claim-based docs contract lane.
- `test/oban_powertools/example_host_contract_test.exs` — canonical example-host proof lanes.
- `.github/workflows/host-contract-proof.yml` — proof-lane topology and CI closure surface.
- `test/oban_powertools/web/live/engine_overview_live_test.exs` — overview and handoff assertions.
- `test/oban_powertools/web/live/control_plane_copy_coherence_test.exs` — cross-surface copy and ownership/cohesion assertions.
- `test/oban_powertools/web/live/audit_live_test.exs` — audit continuity and filter behavior.
- `lib/oban_powertools/web/engine_overview_live.ex` — overview entrypoint and handoff surface.
- `lib/oban_powertools/web/overview_read_model.ex` — overview bucket and venue/read-only wording.
- `lib/oban_powertools/web/control_plane_presenter.ex` — shared native-versus-bridge wording seam.
- `lib/oban_powertools/web/audit_live.ex` — audit destination and continuity surface.
- `lib/oban_powertools/web/oban_web_bridge.ex` — explicit bounded bridge seam.
- `lib/oban_powertools/web/router.ex` — mounted route ownership contract.

### Product posture and research prompts
- `prompts/oban_powertools_context.md` — domain language, support-truth posture, and research-first decision guidance.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — native shell plus bounded bridge strategy and operator UX rationale.
- `prompts/oban-powertools-deep-research-original-prompt.md` — one-shot recommendation posture, ecosystem lessons, DX emphasis, and maintainer intent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/oban_powertools/docs_contract_test.exs` already provides a stable claim-based docs enforcement seam; Phase 31 should extend it rather than replacing it with snapshot-heavy prose locking.
- `test/oban_powertools/example_host_contract_test.exs` plus `.github/workflows/host-contract-proof.yml` already encode the canonical host lanes; they are the right place to close `VER-03` without inventing a second host fixture family.
- `ControlPlanePresenter`, `OverviewReadModel`, and the Phase 28-30 LiveView tests already express the native-shell versus bridge-only story in code and are the natural anchors for proof closure.
- `examples/phoenix_host/README.md` already serves as the canonical fixture truth and should remain the single public current-state host reference.

### Established Patterns
- The repo prefers host-owned seams with library-owned adapters and mounted routes.
- Docs are treated as a public contract only where they make stable claims; the repo already rejects broad prose snapshotting.
- Native Powertools pages own diagnosis and bounded audited action; the Oban Web bridge is intentionally narrower and read-only.
- Repair and closeout phases in this repo preserve chronology, point at canonical proof, and avoid broad history rewrites.

### Integration Points
- Phase 31 planning should connect the public docs set, the example-host fixture, and the proof workflow so they all tell the same native-shell story.
- Proof updates should likely concentrate in docs-contract, example-host contract tests, host-contract workflow lanes, and a small number of high-signal LiveView tests for continuity and venue honesty.
- Milestone closeout work should connect `DOC-04`, `VER-03`, and `HST-04` closure evidence back into the canonical planning artifacts without reassigning ownership or broadening scope.

</code_context>

<deferred>
## Deferred Ideas

- Full native replacement of the generic Oban Web jobs or queues experience.
- Broad browser-E2E or screenshot-proof families for the control plane.
- Repo-wide editorial normalization of every guide regardless of whether it affects support truth.
- Roadmap reshaping or v1.4 scope design hidden inside the v1.3 closeout phase.
- CLI/API automation surfaces or broader machine-facing contracts before the native control-plane vocabulary settles further.

</deferred>

---

*Phase: 31-docs-example-host-verification-support-truth-closure*
*Context gathered: 2026-05-26*
