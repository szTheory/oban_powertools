# Phase 41: Runbook Link Fidelity and Atom Safety Hardening - Research

**Researched:** 2026-05-27
**Domain:** Elixir/Phoenix LiveView — URL selector encoding centralization + bounded atom normalization
**Confidence:** HIGH (every callsite directly inspected; idioms confirmed against ecosystem source)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Recommendation-first planning posture — narrow gray areas, escalate only when public semantics, support truth, architectural boundaries, operator trust, or maintainer burden are materially at stake.
- **D-02:** Preserve the v1.3/v1.4 product posture: native pages own diagnosis and bounded audited action truth; Oban Web bridge is inspection-only; host apps own external escalation and delivery truth. WR-01/WR-02 remediation must not perturb these boundaries.
- **D-03:** Treat Phase 28–35 locked decisions as defaults — in particular the stable URL selector set (`incident_fingerprint`, `resource_type`, `resource_id`, `workflow_id`, `step`, `view`) (Phase 34 D-25) and the thin-LiveView / read-model-owned copy posture (Phase 34 D-22, D-24).
- **D-04:** This is a hardening phase. No new user-visible capability, no vocabulary changes, no public API surface.
- **D-05:** Harden **all six** atom-conversion sites in the four target modules. Goal: the WR-02 verification rg-check returns zero hits with no carve-outs.
- **D-06:** Target sites (audited 2026-05-27) — six callsites listed in full in `## Phase Requirements → Target-Site Map` below.
- **D-07:** Sites 4–6 share a single producer-bounded enum (`"job"`, `"workflow"`, `"workflow_step"`, `"step"`). They get the same canonical helper.
- **D-08:** Also clean up `lib/oban_powertools/web/lifeline_live.ex:1105` (`String.to_existing_atom("preview_" <> "token")`) — replace with atom literal `:preview_token`.
- **D-09:** Status string conversion (control_plane_presenter:18) uses `String.to_existing_atom/1` guarded by `rescue ArgumentError -> status` fallback that returns the original binary. `Phoenix.Naming.humanize` handles the unknown-binary path.
- **D-10:** Map-key fallback (control_plane_presenter:223) uses `String.to_existing_atom/1` with rescue; on failure, the function returns `nil`.
- **D-11:** `evidence_bundle:35` uses a small bounded normalization helper that prefers `String.to_existing_atom/1` on a documented known-key list and leaves unknown keys as binaries. Matches Phase 34 D-09 partial-evidence posture.
- **D-12:** Target_type sites go through a new dedicated `ObanPowertools.Lifeline.TargetType` helper with an explicit case on the closed enum. Unknown values raise (FunctionClauseError) rather than silently coerce.
- **D-13:** No grand `Atoms` umbrella module — would over-couple unrelated normalization domains.
- **D-14:** All link construction in `lib/` already uses safe encoders. Remediation is **centralization + proof**, not re-encoding.
- **D-15:** Introduce a small `ObanPowertools.Web.Selectors` module that owns canonical encoding for the locked selector set and the canonical paths it serves.
- **D-16:** Selector parameter names stay stable (Phase 34 D-25 is locked).
- **D-17:** Existing safe callsites should be rewritten to use the new helper rather than left in place. "One place to harden, one place to test."
- **D-18:** Selector helper drops `nil` / `""` values before encoding (matches existing `selector_path/1` behavior in `runbook_entry.ex`).
- **D-19:** Add deterministic regression tests with delimiter-heavy `incident_fingerprint` fixtures covering at minimum `:`, `/`, `?`, `#`, `%`, ` `, `&`, `=`. Round-trip decode integrity must be asserted in route handling.
- **D-20:** Cover all three LiveView surfaces (`engine_overview_live_test.exs`, `forensics_live_test.exs`, `lifeline_live_test.exs`).
- **D-21:** Add a normalization-helper test covering known→atom / unknown→binary / no new atoms.
- **D-22:** Add a TargetType helper test covering each of the four known strings + unknown-value raise behavior.
- **D-23:** Verification rg commands stay valid and pass with zero hits and no carve-outs.
- **D-24:** Keep a single bundled plan (41-01).
- **D-25:** Replan 41-01 to reflect the decisions captured here.
- **D-26:** ROADMAP.md's "3 plans" count for Phase 41 is loose guidance.
- **D-27:** No change to known-good behavior. Status atom lookups, audit subject shapes, link contracts must remain identical for happy paths.
- **D-28:** Unknown values must remain visible.
- **D-29:** No new atom-table allocation on any path reachable from user-derived input.

### Claude's Discretion
- Exact module names and namespaces for the Selectors and TargetType helpers, provided they live under `ObanPowertools.Web` and `ObanPowertools.Lifeline` respectively and are unit-testable.
- Exact shape of the bounded normalization helper for evidence_bundle — inline, private, or extracted module — provided D-11 is preserved.
- Exact delimiter-heavy fixture composition beyond the minimum set in D-19.
- Whether to keep `URI.encode_query` calls inside Selectors module or wrap them with a thin helper.

### Deferred Ideas (OUT OF SCOPE)
- Project-wide `Atoms` umbrella module.
- Schema-level `Ecto.Enum` typing for `target_type`.
- Encoding selectors as opaque tokens (e.g., signed fingerprints).
- Generalized atom conversion sweep beyond the four target files (deferred to Phase 42 or later).
- Public host-facing automation/runbook DSL or machine-facing API for selector construction.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS-03 | The native overview can project attention-worthy historical issues from limiters, cron, workflows, and Lifeline without degrading into a generic raw-event feed. | Selectors centralization preserves overview-link fidelity for delimiter-heavy fingerprints flowing from `OverviewReadModel.lifeline_incident_path/2` and `forensic_incident_path/1`. Existing test at `engine_overview_live_test.exs:37-67` already covers `&with=delimiters` fingerprints — extend per D-19. |
| RNB-01 | Operators can see runbook-guided next steps for supported diagnosis states. | `Forensics.RunbookEntry.selector_path/1` is the existing canonical safe encoder (line 371). Generalizing this shape into the `Selectors` helper preserves the legal-next-paths and evidence-path contract. |
| RNB-02 | Runbook guidance distinguishes Powertools-native, bridge-only, and host-owned steps. | Bounded `TargetType` helper formalizes the `"job"` / `"workflow"` / `"workflow_step"` producer enum (`Workflow.Runtime.workflow_level_actions/1`, `maybe_add_step_retry/2`, `maybe_add_step_cancel/2`). Audit subject shape `%{type: atom, id: string}` remains identical for all known paths. |
</phase_requirements>

## Summary

Phase 41 is **centralization and proof**, not algorithm change. CONTEXT.md has already locked every meaningful semantic question across 29 decisions. The remaining research work is to ground the implementation in the exact codebase shape so the planner writes a faithful PLAN.md.

I directly inspected each of the six WR-02 atom-conversion sites and each of the WR-01 selector-encoding callsites cited in CONTEXT.md. I also swept the rest of `lib/` to surface adjacent callsites that CONTEXT.md does not enumerate but that D-17 implies must also route through the new helper. I ran both verification rg-checks against the current tree to establish the baseline delta the planner must close.

**Primary recommendation:** The planner can produce a single bundled 41-01 plan with five waves: (W0) test fixtures + helper module skeletons, (W1) `Selectors` module + `TargetType` module with unit tests, (W2) migrate the eight identified safe-but-not-centralized callsites + the six atom sites + the D-08 cleanup, (W3) extend the three LiveView regression suites with delimiter-heavy fixtures, (W4) verify rg-checks pass with zero hits and `mix test --seed 0` green. Three significant findings the planner must address are documented in `## Open Questions`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| URL selector encoding | Web (presenter) | Forensics (read-model) | Selector encoding owns the URL contract surface; read-models construct selector data. New `Selectors` module sits at the Web boundary. |
| `target_type` → atom conversion | Lifeline (domain) | Web (LiveView consumer) | `target_type` originates in `Workflow.Runtime` action producers and `Lifeline.RepairPreview` — Lifeline domain owns the enum. New `TargetType` helper lives under `ObanPowertools.Lifeline`. |
| Status string normalization | Web (presenter) | ControlPlane (taxonomy) | `@status_labels` is presenter-owned UI vocabulary; `ControlPlane.@statuses` is the canonical taxonomy. Inline rescue stays in `ControlPlanePresenter`. |
| `related_evidence` key normalization | Forensics (bundle assembly) | — | `EvidenceBundle.build/1` owns bundle shape; normalization is private to the module per D-11. No new architectural layer. |

## Standard Stack

### Already Present (no installation needed)

| Library | Version | Purpose | Source |
|---------|---------|---------|--------|
| `Phoenix` | 1.8.7 | LiveView host + `Phoenix.Naming.humanize/1` for the status fallback | mix.lock |
| `Phoenix.LiveView` | 1.1.30 | `live/3`, `live_patch`, `assert_patch` for route-handling assertions | mix.lock |
| `Elixir` | ~> 1.19 | `String.to_existing_atom/1`, `URI.encode_query/1`, `URI.decode_query/1` | mix.exs |
| `ExUnit` | (stdlib) | Test framework; `--seed 0` already in CONTEXT.md verification command | test/test_helper.exs |
| `Phoenix.LiveViewTest` + `Plug.Test` | (Phoenix) | `live/2`, `assert_patch/2`, `has_element?/2` in `LiveCase` | test/support/live_case.ex |
| `Ecto.Adapters.SQL.Sandbox` | (ecto_sql 3.10) | Shared-mode sandbox per LiveView test (already wired) | test/support/live_case.ex |

### No new dependencies required

Phase 41 is a pure-Elixir hardening phase. No `mix.exs` change is expected.

### Idioms

**Safe atom conversion with rescue** [CITED: nietaki.com/2018/12, elixirforum.com/t/12871, ti.hashrocket.com/posts/gkwwfy9xvw]:

```elixir
def safe_to_existing_atom(binary) when is_binary(binary) do
  String.to_existing_atom(binary)
rescue
  ArgumentError -> nil  # or the original binary, depending on caller contract
end
```

This is the canonical Elixir idiom for converting untrusted strings to atoms without growing the atom table. `String.to_existing_atom/1` raises `ArgumentError` (not `:badarg`, not `MatchError`) when no atom exists for the binary. `rescue ArgumentError` is precise enough — no need for a catch-all.

**Explicit-case enum helper** [VERIFIED: inspected at `lib/oban_powertools/control_plane.ex:25-70`]:

```elixir
def to_atom("job"), do: :job
def to_atom("workflow"), do: :workflow
def to_atom("workflow_step"), do: :workflow_step
# no fallback clause → FunctionClauseError on unknown input
```

Matches the existing `ControlPlane.limiter_status/1`, `workflow_status/1`, `lifeline_status/1` pattern shape — closed-enum function-clause dispatch with no catch-all.

## Package Legitimacy Audit

No external packages are being installed. The Package Legitimacy Gate is non-applicable for this phase.

## Codebase Inspection: Callsite-by-Callsite Grounding

### A. WR-02 atom-conversion sites (six target + one D-08 cleanup)

| # | File:Line | Current Code | Producer Trust | Strategy (CONTEXT.md) | Implementation Notes |
|---|-----------|--------------|----------------|----------------------|---------------------|
| 1 | `lib/oban_powertools/web/control_plane_presenter.ex:18` | `do: status \|> String.to_atom() \|> status_label()` | User-derived (audit `event_type`, story `operator_status` binaries) | D-09: `String.to_existing_atom/1` + `rescue ArgumentError -> status` → fall through to clause on line 20 which calls `Map.get(@status_labels, status, Phoenix.Naming.humanize(status))`. | `Phoenix.Naming.humanize/1` accepts both atoms and binaries (verified at lines 207, 220, lib/audit_live.ex:114). Backward-compat for unknown status preserved: humanize of binary equals humanize of atom for normalized inputs. |
| 2 | `lib/oban_powertools/web/control_plane_presenter.ex:223` | `Map.get(map, key) \|\| Map.get(map, String.to_atom(key))` | Unbounded — `key` is whatever the caller passes (highest WR-02 risk) | D-10: `String.to_existing_atom/1` + `rescue ArgumentError -> nil` → outer `\|\|` chain returns nil for unknown keys (same as today when both lookups miss). | `follow_up_value/2` callers in `lib/` are not shown in my sweep — verify the planner accounts for any external callers. Only called inside this module. |
| 3 | `lib/oban_powertools/forensics/evidence_bundle.ex:35` | `{key, value} when is_binary(key) -> {String.to_atom(key), value}` | User-derived via JSON-decoded bundle inputs (second-highest WR-02 risk) | D-11: bounded known-key allowlist; unknown keys stay binaries. | **CRITICAL:** the forensics_live template at `web/forensics_live.ex:240-245` accesses `item.title`, `item.summary`, `item.provenance` via atom-key dot-access. Any item with binary `"title"`/`"summary"`/`"provenance"` keys would `KeyError`. The allowlist must include at minimum `:title`, `:summary`, `:provenance`, `:type`, `:resource_id`, `:resource_type` — all producer-emitted atom keys today. See "Open Questions" #2. |
| 4 | `lib/oban_powertools/lifeline.ex:1073` | `%{type: String.to_atom(preview.target_type), id: preview.target_id}` | Producer-bounded: `RepairPreview.target_type` is set in `build_job_preview/build_workflow_step_preview/build_workflow_preview` (lines 636, 692, 756) to `"job"`/`"workflow_step"`/`"workflow"` only. | D-12: `TargetType.to_atom/1` with explicit case clauses; FunctionClauseError on unknown. | Audit subject shape `%{type: :job, id: ...}` is the contract used in `Audit.list/1` callers across `lib/cron.ex`, `lib/limits.ex`, `lib/workflow/runtime.ex`, and `test/oban_powertools/lifeline_test.exs`. Must produce the same atoms (`:job`, `:workflow`, `:workflow_step`). |
| 5 | `lib/oban_powertools/lifeline.ex:1206` | `%{type: String.to_atom(preview.target_type), id: preview.target_id}` | Same producer as #4 | D-12: same `TargetType.to_atom/1` | Identical site to #4 with different surrounding audit metadata — both must use the same helper. |
| 6 | `lib/oban_powertools/web/lifeline_live.ex:1368` | `type: String.to_atom(action_info.target_type)` | Producer-bounded: `action_info.target_type` flows from `Workflow.Runtime.workflow_level_actions/1` (always `"workflow"`) and `maybe_add_step_retry/2` / `maybe_add_step_cancel/2` (always `"workflow_step"`). | D-12: same `TargetType.to_atom/1` | Constructs the `resource` map passed to `LiveAuth.authorized?` and `preview_for_action`. The atom contract must match `:workflow` / `:workflow_step` exactly. |
| (cleanup) | `lib/oban_powertools/web/lifeline_live.ex:1105` | `defp repair_preview_key, do: String.to_existing_atom("preview_" <> "token")` | Obfuscated atom literal | D-08: replace with `defp repair_preview_key, do: :preview_token` | The obfuscation is the only `String.to_existing_atom/1` call in `lib/` and would otherwise leave a carve-out in the WR-02 rg-check. Pure cleanup, no behavior change. The construction `"preview_" <> "token"` is compile-time so the atom already exists at module load. |

**D-07 note on enum size:** CONTEXT.md D-07 lists four producer-bounded strings including `"step"`. My sweep of `lib/oban_powertools/workflow/runtime.ex:1729, 1744, 1762` and `lib/oban_powertools/lifeline.ex:636, 692, 756` shows only `"job"`, `"workflow"`, `"workflow_step"` are emitted by producers today. `"step"` does not appear as a `target_type` value anywhere in `lib/`. The TargetType helper should still accept `"step"` (defensive — a future producer might emit it, and CONTEXT.md D-07 explicitly names it), but the planner should consider whether to: (a) include `"step"` → `:step` for forward compatibility, or (b) document the three known values and let `"step"` raise. **Recommendation:** include `"step"` → `:step` to match CONTEXT.md D-07 verbatim; document in moduledoc that producer side currently emits only the other three. See "Open Questions" #1.

### B. WR-01 selector-encoding callsites

CONTEXT.md cites a specific set of callsites for selector centralization. My sweep of `lib/` shows **eleven files** containing `URI.encode_query` or `URI.encode_www_form` for selector construction. Per D-17, all safe-but-not-centralized callsites should route through the new `Selectors` helper. The complete inventory follows.

| File:Line | Destination | Selectors Used | In CONTEXT.md? |
|-----------|-------------|----------------|-----------------|
| `lib/oban_powertools/forensics/runbook_entry.ex:371-378` | `/ops/jobs/forensics?...` | incident_fingerprint, view, workflow_id, step, resource_type, resource_id | yes (D-15: generalize this shape) |
| `lib/oban_powertools/web/overview_read_model.ex:282-287` | `/ops/jobs/audit?...` | resource_type, resource_id, event_type | implicit via D-17 |
| `lib/oban_powertools/web/overview_read_model.ex:309` | `/ops/jobs/limiters?resource=...` | resource | implicit via D-17 |
| `lib/oban_powertools/web/overview_read_model.ex:311` | `/ops/jobs/forensics?...` (raw interpolation) | resource_id, resource_type | implicit via D-17 |
| `lib/oban_powertools/web/overview_read_model.ex:335` | `/ops/jobs/cron?entry=...` | entry | implicit via D-17 |
| `lib/oban_powertools/web/overview_read_model.ex:337` | `/ops/jobs/forensics?...` (raw interpolation) | resource_id, resource_type | implicit via D-17 |
| `lib/oban_powertools/web/overview_read_model.ex:394, 403` | `/ops/jobs/limiters?resource=...` | resource | implicit via D-17 |
| `lib/oban_powertools/web/overview_read_model.ex:406` | `/ops/jobs/cron?entry=...` | entry | implicit via D-17 |
| `lib/oban_powertools/web/overview_read_model.ex:417-423` | `/ops/jobs/audit?...` | resource_type, resource_id, event_type | implicit via D-17 |
| `lib/oban_powertools/web/overview_read_model.ex:427-433` | `/ops/jobs/lifeline?...` (`lifeline_incident_path/2`) | view, incident_fingerprint | **yes (D-06 list)** |
| `lib/oban_powertools/web/overview_read_model.ex:435-438` | `/ops/jobs/forensics?...` (`forensic_incident_path/1`) | incident_fingerprint | **yes (D-06 list)** |
| `lib/oban_powertools/forensics.ex:443-457` | `/ops/jobs/lifeline?...` | workflow_id, step, action | **yes (D-06 list, line 456)** |
| `lib/oban_powertools/forensics.ex:467-476` | `/ops/jobs/lifeline?...` (`lifeline_path/2`) | incident_fingerprint, view | **yes (D-06 list, line 475)** |
| `lib/oban_powertools/forensics.ex:481-494` | `/ops/jobs/audit?...` (`audit_path/1` — **raw interpolation**) | resource_type, resource_id | implicit via D-17 — note: this is the only place in `lib/` outside `audit_live.ex:165-173` that uses raw interpolation without an encoder, but `step.id`/`workflow.id` are integer-only so no delimiter risk today. Still violates D-17 centralization. |
| `lib/oban_powertools/web/workflows_live.ex:406-416` | `/ops/jobs/forensics?...` (`forensic_path/2`) | workflow_id, step, resource_type, resource_id | implicit via D-17 |
| `lib/oban_powertools/web/workflows_live.ex:429-441` | `/ops/jobs/lifeline?...` (`lifeline_handoff/4`) | workflow_id, step, action | **yes (D-06 list, line 439)** |
| `lib/oban_powertools/web/lifeline_live.ex:845-859` | `/ops/jobs/lifeline?...` (`selection_path/1`) | view, incident_fingerprint, **row-id**, workflow_id, step, **action** | **yes (D-06 list, line 858)** — note non-canonical `row-id` and `action` keys; see "Open Questions" #3 |
| `lib/oban_powertools/web/lifeline_live.ex:1269-1279` | `/ops/jobs/forensics?...` (`forensic_path/2`) | incident_fingerprint, view, resource_type, resource_id | implicit via D-17 |
| `lib/oban_powertools/web/forensics_live.ex:286-295` | `/ops/jobs/audit?...` (`audit_follow_up_path/1`) | resource_type, resource_id, event_type | implicit via D-17 |
| `lib/oban_powertools/web/forensics_live.ex:393-403` | `/ops/jobs/audit?...` (`continuity_audit_follow_up_path/1`) | resource_type, resource_id | implicit via D-17 |
| `lib/oban_powertools/web/control_plane_presenter.ex:177-188` | `/ops/jobs/audit?...` (`audit_follow_up_path/1`) | resource_type, resource_id, event_type | implicit via D-17 |
| `lib/oban_powertools/web/cron_live.ex:533, 551` | `/ops/jobs/forensics?...` and `/ops/jobs/cron?entry=...` | resource_type, resource_id, entry | implicit via D-17 |
| `lib/oban_powertools/web/limiters_live.ex:295, 298` | `/ops/jobs/limiters?resource=...` and `/ops/jobs/forensics?...` | resource, resource_type, resource_id | implicit via D-17 |
| `lib/oban_powertools/forensics/limiter_history.ex:327, 330` | `/ops/jobs/limiters?resource=...` and `/ops/jobs/audit?...` | resource, resource_type, resource_id | implicit via D-17 |
| `lib/oban_powertools/forensics/cron_history.ex:397, 400` | `/ops/jobs/cron?entry=...` and `/ops/jobs/audit?...` | entry, resource_type, resource_id | implicit via D-17 |

**Scope take:** D-17 says "leaving parallel safe paths defeats the centralization purpose." Strict reading: migrate **all 26+ selector callsites** above. Pragmatic reading: migrate the six CONTEXT.md-cited sites + the **eight raw-interpolation sites** (those marked above) since raw interpolation is where WR-01's "delimiter-heavy values" hazard actually lives. The planner should choose between these two interpretations explicitly — see "Open Questions" #3.

### C. The `audit_live.ex:167-168` raw interpolation is NOT a selector callsite

`filter_summary/1` at `lib/oban_powertools/web/audit_live.ex:165-173` produces a human-readable filter-summary string for template display (used at line 57: `<p class="mt-2 text-sm text-zinc-600"><%= filter_summary(@filters) %></p>`), NOT a URL. Out of scope for Phase 41.

## Architecture Patterns

### System Architecture Diagram

```
                       Producers (closed enums)
                       ───────────────────────
                       Workflow.Runtime
                         workflow_level_actions  → target_type: "workflow"
                         maybe_add_step_retry    → target_type: "workflow_step"
                         maybe_add_step_cancel   → target_type: "workflow_step"
                       Lifeline.build_*_preview  → target_type: "job"/"workflow_step"/"workflow"
                       Lifeline.Incident          → incident_fingerprint (delimiter-heavy binaries)
                       ControlPlane.@statuses    → :needs_review/:blocked/:waiting/:runnable/:resolved/:bridge_only
                                            │
                                            ▼
                       ┌──────────────────────────────────────────────┐
                       │       Read-model / Presenter layer          │
                       │  - OverviewReadModel.lifeline_incident_path  │
                       │  - OverviewReadModel.forensic_incident_path  │
                       │  - Forensics.lifeline_path / audit_path      │
                       │  - WorkflowsLive.forensic_path/lifeline_..   │
                       │  - LifelineLive.selection_path/forensic_..   │
                       │  - ControlPlanePresenter.audit_follow_up_..  │
                       │  - RunbookEntry.selector_path                │
                       └──────────────────────────────────────────────┘
                              │ (current: each callsite calls URI.encode_query directly)
                              │
       ─────── PHASE 41 WAVE 1+2 INSERT NEW CENTRALIZING HELPERS ────────
                              │
                              ▼
              ┌────────────────────────────┐  ┌─────────────────────────┐
              │ ObanPowertools.Web.        │  │ ObanPowertools.Lifeline.│
              │   Selectors                │  │   TargetType             │
              │ - encode/2 (path, kvs)     │  │ - to_atom/1              │
              │ - lifeline_path/1          │  │   ("job" → :job, ...)    │
              │ - forensic_path/1          │  │ - raises on unknown      │
              │ - audit_path/1             │  │                          │
              │ - limiter_path/1           │  │                          │
              │ - cron_path/1              │  │                          │
              │ Drops nil/"" before        │  │                          │
              │ URI.encode_query           │  │                          │
              └────────────────────────────┘  └─────────────────────────┘
                              │                          │
                              ▼                          ▼
              ┌─────────────────────────────────────────────────────────┐
              │           Phoenix.LiveView routes/templates             │
              │  /ops/jobs, /ops/jobs/lifeline, /ops/jobs/forensics,    │
              │  /ops/jobs/audit, /ops/jobs/limiters, /ops/jobs/cron    │
              └─────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌─────────────────────────────────────────────────────────┐
              │         LiveView mount → params decode →                │
              │         row lookup (incident_fingerprint, etc.)         │
              │  Asserts round-trip integrity for delimiter-heavy input │
              │  Tests cover: : / ? # % space & = delimiters            │
              └─────────────────────────────────────────────────────────┘

       Bounded normalization (private to EvidenceBundle, per D-11):
       ────────────────────────────────────────────────────────────
       normalize_related_evidence/1:
         - allow-list :title :summary :provenance :type :resource_id :resource_type
         - known binary keys → String.to_existing_atom (atoms already exist module-load time)
         - unknown binary keys → kept as binary (partial-evidence visibility preserved)
         - Provenance value normalization unchanged (lines 33-34)
```

### Recommended Module Placement

```
lib/oban_powertools/
├── web/
│   ├── selectors.ex          # NEW — ObanPowertools.Web.Selectors
│   ├── overview_read_model.ex
│   ├── control_plane_presenter.ex
│   ├── lifeline_live.ex
│   ├── forensics_live.ex
│   ├── workflows_live.ex
│   ├── audit_live.ex
│   ├── cron_live.ex
│   └── limiters_live.ex
├── lifeline/
│   ├── target_type.ex        # NEW — ObanPowertools.Lifeline.TargetType
│   ├── repair_preview.ex
│   └── ...
├── lifeline.ex
├── forensics/
│   ├── evidence_bundle.ex    # normalize_related_evidence/1 reshapes per D-11
│   ├── runbook_entry.ex      # selector_path/1 removed in favor of Selectors
│   └── ...
└── forensics.ex
```

**Naming rationale:**
- `ObanPowertools.Web.Selectors` — sibling to existing `ObanPowertools.Web.ControlPlanePresenter`, `ObanPowertools.Web.OverviewReadModel`. Matches the bare-noun naming used for shared helper modules in this codebase. (Alternative names considered: `RunbookSelectors` was rejected because the helper serves more than runbook surfaces; `UrlSelectors` was rejected as redundant; `Selectors` alone is precise and matches the v1.3 vocabulary already used in CONTEXT.md and Phase 34 D-25.)
- `ObanPowertools.Lifeline.TargetType` — sibling to `ObanPowertools.Lifeline.{Incident, RepairPreview}`. Matches existing `<Domain>.<Concept>` nesting (e.g., `ObanPowertools.Forensics.Provenance`, `ObanPowertools.Forensics.Chronology`).

### Pattern 1: Selectors helper — `encode/2` + named-destination delegators

**What:** A single private encoder + one named helper per canonical destination. Permissive on the selector list (accepts the locked stable set + `row-id`, `action`, `entry`, `resource`, `event_type` for back-compat), strict on the path (each destination is a named function so callsites read like documentation).

**When to use:** Every selector callsite that produces an `/ops/jobs/...?...` URL.

**Example (recommended shape — Claude's discretion territory per CONTEXT.md):**

```elixir
defmodule ObanPowertools.Web.Selectors do
  @moduledoc """
  Canonical encoder for the v1.4 stable URL selector set.

  The locked stable selector set (Phase 34 D-25) is:
    - incident_fingerprint
    - resource_type
    - resource_id
    - workflow_id
    - step
    - view

  Additional permissive selectors used by Phase 41 callsites:
    - row-id, action (Lifeline selection/handoff context)
    - entry, resource (limiter/cron destinations)
    - event_type (audit follow-up filters)

  All values are passed through URI.encode_query/1 (delimiter-safe).
  nil and "" values are dropped before encoding (Phase 34 D-18).
  """

  @canonical_paths %{
    lifeline: "/ops/jobs/lifeline",
    forensics: "/ops/jobs/forensics",
    audit: "/ops/jobs/audit",
    limiters: "/ops/jobs/limiters",
    cron: "/ops/jobs/cron"
  }

  def lifeline_path(params), do: encode(:lifeline, params)
  def forensic_path(params), do: encode(:forensics, params)
  def audit_path(params), do: encode(:audit, params)
  def limiter_path(params), do: encode(:limiters, params)
  def cron_path(params), do: encode(:cron, params)

  def encode(destination, params) when destination in [:lifeline, :forensics, :audit, :limiters, :cron] do
    query =
      params
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
      |> URI.encode_query()

    case query do
      "" -> @canonical_paths[destination]
      q  -> "#{@canonical_paths[destination]}?#{q}"
    end
  end
end
```

**Source:** Synthesized from `lib/oban_powertools/forensics/runbook_entry.ex:371-378` (existing `selector_path/1` shape) + `lib/oban_powertools/web/overview_read_model.ex:427-438` (existing safe encoders).

### Pattern 2: TargetType helper — explicit closed-enum case

**What:** Function-clause dispatch on the producer-bounded enum. No catch-all clause.

**When to use:** Every `String.to_atom(target_type)` callsite — sites 4, 5, 6 in CONTEXT.md.

**Example:**

```elixir
defmodule ObanPowertools.Lifeline.TargetType do
  @moduledoc """
  Closed-enum normalization for Lifeline / Workflow target_type strings.

  Producer side (Workflow.Runtime, Lifeline.build_*_preview) emits only:
    - "job"           → :job
    - "workflow"      → :workflow
    - "workflow_step" → :workflow_step

  CONTEXT.md D-07 also lists "step"; included for forward compatibility
  even though no producer currently emits it.

  Unknown values raise FunctionClauseError — this is caller-trusted internal
  code, and an unknown target_type indicates a programming bug (Phase 41 D-12).
  """

  def to_atom("job"), do: :job
  def to_atom("workflow"), do: :workflow
  def to_atom("workflow_step"), do: :workflow_step
  def to_atom("step"), do: :step
end
```

**Source:** Pattern matches `ObanPowertools.ControlPlane.limiter_status/1` shape (closed enum, no catch-all) at `lib/oban_powertools/control_plane.ex:25-28`.

### Pattern 3: Bounded `related_evidence` key normalization

**What:** Documented known-key allowlist; unknown binary keys stay binary.

**Example (private helper in EvidenceBundle):**

```elixir
# Known atom keys emitted by producers (lib/oban_powertools/forensics.ex:116-127,
# limiter_history.ex:203-222, cron_history.ex:282).
# Atoms in this list are already allocated at module load; String.to_existing_atom
# succeeds without growing the atom table.
@related_evidence_atom_keys ~w(title summary provenance type resource_id resource_type)a

defp normalize_related_evidence(item) do
  Map.new(item, fn
    {:provenance, value} -> {:provenance, Provenance.normalize_provenance(value)}
    {"provenance", value} -> {:provenance, Provenance.normalize_provenance(value)}
    {key, value} when is_binary(key) -> {normalize_key(key), value}
    pair -> pair
  end)
end

defp normalize_key(binary) do
  String.to_existing_atom(binary)
rescue
  ArgumentError -> binary
end
```

The `@related_evidence_atom_keys` module attribute ensures each known key exists as an atom at compile time (Elixir guarantees atoms in module attributes are interned at module load). The rescue branch catches genuinely unknown keys and leaves them as binaries — matching Phase 34 D-09 partial-evidence posture.

### Anti-Patterns to Avoid

- **`String.to_atom/1` anywhere on a user-derived path** — the entire point of WR-02 remediation. Atom table is not garbage-collected; unbounded growth is a stability hazard.
- **Implementing a "generic Atoms umbrella module"** — explicitly rejected in D-13.
- **Catching all exceptions (`rescue _e -> ...`) around atom conversion** — `ArgumentError` is the canonical error from `String.to_existing_atom/1`; catching everything else hides bugs.
- **Adding signed/opaque tokens to selectors** — out of scope per D-16 and deferred ideas list.
- **Touching the `String.to_atom` callsites in `lib/oban_powertools/control_plane.ex:48`, `cron.ex:422`, `explain.ex:130`** — out of scope per CONTEXT.md "four target modules" boundary; these flow to Phase 42 if surfaced.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| URL query string assembly | Manual `"key=#{value}&..."` interpolation | `URI.encode_query/1` (already standard) | Handles all percent-encoded characters correctly per RFC 3986; manual interpolation fails on `&`, `=`, `#`, `?`, spaces, non-ASCII bytes. Current codebase already uses it everywhere; Phase 41 just centralizes. |
| Single-value URL encoding | Manual escaping | `URI.encode_www_form/1` | Already used for path-segment values like `entry=#{...}`. Handles delimiter-heavy fingerprints correctly. |
| String-to-atom check | Try/rescue around `String.to_atom/1` | `String.to_existing_atom/1` + rescue `ArgumentError` | `to_atom` always succeeds and pollutes the atom table; `to_existing_atom` raises only if the atom is unseen. |
| Human-readable label fallback | Custom string-replace logic | `Phoenix.Naming.humanize/1` | Already used at 5+ sites; handles both atoms and binaries. |
| Closed-enum dispatch | Manual `case`/`if` chain | Function-clause heads with no catch-all | Idiomatic Elixir; FunctionClauseError on unknown is exactly what D-12 specifies. |

**Key insight:** Phase 41 doesn't need any new "library" or pattern — it needs centralization of the patterns already present. The helpers are 30-60 lines each.

## Runtime State Inventory

Phase 41 is pure code-edit + test-add. The new helpers are introduced fresh; no existing helper module is being renamed; no datastore key/column is being renamed; no env var, OS-registered state, or build artifact is affected.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — `incident_fingerprint` selector values stored in `oban_powertools_lifeline_incidents.incident_fingerprint` are read-only inputs for this phase; their encoding-at-URL changes, not their storage. | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None | None |

Nothing in any category requires a data migration. The phase is safe to roll forward with code change + test add only.

## Test Coverage Audit (existing)

Before the planner specifies new test additions, here's what already exists so duplicates can be avoided.

### `test/oban_powertools/web/live/engine_overview_live_test.exs`

| Test | Lines | Covers |
|------|-------|--------|
| `"renders diagnosis-first cards..."` | 9-35 | Smoke render of overview with ownership labels and basic link presence. |
| `"encodes incident fingerprints in overview Lifeline and Forensics links"` | **37-67** | **Delimiter-heavy fingerprint encoding (`&with=delimiters`).** Already asserts encoded values appear and unencoded values do NOT. This is the existing baseline for WR-01 in this file. |
| `"keeps diagnosis context visible..."` | 69-84 | Read-only operator view |
| `"renders bounded historical attention..."` | 86+ | Attention projection bounds |

**Gap to close for D-19/D-20:** the existing fingerprint test covers only the `&` and `=` delimiters and only the Lifeline/Forensics destinations. Extend with the full delimiter set (`:`, `/`, `?`, `#`, `%`, ` `, `&`, `=`) and assert round-trip-decode (re-mount the resulting URL and verify the right row resolves).

### `test/oban_powertools/web/live/lifeline_live_test.exs`

| Test | Lines | Covers |
|------|-------|--------|
| `"forensic entry link..."` | 624-651 | Encoded forensic-entry link from Lifeline detail view. Asserts `URI.encode_www_form(fingerprint)` appears in href. |
| `"...selection path encoding"` | 540-580 | `selection_path/1` round-trip via `assert_patch/2` for active and resolved views, including delimiter-aware row-id. |
| Helper `insert_dead_executor_incident!/1` | 661-677 | Inserts incident with fingerprint `"dead_executor:#{executor_id}"` — already a colon-delimited fingerprint. |
| Helper `insert_workflow_incident!/2` | 692-708 | Inserts incident with fingerprint `"workflow_stuck:#{workflow_id}:#{step_id}"` — multi-colon fingerprint. |

**Gap to close for D-19/D-20:** extend `insert_dead_executor_incident!/1` (or add a sibling helper) to accept an explicit fingerprint, then add tests that drive delimiter-heavy fingerprints through the `selection_path/1` → mount → row-lookup loop. The existing tests use the natural-but-narrow `dead_executor:foo` shape; the new tests need `dead_executor:foo&bar=baz/path?x=1 #frag%20` style fingerprints.

### `test/oban_powertools/web/live/forensics_live_test.exs`

| Test | Lines | Covers |
|------|-------|--------|
| `"mounts the workflow forensic bundle and preserves step scope across remount"` | 21-58 | Round-trip mount → remount of `/ops/jobs/forensics?workflow_id=...&step=...&resource_type=workflow_step`. |
| `"mounts the lifeline forensic bundle..."` | 60-167 | Mounts `/ops/jobs/forensics?incident_fingerprint=#{URI.encode_www_form(...)}&view=active&resource_type=job&resource_id=123` and asserts diagnosis + audit continuity. |
| `@allowed_selector_keys` (module attribute at 12-19) | — | Already enumerates the locked stable selector set. The test file already encodes Phase 34 D-25. |

**Gap to close for D-19/D-20:** add tests that mount with delimiter-heavy fingerprints, assert the bundle resolves the correct incident, and that round-trip render preserves the selector values exactly.

### `test/oban_powertools/forensics_test.exs`

| Test | Lines | Covers |
|------|-------|--------|
| `"forensic evidence and continuity links keep the stable selector allowlist"` | 119+ | Exact match for D-15/D-16 — already asserts only locked selectors appear on links. Strong baseline; new Selectors helper must keep this green without modification. |
| `"workflow bundle exposes partial evidence..."` | 106-117 | Verifies `related_evidence` shape with `:provenance` atom key — confirms producer-side atom key contract. |
| `"chronology sorts..."` etc. | Various | Bundle assembly correctness; not directly affected by Phase 41 but must stay green. |

### `test/oban_powertools/forensics/evidence_bundle_test.exs`

Does **not exist**. CONTEXT.md D-21 calls for a normalization-helper test "new or co-located with evidence_bundle." Since `test/oban_powertools/forensics/` does not exist as a directory either, the planner must either: (a) create `test/oban_powertools/forensics/evidence_bundle_test.exs` and the parent directory, or (b) add the test cases to `test/oban_powertools/forensics_test.exs`. **Recommendation:** create the dedicated test file — matches the source structure mirror used elsewhere in `test/oban_powertools/web/live/`.

### `test/oban_powertools/lifeline_test.exs`

Already exercises `Audit.list(%{type: :job, id: ...}, repo: ...)` at lines 335, 414, 452 — those tests will fail loudly if the TargetType refactor produces a different atom for `"job"`. Strong existing coverage of the audit subject contract.

### New tests needed

1. **`test/oban_powertools/web/selectors_test.exs`** (new file) — unit tests for `Selectors.encode/2` and named destination helpers; delimiter-heavy params; nil/"" dropping; empty-params edge case.
2. **`test/oban_powertools/lifeline/target_type_test.exs`** (new file) — unit tests for each known string + unknown-value raise (D-22).
3. **`test/oban_powertools/forensics/evidence_bundle_test.exs`** (new file, new directory) — normalization-helper coverage per D-21: known keys → atom, unknown keys → binary, no new atoms (verify via `:erlang.system_info(:atom_count)` delta or by attempting `String.to_existing_atom/1` on a known-unknown key string after the test runs and asserting it raises).
4. **Extensions to the three LiveView test files** per D-19/D-20.

## Common Pitfalls

### Pitfall 1: `URI.encode_query` versus `URI.encode_www_form` semantic mismatch

**What goes wrong:** `URI.encode_query/1` operates on `{key, value}` enumerable and applies `www_form` encoding to both. `URI.encode_www_form/1` operates on a single binary. They are not interchangeable.

**Why it happens:** Easy to confuse, especially when single-key URLs (`?resource=foo`) are constructed with `encode_www_form` and multi-key URLs with `encode_query`.

**How to avoid:** The new `Selectors` module uses `URI.encode_query/1` exclusively. Single-key destinations (e.g., `/ops/jobs/limiters?resource=...`) become `Selectors.limiter_path(%{"resource" => name})` — `encode_query` handles single-pair maps fine.

**Warning signs:** A test that decodes a fingerprint and gets back partially-decoded content (e.g., `+` instead of space, or `%2520` instead of `%20`).

### Pitfall 2: `String.to_existing_atom` and module-load ordering

**What goes wrong:** `String.to_existing_atom/1` raises if the atom has not been allocated yet in the runtime. Atoms used as map keys in module attributes are allocated at module load. Atoms used only in defp clauses (and never as literals) are allocated at module load too — but atoms referenced only by string keys passed into `String.to_existing_atom` before the defining module is loaded will raise.

**Why it happens:** Order of module loading is non-deterministic during compilation. In tests, modules are loaded on demand.

**How to avoid:** Every atom the bounded normalization helper might return must be referenced as a literal somewhere in code that is guaranteed to load first. For Phase 41:
- `:title`, `:summary`, `:provenance`, `:type`, `:resource_id`, `:resource_type` — all referenced as atom keys in `lib/oban_powertools/forensics.ex:116-127` and template at `lib/oban_powertools/web/forensics_live.ex:240-245`. Safe.
- `:job`, `:workflow`, `:workflow_step`, `:step` — all referenced as atom literals in `lib/oban_powertools/audit.ex` callers (`Audit.list(%{type: :job, ...})` etc.) and `Workflow.Runtime`. Safe.
- `:needs_review`, `:blocked`, `:waiting`, `:runnable`, `:resolved`, `:bridge_only` — all in `@statuses` at `lib/oban_powertools/control_plane.ex:6`. Safe.

**Warning signs:** A test that passes in isolation but fails when run with `--seed 0` because module load order differs.

### Pitfall 3: `Audit.record/4` subject shape backward compatibility

**What goes wrong:** `Audit.normalize_resource/1` at `lib/oban_powertools/audit.ex:169` interpolates `"#{type}:#{id}"`. Whether `type` is atom or string, the interpolated `resource` string is the same. But the `resource_type` column is written from `resource_type(resource, normalized)` which derives a binary from the `%{type: ...}` shape.

**Why it happens:** The contract is implicit — both `%{type: :job, id: "123"}` and `%{type: "job", id: "123"}` produce the same row, but downstream callers (`Audit.list(%{type: :job, id: ...})`) require an atom because the normalize path on the read side also interpolates the type into the resource string for lookup.

**How to avoid:** TargetType must produce atoms, not binaries. Verified by inspecting `test/oban_powertools/lifeline_test.exs:335, 414, 452` and `test/oban_powertools/web/live/lifeline_live_test.exs:456, 621` — all use atom `type:` in their `Audit.list` filters.

**Warning signs:** Lifeline tests fail with empty result sets when looking up audit events after repair execution.

### Pitfall 4: The forensics_live template uses atom-key dot access on `related_evidence` items

**What goes wrong:** `<%= item.title %>` will raise `KeyError` if `item` has only a binary `"title"` key. If the D-11 bounded normalization keeps unknown binary keys, and an upstream caller passes a map with binary keys for `title`/`summary`/`provenance`, the template crashes.

**Why it happens:** This is the documented partial-evidence contract — but it must be carefully scoped to non-essential keys only.

**How to avoid:** The known-key allowlist must include the keys the template uses by atom-dot-access. Minimum: `:title`, `:summary`, `:provenance`. Any caller passing those keys as binaries gets them normalized to atoms (via `String.to_existing_atom` which succeeds because the atom literals exist in the producer code). Unknown keys (e.g., a hypothetical `"extra_evidence_field"` in user-supplied bundle input) stay binary.

**Warning signs:** Forensics LiveView mount-time `KeyError` exceptions in tests that pass a bundle with binary string keys.

### Pitfall 5: `URI.encode_query` orders `Enum` deterministically only for sorted maps

**What goes wrong:** `URI.encode_query/1` accepts both maps and keyword lists. With keyword lists (or `[{k, v}]` lists), order is preserved. With unsorted maps in different Elixir versions or under different load conditions, order may vary.

**Why it happens:** Map iteration order is not specified by the language; tests that assert literal URL strings can be flaky if the helper accepts maps.

**How to avoid:** The new `Selectors` module should accept either a keyword list or a map, but internally always sort selectors into a canonical order (e.g., by key name, or by a documented canonical order matching the existing test expectations). Existing tests (`engine_overview_live_test.exs:55-60`) assert literal URLs like `view=active&incident_fingerprint=...` — so the canonical order MUST be `view` before `incident_fingerprint` to match current behavior. Verified by inspecting `lib/oban_powertools/web/overview_read_model.ex:427-433` — the existing safe encoder passes a keyword list `[{"view", view}, {"incident_fingerprint", incident.incident_fingerprint}]` which preserves that exact order.

**Warning signs:** Existing tests that previously passed now fail with reordered query string parameters, even though the encoded values are correct.

## Code Examples

### Example A: Migrating `OverviewReadModel.lifeline_incident_path/2`

Before (current code at `lib/oban_powertools/web/overview_read_model.ex:427-433`):
```elixir
defp lifeline_incident_path(view, incident) do
  "/ops/jobs/lifeline?" <>
    URI.encode_query([
      {"view", view},
      {"incident_fingerprint", incident.incident_fingerprint}
    ])
end
```

After:
```elixir
alias ObanPowertools.Web.Selectors

defp lifeline_incident_path(view, incident) do
  Selectors.lifeline_path([
    {"view", view},
    {"incident_fingerprint", incident.incident_fingerprint}
  ])
end
```

The keyword-list form preserves the existing parameter order, which is asserted by tests.

### Example B: TargetType migration at `lib/oban_powertools/lifeline.ex:1073`

Before:
```elixir
Audit.record(
  "lifeline.repair_executed",
  %{type: String.to_atom(preview.target_type), id: preview.target_id},
  metadata,
  repo: repo,
  actor_id: Auth.actor_id(actor)
)
```

After:
```elixir
alias ObanPowertools.Lifeline.TargetType

Audit.record(
  "lifeline.repair_executed",
  %{type: TargetType.to_atom(preview.target_type), id: preview.target_id},
  metadata,
  repo: repo,
  actor_id: Auth.actor_id(actor)
)
```

### Example C: Bounded `normalize_related_evidence` per D-11

Before (`lib/oban_powertools/forensics/evidence_bundle.ex:31-38`):
```elixir
defp normalize_related_evidence(item) do
  Map.new(item, fn
    {:provenance, value} -> {:provenance, Provenance.normalize_provenance(value)}
    {"provenance", value} -> {:provenance, Provenance.normalize_provenance(value)}
    {key, value} when is_binary(key) -> {String.to_atom(key), value}
    pair -> pair
  end)
end
```

After:
```elixir
# Known atom keys emitted by Phase 32+ producers. These atoms exist at
# module-load time, so String.to_existing_atom succeeds without growing
# the atom table (Phase 41 D-11, D-29).
@related_evidence_atom_keys ~w(title summary provenance type resource_id resource_type)a

defp normalize_related_evidence(item) do
  Map.new(item, fn
    {:provenance, value} -> {:provenance, Provenance.normalize_provenance(value)}
    {"provenance", value} -> {:provenance, Provenance.normalize_provenance(value)}
    {key, value} when is_binary(key) -> {normalize_related_evidence_key(key), value}
    pair -> pair
  end)
end

defp normalize_related_evidence_key(key) when is_binary(key) do
  if key in ~w(title summary provenance type resource_id resource_type) do
    String.to_existing_atom(key)
  else
    key
  end
rescue
  ArgumentError -> key
end
```

The compile-time `@related_evidence_atom_keys` attribute ensures the atoms are allocated. The runtime check uses the same list in binary form (or via a `MapSet` if performance matters; in this codebase it doesn't — `related_evidence` lists are short). The `rescue` is defensive belt-and-suspenders in case a deployment somehow loads this module before the producer modules.

### Example D: Status fallback per D-09

Before (`lib/oban_powertools/web/control_plane_presenter.ex:17-20`):
```elixir
def status_label(status) when is_binary(status),
  do: status |> String.to_atom() |> status_label()

def status_label(status), do: Map.get(@status_labels, status, Phoenix.Naming.humanize(status))
```

After:
```elixir
def status_label(status) when is_binary(status) do
  status
  |> String.to_existing_atom()
  |> status_label()
rescue
  ArgumentError -> Phoenix.Naming.humanize(status)
end

def status_label(status), do: Map.get(@status_labels, status, Phoenix.Naming.humanize(status))
```

Both atoms (from the `@statuses` list in `ControlPlane`) and unknown binaries pass through to the same humanize fallback. Behavior is identical for unknown inputs; safe for known atoms (they're already in `@status_labels`).

### Example E: `follow_up_value/2` per D-10

Before (`lib/oban_powertools/web/control_plane_presenter.ex:222-224`):
```elixir
defp follow_up_value(map, key) do
  Map.get(map, key) || Map.get(map, String.to_atom(key))
end
```

After:
```elixir
defp follow_up_value(map, key) do
  Map.get(map, key) || Map.get(map, safe_atom(key))
end

defp safe_atom(key) when is_binary(key) do
  String.to_existing_atom(key)
rescue
  ArgumentError -> nil
end
defp safe_atom(_), do: nil
```

`Map.get(map, nil)` returns nil (or the default), so the outer `||` chain still produces `nil` for unknown keys — identical behavior.

### Example F: D-08 obfuscated-atom cleanup

Before (`lib/oban_powertools/web/lifeline_live.ex:1105`):
```elixir
defp repair_preview_key, do: String.to_existing_atom("preview_" <> "token")
```

After:
```elixir
defp repair_preview_key, do: :preview_token
```

Pure cleanup. No behavior change. The original concatenation `"preview_" <> "token"` is compile-time-resolved, so `String.to_existing_atom/1` is called once at module load.

## Verification rg-Check Baseline

I ran both verification commands from CONTEXT.md D-23 against the current tree on 2026-05-27.

### WR-02 baseline (lib): exactly the six target sites + zero non-target hits

```
$ rg -n "String\.to_atom\(" lib/oban_powertools/web/control_plane_presenter.ex \
                            lib/oban_powertools/web/lifeline_live.ex \
                            lib/oban_powertools/lifeline.ex \
                            lib/oban_powertools/forensics/evidence_bundle.ex

lib/oban_powertools/lifeline.ex:1073    %{type: String.to_atom(preview.target_type), id: preview.target_id}
lib/oban_powertools/lifeline.ex:1206       %{type: String.to_atom(preview.target_type), id: preview.target_id}
lib/oban_powertools/forensics/evidence_bundle.ex:35  {key, value} when is_binary(key) -> {String.to_atom(key), value}
lib/oban_powertools/web/lifeline_live.ex:1368        type: String.to_atom(action_info.target_type)
lib/oban_powertools/web/control_plane_presenter.ex:18   do: status |> String.to_atom() |> status_label()
lib/oban_powertools/web/control_plane_presenter.ex:223  Map.get(map, key) || Map.get(map, String.to_atom(key))
```

**After Phase 41:** all six lines disappear. Zero hits.

The separate sweep `rg -n "String\.to_existing_atom\(" lib/` finds exactly one hit: `lib/oban_powertools/web/lifeline_live.ex:1105` — the D-08 cleanup target. After cleanup, zero hits across `lib/`.

**Out-of-scope `String.to_atom/1` callsites** in `lib/` that Phase 41 does NOT touch but Phase 42 may surface:
- `lib/oban_powertools/control_plane.ex:48` — `workflow_status` casting a diagnosis binary
- `lib/oban_powertools/cron.ex:422` — queue name interpolation for Oban.Job
- `lib/oban_powertools/explain.ex:130` — step state casting

### WR-01 baseline (tests): the existing rg-check pattern produces 12 lines TODAY

```
$ rg -n "incident_fingerprint=.*\#|incident_fingerprint=.*\?|incident_fingerprint=.*\/" \
       test/oban_powertools/web/live/*.exs

test/oban_powertools/web/live/forensics_live_test.exs:126
test/oban_powertools/web/live/forensics_live_test.exs:231
test/oban_powertools/web/live/runbook_copy_contract_test.exs:104
test/oban_powertools/web/live/engine_overview_live_test.exs:55,60,63,64
test/oban_powertools/web/live/lifeline_live_test.exs:121,561,570,576,651
```

**Critical finding:** the rg pattern as written in CONTEXT.md D-23 matches **legitimate test code** — every match above uses `URI.encode_www_form(...)` on the fingerprint value and then concatenates it with the URL structure (which contains `?` or `/`). The pattern is matching the URL's `?` separator, not raw fingerprint interpolation. **The rg-check as currently written cannot pass with zero hits** unless every test that mentions a fingerprint in a URL assertion is deleted — which would defeat the purpose.

**Planner action required:** rework the WR-01 verification rg pattern to actually find *raw fingerprint interpolation*. A better pattern is:
```
rg -n 'incident_fingerprint=#\{[^}]*\}' test/oban_powertools/web/live/*.exs
```
which matches `incident_fingerprint=#{anything}` only — and which produces zero hits today (already passing). Alternative: assert positively that every fingerprint URL in tests is built via `URI.encode_www_form(...)` or `URI.encode_query/1`. See "Open Questions" #4.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact on Phase 41 |
|--------------|------------------|--------------|--------|
| `String.to_atom/1` for any user-derived string | `String.to_existing_atom/1` + rescue, or closed-enum function dispatch | Recommended industry-wide since Elixir 1.0+; codified as warning in many guides | Phase 41 brings the four target modules in line with this baseline. |
| `~r/.../` regex-based URL parameter parsing | `URI.encode_query/1` / `URI.decode_query/1` | Stdlib since Elixir 1.0; preferred always | Already in use; Phase 41 centralizes. |
| Hand-rolled atom safety guards | Module attributes (`@allowed_keys`) + compile-time atom literals | Standard Elixir idiom since module attributes shipped | Used in the recommended D-11 implementation. |

**Deprecated/outdated:**
- Nothing here. The patterns being introduced are mature, well-known idioms.

## Assumptions Log

All claims in this RESEARCH.md are tagged inline above. Summary of `[ASSUMED]` claims:

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `"step"` is included in TargetType for forward-compatibility with CONTEXT.md D-07 even though no current producer emits it. | Codebase Inspection A, Pattern 2 | If `"step"` is omitted, TargetType would raise `FunctionClauseError` for any future caller that legitimately emits `"step"`. If included, no risk — atom interns at compile time. Planner should confirm with the user whether `"step"` is forward-looking or a CONTEXT.md typo. |
| A2 | The `@related_evidence_atom_keys` minimal set (`:title`, `:summary`, `:provenance`, `:type`, `:resource_id`, `:resource_type`) is sufficient for downstream consumers. | Pattern 3, Pitfall 4 | If a caller (especially a host-app integration) passes a known key not in this list, that key will stay binary and downstream atom-dot-access could `KeyError`. The set is derived from inspecting every producer in `lib/` — comprehensive within the codebase but cannot speak to third-party producers. |
| A3 | The new `ObanPowertools.Web.Selectors` and `ObanPowertools.Lifeline.TargetType` module names are appropriate per the naming conventions of this codebase. | Architecture Patterns | If the maintainer prefers different names (e.g., `RunbookSelectors`, `TargetTypeConverter`), trivial rename. Naming is in Claude's Discretion per CONTEXT.md. |
| A4 | The `URI.encode_query/1` ordering of selectors (using keyword list to preserve order) must match the current test expectations. | Pitfall 5 | If the planner ignores order and uses a map, existing tests will fail (deterministic failure, easy to fix in W4). |
| A5 | The CONTEXT.md D-23 WR-01 rg-check pattern is broken as written. | Verification rg-Check Baseline | If the planner accepts D-23 verbatim, Phase 41 cannot exit with "zero hits, no carve-outs" because the pattern matches legitimate test code. The planner must either (a) reword the rg pattern, or (b) accept that hits in tests are expected. See "Open Questions" #4. |

## Open Questions

1. **Is `"step"` a real producer-emitted `target_type` value, or a CONTEXT.md typo?**
   - What we know: No `lib/` site emits `target_type: "step"`. The producers use `"workflow_step"`. CONTEXT.md D-07 explicitly lists `"step"`.
   - What's unclear: Whether D-07 is forward-looking (future producer might shorten the value) or a slip when summarizing the enum.
   - Recommendation: Include `to_atom("step"), do: :step` in `TargetType` for forward compatibility per D-07 verbatim. Document in `@moduledoc` that the current producer set is `"job"`/`"workflow"`/`"workflow_step"`. Zero-cost defensiveness; matches CONTEXT.md exactly.

2. **What is the complete known-key allowlist for `related_evidence`?**
   - What we know: Producers in `lib/oban_powertools/forensics.ex:116-127`, `lib/oban_powertools/forensics/limiter_history.ex:203-222`, `lib/oban_powertools/forensics/cron_history.ex:282` emit only `:title`, `:summary`, `:provenance`. The `forensics_live.ex:240-245` template accesses these three by atom-dot-access.
   - What's unclear: Whether host-app integrations (or future Phase 41+ extensions) need additional keys.
   - Recommendation: Allowlist `[:title, :summary, :provenance, :type, :resource_id, :resource_type]` — the conservative superset of producer-emitted keys plus the partial-evidence linkage keys (`type`, `resource_id`, `resource_type`). Document the list in `@related_evidence_atom_keys` so future maintainers can extend it explicitly.

3. **D-17 scope: migrate the six cited callsites only, or all 26+ selector-construction sites?**
   - What we know: D-17 says "Existing safe callsites should be rewritten to use the new helper rather than left in place." D-06 lists six specific sites. The rest of the eleven URI-encoding files in `lib/` arguably qualify as "existing safe callsites."
   - What's unclear: Whether the planner should produce a phase that migrates all 26+ sites (broader risk, broader gain) or stops at the six (narrower change, leaves "parallel safe paths" that D-17 warns against).
   - Recommendation: Migrate **the six cited sites + the eight raw-interpolation sites** (`forensics.ex:481-494` and `overview_read_model.ex:309, 311, 335, 337, 394, 403, 406` per my Section B table). Raw interpolation is where WR-01's hazard actually lives. Leave the already-safe `URI.encode_query`-based callsites in `forensics_live.ex`, `cron_live.ex`, `limiters_live.ex`, `audit_live.ex`, `limiter_history.ex`, `cron_history.ex`, `control_plane_presenter.ex` for a future centralization sweep — they don't pose a delimiter-encoding risk but do duplicate effort. This staged approach gives "one place to harden, one place to test" for the hazard surface while limiting blast radius. Surface this question to the user explicitly during planning.

4. **The CONTEXT.md D-23 WR-01 rg-check pattern matches legitimate test code.**
   - What we know: Running `rg -n "incident_fingerprint=.*\#|incident_fingerprint=.*\?|incident_fingerprint=.*\/" test/oban_powertools/web/live/*.exs` returns 12 lines today, every one of which is correct safely-encoded test code.
   - What's unclear: Whether D-23 intended `incident_fingerprint=#\{` (matching the interpolation operator literally) or whether it expected zero hits including legitimate URL-with-fingerprint test assertions.
   - Recommendation: The planner must either (a) reword the rg pattern to match raw interpolation only (`incident_fingerprint=#\{[^}]*\}`), or (b) clarify with the user that "zero hits, no carve-outs" applies after the rewrite — which is impossible with the current pattern. **Preferred:** rewrite the pattern; the planner should write the corrected rg-check into the Plan's `<verification>` block.

5. **Does the `selection_path/1` non-canonical-selectors set (`row-id`, `action`) belong in the new helper?**
   - What we know: `lib/oban_powertools/web/lifeline_live.ex:845-859` passes `row-id`, `action`, etc. — outside the locked stable set.
   - What's unclear: Whether the Selectors helper should accept these (with a documented permissive policy) or reject them (forcing callers to use a more general `Selectors.encode/2` for non-canonical keys).
   - Recommendation: Permissive policy: the helper accepts any keyword list / map and applies `URI.encode_query/1` over the lot, dropping nil/"". The "canonical" set is documented in `@moduledoc` for human discoverability and asserted positively in test (`forensics_test.exs:119` already does this). This keeps the migration simple while documenting the locked set.

## Environment Availability

Phase 41 is pure-Elixir code change + test add — no external tools beyond what's already required to build and test `oban_powertools`.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | All Elixir builds and tests | ✓ (assumed; not probed) | bundled with Elixir 1.19 | — |
| `rg` (ripgrep) | D-23 verification rg-checks | ✓ (confirmed during this research) | — | `grep -rn` (slower, less precise) |
| PostgreSQL | LiveView tests via `Ecto.Adapters.SQL.Sandbox` | ✓ (assumed; not probed — test runs implied by existing CI) | — | — |

No missing dependencies. Phase 41 does not introduce any new external dependency.

## Validation Architecture

> nyquist_validation is not explicitly disabled in `.planning/config.json`, so this section is included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19 stdlib) + Phoenix.LiveViewTest 1.1.30 |
| Config file | `test/test_helper.exs` (migration boot + sandbox mode) |
| Quick run command | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs --seed 0` |
| Full suite command | `mix test --seed 0` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPS-03 | Overview attention links survive delimiter-heavy fingerprints (Selectors round-trip integrity from overview surface) | LiveView integration | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs --seed 0` | ✅ extends existing |
| RNB-01 | Forensic / runbook entry surfaces resolve delimiter-heavy fingerprints back to the correct incident bundle (Selectors round-trip integrity at forensics) | LiveView integration | `mix test test/oban_powertools/web/live/forensics_live_test.exs --seed 0` | ✅ extends existing |
| RNB-02 | Audit subject `%{type: atom, id: string}` shape preserved across all three target_type sites under refactor | LiveView integration + unit | `mix test test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/lifeline_test.exs --seed 0` | ✅ extends existing |
| WR-01 | Selectors encoder produces correct query strings for delimiter-heavy values; nil/"" dropped | Unit | `mix test test/oban_powertools/web/selectors_test.exs` | ❌ Wave 0 — create file |
| WR-02 | TargetType helper returns correct atoms for known strings, raises for unknown | Unit | `mix test test/oban_powertools/lifeline/target_type_test.exs` | ❌ Wave 0 — create file |
| WR-02 | `normalize_related_evidence` returns atoms for known keys, binaries for unknown, no atom-table growth | Unit | `mix test test/oban_powertools/forensics/evidence_bundle_test.exs` | ❌ Wave 0 — create file + directory |

### Sampling Rate
- **Per task commit:** `mix test <single-file> --seed 0` (the file most recently edited)
- **Per wave merge:** `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/lifeline_test.exs --seed 0`
- **Phase gate:** `mix test --seed 0` (full suite green) + both rg-checks produce expected results before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `test/oban_powertools/web/selectors_test.exs` — covers WR-01 unit behavior
- [ ] `test/oban_powertools/lifeline/target_type_test.exs` — covers WR-02 TargetType behavior
- [ ] `test/oban_powertools/forensics/evidence_bundle_test.exs` (new file) and parent directory `test/oban_powertools/forensics/` — covers WR-02 normalization behavior
- [ ] Framework install: none — existing `mix test` config covers everything.

## Security Domain

> Phase 41 is explicitly an atom-safety / DoS-hardening phase. Security domain applies.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 41 does not modify auth |
| V3 Session Management | no | No session model change |
| V4 Access Control | no | LiveAuth contracts unchanged |
| V5 Input Validation | **yes** | Bounded atom normalization (`String.to_existing_atom` + rescue, allowlists, closed-enum dispatch) per D-09 / D-10 / D-11 / D-12. URL selector encoding via `URI.encode_query/1` per D-14 / D-15. |
| V6 Cryptography | no | No crypto |
| V7 Error Handling | yes (light) | `rescue ArgumentError` catches only the expected error class; downstream code receives nil / binary fallback per D-09 / D-10 / D-11 |
| V8 Data Protection | no | No data-at-rest changes |
| V13 API and Web Service | yes (light) | Selector encoding ensures URL parameters survive delimiters intact through Phoenix LiveView round-trip |

### Known Threat Patterns for Elixir / Phoenix LiveView Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Atom-table exhaustion via `String.to_atom/1` on user input (BEAM has hard atom-count limit ~1M; not garbage-collected) | Denial of Service | `String.to_existing_atom/1` + rescue, or closed-enum function-clause dispatch. **This is what Phase 41 implements.** |
| URL parameter injection via unencoded delimiters | Tampering | `URI.encode_query/1` / `URI.encode_www_form/1`. Already used across `lib/`; Phase 41 centralizes. |
| Map-key atom poisoning (binary keys silently coerced to atoms in deserialized payloads) | Denial of Service | Bounded normalization with known-key allowlist per D-11. |
| Cross-surface link tampering (operator follows a crafted incident_fingerprint URL that resolves to a different incident) | Tampering / Information Disclosure | The fingerprint is a derived deterministic identifier per Phase 4 — the encoding centralization in Phase 41 preserves this identity through arbitrary URL delimiters; round-trip-decode tests in D-19/D-20 verify it. |

## Sources

### Primary (HIGH confidence)
- Direct inspection of the following files at HEAD (commit `ab00fac`):
  - `lib/oban_powertools/web/control_plane_presenter.ex`
  - `lib/oban_powertools/web/lifeline_live.ex`
  - `lib/oban_powertools/web/overview_read_model.ex`
  - `lib/oban_powertools/web/workflows_live.ex`
  - `lib/oban_powertools/web/forensics_live.ex`
  - `lib/oban_powertools/web/cron_live.ex`
  - `lib/oban_powertools/web/limiters_live.ex`
  - `lib/oban_powertools/web/audit_live.ex`
  - `lib/oban_powertools/lifeline.ex`
  - `lib/oban_powertools/lifeline/repair_preview.ex`
  - `lib/oban_powertools/audit.ex`
  - `lib/oban_powertools/control_plane.ex`
  - `lib/oban_powertools/forensics.ex`
  - `lib/oban_powertools/forensics/evidence_bundle.ex`
  - `lib/oban_powertools/forensics/runbook_entry.ex`
  - `lib/oban_powertools/forensics/limiter_history.ex`
  - `lib/oban_powertools/forensics/cron_history.ex`
  - `lib/oban_powertools/workflow/runtime.ex`
  - `test/test_helper.exs`
  - `test/support/live_case.ex`
  - `test/oban_powertools/web/live/engine_overview_live_test.exs`
  - `test/oban_powertools/web/live/forensics_live_test.exs`
  - `test/oban_powertools/web/live/lifeline_live_test.exs`
  - `test/oban_powertools/forensics_test.exs`
  - `test/oban_powertools/lifeline_test.exs`
  - `mix.exs`, `mix.lock`, `.formatter.exs`
- `.planning/phases/41-runbook-link-fidelity-and-atom-safety-hardening/41-CONTEXT.md` (29 locked decisions)
- `.planning/phases/41-runbook-link-fidelity-and-atom-safety-hardening/41-01-PLAN.md` (pre-context plan — to be replaced per D-25)
- `.planning/REQUIREMENTS.md` (OPS-03, RNB-01, RNB-02)
- `.planning/STATE.md` (milestone v1.4 sequencing)
- `.planning/ROADMAP.md` (Phase 41 entry — note D-26 staleness)
- `.planning/PROJECT.md` (recommendation-first decision posture)
- `.planning/v1.4-v1.4-MILESTONE-AUDIT.md` (origin of WR-01 / WR-02)
- Phase 34 D-22 / D-24 / D-25 / D-09 — referenced via Phase 41 CONTEXT.md D-03

### Secondary (MEDIUM confidence — Elixir ecosystem idiom verification)
- WebSearch: "Elixir String.to_existing_atom rescue ArgumentError best practice idiom" — confirmed canonical pattern across multiple Elixir-community sources.

### Tertiary (LOW confidence)
- None. All claims either traced to a direct codebase inspection or to an authoritative Elixir-community pattern reference.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Phase 41 introduces no new dependency; existing stack inspected directly.
- Architecture: HIGH — every callsite read; producer enums traced to source.
- Pitfalls: HIGH — Pitfalls 1-5 derived from direct codebase inspection and known BEAM atom-table semantics.
- Open Questions: MEDIUM — five real questions remain; recommendations provided for each but a few need user confirmation (especially Q3 D-17 scope and Q4 broken D-23 rg-check).

**Research date:** 2026-05-27
**Valid until:** 2026-06-26 (30 days; the codebase is stable, no upstream library bumps imminent)

## RESEARCH COMPLETE

**Phase:** 41 - runbook-link-fidelity-and-atom-safety-hardening
**Confidence:** HIGH

### Key findings
- All six WR-02 atom-conversion sites verified at exact lines CONTEXT.md cites; producer enums traced (only `"job"`, `"workflow"`, `"workflow_step"` emitted today — `"step"` from D-07 is forward-looking).
- WR-01 selector-encoding callsite scope is **broader than CONTEXT.md enumerates**: 26+ encoder sites in 11 files. Eight of them use raw interpolation (the actual delimiter hazard); the rest already use safe encoders but per D-17 should also migrate. Surfaced as Open Question #3 with a staged-scope recommendation.
- The CONTEXT.md D-23 WR-01 rg-check pattern is **broken** — it matches 12 lines of legitimate safely-encoded test code today and cannot pass with zero hits as written. Surfaced as Open Question #4 with a corrected pattern.
- The forensics_live template at `web/forensics_live.ex:240-245` accesses `related_evidence` items via atom-dot-access (`item.title`, `item.summary`, `item.provenance`) — the D-11 bounded normalization allowlist must include these keys at minimum or unknown items will crash render.
- The `selection_path/1` callsite in `lifeline_live.ex:845-859` uses non-canonical selectors (`row-id`, `action`) outside the locked stable set — the Selectors helper must be permissive enough to accept them while documenting the canonical set positively.
- No new dependencies needed; pure Elixir-stdlib + existing Phoenix LiveView. No runtime state migrations needed. No external tools beyond `mix` and `rg`.

### File created
`.planning/phases/41-runbook-link-fidelity-and-atom-safety-hardening/41-RESEARCH.md`

### Open items the planner must address
1. Confirm `"step"` inclusion in TargetType (recommended: include for forward compat per D-07).
2. Confirm `related_evidence` known-key allowlist (recommended: `[:title, :summary, :provenance, :type, :resource_id, :resource_type]`).
3. **Decide D-17 scope** (recommended: migrate 6 cited + 8 raw-interpolation sites = 14 total; defer the other ~12 already-safe sites to a future sweep). Worth surfacing to the user.
4. **Replace the broken D-23 WR-01 rg-check** with `rg -n 'incident_fingerprint=#\{[^}]*\}' test/oban_powertools/web/live/*.exs` (zero hits today; remains zero after Phase 41) — or restructure the check entirely.
5. Decide Selectors-helper permissiveness for non-canonical keys (recommended: permissive + documented canonical set).

### Ready for planning
Research complete. The planner can produce a single bundled 41-01-PLAN.md replacing the current pre-context plan per D-25.
