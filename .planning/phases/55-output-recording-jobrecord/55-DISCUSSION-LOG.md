# Phase 55: Output Recording (JobRecord) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-12
**Phase:** 55-Output Recording (JobRecord)
**Areas discussed:** Public return contract, Payload encoding boundary, Retention policy and pruning, Job detail display shape

---

## Public Return Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-record only `{:ok, payload}` | Preserve Oban's standard return contract and persist successful values only when `record_output: true`. | ✓ |
| Add `{:ok, payload, record_opts}` | Add per-return metadata now, but introduce a Powertools-specific return shape. | |
| Add public `record_output/2` | Let workers manually record output from inside `process/1`, with double-recording and ordering risks. | |
| Manual recording only | Avoid return-shape magic, but miss the roadmap's opt-in auto-recording promise. | |

**User's choice:** Asked the agent to research all areas with subagents and synthesize one coherent recommendation set.
**Notes:** The recommendation was to keep Phase 55 conservative: auto-record only `{:ok, payload}` for `record_output: true`; keep `:ok` as no-output; defer three-tuples and explicit manual recording.

---

## Payload Encoding Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| JSONB-compatible payload only | Normalize JSON-compatible values, size-check with Jason, and store in Postgres JSONB. | ✓ |
| Arbitrary Elixir term encoding | Preserve most BEAM terms with opaque binary encoding, at the cost of inspectability and long-term stability. | |
| Hybrid JSONB plus opaque escape hatch | Support both, but introduce two storage semantics and a more confusing public API. | |

**User's choice:** Asked the agent to decide after research.
**Notes:** The recommendation was JSONB-only to match Ecto/Postgres, current `Workflow.Result`, operator inspectability, and zero-new-dependency support truth. Default `output_limit` is locked to `65_536` bytes.

---

## Retention Policy and Pruning

| Option | Description | Selected |
|--------|-------------|----------|
| Policy TTLs with direct prune: 6h / 7d / 30d | Keep output records bounded and operational, not archival. | ✓ |
| Longer TTLs: 24h / 14d / 90d | Better long support windows but higher storage and PII exposure. | |
| Archive before delete | Preserve output as long-term evidence, but expand scope and misclassify output as audit data. | |
| Couple pruning to `oban_jobs` lifecycle | Delete records when matching jobs disappear, but create brittle soft-reference semantics. | |

**User's choice:** Asked the agent to decide after research.
**Notes:** The recommendation was fixed library-owned TTLs: `:ephemeral` 6 hours, `:standard` 7 days, `:extended` 30 days. `Lifeline.run_archive_prune/3` should directly delete expired JobRecords and count them in `pruned_count`.

---

## Job Detail Display Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse `DisplayPolicy.workflow_result/2` directly | Minimal code, but conflates workflow and standalone job output. | |
| Add dedicated `:job_recorded` DisplayPolicy kind | Preserve host-owned display policy while keeping job output distinct. | ✓ |
| Render output as another raw JSON field | Simple but loses result-specific metadata and support-truth states. | |
| UI-only card without DisplayPolicy | Fast, but unsafe for host redaction/custom display posture. | |

**User's choice:** Asked the agent to decide after research, with UI/UX and operator workflow considered where applicable.
**Notes:** The recommendation was a dedicated `:job_recorded` policy kind and a "Recorded Output" card after Args/Meta and before Errors. Missing output copy must not infer whether recording was enabled.

---

## the agent's Discretion

- The user explicitly selected all gray areas and asked for subagent-backed research, tradeoff analysis, ecosystem lessons, and a one-shot cohesive recommendation set.
- The agent resolved a cross-cutting ambiguity in favor of not creating metadata-only rows for rejected oversized/non-encodable payloads in Phase 55. This keeps `fetch_result/1` semantics simple and matches "rejected rather than stored or truncated."

## Deferred Ideas

- `{:ok, payload, record_opts}` return shape.
- Public `record_output/2` callable.
- Arbitrary Elixir term serialization.
- Metadata-only rows for rejected recordings.
- Archive-before-delete for JobRecord.
- UI retention editing.
- Phase 56 at-rest args redaction and output redaction propagation.
