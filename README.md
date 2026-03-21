# RunPod Claude Code Docker Images

Docker images for running [Claude Code](https://claude.ai/code) on [RunPod](https://www.runpod.io/) GPU instances.

## Images

| Image | Description |
|---|---|
| [runpod-claude](./runpod-claude/) | Minimal — installs Claude Code as root with terminal notification hooks |
| [runpod-claude-yolo](./runpod-claude-yolo/) | Autonomous — dedicated `claude` user, `--dangerously-skip-permissions` mode, safety hooks, tmux, ntfy.sh notifications |

Both are based on `runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404`.

See each image's README for build instructions, usage, and configuration.
