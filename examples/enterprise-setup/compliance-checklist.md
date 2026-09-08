# Enterprise Compliance Checklist

Use this checklist before running Claude Code in regulated environments.

## Pre-Flight Checks

### Security Configuration

- [ ] Sandbox image is built from latest base image
  ```bash
  podman pull ubuntu:24.04
  podman build -t claude-code-sandbox:latest .claude-sandbox/Dockerfile
  ```

- [ ] Network is restricted (if required)
  ```bash
  SANDBOX_NETWORK=none ./.claude-sandbox/run-claude-sandbox.sh
  ```

- [ ] Resource limits are set
  ```bash
  SANDBOX_CPUS=2 SANDBOX_MEMORY=4g ./.claude-sandbox/run-claude-sandbox.sh
  ```

- [ ] Audit logging is enabled
  ```bash
  SANDBOX_AUDIT_LOG=true ./.claude-sandbox/run-claude-sandbox.sh 2>&1 | tee audit.log
  ```

### Data Protection

- [ ] Filesystem encryption enabled on host (LUKS, FileVault, BitLocker)
- [ ] No credentials in environment variables
- [ ] Secrets sourced from secure vault (not files)
- [ ] Project directory does not contain PII/PHI/PCI data without encryption

### Access Control

- [ ] Only authorized users can execute `run-claude-sandbox.sh`
  ```bash
  chmod 750 .claude-sandbox/
  ```

- [ ] sudo access logged and audited
- [ ] User authentication (LDAP, Kerberos, SSO) enforced if applicable

### Audit & Logging

- [ ] Audit logs are being captured
  ```bash
  tail -f audit-*.log
  ```

- [ ] Logs are retained for [YOUR RETENTION PERIOD] (e.g., 1 year for PCI-DSS)
- [ ] Logs are protected from modification (write-once storage if possible)
- [ ] Log rotation configured for large environments
- [ ] Logs are indexed/searchable (SIEM integration if applicable)

### Incident Response

- [ ] Incident response plan documented (see below)
- [ ] Team trained on sandbox incident procedures
- [ ] Contact information for security team available
- [ ] Evidence preservation procedures defined

## Compliance Framework Mapping

### SOC2 - CC (Control Criteria)

| Requirement | Sandbox Coverage | Evidence |
|---|---|---|
| CC6.1 — Data Classification | ✅ Partial | Container prevents unauthorized access |
| CC6.2 — Access Control | ✅ Yes | UID/GID isolation, audit logs |
| CC7.1 — System Monitoring | ✅ Yes | Audit logs capture all activity |
| CC7.2 — System Monitoring | ✅ Yes | Logs accessible for review |
| CC8.1 — Change Management | ⚠️ Manual | Dockerfile versioned in git |

**To achieve SOC2 compliance:**
1. Enable audit logging
2. Store logs with audit trail protection
3. Document configuration in change log
4. Conduct regular audits (quarterly minimum)

### HIPAA - Security Rule

| Requirement | Sandbox Coverage | Action |
|---|---|---|
| 45 CFR §164.308(a)(3) — Workforce Security | ✅ Partial | Use with host OS access controls |
| 45 CFR §164.312(a)(1) — Access Control | ✅ Yes | UID/GID mapping, isolation |
| 45 CFR §164.312(a)(2)(i) — Audit Controls | ✅ Yes | Enable audit logging |
| 45 CFR §164.312(c)(1) — Integrity | ✅ Yes | File permissions enforced |
| 45 CFR §164.312(c)(2) — Encryption | ⚠️ Host-Level | Use host filesystem encryption |

**To achieve HIPAA compliance:**
1. Encrypt data at rest (LUKS, FileVault)
2. Encrypt data in transit (TLS for API calls)
3. Enable audit logging (6+ year retention)
4. Implement access controls
5. Train staff on compliance

### PCI-DSS

| Requirement | Sandbox Coverage | Action |
|---|---|---|
| 1. Network Segmentation | ✅ Yes | Disable network (`SANDBOX_NETWORK=none`) |
| 2. Strong Encryption | ⚠️ Partial | Use TLS for connections, LUKS for disk |
| 3. Access Control | ✅ Yes | UID/GID isolation, RBAC via host |
| 6. Security Testing | ✅ Partial | Regular image rebuilds with latest patches |
| 10. Logging & Monitoring | ✅ Yes | Enable audit logging, review regularly |
| 11. Security Testing | ✅ Partial | Regular vulnerability scans |

**To achieve PCI-DSS compliance:**
1. Restrict network access
2. Enforce TLS for all connections
3. Implement strong access controls
4. Enable comprehensive logging
5. Conduct quarterly vulnerability assessments

### ISO 27001

| Control | Sandbox Coverage | Evidence |
|---|---|---|
| A.5.1 — Information Security Policy | ⚠️ Manual | Document sandbox usage policy |
| A.6.1 — Organization | ⚠️ Manual | Assign sandbox admin roles |
| A.8.1 — Asset Inventory | ⚠️ Manual | Track container images, configurations |
| A.9.1 — Access Control | ✅ Yes | UID/GID isolation, audit logs |
| A.10.3 — Segregation of Duties | ✅ Partial | Namespace isolation enforced |
| A.12.1 — Operations | ✅ Yes | Audit logs, configuration versioning |
| A.12.3 — Backup & Recovery | ⚠️ Manual | Document backup procedures for logs |
| A.15.1 — Incident Management | ⚠️ Manual | Document incident response plan |

**To achieve ISO 27001 compliance:**
1. Create information security policy
2. Maintain asset register (container images, configs)
3. Enable audit logging
4. Document incident response procedures
5. Conduct regular security reviews

## Incident Response Procedure

If a sandbox is suspected to be compromised:

### Immediate Actions (< 1 hour)

1. **Isolate**
   ```bash
   # Stop the container immediately
   podman stop --all
   ```

2. **Preserve Evidence**
   ```bash
   # Capture logs
   podman logs <container-id> > incident-evidence-$(date +%s).txt
   # Archive entire project
   tar czf incident-evidence-$(date +%s).tar.gz /path/to/project
   ```

3. **Notify**
   - Contact security team
   - Contact compliance officer
   - Document the incident

### Investigation (< 4 hours)

1. **Analyze Logs**
   ```bash
   # Review audit logs for unauthorized activity
   grep -i "suspicious\|error\|access denied" audit-*.log
   ```

2. **Identify Scope**
   - What was executed?
   - What files were accessed?
   - What network connections were made?
   - Who had access?

3. **Document Findings**
   - Create incident report
   - Include timeline, impact, root cause

### Recovery (< 24 hours)

1. **Remediate**
   ```bash
   # Delete compromised image
   podman image rm claude-code-sandbox:latest
   # Rebuild from clean source
   podman build -t claude-code-sandbox:latest .claude-sandbox/Dockerfile
   ```

2. **Verify**
   - Run security validation tests
   - Confirm isolation properties intact

3. **Communicate**
   - Notify affected parties
   - Document lessons learned
   - Update procedures if needed

## Regular Maintenance

### Weekly

- [ ] Review audit logs for anomalies
- [ ] Check for base image security updates
- [ ] Verify access controls

### Monthly

- [ ] Rebuild sandbox image with latest base image
  ```bash
  podman pull ubuntu:24.04
  podman build -t claude-code-sandbox:latest .claude-sandbox/Dockerfile
  ```
- [ ] Rotate audit logs
- [ ] Review security incidents

### Quarterly

- [ ] Full security audit
- [ ] Compliance review against regulatory requirements
- [ ] Penetration testing (if applicable)
- [ ] Disaster recovery drill

### Annually

- [ ] Complete compliance assessment
- [ ] Audit trail review
- [ ] Policy update and team re-training

---

**Remember:** The sandbox is *one layer* of security. It should be combined with:
- Host OS hardening
- Network segmentation
- Identity & access management
- Incident response planning
- Regular security training

For questions, see [../../docs/COMPLIANCE.md](../../docs/COMPLIANCE.md) or contact your security team.
