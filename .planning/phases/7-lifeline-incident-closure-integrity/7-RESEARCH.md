# Phase 7: Lifeline Incident Closure Integrity - Research

**Researched:** 2026-05-20
**Domain:** Lifeline incident lifecycle, transactional repair closure, and Phoenix LiveView refresh integrity [VERIFIED: codebase grep]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Downstream agents should treat the recommendations in this context as locked defaults and avoid reopening them unless a later choice would materially affect correctness, operator trust, durability, or the public behavior of the repair flow.
- **D-02:** Shift defaults left for this project: prefer decisive best-practice recommendations over re-asking, except for unusually high-impact semantic changes.

### Incident Retirement Model
- **D-03:** Phase 7 should use a hybrid closure model: a successful repair explicitly transitions the incident row from `active` to `resolved`, while future projection still validates against current stranded state before reopening anything.
- **D-04:** Incident retirement must happen inside the same `Ecto.Multi` as target mutation, preview consumption, and immutable audit write. A repair is not considered complete unless the incident lifecycle transitions atomically with the rest of the action.
- **D-05:** Resolved incidents remain in the durable `oban_powertools_lifeline_incidents` table. Do not hard-delete, archive-move, or otherwise make closure history disappear as part of the Phase 7 hot-path fix.
- **D-06:** Incident lifecycle metadata should stay explicit and grep-able on the incident row. At minimum, planning should preserve/use `status` and `resolved_at`; if additional lifecycle fields are added they should support reopen/history clarity rather than introduce opaque suppression state.

### Re-Projection and Reopen Rules
- **D-07:** `active` status must be derived from current stranded state, not from historical incident existence alone.
- **D-08:** `project_incidents/2` must reconcile stale active rows to `resolved` when their fingerprint is no longer present in the current candidate set.
- **D-09:** For `dead_executor` incidents, only currently stranded targets should qualify as active evidence. Jobs that have already been rescued into `available` or `retryable` must not keep the incident active merely because historical `executor_id` metadata is still present.
- **D-10:** For `workflow_stuck` incidents, only workflow steps whose current state and current blocker fields still make them stuck should qualify as active evidence.
- **D-11:** Reopen behavior should reuse the same logical incident identity (`incident_fingerprint`) and lifecycle row rather than creating noisy successor rows for the same underlying issue class. If extra lifecycle counters/timestamps are added, they should reinforce this stable-identity model.
- **D-12:** Do not use cooldown windows, silent suppression markers, or other “magic” anti-reprojection tricks as the primary fix. If projection is correct, closure should come from real state reconciliation, not timers.

### Repair Failure and Safety Semantics
- **D-13:** Unauthorized, drifted, invalid-reason, or otherwise failed repair attempts must not retire the incident.
- **D-14:** `Heartbeat Late` remains a warning posture only. Preview/execute rejection for late executors should continue to leave the incident lifecycle unchanged.
- **D-15:** Resolution semantics should stay conservative and evidence-first: an incident may only resolve when the acted-on target mutation succeeds and the resulting system state no longer satisfies the active incident criteria.

### UI Closure Behavior
- **D-16:** The Lifeline UI should separate active and resolved incident views instead of making repaired incidents simply disappear with no durable destination.
- **D-17:** Default landing posture remains active incidents / `Needs Review`.
- **D-18:** After a successful repair, the acted-on incident should leave the active list but remain visible in a resolved state long enough for the operator to confirm the success message, after-state, and inline audit evidence.
- **D-19:** The UI should preserve semantic clarity: active views answer “what still needs action,” while resolved views answer “what just happened and what proof was written.”
- **D-20:** Do not keep resolved rows mixed into the active list by default. That muddies `Needs Review` semantics and increases re-action risk.
- **D-21:** Do not rely on toast-only or transient-only confirmation for repair closure. Correctness-sensitive operator actions need a durable resolved destination and inline evidence.

### Verification Bar
- **D-22:** Phase 7’s minimum verification bar is backend plus LiveView refresh/remount regression coverage, not backend-only proof.
- **D-23:** Verification must prove all of the following:
  successful repair retires the incident durably,
  rerunning projection does not leave it active when no qualifying evidence remains,
  failed/drifted/unauthorized paths do not retire it,
  and a fresh Lifeline mount no longer shows the repaired incident in the active list while preserving closure evidence.
- **D-24:** Browser E2E is not required for this phase. The idiomatic test posture for this library is DB-backed integration tests plus `Phoenix.LiveViewTest`.
- **D-25:** Add a targeted compat/backfill test only if the chosen implementation changes incident persistence shape or requires migration semantics for pre-Phase-7 rows.

### the agent's Discretion
- Exact lifecycle field names beyond the already-existing `status` and `resolved_at`, provided the resulting model stays explicit, durable, and easy to query.
- Exact `Ecto.Multi` composition and projection batching, provided reconciliation remains atomic and operator-trustworthy.
- Exact Active/Resolved tab wording and detail-pane behavior, provided the page remains incident-first, evidence-first, and least-surprise.

### Deferred Ideas (OUT OF SCOPE)
- A broader generic incident-management model beyond Powertools-owned repair flows.
- Cooldown-based or suppression-based anti-noise systems for incident reappearance.
- Browser-level E2E infrastructure for this phase.
- Hard-retirement/archive movement of resolved incidents as part of the immediate correctness fix.
- Broad self-healing or automatic rescue expansion beyond the conservative repair semantics already established in Phase 4.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIF-02 | Build an SRE-grade Dry-Run Repair Center for orphaned jobs and stuck workflows, closing the remaining post-repair retirement gap. [VERIFIED: .planning/REQUIREMENTS.md] | Atomic incident resolution in `execute_repair/5`, candidate-set reconciliation in `project_incidents/2`, dead-executor evidence narrowing, resolved-view LiveView UX, and backend plus remount regression tests. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 7 is a correctness repair inside the existing Lifeline architecture, not a redesign. The incident table already has durable lifecycle fields (`status`, `resolved_at`) and a unique stable identity (`incident_fingerprint`), so the safest plan is to reuse that schema and make the repair transaction and projection logic honor it consistently. [VERIFIED: lib/oban_powertools/lifeline/incident.ex] [VERIFIED: test/support/migrations/3_phase_4_tables.exs]

The current gap is twofold. First, `apply_repair/5` mutates the target, consumes the preview, and writes audit evidence, but it never updates the incident row in the same transaction. Second, `project_incidents/2` only upserts currently found candidates and never resolves stale active rows; for dead executors it also still counts `available` and `retryable` jobs as active evidence, which means a rescued job can be re-projected as still active on refresh. [VERIFIED: lib/oban_powertools/lifeline.ex] [VERIFIED: mix test]

The UI currently reloads active incidents after execute and reselects by the old active-row id, which means the operator loses a durable closure destination as soon as the row leaves the active set. Planning should therefore pair backend lifecycle fixes with a small LiveView contract change: keep active incidents as the default view, add a resolved destination for the acted-on incident, and verify both immediate refresh and fresh mount behavior with `Phoenix.LiveViewTest`. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

**Primary recommendation:** Implement Phase 7 as a code-first fix in `Lifeline`: resolve the incident inside the existing `Ecto.Multi`, reconcile stale active rows during projection, narrow dead-executor evidence to truly stranded work, and add LiveView tests that assert resolved-row continuity after refresh and remount. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Incident candidate projection | API / Backend | Database / Storage | `project_incidents/2` derives active evidence from heartbeats, jobs, and workflow steps and persists the incident read model. [VERIFIED: lib/oban_powertools/lifeline.ex] |
| Atomic repair execution and closure | API / Backend | Database / Storage | `execute_repair/5` and `apply_repair/5` own mutation ordering and transaction semantics; the DB row is the durable source of truth. [VERIFIED: lib/oban_powertools/lifeline.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Incident lifecycle persistence | Database / Storage | API / Backend | `oban_powertools_lifeline_incidents` already stores status, fingerprint, and resolution timestamp and has indexes for lifecycle queries. [VERIFIED: test/support/migrations/3_phase_4_tables.exs] |
| Closure visibility and operator continuity | Frontend Server (SSR) | API / Backend | `LifelineLive` controls which incidents are listed, what row stays selected, and whether resolved evidence remains visible after execute. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] |
| Regression proof for refresh/remount | Frontend Server (SSR) | API / Backend | Phoenix LiveView behavior must be proven through `live/2`, `render_click/2`, and a fresh mount path, not inferred from backend tests. [VERIFIED: test/oban_powertools/web/live/lifeline_live_test.exs] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | 3.13.6 locked; 3.14.0 latest on Hex (2026-05-19) | Lifecycle row updates, projection queries, and `Ecto.Multi` orchestration | The repo already uses Ecto schemas, queries, and `Multi`; Phase 7 should extend that path rather than inventing custom transaction code. [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Ecto SQL | 3.13.5 locked; 3.14.0 latest on Hex (2026-05-19) | Repo transaction and SQL adapter support | All current persistence and test migrations run through Ecto SQL; no extra persistence layer is needed. [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto_sql] |
| Oban | 2.22.1 locked; 2.22.1 latest on Hex (2026-04-30) | Job state source of truth for stranded vs rescued work | Dead-executor evidence is derived from `oban_jobs`, so the fix must stay aligned with actual Oban job states. [VERIFIED: mix.lock] [VERIFIED: mix hex.info oban] [VERIFIED: lib/oban_powertools/lifeline.ex] |
| Phoenix LiveView | 1.1.30 locked; 1.1.30 latest stable on Hex (2026-05-05) | Lifeline UI refresh/remount behavior and regression tests | The UI gap is in a LiveView flow, and the existing test posture already uses `Phoenix.LiveViewTest`. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: test/oban_powertools/web/live/lifeline_live_test.exs] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix | 1.8.7 locked; 1.8.7 latest on Hex (2026-05-06) | Routed LiveView mount path and SSR lifecycle | Use for fresh-mount route tests and any tab/filter params if the resolved view becomes URL-addressable. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Oban Web | 2.12.4 locked; 2.12.4 latest on Hex (2026-05-11) | Existing dashboard shell deep-link target | Keep using it only for generic job inspection links; do not move closure semantics into Oban Web. [VERIFIED: mix.lock] [VERIFIED: mix hex.info oban_web] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] |
| Postgrex | 0.22.2 locked; 0.22.2 latest on Hex (2026-05-12) | Local Postgres driver for integration tests | Use through the existing repo; no extra data store or queue adapter is needed. [VERIFIED: mix.lock] [VERIFIED: mix hex.info postgrex] [VERIFIED: local env] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `Incident` lifecycle fields | Add a new archive/suppression table | Violates Phase 7 scope and adds more state than the existing `status` / `resolved_at` model already requires. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] |
| `Ecto.Multi` in `apply_repair/5` | Manual `Repo.transaction(fn -> ... end)` control flow | Would work, but it loses the repo’s established named-step pattern and makes failure attribution less consistent with existing code. [VERIFIED: lib/oban_powertools/lifeline.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| `Phoenix.LiveViewTest` route tests | Browser E2E | Explicitly out of scope and unnecessary for proving refresh/remount semantics in this library. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** Repo-locked versions were verified from `mix.lock` and installed dependency metadata; current Hex release dates were verified with `mix hex.info`. [VERIFIED: mix.lock] [VERIFIED: mix deps] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info oban]

## Architecture Patterns

### System Architecture Diagram

```text
Lifeline LiveView action / page mount
  -> Lifeline.project_incidents(repo)
    -> heartbeat classification
    -> current stranded-job / stuck-step candidate queries
    -> upsert matching fingerprints as active
    -> reconcile stale active fingerprints to resolved
  -> Lifeline.list_incidents(status: active | resolved)
  -> render active default view + resolved closure destination

Preview Repair Plan
  -> Lifeline.preview_repair(repo, actor, attrs)
    -> auth check
    -> derive incident + target snapshot
    -> persist/reuse pending preview

Execute Repair Plan
  -> Lifeline.execute_repair(repo, actor, preview_token, reason)
    -> auth + reason + drift checks
    -> Ecto.Multi
      -> mutate target
      -> resolve matching incident row if active evidence is gone
      -> consume preview
      -> write immutable audit event
    -> LiveView reloads
      -> active list no longer contains resolved fingerprint
      -> resolved view still shows acted-on incident and audit proof
```

This is the architecture already implied by the phase context and current code boundaries; the missing piece is the reconciliation step and resolved-view continuity. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] [VERIFIED: lib/oban_powertools/lifeline.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]

### Recommended Project Structure
```text
lib/
├── oban_powertools/lifeline.ex              # projection, execute transaction, lifecycle reconcile
├── oban_powertools/lifeline/incident.ex     # durable incident lifecycle schema
└── oban_powertools/web/lifeline_live.ex     # active/resolved UI and refresh selection semantics

test/
├── oban_powertools/lifeline_test.exs        # backend lifecycle and reprojection invariants
└── oban_powertools/web/live/lifeline_live_test.exs  # LiveView refresh/remount regressions
```

### Pattern 1: Candidate-Set Projection With Stale-Row Reconciliation
**What:** Build the current active fingerprint set from live stranded evidence, upsert those rows as `active`, then resolve any previously `active` incident rows whose fingerprint no longer appears in the candidate set. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] [VERIFIED: lib/oban_powertools/lifeline.ex]
**When to use:** Every `project_incidents/2` run, including LiveView refresh loads and any backend maintenance path that reprojects incidents. [VERIFIED: lib/oban_powertools/lifeline.ex]
**Example:**
```elixir
# Source: lib/oban_powertools/lifeline.ex + Ecto.Multi docs
candidate_fingerprints = MapSet.new(Enum.map(candidates, & &1.incident_fingerprint))

repo.all(from i in Incident, where: i.status == "active")
|> Enum.reject(&MapSet.member?(candidate_fingerprints, &1.incident_fingerprint))
|> Enum.each(fn incident ->
  incident
  |> Incident.changeset(%{status: "resolved", resolved_at: now})
  |> repo.update!()
end)
```

### Pattern 2: Resolve-In-Transaction After Target Mutation
**What:** Keep incident retirement in the same `Ecto.Multi` as target mutation, preview consumption, and audit write, but only resolve after re-checking current evidence for that fingerprint. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] [VERIFIED: lib/oban_powertools/lifeline.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
**When to use:** On every successful execute path; never on unauthorized, drifted, or invalid-reason failures. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] [VERIFIED: lib/oban_powertools/lifeline.ex]
**Example:**
```elixir
# Source: Ecto.Multi docs + current apply_repair shape
Multi.new()
|> Multi.run(:target, fn repo, _changes -> mutate_target(repo, preview, now) end)
|> Multi.run(:incident, fn repo, %{target: _target} -> resolve_if_inactive(repo, preview, now) end)
|> Multi.update(:preview, RepairPreview.changeset(preview, %{status: "executed", consumed_at: now}))
|> Multi.run(:audit, fn repo, %{preview: preview_record} -> write_repair_audit(repo, preview_record, actor, reason) end)
|> repo.transaction()
```

### Pattern 3: Active/Resolved Split With Stable Post-Execute Context
**What:** Default the page to active incidents, but after execute ensure the selected fingerprint is still visible in a resolved destination instead of falling back to an unrelated first active row. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]
**When to use:** Any successful execute or fresh mount where the last acted-on incident is now resolved. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
**Example:**
```elixir
# Source: lib/oban_powertools/web/lifeline_live.ex
socket
|> assign(:selected_status, "resolved")
|> assign(:selected_fingerprint, preview.incident_fingerprint)
|> load_data(preview.incident_fingerprint)
```

### Anti-Patterns to Avoid
- **Upsert-only projection:** `project_incidents/2` currently only upserts found candidates and returns them, which leaves stale `active` rows behind forever. [VERIFIED: lib/oban_powertools/lifeline.ex]
- **Historical-executor evidence as active proof:** Counting `available` and `retryable` jobs as dead-executor evidence causes rescued jobs to keep incidents active after repair. [VERIFIED: lib/oban_powertools/lifeline.ex]
- **Execute-success without lifecycle transition:** A repair that changes the target but leaves the incident row active breaks operator trust and phase success criteria. [VERIFIED: lib/oban_powertools/lifeline.ex] [VERIFIED: .planning/ROADMAP.md]
- **Active-list-only reload after execute:** `load_data(row.id)` after a successful execute has no resolved destination and can silently reselect another active row once the original row disappears. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-step transaction ordering | Ad hoc transaction code with manual rollback branches | `Ecto.Multi` with named `run`/`update` steps | The repo already uses `Multi`; it gives ordered rollback semantics and clearer failure attribution. [VERIFIED: lib/oban_powertools/lifeline.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Repair audit persistence | A new Phase 7-specific audit table | Existing `Audit.record/4` flow | The immutable audit path is already implemented and tested; Phase 7 should extend it, not fork it. [VERIFIED: lib/oban_powertools/lifeline.ex] [VERIFIED: test/oban_powertools/lifeline_test.exs] |
| LiveView refresh proof | Manual browser spot checks only | `Phoenix.LiveViewTest.live/2`, `render_click/2`, `render_change/2` | The official test tool already supports routed mounts and event-driven assertions and matches the repo’s current verification style. [VERIFIED: test/oban_powertools/web/live/lifeline_live_test.exs] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |

**Key insight:** Phase 7 is mostly about making existing durable primitives agree with each other. New state machines or suppression mechanisms would increase ambiguity instead of reducing it. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Rescued Jobs Still Count As Dead-Executor Evidence
**What goes wrong:** A job rescue moves the job to `available`, but the next projection still treats it as active dead-executor evidence. [VERIFIED: lib/oban_powertools/lifeline.ex]
**Why it happens:** `upsert_dead_executor_incident/3` currently queries jobs in `["executing", "available", "retryable"]` for the old `executor_id`. [VERIFIED: lib/oban_powertools/lifeline.ex]
**How to avoid:** Restrict dead-executor evidence to genuinely stranded targets, with `executing` jobs as the primary proof and any step evidence checked against current stuck/owned state, not historical metadata alone. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md]
**Warning signs:** A green execute path followed by the same fingerprint reappearing in `Needs Review` immediately after refresh. [VERIFIED: .planning/phases/4-VERIFICATION.md]

### Pitfall 2: Resolving Only On Execute, Not On Reprojection
**What goes wrong:** Manual repair can resolve one row, but stale `active` incidents persist forever if evidence disappears through some other path. [VERIFIED: lib/oban_powertools/lifeline.ex]
**Why it happens:** `project_incidents/2` does not currently reconcile active rows whose fingerprints are absent from the current candidate set. [VERIFIED: lib/oban_powertools/lifeline.ex]
**How to avoid:** Make projection idempotent over the whole active set: upsert matching fingerprints and resolve non-matching active rows during each run. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md]
**Warning signs:** `list_incidents(status: "active")` returns rows whose target jobs or steps no longer satisfy the incident criteria. [VERIFIED: lib/oban_powertools/lifeline.ex]

### Pitfall 3: Lost Operator Context After Successful Execute
**What goes wrong:** The success message is shown, but the acted-on incident disappears from the active list and the page may select another active row. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]
**Why it happens:** `handle_event("execute", ...)` clears preview state and calls `load_data(row.id)`, while `load_data/2` only loads active incidents and falls back to the first row when the requested one is gone. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]
**How to avoid:** Track selection by incident fingerprint plus status bucket and provide a resolved destination for the just-executed incident. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md]
**Warning signs:** Post-execute HTML still says success, but the detail pane no longer corresponds to the incident that was repaired. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]

### Pitfall 4: False Confidence From Green Existing Tests
**What goes wrong:** The current suite passes while `LIF-02` remains open. [VERIFIED: mix test] [VERIFIED: .planning/phases/4-VERIFICATION.md]
**Why it happens:** Existing tests prove preview/execute/audit and drift handling, but they do not yet assert incident retirement, stale-row reconciliation, or fresh-mount closure visibility. [VERIFIED: test/oban_powertools/lifeline_test.exs] [VERIFIED: test/oban_powertools/web/live/lifeline_live_test.exs]
**How to avoid:** Add regression tests that fail against the current code before implementation work is considered complete. [VERIFIED: mix test]
**Warning signs:** A PR that modifies only `lifeline.ex` behavior but adds no new lifecycle assertions in the backend or LiveView suites. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources and current repo structure:

### Ordered Transaction Step For Incident Resolution
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Multi.new()
|> Multi.run(:target, fn repo, _changes -> mutate_target(repo, preview, now) end)
|> Multi.run(:incident, fn repo, %{target: _target} -> resolve_if_inactive(repo, preview, now) end)
|> Multi.update(:preview, RepairPreview.changeset(preview, %{status: "executed", consumed_at: now}))
|> Multi.run(:audit, fn repo, %{preview: preview_record} -> write_repair_audit(repo, preview_record, actor, reason) end)
|> repo.transaction()
```

### Routed LiveView Mount For Fresh-Page Proof
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
{:ok, view, html} = live(conn, "/ops/jobs/lifeline")
assert html =~ "Needs Review"

html =
  view
  |> element("button[phx-click='preview']")
  |> render_click()
```

### Current Gap Anchor
```elixir
# Source: lib/oban_powertools/lifeline.ex
def project_incidents(repo, opts \\ []) do
  ...
  dead_executor_incidents ++ workflow_stuck_incidents
end
```

The current function returns newly projected incidents but does not resolve stale active rows. [VERIFIED: lib/oban_powertools/lifeline.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Upsert incident candidates and leave historical active rows untouched. [VERIFIED: lib/oban_powertools/lifeline.ex] | Reconcile the active set against current evidence and resolve rows whose fingerprint no longer qualifies. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] | Phase 7 decision context dated 2026-05-20. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] | Prevents stale active incidents and supports stable reopen semantics. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] |
| Success toast plus active-list reload. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] | Active default view plus explicit resolved destination with inline audit proof. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] | Phase 7 decision context dated 2026-05-20. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] | Preserves operator trust after execute and on fresh mount. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] |

**Deprecated/outdated:**
- Counting `available` or `retryable` jobs as dead-executor active evidence is outdated for this phase and explicitly contradicts the locked reopen rules. [VERIFIED: lib/oban_powertools/lifeline.ex] [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md]
- Treating browser E2E as required proof is outdated for this phase; the locked verification bar is backend plus `Phoenix.LiveViewTest`. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md]

## Open Questions (RESOLVED)

1. **Should the resolved destination be a tab, filter, or split section?**
   - What we know: The UI must separate active and resolved views, default to active, and keep the resolved incident visible after execute. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md]
   - Resolved outcome: Use the smallest durable surface that preserves remountability and selection continuity: an explicit active/resolved view state in `LifelineLive`, implemented as a status filter or equivalent assign-driven switch, with direct-link routing deferred unless execution proves it materially improves correctness. [RESOLVED]
   - Planning implication: Phase 7 should update `load_data/2`, selection, and post-execute reload behavior around active/resolved state rather than introducing a new page or redesigning the shell. [RESOLVED]

2. **Should Phase 7 add any extra lifecycle metadata beyond `status` and `resolved_at`?**
   - What we know: Those fields already exist and satisfy the minimum locked requirement. [VERIFIED: lib/oban_powertools/lifeline/incident.ex]
   - Resolved outcome: Default to no schema change and no extra lifecycle fields in Phase 7. Use the existing `status`, `resolved_at`, `first_detected_at`, and `last_detected_at` model unless execution discovers a concrete ambiguity that cannot be expressed without new metadata. [RESOLVED]
   - Planning implication: The phase should stay code-first and test-first, avoiding migration or backfill work unless a concrete implementation blocker appears during execution. [RESOLVED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile and run tests | ✓ | 1.19.5 | — [VERIFIED: local env] |
| Erlang/OTP | Elixir runtime | ✓ | 28 | — [VERIFIED: local env] |
| Mix | Dependency and test commands | ✓ | 1.19.5 | — [VERIFIED: local env] |
| PostgreSQL client/server | DB-backed integration tests | ✓ | 14.17 / accepting connections on 5432 | — [VERIFIED: local env] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local env]

**Missing dependencies with fallback:**
- None. [VERIFIED: local env]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit plus `Phoenix.LiveViewTest` on Phoenix LiveView 1.1.30. [VERIFIED: test/oban_powertools/web/live/lifeline_live_test.exs] [VERIFIED: mix.lock] |
| Config file | none — conventions are driven by Mix project defaults and test support migrations. [VERIFIED: mix.exs] [VERIFIED: test/support/migrations/3_phase_4_tables.exs] |
| Quick run command | `mix test test/oban_powertools/lifeline_test.exs -x` [VERIFIED: local env] |
| Full suite command | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` [VERIFIED: .planning/phases/4-VERIFICATION.md] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIF-02 | Successful dead-executor repair resolves the incident row in the same transaction as target mutation, preview consumption, and audit write. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] | integration | `mix test test/oban_powertools/lifeline_test.exs -x` | ✅ [VERIFIED: test/oban_powertools/lifeline_test.exs] |
| LIF-02 | Re-running projection resolves stale active rows and does not keep rescued `available` / `retryable` jobs active. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] | integration | `mix test test/oban_powertools/lifeline_test.exs -x` | ✅ [VERIFIED: test/oban_powertools/lifeline_test.exs] |
| LIF-02 | Failed, drifted, invalid-reason, and unauthorized execute paths do not retire incidents. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] | integration | `mix test test/oban_powertools/lifeline_test.exs -x` | ✅ [VERIFIED: test/oban_powertools/lifeline_test.exs] |
| LIF-02 | A fresh Lifeline mount no longer shows the repaired incident in the active list and still exposes resolved closure evidence. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] | liveview integration | `mix test test/oban_powertools/web/live/lifeline_live_test.exs -x` | ✅ [VERIFIED: test/oban_powertools/web/live/lifeline_live_test.exs] |

### Sampling Rate
- **Per task commit:** `mix test test/oban_powertools/lifeline_test.exs -x` [VERIFIED: local env]
- **Per wave merge:** `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` [VERIFIED: .planning/phases/4-VERIFICATION.md]
- **Phase gate:** Full suite green plus new closure assertions before `/gsd-verify-work`. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md]

### Wave 0 Gaps
- [ ] `test/oban_powertools/lifeline_test.exs` — add a regression that proves `execute_repair/5` resolves the durable incident row and sets `resolved_at`. [VERIFIED: test/oban_powertools/lifeline_test.exs]
- [ ] `test/oban_powertools/lifeline_test.exs` — add a regression that `project_incidents/2` resolves stale active rows and excludes rescued `available` / `retryable` jobs from dead-executor active evidence. [VERIFIED: lib/oban_powertools/lifeline.ex]
- [ ] `test/oban_powertools/lifeline_test.exs` — add a failure-path assertion that unauthorized/drifted/invalid-reason executes leave incident status unchanged. [VERIFIED: test/oban_powertools/lifeline_test.exs]
- [ ] `test/oban_powertools/web/live/lifeline_live_test.exs` — add a remount test that executes a repair, remounts with `live(conn, "/ops/jobs/lifeline")`, and asserts the fingerprint is absent from active rows but present in resolved evidence. [VERIFIED: test/oban_powertools/web/live/lifeline_live_test.exs] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host app authentication already gates access before Lifeline authorization runs. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] |
| V3 Session Management | no | No Phase 7 change is planned in session handling itself. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] |
| V4 Access Control | yes | Keep `preview_repair` and `execute_repair` authorization checks and add assertions that failed auth does not retire incidents. [VERIFIED: lib/oban_powertools/lifeline.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] |
| V5 Input Validation | yes | Keep `validate_reason/1` as the gate for operator-readable reasons and ensure invalid reasons cannot change lifecycle state. [VERIFIED: lib/oban_powertools/lifeline.ex] |
| V6 Cryptography | no | Phase 7 does not add new cryptographic responsibilities. [VERIFIED: codebase grep] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized repair execution | Elevation of Privilege | Preserve backend auth inside `execute_repair/5` and assert no incident resolution on auth failure. [VERIFIED: lib/oban_powertools/lifeline.ex] |
| Replay of an old preview token | Tampering | Keep single-use preview consumption and drift checks before any target or incident transition. [VERIFIED: lib/oban_powertools/lifeline.ex] |
| Silent loss of repair evidence | Repudiation | Keep immutable `Audit.record/4` in the same transaction as target and incident changes. [VERIFIED: lib/oban_powertools/lifeline.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| UI misrepresentation after execute | Spoofing | Render resolved evidence from durable incident/audit state rather than from transient success messaging alone. [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] |

## Sources

### Primary (HIGH confidence)
- `lib/oban_powertools/lifeline.ex` - current projection, execute, and audit transaction behavior. [VERIFIED: codebase grep]
- `lib/oban_powertools/lifeline/incident.ex` - existing lifecycle fields and schema contract. [VERIFIED: codebase grep]
- `lib/oban_powertools/web/lifeline_live.ex` - active-list reload behavior and current selection semantics. [VERIFIED: codebase grep]
- `test/oban_powertools/lifeline_test.exs` - existing backend proof coverage and current gaps. [VERIFIED: codebase grep]
- `test/oban_powertools/web/live/lifeline_live_test.exs` - existing LiveView proof coverage and current gaps. [VERIFIED: codebase grep]
- `test/support/migrations/3_phase_4_tables.exs` - durable incident schema/index availability. [VERIFIED: codebase grep]
- `mix.lock`, `mix deps`, `mix hex.info ecto`, `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `mix hex.info oban`, `mix hex.info oban_web`, `mix hex.info postgrex` - locked versions and current Hex release dates. [VERIFIED: local env]
- `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` - current baseline suite result. [VERIFIED: mix test]
- https://hexdocs.pm/ecto/Ecto.Multi.html - ordered transaction and named-step semantics. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html - mount / remount and routed LiveView behavior. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html - routed mount and event-testing APIs. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A simple assign/filter model will likely be enough for active vs resolved UI without needing route-level state. [ASSUMED] | Open Questions | Could force extra LiveView routing work or different remount tests. |
| A2 | Extra lifecycle metadata beyond `status` and `resolved_at` is probably unnecessary for Phase 7. [ASSUMED] | Open Questions | Could require a migration/backfill plan if reopen history proves ambiguous during implementation. |

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions, local environment, and official docs were verified directly. [VERIFIED: mix.lock] [VERIFIED: local env] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- Architecture: HIGH - the current gap and file touch points are explicit in the repo and tightly constrained by the locked Phase 7 context. [VERIFIED: lib/oban_powertools/lifeline.ex] [VERIFIED: .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md]
- Pitfalls: HIGH - the biggest failure modes are observable in current code and reflected by the existing open-gap verification note. [VERIFIED: lib/oban_powertools/lifeline.ex] [VERIFIED: .planning/phases/4-VERIFICATION.md]

**Research date:** 2026-05-20
**Valid until:** 2026-06-19
