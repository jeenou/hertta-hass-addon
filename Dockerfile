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
# 3) Runtime image for local Docker testing
# --------------------------
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    bash \
    ca-certificates \
    curl \
    libssl3 \
    libzmq5 \
    python3 \
    python3-pip \
    tzdata \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

ARG JULIA_VERSION=1.10.3
RUN wget -q https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-${JULIA_VERSION}-linux-x86_64.tar.gz \
    && tar -xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt \
    && ln -s /opt/julia-${JULIA_VERSION}/bin/julia /usr/local/bin/julia \
    && rm julia-${JULIA_VERSION}-linux-x86_64.tar.gz

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

RUN julia --project=./hertta/Predicer -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

ENV XDG_CONFIG_HOME=/data/config \
    HERTTA_GRAPHQL_URL=http://localhost:3030/graphql \
    HASS_BASE_URL=http://host.docker.internal:8123/api \
    julia_exec=/usr/local/bin/julia \
    python_exec=/usr/bin/python3 \
    predicer_project=/usr/src/app/hertta/Predicer \
    predicer_runner_script=/usr/src/app/hertta/predicer_wrapper/Pr_ArrowConnection.jl \
    weather_fetcher_script=/usr/src/app/hertta/forecasts/weather_forecast.py \
    price_fetcher_script=/usr/src/app/hertta/forecasts/entsoe_forecast.py

COPY run-local.sh /run.sh
RUN chmod +x /run.sh && mkdir -p /data/config

VOLUME ["/data"]
EXPOSE 4001

CMD ["/run.sh"]
