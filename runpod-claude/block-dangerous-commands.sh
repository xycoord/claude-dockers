#!/bin/bash
COMMAND=$(cat | jq -r '.tool_input.command // empty')
if echo "$COMMAND" | grep -qiE '(rm -rf /|rm -rf ~|mkfs|dd if=|DROP TABLE|DROP DATABASE|>\s*/dev/sd)'; then
  jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: "Blocked: destructive command intercepted by safety hook"}}'
else
  exit 0
fi