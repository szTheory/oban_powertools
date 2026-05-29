# Phase 43: Read-Only Job Browse - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 43-Read-Only-Job-Browse
**Areas discussed:** None — all decisions resolved autonomously from existing patterns and locked STATE.md decisions

---

## Analysis Summary

Phase 43 is a well-constrained implementation phase. Prior context (STATE.md, PROJECT.md, REQUIREMENTS.md) provided locked decisions for `%JobFilter{}` struct location, permission atoms, pagination strategy, tags GIN index handling, and state-as-primary-dimension. Codebase scouting confirmed clear precedents for route structure (WorkflowsLive double-route pattern), auth (LiveAuth existing pattern), and DisplayPolicy extension (workflow_result/2 precedent).

No gray areas required user discussion — all choices resolved from existing repo decisions, Phoenix/LiveView/Ecto/Postgres norms, and Oban Web UX conventions.

---

## Autonomous Decisions (no user input — resolved from existing patterns)

| Area | Decision Made | Source |
|------|--------------|--------|
| Route structure | `live("/jobs", JobsLive, :index)` + `live("/jobs/:id", JobsLive, :show)` | WorkflowsLive precedent |
| Filter URL encoding | Query params + `push_patch` | LifelineLive + URL serialization requirement |
| State navigation | Tab bar with 7 state tabs | Oban Web UX convention; state always required |
| Data layer | `ObanPowertools.Jobs` context module with `%JobFilter{}` | Existing context module pattern |
| Job list row fields | state badge, worker (short), queue, ID, scheduled_at, attempt count | Standard job queue list format |
| Job detail navigation | Full-page `/jobs/:id` (not side-panel) | Phase 44 will add mutations here — dedicated route is cleaner |
| DisplayPolicy extension | Add `:job_args`/`:job_meta` kinds; nil/string/map return contract | `workflow_result/2` precedent |
| Auth — list page | `authorize_page(socket, :view_jobs, ...)` | LiveAuth existing pattern |
| Auth — detail page | `authorize_page(socket, :view_job_detail, ...)` | STATE.md locked atom |
| Read-only banners | Add `:jobs` and `:job_detail` to `@page_read_only_banners` | Existing map pattern |

## Claude's Discretion

- Exact copy for `@page_read_only_banners[:jobs]` and `[:job_detail]` — planner to draft following established voice
- Exact worker short-name formatting (last module segment) — implementation detail for executor
- Error display format in detail view — follow Lifeline's existing error display pattern

## Deferred Ideas

- Keyset pagination upgrade — document path, don't implement (Phase 43 is offset-based per STATE.md)
- PubSub-backed live job counts — requires `oban_met` integration (QRY-06, post-v1.5)
- args/meta full-text search (QRY-05, post-v1.5)
- Cross-page bulk select (QRY-08, post-v1.5)
- Lifeline → native job detail navigation (QRY-07, post-v1.5)
