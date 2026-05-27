---
status: complete
mode: automated
phase: 34-historical-attention-projection-runbook-entry-surfaces
source:
  - 34-VERIFICATION.md
started: 2026-05-27T07:20:00Z
updated: 2026-05-27T15:39:48Z
human_steps_required: 0
automation_replaces_human:
  - test: "Overview visual scan"
    reason: "Encoded as a deterministic LiveView DOM-order proxy in test/oban_powertools/web/live/engine_overview_live_test.exs that asserts bucket-grid headings precede historical exemplars and no top-level feed-like section is rendered."
  - test: "Runbook copy judgment"
    reason: "Encoded as a deterministic copy-contract proxy in test/oban_powertools/web/live/runbook_copy_contract_test.exs that requires the ownership triad and evidence boundary markers and refutes execution/certainty overclaims."
---

# Phase 34 Automated UAT

## Current Test

closed — automated proxies stand in for the two former human judgments

## Tests

### 1. Overview visual scan

expected: The existing diagnosis-first bucket grid remains the primary scan model, historical exemplars are bounded and secondary, and no feed-like section dominates the page.
reviewer: automated
result: pass
proxy: test/oban_powertools/web/live/engine_overview_live_test.exs ("visual hierarchy proxy: bucket-grid headings precede historical exemplars and no feed-like section is rendered")
command: `mix test test/oban_powertools/web/live/engine_overview_live_test.exs --seed 0`
rationale:
- bucket headings (`Diagnosis-first overview`, `Needs Review`, `Blocked`, `Waiting`, `Runnable`, `Bridge-only Follow-up`, `Resolved Recently`) asserted in DOM order before any exemplar marker
- exemplar markers (`Open forensic timeline`, `Open runbook entry`, `Blocked by policy cooldown for payments-api`) asserted to render after the first bucket heading (nested inside buckets, not a standalone feed)
- forbidden feed-like headings (`Event Feed`, `Activity Feed`, `Event Stream`, `Recent Activity`) refuted

### 2. Runbook copy judgment

expected: Representative overview, drilldown, and /ops/jobs/forensics states read as advisory, evidence-grounded, and ownership-honest before navigation or action.
reviewer: automated
result: pass
proxy: test/oban_powertools/web/live/runbook_copy_contract_test.exs ("runbook surfaces honor the automated copy contract across workflow and lifeline bundles")
command: `mix test test/oban_powertools/web/live/runbook_copy_contract_test.exs --seed 0`
rationale:
- ownership triad (`Powertools-native`, `Oban Web bridge`, `host-owned follow-up`) asserted present across workflows-live + workflow-forensics + lifeline-forensics
- at least one evidence-boundary marker (`partial evidence`, `history unavailable`, `unknown`) asserted present
- refusal section ordering `Outcome → Reason → Legal next move → Venue` asserted on the workflows-live legacy semantics rejection bundle
- forbidden execution/certainty phrases (`executed remediation`, `completed remediation`, `delivered alert`, `alert delivery`, `runbook session`, `session persists`, `persisted session`, `we will execute`, `we executed`) refuted
- faux-native runbook shortcuts refuted: any `phx-click="...runbook..."` handler and the `checklist` marker

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

none — the two former human gates are now deterministic and run under the C3 and C4 continuity proof lanes (see `.planning/phases/40-phase-34-manual-acceptance-closure/40-02-PLAN.md`).
