# Phase 34: Historical Attention Projection & Runbook Entry Surfaces - Research

**Researched:** 2026-05-27 [VERIFIED: system date]
**Domain:** Phoenix LiveView/Ecto read-model extension for diagnosis-first operational forensics and advisory runbook entry surfaces [VERIFIED: .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: codebase inspection + Hex package metadata + official Phoenix/Ecto docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

All content in this section is copied from `.planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-CONTEXT.md`. [VERIFIED: 34-CONTEXT.md]

### Locked Decisions
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Keep recommendation-first planning for this repo. Downstream agents
  should read repo-local context and implementation surfaces, narrow choices
  aggressively, and ask only if a fork changes public semantics, support truth,
  architectural boundaries, operator trust, or maintainer burden.
- **D-02:** Preserve the v1.3/v1.4 product posture: native Powertools pages own
  Powertools diagnosis and bounded audited action truth; the Oban Web bridge is
  inspection-only; host apps own external escalation and delivery truth.
- **D-03:** Treat the Phase 28 diagnosis-first overview, Phase 29 shared
  refusal/audit wording, Phase 30 shared opening-story contract, Phase 32
  forensic bundle contract, and Phase 33 limiter/cron history semantics as
  locked inputs.

### Historical Attention Projection
- **D-04:** Extend the existing overview buckets with historical attention
  projection rather than adding a separate raw history feed or generic
  “Historical Attention” dashboard band.
- **D-05:** Historical evidence may influence exemplar priority, attention
  reason, and next-path selection inside the existing diagnosis-first buckets,
  but it must not replace current-state operator status as the primary scan
  model.
- **D-06:** Attention projection should stay bounded and deterministic: one to
  three exemplar items per relevant bucket, each with a concise reason derived
  from durable facts or explicit partial-evidence state.
- **D-07:** Runbook-entry cards may be layered into overview and drill-down
  surfaces only for diagnosis states that have honest guidance. Do not show
  “interesting history” as a call to action when Powertools cannot state a safe
  next path.
- **D-08:** Projection ordering should favor actionable, symptom-oriented
  signals over recency theater. Recent limiter pressure, cron missed-fire or
  unknown-window evidence, workflow blocked steps, and Lifeline incidents should
  rank when they change what an operator should safely do next.
- **D-09:** Missing history, retention gaps, or incomplete provenance must remain
  visible as `partial evidence`, `history unavailable`, or `unknown`; never let
  an attention card imply certainty the forensic bundle cannot support.

### Runbook Entry Surface Shape
- **D-10:** Use a lightweight hybrid runbook surface: overview and selected native
  drilldowns show compact runbook-entry summaries, while `/ops/jobs/forensics`
  owns the deeper evidence-grounded runbook entry.
- **D-11:** The canonical runbook entry belongs in the same shared read-model
  family as forensic bundles, not as page-local HEEx prose. It should be
  assembled from diagnosis, evidence completeness, linked resources, and legal
  next paths.
- **D-12:** A runbook entry should contain, at minimum:
  diagnosis state, why it matters now, prerequisites, cautions, recommended
  order of operations, ownership/venue for each follow-up path, evidence link,
  and unsupported or partial-evidence boundaries.
- **D-13:** Phase 34 runbook entries are advisory and evidence-grounded. They may
  point to a native investigation, a bridge-only inspection, or a host-owned
  follow-up, but they must not create the impression that Powertools has already
  executed or recorded a remediation attempt.
- **D-14:** Do not introduce a persisted checklist/session model in Phase 34.
  Persisted attempted-step context, action continuity, and post-remediation
  evidence belong to Phase 35.
- **D-15:** Host-owned runbook links or external escalation destinations should
  stay optional and explicitly host-owned. Phase 34 may prepare the semantic
  slot for them, but should not make first product value depend on host
  configuration.

### Ownership Boundary and Copy Alignment
- **D-16:** Use a presenter-owned ownership triad for runbook and follow-up
  wording: `Powertools-native`, `Oban Web bridge`, and `host-owned follow-up`.
- **D-17:** Runbook entries and refusal-adjacent copy should share the same
  operator shape already locked in prior phases:
  `outcome -> concise reason -> legal next move -> venue -> evidence`.
- **D-18:** The ownership/venue label must appear at the decision point where an
  operator chooses the next path, not only after navigation.
- **D-19:** Avoid noisy badge repetition. Ownership should be mandatory in
  structured runbook/follow-up data and consistently rendered at decision
  points, but not sprayed across every sentence.
- **D-20:** `Investigate`, `Remediate`, and `Escalate` style verbs may be used as
  action-intent labels only when the ownership/venue remains equally visible.
  Do not let verb-first copy make host-owned escalation or bridge-only
  inspection sound native.
- **D-21:** Unsupported, premature, or host-owned steps should render as honest
  guidance or refusal-adjacent next paths, not disabled mystery controls or
  faux-native action buttons.

### Architecture and Query Posture
- **D-22:** Keep LiveViews thin. Historical attention and runbook-entry assembly
  belong in shared read-model/presenter modules rather than per-surface query
  and copy branches.
- **D-23:** Build on existing Phase 32/33 forensic read models where possible:
  `Forensics.bundle/2`, limiter history summaries, cron history summaries,
  completeness labels, linked resources, and `legal_next_paths`.
- **D-24:** `OverviewReadModel` should remain the overview composition seam, but
  Phase 34 should add shared historical-attention/runbook helpers instead of
  burying new ranking and copy rules directly inside the overview LiveView.
- **D-25:** Stable URL selectors remain the continuity contract:
  `resource_type`, `resource_id`, `workflow_id`, `step`,
  `incident_fingerprint`, and `view` are appropriate; rendered diagnosis,
  reason text, preview tokens, refusal prose, and runbook copy stay off URLs.
- **D-26:** Prefer additive internal structs or maps for runbook entries over a
  broad host-facing DSL. The structure should be testable and reusable by Phase
  35 without freezing a public automation API.

### Proof and Support-Truth Guardrails
- **D-27:** Phase 34 proof should assert that overview attention projection stays
  bounded, diagnosis-first, and not feed-like.
- **D-28:** Proof should assert that overview summaries, drill-down summaries,
  and forensic runbook entries agree because they share read models or presenter
  vocabulary.
- **D-29:** Tests must cover native, bridge-only, and host-owned follow-up labels
  before navigation or action.
- **D-30:** Tests must cover partial-evidence and history-unavailable states so
  attention/runbook guidance does not imply certainty when retained evidence is
  missing.
- **D-31:** Phase 34 should not claim remediation continuity, escalation
  delivery, or runbook execution in docs, UI, tests, or comments. Those claims
  become eligible only after Phase 35 implements and proves them.

### Claude's Discretion
- Exact module and struct names for historical-attention and runbook-entry read
  models, provided the assembly is centralized, testable, and reusable by Phase
  35.
- Exact attention scoring weights and exemplar ordering, provided they remain
  deterministic, bounded, and explanation-backed.
- Exact compact versus deep runbook layout split, provided the overview stays
  scannable and `/ops/jobs/forensics` remains the canonical evidence-grounded
  runbook entry.
- Exact wording polish for prerequisites and cautions, provided ownership,
  venue, evidence completeness, and unsupported boundaries stay explicit.

### Deferred Ideas (OUT OF SCOPE)
- Persisted runbook sessions, checklists, attempted-step state, and remediation
  continuity — Phase 35.
- First-party alert delivery, PagerDuty/Slack/ticketing adapters, or external
  escalation ownership — later milestone or host-owned companion seam.
- Host-configured external runbook registries as a required first-value path.
- Generic historical event feed, raw audit/history console, or table-first
  operator inbox.
- Machine-facing CLI/API automation contracts for runbook or remediation flows.
</user_constraints>

## Summary

Phase 34 should be planned as an additive read-model and presenter extension, not as a new persistence or automation phase. [VERIFIED: 34-CONTEXT.md; lib/oban_powertools/web/overview_read_model.ex; lib/oban_powertools/forensics.ex] The overview already centralizes diagnosis-first buckets, bounded exemplars, venue labels, and next-step paths in `OverviewReadModel.build/1`, while LiveView rendering is thin and consumes that read model. [VERIFIED: lib/oban_powertools/web/overview_read_model.ex; lib/oban_powertools/web/engine_overview_live.ex]

The strongest implementation seam is to add shared internal modules for historical attention projection and runbook entries under the forensic/read-model family, then have `OverviewReadModel`, selected drilldowns, and `Forensics.bundle/2` consume the same derived structures. [VERIFIED: 34-CONTEXT.md; lib/oban_powertools/forensics/evidence_bundle.ex] Phase 33 already made limiter and cron history first-class forensic destinations through `LimiterHistory.summary/2`, `CronHistory.summary/2`, and stable `resource_type/resource_id` forensic selectors. [VERIFIED: .planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-CONTEXT.md; lib/oban_powertools/forensics/limiter_history.ex; lib/oban_powertools/forensics/cron_history.ex]

**Primary recommendation:** Implement `ObanPowertools.Forensics.AttentionProjection` plus `ObanPowertools.Forensics.RunbookEntry` as internal read-model helpers consumed by overview, drilldown summaries, and forensic bundles; keep output bounded, diagnosis-first, advisory-only, and venue-honest. [VERIFIED: 34-CONTEXT.md; codebase inspection]

## Project Constraints (from AGENTS.md / CLAUDE.md)

No `AGENTS.md` or `CLAUDE.md` file exists in the project root. [VERIFIED: shell `test -f AGENTS.md`; `test -f CLAUDE.md`] No `.claude/skills/` or `.agents/skills/` project skill files exist. [VERIFIED: `find .claude/skills .agents/skills -name SKILL.md`]

## Requirements Trace

| Requirement | Phase 34 Relevance | Planning Implication |
|-------------|--------------------|----------------------|
| OPS-03 | Native overview can project attention-worthy historical issues from limiters, cron, workflows, and Lifeline without becoming a raw-event feed. [VERIFIED: .planning/REQUIREMENTS.md] | Extend existing buckets and exemplar ordering; cap exemplars at 1-3 per bucket. [VERIFIED: 34-CONTEXT.md] |
| RNB-01 | Operators can see runbook-guided next steps with preconditions, cautions, and recommended order before bounded native action. [VERIFIED: .planning/REQUIREMENTS.md] | Add advisory runbook entry data with prerequisites/cautions/order, but no persisted execution state. [VERIFIED: 34-CONTEXT.md] |
| RNB-02 | Runbook guidance distinguishes Powertools-native, bridge-only, and host-owned/external steps. [VERIFIED: .planning/REQUIREMENTS.md] | Make ownership/venue structured metadata and render it at decision points. [VERIFIED: 34-CONTEXT.md; lib/oban_powertools/web/control_plane_presenter.ex] |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Historical attention ranking | API / Backend read model | Database / Storage | Ranking must derive from durable workflow/Lifeline/current-state/history rows and remain deterministic before rendering. [VERIFIED: lib/oban_powertools/web/overview_read_model.ex; lib/oban_powertools/forensics/cron_history.ex; lib/oban_powertools/forensics/limiter_history.ex] |
| Overview projection rendering | Browser / Client via LiveView-rendered HTML | API / Backend read model | LiveView should render read-model results and avoid owning ranking or copy branching. [VERIFIED: 34-CONTEXT.md; lib/oban_powertools/web/engine_overview_live.ex] |
| Runbook entry assembly | API / Backend read model | Browser / Client via LiveView-rendered HTML | Runbook content must be shared across overview, drilldowns, and forensics, so assembly belongs outside HEEx. [VERIFIED: 34-CONTEXT.md; lib/oban_powertools/forensics.ex] |
| Evidence completeness and provenance | API / Backend read model | Database / Storage | Existing bundle builders normalize completeness/provenance from retained facts and audit evidence. [VERIFIED: lib/oban_powertools/forensics/evidence_bundle.ex; lib/oban_powertools/forensics/provenance.ex] |
| Stable navigation continuity | Frontend Server / LiveView routing | API / Backend selector parsing | Forensics LiveView allows only stable selectors and reconstructs current truth with `Forensics.bundle/2`. [VERIFIED: lib/oban_powertools/web/forensics_live.ex; lib/oban_powertools/forensics.ex] |
| Auth and read-only boundaries | API / Backend / LiveView auth helper | Browser / Client display | LiveViews already call `LiveAuth.authorize_page/3` and expose permission/read-only copy through shared helpers. [VERIFIED: lib/oban_powertools/web/live_auth.ex; lib/oban_powertools/web/forensics_live.ex] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / OTP | Elixir 1.19.5, OTP 28 | Runtime and test execution | Project requires `~> 1.19`; local runtime matches. [VERIFIED: mix.exs; `elixir --version`] |
| Phoenix LiveView | 1.1.30 locked; 1.2.0-rc.2 exists but is prerelease | Native `/ops/jobs` interactive surfaces | Current code uses LiveView modules and tests; LiveView docs describe stateful server-rendered lifecycle and `live/2` testing. [VERIFIED: mix.lock; Hex metadata; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Phoenix | 1.8.7 locked/current | Router, ConnTest, LiveView host integration | Phoenix is already locked and current as of Hex metadata. [VERIFIED: mix.lock; `mix hex.info phoenix`] |
| Ecto / Ecto SQL | Ecto 3.13.6 locked; Ecto SQL 3.13.5 locked; 3.14.0 available | Composable queries and Postgres access | Existing read models use `Ecto.Query`; docs recommend interpolation for dynamic values and composable queries. [VERIFIED: mix.lock; `mix hex.info ecto`; `mix hex.info ecto_sql`; CITED: https://hexdocs.pm/ecto/Ecto.Query.html] |
| Postgrex / PostgreSQL | Postgrex 0.22.2 locked; PostgreSQL 14.17 local | Ecto-native persistence | Project is Ecto/Postgres-native; local Postgres is accepting connections. [VERIFIED: mix.lock; `postgres --version`; `pg_isready`] |
| Oban | 2.22.1 locked/current | Job processing domain and source of operational truth | Phase surfaces are scoped around Oban/Powertools resources; Oban 2.22.1 is current per Hex metadata. [VERIFIED: mix.lock; `mix hex.info oban`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix.HTML | 4.3.0 locked/current | HTML safety and template support | Use existing HEEx interpolation and component primitives for rendering runbook/attention data. [VERIFIED: mix.lock; `mix hex.info phoenix_html`; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] |
| LazyHTML | 0.1.11 locked/current | LiveView DOM assertions in tests | Continue `has_element?/2` style LiveView tests for selectors and bounded rendering. [VERIFIED: mix.lock; `mix hex.info lazy_html`; test/oban_powertools/web/live/engine_overview_live_test.exs] |
| ExUnit / Phoenix.LiveViewTest | Bundled with Elixir / LiveView 1.1.30 | Hermetic projection and LiveView proof | LiveViewTest supports connected mount via `live/2` and DOM checks via `has_element?/2`. [VERIFIED: `mix help test`; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Internal read-model helpers | Persisted runbook/session tables | Out of scope; Phase 35 owns persisted remediation continuity. [VERIFIED: 34-CONTEXT.md] |
| Existing overview buckets | Separate history dashboard/feed | Rejected by locked decision; it would degrade diagnosis-first scanning into feed-like browsing. [VERIFIED: 34-CONTEXT.md] |
| Stable selector URLs | Serialized runbook/reason/copy params | Rejected by prior URL guardrails; destination must reconstruct truth from durable selectors. [VERIFIED: 34-CONTEXT.md; lib/oban_powertools/web/forensics_live.ex] |
| Shared presenter vocabulary | Page-local HEEx prose branches | Rejected by locked architecture posture; copy must remain coherent across overview, drilldowns, and forensics. [VERIFIED: 34-CONTEXT.md; test/oban_powertools/web/live/control_plane_copy_coherence_test.exs] |

**Installation:**
No new dependencies should be planned for Phase 34. [VERIFIED: codebase inspection; 34-CONTEXT.md] Use the current project stack:

```bash
mix deps.get
```

**Version verification:** Package versions were checked with `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `mix hex.info ecto`, `mix hex.info ecto_sql`, `mix hex.info oban`, `mix hex.info postgrex`, `mix hex.info phoenix_html`, and `mix hex.info lazy_html` on 2026-05-27. [VERIFIED: command output] Ecto/Ecto SQL have 3.14.0 releases, but Phase 34 does not need an upgrade because the existing locked versions already support the query and LiveView patterns required. [VERIFIED: command output; codebase inspection]

## Architecture Patterns

### System Architecture Diagram

```text
Operator opens /ops/jobs or drilldown
  -> LiveAuth authorizes page/read-only posture
  -> Thin LiveView calls shared read model
     -> Current state queries: limiters, cron entries, workflows, Lifeline incidents
     -> Historical evidence queries: limiter facts, cron slots/coverage, audit, forensic bundle data
     -> AttentionProjection ranks bounded exemplars by diagnosis-impacting facts
     -> RunbookEntry assembles advisory next paths from diagnosis + completeness + legal_next_paths
  -> LiveView renders existing buckets/drilldowns with compact runbook entries
     -> Operator follows stable selector link
        -> /ops/jobs/forensics parses resource_type/resource_id/workflow_id/step/incident_fingerprint/view
        -> Forensics.bundle/2 reconstructs evidence bundle
        -> Forensic page renders canonical deep runbook entry + evidence completeness
```

All data flow above follows existing LiveView read-model and forensic bundle seams. [VERIFIED: lib/oban_powertools/web/overview_read_model.ex; lib/oban_powertools/web/forensics_live.ex; lib/oban_powertools/forensics.ex]

### Recommended Project Structure

```text
lib/oban_powertools/
├── forensics/
│   ├── attention_projection.ex   # ranks diagnosis-impacting historical signals
│   ├── runbook_entry.ex          # builds advisory runbook entries from bundle/read-model data
│   ├── cron_history.ex           # existing cron history inputs
│   └── limiter_history.ex        # existing limiter history inputs
└── web/
    ├── overview_read_model.ex    # composes buckets with attention/runbook helpers
    ├── control_plane_presenter.ex# shared wording/labels for ownership and completeness
    └── *_live.ex                 # thin renderers only
```

The exact module names are discretionary, but assembly must stay centralized and reusable. [VERIFIED: 34-CONTEXT.md]

### Pattern 1: Shared Read Model Before HEEx

**What:** Build maps/structs that contain title, reason, completeness, venue, path, prerequisites, cautions, and ordered next steps before rendering. [VERIFIED: 34-CONTEXT.md]
**When to use:** Overview buckets, selected drilldown summaries, and forensic bundle runbook sections. [VERIFIED: 34-CONTEXT.md; lib/oban_powertools/web/overview_read_model.ex; lib/oban_powertools/forensics.ex]
**Example:**

```elixir
defmodule ObanPowertools.Forensics.RunbookEntry do
  @moduledoc false

  def from_bundle(bundle) do
    %{
      diagnosis_state: bundle.diagnosis_summary.current,
      reason: bundle.diagnosis_summary.detail,
      evidence_completeness: bundle.completeness.state,
      prerequisites: prerequisites(bundle),
      cautions: cautions(bundle),
      next_paths: Enum.map(bundle.legal_next_paths, &normalize_path/1),
      evidence_path: evidence_path(bundle)
    }
  end
end
```

Source pattern: Existing `EvidenceBundle.build/1` normalizes bundle shape before LiveView rendering. [VERIFIED: lib/oban_powertools/forensics/evidence_bundle.ex]

### Pattern 2: Bounded Attention Projection

**What:** Score candidates by whether historical facts change the next safe operator path, then return at most three exemplars per bucket with a concise reason. [VERIFIED: 34-CONTEXT.md]
**When to use:** Overview buckets and compact drilldown summaries where history modifies priority without replacing current status. [VERIFIED: 34-CONTEXT.md]
**Example:**

```elixir
def project(candidates) do
  candidates
  |> Enum.map(&with_attention_reason/1)
  |> Enum.reject(&is_nil(&1.attention_reason))
  |> Enum.sort_by(&{&1.rank, &1.label})
  |> Enum.take(3)
end
```

The sort must be deterministic and explanation-backed; do not sort solely by newest timestamp. [VERIFIED: 34-CONTEXT.md]

### Pattern 3: Stable Selector Handoff

**What:** Links pass durable selectors only, and destinations rebuild current truth. [VERIFIED: 34-CONTEXT.md; lib/oban_powertools/web/forensics_live.ex]
**When to use:** Overview exemplar links, runbook evidence links, and forensic deep links. [VERIFIED: lib/oban_powertools/web/forensics_live.ex]
**Example:**

```elixir
defp forensics_path(:cron_entry, entry_name) do
  "/ops/jobs/forensics?" <>
    URI.encode_query(%{
      "resource_type" => "cron_entry",
      "resource_id" => entry_name
    })
end
```

Source pattern: `CronLive` and `LimitersLive` already deep-link using `resource_type` and `resource_id`. [VERIFIED: lib/oban_powertools/web/cron_live.ex; lib/oban_powertools/web/limiters_live.ex]

### Anti-Patterns to Avoid

- **Raw history feed:** A generic event list conflicts with OPS-03 and the locked diagnosis-first overview. [VERIFIED: .planning/REQUIREMENTS.md; 34-CONTEXT.md]
- **Runbook execution claims:** Phase 34 guidance is advisory only; persisted sessions and remediation continuity belong to Phase 35. [VERIFIED: 34-CONTEXT.md]
- **Page-local copy forks:** Overview, drilldowns, and forensics must agree through shared data/presenter vocabulary. [VERIFIED: 34-CONTEXT.md; test/oban_powertools/web/live/control_plane_copy_coherence_test.exs]
- **Hidden ownership:** Native, bridge-only, and host-owned venue must be visible before an operator chooses a path. [VERIFIED: 34-CONTEXT.md]
- **URL prose serialization:** Do not include rendered diagnosis text, reason text, preview tokens, refusal prose, or runbook copy in URLs. [VERIFIED: 34-CONTEXT.md; test/oban_powertools/web/live/control_plane_copy_coherence_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LiveView interaction testing | Browser automation harness for this phase | Phoenix.LiveViewTest `live/2`, `element/2`, `has_element?/2` | Existing tests use hermetic LiveView mounting; official docs support connected LiveView testing without a browser. [VERIFIED: test/oban_powertools/web/live/*.exs; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| SQL construction | String-built SQL for attention queries | Ecto.Query interpolation and composable query helpers | Ecto docs require external values to be interpolated with `^` and warn against unsafe fragments for uncontrolled input. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] |
| Evidence bundle shape | Per-page maps with inconsistent fields | Existing `EvidenceBundle.build/1` and `Forensics.bundle/2` | Existing bundle contract already normalizes subject, diagnosis, chronology, related evidence, linked resources, legal paths, and completeness. [VERIFIED: lib/oban_powertools/forensics/evidence_bundle.ex; lib/oban_powertools/forensics.ex] |
| Completeness vocabulary | New labels like "maybe" or "stale" | Existing `complete`, `partial evidence`, `history unavailable`, `unknown` labels | Presenter and provenance modules already define these labels. [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex; lib/oban_powertools/forensics/provenance.ex] |
| Ownership wording | Freeform badge/copy strings | `ControlPlanePresenter` / `ControlPlane` ownership and venue helpers | Current surfaces share `Powertools-native`, `Oban Web bridge`, and inspection/audited-action wording through presenter helpers. [VERIFIED: lib/oban_powertools/web/control_plane_presenter.ex] |

**Key insight:** The hard part is not collecting more facts; it is preserving support truth while projecting only the history that changes the next safe operator path. [VERIFIED: 34-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Feed Creep

**What goes wrong:** Historical facts become a new event stream or dashboard band. [VERIFIED: 34-CONTEXT.md]
**Why it happens:** It is easier to list facts than to decide which facts change diagnosis or next action. [ASSUMED]
**How to avoid:** Keep projection inside existing buckets and require every exemplar to carry an attention reason plus safe next path. [VERIFIED: 34-CONTEXT.md]
**Warning signs:** More than three exemplars per bucket, timestamp-only sorting, or labels like "recent activity" without diagnosis impact. [VERIFIED: 34-CONTEXT.md]

### Pitfall 2: Runbook Overclaiming

**What goes wrong:** Copy implies Powertools executed remediation, delivered escalation, or owns external runbook truth. [VERIFIED: 34-CONTEXT.md]
**Why it happens:** Action-intent verbs like "Remediate" or "Escalate" can sound native if venue labels are separated from the decision point. [VERIFIED: 34-CONTEXT.md]
**How to avoid:** Render ownership/venue on each next path and include unsupported/partial-evidence boundaries in the structured entry. [VERIFIED: 34-CONTEXT.md]
**Warning signs:** Buttons with no venue, disabled mystery controls, or "runbook complete" language. [VERIFIED: 34-CONTEXT.md]

### Pitfall 3: Split-Brain Copy

**What goes wrong:** Overview summaries, drilldown summaries, and forensic entries disagree. [VERIFIED: 34-CONTEXT.md]
**Why it happens:** Copy and selection logic are duplicated in HEEx or individual LiveViews. [VERIFIED: 34-CONTEXT.md]
**How to avoid:** Centralize `RunbookEntry` and `AttentionProjection`; extend `ControlPlanePresenter` for wording. [VERIFIED: 34-CONTEXT.md; lib/oban_powertools/web/control_plane_presenter.ex]
**Warning signs:** Tests assert the same phrase in multiple page files but no shared module owns the phrase. [VERIFIED: test/oban_powertools/web/live/control_plane_copy_coherence_test.exs]

### Pitfall 4: Evidence Certainty Inflation

**What goes wrong:** Missing history or retention gaps still render as confident next steps. [VERIFIED: 34-CONTEXT.md]
**Why it happens:** Summary cards hide completeness labels to stay compact. [ASSUMED]
**How to avoid:** Carry `:complete`, `:partial_evidence`, `:history_unavailable`, or `:unknown` from the forensic bundle into compact runbook summaries. [VERIFIED: lib/oban_powertools/forensics/evidence_bundle.ex; lib/oban_powertools/web/control_plane_presenter.ex]
**Warning signs:** An attention card has no completeness label but links to a bundle whose completeness is partial or unknown. [VERIFIED: 34-CONTEXT.md]

## Code Examples

### Attention Projection Candidate Shape

```elixir
%{
  bucket: :waiting,
  label: entry.name,
  current_status: :waiting,
  attention_reason: "Recent cron history shows overlap policy affecting scheduled execution.",
  evidence_completeness: :complete,
  venue: "Powertools-native",
  path: "/ops/jobs/cron?entry=#{URI.encode_www_form(entry.name)}",
  evidence_path:
    "/ops/jobs/forensics?" <>
      URI.encode_query(%{"resource_type" => "cron_entry", "resource_id" => entry.name})
}
```

This shape follows existing bucket exemplar fields and adds explicit evidence metadata without adding URL prose. [VERIFIED: lib/oban_powertools/web/overview_read_model.ex; 34-CONTEXT.md]

### Runbook Entry Shape

```elixir
%{
  diagnosis_state: "needs_review",
  why_now: "Recent cron history shows a missed fire while scheduler coverage was healthy.",
  prerequisites: ["Confirm scheduler coverage and current entry pause state."],
  cautions: ["Partial evidence means this is an investigation path, not proof of remediation."],
  order: [
    %{label: "Open forensic evidence", venue: "Powertools-native", path: evidence_path},
    %{label: "Inspect related audit", venue: "Oban Web bridge", path: audit_path}
  ],
  unsupported_boundaries: ["Powertools has not recorded a remediation attempt for this entry."]
}
```

Minimum fields derive from the Phase 34 locked runbook contract. [VERIFIED: 34-CONTEXT.md]

### LiveView Rendering Pattern

```elixir
<div :if={bucket.runbook_entry} class="rounded border bg-slate-50 p-3 text-sm">
  <p class="font-medium"><%= bucket.runbook_entry.why_now %></p>
  <div :for={path <- bucket.runbook_entry.order} class="mt-2">
    <.link navigate={path.path} class="text-indigo-700 underline"><%= path.label %></.link>
    <span class="text-zinc-500"> — <%= path.venue %></span>
  </div>
</div>
```

HEEx interpolation and component rendering are the standard Phoenix LiveView template mechanism. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Overview shows only current-state exemplars | Overview should project bounded historical attention inside existing buckets | Phase 34 scope, 2026-05-27 [VERIFIED: 34-CONTEXT.md] | Planner should add attention projection without adding a new feed. [VERIFIED: 34-CONTEXT.md] |
| Limiter/cron only supporting evidence | Limiter/cron are first-class forensic destinations | Phase 33 commit `1b36404` [VERIFIED: 33-CONTEXT.md] | Phase 34 can use their summaries and bundles as strong attention inputs. [VERIFIED: lib/oban_powertools/forensics/cron_history.ex; lib/oban_powertools/forensics/limiter_history.ex] |
| Forensics render legal next paths only | Forensics should own canonical deep runbook entry | Phase 34 scope [VERIFIED: 34-CONTEXT.md] | Planner should extend bundle/read-model shape rather than create page-local runbook prose. [VERIFIED: 34-CONTEXT.md] |

**Deprecated/outdated:**
- Treating chronological history as the primary operator scan model is out of scope for v1.4. [VERIFIED: .planning/REQUIREMENTS.md; 34-CONTEXT.md]
- Treating external escalation as Powertools-owned is out of scope until a later milestone deliberately broadens that contract. [VERIFIED: .planning/REQUIREMENTS.md; 34-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | It is easier to list facts than to decide which facts change diagnosis or next action. | Common Pitfalls | Low; this motivates proof but does not change implementation scope. |
| A2 | Summary cards may hide completeness labels if compactness is over-optimized. | Common Pitfalls | Medium; planner should require compact labels for partial/unknown evidence. |

## Open Questions (RESOLVED)

1. **RESOLVED: Which workflow historical signals qualify for attention projection?** [VERIFIED: codebase inspection; 34-01-PLAN.md; 34-03-PLAN.md]
   - What we know: Workflow bundles include workflow/step diagnosis, audit chronology, legal next paths, and refusal-adjacent copy. [VERIFIED: lib/oban_powertools/forensics.ex; test/oban_powertools/web/live/control_plane_copy_coherence_test.exs]
   - Resolution: Phase 34 uses blocked step/current workflow diagnosis plus scoped audit evidence through `Forensics.bundle/2` for attention projection and runbook handoffs. It does not invent a new workflow history store. [VERIFIED: 34-CONTEXT.md; lib/oban_powertools/forensics.ex; 34-01-PLAN.md; 34-03-PLAN.md]

2. **RESOLVED: How visible should host-owned placeholders be in Phase 34?** [VERIFIED: 34-CONTEXT.md; 34-02-PLAN.md; 34-03-PLAN.md]
   - What we know: Host-owned semantic slots are allowed but first product value must not depend on host configuration. [VERIFIED: 34-CONTEXT.md]
   - Resolution: Phase 34 renders host-owned follow-up entries only when derived from an explicit supported diagnosis boundary. It does not add configuration APIs, external runbook registries, escalation destinations, alert delivery, or first-value dependence on host configuration. [VERIFIED: 34-CONTEXT.md; 34-02-PLAN.md; 34-03-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Build/test | yes | 1.19.5 | None needed. [VERIFIED: `elixir --version`] |
| Erlang/OTP | Build/test | yes | 28 | None needed. [VERIFIED: `elixir --version`] |
| Mix | Dependencies/tests | yes | 1.19.5 | None needed. [VERIFIED: `mix --version`] |
| PostgreSQL | Ecto sandbox tests | yes | 14.17, accepting connections on `/tmp:5432` | None needed. [VERIFIED: `postgres --version`; `pg_isready`] |
| Git | Optional docs commit | yes | 2.41.0 | Skip commit if commit tooling fails. [VERIFIED: `git --version`] |
| Node.js | GSD graph tooling only | yes | v22.14.0 | Not required for implementation. [VERIFIED: `node --version`] |

**Missing dependencies with no fallback:** None found. [VERIFIED: environment audit]

**Missing dependencies with fallback:** None found. [VERIFIED: environment audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest + Ecto SQL Sandbox [VERIFIED: test/support/live_case.ex; `mix help test`] |
| Config file | `config/test.exs`, `test/test_helper.exs` [VERIFIED: file scan] |
| Quick run command | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/control_plane_copy_coherence_test.exs` [VERIFIED: test file scan] |
| Full suite command | `mix test` [VERIFIED: `mix help test`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| OPS-03 | Overview projects bounded historical attention without becoming a feed. [VERIFIED: .planning/REQUIREMENTS.md] | Unit + LiveView | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/forensics_test.exs` | yes; needs new Phase 34 cases. [VERIFIED: file scan] |
| RNB-01 | Runbook entries render diagnosis state, prerequisites, cautions, order, evidence, and boundaries. [VERIFIED: .planning/REQUIREMENTS.md; 34-CONTEXT.md] | Unit + LiveView | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs` | yes; needs new Phase 34 cases. [VERIFIED: file scan] |
| RNB-02 | Next paths distinguish Powertools-native, Oban Web bridge, and host-owned follow-up before navigation/action. [VERIFIED: .planning/REQUIREMENTS.md; 34-CONTEXT.md] | LiveView/copy coherence | `mix test test/oban_powertools/web/live/control_plane_copy_coherence_test.exs test/oban_powertools/web/live/forensics_live_test.exs` | yes; needs host-owned runbook case. [VERIFIED: file scan] |
| Support truth | Partial evidence/history unavailable states do not imply certainty. [VERIFIED: 34-CONTEXT.md] | Unit + LiveView | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/engine_overview_live_test.exs` | yes; needs new Phase 34 projection cases. [VERIFIED: file scan] |

### Sampling Rate

- **Per task commit:** Run the quick command above. [VERIFIED: existing Phase 33 validation posture]
- **Per wave merge:** Run `mix test`. [VERIFIED: ExUnit project setup]
- **Phase gate:** Quick command plus full suite green before `/gsd-verify-work`. [VERIFIED: .planning/config.json validation enabled by absence of explicit false]

### Wave 0 Gaps

- [ ] Add or extend `test/oban_powertools/forensics_test.exs` for `RunbookEntry` and `AttentionProjection` unit behavior. [VERIFIED: file scan]
- [ ] Add `engine_overview_live_test.exs` cases proving bounded/non-feed attention projection and partial-evidence labels. [VERIFIED: file scan]
- [ ] Add `forensics_live_test.exs` cases proving canonical deep runbook entry rendering. [VERIFIED: file scan]
- [ ] Add `control_plane_copy_coherence_test.exs` cases proving native/bridge/host-owned labels before navigation. [VERIFIED: file scan]

## Security Domain

Security enforcement is enabled by default because `.planning/config.json` does not explicitly set `security_enforcement: false`. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Existing `LiveAuth.authorize_page/3` and permission helpers gate pages/actions. [VERIFIED: lib/oban_powertools/web/live_auth.ex] |
| V3 Session Management | yes | LiveViews receive host-owned session data; no new session/runbook persistence should be added. [VERIFIED: lib/oban_powertools/web/engine_overview_live.ex; 34-CONTEXT.md] |
| V4 Access Control | yes | Keep `view_forensics`, `view_overview`, and drilldown permissions on every new entry surface. [VERIFIED: lib/oban_powertools/web/live_auth.ex; test/oban_powertools/web/live/forensics_live_test.exs] |
| V5 Input Validation | yes | Use stable selector allowlists and Ecto interpolation; do not accept prose or preview token params. [VERIFIED: lib/oban_powertools/web/forensics_live.ex; CITED: https://hexdocs.pm/ecto/Ecto.Query.html] |
| V6 Cryptography | no new crypto | Do not introduce cryptographic primitives or signed runbook tokens in Phase 34. [VERIFIED: 34-CONTEXT.md] |

OWASP ASVS is an open standard for designing, developing, and testing modern web applications. [CITED: https://github.com/OWASP/ASVS]

### Known Threat Patterns for Phoenix LiveView / Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Selector tampering | Tampering / Elevation of privilege | Keep `@allowed_params` allowlist and reauthorize target pages; reconstruct truth from server-side selectors. [VERIFIED: lib/oban_powertools/web/forensics_live.ex; lib/oban_powertools/web/live_auth.ex] |
| SQL injection through dynamic ranking queries | Tampering | Use Ecto query interpolation and avoid `unsafe_fragment/1` for uncontrolled input. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] |
| XSS through runbook copy | Information disclosure / Tampering | Render through HEEx interpolation and avoid marking dynamic copy as raw safe HTML. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] |
| Support-truth spoofing | Repudiation / Tampering | Keep venue/completeness structured in read-model data and assert in tests. [VERIFIED: 34-CONTEXT.md; lib/oban_powertools/web/control_plane_presenter.ex] |
| Unauthorized runbook/action surfacing | Elevation of privilege | Runbook entries are advisory; bounded native actions still require existing action permissions. [VERIFIED: 34-CONTEXT.md; lib/oban_powertools/web/live_auth.ex] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-CONTEXT.md` - locked decisions, scope, boundaries, proof guardrails. [VERIFIED]
- `.planning/REQUIREMENTS.md` - OPS-03, RNB-01, RNB-02, support truth gate. [VERIFIED]
- `.planning/STATE.md` - milestone sequencing and prior phase status. [VERIFIED]
- `lib/oban_powertools/web/overview_read_model.ex` - existing overview composition seam. [VERIFIED]
- `lib/oban_powertools/forensics.ex` and `lib/oban_powertools/forensics/evidence_bundle.ex` - forensic bundle assembly contract. [VERIFIED]
- `lib/oban_powertools/forensics/cron_history.ex` and `lib/oban_powertools/forensics/limiter_history.ex` - Phase 33 history inputs. [VERIFIED]
- `lib/oban_powertools/web/control_plane_presenter.ex` and `lib/oban_powertools/web/live_auth.ex` - shared wording and auth posture. [VERIFIED]
- Hex package metadata via `mix hex.info` - package locked/current versions and release dates. [VERIFIED]
- Phoenix LiveView docs - lifecycle and LiveView testing. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html; https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
- Ecto Query docs - composable queries, interpolation, unsafe fragment warning. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html]

### Secondary (MEDIUM confidence)

- OWASP ASVS GitHub page - standard purpose and category framing. [CITED: https://github.com/OWASP/ASVS]

### Tertiary (LOW confidence)

- None. [VERIFIED: source review]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions verified from `mix.lock`, `mix hex.info`, and local runtime commands. [VERIFIED]
- Architecture: HIGH - phase decisions and existing code strongly agree on shared read-model/presenter seams. [VERIFIED]
- Pitfalls: MEDIUM - most pitfalls are locked by phase decisions; two causal explanations are marked assumed. [VERIFIED + ASSUMED]

**Research date:** 2026-05-27 [VERIFIED: system date]
**Valid until:** 2026-06-26 for codebase architecture; 2026-06-03 for dependency currency. [ASSUMED]
