# Phase 17: DB-First Transition Engine & Command Pipeline - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/workflow.ex` | public API | request-response | `lib/oban_powertools/workflow.ex` | exact |
| `lib/oban_powertools/workflow/runtime.ex` | service / semantics shell | request-response | `lib/oban_powertools/workflow/runtime.ex` | exact |
| `lib/oban_powertools/workflow/workflow.ex` | schema | CRUD | `lib/oban_powertools/workflow/workflow.ex` | exact |
| `lib/oban_powertools/workflow/step.ex` | schema | CRUD | `lib/oban_powertools/workflow/step.ex` | exact |
| `lib/oban_powertools/workflow/recovery_attempt.ex` | evidence schema | append-only | `lib/oban_powertools/workflow/recovery_attempt.ex` | exact |
| `lib/oban_powertools/workflow/await.ex` | evidence schema | append/update | `lib/oban_powertools/workflow/await.ex` | exact |
| `lib/oban_powertools/workflow/signal_record.ex` | evidence schema | append/update | `lib/oban_powertools/workflow/signal_record.ex` | exact |
| `lib/oban_powertools/lifeline.ex` | operator service | preview -> execute | `lib/oban_powertools/lifeline.ex` | exact |
| `lib/oban_powertools/web/workflows_live.ex` | read-only operator UI | request-response | `lib/oban_powertools/web/workflows_live.ex` | exact |
| `lib/oban_powertools/explain.ex` | diagnosis read model | request-response | `lib/oban_powertools/explain.ex` + runtime diagnosis helpers | strong |
| `lib/mix/tasks/oban_powertools.install.ex` | installer / contract generator | static | `lib/mix/tasks/oban_powertools.install.ex` | exact |
| `test/support/migrations/3_phase_4_tables.exs` | repo test migration harness | static | `test/support/migrations/3_phase_4_tables.exs` | exact |
| `examples/phoenix_host/priv/repo/migrations/*.exs` | public host fixture migrations | static | existing workflow migration files | exact |
| `test/oban_powertools/workflow_runtime_test.exs` | runtime proof | request-response | `test/oban_powertools/workflow_runtime_test.exs` | exact |
| `test/oban_powertools/lifeline_test.exs` | operator repair proof | preview -> execute | `test/oban_powertools/lifeline_test.exs` | exact |

## Pattern Assignments

### `lib/oban_powertools/workflow.ex`

**Strongest analogs**
- Current public verbs are thin wrappers over `Workflow.Runtime`.
- The module already acts like a Phoenix context entrypoint, not a framework DSL.

**Apply this**
- Preserve the public helper posture and route verbs into one new internal legality surface.
- Add new public helpers only where the roadmap already implies an explicit paved-road mutation verb.
- Keep raw planner structs and transaction details internal.

### `lib/oban_powertools/workflow/runtime.ex`

**Strongest analogs**
- Current runtime functions already prove the desired DB-first ordering: write facts, update rows, reconcile, refresh, emit audit/telemetry, and only then treat PubSub as a hint.
- `reconcile_workflow/3`, `workflow_diagnosis/2`, and `step_diagnosis/1` are the natural read-model seam for a command core.

**Apply this**
- Extract command legality and mutation-attempt persistence from the ad hoc verb functions instead of rewriting reconciliation from scratch.
- Keep reconciliation authoritative over persisted rows rather than inventing an in-memory orchestrator.
- Reuse current terminal-cause and diagnosis helpers as the first version of the legal-transition vocabulary.

### Workflow schemas (`workflow.ex`, `step.ex`, `await.ex`, `signal_record.ex`, `recovery_attempt.ex`)

**Strongest analogs**
- The repo already uses append-only or durable evidence tables for signals, awaits, recovery attempts, callbacks, previews, and audits.
- `RecoveryAttempt` is the closest schema analog for a durable command-attempt or command-rejection ledger.

**Apply this**
- Model new rejection evidence as a narrow durable table or schema adjacent to existing workflow evidence records.
- Keep row shapes queryable and low-ceremony: action, scope, status, reason code, before/after snapshots, actor/system source, and timestamps.
- Prefer additive schema changes over repurposing `Audit` or overloading `RecoveryAttempt` with rejected non-recovery actions.

### `lib/oban_powertools/lifeline.ex`

**Strongest analogs**
- `preview_repair/4` and `execute_repair/5` already embody the desired operator boundary: preview, drift check, single-use execution, and durable audit evidence.
- Workflow-step repairs already route through runtime helpers instead of editing rows directly.

**Apply this**
- Reuse Lifeline's preview/execute discipline when widening workflow-level actions.
- Keep policy, reason, and audit handling in Lifeline while delegating mutation legality to the shared workflow command core.
- Do not let Lifeline become a second workflow semantics engine.

### `lib/oban_powertools/web/workflows_live.ex`

**Strongest analogs**
- The page is already read-only, diagnosis-first, and uses shared display-policy seams.
- Existing wording explicitly says native pages own preview, reason, and audited mutations.

**Apply this**
- Keep the page read-only in Phase 17.
- Expand it only enough to surface the converged diagnosis and rejection vocabulary plus links to bounded operator actions where appropriate.
- Avoid embedding mutation execution logic directly in the LiveView.

### `lib/oban_powertools/explain.ex`

**Strongest analogs**
- Existing blocker snapshots and runtime diagnosis helpers already establish a durable-cause read-model pattern.

**Apply this**
- If diagnosis vocabulary needs a shared home, prefer extending existing explain/read-model helpers instead of duplicating classification logic in Lifeline and LiveView.
- Keep diagnosis derivation based on persisted workflow evidence, not PubSub state.

### Installer and migration surfaces

**Strongest analogs**
- `Mix.Tasks.ObanPowertools.Install` is already the public schema generator contract.
- Example-host and test-support migrations are kept in sync with that contract.

**Apply this**
- Land any new workflow evidence tables or fields in the installer and both fixture migration sets in the same slice as the runtime core.
- Preserve timestamp ordering and migration naming conventions already used for workflow tables.
- Avoid hiding schema changes behind repo-local tests only.

### Tests

**Strongest analogs**
- `workflow_runtime_test.exs` already covers cancellation races, signal timing, expiry, callback durability, and lifecycle contract exposure.
- `workflow_coordinator_test.exs` already proves PubSub is advisory.
- `lifeline_test.exs` already proves preview safety and bounded workflow-step repairs.

**Apply this**
- Extend these exact focused tests for legal / illegal command attempts and caller parity.
- Add compatibility coverage in the same ExUnit style rather than large fixture orchestration.
- Keep verification close to durable facts: row state, evidence rows, diagnosis values, and returned error reasons.

## Shared Patterns

- **Postgres rows first, projections second:** runtime truth already lives in workflow/step/await/signal/result rows before any PubSub or UI follow-up.
- **Append durable evidence for operator-significant actions:** audit, repair previews, recovery attempts, signals, awaits, and callbacks all follow this repo norm.
- **Thin public contexts over internal transaction work:** `Workflow`, `Lifeline`, and `Cron` all follow a Phoenix-context style rather than exposing low-level workflow machinery.
- **Focused proof files over opaque integration layers:** workflow and operator behavior is mostly verified in targeted ExUnit files.

## Anti-Patterns

- Do not create a second mutation entrypoint family that bypasses `Workflow.*` or the command core.
- Do not encode rejection truth only in error tuples or only in audit rows.
- Do not let workflow UI or Lifeline define separate diagnosis vocabularies.
- Do not add migration changes to only one of installer, example host, or test-support harnesses.
- Do not solve compatibility by implicitly upgrading legacy rows in place during ordinary commands.

## Metadata

**Analog search scope:** `lib/oban_powertools/**/*.ex`, `test/oban_powertools/**/*.exs`, `test/support/migrations/*.exs`, `examples/phoenix_host/priv/repo/migrations/*.exs`  
**Files scanned:** 21  
**Pattern extraction date:** 2026-05-23
