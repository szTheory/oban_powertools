---
phase: 34-historical-attention-projection-runbook-entry-surfaces
verified: 2026-05-27T15:39:48Z
status: verified
score: 15/15 must-haves verified
overrides_applied: 0
automated_verification:
  - test: "Overview visual scan"
    expected: "The existing diagnosis-first bucket grid remains the primary scan model, historical exemplars are bounded and secondary, and no feed-like section dominates the page."
    proxy: "test/oban_powertools/web/live/engine_overview_live_test.exs"
    command: "mix test test/oban_powertools/web/live/engine_overview_live_test.exs --seed 0"
    closed_by: "Phase 40 plan 40-01"
  - test: "Runbook copy judgment"
    expected: "Representative overview, drilldown, and /ops/jobs/forensics states read as advisory, evidence-grounded, and ownership-honest before navigation or action."
    proxy: "test/oban_powertools/web/live/runbook_copy_contract_test.exs"
    command: "mix test test/oban_powertools/web/live/runbook_copy_contract_test.exs --seed 0"
    closed_by: "Phase 40 plan 40-01"
---

# Phase 34: Historical Attention Projection & Runbook Entry Surfaces Verification Report

**Phase Goal:** project historically important issues back into the native overview and expose the first honest runbook entry points.
**Verified:** 2026-05-27T07:19:52Z (initial); 2026-05-27T15:39:48Z (human gate retired by Phase 40 plan 40-01).
**Status:** verified
**Re-verification:** Phase 40 plan 40-01 replaced the human visual-scan and copy-judgment gates with automated proxies; CI shift-left wired into C3/C4 by Phase 40 plan 40-02.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | The overview surfaces historically important issues without collapsing into an unrestricted event feed. | VERIFIED | `AttentionProjection.project_bucket/2` is wired from `OverviewReadModel`; `rg "Historical Attention|raw event|event feed"` returned no implementation matches. |
| 2 | Supported diagnosis states expose runbook entry guidance with prerequisites, cautions, and recommended next steps. | VERIFIED | `RunbookEntry.from_bundle/1` builds entries; `ForensicsLive` renders diagnosis state, why-now, prerequisites, cautions, recommended order, evidence link, boundaries, and completeness. |
| 3 | Operators can distinguish native, bridge-only, and host-owned follow-up paths before taking action. | VERIFIED | `ControlPlanePresenter.runbook_ownership_label/1` returns `Powertools-native`, `Oban Web bridge`, and `host-owned follow-up`; LiveView tests assert the triad across forensics and drilldowns. |
| 4 | `/ops/jobs` keeps the existing diagnosis-first bucket grid as the primary scan model. | VERIFIED | `engine_overview_live_test.exs` asserts `Diagnosis-first overview`, `Needs Review`, `Blocked`, `Waiting`, `Runnable`, `Bridge-only Follow-up`, and `Resolved Recently`. |
| 5 | Historical limiter, cron, workflow, and Lifeline signals only change exemplar reason, order, or next path when they change the safe operator path. | VERIFIED | Overview candidates are assembled from Lifeline incidents, limiter summaries, cron summaries, and audit/workflow continuity, then ranked by `AttentionProjection`; candidates without honest paths are excluded. |
| 6 | Each affected bucket renders no more than three historical exemplars and never becomes a raw event feed. | VERIFIED | `@bucket_limit 3` and `Enum.take(@bucket_limit)` in `attention_projection.ex`; tests cover four candidates projecting to exactly three. |
| 7 | Partial evidence, history unavailable, and unknown states remain visible before following a next path. | VERIFIED | Projection and overview rendering preserve `evidence_completeness`; tests assert `partial evidence`, `history unavailable`, `unknown`, and evidence links. |
| 8 | Operators can open canonical `/ops/jobs/forensics` runbook entries for supported diagnosis states. | VERIFIED | `Forensics.bundle/2`, `CronHistory.bundle/3`, and `LimiterHistory.bundle/3` enrich bundles with `:runbook_entry`; `ForensicsLive` renders it. |
| 9 | Canonical runbook entries show diagnosis state, why-now, prerequisites, cautions, ordered next paths, ownership/venue, evidence link, unsupported boundaries, and completeness. | VERIFIED | `RunbookEntry` creates all fields and `ForensicsLive` renders them in the required section order between `Diagnosis Summary` and `Timeline`. |
| 10 | Runbook guidance is advisory and evidence-grounded without claiming execution, session persistence, or remediation continuity. | VERIFIED | `rg` found no Phase 34 runbook `phx-click`, checklist, session-persistence, alert-delivery, or remediation-continuity claims in runbook surfaces. |
| 11 | Native, bridge-only, and host-owned follow-up paths are visible before navigation or action. | VERIFIED | Runbook next paths normalize ownership and render venue/ownership before path labels; bridge/host-owned tests assert plain or bordered treatment. |
| 12 | Overview, drilldown, refusal-adjacent, and forensic handoffs use shared control-plane and forensic vocabulary. | VERIFIED | Drilldown LiveViews call `ControlPlanePresenter.runbook_*`; tests assert shared labels and refusal order. |
| 13 | Limiter, cron, workflow, and Lifeline drilldowns show compact runbook guidance only when there is an honest safe path. | VERIFIED | `CronLive`, `LimitersLive`, `WorkflowsLive`, and `LifelineLive` render compact `Open runbook entry` handoffs with stable forensic links and evidence copy. |
| 14 | Ownership labels are visible at decision points using exactly the ownership triad. | VERIFIED | Presenter helper definitions and LiveView tests assert exact strings across all touched surfaces. |
| 15 | Unsupported, premature, bridge-only, and host-owned steps render as guidance or refusal-adjacent next paths, not disabled mystery controls or faux-native buttons. | VERIFIED | Workflow refusal order remains `Outcome`, `Reason`, `Legal next move`, `Venue`, evidence/code; forensics renders non-native paths as bordered/plain guidance. |

**Score:** 15/15 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/oban_powertools/forensics/attention_projection.ex` | Bounded deterministic projection helper | VERIFIED | Exists, 126 lines, exports `project/1` and `project_bucket/2`, caps buckets at three. |
| `lib/oban_powertools/web/overview_read_model.ex` | Overview composition with attention-backed exemplars | VERIFIED | Exists, 431 lines, aliases `AttentionProjection`, `CronHistory`, and `LimiterHistory`; builds candidates and projects buckets. |
| `lib/oban_powertools/web/engine_overview_live.ex` | Overview rendering for attention reason, completeness, venue, evidence links | VERIFIED | Exists, 186 lines, renders `attention_reason`, `evidence_completeness`, `evidence_path`, `Open forensic timeline`, and `Open runbook entry`. |
| `lib/oban_powertools/forensics/runbook_entry.ex` | Canonical advisory runbook entry builder | VERIFIED | Exists, 332 lines, exports `build/1` and `from_bundle/1`. |
| `lib/oban_powertools/forensics.ex` | Bundle enrichment with canonical runbook entry data | VERIFIED | Exists, 458 lines, enriches workflow, Lifeline, and unknown bundles with `RunbookEntry.from_bundle/1`. |
| `lib/oban_powertools/web/forensics_live.ex` | Deep runbook entry rendering | VERIFIED | Exists, 290 lines, renders runbook entry between diagnosis summary and timeline. |
| `lib/oban_powertools/web/control_plane_presenter.ex` | Shared runbook/refusal/ownership helpers | VERIFIED | Exists, 173 lines, defines `runbook_ownership_label/1`, `runbook_path_posture/1`, and `runbook_boundary_note/1`. |
| `lib/oban_powertools/web/cron_live.ex` | Compact cron runbook guidance | VERIFIED | Exists, 522 lines, renders compact runbook guidance and stable cron forensic selector. |
| `lib/oban_powertools/web/limiters_live.ex` | Compact limiter runbook guidance | VERIFIED | Exists, 288 lines, renders compact runbook guidance and stable limiter forensic selector. |
| `lib/oban_powertools/web/workflows_live.ex` | Workflow runbook/refusal guidance | VERIFIED | Exists, 444 lines, renders compact workflow handoff and stable workflow forensic selector. |
| `lib/oban_powertools/web/lifeline_live.ex` | Lifeline incident runbook guidance | VERIFIED | Exists, 1235 lines, renders compact Lifeline handoff and encoded forensic selector. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `overview_read_model.ex` | `attention_projection.ex` | Bucket exemplar projection | WIRED | Calls `AttentionProjection.project_bucket/2` for overview buckets. |
| `engine_overview_live.ex` | Overview exemplar maps | Optional attention fields | WIRED | Renders `attention_reason`, `evidence_completeness`, and `evidence_path`. |
| `forensics.ex` | `runbook_entry.ex` | Bundle enrichment | WIRED | Aliases `RunbookEntry` and calls `RunbookEntry.from_bundle/1`. |
| `forensics_live.ex` | `bundle.runbook_entry` | Canonical runbook entry render | WIRED | Reads `@bundle.runbook_entry` and renders required sections. |
| Drilldown LiveViews | `ControlPlanePresenter` | Shared runbook helpers | WIRED | `cron_live.ex`, `limiters_live.ex`, `workflows_live.ex`, and `lifeline_live.ex` use `ControlPlanePresenter.runbook_*`. |
| Drilldown LiveViews | `/ops/jobs/forensics` | Stable selector handoffs | WIRED | Cron and limiter use `resource_type/resource_id`; workflow uses `workflow_id/step`; Lifeline uses `incident_fingerprint/view`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `overview_read_model.ex` | Bucket exemplars | Repo-backed Lifeline incidents, limiter summaries, cron summaries, and audit rows | Yes | FLOWING |
| `engine_overview_live.ex` | `bucket.exemplars` | `OverviewReadModel.build/1` assigns | Yes | FLOWING |
| `forensics.ex` | `bundle.runbook_entry` | `EvidenceBundle.build/1` plus legal next paths and selectors | Yes | FLOWING |
| `cron_history.ex` | `bundle.runbook_entry` | Cron entries, coverage, slots, and audit events | Yes | FLOWING |
| `limiter_history.ex` | `bundle.runbook_entry` | Limiter resources, history facts, blocker snapshots, and audit events | Yes | FLOWING |
| `forensics_live.ex` | `@bundle.runbook_entry` | `Forensics.bundle/2` dispatch from route selectors | Yes | FLOWING |
| Drilldown LiveViews | Compact runbook panels | Selected resource/incident/workflow summaries and stable forensic link builders | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase 34 targeted suite | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs` | 61 tests, 0 failures | PASS |
| Feed-like overview check | `rg -n "Historical Attention|raw event|event feed" lib/oban_powertools/web/engine_overview_live.ex lib/oban_powertools/web/overview_read_model.ex test/oban_powertools/web/live/engine_overview_live_test.exs` | No matches | PASS |
| Unsafe selector/copy check | `rg -n "preview_token|runbook_copy|attention_reason=|reason=|copy=" ...` | No Phase 34 runbook/overview URL selector matches; existing preview-token internals remain outside runbook handoffs | PASS |
| Action/session/delivery claim check | `rg -n "phx-click=.*runbook|checklist|persisted|session persistence|completed remediation|delivered alert|alert delivery|remediation continuity|runbook session" ...` | No matches | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| OPS-03 | 34-01, 34-03 | Native overview projects attention-worthy historical issues without becoming a raw-event feed. | SATISFIED | Existing bucket grid is preserved, projection caps at three exemplars, and feed-like UI strings are absent. |
| RNB-01 | 34-01, 34-02, 34-03 | Operators see runbook next steps with preconditions, cautions, and recommended order before bounded native action. | SATISFIED | Canonical runbook entries and compact handoffs render prerequisites, cautions, recommended order, and evidence links. |
| RNB-02 | 34-02, 34-03 | Guidance distinguishes Powertools-native, bridge-only, and host-owned/external steps. | SATISFIED | Ownership triad is centralized and rendered before navigation/action across forensics and drilldowns. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| Multiple LiveViews | Various | Empty-list checks such as `@resources == []` and `bucket.exemplars == []` | Info | Legitimate empty-state rendering, not stubs. |

### Risk/Debt

| ID | Source | Risk | Verification Impact |
|----|--------|------|---------------------|
| WR-01 | `34-REVIEW.md` | `overview_read_model.ex` interpolates `incident_fingerprint` directly into some Lifeline/Forensics URLs instead of encoding it. | Advisory debt. Stable selector names are used and no rendered copy selectors were found, but delimiter-containing fingerprints could lose selector fidelity. |
| WR-02 | `34-REVIEW.md` | `RunbookEntry`, `Provenance`, and presenter normalization use `String.to_atom/1` for caller-provided strings. | Advisory security debt. It does not block the Phase 34 UI goal, but should be fixed with whitelist normalization. |

### Automated Verification

The two former human gates are encoded as deterministic ExUnit/LiveView proxy tests added in Phase 40 plan 40-01. CI shift-left into the existing `continuity-ver04-c3` and `continuity-ver04-c4` lanes is performed by Phase 40 plan 40-02; merge-blocking workflow drift is prevented by marker assertions in `test/oban_powertools/docs_contract_test.exs`.

### 1. Overview Visual Scan

**Proxy test:** `test/oban_powertools/web/live/engine_overview_live_test.exs` — `"visual hierarchy proxy: bucket-grid headings precede historical exemplars and no feed-like section is rendered"`
**Command:** `mix test test/oban_powertools/web/live/engine_overview_live_test.exs --seed 0`
**Encoding:** asserts bucket headings (`Diagnosis-first overview`, `Needs Review`, `Blocked`, `Waiting`, `Runnable`, `Bridge-only Follow-up`, `Resolved Recently`) appear in DOM order before any exemplar marker, and refutes any top-level feed-like section heading (`Event Feed`, `Activity Feed`, `Event Stream`, `Recent Activity`).

### 2. Runbook Copy Judgment

**Proxy test:** `test/oban_powertools/web/live/runbook_copy_contract_test.exs` — `"runbook surfaces honor the automated copy contract across workflow and lifeline bundles"`
**Command:** `mix test test/oban_powertools/web/live/runbook_copy_contract_test.exs --seed 0`
**Encoding:** renders workflows-live (legacy semantics rejection) + workflow forensics + lifeline forensics, asserts the ownership triad and at least one evidence-boundary marker, asserts refusal section ordering `Outcome → Reason → Legal next move → Venue` on workflows-live, refutes execution/certainty overclaims and faux-native runbook shortcuts.

### Gaps Summary

No blocking gaps found. Automated checks verify the phase goal and all roadmap/plan must-haves. The previously open human visual-scan and copy-judgment gates are now closed by deterministic proxy tests; the two code review warnings (`WR-01`, `WR-02`) remain advisory debt unchanged by Phase 40.

---

_Verified: 2026-05-27T07:19:52Z_
_Verifier: Claude (gsd-verifier)_
