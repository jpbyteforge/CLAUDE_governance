#!/bin/bash
# session-start-model.sh — Auto-captures model at session start → writes tier file
# Eliminates the need for claude-smart launcher for tier synchronization.
# /model mid-session still requires: claude-smart --set-tier TIER

set -uo pipefail

TIER_FILE="$HOME/.claude/.active-model-tier"

INPUT=$(cat)

# Require jq
command -v jq &>/dev/null || exit 0

# Extract model from SessionStart input
MODEL=$(echo "$INPUT" | jq -r '.model // empty' 2>/dev/null)

if [ -z "$MODEL" ]; then
    exit 0
fi

# Map model ID to tier
case "$MODEL" in
    *haiku*)  TIER="HAIKU" ;;
    *opus*)   TIER="OPUS" ;;
    *)        TIER="SONNET" ;;
esac

echo "$TIER" > "$TIER_FILE"
exit 0
