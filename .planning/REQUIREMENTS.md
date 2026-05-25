# Requirements: Oban Powertools

**Defined:** 2026-05-23
**Milestone:** v1.2 Workflow Semantics & Recovery
**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators.

## v1.2 Requirements

## Phase 16 Baseline

- Semantics version `2` is the durable lifecycle baseline for v1.2 workflow rows.
- Workflow and step rows persist terminal cause, cancel timing, wait identity, and last-transition timing as the explainable truth source.
- Historical rows created before v1.2 remain on a compatibility path until a v2 runtime transition writes the newer durable meaning.
- Historical rows are not silently reclassified under the v1.2 contract.

### Workflow Semantics

- [x] **WFS-01**: A maintainer can rely on one explicit workflow and step lifecycle contract with durable terminal causes for `completed`, `failed`, `cancelled`, `expired`, and recovery-driven transitions.
- [x] **WFS-02**: Runtime and operator mutations can only move workflows through documented legal transitions that are recomputed from Postgres-backed truth rather than transient PubSub state.
- [x] **WFS-03**: In-flight workflows created before v1.2 can continue or reconcile under a documented semantics-compatibility strategy without silent meaning drift.

### Callbacks & Recovery

- [x] **REC-01**: A host app can receive post-commit workflow callbacks through a durable outbox so workflow completion, failure, cancellation, expiry, and recovery side effects survive crashes and retries.
- [x] **REC-02**: An operator or runtime can request scoped workflow recovery without silently re-running already successful side-effecting steps, and the new attempt evidence remains durable and auditable.
- [x] **REC-03**: Workflow cancellation is cooperative and explicit: operators can see request versus final outcome, and late step completion after a cancel request is preserved as durable evidence instead of hidden.

### Await, Signal, And Expiry

- [x] **SIG-01**: A workflow step can durably register an await contract with signal name, correlation identity, dedupe behavior, and deadline so waiting survives restarts and cross-node execution.
- [x] **SIG-02**: Incoming workflow signals are stored as durable facts and reconciled idempotently whether they arrive before, during, or after a matching wait registration.
- [x] **SIG-03**: Expiry and late-arrival policy is explicit: a maintainer can tell whether an overdue wait failed, cancelled downstream work, remained recoverable, or ignored late signals by contract.

### Diagnosis & Operator Surfaces

- [x] **DIA-01**: A workflow screen can explain durable cause classes such as `waiting_on_signal`, `waiting_on_retryable_dependency`, `missing_dependency_result`, `orphaned_executor`, `cancel_requested`, and `expired_wait` without requiring direct database inspection.
- [x] **DIA-02**: Lifeline and workflow inspection surfaces consume the same workflow diagnosis vocabulary and expose only bounded, audited recovery actions that re-enter the workflow command pipeline.

### Verification, Telemetry, And Support Truth

- [x] **VER-01**: The repo proves duplicate, late, dropped, and race-path workflow events with automated fixtures covering signal replay, cancel-versus-complete races, expiry, and lost wakeup reconciliation.
- [x] **VER-02**: A maintainer can upgrade hosts with in-flight waiting, retrying, cancelling, or recovering workflows without breaking semantics or leaving support unable to explain stored state.
- [x] **POL-04**: The public telemetry and support-truth docs describe the new workflow semantics with low-cardinality events, explicit non-goals, and no present-tense guarantees that lack durable proof.

## Capability Selection Rubric

| Capability Family | Route Owner Expectation | Bridge Frequency | Permission / Policy Sensitivity | Support-Matrix Impact | Proof Required | Package Classification |
|-------------------|-------------------------|------------------|---------------------------------|-----------------------|----------------|------------------------|
| Workflow lifecycle semantics | Core library and native operator surfaces | Low-frequency semantic | High | High | Hermetic runtime and upgrade proof | `core` |
| Durable callbacks and recovery commands | Core library | Low-frequency semantic | High | High | Hermetic runtime plus crash/retry proof | `core` |
| Await/signal and expiry contracts | Core library | Low-frequency semantic | High | High | Hermetic race and dedupe proof | `core` |
| Workflow-local diagnosis and Lifeline integration | Native operator surfaces | Native screen | High | High | Hermetic UI plus incident proof | `core` |
| Rich recovery preview differentiator | Native operator surfaces | Native screen | High | Medium | Advisory follow-on proof | `defer` |
| Cross-product control-plane unification | Shared operator platform | Defer | High | High | Out of milestone | `defer` |
| Generic callback/event bus | External integration surface | Defer | High | High | Out of milestone | `defer` |

## Packaging Ledger

| Surface | Classification | Scope Rule |
|---------|----------------|------------|
| Workflow command and semantics modules | `core` | All state transitions must route through DB-first command + semantics APIs. |
| Await, signal, callback, and recovery persistence | `core` | New durable tables and schema fields are part of the supported runtime contract. |
| Workflow LiveView and Lifeline workflow diagnosis | `core` | Native surfaces may explain and mutate only through bounded audited actions. |
| Public docs and telemetry markers | `core` | New support claims must match proof artifacts and low-cardinality telemetry boundaries. |
| Oban Web bridge changes | `defer` | Keep the optional bridge out of workflow-semantics ownership for this milestone. |
| Rich preview / simulation UX for recovery mutations | `defer` | Valuable follow-on once runtime semantics are stable. |
| Ecosystem automation or provider integrations | `defer` | Not part of v1.2. |

## Future Requirements

### Deferred From v1.2

- **REC-04**: Operators can preview exact workflow recovery mutations before commit across every recovery path.
- **CBK-01**: Host apps can configure a broader callback policy matrix beyond the narrow terminal and recovery hooks required for v1.2.
- **CTL-01**: Cron, limiters, workflows, queues, and Lifeline share one cross-product explainability and action vocabulary.
- **API-01**: Ecosystem automation surfaces expose workflow control-plane actions over CLI or API contracts.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New orchestration engine or non-Postgres control plane | Violates the existing Postgres/Ecto-native core value and adds contract churn before semantics harden. |
| Generic event bus or webhook platform | Expands v1.2 into integration-platform design before the callback contract is stable. |
| Cross-product control-plane unification | Explicitly reserved for the later v1.3 milestone in `MILESTONE-ARC.md`. |
| Broad native replacement for generic Oban Web screens | Lower leverage than workflow-specific semantics and diagnosis work. |
| Mobile or companion operator surfaces | Explicit non-goal in the active milestone arc. |

## Proof Posture Gate

| Claim Area | Merge-Blocking Hermetic Proof | Advisory Proof | Support Obligation |
|------------|-------------------------------|----------------|--------------------|
| Lifecycle vocabulary and legal transitions | Unit/integration fixtures over transition planner and runtime writes | None | Docs and UI copy must use the same durable cause vocabulary. |
| Durable callbacks and recovery commands | Callback outbox, retry, dedupe, and crash-recovery tests | Optional host callback smoke proof | Callback guarantees must stay narrow and documented. |
| Await/signal/expiry contracts | Duplicate, late, dropped, pre-await, post-expiry, and race-path fixtures | Optional multi-node notifier smoke proof | Support docs must state late-arrival and cancel precedence rules explicitly. |
| Diagnosis and operator actions | Workflow UI/Lifeline verification plus audited bounded mutation proof | Manual operator review of edge cases | Native surfaces must show cause, evidence, and allowed next action. |
| In-flight compatibility and upgrade safety | Archived/in-flight upgrade fixtures for waiting, retrying, cancelling, and recovering workflows | Maintainer-only regeneration guidance | Upgrade docs must define what is supported versus unsupported in-flight state changes. |
| Telemetry and support-truth docs | Docs-contract and telemetry-contract tests | Optional guide walkthroughs | No event or guide wording may imply unproven semantics. |

## Support Truth Gate

| Surface | Denial / Fallback Behavior | Missing Prerequisite Behavior | Native Rebuild Required | Rough-Edge Docs To Publish |
|---------|----------------------------|-------------------------------|-------------------------|----------------------------|
| Workflow callback contract | Persist callback row and retry; do not inline host side effects inside state transactions | Surface delivery failure durably and keep workflow truth committed | No | Callback scope, retries, and failure visibility |
| Await/signal contract | Keep waiting durable and explainable even if notifier wakeup is lost | Reconcile from stored waits/signals on next runtime pass | No | Signal correlation, dedupe, and late-arrival rules |
| Cancellation and expiry | Preserve `cancel_requested` or expiry evidence even when backing jobs finish late | Reconcile durable workflow truth before offering further mutation | No | Cancellation semantics and expiry precedence |
| Workflow diagnosis in native UI | Render durable cause and route operators to the bounded next action | Show unsupported/unknown state explicitly instead of guessing | No | Diagnosis vocabulary and operator action boundaries |
| In-flight compatibility | Refuse unsupported mutation paths when semantics version cannot be reconciled safely | Surface unsupported upgrade state as maintainer action required | Yes, when schema changes land | Upgrade compatibility and unsupported in-flight cases |

## Traceability

| Requirement | Owner Phase | Closure Proof | Status |
|-------------|-------------|---------------|--------|
| WFS-01 | 16 | 16-VERIFICATION.md | Complete |
| WFS-02 | 17 | 17-VERIFICATION.md | Complete |
| WFS-03 | 16 | 16-VERIFICATION.md | Complete |
| REC-01 | 18 | 18-VERIFICATION.md | Complete |
| REC-02 | 17 | 18-VERIFICATION.md | Complete |
| REC-03 | 20 | 20-VERIFICATION.md | Complete |
| SIG-01 | 19 | 19-VERIFICATION.md | Complete |
| SIG-02 | 19 | 19-VERIFICATION.md | Complete |
| SIG-03 | 19 | 19-VERIFICATION.md | Complete |
| DIA-01 | 21 | 21-VERIFICATION.md | Complete |
| DIA-02 | 22 | 22-VERIFICATION.md | Complete |
| VER-01 | 23 | 23-VERIFICATION.md | Complete |
| VER-02 | 23 | 18-VERIFICATION.md | Complete |
| POL-04 | 23 | 18-VERIFICATION.md | Complete |

**Coverage:**
- v1.2 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0

---
*Requirements defined: 2026-05-23*
*Last updated: 2026-05-25 after milestone audit gap planning created Phases 24-26*
