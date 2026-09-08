#!/usr/bin/env bash
# Launches Claude Code in an isolated, rootless container sandbox.
# Only the specified project directory is mounted into the container.
#
# Usage:
#   ./run-claude-sandbox.sh [PROJECT_DIR]
#
# Examples:
#   ./run-claude-sandbox.sh              # current directory
#   ./run-claude-sandbox.sh ~/my-project # different project
#
# Environment variables (see config-defaults.env):
#   SANDBOX_IMAGE_NAME          Name of the container image
#   SANDBOX_BASE_IMAGE          Base image to use
#   SANDBOX_NETWORK             Network mode (host, none, etc.)
#   SANDBOX_READONLY            Mount project as read-only (true/false)
#   SANDBOX_CPUS                CPU limit
#   SANDBOX_MEMORY              Memory limit
#   SANDBOX_AUDIT_LOG           Enable audit logging (true/false)
#   SANDBOX_ENV_EXTRA           Additional environment variables

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "${PROJECT_DIR}" && pwd)"

# Load default configuration
if [[ -f "${SCRIPT_DIR}/config-defaults.env" ]]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/config-defaults.env"
fi

# Image configuration
SANDBOX_IMAGE_NAME="${SANDBOX_IMAGE_NAME:-claude-code-sandbox}"
SANDBOX_BASE_IMAGE="${SANDBOX_BASE_IMAGE:-ubuntu:24.04}"
RUNTIME="${RUNTIME:-}"

# Container settings
SANDBOX_NETWORK="${SANDBOX_NETWORK:-host}"
SANDBOX_READONLY="${SANDBOX_READONLY:-false}"
SANDBOX_CPUS="${SANDBOX_CPUS:-}"
SANDBOX_MEMORY="${SANDBOX_MEMORY:-}"
SANDBOX_AUDIT_LOG="${SANDBOX_AUDIT_LOG:-false}"
SANDBOX_ENV_EXTRA="${SANDBOX_ENV_EXTRA:-}"

# Detect container runtime (prefer podman)
if [[ -z "${RUNTIME}" ]]; then
    if command -v podman &>/dev/null; then
        RUNTIME="podman"
    elif command -v docker &>/dev/null; then
        RUNTIME="docker"
    else
        echo "Error: Neither podman nor docker found. Please install one." >&2
        exit 1
    fi
fi

echo "==> Container Runtime: ${RUNTIME}"
echo "==> Project Directory: ${PROJECT_DIR}"
echo "==> Image Name: ${SANDBOX_IMAGE_NAME}"

# Build image if it doesn't exist
if ! ${RUNTIME} image inspect "${SANDBOX_IMAGE_NAME}:latest" &>/dev/null; then
    echo "==> Building sandbox image (one-time setup)..."
    ${RUNTIME} build \
        --build-arg BASE_IMAGE="${SANDBOX_BASE_IMAGE}" \
        -t "${SANDBOX_IMAGE_NAME}:latest" \
        -f "${SCRIPT_DIR}/Dockerfile" \
        "${SCRIPT_DIR}"
    echo "==> Image built successfully"
fi

# Build run arguments
RUN_ARGS=(
    "run"
    "--rm"
    "-it"
    # Security options
    "--cap-drop=ALL"
    "--security-opt=no-new-privileges"
    # Network
    "--network=${SANDBOX_NETWORK}"
    # Memory management
    "--tmpfs=/tmp:rw,size=256m"
)

# Add CPU limit if specified
if [[ -n "${SANDBOX_CPUS}" ]]; then
    RUN_ARGS+=("--cpus=${SANDBOX_CPUS}")
fi

# Add memory limit if specified
if [[ -n "${SANDBOX_MEMORY}" ]]; then
    RUN_ARGS+=("--memory=${SANDBOX_MEMORY}")
fi

# Mount project directory
MOUNT_OPTS="Z"
if [[ "${SANDBOX_READONLY}" == "true" ]]; then
    MOUNT_OPTS="Z,ro"
fi
RUN_ARGS+=("-v" "${PROJECT_DIR}:/project:${MOUNT_OPTS}")

# Set working directory
RUN_ARGS+=("-w" "/project")

# Add user namespace mapping
if [[ "${RUNTIME}" == "podman" ]]; then
    RUN_ARGS+=("--userns=keep-id")
else
    RUN_ARGS+=("--user" "$(id -u):$(id -g)")
fi

# Add extra environment variables if specified
if [[ -n "${SANDBOX_ENV_EXTRA}" ]]; then
    RUN_ARGS+=("-e" "${SANDBOX_ENV_EXTRA}")
fi

# Run container
if [[ "${SANDBOX_AUDIT_LOG}" == "true" ]]; then
    echo "==> Audit logging enabled"
fi

echo "==> Starting sandbox..."
exec ${RUNTIME} "${RUN_ARGS[@]}" "${SANDBOX_IMAGE_NAME}:latest"
