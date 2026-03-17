#!/bin/bash
set -euo pipefail

export RUST_LOG="${RUST_LOG:-info}"

# Adjust these only if your app expects them
export HERTTA_GRAPHQL_URL="${HERTTA_GRAPHQL_URL:-http://localhost:3030/graphql}"

echo "Starting hertta..."
echo "RUST_LOG=$RUST_LOG"
echo "Julia: $(julia --version)"

cd /usr/src/app

exec /usr/local/bin/hertta