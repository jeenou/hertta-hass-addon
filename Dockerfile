ARG BUILD_FROM=debian:bookworm-slim

# --------------------------
# 1) Build Rust binaries
# --------------------------
FROM rust:1.86 AS rust_builder

RUN apt-get update && apt-get install -y \
    build-essential \
    ca-certificates \
    git \
    libssl-dev \
    libzmq3-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY Cargo.toml ./
COPY hertta/ hertta/
COPY hass-backend/ hass-backend/

RUN cargo build --release -p hertta -p hass-backend


# --------------------------
# 2) Build frontend
# --------------------------
FROM node:20-alpine AS frontend_builder

WORKDIR /frontend

COPY hertta-frontend/package*.json ./
RUN npm ci

COPY hertta-frontend/ ./
RUN npm run build


# --------------------------
# 3) Runtime image for Home Assistant and local Docker testing
# --------------------------
FROM ${BUILD_FROM}

RUN apt-get update && apt-get install -y \
    bash \
    ca-certificates \
    curl \
    jq \
    libssl3 \
    libzmq5 \
    python3 \
    python3-pip \
    tzdata \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

ARG JULIA_VERSION=1.10.3
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
        amd64) JULIA_ARCH_DIR=x64; JULIA_ARCH=x86_64 ;; \
        arm64) JULIA_ARCH_DIR=aarch64; JULIA_ARCH=aarch64 ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac \
    && JULIA_TARBALL="julia-${JULIA_VERSION}-linux-${JULIA_ARCH}.tar.gz" \
    && wget -q "https://julialang-s3.julialang.org/bin/linux/${JULIA_ARCH_DIR}/1.10/${JULIA_TARBALL}" \
    && tar -xzf "${JULIA_TARBALL}" -C /opt \
    && ln -s /opt/julia-${JULIA_VERSION}/bin/julia /usr/local/bin/julia \
    && rm "${JULIA_TARBALL}"

WORKDIR /usr/src/app

COPY --from=rust_builder /build/target/release/hertta /usr/local/bin/hertta
COPY --from=rust_builder /build/target/release/hass-backend /usr/local/bin/hass-backend

COPY hertta/ ./hertta/
COPY hass-backend/ ./hass-backend/
COPY --from=frontend_builder /frontend/build/ /web/

RUN pip3 install --break-system-packages --no-cache-dir \
    entsoe-py \
    fmiopendata \
    numpy \
    pandas

RUN julia --project=./hertta/predicer_wrapper -e 'using Pkg; Pkg.develop(path="./hertta/Predicer"); Pkg.instantiate(); Pkg.precompile()'

ENV XDG_CONFIG_HOME=/data/config \
    HERTTA_GRAPHQL_URL=http://localhost:3030/graphql \
    HASS_BASE_URL=http://supervisor/core/api \
    julia_exec=/usr/local/bin/julia \
    python_exec=/usr/bin/python3 \
    predicer_project=/usr/src/app/hertta/Predicer \
    predicer_runner_project=/usr/src/app/hertta/predicer_wrapper \
    predicer_runner_script=/usr/src/app/hertta/predicer_wrapper/Pr_ArrowConnection.jl \
    weather_fetcher_script=/usr/src/app/hertta/forecasts/weather_forecast.py \
    price_fetcher_script=/usr/src/app/hertta/forecasts/entsoe_forecast.py

COPY run.sh /run.sh
RUN chmod +x /run.sh && mkdir -p /data/config

VOLUME ["/data"]
EXPOSE 4001

CMD ["/run.sh"]
