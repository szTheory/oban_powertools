---
phase: 50-telemetry-metrics-slo-guide
reviewed: 2026-05-29T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/oban_powertools/telemetry.ex
  - config/prod.exs
  - mix.exs
  - test/oban_powertools/telemetry_test.exs
  - guides/telemetry-and-slos.md
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 50: Code Review Report

**Reviewed:** 2026-05-29
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the telemetry contract module, its tests, the prod config, mix manifest, and the
telemetry/SLO guide. The production code (`telemetry.ex`) is sound: the `@contract`, the
`metrics/0` counter definitions, and the five `execute_*` helpers all agree, and I cross-checked
every emission site in `lib/` (`lifeline.ex`, `cron.ex`, `limits.ex`, `workflow/runtime.ex`,
`web/cron_live.ex`) against the contract — emitted event suffixes and metadata keys match.

The defects are concentrated in the **test file**, which is supposed to be the guard rail for
this "telemetry as a strict public API" contract but actually validates fabricated data rather
than production behavior. The most serious issue is a test that emits and asserts on an event
suffix (`:repair_completed`) that **does not exist anywhere in production** (production uses
`:repair_executed`), so the test passes while testing nothing real. Several other tests assert
against hand-written metadata maps rather than data captured from production code paths, and the
strongest contract invariant (metrics tags ⊆ contract) is checked with a one-directional,
self-referential assertion. No security issues found; no blockers.

## Warnings

### WR-01: Test emits and asserts a nonexistent event suffix (`:repair_completed`)

**File:** `test/oban_powertools/telemetry_test.exs:176-203`
**Issue:** The "emits lifeline events within documented metadata boundaries" test attaches to
`[:oban_powertools, :lifeline, :repair_completed]` and emits `:repair_completed`. That suffix
appears **nowhere** in production: the contract, `metrics/0`, and `lib/oban_powertools/lifeline.ex`
all use `:repair_previewed` and `:repair_executed`. The test passes only because
`:telemetry.execute/3` accepts any event name and the test never cross-checks the suffix against
the contract. This is a false-confidence test — it claims to verify lifeline boundaries but
exercises an event the library never emits. Line 200's assertion
(`Map.keys(metadata) == @expected_contract.families.lifeline`) only passes because the test
author hand-built `metadata` to match the contract list, not because production emits those keys.
**Fix:** Use a real suffix and assert against it. Replace `:repair_completed` with `:repair_executed`
(or `:repair_previewed`), and ideally drive the assertion from the actual emission site rather
than a literal map:
```elixir
:telemetry.attach("lifeline-handler",
  [:oban_powertools, :lifeline, :repair_executed], handler, nil)

ObanPowertools.Telemetry.execute_lifeline_event(:repair_executed, %{count: 1}, metadata)

assert_receive {:lifeline_event,
  [:oban_powertools, :lifeline, :repair_executed], %{count: 1}, ^metadata}
```

### WR-02: Contract-conformance tests assert against fabricated metadata, not production emissions

**File:** `test/oban_powertools/telemetry_test.exs:100-203`
**Issue:** Every "emits ... within documented metadata boundaries" test (workflow step_completed,
workflow_terminal, cron, lifeline) builds a local `metadata` map by hand and then asserts that
`Map.keys(metadata) == @expected_contract.families.<x>`. This is tautological: the test author
copied the contract keys into the literal, so the assertion can never fail regardless of what
production actually emits. The real risk these tests should catch — production code emitting a
metadata key outside the contract, or omitting a required one — is not covered. For example
production `:paused`/`:resumed`/`:run_now` cron events emit only `[:action, :source, :overlap_policy]`
(no `:catch_up_policy`), but the cron test (line 171) fabricates all four keys and asserts they
equal the full cron contract list, masking that asymmetry.
**Fix:** Capture metadata from the actual production call path (e.g. trigger `Cron.pause/.../`,
`Lifeline.preview_repair/...`) and assert the captured keys are a subset of the contract:
```elixir
assert MapSet.subset?(
  MapSet.new(Map.keys(captured_metadata)),
  MapSet.new(allowed_keys_for(family, suffix))
)
```
At minimum, derive the expected keys from the contract by reference rather than re-typing them
into the test body.

### WR-03: `metrics/0` tag-conformance test is one-directional and self-referential

**File:** `test/oban_powertools/telemetry_test.exs:33-52`
**Issue:** The "metrics/0 tags stay within frozen contract" test only verifies metric tags ⊆
contract. It never verifies the reverse useful invariant (that each declared metric maps to a
real, emitted event suffix), nor that the metric event names are well-formed. Combined with the
fact that both `contract()` and `metrics()` come from the same module, a drift where a metric is
declared for a suffix production never emits (the WR-01 class of bug) would pass this test
silently. The contract test (line 21) compares `contract()` against `@expected_contract`, which
is a verbatim copy of `@contract` — so it detects accidental edits to `@contract` but provides no
independent validation that the contract reflects reality.
**Fix:** Add an assertion that every `metric.event_name` suffix corresponds to an event suffix
actually emitted by production (e.g. assert each metric suffix is in a known list of emitted
suffixes, or add an integration test that attaches to each metric's event_name and confirms a
real code path fires it). Cross-checking the 18 metric definitions against the emission sites in
`lib/` would have caught WR-01.

### WR-04: `metrics/0` has no test coverage in a non-test reporter shape; `valid_types` allows `Sum` that is never produced

**File:** `test/oban_powertools/telemetry_test.exs:24-31`
**Issue:** Two coupled weaknesses. (1) `metrics/0` is documented to **raise** when
`:telemetry_metrics` is absent (telemetry.ex:76-86), and `:telemetry_metrics` is `only: [:test, :dev]`
(mix.exs:55) — meaning the raising branch only ever executes in a prod release, which is never
tested. There is no test asserting the raise path or its message, so a regression in the guard
(e.g. wrong module name in `Code.ensure_loaded?`) would ship undetected. (2) The
`valid_types` list (line 29) includes `Telemetry.Metrics.Sum`, but `metrics/0` only produces
`Counter` structs. Allowing `Sum` weakens the assertion: if a future edit accidentally swapped a
counter for a sum (changing aggregation semantics consumers depend on), this test would still
pass.
**Fix:** Tighten the type assertion to exactly the produced type:
```elixir
assert Enum.all?(metrics, &(&1.__struct__ == Telemetry.Metrics.Counter))
```
and add a test for the raise contract — at minimum assert the error message names
`:telemetry_metrics` so the documented behavior is locked.

## Info

### IN-01: `config/prod.exs` is an empty stub

**File:** `config/prod.exs:1`
**Issue:** The file contains only `import Config` with no configuration. This is harmless for a
library (hosts own their config), but it is dead scaffolding included in the review scope. If it
is intentionally empty as a placeholder it is fine; otherwise it adds noise.
**Fix:** Either remove the file or add a brief comment documenting why it is intentionally empty
for a library package.

### IN-02: Guide SLO example uses inconsistent tag set for the success-rate numerator

**File:** `guides/telemetry-and-slos.md:183-198`
**Issue:** The "repair success rate SLO" example numerator filters
`repair_executed_count{action="retry", incident_class="orphaned_job", target_type="job", ...}`
and then in the Parapet block filters on `outcome: "ok"`. But `oban_powertools.lifeline.repair_executed.count`
is declared with tags `[:action, :incident_class, :target_type]` (telemetry.ex:169-172) — it does
**not** carry an `outcome` tag. A reader copying the Prometheus query or the
`tag_filters: [outcome: "ok"]` Parapet snippet would filter on a label that the metric does not
expose, yielding no matching series. The guide's own table (line 120) correctly shows no
`outcome` tag for this metric, so the SLO example contradicts the documented contract.
**Fix:** Either point the SLO example at a metric that carries `outcome`
(`oban_powertools.lifeline.archive_prune_completed.count` has `outcome`), or note that
distinguishing success requires an `outcome` tag that `repair_executed` does not currently expose,
so the example is aspirational. Avoid showing a `tag_filters: [outcome: "ok"]` against a metric
without that tag.

### IN-03: Comment claims `:catch_up_policy` is "only emitted by :slot_claimed" — verify against contract scope

**File:** `lib/oban_powertools/telemetry.ex:119`
**Issue:** The inline comment states `:catch_up_policy only emitted by :slot_claimed; omit from
others`, and the metrics correctly omit it from paused/resumed/run_now. This matches production
(cron paused/resumed/run_now emit only `action, source, overlap_policy`). However the flat `cron`
contract entry (telemetry.ex:37) lists `catch_up_policy` for the whole family, so the
per-suffix nuance lives only in the metrics code and a comment, not in the contract structure.
This is a documentation/structure smell, not a bug — the cron family could use the nested
per-suffix shape (like `workflow`) to make the suffix-specific tag sets explicit and
machine-checkable.
**Fix:** Consider modeling `cron` as a per-suffix map (mirroring `workflow`) so the
`catch_up_policy`-only-for-`slot_claimed` rule is encoded in the contract rather than implied by
a comment.

### IN-04: `execute_*` helpers lack `@doc` annotations after the first

**File:** `lib/oban_powertools/telemetry.ex:191-221`
**Issue:** Only `execute_operator_action/3` (line 180) carries a `@doc`. The other four public
emitters (`execute_limiter_event`, `execute_cron_event`, `execute_workflow_event`,
`execute_lifeline_event`) are undocumented public functions in a module whose whole purpose is a
"strict public API." For a SemVer-governed contract surface, all public entry points should be
documented.
**Fix:** Add a one-line `@doc` to each emitter, mirroring the operator_action doc.

---

_Reviewed: 2026-05-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
