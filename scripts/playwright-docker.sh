#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="mcr.microsoft.com/playwright:v1.61.0-noble"

if [ "$#" -eq 0 ]; then
  set -- npx playwright test
fi

NETWORK_ARGS=()
if [ "$(uname -s)" = "Linux" ]; then
  NETWORK_ARGS=(--network host --add-host=host.docker.internal:host-gateway)
fi

CONTAINER_BASE_URL="${PLAYWRIGHT_DOCKER_BASE_URL:-${PLAYWRIGHT_TEST_BASE_URL:-http://127.0.0.1:4000}}"

docker run \
  --rm \
  --init \
  --ipc=host \
  "${NETWORK_ARGS[@]}" \
  -e CI="${CI:-}" \
  -e HOME=/tmp \
  -e NPM_CONFIG_CACHE=/tmp/.npm \
  -e PLAYWRIGHT_TEST_BASE_URL="${CONTAINER_BASE_URL}" \
  -v "${ROOT_DIR}:/work" \
  -w /work \
  "${IMAGE}" \
  "$@"
