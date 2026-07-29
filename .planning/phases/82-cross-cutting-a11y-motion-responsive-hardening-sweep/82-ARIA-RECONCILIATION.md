# Phase 82 ARIA Reconciliation

**Status:** reviewed  
**Inventory:** schema 8; 163 generated targets; 99 page stories; 3 viewport projects; 297 tracked ARIA snapshots  
**Generation provenance:** generation-only; not completion evidence  
**Reviewer decision:** accept the 93 explained paths below; reject any other drift

## Provenance and Review Method

The pre-generation validators reported 163 targets, 99 page stories, 297 exact
filesystem paths, 297 exact Git-tracked paths, and zero pre-existing ARIA
changes. Candidate generation used only:

```text
npm run showcase:manifest &&
scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/page.acceptance.spec.ts --update-snapshots=changed
```

The first generation-only pass exposed one stale upstream story acceptance
string: `page-forensics-history-unavailable` still required `Event history
unavailable.` after Plan 82-14 made `Event log unavailable.` canonical. No
snapshot was blessed around that failure. The story owner corrected the
acceptance string, and the exact command was rerun: 297/297 cases passed.

Every changed family below was reviewed in all three viewport files for
accessible names, roles, states, order, relationships, truthful copy, one
responsive tree, and confidentiality. Normalized line-delta hashes were
identical across `chromium-320`, `chromium-tablet`, and `chromium-wide` for
every family. The changed set contains no missing, extra, copied, renamed,
untracked, or non-manifest path and no preview token, plan hash, raw exception,
raw metadata, stack trace, return target, credential, provider payload, or
fixture sentinel.

In the path table, `{chromium-320,chromium-tablet,chromium-wide}` is a literal
enumeration of three reviewed paths, not an unreviewed wildcard.

## Path-by-Path Semantic Review

| Reviewed paths under `test/browser/__aria_snapshots__/` | Owning repair | Reviewed semantic delta | Decision |
|---|---|---|---|
| `{chromium-320,chromium-tablet,chromium-wide}/page-overview-all-quiet-aria.yml` | Plan 82-07 | Replaces noun-fragment empty headings with grammatical facts: no work needs review, no limiters are blocked, and no work is waiting. Roles and order are unchanged. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-limiters-unavailable-aria.yml` | Plan 82-07 | Adds a labelled Technical evidence region with current-scope unavailability and a legal close/review recovery step. It does not distinguish missing from unauthorized evidence. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-audit-empty-aria.yml` | Plan 82-07 | Extends the empty fact with the next legal action: review another operator page and return after an action is recorded. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-cron-pause-confirmation-aria.yml` | Plan 82-13 | Places the action-specific `Pause cron entry` submit before the safe-state `Keep running` dismiss in accessible order. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-cron-resume-confirmation-aria.yml` | Plan 82-13 | Places the action-specific `Resume cron entry` submit before the safe-state `Keep paused` dismiss. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-cron-run-now-confirmation-aria.yml` | Plan 82-13 | Places the action-specific `Run cron entry now` submit before `Keep current schedule`. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-batches-bulk-confirmation-aria.yml` | Plan 82-13 | Places `Retry 1 failed jobs` before `Keep current state` without changing scope, reason, or consequence. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-batches-callback-confirmation-aria.yml` | Plan 82-13 | Places `Retry callback` before `Keep current state` without changing authority or form state. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-jobs-frozen-all-matching-aria.yml` | Plans 82-13 and 82-14 | Replaces downstream-sounding completed-action support copy with recorded-action truth and orders `Retry 143 jobs` before `Keep current state`. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-jobs-bulk-zero-ready-aria.yml` | Plan 82-14 | Changes the support boundary from completed actions to recorded actions; failure and recovery state remain visible. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-jobs-bulk-progress-aria.yml` | Plan 82-14 | Changes only the support-boundary claim from completed to recorded actions while progress remains live and independently described. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-jobs-bulk-mixed-results-aria.yml` | Plan 82-14 | Uses recorded-action truth while preserving mixed success, skipped, and failed result semantics. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-jobs-bulk-drifted-aria.yml` | Plan 82-14 | Uses recorded-action truth while retaining stale-preview recovery. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-jobs-bulk-disconnected-aria.yml` | Plan 82-14 | Uses recorded-action truth while retaining disconnect/interruption support boundaries. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-jobs-bulk-interrupted-aria.yml` | Plan 82-14 | Uses recorded-action truth while retaining explicit interrupted mixed-result recovery. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-forensics-unavailable-aria.yml` | Plan 82-14 | Adds `Choose another evidence scope to continue` to the uniform unavailable branch without revealing existence, retention, or permission truth. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-forensics-history-unavailable-aria.yml` | Plan 82-14 | Replaces forbidden `Event history` terminology with canonical `Event log`; retained-history limits remain unchanged. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-lifeline-consumed-preview-aria.yml` | Phase 81 post-baseline UI review | Renames the destination from `Open forensic timeline` to the broader and truthful `Open forensic evidence`; URL and authority are unchanged. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-lifeline-drifted-preview-aria.yml` | Phase 81 post-baseline UI review | Applies the same truthful Forensics destination name while keeping drift recovery intact. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-lifeline-execute-loading-auth-race-aria.yml` | Phase 81 post-baseline UI review | Applies the same destination-name correction without changing loading, authorization, or execution state. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-lifeline-expired-preview-aria.yml` | Phase 81 post-baseline UI review | Applies the same destination-name correction while preserving expired-preview recovery. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-lifeline-invalid-short-reason-aria.yml` | Phase 81 post-baseline UI review and Plan 82-13 | Renames the Forensics destination and orders `Execute remediation` before `Keep current state`; invalid reason semantics remain associated. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-lifeline-preview-open-aria.yml` | Phase 81 post-baseline UI review and Plan 82-13 | Renames the Forensics destination and orders `Execute remediation` before `Keep current state`; scope, consequence, and reason remain ahead of actions. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-workflows-adversarial-redacted-aria.yml` | Phase 81 post-baseline duplicate-link repair | Removes the first duplicate generic `evidence link`; the labelled `Open forensic evidence` link remains later in the same tree. No adversarial value is added. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-workflows-all-complete-aria.yml` | Phase 81 post-baseline duplicate-link repair | Removes only the duplicate generic Forensics link; the canonical labelled link remains. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-workflows-blocked-dag-aria.yml` | Phase 81 post-baseline duplicate-link repair | Removes only the duplicate generic Forensics link while blocker semantics and canonical destination remain. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-workflows-callback-recovery-posture-aria.yml` | Phase 81 post-baseline duplicate-link repair | Removes only the duplicate generic Forensics link while callback recovery and canonical destination remain. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-workflows-dependency-reasons-aria.yml` | Phase 81 post-baseline duplicate-link repair | Removes only the duplicate generic Forensics link while dependency reasons and canonical destination remain. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-workflows-refusal-lifeline-handoff-aria.yml` | Phase 81 post-baseline duplicate-link repair | Removes only the duplicate generic Forensics link while refusal order, Lifeline handoff, and canonical Forensics destination remain. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-workflows-result-unavailable-aria.yml` | Phase 81 post-baseline duplicate-link repair | Removes only the duplicate generic Forensics link while result-unavailable truth and canonical destination remain. | Accept all 3 |
| `{chromium-320,chromium-tablet,chromium-wide}/page-workflows-selected-blocked-step-aria.yml` | Phase 81 post-baseline duplicate-link repair | Removes only the duplicate generic Forensics link while selected-step blocker semantics and canonical destination remain. | Accept all 3 |

## Exact-Set Result

- Generated manifest: schema 8, 163 targets, 99 page stories, nine page families.
- Matrix: exactly `99 × 3 = 297` unique manifest-derived paths.
- Filesystem set: exactly 297; no missing or extra paths.
- Git-tracked set: exactly 297; no missing or extra paths.
- Candidate scope: exactly 93 modified tracked paths across 31 families.
- Family parity: exactly three paths per family; normalized semantic deltas match across all three projects.
- Rename/copy/untracked/out-of-matrix checks: pass.
- `git diff --check`: pass.
- Reviewer result: all 93 candidates explained and reviewed; no unexplained drift or story expansion accepted.

## Compare-Only Evidence Deferred

Update mode above is generation-only. It is not cited as passing runtime
evidence. Plan 82-08 owns the fresh page acceptance compare-only run:

```text
npm run showcase:manifest &&
npx playwright test test/browser/specs/page.acceptance.spec.ts --list &&
node test/browser/support/verify-page-aria-snapshots.mjs &&
scripts/with-showcase-server.sh npx playwright test test/browser/specs/page.acceptance.spec.ts --project=chromium-wide
```

Plan 82-09 owns the connected production-page system-quality and interaction
runs, including:

```text
scripts/with-showcase-server.sh npx playwright test test/browser/specs/system-quality.spec.ts --project=chromium-wide

scripts/with-showcase-server.sh npx playwright test test/browser/specs/page-migration-wave-1.spec.ts test/browser/specs/page-migration-wave-2.spec.ts test/browser/specs/page-migration-wave-3.spec.ts --project=chromium-wide
```

Any compare-only semantic mismatch returns to its production owner and then
through this generation-and-review process. Plans 82-08 and 82-09 do not update
or bless ARIA snapshots.
