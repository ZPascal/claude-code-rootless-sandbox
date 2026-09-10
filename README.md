# Claude Code Rootless Sandbox

A production-ready, isolated Docker/Podman setup for running [Claude Code](https://claude.ai/code) securely with minimal privileges and no host system access.

> **✨ Sandbox Skill Enabled by Default**  
> Once installed, Claude Code automatically recognizes sandbox requests like "run this isolated" and launches the container for you. No manual commands needed—just ask Claude Code to sandbox your code.

See [CLAUDE.md](CLAUDE.md) for configuration and how to disable if needed.

## Quick Start

### 1. Prerequisites
- **Podman** (recommended) or **Docker** (see [installation guide](docs/INSTALLATION.md))
- Claude Code CLI or IDE extension

### 2. Install into Your Project

```bash
# Clone or download this repository
git clone https://github.com/ZPascal/claude-code-rootless-sandbox.git /tmp/sandbox-setup

# Copy sandbox files to your project
cp -r /tmp/sandbox-setup/.claude-sandbox /path/to/your/project/
cp -r /tmp/sandbox-setup/.claude/skills/docker-sandbox /path/to/your/project/.claude/skills/

# Make the script executable
chmod +x /path/to/your/project/.claude-sandbox/run-claude-sandbox.sh
```

### 3. Start Using the Sandbox

The sandbox skill is now **active by default**. Just use Claude Code normally with sandbox requests:

```
You: "Write a Python script that processes CSV files, then run it in the sandbox"

Claude Code: 
  [generates script.py]
  [automatically launches sandbox]
  [executes script inside isolated container]
  [returns results]
```

### 4. Manual Usage (Optional)

Or start the sandbox manually anytime:

```bash
cd /path/to/your/project
./.claude-sandbox/run-claude-sandbox.sh
```

This launches Claude Code in an isolated container with:
- **No root privileges** — runs as your user (UID/GID mapped 1:1)
- **No host filesystem access** — only your project directory is mounted
- **Dropped capabilities** — no unnecessary Linux capabilities
- **No Docker socket** — cannot spawn new containers
- **Restricted network** — configurable policies (default: full access, see [hardening options](docs/CONFIGURATION.md))

## 4. Image Management

### Default: Pre-built Images from GHCR

By default, the sandbox pulls pre-built images from GitHub Container Registry (GHCR) for fast startup — no local build needed:

```bash
# Pulls image from ghcr.io/zpascal/claude-code-sandbox:latest
./.claude-sandbox/run-claude-sandbox.sh
```

**Benefits:**
- Fast startup (pull ~100MB vs. build 5+ minutes)
- CI-tested and consistent across environments
- Works offline if image already cached locally

**Available Images:**
- `ghcr.io/zpascal/claude-code-sandbox:latest` — **Minimal** (recommended for most users)
- `ghcr.io/zpascal/claude-code-sandbox:latest-extended` — **Extended** (Python, Node, Go, Rust included)

**Using Specific Versions:**
```bash
docker pull ghcr.io/zpascal/claude-code-sandbox:v1.0.0          # Minimal v1.0.0
docker pull ghcr.io/zpascal/claude-code-sandbox:v1.0.0-extended # Extended v1.0.0
```

### Option: Rebuild Images Locally

For development or when you need to modify the Dockerfiles, rebuild from your working tree:

```bash
# Rebuild once (this session only)
CLAUDE_REBUILD_IMAGES=1 ./.claude-sandbox/run-claude-sandbox.sh

# Or enable for this project permanently
echo '{"skills": {"docker-sandbox": {"rebuild": true}}}' > .claude/settings.json
```

**When to rebuild:**
- Developing or modifying Dockerfiles
- Testing new image configurations
- Working offline (if registry is unavailable)
- Debugging build-time issues

For full configuration options, see [CONFIGURATION.md](docs/CONFIGURATION.md).

## Use Claude Code Normally Inside the Sandbox

Once running, use Claude Code exactly as you normally would. The sandbox is transparent — your project files are readable/writable, and Claude Code has full access to your project directory in isolation.

```bash
# Example: inside the sandbox, these work normally:
npm install
python script.py
git status
```

## Why Use This?

- **Security**: Claude Code runs in complete isolation; compromised code cannot affect your host system
- **Compliance**: Audit-friendly; satisfies team/enterprise security requirements
- **Development**: Safe sandbox for untrusted code generation or experiments
- **Multi-project**: Run different projects with independent sandbox configurations

## Documentation

### Getting Started
- **[INSTALLATION.md](docs/INSTALLATION.md)** — Step-by-step setup for Ubuntu, macOS, Fedora, and others
- **[CLAUDE.md](CLAUDE.md)** — Claude Code integration, enabling/disabling the skill, rebuild configuration

### Configuration & Usage
- **[CONFIGURATION.md](docs/CONFIGURATION.md)** — All environment variables, image options, rebuild settings, hardening profiles
- **[docs/TESTING.md](docs/TESTING.md)** — How to test the image build workflow locally

### Security & Compliance
- **[SECURITY.md](SECURITY.md)** — Security policy and vulnerability reporting
- **[docs/SECURITY.md](docs/SECURITY.md)** — Threat model, protection guarantees, hardening options
- **[COMPLIANCE.md](docs/COMPLIANCE.md)** — Guidance for regulated environments (SOC2, HIPAA, PCI-DSS, ISO 27001)

## Examples

- **[basic-project](examples/basic-project)** — Minimal example; start here
- **[enterprise-setup](examples/enterprise-setup)** — Advanced: audit logging, compliance checklist

## About the Claude Code Skill

The `docker-sandbox` skill is **enabled by default** in this project. Claude Code automatically recognizes your sandbox requests and launches the container:

**Automatic Recognition:**
- "Run this in the sandbox"
- "Execute this isolated"  
- "Sandbox this code"
- "Start the sandbox"
- And similar natural language requests

**Example:**
```
You: "Write a Python script that installs packages and run it in the sandbox"

Claude Code:
  [generates script.py]
  [automatically launches sandbox]
  [executes script in isolation]
  [returns output with no impact on host]
```

**Customization:**
- Temporarily disable: `export CLAUDE_DISABLE_DOCKER_SANDBOX=1`
- Disable permanently: See [CLAUDE.md](CLAUDE.md)
- Configure rebuild behavior: See [CONFIGURATION.md](docs/CONFIGURATION.md)
- Enable extended tools: `SANDBOX_EXTENDED=true` in config or settings

## Contributing

We welcome security feedback, improvements, and contributions. Please see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE).