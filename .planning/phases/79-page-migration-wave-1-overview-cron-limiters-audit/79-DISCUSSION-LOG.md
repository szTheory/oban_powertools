# Phase 79: Page Migration Wave 1 — Overview, Cron, Limiters, Audit - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-19
**Phase:** 79-Page Migration Wave 1 — Overview, Cron, Limiters, Audit
**Areas discussed:** Overview prioritization, Cron action placement, Limiters diagnosis structure, Audit evidence density

---

## Overview Prioritization

| Option | Description | Selected |
|--------|-------------|----------|
| Equal six-card grid | Minimal visual change and all buckets stay visible, but gives current problems, bridge handoffs, healthy capacity, and history false equivalence. It also makes a representative bridge count look comparable to real totals. | |
| Dynamically ranked alert/feed list | Can place a computed “most urgent” item first, but needs ranking/freshness truth the read model does not have, causes visual/focus churn, harms muscle memory, and violates existing bounded non-feed behavior. | |
| Tabs or collapsed history | Saves vertical space, but hides continuity evidence and adds focus/interaction state without improving the primary task. | |
| Stable layered triage | Current native attention first, bridge follow-up second, routine capacity third, and resolved continuity last. Preserves stable order, bounded exemplars, ownership truth, and one responsive DOM. | ✓ |

**User's choice:** The user asked that every alternative be researched and delegated the final coherent recommendation.
**Notes:** Research across PagerDuty, PatternFly, Grafana, Kubernetes, Oban Web, Sidekiq, GoodJob, and Cloudscape supported separating current state from historical continuity and keeping operator ownership explicit. Repository inspection showed that bridge rows are representative rather than a global total and that “Resolved Recently” has no real time cutoff. The decision therefore locks `Needs Review -> Blocked -> Waiting -> Bridge-only Follow-up -> Runnable -> Resolved continuity` without adding a feed or dynamic page ranking.

---

## Cron Action Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Repeated row actions | Fast direct access, but creates a dense hazardous action column, provides too little context, repeats affordances at narrow widths, and encourages accidental action during scanning. | |
| Row overflow menu | Visually compact, but hides the core page capability behind recall, weakens discoverability/permission explanations, and still launches confirmation without first establishing full context. | |
| Selected detail as sole action venue | The table scans/selects; the URL-backed detail explains state and owns visible actions; all mutations use the shared preview/reason/confirm/result pattern. | ✓ |

**User's choice:** The user delegated the choice after ecosystem, architecture, safety, UI/UX, and DX research.
**Notes:** Oban Web's cron list/detail split, Phoenix LiveView's URL/navigation model, Ecto.Multi transaction semantics, established confirmation patterns, and the repository's existing `?entry=` selection made context-first master/detail the least surprising choice. Action-specific labels and consequences are locked. The migrated UI requires a reason for all three audited actions while preserving the public backend compatibility value. Confirmation leaves the detail surface first to prevent nested modal dialogs.

---

## Limiters Diagnosis Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Keep custom fixed two-column layout | Closest to current markup, but does not compose the shipped DataTable/DetailSurface patterns and degrades less predictably at narrow widths. | |
| Merge current, snapshot, and history into one timeline | Produces a single narrative surface, but visually implies causality and recency, conflates current truth with block-start/history evidence, and conflicts with the glossary's Forensics timeline meaning. | |
| DataTable plus adaptive diagnostic detail | Supports fast resource scanning, stable URL selection, a current blocker explanation, and progressively disclosed snapshot/history with one responsive DOM. | ✓ |

**User's choice:** The user asked for all relevant viewpoints to be considered and delegated the cohesive recommendation.
**Notes:** This area had fewer true gray choices because Phase 78 already locks `DetailSurface` and `WhyBlocked`. The decision carries those contracts forward: current blockers first, block-start snapshot explicitly historical, retained history/completeness next, and authorized runbook/Forensics/Oban Web routes last. Limiters remains read-only and does not gain a mutation or inferred root-cause model.

---

## Audit Evidence Density

| Option | Description | Selected |
|--------|-------------|----------|
| Compact table only | Best raw scan/comparison density and least behavior change, but cannot carry complete reason/source/outcome/correlation evidence without unstable rows or excessive width. | |
| Full AuditEntry timeline | Best comprehension of one record and naturally narrow, but creates severe repetition, poor cross-record comparison, a heavy unbounded DOM, and a false connected chronology for unrelated global actions. | |
| Hybrid table plus progressive detail | A bounded semantic table handles global scanning; one selected AuditEntry in the adaptive DetailSurface handles complete allowlisted evidence. | ✓ |

**User's choice:** The user delegated the final recommendation after research into successful audit/event systems and ecosystem conventions.
**Notes:** AWS CloudTrail, GitHub, GitLab, Datadog, Google Cloud, Grafana, and Oban Web all reinforced dense index/detail review, explicit filters/time/retention, and progressive evidence. Their raw payloads, qualifier grammars, facets, saved views, and observability-heavy search models were rejected for this library. Repository inspection found an unbounded newest-first Audit query with a non-unique ordering; the decision adds conventional 20-row URL pagination and `inserted_at DESC, id DESC` while keeping every record reachable and existing exact filter meanings unchanged.

---

## Claude's Discretion

- The user explicitly delegated all implementation, product, architecture, security, performance, accessibility, UI/UX, content, ecosystem, and DX choices for this phase after deep research.
- Low-level pure-helper names, CSS grid syntax, presentation-map module placement, and test-file decomposition remain discretionary only where `79-CONTEXT.md` and the shipped Phase 76–78 contracts do not decide them.
- The newer `guides/brand-book.md` is authoritative over older prompt wording when they conflict.

## Deferred Ideas

- Configurable/dynamically ranked Overview, charts, polling, and a unified feed.
- A real time-window definition and read-model change for “Resolved recently.”
- New Audit search/filter/export/live-tail/correlation capabilities or schema expansion.
- A breaking public Cron API change for `reason_required`.
- New limiter mutations, root-cause scoring, or duplication of Oban Web bridge capabilities.
