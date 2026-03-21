# runpod-claude

Minimal Docker image that adds Claude Code to a RunPod PyTorch base image. Claude runs as root with terminal bell notifications on input requests and task completion.

## Build

```bash
docker build -t runpod-claude .
```

## What It Does

- Installs Claude Code into `/root/.local/bin`
- Copies `claude-settings.json` with notification hooks that trigger terminal bells on `Notification` and `Stop` events

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Installs Claude Code as root, copies settings |
| `claude-settings.json` | Hook config: terminal bell notifications |
| `git-setup.sh` | Git identity setup from env vars (currently commented out in Dockerfile) |

## Usage

After the pod starts, just run `claude` in the terminal. RunPod's default `/start.sh` entrypoint is not modified.

### Optional Env Vars

- `GIT_NAME` / `GIT_EMAIL` — only used if `git-setup.sh` is re-enabled in the Dockerfile
