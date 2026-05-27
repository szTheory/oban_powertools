# Phase 39: ci-continuity-proof-lane-closure - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Close `VER-04` by making continuity proof merge-blocking and reproducible in CI.

This phase owns:
- wiring continuity suites from phase 32 through phase 35 into host-contract CI
- publishing CI evidence artifacts that map directly to continuity and ownership-boundary proof claims
- closing requirement traceability for `VER-04` with automated, reproducible proof references

This phase does not:
- reopen runtime behavior delivered in phases 32, 33, 34, or 35
- add new operator capability scope outside continuity-proof closure

</domain>

<decisions>
## Implementation Decisions

### CI Topology and Merge Gate
- **D-01:** Add a dedicated `continuity-proof` lane to `.github/workflows/host-contract-proof.yml` using a static matrix with claim-focused shards.
- **D-02:** Keep shard count bounded (3-4 claim shards) to balance failure localization and CI complexity.
- **D-03:** Add a final aggregator status job (for example `continuity-proof-status`) that depends on all continuity shards and is the merge-blocking gate for `VER-04`.
- **D-04:** Keep continuity check names stable and explicit so branch protection, docs-contract assertions, and audit references do not drift.

### Claim-to-Command Mapping
- **D-05:** Use explicit `VER04-C1..C4` claim-to-command mapping instead of one umbrella continuity command.
- **D-06:** Each claim command must be deterministic and rerunnable (`--seed 0`) and map to one continuity claim area:
  - forensic timeline projection
  - limiter and cron history behavior
  - runbook guidance rendering
  - continuity between diagnosis, action, and audit surfaces
- **D-07:** Prefer claim-sliced suites as primary proof and narrow guard checks (copy/coherence, selector-safety, anti-overclaim checks) as secondary proof.

### Failure Semantics and Artifact Boundaries
- **D-08:** Publish a claim-mapped proof packet on every continuity run (`if: always()`), regardless of success or failure.
- **D-09:** Required artifacts include:
  - human-readable claim summary (`ver04-claim-matrix.md`)
  - machine-readable claim summary (`ver04-claim-matrix.json`)
  - per-failing-claim sanitized raw logs
  - run metadata (`run-metadata.json`)
  - redaction/scan report for artifact safety
- **D-10:** Fail the lane if required evidence artifacts are missing (`if-no-files-found: error`) or redaction checks fail.
- **D-11:** Keep success-only heavy artifacts optional and short-retention to preserve DX without inflating CI cost.

### Traceability Closure Model
- **D-12:** Use a hybrid closure model:
  - deterministic machine-readable proof manifest
  - human-readable phase verification report
  - requirements-traceability reconciliation
- **D-13:** Add `39-PROOF-MANIFEST.json` as canonical claim-to-proof mapping for `VER-04` and keep it deterministic to avoid noisy churn.
- **D-14:** Publish `39-VERIFICATION.md` with explicit `VER-04` claim-to-evidence command mapping and CI run evidence.
- **D-15:** Update `.planning/REQUIREMENTS.md` only after proof publication to reconcile `VER-04` from pending to complete with explicit phase-39 references.

### Planning and UX/DX Posture
- **D-16:** Recommendation style for this repo remains one-shot and coherent: avoid broad option menus when a clear best-fit continuity closure exists.
- **D-17:** Prioritize least-surprise CI behavior: explicit claim failures, explicit ownership boundaries, explicit artifact evidence, and explicit traceability links.

### Claude's Discretion
- Exact matrix shard labels and job IDs, as long as they stay stable and clearly map to `VER04-C1..C4`.
- Exact artifact file naming details, as long as required proof packet components are present and enforced.
- Exact placement of manifest-generation and artifact-upload steps in the workflow, as long as merge-blocking and reproducibility rules stay intact.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` - phase 39 scope, must-haves, and plan split.
- `.planning/PROJECT.md` - repo decision posture and v1.4 closure intent for `VER-04`.
- `.planning/REQUIREMENTS.md` - `VER-04` requirement and traceability target.
- `.planning/STATE.md` - active phase and sequencing context.

### Prior verification closure artifacts (inputs to CI continuity lane)
- `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-VERIFICATION.md` - FRN continuity command evidence and residual-risk boundaries.
- `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-VERIFICATION.md` - OPS continuity command evidence and residual-risk boundaries.
- `.planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-VERIFICATION.md` - runbook/ownership-boundary continuity evidence.
- `.planning/phases/38-docs-example-host-forensics-journey-closure/38-VERIFICATION.md` - explicit handoff that keeps `VER-04` owned by phase 39.

### CI and proof surfaces in scope
- `.github/workflows/host-contract-proof.yml` - canonical host-contract CI lane topology.
- `test/oban_powertools/docs_contract_test.exs` - workflow topology contract guardrail and docs-proof posture.
- `test/oban_powertools/forensics_test.exs` - forensic continuity behavior coverage.
- `test/oban_powertools/web/live/forensics_live_test.exs` - forensic UI continuity and selector boundary coverage.
- `test/oban_powertools/lifeline_test.exs` - remediation and audit continuity coverage.
- `test/oban_powertools/web/live/lifeline_live_test.exs` - runbook continuity rendering and ownership-boundary coverage.
- `test/oban_powertools/cron_test.exs` - cron history behavior coverage.
- `test/oban_powertools/web/live/cron_live_test.exs` - cron surface continuity and ownership-boundary coverage.
- `test/oban_powertools/web/live/limiters_live_test.exs` - limiter surface continuity and ownership-boundary coverage.

### Product and engineering research canon
- `prompts/oban_powertools_context.md` - product principles, support-truth rules, and ecosystem lessons.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` - UX/ownership boundary and least-surprise operator posture.
- `prompts/oban-powertools-deep-research-original-prompt.md` - one-shot recommendation and DX-first philosophy.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/host-contract-proof.yml` already provides a lane-oriented CI topology and required-check pattern suitable for adding continuity shards.
- `test/oban_powertools/docs_contract_test.exs` already enforces workflow-lane contract drift checks and can extend to continuity lane assertions.
- Existing phase 32, 33, and 35 verification reports already define concrete continuity command bundles that can be wired directly into CI.

### Established Patterns
- Additive closure artifacts over historical rewrites.
- Explicit requirement-to-evidence mapping with residual-risk boundaries.
- Stable lane naming and deterministic command execution for reproducibility.
- Ownership/support-truth wording is treated as enforceable product contract, not optional prose.

### Integration Points
- Add continuity matrix and final merge-gate job in `.github/workflows/host-contract-proof.yml`.
- Extend docs-contract/testing guardrails so workflow topology and continuity lanes are contract-checked.
- Generate phase-level proof manifest and verification report as canonical `VER-04` closure evidence.
- Reconcile `.planning/REQUIREMENTS.md` only after automated continuity proof references are published.

</code_context>

<specifics>
## Specific Ideas

- Decision quality bar: one coherent recommendation set that minimizes decision burden and preserves repo direction.
- CI UX principle: every red check should immediately say which continuity claim failed, with direct evidence artifacts for diagnosis.
- DX principle: deterministic, local-rerunnable claim commands with explicit mapping beat opaque umbrella jobs.
- Audit principle: machine-readable proof manifest plus human-readable verification report provides both strictness and readability.

</specifics>

<deferred>
## Deferred Ideas

- Reusable multi-repo workflow abstraction (`workflow_call`) for continuity proof standardization; deferred unless additional repos need the same lane.
- Non-merge-blocking nightly-only deep continuity suites; deferred because phase 39 requires merge-blocking closure.
- Broader CI platform/reporting expansion beyond `VER-04` closure needs.

</deferred>

---

*Phase: 39-ci-continuity-proof-lane-closure*
*Context gathered: 2026-05-27*
