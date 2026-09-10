#!/usr/bin/env bash
# Launches Claude Code in an isolated, rootless container sandbox.
# Only the specified project directory is mounted into the container.
#
# Usage:
#   ./run-claude-sandbox.sh [PROJECT_DIR] [CONTAINER_ARGS...]
#
# The first argument that does not start with "-" is the project directory.
# Any remaining arguments are passed through to the container command
# (the image entrypoint), e.g. `./run-claude-sandbox.sh --help`.
#
# Examples:
#   ./run-claude-sandbox.sh              # current directory
#   ./run-claude-sandbox.sh ~/my-project # different project
#
# Image source:
#   By default the sandbox image is pulled from the container registry
#   (ghcr.io/zpascal/claude-code-sandbox). Set CLAUDE_REBUILD_IMAGES=1 (or
#   `skills.docker-sandbox.rebuild: true` in project/global settings.json) to
#   build the image locally from the Dockerfile in this directory instead.
#   If the registry pull fails, the script falls back to a local image or a
#   local build automatically.
#
#   The rebuild setting is resolved as a precedence chain — the first level
#   that defines a value wins, true or false:
#     1. CLAUDE_REBUILD_IMAGES environment variable
#     2. <project>/.claude/settings.local.json, then settings.json
#     3. ${CLAUDE_HOME:-$HOME/.claude}/settings.json
#     4. default: false (pull from registry)
#
# Environment variables (see config-defaults.env):
#   SANDBOX_IMAGE_NAME          Name of the local container image
#   SANDBOX_BASE_IMAGE          Base image to use
#   SANDBOX_NETWORK             Network mode (host, none, etc.)
#   SANDBOX_READONLY            Mount project as read-only (true/false)
#   SANDBOX_CPUS                CPU limit
#   SANDBOX_MEMORY              Memory limit
#   SANDBOX_AUDIT_LOG           Enable audit logging (true/false)
#   SANDBOX_ENV_EXTRA           Additional environment variables
#   SANDBOX_EXTENDED            Use the extended image/Dockerfile (true/false)
#   SANDBOX_REGISTRY_IMAGE      Registry image repository to pull
#   SANDBOX_REGISTRY_TAG        Registry tag to pull (default: latest)
#   CLAUDE_REBUILD_IMAGES       1 = build locally, 0 = pull (overrides settings)
#   SANDBOX_DRY_RUN             true = print the run command, do not execute

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments: first non-flag argument is the project directory,
# everything else is forwarded to the container command.
PROJECT_DIR_ARG=""
CONTAINER_ARGS=()
for arg in "$@"; do
    if [[ -z "${PROJECT_DIR_ARG}" && "${arg}" != -* ]]; then
        PROJECT_DIR_ARG="${arg}"
    else
        CONTAINER_ARGS+=("${arg}")
    fi
done

PROJECT_DIR="${PROJECT_DIR_ARG:-.}"
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
SANDBOX_DRY_RUN="${SANDBOX_DRY_RUN:-false}"

# Image source settings
SANDBOX_EXTENDED="${SANDBOX_EXTENDED:-false}"
SANDBOX_REGISTRY_IMAGE="${SANDBOX_REGISTRY_IMAGE:-ghcr.io/zpascal/claude-code-sandbox}"
SANDBOX_REGISTRY_TAG="${SANDBOX_REGISTRY_TAG:-latest}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-${SCRIPT_DIR}/Dockerfile}"
DOCKERFILE_EXTENDED="${DOCKERFILE_EXTENDED:-${SCRIPT_DIR}/Dockerfile.extended}"
CLAUDE_REBUILD_IMAGES="${CLAUDE_REBUILD_IMAGES:-}"

# Prints the boolean value of skills.docker-sandbox.rebuild from the given
# settings.json and returns 0. Returns 1 (printing nothing) when the file is
# missing, unreadable, unparseable, or the key is absent / not a boolean, so
# that the caller can fall through to the next configuration level.
settings_rebuild_value() {
    local file="$1"
    local value
    [[ -f "${file}" ]] || return 1

    if command -v jq &>/dev/null; then
        value="$(jq -r '
            (.skills["docker-sandbox"] // empty) as $s
            | if ($s | type) == "object" and ($s | has("rebuild")) and (($s.rebuild | type) == "boolean")
              then ($s.rebuild | tostring)
              else "absent"
              end' "${file}" 2>/dev/null)" || return 1
    elif command -v python3 &>/dev/null; then
        value="$(python3 -c '
import json, sys
try:
    with open(sys.argv[1]) as fh:
        data = json.load(fh)
except Exception:
    print("absent")
    sys.exit(0)
skills = data.get("skills") if isinstance(data, dict) else None
entry = skills.get("docker-sandbox") if isinstance(skills, dict) else None
rebuild = entry.get("rebuild") if isinstance(entry, dict) else None
print("true" if rebuild is True else "false" if rebuild is False else "absent")
' "${file}" 2>/dev/null)" || return 1
    else
        # Fallback: whitespace-insensitive scan of the flattened JSON
        local flat
        flat="$(tr -d ' \t\n\r' < "${file}")" || return 1
        if grep -q '"docker-sandbox":{[^}]*"rebuild":true' <<<"${flat}"; then
            value="true"
        elif grep -q '"docker-sandbox":{[^}]*"rebuild":false' <<<"${flat}"; then
            value="false"
        else
            value="absent"
        fi
    fi

    case "${value}" in
        true|false)
            echo "${value}"
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Read rebuild configuration from env, project settings, and global settings.
# This is a precedence chain, not an OR: the first level that actually defines
# a value wins, whether that value is true or false. A level is only skipped
# when it does not define the setting at all.
get_rebuild_setting() {
    local value

    # Priority 1: Environment variable (authoritative when set)
    case "${CLAUDE_REBUILD_IMAGES}" in
        1|true|TRUE|True|yes|on)
            echo "true"
            return
            ;;
        0|false|FALSE|False|no|off)
            echo "false"
            return
            ;;
        "")
            : # unset/empty -> fall through to settings files
            ;;
        *)
            echo "WARNING: ignoring unrecognized CLAUDE_REBUILD_IMAGES='${CLAUDE_REBUILD_IMAGES}' (expected 0 or 1)" >&2
            ;;
    esac

    # Priority 2: Project settings (.claude/settings.json)
    local project_settings
    for project_settings in \
        "${PROJECT_DIR}/.claude/settings.local.json" \
        "${PROJECT_DIR}/.claude/settings.json"; do
        if value="$(settings_rebuild_value "${project_settings}")"; then
            echo "${value}"
            return
        fi
    done

    # Priority 3: Global user settings (check common locations)
    local global_settings=""
    if [[ -n "${CLAUDE_HOME:-}" ]]; then
        global_settings="${CLAUDE_HOME}/settings.json"
    elif [[ -d "${HOME:-}/.claude" ]]; then
        global_settings="${HOME}/.claude/settings.json"
    fi

    if [[ -n "${global_settings}" ]] && value="$(settings_rebuild_value "${global_settings}")"; then
        echo "${value}"
        return
    fi

    # Default: false (pull from registry)
    echo "false"
}

REBUILD_IMAGES="$(get_rebuild_setting)"

# Pick the Dockerfile matching the extended/minimal configuration
select_dockerfile() {
    # Match on the file name only: a project living in e.g. /srv/extended/app
    # must not be mistaken for a request for the extended image.
    if [[ "${SANDBOX_EXTENDED}" == "true" ]] || [[ "${DOCKERFILE_PATH##*/}" == *"extended"* ]]; then
        echo "${DOCKERFILE_EXTENDED}"
    else
        echo "${DOCKERFILE_PATH}"
    fi
}

LOCAL_BUILD_TAG="${SANDBOX_IMAGE_NAME}:rebuild-local"

build_local_image() {
    local dockerfile
    dockerfile="$(select_dockerfile)"

    echo "==> Building sandbox image from ${dockerfile}"
    if ! "${RUNTIME}" build \
        --build-arg BASE_IMAGE="${SANDBOX_BASE_IMAGE}" \
        -t "${LOCAL_BUILD_TAG}" \
        -f "${dockerfile}" \
        "${SCRIPT_DIR}"; then
        echo "ERROR: Failed to build Docker image locally" >&2
        exit 1
    fi
    echo "==> Image built successfully: ${LOCAL_BUILD_TAG}"
}

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
echo "==> Rebuild Images: ${REBUILD_IMAGES}"

# Resolve which image to run
if [[ "${REBUILD_IMAGES}" == "true" ]]; then
    # Rebuild locally from Dockerfile
    echo "==> Rebuilding sandbox image from working tree..." >&2
    build_local_image
    SANDBOX_IMAGE_REF="${LOCAL_BUILD_TAG}"
else
    # Pull from registry (default)
    REGISTRY_TAG="${SANDBOX_REGISTRY_TAG}"
    if [[ "${SANDBOX_EXTENDED}" == "true" ]]; then
        REGISTRY_TAG="${REGISTRY_TAG}-extended"
    fi
    SANDBOX_IMAGE_REF="${SANDBOX_REGISTRY_IMAGE}:${REGISTRY_TAG}"

    echo "==> Pulling image from registry: ${SANDBOX_IMAGE_REF}"
    if ! "${RUNTIME}" pull "${SANDBOX_IMAGE_REF}" 2>/dev/null; then
        echo "WARNING: Failed to pull image from registry" >&2

        if "${RUNTIME}" image inspect "${SANDBOX_IMAGE_NAME}:latest" &>/dev/null; then
            echo "==> Using existing local image: ${SANDBOX_IMAGE_NAME}:latest" >&2
            SANDBOX_IMAGE_REF="${SANDBOX_IMAGE_NAME}:latest"
        else
            echo "==> Building locally instead..." >&2
            build_local_image
            SANDBOX_IMAGE_REF="${LOCAL_BUILD_TAG}"
        fi
    fi
fi

echo "==> Image: ${SANDBOX_IMAGE_REF}"

# Build run arguments
RUN_ARGS=(
    "run"
    "--rm"
    "-i"
    # Security options
    "--cap-drop=ALL"
    "--security-opt=no-new-privileges"
    # Network
    "--network=${SANDBOX_NETWORK}"
    # Memory management
    "--tmpfs=/tmp:rw,size=256m"
)

# Allocate a TTY only when attached to one (keeps non-interactive use working)
if [[ -t 0 ]] && [[ -t 1 ]]; then
    RUN_ARGS+=("-t")
fi

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

if [[ "${SANDBOX_DRY_RUN}" == "true" ]]; then
    echo "==> Dry run: ${RUNTIME} ${RUN_ARGS[*]} ${SANDBOX_IMAGE_REF} ${CONTAINER_ARGS[*]:-}"
    exit 0
fi

echo "==> Starting sandbox..."
exec "${RUNTIME}" "${RUN_ARGS[@]}" "${SANDBOX_IMAGE_REF}" \
    ${CONTAINER_ARGS[@]+"${CONTAINER_ARGS[@]}"}
