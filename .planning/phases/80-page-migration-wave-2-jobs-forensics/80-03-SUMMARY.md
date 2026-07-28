---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 03
subsystem: ui
tags: [phoenix-liveview, jobs, lifeline, confirmation, redaction, accessibility]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 02
    provides: Closed Jobs presenters, canonical list context, and read-only adaptive quick review
provides:
  - Closed bounded full-job detail, action, and action-result presenter contracts
  - Canonical incident-first job detail with allowlisted return context and uniform unavailable truth
  - Shared Lifeline-backed retry, cancel, and discard confirmation with explicit recovery
affects: [80-04, jobs, lifeline, audit, forensics]

tech-stack:
  added: []
  patterns:
    - Opaque Lifeline preview identity stays in LiveView socket private state rather than render assigns
    - Canonical detail receives only finite presenter, policy-display, action-control, confirmation, and receipt maps
    - Every single-job preview and execute reauthorizes page, action, current job truth, service permission, and durable principal

key-files:
  created: []
  modified:
    - lib/oban_powertools/web/control_plane_presenter.ex
    - lib/oban_powertools/web/jobs_live.ex
    - test/oban_powertools/web/operator_pattern_presenter_test.exs
    - test/oban_powertools/web/live/jobs_live_test.exs

key-decisions:
  - "The full detail contract exposes exactly support, actions, identity, timing, errors, data, redaction, and authorized destinations; raw Jobs, exceptions, payloads, and arbitrary evidence never enter shared composition."
  - "Only seven allowlisted Jobs list parameters survive into Back to Jobs; opaque return_to, review job, and unknown parameters are discarded."
  - "Preview tokens remain in LiveView socket private state, while the shared confirmation receives only the finite presenter action, form, result, and recovery truth."
  - "Any non-success result clears the private execution capability and disables server-side replay until the operator explicitly creates a fresh preview."

patterns-established:
  - "Bounded failure evidence: newest ten attempts only, with safe class/message/time/attempt fields and a visible 1,000-grapheme truncation contract."
  - "Uniform detail denial: malformed, missing, and unauthorized IDs render the same heading, body, Back to Jobs action, and no policy/existence detail."
  - "Authoritative mutation lifecycle: exact success closes and reloads current truth; expired, drifted, consumed, skipped, and failed remain explicit recovery states."

requirements-completed: ["PAGE-02", "DATA-*", "PAGE-10", "A11Y-*"]

duration: 1h20m
completed: 2026-07-28
status: complete
---

# Phase 80 Plan 03: Canonical Jobs Detail and Lifeline Actions Summary

**One ordered, redaction-safe canonical job detail with deterministic return context and shared Lifeline confirmation for retry, cancel, and discard**

## Performance

- **Duration:** 1h20m
- **Started:** 2026-07-28T12:17:49Z
- **Completed:** 2026-07-28T13:37:49Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added finite full-detail, single-action, and action-result presenters with exact action copy, newest-ten error bounds, 1,000-grapheme safe truncation, structural redaction, policy-safe recorded-output facts, and authorized local destinations.
- Replaced the legacy full-detail cards and raw payload/error rendering with a pure `page_content/1` detail branch ordered as current truth, legal actions, identity/timing, errors, redacted data, and related evidence.
- Reconstructed Back to Jobs from the seven allowlisted list parameters and made malformed, missing, and unauthorized IDs render one byte-equivalent unavailable state.
- Migrated retry, cancel, and discard to the shared confirmation component and real `Lifeline.preview_repair/4` plus `execute_repair/5`, with exact reason validation, current-principal reauthorization, Audit-linked receipts, finite recovery states, and server-side replay prevention.

## Task Commits

Each task used an atomic red-green pair:

1. **Task 80-03-01: Build the closed full-detail and action presentation contract**
   - `3e13856` — failing full-detail and action presenter contracts
   - `bcbbda3` — bounded detail, action, and result presenters
2. **Task 80-03-02: Compose canonical full job detail with deterministic return context**
   - `ca322ad` — failing canonical detail composition contracts
   - `6a2f082` — incident-first redacted canonical detail
3. **Task 80-03-03: Migrate single-target actions to shared Lifeline confirmation**
   - `99c3760` — failing shared action lifecycle contracts
   - `4ce9aa8` — shared Lifeline confirmation and recovery lifecycle

## Files Created/Modified

- `lib/oban_powertools/web/control_plane_presenter.ex` - Closed job detail, action, and finite action-result presentation contracts.
- `lib/oban_powertools/web/jobs_live.ex` - Canonical detail composition, per-action authorization, socket-private preview authority, shared confirmation, receipts, and recovery.
- `test/oban_powertools/web/operator_pattern_presenter_test.exs` - Exact keys/copy, bounded errors, hostile-data redaction, destination, and closed-result coverage.
- `test/oban_powertools/web/live/jobs_live_test.exs` - Pure hierarchy, canonical navigation, uniform unavailable, sensitive-sentinel, all-action authorization, success, stale, failure, and replay coverage.

## Decisions Made

- Kept only the preview token in namespaced LiveView socket private state. Plan hashes, preview metadata, and raw Lifeline action values never enter render or presenter-facing assigns.
- Derived action controls server-side from the finite presenter plus independent retry/cancel/discard, preview, and execute permissions; every event still repeats authorization against current job truth.
- Preserved safe trimmed reason drafts through recovery while removing the private preview capability after every non-success, so forged LiveView events cannot silently replay a stale or failed action.
- Exposed only authorized Audit as related evidence because no supported job-to-Forensics relationship exists; arbitrary job IDs never manufacture Forensics destinations.

## Deviations from Plan

### Auto-fixed Issues

- **Closed a forged bulk-preview input while editing the shared event boundary.** The existing bulk preview action attribute was unused; the handler now applies that existing retry/cancel/discard allowlist and ignores unknown values.
- **Strengthened stale/failure replay prevention beyond hiding the form.** Non-success paths clear socket-private preview authority and the execute handler rejects every state except `preview`, with forged-event regression coverage.

No scope-expanding schema, route, dependency, mutation API, asset, or Forensics behavior was added.

## Issues Encountered

- This installation does not include an Ecto changeset `Phoenix.HTML.FormData` implementation. The confirmation form therefore uses the supported map form with explicit finite field errors, preserving the exact `Enter at least 8 characters.` contract.
- LiveView synchronous events do not publish an intermediate server render during execution; the shared component's standard `phx-disable-with` and disabled submitting semantics provide duplicate-submit protection without client-owned authority.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/oban_powertools/web/operator_pattern_presenter_test.exs test/oban_powertools/web/live/jobs_live_test.exs --seed 0` - 72 tests, 0 failures.
- `mix test test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/lifeline_test.exs --seed 0` - 69 tests, 0 failures.
- `mix test test/oban_powertools/web/components/data_display_test.exs test/oban_powertools/web/components/operator_patterns_test.exs --seed 0` - 47 tests, 0 failures.
- `mix compile --warnings-as-errors` passed.
- Plan formatting checks, `git diff --check`, direct-Oban-mutation scans, and sensitive execution-field DOM assertions passed.
- The implementation diff from the Plan 80-02 checkpoint contains exactly the four declared production/test paths.

## Next Phase Readiness

- Plan 80-04 can reuse the closed action/result presentation vocabulary and shared recovery semantics while adding bounded bulk scope, progress, and partial-result truth.
- Canonical job detail, deterministic return context, real Lifeline authority, and Audit recovery evidence are complete with no migration or host setup dependency.

## Self-Check: PASSED

- All four declared implementation/test files exist and are committed.
- Red/green task commits `3e13856`, `bcbbda3`, `ca322ad`, `6a2f082`, `99c3760`, and `4ce9aa8` exist.
- Every plan verification command passes.
- No raw action value, preview token, plan hash, internal error, sensitive reason sentinel, direct Oban mutation, or unsupported Forensics destination appears in rendered detail HTML.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-28*
