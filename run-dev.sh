#!/bin/bash
set -euo pipefail

cd /usr/src/app
mkdir -p "${XDG_CONFIG_HOME:-/data/config}"

case "${DEV_SERVICE:-}" in
  hertta)
    if [ -f hertta/predicer_wrapper/Project.toml ]; then
      julia_env_hash="$(sha256sum hertta/predicer_wrapper/Project.toml hertta/Predicer/Project.toml | sha256sum | cut -d ' ' -f1)"
      julia_env_marker="/data/julia/.predicer-runner-project-hash"
      if [ ! -f "${julia_env_marker}" ] || [ "$(cat "${julia_env_marker}")" != "${julia_env_hash}" ]; then
        echo "Preparing Julia Predicer runner environment..."
        julia --project=./hertta/predicer_wrapper -e 'using Pkg; Pkg.develop(path="./hertta/Predicer"); Pkg.instantiate(); Pkg.precompile()'
        echo "${julia_env_hash}" > "${julia_env_marker}"
      fi
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
