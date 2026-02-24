# --------------------------
# 1) Build Rust binaries
# --------------------------
    ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:latest

    FROM rust:1.76-alpine AS rust_builder

RUN apk add --no-cache \
    build-base \
    musl-dev \
    pkgconfig \
    openssl-dev \
    git

WORKDIR /build

# Copy the whole repo (you have a .dockerignore now, so this is fine)
COPY . .

# Build only the binaries you need (workspace packages)
RUN cargo build --release -p hass-backend -p hertta

# ------------------------------------------------
# 2) Build frontend (CRA)
# ------------------------------------------------
FROM node:20-alpine AS frontend_builder

WORKDIR /frontend

# Install deps first (better caching)
COPY hertta-frontend/package*.json ./
RUN npm ci

# Copy frontend sources and build
COPY hertta-frontend/ ./
RUN npm run build
# Output: /frontend/build

# --------------------------
# 2) Final Home Assistant image
# --------------------------

FROM $BUILD_FROM

USER root

RUN apk add --no-cache \
    ca-certificates \
    python3 \
    py3-pip \
    bash \
    tzdata

WORKDIR /usr/src/app

# Rust binaries from builder stage
COPY --from=rust_builder /build/target/release/hass-backend /usr/local/bin/hass-backend
COPY --from=rust_builder /build/target/release/hertta /usr/local/bin/hertta

# Optional python folder (you already had this)
COPY hertta ./hertta
RUN if [ -f ./hertta/requirements.txt ]; then \
      pip3 install --no-cache-dir -r ./hertta/requirements.txt; \
    fi

# Frontend build → /web
COPY --from=frontend_builder /frontend/build/ /web/

COPY run.sh /run.sh
RUN chmod a+x /run.sh

EXPOSE 4001
CMD ["/run.sh"]