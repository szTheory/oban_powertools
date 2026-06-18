#!/usr/bin/env bash
#
# Brand book content-assertion harness (Phase 70, Wave 0).
#
# Asserts that guides/brand-book.md faithfully encodes every locked decision
# (D-01 .. D-22) plus the BRAND-05 traceability table, the "explain, then act"
# north star, and the canonical confirm template (D-16). Exits non-zero if any
# required item is missing.
#
# This mirrors 70-VALIDATION.md §1 exactly so executor verification maps to the
# validation contract. Run with no brand book present and it is EXPECTED to FAIL
# (RED) — that is the Wave 0 contract; Task 2 turns it GREEN.
#
# Usage:  bash .planning/phases/70-brand-book-identity-foundation/checks.sh

set -u

# Resolve the brand book path relative to repo root so the script works from any cwd.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BRAND_BOOK="${REPO_ROOT}/guides/brand-book.md"

FAILED=0

fail() {
  echo "FAIL: $1"
  FAILED=1
}

# The file itself must exist before any content assertion is meaningful.
if [ ! -f "$BRAND_BOOK" ]; then
  fail "guides/brand-book.md does not exist"
  echo ""
  echo "RESULT: 1 or more assertions FAILED (brand book absent)."
  exit 1
fi

# 1. Every decision ID D-01 .. D-22 must appear in the brand book.
for n in $(seq -w 1 22); do
  ID="D-${n}"
  if ! grep -q "${ID}" "$BRAND_BOOK"; then
    fail "decision ID ${ID} not found in guides/brand-book.md"
  fi
done

# 2. BRAND-05 traceability table must be present (case-insensitive).
if ! grep -qi "Traceability" "$BRAND_BOOK"; then
  fail "BRAND-05 traceability table (word 'Traceability') not found"
fi

# 3. The "explain, then act" north star must be codified (case-insensitive).
if ! grep -qi "explain, then act" "$BRAND_BOOK"; then
  fail "'explain, then act' north star not found"
fi

# 4. The canonical confirm template (D-16) must appear verbatim. Match its
#    opening clause about cancelling 3 running jobs.
if ! grep -q "Cancel 3 running jobs? They stop now and won't retry. This can't be undone." "$BRAND_BOOK"; then
  fail "canonical confirm template (D-16) not found verbatim"
fi

echo ""
if [ "$FAILED" -ne 0 ]; then
  echo "RESULT: 1 or more assertions FAILED."
  exit 1
fi

echo "RESULT: all brand-book content assertions PASSED (D-01..D-22, traceability, explain-then-act, canonical confirm template)."
exit 0
