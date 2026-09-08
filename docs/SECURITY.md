# Security Documentation

## Overview

This document describes the security model of the Claude Code rootless sandbox, threat mitigations, audit practices, and hardening options.

## What This Sandbox Protects Against

### ✅ Threats Mitigated

1. **Rogue Code Execution**
   - Generated or untrusted code cannot read/write host system files outside the project directory
   - Malicious code runs with your user privileges but only within the container namespace
   - Cannot affect sibling projects or system-wide resources

2. **Privilege Escalation**
   - Dropped capabilities (`CAP_SYS_ADMIN`, `CAP_NET_ADMIN`, etc.) prevent kernel exploit chains
   - Rootless container: even if process gains root *inside container*, it's still unprivileged on the host
   - `--security-opt no-new-privileges` prevents capability escalation via setuid binaries

3. **Container Breakout via Socket/API**
   - Docker socket not exposed; container cannot spawn siblings
   - No privileged mount of `/sys`, `/proc`, host device files

4. **Network Lateral Movement**
   - Network policies configurable (see [CONFIGURATION.md](CONFIGURATION.md))
   - Default: full outbound access (you can restrict to specific domains)
   - No inbound listening by default

### ⚠️ What This Sandbox Does NOT Protect Against

1. **Supply Chain via Dependencies**
   - If your project's `package.json`, `requirements.txt`, etc. reference compromised packages, they will run
   - The sandbox *contains* the damage but doesn't prevent the fetch
   - **Mitigation:** Audit dependencies, use lock files, consider network restrictions

2. **Hardware-Level Attacks**
   - Timing attacks, side-channel exploitation of CPU/memory not addressed
   - Sandbox assumes the underlying host kernel is trustworthy

3. **Misconfiguration**
   - If you mount additional directories or grant network access without understanding the trade-offs, security is reduced
   - Follow configuration best practices

4. **Social Engineering**
   - Claude Code cannot be tricked into exfiltrating data it doesn't have access to, but if *you* configure it to have access, it can

## Rootless Guarantees by Container Runtime

### Podman (Recommended)

Podman is *natively* rootless — the daemon runs as an unprivileged user:

```bash
# Podman user-namespace isolation
--userns=keep-id        # Maps host UID 1:1 into container (files stay owned by you)
--user $(id -u):$(id -g)  # Explicit UID/GID (redundant but explicit)
```

**Guarantee:** Even if the container process becomes root, it is mapped back to your user ID on the host. A file created as `root:root` (uid 0:0) inside the container appears as `youruser:youruser` on the host filesystem.

### Docker (Rootless Mode Required)

Docker requires explicit rootless mode setup:

```bash
# Without Docker rootless mode, the daemon runs as root:
sudo dockerd  # ← root daemon

# With Docker rootless mode enabled:
dockerd       # ← your user's daemon
```

If Docker daemon is running as root, the sandbox provides process-level isolation but weaker UID guarantee. Check your setup:

```bash
docker info | grep "rootless"
# Output: Rootless: true  ← good
# Output: Rootless: false ← falls back to process isolation only
```

**See [INSTALLATION.md](INSTALLATION.md#docker-rootless-mode) for Docker rootless setup.**

## Audit Points

### Log Access

1. **Process Isolation via PID Namespace**
   ```bash
   # Inside sandbox:
   ps aux  # Only shows sandbox processes
   
   # On host:
   ps aux  # Shows all host processes; sandbox processes are isolated
   ```

2. **File Ownership & Permissions**
   ```bash
   ls -la /path/to/project  # Files created in sandbox are owned by you, auditable
   ```

3. **Container Logs**
   ```bash
   # Capture stdout/stderr from the sandbox:
   ./.claude-sandbox/run-claude-sandbox.sh 2>&1 | tee sandbox.log
   ```

4. **Network Traffic** (if restrictive policy enabled)
   - Network policies can log DNS queries, blocked connections
   - See [CONFIGURATION.md](CONFIGURATION.md#network-policies) for audit logging setup

### Compliance Considerations

- **Audit Trail:** Every file modified in your project is timestamped; filesystem permissions are auditable
- **Immutability:** Consider mounting project directory read-only for audit scenarios (at cost of no write access)
- **Secrets:** Never expose credentials in environment variables; use host secrets management and mount only what's needed
- **Reproducibility:** Full container image is reproducible; you can re-inspect what code ran

## Hardening Options

### 1. Restrict Network Access

**Default:** `--network=host` (full access)

**Restrictive:**
```bash
# Only loopback, block all external:
--network=none
```

**Allowlist-based:**
Use `iptables` or `firewall-cmd` rules inside the container, or configure systemd-resolved to block non-allowlisted domains.

See [CONFIGURATION.md](CONFIGURATION.md#network-hardening) for examples.

### 2. Read-Only Filesystem

Mount project directory as read-only if you only need to *inspect* generated code:

```bash
--mount type=bind,source=/path/to/project,target=/project,ro
```

**Trade-off:** Claude Code cannot write files; useful for audit-only scenarios.

### 3. Resource Limits

Cap CPU and memory to prevent resource exhaustion:

```bash
--cpus=2 --memory=4g
```

### 4. Disable Network Entirely

```bash
--network=none
```

**Trade-off:** Cannot install dependencies, fetch from external APIs, or push to GitHub.

### 5. Dropped Capabilities (Already Enabled)

The default setup drops all capabilities except those needed:

```bash
--cap-drop=ALL
--cap-add=NET_BIND_SERVICE  # If running web servers
```

Current dropped capabilities: `SYS_ADMIN`, `NET_ADMIN`, `SYS_BOOT`, `SYS_MODULE`, etc.

## Known Limitations

1. **Container Escapes**
   - Unpatched kernel vulnerabilities (e.g., Dirty COW, Spectre) could theoretically be exploited to break out
   - **Mitigation:** Keep host kernel patched

2. **Container Runtime Bugs**
   - Podman or Docker bugs could theoretically bypass isolation
   - **Mitigation:** Run latest stable versions; monitor security advisories

3. **Untrusted Base Image**
   - The base image (e.g., `ubuntu:24.04`) could be compromised
   - **Mitigation:** Verify image digest, build your own base image if paranoid

## Security Best Practices

1. **Always use Podman if possible** — native rootless is simpler and more reliable than Docker rootless mode
2. **Keep images updated** — rebuild with fresh base images periodically
3. **Audit dependencies** — even in sandboxed environment, compromised packages can cause damage
4. **Restrict network for sensitive projects** — especially if you don't want Claude Code to fetch arbitrary packages
5. **Review generated code** — sandbox contains damage but doesn't prevent bad code generation
6. **Use lock files** — `package-lock.json`, `poetry.lock`, etc. prevent supply chain surprises
7. **Secrets management** — never pass secrets in environment; use host-level secret stores

## Reporting Security Issues

If you discover a vulnerability in this sandbox setup, please report it **privately** to the maintainers before public disclosure. See [CONTRIBUTING.md](../CONTRIBUTING.md#security-reporting) for contact information.

---

**Next:** See [INSTALLATION.md](INSTALLATION.md) for setup, or [CONFIGURATION.md](CONFIGURATION.md) for detailed options.
