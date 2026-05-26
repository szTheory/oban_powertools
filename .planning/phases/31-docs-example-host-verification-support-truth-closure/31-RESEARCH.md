# Phase 31: Docs, Example Host, Verification & Support-Truth Closure - Research

**Researched:** 2026-05-26
**Domain:** docs-contract, example-host proof, and milestone-close alignment for the v1.3 control plane
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-04 / D-05:** Realign the promise-shaping docs set, not just `README.md`.
- **D-07:** Keep one explicit story: native `/ops/jobs` is the supported Powertools control plane, while `/ops/jobs/oban` is a narrower read-only bridge.
- **D-08 / D-09 / D-10:** Extend the existing proof lanes instead of inventing a new browser-E2E family; assert claims, not incidental prose.
- **D-13 / D-15:** Keep closeout narrow: canonical closure evidence, concise learnings, additive chronology, and explicit future wedges.
- **D-16 / D-17 / D-18:** Keep one canonical host story, preserve explicit bridge-only language, and keep host-owned seams visible everywhere they matter.

### Discretion
- Exact wording and section placement in the touched docs.
- Exact split between docs-contract assertions, example-host smoke coverage, and repo-local LiveView proof.
- Exact shape of the v1.3 closeout artifact, as long as it points back to canonical proof instead of replacing it.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `DOC-04` | README, guides, and example-host material explain the unified native control plane honestly. | The promise-shaping docs already name `/ops/jobs`, `/ops/jobs/oban`, `Powertools-native`, `Audited action`, and `Inspection only`; Phase 31 should tighten those into one repeated contract and add overview/audit continuity language where missing. |
| `VER-03` | Automated proof covers overview handoff, shared vocabulary, read-only behavior, and cross-surface audit expectations. | Repo-local proof already exists in `engine_overview_live_test.exs`, `control_plane_copy_coherence_test.exs`, `audit_live_test.exs`, `docs_contract_test.exs`, and the example-host contract lanes; the gap is tying them together and extending the example host beyond cron-only proof. |
| `HST-04` | Host apps can understand which promises are native guarantees, host-owned seams, or bridge-only behavior. | `README.md`, `guides/support-truth-and-ownership-boundaries.md`, `guides/upgrade-and-compatibility.md`, and `examples/phoenix_host/README.md` already enumerate host-owned seams; Phase 31 should make the control-plane framing and bridge boundary consistent across all of them. |
</phase_requirements>

## Summary

Phase 31 should be planned as a closure phase across three bounded layers:

1. **Docs truth:** sharpen the public wording so the repo consistently says the native `/ops/jobs` shell is the supported Powertools control plane, `/ops/jobs/oban` is a read-only inspection bridge, and host-owned seams remain explicit.
2. **Proof truth:** extend existing docs-contract, example-host, and repo-local LiveView proof lanes so the public story is provably true for overview, bridge, audit, read-only, and first-session behavior.
3. **Closeout truth:** produce one canonical Phase 31 verification artifact plus one milestone-close memo that points at requirement closure and defers v1.4+ wedges without mutating roadmap authority.

## What Already Exists

### Public docs already contain the right nouns

- `README.md` already names the unified native `/ops/jobs` control plane and the read-only `/ops/jobs/oban` bridge.
- `guides/support-truth-and-ownership-boundaries.md` already freezes the five support-truth buckets.
- `guides/optional-oban-web-bridge.md`, `guides/first-operator-session.md`, and `guides/example-app-walkthrough.md` already distinguish native mutation from bridge inspection.
- `examples/phoenix_host/README.md` already frames the fixture as the canonical host-owned proof lane.

**Planning takeaway:** the docs work is an alignment pass, not a rewrite. Tighten scope to the promise-shaping set and make control-plane, overview, audit, and bridge language repeat identically enough for contract testing.

### Proof already spans repo-local and example-host lanes

- `test/oban_powertools/docs_contract_test.exs` already enforces install markers, support-truth buckets, first-session markers, and workflow lane names.
- `test/oban_powertools/web/live/engine_overview_live_test.exs` already proves diagnosis-first overview copy, bridge-only labels, and read-only behavior.
- `test/oban_powertools/web/live/control_plane_copy_coherence_test.exs` already proves cross-surface copy across cron, workflows, Lifeline, and audit.
- `test/oban_powertools/web/live/audit_live_test.exs` already proves read-only audit rendering and canonical filters.
- `test/oban_powertools/example_host_contract_test.exs`, `test/support/example_host_contract.ex`, and `.github/workflows/host-contract-proof.yml` already define the example-host proof topology.

**Planning takeaway:** close `VER-03` by extending the current proof topology, not by introducing another fixture family or another workflow.

### Example-host proof is still cron-centered

- `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` currently proves the canonical cron mutation lane.
- `examples/phoenix_host/test/phoenix_host_web/oban_web_bridge_smoke_test.exs` currently proves the bounded bridge mount.
- The helper in `test/support/example_host_contract.ex` already prepares lanes and runs fixture tests in temp copies.

**Planning takeaway:** the most credible host-proof extension is a narrow additional smoke lane inside the same fixture, likely focused on overview visibility, audit follow-up, and bridge-only language after the first-session proof.

## Recommended Planning Shape

### Plan 31-01 should be docs alignment plus docs-contract tightening

Touch the exact promise-shaping docs set from context:

- `README.md`
- `guides/support-truth-and-ownership-boundaries.md`
- `guides/optional-oban-web-bridge.md`
- `guides/example-app-walkthrough.md`
- `guides/first-operator-session.md`
- `guides/upgrade-and-compatibility.md`
- `examples/phoenix_host/README.md`
- `test/oban_powertools/docs_contract_test.exs`

The plan should lock explicit strings and claims around:

- unified native `/ops/jobs` control plane
- read-only `/ops/jobs/oban` bridge
- `Inspection only`
- overview and audit as part of the same native control plane story
- host-owned seams: router scope, browser pipeline, auth, display policy, runtime config, actor/session lookup, production bridge exposure

### Plan 31-02 should extend proof, not multiply it

Use the existing lanes:

- repo-local LiveView tests for overview, copy coherence, and audit
- docs-contract for promise-shaping markers
- example-host smoke tests and contract helpers
- host-contract workflow jobs already present in `.github/workflows/host-contract-proof.yml`

The likely implementation move is:

- add one bounded example-host smoke test for the control-plane story after the canonical first-session proof
- update `ExampleHostContract` helpers and `example_host_contract_test.exs` to run and assert that lane
- keep bridge-enabled and first-session lanes separate so support truth stays legible

### Plan 31-03 should create canonical closeout artifacts

The closeout should likely write:

- `31-VERIFICATION.md` as the canonical Phase 31 proof/requirements closure artifact for `DOC-04`, `VER-03`, and `HST-04`
- `.planning/v1.3-MILESTONE-AUDIT.md` as the additive milestone-close memo

It may also update:

- `.planning/REQUIREMENTS.md` traceability/status lines for the three Phase 31 requirements
- `.planning/STATE.md` to point from “ready to plan” into completed closure

It should not reshape roadmap semantics or reopen v1.4 planning inside the closeout artifact.

## Validation Architecture

Phase 31 verification should sample the same proof families that execution will touch:

- **Docs contract quick lane:** `mix test test/oban_powertools/docs_contract_test.exs`
- **Repo-local control-plane lane:** `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/control_plane_copy_coherence_test.exs --seed 0`
- **Example-host lane:** `mix test test/oban_powertools/example_host_contract_test.exs --only first_session --only bridge-enabled --only upgrade-proof`
- **Fixture smoke lane:** targeted `examples/phoenix_host/test/phoenix_host_web/*.exs` through `test/support/example_host_contract.ex`
- **Full suite gate:** `mix test`

The plan should require exact grep-verifiable markers in docs and exact test commands for each proof slice.

## Patterns To Reuse

### Docs contract prefers marker assertions, not prose snapshots

`test/oban_powertools/docs_contract_test.exs` asserts exact terms and command names across a joined-doc corpus. That is the right enforcement seam for `DOC-04`.

### Example-host proof runs through copied fixtures, not the checked-in tree

`test/support/example_host_contract.ex` copies `examples/phoenix_host` or `examples/phoenix_host_upgrade_source` to temp directories, rewrites the local dependency path, and then runs specific tests. New host-proof behavior should follow that same helper pattern.

### Control-plane repo-local proof already covers the right semantic edges

`engine_overview_live_test.exs`, `audit_live_test.exs`, and `control_plane_copy_coherence_test.exs` already speak in the right vocabulary: diagnosis-first, bridge-only, inspection-only, recent audit, read-only. Those tests should stay the canonical repo-local semantic lane.

## Anti-Patterns To Avoid

- **Do not add a generic browser-E2E harness.** It is outside the cost profile and conflicts with the locked proof posture.
- **Do not create a second example host.** The current fixture plus the archived upgrade source are the only host stories this milestone should preserve.
- **Do not use the closeout artifact to redesign v1.4.** Record future wedges only as clearly deferred follow-ons.
- **Do not test incidental prose paragraphs.** Lock stable claims and vocabulary markers only.

## Concrete Planning Implications

- Plan 31-01 should carry `DOC-04` and `HST-04`.
- Plan 31-02 should carry `VER-03` and supporting parts of `DOC-04` / `HST-04`.
- Plan 31-03 should close `DOC-04`, `VER-03`, and `HST-04` canonically through `31-VERIFICATION.md` and the milestone audit memo.
