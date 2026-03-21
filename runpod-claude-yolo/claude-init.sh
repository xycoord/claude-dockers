#!/bin/bash
# Makes /workspace accessible to claude user and drops into a ready session
set -e

# Make workspace writable
chmod -R a+rwX /workspace 2>/dev/null || true

# Forward env vars to claude user (skip system vars)
SKIP_VARS="^(HOME|USER|LOGNAME|SHELL|PATH|PWD|TERM|SHLVL|_|MAIL|LANG|LC_|LS_COLORS|HOSTNAME|OLDPWD)="
env | grep -vE "$SKIP_VARS" | while IFS='=' read -r key value; do
  # Only forward vars with safe names
  if [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    sed -i "/^export ${key}=/d" /home/claude/.bashrc
    echo "export ${key}=\"${value}\"" >> /home/claude/.bashrc
  fi
done

# Ensure git config exists for claude user
CLAUDE_EMAIL="${GIT_EMAIL/@/+claude@}"
su - claude -c "git config --global user.email '${CLAUDE_EMAIL:-bot@example.com}'"
su - claude -c "git config --global user.name 'claude [bot]'"

# Set up git credentials if token provided
if [ -n "$GITHUB_PAT" ]; then
  su - claude -c "git config --global credential.helper store"
  su - claude -c "echo 'https://oauth2:${GITHUB_PAT}@github.com' > ~/.git-credentials"
  su - claude -c "chmod 600 ~/.git-credentials"
fi

# Persist session history in workspace
mkdir -p /workspace/.claude-sessions
chmod -R a+rwX /workspace/.claude-sessions
mkdir -p /home/claude/.claude
rm -rf /home/claude/.claude/projects
ln -sf /workspace/.claude-sessions /home/claude/.claude/projects
chown -R claude:claude /home/claude/.claude

# Generate machine-level CLAUDE.md
generate-claude-md

echo "Ready. Dropping into claude user in tmux..."
echo "Detach: Ctrl+b then d | Reattach: claude-tmux"

# Start or reattach tmux session as claude user in /workspace
su - claude -c "cd /workspace && tmux attach -d -t claude 2>/dev/null || tmux new-session -s claude 'bash --login -c \"sleep 0.1; clear; exec bash\"'"