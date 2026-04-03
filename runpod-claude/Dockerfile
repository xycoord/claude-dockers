FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

# Install dependencies
RUN apt-get update && apt-get install -y tmux jq dos2unix && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Claude Code as root
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/root/.local/bin:$PATH"

# Allow Claude Code to run as root in autonomous mode
ENV IS_SANDBOX=1

# Hooks
RUN mkdir -p /root/.claude/hooks
COPY claude-settings.json /root/.claude/settings.json
COPY block-dangerous-commands.sh /root/.claude/hooks/block-dangerous-commands.sh
COPY notify.sh /root/.claude/hooks/notify.sh
COPY git-push-notify.sh /root/.claude/hooks/git-push-notify.sh
RUN dos2unix /root/.claude/settings.json /root/.claude/hooks/*.sh && \
    chmod +x /root/.claude/hooks/*.sh

# Init and utility scripts
COPY claude-init.sh /usr/local/bin/claude-init
COPY generate-claude-md.sh /usr/local/bin/generate-claude-md
RUN dos2unix /usr/local/bin/claude-init /usr/local/bin/generate-claude-md && \
    chmod +x /usr/local/bin/claude-init /usr/local/bin/generate-claude-md

# Default working directory
RUN echo '[ -d /workspace ] && cd /workspace' >> /root/.profile

# Aliases
RUN echo "alias yolo='claude --dangerously-skip-permissions'" >> /root/.bashrc && \
    echo "alias claude-tmux='tmux attach -d -t claude'" >> /root/.bashrc && \
    echo "alias claude-clean='find /workspace/.claude-sessions -name \"*.jsonl\" -size +100M -delete'" >> /root/.bashrc && \
    echo "alias skills-pull='git -C /root/.claude/skills pull'" >> /root/.bashrc && \
    echo "alias skills-push='git -C /root/.claude/skills add -A && git -C /root/.claude/skills commit -m \"Update skills\" && git -C /root/.claude/skills push'" >> /root/.bashrc

# tmux config
RUN echo -e "set -g mouse on\nset -g aggressive-resize on" > /root/.tmux.conf
