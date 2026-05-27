# Phase 36 Research: Docs, Example Host, Verification & Support-Truth Closure

## Scope Understanding (Planning Boundary)

Phase 36 is now a reconciliation/closure umbrella, not a runtime implementation phase.

- The canonical intent remains milestone closure for docs truthfulness and merge-blocking proof posture.
- Execution ownership has already been split and completed:
  - `DOC-05` closure is delivered in Phase 38.
  - `VER-04` closure is delivered in Phase 39.
- Planning for Phase 36 should therefore focus on closure mapping, traceability clarity, and stable evidence links.
- Do not reopen feature/runtime scope from phases 32-35 (forensics, limiter/cron diagnostics, runbook behavior, escalation seams).
- Do not rewrite phase history or renumbering; preserve additive auditability.

## Key Findings To Enable Planning

### 1) Requirement closure is already satisfied by downstream phases

- `.planning/REQUIREMENTS.md` maps `DOC-05 -> Phase 38 (Complete)` and `VER-04 -> Phase 39 (Complete)`.
- `.planning/ROADMAP.md` still describes Phase 36 as the original closure phase while separately showing Phase 38 and 39 as completed split execution.
- The planning task for Phase 36 is to make this relationship explicit and durable, not to re-execute closure work.

### 2) Canonical docs/support-truth contract surfaces are already concrete

Primary public surfaces:

- `README.md`
- `guides/forensics-and-runbook-handoffs.md` (canonical deep contract)
- `guides/support-truth-and-ownership-boundaries.md`
- `guides/example-app-walkthrough.md`
- `guides/first-operator-session.md`
- `examples/phoenix_host/README.md`

Stable support-truth language already exists and should be treated as contract:

- ownership labels: `Powertools-native`, `Oban Web bridge`, `host-owned follow-up`
- evidence boundary labels: `partial evidence`, `history unavailable`, `unknown`
- escalation status truth: `unconfigured`, `invoked`, `failed`
- non-overclaim posture: no provider-delivery guarantees, no external runbook-truth ownership claims

### 3) Claim/evidence contract is explicit and already wired

`DOC-05` contract:

- Claim IDs: `DOC05-C1` through `DOC05-C6`
- File-scoped assertions in `test/oban_powertools/docs_contract_test.exs`
- Anti-overclaim guard assertions present in same test file
- Closure report: `.planning/phases/38-docs-example-host-forensics-journey-closure/38-VERIFICATION.md`

`VER-04` contract:

- Claim IDs: `VER04-C1` through `VER04-C4`
- Workflow jobs: `continuity-ver04-c1..c4` plus aggregate merge gate `continuity-proof-status`
- Deterministic command mapping and artifact refs in:
  - `.planning/phases/39-ci-continuity-proof-lane-closure/39-PROOF-MANIFEST.json`
  - `.planning/phases/39-ci-continuity-proof-lane-closure/39-VERIFICATION.md`
- Artifact safety and completeness boundaries are already encoded in `.github/workflows/host-contract-proof.yml` (`if: always()`, `if-no-files-found: error`, redaction scan fail boundary).

### 4) Phase 36 planning should primarily maintain reconciliation integrity

The highest-value deliverables are not runtime changes; they are durable closure indexing artifacts:

- explicit mapping from Phase 36 intent to Phase 38/39 closure evidence
- consistent requirement/roadmap/state/phase-context narrative
- guardrails against claim ID, check-name, and ownership-language drift

## Dependencies and Ordering Constraints

Hard dependencies before closing Phase 36 planning:

1. Phase 38 closure artifacts remain canonical for `DOC-05`.
2. Phase 39 closure artifacts remain canonical for `VER-04`.
3. Required check topology remains stable (`continuity-proof-status` plus claim lanes).
4. Docs-contract claim markers and anti-overclaim assertions remain intact.

No additional runtime dependencies should be introduced in this phase.

## Risk Points (What Can Go Wrong)

1. **Contract drift risk**: renaming `DOC05-*`/`VER04-*` claim IDs or workflow check names breaks traceability and branch-protection assumptions.
2. **Narrative/proof mismatch risk**: docs language evolves away from test assertions or from phase verification language.
3. **Over-claim regression risk**: accidental wording implies provider delivery certainty or external runbook ownership.
4. **Scope creep risk**: reconciliation work accidentally turns into runtime/UI behavior changes.
5. **Evidence freshness risk**: closure artifacts exist but are not revalidated when reconciliation notes are updated.

## Recommended Plan Slices / Waves (Reconciliation Posture)

### Wave 1: Reconciliation Index and Source-of-Truth Lock

Goal: make the closure mapping explicit from Phase 36 to Phase 38/39 artifacts.

- Produce/update Phase 36 reconciliation text that maps:
  - `36-01` intent -> Phase 38 docs closure assets
  - `36-02` intent -> Phase 39 continuity proof assets
  - `36-03` intent -> milestone archival/reconciliation outputs
- Ensure this mapping is consistent across:
  - `36-CONTEXT.md`
  - `.planning/ROADMAP.md` narrative entries
  - `.planning/STATE.md` sequencing state where applicable

### Wave 2: Contract Surface Audit (No Capability Changes)

Goal: verify public docs and proof topology still match closure claims.

- Audit core docs surfaces for required ownership/evidence boundary vocabulary.
- Audit `docs_contract_test.exs` for claim markers + over-claim guards.
- Audit workflow topology for stable continuity lane names and aggregate gate.
- Only perform additive clarification edits if mismatches are found; avoid semantic broadening.

### Wave 3: Closure Evidence Refresh and Milestone Packaging

Goal: finish with auditable, planner-friendly closure truth.

- Re-run closure-oriented verification commands (see strategy below).
- Record any refreshed evidence links in Phase 36 reconciliation notes.
- Publish a concise “what is closed where” index for future audits/planning handoffs.

## Verification Strategy (Planner-Ready)

Use deterministic, claim-oriented verification with explicit pass/fail evidence:

1. Docs/support-truth contract lane:
   - `mix test test/oban_powertools/docs_contract_test.exs --seed 0`
2. Continuity proof topology contract:
   - verify `.github/workflows/host-contract-proof.yml` still contains:
     - `continuity-ver04-c1`
     - `continuity-ver04-c2`
     - `continuity-ver04-c3`
     - `continuity-ver04-c4`
     - `continuity-proof-status`
3. Claim/evidence mapping integrity:
   - confirm `39-PROOF-MANIFEST.json` still maps `VER04-C1..C4` to deterministic commands/jobs/artifacts
   - confirm `38-VERIFICATION.md` and `39-VERIFICATION.md` still map requirement closure claims to evidence
4. Planning-traceability integrity:
   - verify reconciliation references remain coherent across `ROADMAP`, `REQUIREMENTS`, `STATE`, and `36-CONTEXT`.

## Stable Claim/Evidence Contract Constraints (Must Not Drift)

Treat these as public planning constraints, not implementation details:

- `DOC05-C1..C6` identifiers are stable.
- `VER04-C1..C4` identifiers are stable.
- `continuity-proof-status` remains the aggregate merge gate contract surface.
- Continuity lane names remain explicit and stable (`continuity-ver04-c1..c4`).
- Proof packet minimum artifacts remain required (`ver04-claim-matrix.md`, `ver04-claim-matrix.json`, `run-metadata.json`, `redaction-report.json`, claim logs).
- Over-claim prohibitions remain explicit (no provider-delivery certainty claims, no external runbook-truth ownership claims).

Any changes to the above should be treated as explicit contract migrations in a new phase, not incidental edits inside Phase 36 reconciliation.

## Gotchas for Downstream Planner

- Phase 36 can look “not done” in roadmap checkboxes even though closure execution was intentionally moved to Phases 38/39. Plan around reconciliation, not re-implementation.
- Avoid “helpful” runtime edits while touching docs/proof references; this phase should stay closure-only.
- Do not collapse claim-based proof into narrative-only wording; merge-blocking claims must remain executable and artifact-backed.
- Keep check-name and claim-ID stability in mind before renaming tests, workflow jobs, or artifact paths.
- Preserve additive audit history; avoid rewriting prior phase artifacts unless a correction is strictly required and documented.

## Recommended Planning Starting Point

If planning starts now, begin with Wave 1 (reconciliation index) and explicitly state that Phase 36 is a closure umbrella satisfied through Phase 38/39 artifacts. Then run Wave 2 contract audit before any text changes, and finish with Wave 3 evidence refresh to lock a single support-truthful closure story.
