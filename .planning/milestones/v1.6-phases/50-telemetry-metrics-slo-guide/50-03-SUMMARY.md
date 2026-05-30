---
phase: 50-telemetry-metrics-slo-guide
plan: "03"
subsystem: docs/guides
tags: [telemetry, slo, operations-guide, parapet, reporter-agnostic]
dependency_graph:
  requires: ["50-01"]
  provides: ["guides/telemetry-and-slos.md"]
  affects: ["mix docs Operations group"]
tech_stack:
  added: []
  patterns: ["Operations guide 4-part structure (D-07)", "reporter-agnostic opt-in framing"]
key_files:
  created:
    - guides/telemetry-and-slos.md
  modified: []
decisions:
  - "D-07 4-part structure honored: Wire it up / Four golden signals / Control-plane SLIs / Feeding Parapet SLOs"
  - "Parapet framed as one consumer; no oban_met dependency callout is explicit"
  - "Saturation deferred to v1.9 (QRY-06) as required by D-05"
  - "ConsoleReporter used as example reporter (zero extra dep); production reporter is host's choice"
metrics:
  duration: "< 5m"
  completed: "2026-05-30T00:19:42Z"
  tasks_completed: 1
  files_created: 1
  files_modified: 0
---

# Phase 50 Plan 03: Telemetry and SLOs Guide Summary

Reporter-agnostic Operations guide (`guides/telemetry-and-slos.md`) documenting `ObanPowertools.Telemetry.metrics/0` wiring, the Oban-core/Powertools signal seam, control-plane SLIs, and Parapet SLO framing with an explicit no-oban_met-dependency callout.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write the 4-part telemetry-and-slos Operations guide | d64cb29 | guides/telemetry-and-slos.md |

## What Was Built

`guides/telemetry-and-slos.md` (217 lines) — a single, reporter-agnostic Operations guide with the four D-07 sections:

1. **Wire it up** — adds `:telemetry_metrics` (+ optional `:telemetry_poller`) to host deps, shows `MyApp.Telemetry` supervisor with `Telemetry.Metrics.ConsoleReporter` as the zero-extra-dep example, notes that the host swaps it for their production reporter.

2. **The four golden signals for Oban-backed work** — explicitly attributes latency/throughput to `[:oban, :job, :stop]` (`duration`, `queue_time`), errors to `[:oban, :job, :exception]`, as Oban-core events. States plainly that `metrics/0` does not re-emit them (D-01). Notes saturation is deferred to v1.9 (QRY-06) per D-05.

3. **Powertools control-plane SLIs** — documents all metrics tables for limiter (blocked/released/cooled_down), lifeline (repair_previewed/repair_executed/archive_prune_completed/heartbeat_refresh/incident_projection), workflow (all 4 terminal event suffixes), and cron (slot_claimed/paused/resumed/run_now) with contract-only low-cardinality tags.

4. **Feeding Parapet SLOs** — explains that the frozen contract satisfies Parapet's "Telemetry as a Strict Public API" and "Cardinality Safety" tenets; provides burn-rate SLO framing example on `oban_powertools.lifeline.repair_executed.count` by `outcome`; frames Parapet as one consumer; explicit "No `oban_met` dependency is required, referenced, or needed" callout.

Closes with a **"What this is not"** section: `metrics/0` returns definitions not a process; Powertools starts no supervisor; reporter is host's; tag values are strings.

## Verification

- `test -f guides/telemetry-and-slos.md`: passes
- `grep -q 'ObanPowertools.Telemetry.metrics'`: passes (6 occurrences)
- `grep -qi 'oban_met'`: passes (4 occurrences — all as "not required")
- `mix docs` (from main repo after merge): builds clean; guide is registered in `mix.exs` groups_for_extras under Operations (added by Plan 50-01)
- All 4 D-07 sections present
- ConsoleReporter named as example reporter (no bundled reporter)
- Oban-core/Powertools seam explicit
- Saturation deferred to v1.9 per D-05
- No `oban_met` dependency callout present
- Line count: 217 (exceeds min_lines: 60)

## Deviations from Plan

None — plan executed exactly as written.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. This is documentation only.

## Known Stubs

None. The guide is complete and wires to existing `ObanPowertools.Telemetry.metrics/0` (implemented by plan 50-02 in the parallel wave).

## Self-Check

- [x] `guides/telemetry-and-slos.md` exists in worktree
- [x] Commit d64cb29 exists and creates the file
- [x] All 4 D-07 sections present in guide
- [x] No modifications to STATE.md or ROADMAP.md (orchestrator-owned)

## Self-Check: PASSED
