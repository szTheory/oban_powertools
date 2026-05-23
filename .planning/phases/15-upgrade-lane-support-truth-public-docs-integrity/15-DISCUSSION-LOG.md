# Phase 15 Discussion Log

**Date:** 2026-05-23
**Mode:** Discuss all areas with research-backed defaults
**Outcome:** Recommendations accepted as locked defaults for planning

## Discussion Areas

### 1. Supported upgrade source lane

**Options considered**
- Broad “any existing Phase 8/9/10-style host” lane
- Single native-first source lane from the last pre-`display_policy` host shape
- Two supported source lanes: native-first and bridge-enabled
- Synthetic rewrite of the current canonical fixture

**Chosen default**
- Single native-first source lane from the last pre-`display_policy` host shape

**Why**
- It is the narrowest lane the repo can honestly prove.
- It matches the native-first public posture already established in README, guides, and prior contexts.
- It avoids accidentally promoting the optional bridge into a co-equal supported upgrade surface.

### 2. Upgrade proof realism

**Options considered**
- Fixture rewind on the current canonical host
- Generator replay from a historical commit on every CI run
- Archived historical host fixture generated once from an exact old commit, then upgraded in CI

**Chosen default**
- Archived historical upgrade-source fixture, generated once from an exact pre-`display_policy` commit, then upgraded in CI

**Why**
- It turns the upgrade claim into a real deterministic proof instead of a synthetic patch.
- It fits the repo’s existing “canonical fixture + focused proof lanes” architecture.
- It avoids CI flake from full historical generator replay while preserving reviewable provenance.

### 3. Support-truth boundary language

**Options considered**
- Soft OSS ambiguity
- Sharp layered support-truth contract
- Hardline “as-is/no support” posture

**Chosen default**
- Sharp layered support-truth contract

**Why**
- It is honest without being defeatist.
- It matches the host-owned, proof-backed posture already encoded in the repo.
- It lowers maintainer support burden by naming supported, tested, best-effort, host-owned, and intentionally unsupported boundaries explicitly.

### 4. Docs-to-proof enforcement depth

**Options considered**
- Minimal enforcement: structural tests plus broad docs markers, leave most upgrade/support language narrative
- Layered claim-based enforcement
- Maximal enforcement with prose-level docs locks and a large fixture matrix

**Chosen default**
- Layered claim-based enforcement

**Why**
- It preserves fast feedback and public-contract discipline without turning docs maintenance into brittle test appeasement.
- It keeps executable proof focused on real host-contract claims and leaves narrative guidance free to evolve.

## Cross-Cutting Guidance

- Keep the native `/ops/jobs` shell primary in docs and proof.
- Keep the optional `/ops/jobs/oban` bridge explicitly read-only and additive.
- Do not describe public upgrade support using internal phase-number vocabulary.
- Separate “no commercial support” from “no dependable technical contract.”
- Treat adjacent ecosystem patterns as validation for explicit host-owned seams, not as a reason to broaden the support promise.

## Inputs Used

- Prior phase contexts for Phases 11-14
- Current README and guides
- Current proof workflow and fixture harnesses
- Product research in `prompts/`
- Research-backed comparisons covering idiomatic Elixir/Phoenix practice and adjacent tools such as Oban Web, Phoenix LiveDashboard, GoodJob, Mission Control Jobs, Sidekiq, and Flower

---

*Discussion complete: 2026-05-23*
