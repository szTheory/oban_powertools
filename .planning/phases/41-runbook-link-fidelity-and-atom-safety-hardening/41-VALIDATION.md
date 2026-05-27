---
phase: 41
slug: runbook-link-fidelity-and-atom-safety-hardening
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
updated: 2026-05-27
---

# Phase 41 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from RESEARCH.md `## Validation Architecture` (2026-05-27).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19 stdlib) + Phoenix.LiveViewTest 1.1.30 + Ecto.Adapters.SQL.Sandbox |
| **Config file** | `test/test_helper.exs` (migration boot + sandbox mode) |
| **Quick run command** | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs --seed 0` |
| **Full suite command** | `mix test --seed 0` |
| **Estimated runtime** | quick ~15s; full ~60s (existing repo baseline; not re-measured) |

---

## Sampling Rate

- **After every task commit:** Run `mix test <most-recently-edited-file> --seed 0`
- **After every plan wave:** Run the quick command above (three LiveView suites + the new helper unit tests)
- **Before `/gsd:verify-work`:** Full suite must be green AND both rg-checks produce expected results
- **Max feedback latency:** ~15 seconds (quick command); ~60 seconds (full suite)

---

## Per-Task Verification Map

> Task IDs follow the convention `41-01-<task-N>` once the planner emits PLAN.md.

| Req ID | Behavior | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|------------|-----------------|-----------|-------------------|-------------|--------|
| OPS-03 | Overview attention links survive delimiter-heavy fingerprints (Selectors round-trip from overview surface) | T-WR-01 | URI-encoded selectors decode back to identity | LiveView integration | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs --seed 0` | ✅ extends existing | ⬜ pending |
| RNB-01 | Forensic / runbook entry surfaces resolve delimiter-heavy fingerprints to the correct incident | T-WR-01 | Encoded selector decodes and locates correct incident row | LiveView integration | `mix test test/oban_powertools/web/live/forensics_live_test.exs --seed 0` | ✅ extends existing | ⬜ pending |
| RNB-02 | Audit subject `%{type: atom, id: string}` shape preserved across all three target_type sites under refactor | T-WR-02 | TargetType helper produces atom from closed enum; unknown values raise | LiveView integration + unit | `mix test test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/lifeline_test.exs --seed 0` | ✅ extends existing | ⬜ pending |
| WR-01 | Selectors encoder produces correct query strings for delimiter-heavy values; nil/"" dropped | T-WR-01 | `URI.encode_query/1` round-trip integrity; no raw interpolation remains | Unit | `mix test test/oban_powertools/web/selectors_test.exs --seed 0` | ❌ Wave 0 — create | ⬜ pending |
| WR-02 | TargetType helper returns correct atoms for known strings, raises for unknown | T-WR-02 | Closed-enum function-clause dispatch; no `String.to_atom/1` | Unit | `mix test test/oban_powertools/lifeline/target_type_test.exs --seed 0` | ❌ Wave 0 — create | ⬜ pending |
| WR-02 | `normalize_related_evidence` returns atoms for known keys, binaries for unknown — no atom-table growth | T-WR-02 | `String.to_existing_atom/1` + allowlist; unknown keys remain binary | Unit | `mix test test/oban_powertools/forensics/evidence_bundle_test.exs --seed 0` | ❌ Wave 0 — create file + directory | ⬜ pending |
| WR-02 | Status string conversion (control_plane_presenter:18) uses bounded normalization | T-WR-02 | `String.to_existing_atom/1` + `rescue ArgumentError -> status` | LiveView integration | covered by quick command above | ✅ extends existing | ⬜ pending |
| WR-02 | Map-key fallback (control_plane_presenter:223) uses bounded normalization | T-WR-02 | `String.to_existing_atom/1` + rescue → `nil` on unknown | LiveView integration | covered by quick command above | ✅ extends existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Verification rg-checks (D-23, corrected per RESEARCH.md Open Q#4 + plan-checker iteration 2)

Must produce zero hits before `/gsd:verify-work`:

- **WR-01 selector-encoding gate (CORRECTED — lib-scoped negative-filter pattern):**

  ```bash
  rg -n 'incident_fingerprint=#\{' lib/ 2>/dev/null | rg -v 'encode_(www_form|query)' | wc -l
  # MUST return 0.
  ```

  Catches raw fingerprint interpolation in `lib/` that is NOT wrapped in `URI.encode_www_form` or `URI.encode_query`. Test code is excluded from the gate because test assertions legitimately exercise encoded URL strings like `"incident_fingerprint=#{URI.encode_www_form(...)}"`, which is the contract Selectors must satisfy. Empirically verified at 0 hits on HEAD. Two earlier candidate patterns are documented as historical context in PLAN.md `<strategy>` § Verification gate corrections — neither is referenced for execution.

- **WR-02 atom-safety gate (four target files, no carve-outs):**

  ```bash
  rg -n "String\.to_atom\(" \
    lib/oban_powertools/web/control_plane_presenter.ex \
    lib/oban_powertools/web/lifeline_live.ex \
    lib/oban_powertools/lifeline.ex \
    lib/oban_powertools/forensics/evidence_bundle.ex
  # MUST return zero hits across the four target modules.
  ```

- **D-08 cleanup gate (no obfuscated `String.to_existing_atom` in `lifeline_live.ex`):**

  ```bash
  rg -n "String\.to_existing_atom\(" lib/oban_powertools/web/lifeline_live.ex
  # MUST return zero hits after the line-1105 cleanup.
  ```

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/web/selectors_test.exs` — WR-01 unit coverage for `ObanPowertools.Web.Selectors`
- [ ] `test/oban_powertools/lifeline/target_type_test.exs` — WR-02 unit coverage for `ObanPowertools.Lifeline.TargetType`
- [ ] `test/oban_powertools/forensics/evidence_bundle_test.exs` + parent dir `test/oban_powertools/forensics/` — WR-02 bounded normalization coverage
- [ ] Framework install: **none** — `mix test` config already covers everything.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|

*None — all phase behaviors have automated verification per the LiveView + unit test matrix above. Manual smoke is unnecessary because the LiveView round-trip-decode assertions already exercise the operator path end-to-end.*

---

## Validation Sign-Off

- [ ] All tasks in PLAN.md have `<automated>` verify or Wave 0 dependencies (set during planning)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (set during planning)
- [ ] Wave 0 covers all MISSING references (three new test files above)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] Corrected rg-checks embedded in PLAN.md `<verification>` block (per RESEARCH.md Open Q#4 + plan-checker iteration 2 lib-scoped correction)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** complete — phase executed 2026-05-27; 41-VERIFICATION.md status: passed, 226 tests, 0 failures, 7/7 truths verified. Wave 0 test files (selectors_test.exs, target_type_test.exs, evidence_bundle_test.exs) created and green. WR-01/WR-02 advisory debt closed.
