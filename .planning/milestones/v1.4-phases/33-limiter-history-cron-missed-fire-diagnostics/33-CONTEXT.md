# Phase 33: Limiter History & Cron Missed-Fire Diagnostics - Context

**Gathered:** 2026-05-27
**Status:** Complete
**Implementation commit:** `1b36404` (`feat: add forensic timelines for cron and limiters`)

<domain>
## Phase Boundary

Promote limiters and cron from supporting forensic evidence into first-class investigative surfaces through the shared Phase 32 forensic contract.

This phase owns:
- durable limiter history facts for operator-meaningful transitions
- cron slot and scheduler-coverage evidence for missed-fire, delayed-fire, overlap, manual-run, and unknown-window diagnosis
- shared `/ops/jobs/forensics` selectors for limiter and cron resources
- diagnosis-first history summaries on the limiter and cron pages that deep-link into the canonical forensic destination
- explicit partial-evidence and history-unavailable boundaries

This phase does not:
- add a generic raw event console
- turn audit into the primary automatic history store
- create a machine-facing automation API
- reopen generic Oban queue or job-dashboard scope

</domain>

<decisions>
## Implementation Decisions

- **D-01:** Use the Phase 32 forensic bundle as the canonical destination for limiter and cron investigations.
- **D-02:** Keep limiter history resource-level and diagnosis-first, with partition detail carried as supporting context.
- **D-03:** Persist low-volume limiter facts for blocked, released/restored-observed, cooled-down, and reconfigured transitions.
- **D-04:** Preserve support truth for limiter restoration by distinguishing observed restoration from mathematically eligible restoration.
- **D-05:** Keep cron history slot-centric and reason-bucketed instead of presenting schedule rows as a raw event stream.
- **D-06:** Add scheduler coverage facts so healthy-coverage missing slots can be called missed fires, while coverage gaps remain unknown or partial evidence.
- **D-07:** Treat manual cron runs as visible history that must not rewrite schedule truth.
- **D-08:** Keep LiveViews thin: cron and limiter pages render summaries from the same read models that assemble the full forensic bundles.
- **D-09:** Use stable URL selectors only: `resource_type=cron_entry|limiter` plus `resource_id`.
- **D-10:** Keep Oban Web and audit handoffs venue-honest with the existing Inspection only and supporting-evidence vocabulary.

</decisions>

<implementation>
## Implemented Shape

- Added `ObanPowertools.Forensics.CronHistory` and `ObanPowertools.Forensics.LimiterHistory` as read-model modules.
- Added `ObanPowertools.Forensics.CronCoverage` and `ObanPowertools.Forensics.LimiterHistoryFact` as durable evidence schemas.
- Extended `ObanPowertools.Forensics.bundle/2` to route stable cron and limiter selectors.
- Updated `ObanPowertools.Cron` to retain coverage and slot metadata needed for manual, delayed, overlap, and reconfiguration diagnosis.
- Updated `ObanPowertools.Limits` to record limiter history facts around blocked, released, cooled-down, and reconfigured transitions.
- Added history summary sections to `CronLive` and `LimitersLive` with forensic deep links.
- Updated installer and test migrations so new durable stores exist in fresh installs and test bootstrap.

</implementation>

<verification>
## Verification Evidence

Targeted Phase 33 suite passed on 2026-05-27:

```sh
mix test test/oban_powertools/cron_test.exs \
  test/oban_powertools/forensics_test.exs \
  test/oban_powertools/web/live/cron_live_test.exs \
  test/oban_powertools/web/live/limiters_live_test.exs \
  test/oban_powertools/web/live/forensics_live_test.exs
```

Result: `35 tests, 0 failures`.

Full repo-wide `mix test` was not captured cleanly in the implementation session, so Phase 33 closure records targeted verification only.

</verification>

