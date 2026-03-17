#!/bin/bash
set -euo pipefail

export RUST_LOG="${RUST_LOG:-info}"
export HERTTA_GRAPHQL_URL="${HERTTA_GRAPHQL_URL:-http://localhost:3030/graphql}"
export HASS_BASE_URL="${HASS_BASE_URL:-http://localhost:8123/api}"
export HASS_TOKEN="${HASS_TOKEN:-dummy-token}"

echo "Starting services..."
echo "RUST_LOG=$RUST_LOG"
echo "HERTTA_GRAPHQL_URL=$HERTTA_GRAPHQL_URL"
echo "HASS_BASE_URL=$HASS_BASE_URL"
echo "Julia: $(julia --version)"

cd /usr/src/app

/usr/local/bin/hertta &
HERTTA_PID=$!

/usr/local/bin/hass-backend &
HASS_PID=$!

term_handler() {
  echo "Stopping services..."

  kill -TERM "$HERTTA_PID" 2>/dev/null || true
  kill -TERM "$HASS_PID" 2>/dev/null || true

  wait "$HERTTA_PID" 2>/dev/null || true
  wait "$HASS_PID" 2>/dev/null || true
}

trap term_handler SIGTERM SIGINT

wait -n
term_handler