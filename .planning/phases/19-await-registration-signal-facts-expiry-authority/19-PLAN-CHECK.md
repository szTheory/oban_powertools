**Phase:** Phase 19: Await Registration, Signal Facts & Expiry Authority
**Plans checked:** 3
**Status:** 0 blocker(s), 0 warning(s), 0 info
**Scope of this pass:** Manual repo-local planning verification against roadmap, locked context, research, pattern map, validation strategy, current workflow runtime code, current tests, and supported-host upgrade surfaces

### Coverage Summary

| Requirement | Plans | Status |
|-------------|-------|--------|
| SIG-01 | 19-01 | Covered |
| SIG-02 | 19-02 | Covered |
| SIG-03 | 19-03 | Covered |
| VER-01 | 19-02, 19-03 | Covered |
| VER-02 | 19-01, 19-03 | Covered |

### Plan Summary

| Plan | Tasks | Files | Wave | Depends On | Status |
|------|-------|-------|------|------------|--------|
| 19-01 | 2 | 11 | 1 | - | Valid |
| 19-02 | 2 | 6 | 2 | 19-01 | Valid |
| 19-03 | 2 | 7 | 3 | 19-01, 19-02 | Valid |

### Verification Notes

- Requirement coverage now closes the full Phase 19 contract. `19-01` owns `SIG-01` plus schema and upgrade-parity groundwork for `VER-02`, `19-02` owns the facts-first workflow-authoritative `SIG-02` behavior and core `VER-01` proof lane, and `19-03` owns authoritative expiry for `SIG-03` plus the final proof and planning-truth alignment for `VER-01` and `VER-02`.
- Sequencing is coherent against the current code. The plans first lock row contract and migration parity, then refactor signal ingress/matching, then collapse expiry authority and widen proof. That matches the existing seams in `lib/oban_powertools/workflow/runtime.ex`, where await registration, signal ingestion, reconcile, and expiry are already present but still too loosely coupled for the Phase 19 decisions.
- Realism is acceptable. The revised plans work with the actual repo surfaces instead of inventing new ones: `Await`, `SignalRecord`, `Step`, installer/test/example migrations, `Workflow.deliver_signal/2`, `Workflow.await_step/4`, `workflow_runtime_test.exs`, `workflow_coordinator_test.exs`, and the archived host-proof helper already exist and are named directly in task actions and verification.
- Migration parity is now explicitly planned end-to-end. `19-01` updates the runtime schema modules, installer migration, repo test migration, current example-host migration, and archived upgrade-source migration together, then verifies them with both grep parity checks and the upgrade-proof lane. That closes the prior partial `VER-02` gap.
- Nyquist compliance now passes. `19-VALIDATION.md` exists, every implementation task has an automated verification command, sampling continuity is intact across all six tasks, no watch-mode commands appear, and the validation map covers the archived upgrade proof and planning-contract checks that the revised plans depend on.
- Proof sufficiency is now strong enough for the phase goal. The plans require automated evidence for pre-await signals, duplicates, replay, ambiguous correlation, late-after-expiry behavior, lost-wakeup reconciliation, and archived upgrade preservation of in-flight waiting workflows. That aligns with the proof posture in `.planning/REQUIREMENTS.md` and the gaps identified in `19-RESEARCH.md`.
- Phase-boundary discipline is intact. The plans stay inside durable await registration, canonical signal facts, duplicate/replay evidence posture, and single-authority expiry semantics. They do not introduce multi-wait fan-in, a generic event bus, or broader cancel/completion precedence rules that `19-CONTEXT.md` defers to Phase 20. The `.planning/PROJECT.md` and `.planning/REQUIREMENTS.md` edits in `19-03` are constrained to post-proof traceability and support-truth alignment, which is within scope.

Plans verified. Execution can proceed from these artifacts without the earlier coverage or validation-gate gaps.

## VERIFICATION PASSED
