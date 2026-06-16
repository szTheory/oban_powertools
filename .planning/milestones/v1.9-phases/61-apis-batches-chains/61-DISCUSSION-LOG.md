# Phase 61: APIs (Batches & Chains) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 61-APIs (Batches & Chains)
**Areas discussed:** `Batch.insert_stream/2` public contract, linear chain authoring contract, upstream output handoff

---

## `Batch.insert_stream/2` Public Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed-size stream with required `total_count`, per-chunk commits, summary return | Bounded memory, avoids giant transactions, honest partial failure, fits BAT-02 and fixed-size batch posture. | ✓ |
| All-or-nothing `Batch.insert_all/2` wrapper | Simpler rollback semantics but conflicts with massive batch safety and lock-starvation goal. | |
| Builder DSL `Batch.new() |> Batch.add() |> Batch.insert()` | Familiar for heterogeneous jobs, but larger surface and risks implying growable batches. | |
| Loader-job/growable batch pattern | Proven in Sidekiq for very large batches, but violates current fixed-size/no-growable decision. | |

**User's choice:** User delegated to subagent-backed research and requested a coherent one-shot recommendation.
**Notes:** Selected fixed-size chunked streaming. Lock `total_count`, return result/error structs, surface partial insert failure durably, reject conflict-skipping and silent append to existing batches.

---

## Linear Chain Authoring Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Pipeable builder | Best day-0 DX and closest to Oban `Worker.new/2 |> Oban.insert()` flow, but needs explicit support-truth representation. | |
| Data-first `%Chain{}` spec | Strong validation/supportability, but more verbose and close to Workflow ergonomics. | |
| Worker-level continuation callbacks | Local to worker code, but blurs observe-only hooks and makes workers less reusable. | |
| Explicit list API | Deterministic and small, but weaker pipe ergonomics. | |
| Hybrid pipeable facade over explicit `%Chain{}` plus list constructor | Balances DX, validation, support truth, and generated-chain ergonomics. | ✓ |

**User's choice:** User delegated to subagent-backed research and requested a coherent one-shot recommendation.
**Notes:** Selected hybrid. Canonical docs path is pipeable; durable support-truth is `%ObanPowertools.Chain{}`. Chains compile to batch grouping plus callback links, with no separate chains table and no branching/fan-in.

---

## Upstream Output Handoff

| Option | Description | Selected |
|--------|-------------|----------|
| Pass upstream payload snapshot in next job args | Ergonomic but leaks payloads, bypasses retention/redaction/display-policy boundaries, and creates stale replay semantics. | |
| Pass durable record reference in next job meta/args | Keeps payload out of args and aligns with `JobRecord`. | ✓ |
| Expose `Chain.fetch_upstream_result/1` | Best DX/support-truth API over the meta plumbing. | ✓ |
| Require `record_output: true` for upstream handoff | Reuses existing recorded-output boundary and makes dependencies explicit. | ✓ |
| Store chain-local context in callback payload | Useful for control metadata only; bad as a second business-payload store. | |

**User's choice:** User delegated to subagent-backed research and requested a coherent one-shot recommendation.
**Notes:** Selected reference-based handoff through `JobRecord` plus explicit fetch API. Do not copy full payloads into args or callback payloads by default. Validate output-dependent upstream workers when possible.

---

## the agent's Discretion

- Use durable MFA/builder references for output-dependent chain args rather than anonymous functions, because chain progression must survive BEAM restarts.
- Treat missing/expired/unrecorded output as a visible, repairable chain/callback failure rather than silently passing `nil`.
- Preserve Phase 62 UI requirements by making `insert_failed`, callback failure, and output-unavailable states queryable.

## Deferred Ideas

- Growable/dynamic batches and loader-job patterns.
- Nested batches, chunks, arbitrary DAGs, branching chains, and fan-in/fan-out.
- Full operator UI design for batch/chain blocked states.
