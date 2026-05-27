## PATTERN MAPPING COMPLETE

# Phase 36: Docs, Example Host, Verification & Support-Truth Closure - Pattern Map

**Mapped:** 2026-05-27  
**Files analyzed:** 16 likely phase touchpoints  
**Analogs found:** 16 / 16

## File Classification (Likely Phase-36 Touchpoints)

| Likely New/Modified File | Action Bias | Role in Phase 36 Reconciliation | Closest Analog Pattern(s) | Match Quality |
|---|---|---|---|---|
| `.planning/phases/36-docs-example-host-verification-support-truth-closure/36-CONTEXT.md` | modify (scoped) | authoritative umbrella mapping (`36-01 -> 38`, `36-02 -> 39`, `36-03 -> reconciliation`) | `.planning/phases/25-traceability-audit-consistency-repair/25-PATTERNS.md` (additive closure memo posture), `.planning/phases/36-*/36-DISCUSSION-LOG.md` selected-option framing | strong |
| `.planning/phases/36-docs-example-host-verification-support-truth-closure/36-RESEARCH.md` | modify (scoped) | planning contract and drift-risk constraints | `.planning/phases/37-verification-backfill-forensic-ops-baseline/37-PATTERNS.md` (boundary-first planning notes), `.planning/phases/39-ci-continuity-proof-lane-closure/39-PATTERNS.md` | strong |
| `.planning/ROADMAP.md` | modify (scoped) | canonical sequencing narrative for split closure ownership | `.planning/phases/25-traceability-audit-consistency-repair/25-PATTERNS.md` (role-clarifying top-level edits), current Phase 38/39 sections in `ROADMAP.md` | strong |
| `.planning/REQUIREMENTS.md` | modify (scoped) | requirement traceability truth (`DOC-05`, `VER-04` references remain explicit and stable) | `.planning/phases/37-verification-backfill-forensic-ops-baseline/37-PATTERNS.md` reconciliation row pattern, `.planning/phases/25-traceability-audit-consistency-repair/25-PATTERNS.md` owner-phase-plus-proof posture | strong |
| `.planning/STATE.md` | modify (scoped) | session continuity and "where closure truth lives now" routing | `.planning/phases/25-traceability-audit-consistency-repair/25-PATTERNS.md`, `.planning/phases/26-historical-closeout-hygiene/26-PATTERNS.md` | strong |
| `README.md` | modify only if drift | top-level support-truth spoke; must stay aligned with docs-contract markers | `.planning/phases/38-docs-example-host-forensics-journey-closure/38-PATTERNS.md` (hub-and-spoke docs pattern), current `README.md` support-truth bullets | strong |
| `guides/forensics-and-runbook-handoffs.md` | modify only if drift | canonical DOC-05 hub (`DOC05-C1..C3`) | `.planning/phases/38-docs-example-host-forensics-journey-closure/38-PATTERNS.md` (canonical guide), `guides/first-operator-session.md` style | strong |
| `guides/example-app-walkthrough.md` | modify only if drift | fixture-backed DOC-05 spoke (`DOC05-C4`, `DOC05-C5`) | `.planning/phases/38-docs-example-host-forensics-journey-closure/38-PATTERNS.md`, `examples/phoenix_host/README.md` continuity wording pattern | strong |
| `guides/support-truth-and-ownership-boundaries.md` | modify only if drift | ownership vocabulary lock and evidence-boundary lock | `.planning/phases/31-docs-example-host-verification-support-truth-closure/31-PATTERNS.md`, current guide bucket structure | strong |
| `examples/phoenix_host/README.md` | modify only if drift | fixture-level DOC-05 continuity claim (`DOC05-C6`) and host-owned caveats | `.planning/phases/38-docs-example-host-forensics-journey-closure/38-PATTERNS.md` fixture contract pattern | strong |
| `test/oban_powertools/docs_contract_test.exs` | modify only if drift | merge-blocking docs-assertion contract and over-claim guards | `.planning/phases/31-docs-example-host-verification-support-truth-closure/31-PATTERNS.md`, `.planning/phases/39-ci-continuity-proof-lane-closure/39-PATTERNS.md` | strong |
| `.github/workflows/host-contract-proof.yml` | modify only if drift | continuity claim-lane topology and aggregate gate (`continuity-proof-status`) | `.planning/phases/39-ci-continuity-proof-lane-closure/39-PATTERNS.md` | strong |
| `.planning/phases/38-docs-example-host-forensics-journey-closure/38-VERIFICATION.md` | reference / edit only for correction | canonical DOC-05 evidence publication shape | `.planning/phases/37-verification-backfill-forensic-ops-baseline/37-VERIFICATION.md`, `.planning/phases/35-*/35-VERIFICATION.md` structure conventions | strong |
| `.planning/phases/39-ci-continuity-proof-lane-closure/39-VERIFICATION.md` | reference / edit only for correction | canonical VER-04 claim-to-evidence report shape | `.planning/phases/38-docs-example-host-forensics-journey-closure/38-VERIFICATION.md` table topology | strong |
| `.planning/phases/39-ci-continuity-proof-lane-closure/39-PROOF-MANIFEST.json` | reference / edit only for correction | machine-readable deterministic claim map (job + command + artifacts) | existing manifest structure in `39-PROOF-MANIFEST.json` | exact |
| `.planning/phases/36-docs-example-host-verification-support-truth-closure/36-PATTERNS.md` | create | planning handoff pattern index for Phase 36 | `31-PATTERNS.md`, `38-PATTERNS.md`, `39-PATTERNS.md` | strong |

## Pattern Assignments

### 1) Docs Contract Assertions (Claim-Scoped + Over-Claim Guards)

**Pattern to follow:** keep broad vocabulary checks via `joined_docs/0`, but enforce closure claims with file-scoped assertions and explicit anti-overclaim `refute` checks.

**Primary analog:** `test/oban_powertools/docs_contract_test.exs` plus the DOC-05 closure approach documented in `38-VERIFICATION.md`.

**Concrete snippet shape:**

```elixir
test "doc-05 forensics claims are file-scoped and complete" do
  canonical = File.read!("guides/forensics-and-runbook-handoffs.md")
  walkthrough = File.read!("guides/example-app-walkthrough.md")
  fixture = File.read!("examples/phoenix_host/README.md")

  assert canonical =~ "DOC05-C1"
  assert canonical =~ "DOC05-C2"
  assert canonical =~ "DOC05-C3"
  ...
  assert walkthrough =~ "DOC05-C4"
  assert walkthrough =~ "DOC05-C5"
  ...
  assert fixture =~ "DOC05-C6"
end
```

**Non-negotiable contract notes:**

- Preserve stable claim IDs (`DOC05-C1..C6`), do not silently repurpose.
- Keep ownership labels literal: `Powertools-native`, `Oban Web bridge`, `host-owned follow-up`.
- Keep evidence-boundary labels literal: `partial evidence`, `history unavailable`, `unknown`.
- Keep over-claim prohibitions explicit (`does not claim provider delivery certainty`, `does not guarantee provider delivery`).

### 2) CI Proof Topology (Claim Lanes + Aggregate Merge Gate)

**Pattern to follow:** continuity proof is explicit claim lanes (`VER04-C1..C4`) plus one `always()` aggregate status job that fails on missing artifacts, unsafe output, or upstream lane failures.

**Primary analog:** `.github/workflows/host-contract-proof.yml` as locked by `docs_contract_test.exs` and documented in `39-VERIFICATION.md`.

**Concrete snippet shape:**

```yml
continuity-ver04-c1:
  ...
  - name: Run VER04-C1 suite and emit claim evidence
    run: |
      CLAIM_ID="VER04-C1"
      CLAIM_COMMAND="mix test ... --seed 0"
      ...
  - name: Upload VER04-C1 claim artifact
    if: always()
    uses: actions/upload-artifact@v4
    with:
      if-no-files-found: error
```

```yml
continuity-proof-status:
  if: always()
  needs:
    - continuity-ver04-c1
    - continuity-ver04-c2
    - continuity-ver04-c3
    - continuity-ver04-c4
  ...
  - name: Enforce continuity proof failure boundaries
    if: always()
```

**Non-negotiable contract notes:**

- Keep check/job names stable (`continuity-ver04-c1..c4`, `continuity-proof-status`) because branch-protection and docs-contract assertions depend on them.
- Keep deterministic commands with `--seed 0`.
- Keep proof-packet minima required (`ver04-claim-matrix.md`, `ver04-claim-matrix.json`, `run-metadata.json`, `redaction-report.json`, claim logs).
- Keep redaction and upload failure boundaries hard-fail, not warning-only.

### 3) Verification Artifact Writing (Narrative Shell Around Canonical Claims)

**Pattern to follow:** use a compact frontmatter + must-have table + claim-to-evidence table + automated-proof table + published artifacts + residual risk.

**Primary analogs:** `38-VERIFICATION.md`, `39-VERIFICATION.md`, and backfill rigor from `37-VERIFICATION.md`.

**Concrete snippet shape:**

```md
---
phase: 39-ci-continuity-proof-lane-closure
verified: 2026-05-27T10:45:55Z
status: passed
score: 7/7 verification checks passed
---

## Goal Achievement
### ROADMAP Must-Haves
| # | Must-have | Status | Evidence |

### VER-04 Claim-to-Evidence
| Claim ID | Requirement | Workflow job | Deterministic command | Artifact references | Result status |

## Automated Proof
| Check | Command / Scope | Result | Status |
```

**Non-negotiable contract notes:**

- Canonical truth is deterministic claim mapping; prose is explanatory.
- Each requirement-claim row maps to one lane/command/evidence path.
- Residual risk statements must clearly separate "closed now" from "future drift risk."
- Any reconciliation update should point to Phase 38/39 artifacts rather than re-owning proof in Phase 36.

### 4) Reconciliation Docs Style (Additive, Not Historical Rewrite)

**Pattern to follow:** Phase 36 acts as an umbrella index that routes readers to executed closure artifacts without rewriting prior chronology.

**Primary analogs:** additive closure posture in `25-PATTERNS.md` and chronology hygiene posture in `26-PATTERNS.md`.

**Concrete snippet shape (style target):**

```md
- Keep original implementation ownership in traceability.
- Add explicit proof-pointer references for current closure.
- Preserve failed-or-historical artifacts; publish current canonical closure as additive chronology.
```

**Non-negotiable contract notes:**

- Maintain explicit reconciliation mapping: `36-01 -> Phase 38`, `36-02 -> Phase 39`, `36-03 -> milestone reconciliation outputs`.
- `ROADMAP.md` stays sequencing authority; `REQUIREMENTS.md` stays requirement ledger; `STATE.md` stays session continuity.
- Do not reopen runtime capability scope in reconciliation edits.
- Do not rename stable claim IDs or required check names in the name of cleanup.

## Planner/Executor Checklist (Phase-36 Specific)

- Start with contract-audit reads on docs/test/workflow surfaces before proposing edits.
- If no drift is found, prefer no-op reconciliation updates over churn.
- When drift exists, make the smallest additive correction and keep claim IDs/check names untouched.
- Reference existing closure owners (`38-VERIFICATION.md`, `39-VERIFICATION.md`, `39-PROOF-MANIFEST.json`) instead of duplicating canonical evidence.
- Preserve support-truth vocabulary exactly across README, guides, fixture docs, tests, and workflow contracts.
