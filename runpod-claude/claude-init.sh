#!/bin/bash
# Initialises the pod for Claude Code: git, credentials, tmux
set -e

# Git identity
CLAUDE_EMAIL="${GIT_EMAIL/@/+claude@}"
git config --global user.email "${CLAUDE_EMAIL:-bot@example.com}"
git config --global user.name "claude [bot]"

# Git credentials
if [ -n "$GITHUB_PAT" ]; then
  git config --global credential.helper store
  echo "https://oauth2:${GITHUB_PAT}@github.com" > ~/.git-credentials
  chmod 600 ~/.git-credentials
fi

# Persist session history across pod restarts
mkdir -p /workspace/.claude-sessions
mkdir -p /root/.claude
rm -rf /root/.claude/projects
ln -sf /workspace/.claude-sessions /root/.claude/projects

# Generate machine-level CLAUDE.md with GPU context
generate-claude-md

echo "Ready. Dropping into tmux..."
echo "Detach: Ctrl+b then d | Reattach: claude-tmux"

# Start or reattach tmux session
tmux attach -d -t claude 2>/dev/null || \
  tmux new-session -s claude "bash -c 'read -t 0.1 -n 10000 discard 2>/dev/null; printf \"\ec\"; exec bash --login'"
