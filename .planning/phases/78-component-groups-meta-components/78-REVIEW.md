---
phase: 78-component-groups-meta-components
reviewed: 2026-07-19T01:54:57Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - assets/oban_powertools/theme.js
  - assets/oban_powertools/tokens.css
  - lib/oban_powertools/web/components/data_display.ex
  - lib/oban_powertools/web/components/operator_patterns.ex
  - lib/oban_powertools/web/control_plane_presenter.ex
  - lib/oban_powertools/web/dev/showcase_live.ex
  - lib/oban_powertools/web/status_taxonomy.ex
  - priv/static/oban_powertools/oban_powertools.css
  - priv/static/oban_powertools/oban_powertools.js
  - scripts/showcase_manifest.exs
  - test/browser/specs/operator-patterns.behavior.spec.ts
  - test/browser/specs/showcase.a11y.spec.ts
  - test/browser/specs/showcase.structure.spec.ts
  - test/browser/specs/showcase.vrt.spec.ts
  - test/browser/support/manifest-smoke.mjs
  - test/browser/support/manifest.ts
  - test/browser/support/showcase.ts
  - test/browser/support/verify-group-baselines.mjs
  - test/oban_powertools/hex_release_test.exs
  - test/oban_powertools/operator_pattern_story_catalog_test.exs
  - test/oban_powertools/web/assets_test.exs
  - test/oban_powertools/web/components/operator_patterns_test.exs
  - test/oban_powertools/web/live/operator_patterns_harness_test.exs
  - test/oban_powertools/web/live/showcase_live_test.exs
  - test/oban_powertools/web/operator_pattern_presenter_test.exs
  - test/oban_powertools/web/theme_tokens_test.exs
  - test/support/operator_pattern_story_catalog.ex
findings:
  critical: 1
  warning: 3
  info: 0
  total: 4
status: issues_found
---

# Phase 78: Code Review Report

**Reviewed:** 2026-07-19T01:54:57Z
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

The Phase 78 component, presenter, client behavior, showcase, manifest, and test changes were reviewed at standard depth. One confidentiality blocker allows sensitive audit evidence through the purported presentation-data safety boundary. Three additional correctness issues weaken accepted-action semantics and make the showcase's status/severity evidence materially less representative than its catalog and test names claim.

The generated CSS and JavaScript copies are byte-identical to their source assets.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Audit evidence safety filter accepts common secret fields and then renders them

**File:** `lib/oban_powertools/web/control_plane_presenter.ex:485-497`
**Related:** `lib/oban_powertools/web/components/operator_patterns.ex:955-969`

**Issue:** `ensure_safe_presentation_data!/2` rejects only case-sensitive keys ending in `_token`, `_hash`, or `_error`. Exact keys such as `token`, `hash`, and `error`, camelCase keys such as `previewToken`, and common credential keys such as `authorization`, `password`, or `secret` pass. Unlike the other normalizers, `normalize_audit_entry/1` retains `changes` and `evidence`; `audit_evidence/1` subsequently calls `inspect/2` on those values and renders the result. A synthetic call with `%{changes: %{token: "SYNTHETIC_SECRET"}, evidence: %{authorization: "Bearer SYNTHETIC_SECRET"}}` returns both secrets unchanged. Existing tests cover only underscore-suffixed examples, while their sentinel-absence checks never supply those sentinels to this path.

This violates the component's confidentiality boundary and can disclose credentials in progressive audit evidence.

**Fix:** Normalize keys case-insensitively to a canonical form and reject a closed set of credential/error names and suffixes, including exact and camelCase variants. Prefer accepting a dedicated already-redacted evidence type or an allowlisted presentation schema instead of recursively accepting arbitrary maps. Add render-level regression tests that inject synthetic `token`, `authorization`, `password`, camelCase token/hash, and raw-error-string values and prove they are rejected before reaching `audit_evidence/1`.

## Warnings

### WR-01: Submitting confirmations remain dismissible by default

**File:** `lib/oban_powertools/web/components/operator_patterns.ex:814-818`

**Issue:** `confirmation_dismissible?/2` ignores the lifecycle state. Because `dismissible` defaults to `true`, rendering `state: :submitting` without an explicit override includes the Escape handler and visible safe-dismiss action, while omitting the required “accepted and can no longer be canceled” copy. The component therefore permits callers to accidentally hide accepted in-flight work and imply that Escape cancels it. The current showcase and harness avoid the defect only by remembering to pass `dismissible: false` themselves.

**Fix:** Enforce the accepted-state invariant in the component, for example with `confirmation_dismissible?(:submitting, _caller_value), do: false`, and test `:submitting` with the default attrs. If a separately cancelable pre-acceptance state is needed, model it as a distinct lifecycle value rather than overloading `:submitting`.

### WR-02: Audit outcome matrix discards its finite outcome state and renders failures as neutral

**File:** `lib/oban_powertools/web/components/operator_patterns.ex:761-776`
**Related:** `test/support/operator_pattern_story_catalog.ex:116-129,523-528`

**Issue:** The catalog supplies `outcome_state` values of `:success`, `:failed`, and `:skipped`, but `normalize_audit_entry/1` discards that field and `audit_entry/1` passes the human sentence fragment `@entry.outcome` to the finite `operator_result` taxonomy. Values such as `"Request failed"` are unknown taxonomy states, so they render with a neutral dot/tone rather than the danger/alert semantics defined for `:failed`; skipped and success outcomes have the same problem. The behavior test asserts only the human label, so it blesses the neutral fallback and never checks tone or icon.

**Fix:** Carry a closed `outcome_state` separately from the human outcome text, use that state for the operator-result status semantics, and keep the human outcome in the facts list (or deliberately override only the pill label while retaining the finite state's tone/icon). Extend the matrix test to assert the success/failed/skipped programmatic state, icon, and tone.

### WR-03: Attention “matrix” story renders only one base card and hides an invalid fixture row

**File:** `lib/oban_powertools/web/dev/showcase_live.ex:1190-1220`
**Related:** `test/support/operator_pattern_story_catalog.ex:424-439`

**Issue:** `group-attention-status-severity-matrix` carries four matrix entries, but `group_story_body/1` calls `group_attention_story/1` once with the unexpanded base fixture. The visual, axe, and behavior suites therefore cover only the base retryable/warning/complete card despite the story's matrix name and declared states. The hidden fourth row also uses `severity: :success`, which is outside the production AttentionCard contract (`neutral | info | warning | danger`) and would fail if the showcase actually rendered the matrix.

**Fix:** Add an attention-entry expansion helper analogous to `group_audit_entries/1`, render every matrix row with unique ids, and replace `:success` with a valid attention-priority value (or explicitly extend the production contract if success is truly intended). Update connected tests to require all matrix rows and their distinct status/severity/completeness semantics.

---

_Reviewed: 2026-07-19T01:54:57Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
