#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST_DIR="${ROOT_DIR}/examples/phoenix_host"
mkdir -p "${HOST_DIR}/_build"
BUILD_PATH="$(mktemp -d "${HOST_DIR}/_build/phase79_fixture_toggle.XXXXXX")"

if [[ ! "${BUILD_PATH}" =~ /examples/phoenix_host/_build/phase79_fixture_toggle\.[A-Za-z0-9]+$ ]]; then
  echo "refusing unresolved Phase 79 fixture-toggle build path" >&2
  exit 64
fi

cleanup() {
  rm -rf -- "${BUILD_PATH}"
}

trap cleanup EXIT INT TERM

cd "${HOST_DIR}"
mix deps.get

env \
  MIX_ENV=test \
  MIX_BUILD_PATH="${BUILD_PATH}" \
  PHASE79_BROWSER_FIXTURES=1 \
  mix compile --force --warnings-as-errors

env \
  MIX_ENV=test \
  MIX_BUILD_PATH="${BUILD_PATH}" \
  PHASE79_BROWSER_FIXTURES=1 \
  mix run --no-start --no-compile -e \
  'unless Code.ensure_loaded?(PhoenixHostWeb.Phase79BrowserFixturesController), do: System.halt(1)'

env -u PHASE79_BROWSER_FIXTURES \
  MIX_ENV=test \
  MIX_BUILD_PATH="${BUILD_PATH}" \
  mix compile --warnings-as-errors

env -u PHASE79_BROWSER_FIXTURES \
  MIX_ENV=test \
  MIX_BUILD_PATH="${BUILD_PATH}" \
  mix run --no-start --no-compile -e \
  'if Code.ensure_loaded?(PhoenixHostWeb.Phase79BrowserFixturesController), do: System.halt(1)'

env \
  MIX_ENV=test \
  MIX_BUILD_PATH="${BUILD_PATH}" \
  PHASE79_BROWSER_FIXTURES=1 \
  mix compile --warnings-as-errors

env \
  MIX_ENV=test \
  MIX_BUILD_PATH="${BUILD_PATH}" \
  PHASE79_BROWSER_FIXTURES=1 \
  mix run --no-start --no-compile -e \
  'unless Code.ensure_loaded?(PhoenixHostWeb.Phase79BrowserFixturesController), do: System.halt(1)'
