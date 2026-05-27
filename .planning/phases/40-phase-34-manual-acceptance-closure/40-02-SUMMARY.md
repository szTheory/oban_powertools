---
phase: 40-phase-34-manual-acceptance-closure
plan: 02
status: complete
completed_at: 2026-05-27T15:45:00Z
requirements_addressed:
  - OPS-03
  - RNB-01
  - RNB-02
files_modified:
  - .github/workflows/host-contract-proof.yml
  - .planning/phases/39-ci-continuity-proof-lane-closure/39-PROOF-MANIFEST.json
  - test/oban_powertools/docs_contract_test.exs
self_check: PASSED
---

# Plan 40-02 Summary — Wire Phase 40 Proxy Tests into the C3/C4 Continuity Lanes

## Objective achieved

The two automated proxy tests added by Plan 40-01 now run inside the merge-blocking `continuity-ver04-c3` and `continuity-ver04-c4` lanes, and the `continuity-proof-status` aggregate publishes an explicit `phase40-gate-report.json`. No new top-level CI jobs were introduced; workflow drift that drops these checks fails `docs_contract_test.exs` pre-merge.

## C3 / C4 CLAIM_COMMAND changes

`continuity-ver04-c3` (covers visual-hierarchy proxy):
```
mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/engine_overview_live_test.exs --seed 0
```

`continuity-ver04-c4` (covers copy-contract proxy):
```
mix test test/oban_powertools/forensics_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/runbook_copy_contract_test.exs --seed 0 && mix test test/oban_powertools/docs_contract_test.exs --seed 0
```

Notes:
- `--seed 0` suffix preserved on both lanes.
- The C4 lane already invokes the claim command via `bash -lc "${CLAIM_COMMAND}"` so the `&&` chain (sequential test runs) executes correctly.
- The `phase40-gate-report.json` lives in `continuity-proof-status`, not in C3/C4 themselves, so adding suites to C3/C4 keeps the gate report as a single source of truth.

## Phase 40 gate report

New step `Compose Phase 40 gate report` in `continuity-proof-status` writes `tmp/ver04/phase40-gate-report.json`:
```json
{
  "coverage_scope": "phase40",
  "checked_claims": ["VER04-C3", "VER04-C4"],
  "required_markers": [
    "ownership-triad",
    "runbook-ordering",
    "overview-continuity",
    "copy-contract",
    "visual-hierarchy"
  ],
  "claim_results": {
    "VER04-C3": "<needs.continuity-ver04-c3.result>",
    "VER04-C4": "<needs.continuity-ver04-c4.result>"
  },
  "status": "pass" | "fail",
  "github.run_id": "...",
  "github.sha": "...",
  "generated_at_utc": "..."
}
```
Status is `pass` only when both C3 and C4 are `success`; otherwise `fail`.

Two artifact uploads cover the file:
- Included in the existing `continuity-proof-packet` artifact path list (so downstream consumers of the packet automatically pick it up).
- A dedicated `phase40-gate-report` artifact with `if-no-files-found: error` (clearly named for auditors who only want the gate report).

## 39-PROOF-MANIFEST.json updates

For both `VER04-C3` and `VER04-C4` entries:
- `command` strings updated to match the new `CLAIM_COMMAND` strings exactly.
- `artifact_refs` extended with `"phase40_gate_report": "tmp/ver04/phase40-gate-report.json"`.

`claim_id`, `requirement_id`, `workflow_job`, and `status_source` unchanged. JSON validated with `python3 -c "import json; json.load(open(...))"`.

## docs-contract drift guard

New test in `test/oban_powertools/docs_contract_test.exs`:
```elixir
test "workflow keeps Phase 40 shift-left coverage markers" do
  source = File.read!(@workflow_file)

  assert source =~ "engine_overview_live_test.exs"
  assert source =~ "workflows_live_test.exs"
  assert source =~ "runbook_copy_contract_test.exs"
  assert source =~ "phase40-gate-report.json"
  assert source =~ "phase40-gate-report"
end
```

If a future workflow edit drops any of these markers (e.g. someone removes the new test from a C3/C4 command, or deletes the gate report step), this test fails and blocks the merge inside the existing `docs-contract` CI lane.

## Verification commands

```
mix test test/oban_powertools/docs_contract_test.exs --seed 0
# → 11 tests, 0 failures (Phase 40 marker test = test #11)

rg -n "continuity-ver04-c3|engine_overview_live_test\.exs|--seed 0" .github/workflows/host-contract-proof.yml
rg -n "continuity-ver04-c4|workflows_live_test\.exs|runbook_copy_contract_test\.exs" .github/workflows/host-contract-proof.yml
rg -n "phase40-gate-report" .github/workflows/host-contract-proof.yml .planning/phases/39-ci-continuity-proof-lane-closure/39-PROOF-MANIFEST.json
```

All commands return the expected markers.

## Notes on CI topology

- No new top-level jobs were introduced. The CI graph remains: `structural`, `fresh-host`, `docs-contract`, `native-first`, `first-session`, `optional-bridge`, `control-plane`, `upgrade-proof`, `workflow-compatibility`, `continuity-ver04-{c1,c2,c3,c4}`, `continuity-proof-status`.
- The Phase 40 status is implicitly enforced by the existing `Enforce continuity proof failure boundaries` step (which already requires C3 and C4 to succeed). Adding explicit gate-status enforcement would be redundant with C3/C4 enforcement.

## Self-Check: PASSED
