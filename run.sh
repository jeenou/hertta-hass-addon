#!/bin/bash
set -euo pipefail

OPTIONS_FILE=/data/options.json
LOG_LEVEL="${RUST_LOG:-info}"
if [[ -f "${OPTIONS_FILE}" ]]; then
  LOG_LEVEL="$(jq -r '.log_level // "info"' "${OPTIONS_FILE}")"
fi

export RUST_LOG="${LOG_LEVEL}"
export HASS_BASE_URL="${HASS_BASE_URL:-http://supervisor/core/api}"
if [[ -z "${HASS_TOKEN:-}" ]]; then
  export HASS_TOKEN="${SUPERVISOR_TOKEN:?Set HASS_TOKEN locally or enable homeassistant_api for the add-on}"
fi
export HERTTA_GRAPHQL_URL="http://localhost:3030/graphql"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/data/config}"

echo "[Hertta] Starting add-on (log level: ${LOG_LEVEL})"
echo "[Hertta] Starting GraphQL backend on 0.0.0.0:3030"
hertta &
HERTTA_PID=$!

echo "[Hertta] Starting Home Assistant backend and UI on 0.0.0.0:4001"
hass-backend &
HASS_PID=$!

PIDS=("${HERTTA_PID}" "${HASS_PID}")

term_handler() {
  echo "[Hertta] Stopping add-on processes"

  for pid in "${PIDS[@]}"; do
    if kill -0 "${pid}" 2>/dev/null; then
      kill -TERM "${pid}" 2>/dev/null || true
    fi
  done

  sleep 3

  for pid in "${PIDS[@]}"; do
    if kill -0 "${pid}" 2>/dev/null; then
      echo "[Hertta] Process ${pid} did not exit; killing"
      kill -KILL "${pid}" 2>/dev/null || true
    fi
  done
}

trap term_handler SIGTERM SIGINT

wait -n || true
echo "[Hertta] One of the processes exited; shutting down"
term_handler
wait || true
echo "[Hertta] Add-on stopped"
