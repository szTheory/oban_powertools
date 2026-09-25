# Session Handoff

## Current State

- v2.0, Powertools Identity, is recorded as shipped in the local repository. Its milestone audit passed on 2026-07-31.
- No next milestone is active. Candidate work is provisional and documented in `PROJECT.md`, `research/MILESTONE-ARC.md`, and `ROADMAP.md`.
- GSD is configured to use the Codex runtime in `.planning/config.json`. The installed OpenGSD version is 1.14.0.
- The v2.0 tag remains on release commit `a854a00`. Remote `main` now includes merged PR #29 at `345b8a2`; local `main` remains at `ee78570` and needs a fast-forward after preserving the planning edits in this checkout.
- Earlier direct pushes were exceptional. Keep source changes on the normal pull-request path.

## Recent Phase 79 Work

The committed Phase 79/page-quality follow-up adds fixture-toggle compilation proof, page-story acceptance metadata, expanded accessibility/reflow checks, VoiceOver tooling, and a nightly page-quality workflow.

Phase 79/page-quality changes are committed and pushed. The 2026-09-24 checks on release PR #19 exposed three actionable issues:

- `Compile` failed in test mode because `ObanPowertools.Worker` redefined both `new/1` and `new/2` from `use Oban.Worker`; `new/1` is a generated wrapper, not an Oban callback. The macro now overrides only `new/2`, leaving the generated wrapper to dispatch through the redaction-aware callback.
- `Page Quality` ran the fixture-toggle script inside `examples/phoenix_host` without fetching that standalone Mix project's dependencies. The script now runs `mix deps.get` from the host directory.
- Host Contract Proof C1 failed at `forensics_live_test.exs:227`: its broad HTML substring assertion treated the foreign audit event's integer ID (`1`) as a unique secret. The check now only asserts high-entropy/private string sentinels; selector destinations are checked separately.

Follow-up on 2026-09-24: PR #29's earlier CI run hit the 30-minute Page Quality and 45-minute Full Showcase Visual & A11y job timeouts. Commit `8331fb4` ran stateful connected specs first on one worker, then parallelized isolated showcase specs across three workers; job limits were raised to 120 and 180 minutes. PR #29 merged as `345b8a2`. Its replacement CI run (`36016887347`) passed Page Quality, Full Showcase Visual & A11y, `ci-gate`, and the other reported required lanes. This closes the PR #29 timeout issue.

The old PR #19 checks (run `35947605583` and Host Contract Proof run `35947605584`) predate PR #29's merge. Compile and Page Quality failed, Full Showcase Visual & A11y was cancelled after the gate failed, and Host Contract Proof C1 plus downstream gates failed. Release Please had two `other side closed` failures while backfilling historical commits; its retry succeeded on run `36037967381`. GitHub's supported PR branch rebase plus the successful bot refresh aligned release PR #19 to current `main` (`345b8a2`), current generated head `138b829`. Fresh CI (`36038904874`) and Host Contract Proof (`36038904809`) ran on that head: Page Quality and every short/host-contract check passed, while Full Showcase Visual & A11y hit its 180-minute timeout twice (attempt 1 reached test 3443; attempt 2 reached test 3417) with no assertion failure. Main CI (`36036203147`) passed all 3912 showcase cases in 170 minutes. PR #30 (`c3a82f2`) raises only the exhaustive showcase job timeout to 240 minutes and is merged. Its PR CI (`36076895734`) passed Page Quality in 77 minutes and the complete Full Showcase suite in 190 minutes. Refreshed release PR #19 is now based on `c3a82f2` at generated head `bf39ea5`; its short CI and host-contract checks pass, while Page Quality and Full Showcase Visual & A11y remain in progress in run `36090873846`. The old Compile log reported warnings from `deps/oban/lib/oban/worker.ex`; do not suppress warnings globally if they recur.

Release closeout update (2026-09-25): Release PR #19 merged as `75b2106` and created GitHub release/tag `v1.1.0`. CI run `36103852266` passed `ci-gate` on the tagged SHA, but the original Release run `36103854234` failed first: its poll stopped after 20 minutes while the exhaustive CI run was still active (Page Quality completed at 08:30 UTC; Full Showcase Visual & A11y and `ci-gate` completed successfully at 09:09 UTC). Rerunning the failed Release jobs found the already-green exact-SHA gate and `Publish to Hex.pm` passed. REL-04 then failed compiling the consumer because its checked-in router already mounted `oban_powertools_routes`, and the installer added the same named LiveView session again. PR #31 (`fix/release-ci-gate-timeout`) now raises the poll allowance to 4.5 hours and makes the Hex consumer a pre-install router fixture; the installer runs from the published package before compilation and adds the route once. PR #31's required CI and Host Contract Proof are running on head `a858216`. Keep release UAT records open until published-package verification passes against a published version; do not force a release solely to clear the records. Keep the separate Phase 81 dependency-advisory follow-up open for a proper upgrade/security review.

GSD health repair (2026-09-25): `$gsd-health --repair --backfill` added the default `workflow.nyquist_validation` and `workflow.ai_integration_phase` keys and synthesized the missing v1.10 milestone registry entry from its archive snapshot (original completion date remains unknown). Removed the unsupported `preferences` config key after confirming its intent is captured in `.planning/PROJECT.md`'s Decision Posture. Moved the custom continuation and milestone arc documents into `.planning/threads/` and `.planning/research/` to clear W019 while retaining their content. The installed GSD config still reports a separate global model-bake warning that requires `gsd install --codex` or `gsd update`; do not modify the user-level install from this project task.

Local verification after the fixes: fresh `MIX_ENV=test mix compile --warnings-as-errors` passed; the Phase 79 fixture-toggle script passed; the focused worker/Forensics/LiveView suites passed (91 tests); and `mix test --exclude host_contract --seed 0` passed (966 tests, 0 failures). The `mix deps.get` run also surfaced current Hex security advisories, so the Phase 81 dependency follow-up remains open for a proper dependency-upgrade/security review.

The Phase 52 CR-01 action-pin finding was fixed in commit `fb9cd62`; `.planning/milestones/v1.6-phases/52-zero-touch-release-automation/52-VERIFICATION.md` now records that follow-up and no longer lists it as human-needed. The current `gsd-tools audit-open` scan reports 7 items: six Phase 51/52/52.1 UAT or verification records waiting for live release evidence, plus one Phase 81 dependency-advisory follow-up. The upcoming release's `verify-published` job can close the release-evidence items if it passes.

## Next Steps

1. Require PR #31's exact-head CI and Host Contract Proof checks to pass, then merge the release-wait and fresh-consumer-fixture fixes through the normal PR path.
2. Keep the six Phase 51/52/52.1 records open until the corrected REL-04 flow passes against a published Hex version; do not publish a new version solely to close audit paperwork. Then update those records with exact run evidence and rerun `gsd-tools audit-open`.
3. Leave Phase 81 dependency advisories open for a proper security/upgrade review and reassess adopter evidence before starting another milestone.
4. Fast-forward local `main` after preserving these planning changes; leave no unexplained worktree residue.
