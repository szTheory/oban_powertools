---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 06
subsystem: forensics
tags: [ecto, audit, evidence, presenter, redaction, authorization]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 05
    provides: Typed four-family scope grammar and bounded workflow/incident Audit windows
provides:
  - Typed ok/unavailable/error evidence assembly for all four supported Forensics families
  - Closed newest-first chronology and per-source coverage with structural redaction
  - Exact eight-field diagnosis-first Forensics presentation contract
  - Canonical authorization-bound noun guidance and neutral historical remediation evidence
affects: [80-07, forensics-live, page-stories, browser-quality]

tech-stack:
  added: []
  patterns:
    - Parse and revalidate typed scope before resolving a repository or dispatching a source
    - Project source evidence through finite nested keys before any presentation work
    - Match supported local destinations by authorized canonical URL and finite noun meaning

key-files:
  created: []
  modified:
    - lib/oban_powertools/forensics.ex
    - lib/oban_powertools/forensics/chronology.ex
    - lib/oban_powertools/forensics/evidence_bundle.ex
    - lib/oban_powertools/web/control_plane_presenter.ex
    - test/oban_powertools/forensics_test.exs
    - test/oban_powertools/forensics/evidence_bundle_test.exs
    - test/oban_powertools/web/operator_pattern_presenter_test.exs

key-decisions:
  - "Forensics.bundle/2 parses or revalidates Scope before repository resolution and returns only typed ok, unavailable, or safe error tuples."
  - "Workflow and incident evidence use Audit.forensic_window/2; Cron and limiter output retains only the newest eight source facts and reports unknown totals honestly."
  - "Audit chronology carries finite status and stable padded event identity while operator reasons and runbook continuity remain structurally absent."
  - "The presenter emits destinations only when a supported canonical local URL is present in caller-owned authorized_hrefs."

patterns-established:
  - "Closed evidence boundary: every nested collection is projected through finite keys and unknown structs are discarded."
  - "Independent forensic truth: diagnosis, event status, provenance, completeness, retention, and historical remediation remain separate."
  - "Authorized noun guidance: one primary native route, meaning/URL-deduplicated additions, and a separate optional Audit destination."

requirements-completed: ["PAGE-09", "DATA-*", "PAGE-10", "A11Y-*"]

duration: 24m
completed: 2026-07-28
status: complete
---

# Phase 80 Plan 06: Bounded Forensics Assembly and Closed Presenter Summary

**Four typed evidence families now assemble bounded provenance-aware histories and project one exact diagnosis-first, redaction-safe Forensics page map**

## Performance

- **Duration:** 24m
- **Started:** 2026-07-28T16:00:22Z
- **Completed:** 2026-07-28T16:23:52Z
- **Tasks:** 1
- **Files modified:** 7

## Accomplishments

- Refactored `Forensics.bundle/2` to parse or revalidate a typed scope before repository resolution, dispatch exactly one supported source, and return uniform typed success/unavailable/error results.
- Replaced workflow/incident post-load Audit filtering with `Audit.forensic_window/2`, including exact workflow coverage, incident has-more truth, 50-event output bounds, and stable Audit identities.
- Closed `EvidenceBundle` and `Chronology` over finite nested keys, newest-first deterministic ordering, finite source/status vocabularies, safe 1,000-character notes, and structural exclusion of unknown source structs.
- Preserved Workflow, Lifeline, Cron, and limiter evidence while exposing bounded per-source counts, limits, provenance, completeness, and retention statements.
- Added `ControlPlanePresenter.present_forensics/2` with exactly eight top-level fields, independent diagnosis/history truth, absolute-time events, neutral genuine repair history, exact authorized noun guidance, canonical URL/meaning deduplication, and a separate optional Audit destination.
- Added confidentiality sentinels across reasons, metadata, runbook context, errors, stacks, payloads, URLs, headers, tokens, and credentials; none survive the presenter boundary.

## Task Commits

Task 80-06-01 used one atomic red-green pair:

1. **RED: Add failing typed assembly, chronology, evidence closure, and presenter contracts** - `f91e51d`
2. **GREEN: Assemble bounded evidence and project the closed Forensics map** - `21a479b`

## Files Created/Modified

- `lib/oban_powertools/forensics.ex` - Typed four-family dispatch, bounded Audit integration, source coverage, finite statuses, and stable Audit chronology identities.
- `lib/oban_powertools/forensics/chronology.ex` - Exact chronology schema, deterministic newest-first ordering, finite vocabularies, structural note safety, and stable identities.
- `lib/oban_powertools/forensics/evidence_bundle.ex` - Closed subject/diagnosis/evidence/destination/completeness/coverage projection with unknown-struct exclusion.
- `lib/oban_powertools/web/control_plane_presenter.ex` - Exact eight-field diagnosis-first Forensics presentation, authorized noun guidance, events, remediation, and coverage.
- `test/oban_powertools/forensics_test.exs` - Typed result, zero-read invalid input, bounded query, exact coverage, chronology, and continuity redaction contracts.
- `test/oban_powertools/forensics/evidence_bundle_test.exs` - Exact nested bundle closure and coverage-source projection contracts.
- `test/oban_powertools/web/operator_pattern_presenter_test.exs` - Exact page map, redaction sentinels, authorized canonical links, remediation truth, and note-bound contracts.

## Decisions Made

- Revalidated supplied `%Forensics.Scope{}` values through canonical parameters so forged structs cannot bypass the parser or trigger a repository lookup.
- Kept incident `total_count` unknown while reporting `has_more?`, matching the bounded JSONB Audit predicate rather than inventing an exhaustive total.
- Removed Audit notes at chronology construction and retained only finite attempt status; operator reasons, actions, continuity maps, and metadata never enter the safe evidence record.
- Assigned Audit event identities with a padded durable database ID so events recorded in the same timestamp precision remain distinct and sort newest first.
- Deduplicated destinations both by canonical URL and noun meaning, returning only links independently approved through `authorized_hrefs`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test Correctness] Corrected a contradictory redaction assertion**

- **Found during:** Task 80-06-01 GREEN verification.
- **Issue:** The RED presenter test required the exact authorized Lifeline URL while also scanning the serialized page for that URL's selector-key text.
- **Fix:** Kept the exact authorized URL assertion and changed the redaction check to inspect returned map keys, which tests the intended absence of raw selector summaries without rejecting an approved destination.
- **Files modified:** `test/oban_powertools/web/operator_pattern_presenter_test.exs`
- **Verification:** The exact presenter contract and complete sentinel scan pass.
- **Committed in:** `21a479b`

---

**Total deviations:** 1 auto-fixed test-correctness issue.
**Impact on plan:** The correction aligns the assertion with the locked authorized-link contract; no product scope changed.

## Issues Encountered

- Two Lifeline repair Audit records can share second-level database timestamps. Initial generated chronology identity collapsed them; stable padded Audit IDs now preserve both and make the newer record deterministic.
- The shared checkout contained substantial unrelated dirty work and a known unrelated documentation-contract failure. Those files and failures were preserved and not modified or staged by this plan.

## User Setup Required

None. No migration, dependency, route, configuration, or external service change is required.

## Verification

- `mix test test/oban_powertools/audit_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/forensics/evidence_bundle_test.exs test/oban_powertools/web/operator_pattern_presenter_test.exs --seed 0` - 75 tests, 0 failures.
- Exact seven-file `mix format --check-formatted ...` command passed.
- `mix compile --warnings-as-errors` passed for production code.
- Invalid, mixed, arbitrary-job, and forged typed scopes assert zero source reads; well-formed missing scopes return one uniform unavailable result.
- The 55-event workflow contract exposes exactly 50 Audit chronology events, exact 55 total coverage, `has_more?: true`, and exactly two scoped Audit queries.
- Baseline-to-GREEN inspection contains exactly the seven declared plan implementation/test files; no LiveView, CSS, migration, index, dependency, route, schema, source, search, seventh selector key, or mutation was added.
- Both task commits pass `git show --check`.

## Next Phase Readiness

- Plan 80-07 can consume typed `Forensics.bundle/2` results and `ControlPlanePresenter.present_forensics/2` to build the production diagnosis-first LiveView.
- The presenter already fails closed without caller-owned `authorized_hrefs`; Plan 80-07 must supply only destinations that pass the parent LiveView's scope and authorization checks.
- Existing Forensics LiveView tuple handling and page composition intentionally remain for Plan 80-07.

## Self-Check: PASSED

- All seven declared implementation/test files exist and are committed.
- RED/GREEN commits `f91e51d` and `21a479b` exist and contain only declared Plan 80-06 files.
- The exact focused suite, exact formatting gate, production warnings-as-errors compile, query-bound assertions, and confidentiality sentinel scan pass.
- Workflow/incident assembly calls `Audit.forensic_window/2` and contains no `Audit.list_all/1`.
- Cron and limiter coverage retains limit eight with unknown totals rather than overclaiming exhaustive history.
- No `.planning/STATE.md` or `.planning/REQUIREMENTS.md` change was staged or committed.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-28*
