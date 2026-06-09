#!/bin/bash
set -euo pipefail

cd /usr/src/app
mkdir -p "${XDG_CONFIG_HOME:-/data/config}"

case "${DEV_SERVICE:-}" in
  hertta)
    if [ -f hertta/Predicer/Project.toml ] && [ ! -f /data/julia/.hertta-pkg-ready ]; then
      echo "Installing Julia dependencies..."
      julia --project=./hertta/Predicer -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
      touch /data/julia/.hertta-pkg-ready
    fi

    exec cargo watch --poll \
      -w hertta/src \
      -w hertta/hertta_derive \
      -w hertta/Cargo.toml \
      -w hertta/Cargo.lock \
      -w Cargo.toml \
      -w Cargo.lock \
      -x "run -p hertta"
    ;;

  hass-backend)
    exec cargo watch --poll -w hass-backend -w Cargo.toml -x "run -p hass-backend"
    ;;

  *)
    echo "Set DEV_SERVICE to hertta or hass-backend."
    exit 1
    ;;
esac
