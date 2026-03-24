#!/bin/bash
# session-end.sh — Log session end to token-economy.log
# Runs on Stop hook. Records session closure for token economy reporting.

INPUT=$(cat)
command -v jq &>/dev/null || exit 0

AUDIT_LOG="$HOME/.claude/token-economy.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")

if [ -w "$(dirname "$AUDIT_LOG")" ]; then
    echo "$TS | SESSION_END | stop_hook_active=$STOP_ACTIVE" >> "$AUDIT_LOG" 2>/dev/null || true
fi

exit 0
