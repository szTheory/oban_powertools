#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANONICAL_DIR="${ROOT_DIR}/examples/phoenix_host"
TARGET_DIR="${ROOT_DIR}/examples/.phoenix_host_regen"

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
  --app phoenix_host \
  --module PhoenixHost \
  --database postgres \
  --no-assets \
  --no-dashboard \
  --no-mailer \
  --no-gettext \
  --no-install

replace_once \
  "${TARGET_DIR}/mix.exs" \
  "{:postgrex, \">= 0.0.0\"}," \
  "{:postgrex, \">= 0.0.0\"},\n      {:oban, \"~> 2.18\"},\n      {:oban_powertools, path: \"../..\"},\n      {:oban_web, \"~> 2.10\", optional: true},"

(
  cd "${TARGET_DIR}"
  mix deps.get
  mix oban_powertools.install
)

rm -rf "${TARGET_DIR}/priv/repo/migrations"
mkdir -p "${TARGET_DIR}/priv/repo"
cp -R "${CANONICAL_DIR}/priv/repo/migrations" "${TARGET_DIR}/priv/repo/migrations"

cat <<EOF

Regenerated fixture tree: ${TARGET_DIR}

Completed automatically:
- mix phx.new baseline
- local oban_powertools dependency insertion
- mix oban_powertools.install
- checked-in Powertools migration set copied into priv/repo/migrations

Manual host-owned follow-up still required:
- TODO: reapply the real auth/session seam and review PhoenixHostWeb.ObanPowertoolsAuth
- TODO: reapply the real display policy and review PhoenixHostWeb.ObanPowertoolsDisplayPolicy
- TODO: restore the curated seeds and README support-truth wording
- TODO: diff the regenerated tree against examples/phoenix_host before replacing anything

This script is deterministic support infrastructure for the canonical curated fixture.
It does not claim the entire checked-in host is generator-only today.

EOF
