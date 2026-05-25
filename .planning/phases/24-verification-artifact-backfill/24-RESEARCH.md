# Phase 24: Verification Artifact Backfill - Research

**Researched:** 2026-05-25
**Status:** Ready for planning

## Objective

Define how to backfill the missing phase-level `VERIFICATION.md` artifacts for Phases 17, 19, 20, 21, 22, and 23 using fresh rerunnable proof from the current repo state, while preserving historical ownership and support-truth boundaries.

## Repo Reality

- The missing closure artifacts are phase-local docs, not code gaps.
- The proof topology has evolved since Phases 17-21 shipped.
- Phase 23 split the old omnibus workflow runtime suite into focused current-state proof files:
  - `test/oban_powertools/workflow_runtime_transitions_test.exs`
  - `test/oban_powertools/workflow_runtime_signals_test.exs`
  - `test/oban_powertools/workflow_runtime_commands_test.exs`
  - `test/oban_powertools/workflow_callbacks_test.exs`
  - `test/oban_powertools/workflow_compatibility_test.exs`
- Phase 24 must translate older validation and summary evidence into this current proof topology instead of copying historical commands verbatim.

## Locked Backfill Rules

1. Fresh reruns close the claim; summaries and validation files remain provenance.
2. Each new `VERIFICATION.md` must distinguish primary requirement ownership from supporting cross-phase evidence.
3. The six backfilled files should share one compact report shape:
   - frontmatter
   - goal and backfill note
   - observable truths
   - behavioral spot-checks
   - requirements coverage
   - proof-topology notes
   - residual gaps or closure notes
4. Phase 24 must not repair top-level traceability tables in `.planning/REQUIREMENTS.md`; that is Phase 25.
5. Phase 24 must not broaden supported upgrade-lane or telemetry claims beyond what Phase 23 already locked.

## Requirement Closure Map

| Requirement | Canonical backfill target | Supporting backfill targets | Why |
|---|---|---|---|
| `WFS-02` | `17-VERIFICATION.md` | `22-VERIFICATION.md` | Phase 17 owns DB-first command legality; Phase 22 proves operator actions still re-enter that core. |
| `REC-03` | `20-VERIFICATION.md` | `17-VERIFICATION.md`, `22-VERIFICATION.md` | Phase 20 owns request-versus-outcome semantics; adjacent phases provide earlier command-routing and operator handoff support. |
| `SIG-01` | `19-VERIFICATION.md` | none | Await registration authority is Phase 19's core ownership. |
| `SIG-02` | `19-VERIFICATION.md` | none | Durable signal-fact ingress and idempotent reconciliation were closed in Phase 19. |
| `SIG-03` | `19-VERIFICATION.md` | `20-VERIFICATION.md` | Phase 19 owns expiry authority; Phase 20 adds cancel-race and late-evidence posture. |
| `DIA-01` | `21-VERIFICATION.md` | `20-VERIFICATION.md` | Phase 21 owns diagnosis projection and native workflow surface; Phase 20 provides terminal-truth ordering support. |
| `DIA-02` | `22-VERIFICATION.md` | `21-VERIFICATION.md` | Phase 22 owns bounded workflow action parity across Lifeline and workflow surfaces. |
| `VER-01` | split across all six backfills | none | The proof obligation is phase-scoped; each file must show the exact current command bundle that closes its slice. |

## Current Proof Bundles To Reuse

### Phase 17 backfill

- Historical source artifacts:
  - `17-01-SUMMARY.md`
  - `17-02-SUMMARY.md`
  - `17-03-SUMMARY.md`
  - `17-PLAN-CHECK.md`
- Current proof seams:
  - `test/oban_powertools/workflow_runtime_transitions_test.exs`
  - `test/oban_powertools/workflow_runtime_commands_test.exs`
  - `test/oban_powertools/workflow_coordinator_test.exs`
  - `test/oban_powertools/lifeline_test.exs`
  - `test/oban_powertools/web/live/workflows_live_test.exs`
  - `test/oban_powertools/web/router_test.exs`
  - `test/oban_powertools/workflow_compatibility_test.exs`
- Backfill concern:
  - Keep command-core ownership primary.
  - Show later diagnostics and operator parity only as supporting evidence.

### Phase 19 backfill

- Historical source artifacts:
  - `19-01-SUMMARY.md`
  - `19-02-SUMMARY.md`
  - `19-03-SUMMARY.md`
  - `19-VALIDATION.md`
- Current proof seams:
  - `test/oban_powertools/workflow_runtime_signals_test.exs`
  - `test/oban_powertools/workflow_coordinator_test.exs`
  - `test/oban_powertools/example_host_contract_test.exs --only upgrade-proof`
- Backfill concern:
  - Treat await authority, signal-fact authority, and expiry authority as one phase-level story.
  - Preserve `VER-02` as supporting upgrade continuity, not primary ownership.

### Phase 20 backfill

- Historical source artifacts:
  - `20-01-SUMMARY.md`
  - `20-02-SUMMARY.md`
  - `20-03-SUMMARY.md`
  - `20-VALIDATION.md`
- Current proof seams:
  - `test/oban_powertools/workflow_runtime_commands_test.exs`
  - `test/oban_powertools/workflow_runtime_signals_test.exs`
  - `test/oban_powertools/workflow_coordinator_test.exs`
  - `test/oban_powertools/explain_test.exs`
  - `test/oban_powertools/example_host_contract_test.exs --only upgrade-proof`
- Backfill concern:
  - Make cancel-request evidence and final truth ordering explicit.
  - Keep `SIG-03` supporting, not re-owned away from Phase 19.

### Phase 21 backfill

- Historical source artifacts:
  - `21-01-SUMMARY.md`
  - `21-02-SUMMARY.md`
  - `21-03-SUMMARY.md`
  - `21-VALIDATION.md`
- Current proof seams:
  - `test/oban_powertools/explain_test.exs`
  - `test/oban_powertools/web/live/workflows_live_test.exs`
  - `test/oban_powertools/lifeline_test.exs`
  - `test/oban_powertools/web/live/lifeline_live_test.exs`
- Backfill concern:
  - `21-VALIDATION.md` is not enough by itself.
  - The new verification file must show fresh workflow diagnosis and LiveView proof from current code.

### Phase 22 backfill

- Historical source artifacts:
  - `22-01-SUMMARY.md`
  - `22-02-SUMMARY.md`
  - `22-03-SUMMARY.md`
  - `22-VALIDATION.md`
- Current proof seams:
  - `test/oban_powertools/lifeline_test.exs`
  - `test/oban_powertools/web/live/lifeline_live_test.exs`
  - `test/oban_powertools/web/live/workflows_live_test.exs`
  - `test/oban_powertools/explain_test.exs`
  - `test/oban_powertools/workflow_runtime_commands_test.exs`
- Backfill concern:
  - Aggregate the three plans into one phase-level closure artifact.
  - Preserve read-only workflow diagnosis versus Lifeline execute ownership.

### Phase 23 backfill

- Historical source artifacts:
  - `23-01-SUMMARY.md`
  - `23-02-SUMMARY.md`
  - `23-03-SUMMARY.md`
  - `23-VALIDATION.md`
- Current proof seams:
  - `test/oban_powertools/workflow_runtime_transitions_test.exs`
  - `test/oban_powertools/workflow_runtime_signals_test.exs`
  - `test/oban_powertools/workflow_runtime_commands_test.exs`
  - `test/oban_powertools/workflow_callbacks_test.exs`
  - `test/oban_powertools/workflow_compatibility_test.exs`
  - `test/oban_powertools/example_host_contract_test.exs --only upgrade-proof`
  - `test/oban_powertools/telemetry_test.exs`
  - `test/oban_powertools/docs_contract_test.exs`
- Backfill concern:
  - Keep the supported host lane singular.
  - Keep repo-local compatibility and docs/telemetry support truth explicitly supporting, not flattened into one lane.

## Recommended Execution Split

### Wave 1

- Backfill `17-VERIFICATION.md`, `19-VERIFICATION.md`, and `20-VERIFICATION.md`.
- Reason:
  - These files define the command-core, signal, expiry, and cancellation ownership chain that later diagnosis and operator-surface reports should reference.

### Wave 2

- Backfill `21-VERIFICATION.md` and `22-VERIFICATION.md`.
- Reason:
  - These are surface-oriented proof artifacts that depend on the command and cancellation stories already being stated cleanly.

### Wave 3

- Backfill `23-VERIFICATION.md`.
- Run a consistency audit across all six new files.
- Reason:
  - Phase 23 is the public-proof/support-truth closure layer and should be written last so it can cite the final backfill topology.

## Risks

### Historical-command drift

Older summaries and validation docs reference `workflow_runtime_test.exs`, but the current repo proof is split. Copying the old commands would create false or stale closure.

### Ownership drift

If the new files reuse `requirements-completed` lists from summaries without a primary/supporting distinction, the backfill will silently reassign requirement ownership.

### Phase 25 leakage

If Phase 24 edits `.planning/REQUIREMENTS.md`, roadmap traceability, or the milestone audit tables directly, it collapses the explicit follow-on scope for Phase 25.

### Phase 23 support-truth flattening

If `23-VERIFICATION.md` merges repo-local compatibility proof with the singular supported upgrade lane, it breaks the locked support posture.

## Validation Architecture

### Verification style

- Use executable proof plus grep-backed report-shape checks.
- Every task must rerun the exact current bundle it cites in the new `VERIFICATION.md`.
- Every task must grep the new docs for:
  - `## Observable Truths`
  - `## Behavioral Spot-Checks`
  - `## Requirements Coverage`
  - `## Proof Topology Notes`

### Wave-end proof bundles

| Wave | Command bundle | Purpose |
|---|---|---|
| 1 | `mix test test/oban_powertools/workflow_runtime_transitions_test.exs test/oban_powertools/workflow_runtime_signals_test.exs test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/explain_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/workflow_compatibility_test.exs test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` | Fresh proof for the command-core, signal, expiry, cancel, and upgrade continuity backfills. |
| 2 | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/workflow_runtime_commands_test.exs` | Fresh proof for diagnosis, workflow/Lifeline parity, and bounded operator actions. |
| 3 | `mix test test/oban_powertools/workflow_runtime_transitions_test.exs test/oban_powertools/workflow_runtime_signals_test.exs test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/workflow_compatibility_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/telemetry_test.exs test/oban_powertools/docs_contract_test.exs test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` | Fresh proof for the public-proof closure layer and final support-truth audit. |

### Approval criteria

- Each missing phase gets one canonical `VERIFICATION.md`.
- Every file contains a backfill note and separates primary from supporting evidence.
- Every cited proof command is current and rerunnable in this repo state.
- No Phase 24 task changes top-level requirement traceability tables.

