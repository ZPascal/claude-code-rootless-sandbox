# Enterprise Setup Example

This example demonstrates a production-ready sandbox configuration for regulated environments (SOC2, HIPAA, PCI-DSS, ISO 27001).

## Features

- **Audit logging** — All activity captured to audit log
- **Network restrictions** — No external network access by default
- **Resource limits** — CPU and memory constraints
- **Read-only filesystem** — Code inspection without modification
- **Compliance checklist** — Pre-built configuration for regulated workloads

## Setup

1. Copy the sandbox files:

```bash
cp -r ../../.claude-sandbox .
cp -r ../../.claude .
chmod +x .claude-sandbox/run-claude-sandbox.sh
```

2. Review the compliance configuration:

```bash
cat compliance-checklist.md
```

3. Start the sandbox with enterprise settings:

```bash
# Audit mode: no network, limited resources, logging enabled
SANDBOX_NETWORK=none SANDBOX_CPUS=2 SANDBOX_MEMORY=4g SANDBOX_AUDIT_LOG=true \
  ./.claude-sandbox/run-claude-sandbox.sh

# Or use the provided script:
bash start-audit-sandbox.sh
```

## Files

- **compliance-checklist.md** — Pre-flight checks for regulated environments
- **start-audit-sandbox.sh** — Launch script with enterprise defaults
- **sample-policy.md** — Example security policy for your team

## Compliance Mapping

See `compliance-checklist.md` for mappings to:

- **SOC2** — Access controls, audit trails, encryption
- **HIPAA** — PHI data protection, audit logging, encryption
- **PCI-DSS** — Network segmentation, encryption, access control
- **ISO 27001** — Information security, asset management, incident response

## Audit Logs

Audit logs are written to:

```bash
# Default (stdout)
./.claude-sandbox/run-claude-sandbox.sh 2>&1 | tee audit-$(date +%Y-%m-%d-%H-%M-%S).log

# Or modify the start script to write to a file:
tail -f sandbox-audit.log
```

Each log entry includes:

- Timestamp
- Container ID
- Command executed
- User (UID/GID)
- Exit code

## Security Hardening Checklist

- [ ] Network disabled (`SANDBOX_NETWORK=none`)
- [ ] Resource limits set (`SANDBOX_CPUS`, `SANDBOX_MEMORY`)
- [ ] Audit logging enabled (`SANDBOX_AUDIT_LOG=true`)
- [ ] Base image is latest stable (`docker pull ubuntu:24.04`)
- [ ] No secrets in environment variables
- [ ] Logs are archived to WORM storage or S3
- [ ] Container image is signed (if using enterprise registry)
- [ ] Incident response plan documented
- [ ] Regular security updates (weekly base image rebuild)
- [ ] Access control enforced (who can run `run-claude-sandbox.sh`)

## Next Steps

1. **Document your policy** — Adapt `sample-policy.md` for your organization
2. **Test compliance** — Run through the checklist in `compliance-checklist.md`
3. **Automate audits** — Set up log rotation, archival, and retention
4. **Incident response** — Document what to do if a sandbox is compromised
5. **Team training** — Ensure all team members understand the sandbox workflow

## See Also

- **[../../docs/COMPLIANCE.md](../../docs/COMPLIANCE.md)** — Detailed compliance guidance
- **[../../docs/SECURITY.md](../../docs/SECURITY.md)** — Security details
- **[../../docs/CONFIGURATION.md](../../docs/CONFIGURATION.md)** — All configuration options

---

For questions or issues, see the [main repository](https://github.com/yourusername/claude-code-rootless-sandbox).
