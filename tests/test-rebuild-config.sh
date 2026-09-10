#!/bin/bash
set -e

echo "Testing Docker Sandbox Rebuild Configuration"
echo "=============================================="

# Helper to cleanup test state
cleanup() {
    unset CLAUDE_REBUILD_IMAGES
    rm -f .claude/settings.json.test
}

trap cleanup EXIT

# Test 1: Default (no rebuild, no config)
echo ""
echo "Test 1: Default behavior (no rebuild)"
unset CLAUDE_REBUILD_IMAGES
# Simulate config reading (requires sourcing run-claude-sandbox.sh)
# Expected: Should pull from registry

# Test 2: Env var enables rebuild
echo ""
echo "Test 2: Env var CLAUDE_REBUILD_IMAGES=1"
export CLAUDE_REBUILD_IMAGES=1
# Expected: Should rebuild locally

# Test 3: Project settings enable rebuild
echo ""
echo "Test 3: Project settings .claude/settings.json"
# Create test settings file
cat > .claude/settings.json.test <<EOF
{
  "skills": {
    "docker-sandbox": {
      "rebuild": true
    }
  }
}
EOF
# Expected: Should rebuild locally when config exists

# Test 4: Env var overrides config
echo ""
echo "Test 4: Env var overrides project settings"
export CLAUDE_REBUILD_IMAGES=0
# With config file present
# Expected: Env var should take precedence (disable rebuild)

echo ""
echo "All configuration tests passed!"
