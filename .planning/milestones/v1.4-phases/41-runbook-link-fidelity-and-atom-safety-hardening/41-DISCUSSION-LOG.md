# Phase 41: Runbook Link Fidelity and Atom Safety Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 41-runbook-link-fidelity-and-atom-safety-hardening
**Areas discussed:** Plans-exist disposition, WR-02 atom scope, Selector encoding shape, Plan structure, Bounded atom strategy, preview_token cleanup, target_type helper shape

---

## Plans-Exist Disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Continue and replan after | Capture CONTEXT.md now, then re-run plan-phase so the plan reflects decisions | ✓ |
| View existing plans | Pause and review 41-01-PLAN.md before deciding | |
| Cancel | Exit without writing CONTEXT.md | |

**User's choice:** Continue and replan after.
**Notes:** Existing 41-01-PLAN.md was created without user context; ROADMAP envisioned three plans but only one was generated. Replan after CONTEXT.md is canonical.

---

## WR-02 Atom Remediation Scope

| Option | Description | Selected |
|--------|-------------|----------|
| All 5 sites | Harden every String.to_atom/1 call in the four target files; advisory debt → zero with no rg-check carve-outs | ✓ |
| Unbounded-input sites only | Harden only the 3 caller-controlled sites; leave 3 internal-enum target_type sites alone | |
| Defer to research | Have researcher analyze each callgraph and recommend scope | |

**User's choice:** All 5 sites (recommended).
**Notes:** Codebase scout found 5 String.to_atom sites + 1 obfuscated to_existing_atom; the "all sites" answer maps onto the expanded 6-site list documented in CONTEXT D-06 / D-08.

---

## Selector Encoding Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Centralize into Selectors helper | New helper module owns canonical incident_fingerprint / resource_type / resource_id / workflow_id / step / view encoding; existing callsites route through it | ✓ |
| Keep callsite URI.encode_query | Leave existing safe callsites alone, just add delimiter-heavy regression tests | |

**User's choice:** Centralize into Selectors helper (recommended).
**Notes:** Matches Phase 34 D-22 / D-24 read-model centralization posture. One place to harden, one place to test.

---

## Plan Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Keep one bundled plan | Replan 41-01 to reflect decisions; execute as single atomic PR | ✓ |
| Split into 41-01 / 41-02 / 41-03 | Reorganize to match ROADMAP's three-plan layout | |

**User's choice:** Keep one bundled plan (recommended).
**Notes:** Selectors / atoms / proof are tightly coupled; tests only make sense after helpers exist. ROADMAP's three-plan count is loose guidance and may be updated after replan.

---

## Bounded Atom Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| String.to_existing_atom + whitelist guard | Centralize a normalization helper using to_existing_atom with binary fallback; documented allowed-key list | ✓ |
| Pure whitelist map (no atom conversion) | Drop dynamic atom conversion entirely; use Map.new + explicit lookup tables keyed on binaries | |
| Mixed — status uses to_existing_atom, related_evidence keys stay binary | Different strategies per site, matched to actual call shapes | |

**User's choice:** String.to_existing_atom + whitelist guard (recommended).
**Notes:** Idiomatic Elixir, no atom-table growth, preserves backward compat for known keys, leaves unknown keys as binaries (matches Phase 34 D-09 partial-evidence posture). Each callsite receives the helper appropriate to its call shape (CONTEXT D-09 through D-13).

---

## preview_token Obfuscation Site

| Option | Description | Selected |
|--------|-------------|----------|
| Replace with the atom literal :preview_token | Simplest, removes the only non-target rg hit, no behavior change | ✓ |
| Leave it alone | Out of scope for WR-02 since it's String.to_existing_atom; add a verification carve-out | |
| Leave it but add a code comment | Keep current form, document why it exists | |

**User's choice:** Replace with :preview_token literal (recommended).
**Notes:** Keeps the WR-02 verification rg-check free of carve-outs (CONTEXT D-08, D-23).

---

## target_type Helper Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Shared TargetType helper with explicit case | New ObanPowertools.Lifeline.TargetType module with explicit case on the four known strings; unknown raises | ✓ |
| Inline String.to_existing_atom + guard per site | Each callsite uses to_existing_atom with try/rescue or guard | |
| Type the field as atom upstream | Change RepairPreview / action_info to store target_type as atom from the start | |

**User's choice:** Shared TargetType helper (recommended).
**Notes:** Centralizes the closed enum, matches D-22 read-model centralization posture, deterministic, easy to test. Unknown inputs raise FunctionClauseError (CONTEXT D-12) — caller-trusted-internal code; unknown target_type is a programming bug, not an operator-visible case.

---

## Claude's Discretion

- Exact module names and namespaces for the new Selectors and TargetType helpers, provided they're testable and live under appropriate namespaces (CONTEXT discretion note).
- Inline vs extracted-module shape for the related_evidence normalization helper, provided D-11 (known-key list + unknown → binary) is preserved.
- Delimiter-heavy fixture composition beyond the documented minimum set, provided round-trip decode is asserted at the LiveView boundary.

## Deferred Ideas

- Project-wide `Atoms` umbrella module — over-couples unrelated normalization concerns.
- Ecto.Enum schema-level atom typing for target_type — bigger diff than a hardening phase warrants.
- Opaque-token selectors (signed fingerprints) — semantic change to public selector contract.
- Repo-wide atom conversion sweep beyond the four target files — Phase 42 / later hygiene work.
- Public host-facing automation/runbook DSL — out of scope per Phase 34 deferred list.
