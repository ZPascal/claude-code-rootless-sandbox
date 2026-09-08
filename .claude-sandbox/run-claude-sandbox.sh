#!/usr/bin/env bash
# Startet Claude Code in einer isolierten, rootless Container-Sandbox.
# Es wird NUR das angegebene Code-Verzeichnis in den Container gemountet.
#
# Usage:
#   ./run-claude-sandbox.sh [CODE_DIR] [-- claude-args...]
#
# Beispiele:
#   ./run-claude-sandbox.sh                    # aktuelles Verzeichnis
#   ./run-claude-sandbox.sh ~/projekte/foo      # anderes Projekt
#   ./run-claude-sandbox.sh . -- --model sonnet # zusätzliche claude-Args

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="claude-code-sandbox:latest"
CONFIG_VOLUME="claude-code-sandbox-config"   # persistente, isolierte Claude-Config/Auth

CODE_DIR="${PWD}"
if [[ "${1:-}" != "" && "${1:-}" != "--" ]]; then
    CODE_DIR="$1"
    shift
fi
CODE_DIR="$(cd "${CODE_DIR}" && pwd)"

if [[ "${1:-}" == "--" ]]; then
    shift
fi

# --- Engine wählen: Podman bevorzugt (echtes rootless ohne Daemon) ---
if command -v podman >/dev/null 2>&1; then
    ENGINE="podman"
elif command -v docker >/dev/null 2>&1; then
    ENGINE="docker"
else
    echo "Weder podman noch docker gefunden. Bitte eines von beiden installieren." >&2
    exit 1
fi
echo "==> Engine: ${ENGINE}"
echo "==> Gemounteter Code: ${CODE_DIR}"

# --- Image bauen, falls nicht vorhanden ---
if ! "${ENGINE}" image exists "${IMAGE_NAME}" 2>/dev/null; then
    echo "==> Baue Sandbox-Image (einmalig)..."
    "${ENGINE}" build \
        --build-arg USER_UID="$(id -u)" \
        --build-arg USER_GID="$(id -g)" \
        -t "${IMAGE_NAME}" \
        "${SCRIPT_DIR}"
fi

# --- Container-Volume für Claude-Config anlegen (isoliert vom Host-~/.claude) ---
"${ENGINE}" volume inspect "${CONFIG_VOLUME}" >/dev/null 2>&1 \
    || "${ENGINE}" volume create "${CONFIG_VOLUME}" >/dev/null

COMMON_ARGS=(
    run --rm -it
    --cap-drop=ALL
    --security-opt no-new-privileges
    --network=host          # entfernen/anpassen, falls Claude offline arbeiten soll
    --tmpfs /tmp
    -v "${CODE_DIR}:/workspace:Z"
    -v "${CONFIG_VOLUME}:/home/claude/.claude"
    -w /workspace
)

if [[ "${ENGINE}" == "podman" ]]; then
    # echtes rootless: Host-UID <-> Container-UID 1:1 gemappt
    "${ENGINE}" "${COMMON_ARGS[@]}" --userns=keep-id "${IMAGE_NAME}" "$@"
else
    # Docker: UID/GID manuell setzen (Docker Desktop/rootless-Docker vorausgesetzt)
    "${ENGINE}" "${COMMON_ARGS[@]}" --user "$(id -u):$(id -g)" "${IMAGE_NAME}" "$@"
fi
