# Phase 5: Milestone Evidence & Traceability Closure - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 16
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/REQUIREMENTS.md` + requirements coverage table in `.planning/v1-v1-MILESTONE-AUDIT.md` | role-match |
| `.planning/phases/{0,1,2,3,4}-VERIFICATION.md` | config | transform | `.planning/phases/4-PLAN-CHECK.md` + existing `*-VALIDATION.md` files | partial |
| `.planning/phases/{0,2,3}-VALIDATION.md` | config | transform | `.planning/phases/0-VALIDATION.md`, `.planning/phases/2-VALIDATION.md`, `.planning/phases/3-VALIDATION.md` | exact |
| `.planning/phases/{1,4}-VALIDATION.md` | config | transform | `.planning/phases/2-VALIDATION.md`, `.planning/phases/3-VALIDATION.md` | role-match |
| `.planning/phases/0-01-SUMMARY.md` | config | transform | `.planning/phases/1-01-SUMMARY.md` | role-match |
| `.planning/phases/{2-01,2-02,2-03,2-04,2-05}-SUMMARY.md` | config | transform | `.planning/phases/1-01-SUMMARY.md`, `.planning/phases/4-02-SUMMARY.md` | role-match |
| `.planning/phases/{3-01,3-02,3-03,3-04,3-05}-SUMMARY.md` | config | transform | `.planning/phases/1-01-SUMMARY.md`, `.planning/phases/4-03-SUMMARY.md` | role-match |
| `.planning/v1-v1-MILESTONE-AUDIT.md` | config | transform | `.planning/v1-v1-MILESTONE-AUDIT.md` | exact |

## Pattern Assignments

### Summary Frontmatter: use Phase 1 / Phase 4 as the forward standard

**Strongest local analogs**
- `.planning/phases/1-01-SUMMARY.md`
- `.planning/phases/4-01-SUMMARY.md`
- `.planning/phases/4-02-SUMMARY.md`
- `.planning/phases/4-03-SUMMARY.md`

**Copy this shape**
- YAML frontmatter first, then human-readable summary body.
- Keep these keys stable because they already exist locally and are grep-able: `phase`, `plan`, `subsystem`, `tags`, `requires`, `provides`, `affects`, `tech-stack`, `key-files`, `key-decisions`, `patterns-established`, `requirements-completed`, `duration`, `completed`.
- Keep `requirements-completed` as the summary-side proof hook. This is the only local field already acting as machine-readable requirement evidence.

**Legacy gaps to repair, not redesign**
- `.planning/phases/0-01-SUMMARY.md` has frontmatter, but it uses the older `tech_stack_*`, `key_files_*`, `key_decisions`, `metrics` shape and has no `requirements-completed`.
- `.planning/phases/2-04-SUMMARY.md` and `.planning/phases/2-05-SUMMARY.md` have usable body sections (`## Outcome`, `## Delivered`, `## Verification`) but no frontmatter.
- `.planning/phases/3-01-SUMMARY.md` through `.planning/phases/3-05-SUMMARY.md` have the same body-only pattern and need frontmatter normalization, not prose rewrites.

**Phase 5 rule**
- Normalize only what the audit needs for traceability closure: frontmatter, missing summary files, requirement ids, and explicit verification references.
- Do not rewrite historical body prose for tone or style.

### Validation And Verification Artifacts: validation maps commands, verification records fresh results

**Validation analogs**
- `.planning/phases/0-VALIDATION.md`
- `.planning/phases/2-VALIDATION.md`
- `.planning/phases/3-VALIDATION.md`

**Existing local validation pattern**
- `## Test Framework`
- `## Phase Requirements -> Test Map` or `## Phase Requirements → Test Map`
- `## Execution Requirements`
- `## Gap Coverage`

**Known gaps**
- No phase has a `*-VERIFICATION.md`.
- Phases 1 and 4 have no `*-VALIDATION.md`.
- Existing validation docs lack Nyquist/frontmatter metadata; the audit flags this explicitly for Phases 0, 2, and 3.
- `.planning/phases/4-PLAN-CHECK.md` is a planning-validity artifact, not implementation proof. Do not treat it as substitute verification evidence.

**Phase 5 rule**
- `VALIDATION.md` should stay command-map oriented.
- `VERIFICATION.md` should record fresh repo-state outcomes for the mapped commands and call out unresolved requirements explicitly.
- Broad commands like `mix test` may appear, but only alongside narrower requirement-linked commands already used locally in validation docs.

### Requirement Traceability: follow the audit's 3-source check and preserve implementation ownership

**Authoritative local chain**
- `REQUIREMENTS.md`
- summary frontmatter `requirements-completed`
- per-phase `VERIFICATION.md`

**Best local model**
- The audit’s `Requirements Coverage` table in `.planning/v1-v1-MILESTONE-AUDIT.md` is the clearest repo-local shape for closure logic: ownership, summary evidence, verification evidence, final state.

**Current gaps**
- `REQUIREMENTS.md` currently has only `Requirement | Phase | Status`, which is too coarse and conflates ownership with closure.
- Phase 4 summaries claim `LIF-01` through `LIF-04` complete, but `REQUIREMENTS.md` still says `Pending`.
- Audit scope for Phase 5 is narrower than “close everything”: `FND-03`, `WRK-01..03`, `ENG-01..02`, `WF-01..03`, `LIF-01`, `LIF-03`, and `LIF-04` are Phase 5 closure candidates. `FND-01`, `FND-02`, `ENG-03`, and `LIF-02` remain owned by Phases 6 or 7 because real implementation gaps still exist.

**Phase 5 rule**
- Preserve original implementation phase ownership in `REQUIREMENTS.md`.
- Add proof/closure columns or equivalent explicit metadata rather than reassigning implemented work to Phase 5.
- A requirement must not move to `complete` unless summary evidence and fresh verification evidence both exist.

### Recommended Plan Split Seams

These seams match both the audit findings and the repo’s prior habit of splitting work into narrow, reviewable artifact families rather than one giant catch-up patch.

| Suggested Plan | Scope | Why this seam matches local history |
|---|---|---|
| `5-01` | Traceability contract: normalize `REQUIREMENTS.md` semantics, define verification/frontmatter schema, decide unresolved-requirement handling | Equivalent to the “persistence/contracts first” slice used in Phases 2, 3, and 4 |
| `5-02` | Phase 0 and Phase 1 evidence repair: missing validation/verification and legacy summary normalization | Small, foundational closure slice with minimal overlap into later phases |
| `5-03` | Phase 2 restoration: create missing `2-01..03` summaries, normalize `2-04/05`, add/update validation + verification | Phase 2 is the only phase with missing summary files; it deserves its own artifact-recovery plan |
| `5-04` | Phase 3 normalization: add frontmatter to `3-01..05`, add/update validation + verification | Phase 3 has complete bodies but missing machine-readable metadata, a clean standalone seam |
| `5-05` | Phase 4 sync and final closure: add missing validation/verification, reconcile `LIF-01/03/04` status, rerun milestone audit, record remaining Phase 6/7 gaps | Mirrors prior “final integration/UI/audit pass” slices and keeps `LIF-02` exception handling isolated |

## Shared Patterns

### Stable naming
- Keep the repo’s flat phase layout: `N-CONTEXT.md`, `N-PATTERNS.md`, `N-VALIDATION.md`, `N-VERIFICATION.md`, `N-XX-PLAN.md`, `N-XX-SUMMARY.md`.
- Do not invent nested evidence folders for Phase 5.

### Explicit provenance
- When a legacy file is normalized retrospectively, make that visible in the body or frontmatter rather than implying it was original same-day authorship.
- Keep requirement ids, commands, and outcome language stable and grep-able.

### Fresh-proof posture
- Prefer commands already named in local validation docs and summaries.
- Re-running the milestone audit is part of the verification chain, not an optional appendix.

## Anti-Patterns

- Do not fix the runtime-config defect for `FND-01` or `FND-02` here. That belongs to Phase 6.
- Do not fix cron preview authorization ordering for `ENG-03` here. That belongs to Phase 6.
- Do not fix incident retirement after repair for `LIF-02` here. That belongs to Phase 7.
- Do not reassign already-built requirements to Phase 5 as if it implemented them.
- Do not treat `.planning/phases/4-PLAN-CHECK.md` as runtime verification evidence.
- Do not perform repo-wide wording cleanup or template migration beyond the specific broken artifacts the audit names.
- Do not use `mix format` or unrelated source churn as a closure substitute for missing evidence.

## SUMMARY

Changed files:
- `.planning/phases/5-PATTERNS.md`
