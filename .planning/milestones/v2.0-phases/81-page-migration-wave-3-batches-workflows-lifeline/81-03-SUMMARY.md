---
phase: 81-page-migration-wave-3-batches-workflows-lifeline
plan: 03
subsystem: web
tags: [elixir, phoenix-liveview, workflows, security, accessibility]
requires:
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 01
    provides: RED finite presenter, selector, and page-composition contracts
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 07
    provides: isolated secret-gated Wave 3 connected fixtures
provides:
  - closed canonical Workflows list, detail, and selected-step URLs
  - closed finite workflow, detail, step, result, and destination presentation maps
  - bounded repository-side workflow, step, result, and dependency-evidence reads
  - one pure semantic production composition with shared data and blocked-state patterns
affects: [81-04, 81-05, 81-06, 81-08, page-quality]
tech-stack:
  added: []
  patterns:
    - parse and authorize workflow identity before safe lookup
    - consume LIMIT plus one and expose incomplete evidence explicitly
    - keep diagnosis and dependency ordering separate from causal claims
key-files:
  created: []
  modified:
    - lib/oban_powertools/web/selectors.ex
    - lib/oban_powertools/web/control_plane_presenter.ex
    - lib/oban_powertools/web/workflows_live.ex
key-decisions:
  - "Workflows accepts only the existing step selector on detail URLs; action and preview authority never enter workflow URL state."
  - "Malformed, missing, and unauthorized workflow identities use one non-enumerating unavailable branch."
  - "The first 100 steps remain one semantic ordered list, while status, diagnosis, blocker evidence, and visual order stay independent."
  - "Recovery remains diagnosis-only and always hands off to Lifeline without local mutation controls."
requirements-completed: [PAGE-04]
duration: 13min
completed: 2026-07-29
status: complete
---

# Phase 81 Plan 03: Workflows Migration Summary

**Workflows now provides bounded, authorization-safe diagnosis through canonical deep links, closed presentation maps, and one semantic read-only production composition.**

## Accomplishments

- Added canonical Workflows list/detail selectors with deterministic ordering, encoded path segments, and a closed selected-step query contract.
- Replaced Wave 3 placeholder projections with exact workflow row, detail, step, selected-step, result, completeness, and authorized-destination maps that structurally exclude raw workflow inputs, context, metadata, and mutation authority.
- Replaced raising and unbounded reads with UUID parsing, resource authorization, safe lookup, and repository-side `51/101/51/26` windows for workflows, steps, results, and dependency evidence.
- Rebuilt the page around shared DataTable, DescriptionList, StatusTaxonomy, and WhyBlocked composition while preserving direct-load, patch, reload, PubSub selection, forensic entry, Oban Web bridge, result redaction, refusal vocabulary, and Lifeline handoff behavior.
- Added explicit partial-evidence copy and a uniform `Workflow unavailable` branch that never echoes forged identity.

## Task Commits

1. **Task 81-03-01: Close workflow selectors and presentation contracts** — `5e0ca51`
2. **Task 81-03-02: Rebuild Workflows as a semantic read-only shared page** — `a03d92d`

## Verification

- Focused Workflows, selector, and presenter suite: **62 tests, 0 failures**
- Production compile with warnings as errors: **passed**
- Connected production Workflows contracts on `chromium-wide`: **2 tests passed**
  - 100-step bounded semantic list, Why blocked region, read-only Lifeline handoff, reload/deep-link preservation
  - malformed/missing resource uniform unavailable behavior without identity reflection
- Exact scoped formatting and `git diff --check`: **passed**

## Deviations from Plan

### Auto-fixed

**1. Preserved legacy permissive Lifeline selector compatibility while closing execute authority**

- Existing callers rely on ordered non-canonical Lifeline keys. The new Workflows boundary therefore drops the forbidden `action=execute` value while preserving established ordered selector compatibility.
- Batch selector compatibility likewise retains existing non-authority context while excluding action and preview-token keys.

**2. Added a diagnosis-only Lifeline fallback**

- Saturated fixtures can select a retained step without an executable action. Workflows still needs a legal recovery venue, so the page now offers a workflow/step-scoped Lifeline review link without inventing action authority.

## Issues Encountered

- The first connected invocation bypassed the required fixture launcher and correctly failed closed because no Phase 81 fixture secret was present. The authoritative secret-generating launcher was used for all subsequent evidence.
- Connected acceptance exposed stable semantic hooks expected by the quality graph (`#workflow-steps`, `Why blocked?`, and the recovery-link accessible name); these were aligned with the production composition.
- Dependency resolution reported pre-existing security advisories in locked example-host packages. No dependency or lockfile change was made by this plan.

## Security and Threat Review

- Malformed IDs perform no detail lookup; missing and unauthorized IDs render the same unavailable branch.
- All primary collections are finite at the repository boundary and separately capped for rendering.
- Result payload presentation remains behind DisplayPolicy, and raw workflow input/context never enters generic page composition.
- Workflows exposes no execute, retry, cancel, preview-token, or plan-hash authority.
- DAG order is an ordered reading aid only; current state, diagnosis, blockers, and recovery venue remain explicitly separate.

## Self-Check: PASSED

- Both task commits exist and contain only plan-scoped implementation files.
- The summary records focused, compile, connected, and formatting evidence.
- No unrelated dirty worktree files were staged or committed.

---
*Phase: 81-page-migration-wave-3-batches-workflows-lifeline*
*Completed: 2026-07-29*
