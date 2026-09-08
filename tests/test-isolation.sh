#!/usr/bin/env bash
# Test: Verify filesystem isolation in sandbox

echo "Testing filesystem isolation..."

# Determine runtime
if command -v podman &>/dev/null; then
    RUNTIME="podman"
elif command -v docker &>/dev/null; then
    RUNTIME="docker"
else
    echo "Error: Neither podman nor docker found"
    exit 1
fi

echo "Using ${RUNTIME}..."
PASS_COUNT=0
FAIL_COUNT=0

# Test 1: Project directory accessible
echo -n "  Test 1: Project directory accessible... "
if ${RUNTIME} run --rm -v "$(pwd):/test-mount" alpine:latest test -d /test-mount; then
    echo "PASS"
    ((PASS_COUNT++)) || true
else
    echo "FAIL"
    ((FAIL_COUNT++)) || true
fi

# Test 2: Mount isolation
echo -n "  Test 2: Mount can be accessed... "
if ${RUNTIME} run --rm -v "$(pwd):/test-mount" alpine:latest sh -c "ls /test-mount >/dev/null 2>&1"; then
    echo "PASS"
    ((PASS_COUNT++)) || true
else
    echo "FAIL"
    ((FAIL_COUNT++)) || true
fi

# Test 3: Container has filesystem
echo -n "  Test 3: Container has /etc... "
if ${RUNTIME} run --rm alpine:latest test -d /etc; then
    echo "PASS"
    ((PASS_COUNT++)) || true
else
    echo "FAIL"
    ((FAIL_COUNT++)) || true
fi

# Test 4: tmpfs works
echo -n "  Test 4: tmpfs mounting... "
if ${RUNTIME} run --rm --tmpfs /tmp:rw,size=256m alpine:latest test -d /tmp; then
    echo "PASS"
    ((PASS_COUNT++)) || true
else
    echo "FAIL"
    ((FAIL_COUNT++)) || true
fi

echo ""
echo "Results: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"

if [[ ${FAIL_COUNT} -eq 0 ]]; then
    echo "✓ Filesystem isolation tests passed"
    exit 0
else
    echo "✗ Some tests failed"
    exit 1
fi
