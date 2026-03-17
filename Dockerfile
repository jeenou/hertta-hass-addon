# --------------------------
# 1) Build Rust binaries
# --------------------------
    FROM rust:1.85 AS rust_builder

    RUN apt-get update && apt-get install -y \
        build-essential \
        pkg-config \
        libssl-dev \
        libzmq3-dev \
        git \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    WORKDIR /build
    
    # Root workspace manifest
    COPY Cargo.toml ./
    
    # Copy both Rust projects
    COPY hertta/ hertta/
    COPY hass-backend/ hass-backend/
    COPY hertta/Predicer/ ./Predicer/
    
    # Build both packages
    RUN cargo build --release -p hertta -p hass-backend
    
    
    # --------------------------
    # 2) Build frontend
    # --------------------------
    FROM node:20-alpine AS frontend_builder
    
    WORKDIR /frontend
    
    # Install dependencies first for better caching
    COPY hertta-frontend/package*.json ./
    RUN npm ci
    
    # Copy frontend source and build
    COPY hertta-frontend/ ./
    RUN npm run build
    
    
    # --------------------------
    # 3) Runtime image for local testing
    # --------------------------
    FROM debian:bookworm-slim
    
    RUN apt-get update && apt-get install -y \
        bash \
        ca-certificates \
        curl \
        wget \
        xz-utils \
        python3 \
        python3-pip \
        tzdata \
        libssl3 \
        libzmq5 \
        && rm -rf /var/lib/apt/lists/*
    
    # Install Julia matching Predicer manifest
    ARG JULIA_VERSION=1.10.3
    RUN wget -q https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-${JULIA_VERSION}-linux-x86_64.tar.gz \
        && tar -xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt \
        && ln -s /opt/julia-${JULIA_VERSION}/bin/julia /usr/local/bin/julia \
        && rm julia-${JULIA_VERSION}-linux-x86_64.tar.gz
    
    WORKDIR /usr/src/app
    
    # Rust binaries
    COPY --from=rust_builder /build/target/release/hertta /usr/local/bin/hertta
    COPY --from=rust_builder /build/target/release/hass-backend /usr/local/bin/hass-backend
    
    # Runtime files
    COPY hertta/ ./hertta/
    COPY hass-backend/ ./hass-backend/
    
    # Built frontend
    COPY --from=frontend_builder /frontend/build/ /web/
    
    # Optional Python deps
    RUN if [ -f ./hertta/requirements.txt ]; then \
          pip3 install --break-system-packages --no-cache-dir -r ./hertta/requirements.txt; \
        fi
    
    # Install Julia deps for Predicer
    RUN if [ -f ./Predicer/Project.toml ]; then \
        julia --project=./Predicer -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'; \
        fi
    
    COPY run-local.sh /run.sh
    RUN chmod +x /run.sh
    
    EXPOSE 3030 4001
    
    CMD ["/run.sh"]