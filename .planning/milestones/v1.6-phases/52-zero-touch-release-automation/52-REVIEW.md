---
phase: 52-zero-touch-release-automation
reviewed: 2026-05-30T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/release-pr-automerge.yml
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 52: Code Review Report

**Reviewed:** 2026-05-30
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Two GitHub Actions workflows were reviewed: the general CI workflow (`ci.yml`) and the new release PR auto-merge workflow (`release-pr-automerge.yml`). The CI workflow is well-structured with SHA-pinned actions, a sound ci-gate fan-in pattern, and appropriate permissions. The automerge workflow introduces the primary defects: one unpinned action that is a supply-chain risk, a user-controlled input interpolated directly into JavaScript source (script-injection vector), a job-level timeout omission that leaves a long-polling loop unguarded, and a step ordering issue where an expensive API check runs before a cheap label guard.

---

## Critical Issues

### CR-01: Unpinned `actions/github-script` in automerge workflow

**File:** `.github/workflows/release-pr-automerge.yml:67`
**Issue:** The "Verify ci-gate succeeded on target SHA" step uses `actions/github-script@v8` — a mutable tag reference. Every other action in both workflows is pinned to a full commit SHA. A mutable tag can be silently updated (or hijacked via a compromised upstream) to execute arbitrary code inside the `automerge` job, which holds `contents: write`, `pull-requests: write`, and `actions: write` — the maximum-privilege token set needed to autonomously merge PRs and trigger workflows. The companion `release.yml` already uses the correct pinned SHA (`ed597411d8f924073f98dfc5c65a23a2325f34cd`) for this same action.
**Fix:**
```yaml
# Replace:
        uses: actions/github-script@v8
# With (matching the SHA already used in release.yml):
        uses: actions/github-script@ed597411d8f924073f98dfc5c65a23a2325f34cd # v8
```

---

## Warnings

### WR-01: User-controlled `head_sha` input interpolated directly into JavaScript source

**File:** `.github/workflows/release-pr-automerge.yml:70`
**Issue:** The `workflow_dispatch` input `head_sha` flows from `github.event.inputs.head_sha` into the env var `INPUT_SHA`, then is written verbatim to `$GITHUB_OUTPUT` as `sha`, and is finally interpolated as a string literal inside the `actions/github-script` JavaScript payload:

```javascript
const sha = '${{ steps.target.outputs.sha }}';
```

Any actor with `workflow_dispatch` permission (repo write access) who supplies a value like `'; core.setOutput("result","pwned"); const x = '` would break the script logic. The risk is limited to users already having write access, but it violates the standard GitHub hardening guidance to never interpolate `${{ }}` expressions inside `run:` scripts or `script:` blocks.
**Fix:** Read the value from the Actions environment rather than from the expression:
```yaml
      - name: Verify ci-gate succeeded on target SHA
        uses: actions/github-script@ed597411d8f924073f98dfc5c65a23a2325f34cd # v8
        env:
          TARGET_SHA: ${{ steps.target.outputs.sha }}
        with:
          script: |
            const sha = process.env.TARGET_SHA;
            const { data } = await github.rest.checks.listForRef({
              owner: context.repo.owner,
              repo: context.repo.repo,
              ref: sha,
              filter: 'all'
            });
            // ... rest unchanged
```

### WR-02: No `timeout-minutes` on the `automerge` job

**File:** `.github/workflows/release-pr-automerge.yml:25`
**Issue:** Every job in `ci.yml` declares `timeout-minutes` (10–15 min). The `automerge` job has no timeout. The merge retry loop (lines 140–166) runs up to 12 iterations × 30 s sleep = ~6 minutes and then exits with `exit 1`, so the loop itself is bounded. However, a bug or a hung `gh` call (network stall, API degradation) anywhere in the job's preceding steps has no guard — GitHub's default 6-hour job timeout applies. A reasonable ceiling here is 20 minutes, which covers the ci-gate GitHub Script check, the PR-lookup step, and the full merge retry loop.
**Fix:**
```yaml
  automerge:
    name: Merge release PR
    runs-on: ubuntu-latest
    timeout-minutes: 20
    if: >
```

### WR-03: Merge retry loop re-checks `ci-gate` unnecessarily after a dedicated verification step

**File:** `.github/workflows/release-pr-automerge.yml:134–146`
**Issue:** The "Verify ci-gate succeeded on target SHA" step (lines 66–91) already fails the job if `ci-gate` has not succeeded. If that step passes, `ci-gate` is known to be green. The `latest_ci_gate()` function inside the merge loop (lines 134–145) then re-polls the same API on every iteration, sleeping 30 s and continuing when the result is not `success`. Because the prior step already guarantees success, this branch (`conclusion != "success"`) can only be reached if the check run was retroactively cancelled or if the API returns a transient error — in either case sleeping and retrying silently masks the anomaly. More importantly, the polling mixes two distinct concerns in the same loop: "wait for ci to finish" and "retry a blocked merge". This makes the loop logic hard to follow and means a transient API hiccup (returning an empty/missing result) causes the workflow to spin for up to 6 minutes before failing.
**Fix:** Remove the `latest_ci_gate` guard from inside the retry loop. The dedicated verification step is the correct gate. The loop body should only attempt the merge and sleep on failure:
```bash
for attempt in $(seq 1 12); do
  if gh pr merge "$pr_number" --squash -R "$REPOSITORY"; then
    ...
    exit 0
  fi

  if gh pr merge "$pr_number" --squash --admin -R "$REPOSITORY"; then
    ...
    exit 0
  fi

  echo "Merge blocked (attempt ${attempt}/12); waiting for branch protection to catch up..."
  sleep 30
done
```

---

## Info

### IN-01: Label check runs after expensive API call (step ordering)

**File:** `.github/workflows/release-pr-automerge.yml:66,93,129`
**Issue:** The step order is: (1) Resolve SHA, (2) Verify ci-gate via GitHub API, (3) Find PR and check `autorelease: pending` label. The label check (line 129) is a local `grep` against already-fetched JSON — nearly free. The ci-gate verification (step 2) makes a GitHub Checks API call. If the label is absent (e.g., a stale or manually-opened PR), step 3 exits silently with `exit 0`, but step 2 already consumed API quota and job time. Swapping steps 2 and 3 would allow the cheap label guard to short-circuit before the API check.
**Fix:** Move the PR fetch and label validation into its own step before the ci-gate GitHub Script step, and `exit 0` early if the label is missing or no PR exists.

### IN-02: `actionlint` job missing `timeout-minutes`

**File:** `.github/workflows/ci.yml:131`
**Issue:** Every other job in `ci.yml` has an explicit `timeout-minutes`. The `actionlint` job does not, relying on the 6-hour GitHub default. For consistency and to bound hung runners, add a short timeout.
**Fix:**
```yaml
  actionlint:
    name: Lint workflows
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
```

---

_Reviewed: 2026-05-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
