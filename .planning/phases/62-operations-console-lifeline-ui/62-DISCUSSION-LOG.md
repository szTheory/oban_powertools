# Phase 62: Operations Console & Lifeline UI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 62-operations-console-lifeline-ui
**Areas discussed:** Context creation gate, batch detail navigation, recovery model

---

## Context Creation Gate

| Option | Description | Selected |
|--------|-------------|----------|
| Create context | Write `62-CONTEXT.md` and `62-DISCUSSION-LOG.md` from the locked UI spec, prior decisions, and advisor-mode recommendations. | yes |
| Discuss route | Compare URL-addressable batch detail against inline expansion before locking it. | |
| Discuss recovery | Compare callback retry and failed-member recovery models before locking them. | |

**User's choice:** Create context.
**Notes:** User replied `1` after the context gate. The approved path captures the advisor-mode recommendations without further option shopping.

---

## Batch Detail Navigation

| Option | Description | Selected |
|--------|-------------|----------|
| URL-addressable detail route | Add `/ops/jobs/batches/:id` as the canonical batch detail pattern, matching `JobsLive` and the UI-SPEC preference. | yes |
| Inline-only expansion | Keep all detail inspection inside the index table. | |
| Hybrid with inline previews | Allow compact inline previews, but keep the URL detail route as canonical. | yes |

**User's choice:** Accepted the recommended context.
**Notes:** URL-addressable detail is locked because it supports reloads, deep links, audit/forensic handoffs, and parity with the existing native job detail surface. Inline expansion is allowed only as an enhancement, not as the sole detail route.

---

## Recovery Model

| Option | Description | Selected |
|--------|-------------|----------|
| Existing Lifeline job repair for failed members | Failed batch member retry routes through per-job Lifeline preview/execute attempts and reports per-job outcomes. | yes |
| Explicit Lifeline callback repair target | Callback retry becomes a bounded Lifeline target/action over callback rows, with preview token, reason, drift handling, and audit evidence. | yes |
| Direct Oban or direct database mutation | The batches UI retries jobs or callbacks by calling Oban or updating callback rows directly. | |

**User's choice:** Accepted the recommended context.
**Notes:** Native Powertools pages own audited mutations. The Oban Web bridge remains generic inspection only. If current Lifeline code lacks callback repair support, Phase 62 should add that bounded target rather than bypass Lifeline.

---

## Agent's Discretion

- Exact read model module/function names.
- Exact query composition and pagination internals, within the existing `Jobs` read-model pattern.
- Component extraction versus single LiveView implementation, as long as the UI remains Phoenix LiveView/Tailwind and follows `62-UI-SPEC.md`.
- Test file organization and fixture helpers.

## Deferred Ideas

- Realtime/live counts (`QRY-06`).
- Cross-page select-all (`QRY-08`).
- Args/meta filtering (`QRY-05`), Lifeline-to-job deep-link polish (`QRY-07`), and programmatic job query API (`API-03`).
- Dynamic/growable batches, nested batches, chunking, arbitrary DAGs, and external dependencies.
