#!/bin/bash
INPUT=$(cat)

NTFY_TOPIC="${NTFY_TOPIC:-}"
if [ -z "$NTFY_TOPIC" ]; then
  exit 0
fi

# Extract fields from hook JSON
MESSAGE=$(echo "$INPUT" | jq -r '.message // empty')
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
PROJECT=$(echo "$INPUT" | jq -r '.cwd // empty' | xargs basename 2>/dev/null || echo "unknown")

# Build notification title and body
case "$HOOK_EVENT" in
  Notification)
    TITLE="Claude Code [${PROJECT}]"
    BODY="${MESSAGE:-Needs your input}"
    PRIORITY="high"
    TAGS="warning"
    ;;
  Stop)
    TITLE="Claude Code [${PROJECT}]"
    BODY="Task completed"
    PRIORITY="default"
    TAGS="white_check_mark"
    ;;
  *)
    TITLE="Claude Code"
    BODY="${MESSAGE:-Event: ${HOOK_EVENT}}"
    PRIORITY="default"
    TAGS="robot"
    ;;
esac

curl -s \
  -H "Title: ${TITLE}" \
  -H "Priority: ${PRIORITY}" \
  -H "Tags: ${TAGS}" \
  -d "${BODY}" \
  "ntfy.sh/${NTFY_TOPIC}"