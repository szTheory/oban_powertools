# Phase 38: Docs and Example-Host Forensics Journey Closure - Pattern Map

**Mapped:** 2026-05-27  
**Files analyzed:** 9 likely phase outputs  
**Analogs found:** 9 / 9

## File Classification (Extracted from `38-CONTEXT.md` + `38-RESEARCH.md`)

| New/Modified File | Action | Role | Data Flow | Closest Analog(s) | Match Quality |
|---|---|---|---|---|---|
| `README.md` | Modify | top-level docs entrypoint (spoke) | canonical forensics guide link + support-truth snapshot -> reader onboarding route | `README.md`, `guides/first-operator-session.md`, `guides/support-truth-and-ownership-boundaries.md` | strong |
| `guides/forensics-and-runbook-handoffs.md` | **Create** | canonical phase-38 guide (hub) | runtime truth (`/ops/jobs` -> `/ops/jobs/forensics` -> ownership-labeled legal next path -> `/ops/jobs/audit`) -> deep operator narrative | `guides/first-operator-session.md`, `guides/optional-oban-web-bridge.md`, `lib/oban_powertools/web/forensics_live.ex`, `lib/oban_powertools/forensics/runbook_entry.ex` | strong |
| `guides/first-operator-session.md` | Modify | quickstart operator walkthrough (spoke) | first native mutation (`ops-demo` / `pause_cron_entry nightly_sync`) -> forensic continuity -> audit confirmation | `guides/first-operator-session.md`, `lib/oban_powertools/web/forensics_live.ex` | strong |
| `guides/example-app-walkthrough.md` | Modify | fixture journey explainer (spoke) | fixture provenance -> supported route-level operator flow -> host-owned escalation boundary | `guides/example-app-walkthrough.md`, `examples/phoenix_host/README.md` | strong |
| `guides/support-truth-and-ownership-boundaries.md` | Modify | canonical wording contract | support buckets + ownership triad + evidence boundary labels -> consistent claim language | `guides/support-truth-and-ownership-boundaries.md`, `lib/oban_powertools/web/control_plane_presenter.ex` | strong |
| `examples/phoenix_host/README.md` | Modify | host fixture contract | fixture proof bullets -> operator route journey -> explicit host-owned follow-up caveats | `examples/phoenix_host/README.md`, `guides/example-app-walkthrough.md` | strong |
| `test/oban_powertools/docs_contract_test.exs` | Modify | docs-claim enforcement lane | docs files -> marker assertions (global + file-scoped DOC-05 claims) -> merge-blocking closure signal | `test/oban_powertools/docs_contract_test.exs`, `.planning/phases/31-docs-example-host-verification-support-truth-closure/31-PATTERNS.md` | strong |
| `.planning/phases/38-docs-example-host-forensics-journey-closure/38-VERIFICATION.md` | **Create** | phase closure artifact | docs + docs-contract outputs -> claim-to-evidence table -> command results + residual risk statement | `.planning/phases/37-verification-backfill-forensic-ops-baseline/37-VERIFICATION.md`, `.planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-VERIFICATION.md` | strong |
| `.planning/REQUIREMENTS.md` | Modify (scoped) | milestone traceability ledger | `38-VERIFICATION.md` evidence -> `DOC-05` status reconciliation; keep `VER-04` pending | `.planning/REQUIREMENTS.md`, `.planning/phases/37-verification-backfill-forensic-ops-baseline/37-VERIFICATION.md` | strong |

## Runtime Truth Anchors To Mirror In Docs (No Runtime Changes Planned)

These are the implementation sources that docs must align to verbatim semantics:

```elixir
# lib/oban_powertools/web/router.ex
live("/", ObanPowertools.Web.EngineOverviewLive, :index)
live("/audit", ObanPowertools.Web.AuditLive, :index)
live("/forensics", ObanPowertools.Web.ForensicsLive, :index)
```

```elixir
# lib/oban_powertools/forensics.ex
def selectors(params) do
  %{
    resource_type: blank_to_nil(params[:resource_type] || params["resource_type"]),
    resource_id: blank_to_nil(params[:resource_id] || params["resource_id"]),
    workflow_id: blank_to_nil(params[:workflow_id] || params["workflow_id"]),
    step: blank_to_nil(params[:step] || params["step"]),
    incident_fingerprint: blank_to_nil(params[:incident_fingerprint] || params["incident_fingerprint"]),
    view: blank_to_nil(params[:view] || params["view"])
  }
end
```

```elixir
# lib/oban_powertools/web/control_plane_presenter.ex
def ownership_posture(:powertools_native), do: "Audited action"
def ownership_posture(:oban_web_bridge), do: "Inspection only"
def runbook_ownership_label(:host_owned), do: "host-owned follow-up"
def forensic_completeness_label(:partial_evidence), do: "partial evidence"
def forensic_completeness_label(:history_unavailable), do: "history unavailable"
def forensic_completeness_label(:unknown), do: "unknown"
```

```elixir
# lib/oban_powertools/forensics.ex
defp host_follow_up_status(nil), do: "host_owned_follow_up_unconfigured"
defp host_follow_up_status(event), do: event.metadata["status"] || "host_owned_follow_up_unconfigured"
```

Planning implication: Phase 38 docs can describe only these owned states and labels; do not claim provider delivery completion.

## Pattern Assignments

### 1) Canonical Guide + Spoke Architecture (Hub-and-Spoke)

**Pattern:** keep one deep canonical guide and lightweight pointers from high-traffic docs.

**Analog excerpt (README spoke style):**
```md
## Guides
- [First Operator Session](guides/first-operator-session.md) ...
- [Example App Walkthrough](guides/example-app-walkthrough.md) ...
- [Support Truth And Ownership Boundaries](guides/support-truth-and-ownership-boundaries.md) ...
```

**Analog excerpt (stepwise operator journey style):**
```md
# guides/first-operator-session.md
Use one native Powertools page to perform an audited mutation.
The canonical proof is `pause_cron_entry` on `nightly_sync` as operator `ops-demo`.
```

**Phase-38 fit:** `guides/forensics-and-runbook-handoffs.md` becomes the deep narrative hub; `README.md`, `first-operator-session`, `example-app-walkthrough`, `support-truth-and-ownership-boundaries`, and `examples/phoenix_host/README.md` become concise spokes.

### 2) Evidence-Boundary + Ownership Wording Locks

**Pattern:** decision-point language must stay triad-based and evidence-grounded.

**Analog excerpt (runbook caution labels):**
```elixir
# lib/oban_powertools/forensics/runbook_entry.ex
%{label: "partial evidence", detail: details, severity: :warning}
%{label: "history unavailable", detail: details, severity: :warning}
%{label: "unknown", detail: details, severity: :warning}
...
%{label: "host-owned follow-up", detail: "host-owned follow-up paths point outside Powertools ownership ..."}
```

**Analog excerpt (support-bucket documentation shape):**
```md
# guides/support-truth-and-ownership-boundaries.md
## supported
- `Powertools-native` pages are the diagnosis-first and `Audited action` surface
- the `Oban Web bridge` remains `Inspection only`
```

**Phase-38 fit:** carry exact labels (`Powertools-native`, `Oban Web bridge`, `host-owned follow-up`, `partial evidence`, `history unavailable`, `unknown`) into canonical and spoke docs at the exact handoff moments.

### 3) Docs-Contract Closure Pattern (Marker-Based, Not Snapshot-Based)

**Pattern:** keep assertions marker-oriented; add file-scoped DOC-05 claims for high-risk wording.

**Analog excerpt (current marker lane):**
```elixir
# test/oban_powertools/docs_contract_test.exs
source = joined_docs()
assert source =~ "/ops/jobs"
assert source =~ "/ops/jobs/oban"
assert source =~ "Powertools-native"
assert source =~ "Oban Web bridge"
assert source =~ "Inspection only"
assert source =~ "Audited action"
```

**Analog excerpt (already file-scoped precedent):**
```elixir
source = File.read!("guides/workflows.md")
assert source =~ @workflow_semantics_block
```

**Phase-38 fit:** keep `joined_docs/0` for broad vocabulary checks, then add file-specific assertions for DOC-05 claims (for example claim IDs `DOC05-C1...`) to prevent false positives from unrelated files.

### 4) Verification Artifact + Requirements Reconciliation

**Pattern:** closure report first, requirements status second; keep change scope narrow.

**Analog excerpt (verification skeleton):**
```md
---
phase: 37-verification-backfill-forensic-ops-baseline
verified: 2026-05-27T09:47:00Z
status: passed
score: 9/9 verification checks passed
---

## Goal Achievement
## Automated Proof
```

**Analog excerpt (requirements trace rows):**
```md
| DOC-05 | Phase 38 | Pending |
| VER-04 | Phase 39 | Pending |
```

**Phase-38 fit:** create `38-VERIFICATION.md` with DOC-05 claim-to-evidence mapping and command outputs; only then update `.planning/REQUIREMENTS.md` to mark DOC-05 complete while preserving VER-04 pending.

## Planning-Ready Sequencing (Aligned with 38-01 / 38-02 / 38-03)

1. **38-01 docs hub/spokes first:** create canonical guide, add spoke links/snapshots in README + operator docs.
2. **38-02 fixture docs second:** align `guides/example-app-walkthrough.md` and `examples/phoenix_host/README.md` to the same route-level journey and host-owned escalation caveats.
3. **38-03 proof last:** extend `docs_contract_test.exs` with DOC-05 file-scoped claims, then publish `38-VERIFICATION.md`, then reconcile `DOC-05` in `.planning/REQUIREMENTS.md`.

## Anti-Drift Guardrails For Implementers

- Keep phase boundary docs-only: no runtime code changes in forensics/runbook modules.
- Never claim external provider delivery truth; only claim host follow-up statuses the code exposes.
- Prefer concise spoke copy linking to canonical guide over duplicate long prose in multiple docs.
- Keep docs-contract assertions narrow and grep-friendly; avoid paragraph snapshots.
- Preserve explicit separation: DOC-05 closure in Phase 38, VER-04 closure in Phase 39.
