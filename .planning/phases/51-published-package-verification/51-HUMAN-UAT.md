---
status: partial
phase: 51-published-package-verification
source: [51-VERIFICATION.md]
started: 2026-05-30T10:45:00Z
updated: 2026-05-30T10:45:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. observe verify-published CI job on a real release
expected: When next release is cut (release_created == 'true'), the verify-published job runs, installs the exact published Hex tarball into examples/hex_consumer, runs the first-session test against it, and the job passes green — proving REL-04 end-to-end.
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
