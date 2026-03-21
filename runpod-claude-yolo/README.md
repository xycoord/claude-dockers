# runpod-claude-yolo

Docker image for running Claude Code autonomously on RunPod with `--dangerously-skip-permissions` mode, user isolation, safety hooks, and push notifications.

## Build

```bash
docker build -t runpod-claude-yolo .
```

## Usage

1. Create a RunPod pod with this image and set your environment variables
2. SSH into the pod as root
3. Run `claude-init` — this configures everything and drops you into a tmux session as the `claude` user
4. Run `yolo` to start Claude Code in autonomous mode

```
# Detach from tmux:  Ctrl+b then d
# Reattach (as root): claude-tmux
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | No | Claude API key (optional if using subscription) |
| `GITHUB_PAT` | No | GitHub PAT — configures git credential store |
| `GIT_EMAIL` | No | Git commit email (derives bot email as `user+claude@domain`) |
| `NTFY_TOPIC` | No | [ntfy.sh](https://ntfy.sh) topic for push notifications |
| `HF_TOKEN` | No | Hugging Face token for gated model downloads |

## What `claude-init` Does

1. Makes `/workspace` writable by the `claude` user
2. Forwards environment variables from root to the `claude` user's bashrc
3. Configures git identity and GitHub credentials
4. Symlinks session history to `/workspace/.claude-sessions` (persists across pod restarts)
5. Generates `~/.claude/CLAUDE.md` with GPU hardware context (model size limits, inference backend compatibility)
6. Starts a tmux session as the `claude` user

## Safety

- Claude runs as a non-root `claude` user (with sudo)
- A `PreToolUse` hook blocks destructive commands: `rm -rf /`, `mkfs`, `dd if=`, `DROP TABLE/DATABASE`, writes to `/dev/sd*`
- Push notifications via ntfy.sh alert you when Claude needs input or finishes a task

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Creates claude user, installs Claude Code, wires hooks and aliases |
| `claude-settings.json` | Hook config: PreToolUse safety filter + ntfy.sh notifications |
| `claude-init.sh` | Pod startup script — env forwarding, git setup, tmux |
| `block-dangerous-commands.sh` | PreToolUse hook that denies destructive shell commands |
| `notify.sh` | Notification/Stop hook that posts to ntfy.sh |
| `generate-claude-md.sh` | Generates `~/.claude/CLAUDE.md` with GPU/hardware context |

## Useful Aliases

- `yolo` (claude user) — `claude --dangerously-skip-permissions`
- `claude-tmux` (root) — reattach to the claude tmux session
- `claude-clean` (claude user) — delete session JSONL files over 100MB
