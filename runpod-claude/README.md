# runpod-claude

Docker image for running Claude Code on RunPod GPU instances. Supports both interactive and autonomous (`--dangerously-skip-permissions`) modes. Runs as root with `IS_SANDBOX=1`.

Based on `runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404`.

## Build

```bash
docker build -t runpod-claude .
```

## Usage

1. Create a RunPod pod using the built image
2. SSH in as root
3. Run `claude-init`

This configures git, sets up session persistence, generates a GPU-aware CLAUDE.md, and drops you into a tmux session in `/workspace`.

Inside tmux:
- `claude` — interactive mode
- `yolo` — autonomous mode (`claude --dangerously-skip-permissions`)

Auth happens when you first run `claude` or `yolo`. Credentials don't persist across pod restarts — just re-auth each time.

## Environment Variables

Set these in the RunPod pod configuration:

| Variable | Required | Purpose |
|---|---|---|
| `GITHUB_PAT` | For git push | GitHub personal access token for credential store |
| `GIT_EMAIL` | For git commits | Git commit email (a `+claude` suffix is added automatically) |
| `NTFY_TOPIC` | No | ntfy.sh topic for push notifications |
| `ANTHROPIC_API_KEY` | No | If set, uses API key auth instead of OAuth |
| `HF_TOKEN` | For gated models | Hugging Face token for downloading gated models |
| `CLAUDE_SKILLS_REPO` | No | Git repo URL for custom Claude skills |

## What `claude-init` Does

1. Configures git identity from `$GIT_EMAIL` and credentials from `$GITHUB_PAT`
2. Symlinks session history to `/workspace/.claude-sessions` (persists across pod restarts)
3. Clones or updates custom skills from `$CLAUDE_SKILLS_REPO` into `~/.claude/skills/` (if set)
4. Generates `~/.claude/CLAUDE.md` with GPU specs, model size limits, and operational guidelines
5. Starts a tmux session in `/workspace`

## Safety Hooks

- **PreToolUse** (`block-dangerous-commands.sh`): blocks destructive commands (`rm -rf /`, `mkfs`, `dd`, `DROP TABLE`, etc.)
- **PostToolUse** (`git-push-notify.sh`): sends ntfy.sh notification on successful git push
- **Notification/Stop** (`notify.sh`): sends ntfy.sh notification when Claude needs input or completes a task

All notification hooks require `$NTFY_TOPIC` to be set — they silently no-op otherwise.

## Generated CLAUDE.md

`generate-claude-md.sh` creates `~/.claude/CLAUDE.md` at init time with:
- GPU hardware info (model, VRAM, compute capability, architecture)
- Inference backend compatibility (vLLM, SGLang, Transformers)
- Model size limits for bf16/int8/int4 quantisation
- Storage conventions and package installation guidance
- Notification guidelines: when to notify the user, when to proceed independently, speculative execution while awaiting responses
- Git workflow: push after every commit

## Aliases

| Alias | Purpose |
|---|---|
| `yolo` | `claude --dangerously-skip-permissions` |
| `claude-tmux` | Reattach to the tmux session |
| `claude-clean` | Delete session JSONL files over 100MB |
| `skills-pull` | Pull latest skills from your repo |
| `skills-push` | Commit and push skill changes |

## tmux

- Mouse mode is enabled
- Detach: `Ctrl+b` then `d`
- Reattach: `claude-tmux`

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Installs Claude Code, hooks, aliases, tmux config |
| `claude-init.sh` | Pod startup: git, session persistence, CLAUDE.md generation, tmux |
| `claude-settings.json` | Hook configuration |
| `block-dangerous-commands.sh` | PreToolUse hook: blocks destructive commands |
| `notify.sh` | Notification/Stop hook: posts to ntfy.sh |
| `git-push-notify.sh` | PostToolUse hook: notifies on git push |
| `generate-claude-md.sh` | Generates CLAUDE.md with GPU context and operational guidelines |
