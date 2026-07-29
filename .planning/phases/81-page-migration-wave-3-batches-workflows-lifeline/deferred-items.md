# Phase 81 Deferred Items

- Dependency resolution during Plan 81-07 reported upstream security advisories
  for the currently locked Bandit, hpax, Mint, Oban Web, Phoenix, Plug,
  Postgrex, and Req versions. These are pre-existing dependency concerns and
  were not changed by the fixture-bridge plan; handle them through the
  repository's dependency-upgrade/security-review workflow.
- Plan 81-05 connected Lifeline runtime verification exposed a Plan 81-07
  fixture mismatch: the fixture seeds active incidents with
  `incident_class: "executor_missing"`, while the production projector owns
  `dead_executor` incidents and resolves the unknown seeded class before the
  page reads it. The isolated browser page therefore has zero active incident
  rows and cannot reach the preview button. Correct the test-only fixture class
  (and retain its saturated 51-row contract) in the owning fixture plan before
  treating the connected Wave 3 Lifeline flow as green.
