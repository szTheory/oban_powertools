---
phase: 35
slug: runbook-guided-remediation-alert-hook-boundaries
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-27
updated: 2026-05-27
---

# Phase 35 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| preview metadata -> execute audit | Continuity facts pass from ephemeral preview state into immutable audit evidence. | remediation context metadata (internal operational state) |
| audit metadata -> forensic projection | Structured metadata is transformed into operator-visible chronology and runbook context. | audit event metadata (internal evidence records) |
| runbook continuity -> operator action | Continuity wording influences remediation confidence and escalation decisions. | rendered decision-support copy (operator-facing guidance) |
| native mutation -> host callback | Optional callback receives bounded event facts after native remediation succeeds. | bounded follow-up payload facts (host integration seam) |
| callback result -> audit/UI truth | Callback outcomes become durable operator-facing status and must remain explicit/honest. | callback status metadata (operator-visible continuity state) |
| runtime config -> callback execution | Host wiring controls handler selection and should not trigger hard failures when absent. | configuration + handler module references (runtime control plane) |
| shared presenter helpers -> multiple LiveViews | One helper change can alter ownership semantics everywhere. | normalized ownership/status labels (cross-surface UI contract) |
| read-model continuity -> UI affordance type | Ownership state determines whether controls are primary actions or guidance-only links. | affordance variant + ownership state (authorization-adjacent UI semantics) |
| URL selectors -> forensic/remediation context | Unsafe selector growth can leak transient or misleading action context. | query selector keys (forensic/remediation deep-link context) |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-35-01-01 | Tampering | `Lifeline` continuity metadata | mitigate | Build runbook context from server-side facts only (`plan_hash`, selectors, action, target) and never from client text params. | closed |
| T-35-01-02 | Repudiation | Attempt-state evidence | mitigate | Persist explicit attempt states (`previewed`, `succeeded`, `drifted`, `expired`, `consumed`) in preview/audit metadata with tests. | closed |
| T-35-01-03 | Information Disclosure | URL and metadata boundaries | mitigate | Keep reason text, rendered copy, and preview internals out of URL selectors; use stable forensic selectors only. | closed |
| T-35-01-04 | Spoofing | Ownership/venue rendering | mitigate | Render ownership via normalized triad labels, not freeform metadata strings. | closed |
| T-35-01-05 | Denial of Service | Forensics projection fallback | mitigate | Degrade to existing runbook behavior when continuity metadata is missing (no crashes/no render loss). | closed |
| T-35-02-01 | Spoofing | Host follow-up statuses | mitigate | Restrict status values to explicit enum-like strings and map to fixed presenter labels. | closed |
| T-35-02-02 | Tampering | Callback payload contract | mitigate | Emit server-generated facts only; exclude user-supplied provider destination fields. | closed |
| T-35-02-03 | Repudiation | Host callback outcomes | mitigate | Write dedicated `lifeline.host_follow_up` audit records including status and selector context. | closed |
| T-35-02-04 | Information Disclosure | Callback/UI metadata | mitigate | Avoid credentials, provider endpoints, and high-cardinality destination metadata in payload and UI. | closed |
| T-35-02-05 | Denial of Service | Callback failure path | mitigate | Callback errors produce `host_owned_follow_up_callback_failed` status without rolling back native remediation transaction. | closed |
| T-35-03-01 | Spoofing | Ownership labels across surfaces | mitigate | Centralize ownership mapping and assert exact triad copy in all LiveView tests. | closed |
| T-35-03-02 | Tampering | Follow-up control rendering | mitigate | Use shared render-variant helper and enforce only native ownership maps to primary control styling. | closed |
| T-35-03-03 | Information Disclosure | Selector/query usage | mitigate | Add allowlist-based link-key assertions for generated forensic/remediation links. | closed |
| T-35-03-04 | Repudiation | Attempt-state ordering and meaning | mitigate | Verify reading-order labels and continuity state text in UI tests to prevent ambiguous/omitted states. | closed |
| T-35-03-05 | Elevation of Privilege | Bridge/host follow-up control affordance | mitigate | Ensure bridge/host rows never render native action buttons or execution events. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party)*

---

## Summary Threat Flags

No `Threat Flags` entries were present in `35-01-SUMMARY.md`, `35-02-SUMMARY.md`, or `35-03-SUMMARY.md`.

---

## Verification Evidence

- `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/host_escalation_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs` -> `92 tests, 0 failures`
- `rg -n "preview_token=|reason=|runbook_copy|delivered alert|PagerDuty|Slack" lib/oban_powertools/web/lifeline_live.ex lib/oban_powertools/web/forensics_live.ex lib/oban_powertools/forensics.ex` -> no implementation-path matches
- `rg -n "PagerDuty|Slack|Opsgenie|ticket system|webhook destination" lib/oban_powertools/host_escalation.ex lib/oban_powertools/lifeline.ex lib/oban_powertools/web/lifeline_live.ex lib/oban_powertools/web/forensics_live.ex` -> no implementation-path matches
- `rg -n "alert delivered|ticket created|page sent|PagerDuty|Slack" lib/oban_powertools/web/*.ex test/oban_powertools/web/live/*.exs` -> matches only in test assertions that explicitly refute these claims

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-27 | 15 | 15 | 0 | Codex (`/gsd-secure-phase 35`) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-27
