---
phase: 78-component-groups-meta-components
fixed_at: 2026-07-19T02:35:03Z
review_path: .planning/phases/78-component-groups-meta-components/78-REVIEW.md
iteration: 3
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 78: Code Review Fix Report

**Fixed at:** 2026-07-19T02:35:03Z
**Source review:** `.planning/phases/78-component-groups-meta-components/78-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### WR-04: Refreshed attention-matrix screenshots still fail canonical visual comparison

**Files modified:** `scripts/playwright-docker.sh`, `scripts/with-showcase-server.sh`, and the exact 12 `test/browser/__screenshots__/chromium-{320,tablet,wide}/showcase/group-attention-status-severity-matrix/{system,light,dark,high-contrast}.png` baselines
**Commit:** 1f1e4b5
**Applied fix:** Diagnosed the mismatch rather than accepting another blind refresh. The iteration-2 updater never entered the canonical container because Apple Bash 3.2 treats the empty `NETWORK_ARGS` array expansion under `set -u` as an unbound variable; its fallback host-browser capture therefore produced the non-canonical dimensions. The Docker launcher now builds a non-empty argument array that works under Bash 3.2, and the showcase wrapper `exec`s the BEAM server so its trap owns and promptly removes the actual listener. A fresh canonical Docker reproduction failed all 12 pre-fix targets with the reviewed dimensions, confirming the runtime mismatch; no listener occupied port 42073 before the fresh runs, and the rendered fixture remained the deterministic four-card matrix. Only the exact 12 manifest-derived screenshots were regenerated in the canonical container. Two consecutive fresh compare-only Docker runs then passed 12/12, each with an empty-port preflight and confirmed listener cleanup. The verifier reports the exact 276-baseline inventory and changed scope of exactly 12 paths, all within that inventory.

---

_Fixed: 2026-07-19T02:35:03Z_
_Fixer: Codex (gsd-code-fixer)_
_Iteration: 3_
