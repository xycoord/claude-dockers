FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

# Create claude user with sudo
RUN useradd -m -s /bin/bash claude && \
    apt-get update && apt-get install -y sudo acl tmux jq dos2unix && \
    echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Claude Code for the claude user
RUN su - claude -c "curl -fsSL https://claude.ai/install.sh | bash" && \
    echo 'export PATH="/home/claude/.local/bin:$PATH"' >> /home/claude/.bashrc

# Set up yolo alias
RUN echo "alias yolo='claude --dangerously-skip-permissions'" >> /home/claude/.bashrc

# Safety hooks
RUN mkdir -p /home/claude/.claude/hooks && \
    chown -R claude:claude /home/claude/.claude

COPY claude-settings.json /home/claude/.claude/settings.json
COPY block-dangerous-commands.sh /home/claude/.claude/hooks/block-dangerous-commands.sh
RUN dos2unix /home/claude/.claude/settings.json /home/claude/.claude/hooks/block-dangerous-commands.sh && \
    chmod +x /home/claude/.claude/hooks/block-dangerous-commands.sh && \
    chown -R claude:claude /home/claude/.claude

# Setup script
COPY claude-init.sh /usr/local/bin/claude-init
RUN dos2unix /usr/local/bin/claude-init && chmod +x /usr/local/bin/claude-init

RUN echo "alias claude-tmux='su - claude -c \"tmux attach -d -t claude\"'" >> /root/.bashrc
RUN echo "alias claude-clean='find /workspace/.claude-sessions -name \"*.jsonl\" -size +100M -delete'" >> /home/claude/.bashrc

RUN echo -e "set -g mouse on\nset -g aggressive-resize on" > /home/claude/.tmux.conf && \
    chown claude:claude /home/claude/.tmux.conf

COPY notify.sh /home/claude/.claude/hooks/notify.sh
RUN dos2unix /home/claude/.claude/hooks/notify.sh && \
    chmod +x /home/claude/.claude/hooks/notify.sh

COPY generate-claude-md.sh /usr/local/bin/generate-claude-md
RUN dos2unix /usr/local/bin/generate-claude-md && chmod +x /usr/local/bin/generate-claude-md