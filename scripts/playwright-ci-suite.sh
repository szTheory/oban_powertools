#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
case "${mode}" in
  pages)
    specs=(
      test/browser/specs/page-migration-wave-1.spec.ts
      test/browser/specs/page-migration-wave-2.spec.ts
      test/browser/specs/phase81-fixtures.spec.ts
      test/browser/specs/page-migration-wave-3.spec.ts
      test/browser/specs/system-quality-contract.spec.ts
      test/browser/specs/system-quality.spec.ts
      test/browser/specs/page.acceptance.spec.ts
    )
    ;;
  full)
    specs=()
    for spec in test/browser/specs/*.spec.ts; do
      case "${spec##*/}" in
        showcase.a11y.spec.ts|showcase.vrt.spec.ts) ;;
        *) specs+=("${spec}") ;;
      esac
    done
    ;;
  *)
    echo "usage: $0 pages|full" >&2
    exit 64
    ;;
esac

run_playwright() {
  if [[ "${PAGE_QUALITY_ONLY:-}" == "1" ]]; then
    PAGE_QUALITY_ONLY=1 npx playwright test "$@"
  else
    npx playwright test "$@"
  fi
}

run_playwright "${specs[@]}"
run_playwright \
  test/browser/specs/showcase.a11y.spec.ts \
  test/browser/specs/showcase.vrt.spec.ts \
  --fully-parallel \
  --workers=3
