# Phase 39 Research: CI Continuity Proof Lane Closure

**Date:** 2026-05-27  
**Phase:** 39  
**Goal:** make continuity suites auditable in CI so `VER-04` closure is merge-blocking and reproducible.  
**Boundary:** CI proof-lane wiring, evidence artifact publication, and requirement traceability closure only.

---

## What You Need To Know To Plan This Phase Well

1. `VER-04` is the only pending v1.4 requirement and Phase 39 is its closure owner; no additional feature scope should be added.
2. The host-contract CI workflow already has stable, named jobs and branch-protection-safe check naming in `.github/workflows/host-contract-proof.yml`; continuity proof should extend this workflow, not replace it.
3. Phase-level verification from phases 32, 33, 35, and 38 already defines high-signal command bundles and claim language that can be reused as CI continuity shards.
4. The phase context locks a claim-oriented model (`VER04-C1..C4`) with deterministic reruns (`--seed 0`) and explicit ownership boundary wording.
5. Evidence publication is required on both pass and fail paths (`if: always()`), and artifact absence or redaction failure must fail the continuity gate.
6. The merge-blocking surface should be a single stable aggregate status job (for example `continuity-proof-status`) that depends on all claim shards.
7. Requirements traceability (`.planning/REQUIREMENTS.md`) should be updated only after deterministic proof artifacts and a phase verification report are published.

---

## Canonical Inputs And Dependencies

- `.planning/phases/39-ci-continuity-proof-lane-closure/39-CONTEXT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md` (`VER-04` currently pending)
- `.planning/STATE.md`
- `.github/workflows/host-contract-proof.yml`
- `test/oban_powertools/docs_contract_test.exs`
- `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-VERIFICATION.md`
- `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-VERIFICATION.md`
- `.planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-VERIFICATION.md`
- `.planning/phases/38-docs-example-host-forensics-journey-closure/38-VERIFICATION.md`

---

## Existing CI Topology Findings

1. `host-contract-proof.yml` already encodes a lane-per-proof style (`structural`, `docs-contract`, `first-session`, `workflow-compatibility`, etc.), which is compatible with adding continuity-specific shards.
2. The existing docs contract lane currently checks for baseline lanes; Phase 39 will likely need to expand it so continuity lanes are contract-locked too.
3. Existing jobs use explicit test file targets rather than broad `mix test`; this minimizes runtime and gives more actionable failure output.
4. DB-backed test jobs consistently provision Postgres service blocks; continuity shards can follow this established pattern.

---

## Claim-To-Command Continuity Mapping (Recommended)

Use explicit claim IDs in CI and artifacts:

| Claim ID | Claim Area | Recommended deterministic command(s) |
|---|---|---|
| `VER04-C1` | Forensic timeline projection continuity | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/audit_live_test.exs --seed 0` |
| `VER04-C2` | Limiter and cron history behavior continuity | `mix test test/oban_powertools/cron_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs --seed 0` |
| `VER04-C3` | Runbook guidance rendering and ownership-boundary continuity | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0` |
| `VER04-C4` | Diagnosis/action/audit continuity and proof-lane coherence | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/audit_live_test.exs --seed 0` plus `mix test test/oban_powertools/docs_contract_test.exs --seed 0` for wording/contract posture |

Notes:
- Keep claim commands narrow and stable to avoid flake-driven gate churn.
- Each claim should emit a small per-claim log file for failed-command evidence.

---

## Required Evidence Packet Shape

For every continuity workflow run, publish:

1. `ver04-claim-matrix.md` (human-readable summary)
2. `ver04-claim-matrix.json` (machine-readable claim status and command map)
3. `run-metadata.json` (run id, commit SHA, workflow path, timestamp, seed policy)
4. `redaction-report.json` (artifact safety scan result)
5. Per-failing-claim sanitized logs (for example `logs/VER04-C2.log`)

Guardrails:
- Upload step must run with `if: always()`.
- Upload action should set `if-no-files-found: error`.
- Any failed redaction scan should fail the aggregate continuity status.

---

## Traceability Closure Strategy

1. Generate a deterministic proof manifest at `.planning/phases/39-ci-continuity-proof-lane-closure/39-PROOF-MANIFEST.json` with:
   - claim id
   - command
   - workflow job id
   - artifact paths
   - requirement mapping (`VER-04`)
2. Publish `.planning/phases/39-ci-continuity-proof-lane-closure/39-VERIFICATION.md` with command outputs and claim evidence mapping.
3. Reconcile `.planning/REQUIREMENTS.md` from `VER-04 | Pending` to complete only after proof manifest + verification artifact exist and continuity lane checks are wired.

---

## Risks And Anti-Patterns

1. **Opaque umbrella command risk**  
   One monolithic continuity command hides which claim failed.  
   **Mitigation:** keep `VER04-C1..C4` discrete and aggregate at status job.

2. **False-positive green risk from missing artifacts**  
   Tests can pass while evidence packet is absent.  
   **Mitigation:** hard-fail on missing required files and redaction failures.

3. **Branch-protection drift risk**  
   Renaming jobs/checks breaks merge policy unexpectedly.  
   **Mitigation:** freeze stable check names and assert them in docs contract tests.

4. **Overlapping test suites inflate runtime**  
   Excess overlap can make CI noisy and slow.  
   **Mitigation:** keep shards claim-scoped and reuse existing targeted suites.

5. **Premature VER-04 status flip risk**  
   Updating requirements without durable proof artifacts weakens audit integrity.  
   **Mitigation:** gate requirement reconciliation behind manifest + verification publication.

---

## Validation Architecture

### Validation Layers

1. **Lane topology validation**  
   Ensure workflow contains continuity claim jobs and aggregate status job with stable names.

2. **Command determinism validation**  
   Every claim command uses `--seed 0` and explicit file lists.

3. **Artifact contract validation**  
   Required evidence files always published; missing/unsafe artifacts fail the run.

4. **Traceability validation**  
   `39-PROOF-MANIFEST.json`, `39-VERIFICATION.md`, and `.planning/REQUIREMENTS.md` agree on `VER-04` closure references.

### Verification Commands (Planning Inputs)

- `mix test test/oban_powertools/docs_contract_test.exs --seed 0`
- `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/audit_live_test.exs --seed 0`
- `mix test test/oban_powertools/cron_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs --seed 0`
- `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0`
- `rg -n "continuity-proof|continuity-proof-status|VER04-C1|VER04-C2|VER04-C3|VER04-C4" .github/workflows/host-contract-proof.yml`

---

## Recommended Plan Decomposition (39-01 / 39-02 / 39-03)

### 39-01: CI Continuity Lane Wiring
- Add continuity claim shards and aggregate merge-blocking status job in `host-contract-proof.yml`.
- Expand docs-contract workflow assertions for continuity lane check names.

### 39-02: Evidence Artifact and Fail-Boundary Publishing
- Generate claim matrix + metadata + redaction report in CI.
- Upload required proof packet on every run and hard-fail on missing/unsafe artifacts.

### 39-03: VER-04 Traceability Closure
- Publish `39-PROOF-MANIFEST.json` and `39-VERIFICATION.md`.
- Reconcile `.planning/REQUIREMENTS.md` with explicit Phase 39 proof references.

---

## Planner Checklist

- [ ] Plans keep scope restricted to CI continuity closure for `VER-04`.
- [ ] Claim IDs `VER04-C1..C4` map to deterministic commands with `--seed 0`.
- [ ] Aggregate continuity gate is explicit and branch-protection friendly.
- [ ] Required proof packet is always emitted and enforced.
- [ ] `39-PROOF-MANIFEST.json` and `39-VERIFICATION.md` are explicit deliverables.
- [ ] `.planning/REQUIREMENTS.md` reconciliation is gated on published evidence.

---

*Research intent: planning readiness for Phase 39; not phase execution.*
