FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash

# Add to PATH
ENV PATH="/root/.local/bin:$PATH"

RUN mkdir -p /root/.claude
COPY claude-settings.json /root/.claude/settings.json

# Add git setup script (don't overwrite RunPod's /start.sh!)
# COPY git-setup.sh /git-setup.sh
# RUN chmod +x /git-setup.sh

# Override CMD to run our setup first, then RunPod's original start script
# CMD ["/git-setup.sh"]