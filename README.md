# Claude Code Rootless Sandbox

A production-ready, isolated Docker/Podman setup for running [Claude Code](https://claude.ai/code) securely with minimal privileges and no host system access.

## Quick Start

### 1. Prerequisites
- **Podman** (recommended) or **Docker** (see [installation guide](docs/INSTALLATION.md))
- Claude Code CLI or IDE extension

### 2. Install into Your Project

```bash
# Clone or download this repository
git clone https://github.com/yourusername/claude-code-rootless-sandbox.git /tmp/sandbox-setup

# Copy sandbox files to your project
cp -r /tmp/sandbox-setup/.claude-sandbox /path/to/your/project/
cp -r /tmp/sandbox-setup/.claude/skills/docker-sandbox /path/to/your/project/.claude/skills/

# Make the script executable
chmod +x /path/to/your/project/.claude-sandbox/run-claude-sandbox.sh
```

### 3. Run the Sandbox

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

## Claude Code Skill

If `.claude/skills/docker-sandbox/SKILL.md` is present, Claude Code automatically recognizes sandbox commands:

```
User: "Run this in the sandbox"
Claude Code: [automatically calls run-claude-sandbox.sh]
```

See [skill documentation](\.claude/skills/docker-sandbox/README.md) for details.

## Contributing

We welcome security feedback, improvements, and contributions. Please see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE).