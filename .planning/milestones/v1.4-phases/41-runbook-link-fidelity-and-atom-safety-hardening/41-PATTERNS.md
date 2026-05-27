# Phase 41: Runbook Link Fidelity and Atom Safety Hardening - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 13 (5 new, 8 modified)
**Analogs found:** 13 / 13

This pattern map is the planner's cookbook for Phase 41. Every new file has a concrete in-repo analog. Every modification site is shown with surrounding context the executor will read. Excerpts are copied verbatim from the current tree.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| **NEW** `lib/oban_powertools/web/selectors.ex` | helper module (presenter sibling) | URL-building | `lib/oban_powertools/forensics/runbook_entry.ex:371-378` (`selector_path/1`) | exact (shape to generalize) |
| **NEW** `lib/oban_powertools/lifeline/target_type.ex` | helper module (closed-enum dispatcher) | atom-conversion | `lib/oban_powertools/forensics/provenance.ex` + `lib/oban_powertools/control_plane.ex:25-28` | exact (function-clause closed-enum) |
| **NEW** `test/oban_powertools/web/selectors_test.exs` | unit test (pure helper) | request-response | `test/oban_powertools/control_plane_test.exs` | exact (`use ExUnit.Case, async: true`) |
| **NEW** `test/oban_powertools/lifeline/target_type_test.exs` | unit test (pure helper) | atom-conversion | `test/oban_powertools/control_plane_test.exs` | exact |
| **NEW** `test/oban_powertools/forensics/evidence_bundle_test.exs` | unit test (pure helper, new dir) | atom-conversion | `test/oban_powertools/control_plane_test.exs` | exact |
| **MOD** `lib/oban_powertools/web/control_plane_presenter.ex` | presenter | atom-conversion (status string + map key fallback) | self (same file, neighboring private helpers) | self |
| **MOD** `lib/oban_powertools/forensics/evidence_bundle.ex` | bundle assembler | atom-conversion (related_evidence keys) | self + `forensics/provenance.ex` normalize pattern | self |
| **MOD** `lib/oban_powertools/lifeline.ex` | domain module | atom-conversion (audit subject target_type) | self + new `TargetType` helper | self |
| **MOD** `lib/oban_powertools/web/lifeline_live.ex` | LiveView | atom-conversion (workflow handoff) + obfuscated-atom cleanup | self + new `TargetType` helper | self |
| **MOD** `lib/oban_powertools/web/overview_read_model.ex` | read-model | URL-building (8 selector sites) | self + new `Selectors` helper | self |
| **MOD** `lib/oban_powertools/forensics/runbook_entry.ex` | forensic helper | URL-building (1 selector site) | self + new `Selectors` helper | self |
| **MOD** `lib/oban_powertools/forensics.ex` | forensics domain | URL-building (3 selector sites incl. raw interpolation) | self + new `Selectors` helper | self |
| **MOD** `lib/oban_powertools/web/workflows_live.ex` | LiveView | URL-building (1 selector site) | self + new `Selectors` helper | self |
| **MOD** `test/oban_powertools/web/live/engine_overview_live_test.exs` | LiveView integration test | round-trip test | self (lines 37-67 baseline) | self |
| **MOD** `test/oban_powertools/web/live/forensics_live_test.exs` | LiveView integration test | round-trip test | self (lines 60-167 baseline) | self |
| **MOD** `test/oban_powertools/web/live/lifeline_live_test.exs` | LiveView integration test | round-trip test | self (lines 540-581 baseline) | self |

---

## Pattern Assignments — New Helper Modules

### `lib/oban_powertools/web/selectors.ex` (helper module, URL-building)

**Analog:** `lib/oban_powertools/forensics/runbook_entry.ex` — `selector_path/1` is the canonical safe encoder the planner generalizes.

**Sibling reference (placement + alias style):** `lib/oban_powertools/web/overview_read_model.ex` is the canonical sibling module (same directory, same `ObanPowertools.Web.*` namespace).

**Sibling header style** (from `lib/oban_powertools/web/overview_read_model.ex:1-12`):
```elixir
defmodule ObanPowertools.Web.OverviewReadModel do
  @moduledoc false

  import Ecto.Query

  alias ObanPowertools.{Audit, ControlPlane, Explain}
  alias ObanPowertools.Cron.Entry
  alias ObanPowertools.Forensics.{AttentionProjection, CronHistory, LimiterHistory}
  alias ObanPowertools.Lifeline
  alias ObanPowertools.Lifeline.Incident
  alias ObanPowertools.Limits.{Resource, State}
  alias ObanPowertools.Web.ControlPlanePresenter
```

Note: sibling presenter uses `@moduledoc false` for thin private-API modules. For Selectors, prefer a real moduledoc per CONTEXT.md "explicit known-set documentation in moduledocs" (Specifics block).

**Canonical encoder shape to generalize** (from `lib/oban_powertools/forensics/runbook_entry.ex:371-378`):
```elixir
defp selector_path(params) do
  params =
    params
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> URI.encode_query()

  "/ops/jobs/forensics?#{params}"
end
```

This is the exact pipeline Selectors must implement, generalized to accept a destination key. Note: the current callsite hard-codes `/ops/jobs/forensics?`; Selectors makes the path parameterized.

**Behavior contract to preserve** (verified against existing test at `test/oban_powertools/web/live/engine_overview_live_test.exs:53-66`):
- Drop `nil` and `""` values before encoding (D-18).
- Preserve keyword-list iteration order (existing tests assert literal URLs like `view=active&incident_fingerprint=...`).
- Apply `URI.encode_query/1` — handles delimiter-heavy values (`:` `/` `?` `#` `%` ` ` `&` `=`) safely.
- When the encoded query is empty, return the bare path without trailing `?`.

**Existing safe callsite shape to match for keyword-list ordering** (from `lib/oban_powertools/web/overview_read_model.ex:427-433`):
```elixir
defp lifeline_incident_path(view, incident) do
  "/ops/jobs/lifeline?" <>
    URI.encode_query([
      {"view", view},
      {"incident_fingerprint", incident.incident_fingerprint}
    ])
end
```

Keyword-list (not map) is mandatory here — `engine_overview_live_test.exs:55` asserts the literal `view=active&incident_fingerprint=...` order.

---

### `lib/oban_powertools/lifeline/target_type.ex` (helper module, atom-conversion)

**Analog A (closed-enum dispatch shape):** `lib/oban_powertools/forensics/provenance.ex` — a small bare helper module in `lib/oban_powertools/forensics/` parallel to `lib/oban_powertools/lifeline/`. **This is the closest structural sibling** because Lifeline's only existing sibling modules (`incident.ex`, `repair_preview.ex`, `archive_run.ex`, `heartbeat.ex`, `heartbeat_writer.ex`) are all Ecto schemas, not pure-function helpers.

**Provenance.ex shape** (full file at `lib/oban_powertools/forensics/provenance.ex:1-27`):
```elixir
defmodule ObanPowertools.Forensics.Provenance do
  @durable_values [:durable, :supporting, :bridge_only, :missing]
  @completeness_values [:complete, :partial_evidence, :history_unavailable, :unknown]

  def provenance_values, do: @durable_values
  def completeness_values, do: @completeness_values

  def normalize_provenance(value) when value in @durable_values, do: value
  def normalize_provenance("durable"), do: :durable
  def normalize_provenance("supporting"), do: :supporting
  def normalize_provenance("bridge_only"), do: :bridge_only
  def normalize_provenance("missing"), do: :missing
  def normalize_provenance(_value), do: :missing

  def normalize_completeness(value) when value in @completeness_values, do: value
  def normalize_completeness("complete"), do: :complete
  def normalize_completeness("partial_evidence"), do: :partial_evidence
  def normalize_completeness("history_unavailable"), do: :history_unavailable
  def normalize_completeness("unknown"), do: :unknown
  def normalize_completeness(_value), do: :unknown

  def strength_rank(:durable), do: 0
  def strength_rank(:supporting), do: 1
  def strength_rank(:bridge_only), do: 2
  def strength_rank(:missing), do: 3
  def strength_rank(other), do: other |> normalize_provenance() |> strength_rank()
end
```

**Key conventions to copy:**
- Bare `defmodule` with module attributes at the top documenting the closed enum.
- One-line function clauses, ordered "known string → atom literal".
- No `@moduledoc false` — sibling has no moduledoc at all. **For Phase 41, override this:** CONTEXT.md Specifics block calls for "explicit known-set documentation in moduledocs". Add a moduledoc following Phase 41 D-12 wording.
- No `import`, no `alias`, no `use` — minimal surface.

**Analog B (no-catch-all closed-enum policy):** `lib/oban_powertools/control_plane.ex:25-28`:
```elixir
def limiter_status(%{cooling_down?: true}), do: :waiting
def limiter_status(%{saturation_label: "Blocked"}), do: :blocked
def limiter_status(%{blocked?: true}), do: :blocked
def limiter_status(_resource), do: :runnable
```

Difference for TargetType per D-12: TargetType **must omit the catch-all clause** so unknown values raise `FunctionClauseError` (D-12). Pattern is "closed enum, no fallback" rather than ControlPlane's "explicit fallback".

**D-07 enum:** `"job"` / `"workflow"` / `"workflow_step"` / `"step"`. Producer audit confirms only the first three are emitted today (see RESEARCH.md A-1, Open Question #1); planner should include all four per D-07 verbatim.

---

## Pattern Assignments — New Test Files

### `test/oban_powertools/web/selectors_test.exs` (unit test, pure helper)

**Analog:** `test/oban_powertools/control_plane_test.exs` (full file at lines 1-53)

**Header + assertion style:**
```elixir
defmodule ObanPowertools.ControlPlaneTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.ControlPlane

  test "freezes the exact shared status and ownership taxonomy" do
    assert ControlPlane.statuses() == [
             :needs_review,
             :blocked,
             :waiting,
             :runnable,
             :resolved,
             :bridge_only
           ]
    # ...
  end
end
```

**Conventions to copy:**
- `use ExUnit.Case, async: true` — Selectors helper has no DB dependency, async-safe.
- Single `alias` to the module under test.
- Plain `assert <expression> == <expected>` — no setup, no fixtures.
- One test per behavioral group (e.g., "drops nil and empty values", "preserves delimiter-heavy fingerprint via round-trip decode", "returns bare path when no params survive filtering").

**Behavior coverage targets (from CONTEXT.md D-19 + RESEARCH.md Pattern 1):**
- Delimiter-heavy values: `:` `/` `?` `#` `%` ` ` (whitespace) `&` `=` survive `URI.encode_query/1` and decode back via `URI.decode_query/1`.
- nil / "" values dropped before encoding.
- Empty query → bare path (no trailing `?`).
- Keyword-list order preserved (e.g., `[{"view", "active"}, {"incident_fingerprint", "..."}]` encodes as `view=...&incident_fingerprint=...`).
- Each named destination delegator (`lifeline_path/1`, `forensic_path/1`, `audit_path/1`, `limiter_path/1`, `cron_path/1`) emits the right base path.

---

### `test/oban_powertools/lifeline/target_type_test.exs` (unit test, new subdirectory)

**Analog:** `test/oban_powertools/control_plane_test.exs` (same as above)

**Directory note:** `test/oban_powertools/lifeline/` does **not exist** today (verified via `ls`). Planner must create the directory along with the file. ExUnit auto-discovery picks it up via the existing `test/test_helper.exs` glob.

**Header style** (copy from `control_plane_test.exs`):
```elixir
defmodule ObanPowertools.Lifeline.TargetTypeTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Lifeline.TargetType

  test "maps each producer-bounded target_type string to the expected atom" do
    assert TargetType.to_atom("job") == :job
    assert TargetType.to_atom("workflow") == :workflow
    assert TargetType.to_atom("workflow_step") == :workflow_step
    assert TargetType.to_atom("step") == :step
  end

  test "raises FunctionClauseError for unknown target_type strings" do
    assert_raise FunctionClauseError, fn ->
      TargetType.to_atom("unknown")
    end
  end
end
```

This shape matches CONTEXT.md D-22 verbatim. `assert_raise FunctionClauseError, fn -> ... end` is the canonical ExUnit pattern.

---

### `test/oban_powertools/forensics/evidence_bundle_test.exs` (unit test, new subdirectory)

**Analog:** `test/oban_powertools/control_plane_test.exs` for shape; behavior contract from RESEARCH.md Pattern 3 + CONTEXT.md D-21.

**Directory note:** `test/oban_powertools/forensics/` does **not exist** today (verified via `ls`). Planner must create the directory.

**Behavior coverage targets (D-21):**
- Known binary keys (`"title"`, `"summary"`, `"provenance"`, `"type"`, `"resource_id"`, `"resource_type"`) → atom keys.
- Unknown binary keys (e.g., `"future_unspecified_field"`) → preserved as binary keys (D-28 partial-evidence visibility).
- No new atoms created for unknown inputs. Asserted via either:
  - `:erlang.system_info(:atom_count)` delta check (snapshot before + after, equal), OR
  - `assert_raise ArgumentError, fn -> String.to_existing_atom("future_unspecified_field_#{:rand.uniform(10_000)}") end` after the normalization call, proving the binary stayed binary.

**Imports to model on** `test/oban_powertools/forensics_test.exs:1-13`:
```elixir
defmodule ObanPowertools.ForensicsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Forensics.{
    AttentionProjection,
    Chronology,
    EvidenceBundle,
    LimiterHistoryFact,
    Provenance,
    RunbookEntry
  }
```

The new test does not need `DataCase` (pure unit on `EvidenceBundle.build/1` with hand-built maps), so `use ExUnit.Case, async: true` is sufficient. Alias just `EvidenceBundle`.

---

## Pattern Assignments — Modification Sites

### `lib/oban_powertools/web/control_plane_presenter.ex` — atom sites at lines 18, 223

**Surrounding context for site 1** (`lib/oban_powertools/web/control_plane_presenter.ex:1-22`):
```elixir
defmodule ObanPowertools.Web.ControlPlanePresenter do
  @moduledoc """
  Shared control-plane labels, ownership copy, and venue-aware wording.
  """

  alias ObanPowertools.{Audit, ControlPlane}

  @status_labels %{
    needs_review: "Needs Review",
    blocked: "Blocked",
    waiting: "Waiting",
    runnable: "Runnable",
    resolved: "Resolved",
    bridge_only: "Bridge-only Follow-up"
  }

  def status_label(status) when is_binary(status),
    do: status |> String.to_atom() |> status_label()                     # ← SITE 1 (line 18)

  def status_label(status), do: Map.get(@status_labels, status, Phoenix.Naming.humanize(status))
```

**Strategy (D-09):** rewrite the binary-clause to use `String.to_existing_atom/1` + `rescue ArgumentError -> Phoenix.Naming.humanize(status)`. The fallback returns a human-friendly string identical to what the second `status_label/1` clause would produce for an unknown atom — behavior-preserving (D-27).

**Surrounding context for site 2** (`lib/oban_powertools/web/control_plane_presenter.ex:215-225`):
```elixir
  defp refusal_reason_label(nil), do: "This action is not available right now."
  defp refusal_reason_label(code), do: Phoenix.Naming.humanize(code)

  defp follow_up_value(map, key) do
    Map.get(map, key) || Map.get(map, String.to_atom(key))               # ← SITE 2 (line 223)
  end
end
```

**Strategy (D-10):** introduce a `defp safe_atom/1` helper colocated at the bottom of the file. Returns `nil` on unknown binary, so `Map.get(map, nil)` returns nil and the `||` chain stays semantically identical.

---

### `lib/oban_powertools/forensics/evidence_bundle.ex` — atom site at line 35

**Surrounding context** (`lib/oban_powertools/forensics/evidence_bundle.ex:1-38`):
```elixir
defmodule ObanPowertools.Forensics.EvidenceBundle do
  alias ObanPowertools.Forensics.{Chronology, Provenance}

  def build(attrs) when is_map(attrs) do
    chronology =
      attrs
      |> Map.get(:chronology, Map.get(attrs, "chronology", []))
      |> Enum.map(&Chronology.item/1)
      |> Chronology.sort()

    %{
      subject: Map.get(attrs, :subject) || Map.get(attrs, "subject") || %{},
      # ...
      related_evidence:
        attrs
        |> Map.get(:related_evidence, Map.get(attrs, "related_evidence", []))
        |> Enum.map(&normalize_related_evidence/1),
      # ...
    }
  end

  defp normalize_related_evidence(item) do
    Map.new(item, fn
      {:provenance, value} -> {:provenance, Provenance.normalize_provenance(value)}
      {"provenance", value} -> {:provenance, Provenance.normalize_provenance(value)}
      {key, value} when is_binary(key) -> {String.to_atom(key), value}    # ← SITE 3 (line 35)
      pair -> pair
    end)
  end
```

**Strategy (D-11):** introduce a module attribute `@related_evidence_atom_keys ~w(title summary provenance type resource_id resource_type)a` and a private `normalize_related_evidence_key/1` that uses `String.to_existing_atom/1` with `rescue ArgumentError -> key`. The compile-time list ensures all known atoms are interned at module load.

**Critical downstream constraint (RESEARCH.md Pitfall 4):** `lib/oban_powertools/web/forensics_live.ex:240-245` accesses `item.title`, `item.summary`, `item.provenance` via atom-dot. The allowlist must include those three keys at minimum. The RESEARCH-recommended set adds `:type`, `:resource_id`, `:resource_type` defensively.

---

### `lib/oban_powertools/lifeline.ex` — atom sites at lines 1073, 1206

**Surrounding context for site 4** (`lib/oban_powertools/lifeline.ex:1071-1078`):
```elixir
      Audit.record(
        "lifeline.repair_executed",
        %{type: String.to_atom(preview.target_type), id: preview.target_id},   # ← SITE 4 (line 1073)
        metadata,
        repo: repo,
        actor_id: Auth.actor_id(actor)
      )
```

**Surrounding context for site 5** (`lib/oban_powertools/lifeline.ex:1204-1213`):
```elixir
    case Audit.record(
           "lifeline.host_follow_up",
           %{type: String.to_atom(preview.target_type), id: preview.target_id},   # ← SITE 5 (line 1206)
           metadata,
           repo: repo,
           actor_id: Auth.actor_id(actor)
         ) do
      {:ok, _event} -> :ok
      {:error, _changeset} -> :error
    end
```

**Strategy (D-12):** both sites become `%{type: TargetType.to_atom(preview.target_type), id: preview.target_id}` after adding `alias ObanPowertools.Lifeline.TargetType` at the module header. Audit subject shape (`%{type: atom, id: string}`) preserved — D-27 backward compatibility holds.

**Verification:** `test/oban_powertools/lifeline_test.exs:335, 414, 452` already exercise `Audit.list(%{type: :job, id: ...}, repo: ...)` — these tests will catch any regression in the atom contract.

---

### `lib/oban_powertools/web/lifeline_live.ex` — atom site at line 1368, obfuscated literal at line 1105

**Surrounding context for site 6** (`lib/oban_powertools/web/lifeline_live.ex:1360-1373`):
```elixir
             incident: incident,
             action: action,
             action_label: action_info.label,
             target_type: action_info.target_type,
             target_id: to_string(action_info.target_id),
             target_summary: handoff_summary(workflow, step, action_info),
             previewable?: true,
             resource: %{
               type: String.to_atom(action_info.target_type),                  # ← SITE 6 (line 1368)
               id: to_string(action_info.target_id)
             },
             workflow_id: workflow.id,
             step_name: step && step.step_name
           }}
```

**Strategy (D-12):** rewrite to `type: TargetType.to_atom(action_info.target_type)` after adding `alias ObanPowertools.Lifeline.TargetType` (or qualifying inline if no existing alias block).

**Surrounding context for D-08 cleanup** (`lib/oban_powertools/web/lifeline_live.ex:1097-1108`):
```elixir
    defp preview_status_copy(nil), do: "preview_not_available"

    defp preview_status_copy(%RepairPreview{status: status}),
      do: RepairPreview.canonical_status(status)

    defp repair_preview_value(%RepairPreview{} = preview),
      do: Map.fetch!(preview, repair_preview_key())

    defp repair_preview_key, do: String.to_existing_atom("preview_" <> "token")   # ← D-08 (line 1105)
```

**Strategy (D-08):** replace with `defp repair_preview_key, do: :preview_token`. Pure cleanup. The original obfuscation resolves at compile-time, so the atom already exists at module load — no behavior change. Removes the only `String.to_existing_atom` carve-out in `lib/`.

---

### `lib/oban_powertools/web/overview_read_model.ex` — 8 selector-construction sites

**Existing safe-encoder sites to migrate behind Selectors:**

Site at lines 427-433 (`lifeline_incident_path/2`):
```elixir
defp lifeline_incident_path(view, incident) do
  "/ops/jobs/lifeline?" <>
    URI.encode_query([
      {"view", view},
      {"incident_fingerprint", incident.incident_fingerprint}
    ])
end
```

Site at lines 435-438 (`forensic_incident_path/1`):
```elixir
defp forensic_incident_path(incident) do
  "/ops/jobs/forensics?" <>
    URI.encode_query(%{"incident_fingerprint" => incident.incident_fingerprint})
end
```

**Existing raw-interpolation sites** (the actual delimiter-encoding hazard):

Line 309 — limiter path:
```elixir
path: "/ops/jobs/limiters?resource=#{URI.encode_www_form(resource.name)}",
```

Lines 311, 337 — forensic resource path (raw interpolation of `resource_id` and literal `&resource_type=...`):
```elixir
evidence_path:
  "/ops/jobs/forensics?resource_id=#{URI.encode_www_form(resource.name)}&resource_type=limiter",
```

Lines 335, 394, 403, 406 — cron / limiter resource paths (same raw-interpolation shape).

Lines 417-422 — audit follow-up via `URI.encode_query`:
```elixir
"/ops/jobs/audit?" <>
  URI.encode_query(%{
    "resource_type" => event.resource_type,
    "resource_id" => event.resource_id,
    "event_type" => event.event_type
  })
```

**Strategy (D-17):** all 8 sites move to `Selectors.{lifeline_path, forensic_path, audit_path, limiter_path, cron_path}/1` after adding `alias ObanPowertools.Web.Selectors` at the module header. Keyword-list ordering must be preserved on the lifeline / forensics sites to keep `engine_overview_live_test.exs:53-66` green.

---

### `lib/oban_powertools/forensics/runbook_entry.ex` — `selector_path/1` at line 371

**Decision per CONTEXT.md (Canonical References section + D-17):** the existing `selector_path/1` is the **shape generalized into Selectors**. The planner replaces `defp selector_path/1` at line 371 with calls to `Selectors.forensic_path/1` everywhere the private helper is invoked.

Existing helper (`lib/oban_powertools/forensics/runbook_entry.ex:371-378`):
```elixir
defp selector_path(params) do
  params =
    params
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> URI.encode_query()

  "/ops/jobs/forensics?#{params}"
end
```

**Strategy:** delete this `defp` entirely after migrating its callers. The new Selectors helper owns this logic.

---

### `lib/oban_powertools/forensics.ex` — selector sites at lines 443-494

**Existing safe-encoder sites at lines 443-476:**
```elixir
        params =
          [
            {"workflow_id", workflow.id},
            {"step", selected_step && selected_step.step_name},
            {"action", action.id}
          ]
          |> Enum.reject(fn {_key, value} -> is_nil(value) end)
          |> URI.encode_query()

        [
          %{
            label: action.label,
            venue: "Powertools-native Lifeline",
            path: "/ops/jobs/lifeline?#{params}"
          }
        ]
```

```elixir
defp lifeline_path(incident, view) do
  params =
    [
      {"incident_fingerprint", incident.incident_fingerprint},
      {"view", view || incident_view(incident)}
    ]
    |> URI.encode_query()

  "/ops/jobs/lifeline?#{params}"
end
```

**Raw-interpolation site at lines 481-494** (the only raw-interpolation case in `lib/oban_powertools/forensics.ex`):
```elixir
defp audit_path(%Step{} = step),
  do: "/ops/jobs/audit?resource_type=workflow_step&resource_id=#{step.id}"

defp audit_path(%Workflow{} = workflow),
  do: "/ops/jobs/audit?resource_type=workflow&resource_id=#{workflow.id}"

defp audit_path(%{resource_type: type, resource_id: id})
     when not is_nil(type) and not is_nil(id) do
  "/ops/jobs/audit?resource_type=#{type}&resource_id=#{id}"
end

defp audit_path(%{type: type, id: id}) do
  "/ops/jobs/audit?resource_type=#{type}&resource_id=#{id}"
end
```

**Strategy (D-17):** all four `audit_path/1` clauses become `Selectors.audit_path(%{"resource_type" => ..., "resource_id" => ...})`. Note: `step.id` and `workflow.id` are integer-only — no actual delimiter risk today — but D-17 centralization still applies (the planner should not leave parallel safe paths).

---

### `lib/oban_powertools/web/workflows_live.ex` — selector site at line 439

**Existing site** (`lib/oban_powertools/web/workflows_live.ex:425-441`):
```elixir
        |> Enum.filter(&(&1.target_type == "workflow"))

      action = List.first(step_actions) || List.first(workflow_actions)

      if action do
        params =
          [
            {"workflow_id", workflow.id},
            {"step", selected_step && selected_step.step_name},
            {"action", action.id}
          ]
          |> Enum.reject(fn {_key, value} -> is_nil(value) end)
          |> URI.encode_query()

        %{label: "Review in Lifeline: #{action.label}", path: "/ops/jobs/lifeline?#{params}"}
      end
    end
```

**Strategy (D-17):** replace the body with `Selectors.lifeline_path([{"workflow_id", workflow.id}, {"step", selected_step && selected_step.step_name}, {"action", action.id}])` — Selectors handles the nil-filtering and the encode internally.

---

## Pattern Assignments — Test Extensions

### `test/oban_powertools/web/live/engine_overview_live_test.exs`

**Existing baseline at lines 37-67** (the test to extend):
```elixir
test "encodes incident fingerprints in overview Lifeline and Forensics links", %{conn: conn} do
  seed_overview_fixture!(
    active_fingerprint: "dead_executor:executor&with=delimiters",
    resolved_fingerprint: "dead_executor:resolved&with=delimiters"
  )

  conn =
    Plug.Test.init_test_session(conn,
      current_actor: %{id: "ops-1", permissions: [:view_overview]}
    )

  {:ok, view, html} = live(conn, "/ops/jobs")

  active_fingerprint = URI.encode_www_form("dead_executor:executor&with=delimiters")
  resolved_fingerprint = URI.encode_www_form("dead_executor:resolved&with=delimiters")

  assert has_element?(
           view,
           "a[href='/ops/jobs/lifeline?view=active&incident_fingerprint=#{active_fingerprint}']"
         )

  assert has_element?(
           view,
           "a[href='/ops/jobs/lifeline?view=resolved&incident_fingerprint=#{resolved_fingerprint}']"
         )

  assert html =~ "/ops/jobs/forensics?incident_fingerprint=#{active_fingerprint}"
  assert html =~ "/ops/jobs/forensics?incident_fingerprint=#{resolved_fingerprint}"
  refute html =~ "incident_fingerprint=dead_executor:executor&with=delimiters"
  refute html =~ "incident_fingerprint=dead_executor:resolved&with=delimiters"
end
```

**Gap to close (D-19/D-20):** existing fixture only covers `&` and `=`. Extend with fixtures that include `:` `/` `?` `#` `%` ` ` (whitespace), then assert encoded form appears and raw form does not.

**Pattern for extension:** add a new test (or parameterize the existing one) seeding fingerprints like `"dead_executor:exec/path?frag#tag with%20space&query=value"` and asserting `URI.encode_www_form(fingerprint)` appears in the rendered HTML while raw delimiters do not.

---

### `test/oban_powertools/web/live/forensics_live_test.exs`

**Existing round-trip baseline at lines 60-167** — mounts `/ops/jobs/forensics?incident_fingerprint=...&view=active&resource_type=job&resource_id=123` and verifies bundle resolves to the right incident:
```elixir
path =
  "/ops/jobs/forensics?incident_fingerprint=#{URI.encode_www_form(incident.incident_fingerprint)}&view=active&resource_type=job&resource_id=123"

{:ok, _view, html} = live(conn, path)

assert html =~ "Powertools-native Lifeline"
# ... assertions about bundle content ...

{:ok, _remounted_view, remounted_html} = live(conn, path)

assert remounted_html =~ incident.incident_fingerprint
```

**Pattern for extension (D-19):** new test that seeds an incident with a delimiter-heavy fingerprint (`"workflow_stuck:wf-1/step-2?attempt=3 #frag%20"`), mounts the forensics URL with that encoded fingerprint, and asserts the bundle's `subject` field round-trips back to the exact original fingerprint.

**Allowlist assertion already exists** at module attribute `@allowed_selector_keys` (lines 12-19) — keep using `assert_forensics_selector_allowlist(html)` to enforce Phase 34 D-25.

---

### `test/oban_powertools/web/live/lifeline_live_test.exs`

**Existing baseline at lines 540-581** — `assert_patch` round-trip on `selection_path/1`:
```elixir
{:ok, view, _html} = live(conn, "/ops/jobs/lifeline")

view
|> element("button[phx-value-row-id$=':job:#{active_job.id}'][phx-click='select_incident']")
|> render_click()

assert_patch(
  view,
  "/ops/jobs/lifeline?view=active&incident_fingerprint=#{URI.encode_www_form(active_incident.incident_fingerprint)}&row-id=#{URI.encode_www_form("#{active_incident.id}:job:#{active_job.id}")}"
)
```

**Pattern for extension (D-19/D-20):** seed an incident with a delimiter-heavy fingerprint via `insert_dead_executor_incident!/1` (existing helper at lines 661-677, currently produces `"dead_executor:#{executor_id}"`). Either extend the helper to accept an override fingerprint or add a sibling helper. Then assert that selecting that incident produces a `assert_patch` URL with `URI.encode_www_form(fingerprint)` and that re-mounting the patched URL resolves back to the same row.

---

## Shared Patterns

### Bounded atom-conversion idiom
**Source:** `String.to_existing_atom/1` + `rescue ArgumentError`. RESEARCH.md Standard Stack section confirms this is the canonical Elixir idiom; no in-repo prior example because this is what Phase 41 introduces.

**Apply to:** sites 1, 2 (`control_plane_presenter.ex`), site 3 (`evidence_bundle.ex` via private helper).

**Canonical form:**
```elixir
defp safe_atom(binary) when is_binary(binary) do
  String.to_existing_atom(binary)
rescue
  ArgumentError -> <fallback>  # site-dependent: original binary, nil, or humanize
end
```

Fallback varies by caller:
- `control_plane_presenter:18` (status) → `Phoenix.Naming.humanize(status)` per D-09.
- `control_plane_presenter:223` (map key) → `nil` per D-10.
- `evidence_bundle:35` (related_evidence) → the original binary per D-11 + D-28.

### Closed-enum function-clause dispatch
**Source:** `lib/oban_powertools/control_plane.ex:25-28` (with fallback) and `lib/oban_powertools/forensics/provenance.ex:8-13` (small module shape).

**Apply to:** new `TargetType.to_atom/1` (without fallback, per D-12).

### URL selector encoding
**Source:** `lib/oban_powertools/forensics/runbook_entry.ex:371-378` (`selector_path/1`).

**Apply to:** new `Selectors.encode/2` + named destination delegators.

**Three-step pipeline:**
1. `Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)` — D-18.
2. `URI.encode_query/1` — delimiter-safe; preserves keyword-list order.
3. Concatenate with canonical path; emit bare path when query is empty.

### LiveView integration test header
**Source:** `test/oban_powertools/web/live/forensics_live_test.exs:1-19`

```elixir
defmodule ObanPowertools.Web.<X>LiveTest do
  use ObanPowertools.LiveCase, async: false

  # aliases ...

  @allowed_selector_keys MapSet.new([
    "resource_type",
    "resource_id",
    "workflow_id",
    "step",
    "incident_fingerprint",
    "view"
  ])
```

**Apply to:** the three test files being extended (already have this shape).

### Unit test header (pure helpers)
**Source:** `test/oban_powertools/control_plane_test.exs:1-4`

```elixir
defmodule ObanPowertools.<X>Test do
  use ExUnit.Case, async: true

  alias ObanPowertools.<X>
```

**Apply to:** all three new test files (`selectors_test.exs`, `target_type_test.exs`, `evidence_bundle_test.exs`).

### Atom-table growth verification
**Source:** No in-repo prior example (this is the WR-02 hardening contract). Canonical Elixir pattern:

```elixir
test "does not grow the atom table for unknown keys" do
  unknown_key = "phase_41_atom_safety_canary_#{System.unique_integer([:positive])}"

  _result = EvidenceBundle.build(%{related_evidence: [%{unknown_key => "value"}]})

  assert_raise ArgumentError, fn -> String.to_existing_atom(unknown_key) end
end
```

`System.unique_integer/1` guarantees the canary string is unique per test run, so any pre-existing atom from a prior run can't mask a bug.

---

## No Analog Found

None — every file has at least one strong analog in the codebase. The only "new shape" is the `String.to_existing_atom/1` + rescue idiom, which is a canonical Elixir-stdlib pattern (RESEARCH.md cites ecosystem references; no in-repo prior usage but the pattern is well-established).

---

## Cross-References for Planner

| Concern | Authority |
|---------|-----------|
| Exact 6 atom-conversion sites | CONTEXT.md D-06 |
| D-08 obfuscated-atom cleanup site | CONTEXT.md D-08 |
| TargetType enum members | CONTEXT.md D-07 (`"job"` / `"workflow"` / `"workflow_step"` / `"step"`); RESEARCH.md Open Question #1 notes only first three are producer-emitted today |
| related_evidence allowlist | RESEARCH.md Open Question #2 + Pitfall 4 (recommended: `[:title, :summary, :provenance, :type, :resource_id, :resource_type]`) |
| D-17 selector-migration scope | CONTEXT.md D-17 (locked: rewrite existing safe callsites); RESEARCH.md Open Question #3 (recommended: 14 sites — 6 cited + 8 raw-interpolation) |
| D-23 rg-check pattern correctness | RESEARCH.md Open Question #4 + Assumption A5 (the WR-01 rg pattern as written is broken; planner must reword) |
| Delimiter set for fingerprint fixtures | CONTEXT.md D-19 (`:` `/` `?` `#` `%` ` ` `&` `=`) |
| Audit subject shape backward compatibility | CONTEXT.md D-27; verified by RESEARCH.md Pitfall 3 + `lifeline_test.exs:335, 414, 452` |
| Module attribute atom-internment guarantee | RESEARCH.md Pitfall 2 (atoms in `@module_attributes` are allocated at module load) |

---

## Metadata

**Analog search scope:**
- `lib/oban_powertools/web/` — sibling helper modules and presenter
- `lib/oban_powertools/lifeline/` — sibling helper modules
- `lib/oban_powertools/forensics/` — closest pure-function helper sibling (Provenance)
- `lib/oban_powertools/control_plane.ex` — closed-enum dispatch reference
- `test/oban_powertools/` — unit test header style
- `test/oban_powertools/web/live/` — LiveView integration test analogs

**Files inspected for excerpts:**
- `lib/oban_powertools/web/control_plane_presenter.ex`
- `lib/oban_powertools/web/overview_read_model.ex`
- `lib/oban_powertools/web/lifeline_live.ex`
- `lib/oban_powertools/web/workflows_live.ex`
- `lib/oban_powertools/lifeline.ex`
- `lib/oban_powertools/lifeline/incident.ex`
- `lib/oban_powertools/lifeline/repair_preview.ex`
- `lib/oban_powertools/forensics.ex`
- `lib/oban_powertools/forensics/evidence_bundle.ex`
- `lib/oban_powertools/forensics/runbook_entry.ex`
- `lib/oban_powertools/forensics/provenance.ex`
- `lib/oban_powertools/control_plane.ex`
- `test/oban_powertools/control_plane_test.exs`
- `test/oban_powertools/forensics_test.exs`
- `test/oban_powertools/web/live/engine_overview_live_test.exs`
- `test/oban_powertools/web/live/forensics_live_test.exs`
- `test/oban_powertools/web/live/lifeline_live_test.exs`

**Pattern extraction date:** 2026-05-27

## PATTERN MAPPING COMPLETE
