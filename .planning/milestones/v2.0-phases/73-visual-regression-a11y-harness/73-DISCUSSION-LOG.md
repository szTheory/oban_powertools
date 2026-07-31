# Phase 73: Visual-Regression & A11y Harness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-19
**Phase:** 73-visual-regression-a11y-harness
**Areas discussed:** CI Enforcement, Snapshot Scope, A11y Strictness, Baseline Updates

---

## CI Enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Required `ci-gate` lane | Add a `visual_a11y` job to `.github/workflows/ci.yml` and include it in the existing required `ci-gate` fan-in. Strongest merge-blocking signal and matches current release/branch-protection model. | yes |
| Separate workflow | Isolate browser work in its own workflow. Cleaner browser debug surface, but introduces required-check and release-gate drift unless carefully wired. | |
| Local/manual only | Lowest CI cost and useful for debugging/baseline updates, but not merge-blocking and does not satisfy Phase 73. | |

**User's choice:** Discuss all areas and produce a research-backed one-shot recommendation set.
**Notes:** Subagent research recommended the required `ci-gate` lane because Phase 73 explicitly requires VRT + axe in CI before page/component migration. The lane should run in a pinned Playwright Docker image and upload failure artifacts.

---

## Snapshot Scope

| Option | Description | Selected |
|--------|-------------|----------|
| All showcase sections now | Maximum current surface coverage, but locks placeholder pixels and creates churn for later component phases. | |
| Catalog-backed stories only | Snapshot the stable Phase 72 `ShowcaseCatalog` story cells across theme and viewport matrix. Avoids placeholder churn while protecting real deterministic stress fixtures. | yes |
| Smaller smoke baseline | Fast bootstrap, but too weak for VRT-01 and easy to treat as false confidence. | |

**User's choice:** Discuss all areas and produce a research-backed one-shot recommendation set.
**Notes:** Subagent research recommended catalog-backed stories only. Structural route/control/anchor assertions should still exist, but placeholder future sections should not become visual baselines.

---

## A11y Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Fail critical/serious only | Matches A11Y-01, keeps CI signal high, and publishes lower-severity findings for later hardening. | yes |
| Fail critical/serious plus selected moderate | Catches some structural issues earlier but needs maintained rule policy and can create noise before real stories exist. | |
| Fail all violations | Maximum automated strictness, but poor fit before Phase 82 and likely to cause broad suppressions. | |

**User's choice:** Discuss all areas and produce a research-backed one-shot recommendation set.
**Notes:** Subagent research recommended 0 critical/serious as the merge-blocking threshold, with full reports uploaded. Phase 82 remains responsible for keyboard/focus/motion/manual accessibility completeness.

---

## Baseline Updates

| Option | Description | Selected |
|--------|-------------|----------|
| Local script only | Simple committed PNG flow, but weak PR review ergonomics and easy local/CI drift if not Dockerized. | |
| CI artifact-assisted | CI fails on diffs, uploads reports/diff artifacts, and baselines remain committed source-of-truth. | yes |
| Stricter approval convention only | Strong churn control, but can become process theater unless tied to real snapshot changes. | |

**User's choice:** Discuss all areas and produce a research-backed one-shot recommendation set.
**Notes:** Subagent research recommended artifact-assisted review with explicit local Docker-based snapshot updates. CI must never auto-update baselines. Snapshot-changing PRs should explain why and prefer a separate or clearly labeled baseline update commit.

---

## Claude's Discretion

- Exact Playwright config file names, script names, baseline directory layout, artifact retention period, and target-manifest generation mechanics are left to the planner.
- Planner may split implementation into harness bootstrap, showcase target manifest, visual snapshots, axe scan, CI/artifacts, and documentation.

## Deferred Ideas

- Full visual baselines for future component/page sections.
- Moderate/all axe failures after Phase 82 hardening.
- Manual keyboard/focus/reduced-motion/screen-reader verification.
