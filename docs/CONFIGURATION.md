# Configuration Guide

Complete reference for configuring the Claude Code rootless sandbox.

**Quick links:**
- **New to the sandbox?** Start with [README.md](../README.md) and [CLAUDE.md](../CLAUDE.md)
- **Want to rebuild images locally?** See [Docker Sandbox Rebuild Configuration](#docker-sandbox-rebuild-configuration) below
- **Looking for security hardening?** See [docs/SECURITY.md](SECURITY.md)
- **Need advanced options?** See [Configuration Files](#configuration-files) below

---

## Configuration Files

### `.claude-sandbox/config-defaults.env`

Default environment variables loaded on every run. Customize for your project:

```bash
# Container image name
SANDBOX_IMAGE_NAME=claude-code-sandbox

# Base image (change if you need different OS/packages)
SANDBOX_BASE_IMAGE=ubuntu:24.04

# CPU and memory limits (empty = no limit)
SANDBOX_CPUS=
SANDBOX_MEMORY=

# Network mode: host (default), none (no network), or custom
SANDBOX_NETWORK=host

# Mount project as read-only (true/false)
SANDBOX_READONLY=false

# Enable audit logging (true/false)
SANDBOX_AUDIT_LOG=false

# Custom environment variables to pass to container
SANDBOX_ENV_EXTRA=
```

### `.claude-sandbox/run-claude-sandbox.sh`

Main entry script. Edit to customize:

```bash
#!/bin/bash
# Container runtime (podman or docker)
RUNTIME=${RUNTIME:-podman}

# Mount options, capability drops, security settings
# Modify if you want stricter isolation
```

## Environment Variables

### Override at Runtime

```bash
# Set CPU limit to 2 cores:
SANDBOX_CPUS=2 ./.claude-sandbox/run-claude-sandbox.sh

# Mount as read-only:
SANDBOX_READONLY=true ./.claude-sandbox/run-claude-sandbox.sh

# Use Docker instead of Podman:
RUNTIME=docker ./.claude-sandbox/run-claude-sandbox.sh

# Disable network:
SANDBOX_NETWORK=none ./.claude-sandbox/run-claude-sandbox.sh
```

> **Known limitation:** Environment variables passed to `run-claude-sandbox.sh` are currently overridden by `config-defaults.env`. This is a known limitation. Workaround: use `.claude/settings.json` or pass values via the command directly.

### Docker Sandbox Rebuild Configuration

**Option:** `skills.docker-sandbox.rebuild`

**Type:** Boolean (default: `false`)

**Description:** When enabled, the Docker sandbox skill rebuilds images locally from the current working tree instead of pulling pre-built images from GitHub Container Registry. Useful for development when modifying Dockerfiles or when working offline.

**Configuration Methods:**

#### Environment Variable (Session Override)

```bash
CLAUDE_REBUILD_IMAGES=1 claude
```

#### Project Settings (`.claude/settings.json`)

```json
{
  "skills": {
    "docker-sandbox": {
      "rebuild": true
    }
  }
}
```

#### Global User Settings

```jsonc
// ~/.claude/settings.json (or your Claude Code config location)
{
  "skills": {
    "docker-sandbox": {
      "rebuild": true
    }
  }
}
```

**Priority:** Environment variable > Project settings > Global settings

**Default Behavior:**

- Without rebuild enabled: pulls pre-built images from `ghcr.io/zpascal/claude-code-sandbox:latest` (fast, requires internet)
- If registry pull fails: automatically falls back to local build with warning

**Examples:**

Rebuild for current development session:

```bash
CLAUDE_REBUILD_IMAGES=1 claude /code
```

Enable rebuild for all Claude Code work in this project:

```jsonc
// Edit .claude/settings.json
{
  "skills": {
    "docker-sandbox": {
      "rebuild": true
    }
  }
}
```

Enable rebuild globally (developer actively modifying sandbox):

```jsonc
// Edit ~/.claude/settings.json or your global Claude config
{
  "skills": {
    "docker-sandbox": {
      "rebuild": true
    }
  }
}
```

## Profiles

Pre-configured profiles for common scenarios:

### Development Profile (Default)

```bash
SANDBOX_READONLY=false
SANDBOX_NETWORK=host
SANDBOX_CPUS=
SANDBOX_MEMORY=
```

**Use case:** Full access, development iteration, unrestricted resources.

### Audit Profile

```bash
SANDBOX_READONLY=true
SANDBOX_NETWORK=none
SANDBOX_CPUS=2
SANDBOX_MEMORY=4g
SANDBOX_AUDIT_LOG=true
```

**Use case:** Inspect generated code without modification, compliance scenarios.

```bash
# Run with audit profile:
SANDBOX_READONLY=true SANDBOX_NETWORK=none SANDBOX_AUDIT_LOG=true ./.claude-sandbox/run-claude-sandbox.sh
```

### Strict Profile (Enterprise)

```bash
SANDBOX_READONLY=false
SANDBOX_NETWORK=none  # No external network
SANDBOX_CPUS=1
SANDBOX_MEMORY=2g
SANDBOX_AUDIT_LOG=true
```

**Use case:** Sandboxed code generation with minimal resource access.

```bash
# Run with strict profile:
SANDBOX_NETWORK=none SANDBOX_CPUS=1 SANDBOX_AUDIT_LOG=true ./.claude-sandbox/run-claude-sandbox.sh
```

## Network Hardening

### Disable Network Entirely

```bash
SANDBOX_NETWORK=none ./.claude-sandbox/run-claude-sandbox.sh
```

**Trade-off:** Cannot install packages, fetch from APIs, or push to GitHub.

**Use case:** Offline code review, audit scenarios.

### Restrict to Specific Domains

Create a `/etc/hosts` allowlist inside the container:

**Step 1:** Modify `run-claude-sandbox.sh` to add domain restriction:

```bash
# Add to run-claude-sandbox.sh before container launch:
--mount type=bind,source=/etc/hosts,target=/etc/hosts,ro \
```

**Step 2:** Edit host `/etc/hosts` to include only allowed domains:

```
127.0.0.1       localhost
1.2.3.4         allowed.domain.com
5.6.7.8         github.com
# Block everything else by omission
```

**Trade-off:** Manual DNS management, fragile.

**Use case:** Highly restricted network policies.

### Proxy Setup

If your organization uses a proxy:

```bash
SANDBOX_ENV_EXTRA="HTTP_PROXY=http://proxy.company.com:8080 HTTPS_PROXY=http://proxy.company.com:8080" \
  ./.claude-sandbox/run-claude-sandbox.sh
```

## Resource Limits

### CPU Limit

Restrict to N cores:

```bash
SANDBOX_CPUS=2 ./.claude-sandbox/run-claude-sandbox.sh
```

### Memory Limit

Restrict to N gigabytes:

```bash
SANDBOX_MEMORY=4g ./.claude-sandbox/run-claude-sandbox.sh
```

### Combined Limits

```bash
SANDBOX_CPUS=2 SANDBOX_MEMORY=4g ./.claude-sandbox/run-claude-sandbox.sh
```

**Default:** No limits (uses available system resources).

## Security Options

### Drop Capabilities

The default setup drops all unnecessary Linux capabilities:

```bash
--cap-drop=ALL
--cap-add=NET_BIND_SERVICE  # For web servers
```

To add back a capability (if needed), modify `run-claude-sandbox.sh`:

```bash
--cap-add=SYS_PTRACE  # For debugging with gdb
```

**Common capabilities:**
- `NET_BIND_SERVICE` — bind to ports < 1024
- `SYS_PTRACE` — attach debugger
- `SYS_ADMIN` — mount filesystems (rarely needed)

### Disable Privilege Escalation

Already enabled by default:

```bash
--security-opt no-new-privileges
```

This prevents setuid binaries from gaining privileges inside the container.

### Read-Only Root Filesystem

Make the root filesystem read-only (project directory stays writable):

```bash
# Modify run-claude-sandbox.sh:
--read-only \
--tmpfs /tmp:rw \
--tmpfs /run:rw
```

**Trade-off:** Some applications won't work if they try to write to system directories.

## Audit Logging

### Enable Audit Log

```bash
SANDBOX_AUDIT_LOG=true ./.claude-sandbox/run-claude-sandbox.sh 2>&1 | tee sandbox-audit.log
```

This captures all stdout/stderr from the container.

### Parse Audit Logs

Audit logs contain:
- Container startup parameters
- Files accessed/modified
- Network connections
- Process creation
- Exit code

Example log entry:

```
[2026-09-08T15:00:00] Starting Claude Code sandbox...
[2026-09-08T15:00:05] Container running with UID/GID: 1000:1000
[2026-09-08T15:00:10] Files modified: ./main.py, ./requirements.txt
[2026-09-08T15:00:45] Process exited with code 0
```

## Advanced: Custom Dockerfile

If you need tools beyond the default image, customize the Dockerfile:

```dockerfile
# .claude-sandbox/Dockerfile.custom
FROM ubuntu:24.04

# Install additional tools
RUN apt-get update && apt-get install -y \
    python3 \
    nodejs \
    rust-lang \
    go \
  && rm -rf /var/lib/apt/lists/*

# Rest of Dockerfile...
```

Build and use:

```bash
podman build -t claude-code-sandbox:custom -f .claude-sandbox/Dockerfile.custom .
SANDBOX_IMAGE_NAME=claude-code-sandbox:custom ./.claude-sandbox/run-claude-sandbox.sh
```

## Troubleshooting Configuration

### "Resource limit too low"

If Claude Code runs out of memory:

```bash
SANDBOX_MEMORY=8g ./.claude-sandbox/run-claude-sandbox.sh
```

### "Network connection refused"

Check network mode:

```bash
SANDBOX_NETWORK=host ./.claude-sandbox/run-claude-sandbox.sh  # Allow all
```

### "Cannot write files"

Check read-only setting:

```bash
SANDBOX_READONLY=false ./.claude-sandbox/run-claude-sandbox.sh
```

### "Permission denied for capability"

Some capabilities require specific kernel versions. Try:

```bash
--cap-drop=ALL --cap-add=NET_BIND_SERVICE
```

And avoid adding capabilities like `SYS_ADMIN` unless essential.

---

**Next:** See [SECURITY.md](SECURITY.md) for security details, or [COMPLIANCE.md](COMPLIANCE.md) for regulatory notes.
