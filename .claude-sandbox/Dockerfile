# Minimales, rootless-freundliches Sandbox-Image für Claude Code
FROM node:20-slim

ARG USERNAME=claude
ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        ripgrep \
        less \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Nicht-root-User anlegen. UID/GID werden beim Build auf deinen Host-User
# gesetzt (siehe run-claude-sandbox.sh), damit Dateien im Mount nicht
# root gehören.
RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" -m "${USERNAME}"

RUN npm install -g @anthropic-ai/claude-code

USER ${USERNAME}
WORKDIR /workspace

ENTRYPOINT ["claude"]
