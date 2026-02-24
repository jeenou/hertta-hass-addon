#!/usr/bin/with-contenv bashio
set -euo pipefail

LOG_LEVEL=$(bashio::config 'log_level')
bashio::log.info "Starting Hertta add-on (log level: ${LOG_LEVEL})"

export RUST_LOG="${LOG_LEVEL}"

# Home Assistant Core API base inside an add-on container
export HASS_BASE_URL="http://supervisor/core/api"

# Supervisor injects this token when homeassistant_api: true
export HASS_TOKEN="${SUPERVISOR_TOKEN}"

# Internal URL between processes in the same container
export HERTTA_GRAPHQL_URL="http://localhost:3030/graphql"

bashio::log.info "Starting Hertta GraphQL backend on 0.0.0.0:3030..."
hertta &
HERTTA_PID=$!

bashio::log.info "Starting Hass backend on 0.0.0.0:4001..."
hass-backend &
HASS_PID=$!

PIDS=("${HERTTA_PID}" "${HASS_PID}")

term_handler() {
  bashio::log.info "Stopping Hertta add-on processes..."

  # Graceful stop
  for pid in "${PIDS[@]}"; do
    if kill -0 "${pid}" 2>/dev/null; then
      kill -TERM "${pid}" 2>/dev/null || true
    fi
  done

  # Give them a moment to exit
  sleep 3

  # Hard kill if still running
  for pid in "${PIDS[@]}"; do
    if kill -0 "${pid}" 2>/dev/null; then
      bashio::log.warning "Process ${pid} did not exit; killing..."
      kill -KILL "${pid}" 2>/dev/null || true
    fi
  done
}

trap term_handler SIGTERM SIGINT

wait -n || true
bashio::log.warning "One of the processes exited; shutting down..."
term_handler
wait || true
bashio::log.info "Hertta add-on stopped."