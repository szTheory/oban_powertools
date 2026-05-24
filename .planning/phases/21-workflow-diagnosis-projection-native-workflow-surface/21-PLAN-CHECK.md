**Phase:** Phase 21: Workflow Diagnosis Projection & Native Workflow Surface
**Plans checked:** 3
**Status:** 0 blocker(s), 0 warning(s), 1 info
**Scope of this pass:** Manual repo-local planning verification against roadmap, locked context, approved UI-SPEC, Phase 20 outputs, current workflow diagnosis/runtime code, LiveView routing behavior, Lifeline incident projection, and the focused proof seams already present in the repo

### Coverage Summary

| Requirement | Plans | Status |
|-------------|-------|--------|
| DIA-01 | 21-01, 21-02, 21-03 | Covered |
| DIA-02 | 21-02, 21-03 | Covered |
| VER-01 | 21-01, 21-02, 21-03 | Covered |
| VER-02 | 21-03 | Covered |

### Plan Summary

| Plan | Tasks | Files | Wave | Depends On | Status |
|------|-------|-------|------|------------|--------|
| 21-01 | 2 | 4 | 1 | - | Valid |
| 21-02 | 2 | 4 | 2 | 21-01 | Valid |
| 21-03 | 2 | 7 | 3 | 21-01, 21-02 | Valid |

### Verification Notes

- Sequencing is coherent against the current code. `21-01` fixes the shared meaning layer first in `Runtime` and `Explain`, `21-02` then replaces the current first-blocked-step fallback with durable primary-step selection, and `21-03` reshapes `WorkflowsLive` plus Lifeline parity on top of those shared semantics.
- Phase-boundary discipline is intact. The plans stay inside workflow diagnosis projection and the native workflow surface. They do not pull forward Phase 22’s bounded audited workflow actions, preview flows, or broader mutation UX.
- Realism is acceptable. The plans name existing repo seams that already own this problem: `Runtime.workflow_diagnosis/2`, `Runtime.step_diagnosis/1`, `Explain.workflow_story/3`, `Explain.step_story/2`, `WorkflowsLive.handle_params/3`, patch-driven `?step=` routing, and `Lifeline` workflow-stuck incident projection.
- The locked Phase 21 defaults are respected. Diagnosis remains Postgres-truth-first, narrative stays projector-owned instead of HEEx-owned, raw facts stay available one level lower, and allowed next action is planned as informational guidance only.
- Verification cadence matches `21-VALIDATION.md`. Each task has an automated proof lane, the plans rely on the existing `workflow_runtime`, `explain`, `lifeline`, and `workflows_live` suites, and the final wave ends with the targeted full proof bundle named by the validation artifact.
- UI contract alignment is explicit. `21-03` uses the approved `21-UI-SPEC.md` to keep the page diagnosis-first, evidence-second, raw-facts-third while preserving the current patch-based inspection model.

### Info

- `VER-02` coverage in Phase 21 is deliberately narrow. The plans do not introduce new host-upgrade fixtures; instead they ensure upgraded or in-flight workflows remain explainable through the shared projector and neighboring surfaces. That is acceptable for this phase because Phase 23 still owns the broader upgrade-proof closure.

Plans verified. Execution can proceed from these artifacts without reopening phase scope or pulling Phase 22 action semantics forward.

## VERIFICATION PASSED
