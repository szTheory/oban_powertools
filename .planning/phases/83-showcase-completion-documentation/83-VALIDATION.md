---
phase: 83-showcase-completion-documentation
status: validated
wave_0_complete: true
nyquist_compliant: true
updated: 2026-07-31
---

# Phase 83 Validation

Phase 83 completed with fresh command evidence:

- `npm run showcase:manifest` and `manifest-smoke.mjs`: schema 8, 163 targets,
  99 page stories, nine scenarios, seven primitive stories, nine form stories,
  six shell stories, ten data stories, 23 group stories, four themes, and three
  viewports.
- Focused showcase/catalog/Hex-package/docs/assets closure: 103 tests,
  0 failures.
- The dev/test-only showcase route, host independence, and production Hex
  exclusion are asserted by the showcase and package contracts.
- Repeated asset builds were byte-stable. Source/package CSS is byte-identical
  with SHA-256
  `8396723a7625c077ad75f75669373adfae8fc92a422e6e211f7fa8da1de51899`;
  packaged JS SHA-256 is
  `d8117f39cdeb22208a7bf0b2958c0a59cb50e070a6fae43cdcdcf459d88a2849`.
- `mix format --check-formatted` and
  `MIX_ENV=test mix compile --warnings-as-errors` exited 0.
- The contributor guide and visual-regression/a11y guide are linked from both
  README and HexDocs and are pinned by `docs_contract_test.exs`.

The showcase and documentation contracts are executable, exact-counted, and
forward-only; snapshot update mode is documented as generation/review, never
passing comparison evidence.
