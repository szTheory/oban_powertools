# Phase 23: verification-upgrade-proof-telemetry-support-truth-closure - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v1.2 milestone with proof, upgrade evidence, telemetry markers, and support-truth documentation that match the workflow semantics already shipped. This phase hardens evidence and public contract clarity; it does not add new workflow capabilities or broaden the supported host matrix.

</domain>

<decisions>
## Implementation Decisions

### Proof Topology
- **D-01:** Keep DB-backed runtime proof as the semantics authority. Inline or advisory-only proof is not sufficient for milestone-closing workflow semantics.
- **D-02:** Split the current omnibus workflow runtime proof into focused contract suites by concern rather than keeping one giant semantics file.
- **D-03:** Keep coordinator/advisory-delivery resilience proof separate from DB-first workflow contract proof.
- **D-04:** Keep host and upgrade proof as acceptance lanes rather than folding them into runtime semantics tests.
- **D-05:** Use a narrow shared fixture/helper layer for workflow proofs, but do not introduce a custom matrix framework or an over-abstracted test DSL.
- **D-06:** If an extra layer is added, it may only be a tiny pure reducer/vocabulary spec file; it must not replace DB-first proofs of durable state transitions.

### Supported Upgrade Proof Posture
- **D-07:** Preserve one singular supported host upgrade lane. Do not turn the upgrade lane into a covert matrix of historical host/runtime combinations.
- **D-08:** The supported upgrade lane should prove the documented host upgrade plus one sentinel in-flight waiting-workflow continuity case.
- **D-09:** Broader retry, cancel, recovery, and similar in-flight compatibility semantics belong in repo-local historical compatibility fixtures/tests, not inside the singular host upgrade lane.
- **D-10:** Public support-truth must distinguish clearly between `supported` and `tested` here: the singular host lane stays narrow, while broader semantics compatibility may be tested without being promoted into broader host-shape support.
- **D-11:** Do not widen the supported matrix through CI shape alone. If a scenario appears in the host-contract lane, adopters will reasonably read it as part of the supported lane.

### Workflow Telemetry Contract
- **D-12:** Keep `[:oban_powertools, :workflow, *]` as the only public workflow telemetry family.
- **D-13:** Expand workflow telemetry with a small number of semantics-aware event suffixes rather than creating new public telemetry families.
- **D-14:** Move from a vague family-wide `[:status, :state]` mindset to documented per-event metadata contracts.
- **D-15:** Public workflow telemetry metadata must remain tiny and enum-bounded. Candidate keys may include only bounded fields such as `:scope`, `:state`, `:terminal_cause`, `:outcome`, and `:semantics_version` where materially useful.
- **D-16:** Workflow IDs, step names, signal keys, dedupe keys, operator reasons, callback errors, and race evidence remain out of public telemetry tags and belong in durable rows, callback envelopes, audit records, or clearly private/internal instrumentation.
- **D-17:** Telemetry naming should follow `request -> evidence -> outcome` semantics and must not present request-state evidence as final truth.

### Docs Contract Enforcement
- **D-18:** Keep the existing narrow install/support-truth/docs markers, but add one small exact-locked workflow-semantics block in `guides/workflows.md`.
- **D-19:** Freeze only bounded workflow semantics claims that are important enough to be public contract and already backed by named runtime proof.
- **D-20:** Do not broaden docs tests into prose snapshots or schema-driven narrative generation for workflow semantics.
- **D-21:** Exact docs locking should cover canonical workflow entrypoints and a short semantics block, while surrounding narrative remains editable for clarity.

### Project-Level Defaults To Carry Forward
- **D-22:** Shift strong recommendations left for this phase and downstream GSD work. Treat these decisions as locked defaults unless a later choice would materially widen public semantics, support burden, or host-contract scope.
- **D-23:** Favor maintainer DX, least surprise, and support-truth honesty over a more impressive-looking but broader or noisier proof/telemetry surface.
- **D-24:** Keep durable rows as truth, advisory systems as projections, and public telemetry/docs as bounded summaries of that truth rather than second semantic engines.

### the agent's Discretion
- Exact file split and naming for the focused workflow contract suites, provided the concern boundaries above remain clear.
- Exact workflow telemetry event suffix names, provided they stay under one public `workflow` family and keep metadata bounded.
- Exact wording of the canonical locked semantics block in `guides/workflows.md`, provided it remains short, exact, and traceable to proof.
- Exact shape of repo-local historical compatibility fixtures, provided they stay library-owned and do not blur the singular supported upgrade lane.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase And Milestone Contract
- `.planning/ROADMAP.md` — Phase 23 goal and dependency boundary.
- `.planning/PROJECT.md` — active milestone posture, support-truth constraints, and project-level defaults.
- `.planning/REQUIREMENTS.md` — `VER-01`, `VER-02`, and `POL-04` closure targets plus proof posture gate.

### Prior Locked Phase Decisions
- `.planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md` — singular upgrade lane, five support-truth buckets, and claim-to-proof discipline.
- `.planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md` — narrow callback event surface and thin-envelope/public-contract posture.
- `.planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md` — durable wait/signal authority, duplicate/late evidence posture, and upgrade-proof continuity context.
- `.planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md` — request/evidence/outcome cancellation semantics and late-arrival truth model.
- `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md` — diagnosis-first operator posture and support-truthful workflow explanation.
- `.planning/phases/22-lifeline-integration-bounded-recovery-actions/22-CONTEXT.md` — bounded workflow action vocabulary and preview/audit trust model.

### Public Docs And Support Truth
- `README.md` — current public support-truth, tested-lane, and telemetry framing.
- `guides/workflows.md` — public workflow contract guide; this phase will lock a small canonical semantics block here.
- `guides/upgrade-and-compatibility.md` — singular supported host upgrade lane and upgrade proof threshold.
- `guides/support-truth-and-ownership-boundaries.md` — five support-truth buckets and ownership boundary contract.
- `guides/production-hardening.md` — telemetry and operator hardening guidance that must stay aligned with public contract.
- `guides/troubleshooting.md` — fail-fast/runtime support-truth markers.

### Proof And Contract Tests
- `test/oban_powertools/workflow_runtime_test.exs` — current DB-first workflow semantics proof lane to split by concern.
- `test/oban_powertools/workflow_coordinator_test.exs` — coordinator/advisory-path resilience proof.
- `test/oban_powertools/example_host_contract_test.exs` — host-contract acceptance lanes including `upgrade-proof`.
- `test/support/example_host_contract.ex` — upgrade lane harness and sentinel in-flight continuity proof helper.
- `test/oban_powertools/docs_contract_test.exs` — existing docs-contract posture to extend narrowly.
- `test/oban_powertools/telemetry_test.exs` — public telemetry contract proof.
- `.github/workflows/host-contract-proof.yml` — CI lane topology for host-contract and docs-proof enforcement.

### Runtime And Public API Surfaces
- `lib/oban_powertools/telemetry.ex` — public telemetry contract and family definitions.
- `lib/oban_powertools/workflow/runtime.ex` — workflow runtime semantics and current workflow telemetry emitters.
- `lib/oban_powertools/workflow.ex` — public workflow facade and callback event contract.
- `lib/oban_powertools/workflow/callback_outbox.ex` — bounded callback event vocabulary and durable callback posture.

### Product Posture And DX Guidance
- `prompts/oban_powertools_context.md` — product posture, personas, support-truth framing, and telemetry/DX principles.
- `prompts/oban-powertools-deep-research-original-prompt.md` — ecosystem lessons, best-practice framing, and shift-left DX expectations.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — operator UX and bridge/native-surface strategy relevant to support-truth and telemetry/UI coherence.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/support/workflow_fixtures.ex`: reusable workflow setup for focused contract suites.
- `test/support/example_host_contract.ex`: existing acceptance-lane harness for native-only, bridge-enabled, first-session, and upgrade-proof host scenarios.
- `lib/oban_powertools/telemetry.ex`: single public contract seam for low-cardinality telemetry that Phase 23 should extend rather than fork.
- `test/oban_powertools/docs_contract_test.exs`: established narrow marker-based docs enforcement pattern to refine rather than replace.

### Established Patterns
- DB-first workflow truth lives in durable rows and is proven through `DataCase` integration tests.
- Public contracts stay narrow, explicit, and semver-sensitive, while richer operational detail remains in durable evidence or repo-local proof.
- Support-truth uses five explicit buckets and avoids widening supported claims through vague prose.
- Native operator surfaces and optional bridge surfaces remain distinct but policy-aligned.

### Integration Points
- Workflow semantics proof work connects directly to `workflow_runtime_test.exs`, `workflow_coordinator_test.exs`, and the upgrade-proof harness.
- Telemetry contract work connects to `lib/oban_powertools/telemetry.ex`, runtime emitters, docs, and `telemetry_test.exs`.
- Docs-contract changes connect to `guides/workflows.md`, `docs_contract_test.exs`, and public support-truth guides.
- Upgrade-proof work connects to `example_host_contract.ex`, `example_host_contract_test.exs`, and `host-contract-proof.yml`.

</code_context>

<specifics>
## Specific Ideas

- Keep the proof story layered and legible: durable runtime truth first, advisory resilience second, host upgrade acceptance last.
- Treat the singular supported upgrade lane as a host-shape promise, not as the place to prove every historical runtime scenario.
- Favor one public workflow telemetry family with per-event bounded metadata over a richer but noisier public observability taxonomy.
- Lock one canonical workflow semantics block in docs so public wording cannot drift, but avoid freezing narrative prose.
- Preserve the user preference to shift recommendation burden left within GSD unless a later choice would materially widen the public contract or support burden.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 23-verification-upgrade-proof-telemetry-support-truth-closure*
*Context gathered: 2026-05-25*
