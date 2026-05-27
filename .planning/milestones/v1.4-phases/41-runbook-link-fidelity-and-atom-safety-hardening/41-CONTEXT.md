# Phase 41: Runbook Link Fidelity and Atom Safety Hardening - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Convert the v1.4 milestone-audit advisory debts WR-01 (incident_fingerprint
selector encoding) and WR-02 (`String.to_atom/1` normalization safety) from
open advisory items into tested, durable implementation guarantees across the
runbook and forensics paths surfaced in Phase 34.

This phase owns:
- Bounded, centralized encoding of `incident_fingerprint` and the other
  stable URL selectors used by runbook deep-links, overview attention cards,
  and forensic handoffs.
- Bounded normalization of every `String.to_atom/1` site in the four target
  modules so user-derived strings cannot grow the atom table.
- Deterministic regression coverage that proves selector fidelity for
  delimiter-heavy fingerprints and proves bounded atom behavior for unknown
  inputs.

This phase does not:
- Change ownership-triad labels, runbook copy contracts, or support-truth
  vocabulary established in Phase 34 / Phase 35.
- Change route shapes, selector parameter names, or URL contracts beyond
  encoding behavior.
- Reopen the v1.3/v1.4 native-shell-vs-bridge boundary, persisted runbook
  session model, or host-owned escalation ownership.
- Introduce a public host-facing automation/runbook DSL.

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Recommendation-first planning posture — narrow gray areas, escalate
  only when public semantics, support truth, architectural boundaries,
  operator trust, or maintainer burden are materially at stake (PROJECT.md
  Decision Posture).
- **D-02:** Preserve the v1.3/v1.4 product posture: native pages own diagnosis
  and bounded audited action truth; Oban Web bridge is inspection-only;
  host apps own external escalation and delivery truth. WR-01/WR-02
  remediation must not perturb these boundaries.
- **D-03:** Treat Phase 28–35 locked decisions as defaults — in particular the
  stable URL selector set (`incident_fingerprint`, `resource_type`,
  `resource_id`, `workflow_id`, `step`, `view`) (Phase 34 D-25) and the
  thin-LiveView / read-model-owned copy posture (Phase 34 D-22, D-24).
- **D-04:** This is a hardening phase. No new user-visible capability, no
  vocabulary changes, no public API surface.

### Scope of WR-02 Atom Remediation
- **D-05:** Harden **all six** atom-conversion sites in the four target
  modules, not just the unbounded-input ones. Goal: the WR-02 verification
  rg-check (`rg -n "String\.to_atom\(" {target files}`) returns zero hits
  with no carve-outs, so future contributors cannot reintroduce an
  unconstrained `String.to_atom/1` without a deliberate exemption.
- **D-06:** Target sites (audited 2026-05-27):
  1. `lib/oban_powertools/web/control_plane_presenter.ex:18` — status string
     → atom for `@status_labels` lookup. Closed set of 6 statuses
     (`:needs_review`, `:blocked`, `:waiting`, `:runnable`, `:resolved`,
     `:bridge_only`).
  2. `lib/oban_powertools/web/control_plane_presenter.ex:223` — `Map.get`
     key fallback (`Map.get(map, key) || Map.get(map, String.to_atom(key))`).
     Unbounded-input — highest atom-DoS risk.
  3. `lib/oban_powertools/forensics/evidence_bundle.ex:35` — binary keys in
     `related_evidence` map entries during `normalize_related_evidence/1`.
     Unbounded-input — second-highest risk.
  4. `lib/oban_powertools/lifeline.ex:1073` — `String.to_atom(preview.target_type)`
     in `repair_executed` audit subject.
  5. `lib/oban_powertools/lifeline.ex:1206` — `String.to_atom(preview.target_type)`
     in `host_follow_up` audit subject.
  6. `lib/oban_powertools/web/lifeline_live.ex:1368` —
     `String.to_atom(action_info.target_type)` in workflow handoff row build.
- **D-07:** Sites 4–6 share a single producer-bounded enum (`"job"`,
  `"workflow"`, `"workflow_step"`, `"step"`). They get the same canonical
  helper. Sites 1, 2, 3 each use the canonical helper appropriate to their
  call shape (see D-08, D-09, D-10).
- **D-08:** Also clean up `lib/oban_powertools/web/lifeline_live.ex:1105`
  (`String.to_existing_atom("preview_" <> "token")` — an obfuscated
  `:preview_token`) — replace with the atom literal `:preview_token`. No
  behavior change, but removes the only non-target rg hit so the WR-02
  verification check stays free of carve-outs.

### Bounded Atom Strategy
- **D-09:** Status string conversion (control_plane_presenter:18) uses
  `String.to_existing_atom/1` guarded by a `rescue ArgumentError -> status`
  fallback that returns the original binary. Phoenix.Naming.humanize handles
  the unknown-binary path that the existing `status_label/1` already supports.
- **D-10:** Map-key fallback (control_plane_presenter:223) uses
  `String.to_existing_atom/1` with rescue; on failure, the function returns
  `nil` (i.e., the binary key didn't match, atom key won't either). No new
  atoms created for unknown keys.
- **D-11:** `evidence_bundle:35` (related_evidence key normalization) uses a
  small bounded normalization helper that prefers `String.to_existing_atom/1`
  on a documented known-key list and leaves unknown keys as binaries. Matches
  Phase 34 D-09 partial-evidence posture: unknown values must remain visible,
  not coerced into invented atoms.
- **D-12:** Target_type sites (lifeline.ex:1073, lifeline.ex:1206,
  lifeline_live.ex:1368) go through a new dedicated
  `ObanPowertools.Lifeline.TargetType` helper with an explicit case on the
  closed enum (`"job"` / `"workflow"` / `"workflow_step"` / `"step"`). Unknown
  values raise (FunctionClauseError) rather than silently coerce — this is
  caller-trusted-internal code; an unknown target_type is a programming bug.
- **D-13:** A single shared module owns documentation of "atoms allowed in
  Powertools normalization" — the TargetType helper is its own module; the
  related_evidence/status normalization helpers live alongside their callers
  and reference the same allowed-key principle. No grand `Atoms` umbrella
  module — that would over-couple unrelated normalization domains.

### Scope of WR-01 Selector Encoding
- **D-14:** All link construction in `lib/` already uses `URI.encode_query/1`
  or `URI.encode_www_form/1` — there is no raw `incident_fingerprint=`
  interpolation remaining. The remediation is **centralization + proof**, not
  re-encoding.
- **D-15:** Introduce a small `ObanPowertools.Web.Selectors` (or equivalent)
  module that owns canonical encoding for the locked selector set
  (`incident_fingerprint`, `resource_type`, `resource_id`, `workflow_id`,
  `step`, `view`) and the canonical paths it serves
  (`/ops/jobs/lifeline?...`, `/ops/jobs/forensics?...`,
  `/ops/jobs/limiters?...`, `/ops/jobs/cron?...`,
  `/ops/jobs/audit?...`). Existing callsites move through this helper.
- **D-16:** Selector parameter names stay stable
  (`incident_fingerprint`, `resource_type`, `resource_id`, `workflow_id`,
  `step`, `view`) — D-25 from Phase 34 is locked.
- **D-17:** Existing safe callsites should be rewritten to use the new
  helper rather than left in place. The phase outcome is "one place to
  harden, one place to test" — leaving parallel safe paths defeats the
  centralization purpose.
- **D-18:** Selector helper drops `nil` / `""` values before encoding
  (matches existing `selector_path/1` behavior in
  `forensics/runbook_entry.ex`).

### Test and Proof Posture
- **D-19:** Add deterministic regression tests with delimiter-heavy
  `incident_fingerprint` fixtures covering at minimum the delimiters
  `:`, `/`, `?`, `#`, `%`, ` ` (whitespace), `&`, and `=`. Round-trip
  decode integrity must be asserted in route handling (i.e., the LiveView
  resolves the correct incident row from the encoded fingerprint).
- **D-20:** Cover all three LiveView surfaces that emit or consume
  fingerprint selectors: `engine_overview_live_test.exs`,
  `forensics_live_test.exs`, `lifeline_live_test.exs`.
- **D-21:** Add a normalization-helper test (new or co-located with
  evidence_bundle) covering: known keys → atom, unknown keys → binary,
  no new atoms created for unknown inputs.
- **D-22:** Add a TargetType helper test covering each of the four known
  strings + unknown-value raise behavior.
- **D-23:** Verification commands documented in the existing plan stay valid
  and pass with zero hits and no carve-outs:
  - `rg -n "incident_fingerprint=.*\\#|incident_fingerprint=.*\\?|incident_fingerprint=.*\\/" test/oban_powertools/web/live/*.exs`
  - `rg -n "String\\.to_atom\\(" lib/oban_powertools/web/control_plane_presenter.ex lib/oban_powertools/web/lifeline_live.ex lib/oban_powertools/lifeline.ex lib/oban_powertools/forensics/evidence_bundle.ex`
  - `mix test {three LiveView suites} --seed 0`

### Plan Structure
- **D-24:** Keep a single bundled plan (41-01) rather than splitting into
  three. The three concerns (selectors, atoms, proof) are tightly coupled —
  the regression tests only make sense once the encoders/normalizers exist,
  and splitting would force interim states that don't add review value.
  Matches PROJECT.md "one-shot recommendation posture".
- **D-25:** Replan 41-01 to reflect the decisions captured here. The
  existing 41-01-PLAN.md (created without context) is structurally
  correct but needs to be reissued with the new Selectors / TargetType /
  bounded-normalization helpers, the expanded six-site atom remediation,
  and the verification carve-out removal.
- **D-26:** ROADMAP.md's "3 plans" count for Phase 41 is loose guidance.
  After replan, update the roadmap entry to reflect the single bundled plan
  (or leave the original three-plan layout if the planner finds a clean
  split during replanning — but D-24 is the recommended default).

### Backward Compatibility and Safety Guardrails
- **D-27:** No change to known-good behavior. Status atom lookups, audit
  subject shapes (`%{type: atom, id: string}`), and link contracts must
  remain identical for the existing happy paths.
- **D-28:** Unknown values must remain visible (matches Phase 34 D-09).
  Normalization should not silently coerce unknown keys into invented atoms
  or drop them from downstream consumers — fall back to binary and let the
  partial-evidence vocabulary surface continue to do its job.
- **D-29:** No new atom-table allocation on any path reachable from
  user-derived input.

### Claude's Discretion
- Exact module names and namespaces for the Selectors and TargetType helpers,
  provided they live under `ObanPowertools.Web` and `ObanPowertools.Lifeline`
  respectively and are unit-testable.
- Exact shape of the bounded normalization helper for evidence_bundle —
  inline function, private module-level helper, or extracted module —
  provided D-11 (known-key list + unknown → binary) is preserved.
- Exact delimiter-heavy fixture composition beyond the minimum set in D-19,
  provided round-trip decode is asserted at the LiveView boundary.
- Whether to keep the existing `URI.encode_query` callsites inside the new
  Selectors module's implementation or wrap them with a thin helper —
  implementation detail, not a semantic decision.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` — Phase 41 goal, three-plan envisioned breakdown,
  dependency on Phase 40, and Phase 42 (Nyquist sweep) boundary.
- `.planning/PROJECT.md` — repo-level Decision Posture (recommendation-first,
  narrow gray areas, idiomatic Phoenix/LiveView/Ecto/Postgres defaults).
- `.planning/REQUIREMENTS.md` — `OPS-03`, `RNB-01`, `RNB-02` (the
  requirements this hardening shores up).
- `.planning/STATE.md` — milestone v1.4 closure sequencing.
- `.planning/v1.4-v1.4-MILESTONE-AUDIT.md` — origin of WR-01 and WR-02
  advisory debt; cross-phase integration risks (34→35/38) and at-risk
  end-to-end flows.

### Prior locked decisions that constrain this phase
- `.planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-CONTEXT.md`
  — D-22 thin-LiveView / read-model centralization, D-24 OverviewReadModel as
  composition seam, D-25 stable URL selector set, D-09 partial-evidence
  posture for unknown values.
- `.planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-01-SUMMARY.md`,
  `34-02-SUMMARY.md`, `34-03-SUMMARY.md` — implementation surfaces touched.
- `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-CONTEXT.md`
  — limiter/cron forensic destinations and selector parameter names.
- `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-CONTEXT.md`
  — forensic bundle shape, related_evidence vocabulary, completeness model.
- `.planning/phases/40-phase-34-manual-acceptance-closure/40-01-SUMMARY.md`,
  `40-02-SUMMARY.md` — closure of Phase 34's manual gates via automated
  proxies; the proxy lanes are what merge-blocks regressions and will be
  rerun in Phase 41 CI.

### Existing plan and verification posture
- `.planning/phases/41-runbook-link-fidelity-and-atom-safety-hardening/41-01-PLAN.md`
  — current single-plan structure; to be replanned with the helpers,
  expanded six-site atom remediation, and selector centralization decided
  here.

### Current implementation surfaces and reusable seams
- `lib/oban_powertools/web/overview_read_model.ex` —
  `lifeline_incident_path/2` and `forensic_incident_path/1` already use
  `URI.encode_query/1` (lines 427–438). To move behind Selectors helper.
- `lib/oban_powertools/forensics/runbook_entry.ex` — `selector_path/1`
  at line 371 is the existing canonical safe encoder; Selectors helper
  should generalize this shape (drop nil/"" values, `URI.encode_query`,
  prepend path).
- `lib/oban_powertools/forensics.ex` — lines 456 and 475 build
  `/ops/jobs/lifeline?#{params}` after `URI.encode_query`. To move behind
  Selectors helper.
- `lib/oban_powertools/web/workflows_live.ex:439` — builds
  `/ops/jobs/lifeline?#{params}` after `URI.encode_query`. To move behind
  Selectors helper.
- `lib/oban_powertools/web/lifeline_live.ex` — multiple internal callsites
  using `URI.encode_query/1` for navigation; lines 858 and elsewhere.
  Should move behind Selectors helper where they construct
  outbound `/ops/jobs/...` URLs.
- `lib/oban_powertools/web/control_plane_presenter.ex` — atom-conversion
  sites at lines 18 and 223 (see D-09, D-10).
- `lib/oban_powertools/forensics/evidence_bundle.ex` — atom-conversion site
  at line 35 inside `normalize_related_evidence/1` (see D-11).
- `lib/oban_powertools/lifeline.ex` — atom-conversion sites at lines 1073
  and 1206 (see D-12).
- `lib/oban_powertools/web/lifeline_live.ex` — atom-conversion site at
  line 1368 (see D-12) and obfuscated atom literal at line 1105 (see D-08).

### Test surfaces to extend
- `test/oban_powertools/web/live/engine_overview_live_test.exs` — delimiter-
  heavy fingerprints flowing through overview link construction.
- `test/oban_powertools/web/live/forensics_live_test.exs` — round-trip
  decode and forensic destination selector resolution.
- `test/oban_powertools/web/live/lifeline_live_test.exs` — fingerprint
  resolution to active vs resolved incident rows.

### Product posture references (used to keep wording in scope)
- `prompts/oban_powertools_context.md` — domain language, personas, support-
  truth expectations.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — bounded native-
  shell strategy and why Powertools-owned diagnosis stays honest.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Forensics.RunbookEntry.selector_path/1` is the existing canonical safe
  encoder (drops nil/"", URI.encode_query, prepends path). Generalizing this
  shape into a Selectors helper that knows the four canonical destination
  paths is the smallest faithful refactor.
- `Forensics.bundle/2`, `OverviewReadModel`, and `ControlPlanePresenter`
  already centralize most semantic decisions. Phase 41's helpers slot into
  the same seam pattern without inventing a new architectural layer.
- `RepairPreview` and workflow `action_info` produce `target_type` from a
  closed enum — TargetType helper formalizes the existing reality rather
  than constraining anything new.

### Established Patterns
- Thin LiveViews; read-model/presenter modules own copy, encoding, and
  bounded vocabulary.
- Selectors travel on URLs as stable durable identifiers
  (`incident_fingerprint`, `resource_type`, `resource_id`, `workflow_id`,
  `step`, `view`); rendered diagnosis and copy never appear on URLs.
- Unknown / missing / partial-evidence states are surfaced visibly, not
  silently coerced. WR-02 remediation extends this posture into atom
  normalization (D-28).
- Helpers are testable in isolation; verification favors deterministic
  `--seed 0` LiveView runs over snapshot prose.

### Integration Points
- New Selectors helper: every safe encoder callsite in `lib/oban_powertools/`
  routes through it. Tests assert delimiter-heavy round-trip integrity.
- New TargetType helper: three audit-subject callsites and one workflow
  handoff callsite route through it. Tests assert the four valid strings
  map to the four expected atoms.
- Bounded normalization in evidence_bundle.ex: known related_evidence keys
  list documented at the helper; unknown keys preserved as binaries.
  Downstream consumers (forensics LiveView, runbook entry assembly) must
  handle binary-key fall-throughs without crashing — covered by regression
  tests at the LiveView boundary.
- Phase 40's merge-blocking C3 / C4 proxy lanes (host-contract-proof.yml)
  will re-run on Phase 41 changes; any regression in runbook copy contract
  or overview attention bounds will block merge.

</code_context>

<specifics>
## Specific Ideas

- Preferred operator outcome:
  "Delimiter-heavy incident fingerprints still resolve to the right row.
  Unknown keys in audit/forensics data don't grow the atom table. Nothing
  visible changes."
- Preferred helper shape:
  small modules with explicit known-set documentation in moduledocs; no
  metaprogramming, no protocols, no DSL.
- Preferred test shape:
  fixture-driven regression tests at the LiveView boundary that fail loudly
  if a future contributor re-introduces raw interpolation or unconstrained
  `String.to_atom/1`, plus unit tests for the new helpers.
- Preferred guard against drift:
  the verification rg-checks in 41-01-PLAN.md stay valid post-replan with
  zero hits and no carve-outs.

</specifics>

<deferred>
## Deferred Ideas

- Project-wide `Atoms` umbrella module covering every domain's bounded
  conversion — over-couples unrelated normalization concerns. Out of scope.
- Schema-level atom typing for `target_type` (Ecto.Enum on RepairPreview)
  — bigger diff than a hardening phase warrants; helper-based bounded
  conversion is sufficient. Belongs in a future schema-cleanup pass if ever.
- Encoding selectors as opaque tokens (e.g., signed fingerprints) instead
  of raw URL-encoded values — semantic change to the public selector
  contract; explicitly out of scope per D-16.
- Generalized "all atom conversions in the repo" sweep beyond the four
  target files — Phase 42 (Nyquist compliance sweep) or a later hygiene
  phase if audit surfaces more sites.
- Public host-facing automation/runbook DSL or machine-facing API for
  selector construction — out of scope per Phase 34 deferred-ideas list.

</deferred>

---

*Phase: 41-runbook-link-fidelity-and-atom-safety-hardening*
*Context gathered: 2026-05-27*
