# Phase 23: Verification, Upgrade Proof, Telemetry & Support-Truth Closure - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 11
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/oban_powertools/workflow_runtime_transitions_test.exs` | test | DB-first integration | same file | exact |
| `test/oban_powertools/workflow_runtime_signals_test.exs` | test | DB-first integration | same file | exact |
| `test/oban_powertools/workflow_runtime_commands_test.exs` | test | DB-first integration | same file | exact |
| `test/oban_powertools/workflow_callbacks_test.exs` | test | outbox integration | same file | exact |
| `test/oban_powertools/workflow_compatibility_test.exs` | test | repo-local historical proof | same file | exact |
| `test/support/example_host_contract.ex` | fixture harness | host proof orchestration | same file | exact |
| `test/oban_powertools/example_host_contract_test.exs` | acceptance test | supported host lane | same file | exact |
| `.github/workflows/host-contract-proof.yml` | CI contract | proof lane routing | same file | exact |
| `lib/oban_powertools/telemetry.ex` | public API | bounded telemetry contract | same file | exact |
| `test/oban_powertools/telemetry_test.exs` | contract test | public telemetry verification | same file | exact |
| `test/oban_powertools/docs_contract_test.exs` | docs contract test | support-truth enforcement | same file | exact |

## Pattern Assignments

### Focused workflow proof suites

**Pattern:** Keep one concern per runtime test module and widen locally instead of rebuilding a mega-suite.

**Evidence:**
- `workflow_runtime_transitions_test.exs` owns lifecycle transitions.
- `workflow_runtime_signals_test.exs` owns await/signal/late/duplicate semantics.
- `workflow_runtime_commands_test.exs` owns cancel, recovery, and command-evidence semantics.
- `workflow_callbacks_test.exs` owns narrow callback and outbox behavior.

**Planning takeaway:** Phase 23 proof work should extend these focused suites, not recreate `workflow_runtime_test.exs`.

### Repo-local historical compatibility proof

**Pattern:** Prove broader semantic continuity in a library-owned lane that is explicitly not the supported host upgrade lane.

**Evidence:** `test/oban_powertools/workflow_compatibility_test.exs` already covers legacy waiting, cancel-request evidence, cancelled meaning, and recovery evidence.

**Planning takeaway:** Add retrying/cancelling/recovering continuity here if needed, then point docs and CI wording at this lane as `tested`, not `supported`.

### Singular supported host upgrade lane

**Pattern:** One host fixture lane proves one deterministic source-host upgrade plus one sentinel workflow continuity case.

**Evidence:**
- `test/support/example_host_contract.ex`
- `test/oban_powertools/example_host_contract_test.exs`
- `.github/workflows/host-contract-proof.yml`
- `guides/upgrade-and-compatibility.md`

**Planning takeaway:** Keep `upgrade-proof` narrow. Do not pack retry/cancel/recovery matrices into the host lane.

### Marker-based docs contract

**Pattern:** Freeze a short exact public contract block and validate named proof lanes, while leaving the rest of the narrative editable.

**Evidence:**
- `guides/workflows.md` contains `workflow-semantics-contract` markers.
- `test/oban_powertools/docs_contract_test.exs` asserts the exact block and named proof lanes.

**Planning takeaway:** Phase 23 docs closure should extend marker and wording checks narrowly, not introduce snapshot-heavy prose locking.

### Bounded public telemetry contract

**Pattern:** One public workflow telemetry family with event-specific low-cardinality metadata, validated by a contract test.

**Evidence:**
- `lib/oban_powertools/telemetry.ex`
- `test/oban_powertools/telemetry_test.exs`

**Planning takeaway:** Audit event naming and metadata against workflow semantics, but preserve the current contract shape unless a concrete proof/doc gap requires a minimal addition.

## Implementation Notes

- Use `workflow_compatibility_test.exs` for historical continuity growth.
- Use `example_host_contract_test.exs --only upgrade-proof` for the supported host lane only.
- Use `docs_contract_test.exs` and `telemetry_test.exs` as merge-blocking support-truth guards.
- Prefer grep-backed plan verification for CI lane names, exact docs block text, and telemetry contract keys where it makes the contract more explicit.
