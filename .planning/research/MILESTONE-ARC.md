# Milestone Arc

## Arc Intent

Oban Powertools should compound from a shipped v1 foundation into a host-friendly, operator-grade platform for serious async business flows. The arc favors prerequisite work that reduces surprise, hardens the host contract, and makes later orchestration/ops features cheaper to ship and safer to adopt.

## Default Decision Rule

- Treat candidates below as hypotheses and re-rank them at each milestone boundary using current adopter evidence, repo state, expected value, cost, and risk.
- Prefer a bounded, coherent adopter outcome; do not convert a broad quality checklist into work without concrete success criteria.
- Shift prerequisite, package-boundary, support-truth, and DX hardening left when evidence shows they block adoption or safe operation.
- Resolve routine choices from repo evidence and established decisions. Escalate only material changes to public contracts, operator trust, or maintainer burden.

## Arc Principles

- Host-owned over magical: the host app owns repo, router, auth, supervision, and config.
- Explicit over implicit: blocked state, repair state, and operator mutations must stay inspectable.
- Postgres/Ecto-native over split control planes.
- Bridge-first UI: extend Oban Web where it helps, do not rebuild commodity job UI before Powertools-specific value.
- Telemetry is a public API; high-cardinality evidence belongs in durable tables.
- Explain, then act: preview/reason/audit flows before broadening mutations.

## Recently Shipped

### v1.1 Host Contract & Adoption Hardening

- **Status:** shipped 2026-05-23
- **Why it shipped:** the repo now proves the host-owned install path, native-first operator session, optional dependency boundaries, repaired cross-phase evidence chain, and supported archived-host upgrade lane end to end.
- **Unlocked:** safer host adoption, trustworthy support-truth docs, stable extension seams, and lower churn for later workflow/control-plane milestones.

### v1.2 Workflow Semantics & Recovery

- **Status:** shipped 2026-05-25
- **Why it shipped:** the repo now proves the workflow semantics contract end to end, including DB-first command legality, durable callback and recovery evidence, await/signal/expiry authority, diagnosis-first workflow and Lifeline surfaces, and bounded public support-truth claims.
- **Unlocked:** a stable workflow substrate for cross-surface operator vocabulary, shared explainability, and later control-plane unification work.

### v1.3 Unified Control Plane & Explainability

- **Status:** shipped 2026-05-26
- **Why it shipped:** the repo now proves one shared control-plane vocabulary, a diagnosis-first `/ops/jobs` overview, continuity-safe native and bridge handoffs, unified bounded-action posture, and support-truthful docs plus example-host proof for the native-shell versus bridge-only contract.
- **Unlocked:** a stable operator language and navigation model that makes deeper forensics, runbooks, and later automation surfaces cheaper to design honestly.

## Candidate Milestones

No milestone is active after v2.0. The following candidates remain provisional and must be re-evaluated from current evidence:

Candidate IDs and boundaries are carried forward from the v2.0 project backlog; their presence here is not evidence of current adopter demand.

### Near-term candidate: Native Job Workflow Polish

- **Candidate requirements:** QRY-05 (args/meta filtering), QRY-07 (Lifeline-to-job deep link), QRY-08 (cross-page selection), API-03 (`Operator.list/2`).
- **Entry condition:** adopter evidence identifies a coherent job investigation or automation workflow that these items materially improve.
- **Guardrail:** keep the scope bounded to Powertools-specific value; do not recreate generic Oban Web functionality.

### Near-term candidate: Optional Observability / Live Counts

- **Candidate requirement:** QRY-06, using `oban_met` only as an optional read source if current ecosystem and adopter evidence still support it.
- **Entry condition:** users need the missing counts in Powertools' diagnosis workflow, and the integration remains optional with honest unavailable/support states.
- **Guardrail:** no hard `oban_met` dependency and no generic metrics dashboard.

### Mid-term research lane: Reliability and Adoption Quality

- Consider targeted performance, resilience, property/model-based testing, CI efficiency, install/upgrade proof, and documentation improvements when a concrete gap is found.
- Require each proposal to name the risk it addresses and the evidence that makes it more valuable than feature work.

### Long-term research lane: Capabilities and Ecosystem Integrations

- Revisit new runtime capabilities and integrations only when adoption demonstrates unmet need and the proposal preserves host ownership, Postgres/Ecto fit, and support truth.
- Keep speculative items deferred; do not assign dates or release versions before the evidence review.

## Maintainer UI Review Readiness Gate

v2.0 implemented and automated quality coverage for all nine `/ops/jobs` surfaces. The maintainer has not personally tried the operator UI, so the current VRT, accessibility, responsive, copy, and route evidence does not establish owner-level product fit or workflow clarity. Treat those as separate kinds of evidence.

Before asking for focused maintainer UI feedback:

- Finish active release and published-package closeout, and triage the dependency/security review.
- Resolve or explicitly disposition all critical/high-risk correctness, security, installation, upgrade, and release gaps outside subjective UI product feedback.
- Keep required CI and documented support/install paths green from committed state; review long-running CI cost against the distinct risk it covers.
- Prepare one concise packet with the operator workflows, existing automated evidence and limits, known gaps, and a short set of product questions. Do not ask the maintainer to repeat checks the repository can run automatically.

This gate does not require every low-risk improvement or deferred candidate to be exhausted. After the focused review, use the maintainer's product feedback and any adopter signal to rank UI follow-up work. Do not schedule a UI feature milestone before that evidence exists.

## Research Notes That Shape The Arc

- Sidekiq and BullMQ reinforce that hidden limiter/backpressure behavior creates operator surprise.
- Celery reinforces that payload-composed workflows and topology-dependent semantics are support traps.
- GoodJob reinforces that Postgres-native elegance still requires deliberate retention, overlap, and contention discipline.
- Oban Web reinforces that embedded Phoenix-native ops UX is table stakes, but generic dashboard rebuilds are lower leverage than Powertools-specific surfaces.

## Pull-Forward Rules

- Re-rank candidates when new adopter reports, issues, support requests, or verified code/doc gaps materially change their value.
- Prefer reliability or adoption-quality work when it removes a demonstrated barrier or closes a high-risk correctness gap.
- If no candidate has sufficient evidence, recommend further signal gathering instead of inventing a milestone.

## Milestone Closeout Rule

Verify from committed state, keep required CI green, triage relevant PRs and findings, align docs and package claims with shipped behavior, and leave worktrees clean or explicitly accounted for. Publish a Hex release when the milestone warrants a public release; otherwise record why not and leave the release path ready.

The first owner-led product review of the operator UI is a deliberate handoff after the readiness gate above, not a substitute for automated UAT or CI evidence.

## Deferred / Not Planned Yet

- Non-Postgres backends
- Per-worker ad hoc limiter semantics
- Full native replacement for all Oban Web generic screens
- Mobile companion/operator surfaces
- Broad cloud/provider integrations
