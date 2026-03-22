#!/bin/bash
# resolve-model-policy.sh — Merge global tier with local CLAUDE.md overrides
# Inputs: GLOBAL_TIER (from check-model-tier.sh)
# Output: Final tier (global or overridden)
# Fast: regex pattern matching, no external calls

set -uo pipefail

GLOBAL_TIER="${1:-SONNET}"
GLOBAL_MODEL="${2:-claude-sonnet-4-6}"

# Search for CLAUDE.md in current or parent directories
find_claude_md() {
    local dir="$PWD"
    local max_depth=5
    while [ "$max_depth" -gt 0 ] && [ "$dir" != "/" ]; do
        if [ -f "$dir/CLAUDE.md" ]; then
            echo "$dir/CLAUDE.md"
            return 0
        fi
        dir=$(dirname "$dir")
        ((max_depth--))
    done
    return 1
}

CLAUDE_FILE=$(find_claude_md)

# No local CLAUDE.md = use global
if [ -z "$CLAUDE_FILE" ]; then
    echo "$GLOBAL_TIER|$GLOBAL_MODEL"
    exit 0
fi

# Extract Model Policy section content (lines between "## Model Policy" and next "##")
# Strategy: sed from next line after "## Model Policy" until (but not including) next ##
POLICY=$(sed -n '/^## Model Policy/,/^##/ {/^## Model Policy/! {/^##/! p}}' "$CLAUDE_FILE" 2>/dev/null)
# If empty (no other ## found), extract to EOF
if [ -z "$POLICY" ]; then
    POLICY=$(sed -n '/^## Model Policy/,$ {/^## Model Policy/! p}' "$CLAUDE_FILE" 2>/dev/null)
fi

# No policy section = use global
if [ -z "$POLICY" ]; then
    echo "$GLOBAL_TIER|$GLOBAL_MODEL"
    exit 0
fi

# Parse min/max tier
MIN_TIER=""
MAX_TIER=""

if echo "$POLICY" | grep -qi "min.*tier.*haiku"; then
    MIN_TIER="HAIKU"
elif echo "$POLICY" | grep -qi "min.*tier.*sonnet"; then
    MIN_TIER="SONNET"
elif echo "$POLICY" | grep -qi "min.*tier.*opus"; then
    MIN_TIER="OPUS"
fi

if echo "$POLICY" | grep -qi "max.*tier.*haiku"; then
    MAX_TIER="HAIKU"
elif echo "$POLICY" | grep -qi "max.*tier.*sonnet"; then
    MAX_TIER="SONNET"
elif echo "$POLICY" | grep -qi "max.*tier.*opus"; then
    MAX_TIER="OPUS"
fi

# Tier hierarchy: HAIKU < SONNET < OPUS
tier_rank() {
    case "$1" in
        HAIKU)  echo 1 ;;
        SONNET) echo 2 ;;
        OPUS)   echo 3 ;;
        *)      echo 0 ;;
    esac
}

FINAL_TIER="$GLOBAL_TIER"
FINAL_MODEL="$GLOBAL_MODEL"

GLOBAL_RANK=$(tier_rank "$GLOBAL_TIER")
MIN_RANK=$(tier_rank "$MIN_TIER")
MAX_RANK=$(tier_rank "$MAX_TIER")

# Apply min constraint: upscale if below minimum
if [ "$MIN_RANK" -gt 0 ] && [ "$GLOBAL_RANK" -lt "$MIN_RANK" ]; then
    FINAL_TIER="$MIN_TIER"
fi

# Apply max constraint: downscale if above maximum
# Must recalculate rank after min applied
FINAL_RANK=$(tier_rank "$FINAL_TIER")
if [ "$MAX_RANK" -gt 0 ] && [ "$FINAL_RANK" -gt "$MAX_RANK" ]; then
    FINAL_TIER="$MAX_TIER"
fi

# Map tier to model
case "$FINAL_TIER" in
    HAIKU)  FINAL_MODEL="claude-haiku-4-5-20251001" ;;
    SONNET) FINAL_MODEL="claude-sonnet-4-6" ;;
    OPUS)   FINAL_MODEL="claude-opus-4-6" ;;
esac

echo "$FINAL_TIER|$FINAL_MODEL"
exit 0
