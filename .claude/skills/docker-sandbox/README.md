# Docker Sandbox Skill for Claude Code

This directory contains a Claude Code skill that integrates the rootless sandbox setup with Claude Code.

## Files

- **SKILL.md** — Skill definition and usage documentation

## What Is a Claude Code Skill?

A skill is a packaged set of instructions that Claude Code loads to understand and execute specialized tasks. This skill teaches Claude Code to:

1. Recognize sandbox-related requests (e.g., "run this in a sandbox")
2. Locate the sandbox setup in your project (`.claude-sandbox/run-claude-sandbox.sh`)
3. Launch and manage the isolated container environment

## Installation

This skill is installed automatically when you copy the `.claude/` directory to your project:

```bash
cp -r .claude/skills/docker-sandbox /path/to/your/project/.claude/skills/
```

Claude Code will automatically load the skill on the next startup.

## Enabling/Disabling

### Default Behavior

This skill is **enabled by default** when `SKILL.md` is present. Claude Code will automatically recognize sandbox requests like "run this in the sandbox", "execute isolated", etc.

### Disable Temporarily (Single Session)

```bash
export CLAUDE_DISABLE_DOCKER_SANDBOX=1
claude code
```

### Disable Permanently

**Option A:** Remove the skill file
```bash
rm .claude/skills/docker-sandbox/SKILL.md
```

**Option B:** Update Claude Code settings
```json
{
  "skills": {
    "docker-sandbox": {
      "enabled": false
    }
  }
}
```

### Re-enable

```bash
unset CLAUDE_DISABLE_DOCKER_SANDBOX
# or edit settings to set "enabled": true
```

## Customization

To customize the skill for your project:

1. Edit the `conditions` section in `SKILL.md` to add or change trigger keywords
2. Update examples to match your use cases
3. Modify descriptions if needed

Example: Add a custom keyword

```yaml
conditions:
  - keywords: ["sandbox", "isolated", "myproject-sandbox"]  # Added "myproject-sandbox"
```

## See Also

- **[SKILL.md](SKILL.md)** — Full skill definition
- **[../../docs/CONFIGURATION.md](../../docs/CONFIGURATION.md)** — Sandbox configuration options
- **[../../docs/SECURITY.md](../../docs/SECURITY.md)** — Security documentation

---

For questions, see the [main repository documentation](https://github.com/yourusername/claude-code-rootless-sandbox).
