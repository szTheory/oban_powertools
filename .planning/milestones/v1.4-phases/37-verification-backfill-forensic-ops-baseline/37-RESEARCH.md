# Phase 37 Research: Verification Backfill for Forensic and Ops Baseline

**Date:** 2026-05-27  
**Phase:** 37  
**Goal:** close orphaned requirement verification by publishing phase-level verification artifacts for completed phase-32 and phase-33 work.  
**Boundary:** documentation/verification backfill only; do not reopen runtime scope.

---

## What You Need To Know To Plan This Phase Well

1. The milestone audit failure is a verification-traceability gap, not a known runtime delivery gap for phases 32/33.
2. `FRN-01/02/03` and `OPS-01/02` are currently orphaned because `32-VERIFICATION.md` and `33-VERIFICATION.md` are missing, even though implementation summaries and validation maps exist.
3. Historical artifacts (`*-SUMMARY.md`, `*-VALIDATION.md`) are provenance inputs only; fresh rerunnable command evidence is still required for closure claims.
4. The repo already selected a two-tier confidence model: targeted reruns close phase-level claims; broader repo continuity remains a separate confidence lane (Phase 39 / `VER-04`).
5. The right report shape is concise-but-auditable (must-have truths + requirement mapping + command evidence + explicit residual risk), not minimal checkbox ledger and not oversized contract inventory.
6. Traceability reconciliation is in scope for this phase, but should be additive and scoped to FRN/OPS orphan closure in `.planning/REQUIREMENTS.md`.
7. Do not pull `DOC-05` or `VER-04` closure forward; those stay with Phase 38 and Phase 39.

---

## Canonical Sources For Planning

- `.planning/phases/37-verification-backfill-forensic-ops-baseline/37-CONTEXT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/v1.4-MILESTONE-AUDIT.md`
- `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-VALIDATION.md`
- `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-VALIDATION.md`
- `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-01-SUMMARY.md`
- `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-02-SUMMARY.md`
- `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-03-SUMMARY.md`
- `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-01-SUMMARY.md`
- `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-02-SUMMARY.md`
- `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-03-SUMMARY.md`
- `.planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-VERIFICATION.md`
- `.planning/phases/24-verification-artifact-backfill/24-CONTEXT.md` (closest prior backfill posture)

---

## Current Gap Topology (Why Phase 37 Exists)

From `.planning/v1.4-MILESTONE-AUDIT.md`:

- `FRN-01`, `FRN-02`, `FRN-03` are orphaned (Phase 32 runtime/summaries exist; no `32-VERIFICATION.md`).
- `OPS-01`, `OPS-02` are orphaned (Phase 33 runtime/summaries exist; no `33-VERIFICATION.md`).
- The gate is failing traceability/closure evidence linkage, not roadmap intent for delivered runtime behavior in 32/33.

From `.planning/ROADMAP.md`:

- Phase 37 plan intent is explicitly:
  - `37-01`: publish phase-32 verification artifact mapped to FRN requirements.
  - `37-02`: publish phase-33 verification artifact mapped to OPS requirements.
  - `37-03`: reconcile requirement-to-verification references so FRN/OPS are no longer orphaned.

---

## Evidence Freshness Strategy (Locked)

Use the two-tier model from `.planning/phases/37-verification-backfill-forensic-ops-baseline/37-CONTEXT.md`:

- **Tier A (required for closure in this phase):** fresh targeted reruns for requirement-scoped claims in `32-VERIFICATION.md` and `33-VERIFICATION.md`.
- **Tier B (separate confidence lane):** broader full-suite/CI continuity posture remains explicitly separate and is not implied as closed by targeted reruns.

Planning implications:

- Every requirement closure statement must tie to a rerunnable command and current repo state.
- Historical proof statements from summaries/validation can be cited as provenance, but cannot be the only closure evidence.
- Residual risk language must explicitly avoid claiming repo-wide health from phase-targeted reruns.

---

## Concrete Command Bundles (Planning Inputs)

These are the planning-ready bundles to anchor `37-01` and `37-02`. They come from the existing validation maps and phase summaries.

### Bundle A: Phase 32 / FRN Closure Evidence

Primary source: `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-VALIDATION.md`.

- **FRN-01 / FRN-02 chronology + continuity slice**
  - `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/audit_live_test.exs --seed 0`
- **FRN-01 / FRN-02 entry-surface continuity slice**
  - `mix test test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs --seed 0`
- **FRN-03 vocabulary + URL hygiene slice**
  - `mix test test/oban_powertools/web/live/control_plane_copy_coherence_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0`
  - `rg -n "/ops/jobs/forensics|supporting evidence|Inspection only|Powertools-native" lib/oban_powertools/web/forensics_live.ex lib/oban_powertools/web/workflows_live.ex lib/oban_powertools/web/lifeline_live.ex`
  - `! rg -n "preview_token=.*\\?|reason=.*\\?|diagnosis=.*\\?|refusal=.*\\?" lib/oban_powertools/web/forensics_live.ex lib/oban_powertools/web/workflows_live.ex lib/oban_powertools/web/lifeline_live.ex`

### Bundle B: Phase 33 / OPS Closure Evidence

Primary source: `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-VALIDATION.md`.

- **OPS-01 / OPS-02 targeted history/forensics suite**
  - `mix test test/oban_powertools/cron_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs`

### Bundle C: Traceability Reconciliation Verification

Planning artifact validation (docs-level):

- `rg -n "FRN-01|FRN-02|FRN-03|OPS-01|OPS-02" .planning/REQUIREMENTS.md`
- `rg -n "FRN-01|FRN-02|FRN-03" .planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-VERIFICATION.md`
- `rg -n "OPS-01|OPS-02" .planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-VERIFICATION.md`

Recommended evidence metadata to capture in each verification report run:

- UTC run timestamp
- `git rev-parse HEAD`
- exact command string
- pass/fail result and test count

---

## Verification Report Structure Pattern (Recommended)

Use the concise-auditable shape established by current context decisions and compatible with `.planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-VERIFICATION.md`:

1. Frontmatter (`phase`, `verified`, `status`, `score`).
2. Phase goal statement.
3. Backfill scope note (explicitly retrospective artifact addition, no runtime scope reopen).
4. Goal achievement table (roadmap must-haves / observable truths).
5. Requirement traceability table (requirement -> source plan(s) -> evidence command(s) -> status).
6. Automated proof table (commands + results).
7. Provenance section (which historical artifacts informed command selection and claim framing).
8. Residual risk section using two-tier confidence language.

Keep it compact:

- Include enough context for auditability.
- Avoid heavy contract-inventory sections unless new ambiguity appears.

---

## Requirement Traceability Strategy

For `37-03`, use this reconciliation sequence:

1. Create `32-VERIFICATION.md` and `33-VERIFICATION.md` first (authoritative closure artifacts for the orphaned requirements).
2. Update FRN/OPS rows in `.planning/REQUIREMENTS.md` from pending to complete only after those verification artifacts contain fresh evidence.
3. Keep reconciliation additive and scoped:
   - Close only `FRN-01`, `FRN-02`, `FRN-03`, `OPS-01`, `OPS-02`.
   - Leave `DOC-05` and `VER-04` untouched for Phase 38/39.
4. Preserve ownership clarity:
   - Runtime implementation provenance remains in Phase 32/33 summaries.
   - Present-tense closure surface for audit becomes the new phase verification files plus reconciled requirements table rows.

---

## Residual Risk Language (Use This Posture)

Use consistent wording like:

- "Phase-level closure is based on fresh targeted reruns scoped to FRN/OPS requirements."
- "This report does not claim repo-wide continuity or release readiness."
- "Broader continuity confidence remains dependent on milestone-level proof lanes (see Phase 39 `VER-04`)."

Avoid wording like:

- "All v1.4 tests are green" (unless full milestone suite evidence is actually included).
- "Milestone closure is complete" (outside Phase 37 boundary).

---

## Pitfalls and Anti-Patterns To Avoid

1. **Historical-only closure:** treating prior `*-SUMMARY.md` and `*-VALIDATION.md` content as sufficient present-tense proof.
2. **Overclaiming confidence:** using targeted reruns to imply repository-wide health.
3. **Ownership blur:** mixing primary requirement closure and supporting context without explicit distinction.
4. **Scope drift into runtime changes:** fixing implementation defects discovered during reruns inside Phase 37 instead of flagging follow-up scope.
5. **Traceability overreach:** rewriting unrelated requirement rows or broader milestone artifacts while reconciling FRN/OPS.
6. **Weak evidence logging:** recording commands without commit SHA/timestamp/result details.
7. **Report-shape extremes:** bare checkbox ledger (not auditable) or oversized narrative inventory (high maintenance, low incremental value).

---

## Validation Architecture

Phase 37 is documentation-first, but still has a concrete validation architecture:

1. **Evidence Source Layer (historical provenance)**
   - Phase 32/33 summaries and validation maps define intended requirement-to-proof topology.
2. **Fresh Evidence Layer (current truth)**
   - Targeted rerun command bundles produce present-tense executable proof.
3. **Closure Artifact Layer**
   - `32-VERIFICATION.md` and `33-VERIFICATION.md` become canonical requirement-closure documents.
4. **Traceability Reconciliation Layer**
   - `.planning/REQUIREMENTS.md` FRN/OPS rows are updated to align with new verification artifacts.
5. **Audit Consumption Layer**
   - Future milestone audit reads reconciled chain and should no longer flag FRN/OPS as orphaned.

Gate condition for planning completion:

- No FRN/OPS requirement should remain "implemented in summaries but missing from phase-level verification artifacts."

---

## Recommended Decomposition Into 3 Plans (Matches Roadmap)

### 37-01 Plan: Backfill Phase 32 Verification (FRN-01/02/03)

- **Objective:** publish `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-VERIFICATION.md`.
- **Inputs:** `32-VALIDATION.md`, `32-01/02/03-SUMMARY.md`, Phase 32 plan files, roadmap must-haves.
- **Execution shape:** run Bundle A; map each FRN requirement to explicit commands/results; include provenance and residual risk.
- **Done when:** FRN mapping is explicit, evidence is fresh/rerunnable, and report uses concise-auditable structure.

### 37-02 Plan: Backfill Phase 33 Verification (OPS-01/02)

- **Objective:** publish `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-VERIFICATION.md`.
- **Inputs:** `33-VALIDATION.md`, `33-01/02/03-SUMMARY.md`, Phase 33 context and plan artifacts.
- **Execution shape:** run Bundle B; map OPS requirements to command evidence; preserve partial/unknown boundary language.
- **Done when:** OPS mapping is explicit, targeted suite evidence is fresh, and residual risk reflects two-tier confidence posture.

### 37-03 Plan: Reconcile FRN/OPS Traceability

- **Objective:** remove orphan state in top-level requirement traceability for FRN/OPS.
- **Inputs:** newly created `32-VERIFICATION.md` and `33-VERIFICATION.md`, `.planning/REQUIREMENTS.md`, `.planning/v1.4-MILESTONE-AUDIT.md`.
- **Execution shape:** apply scoped FRN/OPS status reconciliation; verify refs via Bundle C; avoid touching DOC/VER closure lanes.
- **Done when:** FRN/OPS rows are reconciled to complete with a clear evidence chain and no unrelated traceability rewrites.

Recommended order/dependencies:

- `37-01` and `37-02` can be planned/executed independently.
- `37-03` depends on completion of both.

---

## Planning Notes on Failure Handling

If targeted reruns fail during implementation of this phase:

- Treat failures as evidence that closure cannot be claimed yet.
- Capture failing command output in the verification artifact draft or plan notes.
- Do not silently patch runtime scope inside this backfill phase; escalate as follow-up scope if needed.

This preserves Phase 37 boundary integrity and audit honesty.

---

## Planner Checklist

- [ ] Plan references Phase 37 boundary: verification/docs only, no runtime reopen.
- [ ] Plan defines exact command bundles for FRN and OPS closure claims.
- [ ] Plan defines evidence metadata capture (timestamp, commit SHA, command, result).
- [ ] Plan uses concise-auditable report shape for both verification files.
- [ ] Plan includes explicit residual risk language with two-tier confidence posture.
- [ ] Plan includes scoped `.planning/REQUIREMENTS.md` reconciliation for FRN/OPS only.
- [ ] Plan explicitly defers `DOC-05` and `VER-04` to Phase 38 and 39.

---

*Research intent: planning readiness for Phase 37; not execution.*
