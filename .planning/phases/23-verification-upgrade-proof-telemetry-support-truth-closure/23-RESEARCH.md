# Phase 23: Verification, Upgrade Proof, Telemetry & Support-Truth Closure - Research

**Researched:** 2026-05-25
**Domain:** Workflow proof closure, supported upgrade posture, public telemetry, and docs-contract enforcement
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

- Keep DB-backed runtime proof as the semantics authority.
- Keep focused workflow proof suites by concern; do not rebuild a matrix framework.
- Keep coordinator/advisory resilience proof separate from DB-first workflow proof.
- Keep one singular supported host upgrade lane with one sentinel in-flight waiting continuity case.
- Keep broader retry/cancel/recovery compatibility in repo-local proof, not in the supported host lane.
- Keep one public `[:oban_powertools, :workflow, *]` telemetry family with bounded metadata only.
- Lock a small exact workflow-semantics docs block without freezing broad narrative prose.
- Prefer support-truth honesty, maintainer DX, and least surprise over broader-looking CI or docs claims.

</user_constraints>

## Repo Reality Check

### Verified current state

- The old omnibus runtime test file is already gone from the working tree; proof is split across:
  - `test/oban_powertools/workflow_runtime_transitions_test.exs`
  - `test/oban_powertools/workflow_runtime_signals_test.exs`
  - `test/oban_powertools/workflow_runtime_commands_test.exs`
  - `test/oban_powertools/workflow_callbacks_test.exs`
  - `test/oban_powertools/workflow_compatibility_test.exs`
- The supported host lane is already singular in CI and docs:
  - `.github/workflows/host-contract-proof.yml`
  - `test/oban_powertools/example_host_contract_test.exs`
  - `test/support/example_host_contract.ex`
  - `guides/upgrade-and-compatibility.md`
- Public workflow telemetry is already constrained to one family with per-event metadata in:
  - `lib/oban_powertools/telemetry.ex`
  - `test/oban_powertools/telemetry_test.exs`
- Docs-contract enforcement already freezes one exact workflow semantics block in:
  - `guides/workflows.md`
  - `test/oban_powertools/docs_contract_test.exs`

### Planning implication

Phase 23 should not re-do the Phase 19 proof split or invent a larger telemetry taxonomy. It should close the remaining gaps between:

1. runtime proof vs. roadmap requirement wording,
2. supported upgrade lane vs. broader repo-local compatibility proof,
3. emitted workflow telemetry vs. documented telemetry contract,
4. support-truth docs vs. what the repo actually proves today.

## Gap Analysis

### Gap 1: Requirement wording outruns the supported upgrade lane

`VER-02` in `.planning/REQUIREMENTS.md` still reads like hosts upgrade safely with waiting, retrying, cancelling, or recovering workflows. The locked Phase 23 context narrows the supported host claim to one singular lane plus one waiting sentinel, with broader compatibility staying repo-local. Phase 23 needs proof and docs that make that distinction unambiguous.

### Gap 2: Repo-local compatibility proof is present but not yet clearly positioned as the closure surface

`test/oban_powertools/workflow_compatibility_test.exs` already covers legacy waiting, cancel-request evidence, cancelled meaning, and recovery evidence. Phase 23 should widen and harden that lane where needed so retrying/cancelling/recovering continuity is proven there rather than by bloating `upgrade-proof`.

### Gap 3: Telemetry contract is bounded but still closure-sensitive

`lib/oban_powertools/telemetry.ex` already documents event-specific workflow metadata:

- `:step_completed`
- `:step_unblocked`
- `:cascade_cancelled`
- `:workflow_terminal`

Phase 23 should audit whether these event names and metadata fully express request -> evidence -> outcome semantics for the shipped workflow surface. The default should be to keep the family and stay narrow; only add suffixes if a real proof/doc gap remains after the audit.

### Gap 4: Docs and tests need final support-truth alignment

The docs already say:

- one supported upgrade lane,
- broader historical compatibility is repo-local `tested` proof,
- public workflow telemetry is bounded.

Phase 23 should finish by making README, guides, docs-contract tests, and CI naming all say the same thing with no implied extra support matrix.

## Recommended Phase Decomposition

### Plan 23-01: Focused workflow proof and historical compatibility closure

Use the existing split runtime suites as the primary execution seam. Add missing duplicate/late/dropped/race-path proof where required and extend repo-local compatibility coverage for retrying/cancelling/recovering histories without widening the supported host lane.

### Plan 23-02: Supported upgrade lane and CI truth closure

Keep `upgrade-proof` singular. Make the host fixture, harness, CI lane, and upgrade guide prove the documented host upgrade plus one waiting sentinel only, while clearly routing broader continuity claims to repo-local proof.

### Plan 23-03: Telemetry and support-truth docs closure

Audit workflow telemetry emitters and contract docs against the shipped semantics. Keep one public workflow family, bounded metadata, and a short exact docs block; update docs/tests only as far as required to match proof.

## Architecture Notes

### Proof topology to preserve

```text
DB-first workflow semantics proof
  -> workflow_runtime_transitions/signals/commands/callbacks tests
  -> workflow_compatibility_test repo-local historical continuity
  -> example_host_contract upgrade-proof host acceptance lane
  -> docs_contract + telemetry_test enforce public claim boundaries
```

### Why this topology fits the repo

- It matches the current split test files already in the working tree.
- It keeps support claims narrow and auditable.
- It preserves the boundary between runtime truth, host acceptance proof, and public docs/API contract.

## Risks To Avoid

- Reintroducing a broad host compatibility matrix through CI lane shape or guide prose.
- Adding telemetry tags that leak IDs, dedupe keys, reasons, or callback errors into the public contract.
- Letting docs imply that all repo-local historical compatibility scenarios are `supported` host upgrade shapes.
- Recombining focused runtime proof into one large semantics suite.

## Planning Recommendation

Proceed with three plans:

1. close focused workflow proof gaps and repo-local compatibility evidence,
2. keep the supported upgrade lane singular and truthful across fixture, CI, and guide surfaces,
3. finalize bounded telemetry plus docs-contract/support-truth alignment.

These are sufficient to close the phase without broadening the product surface.
