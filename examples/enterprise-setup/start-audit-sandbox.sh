#!/usr/bin/env bash
# Enterprise sandbox startup script with audit logging and compliance settings

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/../.."

# Compliance profile settings
export SANDBOX_NETWORK=none
export SANDBOX_CPUS=2
export SANDBOX_MEMORY=4g
export SANDBOX_AUDIT_LOG=true
export SANDBOX_READONLY=false  # Allow modifications (remove file write access if needed)

# Logging
AUDIT_LOG_DIR="${PROJECT_DIR}/.audit-logs"
AUDIT_LOG_FILE="${AUDIT_LOG_DIR}/sandbox-audit-$(date +%Y-%m-%d-%H-%M-%S).log"

mkdir -p "${AUDIT_LOG_DIR}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║      Claude Code Enterprise Sandbox - Audit Mode           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration:"
echo "  Network:              ${SANDBOX_NETWORK}"
echo "  CPU Limit:            ${SANDBOX_CPUS}"
echo "  Memory Limit:         ${SANDBOX_MEMORY}"
echo "  Audit Logging:        ${SANDBOX_AUDIT_LOG}"
echo "  Audit Log File:       ${AUDIT_LOG_FILE}"
echo ""
echo "Starting sandbox..."
echo ""

# Run sandbox with audit logging
"${PROJECT_DIR}/.claude-sandbox/run-claude-sandbox.sh" 2>&1 | tee "${AUDIT_LOG_FILE}"

# Print audit summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              Sandbox Session Complete                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Audit log saved to: ${AUDIT_LOG_FILE}"
echo ""
echo "To review the audit log:"
echo "  cat ${AUDIT_LOG_FILE}"
echo ""
echo "To search for specific activity:"
echo "  grep 'keyword' ${AUDIT_LOG_FILE}"
echo ""
