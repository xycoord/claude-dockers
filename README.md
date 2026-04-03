# RunPod Claude Code

A custom docker image for [RunPod](https://www.runpod.io/) with [Claude Code](https://claude.ai/code) pre-installed and set-up.

Built upon `runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404`.

## Features

- **Interactive or autonomous** — use `claude` for interactive sessions or `yolo` for fully autonomous (`--dangerously-skip-permissions`) mode
- **Safety hooks** — PreToolUse hook blocks destructive commands (`rm -rf /`, `mkfs`, `DROP TABLE`, etc.)
- **Push notifications** — ntfy.sh alerts when Claude finishes a task, needs your input, or pushes to git
- **GPU-aware CLAUDE.md** — auto-generated at init with GPU specs, model size limits, inference backend compatibility, and operational guidelines
- **Custom skills** — load your personal Claude skills from a git repo at init time
- **Session persistence** — session history survives pod restarts via `/workspace`
- **tmux** — detach and reconnect without interrupting Claude

## Setup RunPod

### 1. Create a GitHub Personal Access Token

Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens) and create a token. You'll need this for git push/pull from your pods.

- **Fine-grained tokens** (recommended): scope access to a single repository with just the permissions you need
- **Classic tokens**: use `repo` scope for full repository access

### 2. Configure RunPod Secrets

In the [RunPod console](https://www.runpod.io/console/secrets), create these secrets:


| Secret Name  | Value                                                                      |
| ------------ | -------------------------------------------------------------------------- |
| `GITHUB_PAT` | Your GitHub personal access token                                          |
| `NTFY_TOPIC` | An [ntfy.sh](https://ntfy.sh) topic name for push notifications (optional) |


Also add any API keys you'll need (e.g. `HF_TOKEN` )

### 3. Create a RunPod Template

Create a new template in [RunPod](https://www.runpod.io/console/templates):

- **Container Image**: `xycoord/runpod-claude:latest`
- **Environment Variables**:
  - `GIT_EMAIL` = your git email address
  - `GITHUB_PAT` = select from secrets
  - `NTFY_TOPIC` = select from secrets (optional)
  - `CLAUDE_SKILLS_REPO` = git URL for your custom skills repo (optional)
  - Any API keys, cache paths (e.g. `HF_HOME = /workspace/.cache/huggingface/`) or other environment variables you like

Then launch a pod from the template.

### 4. SSH in and run `claude-init`

```bash
ssh root@<your-pod-ip>
claude-init
```

This will:

- Configure git identity and credentials from your environment variables
- Set up session history persistence in `/workspace/.claude-sessions`
- Clone or update your custom skills from `$CLAUDE_SKILLS_REPO` (if set)
- Generate `~/.claude/CLAUDE.md` with your GPU specs and operational guidelines
- Drop you into a tmux session in `/workspace` 

**IMPORTANT:** you should run `claude-init` after every fresh boot.

### 5. Clone a repo (optional)

```bash
git clone https://github.com/your-org/your-repo.git
cd your-repo
```

Auth will be dependent on your `GITHUB_PAT`.

### 6. Run Claude

```bash
claude          # interactive mode
yolo            # autonomous mode (--dangerously-skip-permissions)
```

On first run, Claude will prompt you to authenticate — follow the OAuth link in the terminal.

## Notifications

If `$NTFY_TOPIC` is set, you'll get push notifications via [ntfy.sh](https://ntfy.sh) when:

- Claude completes a task
- Claude needs your input or action (e.g. accept a model license)
- A git push succeeds

This is particularly useful when using claude in yolo mode, giving it long running tasks.

[ntfy.sh](https://ntfy.sh) is a free, open-source push notification service — no account required. Pick any topic name (treat it like a password — anyone who knows it can subscribe). You can receive notifications via:

- **Browser**: go to [https://ntfy.sh](https://ntfy.sh) to set-up an account and subscribe to your topic. Pin the tab
- **Phone**: install the ntfy app ([Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy) / [iOS](https://apps.apple.com/app/ntfy/id1625396347)) and subscribe to your topic

## Useful Commands


| Command           | Purpose                                 |
| ----------------- | --------------------------------------- |
| `yolo`            | `claude --dangerously-skip-permissions` |
| `claude-tmux`     | Reattach to tmux (if disconnected)      |
| `claude-clean`    | Delete session files over 100MB         |
| `skills-pull`     | Pull latest skills from your repo       |
| `skills-push`     | Commit and push skill changes           |
| `Ctrl+b` then `d` | Detach from tmux (Claude keeps running) |


# Development/Forking
If my build is not quite perfect for you, you can fork this repo.

See [runpod-claude/README.md](./runpod-claude/README.md) for technical details.