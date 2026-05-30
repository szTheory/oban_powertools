---
phase: 51
slug: published-package-verification
status: compliant
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
updated: 2026-05-30
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in Elixir) |
| **Config file** | `examples/hex_consumer/test/test_helper.exs` |
| **Quick run command** | `cd examples/hex_consumer && mix compile --warnings-as-errors` |
| **Full suite command** | `cd examples/hex_consumer && MIX_ENV=test mix test test/hex_consumer_web/oban_powertools_first_session_test.exs` |
| **Estimated runtime** | ~60–120 seconds (deps.get from hex + compile + LiveView session) |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/hex_consumer && mix compile --warnings-as-errors`
- **After every plan wave:** Run the full first-session test
- **Before `/gsd-verify-work`:** Full suite must be green AND `git status --porcelain` empty
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 51-01-T1 | 51-01 | 0 | REL-04 | scaffold | `ls examples/hex_consumer/mix.exs` | ✅ | ✅ green |
| 51-01-T2 | 51-01 | 0 | REL-04 | smoke | `grep -q 'oban_powertools' examples/hex_consumer/mix.exs` | ✅ | ✅ green |
| 51-02-T1 | 51-02 | 1 | REL-04 | integration | `ls examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs` | ✅ | ✅ green (proved green via path-dep swap in Plan 02) |
| 51-03-T1 | 51-03 | 2 | REL-04 | CI | `grep -q 'verify-published' .github/workflows/release.yml` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `examples/hex_consumer/` — complete Phoenix app scaffold committed (Plan 01)
- [x] `examples/hex_consumer/mix.exs` — `{:oban_powertools, "~> 0.5"}` hex dep, `oban` explicit, no `oban_web`
- [x] `examples/hex_consumer/test/test_helper.exs` — committed (Plan 01/02)
- [x] `examples/hex_consumer/test/support/conn_case.ex` — committed
- [x] `examples/hex_consumer/test/support/data_case.ex` — committed
- [x] `examples/hex_consumer/priv/repo/seeds.exs` — `nightly_sync` cron fixture (gitignored; generated at CI time)
- [x] `examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs` — covers REL-04 (Plan 02, commit 81b72e2)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `verify-published` actually runs post-publish on hex.pm | REL-04 | Only observable on a real release where hex.pm has the new version indexed | After next release, confirm the `verify-published` job ran green on the release commit in GitHub Actions |

*The local first-session test depends on hex.pm reachability (true hex dep). A network-isolated run cannot resolve `{:oban_powertools, "~> 0.5"}` — this is by design (the whole point is exercising the published tarball). Phase 52.1 fixed the Igniter committed-modules conflict that blocked this job in v1.6.*

---

## Phase Gate (Definition of Done)

- [x] `examples/hex_consumer/` scaffold committed with hex dep
- [x] First-session test exists and proved green via path-dep swap
- [x] `verify-published` job added to `release.yml` with `needs: [release-please, publish-hex]`
- [x] `:files` whitelist NOT loosened (no packaging bugs found)
- [x] Drift check passed: intentional no-`oban_web` difference documented in hex_consumer/README.md
- [x] `git status --porcelain` empty for phase paths (D-05)
- [ ] Live CI run against real published tarball (MANUAL-ONLY — next release)

---

## Validation Sign-Off

- [x] All tasks have automated verify command or are explicitly manual-only
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s (smoke checks) + ~120s (full integration)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** compliant

---

## Validation Audit 2026-05-30

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

VALIDATION.md was in stale draft state — all wave 0 tasks and per-task verification already done per Plan 01/02/03 summaries. Updated to reflect actual completed state. The live CI E2E run is a deliberate manual-only item (requires a real release); Phase 52.1 fixed the Igniter conflict that was blocking it.
