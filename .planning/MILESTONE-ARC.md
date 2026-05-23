# Milestone Arc

## Arc Intent

Oban Powertools should compound from a shipped v1 foundation into a host-friendly, operator-grade platform for serious async business flows. The arc favors prerequisite work that reduces surprise, hardens the host contract, and makes later orchestration/ops features cheaper to ship and safer to adopt.

## Default Decision Rule

- Prefer the highest-priority candidate below by default.
- Shift prerequisite, package-boundary, support-truth, and DX hardening left unless a later milestone unlock is materially more important.
- Only treat a pivot away from the default ordering as a user-confirmation event when it would meaningfully change public contracts or delay a major unlock.

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

## Active Milestone

### v1.2 Workflow Semantics & Recovery

- **Status:** active
- **Why now:** the host contract is now stable enough to support the next major capability milestone, which upgrades workflows from durable primitives into a stronger orchestration substrate.
- **Unlocks:** callback/recovery semantics, stuck-graph diagnosis, signal/await behavior, cancellation and expiry contracts, and repair-safe workflow state transitions.
- **Non-goals:** broad control-plane unification before workflow semantics settle, generic Oban Web replacement, ecosystem-specific integrations, mobile/operator companion surfaces.
- **Activated:** 2026-05-23 via `$gsd-new-milestone`

## Candidate Milestones

### v1.3 Unified Control Plane & Explainability

- **Status:** candidate
- **Priority:** high
- **Why now:** once workflow semantics are stronger, unify cron, limits, workflows, queues, and Lifeline under one action/audit/explainability model.
- **Includes:** shared operator vocabulary, common blocked/waiting/orphaned diagnostics, unified action policy, shared search/filter mental model.
- **Pros:** reduces fragmentation; makes every later operator/API surface cheaper.
- **Tradeoffs:** lower standalone glamour; can drift into abstract cleanup if not tied to concrete flows.

### v1.4 Operator Forensics & SRE Runbooks

- **Status:** candidate
- **Priority:** medium-high
- **Why now:** after semantics and control-plane contracts settle, deepen incident timelines, limiter history, missed-fire views, repair evidence, and runbook-guided remediation.
- **Includes:** richer diagnostics, evidence bundles, alert/runbook hooks, operator-grade investigative UX.
- **Pros:** boosts trust and day-2 operability.
- **Tradeoffs:** less leverage if underlying states are still moving.

### v1.5 Automation Surfaces & Ecosystem Hooks

- **Status:** candidate
- **Priority:** medium
- **Why now:** expose machine-facing and ecosystem-facing surfaces only after the core contracts stop moving.
- **Includes:** CLI/API surfaces, deeper Parapet/Threadline/Scoria hooks, automation-oriented admin actions.
- **Pros:** ecosystem leverage; stronger integration story.
- **Tradeoffs:** freezes contracts; easy place for scope sprawl.

## Research Notes That Shape The Arc

- Sidekiq and BullMQ reinforce that hidden limiter/backpressure behavior creates operator surprise.
- Celery reinforces that payload-composed workflows and topology-dependent semantics are support traps.
- GoodJob reinforces that Postgres-native elegance still requires deliberate retention, overlap, and contention discipline.
- Oban Web reinforces that embedded Phoenix-native ops UX is table stakes, but generic dashboard rebuilds are lower leverage than Powertools-specific surfaces.

## Pull-Forward Rules

- Pull v1.2 forward only if workflow semantics are the immediate product bottleneck and host-contract churn is acceptable.
- Pull v1.4 forward only if real operator debugging pain exceeds new runtime capability demand.
- Pull v1.5 forward only after the public host contract and control-plane vocabulary feel stable.

## Deferred / Not Planned Yet

- Non-Postgres backends
- Per-worker ad hoc limiter semantics
- Full native replacement for all Oban Web generic screens
- Mobile companion/operator surfaces
- Broad cloud/provider integrations
