# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A collection of Docker images for running Claude Code on RunPod GPU instances. Two variants exist:

- **runpod-claude** — Minimal image: installs Claude Code as root with terminal notification hooks. Intended for interactive use where RunPod's default `/start.sh` entrypoint is preserved.
- **runpod-claude-yolo** — Full autonomous image: creates a dedicated `claude` user with sudo, runs Claude in `--dangerously-skip-permissions` mode (aliased as `yolo`), and adds safety hooks to block destructive shell commands. Includes tmux session management and ntfy.sh push notifications.

Both images are based on `runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404`.

## File Structure

```
runpod-claude/                  # Minimal image
├── Dockerfile                  # Installs Claude Code as root
├── claude-settings.json        # Notification hooks (terminal bell on Stop/Notification)
└── git-setup.sh                # Git identity config (currently unused, commented out in Dockerfile)

runpod-claude-yolo/             # Full autonomous image
├── Dockerfile                  # Creates claude user, installs Claude Code, wires hooks + aliases
├── claude-settings.json        # Hook config: PreToolUse safety filter, ntfy.sh notifications
├── claude-init.sh              # Pod startup script (→ /usr/local/bin/claude-init): env forwarding, git setup, tmux
├── block-dangerous-commands.sh # PreToolUse hook: blocks rm -rf /, mkfs, dd, DROP TABLE, etc.
├── notify.sh                   # Notification/Stop hook: posts to ntfy.sh via $NTFY_TOPIC
└── generate-claude-md.sh       # Generates ~/.claude/CLAUDE.md with GPU/hardware context at init time
```

## Building

```bash
# Minimal image
docker build -t runpod-claude ./runpod-claude

# Yolo (autonomous) image
docker build -t runpod-claude-yolo ./runpod-claude-yolo
```

## Architecture

### runpod-claude (minimal)
- Installs Claude Code as root, copies notification hooks into `/root/.claude/settings.json`
- `git-setup.sh` (currently commented out in Dockerfile) configures git identity from `$GIT_NAME` / `$GIT_EMAIL` env vars, then chains to RunPod's `/start.sh`

### runpod-claude-yolo (autonomous)
- **User isolation**: Claude Code runs as a non-root `claude` user with sudo access
- **Entrypoint**: `claude-init` (`claude-init.sh`) is the setup script run manually after the pod starts. It:
  - Makes `/workspace` writable by the `claude` user
  - Forwards environment variables from root to `claude`'s bashrc (filtering out system vars)
  - Configures git identity and GitHub PAT credentials
  - Symlinks `/workspace/.claude-sessions` → `/home/claude/.claude/projects` so session history persists across pod restarts
  - Restores auth credentials from `/workspace/.claude-auth/` if available
  - Runs `claude login` before tmux if no credentials or API key found (URL appears in plain SSH terminal for easy copying)
  - Drops into a tmux session as the `claude` user
- **Safety hook** (`block-dangerous-commands.sh`): PreToolUse hook on Bash that denies destructive patterns (`rm -rf /`, `mkfs`, `dd if=`, `DROP TABLE/DATABASE`, writes to `/dev/sd*`)
- **Notifications** (`notify.sh`): Posts to ntfy.sh on Notification/Stop hook events. Requires `$NTFY_TOPIC` env var.

### Key Environment Variables (yolo image)
| Variable | Purpose |
|---|---|
| `GITHUB_PAT` | GitHub personal access token for git credential store |
| `GIT_EMAIL` | Git commit email (also used to derive claude bot email) |
| `NTFY_TOPIC` | ntfy.sh topic for push notifications (optional) |
| `ANTHROPIC_API_KEY` | Claude API key (forwarded to claude user via claude-init) |

### Useful Aliases (yolo image)
- `yolo` — runs `claude --dangerously-skip-permissions`
- `claude-tmux` (root) — reattaches to the claude tmux session
- `claude-clean` (claude user) — deletes session JSONL files over 100MB from `/workspace/.claude-sessions`
- `claude-relogin` (claude user) — re-authenticate and persist new credentials to `/workspace`

## RunPod Constraints (do NOT try to work around these)

- `/workspace` is a network mount: `chown` and `chgrp` fail. Use `chmod` instead.
- FUSE is unavailable: no `bindfs`, `sshfs`, or similar. `modprobe` doesn't work.
- `su - claude` does NOT inherit root's env vars. That's why claude-init forwards them to bashrc.
- All COPY'd scripts must be run through `dos2unix` in the Dockerfile — Windows line endings silently break shebangs.
- Do NOT modify RunPod's entrypoint or startup scripts. `claude-init` is run manually by the user after SSH-ing in.