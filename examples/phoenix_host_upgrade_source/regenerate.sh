#!/usr/bin/env bash
set -euo pipefail

SOURCE_COMMIT="a1fed86"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARCHIVE_DIR="${ROOT_DIR}/examples/phoenix_host_upgrade_source"
WORKTREE_DIR="${ROOT_DIR}/examples/.phoenix_host_upgrade_source_worktree"
TARGET_DIR="${ROOT_DIR}/examples/.phoenix_host_upgrade_source_regen"
GENERATED_DIR="${TARGET_DIR}/phoenix_host"

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

cleanup() {
  rm -rf "${TARGET_DIR}"

  if [ -d "${WORKTREE_DIR}" ]; then
    git -C "${ROOT_DIR}" worktree remove --force "${WORKTREE_DIR}" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

echo "Maintainer-only: rebuilding archived upgrade source fixture from ${SOURCE_COMMIT}"
echo "This helper is intentionally outside the normal CI and PR proof path."

rm -rf "${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"

if [ -d "${WORKTREE_DIR}" ]; then
  git -C "${ROOT_DIR}" worktree remove --force "${WORKTREE_DIR}" >/dev/null 2>&1 || true
fi

git -C "${ROOT_DIR}" worktree add --detach "${WORKTREE_DIR}" "${SOURCE_COMMIT}"

mix phx.new "${GENERATED_DIR}" \
  --app phoenix_host \
  --module PhoenixHost \
  --database postgres \
  --no-assets \
  --no-dashboard \
  --no-mailer \
  --no-gettext \
  --no-install

replace_once \
  "${GENERATED_DIR}/mix.exs" \
  "{:postgrex, \">= 0.0.0\"}," \
  "{:postgrex, \">= 0.0.0\"},\n      {:oban, \"~> 2.18\"},\n      {:oban_powertools, path: \"${WORKTREE_DIR}\"},\n      {:oban_web, \"~> 2.10\", optional: true},"

(
  cd "${GENERATED_DIR}"
  mix deps.get
  mix oban_powertools.install
)

rm -rf "${GENERATED_DIR}/priv/repo/migrations"
cp -R "${ARCHIVE_DIR}/priv/repo/migrations" "${GENERATED_DIR}/priv/repo/migrations"
cp "${ARCHIVE_DIR}/lib/phoenix_host_web/oban_powertools_auth.ex" \
  "${GENERATED_DIR}/lib/phoenix_host_web/oban_powertools_auth.ex"
cp "${ARCHIVE_DIR}/priv/repo/seeds.exs" "${GENERATED_DIR}/priv/repo/seeds.exs"

cat <<EOF

Regenerated historical source lane in: ${GENERATED_DIR}

Completed automatically:
- created a fresh Phoenix host
- pinned oban_powertools to commit ${SOURCE_COMMIT}
- ran mix oban_powertools.install from that historical commit
- restored the checked-in Powertools migration set
- restored the checked-in auth seam and narrow seed story

Next maintainer checks:
- diff ${GENERATED_DIR} against ${ARCHIVE_DIR}
- confirm config/config.exs still omits display_policy
- confirm /ops/jobs and /ops/jobs/oban still match the checked-in archived lane

EOF
