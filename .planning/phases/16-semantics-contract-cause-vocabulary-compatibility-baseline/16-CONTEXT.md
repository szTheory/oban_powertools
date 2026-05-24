# Phase 16: Semantics Contract, Cause Vocabulary & Compatibility Baseline

## Goal

Freeze one explicit workflow and step lifecycle contract before broader v1.2 runtime behavior lands.

This phase should define the durable state vocabulary, legal transition matrix, and pre-v1.2 compatibility posture that later phases depend on. The objective is to remove ambiguity about what workflow state means before expanding recovery, callbacks, awaits, or diagnosis surfaces.

## Owns

- `WFS-01`
- `WFS-03`

## Why This Phase Exists

v1 already proved durable workflow persistence, coordinator signaling, and native inspection UI, but the semantics are still too implicit for stronger recovery and diagnosis work. v1.2 needs one stable contract for:

- workflow and step terminal causes
- request-versus-outcome interpretation
- legal transitions that runtime and operators may invoke
- in-flight compatibility when pre-v1.2 rows are reconciled under the new contract

Without this phase, later recovery and signal behavior would harden against moving targets.

## Inputs

- `.planning/PROJECT.md` — active milestone framing for v1.2
- `.planning/REQUIREMENTS.md` — v1.2 requirements and proof posture
- `.planning/milestones/v1.2-ROADMAP.md` — active milestone sequence
- `lib/oban_powertools/workflow.ex`
- `lib/oban_powertools/workflow/runtime.ex`
- `lib/oban_powertools/workflow/workflow.ex`
- `lib/oban_powertools/workflow/step.ex`
- `lib/oban_powertools/workflow/coordinator.ex`
- `lib/oban_powertools/web/workflows_live.ex`
- `lib/oban_powertools/lifeline.ex`
- `test/oban_powertools/workflow_runtime_test.exs`
- `test/oban_powertools/workflow_coordinator_test.exs`

## Phase Questions To Resolve

1. What is the exact workflow lifecycle vocabulary for available, running, blocked, waiting, cancel-requested, completed, failed, cancelled, expired, and recovered states?
2. Which terminal causes belong on workflows versus steps, and which are interpretation-only versus persisted?
3. What transition matrix is legal for runtime actions versus operator actions?
4. How should pre-v1.2 in-flight rows be versioned, upgraded, or reconciled without silently changing meaning?
5. Which current PubSub/coordinator behaviors remain hints versus truth-bearing state transitions?

## Constraints

- Keep Postgres/Ecto as the durable truth source.
- Preserve low-cardinality telemetry semantics; high-cardinality evidence belongs in durable rows.
- Do not expand the optional `oban_web` bridge contract in this phase.
- Prefer additive compatibility shims over reinterpretation of historical rows.

## Locked Decisions

- Persist semantics versioning on workflow rows rather than inferring semantics from deploy date or code version.
- Persist terminal-cause fields on both workflows and steps so diagnosis and support-truth do not depend on result-table interpretation alone.
- Treat runtime reconciliation as DB-first; coordinator and PubSub behavior may remain latency hints but not correctness-bearing state.
- Keep workflow lifecycle semantics explicit in repo-local code and docs before broadening operator mutation surfaces.
- Use additive compatibility for pre-v1.2 rows: historical workflows may reconcile under a compatibility path, but v1.2 must not silently rewrite their meaning.

## Recommended Default Answers

- **Lifecycle storage:** durable fields on `oban_powertools_workflows` and `oban_powertools_workflow_steps` carry semantics version, terminal cause, cancel timing, and last transition timing.
- **Truth source:** Postgres rows are authoritative; in-memory signals and broadcasts are advisory only.
- **Compatibility stance:** new rows default to semantics version `2`; historical rows require an explicit compatibility policy rather than implicit reinterpretation.
- **Operator safety stance:** runtime and operator actions should share the same legal transition matrix and audit vocabulary.
- **Diagnosis stance:** blocked/waiting state explanation should be derived from durable cause and blocker evidence, not guessed from UI state.

## Expected Deliverables

- One explicit workflow/step lifecycle contract.
- Durable cause vocabulary for terminal and blocked/waiting states.
- Semantics versioning and compatibility strategy for historical rows.
- A documented legal transition matrix used by runtime, UI, and docs.

## Ready-For-Plan Signal

This phase is ready for discussion and planning once the lifecycle vocabulary, compatibility policy, and legal transition scope are specific enough to break into concrete implementation slices.

## Deferred Ideas

- Rich preview/simulation UX for every workflow recovery mutation belongs to a later follow-on once the semantics contract is stable.
- Cross-product control-plane unification across cron, limits, workflows, queues, and Lifeline remains a later milestone concern, not a Phase 16 responsibility.
