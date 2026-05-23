# Domain Pitfalls

**Domain:** Workflow semantics, recovery, and operator diagnosis for a Postgres-native orchestration layer
**Researched:** 2026-05-23

## Critical Pitfalls

Mistakes here usually create durable-truth drift, stranded workflows, or support incidents that require manual data repair.

### Pitfall 1: Treating PubSub Signals as Workflow Truth
**What goes wrong:** Completion, unblock, or recovery semantics are implemented as best-effort broadcasts, and the database is treated as an eventually updated mirror rather than the authoritative transition log.
**Why it happens:** Fast progression feels like a signaling problem, and the current coordinator already uses PubSub as a hint path.
**Consequences:** Lost broadcasts, duplicate deliveries, or subscriber restarts create contradictory views between workflow rows, step rows, and operator screens. Support can no longer tell whether a graph is actually blocked or only visually stale.
**Warning signs:** Re-running reconciliation changes state after “nothing happened”; operators report workflows that “fixed themselves” after refresh; duplicated unblocked events without duplicated durable transitions.
**Operator/support risk:** High. Read-only workflow pages stop being support-truth surfaces and become advisory UI.
**Prevention:** Keep every semantic transition DB-first and idempotent. Signals should only request reconciliation, never define state. Require a reconciliation pass that can rebuild correct workflow state from rows alone after node loss or dropped messages.
**Roadmap phase:** Phase 2: Runtime callbacks and recovery transitions.

### Pitfall 2: State Vocabulary Drift Between Job, Step, and Workflow Layers
**What goes wrong:** `cancelled`, `retryable`, `discarded`, `expired`, `waiting`, `orphaned`, and `blocked` are used loosely across jobs, workflow steps, repair actions, and UI copy.
**Why it happens:** Oban job states already exist, and it is tempting to project them directly onto workflow semantics without defining workflow-specific causality.
**Consequences:** A support engineer cannot answer basic questions such as “Was this cancelled by an operator, by expiry, by dependency failure, or by executor death?” Repair actions become unsafe because the same label hides different causes.
**Warning signs:** One status badge maps to multiple repair paths; audit events need free-text interpretation to explain lifecycle; docs say “cancelled” while runtime rows require reading payload details to know why.
**Operator/support risk:** High. This breaks the v1.1 support-truth promise because user-facing language no longer matches durable evidence.
**Prevention:** Freeze a cause-oriented vocabulary before adding new mutations. Persist explicit cause fields or blocker codes for manual cancel, dependency cancel, deadline expiry, orphaned executor, waiting on signal, and missing result. Make UI copy render those exact causes instead of inferring from state alone.
**Roadmap phase:** Phase 1: Semantics contract and vocabulary.

### Pitfall 3: Assuming `after_process`-Style Hooks Cover Recovery Semantics
**What goes wrong:** Cleanup, callbacks, or side effects are wired only to normal execution hooks, but workflow cancellation, deadline expiry, dependency cancellation, and rescue-based discard happen outside the worker process.
**Why it happens:** Worker authors naturally attach behavior to the success/failure path they already know.
**Consequences:** Notifications, compensations, and audit records silently fail to run for the transitions operators care about most. Recovery looks correct in tables but downstream systems never hear about it.
**Warning signs:** Manual cancellation updates DB state but no callback fires; dependency-cancelled steps have no cleanup side effects; support sees terminal state without corresponding external notification.
**Operator/support risk:** High. Incident responders will trust a callback contract that is not actually triggered by operator actions or runtime recovery.
**Prevention:** Separate execution callbacks from external-state callbacks. Define first-class semantics for manual cancel, dependency cancel, deadline expiry, and discard exhaustion, and test each path independently. Do not document callback guarantees until external transitions are covered.
**Roadmap phase:** Phase 2: Runtime callbacks and recovery transitions.

### Pitfall 4: Infinite Waits and Unkeyed Signals
**What goes wrong:** `await` semantics are added without persisted deadlines, correlation IDs, or deduplication rules for signals.
**Why it happens:** Waiting feels conceptually simple, and the happy path is easy to demo with one approval signal.
**Consequences:** Workflows wait forever, late signals resurrect expired intent, duplicate signals apply twice, and operators cannot distinguish “still legitimately waiting” from “nobody will ever answer this.”
**Warning signs:** Waiting steps have no expiry timestamp; support needs raw payload inspection to know which signal was expected; duplicate callbacks after retries or restarts; no way to explain whether a signal arrived before or after expiry.
**Operator/support risk:** High. Human-in-the-loop flows become the largest source of stuck-graph tickets.
**Prevention:** Persist a wait contract on first suspension: signal name, correlation key, deadline, dedupe key, and resolution policy for late arrivals. Make timeout a first-class terminal or recoverable cause, not an inferred absence of progress. Build duplicate-signal fixtures before shipping.
**Roadmap phase:** Phase 3: Signal/await, cancellation, and expiry contracts.

### Pitfall 5: Believing Cancellation Is Immediate and Final
**What goes wrong:** Product semantics promise that cancelling a workflow or step instantly stops all related work and prevents further state changes.
**Why it happens:** Operator UX naturally wants a clean “Cancel” button with a clean success story.
**Consequences:** Executing jobs may still finish successfully, termination may be queued, downstream activities may continue, and late completions can race with cancellation bookkeeping. The result is support confusion and unsafe compensations.
**Warning signs:** A cancelled workflow still records successful child completion; operators see “cancel requested” and “completed” in adjacent evidence; manual cancel tests pass only for scheduled or available jobs, not executing ones.
**Operator/support risk:** High. Incorrect cancellation promises create escalations because operators think the system violated its own contract.
**Prevention:** Distinguish `cancel_requested`, `cancelled`, and `completed_after_cancel_request` semantics where needed. Document exactly which states can still advance after cancellation is requested. Audit the reason and timing of the request separately from durable final outcome.
**Roadmap phase:** Phase 3: Signal/await, cancellation, and expiry contracts.

### Pitfall 6: Time-Based “Stuck” Diagnosis Without Causality
**What goes wrong:** A workflow is classified as stuck because it has been pending or executing for “too long,” without checking dependency state, signal waits, retries, missing results, or executor liveness.
**Why it happens:** Time thresholds are easy to implement and look operationally useful.
**Consequences:** Healthy long waits get flagged as incidents, while true semantic deadlocks or orphaned graphs are missed. Repair actions then make the system less correct.
**Warning signs:** One “stuck” bucket mixes waiting-for-signal, retry-backoff, orphaned executor, missing dependency result, and deleted-upstream cases; support playbooks start with elapsed minutes instead of blockers and evidence.
**Operator/support risk:** High. False positives train operators to ignore the workflow screen; false negatives leave real incidents unaddressed.
**Prevention:** Diagnose by cause class, not age alone. Separate `waiting_on_signal`, `waiting_on_retryable_dependency`, `orphaned_executor`, `missing_dependency_result`, `cancelled_by_dependency`, and `expired_wait`. Use age only as an escalation dimension after semantic classification.
**Roadmap phase:** Phase 4: Stuck-graph diagnosis and operator surfaces.

### Pitfall 7: Shipping Breaking Semantic Changes Into In-Flight Workflows
**What goes wrong:** Step meanings, callback payloads, result shapes, blocker codes, or wait/cancel sequencing change while workflows created under the old contract are still running.
**Why it happens:** The milestone feels internal, so semantic changes are treated like normal refactors.
**Consequences:** Replayed or resumed flows deserialize old durable data into new assumptions, stuck-graph diagnosis becomes inconsistent across cohorts, and support can no longer reason from stored rows without knowing deployment date.
**Warning signs:** Migration notes mention “rename status,” “insert extra callback stage,” or “change result payload shape” without an in-flight compatibility story; tests recreate only fresh workflows, never pre-upgrade ones.
**Operator/support risk:** High. The same graph state means different things before and after deployment.
**Prevention:** Version workflow semantics explicitly. Preserve readers for old blocker/result formats, or isolate new behavior behind a persisted definition/version field. Add upgrade fixtures for workflows already waiting, retrying, and cancelling at deploy time.
**Roadmap phase:** Phase 1: Semantics contract and vocabulary.

## Moderate Pitfalls

### Pitfall 8: Missing Deleted-Upstream and Missing-Result Recovery Paths
**What goes wrong:** A child step waits forever because an upstream job was pruned, manually deleted, or marked complete without a durable result payload.
**Why it happens:** DAG logic is tested against success, retry, and failure, but not against data-retention or partial-write scenarios.
**Consequences:** Graphs look blocked with no obvious repair path, and operators reach for direct SQL changes.
**Warning signs:** Blocker explanations stop at “waiting on dependency” even when the dependency row or result row is gone; repair tooling has no branch for deleted or resultless parents.
**Operator/support risk:** Medium-high. This becomes a recurring “why is this graph impossible to finish?” ticket.
**Prevention:** Treat deleted-upstream and missing-result as explicit blocker classes with documented operator actions. Retain enough result metadata for diagnosis even when payloads are pruned or redacted.
**Roadmap phase:** Phase 4: Stuck-graph diagnosis and operator surfaces.

### Pitfall 9: Dynamic Graph Mutation Without Dependency Revalidation
**What goes wrong:** Recovery features append or rewire work after insertion but do not prove that referenced dependencies still exist and are semantically compatible.
**Why it happens:** Late-binding new work is useful for recovery and callbacks, and it is tempting to skip expensive checks.
**Consequences:** Incomplete graphs are created that can never be satisfied, or newly appended cleanup work binds to stale assumptions about upstream outputs.
**Warning signs:** Recovery code has a “skip dependency checks” path; appended steps reference names or outputs not guaranteed in the persisted graph version; tests assert insertion succeeded, not that the new graph can finish.
**Operator/support risk:** Medium-high. These failures look like product bugs, not operator mistakes.
**Prevention:** Revalidate dependency existence and contract compatibility whenever recovery appends new work. If you allow unsafe append modes internally, keep them out of operator-facing actions and mark resulting workflows as tainted or unsupported.
**Roadmap phase:** Phase 2: Runtime callbacks and recovery transitions.

### Pitfall 10: Expiry That Isn’t Owned by Any Single Durable Contract
**What goes wrong:** Deadline expiry is partially enforced by worker code, partially by recovery jobs, and partially by UI assumptions, with no single row proving which clock won.
**Why it happens:** There are multiple natural places to add timeout logic: `await`, job deadlines, repair flows, and cron-like sweepers.
**Consequences:** Late signals race expiry sweepers, the same wait may “timeout” twice, and support cannot tell whether an operator can still resume or must restart.
**Warning signs:** Expiry timestamps exist in socket state or computed UI labels but not in durable workflow rows; manual retry can revive an already expired wait without explicit override.
**Operator/support risk:** Medium-high. Expiry bugs are subtle and disproportionately expensive to support.
**Prevention:** Choose one durable authority for wait expiry and one reconciliation path that finalizes it. Persist when expiry was first observed, by which subsystem, and whether late signals are ignored, attached as evidence, or allowed to reopen.
**Roadmap phase:** Phase 3: Signal/await, cancellation, and expiry contracts.

### Pitfall 11: Read-Only Diagnosis Screens That Require Tribal Knowledge
**What goes wrong:** The workflow screen is technically read-only and auditable, but diagnosis still requires support engineers to know internal joins, timing quirks, or repair scripts.
**Why it happens:** Teams stop after rendering blocker codes and assume that satisfies explainability.
**Consequences:** Operators escalate benign cases, developers answer tickets by reading the database directly, and the native surface stops being the promised support boundary.
**Warning signs:** “Blocked” is shown without next action; orphaned and waiting states require checking Oban Web, audit rows, and workflow rows manually; support docs say “ask engineering to inspect.”
**Operator/support risk:** Medium-high. The system remains durable but not operable.
**Prevention:** Every diagnosis state needs three things on-screen: cause, evidence, and allowed next action. Keep mutation authority on native pages, but ensure the read-only workflow screen explains whether the correct next stop is Oban Web, Lifeline, or no action.
**Roadmap phase:** Phase 4: Stuck-graph diagnosis and operator surfaces.

## Minor Pitfalls

### Pitfall 12: High-Cardinality and Sensitive Recovery Evidence in Telemetry
**What goes wrong:** Signal payloads, callback reasons, workflow names, or operator-entered explanations leak into telemetry labels or broad logs.
**Why it happens:** Recovery semantics add rich context, and engineers want it visible everywhere.
**Consequences:** Cardinality spikes, privacy risk increases, and the public telemetry contract becomes impossible to support.
**Warning signs:** Metrics tagged with workflow IDs, signal names derived from user input, or free-form operator reasons; dashboards only useful when filtered by unique identifiers.
**Operator/support risk:** Medium. This degrades observability and violates the public telemetry boundary.
**Prevention:** Keep metric labels low-cardinality and move rich evidence into durable tables already covered by display policy and audit rules. Redaction must be shared across workflow results, signal payloads, and operator-entered reasons.
**Roadmap phase:** Phase 5: Support-truth, telemetry, and verification.

### Pitfall 13: No Test Fixtures for Duplicate, Late, or Missing Events
**What goes wrong:** The suite covers nominal completion but not duplicate signals, dropped coordinator notifications, cancel-vs-complete races, post-expiry signals, or upgrade-era in-flight graphs.
**Why it happens:** These cases are tedious to model and rarely appear in local development.
**Consequences:** Semantics look correct until the first production incident, where support discovers which cases were undefined.
**Warning signs:** Tests call completion once, signal once, and cancel once; no fixtures begin from persisted rows in intermediate states.
**Operator/support risk:** Medium. Support becomes the real integration test harness.
**Prevention:** Build explicit fixtures for duplicate delivery, missing PubSub follow-up, late signal after expiry, manual cancel during execution, deleted upstream dependency, and pre-upgrade in-flight workflows.
**Roadmap phase:** Phase 5: Support-truth, telemetry, and verification.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Phase 1: Semantics contract and vocabulary | State labels collapse cause and outcome into one field. | Freeze a cause taxonomy and versioned durable contract before adding new runtime behaviors. |
| Phase 2: Runtime callbacks and recovery transitions | PubSub or normal execution hooks become the accidental truth source. | Make transitions DB-first, idempotent, and externally replayable from rows alone. |
| Phase 3: Signal/await, cancellation, and expiry contracts | Waiting and cancellation semantics are underspecified around duplicates, late arrivals, and executing work. | Persist wait/cancel contracts with deadlines, correlation keys, dedupe rules, and late-arrival policy. |
| Phase 4: Stuck-graph diagnosis and operator surfaces | “Stuck” becomes an age bucket instead of a causal explanation. | Classify blocked graphs by semantic cause and show allowed operator actions next to evidence. |
| Phase 5: Support-truth, telemetry, and verification | Public docs and tests over-promise callback, cancel, or diagnosis behavior. | Tie every public claim to a durable artifact and add failure-path fixtures before widening docs. |

## Sources

- Internal context: [.planning/PROJECT.md](/Users/jon/projects/oban_powertools/.planning/PROJECT.md), [.planning/MILESTONE-ARC.md](/Users/jon/projects/oban_powertools/.planning/MILESTONE-ARC.md), [lib/oban_powertools/workflow/runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex), [lib/oban_powertools/workflow/coordinator.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/coordinator.ex), [lib/oban_powertools/web/workflows_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/workflows_live.ex)
- Oban job lifecycle: https://hexdocs.pm/oban/job_lifecycle.html
- Oban troubleshooting: https://hexdocs.pm/oban/troubleshooting.html
- Oban cancellation semantics: https://hexdocs.pm/oban/Oban.html#cancel_job/2
- Oban Pro worker hooks, external cancellation/discard hooks, and `await_signal/1`: https://oban.pro/docs/pro/Oban.Pro.Worker.html
- Oban Pro workflow dependency handling, stuck-workflow warning, append dependency checks, and cancellation callbacks: https://oban.pro/docs/pro/Oban.Pro.Workflow.html
- Durable Functions external events and duplicate-delivery guidance: https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-external-events
- Durable Task instance termination semantics: https://learn.microsoft.com/en-us/azure/durable-task/common/durable-task-instance-management
- Durable Task / Durable Functions determinism constraints: https://learn.microsoft.com/en-us/azure/durable-task/common/durable-task-code-constraints
- Durable Functions versioning and in-flight orchestration breaking changes: https://learn.microsoft.com/en-us/azure/azure-functions/durable-functions/durable-functions-versioning
