---
phase: 40-phase-34-manual-acceptance-closure
plan: 01
status: complete
completed_at: 2026-05-27T15:39:48Z
requirements_addressed:
  - OPS-03
  - RNB-01
  - RNB-02
files_modified:
  - test/oban_powertools/web/live/engine_overview_live_test.exs
  - test/oban_powertools/web/live/runbook_copy_contract_test.exs
  - .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-UAT.md
  - .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-VERIFICATION.md
  - .planning/REQUIREMENTS.md
self_check: PASSED
---

# Plan 40-01 Summary — Automated Proxies Replace Phase 34 Human UAT

## Objective achieved

The two remaining Phase 34 human acceptance gates — `Overview visual scan` and `Runbook copy judgment` — are now closed by deterministic ExUnit/LiveView proxy tests. No reviewer step is required to promote OPS-03, RNB-01, or RNB-02 to Complete.

## Proxy 1 — Visual hierarchy (closes "Overview visual scan")

**Test:** `test/oban_powertools/web/live/engine_overview_live_test.exs` — `"visual hierarchy proxy: bucket-grid headings precede historical exemplars and no feed-like section is rendered"`

**What it asserts:**
- Bucket-grid headings appear in DOM order: `Diagnosis-first overview` → `Needs Review` → `Blocked` → `Waiting` → `Runnable` → `Bridge-only Follow-up` → `Resolved Recently`.
- Exemplar markers (`Open forensic timeline`, `Open runbook entry`, `Blocked by policy cooldown for payments-api`) all appear *after* the first bucket heading, proving they render nested inside buckets rather than as a standalone top-level region.
- No top-level feed-like section heading is rendered: `Event Feed`, `Activity Feed`, `Event Stream`, `Recent Activity` are all refuted.

**How it maps to the former human judgment:** the human gate asked "does the diagnosis-first bucket grid remain primary and the historical exemplars stay bounded and secondary?". DOM ordering plus the forbidden-heading refute set encode that question deterministically.

## Proxy 2 — Copy contract (closes "Runbook copy judgment")

**Test:** `test/oban_powertools/web/live/runbook_copy_contract_test.exs` — `"runbook surfaces honor the automated copy contract across workflow and lifeline bundles"`

**Setup:** seeds a workflow with `semantics_version: 1` and triggers an `unsupported_legacy_semantics` rejection (matches `WorkflowsLiveTest` pattern), then a dead-executor `Incident`. Mounts three runbook surfaces:
- `/ops/jobs/workflows/<id>?step=fetch_customer`
- `/ops/jobs/forensics?workflow_id=<id>&step=fetch_customer&resource_type=workflow_step`
- `/ops/jobs/forensics?incident_fingerprint=<encoded>`

Joins the three HTML strings into a single `runbook_surface` for shared-marker assertions.

**What it asserts:**

Required markers (across all three surfaces):
- ownership triad strings present: `Powertools-native`, `Oban Web bridge`, `host-owned follow-up`
- at least one evidence-boundary marker present: `partial evidence`, `history unavailable`, or `unknown`

Required ordering (workflows-live HTML only — refusal block is owned by `WorkflowsLive`):
- `Outcome:` → `Reason:` → `Legal next move:` → `Venue:`

Forbidden phrases (refuted across all three surfaces):
- `executed remediation`, `completed remediation`, `delivered alert`, `alert delivery`
- `runbook session`, `session persists`, `persisted session`
- `we will execute`, `we executed`
- any `phx-click="...runbook..."` handler (faux-native action shortcut)
- the `checklist` keyword (faux-native session marker)

**How it maps to the former human judgment:** the human gate asked "does the runbook copy read as advisory, evidence-grounded, and ownership-honest?". The required-marker set encodes "ownership-honest" and "evidence-grounded"; the forbidden-phrase set encodes "advisory, not execution overclaim".

## Closure artifacts

- `34-UAT.md` — frontmatter now `mode: automated`, `status: complete`; both tests show `reviewer: automated` and `result: pass` with their proxy paths and seed-0 commands. Summary counts updated to 2 passed, 0 pending.
- `34-VERIFICATION.md` — frontmatter `status: verified` (no remaining `human_needed`); `human_verification` replaced by `automated_verification`; `Human Verification Required` section renamed `Automated Verification` and documents both proxies.
- `REQUIREMENTS.md` — top-of-doc checkboxes for OPS-03, RNB-01, RNB-02 flipped to `[x]`; traceability table status updated to `Complete`.

## Verification commands

```
mix test test/oban_powertools/web/live/engine_overview_live_test.exs --seed 0
# → 7 tests, 0 failures (visual hierarchy proxy = test #7)

mix test test/oban_powertools/web/live/runbook_copy_contract_test.exs --seed 0
# → 1 test, 0 failures
```

## Notes

- A small `RunbookCopyContractDisplayPolicy` no-op module is defined in the same file as the test because the workflows-live mount requires `:display_policy` to be configured. This matches the convention already used by `WorkflowsLiveTest` and `ControlPlaneCopyCoherenceTest`.
- The new visual-hierarchy test reuses the existing `seed_overview_fixture!/1` helper inside `engine_overview_live_test.exs`. Two small private helpers (`assert_occurs_in_order/2`, `byte_index/2`) were added at the end of that file to support DOM-order assertions; the `assert_occurs_in_order/2` shape matches the one already in `control_plane_copy_coherence_test.exs`.
- Wiring these two suites into the merge-blocking C3/C4 continuity lanes happens in Plan 40-02.

## Self-Check: PASSED
