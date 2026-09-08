---
name: docker-sandbox
description: Startet Claude Code in einer isolierten, rootless Docker/Podman-Sandbox, in der nur der Projekt-Code gemountet ist. Trigger bei Anfragen wie "starte die Sandbox", "führe das isoliert aus", "im Container laufen lassen", "rootless container", oder wenn der User explizit nach isolierter/sandboxed Ausführung fragt.
---

# Docker/Podman Sandbox für Claude Code

## Zweck
Claude Code (oder eine Aufgabe darin) in einem isolierten, rootless Container
ausführen, der ausschließlich Zugriff auf das aktuelle Projektverzeichnis hat.
Kein Zugriff auf das restliche Host-Dateisystem, keine root-Rechte im
Container, keine geteilten Credentials außer einem dedizierten,
persistenten Config-Volume.

## Wann diese Skill nutzen
- User bittet um isolierte/sandboxed Ausführung von Claude Code oder eines Tasks
- User erwähnt "rootless", "container sandbox", "podman/docker sandbox"
- Vor riskanten Operationen (z. B. `--dangerously-skip-permissions`,
  Ausführen von unbekanntem/generiertem Code), wenn der User zusätzliche
  Isolation wünscht

## Voraussetzungen prüfen
1. Prüfen, ob `podman` oder `docker` verfügbar ist (`command -v podman` /
   `command -v docker`). Podman wird bevorzugt, da es nativ rootless ohne
   Daemon läuft.
2. Prüfen, ob `.claude-sandbox/Dockerfile` und
   `.claude-sandbox/run-claude-sandbox.sh` im Projekt vorhanden sind. Falls
   nicht, aus diesem Bundle kopieren.

## Ablauf
1. `chmod +x .claude-sandbox/run-claude-sandbox.sh` (einmalig)
2. Sandbox starten:
   ```bash
   ./.claude-sandbox/run-claude-sandbox.sh <projekt-pfad>
   ```
   Ohne Argument wird das aktuelle Verzeichnis gemountet.
3. Das Script:
   - baut das Image einmalig (UID/GID = Host-User, damit keine
     root-Dateien entstehen)
   - mountet **nur** `<projekt-pfad>` nach `/workspace`
   - nutzt bei Podman `--userns=keep-id` für echtes rootless
   - droppt alle Capabilities (`--cap-drop=ALL`)
   - hält Claude-Auth/Config in einem separaten, persistenten Volume statt
     im Host-`~/.claude` (Isolation zwischen Host und Sandbox)

## Sicherheitshinweise, die der User kennen sollte
- `--network=host` ist im Script standardmäßig aktiv (damit `claude` sich
  authentifizieren/API-Calls machen kann). Wer zusätzlich Netzwerk
  einschränken will, sollte das gegen ein Allowlist-Proxy-Setup tauschen
  (z. B. wie in `trailofbits/claude-code-devcontainer`) oder `--network=none`
  für rein lokale Tasks setzen.
- Das Config-Volume ist zwischen Sandbox-Läufen persistent, aber getrennt
  vom Host-`~/.claude` — nach dem ersten Start muss sich Claude Code in der
  Sandbox einmal neu authentifizieren.
- Bei Bedarf `--read-only` + gezielte `tmpfs`-Mounts ergänzen, wenn auch
  das Container-Dateisystem außerhalb von `/workspace` unveränderlich sein
  soll.

## Nicht tun
- Nicht das gesamte Host-`$HOME` oder `/` mounten, auch nicht read-only,
  außer der User verlangt es explizit.
- Nicht `--privileged` verwenden.
- Nicht den Host-`~/.claude`-Ordner direkt bind-mounten (Credentials/Session
  von anderen Projekten würden sonst in der Sandbox landen).
