# Phase 31 Discussion Log

**Date:** 2026-05-26
**Mode:** Discuss phase with repo-local research and advisor-style subagent synthesis
**Status:** Complete

## Prompted Areas

1. Docs story scope
2. Verification closure bar
3. Milestone closeout posture

## Research Inputs

- Project authority:
  `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`
- Prior controlling context:
  `15-CONTEXT.md`, `24-CONTEXT.md`, `25-CONTEXT.md`, `26-CONTEXT.md`, `27-CONTEXT.md`, `28-CONTEXT.md`, `29-CONTEXT.md`, `30-CONTEXT.md`
- Public docs and fixtures:
  `README.md`, `guides/support-truth-and-ownership-boundaries.md`, `guides/optional-oban-web-bridge.md`, `guides/example-app-walkthrough.md`, `examples/phoenix_host/README.md`
- Proof surfaces:
  `test/oban_powertools/docs_contract_test.exs`, `test/oban_powertools/example_host_contract_test.exs`, `test/oban_powertools/web/live/engine_overview_live_test.exs`, `test/oban_powertools/web/live/control_plane_copy_coherence_test.exs`, `test/oban_powertools/web/live/audit_live_test.exs`, `.github/workflows/host-contract-proof.yml`
- Product/research prompts:
  `prompts/oban_powertools_context.md`, `prompts/oban_powertools_ultimate_ui_strategy_brief.md`, `prompts/oban-powertools-deep-research-original-prompt.md`

## User Preference Captured

- Research first.
- Use subagents/advisor-style narrowing where helpful.
- Prefer one cohesive recommendation set.
- Ask only on unusually high-impact unresolved architectural forks.
- Shift this behavior left into repo-level GSD defaults where possible.

## Repo-Level Preference Action Taken

- Updated `.planning/config.json`:
  - `preferences.vendor_philosophy = "thorough-evaluator"`
  - `workflow.research_before_questions = true`

## Area Synthesis

### 1. Docs story scope

Options considered:
- top-level copy refresh only
- realign every promise-shaping public entrypoint
- full guide sweep across all public docs

Recommendation:
- Realign every promise-shaping public entrypoint, but do not run a repo-wide editorial sweep.

Why:
- Best matches `DOC-04` and `HST-04`
- Keeps README, support-truth, bridge, example-host, and closeout artifacts coherent
- Avoids partial support-truth drift without widening into generic docs churn

### 2. Verification closure bar

Options considered:
- deepen existing hermetic proof lanes only
- deepen existing lanes plus one narrow operator-journey smoke proof
- add broad browser-E2E proof family
- add snapshot/copy-matrix proof families

Recommendation:
- Deepen the existing hermetic lanes and keep assertions contract-focused.
- A single bounded end-to-end smoke proof is acceptable only if it stays additive and does not become a second proof universe.

Why:
- Best fit for Phoenix LiveView, Oban Web, and current repo proof architecture
- Lowest surprise and best CI cost profile
- Strongest alignment with host-owned route/auth/display seams and audit-follow-up truth

### 3. Milestone closeout posture

Options considered:
- narrow archival / traceability closeout
- narrow closeout plus bounded maintainer retro memo
- broad retrospective / roadmap reshaping

Recommendation:
- Keep `31-03` narrow: archive v1.3 with explicit closure evidence, concise learnings, and clearly deferred future wedges.

Why:
- Best matches the repo’s repair/closeout precedent
- Prevents roadmap churn and generic-dashboard scope reopen
- Preserves canonical ownership and additive chronology

## Final Locked Recommendation Set

- Align all promise-shaping docs and example-host surfaces to one native-shell versus bridge-only story.
- Close proof using the existing docs-contract, example-host, workflow, and focused LiveView lanes rather than adding a new browser or snapshot-heavy proof family.
- Finish the milestone with a narrow archival closeout that records closure and future wedges without redesigning the roadmap.

## Escalation Check

No unresolved major architectural fork remained after research.
No additional user decision was required before writing `31-CONTEXT.md`.
