# Installation Guide

This guide covers setup for different operating systems and container runtimes.

## System Requirements

- **Linux** (Ubuntu 20.04+, Debian 11+, Fedora 35+, CentOS 8+, Arch)
- **Container Runtime:** Podman (recommended) or Docker
- **Disk Space:** ~2GB for base image + your project
- **RAM:** 2GB minimum (4GB+ recommended)

> **Note:** macOS and Windows require Linux VM support (Docker Desktop with WSL2, Lima for Podman, etc.) — the setup runs in the Linux VM, not natively.

## Quick Install (Podman — Recommended)

### Step 1: Install Podman

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install podman
```

**Fedora/CentOS:**
```bash
sudo dnf install podman
```

**Arch:**
```bash
sudo pacman -S podman
```

**Verify installation:**
```bash
podman --version
```

### Step 2: Enable Rootless Mode (Optional, but Recommended)

```bash
# Podman is rootless by default. Verify:
podman run --rm alpine:latest id
# Output should show: uid=0(root) gid=0(root) groups=0(root)
# (This is inside the container; on the host, you're still unprivileged)
```

### Step 3: Copy Sandbox Files to Your Project

```bash
git clone https://github.com/yourusername/claude-code-rootless-sandbox.git /tmp/sandbox
cp -r /tmp/sandbox/.claude-sandbox /path/to/your/project/
cp -r /tmp/sandbox/.claude/skills/docker-sandbox /path/to/your/project/.claude/skills/
chmod +x /path/to/your/project/.claude-sandbox/run-claude-sandbox.sh
```

### Step 4: Run the Sandbox

```bash
cd /path/to/your/project
./.claude-sandbox/run-claude-sandbox.sh
```

---

## Docker Installation

### Step 1: Install Docker

**Ubuntu/Debian:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

**Fedora:**
```bash
sudo dnf install docker
sudo systemctl start docker
sudo systemctl enable docker
```

**Verify:**
```bash
docker --version
```

### Step 2: Enable Rootless Mode (Recommended)

Docker rootless mode requires additional setup:

```bash
# Install rootlesskit and slirp4netns
sudo apt install rootlesskit slirp4netns  # Ubuntu/Debian
# OR
sudo dnf install rootlesskit slirp4netns  # Fedora

# Enable rootless mode
dockerd-rootless-setuptool.sh install

# Verify
docker info | grep -i rootless
# Output: Rootless: true
```

**Add your user to docker group** (if not using rootless):
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Step 3: Copy Sandbox Files & Run

```bash
cp -r /tmp/sandbox/.claude-sandbox /path/to/your/project/
cp -r /tmp/sandbox/.claude/skills/docker-sandbox /path/to/your/project/.claude/skills/
chmod +x /path/to/your/project/.claude-sandbox/run-claude-sandbox.sh
cd /path/to/your/project
./.claude-sandbox/run-claude-sandbox.sh
```

---

## macOS Setup

macOS doesn't have native container support; you need a Linux VM.

### Option 1: Docker Desktop (Easier)

1. **Install [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)**
2. **Enable Docker rootless mode** (see Docker Installation above)
3. **Copy sandbox files** (same as Linux)
4. **Run:** `./.claude-sandbox/run-claude-sandbox.sh`

### Option 2: Podman via Lima (Advanced)

```bash
# Install Lima
brew install lima

# Start Podman VM
limactl start podman

# Use Podman as normal (it runs inside the Lima VM)
podman run --rm alpine:latest echo "Hello from Podman!"
```

Then follow Podman setup (Step 3 onwards).

---

## Windows Setup

Windows requires Windows Subsystem for Linux 2 (WSL2) with Docker or Podman.

### Step 1: Enable WSL2

```powershell
# PowerShell (as Administrator)
wsl --install
wsl --set-default-version 2
```

### Step 2: Install Docker Desktop or Podman

**Option A: Docker Desktop for Windows**
- Download from [docker.com/desktop](https://www.docker.com/desktop)
- Enable WSL2 backend in settings

**Option B: Podman via WSL2**
```bash
# Inside WSL2 terminal
sudo apt update && sudo apt install podman
```

### Step 3: Clone & Run

```bash
# Inside WSL2 terminal
cd /path/to/your/project
./.claude-sandbox/run-claude-sandbox.sh
```

---

## Troubleshooting

### "permission denied" when running sandbox script

**Fix:**
```bash
chmod +x /path/to/your/project/.claude-sandbox/run-claude-sandbox.sh
```

### "Cannot connect to container runtime"

**Podman:**
```bash
# Check if Podman socket is available
podman info

# If permission denied, restart Podman service:
systemctl --user restart podman
podman system reset  # Nuclear option; deletes all images
```

**Docker:**
```bash
# Check if Docker daemon is running
docker ps

# If not, start it:
sudo systemctl start docker

# Or check rootless mode:
systemctl --user status docker
```

### "Image not found"

The script builds the image on first run. If it fails:

```bash
# Rebuild image manually
podman build -t claude-code-sandbox:latest -f .claude-sandbox/Dockerfile .
# or with Docker:
docker build -t claude-code-sandbox:latest -f .claude-sandbox/Dockerfile .
```

### "Device or resource busy" (on Podman)

Sometimes leftover containers block. Clean up:

```bash
podman system prune -a
podman volume prune
```

### Network issues inside sandbox

Check your network configuration in [CONFIGURATION.md](CONFIGURATION.md#network-hardening).

Default is `--network=host`, which should work. If restricted, verify allowlist rules.

---

## Uninstall

To remove the sandbox from a project:

```bash
rm -rf .claude-sandbox
rm -rf .claude/skills/docker-sandbox
```

To remove Podman/Docker entirely (keep images for your own use):

**Podman:**
```bash
sudo apt remove podman  # or dnf remove podman
```

**Docker:**
```bash
sudo apt remove docker.io  # or dnf remove docker
```

---

**Next:** See [CONFIGURATION.md](CONFIGURATION.md) for advanced options, or [SECURITY.md](SECURITY.md) for security details.
