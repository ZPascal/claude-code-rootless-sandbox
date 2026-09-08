# Security Policy

## Reporting Security Vulnerabilities

We take security seriously. If you discover a security vulnerability, please report it responsibly.

### How to Report

**Use GitHub's Private Security Advisory feature:**

1. Navigate to: https://github.com/ZPascal/claude-code-rootless-sandbox/security/advisories
2. Click "Report a vulnerability"
3. Provide:
   - **Title:** Brief description of the vulnerability
   - **Description:** Detailed explanation of what's vulnerable and why
   - **Steps to reproduce:** How to trigger the issue
   - **Impact:** What damage could an attacker cause? Who is affected?
   - **Affected versions:** Which versions/configurations are impacted
   - **Fix:** Suggested patch or mitigation (if you have one)

### Response Timeline

- **48 hours:** Acknowledgment and initial assessment
- **1-2 weeks:** Fix development and testing
- **Release:** Patched version published with security advisory
- **Credit:** Public acknowledgment (unless you prefer anonymity)

### Do NOT

- Post vulnerability details publicly before a fix is available
- Exploit the vulnerability for any purpose
- Demand payment or compensation
- Contact us through non-official channels

### Do

- Report early and provide detailed information
- Give us time to develop and test a fix
- Work with us on coordinated disclosure
- Follow responsible disclosure practices

---

## Security Best Practices for Users

### Using This Sandbox

1. **Keep images updated** — Rebuild weekly with latest base image
   ```bash
   podman pull ubuntu:24.04
   podman build -t claude-code-sandbox:latest .claude-sandbox/Dockerfile
   ```

2. **Enable audit logging** — Capture all activity
   ```bash
   SANDBOX_AUDIT_LOG=true ./.claude-sandbox/run-claude-sandbox.sh 2>&1 | tee audit.log
   ```

3. **Restrict network** — If not needed
   ```bash
   SANDBOX_NETWORK=none ./.claude-sandbox/run-claude-sandbox.sh
   ```

4. **Review generated code** — Don't blindly trust AI output
5. **Keep host OS patched** — The sandbox is only as secure as the kernel
6. **Use secrets management** — Never hardcode credentials in environment

### Compliance & Auditing

See [docs/COMPLIANCE.md](docs/COMPLIANCE.md) for guidance on:
- SOC2 compliance
- HIPAA requirements
- PCI-DSS standards
- ISO 27001 controls

---

## Known Limitations

This sandbox provides **process isolation**, not perfect security:

- **Kernel vulnerabilities** could break out (mitigated by keeping OS patched)
- **Supply chain attacks** still possible (compromised dependencies)
- **Misconfiguration** can reduce security (mount extra directories, enable network unnecessarily)
- **Side-channel attacks** are theoretically possible (not practically prevented)

See [docs/SECURITY.md](docs/SECURITY.md) for threat model and hardening details.

---

## Supported Versions

| Version | Status | Updates |
|---------|--------|---------|
| Latest  | Active | Security + feature updates |
| 1 minor back | Supported | Security updates only |
| Older   | Unsupported | No updates |

---

## Contact

- **Private Security Advisory:** https://github.com/ZPascal/claude-code-rootless-sandbox/security/advisories
- **Issues:** https://github.com/ZPascal/claude-code-rootless-sandbox/issues
- **Discussions:** https://github.com/ZPascal/claude-code-rootless-sandbox/discussions

---

**Thank you for helping keep this project secure.** 🔒
