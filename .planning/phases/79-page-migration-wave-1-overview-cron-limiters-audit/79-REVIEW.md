---
status: issues_found
phase: 79-page-migration-wave-1-overview-cron-limiters-audit
depth: standard
files_reviewed: 43
findings:
  critical: 1
  warning: 3
  info: 1
  total: 5
reviewed_at: 2026-07-20T03:56:51Z
---

# Phase 79: Code Review Report

**Reviewed:** 2026-07-20T03:56:51Z  
**Depth:** standard  
**Files reviewed:** 43  
**Status:** issues_found

## Summary

Phase 79's bounded Audit queries, exact filter composition, Cron preview/execution authorization, read-only Limiter surface, page catalog, manifest generation, CSS source/static parity, and most connected-state contracts are well structured. The review nevertheless found one blocking confidentiality gap: an audit change can name a sensitive field inside the allowlisted `field` value and carry its secret through `before`/`after` into the rendered DOM. Three warnings affect the host fixture compile transition and the trustworthiness of one-overlay and recovery evidence. One inherited Overview copy issue remains visible but was not introduced by this phase.

Focused verification passed `mix compile --warnings-as-errors`, 160 Phase 79-related ExUnit tests, deterministic schema-7 manifest generation/smoke validation, exact CSS source/static equality, and the 228-page baseline inventory check. The direct opt-in host fixture test passed 5/5 only after `mix compile --force`; after the documented route-off run, the next route-on run failed 4/5 because the controller module was absent.

## Critical Issues

### CR-01: Allowlisted audit change values can disclose secrets in the DOM

**Files:** `lib/oban_powertools/web/audit_live.ex:329-342,379-399`; `lib/oban_powertools/web/control_plane_presenter.ex:95-107,1112-1164`; `lib/oban_powertools/web/components/operator_patterns.ex:786-796,964-980`

**Issue:** The confidentiality boundary validates map *keys* but not the semantics of allowlisted audit fields. `safe_audit_data/1` retains `field`, `before`, and `after`; `ensure_safe_presentation_data!/2` then checks only those literal keys. Consequently, `%{"field" => "password", "before" => "SYNTHETIC_OLD_SECRET", "after" => "SYNTHETIC_NEW_SECRET"}` passes both layers. `audit_evidence/1` serializes that map with `inspect/2`, and `audit_entry/1` renders it in the recorded-evidence code block.

This was reproduced directly against the compiled presenter: `present_audit_detail/2` returned the complete password change, including both synthetic secret values. Existing tests reject sensitive map keys such as `preview_token` and `credentials`, but do not cover sensitive identifiers stored under `field` or `label`. The generic structural checker predates Phase 79, but Phase 79 introduces the production Audit detail path that projects and renders this data, so the exposure is in the phase boundary.

**Impact:** A host or provider that records a conventional change tuple for a password, token, credential, or hash can expose the old and new values to any actor authorized to view Audit. This violates the structural-redaction and no-secret-in-DOM contract.

**Fix:** Make audit change/evidence normalization shape-aware. For `field`/`label` records, normalize and reject sensitive identifiers before retaining associated `before`/`after`/`value` data, or replace the entire record with an explicit redacted marker. Keep this enforcement in the presenter as the final boundary, and add presenter plus `AuditLive` DOM regression tests for snake-case, camel-case, and alias forms such as `password`, `accessToken`, `APIKey`, `plan_hash`, and `credential`.

## Warnings

### WR-01: Route-off compilation leaves the next route-on fixture build without its controller

**Files:** `examples/phoenix_host/test/support/phase79_browser_fixtures.ex:1,448-456`; `examples/phoenix_host/lib/phoenix_host_web/router.ex:4-6,36-43`

**Issue:** The entire fixture source is wrapped in the environment gate. Its `__mix_recompile__?/0` hook is defined inside the gated controller, so a route-off compilation removes the beam and also removes the only hook that could cause the file to be reevaluated when the flag returns to `1`. The router's unconditional hook recompiles the three routes, but not the controller source.

The documented transition was reproduced:

- a forced route-on compile followed by the route-on test passed 5/5;
- the route-off test then passed 1/1;
- the next ordinary route-on test recompiled only the router, warned that `Phase79BrowserFixturesController.init/1` was undefined, and failed 4/5 with `UndefinedFunctionError`.

The unique build path in `with-showcase-server.sh` masks this for fresh browser-server launches, but the direct automated contract and claimed back-to-back recompilation guarantee are not reliable.

**Impact:** A normal test build that last compiled with fixtures disabled can expose routes pointing at a missing controller, invalidating the route-on gate and making browser evidence depend on hidden build-cache state.

**Fix:** Put an unconditional recompile sentinel in this source file (outside the feature gate) so the file is reevaluated in both directions while the two fixture modules remain absent when disabled. Add a single automated route-on -> route-off -> route-on test sequence without `--force` or a fresh build path.

### WR-02: The server does not enforce the Showcase's one-overlay invariant

**Files:** `lib/oban_powertools/web/dev/showcase_live.ex:158-166,522-603`; `test/browser/support/showcase.ts:88-105,134-153,213-231`

**Issue:** Activating a page story assigns `active_page_story` without clearing `active_group_overlay`; activating a group story likewise does not clear an active page story. Both sections render independently. A group confirmation/detail can therefore remain open while a page confirmation/detail is activated, producing two dialogs or modal surfaces.

The shared browser helper closes the group overlay at lines 97 and 213-231 *before* it dispatches the page activation, then asserts the one-overlay bound. That client-side cleanup hides the invalid server transition rather than proving it. The LiveView tests activate page stories from a clean state and do not cover group-to-page or page-to-group transitions.

**Impact:** The Showcase can violate its own one-tree/one-overlay accessibility contract through valid server events, while structure/a11y/VRT evidence remains green because the helper repairs the state first.

**Fix:** Make both activation handlers atomically clear the other active story/overlay and any associated transient state. Add LiveView regressions for group overlay -> page confirmation and page detail -> group overlay, asserting no more than one rendered dialog/modal without helper cleanup. The browser helper should verify the precondition or call only the activation event, not repair server state.

### WR-03: “Skipped” and “partial” browser recoveries are the same backend condition

**Files:** `examples/phoenix_host/test/support/phase79_browser_fixtures.ex:342-383`; `test/browser/specs/phase79-fixtures.spec.ts:12-25,96-130`; `test/browser/specs/page-migration-wave-1.spec.ts:548-592`; `lib/oban_powertools/web/cron_live.ex:530-546,585-591`

**Issue:** `prepare_recovery/3` handles `"skipped"` and `"partial"` in one identical branch: each inserts one active job so the single Cron slot claim is skipped. Production maps that skipped result to the generic confirmation state `:partial`. The fixture spec then labels the same UI state as two recoveries; the page-migration assertion is additionally permissive enough for the `partial` case to match `skipped` copy.

**Impact:** The browser ledger claims five distinct real-preview recovery outcomes, but it proves only four domain conditions. In particular, it does not demonstrate a real mixed/partial result.

**Fix:** Either construct a genuinely distinct partial backend outcome and assert its exact result composition, or collapse the fixture/ledger/story language to the truthful four conditions and treat `:partial` as the UI container used for a skipped single result. Avoid matchers that allow `partial` evidence to pass solely on `skipped` text.

## Informational / Pre-existing Debt

### IR-01: Overview still renders raw bridge blocker codes

**Files:** `lib/oban_powertools/web/overview_read_model.ex:209-219`; `lib/oban_powertools/web/engine_overview_live.ex:178-184,225-226`

`bridge_rows/2` uses the first `blocker_codes` value as the exemplar `fact`, and the Overview renderer prints that fact when no `attention_reason` exists. A normal `limit_reached` explain therefore displays the raw classifier value even though the Phase 79 tests only refute the literal key name `blocker_codes`. This path existed before Phase 79 and the old Overview renderer also displayed it, so it is recorded as inherited debt rather than a phase-introduced warning. It still conflicts with the locked “no internal classifier values” copy decision; a finite human-label mapping should replace the raw value, with a regression that rejects representative code *values* rather than only source key names.

## Reviewed Scope

All 43 authoritative paths from `/tmp/phase79-review-files.txt` were reviewed, spanning the four production pages/read models/presenter/components, fixture host/router/launcher, deterministic page catalog and Showcase adapter, schema-7 manifest validators, connected browser suites, CSS source/static copies, and their ExUnit contracts.

Intent and acceptance were checked against all Phase 79 summaries, `79-CONTEXT.md`, `79-UI-SPEC.md`, `79-VALIDATION.md`, `.planning/PROJECT.md`, and the Phase 78 canonical review format.

## Verification Evidence

- `mix compile --warnings-as-errors` — PASS.
- Focused Phase 79 ExUnit suite — PASS, 160 tests, 0 failures.
- Audit redaction probe — FAIL as expected; sensitive `field/before/after` values survived unchanged.
- `npm run showcase:manifest` + `manifest-smoke.mjs` — PASS; schema 7, 19 page stories, 83 targets, 4 themes, 3 viewports; manifest SHA unchanged.
- `verify-page-baselines.mjs` — PASS; 228 page baselines.
- CSS source/static `cmp` and SHA-256 — PASS, byte-identical.
- Host fixture forced route-on — PASS, 5/5.
- Host route-off -> ordinary route-on transition — route-off PASS 1/1; route-on FAIL 4/5 with missing controller.
- `git diff --check` across the authoritative phase scope — PASS.

The full 228-case connected axe/VRT matrix was not rerun during this standard-depth review; the deterministic manifest/baseline gates and focused connected evidence were inspected instead. The phase's explicitly pending human contrast, 200% zoom/reflow, keyboard/focus, and reduced-motion reviews remain validation work, not code-review findings.

## Intentional Test-only Boundaries (not findings)

- The fixture endpoints are compile-time/test-environment gated, use constant-time secret comparison, return indistinguishable empty 404 responses on denial, and expose only closed public fixture state.
- Confidentiality sentinels returned by the fixture state are synthetic test values used for DOM scanning, not production secrets.
- The inherited Credo, Dialyzer, and non-page VRT debt recorded in Phase 79 validation was not reclassified as Phase 79 code-review debt.

---

_Reviewer: Codex (gsd-code-reviewer)_  
_Depth: standard_
