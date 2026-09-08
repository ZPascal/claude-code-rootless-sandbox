# Contributing Guidelines

Thank you for your interest in contributing to the Claude Code rootless sandbox project! This document outlines how to get involved.

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. All contributors must adhere to the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

## How to Contribute

### Reporting Bugs

Found a bug? Please open an issue with:

1. **Description** — What's broken?
2. **Steps to Reproduce** — How do we trigger it?
3. **Expected Behavior** — What should happen?
4. **Actual Behavior** — What actually happens?
5. **Environment** — OS, container runtime, versions
6. **Logs** — Error messages or sandbox logs (sanitize for secrets)

### Requesting Features

Have an idea for improvement? Open a feature request issue:

1. **Problem Statement** — Why is this needed?
2. **Proposed Solution** — How should it work?
3. **Alternatives** — Other approaches you considered
4. **Use Cases** — Who would benefit?

### Security Reporting

**Do not open public issues for security vulnerabilities.**

Instead, email the maintainers at: **[security contact — to be added]**

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Your suggested fix (if any)

We'll acknowledge receipt within 48 hours and work on a fix. Please allow 90 days for a patch before public disclosure.

## Development Setup

### Clone the Repository

```bash
git clone https://github.com/yourusername/claude-code-rootless-sandbox.git
cd claude-code-rootless-sandbox
```

### Make Changes

1. **Create a branch:**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

2. **Make your changes** — follow the style guide below

3. **Test locally:**
   ```bash
   ./.claude-sandbox/run-claude-sandbox.sh
   ```

4. **Run tests** (if applicable):
   ```bash
   ./tests/test-isolation.sh
   ./tests/test-rootless.sh
   ```

### Style Guide

- **Bash scripts:** Follow [Google's shell style guide](https://google.github.io/styleguide/shellguide.html)
- **Documentation:** Plain English, clear and concise; 80-character line limit
- **Dockerfile:** Multi-stage builds when possible; add comments for non-obvious decisions
- **Commit messages:** Imperative mood, first line 50 chars max, wrap body at 72 chars

#### Example Commit Message

```
Add network hardening documentation with domain allowlist example

- Document restricted network configuration
- Add example for domain-based network policy
- Link to CONFIGURATION.md for advanced options

Fixes #42
```

### Submit a Pull Request

1. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Open a PR on GitHub** with:
   - Clear title (e.g., "Fix: resolve UID mapping on Fedora")
   - Description of changes
   - Reference to related issues (e.g., "Fixes #42")
   - Note if this is a breaking change

3. **Address feedback** — we'll review and suggest changes

4. **Merge** — once approved, we'll merge your PR

## Testing

### Before Submitting a PR

1. **Run existing tests:**
   ```bash
   bash ./tests/test-isolation.sh
   bash ./tests/test-rootless.sh
   bash ./tests/test-permissions.sh
   ```

2. **Manual testing:**
   - Test on your OS/container runtime
   - Verify sandbox still works with your changes
   - Check documentation links

3. **Lint and validate:**
   ```bash
   # For Bash:
   shellcheck .claude-sandbox/*.sh
   
   # For Dockerfile:
   docker lint .claude-sandbox/Dockerfile  # if you have hadolint
   ```

### Adding Tests

If you add a feature, add a test for it:

```bash
# Create test-your-feature.sh
#!/bin/bash
set -e

echo "Testing your feature..."

# Your test logic here

echo "✓ Test passed"
```

Then run: `bash ./tests/test-your-feature.sh`

## Documentation

If you change behavior or add features, update the docs:

- **New feature?** Update `docs/CONFIGURATION.md`
- **New OS support?** Update `docs/INSTALLATION.md`
- **Security change?** Update `docs/SECURITY.md`
- **Compliance impact?** Update `docs/COMPLIANCE.md`

Keep docs clear and link to related sections.

## Licensing

By contributing, you agree that your contributions will be licensed under the Apache License 2.0 (see [LICENSE](LICENSE)).

## Recognition

Contributors will be recognized in:

- `CONTRIBUTORS.md` (maintained list)
- GitHub contributors graph
- Release notes (for significant contributions)

## Questions?

Open an issue or reach out to the maintainers. We're here to help!

---

**Thank you for contributing! 🎉**
