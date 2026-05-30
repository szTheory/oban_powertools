#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANONICAL_DIR="${ROOT_DIR}/examples/hex_consumer"
TARGET_DIR="${ROOT_DIR}/examples/.hex_consumer_regen"

replace_once() {
  local file="$1"
  local search="$2"
  local replace="$3"

  ruby -e '
    file, search, replace = ARGV
    source = File.read(file)
    abort("pattern not found in #{file}: #{search}") unless source.include?(search)
    File.write(file, source.sub(search, replace))
  ' "$file" "$search" "$replace"
}

rm -rf "${TARGET_DIR}"

mix phx.new "${TARGET_DIR}" \
  --app hex_consumer \
  --module HexConsumer \
  --database postgres \
  --no-assets \
  --no-dashboard \
  --no-mailer \
  --no-gettext \
  --no-install

# Insert hex dep: {:oban_powertools, "~> 0.5"} (native-only target, no bridge dep)
replace_once \
  "${TARGET_DIR}/mix.exs" \
  "{:postgrex, \">= 0.0.0\"}," \
  "{:postgrex, \">= 0.0.0\"},\n      {:oban, \"~> 2.18\"},\n      {:oban_powertools, \"~> 0.5\"},"

# NOTE: oban_powertools_auth.ex and oban_powertools_display_policy.ex are committed
# in examples/hex_consumer/lib/hex_consumer_web/ as local dev scaffolding so that
# `mix test` and `mix compile` work without running the installer. The CI
# verify-published job deletes these files before running `mix oban_powertools.install`
# so that Igniter generates them fresh from the published tarball (which also triggers
# the 6 required migration files). If you regenerate the scaffold, these files will be
# overwritten by `mix oban_powertools.install` — that is expected and correct.

(
  cd "${TARGET_DIR}"
  mix deps.get
  mix oban_powertools.install
)

rm -rf "${TARGET_DIR}/priv/repo/migrations"
mkdir -p "${TARGET_DIR}/priv/repo"
cp -R "${CANONICAL_DIR}/priv/repo/migrations" "${TARGET_DIR}/priv/repo/migrations"

cat <<EOF

NOTE: This regenerate.sh requires hex.pm to be reachable (hex dep, not path dep).
Run only when oban_powertools is live on hex.pm.

Regenerated fixture tree: ${TARGET_DIR}

Completed automatically:
- mix phx.new baseline
- hex oban_powertools dependency insertion (native-only target, no bridge dep)
- mix oban_powertools.install
- checked-in Powertools migration set copied into priv/repo/migrations

Manual host-owned follow-up still required:
- TODO: reapply the real auth/session seam and review HexConsumerWeb.ObanPowertoolsAuth
- TODO: reapply the real display policy and review HexConsumerWeb.ObanPowertoolsDisplayPolicy
- TODO: restore the curated seeds and README support-truth wording
- TODO: diff the regenerated tree against examples/hex_consumer before replacing anything

This script is deterministic support infrastructure for the canonical curated fixture.
It does not claim the entire checked-in host is generator-only today.

EOF
