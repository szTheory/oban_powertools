# Phase 56: redact: At-Rest - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 56-redact-at-rest
**Areas discussed:** Enqueue intercept point, redact ∩ required-field + path scope, Recording integration, Doctor advisory, (escalated) Cron coverage, (escalated) Required-field mechanism

**Mode:** advisor (USER-PROFILE present; `vendor_philosophy: thorough-evaluator`
project override → fuller tables; `NON_TECHNICAL_OWNER = false` via
`technical_background: true`). All four selected areas were researched by parallel
subagents grounded in `prompts/` + `.planning/research/`, then synthesized.

---

## Enqueue intercept point (REDACT-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Override `new/1,2` (all paths) | Drop + inject `__redacted_fields__` in the macro-overridden `new/2`; covers `enqueue/2` and direct `Oban.insert`. Fingerprint still first in `transaction/3`. | ✓ |
| `transaction/3` only | Redact only in the Powertools idempotency path; direct `MyWorker.new \|> Oban.insert` silently persists PII. | |

**User's choice:** Override `new/1,2` (full coverage).
**Notes:** Research validated against Oban Pro `encrypted:` (hooks worker changeset
build) + Sidekiq client-middleware model. Subtlety: inject `__redacted_fields__`
exactly once (in `new/2`, not also in `transaction/3`); deep-merge to preserve
fingerprint/limits/deadline meta.

---

## redact: ∩ required-field + path scope (REDACT-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Compile-time raise + top-level only | Raise on `redact ∩ validate_required`; `Map.drop` top-level keys only; nested deferred. | ✓ (refined to auto-exempt — see escalation) |
| Enqueue-time raise + top-level only | Defer collision check to enqueue time. | |
| Compile-time raise + nested paths | Support nested redaction paths in v1.7. | |

**User's choice:** Compile-time raise + top-level only — **refined** by research
into auto-exempt + compile-time typo guard (see "Required-field mechanism" below).
**Notes:** Research found `validate_required` is all-or-nothing today
(`worker.ex:97-101`), so the collision is the default for any typed+redacted field.

---

## Recording integration

| Option | Description | Selected |
|--------|-------------|----------|
| Flag `redacted:true` + document | Set `JobRecord.redacted` true for redact-workers. | |
| Document-only | redact never touches recording; doc host responsibility; leave flag false. | ✓ |
| Auto-scrub recorded payload | `Map.drop` over `{:ok, payload}`. | |

**User's choice:** Document-only (research reversed the initial "flag" lean).
**Notes:** Setting `redacted:true` on an unscrubbed payload violates Phase 55 D-36
and the support-truth posture; `runtime_config.ex:202` would render the false claim
to operators. Auto-scrub rejected — payload keys ≠ arg keys (false assurance + data
loss). UI annotation obligation met via `__redacted_fields__` args-panel display.

---

## Doctor advisory

| Option | Description | Selected |
|--------|-------------|----------|
| Defer | No doctor check this phase; note trigger to revisit. | ✓ |
| Include in Phase 56 | Flag jobs whose worker declares `redact:` but meta lacks `__redacted_fields__`. | |

**User's choice:** Defer.
**Notes:** Requires worker-module introspection (crosses doctor's DB-only boundary),
high false-positive surface, no REDACT requirement asks for it. Universal intercept +
cron fix + compile-time guards make the supported path bypass-resistant instead.

---

## (Escalated) Cron coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Fix cron path (full coverage) | Route `cron.ex:422` through `entry.worker.new/2`; fall back to bare `Oban.Job.new` for plain workers. | ✓ |
| Document gap for v1.7 | Leave cron.ex:422 as-is; document cron jobs not redacted. | |

**User's choice:** Fix cron path.
**Notes:** Research finding — `cron.ex:422` uses bare `Oban.Job.new`, bypassing the
`new/2` override, so cron-scheduled redact-workers would leak PII without this fix.

---

## (Escalated) Required-field mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-exempt + typo guard | Redacted fields auto-exempt from `validate_required` at perform re-cast; compile-time raise if a redact field isn't a declared schema field. No new public API. | ✓ |
| Explicit `required: false` modifier | New per-field arg modifier + raise if redact field still required. | |
| Redact only non-typed fields | Disallow redacting typed fields entirely. | |

**User's choice:** Auto-exempt + typo guard.
**Notes:** `perform/1` re-casts stored (redacted) args each run, so a typed+required+
redacted field would fail on every execution. Auto-exempt is the least-surprise
behavior; typo guard preserves loud-on-misconfig. Avoids new public API on the
shipped typed-args contract.

---

## Claude's Discretion

Per the user's posture ("research deeply, one-shot a coherent recommendation set,
escalate only new public API / security"), Claude synthesized all locked decisions
from subagent research. Only the two genuinely new/consequential findings (cron-path
bypass, required-field collision) were escalated as explicit questions; both confirmed.

## Deferred Ideas

- `encrypt:` field-level at-rest encryption (PROJECT.md-deferred).
- Retroactive redaction (`Redactor.scrub_past_jobs/2`).
- Nested redaction paths (`[[:user, :ssn]]`).
- `required: false` per-field arg modifier.
- Doctor redact-bypass advisory (trigger: real bypass incident with PII in args).
- Auto-scrubbing recorded output payloads.
