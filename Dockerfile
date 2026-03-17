# --------------------------
# 1) Build hertta (Rust)
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
    
    # Copy the whole hertta project so path deps like hertta_derive are available
    COPY hertta/ hertta/
    
    # Build only the hertta package
    RUN cargo build --release -p hertta
    
    
    # --------------------------
    # 2) Runtime image for local testing
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
    
    # Install Julia matching your Manifest as closely as practical
    ARG JULIA_VERSION=1.10.3
    RUN wget -q https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-${JULIA_VERSION}-linux-x86_64.tar.gz \
        && tar -xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt \
        && ln -s /opt/julia-${JULIA_VERSION}/bin/julia /usr/local/bin/julia \
        && rm julia-${JULIA_VERSION}-linux-x86_64.tar.gz
    
    WORKDIR /usr/src/app
    
    # Rust binary
    COPY --from=rust_builder /build/target/release/hertta /usr/local/bin/hertta
    
    # Runtime files hertta may need
    COPY hertta/ ./hertta/
    
    # Optional Python deps if you actually use them
    RUN if [ -f ./hertta/requirements.txt ]; then \
          pip3 install --break-system-packages --no-cache-dir -r ./hertta/requirements.txt; \
        fi
    
    # Install Julia deps for Predicer
    RUN if [ -f ./hertta/Predicer/Project.toml ]; then \
          julia --project=./hertta/Predicer -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'; \
        fi
    
    COPY run-local.sh /run.sh
    RUN chmod +x /run.sh
    
    EXPOSE 3030
    
    CMD ["/run.sh"]