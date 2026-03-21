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

# Persist auth credentials in workspace (survives pod restarts)
mkdir -p /workspace/.claude-auth
chmod 700 /workspace/.claude-auth

# Restore saved credentials if available
if [ -f /workspace/.claude-auth/.credentials.json ]; then
  cp /workspace/.claude-auth/.credentials.json /home/claude/.claude/.credentials.json
fi

chown -R claude:claude /home/claude/.claude

# Generate machine-level CLAUDE.md
generate-claude-md

# Authenticate if needed — BEFORE tmux so the interactive auth flow works in the plain SSH terminal
if [ -n "$ANTHROPIC_API_KEY" ]; then
  echo "Using ANTHROPIC_API_KEY for authentication."
elif su - claude -c "/home/claude/.local/bin/claude auth status" &>/dev/null; then
  echo "Already authenticated."
else
  echo ""
  echo "No credentials found. Launching Claude for authentication..."
  echo ""
  su -l claude -c "cd /workspace && /home/claude/.local/bin/claude /exit"

  # Persist credentials if login succeeded
  if su - claude -c "/home/claude/.local/bin/claude auth status" &>/dev/null; then
    su - claude -c "mkdir -p /workspace/.claude-auth && cp ~/.claude/.credentials.json /workspace/.claude-auth/.credentials.json && chmod 600 /workspace/.claude-auth/.credentials.json" 2>/dev/null
    echo "Credentials saved (will persist across pod restarts)."
  else
    echo "Warning: authentication not completed. Run claude-relogin inside the session."
  fi
fi

echo ""
echo "Ready. Dropping into claude user in tmux..."
echo "Detach: Ctrl+b then d | Reattach: claude-tmux"

# Start or reattach tmux session as claude user in /workspace
su - claude -c "cd /workspace && tmux attach -d -t claude 2>/dev/null || tmux new-session -s claude 'bash --login -c \"sleep 1; read -t 0.1 -n 10000 discard 2>/dev/null; printf \\\"\\\\ec\\\"; exec bash\"'"