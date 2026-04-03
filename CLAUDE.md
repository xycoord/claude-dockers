# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A Docker image for running Claude Code on RunPod GPU instances. Runs as root with `IS_SANDBOX=1`, supporting both interactive and autonomous (`--dangerously-skip-permissions`) modes. Includes safety hooks, ntfy.sh push notifications, and tmux session management.

Based on `runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404`.

## File Structure

```
runpod-claude/
├── Dockerfile                  # Installs Claude Code, hooks, aliases, tmux config
├── claude-settings.json        # Hook config: PreToolUse safety filter, PostToolUse git push notify, ntfy.sh notifications
├── claude-init.sh              # Pod startup script (→ /usr/local/bin/claude-init): git, credentials, auth, tmux
├── block-dangerous-commands.sh # PreToolUse hook: blocks rm -rf /, mkfs, dd, DROP TABLE, etc.
├── notify.sh                   # Notification/Stop hook: posts to ntfy.sh via $NTFY_TOPIC
├── git-push-notify.sh          # PostToolUse hook: notifies via ntfy.sh on successful git push
└── generate-claude-md.sh       # Generates ~/.claude/CLAUDE.md with GPU/hardware context at init time
```

## Building

```bash
docker build -t runpod-claude ./runpod-claude
```

## Architecture

- **Runs as root** with `IS_SANDBOX=1` — no user switching complexity
- **Entrypoint**: `claude-init` is run manually after SSH-ing into the pod. It:
  - Configures git identity and GitHub PAT credentials
  - Symlinks `/workspace/.claude-sessions` → `/root/.claude/projects` so session history persists across pod restarts
  - Clones or updates custom skills from `$CLAUDE_SKILLS_REPO` into `~/.claude/skills/` (optional)
  - Generates `~/.claude/CLAUDE.md` with GPU hardware context and operational guidelines
  - Drops into a tmux session in `/workspace`
- **Safety hook** (`block-dangerous-commands.sh`): PreToolUse hook on Bash that denies destructive patterns (`rm -rf /`, `mkfs`, `dd if=`, `DROP TABLE/DATABASE`, writes to `/dev/sd*`)
- **Notifications** (`notify.sh`): Posts to ntfy.sh on Notification/Stop hook events. Requires `$NTFY_TOPIC` env var.
- **Git push notifications** (`git-push-notify.sh`): PostToolUse hook that notifies via ntfy.sh on successful git push.

### Key Environment Variables
| Variable | Purpose |
|---|---|
| `GITHUB_PAT` | GitHub personal access token for git credential store |
| `GIT_EMAIL` | Git commit email (also used to derive claude bot email) |
| `NTFY_TOPIC` | ntfy.sh topic for push notifications (optional) |
| `ANTHROPIC_API_KEY` | Claude API key (if set, skips OAuth login) |
| `HF_TOKEN` | Hugging Face token for gated model downloads |
| `CLAUDE_SKILLS_REPO` | Git repo URL for custom Claude skills (optional) |

### Useful Aliases
- `yolo` — runs `claude --dangerously-skip-permissions`
- `claude-tmux` — reattaches to the tmux session
- `claude-clean` — deletes session JSONL files over 100MB from `/workspace/.claude-sessions`
- `skills-pull` — pull latest skills from the repo
- `skills-push` — commit and push skill changes back to the repo

## RunPod Constraints (do NOT try to work around these)

- `/workspace` is a network mount: `chown` and `chgrp` fail. Use `chmod` instead.
- FUSE is unavailable: no `bindfs`, `sshfs`, or similar. `modprobe` doesn't work.
- All COPY'd scripts must be run through `dos2unix` in the Dockerfile — Windows line endings silently break shebangs.
- Do NOT modify RunPod's entrypoint or startup scripts. `claude-init` is run manually by the user after SSH-ing in.
