# Phase 78: Component Groups (Meta-Components) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-18
**Phase:** 78-Component Groups (Meta-Components)
**Areas discussed:** confirmation/result lifecycle, FilterBar behavior, DetailDrawer/Panel behavior, AttentionCard/Why blocked?/AuditEntry semantics

---

## Confirmation and Result Lifecycle

| Option | Description | Selected |
|--------|-------------|----------|
| Close every outcome | Dismiss after every response and reduce success/failure/partial results to transient notification copy. | |
| Keep every outcome open | Preserve a result view even after every clean, authoritative success. | |
| Adaptive terminal-result lifecycle | Close with an exact receipt on clean authoritative success; keep partial, failed, skipped, expired, drifted, and consumed results open with recovery evidence. | ✓ |

**User's choice:** The user asked the assistant to research all alternatives and make the coherent final choice without further decision work from them.

**Notes:** The selected lifecycle preserves operational evidence without adding confirmation fatigue. The research rejected generic “Are you sure?”, universal typed phrases, click-away dismissal, dangerous-button autofocus, preview-token exposure, and new dialog dependencies. Confirmation friction scales with reversibility and blast radius. Parent LiveViews retain authorization, preview, mutation, and audit authority; `focus_wrap` and LiveView focus JS provide the modal behavior. Frozen bulk membership, exact counts, per-item results, support-truth copy, and stale-preview rejection are non-negotiable.

---

## FilterBar Interaction Model

| Option | Description | Selected |
|--------|-------------|----------|
| Instant apply everywhere | Every field immediately changes results and URL state. | |
| Explicit apply everywhere | Every change remains a draft until a submit action. | |
| Hybrid by semantic cost | Explicit apply is the multi-field default; one cheap state/sort criterion may opt into instant application. | ✓ |
| Persistent left sidebar | Keep all filters permanently visible alongside results. | |

**User's choice:** Delegated after requesting research into ecosystem conventions, successful libraries, developer ergonomics, operator psychology, and responsive UI.

**Notes:** A top-of-results bar preserves dense-table width. Applied URL state remains canonical/shareable and parent-owned; invalid drafts do not mutate results or URL. Applied noun/value filters, exact result count, per-item removal, and Clear remain visible when narrow-screen fields collapse. The decision incorporates Phoenix `handle_params`/`push_patch` conventions, Carbon's instant-versus-batch distinction, MOJ/PatternFly applied-filter patterns, and Oban Web's lessons from removing a low-value queue sidebar while retaining shareable filtering.

---

## Detail Drawer/Panel Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Always inline panel | Preserve list interaction and comparison at every width. | |
| Always modal drawer | Focus detail inspection and block the underlying list at every width. | |
| Dedicated page only | Navigate away for all resource detail. | |
| Adaptive master/detail | Use one content tree: nonmodal inline panel when wide, modal drawer when constrained, full-screen at 320px, with a full-details escape hatch. | ✓ |

**User's choice:** Delegated as part of the one-shot recommendation request.

**Notes:** The public contract makes modality explicit with closed `:adaptive | :inline | :drawer` variants. A native `<dialog>` plus a small idempotent hook provides modal/nonmodal platform semantics without a dependency or duplicate DOM. The parent owns selected-resource URLs, fetch/authorization, history, and fallback focus. Nested dialogs, hidden desktop/mobile copies, component-owned queries, and drawers used as universal full pages were rejected.

---

## Attention, Blocker Explanation, and Audit Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| One generic alert | Use a single configurable card for current attention, causal explanation, and historical events. | |
| Provider-shaped evidence first | Lead with machine codes, raw maps, snapshots, and implementation details. | |
| Three operator-facing layers | Keep AttentionCard, Why blocked?, and AuditEntry distinct, connected by summary-first progressive disclosure. | ✓ |

**User's choice:** Delegated after asking that all personas, JTBD flows, support truth, architecture, SRE, security, accessibility, visual design, and developer-consumer perspectives be considered.

**Notes:** `AttentionCard` answers what needs attention; `why_blocked` explains current blockers, impact, clearing conditions, and safe next action; `AuditEntry` records immutable who/what/why/when/outcome history. Status and severity remain separate. Freshness/completeness is explicit. The system does not infer root cause or current truth from audit events. Raw technical evidence is redaction-safe and progressively disclosed or linked to Forensics. The recommendation draws on Kubernetes conditions/events, Grafana state/history/runbook separation, PatternFly status/severity, and the project's stronger durable audit model.

---

## Claude's Discretion

The user explicitly requested a one-shot expert recommendation and delegated every product/architecture/UI fork. The assistant chose the complete public behavior documented in `78-CONTEXT.md`. Planning retains discretion only over private helper names, exact token spacing, breakpoint tuning against real content, and equivalent internal implementation details that preserve the locked contracts.

Research used three parallel specialist agents for confirmation, filtering/detail, and explanation/audit, plus a primary-agent synthesis across the repository, all three `prompts/` research/context documents, the newer canonical brand book, prior component phases, existing LiveViews and Lifeline/Audit/Explain code, and primary ecosystem guidance. The UI-interface rules applied progressive disclosure, conventional affordances, proximity, restrained choice count, consistent spacing, target size, sub-300ms feedback, keyboard-safe motion, and strong terminal feedback.

## Deferred Ideas

- Page migrations and page-specific route/query wiring remain Phases 79–80.
- A scalable asynchronous/batched bulk executor is a Phase 80 migration concern.
- Saved filters, async suggestions, query grammar, and filter presets are out of scope.
- New audit schemas, causal inference, backend root-cause claims, and operator capabilities are out of scope.
- New runtime dependencies and nested modal workflows were rejected.
