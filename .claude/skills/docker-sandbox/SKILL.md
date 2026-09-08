---
name: docker-sandbox
description: Run Claude Code in a rootless Docker/Podman sandbox
conditions:
  - keywords: ["sandbox", "isolated", "rootless", "container", "docker", "podman"]
  - phrases:
      - "run this in sandbox"
      - "run this isolated"
      - "start the sandbox"
      - "launch sandbox"
      - "execute in sandbox"
      - "run in container"
---

# Claude Code Rootless Sandbox Skill

This skill enables Claude Code to recognize requests to run tasks in an isolated sandbox environment.

## Activation

Claude Code recognizes requests like:

- "Run this in the sandbox"
- "Execute this isolated"
- "Start the rootless container"
- "Launch the sandbox for this task"

## What It Does

When activated, this skill:

1. **Detects** a sandbox request in user input
2. **Locates** the `./.claude-sandbox/run-claude-sandbox.sh` script in your project
3. **Launches** the sandbox container with your project directory mounted
4. **Executes** subsequent commands inside the isolated container

## How It Works

```
User: "Run this in the sandbox"
     ↓
Claude: Recognizes sandbox request
     ↓
Claude: Calls ./.claude-sandbox/run-claude-sandbox.sh
     ↓
Container: Starts with project directory mounted
     ↓
User: Can run commands inside the sandbox
```

## Example Usage

### Basic Sandbox Session

```
User: "Start the sandbox"

Claude: [launches container]
Sandbox: /project$

User: npm install
Sandbox: /project$ npm install
         ✓ Installed dependencies

User: npm run test
Sandbox: /project$ npm run test
         ✓ Tests pass
```

### Generate Code in Sandbox

```
User: "Write a Python script to process CSV files, run it in the sandbox"

Claude: [generates script.py]
        [launches sandbox]
        [runs script.py]

Output: [results from isolated execution]
```

## Configuration

Customize sandbox behavior by setting environment variables:

```bash
# Restrict network
SANDBOX_NETWORK=none ./run-claude-sandbox.sh

# Limit resources
SANDBOX_CPUS=2 SANDBOX_MEMORY=4g ./run-claude-sandbox.sh

# Read-only mode (audit)
SANDBOX_READONLY=true ./run-claude-sandbox.sh

# Enable audit logging
SANDBOX_AUDIT_LOG=true ./run-claude-sandbox.sh
```

See [`.claude-sandbox/config-defaults.env`](../../.claude-sandbox/config-defaults.env) for all options.

## Security Properties

The sandbox provides:

- **Isolation** — Project directory is separate from host system
- **Rootless execution** — No elevated privileges
- **Dropped capabilities** — Linux capabilities restricted
- **Namespace isolation** — Separate PID, network, filesystem namespaces
- **Resource limits** — CPU and memory constraints (optional)

See [`docs/SECURITY.md`](../../docs/SECURITY.md) for full security documentation.

## Troubleshooting

### "Sandbox script not found"

Ensure `.claude-sandbox/run-claude-sandbox.sh` exists in your project root:

```bash
ls -la ./.claude-sandbox/run-claude-sandbox.sh
```

If missing, copy it from the repository:

```bash
cp -r /path/to/sandbox-repo/.claude-sandbox ./.claude-sandbox
chmod +x ./.claude-sandbox/run-claude-sandbox.sh
```

### "Container runtime not found"

Install Podman (recommended) or Docker:

```bash
# Ubuntu/Debian
sudo apt install podman

# Fedora
sudo dnf install podman

# macOS
brew install podman
```

### "Permission denied"

Make sure the script is executable:

```bash
chmod +x ./.claude-sandbox/run-claude-sandbox.sh
```

## Advanced Configuration

For advanced use cases, see:

- [CONFIGURATION.md](../../docs/CONFIGURATION.md) — Environment variables, profiles, hardening
- [SECURITY.md](../../docs/SECURITY.md) — Threat model, audit logging
- [COMPLIANCE.md](../../docs/COMPLIANCE.md) — Regulatory compliance (SOC2, HIPAA, PCI-DSS)

## Disabling This Skill

To disable the skill, simply remove or rename this file:

```bash
rm ./.claude/skills/docker-sandbox/SKILL.md
```

Claude Code will no longer recognize sandbox requests.

---

**Questions?** See the [main repository](https://github.com/yourusername/claude-code-rootless-sandbox) or open an issue.
