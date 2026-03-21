#!/bin/bash

# Configure git identity if env vars are set
if [ -n "$GIT_NAME" ]; then
    git config --global user.name "$GIT_NAME"
fi

if [ -n "$GIT_EMAIL" ]; then
    git config --global user.email "$GIT_EMAIL"
fi

exec /start.sh