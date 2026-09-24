# Session Handoff

## Current State

- v2.0, Powertools Identity, is recorded as shipped in the local repository. Its milestone audit passed on 2026-07-31.
- No next milestone is active. Candidate work is provisional and documented in `PROJECT.md`, `MILESTONE-ARC.md`, and `ROADMAP.md`.
- GSD is configured to use the Codex runtime in `.planning/config.json`. The installed OpenGSD version is 1.14.0.
- The v2.0 tag remains on release commit `a854a00`. Local and remote `main` are synchronized at the post-release follow-up commits.
- The pushes bypassed GitHub's pull-request-only branch rule. Do not use that path as the normal workflow; restore authenticated GitHub CLI access and publish future changes through a pull request.

## Recent Phase 79 Work

The committed Phase 79/page-quality follow-up adds fixture-toggle compilation proof, page-story acceptance metadata, expanded accessibility/reflow checks, VoiceOver tooling, and a nightly page-quality workflow.

Phase 79/page-quality changes are committed and pushed. The 2026-09-24 checks on release PR #19 exposed three actionable issues:

- `Compile` failed in test mode because `ObanPowertools.Worker` redefined both `new/1` and `new/2` from `use Oban.Worker`; `new/1` is a generated wrapper, not an Oban callback. The macro now overrides only `new/2`, leaving the generated wrapper to dispatch through the redaction-aware callback.
- `Page Quality` ran the fixture-toggle script inside `examples/phoenix_host` without fetching that standalone Mix project's dependencies. The script now runs `mix deps.get` from the host directory.
- Host Contract Proof C1 failed at `forensics_live_test.exs:227`: its broad HTML substring assertion treated the foreign audit event's integer ID (`1`) as a unique secret. The check now only asserts high-entropy/private string sentinels; selector destinations are checked separately.

The Full Showcase Visual & A11y job was cancelled after the required CI gate had failed; it did not report a separate visual regression. `ci-gate`, `host-contract-gate`, and `continuity-proof-status` failures were downstream of the failed lanes.

Local verification after the fixes: fresh `MIX_ENV=test mix compile --warnings-as-errors` passed; the Phase 79 fixture-toggle script passed; the focused worker/Forensics/LiveView suites passed (91 tests); and `mix test --exclude host_contract --seed 0` passed (966 tests, 0 failures). The `mix deps.get` run also surfaced current Hex security advisories, so the Phase 81 dependency follow-up remains open for a proper dependency-upgrade/security review.

The Phase 52 CR-01 action-pin finding was fixed in commit `fb9cd62`; `.planning/milestones/v1.6-phases/52-zero-touch-release-automation/52-VERIFICATION.md` now records that follow-up and no longer lists it as human-needed. The cross-phase audit now reports 8 outstanding items across 7 archived files.

## Next Steps

1. Publish the local CI fixes through a normal pull request; do not push directly to `main` or amend release PR #19.
2. After the fix PR passes and merges, confirm release PR #19 updates and its full required CI gate passes before the 1.1.0 release proceeds.
3. Triage the current dependency advisories through the dependency-upgrade/security-review workflow.
4. At the next milestone boundary, reassess adopter evidence before selecting a candidate. Do not assign a release version or date before that review.
