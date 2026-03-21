#!/bin/bash
# Wrapper for claude auth login that detects the OAuth callback port
# and provides SSH port-forwarding instructions for remote containers.
#
# Usage: claude-auth (as the claude user)

CLAUDE=/home/claude/.local/bin/claude

# Check if already authenticated
if $CLAUDE auth status &>/dev/null; then
  echo "Already authenticated."
  $CLAUDE auth status --text 2>/dev/null
  exit 0
fi

echo "Starting Claude auth login..."
echo ""

# Start claude auth login in the background
$CLAUDE auth login &
AUTH_PID=$!

# Wait for it to start listening
sleep 2

# Find the port claude is listening on
AUTH_PORT=""
for i in $(seq 1 10); do
  AUTH_PORT=$(ss -tlnp 2>/dev/null | grep "pid=${AUTH_PID}" | grep -oP '127\.0\.0\.1:\K[0-9]+' | head -1)
  if [ -n "$AUTH_PORT" ]; then
    break
  fi
  sleep 1
done

if [ -z "$AUTH_PORT" ]; then
  echo "Could not detect callback port. Waiting for auth to complete..."
  echo "If auth hangs, you may need to copy credentials from a local machine."
  wait $AUTH_PID 2>/dev/null
  exit 1
fi

echo "=========================================="
echo "  OAuth callback port detected: $AUTH_PORT"
echo "=========================================="
echo ""
echo "From your LOCAL machine, open a NEW terminal and run:"
echo ""
echo "  ssh -L ${AUTH_PORT}:localhost:${AUTH_PORT} root@<YOUR_POD_IP>"
echo ""
echo "Then open the auth URL shown above in your browser."
echo "The login will complete automatically once you authenticate."
echo "=========================================="
echo ""

# Wait for auth to complete
wait $AUTH_PID 2>/dev/null

# Persist credentials if successful
if $CLAUDE auth status &>/dev/null; then
  echo ""
  echo "Login successful!"
  mkdir -p /workspace/.claude-auth
  cp ~/.claude/.credentials.json /workspace/.claude-auth/.credentials.json 2>/dev/null
  chmod 600 /workspace/.claude-auth/.credentials.json 2>/dev/null
  echo "Credentials saved to /workspace (will persist across pod restarts)."
else
  echo ""
  echo "Login did not complete. Try again or use claude-relogin."
fi
