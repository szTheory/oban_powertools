# Phase 35: Runbook-Guided Remediation & Alert Hook Boundaries - Research

**Researched:** 2026-05-27  
**Domain:** Elixir/Phoenix LiveView, Ecto transaction boundaries, durable audit/forensic metadata, host-owned escalation callbacks  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for all copied constraints in this section: [VERIFIED: `.planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-CONTEXT.md`]

### Locked Decisions

### Recommendation-First Scope
- **D-01:** Treat Phase 35 as a continuity and boundary phase, not a new capability family. The planner should extend the existing advisory runbook, Lifeline remediation, audit, and forensic bundle seams.
- **D-02:** Do not reopen Phase 34's runbook shape. `RunbookEntry` remains evidence-grounded guidance assembled from forensic bundles; Phase 35 adds durable attempted-step context only where a supported native action is previewed or executed.
- **D-03:** No broad user-choice gray area remains after repo-local research. Escalation would only be needed if planning proposes first-party provider delivery, a persisted generic checklist/session product, or a new public automation API.

### Native Remediation Continuity
- **D-04:** Supported Powertools-native remediation flows must carry runbook context from guidance into preview, execute, audit, and forensic evidence. The resulting audit/evidence view should answer: which runbook entry or legal next path led here, what was attempted, why it was allowed, and what result was recorded.
- **D-05:** Store durable runbook context as structured metadata attached to existing native mutation evidence, not as rendered prose. Prefer stable selectors and facts: runbook entry subject, diagnosis state, evidence completeness, selected legal-next-path intent/ownership/venue, preview token, incident fingerprint, target resource, action, reason, and plan hash.
- **D-06:** Keep rendered runbook copy, refusal prose, reason text in URLs, preview internals in URLs, and destination-specific UI wording out of continuity selectors. Destinations must reconstruct current truth from durable identifiers and stored facts.
- **D-07:** Lifeline remains the native execution venue for currently supported remediation. Workflow, cron, limiter, and forensic surfaces can route toward Lifeline or evidence follow-up, but should not become second mutation venues unless a later phase deliberately changes that contract.
- **D-08:** Completion evidence must distinguish previewed, attempted, succeeded, refused, drifted, expired, consumed, bridge-only, and host-owned follow-up states. Do not imply a remediation completed when the operator only opened guidance or followed an external path.

### Alert and Escalation Hook Boundaries
- **D-09:** Add only a narrow host-owned alert/escalation integration seam. Powertools may expose structured event facts or callback points around evidence/runbook/remediation state, but the host owns destinations, credentials, delivery guarantees, retry policy, escalation routing, and downstream runbook truth.
- **D-10:** Fallback behavior must be explicit and non-magical: if no host hook is configured, render and record "host-owned follow-up unavailable/not configured" style guidance rather than pretending Powertools delivered an alert.
- **D-11:** Avoid provider-specific adapters in core. Slack, PagerDuty, ticketing, webhooks, and incident-management products remain future companion or host code unless a later milestone changes the packaging ledger.
- **D-12:** Hook payloads, if introduced, should use low-cardinality event names and bounded structured metadata. They must not leak high-cardinality identifiers into telemetry labels or freeze a broad machine automation contract.

### Ownership and UX Boundaries
- **D-13:** Preserve the ownership triad at the point of choice: `Powertools-native`, `Oban Web bridge`, and `host-owned follow-up`.
- **D-14:** Powertools-native paths may render as actionable controls only when they stay inside the existing preview -> reason -> execute -> audit trust model.
- **D-15:** Oban Web bridge paths remain inspection-only, even when they appear as part of a remediation runbook.
- **D-16:** Host-owned escalation paths render as guidance or configured host follow-up, not as filled native action controls owned by Powertools.
- **D-17:** Continue the shared operator reading order: diagnosis -> runbook guidance -> legal next path -> venue/ownership -> evidence -> audit follow-up.

### Proof and Support Truth
- **D-18:** Merge-blocking proof should cover runbook context preserved through at least one supported native remediation path into audit and forensic evidence.
- **D-19:** Proof should cover host-owned escalation hook fallback and configured-hook behavior without requiring a real external provider.
- **D-20:** Proof should assert native, bridge-only, and host-owned follow-up paths remain visually and semantically distinct across remediation and escalation surfaces.
- **D-21:** Public docs and example-host changes belong mostly to Phase 36, but Phase 35 implementation and tests must avoid claims that Phase 36 docs cannot support.

### Claude's Discretion
- Exact schema, struct, or metadata names for runbook attempt context, provided selectors remain stable and rendered prose stays out of durable selectors.
- Whether the host-owned hook seam is a behaviour, callback module, config option, or small event dispatcher, provided ownership and fallback semantics stay explicit.
- Exact UI layout for remediation context in audit/forensics, provided it stays close to the acted-on evidence and does not become a generic incident-management console.
- Exact test file split, provided the proof directly covers RNB-03 and the alert/escalation boundary portion of HST-05.

### Deferred Ideas (OUT OF SCOPE)
- First-party Slack, PagerDuty, ticketing, or incident-management delivery adapters — future companion package or later milestone.
- Generic persisted runbook checklist/session product — out of v1.4 scope unless a later milestone deliberately broadens the product.
- Machine-facing CLI/API automation contracts for runbook remediation — deferred until the investigative vocabulary and support truth settle.
- Native generic queue/job dashboard parity — still deferred and bridge-only per earlier milestone decisions.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RNB-03 | When operators launch or complete a supported remediation flow, the resulting audit and evidence views retain the runbook context needed to explain what was attempted and why. [VERIFIED: `.planning/REQUIREMENTS.md`] | Extend Lifeline preview/execute metadata and `Audit.record/4`; project audit metadata into forensic bundles and LiveView evidence. [VERIFIED: `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/audit.ex`, `lib/oban_powertools/forensics.ex`] |
| HST-05 | Host apps can integrate alert or escalation hooks around the new investigative surfaces without losing explicit boundaries about where entitlement, delivery, or downstream runbook truth lives. [VERIFIED: `.planning/REQUIREMENTS.md`] | Add a narrow optional host callback/config seam with explicit unconfigured fallback; keep provider delivery out of core. [VERIFIED: `.planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-CONTEXT.md`, `lib/oban_powertools/runtime_config.ex`, `lib/oban_powertools/workflow/callback_handler.ex`] |
</phase_requirements>

## Project Constraints (from AGENTS.md / CLAUDE.md)

No `AGENTS.md` or `CLAUDE.md` file exists in the project root, and no `.claude/skills/` or `.agents/skills/` project skill directory was found. [VERIFIED: filesystem checks] Project-level constraints for this phase therefore come from `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, and `35-CONTEXT.md`. [VERIFIED: user-provided files]

## Summary

Phase 35 should preserve runbook context by adding structured, stable attempt metadata to existing Lifeline preview/execute evidence, then rendering that metadata in audit and forensic read models. [VERIFIED: `35-CONTEXT.md`, `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/audit.ex`] The current implementation already has a preview-first native remediation trust path (`preview_repair/4` -> `execute_repair/5` -> `Ecto.Multi` mutation -> `Audit.record/4`), so the planner should extend that path instead of creating a new runbook session store. [VERIFIED: `lib/oban_powertools/lifeline.ex`]

The alert/escalation part should be a host-owned seam, not provider delivery. [VERIFIED: `35-CONTEXT.md`, `.planning/REQUIREMENTS.md`] The closest existing local pattern is `Workflow.CallbackHandler`, `Workflow.CallbackOutbox`, and `RuntimeConfig.workflow_callback_handler/1`, but Phase 35 should stay narrower unless durable retry delivery is explicitly required by a plan. [VERIFIED: `lib/oban_powertools/workflow/callback_handler.ex`, `lib/oban_powertools/workflow/callback_outbox.ex`, `lib/oban_powertools/runtime_config.ex`, `35-CONTEXT.md`] The fallback path must render and record "not configured/unavailable" truth rather than implying a page, ticket, webhook, or external runbook was delivered. [VERIFIED: `35-CONTEXT.md`]

External SRE guidance supports this boundary: monitoring/alerting should focus on actionable conditions and clear symptoms, and incident escalation policy owns who is notified, how handoffs happen, and when escalation occurs. [CITED: https://sre.google/sre-book/monitoring-distributed-systems/, https://www.atlassian.com/incident-management/on-call/escalation-policies] That reinforces the product decision to expose facts and seams while leaving credentials, routing, retries, and downstream runbook truth to the host. [VERIFIED: `35-CONTEXT.md`; CITED: Atlassian escalation policy]

**Primary recommendation:** Extend Lifeline repair previews/audits with `runbook_context` structured metadata, project that metadata into forensic evidence, and add an optional host escalation callback seam with explicit fallback records and no provider adapters. [VERIFIED: `35-CONTEXT.md`, `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/forensics.ex`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Runbook context capture for native remediation | API / Backend | Database / Storage | `Lifeline.preview_repair/4` and `execute_repair/5` own the preview, mutation, and audit transaction; durable context belongs with the mutation evidence. [VERIFIED: `lib/oban_powertools/lifeline.ex`] |
| Attempt state projection into audit/evidence | API / Backend | Frontend Server / LiveView | `Audit` stores normalized event metadata and `Forensics` turns audit rows into chronology/read-model items; LiveViews should render the read model. [VERIFIED: `lib/oban_powertools/audit.ex`, `lib/oban_powertools/forensics.ex`, `lib/oban_powertools/web/forensics_live.ex`] |
| Host-owned alert/escalation hook seam | API / Backend | Host Application | Runtime callback configuration already lives in `RuntimeConfig`; host code owns callback implementation and delivery semantics. [VERIFIED: `lib/oban_powertools/runtime_config.ex`, `lib/oban_powertools/workflow/callback_handler.ex`] |
| Ownership distinction in operator UI | Frontend Server / LiveView | API / Backend | `ControlPlanePresenter` centralizes ownership labels and LiveViews render the `Powertools-native`, `Oban Web bridge`, and `host-owned follow-up` distinctions. [VERIFIED: `lib/oban_powertools/web/control_plane_presenter.ex`, `lib/oban_powertools/web/forensics_live.ex`, `lib/oban_powertools/web/lifeline_live.ex`] |
| Phase 36 docs/proof closure boundary | Documentation / Planning | Test Suite | Phase 35 may add implementation and hermetic proof, but public docs and example-host closure belong mostly to Phase 36. [VERIFIED: `35-CONTEXT.md`, `.planning/ROADMAP.md`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Runtime, build, and ExUnit execution. [VERIFIED: `elixir --version`, `mix --version`] | Existing project language/runtime. [VERIFIED: `mix.exs`] |
| Ecto / Ecto SQL | `ecto` 3.13.6 locked; latest 3.14.0 published 2026-05-19. `ecto_sql` 3.13.5 locked. [VERIFIED: `mix deps`, `mix hex.info ecto`] | Transactional changesets, queries, and `Ecto.Multi`. [CITED: https://hexdocs.pm/ecto/3.14.0/Ecto.Multi.html] | Existing native mutation path already uses `Ecto.Multi`; preserve atomic preview consumption, target mutation, incident resolution, and audit write. [VERIFIED: `lib/oban_powertools/lifeline.ex`] |
| Phoenix LiveView | 1.1.30 locked; 1.2.0 is release-candidate only as of 2026-05-27. [VERIFIED: `mix deps`, `mix hex.info phoenix_live_view`] | Native operator UI and LiveView tests. [VERIFIED: `lib/oban_powertools/web/lifeline_live.ex`, `test/oban_powertools/web/live/lifeline_live_test.exs`] | Existing `/ops/jobs` surfaces are LiveViews; official LiveView test helpers support event-driven proof via `element/2`, `render_click/1`, and `has_element?/1`. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| Oban | 2.22.1 locked and current stable. [VERIFIED: `mix deps`, `mix hex.info oban`] | Job state model and repair targets. [VERIFIED: `mix.exs`, `lib/oban_powertools/lifeline.ex`] | Existing Lifeline repairs operate on Oban jobs and workflow-owned records; Oban docs define job states and job management APIs. [CITED: https://github.com/oban-bg/oban/blob/main/guides/learning/job_lifecycle.md] |
| Telemetry | 1.4.2 locked and current. [VERIFIED: `mix deps`, `mix hex.info telemetry`] | Low-cardinality instrumentation around preview/execution events. [VERIFIED: `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/telemetry.ex`] | Official `:telemetry.execute/3` takes event name, measurements, and metadata, matching existing project wrappers. [CITED: https://hexdocs.pm/telemetry/] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | 1.4.5 locked. [VERIFIED: `mix deps`] | JSON/map metadata encoding through Ecto/Postgres fields. [VERIFIED: `mix.exs`, `lib/oban_powertools/audit.ex`] | Use only through existing map metadata fields; do not add a custom serialization layer. [VERIFIED: `lib/oban_powertools/audit.ex`, `lib/oban_powertools/lifeline/repair_preview.ex`] |
| Postgrex / PostgreSQL | Postgrex 0.22.2 locked; local `psql` 14.17 and local server accepting connections. [VERIFIED: `mix deps`, `psql --version`, `pg_isready`] | Ecto/Postgres-backed durable audit, preview, incident, and forensic state. [VERIFIED: `mix.exs`, `test/test_helper.exs`] | Required for migration-backed tests and local proof. [VERIFIED: `test/test_helper.exs`] |
| lazy_html | 0.1.11 locked in test. [VERIFIED: `mix deps`] | LiveView HTML assertions. [VERIFIED: `mix.exs`, `test/oban_powertools/web/live/forensics_live_test.exs`] | Keep for existing LiveView proof; no new browser automation is required for Phase 35. [VERIFIED: existing test suite files] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Structured metadata on existing `RepairPreview` and audit rows | New persisted runbook session/checklist tables | New tables would contradict the locked "no generic persisted runbook checklist/session product" scope and create extra lifecycle states to reconcile. [VERIFIED: `35-CONTEXT.md`] |
| Optional host callback/config seam | Provider adapters for Slack, PagerDuty, tickets, webhooks | Provider adapters are explicitly deferred and would falsely imply core owns delivery guarantees and credentials. [VERIFIED: `35-CONTEXT.md`, `.planning/REQUIREMENTS.md`] |
| Ecto.Multi extension in Lifeline | LiveView-local mutation side effects | LiveViews are currently thin render/control surfaces, while `Lifeline.execute_repair/5` is the durable mutation/audit boundary. [VERIFIED: `lib/oban_powertools/web/lifeline_live.ex`, `lib/oban_powertools/lifeline.ex`] |

**Installation:**

No new dependencies are recommended for Phase 35. [VERIFIED: current stack in `mix.exs`; VERIFIED: `35-CONTEXT.md` scope forbids provider adapters]

**Version verification:** Package versions were verified with `mix deps` and current release information with `mix hex.info ecto`, `mix hex.info phoenix_live_view`, `mix hex.info telemetry`, `mix hex.info oban`, and `mix hex.info phoenix`. [VERIFIED: command outputs]

## Architecture Patterns

### System Architecture Diagram

```text
Runbook guidance / legal next path
  [Forensics.RunbookEntry from EvidenceBundle]
        |
        | stable selectors + ownership/intent facts
        v
Lifeline preview request
  [Lifeline.preview_repair/4]
        |
        | attach runbook_context to RepairPreview metadata
        v
Operator reason + execute
  [Lifeline.execute_repair/5]
        |
        v
Ecto.Multi transaction
  target mutation -> incident resolution -> preview consumed -> audit event
        |
        | audit metadata includes runbook_context + result/status
        v
Audit / Forensics read model
  [Audit.list_all/2 + Forensics.bundle/2 chronology/evidence]
        |
        +--> Native evidence: attempted/succeeded/refused/drifted/expired/consumed
        +--> Bridge-only evidence: inspection path only
        +--> Host-owned evidence: configured callback or explicit unavailable fallback
        |
        v
LiveView surfaces
  [LifelineLive, ForensicsLive, Audit follow-up links]
```

Diagram source: existing data flow in `Lifeline`, `Audit`, `Forensics`, and LiveViews. [VERIFIED: `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/audit.ex`, `lib/oban_powertools/forensics.ex`, `lib/oban_powertools/web/lifeline_live.ex`, `lib/oban_powertools/web/forensics_live.ex`]

### Recommended Project Structure

```text
lib/oban_powertools/
├── lifeline.ex                         # Native preview/execute transaction; add runbook_context metadata here. [VERIFIED]
├── lifeline/repair_preview.ex          # Durable preview state; use existing metadata map unless planner proves typed columns are needed. [VERIFIED]
├── audit.ex                            # Audit metadata read/write helpers; add read helpers for attempt context if useful. [VERIFIED]
├── forensics.ex                        # Project audit attempt context into evidence bundle chronology/related evidence. [VERIFIED]
├── forensics/runbook_entry.ex          # Source advisory runbook facts; do not turn into mutable session state. [VERIFIED]
├── host_escalation_handler.ex          # New optional behaviour only if planner chooses behaviour seam. [RECOMMENDED: 35-CONTEXT.md]
├── runtime_config.ex                   # Add optional host escalation handler lookup/fallback. [VERIFIED]
└── web/
    ├── control_plane_presenter.ex      # Shared ownership/fallback wording. [VERIFIED]
    ├── lifeline_live.ex                # Render attempt context near preview/audit evidence. [VERIFIED]
    └── forensics_live.ex               # Render runbook attempt context in evidence chronology. [VERIFIED]
```

### Pattern 1: Extend the Existing Native Transaction Boundary

**What:** Add runbook attempt context to preview metadata and audit metadata inside Lifeline's existing preview/execute path. [VERIFIED: `lib/oban_powertools/lifeline.ex`]  
**When to use:** All supported Powertools-native remediation flows (`job_rescue`, `job_retry`, `job_cancel`, `workflow_step_retry`, `workflow_step_cancel`, `workflow_request_cancel`). [VERIFIED: `lib/oban_powertools/lifeline.ex`]  
**Example:**

```elixir
# Source: existing repo pattern in lib/oban_powertools/lifeline.ex; Ecto.Multi API cited from https://hexdocs.pm/ecto/3.14.0/Ecto.Multi.html
Multi.new()
|> Multi.run(:target, fn repo, _changes -> mutate_target(repo, preview, actor, reason, now) end)
|> Multi.update(:preview, RepairPreview.changeset(preview, %{status: "consumed"}))
|> Multi.run(:audit, fn repo, %{preview: preview_record} ->
  Audit.record("lifeline.repair_executed", resource, metadata_with_runbook_context, repo: repo)
end)
|> repo.transaction()
```

### Pattern 2: Store Stable Facts, Render Current Truth

**What:** Persist stable identifiers and facts such as subject, diagnosis state, evidence completeness, ownership, venue, intent, target, action, preview token, plan hash, and incident fingerprint; avoid durable prose and URL-unsafe internals. [VERIFIED: `35-CONTEXT.md`]  
**When to use:** Preview metadata, audit metadata, host hook payloads, forensic chronology items, and LiveView selectors. [VERIFIED: `35-CONTEXT.md`, `lib/oban_powertools/forensics/runbook_entry.ex`, `lib/oban_powertools/web/forensics_live.ex`]  
**Example:**

```elixir
# Source: local metadata maps in lib/oban_powertools/lifeline.ex and context decision D-05.
%{
  "runbook_context" => %{
    "subject" => %{"type" => "lifeline_incident", "id" => incident_fingerprint},
    "diagnosis_state" => diagnosis_state,
    "evidence_completeness" => completeness_state,
    "selected_path" => %{
      "ownership" => "Powertools-native",
      "venue" => "Powertools-native Lifeline",
      "intent" => "remediate"
    }
  }
}
```

### Pattern 3: Optional Host Callback with Truthful Fallback

**What:** Add a host-owned seam that receives bounded event facts when configured; when absent, return/render/record an explicit unavailable state. [VERIFIED: `35-CONTEXT.md`]  
**When to use:** Host-owned follow-up recommendations around evidence/runbook/remediation state, especially where a legal next path is outside Powertools ownership. [VERIFIED: `35-CONTEXT.md`, `.planning/REQUIREMENTS.md`]  
**Example:**

```elixir
# Source: existing RuntimeConfig callback lookup style in lib/oban_powertools/runtime_config.ex.
case RuntimeConfig.escalation_handler() do
  nil ->
    {:unconfigured, %{status: "host_owned_follow_up_unavailable"}}

  handler ->
    handler.handle_escalation(event_facts)
end
```

### Anti-Patterns to Avoid

- **New generic runbook session engine:** It conflicts with the locked advisory runbook/session boundary and adds persistence that Phase 35 explicitly defers. [VERIFIED: `35-CONTEXT.md`]
- **Provider delivery in core:** Slack, PagerDuty, tickets, and webhooks are deferred companion/host code, not Phase 35 core. [VERIFIED: `35-CONTEXT.md`, `.planning/REQUIREMENTS.md`]
- **Rendered copy as durable identity:** Rendering language may change; selectors must be stable facts. [VERIFIED: `35-CONTEXT.md`, `lib/oban_powertools/forensics/runbook_entry.ex`]
- **Preview token or reason text in URLs:** Context decisions explicitly forbid preview internals and reason text in URL continuity selectors. [VERIFIED: `35-CONTEXT.md`]
- **Telemetry labels with high-cardinality identifiers:** Phase context requires low-cardinality event names and bounded metadata; existing telemetry wrappers already keep action/class/type metadata low-cardinality. [VERIFIED: `35-CONTEXT.md`, `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/telemetry.ex`; CITED: https://hexdocs.pm/telemetry/]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Native mutation/audit transaction | Custom transaction orchestration | `Ecto.Multi` in `Lifeline.execute_repair/5` | The existing flow already atomically mutates the target, resolves incidents, consumes previews, and writes audit evidence. [VERIFIED: `lib/oban_powertools/lifeline.ex`; CITED: Ecto.Multi docs] |
| Durable remediation attempt history | New event store or checklist table | Existing `RepairPreview.metadata` and `Audit.metadata` | The project already persists preview state and audit metadata; context locks this as structured metadata on native mutation evidence. [VERIFIED: `lib/oban_powertools/lifeline/repair_preview.ex`, `lib/oban_powertools/audit.ex`, `35-CONTEXT.md`] |
| Ownership wording and labels | Page-local string branches | `ControlPlanePresenter` helpers | The presenter already centralizes ownership, runbook boundary, provenance, completeness, and audit follow-up labels. [VERIFIED: `lib/oban_powertools/web/control_plane_presenter.ex`] |
| Host escalation delivery | Retry queues, provider clients, credential storage | Optional host callback/config seam | Host owns destinations, credentials, delivery guarantees, retries, routing, and downstream truth. [VERIFIED: `35-CONTEXT.md`] |
| LiveView proof helpers | Browser automation for basic event proof | Phoenix LiveViewTest helpers | Existing tests use LiveViewTest; official docs support event assertions through `element/2`, `render_click/1`, forms, and `has_element?/1`. [VERIFIED: `test/oban_powertools/web/live/lifeline_live_test.exs`; CITED: Phoenix LiveViewTest docs] |

**Key insight:** Phase 35 is mostly metadata continuity and boundary proof; building new delivery, checklist, or automation infrastructure would widen product support obligations beyond locked requirements. [VERIFIED: `35-CONTEXT.md`, `.planning/REQUIREMENTS.md`]

## Common Pitfalls

### Pitfall 1: Treating Host-Owned Follow-Up as Delivered Alerting
**What goes wrong:** UI or audit copy implies Powertools paged someone, opened a ticket, or ran an external runbook. [VERIFIED: `35-CONTEXT.md`]  
**Why it happens:** A hook seam can look like a delivery product if fallback, configured, and delivered states are not named separately. [VERIFIED: `35-CONTEXT.md`]  
**How to avoid:** Use explicit statuses such as `host_owned_follow_up_unconfigured`, `host_owned_follow_up_callback_invoked`, and `host_owned_follow_up_callback_failed`; avoid provider names in core. [RECOMMENDED: `35-CONTEXT.md`]  
**Warning signs:** Tests assert provider names or success copy without a fake host handler. [VERIFIED: `35-CONTEXT.md`]

### Pitfall 2: Losing Attempt Context on Drift, Expiry, or Refusal
**What goes wrong:** Only successful execution gets runbook context, leaving previewed/refused/drifted/expired paths unexplained. [VERIFIED: `35-CONTEXT.md`, `lib/oban_powertools/lifeline.ex`]  
**Why it happens:** Current audit writes happen on successful `lifeline.repair_executed`, while preview state transitions can occur before audit. [VERIFIED: `lib/oban_powertools/lifeline.ex`]  
**How to avoid:** Attach runbook context at preview creation and preserve it through status changes; decide whether failed/blocked attempts need audit rows or forensic projection from preview records. [RECOMMENDED: `lib/oban_powertools/lifeline.ex`, `35-CONTEXT.md`]  
**Warning signs:** A drifted preview has `metadata["drift_reason"]` but no `runbook_context`. [VERIFIED: current drift metadata in `lib/oban_powertools/lifeline.ex`]

### Pitfall 3: Expanding URLs Into Session State
**What goes wrong:** Reason text, preview tokens, or rendered runbook labels leak into URLs. [VERIFIED: `35-CONTEXT.md`]  
**Why it happens:** It is tempting to pass all LiveView state through `push_patch/2`; current selectors already constrain allowed forensic params. [VERIFIED: `lib/oban_powertools/web/forensics_live.ex`, `lib/oban_powertools/web/lifeline_live.ex`]  
**How to avoid:** Keep URLs to resource selectors (`workflow_id`, `step`, `incident_fingerprint`, `view`, `resource_type`, `resource_id`) and reconstruct from storage. [VERIFIED: `35-CONTEXT.md`, `lib/oban_powertools/web/forensics_live.ex`]  
**Warning signs:** Query strings contain `reason=`, `preview_token=`, rendered labels, or provider destination text. [VERIFIED: `35-CONTEXT.md`]

### Pitfall 4: Telemetry Cardinality Blow-Up
**What goes wrong:** Incident fingerprints, preview tokens, job IDs, or resource IDs become telemetry labels/metadata used by metrics backends. [VERIFIED: `35-CONTEXT.md`]  
**Why it happens:** Hook payload facts can be confused with metrics labels. [VERIFIED: `35-CONTEXT.md`]  
**How to avoid:** Keep telemetry event names low-cardinality and put high-cardinality identifiers only in audit/preview metadata, not metrics dimensions. [VERIFIED: existing telemetry wrapper usage in `lib/oban_powertools/lifeline.ex`; CITED: https://hexdocs.pm/telemetry/]  
**Warning signs:** `Telemetry.execute_lifeline_event/3` receives `incident_fingerprint`, `preview_token`, or `target_id`. [VERIFIED: `lib/oban_powertools/lifeline.ex` currently avoids those fields]

### Pitfall 5: Freezing Phase 36 Claims Too Early
**What goes wrong:** Phase 35 UI/docs text claims complete host integration support before docs/example-host proof closes in Phase 36. [VERIFIED: `35-CONTEXT.md`, `.planning/ROADMAP.md`]  
**Why it happens:** Implementation proof and public support-truth documentation are adjacent but not the same phase. [VERIFIED: `.planning/ROADMAP.md`]  
**How to avoid:** Keep user-facing Phase 35 copy narrow: "host-owned follow-up configured/unconfigured" rather than "alerts integrated." [RECOMMENDED: `35-CONTEXT.md`]  
**Warning signs:** README/operator-guide changes are used as the only proof of HST-05 in Phase 35. [VERIFIED: `.planning/ROADMAP.md`]

## Code Examples

Verified patterns from official and local sources:

### Ecto.Multi Keeps Mutation and Audit Atomic

```elixir
# Source: https://hexdocs.pm/ecto/3.14.0/Ecto.Multi.html and lib/oban_powertools/lifeline.ex
Ecto.Multi.new()
|> Ecto.Multi.update(:preview, RepairPreview.changeset(preview, attrs))
|> Ecto.Multi.run(:audit, fn repo, %{preview: preview_record} ->
  Audit.record("lifeline.repair_executed", resource, metadata, repo: repo)
end)
|> repo.transaction()
```

### LiveView Event Proof Should Use Rendered Elements

```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
html =
  view
  |> element("button[phx-click='preview']")
  |> render_click()

assert html =~ "Preview Ready"
```

### Telemetry Events Are Name + Measurements + Metadata

```elixir
# Source: https://hexdocs.pm/telemetry/
:telemetry.execute(
  [:oban_powertools, :lifeline, :repair_executed],
  %{count: 1},
  %{action: "workflow_step_retry", target_type: "workflow_step"}
)
```

### Host Callback Behaviour Shape

```elixir
# Source: existing local pattern in lib/oban_powertools/workflow/callback_handler.ex
defmodule ObanPowertools.HostEscalationHandler do
  @callback handle_escalation(map()) :: :ok | {:error, term()}
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Advisory runbook copy only | Structured runbook attempt context attached to preview/audit/evidence for supported native remediation | Phase 35 target, after Phase 34 advisory runbook entry surfaces. [VERIFIED: `.planning/ROADMAP.md`, `35-CONTEXT.md`] | Planner should add continuity metadata, not a new action surface. [VERIFIED: `35-CONTEXT.md`] |
| Alerting as core provider integration | Host-owned seam with explicit fallback and no provider adapters | Locked for v1.4. [VERIFIED: `.planning/REQUIREMENTS.md`, `35-CONTEXT.md`] | Planner should test fake host handler and unconfigured fallback only. [VERIFIED: `35-CONTEXT.md`] |
| Incident follow-up as generic external automation | Powertools-native, Oban Web bridge, and host-owned paths stay visually/semantically distinct | Locked since Phase 34 and reinforced in Phase 35. [VERIFIED: `34-CONTEXT.md` referenced by `35-CONTEXT.md`; `35-CONTEXT.md`] | Planner must keep bridge-only and host-owned paths non-native controls. [VERIFIED: `35-CONTEXT.md`, `test/oban_powertools/web/live/forensics_live_test.exs`] |

**Deprecated/outdated:**
- Using Phase 34 copy "advisory only; does not record remediation attempts" as final truth after Phase 35 is implemented will become outdated for supported native remediation flows. [VERIFIED: `lib/oban_powertools/forensics/runbook_entry.ex`, `35-CONTEXT.md`]
- Treating host-owned escalation as a provider integration is out of scope for v1.4 core. [VERIFIED: `.planning/REQUIREMENTS.md`, `35-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The planner can use `RepairPreview.metadata` for runbook context without a migration; a typed column is only needed if querying/indexing requirements emerge. [ASSUMED] | Architecture Patterns | If wrong, Phase 35 needs a migration task and extra migration/backfill proof. |
| A2 | The host escalation seam does not need durable retry/outbox semantics in Phase 35; configured callback proof can be synchronous or small and fake-handler based. [ASSUMED] | Architecture Patterns / Standard Stack | If wrong, planner should reuse the workflow callback outbox pattern and add retry/failure-state proof. |

## Open Questions

1. **Should non-success preview states create audit rows, or is forensic projection from `RepairPreview` records enough?**
   - What we know: successful execution currently writes `lifeline.repair_executed`; drift/expiry/consumed statuses live on `RepairPreview`. [VERIFIED: `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/lifeline/repair_preview.ex`]
   - What's unclear: `35-CONTEXT.md` requires distinguishing previewed/refused/drifted/expired/consumed but does not mandate an audit event for every state. [VERIFIED: `35-CONTEXT.md`]
   - Recommendation: planner should add explicit tasks to choose the minimal durable projection, preferring preview metadata plus successful audit unless proof shows audit rows are needed for failed/blocked attempts. [RECOMMENDED]

2. **Should host hook invocation be post-commit durable outbox or best-effort callback?**
   - What we know: workflow callbacks use a durable outbox and state handlers must be idempotent. [VERIFIED: `lib/oban_powertools/workflow/callback_outbox.ex`, `lib/oban_powertools/workflow/callback_handler.ex`]
   - What's unclear: Phase 35 context says host owns delivery guarantees and retry policy, so core should not silently assume durable delivery. [VERIFIED: `35-CONTEXT.md`]
   - Recommendation: planner should implement the smallest optional seam with explicit unconfigured/configured/failure return facts; do not introduce outbox retry unless required by tests or host contract wording. [RECOMMENDED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | Compile and ExUnit tests | yes | Elixir 1.19.5, Mix 1.19.5 [VERIFIED: command output] | none |
| Erlang/OTP | Elixir runtime | yes | OTP 28 [VERIFIED: command output] | none |
| PostgreSQL server | Ecto integration tests | yes | local server accepting connections on `/tmp:5432` [VERIFIED: `pg_isready`] | none |
| psql client | DB diagnostics | yes | PostgreSQL 14.17 [VERIFIED: `psql --version`] | Ecto SQL test setup if CLI unused |
| Git | Optional research commit | yes | 2.41.0 [VERIFIED: `git --version`] | none |

**Missing dependencies with no fallback:** None found. [VERIFIED: environment probes]  
**Missing dependencies with fallback:** None found. [VERIFIED: environment probes]

## Validation Architecture

`.planning/config.json` does not set `workflow.nyquist_validation` to `false`, so validation architecture is enabled. [VERIFIED: `.planning/config.json`]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix LiveViewTest and Ecto SQL/Postgres test support. [VERIFIED: `test/test_helper.exs`, `test/oban_powertools/web/live/lifeline_live_test.exs`] |
| Config file | `test/test_helper.exs` plus test support modules; no separate `pytest`/Jest/Vitest config applies. [VERIFIED: `find test -name '*test.exs'`, `test/test_helper.exs`] |
| Quick run command | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs` [VERIFIED: files exist] |
| Full suite command | `mix test` [VERIFIED: Mix project] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| RNB-03 | Preview creation stores runbook context for at least one supported native Lifeline remediation path. [VERIFIED: `35-CONTEXT.md`] | unit/integration | `mix test test/oban_powertools/lifeline_test.exs` | ✅ |
| RNB-03 | Execution audit includes runbook context explaining selected path, action, reason, plan hash, target, and result. [VERIFIED: `35-CONTEXT.md`, `lib/oban_powertools/lifeline.ex`] | unit/integration | `mix test test/oban_powertools/lifeline_test.exs` | ✅ |
| RNB-03 | Forensic bundle renders or exposes attempt context after native remediation. [VERIFIED: `35-CONTEXT.md`, `lib/oban_powertools/forensics.ex`] | integration/LiveView | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs` | ✅ |
| HST-05 advisory | No host hook configured renders/records explicit host-owned unavailable fallback. [VERIFIED: `35-CONTEXT.md`] | unit/LiveView | New test likely in `test/oban_powertools/host_escalation_test.exs` or existing forensics/lifeline tests | ❌ Wave 0 |
| HST-05 advisory | Fake configured host hook receives bounded event facts without provider-specific delivery. [VERIFIED: `35-CONTEXT.md`] | unit | New test likely in `test/oban_powertools/host_escalation_test.exs` | ❌ Wave 0 |
| RNB-03 / HST-05 | Native, bridge-only, and host-owned paths remain visually/semantically distinct. [VERIFIED: `35-CONTEXT.md`] | LiveView | `mix test test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs` | ✅ |

### Sampling Rate

- **Per task commit:** `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/forensics_test.exs` [RECOMMENDED]
- **Per wave merge:** `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs` [RECOMMENDED]
- **Phase gate:** `mix test` before `/gsd-verify-work`. [RECOMMENDED]

### Wave 0 Gaps

- [ ] `test/oban_powertools/host_escalation_test.exs` — covers HST-05 unconfigured/configured/failure seam if the planner introduces a new module. [RECOMMENDED]
- [ ] Extend `test/oban_powertools/lifeline_test.exs` — covers RNB-03 preview/execute metadata continuity. [VERIFIED: file exists]
- [ ] Extend `test/oban_powertools/forensics_test.exs` and `test/oban_powertools/web/live/forensics_live_test.exs` — covers evidence projection and visual distinction. [VERIFIED: files exist]

## Security Domain

`security_enforcement` is absent from `.planning/config.json`, so security review is enabled by default per GSD instructions. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No new auth mechanism | Reuse existing host-owned `Auth`/`LiveAuth` authorization and actor attribution; do not add credentials for external providers. [VERIFIED: `lib/oban_powertools/web/live_auth.ex`, `35-CONTEXT.md`] |
| V3 Session Management | No new session contract | Keep LiveView state server-side and URL selectors stable/minimal; do not persist reason or preview internals in URLs. [VERIFIED: `35-CONTEXT.md`, `lib/oban_powertools/web/forensics_live.ex`] |
| V4 Access Control | Yes | Continue `LiveAuth.authorize_page/3`, `LiveAuth.authorize_action/4`, and backend `Auth.authorize/3` checks before preview/execute. [VERIFIED: `lib/oban_powertools/web/lifeline_live.ex`, `lib/oban_powertools/lifeline.ex`; CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| V5 Input Validation | Yes | Validate action, target type, preview availability, reason, and handler payload shape through changesets/allowlists. [VERIFIED: `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/lifeline/repair_preview.ex`; CITED: OWASP ASVS page] |
| V6 Cryptography | No new crypto | Do not add provider credentials or signing in core Phase 35; host owns provider secrets if any. [VERIFIED: `35-CONTEXT.md`] |
| V7 Error Handling and Logging | Yes | Record explicit fallback/failure facts without leaking secrets or high-cardinality telemetry labels. [VERIFIED: `35-CONTEXT.md`, `lib/oban_powertools/audit.ex`; CITED: OWASP ASVS page] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized remediation execution | Elevation of privilege | Keep action authorization in LiveView and backend Lifeline checks. [VERIFIED: `lib/oban_powertools/web/lifeline_live.ex`, `lib/oban_powertools/lifeline.ex`] |
| Tampered preview/action context | Tampering | Recompute plan hash before execution and mark drifted when target state changes. [VERIFIED: `lib/oban_powertools/lifeline.ex`] |
| Repudiation of attempted remediation | Repudiation | Preserve actor, reason, preview token, plan hash, target, action, runbook context, and result in audit/preview metadata. [VERIFIED: existing audit fields in `lib/oban_powertools/audit.ex`; RECOMMENDED for new runbook fields] |
| Secret leakage through hook payloads | Information disclosure | Do not include credentials, provider destinations, reason text in URLs, or rendered prose in durable selectors; keep payload bounded. [VERIFIED: `35-CONTEXT.md`] |
| Callback failure causing native mutation rollback unexpectedly | Denial of service | Invoke host hook outside the critical mutation path or record failure explicitly; do not let optional host delivery break native repair unless deliberately designed. [RECOMMENDED: `35-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-CONTEXT.md` — locked Phase 35 decisions, discretion, deferred scope. [VERIFIED]
- `.planning/REQUIREMENTS.md` — RNB-03, HST-05, proof posture, support truth, packaging ledger. [VERIFIED]
- `.planning/ROADMAP.md` — Phase 35 plans and Phase 36 boundary. [VERIFIED]
- `.planning/STATE.md` — current milestone decisions and completed Phase 34 posture. [VERIFIED]
- `lib/oban_powertools/lifeline.ex`, `audit.ex`, `forensics.ex`, `forensics/runbook_entry.ex`, `web/control_plane_presenter.ex`, `web/lifeline_live.ex`, `web/forensics_live.ex` — current implementation seams. [VERIFIED]
- `test/oban_powertools/lifeline_test.exs`, `forensics_test.exs`, `web/live/lifeline_live_test.exs`, `web/live/forensics_live_test.exs` — existing proof surfaces. [VERIFIED]
- Context7 docs: `/websites/hexdocs_pm_ecto` for `Ecto.Multi`; `/websites/hexdocs_pm_phoenix_live_view` for LiveViewTest; `/websites/hexdocs_pm_telemetry` for `:telemetry.execute/3`; `/oban-bg/oban` for Oban lifecycle/job management. [CITED]

### Secondary (MEDIUM confidence)
- Google SRE Book, "Monitoring Distributed Systems" — actionable alerting, symptoms/causes, loose coupling. [CITED: https://sre.google/sre-book/monitoring-distributed-systems/]
- Atlassian escalation policies — escalation policy owns handoffs, notification targets, severity/duration/scope nuance. [CITED: https://www.atlassian.com/incident-management/on-call/escalation-policies]
- OWASP ASVS project page — ASVS as basis for testing web application technical security controls. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified from `mix.exs`, `mix.lock`, `mix deps`, `mix hex.info`, and Context7/official docs. [VERIFIED]
- Architecture: HIGH — current code has clear Lifeline, Audit, Forensics, Presenter, and LiveView boundaries. [VERIFIED]
- Pitfalls: HIGH for scope/ownership pitfalls from locked context; MEDIUM for exact hook execution semantics because callback durability is still a planner decision. [VERIFIED: `35-CONTEXT.md`; ASSUMED: A2]

**Research date:** 2026-05-27  
**Valid until:** 2026-06-26 for repo architecture; 2026-06-03 for library "latest version" claims because Ecto/Phoenix/Telemetry are actively releasing. [VERIFIED: `mix hex.info` recent release cadence]
