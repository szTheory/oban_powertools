# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

---

## Milestone: v1.4 — Operator Forensics & SRE Runbooks

**Shipped:** 2026-05-27
**Phases:** 11 (32-42) | **Plans:** 28

### What Was Built

- Forensic timeline and evidence bundle foundation with shared v1.3 vocabulary, provenance model, and `/ops/jobs/forensics` investigative destination.
- Limiter history projection and cron missed-fire/delayed-fire diagnostics with explicit retention-boundary support truth.
- Diagnosis-first historical attention projection in the native overview and advisory runbook entry surfaces distinguishing native/bridge-only/host-owned follow-up.
- Runbook-guided remediation continuity persisted through preview→execute→audit, and host-owned escalation hook seams with truthful fallback statuses.
- Canonical phase-level verification backfills (Phase 37) that closed the FRN/OPS orphaned-traceability gap from the original audit.
- Docs-contract and docs/example-host closure (Phase 38) locking the forensics/runbook operator journey as verifiable claims.
- Four merge-blocking CI continuity lanes (Phase 39) turning milestone-proof from phase-local evidence into reproducible CI enforcement.
- Automated acceptance proxies (Phase 40) replacing the last human UAT gates; advisory hardening (Phase 41) centralizing selector encoding and atom normalization; Nyquist compliance sweep (Phase 42).

### What Worked

- **Iterative audit-driven gap closure:** Running the milestone audit mid-stream (after Phase 36) and building dedicated closure phases for each gap (37-42) worked cleanly. Each gap got a scoped, self-contained phase with clear success criteria rather than diffuse rework across existing phases.
- **Additive reconciliation pattern:** Treating Phase 36 as a "reconciliation umbrella" with additive chronology — rather than reopening or amending earlier phases — kept audit traceability clean and prevented circular ownership drift.
- **Automated gate replacement:** Shifting Phase 34 manual acceptance gates left into deterministic proxy tests (Phase 40) was more durable than recording human reviewer outcomes, and the proxies double as regression tests.
- **Bundled plan execution:** Phases 41 and 42 used single bundled plans that covered tightly coupled work (selectors+atoms+proof, all four VALIDATION.md sweeps) without splitting into interim states with no review value.

### What Was Inefficient

- **Phase 36 scope confusion:** Phase 36 was originally planned as the docs/proof closure phase but was overtaken by the audit gap findings. The reconciliation pivot was correct but required additional reconciliation work to document the canonical ownership boundaries for DOC-05 and VER-04.
- **Audit found 7 gaps after Phase 36:** The original audit showed `status: gaps_found` across requirements, phases, integration, and flows. This drove phases 37-42. Better upfront proof harness design (wiring continuity CI lanes earlier, writing verification artifacts closer to implementation) would have avoided the gap-closure tail.
- **ROADMAP.md Phase 42 checkbox inconsistency:** Phase 42 was planned with 3 plans but completed with 1 bundled plan. The ROADMAP.md unchecked plans for 42-02 and 42-03 diverged from actual completion state. Bundling decisions should update ROADMAP.md checkboxes immediately.

### Patterns Established

- **Milestone-audit-driven gap phases:** When an audit finds gaps, add scoped closure phases rather than amending existing ones. Name them after the gap they close (e.g., `37-verification-backfill`, `38-docs-closure`, `39-ci-proof-closure`).
- **Reconciliation umbrella pattern:** A phase that reconciles additive closure (pointing to canonical owners) is legitimate and should be documented as such — not reopened or stripped — in the ROADMAP.md notes.
- **Automated acceptance proxy pattern:** Replace human gates with deterministic LiveView/copy-contract proxies wired into existing CI lanes. Reduces closure ambiguity and doubles as regression protection.
- **Bundled plan pattern:** When sub-plans for a phase are tightly coupled, bundle into one plan and document the rationale in ROADMAP.md. Update checkboxes to reflect the bundled shape, not the original plan breakdown.

### Key Lessons

1. **Wire CI lanes early.** VER-04 required a dedicated closure phase because continuity suites existed only as local evidence. Wiring them to named CI check IDs during Phase 35 (when the seams were implemented) would have closed VER-04 without a follow-up phase.
2. **Publish phase verification artifacts before closing the phase.** FRN-01/02/03 and OPS-01/02 required Phase 37 backfill because Phase 32/33 had no VERIFICATION.md at close. The fix: treat VERIFICATION.md as a phase exit criterion, not an optional artifact.
3. **Docs-contract tests are cheapest at implementation time.** DOC-05 required a dedicated Phase 38 because docs-contract coverage was thin at Phase 36. Adding docs-contract markers during Phase 32-35 implementation would have closed DOC-05 in-band.
4. **Proof bundled with code is sticky; deferred proof accumulates as tech debt.** Phases that shipped code without verification or docs-contract coverage systematically became audit gaps. The gap-closure tail (Phases 37-42) is the cost of that deferral.

### Cost Observations

- Model mix: primarily Sonnet for execution phases, Opus-class reasoning for discuss/plan/audit phases.
- Notable: gap-closure phases (37-42) added ~40% more phase count than the core milestone arc (32-36). Upfront proof discipline would reduce this ratio.

---

## Milestone: v1.5 — Native Job Surface & Automation API

**Shipped:** 2026-05-28
**Phases:** 4 (43-46) | **Plans:** 9

### What Was Built

- Ecto-native `ObanPowertools.Jobs` query context with `%JobFilter{}`, state-leading queries, offset pagination (documented keyset upgrade path), and a `DisplayPolicy.render_job_field/3` redaction helper.
- Native `/ops/jobs/jobs` list + detail surface: filter by state/queue/worker/tags, URL-serialized filter state for deep-links, and args/meta redaction on the detail view.
- Single-job retry/cancel/discard through the full Lifeline preview → reason → execute → audit pipeline, with a concurrent-modification (`preview_drifted`) guard and no direct `Oban` calls from the LiveView.
- Bulk operations: MapSet-backed multi-select, an independent `Lifeline.execute_repair` per job (no single `Ecto.Multi` over N), and honest per-job success/failure reporting.
- `ObanPowertools.Operator` typed single + bulk API requiring a non-nil actor, routed through the same Lifeline pipeline as the UI and emitting `source: "api"` telemetry within the frozen low-cardinality contract.

### What Worked

- **Pipeline reuse over parallel paths:** Anchoring both the UI and the Elixir API to the single `Lifeline.execute_repair` pipeline meant the API phase (46) inherited the audit, preview-drift, and telemetry guarantees the UI phases already proved — no second mutation surface to secure.
- **Phase ordering discipline:** Building read-only browse first (43), then single-job actions (44), then bulk (45), then the API wrapper (46) meant each phase derived its contract from a proven predecessor. The API signatures fell out of the established UI pipeline rather than being designed speculatively.
- **Tight milestone arc:** 4 phases / 9 plans with zero gap-closure tail — the audit passed 6/6 first time, a marked improvement over v1.4's 37-42 tail.

### What Was Inefficient

- **Phase 44/45 implementation was never committed during execution.** Both phases had completed SUMMARY files claiming "all tests passing," but the `JobsLive` UI implementation existed only as uncommitted working-tree changes — no `feat(44-*)`/`feat(45-*)` commits ever landed. The milestone audit reported `passed` because it validated working-tree state, not committed state. This was caught only at milestone close and recovered by committing the working tree (`0ea569d`, 270 tests green).
- **Botched-edit debris reached the tree:** a malformed test-file tail (a stray comment block after the module's closing `end`), a corrupted ROADMAP.md table row, and ~950 KB of un-gitignored scratch artifacts (`test_output.txt`, `*.json`, `*.patch`) were all sitting in the working tree at close.
- **ROADMAP plan-list copy-paste errors:** Phase 45's plan list referenced `46-01/46-02` plan files, and 45/46 checkbox + Progress-table state diverged from reality — symptoms of edits applied to the wrong section.

### Patterns Established

- **Pipeline-anchored API wrapper:** When exposing a programmatic API for capability the UI already has, wrap the *same* internal pipeline rather than building a parallel path. The API phase then inherits proven guarantees and only needs signature + actor-attribution work.
- **Commit-state is the source of truth at close, not working-tree state.** Verification and audit must run against committed state (or at minimum assert a clean tree), or "passing" can mean "passing in an uncommitted tree."

### Key Lessons

1. **A phase is not done until its implementation is committed.** SUMMARY files and green tests are necessary but not sufficient — execution must verify a commit actually landed for the phase's code. The audit's `passed` was misleading because it never checked `git log` for the phase's feat commit.
2. **Audits should assert a clean working tree.** An audit that validates uncommitted changes will certify work that does not exist in history. Add a `git status --porcelain` clean-tree precondition (or explicit commit-existence check per phase) to the audit/verification contract.
3. **Gitignore agent scratch early.** Run artifacts (`test_output.txt`, `*.json`, `*.patch`) accumulated untracked at repo root and were one `git add .` away from being committed. Ignore patterns belong in `.gitignore` from the first execution phase.
4. **Update ROADMAP checkboxes/tables in the same edit that completes the work** — deferred or mis-targeted edits produced corrupted rows and wrong plan references that had to be repaired at close (an echo of the v1.4 Phase 42 checkbox lesson).

### Cost Observations

- Model mix: Opus for discuss/plan/audit, Sonnet for execution/verification/completion (per `balanced` model profile).
- Notable: the milestone arc itself was efficient (no gap-closure tail), but the close required unplanned recovery work (committing lost phase code, repairing debris) that disciplined execution-time commit verification would have eliminated.

---

## Milestone: v1.6 — Release & Operability

**Shipped:** 2026-05-30
**Phases:** 7 (47-52.1, including inserted 52.1) | **Plans:** 16

### What Was Built

- Full release-please CI/CD pipeline — release-please → gate-ci-green → publish-hex → verify-published with zero-touch automerge. Published at `0.5.0` with Apache-2.0 LICENSE, Keep-a-Changelog CHANGELOG.md, and path-to-1.0 documented.
- `mix oban_powertools.doctor` — five read-only `pg_catalog` health checks (index validity, INVALID detection, migration drift, Powertools tables, uniqueness-timeout risk), human + JSON output, 0/1/2 CI exit codes, remediation hints.
- `mix oban_powertools.limiter.explain` and `.simulate` — CLI over existing `Explain` API + pure `compute_reservation/4` with no DB access; rate-limit `ObanPowertools.Glossary` module locked by docs-contract test.
- Opt-in `ObanPowertools.Telemetry.metrics/0` — 17 counters over the frozen low-cardinality contract; `telemetry_metrics`/`telemetry_poller` optional deps; `Code.ensure_loaded?` guard. Zero new runtime deps.
- `guides/telemetry-and-slos.md` — reporter-agnostic Parapet/SLO Operations guide, no `oban_met` dependency.
- `examples/hex_consumer/` — Phoenix adoption proof with first-session test proved green via path-dep swap; `verify-published` CI job gates release pipeline on real published tarball.
- Phase 52.1 (inserted after milestone audit) — four surgical fixes to `release.yml`, `regenerate.sh`, `.gitignore` to close the REL-04 Igniter committed-modules blocker.

### What Worked

- **Milestone audit-driven insertion:** Running the audit before archiving surfaced the REL-04 Igniter conflict early. Inserting Phase 52.1 to close the static half of the gap before archiving was the right call — clean audit trail, no deferred surprises.
- **Phase 52.1 as a surgical insert:** The single-plan phase pattern for a targeted fix (4 edits across 3 files) was efficient. Naming it after the gap (`close-gap-rel-04`) made its purpose unambiguous.
- **Nyquist VALIDATION.md already updated by the time of milestone close:** Both Phase 50 and Phase 51 VALIDATION.md files had been updated to `nyquist_compliant: true` between the audit and the milestone archive. The compliance check passed without a separate validation run.
- **Zero gap-closure phase tail:** Unlike v1.4 (6 gap-closure phases), v1.6 needed only one inserted closure phase — Phase 52.1. Proactive verification (13/13 per-phase verification truths) and the Nyquist discipline kept the tail short.
- **Release infrastructure investment paid off immediately:** The release-please + automerge pipeline means future releases are zero-touch from `git push`. The one-time setup cost in Phase 47/52 amortizes across every subsequent release.

### What Was Inefficient

- **Milestone audit still showed `gaps_found` at archive time** — because the audit ran before Phase 52.1 closed the REL-04 static gap. The audit file itself is stale. A re-run post Phase 52.1 would have shown a cleaner `passed` (or `partial` with the live CI gate explicit). Consider re-running the audit after all inserted closure phases complete.
- **Phase 47 missing VERIFICATION.md:** Phase 47 has strong external evidence (0.5.0 live, hexdocs renders, VALIDATION.md 35 green tests) but never received a goal-backward verification report. This repeated the v1.4 pattern of strong deliverables with missing process artifacts. A VERIFICATION.md written at Phase 47 close would have moved REL-01/02/03 from `partial` to `satisfied` in the audit.
- **Doctor/limiter CLI/telemetry not in published 0.5.0 at milestone close:** All three features were in-repo verified but the 0.5.1 release-please PR remained unmerged. v1.6 shipped the code but not the published package for 10/13 requirements. The "release IS the milestone" framing was only half-true at close.
- **Release pipeline PAT + secrets setup required out-of-band operator action:** RELEASE_PLEASE_TOKEN, HEX_API_KEY, and branch protection rules required human setup steps. These are correct calls (security boundaries), but the setup steps weren't captured as trackable tasks — they surfaced as process gaps at close.

### Patterns Established

- **Audit-before-archive as a gate:** Running `gsd-audit-milestone` before `gsd-complete-milestone` and inserting a closure phase when gaps are found (rather than archiving with known blockers) is now established practice.
- **Surgical insert pattern:** A single-plan phase named after the gap it closes (`52.1-close-gap-rel-04`) is the right shape for post-audit surgical fixes. Avoid bundling unrelated work.
- **`verify-published` CI job as release gate:** Gating the release pipeline on a fresh-host first-session test from the published tarball closes the "works in-repo, broken on hex" failure mode.
- **Release-please `bootstrap-sha` must be `0.0.0`, not `0.1.0`:** The first-release bootstrap pitfall — seed manifest at `0.0.0` with a `Release-As: X.Y.Z` footer commit. Seeding at the current version breaks the version-increment math.

### Key Lessons

1. **Re-run the milestone audit after all inserted closure phases complete.** The v1.6 audit ran before Phase 52.1 and remained stale. The final pre-archive audit should reflect the completed state.
2. **Write VERIFICATION.md at phase close, not retroactively.** Phase 47's missing VERIFICATION.md repeated the v1.4 lesson. Treat VERIFICATION.md as a non-optional phase exit criterion.
3. **"Release IS the milestone" requires verifying the published tarball, not just in-repo.** Doctor/limiter/telemetry were verified in-repo but not in the published 0.5.0. For release milestones, the published tarball is the only acceptable final verification artifact.
4. **Document operator setup steps as first-class tasks.** PAT/secret/branch-protection setup should be in the plan as explicit tasks with acceptance criteria, not implied.

### Cost Observations

- Model mix: Opus for discuss/plan/audit phases, Sonnet for execution/verification/completion (per `balanced` model profile).
- Sessions: ~3 days across 7 phases.
- Notable: the milestone was dense on infrastructure (CI/CD, release pipeline, adoption proof) with relatively low LOC compared to feature-heavy milestones. Setup/verification overhead was proportionally higher than in-code work.

---

## Milestone: v1.7 — Worker Lifecycle & Safety

**Shipped:** 2026-06-13
**Phases:** 4 (53-56) | **Plans:** 14

### What Was Built

- Crash-safe worker lifecycle hooks (`on_start/1`, `on_success/2`, `on_failure/2`, `on_discard/2`) with wrapper-owned dispatch, final-attempt classification, and `worker_hook` telemetry family.
- Soft `deadline:` stores `__deadline_at__` ISO8601 meta at enqueue; `perform/1` cancels expired jobs before `process/1`. `timeout:` generates overridable `timeout/1`. Doctor warns on retryable expired-deadline jobs.
- `ObanPowertools.JobRecord` — new `oban_powertools_job_records` table with opt-in `record_output: true`, best-effort recording before `on_success`, `fetch_result/1` API, Recorded Output card in `/ops/jobs` detail, Lifeline ephemeral pruning.
- `redact: [:field]` drops PII from args after fingerprint via `new/2` override, injects `__redacted_fields__` meta. Cron path fixed via sentinel routing. UI disclosure block + per-field "Redacted at enqueue" overlay. Docs-contract locked.

### What Worked

- **Tight 2-day arc with zero gap-closure tail.** 4 phases, 14 plans, 507 tests, 0 failures, no inserted closure phases. The audit passed all 18 requirements on the first run, with findings categorized as deferred tech debt rather than blockers.
- **Build order discipline.** Phase 53 (hooks) → 54 (deadline/timeout, depends on wrapper) → 55 (recording, depends on wrapper) → 56 (redact, depends on recording pipeline) meant each phase inherited a proven seam from the prior one. Phase 56 redaction slotted into the recording pipeline without refactoring.
- **Audit-before-archive surfaced INT-01/INT-02 as deferred items** rather than blocking the milestone close. The `tech_debt` status correctly captured that all requirements are satisfied while flagging known non-blocking gaps for v1.8.
- **Docs-contract tests prevent support-truth drift.** Phase 53 and Phase 56 both locked critical boundary sentences (hook observe-only semantics, `redact:` does NOT scrub recorded outputs) in `docs_contract_test.exs`. These become regression protection, not just documentation.

### What Was Inefficient

- **INT-02 (cron+deadline path) was missed in planning.** The cron path missing `merge_powertools_meta/4` for `deadline:`-configured workers was not in the Phase 54 plan; it surfaced only in the audit. Given that Phase 56 (redact) explicitly fixed the cron path, Phase 54 should have similarly audited the cron path for deadline injection. Fix is small (`maybe_insert_job` calling `Deadlines.build_meta` when the sentinel fires); it should have been in Phase 54-02.
- **INT-01 (Doctor manifest gap) was a predictable miss.** When adding a new Powertools table, the `@powertools_manifest` in `doctor/checks.ex` is the natural place to register it. The PLAN.md for Phase 55 did not reference Doctor manifest as a success criterion, so it was missed. A standard checklist item — "did you add a new table? → update @powertools_manifest" — would prevent this class of oversight.
- **Nyquist `wave_0_complete: false` in 3 of 4 phases** (53, 54, 56). The formal TDD wave-0 capture (recording which tests were initially red before going green) was not consistently recorded in VALIDATION.md. Only Phase 55 was fully Nyquist-compliant. This is process debt, not functional debt, but it accumulates across milestones.
- **Frontmatter key inconsistency** (`requirements:` vs `requirements-completed:`) in plans 55-03, 55-04, 56-01, 56-03, 56-04. Caught by audit but not prevented at plan creation time.

### Patterns Established

- **`function_exported?/2` sentinel for Powertools worker routing on shared paths (cron, etc.):** `function_exported?(worker_mod, :__powertools_limits__, 0)` is the canonical sentinel because it is always generated for all `ObanPowertools.Worker` modules, including those with `limits: []`. This pattern applies whenever a shared Oban code path needs to route Powertools workers differently.
- **No FK from operational tables to `oban_jobs`:** `oban_powertools_job_records` uses `oban_job_id` as a soft bigint reference. No FK so Oban can prune its own table without blocking. Retention managed independently via `expires_at` in Lifeline.
- **Recording runs before hook dispatch:** Worker recording happens between `process/1` and `Hooks.after_result/3` so `on_success/2` callbacks can observe the persisted `JobRecord`. This ordering matters for callback-chain correctness.
- **`rescue ArgumentError` degradation on cron path:** Wrapping both atom resolution and `function_exported?` check in a rescue block prevents cron-run crashes when a worker module is unloaded or removed at runtime. Degrade to bare `Oban.Job.new`.

### Key Lessons

1. **Doctor manifest is a checklist item for new tables.** Any plan adding a new Powertools table should have "add to `@powertools_manifest` in `doctor/checks.ex`" as an explicit task. Missed in Phase 55 → INT-01 surfaced in audit.
2. **Audit cron path when enqueue logic changes.** Phase 54 added enqueue-time `__deadline_at__` injection but didn't audit the cron path — a natural parallel to the explicit cron-path fix in Phase 56 for redaction. Cross-path enqueue behavior should be a standard success criterion when any enqueue-time metadata is introduced.
3. **Nyquist wave-0 capture belongs in the plan's task list, not as a post-hoc VALIDATION.md note.** Without an explicit task, the red-commit evidence gets skipped in fast execution phases (54: 3 min, 2 min, 2 min). Make it a task-0 requirement.
4. **`tech_debt` audit status is a valid ship gate.** v1.7 shipped cleanly with `tech_debt` status. The gaps were documented, categorized, and deferred — this is the right outcome when requirements are fully satisfied and integration gaps are non-blocking. Don't hold milestones for non-blocking items.

### Cost Observations

- Model mix: Sonnet for execution phases (per `balanced` model profile); Opus-class for discuss/plan/audit phases.
- Sessions: 2 days, 4 phases, 14 plans.
- Notable: fastest milestone arc yet (2 days, no gap-closure phases) with the most densely coupled cross-phase wiring (hooks → deadline → recording → redaction all reuse the same generated perform wrapper seam).

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1        | 8      | 28    | Initial GSD process — establish patterns |
| v1.1      | 8      | 27    | Host contract hardening; more structured audit posture |
| v1.2      | 11     | 31    | Verification backfill pattern introduced |
| v1.3      | 5      | 15    | Tighter scoping; control-plane convergence |
| v1.4      | 11     | 28    | Audit-driven gap-closure phases; CI proof enforcement; automated acceptance proxies |
| v1.5      | 4      | 9     | Tight arc, no gap-closure tail; but lost phase commits exposed audit-vs-commit-state gap |
| v1.6      | 7      | 16    | Release milestone: hex publication + operability CLIs; audit-before-archive gate; one surgical insert (52.1) |
| v1.7      | 4      | 14    | Tightest arc yet (2 days, zero gap-closure phases); `tech_debt` audit as valid ship gate; cron-path and Doctor-manifest class of gaps identified |

### Top Lessons (Verified Across Milestones)

1. **Proof artifacts at phase close prevent gap-closure tails.** Every milestone that skipped phase-level verification produced a backfill obligation in a later phase.
2. **Bounded scope + explicit support-truth beats broad capability claims.** Narrowing each milestone to one coherent operator story produces more useful audit and docs outcomes than broad feature sprawl.
3. **Reconciliation phases are legitimate work.** Additive reconciliation (adjusting ownership, traceability, and canonical references) has appeared in v1.2 (Phase 24/25), v1.3, and v1.4. It should be planned for, not treated as scope failure.
4. **Verify commit-state, not working-tree state.** v1.5 shipped phases whose code was never committed yet still audited `passed`. Verification/audit must assert a clean tree or per-phase commit existence — green tests in a dirty tree are not proof of shipped work.
5. **Audit-before-archive is a gate, not a formality.** v1.6 inserted Phase 52.1 based on the audit finding; skipping the audit would have archived a broken `verify-published` CI job. Re-run the audit after all inserted closure phases complete.
6. **For release milestones, the published tarball is the only final verification artifact.** In-repo green ≠ published green. `verify-published` CI job is the right closing gate for any hex release milestone.
7. **Cross-path enqueue coverage is a standard checklist item.** Any enqueue-time metadata addition must audit all insert paths (idempotency, cron, direct). v1.7's INT-02 (cron+deadline gap) repeats the same class of miss as v1.6's REL-04 — a shared code path that wasn't updated when a feature was added to the primary path.
8. **`tech_debt` audit status is a valid ship gate.** All requirements satisfied + non-blocking gaps documented = ready to ship. Don't hold milestones for non-blocking items; defer them with explicit tracking.
