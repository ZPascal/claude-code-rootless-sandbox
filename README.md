# Claude Code Rootless Sandbox

Isoliertes, rootless Docker/Podman-Setup für Claude Code. Es wird
ausschließlich das Projektverzeichnis in den Container gemountet — kein
Zugriff aufs restliche Host-Filesystem, keine root-Rechte, kein Teilen von
`~/.claude` mit dem Host.

## Installation ins eigene Projekt

```bash
# Im Root deines Projekts:
cp -r .claude-sandbox /pfad/zu/deinem/projekt/
cp -r .claude/skills/docker-sandbox /pfad/zu/deinem/projekt/.claude/skills/
chmod +x /pfad/zu/deinem/projekt/.claude-sandbox/run-claude-sandbox.sh
```

Danach committen (oder in `.gitignore` mit Bedacht behandeln — das Setup
selbst ist unproblematisch, es enthält keine Secrets).

## Manuell starten

```bash
cd dein-projekt
./.claude-sandbox/run-claude-sandbox.sh
```

Optional anderes Verzeichnis:

```bash
./.claude-sandbox/run-claude-sandbox.sh ~/projekte/anderes-projekt
```

## Automatisch via Skill

Sobald `.claude/skills/docker-sandbox/SKILL.md` im Projekt liegt, erkennt
Claude Code selbst Anfragen wie "starte die Sandbox" oder "führ das isoliert
aus" und ruft das Run-Script eigenständig auf.

## Was rootless hier konkret bedeutet

- **Podman (empfohlen):** läuft ganz ohne root-Daemon; `--userns=keep-id`
  mappt deine normale Host-UID 1:1 in den Container — Dateien, die Claude
  im Mount anlegt, gehören dir, nicht `root`.
- **Docker:** volle Rootless-Garantien nur mit
  [Docker rootless mode](https://docs.docker.com/engine/security/rootless/)
  installiert. Ohne das läuft der Docker-Daemon selbst weiterhin als root
  auf dem Host, auch wenn der Container-Prozess intern als Nicht-root-User
  fährt (das Script setzt `--user $(id -u):$(id -g)`).
- Zusätzlich in beiden Fällen: `--cap-drop=ALL`, `--security-opt
  no-new-privileges`, keine `--privileged`-Flags, kein Host-Mount außerhalb
  des Projektordners.

## Anpassungen, die du wahrscheinlich willst

- **Netzwerk einschränken:** `--network=host` im Script gegen
  `--network=none` (rein lokale Tasks) oder ein Proxy-Allowlist-Setup
  tauschen, falls Claude nur zu bestimmten Domains dürfen soll.
- **Zusätzliche Tools im Image:** Dockerfile erweitern (z. B. Python,
  Rust, Go je nach Projekt).
- **`--dangerously-skip-permissions`:** kann in der Sandbox sicherer
  genutzt werden als auf dem Host, da der Blast Radius auf den Container
  begrenzt ist — Netzwerk-Policy trotzdem beachten.
