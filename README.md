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

- **[SECURITY.md](SECURITY.md)** — Security policy, vulnerability reporting, best practices
- **[docs/SECURITY.md](docs/SECURITY.md)** — Threat model, what's protected, hardening options
- **[INSTALLATION.md](docs/INSTALLATION.md)** — OS-specific setup (Ubuntu, macOS, Fedora, etc.)
- **[CONFIGURATION.md](docs/CONFIGURATION.md)** — Environment variables, profiles, advanced options
- **[COMPLIANCE.md](docs/COMPLIANCE.md)** — Notes for regulated environments (SOC2, HIPAA, etc.)

## Examples

- **[basic-project](examples/basic-project)** — Minimal example; start here
- **[enterprise-setup](examples/enterprise-setup)** — Advanced: audit logging, compliance checklist

## Claude Code Skill (Enabled by Default)

The `docker-sandbox` skill is **enabled by default**. Claude Code automatically recognizes sandbox requests and launches the isolated container:

```
User: "Run this in the sandbox"
Claude Code: [automatically launches sandbox and executes]

User: "Write a test script and run it in isolation"
Claude Code: [generates code, starts sandbox, runs test]
```

### Automatic Recognition

Claude Code recognizes these requests without explicit triggers:
- "Run this in the sandbox"
- "Execute this isolated"
- "Sandbox this code"
- "Start the sandbox"
- And similar phrases

### Disabling the Skill

To disable temporarily:
```bash
export CLAUDE_DISABLE_DOCKER_SANDBOX=1
```

Or permanently via settings. See [CLAUDE.md](CLAUDE.md) and [skill documentation](.claude/skills/docker-sandbox/README.md) for details.

## Contributing

We welcome security feedback, improvements, and contributions. Please see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE).