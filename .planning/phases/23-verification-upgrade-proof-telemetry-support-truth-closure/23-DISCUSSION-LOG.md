# Phase 23: verification-upgrade-proof-telemetry-support-truth-closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 23-verification-upgrade-proof-telemetry-support-truth-closure
**Areas discussed:** Proof topology, supported upgrade proof posture, workflow telemetry contract, docs-contract enforcement

---

## Proof Topology

| Option | Description | Selected |
|--------|-------------|----------|
| One dense runtime proof lane | Keep one omnibus `workflow_runtime_test.exs` as the primary semantics contract | |
| Focused contract suites by concern | Split DB-first workflow proof into lifecycle, signal, callback/recovery, and related focused suites with shared helpers | ✓ |
| Matrix/harness-first proof topology | Build a larger shared matrix system with scenario grids and focused suites | |
| Three-tier proof pyramid | Add pure reducer/unit specs plus focused DB suites plus acceptance lanes | |

**User's choice:** Shift the recommendation left. Adopt focused contract suites by concern, keep DB-first runtime proof authoritative, keep coordinator resilience separate, and preserve host/upgrade proof as separate acceptance lanes. A tiny pure reducer/vocabulary layer is acceptable only if it stays supplementary.

**Notes:** The user asked for one-shot, deeply researched recommendations with strong DX and least-surprise defaults. Final posture favors maintainability and clarity over a more abstract matrix framework.

---

## Supported Upgrade Proof Posture

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal singular lane | Keep the supported host lane narrow: documented host upgrade plus one waiting-workflow continuity case | |
| Broad singular lane | Pack waiting, cancelling, retrying, and recovering in-flight cases into the supported upgrade lane | |
| Narrow lane + repo-local semantics proofs | Keep host lane narrow and move broader upgrade semantics to library-owned tests | |
| Hybrid layered posture | Keep one singular host lane with one sentinel waiting case, while broader retry/cancel/recovery compatibility stays repo-local | ✓ |

**User's choice:** Shift the recommendation left. Preserve one singular supported lane with one sentinel in-flight waiting continuity case, and keep broader semantics compatibility in repo-local fixtures/tests under `tested`, not `supported`.

**Notes:** The selected posture protects support-truth honesty and avoids accidentally widening the supported host matrix through CI shape alone.

---

## Workflow Telemetry Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Keep the current thin family with only new suffixes | Minimal change, preserve the existing low-cardinality contract almost as-is | |
| Keep one workflow family and add bounded semantics-aware metadata/suffixes | Extend the current public family with small, enum-bounded additions | ✓ |
| Split into multiple public workflow families | Separate workflow semantics into new public telemetry families | |
| Public compact family + private rich evidence | Keep one public family while routing rich detail into durable rows or private instrumentation | ✓ |

**User's choice:** Shift the recommendation left. Keep one public `[:oban_powertools, :workflow, *]` family, add a small number of semantics-aware suffixes and bounded metadata keys, and keep rich evidence out of public metric tags.

**Notes:** The final posture emphasizes low-cardinality operator usefulness, semver stability, and a clear public-vs-private boundary.

---

## Docs-Contract Enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Marker assertions only | Keep broad marker-based docs assertions without exact semantics locking | |
| Exact-locked canonical semantics block | Add a small exact block for workflow semantics in public docs | |
| Schema-driven narrative checks | Generate or derive docs checks from machine-readable contracts | |
| Hybrid posture | Keep narrow markers, add one small exact workflow-semantics block, and avoid broad prose freezing | ✓ |

**User's choice:** Shift the recommendation left. Keep the current narrow marker posture, add one small exact locked workflow-semantics block in `guides/workflows.md`, and avoid broad prose snapshots or generated narrative checks.

**Notes:** The selected posture matches idiomatic Elixir docs testing: freeze examples and bounded public contract, not explanatory narrative.

---

## the agent's Discretion

- Exact names and file split for focused proof suites
- Exact telemetry suffix names and bounded public metadata vocabulary
- Exact wording of the locked canonical workflow semantics block in docs
- Exact library-owned historical compatibility fixture shape for broader in-flight upgrade semantics

## Deferred Ideas

None
