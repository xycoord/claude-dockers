#!/bin/bash
# PostToolUse hook: notifies via ntfy.sh when a git push succeeds
INPUT=$(cat)

NTFY_TOPIC="${NTFY_TOPIC:-}"
if [ -z "$NTFY_TOPIC" ]; then
  exit 0
fi

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [ "$TOOL" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if ! echo "$COMMAND" | grep -qE 'git\s+push'; then
  exit 0
fi

# Check the tool succeeded
STDOUT=$(echo "$INPUT" | jq -r '.tool_output.stdout // empty')
STDERR=$(echo "$INPUT" | jq -r '.tool_output.stderr // empty')
if echo "$STDERR" | grep -qiE '(rejected|fatal|error|failed)'; then
  exit 0
fi

PROJECT=$(echo "$INPUT" | jq -r '.cwd // empty' | xargs basename 2>/dev/null || echo "unknown")
# Extract branch and remote from the command or output
BRANCH=$(git -C "$(echo "$INPUT" | jq -r '.cwd // "."')" branch --show-current 2>/dev/null || echo "unknown")

curl -s \
  -H "Title: Git Push [${PROJECT}]" \
  -H "Priority: low" \
  -H "Tags: rocket" \
  -d "Pushed to ${BRANCH}" \
  "ntfy.sh/${NTFY_TOPIC}"
