#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST_DIR="${ROOT_DIR}/examples/phoenix_host"
PORT="${PLAYWRIGHT_SHOWCASE_PORT:-}"

if [ -z "${PORT}" ]; then
  PORT="$(
    node -e '
      const net = require("node:net");
      const server = net.createServer();
      server.listen(0, "127.0.0.1", () => {
        process.stdout.write(String(server.address().port));
        server.close();
      });
    '
  )"
fi

HOST_BASE_URL="http://127.0.0.1:${PORT}"
SHOWCASE_URL="${HOST_BASE_URL}/ops/jobs/_showcase"
SERVER_LOG="$(mktemp "${TMPDIR:-/tmp}/oban-powertools-showcase-${PORT}-XXXXXX")"
SERVER_PID=""
COMMAND_PID=""
DATABASE_CREATED=0
POSTGRES_HOST="${PGHOST:-localhost}"
POSTGRES_PORT="${PGPORT:-5432}"
POSTGRES_USER="${PGUSER:-postgres}"
POSTGRES_PASSWORD="${PGPASSWORD:-postgres}"

case "${PORT}" in
  ''|*[!0-9]*)
    echo "PLAYWRIGHT_SHOWCASE_PORT must contain only digits" >&2
    exit 64
    ;;
esac

MIX_TEST_PARTITION="_phase79_${PORT}_$$"
PHASE79_BUILD_PATH="${HOST_DIR}/_build/phase79_${PORT}_$$"

if [[ ! "${MIX_TEST_PARTITION}" =~ ^_phase79_[0-9]+_[0-9]+$ ]]; then
  echo "refusing unresolved Phase 79 test database partition" >&2
  exit 64
fi

if [[ ! "${PHASE79_BUILD_PATH}" =~ /examples/phoenix_host/_build/phase79_[0-9]+_[0-9]+$ ]]; then
  echo "refusing unresolved Phase 79 build path" >&2
  exit 64
fi

DATABASE_NAME="phoenix_host_test${MIX_TEST_PARTITION}"

if [[ ! "${DATABASE_NAME}" =~ ^phoenix_host_test_phase79_[0-9]+_[0-9]+$ ]]; then
  echo "refusing unresolved Phase 79 test database name" >&2
  exit 64
fi

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
  local exit_status=$?
  local drop_status=0

  trap - EXIT INT TERM

  if [ -n "${COMMAND_PID}" ] && kill -0 "${COMMAND_PID}" 2>/dev/null; then
    kill "${COMMAND_PID}" 2>/dev/null || true
    wait "${COMMAND_PID}" 2>/dev/null || true
  fi

  if [ -n "${SERVER_PID}" ] && kill -0 "${SERVER_PID}" 2>/dev/null; then
    kill "${SERVER_PID}" 2>/dev/null || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi

  if [ "${DATABASE_CREATED}" -eq 1 ]; then
    PGPASSWORD="${POSTGRES_PASSWORD}" dropdb \
      --if-exists \
      --host="${POSTGRES_HOST}" \
      --port="${POSTGRES_PORT}" \
      --username="${POSTGRES_USER}" \
      "${DATABASE_NAME}" || drop_status=$?
  fi

  rm -rf -- "${PHASE79_BUILD_PATH}" 2>/dev/null || {
    sleep 1
    rm -rf -- "${PHASE79_BUILD_PATH}"
  }

  if [ "${exit_status}" -eq 0 ] && [ "${drop_status}" -ne 0 ]; then
    exit_status="${drop_status}"
  fi

  if [ "${exit_status}" -eq 0 ]; then
    rm -f -- "${SERVER_LOG}"
  else
    echo "showcase server log retained at ${SERVER_LOG}" >&2
  fi

  exit "${exit_status}"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

(
  cd "${HOST_DIR}"
  env \
    MIX_ENV=test \
    MIX_BUILD_PATH="${PHASE79_BUILD_PATH}" \
    MIX_TEST_PARTITION="${MIX_TEST_PARTITION}" \
    PHASE79_BROWSER_FIXTURES=1 \
    PHASE80_BROWSER_FIXTURES=1 \
    PHASE81_BROWSER_FIXTURES=1 \
    mix deps.get --quiet
  env \
    MIX_ENV=test \
    MIX_BUILD_PATH="${PHASE79_BUILD_PATH}" \
    MIX_TEST_PARTITION="${MIX_TEST_PARTITION}" \
    PHASE79_BROWSER_FIXTURES=1 \
    PHASE80_BROWSER_FIXTURES=1 \
    PHASE81_BROWSER_FIXTURES=1 \
    mix ecto.create --quiet
)
DATABASE_CREATED=1

(
  cd "${HOST_DIR}"
  env \
    MIX_ENV=test \
    MIX_BUILD_PATH="${PHASE79_BUILD_PATH}" \
    MIX_TEST_PARTITION="${MIX_TEST_PARTITION}" \
    PHASE79_BROWSER_FIXTURES=1 \
    PHASE80_BROWSER_FIXTURES=1 \
    PHASE81_BROWSER_FIXTURES=1 \
    mix ecto.migrate --quiet
)

PHASE79_BROWSER_FIXTURE_SECRET="$(openssl rand -hex 32)"
PHASE80_BROWSER_FIXTURE_SECRET="$(openssl rand -hex 32)"
PHASE81_BROWSER_FIXTURE_SECRET="$(openssl rand -hex 32)"

if [ -z "${PHASE79_BROWSER_FIXTURE_SECRET}" ]; then
  echo "failed to generate the Phase 79 browser fixture credential" >&2
  exit 1
fi

if [ -z "${PHASE80_BROWSER_FIXTURE_SECRET}" ]; then
  echo "failed to generate the Phase 80 browser fixture credential" >&2
  exit 1
fi

if [ -z "${PHASE81_BROWSER_FIXTURE_SECRET}" ]; then
  echo "failed to generate the Phase 81 browser fixture credential" >&2
  exit 1
fi

(
  cd "${HOST_DIR}"
  exec env \
    MIX_ENV=test \
    MIX_BUILD_PATH="${PHASE79_BUILD_PATH}" \
    MIX_TEST_PARTITION="${MIX_TEST_PARTITION}" \
    PHASE79_BROWSER_FIXTURES=1 \
    PHASE79_BROWSER_FIXTURE_SECRET="${PHASE79_BROWSER_FIXTURE_SECRET}" \
    PHASE80_BROWSER_FIXTURES=1 \
    PHASE80_BROWSER_FIXTURE_SECRET="${PHASE80_BROWSER_FIXTURE_SECRET}" \
    PHASE81_BROWSER_FIXTURES=1 \
    PHASE81_BROWSER_FIXTURE_SECRET="${PHASE81_BROWSER_FIXTURE_SECRET}" \
    PORT="${PORT}" \
    PHX_SERVER=true \
    mix phx.server >"${SERVER_LOG}" 2>&1
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
PHASE79_BROWSER_FIXTURE_SECRET="${PHASE79_BROWSER_FIXTURE_SECRET}" \
PHASE80_BROWSER_FIXTURE_SECRET="${PHASE80_BROWSER_FIXTURE_SECRET}" \
PHASE81_BROWSER_FIXTURE_SECRET="${PHASE81_BROWSER_FIXTURE_SECRET}" \
"$@" &
COMMAND_PID="$!"

while kill -0 "${COMMAND_PID}" 2>/dev/null; do
  if ! kill -0 "${SERVER_PID}" 2>/dev/null; then
    if wait "${SERVER_PID}"; then
      server_status=0
    else
      server_status=$?
    fi

    echo "showcase server exited unexpectedly with status ${server_status}" >&2
    echo "showcase server exited unexpectedly with status ${server_status}" >>"${SERVER_LOG}"
    tail -n 200 "${SERVER_LOG}" | sed -E 's/[[:xdigit:]]{64}/[REDACTED]/g' >&2
    kill "${COMMAND_PID}" 2>/dev/null || true
    wait "${COMMAND_PID}" 2>/dev/null || true
    COMMAND_PID=""

    if [ "${server_status}" -eq 0 ]; then
      exit 1
    fi

    exit "${server_status}"
  fi

  sleep 1
done

if wait "${COMMAND_PID}"; then
  command_status=0
else
  command_status=$?
fi
COMMAND_PID=""
exit "${command_status}"
