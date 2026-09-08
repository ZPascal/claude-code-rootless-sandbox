# Claude Code Rootless Sandbox - Minimal Base Image
# Designed for rootless container execution with security-hardened defaults

FROM ubuntu:24.04

LABEL maintainer="Claude Code Sandbox Project"
LABEL description="Rootless sandbox for Claude Code"
LABEL version="1.0"

# Set non-interactive environment
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Install minimal dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    wget \
    bash \
    coreutils \
    findutils \
    grep \
    sed \
    tar \
    gzip \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user (optional, if needed)
# By default, we run as whatever UID is mapped from the host
ARG UID=1000
ARG GID=1000

# Ensure /tmp exists and is writable
RUN mkdir -p /tmp && chmod 1777 /tmp

# Set working directory
WORKDIR /project

# Health check (simple check that container is running)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD exit 0 || exit 1

# Default entrypoint: bash
ENTRYPOINT ["/bin/bash"]
CMD ["-i"]
