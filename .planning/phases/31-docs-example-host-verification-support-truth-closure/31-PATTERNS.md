# Phase 31: Docs, Example Host, Verification & Support-Truth Closure - Pattern Map

**Mapped:** 2026-05-26
**Files analyzed:** 17
**Analogs found:** 17 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `README.md` | top-level promise surface | public product story -> supported/tested/host-owned contract | current README support-truth section | strong |
| `guides/support-truth-and-ownership-boundaries.md` | canonical ownership bucket reference | support claim -> host/library boundary | existing bucket guide | strong |
| `guides/optional-oban-web-bridge.md` | bounded bridge contract | bridge route -> read-only claim -> native/bridge distinction | current bridge guide | strong |
| `guides/example-app-walkthrough.md` | example-host provenance and usage guide | fixture story -> public proof interpretation | current example walkthrough | strong |
| `guides/first-operator-session.md` | native-first day-0 proof guide | install -> first audited native action -> optional bridge boundary | current first-session guide | strong |
| `guides/upgrade-and-compatibility.md` | supported upgrade lane truth | supported source host -> deterministic upgrade proof | current upgrade guide | strong |
| `examples/phoenix_host/README.md` | canonical current-state host fixture truth | fixture contents -> host-owned obligations -> proof posture | current example-host README | strong |
| `test/oban_powertools/docs_contract_test.exs` | docs claim enforcement | stable wording markers -> merge-blocking proof | current docs contract lane | strong |
| `test/support/example_host_contract.ex` | fixture-lane orchestration helper | copied fixture -> compile/reset/seeds/test lanes | existing example-host contract helper | strong |
| `test/oban_powertools/example_host_contract_test.exs` | top-level host contract assertions | lane outputs -> bounded support proof | existing host contract test | strong |
| `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` | native-first host smoke proof | seeded actor -> native action -> durable audit | current first-session smoke | strong |
| `examples/phoenix_host/test/phoenix_host_web/oban_web_bridge_smoke_test.exs` | bridge smoke proof | shared session -> `/ops/jobs/oban` render | current bridge smoke | strong |
| `examples/phoenix_host/test/phoenix_host_web/oban_powertools_control_plane_smoke_test.exs` | bounded new host proof lane | seeded actor -> overview / audit / bridge-only claims | first-session smoke + bridge smoke combined pattern | medium |
| `test/oban_powertools/web/live/engine_overview_live_test.exs` | repo-local overview truth | overview buckets -> bridge/native ownership copy | current overview LiveView test | strong |
| `test/oban_powertools/web/live/audit_live_test.exs` | repo-local audit truth | audit event rows -> read-only cross-surface contract | current audit LiveView test | strong |
| `test/oban_powertools/web/live/control_plane_copy_coherence_test.exs` | repo-local cross-surface coherence truth | native pages + audit -> shared vocabulary | current coherence lane | strong |
| `.planning/v1.3-MILESTONE-AUDIT.md` / `31-VERIFICATION.md` | canonical closeout artifacts | completed proof -> requirement closure -> deferred wedges | prior milestone/verification closeout artifacts | medium |

## Pattern Assignments

### Promise-shaping docs are enforced through shared markers

**Pattern:** the repo does not snapshot docs paragraphs. It asserts stable nouns, commands, routes, and support-truth labels in `test/oban_powertools/docs_contract_test.exs`.

**Planning takeaway:** add or tighten exact markers like `unified native /ops/jobs control plane`, `Inspection only`, and host-owned seam names rather than asserting whole sections verbatim.

### Host proof is lane-based and temp-fixture-backed

**Pattern:** `test/support/example_host_contract.ex` prepares a temp host copy, runs lane-specific tests, and returns textual outputs for assertions.

**Planning takeaway:** any new host-proof lane should be another focused fixture test plus helper wiring, not a new harness or another fixture directory.

### Repo-local semantic proof already owns overview and audit behavior

**Pattern:** overview, audit, and copy coherence are already proven with focused LiveView tests under `test/oban_powertools/web/live/`.

**Planning takeaway:** keep those as the semantic proof source for `VER-03`, while the example host proves the public host contract can surface the same promises.

### Closeout artifacts should point at canonical proof, not restate it

**Pattern:** prior closeout-oriented planning artifacts prefer additive chronology, explicit pointers, and narrow summaries over rewriting earlier files.

**Planning takeaway:** `31-VERIFICATION.md` should own requirement closure for Phase 31, while the milestone audit memo should summarize evidence and deferred wedges without replacing roadmap or requirements authority.

## Implementation Notes

- Prefer adding a new bounded fixture smoke test over widening `oban_powertools_first_session_test.exs` into a giant scenario.
- Keep bridge-only proof separate from native audited action proof even if both run in the same example host.
- Reuse the exact support-truth bucket words already frozen in the docs and tests.
- Keep closeout edits confined to Phase 31 artifacts and minimal top-level traceability updates.
