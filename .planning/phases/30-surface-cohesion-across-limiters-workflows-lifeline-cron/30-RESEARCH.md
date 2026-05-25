# Phase 30: surface-cohesion-across-limiters-workflows-lifeline-cron - Research

**Researched:** 2026-05-25
**Domain:** Phoenix LiveView control-plane cohesion across native operator pages
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md`. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]

### Locked Decisions
- **D-01:** For this repo, discuss-phase and downstream agents must research repo-local artifacts, nearby phase context, relevant prompts, and adjacent implementation surfaces before asking the user to resolve a gray area.
- **D-02:** Prefer one-shot, research-backed recommendations over interactive option shopping. Narrow aggressively unless multiple options remain genuinely viable after local research.
- **D-03:** Do not escalate choices that can be settled by existing repo decisions, Phoenix/LiveView/Ecto/Postgres norms, ecosystem best practice, or direct inspection of the current implementation.
- **D-04:** Only ask the user about forks that materially change public product semantics, support truth, architectural boundaries, operator trust, or long-term maintainer burden.
- **D-05:** Treat prior `CONTEXT.md` decisions as locked defaults. Reopen them only when the current phase would otherwise create a real contract conflict.
- **D-06:** When escalation is necessary, present a recommended path first and ask the narrowest possible question rather than a broad design interview.
- **D-07:** Workflow, Lifeline, cron, and limiter detail surfaces should converge on one shared opening stack:
  `status badge -> diagnosis sentence -> next action -> venue -> evidence`.
- **D-08:** The shared operator status remains the compact scan layer only. It must not be the first full explanatory sentence on detail views.
- **D-09:** The first sentence on each selected resource must answer “what is happening and why?” in control-plane language derived from durable facts rather than page-local prose.
- **D-10:** Shared presenter and read-model seams own this opening story. Do not hand-author the resource-opening sentence independently in each LiveView.
- **D-11:** Cross-surface tests should assert opening-story order and continuity language, not only the existence of preview/reason/audit copy.
- **D-12:** Limiters remain a **Powertools-native diagnosis surface**, not a native mutation venue.
- **D-13:** The limiter page should adopt the shared control-plane reading order:
  `operator status -> diagnosis -> legal next action -> venue -> evidence`.
- **D-14:** `Live Now` and `Snapshot at Block Start` remain, but as supporting evidence beneath the diagnosis layer rather than as the page’s primary mental model.
- **D-15:** The limiter list CTA should be framed as review/open diagnosis, not as an `Action`; do not imply audited mutation where none exists.
- **D-16:** Limiters continue mapping into `blocked`, `waiting`, and `runnable`. Do not force `needs_review` onto ordinary saturation/cooldown states unless a distinct operator-intervention contract is introduced later.
- **D-17:** Limiter next-action guidance may legitimately stay read-only, such as review native diagnosis, inspect the blocked job in the Oban Web bridge, or wait for cooldown. It does not need to be executable on the current page.
- **D-18:** Venue must stay explicit whenever the next useful inspection leaves the native limiter page, especially for generic job drilldowns into the Oban Web bridge.
- **D-19:** Workflow keeps its diagnosis-first posture, but cron and Lifeline must be brought up to the same opening-story contract rather than pulling workflow back toward status-first wording.
- **D-20:** Lifeline must stop leading selected-resource detail with health/detection/repair framing alone; those remain supporting evidence after the diagnosis sentence.
- **D-21:** Cron must stop leading selected-resource detail with operator status alone; paused/ready/run-now semantics should be expressed first as diagnosis copy, with status retained as the badge.
- **D-22:** Legal next move and venue should follow immediately after diagnosis whenever the operator may otherwise confuse “what should happen next” with “what can be done on this page right now.”
- **D-23:** Keep machine-facing status, refusal codes, and raw state visible as support/debug depth, but secondary to the shared operator story.
- **D-24:** URL and router params own durable continuity selectors, not just bare selection, when a destination needs more than one stable key to reopen the same follow-up slice.
- **D-25:** Allowed continuity params are stable identifiers and scoped view/filter keys such as `resource`, `entry`, `id`, `step`, `view`, `row-id`, `incident_fingerprint`, `workflow_id`, `action`, `resource_type`, `resource_id`, `event_type`, and later `command_key` where warranted.
- **D-26:** Rendered diagnosis, refusal, venue, next-step copy, audit prose, reason text, preview token, preview lifecycle state, and any other mutation internals stay off the URL.
- **D-27:** Cross-surface navigation must reconstruct operator framing from the destination read model using router-backed selectors, not by trusting source-surface prose serialized into params.
- **D-28:** Refresh, remount, reconnect, and read-only access should reopen the same scoped continuity slice where the destination supports it, but must always show current durable truth rather than a frozen historical narrative.
- **D-29:** Audit continuity is canonicalized through URL-backed filters on `/ops/jobs/audit`; local pages should deep-link into those scoped filters rather than inventing separate history-state schemes.
- **D-30:** Bridge continuity should remain venue-honest: params may preserve the inspection target, but must not make bridge pages appear equivalent to Powertools-native diagnosis or audited-action surfaces.
- **D-31:** The canonical selection contract for limiters remains `resource=` in the URL; no preview or mutation state belongs on that page.
- **D-32:** Keep generic inspection and product-specific diagnosis separate. The native Powertools shell should own Powertools-specific explanation and bounded action posture, while generic queue/job inspection remains an explicit bridge responsibility.
- **D-33:** Dangerous or policy-bearing actions should remain explicit, preview-first where applicable, and audit-backed rather than hidden behind ambiguous single-click shortcuts or overloaded drilldown links.
- **D-34:** URL-backed drilldowns and query-backed scoped filters are the preferred continuity model for operator surfaces; avoid ephemeral local-only state for durable follow-up flows.
- **D-35:** Avoid turning the control plane into a generic dashboard theater layer. Cohesion should come from shared language and follow-up rules, not from flattening every surface into the same chrome regardless of domain.

### Claude's Discretion
- Exact module, component, and helper names for any shared opening-story presenter or read-model seam, provided wording ownership stays centralized and testable.
- Exact badge/component layout and spacing, provided the shared opening stack and venue honesty remain intact.
- Exact continuity-param helper structure, provided params stay stable, documented, and limited to durable selectors.
- Exact evidence-card density and wording polish, provided diagnosis remains the first sentence and evidence stays grounded in durable truth.

### Deferred Ideas (OUT OF SCOPE)
- Full native replacement of generic Oban Web job or queue inspection.
- New limiter mutation or repair controls.
- Persisting rendered diagnosis, refusal, or preview wording into shareable URLs.
- A broader operator inbox, analytics, or reporting dashboard beyond the current control-plane cohesion scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OVR-03 | Native pages converge on one shared drill-down mental model so selected resource, diagnosis, and follow-up action state survive refresh, remount, and read-only access coherently. | Use router-owned selector params plus `handle_params/3` on every native detail surface; keep rendered prose and preview state off the URL. [VERIFIED: lib/oban_powertools/web/limiters_live.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| ACT-02 | Workflow-directed actions, Lifeline repairs, and cron mutations all present one shared policy story for what can happen next, why an action is unavailable, and where durable evidence will land. | Reuse `ControlPlanePresenter` and `LiveAuth` as the central wording seam, then align each page’s opening story and refusal/venue copy to the same order. [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex] [VERIFIED: lib/oban_powertools/web/live_auth.ex] [VERIFIED: test/oban_powertools/web/live/control_plane_copy_coherence_test.exs] |
| ACT-03 | The audit destination can be read as part of the same control plane, with resource links and event metadata that match the shared operator vocabulary used on native pages. | Keep `/ops/jobs/audit` query-backed and canonical; deepen follow-up links from local pages into `resource_type/resource_id/event_type` filters instead of separate local schemes. [VERIFIED: lib/oban_powertools/web/audit_live.ex] [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex] [VERIFIED: lib/oban_powertools/audit.ex] |
</phase_requirements>

## Summary

Phase 30 should be planned as a presentation-and-read-model cohesion pass, not as a new capability phase. The repo already has the right mechanical primitives: a shared status taxonomy in `ObanPowertools.ControlPlane`, shared operator/venue wording in `ObanPowertools.Web.ControlPlanePresenter`, shared permission and refusal categories in `ObanPowertools.Web.LiveAuth`, router-backed detail params on every relevant LiveView, and canonical audit filters on `/ops/jobs/audit`. [VERIFIED: lib/oban_powertools/control_plane.ex] [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex] [VERIFIED: lib/oban_powertools/web/live_auth.ex] [VERIFIED: lib/oban_powertools/web/limiters_live.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] [VERIFIED: lib/oban_powertools/web/audit_live.ex]

The planning risk is not missing infrastructure; it is wording drift and read-model drift. Limiters still lead with evidence-first blocks and an action-shaped CTA, cron still leads selected-entry detail with operator status rather than diagnosis, Lifeline detail still opens on detection/repair sections rather than a unified diagnosis sentence, and audit still reads like a filtered event table more than a continuation of the same operator story. [VERIFIED: lib/oban_powertools/web/limiters_live.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] [VERIFIED: lib/oban_powertools/web/audit_live.ex]

The safest plan is therefore additive: centralize an “opening story” seam in the presenter/read-model layer, rewrite each selected-resource pane to render `status badge -> diagnosis sentence -> next action -> venue -> evidence`, keep continuity owned by stable URL selectors through `handle_params/3`, and expand the existing LiveView test lane to assert order, venue honesty, and remount-safe follow-up. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md] [VERIFIED: test/oban_powertools/web/live/control_plane_copy_coherence_test.exs] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

**Primary recommendation:** Implement Phase 30 by extracting one shared opening-story presenter contract and applying it across limiters, cron, workflows, Lifeline, and audit-linked follow-up without adding new dependencies or widening mutation scope. [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex] [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Shared opening-story wording | Frontend Server (SSR) | API / Backend | LiveViews render operator copy, but the facts come from durable read models and control-plane status mapping. [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex] [VERIFIED: lib/oban_powertools/control_plane.ex] |
| Limiter diagnosis and bridge handoff | Frontend Server (SSR) | API / Backend | The limiter page is a native diagnosis surface rendered in LiveView over `Explain` and limiter state data, with explicit bridge links for generic job inspection. [VERIFIED: lib/oban_powertools/web/limiters_live.ex] |
| Workflow/Lifeline/cron next-action cohesion | Frontend Server (SSR) | API / Backend | Each page renders read-only or preview-first policy story from server-side facts and permissions. [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] |
| URL-backed continuity selectors | Frontend Server (SSR) | Browser / Client | LiveView `patch` and `handle_params/3` own durable selection state, while the browser only carries the URL/history. [VERIFIED: lib/oban_powertools/web/limiters_live.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Audit follow-up and scoped continuity | Frontend Server (SSR) | Database / Storage | `/ops/jobs/audit` reads canonical event data via query-backed filters on durable audit rows. [VERIFIED: lib/oban_powertools/web/audit_live.ex] [VERIFIED: lib/oban_powertools/audit.ex] |
| Authorization/read-only posture | API / Backend | Frontend Server (SSR) | `LiveAuth` enforces the permission outcome server-side and pages render the resulting posture. [VERIFIED: lib/oban_powertools/web/live_auth.ex] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | 1.8.7 locked, released 2026-05-06 | Router and LiveView host framework | The repo is already router-mounted and Phase 30 is a native LiveView cohesion pass, not a framework change. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix] |
| Phoenix LiveView | 1.1.30 locked, released 2026-05-05 | URL-owned drill-down state, LiveView patches, server-rendered detail panes | Official docs define `patch`/`push_patch` plus `handle_params/3` as the standard way to keep current-LiveView URL state without remounting. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Oban | 2.22.1 locked, released 2026-04-30 | Durable cron/workflow/lifeline/limiter backing data | The control plane already projects its operator story from persisted Oban Powertools/Oban state rather than client state. [VERIFIED: mix.lock] [VERIFIED: mix hex.info oban] |
| Ecto SQL | 3.13.5 locked, latest release 3.14.0 on 2026-05-19 | Query-backed read models and audit filtering | Phase 30 should reuse existing Ecto queries and avoid in-memory continuity schemes. No upgrade is needed for this phase. [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: lib/oban_powertools/audit.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban Web | 2.12.4 locked, released 2026-05-11 | Explicit generic inspection bridge | Use only for venue-honest deep links where Powertools does not own native diagnosis or mutation semantics. [VERIFIED: mix.lock] [VERIFIED: mix hex.info oban_web] [VERIFIED: lib/oban_powertools/web/router.ex] |
| Phoenix.LiveViewTest | bundled with Phoenix LiveView 1.1.30 | Remount, patch, and copy-order proof | Use to assert selector continuity, patch semantics, and cross-surface copy order in existing LiveView tests. [VERIFIED: test/support/live_case.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared presenter/read-model wording seam | Per-page HEEx prose | Faster locally, but it directly conflicts with locked Phase 30 decisions against hand-authored opening sentences per LiveView. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md] |
| URL-backed selector continuity | Local-only assigns or client state | Simpler initially, but it breaks refresh/remount/read-only continuity and ignores LiveView’s standard patch model. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Audit scoped filters as canonical follow-up | Per-page local history panels as separate state models | Panels can stay bounded, but global continuity must still collapse into `/ops/jobs/audit` filters to satisfy ACT-03. [VERIFIED: lib/oban_powertools/web/audit_live.ex] [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** Phoenix 1.8.7, Phoenix LiveView 1.1.30, Oban 2.22.1, and Oban Web 2.12.4 are current locked releases in this repo and current release lines as of 2026-05-25; Ecto SQL is locked at 3.13.5 while Hex shows 3.14.0 as the latest release, so do not fold a dependency upgrade into Phase 30. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info oban] [VERIFIED: mix hex.info oban_web] [VERIFIED: mix hex.info ecto_sql]

## Architecture Patterns

### System Architecture Diagram

```text
Operator click / bookmarked URL
        |
        v
Phoenix Router -> LiveView mount
        |
        v
handle_params/3 reads stable selectors
resource / entry / id / step / view / incident_fingerprint / audit filters
        |
        v
Read model + presenter seam
ControlPlane + Explain + Audit + page-specific selectors
        |
        +--> Diagnosis sentence
        +--> Next action
        +--> Venue
        +--> Evidence blocks
        |
        v
Selected native page detail pane
limiters / cron / workflows / lifeline / audit
        |
        +--> native follow-up -> preview / reason / audit
        |
        +--> bridge-only follow-up -> /ops/jobs/oban or job link
```

The planner should treat the opening story as a read-model composition problem, with LiveViews assembling shared sections from durable facts rather than composing page-local prose in templates. [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex] [VERIFIED: lib/oban_powertools/web/overview_read_model.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex]

### Recommended Project Structure

```text
lib/oban_powertools/web/
├── control_plane_presenter.ex   # Shared status, venue, audit, and new opening-story helpers
├── overview_read_model.ex       # Existing cross-surface bucket/read-model logic to keep aligned
├── limiters_live.ex             # Limiter diagnosis surface and bridge handoff
├── cron_live.ex                 # Cron detail and preview-first mutation surface
├── workflows_live.ex            # Diagnosis-first workflow detail and Lifeline handoff
├── lifeline_live.ex             # Native execution venue and continuity selectors
└── audit_live.ex                # Canonical scoped audit destination
```

### Pattern 1: Router-Owned Durable Selection
**What:** Keep only stable selectors in the URL and load page detail through `handle_params/3`. [VERIFIED: lib/oban_powertools/web/limiters_live.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]  
**When to use:** Any selected-resource or follow-up slice that must survive refresh, remount, reconnect, or read-only mode. [VERIFIED: test/oban_powertools/web/live/limiters_live_test.exs] [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs] [VERIFIED: test/oban_powertools/web/live/workflows_live_test.exs] [VERIFIED: test/oban_powertools/web/live/lifeline_live_test.exs]  
**Example:**
```elixir
def handle_params(params, _uri, socket) do
  {:noreply,
   socket
   |> load_resources()
   |> load_selection(Map.get(params, "resource"))}
end
```
Source: [lib/oban_powertools/web/limiters_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/limiters_live.ex:24) [VERIFIED: codebase]

### Pattern 2: Same-LiveView State Changes Use Patch
**What:** Use `push_patch/2` or `<.link patch={...}>` for selector changes within the same LiveView. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html]  
**When to use:** Row selection, tab/view changes, or scoped detail changes that stay on the same page. [VERIFIED: lib/oban_powertools/web/limiters_live.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]  
**Example:**
```elixir
{:noreply, push_patch(socket, to: "/ops/jobs/cron?entry=#{URI.encode_www_form(entry_name)}")}
```
Source: [lib/oban_powertools/web/cron_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/cron_live.ex:40) [VERIFIED: codebase]

### Pattern 3: Shared Presenter Owns Operator Copy
**What:** Generate shared status/venue/refusal/audit labels in one presenter seam and keep domain services machine-facing. [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex] [VERIFIED: lib/oban_powertools/web/live_auth.ex]  
**When to use:** Any diagnosis sentence, legal-next-move sentence, venue label, or audit follow-up label that appears on more than one page. [VERIFIED: test/oban_powertools/web/live/control_plane_copy_coherence_test.exs]  
**Example:**
```elixir
def workflow_refusal(rejection) do
  %{
    outcome: "Needs Review",
    reason: rejection.message || refusal_reason_label(rejection.code),
    next_move: legal_next_move_label(rejection.legal_next_steps),
    venue: refusal_venue_label(rejection.legal_next_steps),
    code: rejection.code
  }
end
```
Source: [lib/oban_powertools/web/control_plane_presenter.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/control_plane_presenter.ex:45) [VERIFIED: codebase]

### Anti-Patterns to Avoid
- **Page-local opening prose drift:** It makes Phase 30 untestable and reintroduces vocabulary skew immediately after this phase. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]
- **Mutating the URL with diagnosis/refusal/preview internals:** Official LiveView guidance and locked repo decisions both point to params for durable selectors only. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]
- **Treating limiters like an action surface:** The page is read-only diagnosis plus venue-honest bridge follow-up, not a hidden mutation venue. [VERIFIED: lib/oban_powertools/web/limiters_live.ex] [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]
- **Building a fake native parity layer over Oban Web:** The router and project docs freeze the bridge as inspection-only. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: .planning/PROJECT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Refresh-safe drill-down continuity | Client store or hidden assigns-only state | LiveView `patch` plus `handle_params/3` | This is the official LiveView pattern and the repo already uses it successfully on four surfaces. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [VERIFIED: lib/oban_powertools/web/limiters_live.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] |
| Cross-surface operator wording | New copy DSL or per-page strings | `ControlPlanePresenter` plus page read models | The shared seam already exists and current coherence tests depend on it. [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex] [VERIFIED: test/oban_powertools/web/live/control_plane_copy_coherence_test.exs] |
| Audit follow-up routing | Local history-state schemes | Canonical `/ops/jobs/audit` query filters | `Audit.list_all/2` already supports query-backed filtering on `resource_type`, `resource_id`, and `event_type`. [VERIFIED: lib/oban_powertools/audit.ex] [VERIFIED: lib/oban_powertools/web/audit_live.ex] |
| Generic job detail in native pages | New queue/job dashboard | Explicit Oban Web bridge links | The product posture deliberately keeps generic inspection bridge-only for now. [VERIFIED: .planning/PROJECT.md] [VERIFIED: lib/oban_powertools/web/router.ex] |

**Key insight:** Phase 30 should compose existing primitives into one operator story, not introduce a new state-management, copy-management, or dashboard subsystem. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md]

## Common Pitfalls

### Pitfall 1: Leading with status labels instead of diagnosis sentences
**What goes wrong:** The page feels internally correct but cross-surface inconsistent because a badge replaces the first explanatory sentence. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]  
**Why it happens:** Cron and some existing detail panes already expose status fields, so it is tempting to reuse them as the headline. [VERIFIED: lib/oban_powertools/web/cron_live.ex]  
**How to avoid:** Render the badge as the scan layer, then generate the first prose sentence from the shared opening-story presenter. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]  
**Warning signs:** The first sentence on a detail pane starts with `Operator Status:` or a health label rather than “what is happening and why.” [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]

### Pitfall 2: Reusing action-shaped CTAs on read-only diagnosis pages
**What goes wrong:** Operators infer an audited mutation contract where the page is actually inspection-only. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]  
**Why it happens:** The current limiter table uses `Inspect Job Blockers` under an `Action` column, which frames the page like a mutation surface. [VERIFIED: lib/oban_powertools/web/limiters_live.ex]  
**How to avoid:** Rename the column and CTA to review/open diagnosis language and surface the venue explicitly when the next step is bridge-only. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]  
**Warning signs:** Buttons or table headings say `Action` on limiters even though no preview/reason/audit flow exists. [VERIFIED: lib/oban_powertools/web/limiters_live.ex]

### Pitfall 3: Serializing rendered story text into params
**What goes wrong:** Refresh-safe links become stale narratives instead of recomputed truth. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]  
**Why it happens:** It is easy to preserve UX copy by passing it along, especially across native-to-audit or native-to-bridge handoffs. [INFERENCE from verified sources: the risk follows directly from the locked URL rules and existing selector-based code.]  
**How to avoid:** Pass only stable keys and reconstruct the opening story at the destination from its read model. [VERIFIED: lib/oban_powertools/web/audit_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex] [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]  
**Warning signs:** Params start containing preview tokens, reason text, diagnosis prose, or refusal text. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]

### Pitfall 4: Letting audit continuity diverge from local page continuity
**What goes wrong:** Local “Open in Audit” links work, but the audit page uses different naming or filter assumptions than the source surface. [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex] [VERIFIED: lib/oban_powertools/web/audit_live.ex]  
**Why it happens:** Audit is read-only and can be treated like a separate history page instead of part of the same control plane. [VERIFIED: lib/oban_powertools/web/audit_live.ex]  
**How to avoid:** Keep all audit follow-up links flowing through the same `resource_type/resource_id/event_type` filter vocabulary and shared presenter labels. [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex] [VERIFIED: lib/oban_powertools/audit.ex]  
**Warning signs:** New local history sections invent custom path shapes or require local-only assigns to reopen context. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]

### Pitfall 5: Regressing continuity tests to content-only assertions
**What goes wrong:** Copy appears correct on initial render but breaks after patch/remount or in read-only sessions. [VERIFIED: test/oban_powertools/web/live/limiters_live_test.exs] [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs] [VERIFIED: test/oban_powertools/web/live/lifeline_live_test.exs]  
**Why it happens:** Existing tests already cover content presence, so it is easy to stop short of asserting ordering and patch/remount behavior. [VERIFIED: test/oban_powertools/web/live/control_plane_copy_coherence_test.exs]  
**How to avoid:** Extend the current test lane with `assert_patch`, remount checks, and ordering assertions for the opening stack. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] [VERIFIED: test/oban_powertools/web/live/control_plane_copy_coherence_test.exs]  
**Warning signs:** Tests only assert `html =~ ...` strings without verifying patch/remount paths or semantic order. [VERIFIED: test/oban_powertools/web/live/control_plane_copy_coherence_test.exs]

## Code Examples

Verified patterns from official sources and the current codebase:

### LiveView patch for durable same-page state
```elixir
{:noreply, push_patch(socket, to: ~p"/pages/#{@page + 1}")}
```
Source: `Phoenix.LiveView` live navigation guide. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

### Link component for patch versus navigate
```heex
<.link patch={~p"/details"}>view details</.link>
<.link navigate={~p"/jobs/#{@id}"}>open</.link>
```
Source: `Phoenix.Component.link/1` docs. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html]

### Repo pattern already used for selector continuity
```elixir
def handle_event("toggle_view", %{"view" => view}, socket) do
  {:noreply,
   push_patch(socket,
     to:
       selection_path(%{
         view: view,
         row_id: socket.assigns.selected_row && socket.assigns.selected_row.id,
         incident_fingerprint: selected_fingerprint(socket.assigns.selected_row)
       })
   )}
end
```
Source: [lib/oban_powertools/web/lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:61) [VERIFIED: codebase]

### LiveView test assertion for patch behavior
```elixir
render_click(view, :event_that_triggers_patch)
assert_patch view, "/path"
```
Source: `Phoenix.LiveViewTest.assert_patch/3` docs. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `live_patch` / helper-based live links in older LiveView APIs | `<.link patch={...}>` and `push_patch/2` | Current LiveView 1.1 docs | Phase 30 should stay on current `link/1` and `push_patch/2` semantics when shaping continuity tests and examples. [CITED: https://hexdocs.pm/phoenix_live_view/0.17.6/Phoenix.LiveView.Helpers.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] |
| Content-presence-only UI tests | Patch/remount-aware LiveView tests with ordering assertions | Current LiveViewTest docs plus existing repo proof style | Planner should add semantic-order and continuity assertions instead of pure string existence checks. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] [VERIFIED: test/oban_powertools/web/live/control_plane_copy_coherence_test.exs] |

**Deprecated/outdated:**
- `push_redirect/2` is not the current same-session LiveView navigation guidance; current docs point to `push_navigate/2` for LiveView-to-LiveView navigation and `push_patch/2` for the same LiveView. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Existing “recent audit” list rendering in cron is acceptable as-is for Phase 30 even though it currently filters in memory after `Audit.list_all/1`. | Common Pitfalls / planning scope | If this should be optimized in-phase, planner may under-scope a read-model cleanup. [ASSUMED] |

## Open Questions

1. **Should Phase 30 normalize the cron and limiter list table labels as part of the opening-story pass, or only the selected-detail panes?**
   - What we know: Locked decisions explicitly call out the limiter list CTA framing and shared drill-down mental model, while the strongest wording requirements target selected-resource openings. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md]
   - What's unclear: Whether cron’s row-level `Review Entry` and table headings should be fully rewritten in the same phase or treated as supporting polish. [VERIFIED: lib/oban_powertools/web/cron_live.ex]
   - Recommendation: Plan list-surface wording changes when they alter the operator contract (`Action` vs `Review`, bridge/native honesty), but keep broad visual restyling out of scope. [INFERENCE from verified sources]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build and test execution | ✓ | 1.19.5 | — [VERIFIED: `elixir --version`] |
| Mix | Test runner and dependency metadata | ✓ | 1.19.5 | — [VERIFIED: `mix --version`] |
| PostgreSQL CLI/server | Local Ecto/Postgres test repo | ✓ | 14.17 | — [VERIFIED: `psql --version`] [VERIFIED: `postgres --version`] |
| Docker | Optional local infra fallback | ✓ | 29.4.1 | Local Postgres already present [VERIFIED: `docker --version`] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local environment probes]

**Missing dependencies with fallback:**
- None. [VERIFIED: local environment probes]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 with Phoenix.LiveViewTest from Phoenix LiveView 1.1.30. [VERIFIED: test/test_helper.exs] [VERIFIED: test/support/live_case.ex] [VERIFIED: mix --version] [VERIFIED: mix.lock] |
| Config file | `test/test_helper.exs` plus `test/support/live_case.ex`. [VERIFIED: test/test_helper.exs] [VERIFIED: test/support/live_case.ex] |
| Quick run command | `mix test test/oban_powertools/web/live/control_plane_copy_coherence_test.exs --seed 0` [VERIFIED: executed 2026-05-25, 1 test, 0 failures] |
| Full suite command | `mix test` [VERIFIED: test tree detected in `test/`] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OVR-03 | Selected limiter/cron/workflow/lifeline/audit continuity survives patch/remount/read-only with durable selectors only. | LiveView integration | `mix test test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs --seed 0` | ✅ [VERIFIED: test files exist] |
| ACT-02 | Workflow/Lifeline/cron opening story, refusal wording, next action, and venue language read as one policy surface. | LiveView integration | `mix test test/oban_powertools/web/live/control_plane_copy_coherence_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs --seed 0` | ✅ [VERIFIED: test files exist] |
| ACT-03 | Audit destination vocabulary and follow-up links match native pages and stay router-backed. | LiveView integration | `mix test test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/control_plane_copy_coherence_test.exs --seed 0` | ✅ [VERIFIED: test files exist] |

### Sampling Rate
- **Per task commit:** `mix test test/oban_powertools/web/live/control_plane_copy_coherence_test.exs --seed 0` [VERIFIED: executed and passing on 2026-05-25]
- **Per wave merge:** `mix test test/oban_powertools/web/live/*.exs --seed 0` [VERIFIED: live test files exist]
- **Phase gate:** `mix test` [VERIFIED: standard project test entrypoint]

### Wave 0 Gaps
- None in infrastructure. Existing LiveView test scaffolding, Postgres-backed test repo, and cross-surface coherence tests already exist; implementation work should extend assertions rather than create new test foundations. [VERIFIED: test/support/live_case.ex] [VERIFIED: test/test_helper.exs] [VERIFIED: test/oban_powertools/web/live/control_plane_copy_coherence_test.exs]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host apps own auth policy; Powertools reads `current_actor` and enforces page/action authorization through `LiveAuth`. [VERIFIED: lib/oban_powertools/web/live_auth.ex] [VERIFIED: .planning/PROJECT.md] |
| V3 Session Management | no | Session lifecycle is host-owned; this phase should not change it. [VERIFIED: .planning/PROJECT.md] |
| V4 Access Control | yes | `LiveAuth.authorize_page/3`, `authorize_action/4`, and read-only banners keep access checks server-side. [VERIFIED: lib/oban_powertools/web/live_auth.ex] |
| V5 Input Validation | yes | Selector params are whitelisted in `handle_params/3`, and planner should keep any new continuity params limited to stable identifiers only. [VERIFIED: lib/oban_powertools/web/limiters_live.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] |
| V6 Cryptography | no | This phase does not introduce cryptographic primitives. [VERIFIED: phase scope in .planning/ROADMAP.md] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| URL param tampering to reach unsupported follow-up state | Tampering | Recompute detail state from durable selectors in `handle_params/3`; keep preview/reason/refusal prose off the URL. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Unauthorized operator action through UI affordances | Elevation of privilege | Enforce action authorization server-side in `LiveAuth` even when the UI renders disabled controls or direct events. [VERIFIED: lib/oban_powertools/web/live_auth.ex] [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs] |
| Confusing bridge pages with native mutation surfaces | Spoofing | Keep venue badges and posture copy explicit as `Powertools-native` vs `Oban Web bridge` / `Inspection only`. [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex] [VERIFIED: lib/oban_powertools/web/router.ex] |
| Stale continuity text after remount | Repudiation | Rebuild the operator story from current durable truth on every mount/param change rather than passing rendered prose between pages. [VERIFIED: .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md` - locked Phase 30 semantics and out-of-scope rules. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - OVR-03, ACT-02, ACT-03 requirement text and proof posture. [VERIFIED: local file]
- `.planning/ROADMAP.md` - phase breakdown and dependency sequencing. [VERIFIED: local file]
- `.planning/PROJECT.md` - product posture and native-versus-bridge boundary. [VERIFIED: local file]
- [mix.exs](/Users/jon/projects/oban_powertools/mix.exs:1) and `mix.lock` - project stack and locked dependency versions. [VERIFIED: codebase]
- `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `mix hex.info oban`, `mix hex.info oban_web`, `mix hex.info ecto_sql` - current Hex release verification as of 2026-05-25. [VERIFIED: Hex registry]
- [lib/oban_powertools/web/control_plane_presenter.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/control_plane_presenter.ex:1) - shared operator wording seam. [VERIFIED: codebase]
- [lib/oban_powertools/web/limiters_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/limiters_live.ex:1), [cron_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/cron_live.ex:1), [workflows_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/workflows_live.ex:1), [lifeline_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/lifeline_live.ex:1), [audit_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/audit_live.ex:1) - current surface behavior and continuity contracts. [VERIFIED: codebase]
- [lib/oban_powertools/audit.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/audit.ex:1) - canonical audit filter/query model. [VERIFIED: codebase]
- https://hexdocs.pm/phoenix_live_view/live-navigation.html - official LiveView patch/navigate/handle_params guidance. [CITED: hexdocs.pm]
- https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html - official `Phoenix.Component.link/1` docs. [CITED: hexdocs.pm]
- https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html - official `push_patch/2` and `push_navigate/2` docs. [CITED: hexdocs.pm]
- https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html - official patch/remount assertion helpers. [CITED: hexdocs.pm]

### Secondary (MEDIUM confidence)
- `npx --yes ctx7@latest docs /phoenixframework/phoenix_live_view "live navigation handle_params push_patch patch navigate"` - current documentation snippets confirming the same LiveView navigation guidance. [VERIFIED: Context7 CLI]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo stack, lockfile, and current Hex releases are all verified directly. [VERIFIED: mix.lock] [VERIFIED: mix hex.info outputs]
- Architecture: HIGH - the relevant LiveViews, presenter seam, audit model, and prior phase constraints are all present in the codebase. [VERIFIED: lib/oban_powertools/web/*.ex] [VERIFIED: .planning/phases/27-30-*]
- Pitfalls: MEDIUM - code and tests expose the current weak spots clearly, but the exact final copy phrasing still requires implementation judgment. [VERIFIED: codebase] [VERIFIED: tests]

**Research date:** 2026-05-25
**Valid until:** 2026-06-24
