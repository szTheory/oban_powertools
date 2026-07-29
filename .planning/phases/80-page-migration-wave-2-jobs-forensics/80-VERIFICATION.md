---
phase: 80-page-migration-wave-2-jobs-forensics
verified: 2026-07-29T04:31:29Z
status: gaps_found
score: "90/91 must-haves verified"
behavior_unverified: 0
requirements_total: 12
requirements_satisfied: 11
requirements_partial: 1
requirements_blocked: 0
review_findings:
  critical_open: 0
  warnings_open: 1
gaps:
  - id: WR-01
    requirement: PAGE-02
    severity: warning
    summary: "The canonical full Jobs detail route accepts positive IDs above signed 64-bit range and passes them to Repo.get/2."
    files:
      - lib/oban_powertools/web/jobs_live.ex
      - lib/oban_powertools/web/jobs_params.ex
      - test/oban_powertools/web/live/jobs_live_test.exs
    missing:
      - "Bound normalize_detail_job_id/1 to 9_223_372_036_854_775_807 before authorization or Repo access."
      - "Add connected regressions for the maximum accepted detail-path ID and an oversized detail-path ID that renders the uniform unavailable state without issuing an oban_jobs query."
human_verification: []
next_action: "Create and execute a gap-closure plan for WR-01, then re-run Phase 80 verification."
next_command: "/gsd:plan-phase 80 --gaps"
---

# Phase 80 Verification Report

**Phase Goal:** Migrate the data-dense Jobs and Forensics surfaces onto the
shared filter, table, detail, and timeline patterns while preserving URL state,
accessibility, visual evidence, and filter/search/bulk/deep-link behavior.

**Result:** Gaps found. The Forensics authority gap, Jobs list/quick-review
integer bounds, and frozen batch-result identity gaps are closed. The canonical
full-detail Jobs route still has a distinct unbounded path-ID parser, so PAGE-02
and the phase's no-deep-link-regression criterion are not fully achieved.

## Goal Achievement

| Goal | Status | Evidence |
|---|---|---|
| Jobs and Forensics use the shared production composition seams | VERIFIED | Actual `JobsLive`/`ForensicsLive` composition, focused suites, manifest, ARIA, and VRT evidence |
| URL-owned filters, search, and typed Forensics scopes are preserved | VERIFIED | `JobsParams`, `Forensics.Scope`, selectors, LiveView tests, and connected page matrix |
| Bulk execution remains bounded, frozen, and fail-closed | VERIFIED | Batch coordinator and JobsLive exact-position contracts; focused suite and repeated coordinator runs |
| Full-detail and quick-review deep links are safe and behavior-preserving | PARTIAL | Quick-review IDs are signed-64-bit bounded; full-detail path IDs are not |
| Adversarial VRT and accessibility gates are green | VERIFIED | 147 ARIA snapshots, 588 PNG baselines, seven VoiceOver cases discovered, and 1,392 compare-only page checks |

## Blocking Gap

### WR-01 — Full-detail Jobs path IDs are not signed-64-bit bounded

`JobsParams.parse_job_id/1` correctly bounds the list's `job=<id>` quick-review
selector, but `/ops/jobs/jobs/:id` does not use it.
`JobsLive.normalize_detail_job_id/1` accepts every positive Erlang integer and
`load_job_detail/3` then calls `Jobs.get(repo(), normalized_id)`, which delegates
directly to `repo.get(Oban.Job, job_id)`.

Consequently, a 50-digit path ID can reach the Postgrex `bigint` binding instead
of rendering the existing non-enumerating “Job unavailable” state. This is a
real application-level crash/noisy-log path and a low-cost denial-of-service
surface.

This changes the phase status because it contradicts:

- Plan 80-15's must-have that a job ID above signed-64-bit range is rejected
  before it reaches Repo;
- Plan 80-15's key link promising a safe job ID before `get` Repo calls;
- PAGE-02's preservation of Jobs list **and detail** deep-link behavior; and
- Roadmap success criterion 3, “No functional regression in
  filter/search/bulk/deep-link behavior.”

The warning is not a critical security finding, but it is an unmet explicit
phase truth. It therefore requires `gaps_found`, not an advisory-only passed
status.

## Corrected Gap-Closure Reconciliation

| Previous gap | Status | Evidence |
|---|---|---|
| CR-01 — forged cross-workflow Forensics step | CLOSED | One relational Step predicate validates ID, workflow, and name before Audit; uniform unavailable regressions pass |
| WR-01 — oversized Jobs URL integers | PARTIAL | List-page offsets and quick-review query IDs are bounded; full-detail path IDs remain unbounded |
| WR-02 — frozen batch terminal identity | CLOSED | Target positions survive timeout/crash/out-of-order terminals and exact unique-position reconciliation fails closed |
| V-TEST-01 — coordinator repeatability | CLOSED | Three additional coordinator runs passed 9 tests with 0 failures each |

## Must-Have Accounting

The 16 plan frontmatters define 91 truth-level must-haves. Actual source,
tests, summaries, validation evidence, and the current review support 90.
The one failed truth is Plan 80-15's broad signed-64-bit job-ID-before-Repo
contract.

All declared artifacts and key links exist. Summary claims are supported except
where the closing records overstate the partial integer fix:

- `80-15-SUMMARY.md` accurately says it bounded page offsets and
  **quick-review** IDs, but its “Jobs URL safety” readiness statement is too
  broad for the full-detail route.
- `80-16-SUMMARY.md`, `80-VALIDATION.md`, and the prior verification mark
  PAGE-02/WR-01 fully closed without checking the separate
  `normalize_detail_job_id/1` path.

## Requirement Coverage

| Requirement | Status | Evidence |
|---|---|---|
| PAGE-02 | PARTIAL | Jobs list, filters, bulk flows, quick review, and canonical detail composition are migrated; oversized full-detail path IDs can still reach Repo |
| PAGE-09 | SATISFIED | Typed four-family Forensics scope, relational workflow-step authority, bounded evidence, and diagnosis-first timeline |
| FORM-03 | SATISFIED | Submit-owned Jobs/Forensics validation and canonical URL-applied truth |
| DATA-01 | SATISFIED | Shared table/detail/timeline/progress/explicit-state components are used |
| DATA-02 | SATISFIED | Closed shared status taxonomy remains the rendered status source |
| DATA-03 | SATISFIED | 320/tablet/wide and adversarial bounded page matrix passes |
| DATA-04 | SATISFIED | Closed presenters and shared structural redaction pass confidentiality checks |
| PAGE-10 | SATISFIED | Jobs and Forensics use shared production composition seams and generated story discovery |
| A11Y-01 | SATISFIED | Page axe, ARIA, acceptance, and compare-only gates pass |
| A11Y-02 | SATISFIED | Keyboard, focus, modal, and semantic-tree contracts pass |
| A11Y-03 | SATISFIED | Four themes, responsive geometry, contrast modes, targets, and focus evidence pass |
| A11Y-04 | SATISFIED WITH DOCUMENTED ENVIRONMENT LIMITATION | Seven production-composed VoiceOver cases are executable/discovered; real transcripts remain explicitly open because local Guidepup cannot start VoiceOver |

The current `REQUIREMENTS.md` marks PAGE-02 complete. That ledger state is
premature while WR-01 remains open and should not be used to override actual
behavioral verification.

## Fresh Evidence Reconciled

| Check | Result |
|---|---|
| Focused five-file Jobs/Forensics lane | 112 tests, 0 failures |
| Full ExUnit suite | 933 tests, exactly 5 inherited failures |
| Isolated/full/rerun attribution | Five byte-identical exact module/title/path/line tuples |
| Compare-only page matrix | 1,392 passed |
| ARIA artifact validator | 147 exact snapshots |
| PNG baseline validator | 588 exact baselines |
| VoiceOver discovery | Exactly 7 cases |
| Code review | 0 critical, 1 open warning: WR-01 |
| Schema and UI safety gates | Passed |

The five full-suite failures remain exactly attributable to inherited
docs/example-host/fresh-host contract owners and do not change this phase's
status. Codebase-drift output is advisory only. The `gaps_found` status is
caused solely by the phase-owned full-detail Jobs path bound.

## Human Verification

None required for this gap. It is mechanically fixable and should be closed by
code plus a connected regression. The existing VoiceOver supported-environment
limitation remains documented and is not reclassified as the WR-01 blocker.

## Next Action

Create a gap-closure plan that reuses a signed-64-bit-bounded job-ID parser (or
applies the identical upper bound in `normalize_detail_job_id/1`) and proves
that oversized detail-path IDs render the uniform unavailable state before any
`oban_jobs` query:

`/gsd:plan-phase 80 --gaps`

---

_Verified: 2026-07-29_
_Verifier: Codex_
