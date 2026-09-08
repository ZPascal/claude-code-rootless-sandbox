# Compliance & Regulatory Notes

This document addresses compliance considerations for regulated environments (SOC2, HIPAA, PCI-DSS, etc.).

> **Disclaimer:** This is informational, not legal advice. Consult your compliance team or legal counsel for your specific requirements.

## SOC2 Compliance

### What This Sandbox Provides

| SOC2 Requirement | Coverage | Notes |
|---|---|---|
| **Access Controls** | ✅ Partial | Isolation by namespace; audit trails via logs |
| **Encryption in Transit** | ⚠️ Configurable | Network traffic not encrypted by default; add TLS if needed |
| **Encryption at Rest** | ❌ Not Covered | Project files not encrypted; use filesystem-level encryption (LUKS) |
| **Audit Logging** | ✅ Yes | File modifications, process creation logged |
| **Segregation of Duties** | ✅ Partial | Sandbox isolates processes; users/roles still handled by host OS |
| **Change Management** | ⚠️ Manual | Container setup is reproducible; changes should be versioned in git |

### Recommendations for SOC2

1. **Enable Audit Logging**
   ```bash
   SANDBOX_AUDIT_LOG=true ./.claude-sandbox/run-claude-sandbox.sh 2>&1 | tee audit-$(date +%s).log
   ```

2. **Version Control Sandbox Configuration**
   ```bash
   git add .claude-sandbox/config-defaults.env
   git commit -m "feat: document sandbox security config"
   ```

3. **Regular Image Updates**
   ```bash
   # Weekly rebuild with latest base image
   podman pull ubuntu:24.04
   podman build -t claude-code-sandbox:latest .claude-sandbox/Dockerfile
   ```

4. **Network Restrictions**
   ```bash
   # For sensitive workloads, disable network:
   SANDBOX_NETWORK=none ./.claude-sandbox/run-claude-sandbox.sh
   ```

5. **Immutable Audit Logs**
   - Store logs on a separate, read-only filesystem or S3 bucket
   - Use write-once-read-many (WORM) storage where possible

---

## HIPAA Compliance (Healthcare)

### Key HIPAA Requirements

| Requirement | Sandbox Coverage | Action Required |
|---|---|---|
| **Access Control** | ✅ Yes | Sandbox isolates processes; log all access |
| **Audit Controls** | ✅ Yes | Enable audit logging (see below) |
| **Encryption** | ⚠️ Partial | Sandbox doesn't encrypt at-rest; use host-level encryption (LUKS, FileVault) |
| **Integrity Controls** | ✅ Yes | File permissions enforce integrity |
| **Transmission Security** | ⚠️ Manual | If Claude Code connects to health systems, require TLS/VPN |

### HIPAA Checklist

- [ ] **PHI Data** — Does Claude Code access Protected Health Information (PHI)?
  - If yes: restrict network (`SANDBOX_NETWORK=none`), enable audit logging
  - If no: proceed with default settings

- [ ] **Encryption at Rest** — Enable full-disk encryption on host
  ```bash
  # Linux: use LUKS
  sudo cryptsetup luksFormat /dev/sdX
  
  # macOS: use FileVault
  # Settings → Security → FileVault → Turn On
  ```

- [ ] **Audit Logging** — Enable and retain for 6+ years
  ```bash
  SANDBOX_AUDIT_LOG=true ./.claude-sandbox/run-claude-sandbox.sh 2>&1 | \
    tee /var/log/hipaa-audit-$(date +%Y-%m-%d).log
  ```

- [ ] **Access Logging** — Document who ran the sandbox, when, and for what purpose
  ```bash
  # Create a wrapper script:
  # audit-wrapper.sh
  echo "[$(date)] User: $USER, Project: $PWD, Command: $@" >> /var/log/sandbox-access.log
  ./.claude-sandbox/run-claude-sandbox.sh "$@"
  ```

- [ ] **Incident Response** — Have a plan for data breaches; audit logs are evidence

---

## PCI-DSS Compliance (Payment Processing)

### PCI-DSS Scope for Claude Code Sandbox

If Claude Code is used in systems that process, store, or transmit credit card data:

| PCI Requirement | Sandbox Role | Mitigation |
|---|---|---|
| **Network Segmentation** | ✅ Yes | Sandbox isolates process; doesn't replace network firewalls |
| **Malware Protection** | ⚠️ Partial | Sandbox contains; doesn't prevent |
| **Strong Encryption** | ❌ No | Sandbox doesn't encrypt traffic by default |
| **Access Control** | ✅ Yes | Namespace isolation; log access |
| **Vulnerability Management** | ⚠️ Manual | Keep base image and tools updated |

### PCI-DSS Checklist

- [ ] **Network Isolation** — Run sandbox on a separate network segment if processing PCI data
- [ ] **Encryption in Transit** — Require TLS for all external connections
  ```bash
  # Example: configure environment for HTTPS-only
  SANDBOX_ENV_EXTRA="CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt" \
    ./.claude-sandbox/run-claude-sandbox.sh
  ```

- [ ] **No Hardcoded Credentials** — Use environment secrets (not committed to git)
  ```bash
  # Load from secure vault, not files:
  export PCI_API_KEY=$(vault kv get -field=value secret/pci-key)
  ./.claude-sandbox/run-claude-sandbox.sh
  ```

- [ ] **Audit Logging** — Retain for 1+ year
- [ ] **Change Control** — Document all configuration changes in git

---

## ISO 27001 Compliance (Information Security)

### ISO 27001 Controls & Sandbox Mapping

| Control | Coverage |
|---|---|
| **A.5.1 — Information Security Policy** | ✅ Define sandbox usage policy |
| **A.6 — Organization** | ✅ Assign sandbox admin roles |
| **A.8 — Asset Management** | ⚠️ Sandbox images are assets; track versions |
| **A.9 — Access Control** | ✅ Sandbox enforces namespace isolation |
| **A.10 — Cryptography** | ⚠️ Not provided; use host-level encryption |
| **A.12 — Communications & Operations** | ✅ Audit logging covers this |
| **A.13 — System Acquisition, Development** | ✅ Sandbox hardens dev environments |
| **A.14 — Supplier Relations** | ⚠️ Audit vendors' use of sandbox |
| **A.15 — Information Security Incident Management** | ✅ Logs support incident response |

### ISO 27001 Recommendations

1. **Asset Register** — Document all sandbox instances
   ```bash
   # Create asset register:
   cat > .claude-sandbox/ASSET_REGISTER.md << EOF
   # Sandbox Assets
   
   - Container Image: claude-code-sandbox:latest (built: $(date))
   - Host OS: Ubuntu 24.04
   - Base Image: ubuntu:24.04
   - Dockerfile: .claude-sandbox/Dockerfile
   - Last Security Update: $(date)
   EOF
   ```

2. **Configuration Control** — Version all settings in git

3. **Incident Response Plan** — Document sandbox-specific incident procedures
   ```bash
   # Example: if container is compromised:
   # 1. Capture logs: docker logs <container>
   # 2. Preserve evidence: cp -r .claude-sandbox evidence/
   # 3. Investigate: analyze audit-*.log
   # 4. Rebuild: podman system prune -a && rebuild image
   ```

---

## General Best Practices for All Compliance Standards

### 1. Enable Audit Logging

```bash
# Create audit wrapper
cat > audit-sandbox.sh << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/sandbox-audit-$(date +%Y-%m-%d-%H-%M-%S).log"
echo "[$(date -Iseconds)] Starting sandbox for project: $PWD" >> $LOG_FILE
./.claude-sandbox/run-claude-sandbox.sh "$@" 2>&1 | tee -a $LOG_FILE
echo "[$(date -Iseconds)] Sandbox exited" >> $LOG_FILE
EOF

chmod +x audit-sandbox.sh
```

### 2. Version Control

```bash
# Commit all sandbox configuration
git add .claude-sandbox/ .claude/skills/docker-sandbox/
git commit -m "chore: version control sandbox security configuration"
```

### 3. Regular Updates

```bash
# Monthly: rebuild with latest base image
podman pull ubuntu:24.04
podman build -t claude-code-sandbox:latest .claude-sandbox/Dockerfile
```

### 4. Signed Commits (Optional)

```bash
# Sign all commits for compliance audit trail
git config user.signingkey <your-key-id>
git commit -S -m "chore: update sandbox configuration"
```

### 5. Documentation

- Document all configuration changes in commit messages
- Maintain a change log: `CHANGELOG.md`
- Keep security policy up-to-date: `SECURITY_POLICY.md`

### 6. Access Control

```bash
# Restrict who can modify sandbox configuration:
chmod 750 .claude-sandbox/
chmod 640 .claude-sandbox/config-defaults.env
```

### 7. Incident Response Template

```bash
cat > INCIDENT_RESPONSE.md << 'EOF'
# Sandbox Incident Response

## If a Sandbox is Compromised

1. **Isolate:** Disconnect the container from network
   ```bash
   SANDBOX_NETWORK=none ./.claude-sandbox/run-claude-sandbox.sh
   ```

2. **Preserve Evidence:**
   ```bash
   docker logs <container> > incident-logs-$(date +%s).txt
   ```

3. **Rebuild:** Delete image and rebuild from source
   ```bash
   podman image rm claude-code-sandbox:latest
   podman build -t claude-code-sandbox:latest .claude-sandbox/Dockerfile
   ```

4. **Notify:** Alert your security team and compliance officer

5. **Audit:** Review all audit logs for unauthorized access
EOF
```

---

## Regulatory Self-Assessment

Use this checklist to assess sandbox compliance with your requirements:

```markdown
## Compliance Checklist

- [ ] **Audit Logging Enabled** — SANDBOX_AUDIT_LOG=true
- [ ] **Network Restricted** — SANDBOX_NETWORK=none (if required)
- [ ] **Encryption at Rest** — Host filesystem encrypted (LUKS/FileVault)
- [ ] **Encryption in Transit** — TLS enforced for external connections
- [ ] **Access Control** — Sandbox limited to authorized users
- [ ] **Version Control** — Configuration in git with signed commits
- [ ] **Change Management** — All changes documented and approved
- [ ] **Incident Response Plan** — Written procedures for sandbox breaches
- [ ] **Regular Updates** — Base image updated monthly
- [ ] **Documentation** — Security policy and audit procedures documented
```

---

**Questions?** Consult your compliance/security team, or open an issue on GitHub with details (without revealing sensitive information).

**Next:** See [SECURITY.md](SECURITY.md) for technical security details.
