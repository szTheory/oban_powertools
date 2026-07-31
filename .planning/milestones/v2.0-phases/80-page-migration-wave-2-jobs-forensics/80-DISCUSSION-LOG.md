# Phase 80: Page Migration Wave 2 — Jobs, Forensics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 80-Page Migration Wave 2 — Jobs, Forensics
**Areas discussed:** Jobs browse-to-detail, Jobs filter and table hierarchy, Bulk selection/confirmation/execution/results, Forensics investigation narrative

---

## Jobs browse-to-detail

| Option | Description | Selected |
|--------|-------------|----------|
| Full-page detail only | Preserve the current list → `/jobs/:id` model and do not use Phase 78 adaptive detail. Simple and canonical, but slower for repeated scan/review and does not satisfy the roadmap’s DetailDrawer migration intent. | |
| Drawer/modal detail only | Replace rich job detail with one adaptive surface. Fast in-list review, but overloads a modal with payloads, history, and mutations; creates nested-dialog and deep-link problems. | |
| Hybrid quick review plus full detail | Use a URL-backed, read-only adaptive review surface for scan context and retain `/jobs/:id` for rich detail and every mutation. | ✓ |

**User's choice:** Discuss all approaches deeply and make the cohesive recommendation.
**Notes:** Research favored the hybrid because it follows the shipped Phase 78 rule that bounded review may be adaptive while complex mutation-heavy detail remains a full page. Quick review is deliberately payload-free and mutation-free. Canonical history and allowlisted list context avoid ephemeral state and open redirects.

### Quick-review content alternatives

| Option | Description | Selected |
|--------|-------------|----------|
| Near-complete detail in the drawer | Duplicate arguments, metadata, output, stacktraces, history, and actions. | |
| Identity-only peek | Show only ID/worker/state. Safe but too weak to support the review JTBD. | |
| Task-focused read-only summary | Show identity, state, queue, attempts/timing, safe latest error summary, output availability, and a full-detail escalation. | ✓ |

---

## Jobs filter and table hierarchy

| Option | Description | Selected |
|--------|-------------|----------|
| Instant query on every field | Treat every change as applied state. Feels immediate for tiny inputs, but JSON composition, URL churn, database load, and draft-error handling become surprising. | |
| Submit mode with a new qualifier DSL | Adopt an Oban Web-like unified grammar. Powerful, but changes current behavior, exposes parser concepts, and expands scope. | |
| Submit-mode typed fields | Keep state as the required view and preserve Queue/Worker/Tags/Args/Meta semantics, with draft validation and atomic URL application. | ✓ |

**User's choice:** Discuss all approaches deeply and make the cohesive recommendation.
**Notes:** Primary fields are Queue, Worker module, and Tags; args/meta JSON containment is advanced. Categories are ANDed, tags require every listed tag, and JSON fields use map containment. Applied values, exact state counts, invalid drafts/direct URLs, and selection resets are all explicit.

### Table-density alternatives

| Option | Description | Selected |
|--------|-------------|----------|
| Expose every attribute | Put tags, args, metadata, payloads, and history into the browse table. High information volume, poor scanning, privacy, and responsive behavior. | |
| Add sorting and pagination redesign | Introduce user sorting and cursor/keyset state now. Potential scale benefit, but breaks the current URL/behavior contract and expands the migration. | |
| Operational scan table | Preserve stable scheduled/id ordering and 20-row pages; show Selection, Worker, State, Queue, Scheduled, Attempts, Job ID, and Review job. | ✓ |

---

## Bulk selection, confirmation, execution, and results

| Option | Description | Selected |
|--------|-------------|----------|
| Visible-page selection only | Safest and simplest, but removes the existing all-matching JTBD and makes large incident response laborious. | |
| Boolean all-matching scope | Keep `global_select` and rerun an unbounded ID query at execution. Familiar but unsafe under drift, scale, and authorization changes. | |
| Bounded frozen server-owned scope | Preserve explicit/page/all-matching scopes, but freeze ordered IDs, filter identity, count, and observation time before confirmation. | ✓ |

**User's choice:** Discuss all approaches deeply and make the cohesive recommendation.
**Notes:** The recommendation keeps the useful “all matching” pattern from successful job dashboards while adding a default 100 target limit, absolute 1000 host cap, no silent truncation, per-target authorization/Lifeline preview, server-only tokens, reason and typed-ready-count confirmation.

### Execution alternatives

| Option | Description | Selected |
|--------|-------------|----------|
| Sequential LiveView loop | Execute every preview/action inside `handle_event`. Easy to write, but blocks the socket and couples work lifetime to the UI. | |
| One all-or-nothing transaction | Wrap the batch in one `Ecto.Multi`. Attractive atomicity, but dishonest for independent Oban/Lifeline effects and makes partial recovery worse. | |
| Independent supervised bounded work | Use nonlinked supervised OTP work, concurrency 4, per-target timeouts, stable results, and Audit-backed recovery evidence. | ✓ |

### Result alternatives

| Option | Description | Selected |
|--------|-------------|----------|
| One aggregate success/error flash | Compact but erases partial, skipped, drifted, and recovery detail. | |
| Treat skipped as successful | Makes completion look cleaner but violates operational truth. | |
| Exact per-target outcomes | Distinguish success/skipped/failed; keep non-success open; clear only successes; require fresh preview for another attempt. | ✓ |

---

## Forensics investigation narrative

| Option | Description | Selected |
|--------|-------------|----------|
| Timeline-first event explorer | Lead with chronological evidence and infer the story from events. Familiar log-viewer shape, but weak for diagnosis and tempts causal inference. | |
| Tabs or two-pane evidence browser | Split summary, guidance, sources, and timeline into separate views. Dense but hides relationships and creates nested scroll/responsive problems. | |
| Diagnosis-first narrative | Present current supported truth, one next-safe route, historical remediation, bounded Event log, then evidence limits/sources. | ✓ |

**User's choice:** Discuss all approaches deeply and make the cohesive recommendation.
**Notes:** The page remains read-only and full-page. It uses a typed scope selector for Workflow, Lifeline incident, Cron entry, or Limiter while preserving the existing six URL keys. Mixed scopes do not silently follow backend precedence.

### Evidence-depth alternatives

| Option | Description | Selected |
|--------|-------------|----------|
| Render raw exhaustive bundle | Dump selectors, schemas, audit metadata, reasons, and all events. Exposes backend structure/secrets and cannot scale safely. | |
| Infinite timeline/search | Add filtering, live tail, and infinite scroll. Useful for a log product, but duplicates Audit and expands scope. | |
| Curated bounded evidence plus Audit | Show newest retained evidence with explicit source/provenance/completeness and coverage, then link to exhaustive authorized scoped Audit evidence. | ✓ |

---

## Claude's Discretion

The user explicitly delegated all unresolved choices and asked for a one-shot recommendation. Research and judgment were applied across:

- Elixir/OTP, Phoenix LiveView, Plug, and Ecto idioms.
- Oban Web, Mission Control Jobs, GoodJob, Sidekiq, and adjacent successful operator tools.
- The repository’s current code, Phase 77–79 contracts, prompt corpus, and current brand book.
- Operator personas, JTBD, canonical domain language, accessibility, security/privacy, performance, reliability/SRE, responsive behavior, visual design, DX, testability, and observability.

Only private implementation names, existing-token CSS composition, and exact bounded page/window sizes remain discretionary. Observable behavior and safety choices are locked in `80-CONTEXT.md`.

## Deferred Ideas

- Drawer-only job detail or quick-review mutations.
- Saved filters, qualifier DSL, new filter dimensions, global Forensics search, or saved investigations.
- User sorting, keyset/cursor URL migration, timeline filtering/live tail/infinite scrolling.
- A durable bulk-run ledger, cross-node recovery, retry-failed-only action, or result export.
- New forensic source types, causal inference, charts, encryption, or a new evidence schema.
- New job actions, provider/bridge-specific UI, or unsupported arbitrary Job→Forensics routing.
