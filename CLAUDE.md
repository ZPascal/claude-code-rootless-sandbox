# Claude Code Configuration

This file documents Claude Code-specific settings and behaviors for this project.

## Docker Sandbox Skill

The `docker-sandbox` skill is **enabled by default** in this project.

### What It Does

Automatically recognizes requests to run code in an isolated sandbox:

- "Run this in the sandbox"
- "Execute this isolated"
- "Start the sandbox"
- "Sandbox this code"

When triggered, Claude Code:
1. Launches `./.claude-sandbox/run-claude-sandbox.sh`
2. Executes commands inside the isolated container
3. Returns results from the sandboxed environment

### Disable the Skill

**Temporarily (single session):**
```bash
export CLAUDE_DISABLE_DOCKER_SANDBOX=1
```

**Permanently (via settings):**
```json
{
  "skills": {
    "docker-sandbox": {
      "enabled": false
    }
  }
}
```

**Permanently (remove file):**
```bash
rm .claude/skills/docker-sandbox/SKILL.md
```

## Sandbox Configuration

The sandbox is configured via environment variables in `.claude-sandbox/config-defaults.env`.

Common configurations:

```bash
# Development (default)
SANDBOX_NETWORK=host
SANDBOX_READONLY=false
SANDBOX_CPUS=
SANDBOX_MEMORY=

# Audit mode
SANDBOX_NETWORK=none
SANDBOX_READONLY=true
SANDBOX_CPUS=2
SANDBOX_MEMORY=4g
SANDBOX_AUDIT_LOG=true

# Strict/Isolated
SANDBOX_NETWORK=none
SANDBOX_READONLY=false
SANDBOX_CPUS=1
SANDBOX_MEMORY=2g
```

See [docs/CONFIGURATION.md](docs/CONFIGURATION.md) for all options.

## Project Structure

```
.
├── .claude/                           # Claude Code configuration
│   └── skills/docker-sandbox/         # Sandbox skill
├── .claude-sandbox/                   # Container setup
│   ├── Dockerfile                     # Minimal image
│   ├── Dockerfile.extended            # Extended image (Python, Node, Go, Rust)
│   ├── run-claude-sandbox.sh           # Launch script
│   └── config-defaults.env             # Configuration
├── docs/                              # Documentation
│   ├── SECURITY.md                    # Security threat model
│   ├── INSTALLATION.md                # Setup guide
│   ├── CONFIGURATION.md               # All options
│   └── COMPLIANCE.md                  # Regulatory guidance
├── examples/                          # Working examples
│   ├── basic-project/                 # Minimal example
│   └── enterprise-setup/              # Compliance setup
├── tests/                             # Validation tests
│   ├── test-isolation.sh
│   ├── test-rootless.sh
│   └── test-permissions.sh
├── SECURITY.md                        # Security policy
├── CONTRIBUTING.md                    # Contributing guide
├── LICENSE                            # Apache 2.0
└── README.md                          # Quick start
```

## Security & Compliance

- **Security:** See [docs/SECURITY.md](docs/SECURITY.md) for threat model and hardening
- **Compliance:** See [docs/COMPLIANCE.md](docs/COMPLIANCE.md) for SOC2, HIPAA, PCI-DSS, ISO 27001
- **Reporting:** See [SECURITY.md](SECURITY.md) for vulnerability disclosure

## Testing

Run validation tests to verify sandbox properties:

```bash
bash tests/test-isolation.sh      # Filesystem isolation
bash tests/test-rootless.sh       # Rootless execution
bash tests/test-permissions.sh    # Capability dropping
```

## Quick Start

1. **Install container runtime:**
   ```bash
   # Podman (recommended)
   sudo apt install podman
   
   # or Docker
   sudo apt install docker.io
   ```

2. **Start the sandbox:**
   ```bash
   ./.claude-sandbox/run-claude-sandbox.sh
   ```

3. **Use Claude Code normally** inside the sandbox

See [README.md](README.md) and [docs/INSTALLATION.md](docs/INSTALLATION.md) for details.

---

**Repository:** https://github.com/ZPascal/claude-code-rootless-sandbox
