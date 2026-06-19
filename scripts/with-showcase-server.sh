#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST_DIR="${ROOT_DIR}/examples/phoenix_host"
PORT="${PLAYWRIGHT_SHOWCASE_PORT:-42073}"
HOST_BASE_URL="http://127.0.0.1:${PORT}"
SHOWCASE_URL="${HOST_BASE_URL}/ops/jobs/_showcase"
SERVER_LOG="${ROOT_DIR}/test-results/showcase-server.log"
SERVER_PID=""

if [ "$#" -eq 0 ]; then
  echo "usage: scripts/with-showcase-server.sh <command> [args...]" >&2
  exit 64
fi

if [ "$(uname -s)" = "Darwin" ]; then
  DOCKER_BASE_URL="http://host.docker.internal:${PORT}"
else
  DOCKER_BASE_URL="${HOST_BASE_URL}"
fi

cleanup() {
  if [ -n "${SERVER_PID}" ] && kill -0 "${SERVER_PID}" 2>/dev/null; then
    kill "${SERVER_PID}" 2>/dev/null || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

mkdir -p "$(dirname "${SERVER_LOG}")"

(
  cd "${HOST_DIR}"
  mix deps.get --quiet
  mix ecto.create --quiet || true
  mix ecto.migrate --quiet
)

(
  cd "${HOST_DIR}"
  MIX_ENV=dev PORT="${PORT}" PHX_SERVER=true mix phx.server >"${SERVER_LOG}" 2>&1
) &
SERVER_PID="$!"

SHOWCASE_URL="${SHOWCASE_URL}" node <<'NODE'
const url = process.env.SHOWCASE_URL;
const deadline = Date.now() + 60000;

async function wait() {
  while (Date.now() < deadline) {
    try {
      const response = await fetch(url);
      if (response.ok) process.exit(0);
    } catch (_error) {
    }

    await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  console.error(`Timed out waiting for ${url}`);
  process.exit(1);
}

wait();
NODE

PLAYWRIGHT_TEST_BASE_URL="${HOST_BASE_URL}" \
PLAYWRIGHT_DOCKER_BASE_URL="${DOCKER_BASE_URL}" \
"$@"
