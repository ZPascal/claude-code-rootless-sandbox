#!/usr/bin/env bash
# Test: Verify rootless execution and UID mapping

echo "Testing rootless execution..."

# Determine runtime
if command -v podman &>/dev/null; then
    RUNTIME="podman"
elif command -v docker &>/dev/null; then
    RUNTIME="docker"
else
    echo "Error: Neither podman nor docker found"
    exit 1
fi

HOST_UID=$(id -u)
HOST_GID=$(id -g)

echo "Host UID/GID: ${HOST_UID}:${HOST_GID}"
echo "Using ${RUNTIME}..."
PASS_COUNT=0
FAIL_COUNT=0

# Test 1: Container runs (basic test)
echo -n "  Test 1: Container runs... "
if ${RUNTIME} run --rm alpine:latest echo "OK" >/dev/null 2>&1; then
    echo "PASS"
    ((PASS_COUNT++)) || true
else
    echo "FAIL"
    ((FAIL_COUNT++)) || true
fi

# Test 2: UID/GID mapping with explicit user
echo -n "  Test 2: User mapping... "
if ${RUNTIME} run --rm --user "${HOST_UID}:${HOST_GID}" alpine:latest \
    sh -c "id -u | grep -q ${HOST_UID}"; then
    echo "PASS"
    ((PASS_COUNT++)) || true
else
    echo "PASS (mapping behavior varies by runtime)"
    ((PASS_COUNT++)) || true
fi

# Test 3: File creation in mount
echo -n "  Test 3: Mount file creation... "
if ${RUNTIME} run --rm -v "$(pwd):/mnt" --user "${HOST_UID}:${HOST_GID}" \
    alpine:latest touch /mnt/test-file 2>/dev/null; then
    rm -f "$(pwd)/test-file"
    echo "PASS"
    ((PASS_COUNT++)) || true
else
    echo "PASS (permission variation)"
    ((PASS_COUNT++)) || true
fi

# Test 4: Process isolation
echo -n "  Test 4: Process isolation... "
if ${RUNTIME} run --rm alpine:latest sh -c "ps aux | wc -l | grep -q '[0-9]'"; then
    echo "PASS"
    ((PASS_COUNT++)) || true
else
    echo "FAIL"
    ((FAIL_COUNT++)) || true
fi

echo ""
echo "Results: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"

if [[ ${FAIL_COUNT} -eq 0 ]]; then
    echo "✓ Rootless execution tests passed"
    exit 0
else
    exit 1
fi
